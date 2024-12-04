// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code as governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--deterministic --optimization_counter_threshold=150

import "package:expect/expect.dart";
import "package:expect/variations.dart";

class A<T> {}

class B<T> {
  void foo(T x) {}
  void bar(A<T> x) {}
}

B<(num, num)> b1 = (int.parse('1') == 1) ? B<(int, int)>() : B<(num, num)>();
B<({num foo})?> b2 =
    (int.parse('1') == 1) ? B<({int foo})>() : B<({num foo})?>();
B<(num?, {num? foo})?> b3 =
    (int.parse('1') == 1) ? B<(int, {int? foo})?>() : B<(num?, {num? foo})?>();

doTests() {
  b1 as B<(int, int)>;
  b1 as B<(int, num)>;
  b1 as B<(int, int?)>;
  b1 as B<(int, int)>?;
  b1 as B<Object>;
  b1 as B<Record>;
  Expect.throwsTypeError(() => b1 as B<(int, double)>);
  Expect.throwsTypeError(() => b1 as B<(double, int)>);
  Expect.throwsTypeError(() => b1 as B<Null>);
  Expect.throwsTypeError(() => b1 as B<Never>);
  Expect.throwsTypeError(() => b1 as B<Function>);
  Expect.throwsTypeError(() => b1 as B<int>);
  Expect.throwsTypeError(() => b1 as B<(int, {int foo})>);
  Expect.throwsTypeError(() => b1 as B<({int foo})>);

  b2 as B<({int foo})>;
  b2 as B<({num foo})>;
  b2 as B<({int foo})>?;
  b2 as B<({int foo})?>;
  b2 as B<({int? foo})>;
  Expect.throwsTypeError(() => b2 as B<(int, int)>);
  Expect.throwsTypeError(() => b2 as B<({int bar})>);
  Expect.throwsTypeError(() => b2 as B<({double foo})>);

  b3 as B<(int, {int? foo})?>;
  if (!unsoundNullSafety) {
    Expect.throwsTypeError(() => b3 as B<(int, {int? foo})>);
    Expect.throwsTypeError(() => b3 as B<(int, {int foo})?>);
  }

  A<(int, int)>() as A<(int, num)>;
  A<(int, int)>() as A<Object>;
  A<(int, int)>() as A<Record>;
  Expect.throwsTypeError(() => A<(int, int)>() as A<(double, num)>);
  Expect.throwsTypeError(() => A<(int, int)>() as A<(num, double)>);
  Expect.throwsTypeError(() => A<(int, int)>() as A<Function>);
  Expect.throwsTypeError(() => A<(int, int)>() as A<int>);
  Expect.throwsTypeError(() => A<(int, int)>() as A<String>);

  A<({int foo})>() as A<({int? foo})>;
  A<({int foo})>() as A<({int foo})?>;
  A<({int foo})>() as A<({int foo})>?;
  if (!unsoundNullSafety) {
    Expect.throwsTypeError(() => A<({int? foo})>() as A<({int foo})>);
    Expect.throwsTypeError(() => A<({int? foo})>() as A<({int foo})?>);
    Expect.throwsTypeError(() => A<({int? foo})>() as A<({int foo})>?);
    Expect.throwsTypeError(() => A<({int foo})?>() as A<({int? foo})>);
    Expect.throwsTypeError(() => A<({int foo})?>() as A<({int foo})>);
    Expect.throwsTypeError(() => A<({int foo})?>() as A<({int foo})>?);
  }
}

main() {
  for (int i = 0; i < 200; ++i) {
    doTests();
  }
}
