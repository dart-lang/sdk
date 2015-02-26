part of dart.core;

class bool {
  external const factory bool.fromEnvironment(String name,
      {bool defaultValue: false});
  String toString() {
    return this ? "true" : "false";
  }
}
