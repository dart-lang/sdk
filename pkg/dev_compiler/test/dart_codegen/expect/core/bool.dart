part of dart.core;

class bool {
  @patch factory bool.fromEnvironment(String name, {bool defaultValue: false}) {
    throw new UnsupportedError(
        'bool.fromEnvironment can only be used as a const constructor');
  }
  String toString() {
    return this ? "true" : "false";
  }
}
