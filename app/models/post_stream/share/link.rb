
class PostStream::Share::Link < PostStream::Share::Base

  def self.post_stream_share_handler_info
    {
      :name => 'Link'
    }
  end

  def render_form_elements(form, opts={})
    form.text_field :link
  end

  def process_request(params)
    self.post.link = self.options.link
  end

  def render(renderer)
    'Link: %s' / content_tag(:a, self.post.link, {:href => self.post.link, :rel => 'nofollow', :target => '_blank'})
  end

  class Options < HashModel
    attributes :link => nil

    validates_presence_of :link
    validates_urlness_of :link, :allow_nil => true
  end
end
