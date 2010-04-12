class PostStream::PageRenderer < ParagraphRenderer

  features '/post_stream/page_feature'

  paragraph :stream

  def stream
    @options = paragraph_options(:stream)

    require_js('prototype')
    require_js('/components/post_stream/javascript/post_stream.js')

    target = nil
    conn_type, conn_id = page_connection(:target)
    if conn_id
      target = conn_type == :target ? conn_id : conn_type.constantize.find_by_id(conn_id)
    end

    return render_paragraph :text => 'Please setup page connections' unless target

    @poster = PostStreamPoster.new myself, target

    conn_type, conn_id = page_connection(:post_permission)
    @poster.post_permission = true if conn_id

    conn_type, conn_id = page_connection(:admin_permission)
    @poster.admin_permission = true if conn_id

    if @poster.can_post?

      handle_file_upload(params[:stream_post], 'domain_file_id', {:folder => @options.folder_id}) if request.post? && ! editor?

      @poster.setup_post(params[:stream_post])

      if request.post? && @poster.valid? && ! editor?
        if @poster.save
        end
      end
    end

    @has_more, @posts = @poster.fetch_posts(params[:stream_page], :post_types => @options.post_types_filter)

    css_style = render_to_string(:partial => '/post_stream/page/form_css')
    output = post_stream_page_stream_feature
    render_paragraph :text => css_style + output
  end

end
