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
      :post_types => ['media', 'image', 'link']
    }
  end

  def process_request(renderer, params, opts={})
    maxwidth = opts[:maxwidth] || '340'
    maxheight = opts[:maxheight] ? opts[:maxheight].to_s : nil
    OEmbed.transform(self.link, false, {'maxwidth' => maxwidth.to_s, 'maxheight' => maxheight}.delete_if{|k,v| v.blank?}) do |r, url|
      r.video? { |d| self.post_type = 'media'; self.data = d.to_hash.symbolize_keys; '' }
      r.photo? { |d| self.post_type = 'image'; self.data = d.to_hash.symbolize_keys; '' }
      r.rich? { |d| self.post_type = 'media'; self.data = d.to_hash.symbolize_keys; '' }
      r.link? { |d| self.post_type = 'link'; self.data = d.to_hash.symbolize_keys; '' }
    end

    unless self.data.empty?
      if self.data[:type] == 'video' || self.data[:type] == 'rich'
        if self.data[:html].blank?
          self.data[:type] = 'photo'
          self.data[:image_url] = self.data[:thumbnail_url]
          self.data[:width] = self.data[:thumbnail_width]
          self.data[:height] = self.data[:thumbnail_height]
        end
      elsif self.data[:type] == 'photo'
        self.data[:image_url] = self.data[:url]
      end
    end

    self.data.empty? ? false : true
  end

  class WebivaNetHTTP
    def name
      "WebivaNetHTTP"
    end

    def fetch(url)
      uri = nil
      begin
        uri = URI.parse(url)
      rescue URI::InvalidURIError => e
        return nil
      end

      link = uri.query.split('&').find { |arg| arg =~ /^url=/ }
      return nil unless link

      link = CGI::unescape(link.sub('url=', ''))
      return nil unless PostStream::AdminController.allowed_oembed_link?(link)

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
