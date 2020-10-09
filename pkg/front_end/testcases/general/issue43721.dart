import 'dart:async';

ok<T extends FutureOr<num>>(T t) {}
error<T extends FutureOr<int>>(T t) {}

bar(bool condition) {
  FutureOr<int> x = null;
  num n = 1;
  var z = condition ? x : n;

  ok(z); // Ok.
  error(z); // Error.
}

main() {}
