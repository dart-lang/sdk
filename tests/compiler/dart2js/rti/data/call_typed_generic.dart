// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:meta/dart2js.dart';

/*strong.class: A:direct,explicit=[A.T],needsArgs*/
/*omit.class: A:*/
class A<T> {
  /*strong.element: A.call:*/
  /*omit.element: A.call:*/
  call(T t) {}
}

@noInline
test(o) => o is Function(int);

main() {
  Expect.isFalse(test(new A<int>()));
  Expect.isFalse(test(new A<String>()));
  new A().call(null); // Use .call to ensure it is live.
}
