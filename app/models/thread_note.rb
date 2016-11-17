class ThreadNote < Note
  validates :noteable_type, inclusion: { in: ['MergeRequest'] }

  class << self
    def resolvable?
      true
    end
  end

  def threaded?
    true
  end

  private

  def set_discussion_id
    if thread_discussion_id
      self.discussion_id = thread_discussion_id
    else
      super
    end
  end
end
