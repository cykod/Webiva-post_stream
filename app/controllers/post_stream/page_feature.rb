
class PostStream::PageFeature < ParagraphFeature

  feature :post_stream_page_stream, :default_feature => <<-FEATURE
    <cms:form/>
    <cms:stream/>
  FEATURE

  def post_stream_page_stream_feature(data)
    webiva_feature(:post_stream_page_stream,data) do |c|
      c.define_tag('form') { |t| render_to_string(:partial => '/post_stream/page/form', :locals => data.merge(:paragraph => paragraph)) if data[:poster].can_post? }
      c.define_tag('stream') { |t| render_to_string :partial => '/post_stream/page/stream', :locals => data.merge(:paragraph => paragraph) }
    end
  end
end
