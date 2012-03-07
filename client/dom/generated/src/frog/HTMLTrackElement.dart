
class _HTMLTrackElementJs extends _HTMLElementJs implements HTMLTrackElement native "*HTMLTrackElement" {

  static final int ERROR = 3;

  static final int LOADED = 2;

  static final int LOADING = 1;

  static final int NONE = 0;

  bool isDefault;

  String kind;

  String label;

  final int readyState;

  String src;

  String srclang;

  final _TextTrackJs track;
}
