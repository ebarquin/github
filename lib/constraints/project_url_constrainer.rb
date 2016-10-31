require_relative 'constrainer_helper'

class ProjectUrlConstrainer
  include ConstrainerHelper

  def matches?(request)
    namespace_path = request.params[:namespace_id]
    project_path = request.params[:project_id] || request.params[:id]
    full_path = namespace_path + '/' + project_path

    if namespace_path.blank? ||
      project_path.blank? ||
      reserved_names.include?(project_path)
      return false
    end

    Project.find_with_namespace(full_path).present?
  end

  def reserved_names
    # Every routing that has wildcard id inside project scope should be restricted here.
    # We need this to avoid false positive routing match because namespace id contains wildcard too.
    # For example wiki routing looks like "*namespace_id/:project_id/wikis/*id".
    %w(tree commits wikis new edit create update logs_tree preview blob blame raw files create_dir find_file)
  end
end
