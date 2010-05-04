require 'nokogiri'
require 'net/http'

class PostStream::Share::Link::Fetch < PostStream::Share::Link::Base
  def self.post_stream_link_handler_info
    {
      :name => 'Fetch Link Handler',
      :post_types => ['image', 'link']
    }
  end

  def process_request(renderer, params, opts={})
    uri = nil
    begin
      uri = URI.parse(self.link)
    rescue URI::InvalidURIError => e
      return nil
    end

    return nil unless uri.scheme == 'http'
    return nil unless uri.port == 80

    body = self.fetch(uri)
    return nil unless body

    doc = Nokogiri::HTML(body)

    title = self.title(doc)
    description = self.metadata(doc, 'description')
    author = self.metadata(doc, 'author')

    self.post_type = 'link'

    self.data[:title] = title if title
    self.data[:description] = description if description
    self.data[:author_name] = author if author

    image_src_node = self.find_node(doc, 'link', 'rel', 'image_src')
    if image_src_node && ! image_src_node['href'].blank?
      self.post_type = 'image'
      self.data[:image_url] = image_src_node['href']
    end

    unless self.data.empty?
      self.data[:provider_name] = uri.host.sub(/^www\./, '')
      self.data[:provider_url] = "http://#{uri.host}/"
    end

    self.data.empty? ? false : true
  end

  def title(doc)
    title = self.metadata(doc, 'title')
    return title if title

    title_node = doc.css('title').first
    return title_node.content if title_node
    nil
  end

  def metadata(doc, name)
    node = self.find_node(doc, 'meta', 'name', name)
    node && ! node['content'].blank? ? node['content'] : nil
  end

  def find_node(doc, tag, name, value)
    doc.xpath("//#{tag}[translate(@#{name},'ABCDEFGHIJKLMNOPQRSTUVWXYZ','abcdefghijklmnopqrstuvwxyz')='#{value}']").first
  end

  def fetch(url)
    begin
      response = DomainFile.download(url)
      return response.body
    rescue URI::InvalidURIError => e
      return nil
    rescue Exeception => e
      Rails.logger.error "failed to fetch: #{url}, #{e}"
    end

    nil
  end
end
