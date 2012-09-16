class JiraClient

  def initialize(username, password, base_uri)
    @username = username
    @password = password
    @base_uri = base_uri
  end

  def auth
    { :username => @username, :password => @password }
  end

  def issue_by_id(issue_id)
    issue = HTTParty.get(@base_uri + "/rest/api/2/issue/#{issue_id}", :basic_auth => auth).parsed_response
    Issue.new(issue["key"], issue["fields"]["summary"], issue["fields"]["assignee"]["name"], issue["fields"]["status"]["name"], transitions(issue_id))
  end

  def transition_issue(issue_id, transition_id)
    options = {:basic_auth => auth, :body => {:transition => {:id => transition_id}}, :headers => {'Content-Type' => 'application/json'}}
    response = HTTParty.post(@base_uri + "/rest/api/2/issue/#{issue_id}/transitions",
                             :basic_auth => auth,
                             :body => {:transition => {:id => transition_id}},
                             :headers => {'Content-Type' => 'application/json'})
    {:transitions => transitions(issue_id)}
  end

  private

  def transitions(issue_id)
    response = HTTParty.get(@base_uri + "/rest/api/2/issue/#{issue_id}/transitions", :basic_auth => auth).parsed_response
    response["transitions"].collect {|value| {:id => value["id"], :name => value["name"]} }
  end

end
