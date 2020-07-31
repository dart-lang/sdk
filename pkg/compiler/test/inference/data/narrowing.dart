// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/// Regression test for Issue #33761: is-checks and null-checks were assumed to
/// be true even in nested non-condition contexts.

/*member: argIsNonNull1:[null]*/
argIsNonNull1(/*[exact=JSUInt31]*/ x) {
  print('>> is null: ${x == null}');
}

/*member: nonNull1:[null]*/
void nonNull1() {
  var x = 1;
  if (x /*invoke: [null|subclass=JSInt]*/ == null) return;
  argIsNonNull1(x);
}

/*member: argIsNonNull2:[null]*/
argIsNonNull2(/*[exact=JSUInt31]*/ x) {
  print('>> is null: ${x == null}');
}

/*member: nonNull2:[null]*/
void nonNull2() {
  var x = 1;
  if ((x /*invoke: [null|subclass=JSInt]*/ ==
          null) /*invoke: [exact=JSBool]*/ ==
      true) return;
  argIsNonNull2(x);
}

/*member: argIsNonNull3:[null]*/
argIsNonNull3(/*[exact=JSUInt31]*/ x) {
  print('>> is null: ${x == null}');
}

/*member: nonNull3:[null]*/
void nonNull3() {
  var x = 1;
  if ((x /*invoke: [null|subclass=JSInt]*/ ==
          null) /*invoke: [exact=JSBool]*/ !=
      false) return;
  argIsNonNull3(x);
}

/*member: argIsNonNull4:[null]*/
argIsNonNull4(/*[exact=JSUInt31]*/ x) {
  print('>> is null: ${x == null}');
}

/*member: discard:Value([exact=JSBool], value: false)*/
discard(/*[exact=JSBool]*/ x) => false;

/*member: nonNull4:[null]*/
void nonNull4() {
  var x = 1;
  if (discard(x /*invoke: [null|subclass=JSInt]*/ != null)) return;
  argIsNonNull4(x);
}

/*member: argIsNonNull5:[null]*/
argIsNonNull5(/*[null|exact=JSUInt31]*/ x) {
  print('>> is null: ${x == null}');
}

/*member: nonNull5:[null]*/
void nonNull5() {
  var x = 1;
  if (x /*invoke: [null|subclass=JSInt]*/ != null ? false : false) return;
  argIsNonNull5(x);
}

/*member: argIsNonNull6:[null]*/
argIsNonNull6(/*[exact=JSUInt31]*/ x) {
  print('>> is null: ${x == null}');
}

/*member: nonNull6:[null]*/
void nonNull6() {
  var x = 1;
  if ((/*[exact=JSBool]*/ (/*[exact=JSBool]*/ y) =>
      y && false)(x /*invoke: [null|subclass=JSInt]*/ != null)) return;
  argIsNonNull6(x);
}

/*member: argIsNonNull7:[null]*/
argIsNonNull7(/*[exact=JSUInt31]*/ x) {
  print('>> is null: ${x == null}');
}

/*member: nonNull7:[null]*/
void nonNull7() {
  var f = false;
  var x = 1;
  if (f ? (throw x /*invoke: [null|subclass=JSInt]*/ != null) : false) return;
  argIsNonNull7(x);
}

/*member: argIsNonNull8:[null]*/
argIsNonNull8(/*[exact=JSUInt31]*/ x) {
  print('>> is null: ${x == null}');
}

/*member: nonNull8:[null]*/
void nonNull8() {
  var f = false;
  var x = 1;
  if (f ?? (x /*invoke: [null|subclass=JSInt]*/ != null)) return;
  argIsNonNull8(x);
}

/*member: main:[null]*/
void main() {
  nonNull1();
  nonNull2();
  nonNull3();
  nonNull4();
  nonNull5();
  nonNull6();
  nonNull7();
  nonNull8();
}
