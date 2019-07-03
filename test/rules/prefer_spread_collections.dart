// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

f() {
  var ints = [1, 2, 3];
  print(['a']..addAll(ints.map((i) => i.toString()))..addAll(['c'])); // LINT
}

var l = ['a']..addAll(['b']); // OK -- prefer_inlined_adds

var l1 = [];
var l2 = l1..addAll(['b']); // OK

var things;
var l3 = ['a']..addAll(things ?? const []); // LINT
var l4 = ['a']..addAll(things ?? []); // LINT
var l7 = []..addAll(things); // LINT

// Control flow.

bool condition;
var l5 = ['a']..addAll(condition ? things : const []); // LINT
var l6 = ['a']..addAll(condition ? things : []); // LINT

class A {
 void addAll(Iterable iterable) { }
}

g() {
  A()..addAll(['a']); // OK
}

const thangs = [];
const cc = []..addAll(thangs); // OK -- don't show on invalid code
