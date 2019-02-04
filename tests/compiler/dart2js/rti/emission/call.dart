// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:meta/dart2js.dart';

/*class: A:checks=[],instance*/
class A {
  call() {}
}

@noInline
test(o) => o is Function;

main() {
  Expect.isFalse(test(new A()));
  Expect.isFalse(test(null));
}
