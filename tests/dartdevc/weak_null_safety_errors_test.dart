// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Requirements=nnbd-weak

// dartdevcOptions=--weak-null-safety-errors

import 'package:expect/expect.dart';

void main() {
  Expect.throwsTypeError(() => null as int);
  dynamic dynamicNull = null;
  Expect.throwsTypeError(() => fn(dynamicNull));
}

void fn(StringBuffer arg) {}
