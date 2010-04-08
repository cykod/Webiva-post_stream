require  File.expand_path(File.dirname(__FILE__)) + '/../../post_stream_spec_helper'

describe PostStream::PageRenderer, :type => :controller do
  controller_name :page
  integrate_views

  reset_domain_tables :post_stream_post, :post_stream_post_comments, :post_stream_targets, :post_stream_post_targets, :end_users

  renderer_builder '/post_stream/page/stream'

  it "should render the stream paragraph even when not setup" do
    @rnd = stream_renderer
    @rnd.should_receive(:render_paragraph)
    PostStreamPoster.should_receive(:new).exactly(0).times
    renderer_get @rnd
  end

  it "should render the stream for a user" do
    @user = EndUser.push_target('test@test.dev')
    @rnd = stream_renderer({}, :target => [:target, @user])
    @rnd.should_receive(:render_paragraph).with(:feature => :post_stream_page_stream)
    renderer_get @rnd
  end

  it "should post to the stream" do
    mock_user
    @rnd = stream_renderer({}, :target => [:target, @myself], :post_permission => [:target, @myself])
    @rnd.should_receive(:render_paragraph).with(:feature => :post_stream_page_stream)
    assert_difference 'PostStreamPost.count', 1 do
      renderer_post @rnd, :stream_post => {:body => 'My first post'}
    end

    @post = PostStreamPost.find(:last)
    @post.should_not be_nil
    @post.body.should == 'My first post'
    @post.body_html.should include('My first post')
    @post.posted_by.should_not be_nil
    @post.posted_by.id.should == @myself.id
    @post.end_user.should_not be_nil
    @post.end_user.id.should == @myself.id
  end
end
