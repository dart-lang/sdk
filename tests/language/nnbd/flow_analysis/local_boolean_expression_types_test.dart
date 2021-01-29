// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../static_type_helper.dart';

// This test checks whether a local boolean variable can be used to perform type
// promotion, for various kinds of boolean expressions that we expect to cause
// promotions, and various contexts in which those boolean variables could be
// used.
//
// For the boolean variable, we test the forms:
// - `<variable> is <Type>`
// - `<variable> is! <Type>`
// - `!<expr>`
// - `<variable> == null`
// - `<variable> != null`
// - `null == <variable>`
// - `null != <variable>`
// - `<expr> && <expr>`
// - `<expr> || <expr>`
// - `<variable> is <Type> ? true : false`
// - `<variable> = <expr>`
// For the use site, we test the forms:
// - `(<variable>)`
// - `!<variable>`
// - `<variable> && <expr>`
// - `<expr> && <variable>`
// - `<variable> || <expr>`
// - `<expr> || <variable>`
// - `<variable> ? <expr> : <expr>`
// - `if (<variable>) ...`
// - `while (<variable>) ...`
// - `do ... while (<variable>)`
// - `for (...; <variable>; ...) ...`

bool _alwaysTrue(Object? x) => true;

bool _alwaysFalse(Object? x) => false;

is_(Object x) {
  bool b = x is int;
  if ((b)) {
    x.expectStaticType<Exactly<int>>();
  } else {
    x.expectStaticType<Exactly<Object>>();
  }
  if (!b) {
    x.expectStaticType<Exactly<Object>>();
  } else {
    x.expectStaticType<Exactly<int>>();
  }
  if (b && _alwaysTrue(x.expectStaticType<Exactly<int>>())) {
    x.expectStaticType<Exactly<int>>();
  } else {
    x.expectStaticType<Exactly<Object>>();
  }
  if (_alwaysTrue(x.expectStaticType<Exactly<Object>>()) && b) {
    x.expectStaticType<Exactly<int>>();
  } else {
    x.expectStaticType<Exactly<Object>>();
  }
  if (b || _alwaysFalse(x.expectStaticType<Exactly<Object>>())) {
    x.expectStaticType<Exactly<Object>>();
  } else {
    x.expectStaticType<Exactly<Object>>();
  }
  if (_alwaysFalse(x.expectStaticType<Exactly<Object>>()) || b) {
    x.expectStaticType<Exactly<Object>>();
  } else {
    x.expectStaticType<Exactly<Object>>();
  }
  if (b) {
    x.expectStaticType<Exactly<int>>();
  } else {
    x.expectStaticType<Exactly<Object>>();
  }
  while (b) {
    x.expectStaticType<Exactly<int>>();
    if (_alwaysTrue(null)) break;
  }
  x.expectStaticType<Exactly<Object>>();
  do {
    x.expectStaticType<Exactly<Object>>();
    if (_alwaysTrue(null)) break;
  } while (b);
  x.expectStaticType<Exactly<Object>>();
  for (x.expectStaticType<Exactly<Object>>();
      b;
      x.expectStaticType<Exactly<int>>()) {
    x.expectStaticType<Exactly<int>>();
    if (_alwaysTrue(null)) break;
  }
}

isNot(Object x) {
  bool b = x is! int;
  if ((b)) {
    x.expectStaticType<Exactly<Object>>();
  } else {
    x.expectStaticType<Exactly<int>>();
  }
  if (!b) {
    x.expectStaticType<Exactly<int>>();
  } else {
    x.expectStaticType<Exactly<Object>>();
  }
  if (b && _alwaysTrue(x.expectStaticType<Exactly<Object>>())) {
    x.expectStaticType<Exactly<Object>>();
  } else {
    x.expectStaticType<Exactly<Object>>();
  }
  if (_alwaysTrue(x.expectStaticType<Exactly<Object>>()) && b) {
    x.expectStaticType<Exactly<Object>>();
  } else {
    x.expectStaticType<Exactly<Object>>();
  }
  if (b || _alwaysFalse(x.expectStaticType<Exactly<int>>())) {
    x.expectStaticType<Exactly<Object>>();
  } else {
    x.expectStaticType<Exactly<int>>();
  }
  if (_alwaysFalse(x.expectStaticType<Exactly<Object>>()) || b) {
    x.expectStaticType<Exactly<Object>>();
  } else {
    x.expectStaticType<Exactly<int>>();
  }
  if (b) {
    x.expectStaticType<Exactly<Object>>();
  } else {
    x.expectStaticType<Exactly<int>>();
  }
  while (b) {
    x.expectStaticType<Exactly<Object>>();
    if (_alwaysTrue(null)) break;
  }
  x.expectStaticType<Exactly<Object>>();
  if (_alwaysFalse(null)) {
    // We test this at compile time only because we don't want to have an
    // infinite loop
    do {
      x.expectStaticType<Exactly<Object>>();
    } while (b);
    x.expectStaticType<Exactly<int>>();
  }
  x.expectStaticType<Exactly<Object>>();
  for (x.expectStaticType<Exactly<Object>>();
      b;
      x.expectStaticType<Exactly<Object>>()) {
    x.expectStaticType<Exactly<Object>>();
    if (_alwaysTrue(null)) break;
  }
}

