
class PostStreamPoster
  attr_accessor :end_user, :target, :post_permission, :admin_permission, :additional_target, :content_node, :view_targets, :active_handlers

  include HandlerActions

  def initialize(user, target)
    self.end_user = user
    self.target = target
  end

  def can_post?
    self.post_permission || self.admin_permission
  end

  def setup_post(attributes, opts={})
    attributes ||= {}
    @post = PostStreamPost.new attributes.slice(:body, :name, :domain_file_id).merge(opts)
    @post.end_user_id = self.end_user.id if self.end_user
    @post.posted_by = self.target if self.admin_permission
    @post.content_node_id = self.content_node.id if self.content_node
    @post.handler = attributes[:handler] if self.valid_handler(attributes[:handler])
    @post
  end

  def self.setup_header(renderer)
    self.get_handler_info(:post_stream, :share).each do |info|
      info[:class].setup_header(renderer) if info[:class].respond_to?(:setup_header)
    end
  end

  def post
    @post
  end

  def valid?
    @post.valid?
  end

  def valid_handler(identifier)
    return false if identifier.blank?
    info = get_handler_info(:post_stream, :share, identifier)
    return false unless info
    self.active_handlers ? self.active_handlers.include?(identifier) : true
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

  def fetch_targets
    targets = []
    stream_target = PostStreamTarget.find_target(self.target)
    targets << stream_target if stream_target

    if self.view_targets
      self.view_targets.each do |target_group|
        target_type, target_ids = *target_group
        stream_targets = PostStreamTarget.find(:all, :conditions => {:target_type => target_type, :target_id => target_ids})
        targets = targets + stream_targets unless stream_targets.empty?
      end
    end

    targets
  end

  # returns has_more and posts
  def fetch_posts(page=1, opts={})
    stream_targets = self.fetch_targets
    return [false, []] if stream_targets.empty?

    PostStreamPost.find_for_targets(stream_targets, page, opts)
  end

  def handlers
    @handlers ||= self.get_handler_info(:post_stream, :share).collect do |info|
      if self.active_handlers.nil? || self.active_handlers.include?(info[:identifier])
        self.post.handler == info[:identifier] ? self.post.handler_obj : info[:class].new(self.post)
      else
        nil
      end
    end.compact
  end

  def get_handler_by_type(type)
    self.handlers.find { |handler| handler.type == type }
  end

  def process_request(params)
    return unless params[:stream_post]
    return unless self.post.handler_obj

    opts = params[self.post.handler_obj.form_name]
    opts = opts.to_hash.symbolize_keys if opts

    if opts && self.post.handler_obj.respond_to?(:valid_params)
      opts = opts.slice(*self.post.handler_obj.valid_params)
    end

    self.post.handler_obj.options(opts)
    self.post.handler_obj.process_request(params) if self.post.handler_obj.valid?
  end
end
