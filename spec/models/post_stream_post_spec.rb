require  File.expand_path(File.dirname(__FILE__)) + '/../post_stream_spec_helper'

describe PostStreamPost do

  reset_domain_tables :post_stream_post, :post_stream_post_comments, :post_stream_targets, :post_stream_post_targets, :end_users

  it "should require post, target and date" do
    @post = PostStreamPost.new
    @post.valid?

    @post.should have(1).errors_on(:post_type)
  end
end
