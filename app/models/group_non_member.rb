# Janya Server - Compliance, Process Management Software
# Copyright (C) 2016- 2020 Janya Inc, Venkat Allu, PMP®

class GroupNonMember < GroupBuiltin
  def name
    l(:label_group_non_member)
  end

  def builtin_type
    "non_member"
  end
end
