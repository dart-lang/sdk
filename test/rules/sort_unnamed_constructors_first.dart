// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N sort_unnamed_constructors_first`

class A {
  A();
  A.named();
  A._();
}

class B {
  B.named();
  B(); //LINT
  B._();
}
