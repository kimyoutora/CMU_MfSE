require 'spec_helper'

describe Team do

  it "should throw an error when a google distribution list was not created" do
    google_apps_connection.stub(:create_group)
    google_apps_connection.stub(:add_member_to_group)

    team = Factory.create(:team_triumphant)
    lambda { team.update_google_mailing_list("new", "old", 123) }.should raise_error()


  end

  it "should update google distribution list" do
    email_groups = %w(old_mailing_list@gmail.com new_mailing_list@gmail.com)
    team = Factory(:team_triumphant)
    google_apps_connection.stub(:retrieve_all_groups => email_groups, :delete_group => true, :create_group => true, :add_member_to_group => true, :retrieve_all_members => team.people.map(&:email).sort)

    
    lambda {
      team.update_google_mailing_list(email_groups[0], email_groups[1], team.id)
    }.should_not raise_exception
  end

  it 'can be created' do
    lambda {
      Factory(:team)
    }.should change(Team, :count).by(1)
  end

   it "should not be valid if missing course_id attributes" do
     team = Factory.ild(:team_triumphant, :course_id => nil)
     team.should_receive(:clean_up_data).once
     team.valid?.should == false
   end

   it "should not be valid if missing name attributes" do
     team = Factory.build(:team_triumphant, :name => nil)
     team.should_receive(:clean_up_data).once
     team.valid?.should == false
   end

   it "should return all faculty email addresses without duplicates" do
     team = Factory.create(:team_triumphant, :primary_faculty_id => 1, :secondary_faculty_id =>1)
     user = User.new(:email => "foo@bar.com")
     User.should_receive(:find_by_id).with(1).and_return(user)
     team.faculty_email_addresses.should == [user.email]
   end

   it "should return empty message if passed empty array of members" do
     team = Factory(:team_triumphant)
     team.update_members(nil).should == ""
   end

   it "should return error message if member being added is not found in DB" do
     team = Factory(:team_triumphant)
     nonexistent_user = User.new(:human_name => "asdfghjkl")
     existing_user = User.new(:human_name => "foobar")

     team.update_members(["foo bar", Person.first.human_name]).should_not be_empty
   end


  context "has peer evaluation date" do
    it "first email that is copied from the course's peer evaluation first email date if it exists" do
      course = Factory(:course, :peer_evaluation_first_email => Date.today)
      team = Factory(:team, :course_id => course.id)

      team.peer_evaluation_first_email.to_date.should == course.peer_evaluation_first_email
    end

    it "first email that is not overwritten if the faculty has already specified a peer evaluation date" do
      course = Factory(:course, :peer_evaluation_first_email => Date.today)
      team = Factory(:team, :course_id => course.id, :peer_evaluation_first_email => 4.hours.from_now)
      course.peer_evaluation_first_email = 1.day.ago
      team.save
      team.peer_evaluation_first_email == 4.hours.from_now
    end

    it "second email that is copied from the course's peer evaluation second email date if it exists" do
      course = Factory(:course, :peer_evaluation_second_email => Date.today)
      team = Factory(:team, :course_id => course.id)

      team.peer_evaluation_second_email.to_date.should == course.peer_evaluation_second_email
    end

    it "second email that is not overwritten if the faculty has already specified a peer evaluation date" do
      course = Factory(:course, :peer_evaluation_second_email => Date.today)
      team = Factory(:team, :course_id => course.id, :peer_evaluation_second_email => 4.hours.from_now)
      course.peer_evaluation_second_email = 1.day.ago
      team.save
      team.peer_evaluation_second_email == 4.hours.from_now
    end


  end

  context "is_person_on_team?" do

   before do
      @faculty_frank = Factory(:faculty_frank)
      @student_sam = Factory(:student_sam)
      @student_sally = Factory(:student_sally)
      @course = Factory(:course, :configure_teams_name_themselves => false)
      @team = Factory(:team, :course_id => @course.id, :name => "Dracula", :people => [@student_sam, @student_sally])
    end

    it "correctly determines whether a person is on the team" do
      @team.is_person_on_team?(@student_sam).should be_true
      @team.is_person_on_team?(@student_sally).should be_true
      @team.is_person_on_team?(@faculty_frank).should be_false
    end
  end

  context "when finding the team a person belongs to" do
    describe "#find_by_person" do
      before(:each) do
        @person = Factory.build(:person)
        @person.stub!(:person_before_save)
        @person.save
      end

      it "should return the person's teams" do
        teams = Team.find_by_person(@person)
        teams.should == @person.teams
      end
    end
  end

  context "when deleting this team " do
    describe "#remove_google_group" do
      it "should log the exception" do
        team = Factory(:team_triumphant)
        google_apps_connection.stub(:delete_group).and_raise(GDataError)
        Rails.logger.should_receive(:error).once
        team.destroy
      end
    end
  end

end
