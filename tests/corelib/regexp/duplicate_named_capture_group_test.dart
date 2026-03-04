// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

void main() {
  var r = RegExp(r"0x(?<digits>[a-f0-9]+)|(?<digits>\d+)");

  var m = r.firstMatch("0xabc")!;
  Expect.equals(2, m.groupCount);
  Expect.listEquals(["digits"], [...m.groupNames]);
  Expect.equals("abc", m.namedGroup("digits"));
  Expect.equals("abc", m[1]);
  Expect.isNull(m[2]);

  m = r.firstMatch("123")!;
  Expect.equals(2, m.groupCount);
  Expect.listEquals(["digits"], [...m.groupNames]);
  Expect.equals("123", m.namedGroup("digits"));
  Expect.isNull(m[1]);
  Expect.equals("123", m[2]);

  r = RegExp(r"(?<unmatched>A)|(?<unmatched>B)|(?<matched>C)|(?<matched>D)");
  m = r.firstMatch("D")!;
  Expect.equals(4, m.groupCount);
  Expect.listEquals(["unmatched", "matched"], [...m.groupNames]);
  Expect.isNull(m.namedGroup("unmatched"));
  Expect.equals("D", m.namedGroup("matched"));
  Expect.isNull(m[1]);
  Expect.isNull(m[2]);
  Expect.isNull(m[3]);
  Expect.equals("D", m[4]);
}
