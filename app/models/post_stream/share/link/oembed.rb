require 'oembed_links'

yaml_file = File.join(File.dirname(__FILE__), '../../../../..', "config", "oembed_links.yml")
if File.exists?(yaml_file)
  OEmbed::register_yaml_file(yaml_file)
end

class PostStream::Share::Link::Oembed < PostStream::Share::Link::Base
  def self.post_stream_link_handler_info
    {
      :name => 'Oembed Link Handler',
      :post_types => ['media', 'images']
    }
  end

  def self.setup_header(renderer)
    renderer.require_js('/components/post_stream/javascript/oembed.js')
  end

  def process_request(params)
    OEmbed.transform(self.link, false, 'maxwidth' => '340') do |r, url|
      r.video? { |d| self.options.data = d; '' }
      r.photo? { |d| self.options.data = d; '' }
    end

    self.options.data.empty? ? false : true
  end

  def render(renderer)
    renderer.render_to_string :partial => '/post_stream/share/link/oembed', :locals => {:post => self.post, :options => self.options}
  end

  class Options < HashModel
    attributes :data => {}
  end
end
