class PostStream::PageController < ParagraphController

  editor_header 'Post Stream Paragraphs'
  
  editor_for :stream, :name => "Stream", :feature => :post_stream_page_stream,
                      :inputs => { :public_target => [[:content, 'Public Content', :content],
                                                      [:target, 'Public Target', :target]],
                                   :private_target => [[:content, 'Private Content', :content],
                                                       [:target, 'Private Target', :target]]
                                 }

  class StreamOptions < HashModel
    attributes :end_user_id => nil, :allow_anonymous_posting => false

    boolean_options :allow_anonymous_post

    # REMINDER :end_user_selector does not work this way
    options_form(
                 fld(:end_user_id, :end_user_selector, :description => 'Only display a wall for this user'),
                 fld(:allow_anonymous_posting, :check_boxes, :single => true, :options => [['anonymous users can post', true]])
                 )
  end
end
