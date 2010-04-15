
class PostStream::PageFeature < ParagraphFeature

  include StyledFormBuilderGenerator::FormFor

  feature :post_stream_page_stream, :default_feature => <<-FEATURE
  <div class="post_stream_form">
    <cms:form>
      <cms:body/>
      <cms:handlers close='[X]'/>
      <div class="controls">
        <cms:share>
          <cms:buttons label="Share:"/>
        </cms:share>
  
        <cms:share_with>
          <cms:facebook/>
        </cms:share_with>
  
        <div class="post_stream_submit">
          <cms:submit/>
        </div>
      </div>
      <hr class="seperator"/>
    </cms:form>
  </div>

  <cms:stream/>
  FEATURE

  def post_stream_page_stream_feature(data)
    webiva_feature(:post_stream_page_stream,data) do |c|
      c.form_for_tag('form','stream_post', :html => {:multipart => true, :id => 'stream_post_form', :onsubmit => "PostStreamForm.onsubmit('#{self.ajax_url}', 'stream_post_form'); return false;"}) { |t| t.locals.stream_post = data[:poster].post if data[:poster].can_post? }

      c.define_tag('form:body') do |t|
        rows = data[:poster].post.handler ? (t.attr['active_rows'] || 3) : (t.attr['rows'] || 1)
        onfocus = data[:poster].post.handler ? nil : 'PostStreamForm.bodyOnFocus();'
        script = "<script>PostStreamForm.inactiveRows = #{t.attr['rows'] || 1}; PostStreamForm.activeRows = #{t.attr['active_rows'] || 3};</script>\n"
        script + '<div class="body">' + t.locals.form.text_area(:body, {:rows => rows, :onfocus => onfocus}.merge(t.attr)) + '</div>'
      end

      c.define_tag('form:handlers') do |t|
        t.locals.share_components_close = t.attr['close'] || '[X]'
        t.locals.share_components_close_image = t.attr['close_image']

        output = t.locals.form.hidden_field :handler
        output << '<div class="stream_post_handlers">'
        output << (t.single? ? self.render_handler_forms(t, data) : t.expand)
        output << '</div>'
      end

      c.define_tag('form:handlers:handler') do |t|
        title = t.single? ? t.attr['title'] : t.expand
        handler = data[:poster].get_handler_by_type(t.attr['type'])
        self.render_handler_form(handler, t, data, {'title' => title, 'close' => t.locals.share_components_close, 'close_image' => t.locals.share_components_close_image}.merge(t.attr))
      end

      c.define_tag('form:share') do |t|
        '<div id="post_stream_share" class="post_stream_share">' + t.expand + '&nbsp;</div>'
      end

      c.define_tag('form:share:buttons') do |t|
        style = data[:poster].post.handler ? "style='display:none;'" : ''
        output = "<ul id='post_stream_share_buttons' class='post_stream_share_buttons' #{style}>"
        output << "<li class='label'>#{t.attr['label']}</li>" unless t.attr['label'].blank?

        if t.single?
          output << ("<li class='button'>" + data[:poster].handlers.collect{ |handler| handler.render_button }.join("</li><li class='button'>") + "</li>")
        else
          output << t.expand
        end
        output << '</ul>'
      end

      c.define_tag('form:share:buttons:button') do |t|
        title = t.attr['title'] || t.expand
        handler = data[:poster].get_handler_by_type(t.attr['type'])
        handler ? '<li class="button">' + handler.render_button('title' => title) + '</li>' : ''
      end

      c.define_tag('form:share_with') do |t|
        '<div class="post_stream_share_with">' + t.expand + '</div>'
      end

      c.define_tag('form:share_with:facebook') do |t|
        content = t.single? ? 'post on facebook' : t.expand
        '<label>' + check_box(:stream_post, 'post_on_facebook') + " #{content}</label>"
      end

      c.submit_tag('form:submit', :default => 'Post')

      c.define_tag('stream') { |t| render_to_string :partial => '/post_stream/page/stream', :locals => data.merge(:paragraph => paragraph, :renderer => self.renderer) }
    end
  end

  def render_handler_forms(t, data)
    data[:poster].handlers.collect { |handler| self.render_handler_form(handler, t, data, t.attr) }.join("\n")
  end

  def render_handler_form(handler, t, data, opts={})
    cms_unstyled_fields_for(handler.form_name, handler.options) do |f|
      handler.render_form(self.renderer, f, opts)
    end
  end
end
