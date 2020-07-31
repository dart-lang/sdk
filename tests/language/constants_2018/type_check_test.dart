// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that type checks (is) are allowed.

import "package:expect/expect.dart";

main() {
  const c = C();
  const l = [1];
  const s = "a";

  Expect.equals(1, const T.length(s, 42).value);
  Expect.equals(42, const T.length(l, 42).value);
  Expect.equals(1, const T.length2(s, 42).value);
  Expect.equals(42, const T.length2(l, 42).value);

  Expect.equals(3, const T.sum(1, 2).value);
  Expect.equals(3.7, const T.sum(1.5, 2.2).value);
  Expect.equals("abc", const T.sum("a", "bc").value);
  Expect.equals("a", const T.sum("a", 2).value);
}

class T {
  final Object value;
  const T.length(dynamic l, int defaultValue)
      : value = l is String ? l.length : defaultValue;
  const T.length2(dynamic l, int defaultValue)
      : value = l is! String ? defaultValue : l.length;
  const T.sum(dynamic o1, dynamic o2)
      : value = ((o1 is num) & (o2 is num)) | ((o1 is String) & (o2 is String))
            ? o1 + o2
            : o1;
}

class C {
  const C();
  dynamic operator +(dynamic other) => throw "Never";
  bool operator <(dynamic other) => throw "Never";
}
