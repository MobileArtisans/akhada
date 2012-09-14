require 'sinatra/base'
require "sinatra/config_file"

class Akhada < Sinatra::Base
  register Sinatra::ConfigFile

  config_file './config.yml'

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

  get '/:site/issue/:id' do
    protected!
    url = settings.protocol + params[:site]
    client = JiraClient.new(@username, @password)
    issue = client.issue_by_id(url, params[:id])
    { :key => issue.key,
      :summary => issue.summary,
      :assignee => issue.assignee,
      :status => issue.status
    }.merge(client.transitions(url, params[:id])).to_json
  end

end
