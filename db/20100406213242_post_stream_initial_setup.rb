class PostStreamInitialSetup < ActiveRecord::Migration
  def self.up
    create_table :post_stream_posts, :force => true do |t|
      t.integer :end_user_id
      t.string :posted_by_type
      t.integer :posted_by_id
      t.integer :content_node_id
      t.integer :domain_file_id
      t.string :post_type, :size => 16
      t.string :post_hash
      t.string :title
      t.text :link
      t.text :body
      t.text :body_html
      t.string :handler
      t.text :data
      t.integer :post_stream_post_comments_count, :default => 0
      t.datetime :posted_at
    end

    add_index :post_stream_posts, [:end_user_id], :name => 'post_stream_posts_user_idx'
    add_index :post_stream_posts, [:content_node_id], :name => 'post_stream_posts_content_idx'
    add_index :post_stream_posts, [:post_type, :posted_at], :name => 'post_stream_posts_type_posted_at_idx'

    create_table :post_stream_post_comments, :force => true do |t|
      t.integer :post_stream_post_id
      t.integer :end_user_id
      t.string :name
      t.text :body
      t.text :body_html
      t.datetime :posted_at
    end

    add_index :post_stream_post_comments, [:end_user_id], :name => 'post_stream_post_comments_user_idx'
    add_index :post_stream_post_comments, [:post_stream_post_id], :name => 'post_stream_post_comments_stream_idx'

    create_table :post_stream_targets, :force => true do |t|
      t.integer :target_id
      t.string :target_type
    end

    add_index :post_stream_targets, [:target_type, :target_id], :name => 'post_stream_targets_idx', :unique => true

    create_table :post_stream_post_targets, :force => true do |t|
      t.integer :post_stream_post_id
      t.integer :post_stream_target_id
      t.datetime :posted_at
      t.string :post_type, :size => 16
    end

    add_index :post_stream_post_targets, [:post_stream_target_id, :posted_at], :name => 'post_stream_post_targets_idx'
  end

  def self.down
    drop_table :post_stream_posts
    drop_table :post_stream_post_comments
    drop_table :post_stream_targets
    drop_table :post_stream_post_targets
  end
end
