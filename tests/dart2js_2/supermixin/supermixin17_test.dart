// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:expect/expect.dart';

class S {}

class M {}

class SuperC = S with M;

class SuperA {}

class SuperB extends SuperA implements SuperC {}

mixin Mixin on SuperC, SuperA {}

class Class extends SuperB with Mixin {}

@pragma('dart2js:assumeDynamic')
@pragma('dart2js:noInline')
test(c) {
  Expect.isTrue(c is Mixin, "Unexpected result for $c is Mixin");
  Expect.isTrue(c is SuperC, "Unexpected result for $c is SuperC");
  Expect.isTrue(c is SuperA, "Unexpected result for $c is SuperA");
  Expect.isTrue(c is S, "Unexpected result for $c is S");
  Expect.isTrue(c is M, "Unexpected result for $c is M");
}

main() {
  new SuperC();
  test(new Class());
}
