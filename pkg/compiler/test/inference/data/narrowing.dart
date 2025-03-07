// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Regression test for Issue #33761: is-checks and null-checks were assumed to
/// be true even in nested non-condition contexts.

/*member: argIsNonNull1:[null|powerset=1]*/
argIsNonNull1(/*[exact=JSUInt31|powerset=0]*/ x) {
  print('>> is null: ${x == null}');
}

/*member: nonNull1:[null|powerset=1]*/
void nonNull1() {
  var x = 1;
  if (x /*invoke: [subclass=JSInt|powerset=0]*/ == null) return;
  argIsNonNull1(x);
}

/*member: argIsNonNull2:[null|powerset=1]*/
argIsNonNull2(/*[exact=JSUInt31|powerset=0]*/ x) {
  print('>> is null: ${x == null}');
}

/*member: nonNull2:[null|powerset=1]*/
void nonNull2() {
  var x = 1;
  if ((x /*invoke: [subclass=JSInt|powerset=0]*/ ==
          null) /*invoke: [exact=JSBool|powerset=0]*/ ==
      true)
    return;
  argIsNonNull2(x);
}

/*member: argIsNonNull3:[null|powerset=1]*/
argIsNonNull3(/*[exact=JSUInt31|powerset=0]*/ x) {
  print('>> is null: ${x == null}');
}

/*member: nonNull3:[null|powerset=1]*/
void nonNull3() {
  var x = 1;
  if ((x /*invoke: [subclass=JSInt|powerset=0]*/ ==
          null) /*invoke: [exact=JSBool|powerset=0]*/ !=
      false)
    return;
  argIsNonNull3(x);
}

/*member: argIsNonNull4:[null|powerset=1]*/
argIsNonNull4(/*[exact=JSUInt31|powerset=0]*/ x) {
  print('>> is null: ${x == null}');
}

/*member: discard:Value([exact=JSBool|powerset=0], value: false, powerset: 0)*/
discard(/*[exact=JSBool|powerset=0]*/ x) => false;

/*member: nonNull4:[null|powerset=1]*/
void nonNull4() {
  var x = 1;
  if (discard(x /*invoke: [subclass=JSInt|powerset=0]*/ != null)) return;
  argIsNonNull4(x);
}

/*member: argIsNonNull5:[null|powerset=1]*/
argIsNonNull5(/*[exact=JSUInt31|powerset=0]*/ x) {
  print('>> is null: ${x == null}');
}

/*member: nonNull5:[null|powerset=1]*/
void nonNull5() {
  var x = 1;
  if (x /*invoke: [subclass=JSInt|powerset=0]*/ != null ? false : false) return;
  argIsNonNull5(x);
}

/*member: argIsNonNull6:[null|powerset=1]*/
argIsNonNull6(/*[exact=JSUInt31|powerset=0]*/ x) {
  print('>> is null: ${x == null}');
}

/*member: nonNull6:[null|powerset=1]*/
void nonNull6() {
  var x = 1;
  if (( /*[exact=JSBool|powerset=0]*/ (/*[exact=JSBool|powerset=0]*/ y) =>
      y && false)(x /*invoke: [subclass=JSInt|powerset=0]*/ != null))
    return;
  argIsNonNull6(x);
}

/*member: argIsNonNull7:[null|powerset=1]*/
argIsNonNull7(/*[exact=JSUInt31|powerset=0]*/ x) {
  print('>> is null: ${x == null}');
}

/*member: nonNull7:[null|powerset=1]*/
void nonNull7() {
  var f = false;
  var x = 1;
  if (f ? (throw x /*invoke: [subclass=JSInt|powerset=0]*/ != null) : false)
    return;
  argIsNonNull7(x);
}

/*member: argIsNonNull8:[null|powerset=1]*/
argIsNonNull8(/*[exact=JSUInt31|powerset=0]*/ x) {
  print('>> is null: ${x == null}');
}

/*member: nonNull8:[null|powerset=1]*/
void nonNull8() {
  var f = false;
  var x = 1;
  if (f ?? (x /*invoke: [subclass=JSInt|powerset=0]*/ != null)) return;
  argIsNonNull8(x);
}

/*member: main:[null|powerset=1]*/
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
