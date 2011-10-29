require 'spec_helper'
require 'controllers/permission_behavior'

describe TeamsController do

  let(:course) { Factory(:course) }
  let(:team) { Factory(:team) }

  context "any user can" do
    before do
      login(Factory(:student_sam))
    end

    describe "GET show" do
      before do
        get :show, :id => team.to_param, :course_id => team.course.to_param
      end

      specify { assigns(:course).should == team.course }
      specify { assigns(:team).should == team }
    end


    describe "GET index of teams" do
      before do
        get :index_all
      end

      specify { assigns(:teams).should_not be_nil }
    end

    describe "GET index of teams for a particular course" do
      before do
        get :index, :course_id => course.to_param
      end

      specify { assigns(:teams).should_not be_nil }
      specify { assigns(:course).should == course }
    end

    describe "not GET new" do
      before do
        get :new, :course_id => course.to_param
      end

      it_should_behave_like "permission denied"
    end


    describe "not POST create" do
      before do
        @team = Factory.build(:team)
        post :create, :team => @team.attributes
      end

      it_should_behave_like "permission denied"
    end

    describe "not PUT update" do
      before do
        put :update, :id => team.to_param, :course_id => team.course.to_param, :team => {:name => 'NNNNN'}
        @redirect_url = course_team_path(team.course, team)
      end

      it_should_behave_like "permission denied"
    end

    describe "not DELETE destroy" do
      before do
        delete :destroy, :id => team.to_param
        @redirect_url = teams_path
      end

      it_should_behave_like "permission denied"
    end

    describe "#twiki_new" do
      it "should redirect to something reasonable and not raise exception" do
        controller.stub(:get_twiki_http_referer => "http://info.sv.cmu.edu/twiki/bin/view/Fall2008/Foundations/StudentTeams
")
        lambda {
          get :twiki_new
        }.should_not raise_exception
      end

      it "should be able to create the new course" do
        course = Factory.create(:course, :twiki_url => "http://info.sv.cmu.edu/twiki/bin/view/Fall2008/Foundations/StudentTeams")
        controller.stub(:get_twiki_http_referer => course.twiki_url)
        Course.should_receive(:find).and_return(course)

        get :twiki_new
        assigns(:course).should_not be_nil
      end
    end


    describe "#remove_team_member" do
      it "should be success" do
        team = Factory.create(:team_triumphant)
        delete :remove_team_member, {:team_id => team.id}
        response.should be_success
      end
    end

    describe "#peer_evaluation" do
      it "should be success" do
        team = Factory.create(:team_triumphant)
        person = Factory.create(:person, :first_name => "foo", :last_name => "bar")
        team.stub(:people => [person])
        Team.should_receive(:find).with(team.id).and_return(team)

        get :peer_evaluation, {:course_id => team.course_id, :id => team.id}
        response.should be_success
      end
    end

    describe "#peer_evaluation_update" do
      it "should be success" do
        team=Factory.create(:team_triumphant)
        course = Factory.create(:course)
        team.stub(:course => course)
        Team.should_receive(:find).with(team.id).and_return(team)

        params = {
          :team => {
            :peer_evaluation_second_email => Time.now
          }
        }
        
        put :peer_evaluation_update, {:id => team.id}
        assigns(:team).should == team
        response.should be_success
      end
    end

  end

  context "any staff can" do
    before do
      login(Factory(:faculty_frank))
    end

    describe "GET new" do
      before do
        get :new, :course_id => team.course.to_param
      end

      specify { assigns(:course).should_not be_nil }
      specify { assigns(:team).should_not be_nil }
    end

    describe "GET edit" do
      before do
        get :edit, :id => team.to_param, :course_id => team.course.to_param
      end

      specify { assigns(:course).should == team.course }
      specify { assigns(:team).should == team }
    end

    describe "POST create" do

      describe "with valid params" do
        before(:each) do
          @team = Factory.build(:team)
        end

        it "saves a newly created project" do
          lambda {
            post :create, :team => @team.attributes, :course_id => @team.course.to_param
          }.should change(Team,:count).by(1)
        end

        it "redirects to the index of teams" do
          post :create, :team => @team.attributes, :course_id => @team.course.to_param
          response.should redirect_to(course_teams_path(@team.course))
        end

        it "assigns faculty as @faculty" do
          post :create, :team => @team.attributes, :course_id => @team.course.to_param
          assigns(:faculty).should_not be_nil
        end
      end

      #Re-evaluate this when team CAN have an invalid parameter
      #describe "with invalid params" do
      #  it "assigns a newly created but unsaved item as item" do
      #    lambda {
      #      post :create, :team => {:name => nil, :email => "nothing"}, :course_id => team.course.to_param
      #    }.should_not change(Team, :count)
      #    assigns(:team).should_not be_nil
      #    assigns(:team).should be_kind_of(Team)
      #  end
      #
      #  it "re-renders the 'new' template" do
      #    post :create, :team => {:name => nil, :email =>"nothing"}, :course_id => team.course.to_param
      #    response.should render_template("new")
      #  end
      #end
    end

    describe "PUT update" do

      describe "with valid params" do

        before do
          put :update, :id => team.to_param, :team => {:name => 'NNNNN'}, :course_id => team.course.to_param
        end

        it "updates the requested team name" do
          team.reload.name.should == "NNNNN"
        end

        it "should assign @team" do
          assigns(:team).should_not be_nil
        end

        it "should assign @course" do
          assigns(:course).should_not be_nil
        end

        it "redirects to the course's' teams" do
          response.should redirect_to(course_teams_path(team.course))
        end
      end

      describe "with invalid params" do
        before do
          put :update, :id => team.to_param, :team => {:name => ''}, :course_id => team.course.to_param
        end

        it "should assign @team" do
          assigns(:team).should_not be_nil
        end

        it "should assign @course" do
          assigns(:course).should_not be_nil
        end

        it "re-renders the 'edit' template" do
          response.should render_template("edit")
        end
      end

    end

    describe "not DELETE destroy" do
      before do
        delete :destroy, :id => team.to_param
        @redirect_url = teams_path
      end

      it_should_behave_like "permission denied"
    end
  end


  context "any admin can" do
    before do
      login(Factory(:admin_andy))
    end

    describe "DELETE destroy" do

      it "destroys the course"
#       course.should_receive(:destroy)

#        lambda {
#          a = Course.count
#          c = course
#          delete :destroy, :id => course.to_param
#          b = Course.count
#          t = 1
#        }.should change(Course, :count).by(1)


    end

  end
end
