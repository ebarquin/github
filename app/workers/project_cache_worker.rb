# Worker for updating any project specific caches.
#
# This worker runs at most once every 15 minutes per project. This is to ensure
# that multiple instances of jobs for this worker don't hammer the underlying
# storage engine as much.
class ProjectCacheWorker
  include Sidekiq::Worker
  include DedicatedSidekiqQueue

  LEASE_TIMEOUT = 15.minutes.to_i

  def self.lease_for(project_id)
    Gitlab::ExclusiveLease.
      new("project_cache_worker:#{project_id}", timeout: LEASE_TIMEOUT)
  end

  # Overwrite Sidekiq's implementation so we only schedule when actually needed.
  def self.perform_async(project_id, refresh = [])
    # If a lease for this project is still being held there's no point in
    # scheduling a new job.
    super unless lease_for(project_id).exists?
  end

  # project_id - The ID of the project for which to flush the cache.
  # refresh - An Array containing extra types of data to refresh such as
  #           `:readme` to flush the README and `:changelog` to flush the
  #           CHANGELOG.
  def perform(project_id, refresh = [])
    if try_obtain_lease_for(project_id)
      Rails.logger.
        info("Obtained ProjectCacheWorker lease for project #{project_id}")
    else
      Rails.logger.
        info("Could not obtain ProjectCacheWorker lease for project #{project_id}")

      return
    end

    update_caches(project_id, refresh)
  end

  def update_caches(project_id, refresh = [])
    project = Project.find(project_id)

    return unless project.repository.exists?

    project.update_repository_size
    project.update_commit_count

    project.repository.refresh_method_caches(refresh)
  end

  def try_obtain_lease_for(project_id)
    self.class.lease_for(project_id).try_obtain
  end
end
