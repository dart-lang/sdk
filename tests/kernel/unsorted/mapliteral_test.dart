// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

main() {
  var map = {
    'k1': 'v1',
    'k2': 'v2',
    1: 2,
    1.5: 1.2,
    3: 3.14,
  };

  Expect.isTrue(map.length == 5);

  map['foo'] = 'bar';

  Expect.isTrue(map['k1'] == 'v1');
  Expect.isTrue(map['k2'] == 'v2');
  Expect.isTrue(map[1] == 2);
  Expect.isTrue(map[1.5] == 1.2);
  Expect.isTrue(map[3] == 3.14);
  Expect.isTrue(map['foo'] == 'bar');
  Expect.isTrue(map.length == 6);
}
