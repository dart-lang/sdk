// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N avoid_init_to_null`

int i = null; //OK (compilation error)
int? ii = null; //LINT
dynamic iii = null; //LINT

// todo (pq): mock and add FutureOr examples

var x = null; //LINT
var y; //OK
var z = 1; //OK
const nil = null; //OK
final nil2 = null; //OK
foo({p: null}) {} //LINT


class X {
  static const nil = null; //OK
  final nil2 = null; //OK

  // TODO(pq): ints are not nullable so we'll want to update the lint here
  // since it will produce a compilation error.
  int x = null; //OK (compilation error)
  int? xx = null; //LINT
  int y; //OK
  int z; //OK

  X({int a: null}) //OK (compilation error)
    : y = 1, z = 1;

  X.b({this.z: null}) //OK (compilation error)
    : y = 1;

  X.c({this.xx: null}) //LINT
      : y = 1, z = 1;


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
