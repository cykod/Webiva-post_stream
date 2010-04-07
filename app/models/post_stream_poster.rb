
class PostStreamPoster
  attr_accessor :end_user, :target, :post_permission, :admin_permission, :additional_target, :content_node

  def initialize(user, target)
    self.end_user = user
    self.target = target
  end

  def can_post?
    self.post_permission || self.admin_permission
  end

  def setup_post(attributes, opts={})
    attributes ||= {}
    @post = PostStreamPost.new attributes.slice(:body, :name, :link, :domain_file_id).merge(opts)
    @post.end_user_id = self.end_user.id if self.end_user
    @post.posted_by = self.target if self.admin_permission
    @post.content_node_id = self.content_node.id if self.content_node
    @post
  end

  def post
    @post
  end

  def valid?
    @post.valid?
  end

  def link_post_to_target(target)
    PostStreamPostTarget.link_post_to_target(@post, PostStreamTarget.push_target(target))
  end

  def save
    if @post.save
      self.link_post_to_target(self.target)
      self.link_post_to_target(self.end_user) unless self.admin_permission || self.target == self.end_user
      self.link_post_to_target(self.additional_target) if self.additional_target
      true
    end
  end
end
