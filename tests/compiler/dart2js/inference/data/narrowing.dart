// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Regression test for Issue #33761: is-checks and null-checks were assumed to
/// be true even in nested non-condition contexts.

/*element: argIsNonNull1:[null]*/
argIsNonNull1(/*[exact=JSUInt31]*/ x) {
  print('>> is null: ${x == null}');
}

/*element: nonNull1:[null]*/
void nonNull1() {
  var x = 1;
  if (x == null) return;
  argIsNonNull1(x);
}

/*element: argIsNonNull2:[null]*/
argIsNonNull2(/*[exact=JSUInt31]*/ x) {
  print('>> is null: ${x == null}');
}

/*element: nonNull2:[null]*/
void nonNull2() {
  var x = 1;
  if ((x == null) /*invoke: [exact=JSBool]*/ == true) return;
  argIsNonNull2(x);
}

/*element: argIsNonNull3:[null]*/
argIsNonNull3(/*[exact=JSUInt31]*/ x) {
  print('>> is null: ${x == null}');
}

/*element: nonNull3:[null]*/
void nonNull3() {
  var x = 1;
  if ((x == null) /*invoke: [exact=JSBool]*/ != false) return;
  argIsNonNull3(x);
}

/*element: argIsNonNull4:[null]*/
argIsNonNull4(/*[exact=JSUInt31]*/ x) {
  print('>> is null: ${x == null}');
}

/*element: discard:Value([exact=JSBool], value: false)*/
discard(/*[exact=JSBool]*/ x) => false;

/*element: nonNull4:[null]*/
void nonNull4() {
  var x = 1;
  if (discard(x != null)) return;
  argIsNonNull4(x);
}

/*element: argIsNonNull5:[null]*/
argIsNonNull5(/*[null|exact=JSUInt31]*/ x) {
  print('>> is null: ${x == null}');
}

/*element: nonNull5:[null]*/
void nonNull5() {
  var x = 1;
  if (x != null ? false : false) return;
  argIsNonNull5(x);
}

/*element: argIsNonNull6:[null]*/
argIsNonNull6(/*[exact=JSUInt31]*/ x) {
  print('>> is null: ${x == null}');
}

/*element: nonNull6:[null]*/
void nonNull6() {
  var x = 1;
  if ((/*[exact=JSBool]*/ (/*[exact=JSBool]*/ y) => y && false)(x != null))
    return;
  argIsNonNull6(x);
}

/*element: argIsNonNull7:[null]*/
argIsNonNull7(/*[exact=JSUInt31]*/ x) {
  print('>> is null: ${x == null}');
}

/*element: nonNull7:[null]*/
void nonNull7() {
  var f = false;
  var x = 1;
  if (f ? (throw x != null) : false) return;
  argIsNonNull7(x);
}

/*element: argIsNonNull8:[null]*/
argIsNonNull8(/*[exact=JSUInt31]*/ x) {
  print('>> is null: ${x == null}');
}

/*element: nonNull8:[null]*/
void nonNull8() {
  var f = false;
  var x = 1;
  if (f ?? (x != null)) return;
  argIsNonNull8(x);
}

/*element: main:[null]*/
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
