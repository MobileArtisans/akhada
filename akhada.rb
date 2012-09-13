require 'sinatra/base'

class Akhada < Sinatra::Base

  helpers do
    def protected!
      unless authorized?
        response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
        throw(:halt, [401, "Not authorized\n"])
      end
    end

    def authorized?
      @auth ||=  Rack::Auth::Basic::Request.new(request.env)
      return false unless @auth.provided?
      @username, @password = @auth.credentials
    end
  end

  get '/' do
    "Welcome to the chaos !"
  end

  get '/issue/:id' do
    protected!
    issue = JiraClient.new(@username, @password).issue_by_id(params[:id])
    { :key => issue.key,
      :summary => issue.summary,
      :assignee => issue.assignee,
      :status => issue.status
    }.merge(transitions(params[:id])).to_json
  end

  def transitions(id)
    auth = {:username => @username, :password => @password}
    response = HTTParty.get("http://localhost:2990/jira/rest/api/2/issue/#{id}/transitions", :basic_auth => auth).parsed_response
    transitions = response["transitions"].inject([]) {|states, value| states << {:id => value["id"], :name => value["name"]}}
    {:transitions => transitions}
  end

end
