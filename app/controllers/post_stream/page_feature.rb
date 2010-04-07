
class PostStream::PageFeature < ParagraphFeature

  feature :post_stream_page_stream, :default_feature => <<-FEATURE
    Stream Feature Code...
  FEATURE

  def post_stream_page_stream_feature(data)
    webiva_feature(:post_stream_page_stream,data) do |c|
      
    end
  end
end
