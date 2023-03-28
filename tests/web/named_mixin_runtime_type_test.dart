// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(https://github.com/dart-lang/sdk/issues/51557): Decide if the mixins
// being applied in this test should be "mixin", "mixin class" or the test
// should be left at 2.19.
// @dart=2.19

import 'package:expect/expect.dart';

abstract class A {}

abstract class B {}

class C = B with A;

@pragma('dart2js:noInline')
test(o) => o.runtimeType;

main() {
  Expect.equals(C, test(new C()));
}
