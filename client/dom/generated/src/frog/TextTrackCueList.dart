
class _TextTrackCueListJs extends _DOMTypeJs implements TextTrackCueList native "*TextTrackCueList" {

  final int length;

  _TextTrackCueJs getCueById(String id) native;

  _TextTrackCueJs item(int index) native;
}
