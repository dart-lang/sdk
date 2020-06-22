// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

abstract class A {}

abstract class B {}

class C = B with A;

@pragma('dart2js:noInline')
test(o) => o.runtimeType;

main() {
  Expect.equals(C, test(new C()));
}
