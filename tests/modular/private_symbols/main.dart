import 'package:expect/expect.dart';
import 'a.dart';
import 'b.dart';

void main() {
  var s1 = foo_a();
  var s2 = foo_b();
  Expect.identical(s1, s2);
  Expect.equals(s1, s2);
}
