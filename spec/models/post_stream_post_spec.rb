require "spec_helper"
require "post_stream_spec_helper"

describe PostStreamPost do
  include ActionDispatch::TestProcess

  reset_domain_tables :post_stream_posts, :post_stream_post_comments, :post_stream_targets, :post_stream_post_targets, :end_users

  it "should require post, target and date" do
    @post = PostStreamPost.new
    @post.valid?

    @post.should have(1).errors_on(:body)
  end

  it "should be able to create an anonymous post with a type and body" do
    @post = PostStreamPost.create :body => 'My first post'
    @post.id.should_not be_nil
    @post.title.should == 'Anonymous'
    @post.posted_at.should_not be_nil
    @post.post_hash.should_not be_nil
    @post.body_html.should include('My first post')
  end

  it "should be able to create a post from an end_user" do
    @user = EndUser.push_target('test@test.dev', :first_name => 'First', :last_name => 'Last')

    @post = PostStreamPost.create :body => 'My first post', :end_user_id => @user.id
    @post.id.should_not be_nil
    @post.title.should == 'First Last'
    @post.posted_at.should_not be_nil
    @post.post_hash.should_not be_nil
    @post.body_html.should include('My first post')
    @post.posted_by.should_not be_nil
    @post.posted_by.should == @user
  end

  it "should require a valid link when creating a link post" do
    @post = PostStreamPost.new :post_type => 'link'
    @post.valid?

    @post.should have(1).errors_on(:body)
    @post.should have(1).errors_on(:link)

    @post = PostStreamPost.new :post_type => 'link', :body => 'My first post'
    @post.valid?

    @post.should have(1).errors_on(:link)

    @post = PostStreamPost.create :body => 'My first post', :link => 'http://test.dev/'
    @post.id.should_not be_nil
    @post.title.should == 'Anonymous'
    @post.posted_at.should_not be_nil
    @post.post_hash.should_not be_nil
    @post.body_html.should include('My first post')
    @post.link.should == 'http://test.dev/'
    @post.post_type.should == 'link'
  end

  it "should set the title to the posted_by target and not the end_user" do
    @user = EndUser.push_target('test@test.dev', :first_name => 'First', :last_name => 'Last')
    @site_node = SiteVersion.default.root.add_subpage('blog')

    @post = PostStreamPost.create :body => 'My first post', :end_user_id => @user.id, :posted_by => @site_node
    @post.id.should_not be_nil
    @post.title.should == 'Blog'
    @post.post_hash.should_not be_nil
    @post.posted_at.should_not be_nil
    @post.body_html.should include('My first post')
    @post.posted_by.should_not be_nil
    @post.posted_by.should == @site_node
  end

  it "should be able to create a post of type image" do
    fdata = fixture_file_upload("files/rails.png",'image/png')
    @df = DomainFile.create(:filename => fdata)

    @post = PostStreamPost.create :body => 'My first post', :domain_file_id => @df.id
    @post.id.should_not be_nil
    @post.title.should == 'Anonymous'
    @post.post_hash.should_not be_nil
    @post.posted_at.should_not be_nil
    @post.body_html.should include('My first post')
    @post.post_type.should == 'image'
    @post.domain_file.should == @df

    @df.destroy
  end

  it "should be able to create a post of type media" do
    fdata = fixture_file_upload("files/fake_video.flv", 'video/flv')
    @df = DomainFile.create(:filename => fdata)

    @post = PostStreamPost.create :body => 'My first post', :domain_file_id => @df.id
    @post.id.should_not be_nil
    @post.title.should == 'Anonymous'
    @post.post_hash.should_not be_nil
    @post.posted_at.should_not be_nil
    @post.body_html.should include('My first post')
    @post.post_type.should == 'media'
    @post.domain_file.should == @df

    @df.destroy
  end

  it "should be able to create a post of type media" do
    @site_node = SiteVersion.default.root.add_subpage('blog')

    @post = PostStreamPost.create :body => 'My first post', :shared_content_node_id => @site_node.content_node.id
    @post.id.should_not be_nil
    @post.title.should == 'Anonymous'
    @post.post_hash.should_not be_nil
    @post.posted_at.should_not be_nil
    @post.body_html.should include('My first post')
    @post.post_type.should == 'content'
  end

  it "should be able to create a post and update the end user name if a name is set" do
    @user = EndUser.push_target('test@test.dev')
    @post = PostStreamPost.create :body => 'My first post', :end_user_id => @user.id, :name => 'First Last'
    @post.id.should_not be_nil
    @post.title.should == 'First Last'
    @post.posted_at.should_not be_nil
    @post.post_hash.should_not be_nil
    @post.body_html.should include('My first post')
    @post.posted_by.should_not be_nil
    @post.posted_by.should == @user

    @user.reload
    @user.name.should == 'First Last'
    @user.first_name.should == 'First'
    @user.last_name.should == 'Last'
  end
end
