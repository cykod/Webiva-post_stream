class PostStream::PageRenderer < ParagraphRenderer

  features '/post_stream/page_feature'

  paragraph :stream

  def stream
    @options = paragraph_options(:stream)

    target = nil
    conn_type, conn_id = page_connection(:target)
    if conn_id
      target = conn_type == :target ? conn_id : conn_type.constantize.find_by_id(conn_id)
    end

    @poster = PostStreamPoster.new myself, target

    conn_type, conn_id = page_connection(:post_permission)
    @poster.post_permission = true if conn_id

    conn_type, conn_id = page_connection(:admin_permission)
    @poster.admin_permission = true if conn_id

    if @poster.can_post?
      @poster.setup_post(params['post'])

      if request.post? && @poster.valid?
        if @poster.save
        end
      end
    end

    render_paragraph :feature => :post_stream_page_stream
  end

end
