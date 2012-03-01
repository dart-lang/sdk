
class _MediaQueryListImpl implements MediaQueryList native "*MediaQueryList" {

  final bool matches;

  final String media;

  void addListener(_MediaQueryListListenerImpl listener) native;

  void removeListener(_MediaQueryListListenerImpl listener) native;
}