not(Object x) {
  bool b = !(x is int);
  if ((b)) {
    x.expectStaticType<Exactly<Object>>();
  } else {
    x.expectStaticType<Exactly<int>>();
  }
  if (!b) {
    x.expectStaticType<Exactly<int>>();
  } else {
    x.expectStaticType<Exactly<Object>>();
  }
  if (b && _alwaysTrue(x.expectStaticType<Exactly<Object>>())) {
    x.expectStaticType<Exactly<Object>>();
  } else {
    x.expectStaticType<Exactly<Object>>();
  }
  if (_alwaysTrue(x.expectStaticType<Exactly<Object>>()) && b) {
    x.expectStaticType<Exactly<Object>>();
  } else {
    x.expectStaticType<Exactly<Object>>();
  }
  if (b || _alwaysFalse(x.expectStaticType<Exactly<int>>())) {
    x.expectStaticType<Exactly<Object>>();
  } else {
    x.expectStaticType<Exactly<int>>();
  }
  if (_alwaysFalse(x.expectStaticType<Exactly<Object>>()) || b) {
    x.expectStaticType<Exactly<Object>>();
  } else {
    x.expectStaticType<Exactly<int>>();
  }
  if (b) {
    x.expectStaticType<Exactly<Object>>();
  } else {
    x.expectStaticType<Exactly<int>>();
  }
  while (b) {
    x.expectStaticType<Exactly<Object>>();
    if (_alwaysTrue(null)) break;
  }
  x.expectStaticType<Exactly<Object>>();
  if (_alwaysFalse(null)) {
    // We test this at compile time only because we don't want to have an
    // infinite loop
    do {
      x.expectStaticType<Exactly<Object>>();
    } while (b);
    x.expectStaticType<Exactly<int>>();
  }
  x.expectStaticType<Exactly<Object>>();
  for (x.expectStaticType<Exactly<Object>>();
      b;
      x.expectStaticType<Exactly<Object>>()) {
    x.expectStaticType<Exactly<Object>>();
    if (_alwaysTrue(null)) break;
  }
}

eqNull(int? x) {
  bool b = (x == null);
  if ((b)) {
    x.expectStaticType<Exactly<int?>>();
  } else {
    x.expectStaticType<Exactly<int>>();
  }
  if (!b) {
    x.expectStaticType<Exactly<int>>();
  } else {
    x.expectStaticType<Exactly<int?>>();
  }
  if (b && _alwaysTrue(x.expectStaticType<Exactly<int?>>())) {
    x.expectStaticType<Exactly<int?>>();
  } else {
    x.expectStaticType<Exactly<int?>>();
  }
  if (_alwaysTrue(x.expectStaticType<Exactly<int?>>()) && b) {
    x.expectStaticType<Exactly<int?>>();
  } else {
    x.expectStaticType<Exactly<int?>>();
  }
  if (b || _alwaysFalse(x.expectStaticType<Exactly<int>>())) {
    x.expectStaticType<Exactly<int?>>();
  } else {
    x.expectStaticType<Exactly<int>>();
  }
  if (_alwaysFalse(x.expectStaticType<Exactly<int?>>()) || b) {
    x.expectStaticType<Exactly<int?>>();
  } else {
    x.expectStaticType<Exactly<int>>();
  }
  if (b) {
    x.expectStaticType<Exactly<int?>>();
  } else {
    x.expectStaticType<Exactly<int>>();
  }
  while (b) {
    x.expectStaticType<Exactly<int?>>();
    if (_alwaysTrue(null)) break;
  }
  x.expectStaticType<Exactly<int?>>();
  if (_alwaysFalse(null)) {
    // We test this at compile time only because we don't want to have an
    // infinite loop
    do {
      x.expectStaticType<Exactly<int?>>();
    } while (b);
    x.expectStaticType<Exactly<int>>();
  }
  x.expectStaticType<Exactly<int?>>();
  for (x.expectStaticType<Exactly<int?>>();
      b;
      x.expectStaticType<Exactly<int?>>()) {
    x.expectStaticType<Exactly<int?>>();
    if (_alwaysTrue(null)) break;
  }
}

