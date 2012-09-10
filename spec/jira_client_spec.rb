require 'spec_helper'

describe JiraClient do 
  let(:client) {
    JiraClient.new('user', 'password')
  }

  it "should search by issue id" do
    jira = mock('jira::client')
    mock_issue = mock("jira::issue")
    mock_issue.stub(:key).and_return("TEST-1")
    jira.stub_chain("Issue.jql").and_return([mock_issue])
    JIRA::Client.should_receive(:new).and_return(jira)

    issue = client.issue_by_id("TEST-1")
    issue.key.should == "TEST-1"
  end
end
