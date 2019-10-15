// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N unnecessary_null_in_if_null_operators`

var x = 1 ?? null; //LINT
var y = 1 ?? 1; //OK
var z = null ?? 1; //LINT

class X {
  m1() {
    var x = 1 ?? null; //LINT
    var y = 1 ?? 1; //OK
    var z = null ?? 1; //LINT
  }
}
