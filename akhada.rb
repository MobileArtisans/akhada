require 'sinatra/base'
require "sinatra/config_file"
require 'json'

class Akhada < Sinatra::Base
  register Sinatra::ConfigFile
  set :show_exceptions, :after_handler

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

  error NotFoundError do
    halt 404
  end

  error AuthError do
    halt 401
  end

  get '/' do
    "Welcome to the chaos !"
  end

  get '/:site/projects' do
    protected!
    url = settings.protocol + params[:site]
    client = JiraClient.new(@username, @password, url)
    projects = client.projects
    content_type :json
    projects.to_json
  end

  get '/:site/issue/:id' do
    protected!
    url = settings.protocol + params[:site]
    client = JiraClient.new(@username, @password, url)
    render_issue(client, params[:id])
  end

  post '/:site/issue/:id/transition' do
    protected!
    url = settings.protocol + params[:site]
    client = JiraClient.new(@username, @password, url)
    body = JSON.parse(request.body.read)
    content_type :json
    client.transition_issue(params[:id], body["transition_id"]).to_json
    render_issue(client, params[:id])
  end

  get '/:site/issue/:id/assignable' do
    protected!
    url = settings.protocol + params[:site]
    client = JiraClient.new(@username, @password, url)
    users = client.assignable_users(params[:id])
    content_type :json
    users.to_json
  end

  put '/:site/issue/:id/assignee' do
    protected!
    url = settings.protocol + params[:site]
    client = JiraClient.new(@username, @password, url)
    body = JSON.parse(request.body.read)
    client.assign_user(params[:id], body["name"])
    render_issue(client, params[:id])
  end

  def render_issue(client, id)
    issue = client.issue_by_id(id)
    content_type :json
    issue.to_json
  end
end
