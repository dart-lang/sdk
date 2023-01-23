class Foo {
  final (int a, int b) x = (42, 42);
  static (int a, int b) y = (42, 42);
  static final (int a, int b) z = (42, 42);
  static const (int a, int b) b = (42, 42);
  late (int a, int b) c;
  late final (int a, int b) d;
}
