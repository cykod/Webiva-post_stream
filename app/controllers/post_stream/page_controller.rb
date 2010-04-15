class PostStream::PageController < ParagraphController

  editor_header 'Post Stream Paragraphs'
  
  editor_for :stream, :name => "Stream", :feature => :post_stream_page_stream,
                      :inputs => { :target => [[:target, 'Target', :target],
                                               [:content, 'Content', :content]],
                                   :post_permission => [[:target, 'Post Permission Target', :target],
                                                        [:content, 'Post Permission Content', :content]],
                                   :admin_permission => [[:target, 'Admin Permission Target', :target],
                                                         [:content, 'Admin Permission Content', :content]]
                                 }

  class StreamOptions < HashModel
    attributes :folder_id => nil, :post_types_filter => [], :maxwidth => 340

    integer_options :maxwidth

    options_form(
                 fld(:post_types_filter, :ordered_array, :options => :post_types_options, :description => 'all posts are shown by default'),
                 fld(:folder_id, :filemanager_folder, :description => 'folder to use for file uploads'),
                 fld(:maxwidth, :text_field, :description => 'embed content max width', :label => 'Max width')
                 )

    def folder_id
      @folder_id || PostStream::AdminController.module_options.folder_id
    end

    def post_types_options
      PostStreamPost.post_type_select_options
    end
  end
end
