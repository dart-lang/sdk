
class MediaQueryList native "MediaQueryList" {

  bool matches;

  String media;

  void addListener(MediaQueryListListener listener) native;

  void removeListener(MediaQueryListListener listener) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
