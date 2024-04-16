// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Requirements=nnbd-weak
// dart2jsOptions=--experiment-null-safety-checks
// ddcOptions=--weak-null-safety-errors

import 'package:dart2js_runtime_metrics/null_safety.dart';
import 'package:expect/expect.dart';

void main() {
  onExtraNullSafetyError = (e, _) {
    throw e;
  };

  Expect.throwsTypeError(() => [1, 2, null] is List<int>);

  final getInt = () => null;
  Expect.throwsTypeError(() => getInt as int Function());

  Expect.throwsTypeError(() => [1, 2, null] as List<int>);

  Expect.throwsTypeError(() => null as String);

  Expect.throwsTypeError(() => null as Object);
}
