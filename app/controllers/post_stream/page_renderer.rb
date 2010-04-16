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

    unless ajax?
      require_js('prototype')
      require_js('/components/post_stream/javascript/post_stream.js')

      PostStreamPoster.setup_header(self)
    end

    if @poster.can_post?

      unless editor?
        handle_file_upload(params[:stream_post], 'domain_file_id', {:folder => @options.folder_id}) if request.post? && params[:stream_post]

        @poster.setup_post(params[:stream_post])
        @poster.process_request(params)

        if request.post?
          if ajax?
            @saved = @poster.save
            new_post_output = ''
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
                new_post_output = render_to_string(:partial => '/post_stream/page/new_post', :locals => {:post => @poster.post, :renderer => self, :poster => @poster})
                @poster.setup_post nil
              end

              @partial_feature = 'form'
              form_output = webiva_post_process_paragraph(post_stream_page_stream_feature)
            end

            render_paragraph :rjs => '/post_stream/page/update', :locals => {:saved => @saved, :form_output => form_output, :new_post_output => new_post_output, :post => @poster.post, :renderer => self, :poster => @poster}
            return
          else
            if @poster.save
              return redirect_paragraph :page
            end
          end
        end
      end
    end

    @has_more, @posts = @poster.fetch_posts(params[:stream_page], :post_types => @options.post_types_filter)

    css_style = render_to_string(:partial => '/post_stream/page/form_css')
    output = post_stream_page_stream_feature
    render_paragraph :text => css_style + output
  end

end
