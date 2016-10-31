require_relative 'constrainer_helper'

class GroupUrlConstrainer
  include ConstrainerHelper

  def matches?(request)
    id = extract_resource_path(request.path)
    group_path = id.rpartition('/').last

    if group_path =~ Gitlab::Regex.namespace_regex
      Group.find_by_full_path(id).present?
    else
      false
    end
  end
end
