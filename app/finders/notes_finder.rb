class NotesFinder
  FETCH_OVERLAP = 5.seconds

  attr_accessor :project, :current_user, :params

  def initialize(project, current_user, params)
    @project, @current_user, @params = project, current_user, params
  end

  def execute
    notes =
      if target.respond_to?(:related_notes)
        target.related_notes
      else
        target.notes
      end

    last_fetched_at = Time.at(params.fetch(:last_fetched_at, 0).to_i)
    # Use overlapping intervals to avoid worrying about race conditions
    notes.inc_author.where('updated_at > ?', last_fetched_at - FETCH_OVERLAP).fresh
  end

  def target
    target_type = params[:target_type]
    target_id   = params[:target_id]

    notes =
      case target_type
      when "commit"
        project.commit(target_id)
      when "issue"
        project.issues.visible_to_user(current_user).find(target_id)
      when "merge_request"
        project.merge_requests.find(target_id)
      when "snippet", "project_snippet"
        project.snippets.find(target_id)
      else
        raise 'invalid target_type'
      end
  end
end
