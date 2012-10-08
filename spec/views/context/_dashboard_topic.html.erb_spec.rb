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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../views_helper')

describe "context/dashboard_topic" do
  it "should not show the author for nil user_id" do
    render :partial => "context/dashboard_topic", :locals =>
        { :dashboard_topic => OpenObject.new({:root_discussion_entries => nil,
                                              :created_at => Time.now.utc, :user_id => nil})}
    response.should_not be_nil
    response.body.should_not match /Author/
  end
end
