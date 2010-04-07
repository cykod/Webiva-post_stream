require  File.expand_path(File.dirname(__FILE__)) + '/../post_stream_spec_helper'

describe PostStreamPoster do

  reset_domain_tables :post_stream_post, :post_stream_post_comments, :post_stream_targets, :post_stream_post_targets, :end_users

  it "should be able to check if posting is allowed" do
    @user1 = EndUser.push_target('test1@test.dev')
    @user2 = EndUser.push_target('test2@test.dev')

    @poster = PostStreamPoster.new @user1, @user1, @user2
    @poster.can_post?.should be_false

    @poster = PostStreamPoster.new @user1, @user1, @user1
    @poster.can_post?.should be_true
  end

  it "should be able to create a post" do
    @user1 = EndUser.push_target('test1@test.dev', :first_name => 'First', :last_name => 'Last')

    @poster = PostStreamPoster.new @user1, @user1, @user1
    @poster.can_post?.should be_true

    @poster.setup_post(:body => 'My first post')
    @poster.valid?.should be_true

    assert_difference 'PostStreamPostTarget.count', 1 do
      assert_difference 'PostStreamTarget.count', 1 do
        assert_difference 'PostStreamPost.count', 1 do
          @poster.save.should be_true
        end
      end
    end

    @poster.post.title.should == 'First Last'
  end

  it "should be able to create a post and set end user name" do
    @user1 = EndUser.push_target('test1@test.dev')

    @poster = PostStreamPoster.new @user1, @user1, @user1
    @poster.can_post?.should be_true

    @poster.setup_post(:body => 'My first post', :name => 'First Last')
    @poster.valid?.should be_true

    assert_difference 'PostStreamPostTarget.count', 1 do
      assert_difference 'PostStreamTarget.count', 1 do
        assert_difference 'PostStreamPost.count', 1 do
          @poster.save.should be_true
        end
      end
    end

    @user1.reload
    @user1.name.should == 'First Last'
    @user1.first_name.should == 'First'
    @user1.last_name.should == 'Last'
  end
end
