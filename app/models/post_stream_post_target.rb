
class PostStreamPostTarget < DomainModel
  belongs_to :post_stream_post
  belongs_to :post_stream_target

  validates_presence_of :post_stream_post_id
  validates_presence_of :post_stream_target_id
  validates_presence_of :posted_at

end
