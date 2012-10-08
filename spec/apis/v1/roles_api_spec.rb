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

require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')

describe "Roles API", :type => :integration do
  before do
    @account = Account.default
    account_admin_user(:account => @account)
    user_with_pseudonym(:user => @admin)
  end

  describe "add_role" do
    before :each do
      @role = 'NewRole'
      @permission = 'read_reports'
      @initial_count = @account.role_overrides.size
    end

    def api_call_with_settings(settings={})
      admin = settings.delete(:admin) || @admin
      account = settings.delete(:account) || @admin.account
      role = settings.delete(:role) || @role
      permission = settings.delete(:permission) || @permission
      api_call(:post, "/api/v1/accounts/#{account.id}/roles",
        { :controller => 'role_overrides', :action => 'add_role', :format => 'json', :account_id => account.id.to_s },
        { :role => role,
          :permissions => { permission => settings } })
    end

    it "should add the role to the account" do
      @account.account_membership_types.should_not include(@role)
      json = api_call_with_settings(:explicit => '1', :enabled => '1')
      @account.reload
      @account.account_membership_types.should include(@role)
    end

    it "should require a role" do
      raw_api_call(:post, "/api/v1/accounts/#{@admin.account.id}/roles",
        { :controller => 'role_overrides', :action => 'add_role', :format => 'json', :account_id => @admin.account.id.to_s },
        { :permissions => { @permission => { :explicit => '1', :enabled => '1' } } })
      response.status.should == '400 Bad Request'
      JSON.parse(response.body).should == {"message" => "missing required parameter 'role'"}
    end

    it "should fail when given an existing role" do
      @account.add_account_membership_type(@role)
      raw_api_call(:post, "/api/v1/accounts/#{@admin.account.id}/roles",
        { :controller => 'role_overrides', :action => 'add_role', :format => 'json', :account_id => @admin.account.id.to_s },
        { :role => @role })
      response.status.should == '400 Bad Request'
      JSON.parse(response.body).should == {"message" => "role already exists"}
    end

    it "should not create an override if enabled is nil and locked is not 1" do
      api_call_with_settings(:explicit => '1', :locked => '0')
      @account.role_overrides(true).size.should == @initial_count
    end

    it "should not create an override if explicit is not 1 and locked is not 1" do
      api_call_with_settings(:explicit => '0', :enabled => '1', :locked => '0')
      @account.role_overrides(true).size.should == @initial_count
    end

    it "should create the override if explicit is 1 and enabled has a value" do
      api_call_with_settings(:explicit => '1', :enabled => '0')
      @account.role_overrides(true).size.should == @initial_count + 1
      override = @account.role_overrides.find_by_permission_and_enrollment_type(@permission, @role)
      override.should_not be_nil
      override.enabled.should be_false
    end

    it "should create the override if enabled is nil but locked is 1" do
      api_call_with_settings(:locked => '1')
      @account.role_overrides(true).size.should == @initial_count + 1
      override = @account.role_overrides.find_by_permission_and_enrollment_type(@permission, @role)
      override.should_not be_nil
      override.locked.should be_true
    end

    it "should only set the parts that are specified" do
      api_call_with_settings(:explicit => '1', :enabled => '0')
      override = @account.role_overrides(true).find_by_permission_and_enrollment_type(@permission, @role)
      override.should_not be_nil
      override.enabled.should be_false
      override.locked.should be_nil

      override.destroy
      @account.remove_account_membership_type(@role)

      api_call_with_settings(:locked => '1')
      override = @account.role_overrides(true).find_by_permission_and_enrollment_type(@permission, @role)
      override.should_not be_nil
      override.enabled.should be_nil
      override.locked.should be_true
    end

    it "should discard restricted permissions" do
      # @admin.account is not Account.site_admin, so the site_admin permission
      # (and a few others) is not available to roles on that account.
      restricted_permission = 'site_admin'

      api_call(:post, "/api/v1/accounts/#{@admin.account.id}/roles",
        { :controller => 'role_overrides', :action => 'add_role', :format => 'json', :account_id => @admin.account.id.to_s },
        { :role => @role,
          :permissions => {
            @permission => { :explicit => '1', :enabled => '1' },
            restricted_permission => { :explicit => '1', :enabled => '1' } } })

      @account.role_overrides(true).size.should == @initial_count + 1 # not 2
      override = @account.role_overrides.find_by_permission_and_enrollment_type(restricted_permission, @role)
      override.should be_nil

      override = @account.role_overrides.find_by_permission_and_enrollment_type(@permission, @role)
      override.should_not be_nil
    end

    describe "json response" do
      it "should return the expected json format" do
        json = api_call_with_settings
        json.keys.sort.should == ["account", "permissions", "role"]
        json["account"].should == {
          "name" => @account.name,
          "root_account_id" => @account.root_account_id,
          "parent_account_id" => @account.parent_account_id,
          "id" => @account.id
        }
        json["role"].should == @role

        # make sure all the expected keys are there, but don't assert on a
        # *only* the expected keys, since plugins may have added more.
        ([
          "become_user", "change_course_state",
          "comment_on_others_submissions", "create_collaborations",
          "create_conferences", "manage_account_memberships",
          "manage_account_settings", "manage_admin_users", "manage_alerts",
          "manage_assignments", "manage_calendar", "manage_content",
          "manage_courses", "manage_files", "manage_grades", "manage_groups",
          "manage_interaction_alerts", "manage_outcomes",
          "manage_role_overrides", "manage_sections", "manage_sis",
          "manage_students", "manage_user_logins", "manage_user_notes",
          "manage_wiki", "moderate_forum", "post_to_forum",
          "read_course_content", "read_course_list", "read_forum",
          "read_question_banks", "read_reports", "read_roster",
          "read_sis", "send_messages", "view_all_grades", "view_group_pages",
          "view_statistics"
        ] - json["permissions"].keys).should be_empty

        json["permissions"][@permission].should == {
          "explicit" => false,
          "readonly" => false,
          "enabled" => false,
          "locked" => false
        }
      end

      it "should only return manageable permissions" do
        # set up a subaccount and admin in subaccount
        subaccount = @account.sub_accounts.create!

        # add a role in that subaccount
        json = api_call_with_settings(:account => subaccount)
        json["account"]["id"].should == subaccount.id

        # become_user is a permission restricted to root account roles. it
        # shouldn't be in the response for this subaccount role.
        json["permissions"].keys.should_not include("become_user")
      end

      it "should set explicit and prior default if enabled was provided" do
        json = api_call_with_settings(:explicit => '1', :enabled => '1')
        json["permissions"][@permission].should == {
          "explicit" => true,
          "readonly" => false,
          "enabled" => true,
          "locked" => false,
          "prior_default" => false
        }
      end
    end
  end

  describe "create permission overrides" do
    before do
      @account = Account.default
      @path = "/api/v1/accounts/#{@account.id}/roles/TeacherEnrollment"
      @path_options = { :controller => 'role_overrides', :action => 'update',
        :account_id => @account.id.to_param, :format => 'json',
        :role => 'TeacherEnrollment' }
      @permissions = { :permissions => {
        :read_question_banks => { :explicit => 1, :enabled => 0,
        :locked => 1 }}}
    end

    context "an authorized user" do
      it "should be able to change permissions" do
        json = api_call(:put, @path, @path_options, @permissions)
        json['permissions']['read_question_banks'].should == {
          'enabled'       => false,
          'locked'        => true,
          'readonly'      => false,
          'prior_default' => true,
          'explicit'      => true }
        json['role'].should eql 'TeacherEnrollment'
        json['account'].should == {
          'root_account_id' => nil,
          'name' => Account.default.name,
          'id' => Account.default.id,
          'parent_account_id' => nil }
      end

      it "should not be able to edit read-only permissions" do
        json = api_call(:put, @path, @path_options, { :permission => {
          :read_forum => { :explicit => 1, :enabled => 0 }}})

        # permissions should remain unchanged
        json['permissions']['read_forum'].should == {
          'explicit' => false,
          'enabled'  => true,
          'readonly' => true,
          'locked'   => true }
      end

      it "should be able to change permissions for account admins" do
        json = api_call(:put, @path.sub(/TeacherEnrollment/, 'AccountAdmin'),
          @path_options.merge(:role => 'AccountAdmin'), { :permissions => {
          :manage_courses => { :explicit => 1, :enabled => 0 }}})
        json['permissions']['manage_courses']['enabled'].should eql false
      end
    end

    context "an unauthorized user" do
      it "should return 401 unauthorized" do
        user_with_pseudonym
        raw_api_call(:put, @path, @path_options, @permissions)
        response.code.should eql '401'
      end
    end
  end
end
