
class PostStreamPost < DomainModel
  attr_accessor :folder_id, :name

  has_end_user :end_user_id, :name_column => :name
  belongs_to :content_node

  has_domain_file :domain_file_id

  # posted_by models must have a name and image field
  belongs_to :posted_by, :polymorphic => true
  has_many :post_stream_post_targets, :dependent => :destroy
  has_many :post_stream_post_comments, :dependent => :destroy

  validates_presence_of :post_type
  has_options :post_type, [['Post', 'post'], ['Content','content'], ['Link','link'], ['Image', 'image'], ['Media', 'media']] 

  validates_presence_of :body
  validates_presence_of :posted_at

  validates_urlness_of :link, :allow_nil => true

  serialize :data

  safe_content_filter(:body => :body_html)  do |post|
    { :filter => post.content_filter,
      :folder_id => post.folder_id
    }
  end

  def image
    self.posted_by ? self.posted_by.image : Configuration.missing_image(nil)
  end

  def validate
    case self.post_type
    when 'link'
      self.errors.add(:link, 'is required') if self.link.blank?
    when 'image'
      self.errors.add(:domain_file_id, 'is required') if self.domain_file.nil?
      self.errors.add(:domain_file_id, 'is invalid') if self.domain_file && ! self.domain_file.image?
    when 'media'
      self.errors.add(:domain_file_id, 'is required') if self.domain_file.nil?
    when 'content'
      self.errors.add(:content_node_id, 'is required') if self.content_node.nil?
    end
  end

  def before_validation_on_create
    if self.post_type.nil?
      if self.content_node
        self.post_type = 'content'
      elsif self.domain_file
        self.post_type = self.domain_file.image? ? 'image' : 'media'
      elsif self.link
        self.post_type = 'link'
      else
        self.post_type = 'post'
      end
    end

    self.posted_at ||= Time.now
  end

  def before_create
    self.post_hash ||= DomainModel.generate_hash

    self.posted_by = self.end_user if self.posted_by.nil? && self.end_user

    self.title = self.posted_by ? self.posted_by.name : 'Anonymous'.t if self.title.blank?
    self.title = self.name if self.name && self.title == 'Anonymous'.t
  end

  def content_filter
    PostStream::AdminController.module_options.content_filter || 'comment'
  end

  def self.find_for_targets(targets, page=1, opts={})
    page = (page || 1).to_i
    limit = opts.delete(:limit) || 10
    offset = (page-1) * limit

    post_types = opts.delete(:post_types)
    if post_types && ! post_types.empty?
      scope = PostStreamPostTarget.with_types(post_types)
    else
      scope = PostStreamPostTarget
    end

    items = scope.with_target(targets).find(:all, {:select => 'DISTINCT post_stream_post_id', :limit => limit + 1, :offset => offset, :order => 'posted_at DESC'}.merge(opts))

    posts = PostStreamPost.find(:all, :conditions => {:id => items.collect { |item| item.post_stream_post_id }}, :order => 'posted_at DESC')
    has_more = posts.length > limit
    posts.pop if has_more
    [has_more, posts]
  end
end
