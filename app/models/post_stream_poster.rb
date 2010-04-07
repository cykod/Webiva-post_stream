
class PostStreamPoster
  attr_accessor :end_user, :public_target, :private_target, :additional_target, :posted_by, :content_node

  def initialize(user, public_target, private_target)
    self.end_user = user
    self.public_target = public_target
    self.private_target = private_target
  end

  def can_post?
    self.public_target == self.private_target
  end

  def setup_post(attributes)
    attributes ||= {}
    @post = PostStreamPost.new attributes.slice(:body, :name, :link, :domain_file_id)
    @post.end_user_id = self.end_user.id if self.end_user
    @post.posted_by = self.posted_by if self.posted_by
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
      self.link_post_to_target(@post.end_user) if @post.end_user
      self.link_post_to_target(self.public_target) unless self.end_user == self.public_target
      self.link_post_to_target(self.additional_target) if self.additional_target
      true
    end
  end
end
