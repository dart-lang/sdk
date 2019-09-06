// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:expect/expect.dart';

import 'def.dart';

const set3 = [...set1, ...set2];

main() {
  Expect.isTrue(set3.length == 5);
  Expect.setEquals(set3, {0, 1, 2, 3, 4});
}
