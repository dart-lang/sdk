// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/dart2js.dart';

/*class: A:implicit=[A],required,checks=[A]*/
class A {}

/*class: B:needsArgs,test,explicit=[B.T]*/
class B<T> {
  @noInline
  method(T t) => t is T;
}

main() {
  new B<A>().method(new A());
}
