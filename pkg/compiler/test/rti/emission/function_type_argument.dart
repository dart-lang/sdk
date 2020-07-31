// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:expect/expect.dart';

/*spec.class: C:checkedInstance,checks=[],instance,typeArgument*/
/*prod.class: C:checks=[],instance,typeArgument*/
class C {
  call(int i) {}
}

/*spec.class: D:checkedInstance,checks=[],instance,typeArgument*/
/*prod.class: D:checks=[],instance,typeArgument*/
class D {
  call(double i) {}
}

@pragma('dart2js:noInline')
test1(o) => o is Function(int);

@pragma('dart2js:noInline')
test2(o) => o is List<Function(int)>;

main() {
  Expect.isFalse(test1(new C()));
  Expect.isFalse(test1(new D()));
  Expect.isFalse(test2(<C>[]));
  Expect.isFalse(test2(<D>[]));
}
