import "package:expect/expect.dart";

void main() {
  var h = "hello", w = "world";
  Expect.notEquals(h.hashCode, w.hashCode);
  Expect.notEquals((String).hashCode, (int).hashCode);
  var c = h.runtimeType.hashCode;
  Expect.isTrue(c is int);
  Expect.notEquals(c, null);
  Expect.notEquals(c, 0);
}
