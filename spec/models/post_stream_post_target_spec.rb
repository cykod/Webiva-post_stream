require  File.expand_path(File.dirname(__FILE__)) + '/../post_stream_spec_helper'

describe PostStreamPostTarget do

  reset_domain_tables :post_stream_post, :post_stream_post_comments, :post_stream_targets, :post_stream_post_targets

  it "should require post, target and date" do
    @post_target = PostStreamPostTarget.new
    @post_target.valid?

    @post_target.should have(1).errors_on(:post_stream_post_id)
    @post_target.should have(1).errors_on(:post_stream_target_id)
    @post_target.should have(1).errors_on(:posted_at)
  end
end
