class AddedPostedByCount < ActiveRecord::Migration
  def self.up
    add_column :post_stream_targets, :posted_by_count, :integer
  end

  def self.down
    remove_column :post_stream_targets, :posted_by_count
  end
end
