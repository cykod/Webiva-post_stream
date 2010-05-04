

class PostStream::Autopublish

  def self.blog_targeted_after_publish_handler_info
   { :name => 'Post Stream Publish' }
  end
  
  def self.after_publish(blog_post,user)
    poster = PostStreamPoster.new(user,blog_post.blog_blog.targeted_blog) 
    poster.admin_permission = true
    poster.shared_content_node = blog_post.content_node

    post_body = { :stream_post => { :body => blog_post.preview }  } 
    poster.setup(post_body,:title => blog_post.title  )
    poster.save
    
  end


end
