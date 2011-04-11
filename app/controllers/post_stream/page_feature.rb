
class PostStream::PageFeature < ParagraphFeature

  include StyledFormBuilderGenerator::FormFor
  include ActionView::Helpers::DateHelper
  extend ActionView::Helpers::DateHelper

  def self.site_feature_social_unit_location_handler_info
    {
      :name => 'Recent Post'
    }
  end

  feature :post_stream_page_stream,
    :default_css_file => '/components/post_stream/stylesheets/stream.css',
    :default_feature => <<-FEATURE
  <div class="post_stream_form">
    <cms:form>
      <cms:errors prefix="* "><div class="errors"><cms:value/></div></cms:errors>
      <cms:no_name>
        <cms:name/>
      </cms:no_name>
      <cms:body/>
      <cms:handlers close='[X]'/>
      <div class="controls">
        <cms:share>
          <cms:buttons label="Share:"/>
        </cms:share>
  
        <cms:share_with>
          <cms:targets/>
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
      formClass = data[:poster].was_submitted? ? 'post_stream_active' : 'post_stream_inactive'
      c.form_for_tag('form','stream_post', :html => {:multipart => true, :id => 'stream_post_form', :class => formClass, :onsubmit => "PostStreamForm.onsubmit('#{self.ajax_url}', 'stream_post_form'); return false;"}) { |t| t.locals.stream_post = data[:poster].post if data[:poster].can_post? }

      c.value_tag('form:errors') do |t|
        errors = []
        
        errors << t.locals.stream_post.errors[:base] unless t.locals.stream_post.errors[:base].empty?

        errors << "Body #{t.locals.stream_post.errors[:body]}" unless t.locals.stream_post.errors[:body].empty?

        prefix = t.attr['prefix'] || ''
        postfix = t.attr['postfix'] || ''
        spacer = t.attr['spacer'] || '<br/>'
        errors.empty? ? nil : prefix + errors.join("#{postfix}#{spacer}#{prefix}") + postfix
      end

      c.expansion_tag('form:no_name') { |t| myself.missing_name? }
      c.define_tag('form:name') do |t|
        content_tag :div, 'Name:'.t + ' ' + t.locals.form.text_field(:name, t.attr), {:class => 'name'}, false
      end

      c.define_tag('form:body') do |t|
        content_tag :div, t.locals.form.text_area(:body, {:onfocus => 'PostStreamForm.bodyOnFocus();'}.merge(t.attr)), {:class => 'body'}, false
      end

      c.define_tag('form:handlers') do |t|
        t.locals.share_components_close = t.attr['close'] || '[X]'
        t.locals.share_components_close_image = t.attr['close_image']

        output = t.locals.form.hidden_field :handler
        output << content_tag(:div, (t.single? ? self.render_handler_forms(t, data) : t.expand), {:class => "stream_post_handlers"}, false)
      end

      c.define_tag('form:handlers:handler') do |t|
        title = t.single? ? t.attr['title'] : t.expand
        handler = data[:poster].get_handler_by_type(t.attr['type'])
        self.render_handler_form(handler, t, data, {'title' => title, 'close' => t.locals.share_components_close, 'close_image' => t.locals.share_components_close_image}.merge(t.attr))
      end

      c.define_tag('form:share') do |t|
        content_tag :div, "#{t.expand}&nbsp;", {:id => 'post_stream_share', :class => 'post_stream_share'}, false
      end

      c.define_tag('form:share:buttons') do |t|
        style = data[:poster].post.handler ? "style='display:none;'" : ''
        output = ''
        output = "<li class='label'>#{t.attr['label']}</li>" unless t.attr['label'].blank?

        if t.single?
          output << ("<li class='button'>" + data[:poster].handlers.collect{ |handler| handler.render_button }.join("</li><li class='button'>") + "</li>")
        else
          output << t.expand
        end
        content_tag :ul, output, {:id => 'post_stream_share_buttons', :class => 'post_stream_share_buttons'}, false
      end

      c.define_tag('form:share:buttons:button') do |t|
        title = t.attr['title'] || t.expand
        handler = data[:poster].get_handler_by_type(t.attr['type'])
        handler ? content_tag(:li, handler.render_button('title' => title) ,{:class => "button"}, false) : ''
      end

      c.define_tag('form:share_with') do |t|
        content_tag :div, t.expand, {:class => 'post_stream_share_with'}, false
      end

      c.define_tag('form:share_with:facebook') do |t|
        if data[:poster].can_post_to_facebook?
          content = t.single? ? 'Post to Facebook' : t.expand
          content_tag :div, t.locals.form.check_boxes(:post_on_facebook, [[content, true]], :single => true), {:class => 'facebook'}, false
        end
      end

      c.define_tag('form:share_with:targets') do |t|
        unless data[:poster].additional_targets.empty?
          content = data[:poster].additional_targets.length == 1 ? t.locals.form.check_boxes(:additional_target, data[:poster].additional_target_options, :single => true) : t.locals.form.select(:additional_target, [['-- Also post to --'.t, nil]] + data[:poster].additional_target_options)
          content_tag :div, content, {:class => 'targets'}, false
        end
      end

      c.submit_tag('form:submit', :default => 'Post')

      c.define_tag('stream') { |t| render_to_string :partial => '/post_stream/page/stream', :locals => data[:poster].get_locals.merge(:attributes => t.attr) }
    end
  end

  def render_handler_forms(t, data)
    data[:poster].handlers.collect { |handler| self.render_handler_form(handler, t, data, t.attr) }.join("\n")
  end

  def render_handler_form(handler, t, data, opts={})
    render_to_string :partial => '/post_stream/page/handler_form', :locals => {:renderer => self.renderer, :handler => handler, :opts => opts}
  end

  feature :post_stream_page_recent_posts,
    :default_css_file => '/components/post_stream/stylesheets/stream.css',
    :default_feature => <<-FEATURE
  <cms:posts>
    <div class="post_stream_posts">
      <cms:post>
        <div class="post_stream_post">
          <div class="post">
            <cms:photo size="thumb"/>
            <span class="title_body">
              <span class="title"><cms:post_link><cms:title/></cms:post_link></span>
              <span class="body"><cms:body/></span>
            </span>
          </div>
          <span class="actions">
            <span class="posted_at"><cms:posted_ago/> ago</span>
          </span>
          <div class="shared_content">
            <cms:embeded/>
          </div>
        <hr class="separator"/>
        </div>
      </cms:post>
    </div>
  </cms:posts>
  FEATURE

  def post_stream_page_recent_posts_feature(data)
    webiva_feature(:post_stream_page_recent_posts,data) do |c|
      c.loop_tag('post') { |t| data[:posts] }
      self.class.post_features(c, data)
      c.value_tag("post:embeded") { |t| t.locals.post.handler_obj.render(self.renderer, data[:poster].options) if t.locals.post.handler_obj }
    end
  end

  feature :post_stream_page_post,
    :default_css_file => '/components/post_stream/stylesheets/stream.css',
    :default_feature => <<-FEATURE
  <cms:stream/>
  FEATURE

  def post_stream_page_post_feature(data)
    webiva_feature(:post_stream_page_post,data) do |c|
      c.define_tag('stream') { |t| render_to_string(:partial => '/post_stream/page/stream', :locals => data[:poster].get_locals.merge(:attributes => t.attr)) }
    end
  end

  def self.social_unit_location_feature(context, data)
    context.expansion_tag('group:post') { |t| t.locals.post = PostStreamPost.with_posted_by(t.locals.group).find(:first, :order => 'posted_at DESC') }
    self.post_features(context, data, 'group:post')
  end

  def self.post_features(context, data, base='post')
    context.image_tag("#{base}:photo") { |t| t.locals.post.image }
    context.link_tag("#{base}:post") { |t| t.locals.post.content_node.link }
    context.link_tag("#{base}:posted_by") { |t| t.locals.post.posted_by_shared_content_node.link if t.locals.post.posted_by_shared_content_node }
    context.link_tag("#{base}:content") { |t| t.locals.post.shared_content_node.link if t.locals.post.shared_content_node }
    context.h_tag("#{base}:title") { |t| t.locals.post.title }
    context.value_tag("#{base}:body") { |t| t.locals.post.body_html }
    context.date_tag("#{base}:posted_at",DEFAULT_DATETIME_FORMAT.t) { |t| t.locals.post.posted_at }
    context.value_tag("#{base}:posted_ago") { |t| time_ago_in_words(t.locals.post.posted_at) }
  end
end
