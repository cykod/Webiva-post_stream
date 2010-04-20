
class PostStream::Share::MediaLink < PostStream::Share::Link
  def self.post_stream_share_handler_info
    {
      :name => 'Media Link'
    }
  end

  def initialize(post)
    super(post)
    self.supported_post_types = ['image', 'media']
  end

  def options(opts={})
    return @options if @options
    super(opts)
    @options.handler_required = true
    @options
  end

  class Options < PostStream::Share::Link::Options
  end
end
