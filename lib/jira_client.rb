class JiraClient
  def initialize(username, password)
    @client = JIRA::Client.new({
      :username => username,
      :password => password,
      :site => 'https://bawall.atlassian.net',
      :context_path => '',
      :auth_type => :basic})
  end

  def issue_by_id(id)
    issue = @client.Issue.jql("issueKey='#{id}'").first
    Issue.new(issue.key, issue.summary, issue.assignee.name, issue.status.name)
  end
end
