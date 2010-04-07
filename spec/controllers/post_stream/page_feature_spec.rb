require  File.expand_path(File.dirname(__FILE__)) + '/../../post_stream_spec_helper'

describe PostStream::PageFeature, :type => :view do

  reset_domain_tables :post_stream_post, :post_stream_post_comments, :post_stream_targets, :post_stream_post_targets, :end_users

  before(:each) do
    @feature = build_feature('/post_stream/page_feature')
  end

  it "should render the stream" do
    @options = PostStream::PageController::StreamOptions.new nil
    @output = @feature.post_stream_page_stream_feature(:options => @options)
  end
end
