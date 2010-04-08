
class PostStreamTarget < DomainModel
  belongs_to :target, :polymorphic => true

  validates_presence_of :target_id
  validates_presence_of :target_type

  has_many :post_stream_post_targets, :dependent => :destroy

  named_scope :with_target, lambda { |target| {:conditions => {:target_type => target.class.to_s, :target_id => target.id}} }

  def self.push_target(target)
    self.find_target(target) || self.create_target(target)
  end

  def self.find_target(target)
    self.with_target(target).find(:first)
  end

  def self.create_target(target)
    # Note: could test target here and make sure it responds to name and image

    begin
      self.create(:target => target)
    rescue ActiveRecord::StatementInvalid => e
      # possible the record was already created
      logger.error e
      self.find_target(target)
    end
  end
end
