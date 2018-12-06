// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N avoid_init_to_null`

var x = null; //LINT
var y; //OK
var z = 1; //OK
const nil = null; //OK
final nil2 = null; //OK
foo({p: null}) {} //LINT

class X {
  static const nil = null; //OK
  final nil2 = null; //OK
  int x = null; //LINT
  int y; //OK
  int z;

  X({int a: null}); //LINT
  X.b({this.z: null}); //LINT

  fooNamed({
    p: null, //LINT
    p1 = null, //LINT
    var p2 = null, //LINT
    p3 = 1, //OK
    p4, //OK
  }) {}

  fooOptional([
    p = null, //LINT
    p1 = null, //LINT
    var p2 = null, //LINT
    p3 = 1, //OK
    p4, //OK
  ]) {}
}
