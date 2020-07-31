// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that short-circuit operators do not care about the unevaluated part.

import "package:expect/expect.dart";

main() {
  const c = C();
  // Short-circuited operations.
  // Non-taken branch of ?:.
  const c1 = true ? c : c + c;
  const c2 = false ? c + c : c;
  // Non-taken part of &&, ||, ??.
  const c3 = (c != null) || c < c;
  const c4 = (c == null) && c < c;
  const c5 = (c as dynamic) ?? c + c;
  Expect.identical(c, c1);
  Expect.identical(c, c2);
  Expect.isTrue(c3);
  Expect.isFalse(c4);
  Expect.identical(c, c5);
  // Nested short-circuiting.
  const c6 = true ? c == null && c + c : c < c;
  Expect.isFalse(c6);

  // Concrete use-case.
  Expect.equals(1, const T.length("a").value);
  Expect.equals(0, const T.length("").value);
  Expect.equals(0, const T.length(null).value);
  Expect.equals(1, T.length([1]).value);
  Expect.equals(0, T.length([]).value);
  Expect.equals(0, T.length(null).value);

  Expect.equals(1, const T.asserts("a").value);
  Expect.equals(0, const T.asserts("").value);
  Expect.equals(0, const T.asserts(null).value);
  Expect.equals(1, T.asserts([1]).value);
  Expect.equals(0, T.asserts([]).value);
  Expect.equals(0, T.asserts(null).value);
}

class T {
  final Object value;
  const T(this.value);
  const T.length(dynamic l) : value = (l == null ? 0 : l.length);
  const T.asserts(dynamic l)
      : assert(l == null || l.length < 2),
        value = (l ?? "").length;
}

class C {
  const C();
  dynamic operator +(dynamic other) => throw "Never";
  bool operator <(dynamic other) => throw "Never";
}
