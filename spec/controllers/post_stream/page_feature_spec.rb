require "spec_helper"
require "post_stream_spec_helper"

describe PostStream::PageFeature, :type => :view do

  reset_domain_tables :post_stream_post, :post_stream_post_comments, :post_stream_targets, :post_stream_post_targets, :end_users

  before(:each) do
    @feature = build_feature('/post_stream/page_feature')
  end

  it "should render the stream" do
    @user = EndUser.push_target('test1@test.dev', :first_name => 'First', :last_name => 'Last')
    @poster = PostStreamPoster.new @user, @user
    @poster.post_permission = true

    @site_node = SiteVersion.default.root.add_subpage('wall')

    @options = PostStream::PageController::StreamOptions.new nil
    @feature.should_receive(:render_to_string).once
    @feature.renderer.should_receive(:require_css)
    @feature.should_receive(:site_node).any_number_of_times.and_return(@site_node)

    @output = @feature.post_stream_page_stream_feature(:options => @options, :poster => @poster, :posts => [], :has_more => false)
  end
end
