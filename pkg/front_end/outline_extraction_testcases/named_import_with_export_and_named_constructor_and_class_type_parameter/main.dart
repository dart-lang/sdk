import 'package:foo/a.dart' as foo;

class A {
  var c1 = foo.C<A>.b();
  var c2 = new foo.C2<A>.b();
}
