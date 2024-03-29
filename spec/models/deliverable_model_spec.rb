require 'spec_helper'

describe Deliverable do

  it 'can be created' do
    lambda {
      Factory(:deliverable)
    }.should change(Deliverable, :count).by(1)
  end

  context "is not valid" do

    [:course, :creator].each do |attr|
      it "without #{attr}" do
        subject.should_not be_valid
        subject.errors[attr].should_not be_empty
      end
    end

    context "when a duplicate deliverable for the same course, task and owner" do
      [:team_deliverable, :individual_deliverable].each do |symbol|
        it "for a team/individual deliverable" do
          original = Factory.build(symbol)
          original.stub(:update_team)
          original.save
          duplicate = Deliverable.new()
          duplicate.stub(:update_team)
          duplicate.creator_id = original.creator_id
          duplicate.course = original.course
          duplicate.task_number = original.task_number
          duplicate.is_team_deliverable = original.is_team_deliverable
          duplicate.team_id = original.team_id
          duplicate.should_not be_valid
        end
      end
    end
  end

  it "should return team name for a team deliverable" do
    deliverable = Factory.build(:team_deliverable)
    deliverable.stub(:update_team)
    deliverable.save
    deliverable.owner_name.should be_equal(deliverable.team.name)
  end

    it "should return person name for a individual deliverable" do
    deliverable = Factory(:individual_deliverable)
    deliverable.owner_name.should be_equal(deliverable.creator.human_name)
  end
  
  it "should return team email for a team deliverable" do
    deliverable = Factory.build(:team_deliverable)
    deliverable.stub(:update_team)
    deliverable.save
    deliverable.owner_email.should be_equal(deliverable.team.email)
  end

  it "should return person email for a individual deliverable" do
    deliverable = Factory(:individual_deliverable)
    deliverable.owner_email.should be_equal(deliverable.creator.email)
  end
  
  it "should not have a team name for an individual deliverable" do
	deliverable = Factory(:individual_deliverable)
	deliverable.team_id.should == nil
  end
  
  it "team deliverable creator should be Sam" do
	team_deliverable = Factory.build(:team_deliverable)
	team_deliverable.stub(:update_team)
	team_deliverable.save
	team_deliverable.creator.human_name.should == "Student Sam"
  end
  
  it "should return a list of team deliverables and individual deliverables" do
     @teams = Team.all
	 @student = Factory(:student_raj)
     @deliverables = Deliverable.find_by_person_and_teams(@student,@teams)
	 @deliverables.size.should >= 0
  end
  
  it "should return current deliverables for Sam" do
	@student = Factory(:student_sam)
	deliverable = Deliverable.find_current_by_person(@student)
	deliverable.size.should > 0
  end
  
  it "should return past deliverables for Raj" do
	student = Factory(:student_raj)
	deliverable = Deliverable.find_past_by_person(student)
	deliverable.size.should == 0
  end
  
  it "should submit notification email to faculty with task number" do
	@student = Factory.build(:student_sam)
	@deliverable = Factory.build(:individual_deliverable)
	@deliverable.stub(:task_number => 1)
	@deliverable.send_deliverable_upload_email("http://rails.sv.cmu.edu")
  end
  
  it "should submit email with course name" do
	@student = Factory.build(:student_sam)
	@course = Factory.build(:fse)
	@deliverable = Factory.build(:team_deliverable)
	@deliverable.stub(:course => @course)
	@deliverable.send_deliverable_upload_email("http://rails.sv.cmu.edu")
  end
    
  it "should receive feedback email with task number" do
	@student = Factory.build(:student_sam)
	@deliverable = Factory.build(:individual_deliverable)
	@deliverable.stub(:task_number => 1)
	@deliverable.send_deliverable_feedback_email("http://rails.sv.cmu.edu")
  end
  
  it "should receive feedback email with course name" do
	@student = Factory.build(:student_sam)
	@course = Factory.build(:fse)
	@deliverable = Factory.build(:individual_deliverable)
	@deliverable.stub(:course => @course)
	@deliverable.send_deliverable_feedback_email("http://rails.sv.cmu.edu")
	#with(hash_including(:message => "Feedback has been submitted for Foundations"))
  end


  context "has_feedback?" do
  it "returns false when there is no feedback" do
    subject.has_feedback?.should be_false

#!(self.feedback_comment.nil? or self.feedback_comment == "") or !self.feedback_file_name.nil?
  end

  it "returns true when there is a comment" do
    subject.feedback_comment = "Great job team!"
    subject.has_feedback?.should be_true
  end

  it "returns true when there is a file" do
    subject.feedback_file_name = "/somewhere_on_s3/somewhere_over_the_rainbow/amazing_feedback.txt"
    subject.has_feedback?.should be_true
  end
  
  end

  context "for a team" do
    before(:each) do
      @deliverable = Factory.build(:team_deliverable)
      @team_member = @deliverable.team.people[0]
    end

    it "is not editable by any random student" do
      @deliverable.editable?(Factory(:student_sally)).should be_false
    end

    it "is editable by staff or admin" do
      @deliverable.editable?(Factory(:faculty_frank)).should be_true
     end

    it "is editable by a team member" do
      @deliverable.editable?(@team_member).should be_true
    end
	
	it "is okay for team deliverable to have blank name" do
	  @deliverable.update_attribute(:name, nil)
	  @deliverable.should be_valid
    end
  end

  context "for an individual deliverable" do
    before(:each) do
      @deliverable = Factory.build(:individual_deliverable)
      @individual = @deliverable.creator
    end

    it "is not editable by any random student" do
      @deliverable.editable?(Factory(:student_sally)).should be_false
    end

    it "is editable by staff or admin" do
      @deliverable.editable?(Factory(:faculty_frank)).should be_true
     end

    it "is editable by its owner" do
      @deliverable.editable?(@individual).should be_true
    end
	
	it "is editable by staff member" do
	  @deliverable.editable?(Factory(:faculty_frank)).should be_true
	end
	
	it "is not editable by team member" do
		@deliverable.editable?(Factory(:student_raj)).should be_false
	end
	
	it "is okay for individual deliverable to have blank name" do
	  @deliverable.update_attribute(:name, nil)
	  @deliverable.should be_valid
    end
	
	it "Raj does not have a deliverable for past or current" do
		@raj = Factory(:student_raj)
		Deliverable.find_current_by_person(@raj).size.should == 0
		Deliverable.find_past_by_person(@raj).size.should == 0
	end
  end
  
end


