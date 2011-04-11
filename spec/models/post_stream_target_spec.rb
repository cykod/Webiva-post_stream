require "spec_helper"
require "post_stream_spec_helper"

describe PostStreamTarget do

  reset_domain_tables :post_stream_post, :post_stream_post_comments, :post_stream_targets, :post_stream_post_targets, :end_users

  it "should require a target" do
    @target = PostStreamTarget.new
    @target.valid?

    @target.should have(1).errors_on(:target_type)
    @target.should have(1).errors_on(:target_id)
  end

  it "should be able to push targets" do
    @user = EndUser.push_target('test@test.dev')

    assert_difference 'PostStreamTarget.count', 1 do
      @target = PostStreamTarget.push_target(@user)
    end

    @target.target_id.should == @user.id
    @target.target_type.should == 'EndUser'

    assert_difference 'PostStreamTarget.count', 0 do
      @target = PostStreamTarget.push_target(@user)
    end

    @target.target_id.should == @user.id
    @target.target_type.should == 'EndUser'
  end

  it "should be able to fetch the user if create fails" do
    @user = EndUser.push_target('test@test.dev')

    assert_difference 'PostStreamTarget.count', 1 do
      @target = PostStreamTarget.create_target(@user)
    end

    @target.target_id.should == @user.id
    @target.target_type.should == 'EndUser'

    assert_difference 'PostStreamTarget.count', 0 do
      @target = PostStreamTarget.create_target(@user)
    end

    @target.target_id.should == @user.id
    @target.target_type.should == 'EndUser'
  end
end
