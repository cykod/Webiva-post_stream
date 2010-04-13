
class PostStream::Share::Link::Youtube < PostStream::Share::Link::Base
  include ActionView::Helpers::TagHelper

  def self.post_stream_link_handler_info
    {
      :name => 'Youtube Link Handler',
      :post_types => ['media']
    }
  end

  def process_request(params)
    self.post.link =~ /youtube/i
  end

  def render(renderer)
    'Youtube Link: %s' / content_tag(:a, self.post.link, {:href => self.post.link, :rel => 'nofollow', :target => '_blank'})
  end

  class Options < HashModel
  end
end
