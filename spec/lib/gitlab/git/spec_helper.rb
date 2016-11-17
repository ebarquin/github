require "spec_helper"

if ENV['TRAVIS']
  require 'coveralls'
  Coveralls.wear!
else
  require 'simplecov'
  SimpleCov.start
end

require 'pry'
require 'rspec/its'

require_relative 'support/seed_helper'
require_relative 'support/commit'
require_relative 'support/empty_commit'
require_relative 'support/encoding_commit'
require_relative 'support/first_commit'
require_relative 'support/last_commit'
require_relative 'support/big_commit'
require_relative 'support/ruby_blob'
require_relative 'support/repo'

RSpec::Matchers.define :be_valid_commit do
  match do |actual|
    actual &&
      actual.id == SeedRepo::Commit::ID &&
      actual.message == SeedRepo::Commit::MESSAGE &&
      actual.author_name == SeedRepo::Commit::AUTHOR_FULL_NAME
  end
end

GITLAB_GIT_SUPPORT_PATH = File.join(File.expand_path(File.dirname(__FILE__)), '../../../../tmp/gitlab_git_tests')
TEST_REPO_PATH = File.join(GITLAB_GIT_SUPPORT_PATH, 'gitlab-git-test.git')
TEST_NORMAL_REPO_PATH = File.join(GITLAB_GIT_SUPPORT_PATH, "not-bare-repo.git")
TEST_MUTABLE_REPO_PATH = File.join(GITLAB_GIT_SUPPORT_PATH, "mutable-repo.git")
TEST_BROKEN_REPO_PATH = File.join(GITLAB_GIT_SUPPORT_PATH, "broken-repo.git")

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.order = 'random'
  config.include SeedHelper
  config.before(:all) { ensure_seeds }
end
