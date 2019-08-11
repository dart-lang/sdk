// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:expect/expect.dart';

import 'def.dart';

const c1 = A(B());
const c2 = ab;
const c3 = A(b);

main() {
  Expect.equals(c1, c2);
  Expect.equals(c2, c3);
}
