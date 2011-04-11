require "spec_helper"
require "post_stream_spec_helper"

describe PostStreamPostTarget do

  reset_domain_tables :post_stream_post, :post_stream_post_comments, :post_stream_targets, :post_stream_post_targets, :end_users

  it "should require post, target and date" do
    @post_target = PostStreamPostTarget.new
    @post_target.valid?

    @post_target.should have(1).errors_on(:post_stream_post_id)
    @post_target.should have(1).errors_on(:post_stream_target_id)
    @post_target.should have(1).errors_on(:posted_at)
    @post_target.should have(1).errors_on(:post_type)
  end

  it "should link posts and targets" do
    @user = EndUser.push_target('test@test.dev')
    @post = PostStreamPost.create :body => 'My first post', :end_user_id => @user
    @target = PostStreamTarget.push_target(@user)
    @post_target = PostStreamPostTarget.link_post_to_target(@post, @target)
    @post_target.should_not be_nil
    @post_target.post_type.should == @post.post_type
    @post_target.posted_at.should == @post.posted_at
  end
end
