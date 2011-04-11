
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

  def valid?
    is_valid = super

    if ! self.options.errors[:link].empty?
      error = self.options.errors[:link].first
      self.post.errors.add_to_base('Link ' + error)
      return false
    elsif ! self.options.errors[:handler].empty?
      self.options.errors.add(:link, 'is not supported.')
      self.post.errors.add_to_base('Link ' + self.options.errors[:link])
      return false
    end

    is_valid
  end

  def render_form_elements(renderer, form, opts={})
    form.text_field :link
  end

  def process_request(renderer, params, opts={})
    self.post.link = self.options.link

    self.handlers.find do |handler|
      if handler.process_request(renderer, params, opts)
        @handler_class = handler.class.to_s.underscore
        @handler_obj = handler
        self.options.handler = @handler_class
        true
      else
        nil
      end
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
    @handler_class ||= self.options.handler.camelcase.constantize if self.options.handler
  end

  def handler_obj
    @handler_obj ||= self.handler_class.new(self.post) if self.handler_class
  end

  def image_url
    self.options.data[:image_url]
  end

  def width
    self.options.data[:width]
  end

  def height
    self.options.data[:height]
  end

  def name
    self.options.data[:title]
  end

  def description
    self.options.data[:description]
  end

  def author_name
    self.options.data[:author_name]
  end

  def author_url
    self.options.data[:author_url]
  end

  def provider_name
    self.options.data[:provider_name]
  end

  def provider_url
    self.options.data[:provider_url]
  end

  def embeded_html
    self.options.data[:html]
  end

  def thumbnail_url
    self.options.data[:thumbnail_url]
  end

  def thumbnail_width
    self.options.data[:thumbnail_width]
  end

  def thumbnail_height
    self.options.data[:thumbnail_height]
  end

  class Options < HashModel
    attr_accessor :handler_required

    attributes :link => nil, :handler => nil, :data => nil

    validates_presence_of :link
    validates_urlness_of :link, :allow_nil => true

    def validate
      if self.handler_required
        self.errors.add(:handler, 'is required') unless self.handler
      end
    end

    def data
      @data ||= {}
    end

    def data=(data)
      @data = data
    end
  end

  class Base
    attr_accessor :error_message

    def initialize(post)
      @post = post
    end

    def post
      @post
    end

    def link
      self.post.link
    end

    def data
      self.post.handler_obj.options.data
    end

    def data=(data)
      self.post.handler_obj.options.data = data
    end

    def post_type
      self.post.post_type
    end

    def post_type=(type)
      self.post.post_type = type
    end
  end
end
