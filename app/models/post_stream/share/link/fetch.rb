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

    return nil if uri.host.downcase.include?("facebook.com")

    body = self.fetch(uri)
    return nil unless body

    doc = Nokogiri::HTML(body)

    self.post_type = 'link'

    self.data[:title] = self.title(doc)
    self.data[:description] = self.description(doc)
    self.data[:author_name] = self.author_name(doc)
    self.data[:provider_name] = self.provider_name(doc, uri)
    self.data[:provider_url] = self.provider_url(doc, uri)

    image_url = self.image_url(doc)
    if image_url
      image_size = DomainFile.remote_image_size(image_url)
      if image_size
        self.data[:image_url] = image_url
        self.data[:width] = image_size[0]
        self.data[:height] = image_size[1]
        self.post_type = 'image'
      end
    end

    self.data[:title].blank? ? false : true
  end

  def title(doc)
    title = self.ogdata(doc, 'title')
    return title if title

    title = self.metadata(doc, 'title')
    return title if title

    title_node = doc.css('title').first
    return title_node.content if title_node
    nil
  end

  def description(doc)
    description = self.ogdata(doc, 'description')
    return description if description

    description = self.metadata(doc, 'description')
    return description if description

    nil
  end

  def image_url(doc)
    image_url = self.ogdata(doc, 'image')
    return image_url if image_url

    image_src_node = self.find_node(doc, 'link', 'rel', 'image_src')
    return image_src_node[:href] if image_src_node && ! image_src_node['href'].blank?

    nil
  end

  def author_name(doc)
    self.metadata(doc, 'author')
  end

  def author_url(doc)
    nil
  end

  def provider_name(doc, uri)
    provider_name = self.ogdata(doc, 'site_name')
    return provider_name if provider_name

    uri.host.sub(/^www\./, '')
  end

  def provider_url(doc, uri)
    "http://#{uri.host}/"
  end

  def metadata(doc, name)
    node = self.find_node(doc, 'meta', 'name', name)
    node && ! node['content'].blank? ? node['content'] : nil
  end

  def ogdata(doc, name)
    node = self.find_node(doc, 'meta', 'property', "og:#{name}")
    return node['content'] if node && ! node['content'].blank?
    self.metadata(doc, "og:#{name}")
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
    rescue Exception => e
      Rails.logger.error "failed to fetch: #{url}, #{e}"
    end

    nil
  end
end
