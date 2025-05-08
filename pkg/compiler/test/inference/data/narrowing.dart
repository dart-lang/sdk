// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Regression test for Issue #33761: is-checks and null-checks were assumed to
/// be true even in nested non-condition contexts.

/*member: argIsNonNull1:[null|powerset={null}]*/
argIsNonNull1(/*[exact=JSUInt31|powerset={I}{O}]*/ x) {
  print('>> is null: ${x == null}');
}

/*member: nonNull1:[null|powerset={null}]*/
void nonNull1() {
  var x = 1;
  if (x /*invoke: [subclass=JSInt|powerset={I}{O}]*/ == null) return;
  argIsNonNull1(x);
}

/*member: argIsNonNull2:[null|powerset={null}]*/
argIsNonNull2(/*[exact=JSUInt31|powerset={I}{O}]*/ x) {
  print('>> is null: ${x == null}');
}

/*member: nonNull2:[null|powerset={null}]*/
void nonNull2() {
  var x = 1;
  if ((x /*invoke: [subclass=JSInt|powerset={I}{O}]*/ ==
          null) /*invoke: [exact=JSBool|powerset={I}{O}]*/ ==
      true)
    return;
  argIsNonNull2(x);
}

/*member: argIsNonNull3:[null|powerset={null}]*/
argIsNonNull3(/*[exact=JSUInt31|powerset={I}{O}]*/ x) {
  print('>> is null: ${x == null}');
}

/*member: nonNull3:[null|powerset={null}]*/
void nonNull3() {
  var x = 1;
  if ((x /*invoke: [subclass=JSInt|powerset={I}{O}]*/ ==
          null) /*invoke: [exact=JSBool|powerset={I}{O}]*/ !=
      false)
    return;
  argIsNonNull3(x);
}

/*member: argIsNonNull4:[null|powerset={null}]*/
argIsNonNull4(/*[exact=JSUInt31|powerset={I}{O}]*/ x) {
  print('>> is null: ${x == null}');
}

/*member: discard:Value([exact=JSBool|powerset={I}{O}], value: false, powerset: {I}{O})*/
discard(/*[exact=JSBool|powerset={I}{O}]*/ x) => false;

/*member: nonNull4:[null|powerset={null}]*/
void nonNull4() {
  var x = 1;
  if (discard(x /*invoke: [subclass=JSInt|powerset={I}{O}]*/ != null)) return;
  argIsNonNull4(x);
}

/*member: argIsNonNull5:[null|powerset={null}]*/
argIsNonNull5(/*[exact=JSUInt31|powerset={I}{O}]*/ x) {
  print('>> is null: ${x == null}');
}

/*member: nonNull5:[null|powerset={null}]*/
void nonNull5() {
  var x = 1;
  if (x /*invoke: [subclass=JSInt|powerset={I}{O}]*/ != null ? false : false)
    return;
  argIsNonNull5(x);
}

/*member: argIsNonNull6:[null|powerset={null}]*/
argIsNonNull6(/*[exact=JSUInt31|powerset={I}{O}]*/ x) {
  print('>> is null: ${x == null}');
}

/*member: nonNull6:[null|powerset={null}]*/
void nonNull6() {
  var x = 1;
  if (( /*[exact=JSBool|powerset={I}{O}]*/ (
    /*[exact=JSBool|powerset={I}{O}]*/ y,
  ) => y && false)(x /*invoke: [subclass=JSInt|powerset={I}{O}]*/ != null))
    return;
  argIsNonNull6(x);
}

/*member: argIsNonNull7:[null|powerset={null}]*/
argIsNonNull7(/*[exact=JSUInt31|powerset={I}{O}]*/ x) {
  print('>> is null: ${x == null}');
}

/*member: nonNull7:[null|powerset={null}]*/
void nonNull7() {
  var f = false;
  var x = 1;
  if (f
      ? (throw x /*invoke: [subclass=JSInt|powerset={I}{O}]*/ != null)
      : false)
    return;
  argIsNonNull7(x);
}

/*member: argIsNonNull8:[null|powerset={null}]*/
argIsNonNull8(/*[exact=JSUInt31|powerset={I}{O}]*/ x) {
  print('>> is null: ${x == null}');
}

/*member: nonNull8:[null|powerset={null}]*/
void nonNull8() {
  var f = false;
  var x = 1;
  if (f ?? (x /*invoke: [subclass=JSInt|powerset={I}{O}]*/ != null)) return;
  argIsNonNull8(x);
}

/*member: main:[null|powerset={null}]*/
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
