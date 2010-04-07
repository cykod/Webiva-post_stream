
class PostStreamPost < DomainModel
  has_end_user :end_user_id, :name_column => :title
  belongs_to :content_node
  belongs_to :posted_by, :polymorphic => true
  has_many :post_stream_post_targets, :dependent => :destroy
  has_many :post_stream_post_comments, :dependent => :destroy

  validates_presence_of :post_type
  has_options :post_type, [['Post', 'post'], ['Blog','blog'], ['Link','link'], ['Image', 'image'], ['Media', 'media']] 

  serialize :data

end