notEqNull(int? x) {
  bool b = x != null;
  if ((b)) {
    x.expectStaticType<Exactly<int>>();
  } else {
    x.expectStaticType<Exactly<int?>>();
  }
  if (!b) {
    x.expectStaticType<Exactly<int?>>();
  } else {
    x.expectStaticType<Exactly<int>>();
  }
  if (b && _alwaysTrue(x.expectStaticType<Exactly<int>>())) {
    x.expectStaticType<Exactly<int>>();
  } else {
    x.expectStaticType<Exactly<int?>>();
  }
  if (_alwaysTrue(x.expectStaticType<Exactly<int?>>()) && b) {
    x.expectStaticType<Exactly<int>>();
  } else {
    x.expectStaticType<Exactly<int?>>();
  }
  if (b || _alwaysFalse(x.expectStaticType<Exactly<int?>>())) {
    x.expectStaticType<Exactly<int?>>();
  } else {
    x.expectStaticType<Exactly<int?>>();
  }
  if (_alwaysFalse(x.expectStaticType<Exactly<int?>>()) || b) {
    x.expectStaticType<Exactly<int?>>();
  } else {
    x.expectStaticType<Exactly<int?>>();
  }
  if (b) {
    x.expectStaticType<Exactly<int>>();
  } else {
    x.expectStaticType<Exactly<int?>>();
  }
  while (b) {
    x.expectStaticType<Exactly<int>>();
    if (_alwaysTrue(null)) break;
  }
  x.expectStaticType<Exactly<int?>>();
  do {
    x.expectStaticType<Exactly<int?>>();
    if (_alwaysTrue(null)) break;
  } while (b);
  x.expectStaticType<Exactly<int?>>();
  for (x.expectStaticType<Exactly<int?>>();
      b;
      x.expectStaticType<Exactly<int>>()) {
    x.expectStaticType<Exactly<int>>();
    if (_alwaysTrue(null)) break;
  }
}

nullEq(int? x) {
  bool b = (null == x);
  if ((b)) {
    x.expectStaticType<Exactly<int?>>();
  } else {
    x.expectStaticType<Exactly<int>>();
  }
  if (!b) {
    x.expectStaticType<Exactly<int>>();
  } else {
    x.expectStaticType<Exactly<int?>>();
  }
  if (b && _alwaysTrue(x.expectStaticType<Exactly<int?>>())) {
    x.expectStaticType<Exactly<int?>>();
  } else {
    x.expectStaticType<Exactly<int?>>();
  }
  if (_alwaysTrue(x.expectStaticType<Exactly<int?>>()) && b) {
    x.expectStaticType<Exactly<int?>>();
  } else {
    x.expectStaticType<Exactly<int?>>();
  }
  if (b || _alwaysFalse(x.expectStaticType<Exactly<int>>())) {
    x.expectStaticType<Exactly<int?>>();
  } else {
    x.expectStaticType<Exactly<int>>();
  }
  if (_alwaysFalse(x.expectStaticType<Exactly<int?>>()) || b) {
    x.expectStaticType<Exactly<int?>>();
  } else {
    x.expectStaticType<Exactly<int>>();
  }
  if (b) {
    x.expectStaticType<Exactly<int?>>();
  } else {
    x.expectStaticType<Exactly<int>>();
  }
  while (b) {
    x.expectStaticType<Exactly<int?>>();
    if (_alwaysTrue(null)) break;
  }
  x.expectStaticType<Exactly<int?>>();
  if (_alwaysFalse(null)) {
    // We test this at compile time only because we don't want to have an
    // infinite loop
    do {
      x.expectStaticType<Exactly<int?>>();
    } while (b);
    x.expectStaticType<Exactly<int>>();
  }
  x.expectStaticType<Exactly<int?>>();
  for (x.expectStaticType<Exactly<int?>>();
      b;
      x.expectStaticType<Exactly<int?>>()) {
    x.expectStaticType<Exactly<int?>>();
    if (_alwaysTrue(null)) break;
  }
}

