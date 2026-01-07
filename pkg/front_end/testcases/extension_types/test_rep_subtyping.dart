extension type ExtType<T>(T value) {}

void main() {
  ExtType<String> e = ExtType('s');
  String s = e; // Should be valid if E <: Rep
}
