// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests syntax edge cases.
import 'package:expect/expect.dart';

void main() {
  // Trailing comma.
  Expect.listEquals([1, 2], [...[1, 2],]);
  Expect.mapEquals({1: 1, 2: 2}, {...{1: 1, 2: 2},});
  Expect.setEquals({1, 2}, {...{1, 2},});

  // Precedence.
  Expect.listEquals([1, 2, 3], [1, ...true ? [2] : [], 3]);
  Expect.listEquals([1, 3], [1, ...?true ? null : [], 3]);

  var a = [0];
  Expect.listEquals([1, 2, 3], [1, ...a = [2], 3]);
  Expect.listEquals([1, 3], [1, ...?a = null, 3]);

  var b = [2];
  Expect.listEquals([1, 2, 3, 4], [1, ...b..add(3), 4]);
  b = [2];
  Expect.listEquals([1, 2, 3, 4], [1, ...?b..add(3), 4]);
}
