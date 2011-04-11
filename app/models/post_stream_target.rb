
class PostStreamTarget < DomainModel
  belongs_to :target, :polymorphic => true

  validates_presence_of :target_id
  validates_presence_of :target_type

  has_many :post_stream_post_targets, :dependent => :destroy
  has_many :post_stream_posts, :through => :post_stream_post_targets

  scope :with_target, lambda { |target| where(:target_type => target.class.to_s, :target_id => target.id) }

  def self.push_target(target)
    self.find_target(target) || self.create_target(target)
  end

  def self.find_target(target)
    self.with_target(target).find(:first) if target
  end

  def self.create_target(target)
    # Note: could test target here and make sure it responds to name and image

    begin
      self.create(:target => target, :name => target.name)
    rescue ActiveRecord::StatementInvalid => e
      # possible the record was already created
      logger.error e
      self.find_target(target)
    end
  end

  def update_stats(post=nil)
    self.name = self.target.name if self.target
    self.last_posted_at = post.posted_at if post
    self.post_stream_post_count = self.post_stream_posts.count :select => 'DISTINCT post_stream_posts.id'
    self.flagged_post_count = self.post_stream_posts.flagged_posts.count :select => 'DISTINCT post_stream_posts.id'
    self.posted_by_count = self.post_stream_posts.with_posted_by(self.target).count :select => 'DISTINCT post_stream_posts.id' if self.target
    self.save
  end
end
