class SetDiscussionEntryRootIds < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    # fix up parent_id, which was getting set to 0 for root-level entries
    # also set root_entry_id to parent_id for all existing entries
    DiscussionEntry.update_all("parent_id = CASE parent_id WHEN 0 THEN null ELSE parent_id END, root_entry_id = CASE parent_id WHEN 0 THEN null ELSE parent_id END")
  end

  def self.down
    DiscussionEntry.update_all("parent_id = 0", "parent_id IS NULL")
    # previous migration drops the root_entry_id column here
  end
end
