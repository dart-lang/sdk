class Foo {
  String? x;
  int y;

  Foo(Object? o) : x = o as String?, y = 0;
  Foo.a(dynamic o) : y = o is String ? o.length : null, x = null;
  Foo.b(dynamic o) : y = o is String? ? o.length : null, x = null;
  Foo.c(dynamic o) : y = o as String ? o.length : null, x = null;
  Foo.d(dynamic o) : y = o as String? ? o.length : null, x = null;
}
