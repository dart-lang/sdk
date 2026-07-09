// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

// Regression test for https://github.com/dart-lang/sdk/issues/43281.

void main() {
  const s = {1, 2, 3, null};
  Expect.equals(4, s.length);
  Expect.isTrue(s is Set<int?>);
}