nullNotEq(int? x) {
  bool b = null != x;
  if ((b)) {
    x.expectStaticType<Exactly<int>>();
  } else {
    x.expectStaticType<Exactly<int?>>();
  }
  if (!b) {
    x.expectStaticType<Exactly<int?>>();
  } else {
    x.expectStaticType<Exactly<int>>();
  }
  if (b && _alwaysTrue(x.expectStaticType<Exactly<int>>())) {
    x.expectStaticType<Exactly<int>>();
  } else {
    x.expectStaticType<Exactly<int?>>();
  }
  if (_alwaysTrue(x.expectStaticType<Exactly<int?>>()) && b) {
    x.expectStaticType<Exactly<int>>();
  } else {
    x.expectStaticType<Exactly<int?>>();
  }
  if (b || _alwaysFalse(x.expectStaticType<Exactly<int?>>())) {
    x.expectStaticType<Exactly<int?>>();
  } else {
    x.expectStaticType<Exactly<int?>>();
  }
  if (_alwaysFalse(x.expectStaticType<Exactly<int?>>()) || b) {
    x.expectStaticType<Exactly<int?>>();
  } else {
    x.expectStaticType<Exactly<int?>>();
  }
  if (b) {
    x.expectStaticType<Exactly<int>>();
  } else {
    x.expectStaticType<Exactly<int?>>();
  }
  while (b) {
    x.expectStaticType<Exactly<int>>();
    if (_alwaysTrue(null)) break;
  }
  x.expectStaticType<Exactly<int?>>();
  do {
    x.expectStaticType<Exactly<int?>>();
    if (_alwaysTrue(null)) break;
  } while (b);
  x.expectStaticType<Exactly<int?>>();
  for (x.expectStaticType<Exactly<int?>>();
      b;
      x.expectStaticType<Exactly<int>>()) {
    x.expectStaticType<Exactly<int>>();
    if (_alwaysTrue(null)) break;
  }
}

and(Object x, Object y) {
  bool b = x is int && y is int;
  if ((b)) {
    x.expectStaticType<Exactly<int>>();
    y.expectStaticType<Exactly<int>>();
  } else {
    x.expectStaticType<Exactly<Object>>();
    y.expectStaticType<Exactly<Object>>();
  }
  if (!b) {
    x.expectStaticType<Exactly<Object>>();
    y.expectStaticType<Exactly<Object>>();
  } else {
    x.expectStaticType<Exactly<int>>();
    y.expectStaticType<Exactly<int>>();
  }
  if (b &&
      _alwaysTrue([
        x.expectStaticType<Exactly<int>>(),
        y.expectStaticType<Exactly<int>>()
      ])) {
    x.expectStaticType<Exactly<int>>();
    y.expectStaticType<Exactly<int>>();
  } else {
    x.expectStaticType<Exactly<Object>>();
    y.expectStaticType<Exactly<Object>>();
  }
  if (_alwaysTrue([
        x.expectStaticType<Exactly<Object>>(),
        y.expectStaticType<Exactly<Object>>()
      ]) &&
      b) {
    x.expectStaticType<Exactly<int>>();
    y.expectStaticType<Exactly<int>>();
  } else {
    x.expectStaticType<Exactly<Object>>();
    y.expectStaticType<Exactly<Object>>();
  }
  if (b ||
      _alwaysFalse([
        x.expectStaticType<Exactly<Object>>(),
        y.expectStaticType<Exactly<Object>>()
      ])) {
    x.expectStaticType<Exactly<Object>>();
    y.expectStaticType<Exactly<Object>>();
  } else {
    x.expectStaticType<Exactly<Object>>();
    y.expectStaticType<Exactly<Object>>();
  }
  if (_alwaysFalse([
        x.expectStaticType<Exactly<Object>>(),
        y.expectStaticType<Exactly<Object>>()
      ]) ||
      b) {
    x.expectStaticType<Exactly<Object>>();
    y.expectStaticType<Exactly<Object>>();
  } else {
    x.expectStaticType<Exactly<Object>>();
    y.expectStaticType<Exactly<Object>>();
  }
  if (b) {
    x.expectStaticType<Exactly<int>>();
    y.expectStaticType<Exactly<int>>();
  } else {
    x.expectStaticType<Exactly<Object>>();
    y.expectStaticType<Exactly<Object>>();
  }
  while (b) {
    x.expectStaticType<Exactly<int>>();
    y.expectStaticType<Exactly<int>>();
    if (_alwaysTrue(null)) break;
  }
  x.expectStaticType<Exactly<Object>>();
  y.expectStaticType<Exactly<Object>>();
  do {
    x.expectStaticType<Exactly<Object>>();
    y.expectStaticType<Exactly<Object>>();
    if (_alwaysTrue(null)) break;
  } while (b);
  x.expectStaticType<Exactly<Object>>();
  y.expectStaticType<Exactly<Object>>();
  for ([
    x.expectStaticType<Exactly<Object>>(),
    y.expectStaticType<Exactly<Object>>()
  ];
      b;
      x.expectStaticType<Exactly<int>>(), y.expectStaticType<Exactly<int>>()) {
    x.expectStaticType<Exactly<int>>();
    y.expectStaticType<Exactly<int>>();
    if (_alwaysTrue(null)) break;
  }
}

