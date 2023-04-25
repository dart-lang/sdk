// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: and2v1:function(a, b) {
  return a && b;
}*/
bool and2v1(bool a, bool b) => a && b;

/*member: and2v2:function(a, b) {
  return a && b;
}*/
bool and2v2(bool a, bool b) => a ? b : false;

/*member: and2v3:function(a, b) {
  return a && b;
}*/
bool and2v3(bool a, bool b) => a && b;

/*member: or2v1:function(a, b) {
  return a || b;
}*/
bool or2v1(bool a, bool b) => a || b;

/*member: or2v3:function(a, b) {
  return a || b;
}*/
bool or2v3(bool a, bool b) => !a ? b : true;

/*member: and3:function(a, b, c) {
  return a && b && c;
}*/
bool and3(bool a, bool b, bool c) => a && b && c;

/*member: or3:function(a, b, c) {
  return a || b || c;
}*/
bool or3(bool a, bool b, bool c) => a || b || c;

/*member: range1:function(i) {
  if (0 <= i && i < 10)
    A.print(i);
}*/
void range1(int i) {
  if (0 <= i && i < 10) print(i);
}

// Problem cases.
//
// Move the following cases above this comment when the code quality improves.
//
// TODO(http://dartbug.com/29475): Cases with partially constant-folded
// control-flow would benefit from an ability to delete parts of the CFG.
//
// TODO(http://dartbug.com/17027): `||` causes spurious negations.

// `a || b` would be better.
/*member: or2v2:function(a, b) {
  return a ? true : b;
}*/
bool or2v2(bool a, bool b) => a ? true : b;

// Fix the spurious negations.
/*member: orGvn:function(a, b, c) {
  var t1 = !a;
  if (!t1 || b)
    A.print(1);
  if (!t1 || c)
    A.print(2);
}*/
void orGvn(bool a, bool b, bool c) {
  if (a || b) print(1);
  if (a || c) print(2);
}

// This could be a lot better. codegen does a poor job of generating nested
// control-flow expressions.
/*member: range2:function(i) {
  var t1;
  if (!(64 <= i && i <= 90))
    t1 = 97 <= i && i <= 122;
  else
    t1 = true;
  if (t1)
    A.print("letter");
}*/
void range2(int i) {
  if ((64 <= i && i <= 90) || (97 <= i && i <= 122)) print('letter');
}

// This could be a lot better. codegen does a poor job of generating nested
// control-flow expressions.
/*member: range3:function(i, j) {
  var t1;
  if (i === 1 || i === 11)
    t1 = j === 1 || j === 11;
  else
    t1 = false;
  if (t1)
    A.print("yes");
}*/
void range3(int i, int j) {
  if ((i == 1 || i == 11) && (j == 1 || j == 11)) print('yes');
}

/*member: constantFoldedControlFlow1:function(a, b) {
  var t1;
  if (a)
    t1 = b;
  else
    t1 = false;
  return t1;
}*/
bool constantFoldedControlFlow1(bool a, bool b) {
  return a && 1 == 1 && b;
}

/*member: constantFoldedControlFlow2:function(a, b) {
  return a && b && true;
}*/
bool constantFoldedControlFlow2(bool a, bool b) {
  return 1 == 1 && a && 2 == 2 && b && 3 == 3;
}

/*member: constantFoldedControlFlow3:function(a) {
  var t1;
  if (a)
    t1 = true;
  else
    t1 = false;
  return t1;
}*/
bool constantFoldedControlFlow3(bool a) {
  return a && 1 == 1 && 2 == 2;
}

/*member: constantFoldedControlFlow4:function(a) {
  return a && true;
}*/
bool constantFoldedControlFlow4(bool a) {
  return 1 == 1 && a && 2 == 2;
}

@pragma('dart2js:disable-inlining')
/*member: main:ignore*/
main() {
  for (final v1 in [false, true]) {
    constantFoldedControlFlow3(v1);
    constantFoldedControlFlow4(v1);
    for (final v2 in [false, true]) {
      print(and2v1(v1, v2));
      print(and2v2(v1, v2));
      print(and2v3(v1, v2));
      print(or2v1(v1, v2));
      print(or2v2(v1, v2));
      print(or2v3(v1, v2));

      constantFoldedControlFlow1(v1, v2);
      constantFoldedControlFlow2(v1, v2);

      for (final v3 in [false, true]) {
        print(and3(v1, v2, v3));
        print(or3(v1, v2, v3));
        orGvn(v1, v2, v3);
      }
    }
  }

  for (int i = -100; i < 100; i++) {
    range1(i);
    range2(i);
    range3(i, i);
  }
}
