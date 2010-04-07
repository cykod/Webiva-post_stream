class PostStream::PageRenderer < ParagraphRenderer

  features '/post_stream/page_feature'

  paragraph :stream

  def stream
    @options = paragraph_options(:stream)

    render_paragraph :feature => :post_stream_page_stream
  end

end
