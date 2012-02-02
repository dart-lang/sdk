
class _MediaQueryListJs extends _DOMTypeJs implements MediaQueryList native "*MediaQueryList" {

  bool get matches() native "return this.matches;";

  String get media() native "return this.media;";

  void addListener(_MediaQueryListListenerJs listener) native;

  void removeListener(_MediaQueryListListenerJs listener) native;
}
