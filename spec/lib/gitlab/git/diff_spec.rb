require_relative "spec_helper"

describe Gitlab::Git::Diff do
  let(:repository) { Gitlab::Git::Repository.new(TEST_REPO_PATH) }

  before do
    @raw_diff_hash = {
      diff: <<EOT.gsub(/^ {8}/, "").sub(/\n$/, ""),
        --- a/.gitmodules
        +++ b/.gitmodules
        @@ -4,3 +4,6 @@
         [submodule "gitlab-shell"]
         \tpath = gitlab-shell
         \turl = https://github.com/gitlabhq/gitlab-shell.git
        +[submodule "gitlab-grack"]
        +	path = gitlab-grack
        +	url = https://gitlab.com/gitlab-org/gitlab-grack.git

EOT
      new_path: ".gitmodules",
      old_path: ".gitmodules",
      a_mode: '100644',
      b_mode: '100644',
      new_file: false,
      renamed_file: false,
      deleted_file: false,
      too_large: false
    }

    @rugged_diff = repository.rugged.diff("5937ac0a7beb003549fc5fd26fc247adbce4a52e^", "5937ac0a7beb003549fc5fd26fc247adbce4a52e", paths:
                                          [".gitmodules"]).patches.first
  end

  describe :new do
    context 'using a Hash' do
      context 'with a small diff' do
        let(:diff) { Gitlab::Git::Diff.new(@raw_diff_hash) }

        it 'initializes the diff' do
          expect(diff.to_hash).to eq(@raw_diff_hash)
        end

        it 'does not prune the diff' do
          expect(diff).not_to be_too_large
        end
      end

      context 'using a diff that is too large' do
        it 'prunes the diff' do
          diff = Gitlab::Git::Diff.new(diff: 'a' * 204800)

          expect(diff.diff).to be_empty
          expect(diff).to be_too_large
        end
      end
    end

    context 'using a Rugged::Patch' do
      context 'with a small diff' do
        let(:diff) { Gitlab::Git::Diff.new(@rugged_diff) }

        it 'initializes the diff' do
          expect(diff.to_hash).to eq(@raw_diff_hash.merge(too_large: nil))
        end

        it 'does not prune the diff' do
          expect(diff).not_to be_too_large
        end
      end

      context 'using a diff that is too large' do
        it 'prunes the diff' do
          expect_any_instance_of(String).to receive(:bytesize).
            and_return(1024 * 1024 * 1024)

          diff = Gitlab::Git::Diff.new(@rugged_diff)

          expect(diff.diff).to be_empty
          expect(diff).to be_too_large
        end
      end

      context 'using a collapsable diff that is too large' do
        before do
          # The patch total size is 200, with lines between 21 and 54.
          # This is a quick-and-dirty way to test this. Ideally, a new patch is
          # added to the test repo with a size that falls between the real limits.
          stub_const('Gitlab::Git::Diff::DIFF_SIZE_LIMIT', 150)
          stub_const('Gitlab::Git::Diff::DIFF_COLLAPSE_LIMIT', 100)
        end

        it 'prunes the diff as a large diff instead of as a collapsed diff' do
          diff = Gitlab::Git::Diff.new(@rugged_diff, collapse: true)

          expect(diff.diff).to be_empty
          expect(diff).to be_too_large
          expect(diff).not_to be_collapsed
        end
      end

      context 'using a large binary diff' do
        it 'does not prune the diff' do
          expect_any_instance_of(Rugged::Diff::Delta).to receive(:binary?).
            and_return(true)

          diff = Gitlab::Git::Diff.new(@rugged_diff)

          expect(diff.diff).not_to be_empty
        end
      end
    end
  end

  describe 'straight diffs' do
    let(:options) { { :straight => true } }
    let(:diffs) { Gitlab::Git::Diff.between(repository, 'feature', 'master', options) }
    subject { diffs }

    describe '#size' do
      subject { super().size }

      it { is_expected.to eq(24) }
    end

    context :diff do
      subject { diffs.first }

      it { should be_kind_of Gitlab::Git::Diff }
      its(:new_path) { should == '.DS_Store' }
      its(:diff) { should include 'Binary files /dev/null and b/.DS_Store differ' }
    end
  end

  describe :between do
    let(:diffs) { Gitlab::Git::Diff.between(repository, 'feature', 'master') }
    subject { diffs }

    it { is_expected.to be_kind_of Gitlab::Git::DiffCollection }

    describe '#size' do
      subject { super().size }

      it { is_expected.to eq(1) }
    end

    context :diff do
      subject { diffs.first }

      it { is_expected.to be_kind_of Gitlab::Git::Diff }

      describe '#new_path' do
        subject { super().new_path }

        it { is_expected.to eq('files/ruby/feature.rb') }
      end

      describe '#diff' do
        subject { super().diff }

        it { is_expected.to include '+class Feature' }
      end
    end
  end

  describe :filter_diff_options do
    let(:options) { { max_size: 100, invalid_opt: true } }

    context "without default options" do
      let(:filtered_options) { Gitlab::Git::Diff.filter_diff_options(options) }

      it "should filter invalid options" do
        expect(filtered_options).not_to have_key(:invalid_opt)
      end
    end

    context "with default options" do
      let(:filtered_options) do
        default_options = { max_size: 5, bad_opt: 1, ignore_whitespace: true }
        Gitlab::Git::Diff.filter_diff_options(options, default_options)
      end

      it "should filter invalid options" do
        expect(filtered_options).not_to have_key(:invalid_opt)
        expect(filtered_options).not_to have_key(:bad_opt)
      end

      it "should merge with default options" do
        expect(filtered_options).to have_key(:ignore_whitespace)
      end

      it "should override default options" do
        expect(filtered_options).to have_key(:max_size)
        expect(filtered_options[:max_size]).to eq(100)
      end
    end
  end

  describe :submodule? do
    before do
      commit = repository.lookup('5937ac0a7beb003549fc5fd26fc247adbce4a52e')
      @diffs = commit.parents[0].diff(commit).patches
    end

    it { expect(Gitlab::Git::Diff.new(@diffs[0]).submodule?).to eq(false) }
    it { expect(Gitlab::Git::Diff.new(@diffs[1]).submodule?).to eq(true) }
  end

  describe :line_count do
    subject { Gitlab::Git::Diff.new(@rugged_diff) }

    describe '#line_count' do
      subject { super().line_count }
      it { is_expected.to eq(9) }
    end

    its(:line_count) { should eq(9) }
  end

  describe :too_large? do
    it 'returns true for a diff that is too large' do
      diff = Gitlab::Git::Diff.new(diff: 'a' * 204800)

      expect(diff.too_large?).to eq(true)
    end

    it 'returns false for a diff that is small enough' do
      diff = Gitlab::Git::Diff.new(diff: 'a')

      expect(diff.too_large?).to eq(false)
    end

    it 'returns true for a diff that was explicitly marked as being too large' do
      diff = Gitlab::Git::Diff.new(diff: 'a')

      diff.prune_large_diff!

      expect(diff.too_large?).to eq(true)
    end
  end

  describe :collapsed? do
    it 'returns false by default even on quite big diff' do
      diff = Gitlab::Git::Diff.new(diff: 'a' * 20480)

      expect(diff.collapsed?).to eq(false)
    end

    it 'returns false by default for a diff that is small enough' do
      diff = Gitlab::Git::Diff.new(diff: 'a')

      expect(diff.collapsed?).to eq(false)
    end

    it 'returns true for a diff that was explicitly marked as being collapsed' do
      diff = Gitlab::Git::Diff.new(diff: 'a')

      diff.prune_collapsed_diff!

      expect(diff.collapsed?).to eq(true)
    end
  end

  describe :collapsible? do
    it 'returns true for a diff that is quite large' do
      diff = Gitlab::Git::Diff.new(diff: 'a' * 20480)

      expect(diff.collapsible?).to eq(true)
    end

    it 'returns false for a diff that is small enough' do
      diff = Gitlab::Git::Diff.new(diff: 'a')

      expect(diff.collapsible?).to eq(false)
    end
  end

  describe :prune_collapsed_diff! do
    it 'prunes the diff' do
      diff = Gitlab::Git::Diff.new(diff: "foo\nbar")

      diff.prune_collapsed_diff!

      expect(diff.diff).to eq('')
      expect(diff.line_count).to eq(0)
    end
  end
end
