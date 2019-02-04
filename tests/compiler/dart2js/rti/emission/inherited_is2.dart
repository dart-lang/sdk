// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:meta/dart2js.dart';

/*class: A:checkedInstance*/
class A {}

/*class: B:checks=[$isA],indirectInstance*/
class B implements A {}

/*class: C:checks=[],indirectInstance*/
class C extends B {}

/*class: D:checks=[],instance*/
class D extends C {}

@noInline
test(o) => o is A;

main() {
  Expect.isTrue(test(new D()));
  Expect.isFalse(test(null));
}
