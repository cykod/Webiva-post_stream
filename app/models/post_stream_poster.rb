require 'digest/sha1'

class PostStreamPoster
  attr_accessor :end_user, :target, :post_permission, :admin_permission, :additional_targets, :shared_content_node, :view_targets, :active_handlers, :options, :renderer, :page_connection_hash, :post_page_node, :request_type, :paragraph_options

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

  def can_comment?
    self.can_post?
  end

  def fetch_first_post
    @post = PostStreamPost.find :first
  end

  def setup(params={}, opts={})
    attributes = params[:stream_post] ? params[:stream_post] : {:body => self.options[:default_post_text]}
    @post = PostStreamPost.new attributes.slice(:body, :name, :domain_file_id, :post_on_facebook, :additional_target).merge(opts)
    @post.end_user_id = self.end_user.id if self.end_user
    @post.posted_by = self.target if self.admin_permission
    @post.shared_content_node_id = self.shared_content_node.id if self.shared_content_node
    @post.handler = attributes[:handler] if self.valid_handler(attributes[:handler])
    @post
  end

  def self.setup_header(renderer)
    unless renderer.ajax?
      renderer.require_js('prototype')
      renderer.require_js('effects')
      renderer.require_js('/components/post_stream/javascript/post_stream.js')
    end

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
  end

  def fetch_post_by_identifier(identifier)
    @post = PostStreamPost.find_by_identifier(identifier)
  end

  def valid_post_and_target
    self.fetch_targets.find do |stream_target|
      PostStreamPostTarget.find_with_post_and_target(@post, stream_target)
    end
  end

  def post
    @post
  end

  def posts
    @posts ||= []
  end

  def posts=(posts)
    @posts = posts
  end

  def has_more
    @has_more
  end

  def comment
    @comment
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
    self.request_type
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
    if @post.save
      self.link_post_to_target(self.target)
      self.link_post_to_target(self.end_user) unless self.admin_permission || self.target == self.end_user
      self.link_post_to_target(self.additional_target) if self.additional_target
      true
    else
      false
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
    opts[:exclude] = self.flagged_posts

    if self.options[:posts_to_display] == 'target'
      @has_more, @posts = PostStreamPost.find_for_target(self.target, page, opts)
    else
      stream_targets = self.fetch_targets
      return [false, []] if stream_targets.empty?

      opts[:except] = self.target if self.options[:posts_to_display] == 'not_target'
      @has_more, @posts = PostStreamPost.find_for_targets(stream_targets, page, opts)
    end

    self.fetch_comments(@posts)
    self.fetch_images(@posts)
    [@has_more, @posts]
  end

  def fetch_comments(posts)
    comments = PostStreamPostComment.find(:all, :conditions => {:post_stream_post_id => posts.collect { |p| p.id if p.post_stream_post_comments_count > 0 }.compact}, :order => 'posted_at DESC').group_by(&:post_stream_post_id)

    posts.each do |post|
      post.comments = comments[post.id] if comments[post.id]
    end
  end

  def fetch_images(posts)
    user_profile_ids = posts.collect { |post| post.posted_by_id if post.posted_by_type == 'UserProfileEntry' }.compact
    return if user_profile_ids.empty?

    user_profiles = UserProfileEntry.find(:all, :conditions => {:id => user_profile_ids}, :include => {:end_user => :domain_file}).index_by(&:id)
    posts.each do |post|
      post.image = user_profiles[post.posted_by_id].end_user.image if user_profiles[post.posted_by_id] && post.posted_by_type == 'UserProfileEntry'
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

  def process_request(params)
    if params[:delete]
      self.request_type = 'delete_post'

      self.fetch_post(params[:post_stream_post_identifier])

      @deleted = self.delete_post
    elsif params[:flag]
      self.request_type = 'flag_post'

      self.fetch_post_by_identifier(params[:post_stream_post_identifier])

      @flagged = self.flag_post
    elsif params[:stream_post_comment]
      self.request_type = 'new_comment'

      if self.can_comment?
        self.fetch_post(params[:stream_post_comment][:post_stream_post_identifier])

        if @post && self.valid_post_and_target
          @comment = @post.post_stream_post_comments.build params[:stream_post_comment].slice(:body, :name)
          @comment.end_user_id = self.end_user.id if self.end_user
          @saved = @comment.save
          @post.reload if @saved
        end
      end
    elsif params[:stream_post]
      self.request_type = 'new_post'

      if self.can_post?
        if self.post.handler_obj
          opts = params[self.post.handler_obj.form_name.to_sym]
          opts = opts.to_hash.symbolize_keys if opts

          if opts && self.post.handler_obj.respond_to?(:valid_params)
            opts = opts.slice(*self.post.handler_obj.valid_params)
          end

          self.post.handler_obj.options(opts)
          self.post.handler_obj.process_request(self.renderer, params, options)
        end

        @saved = self.save
      end
    end
  end

  def can_delete_post?(post)
    self.can_post? && post.end_user_id == self.end_user.id
  end

  def delete_post
    if @post && self.can_delete_post?(@post)
      @post.destroy
      true
    else
      false
    end
  end

  def flag_post
    if @post
      @post.flagged = true
      @post.save

      if self.renderer
        self.renderer.session[:post_stream_posts] ||= {}
        self.renderer.session[:post_stream_posts][:flagged] ||= []
        self.renderer.session[:post_stream_posts][:flagged] << @post.id
      end

      true
    else
      false
    end
  end

  def flagged?
    @flagged
  end

  def flagged_posts
    if self.renderer && self.renderer.session[:post_stream_posts] && self.renderer.session[:post_stream_posts][:flagged]
      self.renderer.session[:post_stream_posts][:flagged]
    else
      nil
    end
  end

  def can_post_to_facebook?
    self.options[:post_on_facebook] && self.post_page_node && SiteModule.module_enabled?('Facebooked')
  end

  def get_locals
    {:poster => self, :posts => self.posts, :post => self.post, :has_more => self.has_more, :saved => @saved, :deleted => @deleted, :flagged => @flagged, :renderer => self.renderer, :post_page_node => self.post_page_node, :page_connection_hash => self.page_connection_hash, :comment => @comment, :options => self.paragraph_options}
  end
end
