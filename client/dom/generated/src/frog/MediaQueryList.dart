
class _MediaQueryListJs extends _DOMTypeJs implements MediaQueryList native "*MediaQueryList" {

  final bool matches;

  final String media;

  void addListener(_MediaQueryListListenerJs listener) native;

  void removeListener(_MediaQueryListListenerJs listener) native;
}
