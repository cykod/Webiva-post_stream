require  File.expand_path(File.dirname(__FILE__)) + '/../post_stream_spec_helper'

describe PostStreamPoster do

  reset_domain_tables :post_stream_posts, :post_stream_post_comments, :post_stream_targets, :post_stream_post_targets, :end_users

  it "should be able to check if posting is allowed" do
    @user1 = EndUser.push_target('test1@test.dev')
    @user2 = EndUser.push_target('test2@test.dev')

    @poster = PostStreamPoster.new @user1, @user1
    @poster.can_post?.should be_false

    @poster = PostStreamPoster.new @user1, @user1
    @poster.post_permission = true
    @poster.can_post?.should be_true

    @poster = PostStreamPoster.new @user1, @user1
    @poster.admin_permission = true
    @poster.can_post?.should be_true
  end

  it "should be able to create a post" do
    @user1 = EndUser.push_target('test1@test.dev', :first_name => 'First', :last_name => 'Last')

    @poster = PostStreamPoster.new @user1, @user1
    @poster.post_permission = true
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

    @poster = PostStreamPoster.new @user1, @user1
    @poster.post_permission = true
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

  it "should be able to create a post and post is linked to the posted by" do
    @user1 = EndUser.push_target('test1@test.dev', :first_name => 'First', :last_name => 'Last')
    @user2 = EndUser.push_target('test2@test.dev', :first_name => 'First2', :last_name => 'Last2')

    @poster = PostStreamPoster.new @user1, @user2
    @poster.admin_permission = true

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

    @poster.post.title.should == 'First2 Last2'
  end

  it "should be able to create a post with anonymous user" do
    @user1 = EndUser.push_target('test1@test.dev', :first_name => 'First', :last_name => 'Last')

    @poster = PostStreamPoster.new EndUser.new, @user1
    @poster.post_permission = true
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

    @poster.post.title.should == 'Anonymous'
  end

  it "should be able to create a post and post is link it to an additional target" do
    @user1 = EndUser.push_target('test1@test.dev', :first_name => 'First', :last_name => 'Last')
    @user2 = EndUser.push_target('test2@test.dev', :first_name => 'First2', :last_name => 'Last2')

    @poster = PostStreamPoster.new @user1, @user1
    @poster.additional_targets << @user2
    @poster.post_permission = true
    @poster.can_post?.should be_true

    additional_target = Digest::SHA1.hexdigest(@user2.class.to_s + @user2.id.to_s)

    @poster.setup_post(:body => 'My first post', :additional_target => additional_target)
    @poster.valid?.should be_true

    assert_difference 'PostStreamPostTarget.count', 2 do
      assert_difference 'PostStreamTarget.count', 2 do
        assert_difference 'PostStreamPost.count', 1 do
          @poster.save.should be_true
        end
      end
    end

    @poster.post.title.should == 'First Last'
  end

  it "should be able to fetch posts for target" do
    @user = EndUser.push_target('test1@test.dev', :first_name => 'First', :last_name => 'Last')
    @poster = PostStreamPoster.new @user, @user

    assert_difference 'PostStreamPostTarget.count', 4 do
      assert_difference 'PostStreamTarget.count', 1 do
        assert_difference 'PostStreamPost.count', 4 do
          @poster.setup_post :body => 'My first post'
          @poster.save
          @poster.setup_post :body => 'My first post'
          @poster.save
          @poster.setup_post :body => 'My first post'
          @poster.save
          @poster.setup_post :body => 'My first post'
          @poster.save
        end
      end
    end

    @poster = PostStreamPoster.new @user, @user
    has_more, posts = @poster.fetch_posts
    posts.length.should == 4
  end

  it "should be able to post to a different stream" do
    @user1 = EndUser.push_target('test1@test.dev', :first_name => 'First', :last_name => 'Last')
    @user2 = EndUser.push_target('test2@test.dev', :first_name => 'First2', :last_name => 'Last2')
    @poster = PostStreamPoster.new @user2, @user1

    assert_difference 'PostStreamPostTarget.count', 8 do
      assert_difference 'PostStreamTarget.count', 2 do
        assert_difference 'PostStreamPost.count', 4 do
          @poster.setup_post :body => 'My first post'
          @poster.save
          @poster.setup_post :body => 'My first post'
          @poster.save
          @poster.setup_post :body => 'My first post'
          @poster.save
          @poster.setup_post :body => 'My first post'
          @poster.save
        end
      end
    end

    @poster = PostStreamPoster.new @user1, @user2
    has_more, posts = @poster.fetch_posts
    posts.length.should == 4

    @poster = PostStreamPoster.new @user1, @user1
    has_more, posts = @poster.fetch_posts
    posts.length.should == 4

    @poster = PostStreamPoster.new @user2, @user2
    has_more, posts = @poster.fetch_posts
    posts.length.should == 4

    @poster = PostStreamPoster.new @user2, @user1
    has_more, posts = @poster.fetch_posts
    posts.length.should == 4
  end

  it "should be able to view the target and other streams" do
    @user1 = EndUser.push_target('test1@test.dev', :first_name => 'First', :last_name => 'Last')
    @user2 = EndUser.push_target('test2@test.dev', :first_name => 'First2', :last_name => 'Last2')
    @user3 = EndUser.push_target('test3@test.dev', :first_name => 'First3', :last_name => 'Last3')
    @poster = PostStreamPoster.new @user2, @user2

    assert_difference 'PostStreamPostTarget.count', 4 do
      assert_difference 'PostStreamTarget.count', 1 do
        assert_difference 'PostStreamPost.count', 4 do
          @poster.setup_post :body => 'My first post'
          @poster.save
          @poster.setup_post :body => 'My first post'
          @poster.save
          @poster.setup_post :body => 'My first post'
          @poster.save
          @poster.setup_post :body => 'My first post'
          @poster.save
        end
      end
    end


    @poster = PostStreamPoster.new @user1, @user1

    assert_difference 'PostStreamPostTarget.count', 4 do
      assert_difference 'PostStreamTarget.count', 1 do
        assert_difference 'PostStreamPost.count', 4 do
          @poster.setup_post :body => 'My first post'
          @poster.save
          @poster.setup_post :body => 'My first post'
          @poster.save
          @poster.setup_post :body => 'My first post'
          @poster.save
          @poster.setup_post :body => 'My first post'
          @poster.save
        end
      end
    end

    @poster = PostStreamPoster.new @user1, @user1
    has_more, posts = @poster.fetch_posts
    posts.length.should == 4

    @poster = PostStreamPoster.new @user1, @user2
    has_more, posts = @poster.fetch_posts
    posts.length.should == 4

    @poster = PostStreamPoster.new @user3, @user3
    @poster.view_targets = [['EndUser', [@user1.id, @user2.id]]]
    has_more, posts = @poster.fetch_posts
    posts.length.should == 8

  end

  it "should be able to fetch posts for a type" do
    @user = EndUser.push_target('test1@test.dev', :first_name => 'First', :last_name => 'Last')
    @poster = PostStreamPoster.new @user, @user

    assert_difference 'PostStreamPostTarget.count', 4 do
      assert_difference 'PostStreamTarget.count', 1 do
        assert_difference 'PostStreamPost.count', 4 do
          @poster.setup_post :body => 'My first post'
          @poster.save
          @poster.setup_post :body => 'My first post'
          @poster.save
          @poster.setup_post :body => 'My first post'
          @poster.save
          @poster.setup_post :body => 'My first post'
          @poster.save
        end
      end
    end

    assert_difference 'PostStreamPostTarget.count', 2 do
      assert_difference 'PostStreamTarget.count', 0 do
        assert_difference 'PostStreamPost.count', 2 do
          params = {:body => 'My first post'}
          @poster.setup_post params
          @poster.post.handler = PostStream::Share::Link.to_s.underscore
          @poster.process_request(:stream_post => params, :stream_post_link => {:link => 'http://test.dev/1'})
          @poster.save
          @poster.setup_post params
          @poster.post.handler = PostStream::Share::Link.to_s.underscore
          @poster.process_request(:stream_post => params, :stream_post_link => {:link => 'http://test.dev/2'})
          @poster.save
        end
      end
    end

    @poster = PostStreamPoster.new @user, @user
    has_more, posts = @poster.fetch_posts(nil, :post_types => nil)
    posts.length.should == 6

    @poster = PostStreamPoster.new @user, @user
    has_more, posts = @poster.fetch_posts(nil, :post_types => [])
    posts.length.should == 6

    @poster = PostStreamPoster.new @user, @user
    has_more, posts = @poster.fetch_posts(nil, :post_types => ['link'])
    posts.length.should == 2
  end
end
