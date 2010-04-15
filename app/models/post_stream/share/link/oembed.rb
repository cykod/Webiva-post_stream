require 'oembed_links'
require 'nokogiri'
require 'net/http'

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

  def process_request(params, opts={})
    maxwidth = opts[:maxwidth] || '340'
    maxheight = opts[:maxheight] ? opts[:maxheight].to_s : nil
    OEmbed.transform(self.link, false, {'maxwidth' => maxwidth.to_s, 'maxheight' => maxheight}.delete_if{|k,v| v.blank?}) do |r, url|
      r.video? { |d| self.options.data = d; '' }
      r.photo? { |d| self.options.data = d; '' }
      r.audio? { |d| self.options.data = d; '' }
      r.rich? { |d| self.options.data = d; '' }
      r.link? { |d| self.options.data = d; '' }
    end

    self.options.data.empty? ? false : true
  end

  def render(renderer, opts={})
    maxwidth = (opts[:maxwidth] || 340).to_i
    maxheight = opts[:maxheight] ? opts[:maxheight].to_i : nil
    title_length = (opts[:title_length] || 40).to_i
    renderer.render_to_string :partial => '/post_stream/share/link/oembed', :locals => {:post => self.post, :options => self.options, :maxwidth => maxwidth, :maxheight => maxheight, :title_length => title_length}
  end

  class Options < HashModel
    attributes :data => {}
  end

  class WebivaNetHTTP
    def name
      "WebivaNetHTTP"
    end

    def fetch(url)
      Rails.logger.error "fetching: #{url}"
      uri = URI.parse(url)
      Net::HTTP.start(uri.host, uri.port) do |http|
        http.request_get("#{uri.path}?#{uri.query}", {'User-Agent' => 'Webiva'}) do |response|
          begin
            response.value
            return response.body
          rescue
            Rails.logger.error "failed to fetch: #{url}"
          end
        end
      end
      nil
    end
  end

  class JSON < OEmbed::Formatters::JSON
    def format(txt)
      return {} if txt.blank?
      super(txt)
    end
  end

  class XML < OEmbed::Formatters::LibXML
    def format(txt)
      return {} if txt.blank?
      super(txt)
    end
  end
end

OEmbed.register_fetcher(PostStream::Share::Link::Oembed::WebivaNetHTTP)
OEmbed.register_formatter(PostStream::Share::Link::Oembed::JSON)
OEmbed.register_formatter(PostStream::Share::Link::Oembed::XML)
