module ExploreHelper
  def filter_projects_path(options = {})
    exist_opts = {
      sort: params[:sort],
      scope: params[:scope],
      group: params[:group],
      tag: params[:tag],
      visibility_level: params[:visibility_level],
    }

    options = exist_opts.merge(options)
    path = request.path
    path << "?#{options.to_param}"
    path
  end

  def filter_group_member_path(options = {})
    exist_opts = {
      utf8: params[:utf8] ||= '✓',
      search: params[:search],
      sort: params[:sort],
    }

    options = exist_opts.merge(options)
    path = request.path
    path << "?#{options.to_param}"
    path
  end

  def explore_controller?
    controller.class.name.split("::").first == "Explore"
  end
end
