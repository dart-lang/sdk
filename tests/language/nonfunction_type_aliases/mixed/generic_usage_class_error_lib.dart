// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Introduce an aliased type.

class A<X> {
  A();
  A.named();
  static void staticMethod<Y>() {}
}

typedef T<X> = A<X>;
