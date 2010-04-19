
class PostStreamPostComment < DomainModel
  attr_accessor :folder_id, :name

  belongs_to :post_stream_post
  has_end_user :end_user_id, :name_column => :name

  validates_presence_of :post_stream_post_id
  validates_presence_of :body
  validates_presence_of :posted_at

  safe_content_filter(:body => :body_html)  do |comment|
    { :filter => comment.content_filter,
      :folder_id => comment.folder_id
    }
  end

  def before_validation_on_create
    self.posted_at ||= Time.now
  end

  def validate
    self.errors.add(:name, 'is missing') if self.end_user && self.end_user.missing_name? && self.name.blank?
  end

  def content_filter
    PostStream::AdminController.module_options.content_filter || 'comment'
  end
end
