
class PostStream::ManageController < ModuleController
  permit 'post_stream_manage'

  component_info 'PostStream'

  cms_admin_paths 'content', 
                  'Content' => { :controller => '/content' },
                  'Post Stream Posts' => { :action => 'index' }

  # need to include
  include ActiveTable::Controller
  active_table :post_stream_table,
                PostStreamPost,
                [ :check,
                  :post_type,
                  :title,
                  :body,
                  hdr(:static, 'User'),
                  hdr(:static, 'Posted By'),
                  :handler,
                  hdr(:number, :post_stream_post_comments_count, :label => '# Comments'),
                  :posted_at
                ]


  def index
    cms_page_path ['Content'], 'Post Stream Posts'

    post_stream_table(false)
  end

  def post_stream_table(display=true)
    active_table_action 'post_stream' do |act,ids|
      case act
      when 'delete': PostStreamPost.destroy(ids)
      end
    end

    @active_table_output = post_stream_table_generate params
    
    render :partial => 'post_stream_table' if display
  end

  def post
    cms_page_path ['Content', 'Post Stream Posts'], 'Post'

    @post = PostStreamPost.find params[:path][0]

    if request.post?
      if params[:delete]
        @post.destroy
        redirect_to :action => 'index'
      end
    end
  end
end
