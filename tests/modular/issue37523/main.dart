// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

import 'def.dart';

main() {
  const v1 = A(B());
  const v2 = ab;
  const v3 = A(b);
  Expect.equals(v1, v2);
  Expect.equals(v2, v3);
}
