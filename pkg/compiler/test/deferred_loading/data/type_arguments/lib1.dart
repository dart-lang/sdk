// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'lib3.dart';

/*class: A:OutputUnit(1, {lib1})*/
class A<T> {
  const A();
}

/*class: B:OutputUnit(1, {lib1})*/
class B {}

const dynamic field1 = const A<B>();

const dynamic field2 = const A<F>();