or(Object x, Object y) {
  bool b = x is! int || y is! int;
  if ((b)) {
    x.expectStaticType<Exactly<Object>>();
    y.expectStaticType<Exactly<Object>>();
  } else {
    x.expectStaticType<Exactly<int>>();
    y.expectStaticType<Exactly<int>>();
  }
  if (!b) {
    x.expectStaticType<Exactly<int>>();
    y.expectStaticType<Exactly<int>>();
  } else {
    x.expectStaticType<Exactly<Object>>();
    y.expectStaticType<Exactly<Object>>();
  }
  if (b &&
      _alwaysTrue([
        x.expectStaticType<Exactly<Object>>(),
        y.expectStaticType<Exactly<Object>>()
      ])) {
    x.expectStaticType<Exactly<Object>>();
    y.expectStaticType<Exactly<Object>>();
  } else {
    x.expectStaticType<Exactly<Object>>();
    y.expectStaticType<Exactly<Object>>();
  }
  if (_alwaysTrue([
        x.expectStaticType<Exactly<Object>>(),
        y.expectStaticType<Exactly<Object>>()
      ]) &&
      b) {
    x.expectStaticType<Exactly<Object>>();
    y.expectStaticType<Exactly<Object>>();
  } else {
    x.expectStaticType<Exactly<Object>>();
    y.expectStaticType<Exactly<Object>>();
  }
  if (b ||
      _alwaysFalse([
        x.expectStaticType<Exactly<int>>(),
        y.expectStaticType<Exactly<int>>()
      ])) {
    x.expectStaticType<Exactly<Object>>();
    y.expectStaticType<Exactly<Object>>();
  } else {
    x.expectStaticType<Exactly<int>>();
    y.expectStaticType<Exactly<int>>();
  }
  if (_alwaysFalse([
        x.expectStaticType<Exactly<Object>>(),
        y.expectStaticType<Exactly<Object>>()
      ]) ||
      b) {
    x.expectStaticType<Exactly<Object>>();
    y.expectStaticType<Exactly<Object>>();
  } else {
    x.expectStaticType<Exactly<int>>();
    y.expectStaticType<Exactly<int>>();
  }
  if (b) {
    x.expectStaticType<Exactly<Object>>();
    y.expectStaticType<Exactly<Object>>();
  } else {
    x.expectStaticType<Exactly<int>>();
    y.expectStaticType<Exactly<int>>();
  }
  while (b) {
    x.expectStaticType<Exactly<Object>>();
    y.expectStaticType<Exactly<Object>>();
    if (_alwaysTrue(null)) break;
  }
  x.expectStaticType<Exactly<Object>>();
  y.expectStaticType<Exactly<Object>>();
  if (_alwaysFalse(null)) {
    // We test this at compile time only because we don't want to have an
    // infinite loop
    do {
      x.expectStaticType<Exactly<Object>>();
      y.expectStaticType<Exactly<Object>>();
    } while (b);
    x.expectStaticType<Exactly<int>>();
    y.expectStaticType<Exactly<int>>();
  }
  x.expectStaticType<Exactly<Object>>();
  y.expectStaticType<Exactly<Object>>();
  for ([
    x.expectStaticType<Exactly<Object>>(),
    y.expectStaticType<Exactly<Object>>()
  ];
      b;
      x.expectStaticType<Exactly<Object>>(),
      y.expectStaticType<Exactly<Object>>()) {
    x.expectStaticType<Exactly<Object>>();
    y.expectStaticType<Exactly<Object>>();
    if (_alwaysTrue(null)) break;
  }
}

