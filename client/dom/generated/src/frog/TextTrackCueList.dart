
class TextTrackCueListJS implements TextTrackCueList native "*TextTrackCueList" {

  int get length() native "return this.length;";

  TextTrackCueJS getCueById(String id) native;

  TextTrackCueJS item(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
