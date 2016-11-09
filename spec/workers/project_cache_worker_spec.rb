require 'spec_helper'

describe ProjectCacheWorker do
  let(:project) { create(:project) }
  let(:worker) { described_class.new }

  describe '.perform_async' do
    it 'schedules the job when no lease exists' do
      allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:exists?).
        and_return(false)

      expect_any_instance_of(described_class).to receive(:perform)

      described_class.perform_async(project.id)
    end

    it 'does not schedule the job when a lease exists' do
      allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:exists?).
        and_return(true)

      expect_any_instance_of(described_class).not_to receive(:perform)

      described_class.perform_async(project.id)
    end
  end

  describe '#perform' do
    context 'when an exclusive lease can be obtained' do
      before do
        allow(worker).to receive(:try_obtain_lease_for).with(project.id).
          and_return(true)
      end

      it 'updates the caches' do
        expect(worker).to receive(:update_caches).with(project.id, %i(readme))

        worker.perform(project.id, %i(readme))
      end
    end

    context 'when an exclusive lease can not be obtained' do
      it 'does nothing' do
        allow(worker).to receive(:try_obtain_lease_for).with(project.id).
          and_return(false)

        expect(worker).not_to receive(:update_caches)

        worker.perform(project.id)
      end
    end
  end

  describe '#update_caches' do
    context 'using a non-existing repository' do
      it 'does nothing' do
        allow_any_instance_of(Repository).to receive(:exists?).and_return(false)

        expect_any_instance_of(Project).not_to receive(:update_repository_size)

        worker.update_caches(project.id)
      end
    end

    context 'using an existing repository' do
      it 'updates the repository size' do
        expect_any_instance_of(Project).to receive(:update_repository_size)

        worker.update_caches(project.id)
      end

      it 'updates the commit count' do
        expect_any_instance_of(Project).to receive(:update_commit_count)

        worker.update_caches(project.id)
      end

      it 'updates method caches' do
        expect_any_instance_of(Repository).to receive(:refresh_method_caches).
          with(%i(readme))

        worker.update_caches(project.id, %i(readme))
      end
    end
  end
end
