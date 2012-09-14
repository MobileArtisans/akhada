require 'spec_helper'

describe JiraClient do 
  let(:client) {
    JiraClient.new('user', 'password')
  }

  it "should search by issue id" do
    stub_issue = stub(:parsed_response => jira_issue("TEST-1", "issue summary", "bob", "Open"))
    jira = HTTParty.should_receive(:get).with("localhost/rest/api/2/issue/TEST-1", :basic_auth => {:username => 'user', :password => 'password'}).and_return(stub_issue)

    issue = client.issue_by_id("localhost", "TEST-1")
    issue.key.should == "TEST-1"
    issue.summary.should == "issue summary"
    issue.status.should == "Open"
    issue.assignee.should == "bob"
  end

  it "should return transitions" do
    stub_issue = stub(:parsed_response => transitions("TEST-1"))
    jira = HTTParty.should_receive(:get).with("localhost/rest/api/2/issue/TEST-1/transitions", :basic_auth => {:username => 'user', :password => 'password'}).and_return(stub_issue)

    transitions = client.transitions("localhost", "TEST-1")

    transitions.should == {:transitions => [{:id => 1, :name => "Accepted"}, {:id => 2, :name => "Rejected"}] }
  end

  def transitions(key)
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
end
