require "spec_helper"
require "post_stream_spec_helper"

describe PostStreamPostComment do

  reset_domain_tables :post_stream_post, :post_stream_post_comments, :post_stream_targets, :post_stream_post_targets

  it "should require a stream, body, date" do
    @comment = PostStreamPostComment.new
    @comment.valid?

    @comment.should have(1).errors_on(:post_stream_post_id)
    @comment.should have(1).errors_on(:body)
  end
end
