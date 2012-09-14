require 'spec_helper'
require './akhada'
require 'rack/test'

set :environment, :test

describe 'Akhada' do
  include Rack::Test::Methods

  def app
    Akhada
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
      issue = Issue.new(key, "summary", "assignee", "Open", [{"id" => "2", "name" => "Closed"}])
      JiraClient.stub_chain(:new, :issue_by_id).and_return(issue)

      expected_response_body = {
        :key => "TEST-1234",
        :summary => "summary",
        :assignee => "assignee",
        :status => "Open",
        :transitions => [{"id" => "2", "name" => "Closed"}]
      }.to_json

      get '/somesite/issue/TEST-1234'

      last_response.status.should == 200
      last_response.body.should == expected_response_body
    end

  end

end
