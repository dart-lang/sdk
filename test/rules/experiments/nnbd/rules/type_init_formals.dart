// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N type_init_formals`

class A {
  String? p1;
  String p2;

  A.w({required String this.p1}); // OK
  A.x({required String? this.p1}); // LINT
  A.y({required String? this.p2}); // OK
  A.z({required String this.p2}); // LINT
}
