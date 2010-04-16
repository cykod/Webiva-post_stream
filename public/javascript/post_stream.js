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
    PostStreamForm.deactivateComments();
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
  },

  onsubmit: function(url, form_id) {
    new Ajax.Request(url, {parameters: $(form_id).serialize(true),
                           onSuccess: function(res) { eval(res.responseText); }
                     });
  },

  toggleComment: function(id) {
    if( PostStreamForm.hasComments(id) || ($('post_stream_comment_' + id).visible() && $('post_stream_comment_form_' + id).hasClassName('inactive'))) {
      if( $('post_stream_comment_form_' + id).hasClassName('active') ) {
        PostStreamForm.deactivateComments();
      } else {
        PostStreamForm.deactivateComments();
        $('post_stream_comment_form_' + id).className = 'post_stream_comment_form active';
        PostStreamForm.focusCommentBody(id);
      }
    } else {
      PostStreamForm.deactivateComments();

      $('post_stream_comment_' + id).toggle();

      if( $('post_stream_comment_' + id).visible() ) {
        $('post_stream_comment_form_' + id).className = 'post_stream_comment_form active';
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

    $('post_stream_comment_form_' + id).className = 'post_stream_comment_form active';
  },

  focusCommentBody: function(id) {
    $$('form#post_stream_comment_form_' + id + ' textarea').invoke('focus');
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
