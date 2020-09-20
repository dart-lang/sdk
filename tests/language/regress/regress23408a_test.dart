// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library regress_23408a_test;

import 'package:expect/expect.dart';

import 'regress23408_lib.dart' deferred as lib;

class A<T> extends C {
  get t => T;
}

class C {
  C();
  factory C.l() = A<lib.K>;
  //                ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ANNOTATION_DEFERRED_CLASS
  // [cfe] unspecified
  get t => null;
}

void main() async {
  await lib.loadLibrary();
  Expect.equals(lib.K, C.l().t);
}
