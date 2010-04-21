class PostStream::PageRenderer < ParagraphRenderer

  features '/post_stream/page_feature'

  paragraph :stream, :ajax => true
  paragraph :recent_posts
  paragraph :post

  def stream
    @options = paragraph_options(:stream)
    @page_connection_hash =  page_connection_hash

    target = nil
    conn_type, conn_id = page_connection(:target)
    if conn_id
      target = conn_type == :target ? conn_id : conn_id[0].constantize.find_by_id(conn_id[1])
    end

    if conn_type && !conn_id
      return render_paragraph :nothing => true
    else
      return render_paragraph :text => 'Please setup page connections' unless target
    end

    @poster = PostStreamPoster.new myself, target, @options.to_h

    conn_type, conn_id = page_connection(:post_permission)
    @poster.post_permission = true if conn_id

    conn_type, conn_id = page_connection(:admin_permission)
    @poster.admin_permission = true if conn_id

    @stream_page = (params[:stream_page] || 1).to_i
    if @stream_page > 1
      @has_more, @posts = @poster.fetch_posts(@stream_page, :post_types => @options.post_types_filter, :limit => @options.posts_per_page)
      if @posts.empty?
        render_paragraph :inline => 'no_more'
      else
        render_paragraph :inline => render_to_string(:partial => '/post_stream/page/posts', :locals => {:posts => @posts, :renderer => self, :poster => @poster, :site_node => site_node, :has_more => @has_more, :stream_page => @stream_page})
      end

      return
    end

    require_js('prototype')
    require_js('effects')
    require_js('/components/post_stream/javascript/post_stream.js')

    PostStreamPoster.setup_header(self)

    if @poster.can_post?

      unless editor?
        handle_file_upload(params[:stream_post], 'domain_file_id', {:folder => @options.folder_id}) if request.post? && params[:stream_post]

        @poster.setup_post(params[:stream_post]) unless @poster.post
        @poster.process_request(self, params)

        if request.post?
          if ajax?
            @saved = @poster.save

            myself.reload if @saved && myself.id && myself.missing_name?

            new_post_output = ''
            new_post = nil
            form_output = ''
            if @poster.comment
              if @saved
                new_post_output = render_to_string(:partial => '/post_stream/page/new_comment', :locals => {:post => @poster.post, :renderer => self, :poster => @poster, :comment => @poster.comment})
              else
                # in this situation they were not allowed to comment on this post
                render_paragraph :inline => '' if @poster.post.id.nil?
                return
              end

              form_output = render_to_string(:partial => '/post_stream/page/comment_form', :locals => {:post => @poster.post, :renderer => self, :poster => @poster})
            else
              if @saved
                new_post_output = render_to_string(:partial => '/post_stream/page/new_post', :locals => {:post => @poster.post, :renderer => self, :poster => @poster, :site_node => site_node})
                new_post = @poster.post
                @poster.setup_post nil
              end

              @partial_feature = 'form'
              form_output = webiva_post_process_paragraph(post_stream_page_stream_feature)
            end

            render_paragraph :rjs => '/post_stream/page/update', :locals => {:saved => @saved, :form_output => form_output, :new_post_output => new_post_output, :post => @poster.post, :renderer => self, :poster => @poster, :new_post => new_post}
            return
          else
            if @poster.save
              return redirect_paragraph :page
            end
          end
        end
      end
    end

    @has_more, @posts = @poster.fetch_posts(@stream_page, :post_types => @options.post_types_filter, :limit => @options.posts_per_page)

    if self.file_upload?
      return render_paragraph :inline => ''
    end

    render_paragraph :feature => :post_stream_page_stream
  end

  def recent_posts
    @options = paragraph_options(:recent_posts)

    results = renderer_cache(nil, nil, :expires => @options.cache_expires*60) do |cache|
      @page_connection_hash = nil
      @poster = PostStreamPoster.new myself, nil, @options.to_h
      @has_more = false
      @stream_page = 1
      @posts = PostStreamPost.with_types(@options.post_types_filter).find(:all, :limit => @options.posts_to_display, :order => 'posted_at DESC')
      @poster.fetch_comments(@posts) if @options.show_comments

      if paragraph.site_feature
        cache[:output] = post_stream_page_recent_posts_feature
      else
        cache[:output] = render_to_string :partial => '/post_stream/page/stream', :locals => {:poster => @poster, :has_more => @has_more, :stream_page => @stream_page, :page_connection_hash => @page_connection_hash, :posts => @posts, :paragraph => paragraph, :renderer => self, :site_node => site_node}
      end
    end

    require_js('prototype')
    require_js('effects')
    require_js('/components/post_stream/javascript/post_stream.js')
    PostStreamPoster.setup_header(self)

    require_css('/components/post_stream/stylesheets/stream.css') unless paragraph.render_css
    render_paragraph :text => results.output
  end

  def post
    @options = paragraph_options(:post)

    @page_connection_hash = nil
    @poster = PostStreamPoster.new myself, nil, @options.to_h

    if editor?
      @poster.fetch_first_post
    else
      conn_type, post_identifier = page_connection(:post_identifier)
      raise SiteNodeEngine::MissingPageException.new( site_node, language ) unless post_identifier
      raise SiteNodeEngine::MissingPageException.new( site_node, language ) unless @poster.fetch_post_by_identifier(post_identifier)
    end

    @has_more = false
    @stream_page = 1
    @posts = []
    @posts << @poster.post if @poster.post
    @poster.fetch_comments(@posts)

    require_js('prototype')
    require_js('effects')
    require_js('/components/post_stream/javascript/post_stream.js')
    PostStreamPoster.setup_header(self)

    if @poster.post
      self.html_include(:head_html, "<meta name='title' content='#{vh truncate(@poster.post.body, :length => 60)}' />")

      if @poster.post.preview_image_url
        self.html_include(:head_html, "<link rel='image_src' href='#{vh @poster.post.preview_image_url}' />")
      end
    end

    render_paragraph :feature => :post_stream_page_post
  end

  protected

  def file_upload?
    params[:upload]
  end
end
