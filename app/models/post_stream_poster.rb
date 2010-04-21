require 'digest/sha1'

class PostStreamPoster
  attr_accessor :end_user, :target, :post_permission, :admin_permission, :additional_targets, :shared_content_node, :view_targets, :active_handlers, :options, :submitted

  include HandlerActions

  def initialize(user, target, opts={})
    self.end_user = user
    self.target = target
    self.options = opts
    self.additional_targets = []
  end

  def can_post?
    self.post_permission || self.admin_permission
  end

  def fetch_first_post
    @post = PostStreamPost.find :first
  end

  def setup_post(attributes, opts={})
    attributes ||= {:body => self.options[:default_post_text]}
    self.submitted = false
    @post = PostStreamPost.new attributes.slice(:body, :name, :domain_file_id, :post_on_facebook, :additional_target).merge(opts)
    @post.end_user_id = self.end_user.id if self.end_user
    @post.posted_by = self.target if self.admin_permission
    @post.shared_content_node_id = self.shared_content_node.id if self.shared_content_node
    @post.handler = attributes[:handler] if self.valid_handler(attributes[:handler])
    @post
  end

  def self.setup_header(renderer)
    self.get_handler_info(:post_stream, :share).each do |info|
      info[:class].setup_header(renderer) if info[:class].respond_to?(:setup_header)
    end
  end

  def fetch_post(identifier)
    return true if identifier.nil?
    fetch_post_by_identifier(identifier)
    return false if @post.nil?
    return false unless self.valid_post_and_target
    @post
    @comment = @post.post_stream_post_comments.new
  end

  def fetch_post_by_identifier(identifier)
    @post = PostStreamPost.find_by_identifier(identifier)
  end

  def valid_post_and_target
    stream_target = PostStreamTarget.find_target(self.target)
    return nil unless stream_target
    PostStreamPostTarget.find_with_post_and_target(@post, stream_target)
  end

  def post
    @post
  end

  def comment
    @comment
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

  def was_submitted?
    self.submitted
  end

  def additional_target
    return nil if self.additional_targets.empty?

    self.additional_targets.find { |t| Digest::SHA1.hexdigest(t.class.to_s + t.id.to_s) == self.post.additional_target }
  end

  def additional_target_options
    return nil if self.additional_targets.empty?

    self.additional_targets.collect { |t| ['Post to %s' / t.name, Digest::SHA1.hexdigest(t.class.to_s + t.id.to_s)] }
  end

  def save
    self.submitted = true

    if @comment
      @comment.save
    elsif @post.save
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

    has_more, posts = PostStreamPost.find_for_targets(stream_targets, page, opts)
    self.fetch_comments(posts)
    [has_more, posts]
  end

  def fetch_comments(posts)
    comments = PostStreamPostComment.find(:all, :conditions => {:post_stream_post_id => posts.collect { |p| p.id if p.post_stream_post_comments_count > 0 }.compact}, :order => 'posted_at DESC')

    comments.each do |comment|
      post = posts.find { |p| p.id == comment.post_stream_post_id }
      post.add_comment(comment) if post
    end
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

  def process_request(renderer, params)
    return self.process_comment_request(params) if params[:stream_post_comment]
    return unless params[:stream_post]
    return unless self.post.handler_obj

    opts = params[self.post.handler_obj.form_name.to_sym]
    opts = opts.to_hash.symbolize_keys if opts

    if opts && self.post.handler_obj.respond_to?(:valid_params)
      opts = opts.slice(*self.post.handler_obj.valid_params)
    end

    self.post.handler_obj.options(opts)
    self.post.handler_obj.process_request(renderer, params, options)
  end

  def process_comment_request(params)
    return unless params[:stream_post_comment]

    @post = PostStreamPost.find_by_id(params[:stream_post_comment][:post_stream_post_id])
    if @post.nil?
      self.setup_post nil
      return nil
    end

    return nil unless self.valid_post_and_target

    @comment = @post.post_stream_post_comments.build params[:stream_post_comment].slice(:body, :name)
    @comment.end_user_id = self.end_user.id if self.end_user
    @comment
  end
end
