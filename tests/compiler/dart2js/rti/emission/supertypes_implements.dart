// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*class: A:checkedInstance*/
class A {}

/*class: B:*/
class B extends A {}

/*class: C:checks=[$isA],instance*/
class C implements B {} // Implements A through `implements B`.

@pragma('dart2js:noInline')
test(o) => o is A;

main() {
  test(new C());
  test(null);
}
