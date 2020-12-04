// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*class: E:
 class_unit=2{lib3},
 type_unit=2{lib3}
*/
class E<T> {
  const E();
}

/*class: F:
 class_unit=none,
 type_unit=3{lib1, lib3}
*/
class F {}

const dynamic field = const E<F>();
