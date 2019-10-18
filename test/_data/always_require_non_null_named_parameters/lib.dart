import 'package:meta/meta.dart';

class A {
  var a;
  A.c({
    @required a, // OK
    b, // LINT
    @required c, // OK
  })
      : assert(a != null),
        assert(b != null);
}
