module API
  # Projects API
  class Projects < Grape::API
    before { authenticate! }

    helpers do
      params :optional_params do
        optional :description, type: String, desc: 'The description of the project'
        optional :issues_enabled, type: Boolean, desc: 'Flag indication if the issue tracker is enabled'
        optional :merge_requests_enabled, type: Boolean, desc: 'Flag indication if merge requests are enabled'
        optional :wiki_enabled, type: Boolean, desc: 'Flag indication if the wiki is enabled'
        optional :builds_enabled, type: Boolean, desc: 'Flag indication if builds are enabled'
        optional :snippets_enabled, type: Boolean, desc: 'Flag indication if snippets are enabled'
        optional :shared_runners_enabled, type: Boolean, desc: 'Flag indication if shared runners are enabled for that project'
        optional :container_registry_enabled, type: Boolean, desc: 'Flag indication if the container registry is enabled for that project'
        optional :lfs_enabled, type: Boolean, desc: 'Flag indication if Git LFS is enabled for that project'
        optional :public, type: Boolean, desc: 'Create a public project. The same as visibility_level = 20.'
        optional :visibility_level, type: Integer, values: [Gitlab::VisibilityLevel::PRIVATE, Gitlab::VisibilityLevel::INTERNAL, Gitlab::VisibilityLevel::PUBLIC], desc: 'Create a public project. The same as visibility_level = 20.'
        optional :public_builds, type: Boolean, desc: ''
        optional :request_access_enabled, type: Boolean, desc: 'Allow users to request member access'
        optional :only_allow_merge_if_build_succeeds, type: Boolean, desc: 'Only allow to merge if builds succeed'
        optional :only_allow_merge_if_all_discussions_are_resolved, type: Boolean, desc: 'Only allow to merge if all discussions are resolved'
        optional :path, type: String, desc: 'The path of the repository'
      end

      def map_public_to_visibility_level(attrs)
        publik = attrs.delete(:public)
        if !publik.nil? && !attrs[:visibility_level].present?
          # Since setting the public attribute to private could mean either
          # private or internal, use the more conservative option, private.
          attrs[:visibility_level] = (publik == true) ? Gitlab::VisibilityLevel::PUBLIC : Gitlab::VisibilityLevel::PRIVATE
        end
        attrs
      end
    end

    resource :projects do
      helpers do
        params :sort_params do
          optional :order_by, type: String, values: %w[id name path created_at updated_at last_activity_at],
                              default: 'created_at', desc: 'Return projects ordered by field'
          optional :sort, type: String, values: %w[asc desc], default: 'desc',
                          desc: 'Return projects sorted in ascending and descending order'
        end

        params :filter_params do
          optional :archived, type: Boolean, default: false, desc: 'Limit by archived status'
          optional :visibility, type: String, values: %w[public internal private],
                                desc: 'Limit by visibility'
          optional :search, type: String, desc: 'Return list of authorized projects matching the search criteria'
          use :sort_params
        end

        params :create_params do
          optional :namespace_id, type: Integer, desc: 'Namespace ID for the new project. Default to the user namespace.'
          optional :import_url, type: String, desc: 'URL from which the project is imported'
        end
      end

      # Get a projects list for authenticated user
      #
      # Example Request:
      #   GET /projects
      desc 'Get a projects list for authenticated user' do
        success Entities::BasicProjectDetails
      end
      params do
        optional :simple, type: Boolean, default: false,
                          desc: 'Return only the ID, URL, name, and path of each project'
        use :filter_params
      end
      get do
        projects = current_user.authorized_projects
        projects = filter_projects(projects)
        entity = params[:simple] ? Entities::BasicProjectDetails : Entities::ProjectWithAccess

        present paginate(projects), with: entity, user: current_user
      end

      # Get a list of visible projects for authenticated user
      #
      # Example Request:
      #   GET /projects/visible
      desc 'Get a list of visible projects for authenticated user' do
        success Entities::BasicProjectDetails
      end
      params do
        optional :simple, type: Boolean, default: false,
                          desc: 'Return only the ID, URL, name, and path of each project'
        use :filter_params
      end
      get '/visible' do
        projects = ProjectsFinder.new.execute(current_user)
        projects = filter_projects(projects)
        entity = params[:simple] ? Entities::BasicProjectDetails : Entities::ProjectWithAccess

        present paginate(projects), with: entity, user: current_user
      end

      # Get an owned projects list for authenticated user
      #
      # Example Request:
      #   GET /projects/owned
      desc 'Get an owned projects list for authenticated user' do
        success Entities::BasicProjectDetails
      end
      params do
        use :filter_params
      end
      get '/owned' do
        projects = current_user.owned_projects
        projects = filter_projects(projects)

        present paginate(projects), with: Entities::ProjectWithAccess, user: current_user
      end

      # Gets starred project for the authenticated user
      #
      # Example Request:
      #   GET /projects/starred
      desc 'Gets starred project for the authenticated user' do
        success Entities::BasicProjectDetails
      end
      params do
        use :filter_params
      end
      get '/starred' do
        projects = current_user.viewable_starred_projects
        projects = filter_projects(projects)

        present paginate(projects), with: Entities::Project, user: current_user
      end

      # Get all projects for admin user
      #
      # Example Request:
      #   GET /projects/all
      desc 'Get all projects for admin user' do
        success Entities::BasicProjectDetails
      end
      params do
        use :filter_params
      end
      get '/all' do
        authenticated_as_admin!
        projects = Project.all
        projects = filter_projects(projects)

        present paginate(projects), with: Entities::ProjectWithAccess, user: current_user
      end

      desc 'Search for projects the current user has access to' do
        success Entities::Project
      end
      params do
        requires :query, type: String, desc: 'The project name to be searched'
        optional :per_page, type: Integer, desc: 'The number of projects to return per page'
        optional :page, type: Integer, desc: 'The page to retrieve'
        use :sort_params
      end
      get "/search/:query" do
        search_service = Search::GlobalService.new(current_user, search: params[:query]).execute
        projects = search_service.objects('projects', params[:page])
        projects = projects.reorder(params[:order_by] => params[:sort].to_sym)

        present paginate(projects), with: Entities::Project
      end

      desc 'Create new project' do
        success Entities::Project
      end
      params do
        requires :name, type: String, desc: 'The name of the project'
        use :optional_params
        use :create_params
      end
      post do
        attrs = map_public_to_visibility_level(declared_params(include_missing: false))
        project = ::Projects::CreateService.new(current_user, attrs).execute

        if project.saved?
          present project, with: Entities::Project,
                           user_can_admin_project: can?(current_user, :admin_project, project)
        else
          if project.errors[:limit_reached].present?
            error!(project.errors[:limit_reached], 403)
          end
          render_validation_error!(project)
        end
      end

      desc 'Create new project for a specified user. Only available to admin users.' do
        success Entities::Project
      end
      params do
        requires :name, type: String, desc: 'The name of the project'
        requires :user_id, type: Integer, desc: 'The ID of a user'
        use :optional_params
        use :create_params
      end
      post "user/:user_id" do
        authenticated_as_admin!
        user = User.find(params.delete(:user_id))

        attrs = map_public_to_visibility_level(declared_params(include_missing: false))
        project = ::Projects::CreateService.new(user, attrs).execute

        if project.saved?
          present project, with: Entities::Project,
                           user_can_admin_project: can?(current_user, :admin_project, project)
        else
          render_validation_error!(project)
        end
      end
    end

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: { id: /[^\/]+/ } do
      desc 'Get a single project' do
        success Entities::ProjectWithAccess
      end
      get ":id" do
        present user_project, with: Entities::ProjectWithAccess, user: current_user,
                              user_can_admin_project: can?(current_user, :admin_project, user_project)
      end

      desc 'Get events for a single project' do
        success Entities::Event
      end
      get ":id/events" do
        events = paginate user_project.events.recent
        present events, with: Entities::Event
      end



      desc 'Fork new project for the current user or provided namespace.' do
        success Entities::Project
      end
      params do
        optional :namespace, type: String, desc: 'The ID or name of the namespace that the project will be forked into'
      end
      post 'fork/:id' do
        attrs = {}
        namespace_id = params[:namespace]

        if namespace_id.present?
          namespace = Namespace.find_by(id: namespace_id) || Namespace.find_by_path_or_name(namespace_id)

          unless namespace && can?(current_user, :create_projects, namespace)
            not_found!('Target Namespace')
          end

          attrs[:namespace] = namespace
        end

        forked_project =
          ::Projects::ForkService.new(user_project,
                                      current_user,
                                      attrs).execute

        if forked_project.errors.any?
          conflict!(forked_project.errors.messages)
        else
          present forked_project, with: Entities::Project,
                                  user_can_admin_project: can?(current_user, :admin_project, forked_project)
        end
      end

      desc 'Update an existing project' do
        success Entities::Project
      end
      params do
        optional :name, type: String, desc: 'The name of the project'
        optional :default_branch, type: String, desc: 'The default branch of the project'
        use :optional_params
        at_least_one_of :name, :description, :issues_enabled, :merge_requests_enabled,
                        :wiki_enabled, :builds_enabled, :snippets_enabled,
                        :shared_runners_enabled, :container_registry_enabled,
                        :lfs_enabled, :public, :visibility_level, :public_builds,
                        :request_access_enabled, :only_allow_merge_if_build_succeeds,
                        :only_allow_merge_if_all_discussions_are_resolved, :path,
                        :default_branch
      end
      put ':id' do
        authorize_admin_project
        attrs = map_public_to_visibility_level(declared_params(include_missing: false))
        authorize! :rename_project, user_project if attrs[:name].present?
        authorize! :change_visibility_level, user_project if attrs[:visibility_level].present?

        ::Projects::UpdateService.new(user_project, current_user, attrs).execute

        if user_project.errors.any?
          render_validation_error!(user_project)
        else
          present user_project, with: Entities::Project,
                                user_can_admin_project: can?(current_user, :admin_project, user_project)
        end
      end

      desc 'Archive a project' do
        success Entities::Project
      end
      post ':id/archive' do
        authorize!(:archive_project, user_project)

        user_project.archive!

        present user_project, with: Entities::Project
      end

      desc 'Unarchive a project' do
        success Entities::Project
      end
      post ':id/unarchive' do
        authorize!(:archive_project, user_project)

        user_project.unarchive!

        present user_project, with: Entities::Project
      end

      desc 'Star a project' do
        success Entities::Project
      end
      post ':id/star' do
        if current_user.starred?(user_project)
          not_modified!
        else
          current_user.toggle_star(user_project)
          user_project.reload

          present user_project, with: Entities::Project
        end
      end

      desc 'Unstar a project' do
        success Entities::Project
      end
      delete ':id/star' do
        if current_user.starred?(user_project)
          current_user.toggle_star(user_project)
          user_project.reload

          present user_project, with: Entities::Project
        else
          not_modified!
        end
      end

      desc 'Remove a project'
      delete ":id" do
        authorize! :remove_project, user_project
        ::Projects::DestroyService.new(user_project, current_user, {}).async_execute
      end

      desc 'Mark this project as forked from another'
      params do
        requires :forked_from_id, type: String, desc: 'The ID of the project it was forked from'
      end
      post ":id/fork/:forked_from_id" do
        authenticated_as_admin!
        forked_from_project = find_project(params[:forked_from_id])
        unless forked_from_project.nil?
          if user_project.forked_from_project.nil?
            user_project.create_forked_project_link(forked_to_project_id: user_project.id, forked_from_project_id: forked_from_project.id)
          else
            render_api_error!("Project already forked", 409)
          end
        else
          not_found!("Source Project")
        end
      end

      desc 'Remove a forked_from relationship'
      delete ":id/fork" do
        authorize! :remove_fork_project, user_project

        if user_project.forked?
          user_project.forked_project_link.destroy
        else
          not_modified!
        end
      end

      desc 'Share the project with a group' do
        success Entities::ProjectGroupLink
      end
      params do
        requires :group_id, type: Integer, desc: 'The ID of a group'
        requires :group_access, type: Integer, values: Gitlab::Access.values, desc: 'The group access level'
        optional :expires_at, type: String, desc: 'Share expiration date'
      end
      post ":id/share" do
        authorize! :admin_project, user_project
        group = Group.find_by_id(params[:group_id])

        unless group && can?(current_user, :read_group, group)
          not_found!('Group')
        end

        unless user_project.allowed_to_share_with_group?
          return render_api_error!("The project sharing with group is disabled", 400)
        end

        link = user_project.project_group_links.new(declared_params(include_missing: false))

        if link.save
          present link, with: Entities::ProjectGroupLink
        else
          render_api_error!(link.errors.full_messages.first, 409)
        end
      end

      desc 'Upload a file'
      params do
        requires :file, type: File, desc: 'The file to be uploaded'
      end
      post ":id/uploads" do
        ::Projects::UploadService.new(user_project, params[:file]).execute
      end

      desc 'Get the users list of a project' do
        success Entities::UserBasic
      end
      params do
        optional :search, type: String, desc: 'Return list of users matching the search criteria'
      end
      get ':id/users' do
        users = User.where(id: user_project.team.users.map(&:id))
        users = users.search(params[:search]) if params[:search].present?

        present paginate(users), with: Entities::UserBasic
      end
    end
  end
end
