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
    $('stream_post_form').className = 'post_stream_active';
    if( bodyEle.value == PostStreamForm.defaultPostText ) {
      bodyEle.value = '';
    }
  },

  bodyOnBlur: function(ele) {
    bodyEle = $('stream_post_body');
    if( ! bodyEle )
      return;

    if( (bodyEle.value == PostStreamForm.defaultPostText || bodyEle.value == '') && PostStreamForm.currentHandler == null ) {
      $('stream_post_form').className = 'post_stream_inactive';
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
    if( PostStreamForm.hasComments(id) || ($('post_stream_comment_' + id).visible() && $('post_stream_comment_form_' + id).hasClassName('post_stream_inactive'))) {
      if( $('post_stream_comment_form_' + id).hasClassName('post_stream_active') ) {
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
    $('post_stream_comment_form_' + id).className = 'post_stream_comment_form post_stream_active';
    if( $('stream_post_comment_body_' + id).value == PostStreamForm.defaultCommentText )
      $('stream_post_comment_body_' + id).value = '';
  },

  focusCommentBody: function(id) {
    $('stream_post_comment_body_' + id).focus();
  },

  deactivateComments: function() {
    $$('.post_stream_comment_form').each(function(e) { e.className = 'post_stream_comment_form post_stream_inactive'; });
  },

  hasComments: function(id) {
    return $$('#post_stream_comments_' + id + ' div.comment').length > 0
  },

  has_more: function(url) {
    PostStream.nextPage++;

    new Ajax.Request(url, {parameters: 'stream_page=' + PostStream.nextPage + '&page_connection_hash=' + PostStreamForm.pageConnectionHash,
                           method: 'get',
                           onSuccess: function(res) {
                             if(res.responseText == 'no_more') {
                               $('stream_post_has_more').hide();
                               $('stream_post_no_more').show();
                             } else {
                               $('more_stream_posts').insert(res.responseText);
                             }
                           }
                     });
  }
}

PostStream = {
  nextPage: 1,

  embed: function(html, id) {
    // remove shared embeded content
    $$('.post_stream_embed').each(function(layer) { layer.update(); layer.hide(); });

    // display the share thumbnails
    $$('.post_stream_thumbnail').invoke('show');

    $('post_stream_thumbnail_' + id).hide();
    ele_id = "post_stream_embed_" + id
    $(ele_id).show();
    $(ele_id).insert(html);
  },

  share: function(url, title, summary) {

    if( FB.Connect.get_loggedInUser() ) {
      FB.Connect.showShareDialog(url, function(){});
      return;
    }

    if( ! summary ) {
      summary = '';
    }

    var sharer_url = "http://www.facebook.com/sharer.php?s=100&p[url]=" + escape(url) + "&p[title]=" + escape(title) + "&p[summary]=" + escape(summary);
    window.open(sharer_url, 'sharer', 'toolbar=0,status=0,width=626,height=436');
  },

  deletePost: function(url, id) {
    parameters = 'delete=1&post_stream_post_identifier=' + id + '&page_connection_hash=' + PostStreamForm.pageConnectionHash;

    new Ajax.Request(url, {parameters: parameters,
                           onSuccess: function(res) { eval(res.responseText); }
                     });    
  },

  onMouseOverPost: function(id) {
    $('post_stream_post_' + id).className = 'post_stream_post post_stream_post_over';
  },

  onMouseOutPost: function(id) {
    $('post_stream_post_' + id).className = 'post_stream_post post_stream_post_out';
  }
}
