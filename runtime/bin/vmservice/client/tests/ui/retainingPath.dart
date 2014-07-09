/*
0.
dart --observe retainingPath.dart
1.
isolate 'root'
2.
library 'retainingPath.dart'
3.
class 'Foo'
4.
under 'instances', find 'strongly reachable' list; it should contain 2 elements, one of which should have a field containing "87"
5.
instance "87"
6.
find 'retaining path'; it should have length 4, and be annotated as follows:
 "87" in var a
 Foo in var b
 Foo at list index 5 of
 _List(10)
*/
class Foo {
  var a;
  var b;
  Foo(this.a, this.b);
}

main() {
  var list = new List<Foo>(10);
  list[5] = new Foo(42.toString(), new Foo(87.toString(), 17.toString()));
  while (true) {}
}
