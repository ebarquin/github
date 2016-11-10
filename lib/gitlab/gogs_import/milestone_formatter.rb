module Gitlab
  module GogsImport
    class MilestoneFormatter < BaseFormatter
      def self.iid_attr
        :id
      end
    end
  end
end
