// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:meta/dart2js.dart';

/*class: B:checkedInstance,checks=[],typeArgument*/
class B {}

/*class: C:checks=[],instance*/
class C {
  @noInline
  method1<T>(o) => method2<T>(o);

  @noInline
  method2<T>(o) => o is T;
}

/*class: D:checks=[$isB],instance*/
class D implements B {}

@noInline
test(o) => new C().method1<B>(o);

main() {
  Expect.isTrue(test(new D()));
  Expect.isFalse(test(null));
}
