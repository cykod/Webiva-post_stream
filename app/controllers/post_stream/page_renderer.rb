class PostStream::PageRenderer < ParagraphRenderer

  features '/post_stream/page_feature'

  paragraph :stream, :ajax => true

  def stream
    @options = paragraph_options(:stream)
    @page_connection_hash =  page_connection_hash

    target = nil
    conn_type, conn_id = page_connection(:target)
    if conn_id
      target = conn_type == :target ? conn_id : conn_type.constantize.find_by_id(conn_id)
    end

    return render_paragraph :text => 'Please setup page connections' unless target

    @poster = PostStreamPoster.new myself, target, @options.to_h

    conn_type, conn_id = page_connection(:post_permission)
    @poster.post_permission = true if conn_id

    conn_type, conn_id = page_connection(:admin_permission)
    @poster.admin_permission = true if conn_id

    conn_type, post_identifier = page_connection(:post_identifier)

    raise SiteNodeEngine::MissingPageException.new( site_node, language ) unless @poster.fetch_post(post_identifier)
    @show_post_form = @poster.post.nil? ? true : false

    unless ajax?
      require_js('prototype')
      require_js('effects')
      require_js('/components/post_stream/javascript/post_stream.js')

      PostStreamPoster.setup_header(self)
    end

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

    if @poster.can_post?

      unless editor?
        handle_file_upload(params[:stream_post], 'domain_file_id', {:folder => @options.folder_id}) if request.post? && params[:stream_post]

        @poster.setup_post(params[:stream_post]) unless @poster.post
        @poster.process_request(params)

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

    if @poster.post.id
      @has_more = false
      @posts = [@poster.post]
    else
      @has_more, @posts = @poster.fetch_posts(@stream_page, :post_types => @options.post_types_filter, :limit => @options.posts_per_page)
    end

    render_paragraph :feature => :post_stream_page_stream
  end

end
