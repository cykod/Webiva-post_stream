
class PostStream::Share::Link < PostStream::Share::Base
  attr_accessor :supported_post_types

  def self.post_stream_share_handler_info
    {
      :name => 'Link'
    }
  end

  def self.setup_header(renderer)
    self.get_handler_info(:post_stream, :link).each do |info|
      info[:class].setup_header(renderer) if info[:class].respond_to?(:setup_header)
    end
  end

  def valid_params
    [:link]
  end

  def render_form_elements(renderer, form, opts={})
    form.text_field :link
  end

  def process_request(params, opts={})
    self.post.link = self.options.link

    self.handlers.find do |handler|
      if handler.process_request(params, opts)
        self.options.handler = handler.class.to_s.underscore
        self.options.data = handler.data
        true
      else
        nil
      end
    end
  end

  def render(renderer, opts={})
    if self.handler_obj
      self.handler_obj.render(renderer, opts)
    else
      'Link: %s' / content_tag(:a, self.post.link, {:href => self.post.link, :rel => 'nofollow', :target => '_blank'})
    end
  end

  def supported_handler?(info)
    return true unless self.supported_post_types

    info[:post_types].find do |post_type|
      self.supported_post_types.include?(post_type)
    end
  end

  def handlers
    @handlers ||= self.get_handler_info(:post_stream, :link).collect do |info|
      if self.supported_handler?(info)
        info[:class].new(self.post)
      else
        nil
      end
    end.compact
  end

  def handler_class
    @handler_class ||= self.options.handler.classify.constantize if self.options.handler
  end

  def handler_obj
    @handler_obj ||= self.handler_class.new(self.post) if self.handler_class
  end

  def preview_image_url
    self.handler_obj.preview_image_url if self.handler_obj
  end

  class Options < HashModel
    attr_accessor :handler_required

    attributes :link => nil, :handler => nil, :data => {}

    validates_presence_of :link
    validates_urlness_of :link, :allow_nil => true

    def validate
      if self.handler_required
        self.errors.add(:link, 'is required') unless self.handler
      end
    end
  end

  class Base
    def initialize(post)
      @post = post
    end

    def preview_image_url; nil; end

    def post
      @post
    end

    def link
      self.post.link
    end

    def options_class
      @options_class ||= "#{self.class.to_s}::Options".constantize
    end

    def options(opts={})
      data = self.post.handler_obj.options.data || {}
      opts ||= {}
      @options ||= self.options_class.new(data.merge(opts.to_hash.symbolize_keys))
    end

    def data
      self.options.to_h
    end

    def valid?
      self.options.valid?
    end
  end
end
