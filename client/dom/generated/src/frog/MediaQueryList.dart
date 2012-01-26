
class MediaQueryListJs extends DOMTypeJs implements MediaQueryList native "*MediaQueryList" {

  bool get matches() native "return this.matches;";

  String get media() native "return this.media;";

  void addListener(MediaQueryListListenerJs listener) native;

  void removeListener(MediaQueryListListenerJs listener) native;
}
