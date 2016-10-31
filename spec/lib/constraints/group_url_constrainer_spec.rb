require 'spec_helper'

describe GroupUrlConstrainer, lib: true do
  let!(:group) { create(:group, path: 'gitlab') }

  describe '#matches?' do
    context 'root group' do
      it { expect(subject.matches?(request '/gitlab')).to be_truthy }
      it { expect(subject.matches?(request '/gitlab.atom')).to be_truthy }
      it { expect(subject.matches?(request '/gitlab/edit')).to be_falsey }
      it { expect(subject.matches?(request '/gitlab-ce')).to be_falsey }
      it { expect(subject.matches?(request '/.gitlab')).to be_falsey }
    end

    context 'nested group' do
      let!(:nested_group) { create(:group, path: 'nested', parent_path: 'gitlab') }

      it { expect(subject.matches?(request '/gitlab/nested')).to be_truthy }
      it { expect(subject.matches?(request '/gitlab/nested/edit')).to be_falsey }
      it { expect(subject.matches?(request '/gitlab/edit')).to be_falsey }
    end
  end

  def request(path)
    double(:request, path: path)
  end
end
