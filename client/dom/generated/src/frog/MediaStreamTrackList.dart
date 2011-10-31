
class MediaStreamTrackList native "MediaStreamTrackList" {

  int length;

  MediaStreamTrack item(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
