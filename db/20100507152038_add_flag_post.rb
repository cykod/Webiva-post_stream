class AddFlagPost < ActiveRecord::Migration
  def self.up
    add_column :post_stream_posts, :flagged, :boolean
    add_column :post_stream_targets, :flagged_post_count, :integer
  end

  def self.down
    remove_column :post_stream_posts, :flagged
    remove_column :post_stream_targets, :flagged_post_count
  end
end
