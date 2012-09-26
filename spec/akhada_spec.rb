require 'spec_helper'
require './akhada'
require 'rack/test'

set :environment, :test

describe 'Akhada' do
  include Rack::Test::Methods

  def app
    Akhada
  end

  def issue(key)
    Issue.new(key, "summary", "assignee", "Open", [{"id" => "2", "name" => "Closed"}])
  end

  def issue_as_json key
    {
      :key => key,
      :summary => "summary",
      :assignee => "assignee",
      :status => "Open",
      :transitions => [{"id" => "2", "name" => "Closed"}]
    }.to_json
  end

  it "should say welcome" do
    get '/'

    last_response.should be_ok
    last_response.body.should == 'Welcome to the chaos !'
  end

  context "get issue" do

    it "should not authorize without credentials" do
      get '/my.jira.com/issue/TEST-1234'

      last_response.status.should == 401
      last_response.body.should == "Not authorized\n"
    end

    it "should authorize for correct credentials and return requested issue attributes json" do
      authorize 'admin', 'admin'

      key = 'TEST-1234'
      JiraClient.stub_chain(:new, :issue_by_id).and_return(issue(key))

      get '/somesite/issue/TEST-1234'

      last_response.status.should == 200
      last_response.body.should == issue_as_json(key)
    end
    it "should return a 404 for invalid issue id" do
      authorize 'admin', 'admin'

      key = 'some-1234'
      JiraClient.stub_chain(:new, :issue_by_id).and_raise NotFoundError

      get '/somesite/issue/TEST-1234'

      last_response.status.should == 404
    end

    it "should return a 401 response for AuthError due to invalid credentials" do
      authorize "bad", "user"
      key = "some-1233"
      JiraClient.stub_chain(:new, :issue_by_id).and_raise AuthError

      get '/somesite/issue/some-1233'

      last_response.status.should == 401
    end

  end

  context "transition a issue" do

    it "should not authorize without credentials" do
      post '/my.jira.com/issue/TEST-1234/transition'

      last_response.status.should == 401
      last_response.body.should == "Not authorized\n"
    end

    it "should authorize and transition to a given possible state" do
      authorize 'admin', 'admin'

      transitions = {:transitions => [{"id" => 3, "name" => "Accepted"}]}
      JiraClient.stub_chain(:new, :transition_issue).and_return(transitions)
      JiraClient.stub_chain(:new, :issue_by_id).and_return(issue("TEST-1234"))

      post '/my.jira.com/issue/TEST-1234/transition', {:transition_id => "2"}.to_json

      last_response.status.should == 200
      last_response.body.should == issue_as_json("TEST-1234")
    end

  end

  context "get projects" do

    it "should not authorize without credentials" do
      get '/my.jira.com/projects'

      last_response.status.should == 401
      last_response.body.should == "Not authorized\n"
    end

    it "should authorize and return a list of valid users" do
      authorize 'admin', 'admin'

      projects = ["TEST", "DEV"]
      JiraClient.stub_chain(:new, :projects).and_return(projects)

      get '/my.jira.com/projects'

      last_response.status.should == 200
      last_response.body.should == projects.to_json
    end

  end

  context "get users" do

    it "should not authorize without credentials" do
      get '/my.jira.com/issue/TEST-1234/assignable'

      last_response.status.should == 401
      last_response.body.should == "Not authorized\n"
    end

    it "should authorize and return a list of valid users" do
      authorize 'admin', 'admin'

      users = {:users => [{"name" => "user", "displayName" => "Test User"}]}
      JiraClient.stub_chain(:new, :assignable_users).and_return(users)

      get '/my.jira.com/issue/TEST-1234/assignable'

      last_response.status.should == 200
      last_response.body.should == users.to_json
    end

  end

  context "set assignee" do

    it "should not authorize without credentials" do
      put '/my.jira.com/issue/TEST-1234/assignee'

      last_response.status.should == 401
      last_response.body.should == "Not authorized\n"
    end

    it "should authorize and set the assignee for an issue" do
      authorize 'admin', 'admin'

      JiraClient.stub_chain(:new, :assign_user)
      JiraClient.stub_chain(:new, :issue_by_id).and_return(issue("TEST-1234"))

      put '/my.jira.com/issue/TEST-1234/assignee', {:name => "user"}.to_json

      last_response.status.should == 200
      last_response.body.should == issue_as_json("TEST-1234")
    end

  end

end
