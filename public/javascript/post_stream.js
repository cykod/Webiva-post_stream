PostStreamForm = {
  defaultBodyText: 'Share you ASP Story',
  currentHandler: null,

  share: function(handler) {
    PostStreamForm.currentHandler = handler;

    $$('.post_stream_handler_form').invoke('hide');
    $('post_stream_share_buttons').hide();
    $('post_stream_handler_form_' + handler).show();

    PostStreamForm.bodyOnFocus();
  },

  close: function() {
    PostStreamForm.currentHandler = null;

    $$('.post_stream_handler_form').invoke('hide');
    $('post_stream_share_buttons').show();
  },

  bodyOnFocus: function() {
    bodyEle = $('stream_post_body');
    bodyEle.rows = 3;
    if( bodyEle.value == PostStreamForm.defaultBodyText ) {
      bodyEle.value = '';
    }
  },

  bodyOnBlur: function(ele) {
    bodyEle = $('stream_post_body');
    if( (bodyEle.value == PostStreamForm.defaultBodyText || bodyEle.value == '') && PostStreamForm.currentHandler == null ) {
      bodyEle.rows = 1;
      bodyEle.value = PostStreamForm.defaultBodyText;
    }
  }
}

