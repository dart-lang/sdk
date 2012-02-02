
class _TextTrackCueListJs extends _DOMTypeJs implements TextTrackCueList native "*TextTrackCueList" {

  int get length() native "return this.length;";

  _TextTrackCueJs getCueById(String id) native;

  _TextTrackCueJs item(int index) native;
}
