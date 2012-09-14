class Issue
  attr_reader :key, :summary, :assignee, :status, :transitions

  def initialize(key, summary, assignee, status, transitions)
    @key = key
    @summary = summary
    @assignee = assignee
    @status = status
    @transitions = transitions
  end

  def to_json
    {
      :key => @key,
      :summary => @summary,
      :assignee => @assignee,
      :status => @status,
      :transitions => @transitions
    }.to_json
  end
end
