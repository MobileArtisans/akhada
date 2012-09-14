class JiraClient

  def initialize(username, password)
    @username = username
    @password = password
  end

  def issue_by_id(url, id)
    auth = {:username => @username, :password => @password}
    issue = HTTParty.get(url + "/rest/api/2/issue/#{id}", :basic_auth => auth).parsed_response

    Issue.new(issue["key"], issue["fields"]["summary"], issue["fields"]["assignee"]["name"], issue["fields"]["status"]["name"])
  end

  def transitions(url, id)
    auth = {:username => @username, :password => @password}

    response = HTTParty.get(url + "/rest/api/2/issue/#{id}/transitions", :basic_auth => auth).parsed_response

    transitions = response["transitions"].inject([]) {|states, value| states << {:id => value["id"], :name => value["name"]}}
    {:transitions => transitions}
  end

end
