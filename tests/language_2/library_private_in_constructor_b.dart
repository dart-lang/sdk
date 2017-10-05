// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library LibraryPrivateInConstructorB;

import "library_private_in_constructor_a.dart";

class PrivateB {
  const PrivateB();
  final _val = 42;
}

var fooB = const PrivateB();

class B extends A {
  var y;
  B() : this.y = fooB._val;
}
