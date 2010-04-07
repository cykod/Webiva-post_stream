require  File.expand_path(File.dirname(__FILE__)) + '/../../post_stream_spec_helper'

describe PostStream::PageRenderer, :type => :controller do
  controller_name :page
  integrate_views

  reset_domain_tables :post_stream_post, :post_stream_post_comments, :post_stream_targets, :post_stream_post_targets, :end_users

  def generate_page_renderer(paragraph, options={}, inputs={})
    @rnd = build_renderer('/page', '/post_stream/page/' + paragraph, options, inputs)
  end

  it "should render the stream paragraph even when not setup" do
    @rnd = generate_page_renderer('stream')
    @rnd.should_receive(:render_paragraph)
    renderer_get @rnd
  end
end
