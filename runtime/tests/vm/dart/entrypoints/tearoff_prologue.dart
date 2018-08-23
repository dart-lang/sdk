// No type checks are removed here, but we can skip the argument count check.

import "package:expect/expect.dart";
import "common.dart";

class C<T> {
  @NeverInline
  @pragma("vm:testing.unsafe.trace-entrypoints-fn", validateTearoff)
  void samir1(T x) {
    if (x == -1) {
      throw "oh no";
    }
  }
}

test(List<String> args) {
  var c = new C<int>();
  var f = c.samir1;

  // Warmup.
  expectedEntryPoint = -1;
  expectedTearoffEntryPoint = -1;
  for (int i = 0; i < 100; ++i) {
    f(i);
  }

  expectedEntryPoint = 0;
  expectedTearoffEntryPoint = 1;
  int iterations = benchmarkMode ? 100000000 : 100;
  for (int i = 0; i < iterations; ++i) {
    f(i);
  }

  Expect.isTrue(validateRan);
}
