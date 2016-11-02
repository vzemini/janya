package Apache::Authn::Janya;

=head1 Apache::Authn::Janya

Janya - a mod_perl module to authenticate webdav subversion users
against janya database

=head1 SYNOPSIS

This module allow anonymous users to browse public project and
registred users to browse and commit their project. Authentication is
done against the janya database or the LDAP configured in janya.

This method is far simpler than the one with pam_* and works with all
database without an hassle but you need to have apache/mod_perl on the
svn server.

=head1 INSTALLATION

For this to automagically work, you need to have a recent reposman.rb
(after r860) and if you already use reposman, read the last section to
migrate.

Sorry ruby users but you need some perl modules, at least mod_perl2,
DBI and DBD::mysql (or the DBD driver for you database as it should
work on allmost all databases).

On debian/ubuntu you must do :

  aptitude install libapache-dbi-perl libapache2-mod-perl2 libdbd-mysql-perl

If your Janya users use LDAP authentication, you will also need
Authen::Simple::LDAP (and IO::Socket::SSL if LDAPS is used):

  aptitude install libauthen-simple-ldap-perl libio-socket-ssl-perl

=head1 CONFIGURATION

   ## This module has to be in your perl path
   ## eg:  /usr/lib/perl5/Apache/Authn/Janya.pm
   PerlLoadModule Apache::Authn::Janya
   <Location /svn>
     DAV svn
     SVNParentPath "/var/svn"

     AuthType Basic
     AuthName janya
     Require valid-user

     PerlAccessHandler Apache::Authn::Janya::access_handler
     PerlAuthenHandler Apache::Authn::Janya::authen_handler

     ## for mysql
     JanyaDSN "DBI:mysql:database=databasename;host=my.db.server"
     ## for postgres
     # JanyaDSN "DBI:Pg:dbname=databasename;host=my.db.server"

     JanyaDbUser "janya"
     JanyaDbPass "password"
     ## Optional where clause (fulltext search would be slow and
     ## database dependant).
     # JanyaDbWhereClause "and members.role_id IN (1,2)"
     ## Optional credentials cache size
     # JanyaCacheCredsMax 50
  </Location>

To be able to browse repository inside janya, you must add something
like that :

   <Location /svn-private>
     DAV svn
     SVNParentPath "/var/svn"
     Order deny,allow
     Deny from all
     # only allow reading orders
     <Limit GET PROPFIND OPTIONS REPORT>
       Allow from janya.server.ip
     </Limit>
   </Location>

and you will have to use this reposman.rb command line to create repository :

  reposman.rb --janya my.janya.server --svn-dir /var/svn --owner www-data -u http://svn.server/svn-private/

=head1 REPOSITORIES NAMING

A project repository must be named with the project identifier. In case
of multiple repositories for the same project, use the project identifier
and the repository identifier separated with a dot:

  /var/svn/foo
  /var/svn/foo.otherrepo

=head1 MIGRATION FROM OLDER RELEASES

