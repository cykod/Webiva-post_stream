
class PostStream::AdminController < ModuleController

  component_info 'PostStream', :description => 'Post Stream support', :access => :private

  content_model :post_stream

  # Register a handler feature
  register_permission_category :post_stream, "PostStream" ,"Permissions related to Post Stream"
  
  register_permissions :post_stream, [[ :manage, 'Manage Post Stream', 'Manage Post Stream'],
                                      [:config, 'Configure Post Stream', 'Configure Post Stream']
                                     ]

  register_handler :post_stream, :share, 'PostStream::Share::Link'
  register_handler :post_stream, :share, 'PostStream::Share::MediaLink'
  register_handler :post_stream, :share, 'PostStream::Share::File'
  register_handler :post_stream, :link, 'PostStream::Share::Link::Oembed'
  register_handler :post_stream, :link, 'PostStream::Share::Link::Fetch'
  register_handler :trigger, :actions, 'PostStream::Trigger'

  register_handler :webiva, :widget, 'PostStreamWidget'

  register_handler :blog, :targeted_after_publish, "PostStream::Autopublish"

  register_handler :site_feature, :social_unit_location, 'PostStream::PageFeature'

  register_action '/post_stream/flagged_post', :description => 'Post Stream: Flagged a post'
  register_action '/post_stream/new_post', :description => 'Post Stream: Posted'
  register_action '/post_stream/new_comment', :description => 'Post Stream: Commented on a post'

  cms_admin_paths "options",
    "Post Stream Options" => { :action => 'options' },
    "Options" => { :controller => '/options' },
    "Modules" => { :controller => '/modules' }

  permit 'post_stream_config'

  content_node_type 'Post Stream Posts', "PostStreamPost", :title_field => :title, :url_field => :identifier

  linked_models :end_user, 
                [ :post_stream_post_comments, [ :post_stream_targets, :target_type, :target_id ] ]

  linked_models :content_node, [ [ :post_stream_post, :shared_content_node_id ]  ]
  public

  def self.get_post_stream_info
    [
      {:name => 'Post Stream Posts', :url => {:controller => '/post_stream/manage'}, :permission => 'post_stream_manage', :icon => 'icons/content/feedback.gif'}
    ]
  end

  def options
    cms_page_path ['Options','Modules'],"Post Stream Options"
    
    @options = self.class.module_options(params[:options])
    
    if request.post? && @options.valid?
      Configuration.set_config_model(@options)
      flash[:notice] = "Updated Post Stream module options".t 
      redirect_to :controller => '/modules'
      return
    end    
  end
  
  def self.module_options(vals=nil)
    Configuration.get_config_model(Options,vals)
  end

  def self.allowed_oembed_link?(link)
    self.module_options.allowed_oembed_link?(link)
  end

  class Options < HashModel
    attributes :content_filter => 'comment', :folder_id => nil, :oembed_domains => ''

    options_form(
                 fld(:folder_id, :filemanager_folder, :description => 'default folder for uploads'),
                 fld(:oembed_domains, :text_area, :description => 'only allow embed media from these domains')
                 )

    def allowed_oembed_domains
      @allowed_oembed_domains ||= self.oembed_domains.split("\n").collect { |domain| domain.strip }
    end

    def allowed_oembed_link?(link)
      return true if self.oembed_domains.empty?

      self.allowed_oembed_domains.find { |domain| link.include?(".#{domain}") || link.include?("//#{domain}") }
    end
  end

end
