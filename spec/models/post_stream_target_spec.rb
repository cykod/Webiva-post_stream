require  File.expand_path(File.dirname(__FILE__)) + '/../post_stream_spec_helper'

describe PostStreamTarget do

  reset_domain_tables :post_stream_post, :post_stream_post_comments, :post_stream_targets, :post_stream_post_targets

  it "should require a target" do
    @target = PostStreamTarget.new
    @target.valid?

    @target.should have(1).errors_on(:target_type)
    @target.should have(1).errors_on(:target_id)
  end
end
