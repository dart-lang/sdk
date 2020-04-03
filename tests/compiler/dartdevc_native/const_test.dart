// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.6

import "package:expect/expect.dart";
import 'dart:_foreign_helper' show JS;
import 'dart:_runtime' as dart;

void main() {
  var data = JS('', '[1, 2, 3, 4]');
  Expect.isFalse(data is List<int>);

  var list = dart.constList(data, dart.unwrapType(int));
  Expect.isTrue(list is List<int>);
  Expect.throws(() {
    list[0] = 0;
  });

  var set = dart.constSet<int>(data);
  Expect.isTrue(set is Set<int>);
  Expect.isTrue(set.contains(3));
  Expect.throws(() => set.clear());

  var map = dart.constMap<int, int>(data);
  Expect.isTrue(map is Map<int, int>);
  Expect.equals(map[1], 2);
  Expect.throws(() {
    map[1] = 42;
  });
}