If you use an older reposman.rb (r860 or before), you need to change
rights on repositories to allow the apache user to read and write
S<them :>

  sudo chown -R www-data /var/svn/*
  sudo chmod -R u+w /var/svn/*

And you need to upgrade at least reposman.rb (after r860).

=head1 GIT SMART HTTP SUPPORT

Git's smart HTTP protocol (available since Git 1.7.0) will not work with the
above settings. Janya.pm normally does access control depending on the HTTP
method used: read-only methods are OK for everyone in public projects and
members with read rights in private projects. The rest require membership with
commit rights in the project.

However, this scheme doesn't work for Git's smart HTTP protocol, as it will use
POST even for a simple clone. Instead, read-only requests must be detected using
the full URL (including the query string): anything that doesn't belong to the
git-receive-pack service is read-only.

To activate this mode of operation, add this line inside your <Location /git>
block:

  JanyaGitSmartHttp yes

Here's a sample Apache configuration which integrates git-http-backend with
a MySQL database and this new option:

   SetEnv GIT_PROJECT_ROOT /var/www/git/
   SetEnv GIT_HTTP_EXPORT_ALL
   ScriptAlias /git/ /usr/libexec/git-core/git-http-backend/
   <Location /git>
       Order allow,deny
       Allow from all

       AuthType Basic
       AuthName Git
       Require valid-user

       PerlAccessHandler Apache::Authn::Janya::access_handler
       PerlAuthenHandler Apache::Authn::Janya::authen_handler
       # for mysql
       JanyaDSN "DBI:mysql:database=janya;host=127.0.0.1"
       JanyaDbUser "janya"
       JanyaDbPass "xxx"
       JanyaGitSmartHttp yes
    </Location>

Make sure that all the names of the repositories under /var/www/git/ have a
matching identifier for some project: /var/www/git/myproject and
/var/www/git/myproject.git will work. You can put both bare and non-bare
repositories in /var/www/git, though bare repositories are strongly
recommended. You should create them with the rights of the user running Janya,
like this:

  cd /var/www/git
  sudo -u user-running-janya mkdir myproject
  cd myproject
  sudo -u user-running-janya git init --bare

Once you have activated this option, you have three options when cloning a
repository:

- Cloning using "http://user@host/git/repo(.git)" works, but will ask for the password
  all the time.

- Cloning with "http://user:pass@host/git/repo(.git)" does not have this problem, but
  this could reveal accidentally your password to the console in some versions
  of Git, and you would have to ensure that .git/config is not readable except
  by the owner for each of your projects.

- Use "http://host/git/repo(.git)", and store your credentials in the ~/.netrc
  file. This is the recommended solution, as you only have one file to protect
  and passwords will not be leaked accidentally to the console.

  IMPORTANT NOTE: It is *very important* that the file cannot be read by other
  users, as it will contain your password in cleartext. To create the file, you
  can use the following commands, replacing yourhost, youruser and yourpassword
  with the right values:

    touch ~/.netrc
    chmod 600 ~/.netrc
    echo -e "machine yourhost\nlogin youruser\npassword yourpassword" > ~/.netrc

=cut

use strict;
use warnings FATAL => 'all', NONFATAL => 'redefine';

use DBI;
use Digest::SHA;
# optional module for LDAP authentication
my $CanUseLDAPAuth = eval("use Authen::Simple::LDAP; 1");

use Apache2::Module;
use Apache2::Access;
use Apache2::ServerRec qw();
use Apache2::RequestRec qw();
use Apache2::RequestUtil qw();
use Apache2::Const qw(:common :override :cmd_how);
use APR::Pool ();
use APR::Table ();

# use Apache2::Directive qw();

my @directives = (
  {
    name => 'JanyaDSN',
    req_override => OR_AUTHCFG,
    args_how => TAKE1,
    errmsg => 'Dsn in format used by Perl DBI. eg: "DBI:Pg:dbname=databasename;host=my.db.server"',
  },
  {
    name => 'JanyaDbUser',
    req_override => OR_AUTHCFG,
    args_how => TAKE1,
  },
  {
    name => 'JanyaDbPass',
    req_override => OR_AUTHCFG,
    args_how => TAKE1,
  },
  {
    name => 'JanyaDbWhereClause',
    req_override => OR_AUTHCFG,
    args_how => TAKE1,
  },
  {
    name => 'JanyaCacheCredsMax',
    req_override => OR_AUTHCFG,
    args_how => TAKE1,
    errmsg => 'JanyaCacheCredsMax must be decimal number',
  },
  {
    name => 'JanyaGitSmartHttp',
    req_override => OR_AUTHCFG,
    args_how => TAKE1,
  },
);

sub JanyaDSN {
  my ($self, $parms, $arg) = @_;
  $self->{JanyaDSN} = $arg;
  my $query = "SELECT 
                 users.hashed_password, users.salt, users.auth_source_id, roles.permissions, projects.status
              FROM projects, users, roles
              WHERE 
                users.login=? 
                AND projects.identifier=?
                AND users.type='User'
                AND users.status=1 
                AND (
                  roles.id IN (SELECT member_roles.role_id FROM members, member_roles WHERE members.user_id = users.id AND members.project_id = projects.id AND members.id = member_roles.member_id)
                  OR
                  (cast(projects.is_public as CHAR) IN ('t', '1')
                    AND (roles.builtin=1
                         OR roles.id IN (SELECT member_roles.role_id FROM members, member_roles, users g
                                 WHERE members.user_id = g.id AND members.project_id = projects.id AND members.id = member_roles.member_id
                                 AND g.type = 'GroupNonMember'))
                  )
                )
                AND roles.permissions IS NOT NULL";
  $self->{JanyaQuery} = trim($query);
}

sub JanyaDbUser { set_val('JanyaDbUser', @_); }
sub JanyaDbPass { set_val('JanyaDbPass', @_); }
sub JanyaDbWhereClause {
  my ($self, $parms, $arg) = @_;
  $self->{JanyaQuery} = trim($self->{JanyaQuery}.($arg ? $arg : "")." ");
}

sub JanyaCacheCredsMax {
  my ($self, $parms, $arg) = @_;
  if ($arg) {
    $self->{JanyaCachePool} = APR::Pool->new;
    $self->{JanyaCacheCreds} = APR::Table::make($self->{JanyaCachePool}, $arg);
    $self->{JanyaCacheCredsCount} = 0;
    $self->{JanyaCacheCredsMax} = $arg;
  }
}

sub JanyaGitSmartHttp {
  my ($self, $parms, $arg) = @_;
  $arg = lc $arg;

  if ($arg eq "yes" || $arg eq "true") {
    $self->{JanyaGitSmartHttp} = 1;
  } else {
    $self->{JanyaGitSmartHttp} = 0;
  }
}

sub trim {
  my $string = shift;
  $string =~ s/\s{2,}/ /g;
  return $string;
}

sub set_val {
  my ($key, $self, $parms, $arg) = @_;
  $self->{$key} = $arg;
}

Apache2::Module::add(__PACKAGE__, \@directives);


my %read_only_methods = map { $_ => 1 } qw/GET HEAD PROPFIND REPORT OPTIONS/;

sub request_is_read_only {
  my ($r) = @_;
  my $cfg = Apache2::Module::get_config(__PACKAGE__, $r->server, $r->per_dir_config);

  # Do we use Git's smart HTTP protocol, or not?
  if (defined $cfg->{JanyaGitSmartHttp} and $cfg->{JanyaGitSmartHttp}) {
    my $uri = $r->unparsed_uri;
    my $location = $r->location;
    my $is_read_only = $uri !~ m{^$location/*[^/]+/+(info/refs\?service=)?git\-receive\-pack$}o;
    return $is_read_only;
  } else {
    # Standard behaviour: check the HTTP method
    my $method = $r->method;
    return defined $read_only_methods{$method};
  }
}

sub access_handler {
  my $r = shift;

  unless ($r->some_auth_required) {
      $r->log_reason("No authentication has been configured");
      return FORBIDDEN;
  }

  return OK unless request_is_read_only($r);

  my $project_id = get_project_identifier($r);

  if (is_public_project($project_id, $r) && anonymous_allowed_to_browse_repository($project_id, $r)) {
    $r->user("");
    $r->set_handlers(PerlAuthenHandler => [\&OK]);
  }

  return OK
}

sub authen_handler {
  my $r = shift;

  my ($res, $janya_pass) =  $r->get_basic_auth_pw();
  return $res unless $res == OK;

  if (is_member($r->user, $janya_pass, $r)) {
      return OK;
  } else {
      $r->note_auth_failure();
      return DECLINED;
  }
}

# check if authentication is forced
sub is_authentication_forced {
  my $r = shift;

  my $dbh = connect_database($r);
  my $sth = $dbh->prepare(
    "SELECT value FROM settings where settings.name = 'login_required';"
  );

  $sth->execute();
  my $ret = 0;
  if (my @row = $sth->fetchrow_array) {
    if ($row[0] eq "1" || $row[0] eq "t") {
      $ret = 1;
    }
  }
  $sth->finish();
  undef $sth;

  $dbh->disconnect();
  undef $dbh;

  $ret;
}

sub is_public_project {
    my $project_id = shift;
    my $r = shift;

    if (is_authentication_forced($r)) {
      return 0;
    }

    my $dbh = connect_database($r);
    my $sth = $dbh->prepare(
        "SELECT is_public FROM projects WHERE projects.identifier = ? AND projects.status <> 9;"
    );

    $sth->execute($project_id);
    my $ret = 0;
    if (my @row = $sth->fetchrow_array) {
      if ($row[0] eq "1" || $row[0] eq "t") {
        $ret = 1;
      }
    }
    $sth->finish();
    undef $sth;
    $dbh->disconnect();
    undef $dbh;

    $ret;
}

sub anonymous_allowed_to_browse_repository {
  my $project_id = shift;
  my $r = shift;

  my $dbh = connect_database($r);
  my $sth = $dbh->prepare(
      "SELECT permissions FROM roles WHERE permissions like '%browse_repository%'
        AND (roles.builtin = 2
             OR roles.id IN (SELECT member_roles.role_id FROM projects, members, member_roles, users
                             WHERE members.user_id = users.id AND members.project_id = projects.id AND members.id = member_roles.member_id
                             AND projects.identifier = ? AND users.type = 'GroupAnonymous'));"
  );

  $sth->execute($project_id);
  my $ret = 0;
  if (my @row = $sth->fetchrow_array) {
    if ($row[0] =~ /:browse_repository/) {
      $ret = 1;
    }
  }
  $sth->finish();
  undef $sth;
  $dbh->disconnect();
  undef $dbh;

  $ret;
}

# perhaps we should use repository right (other read right) to check public access.
# it could be faster BUT it doesn't work for the moment.
# sub is_public_project_by_file {
#     my $project_id = shift;
#     my $r = shift;

#     my $tree = Apache2::Directive::conftree();
#     my $node = $tree->lookup('Location', $r->location);
#     my $hash = $node->as_hash;

#     my $svnparentpath = $hash->{SVNParentPath};
#     my $repos_path = $svnparentpath . "/" . $project_id;
#     return 1 if (stat($repos_path))[2] & 00007;
# }

sub is_member {
  my $janya_user = shift;
  my $janya_pass = shift;
  my $r = shift;

  my $project_id  = get_project_identifier($r);

  my $pass_digest = Digest::SHA::sha1_hex($janya_pass);

  my $access_mode = request_is_read_only($r) ? "R" : "W";

  my $cfg = Apache2::Module::get_config(__PACKAGE__, $r->server, $r->per_dir_config);
  my $usrprojpass;
  if ($cfg->{JanyaCacheCredsMax}) {
    $usrprojpass = $cfg->{JanyaCacheCreds}->get($janya_user.":".$project_id.":".$access_mode);
    return 1 if (defined $usrprojpass and ($usrprojpass eq $pass_digest));
  }
  my $dbh = connect_database($r);
  my $query = $cfg->{JanyaQuery};
  my $sth = $dbh->prepare($query);
  $sth->execute($janya_user, $project_id);

  my $ret;
  while (my ($hashed_password, $salt, $auth_source_id, $permissions, $project_status) = $sth->fetchrow_array) {
      if ($project_status eq "9" || ($project_status ne "1" && $access_mode eq "W")) {
        last;
      }

      unless ($auth_source_id) {
          my $method = $r->method;
          my $salted_password = Digest::SHA::sha1_hex($salt.$pass_digest);
          if ($hashed_password eq $salted_password && (($access_mode eq "R" && $permissions =~ /:browse_repository/) || $permissions =~ /:commit_access/) ) {
              $ret = 1;
              last;
          }
      } elsif ($CanUseLDAPAuth) {
          my $sthldap = $dbh->prepare(
              "SELECT host,port,tls,account,account_password,base_dn,attr_login from auth_sources WHERE id = ?;"
          );
          $sthldap->execute($auth_source_id);
          while (my @rowldap = $sthldap->fetchrow_array) {
            my $bind_as = $rowldap[3] ? $rowldap[3] : "";
            my $bind_pw = $rowldap[4] ? $rowldap[4] : "";
            if ($bind_as =~ m/\$login/) {
              # replace $login with $janya_user and use $janya_pass
              $bind_as =~ s/\$login/$janya_user/g;
              $bind_pw = $janya_pass
            }
            my $ldap = Authen::Simple::LDAP->new(
                host    =>      ($rowldap[2] eq "1" || $rowldap[2] eq "t") ? "ldaps://$rowldap[0]:$rowldap[1]" : $rowldap[0],
                port    =>      $rowldap[1],
                basedn  =>      $rowldap[5],
                binddn  =>      $bind_as,
                bindpw  =>      $bind_pw,
                filter  =>      "(".$rowldap[6]."=%s)"
            );
            my $method = $r->method;
            $ret = 1 if ($ldap->authenticate($janya_user, $janya_pass) && (($access_mode eq "R" && $permissions =~ /:browse_repository/) || $permissions =~ /:commit_access/));

          }
          $sthldap->finish();
          undef $sthldap;
      }
  }
  $sth->finish();
  undef $sth;
  $dbh->disconnect();
  undef $dbh;

  if ($cfg->{JanyaCacheCredsMax} and $ret) {
    if (defined $usrprojpass) {
      $cfg->{JanyaCacheCreds}->set($janya_user.":".$project_id.":".$access_mode, $pass_digest);
    } else {
      if ($cfg->{JanyaCacheCredsCount} < $cfg->{JanyaCacheCredsMax}) {
        $cfg->{JanyaCacheCreds}->set($janya_user.":".$project_id.":".$access_mode, $pass_digest);
        $cfg->{JanyaCacheCredsCount}++;
      } else {
        $cfg->{JanyaCacheCreds}->clear();
        $cfg->{JanyaCacheCredsCount} = 0;
      }
    }
  }

  $ret;
}

sub get_project_identifier {
    my $r = shift;

    my $cfg = Apache2::Module::get_config(__PACKAGE__, $r->server, $r->per_dir_config);
    my $location = $r->location;
    $location =~ s/\.git$// if (defined $cfg->{JanyaGitSmartHttp} and $cfg->{JanyaGitSmartHttp});
    my ($identifier) = $r->uri =~ m{$location/*([^/.]+)};
    $identifier;
}

sub connect_database {
    my $r = shift;

    my $cfg = Apache2::Module::get_config(__PACKAGE__, $r->server, $r->per_dir_config);
    return DBI->connect($cfg->{JanyaDSN}, $cfg->{JanyaDbUser}, $cfg->{JanyaDbPass});
}

1;
