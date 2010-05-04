
module PostStream::Share
  class Base
    include HandlerActions
    include ActionView::Helpers::TagHelper

    def initialize(post)
      @post = post
    end

    def title; self.class.post_stream_share_handler_info[:name]; end
    def type; @type ||= self.title.downcase.gsub(/[^a-z0-9 -]/, '').gsub(/( |-)/, '_'); end
    def form_name; "stream_post_#{self.type}"; end
    def info; @info ||= self.get_handler_info(:post_stream, :share, self.class.to_s.underscore); end
    def identifier; self.info[:identifier]; end

    def name; self.post.link; end
    def description; nil; end
    def image_url; nil; end
    def width; nil; end
    def height; nil; end
    def thumbnail_url; nil; end
    def thumbnail_width; nil; end
    def thumbnail_height; nil; end
    def preview_image_url; self.image_url; end
    def author_name; nil; end
    def author_url; nil; end
    def provider_name; nil; end
    def provider_url; nil; end
    def additional_information; nil; end
    def embeded_html; nil; end

    def options_class
      @options_class ||= "#{self.class.to_s}::Options".constantize
    end

    def options(opts={})
      return @options if @options

      data = self.post.data || {}
      opts ||= {}
      @options ||= self.options_class.new(data.merge(opts))
    end

    def valid?
      self.options.valid?
    end

    def post
      @post
    end

    def render_form(renderer, form, opts={})
      close_content = opts['close_image'] ? "<img src='#{opts['close_image']}'/>" : opts['close']
      title = opts['title'] || self.title
      style = opts['visible'] || self.post.handler == self.identifier ? '' : 'style="display:none;"'

      <<-HANDLER
      <div id="post_stream_handler_form_#{self.type}" class="post_stream_handler_form" #{style}>
      <div class="title_bar">
        <span class="title">#{title}</span>
        <span class="close_button"><a href="javascript:void(0);" onclick="PostStreamForm.close();">#{close_content}</a></span>
      </div>
      <div class="handler_form">
        #{self.render_form_elements(renderer, form, opts)}
      </div>
      </div>
      HANDLER
    end

    def render_button(opts={})
      text = opts['title'] || self.title
      handler = self.class.to_s.underscore
      content_tag(:a, text, {:href => 'javascript:void(0);', :onclick => "PostStreamForm.share('#{self.type}', '#{handler}');"})
    end

    def render(renderer, opts={})
      maxwidth = (opts[:maxwidth] || 340).to_i
      maxheight = opts[:maxheight] ? opts[:maxheight].to_i : nil
      title_length = (opts[:title_length] || 40).to_i
      renderer.render_to_string :partial => '/post_stream/page/share', :locals => {:share => self, :post => self.post, :options => self.options, :maxwidth => maxwidth, :maxheight => maxheight, :title_length => title_length}
    end
  end
end


