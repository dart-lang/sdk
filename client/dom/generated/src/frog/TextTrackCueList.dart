
class TextTrackCueList native "TextTrackCueList" {

  int length;

  TextTrackCue getCueById(String id) native;

  TextTrackCue item(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
