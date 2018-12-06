// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N unnecessary_null_aware_assignments`

class X {
  m1() {
    var x;
    x ??= null; //LINT
    x ??= 1; //OK
  }
}
