
class PostStream::ManageController < ModuleController
  permit 'post_stream_manage'

  component_info 'PostStream'

  cms_admin_paths 'content', 
                  'Content' => { :controller => '/content' },
                  'Post Stream Targets' => { :action => 'index' },
                  'Post Stream Posts' => { :action => 'posts' }

  # need to include
  include ActiveTable::Controller
  active_table :post_stream_table,
                PostStreamPost,
                [ :check,
                  hdr(:options, :post_type, :options => :post_type_options),
                  :title,
                  :body,
                  hdr(:static, 'User'),
                  :handler,
                  hdr(:number, :post_stream_post_comments_count, :label => '# Comments'),
                  :flagged,
                  :posted_at
                ]


  active_table :target_table,
                PostStreamTarget,
                [ :name,
                  hdr(:number, :post_stream_post_count, :label => '# Posts'),
                  hdr(:number, :flagged_post_count, :label => '# Flagged Posts'),
                  :last_posted_at,
                  :created_at
                ]


  def index
    cms_page_path ['Content'], 'Post Stream Targets'

    target_table(false)
  end

  def target_table(display=true)
    @active_table_output = target_table_generate params, :order => 'last_posted_at DESC'
    
    render :partial => 'target_table' if display
  end

  def posts
    @target = PostStreamTarget.find params[:path][0]

    cms_page_path ['Content', 'Post Stream Targets'], '%s Posts' / @target.name

    post_stream_table(false)
  end


  def post_stream_table(display=true)
    @target = PostStreamTarget.find params[:path][0] unless @target

    active_table_action 'post_stream' do |act,ids|
      case act
      when 'delete': PostStreamPost.destroy(ids)
      when 'flag'
        PostStreamPost.update_all('flagged = 1', :id => ids)
        @target.flagged_post_count = PostStreamPost.with_posted_by(@target.target).flagged_posts.count
        @target.save
      when 'unflag'
        PostStreamPost.update_all('flagged = 0', :id => ids)
        @target.flagged_post_count = PostStreamPost.with_posted_by(@target.target).flagged_posts.count
        @target.save
      end
    end

    @active_table_output = post_stream_table_generate params, :order => 'posted_at DESC', :conditions => ['post_stream_targets.id = ?', @target.id], :joins => :post_stream_targets
    
    render :partial => 'post_stream_table' if display
  end

  def post
    @target = PostStreamTarget.find params[:path][0]
    @post = PostStreamPost.find params[:path][1]

    cms_page_path ['Content', 'Post Stream Targets', ['%s Posts', url_for(:action => 'posts', :path => @target.id), @target.name]], 'Post'

    if request.post?
      if params[:delete]
        @post.destroy
        redirect_to :action => 'index'
      end
    end
  end

  protected

  def post_type_options
    PostStreamPost.post_type_select_options
  end
end
