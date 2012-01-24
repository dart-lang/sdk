
class MediaQueryListJS implements MediaQueryList native "*MediaQueryList" {

  bool get matches() native "return this.matches;";

  String get media() native "return this.media;";

  void addListener(MediaQueryListListenerJS listener) native;

  void removeListener(MediaQueryListListenerJS listener) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
