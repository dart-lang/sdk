// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

main() {
  final l = [10, 20, 30];
  for (int i = l.length; i-- > 0;) {
    if (i > 0) l.insert(i, -1);
  }
  Expect.deepEquals([10, -1, 20, -1, 30], l);
}