conditional(Object x) {
  bool b = x is int ? true : false;
  if ((b)) {
    x.expectStaticType<Exactly<int>>();
  } else {
    x.expectStaticType<Exactly<Object>>();
  }
  if (!b) {
    x.expectStaticType<Exactly<Object>>();
  } else {
    x.expectStaticType<Exactly<int>>();
  }
  if (b && _alwaysTrue(x.expectStaticType<Exactly<int>>())) {
    x.expectStaticType<Exactly<int>>();
  } else {
    x.expectStaticType<Exactly<Object>>();
  }
  if (_alwaysTrue(x.expectStaticType<Exactly<Object>>()) && b) {
    x.expectStaticType<Exactly<int>>();
  } else {
    x.expectStaticType<Exactly<Object>>();
  }
  if (b || _alwaysFalse(x.expectStaticType<Exactly<Object>>())) {
    x.expectStaticType<Exactly<Object>>();
  } else {
    x.expectStaticType<Exactly<Object>>();
  }
  if (_alwaysFalse(x.expectStaticType<Exactly<Object>>()) || b) {
    x.expectStaticType<Exactly<Object>>();
  } else {
    x.expectStaticType<Exactly<Object>>();
  }
  if (b) {
    x.expectStaticType<Exactly<int>>();
  } else {
    x.expectStaticType<Exactly<Object>>();
  }
  while (b) {
    x.expectStaticType<Exactly<int>>();
    if (_alwaysTrue(null)) break;
  }
  x.expectStaticType<Exactly<Object>>();
  do {
    x.expectStaticType<Exactly<Object>>();
    if (_alwaysTrue(null)) break;
  } while (b);
  x.expectStaticType<Exactly<Object>>();
  for (x.expectStaticType<Exactly<Object>>();
      b;
      x.expectStaticType<Exactly<int>>()) {
    x.expectStaticType<Exactly<int>>();
    if (_alwaysTrue(null)) break;
  }
}

assignment(Object x) {
  // Note: flow analysis currently doesn't understand that `x = y` has the same
  // value as `y`, so no promotion happens in this test.
  bool b1;
  bool b2 = b1 = x is int;
  if ((b2)) {
    x.expectStaticType<Exactly<Object>>();
  } else {
    x.expectStaticType<Exactly<Object>>();
  }
  if (!b2) {
    x.expectStaticType<Exactly<Object>>();
  } else {
    x.expectStaticType<Exactly<Object>>();
  }
  if (b2 && _alwaysTrue(x.expectStaticType<Exactly<Object>>())) {
    x.expectStaticType<Exactly<Object>>();
  } else {
    x.expectStaticType<Exactly<Object>>();
  }
  if (_alwaysTrue(x.expectStaticType<Exactly<Object>>()) && b2) {
    x.expectStaticType<Exactly<Object>>();
  } else {
    x.expectStaticType<Exactly<Object>>();
  }
  if (b2 || _alwaysFalse(x.expectStaticType<Exactly<Object>>())) {
    x.expectStaticType<Exactly<Object>>();
  } else {
    x.expectStaticType<Exactly<Object>>();
  }
  if (_alwaysFalse(x.expectStaticType<Exactly<Object>>()) || b2) {
    x.expectStaticType<Exactly<Object>>();
  } else {
    x.expectStaticType<Exactly<Object>>();
  }
  if (b2) {
    x.expectStaticType<Exactly<Object>>();
  } else {
    x.expectStaticType<Exactly<Object>>();
  }
  while (b2) {
    x.expectStaticType<Exactly<Object>>();
    if (_alwaysTrue(null)) break;
  }
  x.expectStaticType<Exactly<Object>>();
  do {
    x.expectStaticType<Exactly<Object>>();
    if (_alwaysTrue(null)) break;
  } while (b2);
  x.expectStaticType<Exactly<Object>>();
  for (x.expectStaticType<Exactly<Object>>();
      b2;
      x.expectStaticType<Exactly<Object>>()) {
    x.expectStaticType<Exactly<Object>>();
    if (_alwaysTrue(null)) break;
  }
}

main() {
  is_('foo');
  is_(0);
  isNot('foo');
  isNot(0);
  not('foo');
  not(0);
  eqNull(null);
  eqNull(0);
  notEqNull(null);
  notEqNull(0);
  nullEq(null);
  nullEq(0);
  nullNotEq(null);
  nullNotEq(0);
  and('foo', 'bar');
  and('foo', 1);
  and(0, 'bar');
  and(0, 1);
  or('foo', 'bar');
  or('foo', 1);
  or(0, 'bar');
  or(0, 1);
  conditional('foo');
  conditional(0);
  assignment('foo');
  assignment(0);
}
