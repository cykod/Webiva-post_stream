
class PostStream::Share::File < PostStream::Share::Base
  attr_accessor :supported_post_types

  def self.post_stream_share_handler_info
    {
      :name => 'File'
    }
  end

  def valid_params
    [:domain_file_id]
  end

  def valid?
    is_valid = super

    if self.options.errors[:file_id]
      error = self.options.errors[:file_id]
      error = error[0] if error.is_a?(Array)
      self.post.errors.add_to_base('Upload file ' + error)
      return false
    end

    is_valid
  end

  def render_form_elements(renderer, form, opts={})
    form.upload_image :file
  end

  def process_request(renderer, params, opts={})
    if renderer.request.post? && params[self.form_name]
      renderer.handle_file_upload(params[self.form_name], 'file_id', {:folder => opts[:folder_id]})
    end

    self.post.domain_file_id = self.options.file_id
  end

  def render(renderer, opts={})
    self.post.domain_file.image_tag if self.post.domain_file
  end

  def preview_image_url
    self.post.domain_file.full_url if self.post.domain_file
  end

  class Options < HashModel
    attributes :file_id => nil

    validates_presence_of :file_id
  end
end
