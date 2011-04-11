
class PostStreamPostTarget < DomainModel
  belongs_to :post_stream_post
  belongs_to :post_stream_target

  validates_presence_of :post_stream_post_id
  validates_presence_of :post_stream_target_id
  validates_presence_of :posted_at
  validates_presence_of :post_type

  scope :with_post, lambda { |post_id| where(:post_stream_post_id => post_id) }
  scope :with_target, lambda { |target_id| where(:post_stream_target_id => target_id) }
  scope :with_types, lambda { |types| where(:post_type => types) }
  scope :without_posted_by, lambda { |poster| joins(:post_stream_post).where('NOT (post_stream_posts.posted_by_type = ? and post_stream_posts.posted_by_id = ?)',  poster.class.to_s, poster.id) }
  scope :without_posts, lambda { |ids| where('post_stream_post_id not in(?)', ids) }

  def self.link_post_to_target(post, target)
    begin
      post_target = self.create :post_stream_post_id => post.id, :post_stream_target_id => target.id, :posted_at => post.posted_at, :post_type => post.post_type
      target.update_stats post
      post_target
    rescue ActiveRecord::StatementInvalid => e
      logger.error e
      self.find_with_post_and_target(post, target)
    end
  end

  def self.find_with_post_and_target(post, target)
    self.with_post(post.id).with_target(target.id).find(:first)
  end
end
