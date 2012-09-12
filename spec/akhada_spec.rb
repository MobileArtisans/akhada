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

  it "should not authorize without credentials" do
    get '/issue/TEST-1234'

    last_response.status.should == 401
    last_response.body.should == "Not authorized\n"
  end

  it "should not authorize with bad credentials" do
    authorize 'wrong', 'creds'

    get '/issue/TEST-1234'

    last_response.status.should == 401
  end

  it "should authorize for correct credentials and return requested issue attributes json" do
    authorize 'admin', 'admin'

    key = 'TEST-1234'
    issue = Issue.new(key, "summary", "assignee", "Open")
    JiraClient.stub_chain(:new, :issue_by_id).and_return(issue)

    get '/issue/TEST-1234'

    last_response.status.should == 200
    last_response.body.should == {:key => "TEST-1234", :summary => "summary", :assignee => "assignee", :status => "Open"}.to_json
  end

end
