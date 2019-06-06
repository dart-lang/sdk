// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests syntax edge cases.
import 'package:expect/expect.dart';

void main() {
  // Trailing comma after then.
  Expect.listEquals([1], [if (true) 1,]);
  Expect.mapEquals({1: 1}, {if (true) 1: 1,});
  Expect.setEquals({1}, {if (true) 1,});

  // Trailing comma after else.
  Expect.listEquals([1], [if (true) 1 else 2,]);
  Expect.mapEquals({1: 1}, {if (true) 1: 1 else 2: 2,});
  Expect.setEquals({1}, {if (true) 1 else 2,});

  // Trailing comma after for.
  Expect.listEquals([1], [1, for (; false;) 2,]);
  Expect.mapEquals({1: 1}, {1: 1, for (; false;) 2: 2,});
  Expect.setEquals({1}, {1, for (; false;) 2,});

  // Dangling else.
  Expect.listEquals([1], [if (true) if (false) 0 else 1]);
  Expect.listEquals([1], [if (true) if (false) 0 else 1 else 2]);
  Expect.listEquals([2], [if (false) if (false) 0 else 1 else 2]);

  // Precedence of then.
  Expect.listEquals([1, 2, 3], [1, if (true) true ? 2 : 0, 3]);
  var a = 0;
  Expect.listEquals([1, 2, 3], [1, if (true) a = 2, 3]);

  // Precedence of else.
  Expect.listEquals([1, 2, 3], [1, if (false) 0 else true ? 2 : 0, 3]);
  a = 0;
  Expect.listEquals([1, 2, 3], [1, if (false) 0 else a = 2, 3]);

  // Precedence of for.
  Expect.listEquals([1, 2, 3],
      [1, for (var i = 0; i < 1; i++) true ? 2 : 0, 3]);
  a = 0;
  Expect.listEquals([1, 2, 3], [1, for (var i = 0; i < 1; i++) a = 2, 3]);
}
