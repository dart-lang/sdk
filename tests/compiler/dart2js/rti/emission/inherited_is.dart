// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:expect/expect.dart';

/*class: A:checkedInstance*/
class A {}

/*class: B:checks=[]*/
class B implements A {}

/*class: C:checks=[$isA],indirectInstance*/
class C = Object with B;

/*class: D:checks=[],instance*/
class D extends C {}

@pragma('dart2js:noInline')
test(o) => o is A;

main() {
  Expect.isTrue(test(new D()));
  Expect.isFalse(test(null));
}
