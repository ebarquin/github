require 'spec_helper'

describe Event, models: true do
  describe "Associations" do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:target) }
  end

  describe "Respond to" do
    it { is_expected.to respond_to(:author_name) }
    it { is_expected.to respond_to(:author_email) }
    it { is_expected.to respond_to(:issue_title) }
    it { is_expected.to respond_to(:merge_request_title) }
    it { is_expected.to respond_to(:commits) }
  end

  describe 'Callbacks' do
    describe 'after_create :reset_project_activity' do
      let(:project) { create(:empty_project) }

      it 'calls the reset_project_activity method' do
        expect_any_instance_of(Event).to receive(:reset_project_activity)

        create_event(project, project.owner)
      end
    end
  end

  describe "Push event" do
    before do
      project = create(:project)
      @user = project.owner
      @event = create_event(project, @user)
    end

    it { expect(@event.push?).to be_truthy }
    it { expect(@event.visible_to_user?).to be_truthy }
    it { expect(@event.tag?).to be_falsey }
    it { expect(@event.branch_name).to eq("master") }
    it { expect(@event.author).to eq(@user) }
  end

  describe '#note?' do
    subject { Event.new(project: target.project, target: target) }

    context 'issue note event' do
      let(:target) { create(:note_on_issue) }

      it { is_expected.to be_note }
    end

    context 'merge request diff note event' do
      let(:target) { create(:legacy_diff_note_on_merge_request) }

      it { is_expected.to be_note }
    end
  end

  describe '#visible_to_user?' do
    let(:project) { create(:empty_project, :public) }
    let(:non_member) { create(:user) }
    let(:member)  { create(:user) }
    let(:guest)  { create(:user) }
    let(:author) { create(:author) }
    let(:assignee) { create(:user) }
    let(:admin) { create(:admin) }
    let(:issue) { create(:issue, project: project, author: author, assignee: assignee) }
    let(:confidential_issue) { create(:issue, :confidential, project: project, author: author, assignee: assignee) }
    let(:note_on_issue) { create(:note_on_issue, noteable: issue, project: project) }
    let(:note_on_confidential_issue) { create(:note_on_issue, noteable: confidential_issue, project: project) }
    let(:event) { Event.new(project: project, target: target, author_id: author.id) }

    before do
      project.team << [member, :developer]
      project.team << [guest, :guest]
    end

    context 'issue event' do
      context 'for non confidential issues' do
        let(:target) { issue }

        it { expect(event.visible_to_user?(non_member)).to eq true }
        it { expect(event.visible_to_user?(author)).to eq true }
        it { expect(event.visible_to_user?(assignee)).to eq true }
        it { expect(event.visible_to_user?(member)).to eq true }
        it { expect(event.visible_to_user?(guest)).to eq true }
        it { expect(event.visible_to_user?(admin)).to eq true }
      end

      context 'for confidential issues' do
        let(:target) { confidential_issue }

        it { expect(event.visible_to_user?(non_member)).to eq false }
        it { expect(event.visible_to_user?(author)).to eq true }
        it { expect(event.visible_to_user?(assignee)).to eq true }
        it { expect(event.visible_to_user?(member)).to eq true }
        it { expect(event.visible_to_user?(guest)).to eq false }
        it { expect(event.visible_to_user?(admin)).to eq true }
      end
    end

    context 'issue note event' do
      context 'on non confidential issues' do
        let(:target) { note_on_issue }

        it { expect(event.visible_to_user?(non_member)).to eq true }
        it { expect(event.visible_to_user?(author)).to eq true }
        it { expect(event.visible_to_user?(assignee)).to eq true }
        it { expect(event.visible_to_user?(member)).to eq true }
        it { expect(event.visible_to_user?(guest)).to eq true }
        it { expect(event.visible_to_user?(admin)).to eq true }
      end

      context 'on confidential issues' do
        let(:target) { note_on_confidential_issue }

        it { expect(event.visible_to_user?(non_member)).to eq false }
        it { expect(event.visible_to_user?(author)).to eq true }
        it { expect(event.visible_to_user?(assignee)).to eq true }
        it { expect(event.visible_to_user?(member)).to eq true }
        it { expect(event.visible_to_user?(guest)).to eq false }
        it { expect(event.visible_to_user?(admin)).to eq true }
      end
    end

    context 'merge request diff note event' do
      let(:project) { create(:project, :public) }
      let(:merge_request) { create(:merge_request, source_project: project, author: author, assignee: assignee) }
      let(:note_on_merge_request) { create(:legacy_diff_note_on_merge_request, noteable: merge_request, project: project) }
      let(:target) { note_on_merge_request }

      it { expect(event.visible_to_user?(non_member)).to eq true }
      it { expect(event.visible_to_user?(author)).to eq true }
      it { expect(event.visible_to_user?(assignee)).to eq true }
      it { expect(event.visible_to_user?(member)).to eq true }
      it { expect(event.visible_to_user?(guest)).to eq true }
      it { expect(event.visible_to_user?(admin)).to eq true }
    end
  end

  describe '.limit_recent' do
    let!(:event1) { create(:closed_issue_event) }
    let!(:event2) { create(:closed_issue_event) }

    describe 'without an explicit limit' do
      subject { Event.limit_recent }

      it { is_expected.to eq([event2, event1]) }
    end

    describe 'with an explicit limit' do
      subject { Event.limit_recent(1) }

      it { is_expected.to eq([event2]) }
    end
  end

  describe '#reset_project_activity' do
    let(:project) { create(:empty_project) }

    context 'when a project was updated less than 1 hour ago' do
      it 'does not update the project' do
        project.update(last_activity_at: Time.now)

        expect(project).not_to receive(:update_column).
          with(:last_activity_at, a_kind_of(Time))

        create_event(project, project.owner)
      end
    end

    context 'when a project was updated more than 1 hour ago' do
      it 'updates the project' do
        project.update(last_activity_at: 1.year.ago)

        expect_any_instance_of(Gitlab::ExclusiveLease).
          to receive(:try_obtain).and_return(true)

        expect(project).to receive(:update_column).
          with(:last_activity_at, a_kind_of(Time))

        create_event(project, project.owner)
      end
    end
  end

  describe '.flush_redis_keys' do
    before do
      Rails.cache.clear
    end

    after do
      Rails.cache.clear
    end

    it 'flushes the Redis keys for the given collection' do
      project = create(:empty_project)
      note = create(:note, author: project.owner, project: project)
      settings = Gitlab::CurrentSettings.current_application_settings

      2.times do
        event = create(:event,
               project: project,
               author: project.owner,
               target_id: note.id,
               target_type: 'Note')

        Rails.cache.fetch([event, settings, Event::CACHE_VERSION]) { 'foo' }
      end

      collection = Event.all

      collection.flush_redis_keys

      collection.each do |event|
        expect(Rails.cache.fetch([event, settings, Event::CACHE_VERSION])).
          to be_nil
      end
    end
  end

  describe '.reset_event_cache_for' do
    it 'flushes the cache keys for a given target' do
      project = create(:empty_project)
      note = create(:note, author: project.owner, project: project)

      expect(described_class).to receive(:flush_redis_keys)

      described_class.reset_event_cache_for(note)
    end
  end

  def create_event(project, user, attrs = {})
    data = {
      before: Gitlab::Git::BLANK_SHA,
      after: "0220c11b9a3e6c69dc8fd35321254ca9a7b98f7e",
      ref: "refs/heads/master",
      user_id: user.id,
      user_name: user.name,
      repository: {
        name: project.name,
        url: "localhost/rubinius",
        description: "",
        homepage: "localhost/rubinius",
        private: true
      }
    }

    Event.create({
      project: project,
      action: Event::PUSHED,
      data: data,
      author_id: user.id
    }.merge(attrs))
  end
end
