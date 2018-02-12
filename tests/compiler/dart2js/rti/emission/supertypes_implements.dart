// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/dart2js.dart';

/*class: A:*/
class A {}

/*class: B:*/
class B extends A {}

/*class: C:checks=[$isA]*/
class C implements B {} // Implements A through `implements B`.

@noInline
test(o) => o is A;

main() {
  test(new C());
  test(null);
}
