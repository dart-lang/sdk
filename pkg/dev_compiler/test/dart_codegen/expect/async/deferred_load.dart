part of dart.async;

@Deprecated("Dart sdk v. 1.8")
class DeferredLibrary {
  final String libraryName;
  final String uri;
  const DeferredLibrary(this.libraryName, {this.uri});
  Future<Null> load() {
    throw 'DeferredLibrary not supported. ' 'please use the `import "lib.dart" deferred as lib` syntax.';
  }
}
class DeferredLoadException implements Exception {
  DeferredLoadException(String this._s);
  String toString() => "DeferredLoadException: '$_s'";
  final String _s;
}
