
class PostStreamWidget < Dashboard::WidgetBase
  widget :posts, :name => 'Posts: Display Post Stream Posts', :title => 'Post Stream Posts', :permission => :post_stream_manage

  def posts
    set_title_link url_for(:controller => '/post_stream/manage')

    scope = options.flagged_posts ? PostStreamPost.flagged_posts : PostStreamPost

    @posts = scope.find(:all, :order => 'posted_at DESC', :limit => options.limit)

    render_widget :partial => '/post_stream/widget/posts', :locals => { :posts => @posts, :options => options }
  end

  class PostsOptions < HashModel
    attributes :limit => 10, :flagged_posts => false

    boolean_options :flagged_posts
    integer_options :limit
    validates_numericality_of :limit

    options_form(
                 fld(:limit, :text_field, :label => 'Number of results to diaply'),
                 fld(:flagged_posts, :check_boxes, :single => true, :options => [['only display posts that have been flagged', true]])
                 )
  end

end
