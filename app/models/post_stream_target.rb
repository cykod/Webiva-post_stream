
class PostStreamTarget < DomainModel
  belongs_to :target, :polymorphic => true

  validates_presence_of :target_id
  validates_presence_of :target_type

  has_many :post_stream_post_targets, :dependent => :destroy
end
