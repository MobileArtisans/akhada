require 'spec_helper'

describe JiraClient do
  let(:client) {
    JiraClient.new('user', 'password', 'http://localhost')
  }

  it "should search by issue id" do
    stub_issue = stub(:parsed_response => jira_issue("TEST-1", "issue summary", "bob", "Open"), :code => 200)
    HTTParty.should_receive(:get).with("http://localhost/rest/api/2/issue/TEST-1", :basic_auth => {:username => 'user', :password => 'password'}).and_return(stub_issue)
    HTTParty.should_receive(:get).with("http://localhost/rest/api/2/issue/TEST-1/transitions", :basic_auth => {:username => 'user', :password => 'password'}).and_return(stub(:parsed_response => transitions))

    issue = client.issue_by_id("TEST-1")

    issue.key.should == "TEST-1"
    issue.summary.should == "issue summary"
    issue.status.should == "Open"
    issue.assignee.should == "bob"
    issue.transitions.should == [{:id => 1, :name => "Accepted"}, {:id => 2, :name => "Rejected"}]
  end

  it "should raise error if issue with given key does not exist" do
    stub_issue = stub(:code => 404)
    HTTParty.should_receive(:get).with("http://localhost/rest/api/2/issue/TEST-1",
                                       :basic_auth => {:username => 'user', :password => 'password'}
                                       ).and_return(stub_issue)

    expect { client.issue_by_id("TEST-1") }.to raise_error NotFoundError
  end

  it "should raise error if given credentials are invalid" do
    HTTParty.should_receive(:get).with("http://localhost/rest/api/2/issue/TEST-1",
                                       :basic_auth => {:username => 'user', :password => 'password'}
                                       ).and_return(stub(:code => 401))

    expect {client.issue_by_id("TEST-1")}.to raise_error AuthError
  end

  it "should transition the issue to given state" do
    HTTParty.should_receive(:post).with("http://localhost/rest/api/2/issue/TEST-1/transitions",
                                        :basic_auth => {:username => 'user', :password => 'password'},
                                        :body => {:transition => {:id => "2"}}.to_json,
                                        :headers => {"Content-Type"=>"application/json"}).and_return(stub(:parsed_response => nil,:code => 200))

    client.transition_issue('TEST-1', "2")
  end

  it "should return a list of assignable users to a given issue" do
    HTTParty.should_receive(:get).with("http://localhost/rest/api/2/user/assignable/search",
                                       :query => {:issueKey => "TEST-1"},
                                       :basic_auth => {:username => 'user', :password => 'password'}
                                       ).and_return(stub(:parsed_response => assignable_users))

    response = client.assignable_users("TEST-1")

    response[:users][0][:name].should == "alpha"
    response[:users][0][:displayName].should == "Alpha User"
    response[:users][1][:name].should == "beta"
    response[:users][1][:displayName].should == "Beta User"
  end

  def transitions
    {
      "transitions" => [
        {
          "id" => 1,
          "name" => "Accepted"
        },
        {
          "id" => 2,
          "name" => "Rejected"
        }
      ]
    }
  end

  def jira_issue(key, summary, assignee, status)
    {
      "key" => key,
      "fields" => {
        "summary" => summary,
        "assignee" => {
          "name" => assignee
        },
        "status" => {
          "name" => status
        }
      }
    }
  end

  def assignable_users
    [
     {
       "name" => "alpha",
       "displayName" => "Alpha User"
     },
     {
       "name" => "beta",
       "displayName" => "Beta User"
     }
    ]
  end

end
