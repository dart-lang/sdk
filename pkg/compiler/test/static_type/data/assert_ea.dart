// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

class Class {
  Class next;
}

main() {
  assert1(null);
  assert2(null);
  assert3(null);
  assert4(null);
  assert5(null);
  assert6(null);
  assert7(null);
  assert8(null);
}

assert1(Class c) {
  assert(/*Class*/ c /*invoke: [Class]->bool*/ != null);
  /*Class*/ c.next;
}

assert2(Class c) {
  assert(/*Class*/ c /*invoke: [Class]->bool*/ == null);
  /*Null*/ c.next;
}

assert3(Class c) {
  bool b;
  assert(/*Class*/ c /*invoke: [Class]->bool*/ != null);
  if (/*bool*/ b) return;
  /*Class*/ c.next;
}

assert4(Class c) {
  bool b;
  assert(/*Class*/ c /*invoke: [Class]->bool*/ == null);
  if (/*bool*/ b) return;
  /*Null*/ c.next;
}

assert5(dynamic c) {
  assert(/*dynamic*/ c is Class);
  /*Class*/ c.next;
}

assert6(dynamic c) {
  assert(/*dynamic*/ c is! Class);
  /*dynamic*/ c.next;
}

assert7(dynamic c) {
  bool b;
  assert(/*dynamic*/ c is Class);
  if (/*bool*/ b) return;
  /*Class*/ c.next;
}

assert8(dynamic c) {
  bool b;
  assert(/*dynamic*/ c is! Class);
  if (/*bool*/ b) return;
  /*dynamic*/ c.next;
}
