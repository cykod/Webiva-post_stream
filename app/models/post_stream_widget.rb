
class PostStreamWidget < Dashboard::WidgetBase
  widget :posts, :name => 'Posts: Display Post Stream Posts', :title => 'Post Stream Posts', :permission => :post_stream_manage

  def posts
    set_title_link url_for(:controller => '/post_stream/manage')

    @posts = PostStreamPost.find(:all, :order => 'posted_at DESC', :limit => options.limit)

    render_widget :partial => '/post_stream/widget/posts', :locals => { :posts => @posts, :options => options }
  end

  class PostsOptions < HashModel
    attributes :limit => 10

    integer_options :limit
    validates_numericality_of :limit

    options_form(
                 fld(:limit, :text_field, :label => 'Number of results to diaply')
                 )
  end

end
