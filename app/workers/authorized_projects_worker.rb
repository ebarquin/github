class AuthorizedProjectsWorker
  include Sidekiq::Worker
  include DedicatedSidekiqQueue

  def perform(user_id)
    user = User.find_by(id: user_id)
    return unless user

    user.refresh_authorized_projects
  end
end
