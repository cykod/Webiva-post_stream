
PostStreamOmbedLink = {

  play: function(html, id) {
    // remove any videos that are playing
    $$('.post_stream_video').each(function(layer) { layer.update(); layer.hide(); });

    // display the video thumbnails
    $$('.post_stream_thumbnail').invoke('show');

    $('post_stream_thumbnail_' + id).hide();
    ele_id = "post_stream_video_" + id
    $(ele_id).show();
    $(ele_id).insert(html);
  }
}
