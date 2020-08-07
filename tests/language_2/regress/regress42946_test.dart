// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

/// https://github.com/dart-lang/sdk/issues/42946
void main() {
  // fix bug in constant eval
  const x = (2.0 == 2);
  const a = (2.0 == 2.0);
  const b = (0.0 == 0.0);
  const c = (double.nan == double.nan);
  const d = (2.0 == 1.0);

  Expect.isTrue(x);
  Expect.isTrue(a);
  Expect.isTrue(b);
  Expect.isFalse(c);
  Expect.isFalse(d);
}
