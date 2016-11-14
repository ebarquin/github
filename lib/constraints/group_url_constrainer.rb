class GroupUrlConstrainer
  def matches?(request)
    id = request.params[:id]

    if NamespaceValidator::RESERVED.include?(id)
      return false
    end

    Group.find_by(path: id).present?
  end
end
