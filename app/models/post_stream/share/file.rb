
class PostStream::Share::File < PostStream::Share::Base
  attr_accessor :supported_post_types

  def self.post_stream_share_handler_info
    {
      :name => 'File'
    }
  end

  def valid_params
    [:file_id]
  end

  def valid?
    is_valid = super

    if ! self.options.errors[:file_id].empty?
      error = self.options.errors[:file_id][0]
      self.post.errors.add_to_base('File ' + error)
      return false
    end

    is_valid
  end

  def render_form_elements(renderer, form, opts={})
    return '' if renderer.editor?
    renderer.render_to_string :partial => '/post_stream/share/file_form', :locals => {:renderer => renderer, :form => form}
  end

  def process_request(renderer, params, opts={})
    self.options.file_id = nil unless self.options.file && self.options.file.creator_id == renderer.myself.id && renderer.myself.id
    self.post.domain_file_id = self.options.file_id
    self.post.post_type = 'image'
  end

  def name
    self.post.domain_file.name
  end

  def image_url
    self.post.domain_file.url :small
  end

  def link
    self.post.domain_file.full_url
  end

  def width
    self.post.domain_file.width :small
  end

  def height
    self.post.domain_file.height :small
  end

  def author_name
    self.post.end_user.name if self.post.end_user
  end

  def provider_name
    Configuration.domain
  end

  def provider_url
    Configuration.domain_link '/'
  end

  def render(renderer, opts={})
    super if self.post.domain_file
  end

  class Options < HashModel
    attributes :file_id => nil
    validates_presence_of :file_id
    domain_file_options :file_id

    def validate
      self.errors.add(:file_id, 'must be an image') if self.file && ! self.file.image?
    end
  end
end
