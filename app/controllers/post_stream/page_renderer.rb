class PostStream::PageRenderer < ParagraphRenderer

  features '/post_stream/page_feature'

  paragraph :stream, :ajax => true
  paragraph :recent_posts
  paragraph :post

  def stream
    @options = paragraph_options(:stream)

    target = nil
    conn_type, conn_id = page_connection(:target)
    if conn_id
      target = conn_type == :target ? conn_id : conn_id[0].constantize.find_by_id(conn_id[1])
    end

    if conn_type && !conn_id
      return render_paragraph :nothing => true
    elsif editor?
      target = myself
    else
      return render_paragraph :text => 'Please setup page connections' unless target
    end

    PostStreamPoster.setup_header(self)

    @poster = PostStreamPoster.new myself, target, @options.to_h
    @poster.renderer = self
    @poster.post_page_node = @options.post_page_node
    @poster.page_connection_hash = page_connection_hash
    @poster.paragraph_options = @options

    conn_type, conn_id = page_connection(:post_permission)
    @poster.post_permission = true if conn_id || editor?

    conn_type, conn_id = page_connection(:admin_permission)
    @poster.admin_permission = true if conn_id || editor?

    conn_type, conn_id = page_connection(:content_list)
    @poster.view_targets = conn_id if conn_id

    @poster.setup(params)

    unless editor?
      if request.post?
        @poster.process_request(params)

        myself.reload if myself.id && myself.missing_name?

        if ajax?
          return render_paragraph :rjs => '/post_stream/page/update', :locals => @poster.get_locals
        else
          return redirect_paragraph :page
        end
      end
    end

    @stream_page = (params[:stream_page] || 1).to_i
    @has_more, @posts = @poster.fetch_posts(@stream_page, :post_types => @options.post_types_filter, :limit => @options.posts_per_page)

    if @stream_page > 1 && ajax?
      if @posts.empty?
        render_paragraph :inline => 'no_more'
      else
        render_paragraph :text => render_to_string(:partial => '/post_stream/page/posts', :locals => @poster.get_locals)
      end

      return
    end

    require_css('/components/post_stream/stylesheets/stream.css') unless paragraph.render_css
    render_paragraph :feature => :post_stream_page_stream
  end

  def recent_posts
    @options = paragraph_options(:recent_posts)

    results = renderer_cache(nil, nil, :expires => @options.cache_expires*60) do |cache|
      @poster = PostStreamPoster.new myself, nil, @options.to_h
      @poster.renderer = self
      @poster.post_page_node = @options.post_page_node
      @poster.paragraph_options = @options

      @poster.posts = PostStreamPost.with_types(@options.post_types_filter).find(:all, :limit => @options.posts_to_display, :order => 'posted_at DESC')
      @poster.fetch_comments(@poster.posts) if @options.show_comments

      if paragraph.site_feature
        cache[:output] = post_stream_page_recent_posts_feature(@poster.get_locals)
      else
        cache[:output] = render_to_string :partial => '/post_stream/page/stream', :locals => @poster.get_locals.merge(:attributes => {})
      end
    end

    PostStreamPoster.setup_header(self)

    require_css('/components/post_stream/stylesheets/stream.css') unless paragraph.render_css
    render_paragraph :text => results.output
  end

  def post
    @options = paragraph_options(:post)

    @poster = PostStreamPoster.new myself, nil, @options.to_h
    @poster.renderer = self
    @poster.post_page_node = site_node
    @poster.paragraph_options = @options

    if editor?
      @poster.fetch_first_post
    else
      conn_type, post_identifier = page_connection(:post_identifier)
      raise SiteNodeEngine::MissingPageException.new( site_node, language ) unless post_identifier
      raise SiteNodeEngine::MissingPageException.new( site_node, language ) unless @poster.fetch_post_by_identifier(post_identifier)
    end

    @poster.posts = @poster.post ? [@poster.post] : []
    @poster.fetch_comments(@poster.posts)

    PostStreamPoster.setup_header(self)

    if @poster.post
      @poster.posts = [@poster.post]
      @poster.fetch_comments(@poster.posts)

      self.html_include(:head_html, "<meta name='title' content='#{vh truncate(@poster.post.body, :length => 60)}' />")

      if @poster.post.preview_image_url
        self.html_include(:head_html, "<link rel='image_src' href='#{vh @poster.post.preview_image_url}' />")
      end
    end

    require_css('/components/post_stream/stylesheets/stream.css') unless paragraph.render_css
    render_paragraph :feature => :post_stream_page_post
  end

  protected

  def file_upload?
    params[:upload]
  end
end
