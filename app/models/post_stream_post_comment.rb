
class PostStreamPostComment < DomainModel
  belongs_to :post_stream_post
  has_end_user :end_user_id

  validates_presence_of :post_stream_post_id
  validates_presence_of :body
  validates_presence_of :posted_at
end
