require  File.expand_path(File.dirname(__FILE__)) + '/../../../../post_stream_spec_helper'

describe PostStream::Share::Link::Youtube do

  reset_domain_tables :post_stream_posts, :post_stream_post_comments, :post_stream_targets, :post_stream_post_targets, :end_users

  it "should be able to process a youtube video link" do
    youtube_link = 'http://www.youtube.com/watch?v=test_video_key'

    youtube_xml = <<-XML
    <?xml version='1.0' encoding='UTF-8'?><entry xmlns='http://www.w3.org/2005/Atom' xmlns:media='http://search.yahoo.com/mrss/' xmlns:gd='http://schemas.google.com/g/2005' xmlns:yt='http://gdata.youtube.com/schemas/2007'><id>#{youtube_link}</id>
      <media:group>
        <media:thumbnail url="http://media.test.dev/test.jpg" width="120" height="90" time='00:01:15'/>
        <media:title type='plain'>My Youtube Video Title</media:title>
      </media:group>
    </entry>
    XML

    Net::HTTP.should_receive(:get).and_return(youtube_xml)

    PostStreamPoster.should_receive(:get_handler_info).any_number_of_times.with(:post_stream, :share, nil, false).and_return( [{:name => 'Link', :class => PostStream::Share::Link, :identifier => PostStream::Share::Link.to_s.underscore}] )

    PostStreamPoster.should_receive(:get_handler_info).any_number_of_times.with(:post_stream, :share, 'post_stream/share/link', false).and_return( {:name => 'Link', :class => PostStream::Share::Link, :identifier => PostStream::Share::Link.to_s.underscore} )

    PostStream::Share::Link.should_receive(:get_handler_info).any_number_of_times.with(:post_stream, :link, nil, false).and_return( [{:name => 'Youtube Link Handler', :class => PostStream::Share::Link::Youtube, :identifier => PostStream::Share::Link::Youtube.to_s.underscore, :post_types => ['media']}] )

    @user = EndUser.push_target('test@test.dev')
    @poster = PostStreamPoster.new(@user, @user)

    params = {:stream_post => {:body => 'My first post', :handler => 'post_stream/share/link'}, :stream_post_link => {:link => youtube_link}}
    @poster.setup_post(params[:stream_post])
    @poster.process_request(params)
    @poster.valid?

    assert_difference 'PostStreamPost.count', 1 do
      @poster.save
    end

    @post = @poster.post
    @post.reload
    @post.handler.should == 'post_stream/share/link'
    @post.handler_obj.options.handler.should == 'post_stream/share/link/youtube'
    @post.handler_obj.handler_obj.options.video_key.should == 'test_video_key'
    @post.handler_obj.handler_obj.options.title.should == 'My Youtube Video Title'
    @post.handler_obj.handler_obj.options.thumbnail.should == 'http://media.test.dev/test.jpg'
  end
end
