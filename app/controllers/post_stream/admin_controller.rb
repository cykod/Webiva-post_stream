
class PostStream::AdminController < ModuleController

  component_info 'PostStream', :description => 'Post Stream support', :access => :public
                              
  # Register a handler feature
  register_permission_category :post_stream, "PostStream" ,"Permissions related to Post Stream"
  
  register_permissions :post_stream, [[ :manage, 'Manage Post Stream', 'Manage Post Stream'],
                                      [:config, 'Configure Post Stream', 'Configure Post Stream']
                                     ]
  cms_admin_paths "options",
    "Post Stream Options" => { :action => 'options' },
    "Options" => { :controller => '/options' },
    "Modules" => { :controller => '/modules' }

  permit 'post_stream_config'

  public

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

  class Options < HashModel
    attributes :content_filter => 'comment'
  end

end
