// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*class: E:OutputUnit(3, {lib3})*/
class E<T> {
  const E();
}

/*class: F:OutputUnit(2, {lib1, lib3})*/
class F {}

const dynamic field = const E<F>();
