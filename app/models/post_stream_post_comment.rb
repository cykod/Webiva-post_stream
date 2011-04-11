
class PostStreamPostComment < DomainModel
  attr_accessor :folder_id, :name

  belongs_to :post_stream_post
  has_end_user :end_user_id, :name_column => :name

  before_validation :set_defaults, :on => :create

  validates_presence_of :post_stream_post_id
  validates_presence_of :body
  validates_presence_of :posted_at
  validate :validate_name

  safe_content_filter(:body => :body_html)  do |comment|
    { :filter => comment.content_filter,
      :folder_id => comment.folder_id
    }
  end

  after_create :update_comments_count

  def set_defaults
    self.posted_at ||= Time.now
  end

  def validate_name
    self.errors.add(:name, 'is missing') if self.end_user && self.end_user.missing_name? && self.name.blank?
  end

  def content_filter
    PostStream::AdminController.module_options.content_filter || 'comment'
  end

  def update_comments_count
    self.post_stream_post.update_comments_count
  end

  def post_stream_post_identifier
    self.post_stream_post.identifier
  end
end
