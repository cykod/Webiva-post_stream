require  File.expand_path(File.dirname(__FILE__)) + '/../../post_stream_spec_helper'

describe PostStream::PageFeature, :type => :view do

  reset_domain_tables :post_stream_post, :post_stream_post_comments, :post_stream_targets, :post_stream_post_targets, :end_users

  before(:each) do
    @feature = build_feature('/post_stream/page_feature')
  end

  it "should render the stream" do
    @user = EndUser.push_target('test1@test.dev', :first_name => 'First', :last_name => 'Last')
    @poster = PostStreamPoster.new @user, @user
    @poster.post_permission = true

    @options = PostStream::PageController::StreamOptions.new nil
    @feature.should_receive(:render_to_string).twice
    @feature.should_receive(:paragraph).twice
    @output = @feature.post_stream_page_stream_feature(:options => @options, :poster => @poster, :posts => [], :has_more => false)
  end
end
