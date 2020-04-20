// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'from_agnostic_lib.dart';

const c1 = identical(a, b);
const c2 = {a: 0, b: 1};
const c3 = {a, b};
const c4 = a;
const c5 = b;

main() {
  a;
  b;
}
