// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Regression test for https://github.com/dart-lang/sdk/issues/54375.
///
/// Records should support named elements with the names 'shape', 'values',
/// 'constructor', and 'prototype'.

import 'package:expect/expect.dart';

@pragma('dart2js:noInline')
@pragma('dart2js:assumeDynamic')
confuse(x) {
  return x;
}

void main() {
  var r = (shape: 123);
  Expect.equals(123, r.shape);
  var d = confuse(r);
  Expect.equals(123, d.shape);

  var r2 = (values: 'hello');
  Expect.equals('hello', r2.values);
  d = confuse(r2);
  Expect.equals('hello', d.values);

  var r3 = (constructor: Duration.zero);
  Expect.equals(Duration.zero, r3.constructor);
  d = confuse(r3);
  Expect.equals(Duration.zero, d.constructor);

  var r4 = (prototype: null);
  Expect.equals(null, r4.prototype);
  d = confuse(r4);
  Expect.equals(null, d.prototype);
}
