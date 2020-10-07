// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// These tests verify that the kinds of constructs we expect to cause type
// promotion continue to function properly even when used inside unreachable
// code.

conditionalIs(Object o) {
  return;
  o is int ? null : throw 'bad';
  /*int*/ o;
}

conditionalIsNot(Object o) {
  return;
  o is! int ? throw 'bad' : null;
  /*int*/ o;
}

conditionalJoinFalse(Object o, bool b) {
  return;
  if (b ? o is! int : o is! int) return;
  /*int*/ o;
}

conditionalJoinTrue(Object o, bool b) {
  return;
  if (!(b ? o is int : o is int)) return;
  /*int*/ o;
}

doBreak(Object o) {
  return;
  do {
    if (o is int) break;
  } while (true);
  /*int*/ o;
}

doContinue(Object o) {
  return;
  do {
    if (o is int) continue;
    return;
  } while (false);
  /*int*/ o;
}

doCondition(Object o) {
  return;
  do {} while (o is! int);
  /*int*/ o;
}

ifIsNot(Object o) {
  return;
  if (o is! int) return;
  /*int*/ o;
}

ifIsNot_listElement(Object o) {
  return;
  [if (o is! int) throw 'x'];
  /*int*/ o;
}

ifIsNot_setElement(Object o) {
  return;
  ({if (o is! int) throw 'x'});
  /*int*/ o;
}

ifIsNot_mapElement(Object o) {
  return;
  ({if (o is! int) 0: throw 'x'});
  /*int*/ o;
}
