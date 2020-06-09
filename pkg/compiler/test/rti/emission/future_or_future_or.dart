// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'dart:async';
import 'package:expect/expect.dart';

/*class: global#Future:checkedInstance*/

/*class: A:checkedInstance,checkedTypeArgument,checks=[],instance,typeArgument*/
class A {}

/*class: B:checks=[],instance*/
class B {}

@pragma('dart2js:noInline')
test(o) => o is FutureOr<FutureOr<A>>;

main() {
  Expect.isTrue(test(new A()));
  Expect.isFalse(test(new B()));
}
