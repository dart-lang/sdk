import 'package:expect/expect.dart';

class A {
  A(ignore);
}

main() => Expect.throws(() => A(const [])); // oops, `new` is missing!
