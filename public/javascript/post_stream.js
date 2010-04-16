PostStreamForm = {
  defaultPostText: '',
  defaultCommentText: '',
  currentHandler: null,
  pageConnectionHash: '',

  share: function(type, handler) {
    PostStreamForm.currentHandler = handler;

    $$('.post_stream_handler_form').invoke('hide');
    $('post_stream_share_buttons').hide();
    $('post_stream_handler_form_' + type).show();
    $('stream_post_handler').value = handler;
    PostStreamForm.bodyOnFocus();
  },

  close: function() {
    PostStreamForm.currentHandler = null;

    $('stream_post_handler').value = '';
    $$('.post_stream_handler_form').invoke('hide');
    $('post_stream_share_buttons').show();
  },

  bodyOnFocus: function() {
    PostStreamForm.deactivateComments();
    bodyEle = $('stream_post_body');
    $('stream_post_form').className = 'active';
    if( bodyEle.value == PostStreamForm.defaultPostText ) {
      bodyEle.value = '';
    }
  },

  bodyOnBlur: function(ele) {
    bodyEle = $('stream_post_body');
    if( (bodyEle.value == PostStreamForm.defaultPostText || bodyEle.value == '') && PostStreamForm.currentHandler == null ) {
      $('stream_post_form').className = 'inactive';
      bodyEle.value = PostStreamForm.defaultPostText;
    }
  },

  onsubmit: function(url, form_id) {
    parameters = $(form_id).serialize(true);
    parameters.page_connection_hash = PostStreamForm.pageConnectionHash;

    new Ajax.Request(url, {parameters: parameters,
                           onSuccess: function(res) { eval(res.responseText); }
                     });
  },

  toggleComment: function(id) {
    if( PostStreamForm.hasComments(id) || ($('post_stream_comment_' + id).visible() && $('post_stream_comment_form_' + id).hasClassName('inactive'))) {
      if( $('post_stream_comment_form_' + id).hasClassName('active') ) {
        PostStreamForm.deactivateComments();
      } else {
        PostStreamForm.activateComment(id);
        PostStreamForm.focusCommentBody(id);
      }
    } else {
      PostStreamForm.deactivateComments();

      $('post_stream_comment_' + id).toggle();

      if( $('post_stream_comment_' + id).visible() ) {
        PostStreamForm.activateComment(id);
        PostStreamForm.focusCommentBody(id);
      }
    }
  },

  showComment: function(id) {
    $('post_stream_comment_' + id).show();
  },

  hideComment: function(id) {
    $('post_stream_comment_' + id).hide();
  },

  activateComment: function(id) {
    PostStreamForm.deactivateComments();
    PostStreamForm.bodyOnBlur();
    $('post_stream_comment_form_' + id).className = 'post_stream_comment_form active';
    if( $('stream_post_comment_body_' + id).value == PostStreamForm.defaultCommentText )
      $('stream_post_comment_body_' + id).value = '';
  },

  focusCommentBody: function(id) {
    $('stream_post_comment_body_' + id).focus();
  },

  deactivateComments: function() {
    $$('.post_stream_comment_form').each(function(e) { e.className = 'post_stream_comment_form inactive'; });
  },

  hasComments: function(id) {
    return $$('#post_stream_comments_' + id + ' div.comment').length > 0
  }
}

PostStream = {

  embed: function(html, id) {
    // remove shared embeded content
    $$('.post_stream_embed').each(function(layer) { layer.update(); layer.hide(); });

    // display the share thumbnails
    $$('.post_stream_thumbnail').invoke('show');

    $('post_stream_thumbnail_' + id).hide();
    ele_id = "post_stream_embed_" + id
    $(ele_id).show();
    $(ele_id).insert(html);
  }
}
