
class TextTrackCueListJs extends DOMTypeJs implements TextTrackCueList native "*TextTrackCueList" {

  int get length() native "return this.length;";

  TextTrackCueJs getCueById(String id) native;

  TextTrackCueJs item(int index) native;
}
