
class TextTrackCueList native "*TextTrackCueList" {

  int get length() native "return this.length;";

  TextTrackCue getCueById(String id) native;

  TextTrackCue item(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
