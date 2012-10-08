#
# Copyright (C) 2011 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe GettingStartedController do
  before do
    account = Account.default
    account.settings = {:teachers_can_create_courses => true, :no_enrollments_can_create_courses => true}
    account.save!
  end

  it "should use GettingStartedController" do
    controller.should be_an_instance_of(GettingStartedController)
  end

  describe "GET 'name'" do

    # it "should serve html, xml, and json data" do
      # format = mock("format")
      # format.expects(:html).returns('this text')
      # format.expects(:xml).returns('this text')
      # format.expects(:json).returns("this text")
      # controller.expects(:respond_to).and_yield(format)
      # session[:course_creation_auth] = true
      # get 'name', :format => :html
    # end
    
    it "should assign @context to a course" do
      user_session(user)
      session[:course_creation_auth] = true
      get 'name'
      assigns[:context].class.should eql(Course)
    end

    it "should require permission" do
      Account.default.update_attribute(:settings, { :no_enrollments_can_create_courses => false })
      user_session(user)
      get 'name'
      response.status.should == '401 Unauthorized'
    end

    it "should allow teachers to create courses" do
      Account.default.update_attribute(:settings, { :no_enrollments_can_create_courses => false })
      course_with_teacher_logged_in
      get 'name'
      response.should be_success
    end

    it "should have a route for name" do
      params_from(:get, "/getting_started/name").should == {:controller => "getting_started", :action => "name"}
    end
  end
  
  describe "GET 'assignments'" do
    
    # it "should serve html, xml, and json data" do
      # format = mock("format")
      # format.expects(:html).returns('this text')
      # format.expects(:xml).returns('this text')
      # format.expects(:json).returns('this text')
      # controller.expects(:respond_to).and_yield(format)
      # session[:course_creation_auth] = true
      # get 'assignments', :format => :html
    # end
    
    it "should have a route to get assignments" do
      params_from(:get, "/getting_started/assignments").should == 
        {:controller => "getting_started", :action => "assignments"}
    end
    
    it "should have assignment and assignments ready for the views." do
      session[:course_creation_auth] = true
      user_session(user)
      get 'assignments'
      assigns[:groups].should_not be_nil
      assigns[:assignments].should_not be_nil
    end
  end
  
  describe "GET 'students'" do
    # it "should serve html, xml, and json data" do
      # format = mock("format")
      # format.expects(:html).returns('this text')
      # format.expects(:xml).returns('this text')
      # format.expects(:json).returns('this text')
      # controller.expects(:respond_to).and_yield(format)
      # session[:course_creation_auth] = true
      # get 'students', :format => :html
    # end
    
    it "should have a route to get students" do
      params_from(:get, "/getting_started/students").should == 
        {:controller => "getting_started", :action => "students"}
    end
    
    it "should have students ready for the views." do
      session[:course_creation_auth] = true
      user_session(user)
      get 'students'
      assigns[:students].should_not be_nil
    end
  end
        
end
