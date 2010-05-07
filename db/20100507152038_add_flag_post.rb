class AddFlagPost < ActiveRecord::Migration
  def self.up
    add_column :post_stream_posts, :flagged, :boolean
  end

  def self.down
    remove_column :post_stream_posts, :flagged
  end
end
