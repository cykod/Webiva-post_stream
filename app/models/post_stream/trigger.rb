
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
      default_options :body => nil
      validates_presence_of :body
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

    def post
      {:stream_post => {:body => self.body}}
    end

    def body
      @body = options.body
      @body = self.body_replace(:body)
      @body = self.body_replace(:preview)
      @body = self.body_replace(:title)
      @body = self.body_replace(:name)
      @body = self.body_replace(:link)
      @body
    end

    def body_replace(name)
      @data.respond_to?(name) && @data.send(name) ? @body.gsub("%%#{name}%%", truncate(@data.send(name).to_s, :length => 200)) : @body
    end

    def post_options
      {:title => self.title, :link => self.link, :post_type => self.post_type, :shared_content_node_id => self.shared_content_node_id}
    end

    def title
      nil
    end

    def link
      @data.respond_to?(:link) ? @data.link : nil
    end

    def post_type
      self.link ? 'link' : nil
    end

    def shared_content_node_id
      @data.respond_to?(:content_node) && @data.content_node.respond_to?(:id) ? @data.content_node.id : nil
    end
  end
end
