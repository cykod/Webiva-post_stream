PostStreamForm = {
  defaultBodyText: 'Share you ASP Story',
  currentType: null,
  inactiveRows: 1,
  activeRows: 3,

  share: function(type, handler) {
    PostStreamForm.currentType = handler;

    $$('.post_stream_handler_form').invoke('hide');
    $('post_stream_share_buttons').hide();
    $('post_stream_handler_form_' + type).show();
    $('stream_post_handler').value = handler;
    PostStreamForm.bodyOnFocus();
  },

  close: function() {
    PostStreamForm.currentType = null;

    $('stream_post_handler').value = '';
    $$('.post_stream_handler_form').invoke('hide');
    $('post_stream_share_buttons').show();
  },

  bodyOnFocus: function() {
    bodyEle = $('stream_post_body');
    bodyEle.rows = PostStreamForm.activeRows;
    if( bodyEle.value == PostStreamForm.defaultBodyText ) {
      bodyEle.value = '';
    }
  },

  bodyOnBlur: function(ele) {
    bodyEle = $('stream_post_body');
    if( (bodyEle.value == PostStreamForm.defaultBodyText || bodyEle.value == '') && PostStreamForm.currentType == null ) {
      bodyEle.rows = PostStreamForm.inactiveRows;
      bodyEle.value = PostStreamForm.defaultBodyText;
    }
  }
}

