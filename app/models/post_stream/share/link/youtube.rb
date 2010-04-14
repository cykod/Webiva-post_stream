require 'nokogiri'

class PostStream::Share::Link::Youtube < PostStream::Share::Link::Base
  include ActionView::Helpers::TagHelper

  def self.post_stream_link_handler_info
    {
      :name => 'Youtube Link Handler',
      :post_types => ['media']
    }
  end

  def self.setup_header(renderer)
    renderer.require_js('/components/post_stream/javascript/youtube.js')
  end

  def youtube_rss(video_key)
    "http://gdata.youtube.com/feeds/api/videos/#{video_key}"
  end

  def process_request(params)
    if self.link =~ /^http\:\/\/(www|)\.youtube\.com\/watch\?v\=([^&]+)/i
      video_key = $2
      vid_url = URI.parse(youtube_rss(video_key))
      res = Net::HTTP.get(vid_url)

      doc =  Nokogiri::XML(res)
      vid = doc.at('entry')

      return false unless vid

      self.options.video_key = video_key
      self.options.thumbnail = doc.xpath('//media:thumbnail')[0].attributes['url'].to_s
      self.options.title = doc.xpath('//media:title')[0].inner_html

      true
    end
  end

  def render(renderer)
    if self.options.video_key
      renderer.render_to_string :partial => '/post_stream/share/link/youtube', :locals => {:post => self.post, :options => self.options}
    else
      'Youtube Link: %s' / content_tag(:a, self.post.link, {:href => self.post.link, :rel => 'nofollow', :target => '_blank'})
    end
  end

  class Options < HashModel
    attributes :video_key => nil, :thumbnail => nil, :title => nil
  end
end
