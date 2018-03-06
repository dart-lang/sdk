// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:meta/dart2js.dart';

/*class: C:checks=[],functionType,instance,typeArgument*/
class C {
  call(int i) {}
}

/*class: D:checks=[],functionType,instance,typeArgument*/
class D {
  call(double i) {}
}

@noInline
test1(o) => o is Function(int);

@noInline
test2(o) => o is List<Function(int)>;

main() {
  Expect.isTrue(test1(new C()));
  Expect.isFalse(test1(new D()));
  Expect.isTrue(test2(<C>[]));
  Expect.isFalse(test2(<D>[]));
}
