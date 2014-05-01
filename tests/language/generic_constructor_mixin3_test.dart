// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that parameter types types are checked correctly in the face of
// mixin application upon a generic constructor.

import 'checked_mode_helper.dart';

class A<X> {
  A(X x);
}

class B {}

class C1 = A<int> with B;
class C2 = A<String> with B;

void main() {
  var v = 0;
  checkNoDynamicTypeError(() => new C1(v));
  checkDynamicTypeError(() => new C2(v));
}
