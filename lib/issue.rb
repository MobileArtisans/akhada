class Issue
  attr_reader :key, :summary, :assignee, :status

  def initialize(key, summary, assignee, status)
    @key = key
    @summary = summary
    @assignee = assignee
    @status = status
  end
end
