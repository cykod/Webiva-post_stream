
class PostStreamPostTarget < DomainModel
  belongs_to :post_stream_post
  belongs_to :post_stream_target

  validates_presence_of :post_stream_post_id
  validates_presence_of :post_stream_target_id
  validates_presence_of :posted_at
  validates_presence_of :post_type

  named_scope :with_post, lambda { |post_id| {:conditions => {:post_stream_post_id => post_id}} }
  named_scope :with_target, lambda { |target_id| {:conditions => {:post_stream_target_id => target_id}} }
  named_scope :with_types, lambda { |types| {:conditions => {:post_type => types}} }

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
