
class PostStream::Trigger < Trigger::TriggeredActionHandler

  def self.trigger_actions_handler_info
    { :name => 'Post Stream Triggered Actions' }
  end  

  register_triggered_actions [
    { :name => :auto_post,
      :description => 'Auto post to user stream' ,
      :options_partial => '/post_stream/trigger/auto_post'
    }
  ]

  class AutoPostTrigger < Trigger::TriggerBase #:nodoc:

    include ActionView::Helpers::TextHelper

    class AutoPostOptions < HashModel
      default_options :body => nil, :title => nil, :use_title => false
      boolean_options :use_title
      validates_presence_of :body

      def validate
        self.errors.add(:title, 'is missing') if self.use_title && self.title.blank?
      end
    end
    
    options "Auto Post Options", AutoPostOptions

    def perform(data={},user = nil)
      @data = data
    
      if user
        poster = PostStreamPoster.new user, user
        poster.setup self.post, self.post_options
        poster.save
      end
    end

    def data_vars
      @data_vars ||= @data.is_a?(DomainModel) ? @data.triggered_attributes.symbolize_keys :  (@data.is_a?(Hash) ? @data.symbolize_keys : {})
    end

    def post
      {:stream_post => {:body => self.body}}
    end

    def body
      DomainModel.variable_replace(options.body, self.data_vars)
    end

    def post_options
      {:title => self.title, :shared_content_node_id => self.shared_content_node_id}
    end

    def title
      options.use_title ? DomainModel.variable_replace(options.title, self.data_vars) : nil
    end

    def shared_content_node_id
      @data.respond_to?(:content_node) && @data.content_node.respond_to?(:id) ? @data.content_node.id : nil
    end
  end
end
