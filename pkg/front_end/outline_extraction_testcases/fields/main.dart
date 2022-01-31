import "foo.dart";

class A {
  Bar field = new Bar();
  Bar2 field2 = new Bar2();
  var field3 = new Bar3(), field4 = new Bar4();
}

mixin A2 {
  Baz field = new Baz();
  Baz2 field2 = new Baz2();
  var field3 = new Baz3(), field4 = new Baz4();
}

extension A3 on Object {
  static Foo field = new Foo();
  static Foo2 field2 = new Foo2();
  static var field3 = new Foo3(), field4 = new Foo4();
}
