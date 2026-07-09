// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Regression test for https://github.com/dart-lang/sdk/issues/52593.
///
/// Adding the value returned from a method with a static return type of `void`
/// to a record and getting the value should not cause a runtime error.

import 'package:expect/expect.dart';

(Object?,) fn1() => (fn2() as Object?,);
void fn2() {}

@pragma('dart2js:noInline')
@pragma('dart2js:assumeDynamic')
confuse(x) {
  return x;
}

void main() {
  var r = fn1();
  Expect.isNull(r.$1);
  var d = confuse(fn1());
  Expect.isNull(d.$1);
}
