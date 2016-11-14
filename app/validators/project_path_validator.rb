# ProjectPathValidator
#
# Custom validator for GitLab project path values.
#
# Values are checked for exclusion from a list of reserved path names.
class ProjectPathValidator < ActiveModel::EachValidator
  RESERVED = (NamespaceValidator::RESERVED +
              %w[tree commits wikis new edit create update logs_tree
                 preview blob blame raw files create_dir find_file]).freeze

  def validate_each(record, attribute, value)
    if reserved?(value)
      record.errors.add(attribute, "#{value} is a reserved name")
    end
  end

  private

  def reserved?(value)
    RESERVED.include?(value)
  end
end
