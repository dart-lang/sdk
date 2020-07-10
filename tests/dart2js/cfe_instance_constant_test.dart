// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for CFE constant evaluation. The evaluation of [Class9.field]
// assumed that its initializer did not hold an unevaluated constant.

import 'package:expect/expect.dart';

const dynamic zero_ = const bool.fromEnvironment("x") ? null : 0;

class Class9 {
  final field = zero_;
  const Class9();
}

const c0 = const bool.fromEnvironment("x") ? null : const Class9();

main() {
  Expect.equals(0, c0!.field);
}
