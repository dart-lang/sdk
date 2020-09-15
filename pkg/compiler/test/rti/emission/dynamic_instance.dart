// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:expect/expect.dart';

/*class: B:checkedInstance,typeArgument*/
class B {}

/*class: C:checks=[],instance*/
class C {
  @pragma('dart2js:noInline')
  method1<T>(o) => method2<T>(o);

  @pragma('dart2js:noInline')
  method2<T>(o) => o is T;
}

/*class: D:checks=[$isB],instance*/
class D implements B {}

@pragma('dart2js:noInline')
test(o) => new C().method1<B>(o);

main() {
  Expect.isTrue(test(new D()));
  Expect.isFalse(test(null));
}
