import 'package:foo/test11.dart';

class Abc {
  Abc() {}
  factory Abc.a() {
    return Abc2();
  }
  // Abc3 currently gets in --- it doesn't have to.
  factory Abc.b() => Abc3();
  var v1 = Abc4();
  var v2 = new Abc5();
}
