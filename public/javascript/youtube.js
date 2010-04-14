
PostStreamLinkYoutube = {
  autoplay: 1,
  width: '340',
  height: '260',
  color: "#FFFFFF",

  play: function(video_key, id) {
    // remove any videos that are playing
    $$('.post_stream_video').each(function(layer) { layer.update(); layer.hide(); });

    // display the video thumbnails
    $$('.post_stream_thumbnail').invoke('show');

    $('post_stream_thumbnail_' + id).hide();
    layer_id = "post_stream_video_" + id
    container_id = "youtube_video_" + id
    $(layer_id).show();
    $(layer_id).insert( '<div id="' + container_id + '"></div>' );
    swfobject.embedSWF(PostStreamLinkYoutube.youtubeVideoUrl(video_key), container_id, PostStreamLinkYoutube.width, PostStreamLinkYoutube.height, '8', '/javascripts/swfobject/plugins/expressInstall.swf', {}, {wmode: 'transparent', quality: 'hight'}, {style: 'outline : none'}, false);
  },

  youtubeVideoUrl: function(video_key) {
    return "http://www.youtube.com/v/" + video_key + "&rel=0&autoplay=" + PostStreamLinkYoutube.autoplay;
  }
}
