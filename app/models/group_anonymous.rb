# Janya Server - Compliance, Process Management Software
# Copyright (C) 2016- 2020 Janya Inc, Venkat Allu, PMP®

class GroupAnonymous < GroupBuiltin
  def name
    l(:label_group_anonymous)
  end

  def builtin_type
    "anonymous"
  end
end
