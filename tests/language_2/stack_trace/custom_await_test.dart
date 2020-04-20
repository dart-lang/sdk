import "dart:async";
import "package:expect/expect.dart";

class Blah implements StackTrace {
  Blah(this._trace);

  toString() {
    return "Blah " + _trace.toString();
  }

  var _trace;
}

foo() {
  var x = "\nBloop\nBleep\n";
  return new Future.error(42, new Blah(x));
}

main() async {
  try {
    var x = await foo();
    Expect.fail("Should not reach here.");
  } on int catch (e, s) {
    Expect.equals(42, e);
    Expect.equals("Blah \nBloop\nBleep\n", s.toString());
    return;
  }
  Expect.fail("Unreachable.");
}
