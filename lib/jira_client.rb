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
    response = HTTParty.get(@base_uri + "/rest/api/2/issue/#{issue_id}", :basic_auth => auth)
    issue = get_parsed_response(response)
    Issue.new(issue["key"], issue["fields"]["summary"], issue["fields"]["assignee"]["name"], issue["fields"]["status"]["name"], transitions(issue_id))
  end

  def transition_issue(issue_id, transition_id)
    response = HTTParty.post(@base_uri + "/rest/api/2/issue/#{issue_id}/transitions",
                             :basic_auth => auth,
                             :body => {:transition => {:id => transition_id}}.to_json,
                             :headers => {'Content-Type' => 'application/json'})
    get_parsed_response(response)
  end

  def assignable_users(issue_id)
    response = HTTParty.get(@base_uri + "/rest/api/2/user/assignable/search",
                            :query => {:issueKey => issue_id},
                            :basic_auth => auth).parsed_response

    users = response.collect {|value| {:name => value["name"], :displayName => value["displayName"]} }
    {:users => users}
  end

  def assign_user(issue_id, name)
    HTTParty.put(@base_uri + "/rest/api/2/issue/#{issue_id}/assignee",
                 :basic_auth => auth,
                 :body => {:name => name},
                 :headers => {'Content-Type' => 'application/json'})
  end

  private

  def transitions(issue_id)
    response = HTTParty.get(@base_uri + "/rest/api/2/issue/#{issue_id}/transitions", :basic_auth => auth).parsed_response
    response["transitions"].collect {|value| {:id => value["id"], :name => value["name"]} }
  end

  def get_parsed_response response
    raise NotFoundError if response.code == 404
    raise AuthError if response.code == 401
    response.parsed_response
  end

end

class AuthError < Exception
end

class NotFoundError < Exception
end
