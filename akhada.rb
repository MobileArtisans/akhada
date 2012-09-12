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
    {:key => issue.key, :summary => issue.summary, :assignee => issue.assignee, :status => issue.status}.to_json
  end

end
