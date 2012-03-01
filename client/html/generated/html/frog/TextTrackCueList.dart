
class _TextTrackCueListImpl implements TextTrackCueList native "*TextTrackCueList" {

  final int length;

  _TextTrackCueImpl getCueById(String id) native;

  _TextTrackCueImpl item(int index) native;
}
