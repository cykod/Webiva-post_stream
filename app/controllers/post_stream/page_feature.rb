
class PostStream::PageFeature < ParagraphFeature

  feature :post_stream_page_stream, :default_feature => <<-FEATURE
  <div class="post_stream_form">
    <cms:form>
      <cms:body/>
      <cms:share_components close='[X]'/>
      <div class="controls">
        <cms:share>
  
          <cms:buttons>
            <li class="label">Share: </li>
            <cms:link>Link</cms:link>
          </cms:buttons>
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
      c.form_for_tag('form','stream_post', :html => {:multipart => true}) { |t| t.locals.stream_post = data[:poster].post if data[:poster].can_post? }

      c.define_tag('form:body') do |t|
        '<div class="body">' + t.locals.form.text_area(:body, {:rows => 1, :onfocus => 'PostStreamForm.bodyOnFocus();'}.merge(t.attr)) + '</div>'
      end

      c.define_tag('form:share_components') do |t|
        t.locals.share_components_close = t.attr['close'] || '[X]'
        self.render_form_handlers(t, data)
      end

      c.define_tag('form:share') do |t|
        '<div id="post_stream_share" class="post_stream_share">' + t.expand + '&nbsp;</div>'
      end

      c.define_tag('form:share:buttons') do |t|
        '<ul id="post_stream_share_buttons" class="post_stream_share_buttons">' + t.expand + '</ul>'
      end

      c.define_tag('form:share:buttons:link') do |t|
        content = t.single? ? 'Link' : t.expand
        '<li class="button">' + content_tag(:a, content, {:href => 'javascript:void(0);', :onclick => 'PostStreamForm.share("link");'}) + '</li>'
      end

      c.define_tag('form:share_with') do |t|
        '<div class="post_stream_share_with">' + t.expand + '</div>'
      end

      c.define_tag('form:share_with:facebook') do |t|
        content = t.single? ? 'post on facebook' : t.expand
        '<label>' + check_box(:stream_post, 'post_on_facebook') + " #{content}</label>"
      end

      c.submit_tag('form:submit', :default => 'Post')

      c.define_tag('stream') { |t| render_to_string :partial => '/post_stream/page/stream', :locals => data.merge(:paragraph => paragraph) }
    end
  end

  def render_form_handlers(t, data)
    output = '<div class="stream_post_handlers">'
    output << self.render_link_handler(t, data)
    output << '</div>'
    output
  end

  def render_link_handler(t, data)
    <<-HANDLER
    <div id="post_stream_handler_form_link" class="post_stream_handler_form" style="display:none;">
      <div class="title_bar">
        <span class="title">Link</span>
        <span class="close_button"><a href="javascript:void(0);" onclick="PostStreamForm.close();">#{t.locals.share_components_close}</a></span>
      </div>
      <div class="handler_form">
        #{t.locals.form.text_field :link}
      </div>
    </div>
    HANDLER
  end
end
