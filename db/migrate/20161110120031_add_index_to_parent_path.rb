# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddIndexToParentPath < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def change
    add_concurrent_index(:namespaces, :parent_path)
    add_concurrent_index(:namespaces, [:parent_path, :path], unique: true)
  end
end
