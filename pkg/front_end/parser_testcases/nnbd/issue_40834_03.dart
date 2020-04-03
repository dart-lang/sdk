class Foo {
  String? x;
  int y;

  Foo(Object? o) : x = o != null ? o as String? : null, y = 0;

  void foo(dynamic x) {
    if (x is String? ? 4 : 2 == 4) {
      print("hello");
    }
  }

  void bar(dynamic x) {
    if (x is String ? 4 : 2 == 4) {
      print("hello");
    }
  }
}
