// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Examples where primitive checks should be removed.
//
// In all these examples, the loop bound `a + b + c + d` should be hoisted out
// of the loop.

/*member: test1:function(a, b, c, d) {
  var t1, s, i;
  if (a == null || b == null || c == null || d == null)
    return 0;
  if (typeof a !== "number")
    return a.$add();
  if (typeof b !== "number")
    return A.iae(b);
  if (typeof c !== "number")
    return A.iae(c);
  t1 = a + b + c + d;
  s = 0;
  i = 1;
  for (; i <= t1; ++i)
    s += i;
  return s;
}*/
int test1(int? a, int? b, int? c, int? d) {
  if (a == null || b == null || c == null || d == null) return 0;
  int s = 0;
  for (int i = 1; i <= a + b + c + d; i++) s += i;
  return s;
}

/*member: test2:function(a, b, c, d) {
  var t1, s, i;
  if (!A._isInt(a) || !A._isInt(b) || !A._isInt(c) || !A._isInt(d))
    return 0;
  if (typeof a !== "number")
    return a.$add();
  if (typeof b !== "number")
    return A.iae(b);
  if (typeof c !== "number")
    return A.iae(c);
  t1 = a + b + c + d;
  s = 0;
  i = 1;
  for (; i <= t1; ++i)
    s += i;
  return s;
}*/
int test2(int? a, int? b, int? c, int? d) {
  if (a is! int || b is! int || c is! int || d is! int) return 0;
  int s = 0;
  for (int i = 1; i <= a + b + c + d; i++) s += i;
  return s;
}

/*member: test3:function(a, b, c, d) {
  var t1, i, s = 0;
  if (a != null && b != null && c != null && d != null) {
    if (typeof a !== "number")
      return a.$add();
    if (typeof b !== "number")
      return A.iae(b);
    if (typeof c !== "number")
      return A.iae(c);
    t1 = a + b + c + d;
    i = 1;
    for (; i <= t1; ++i)
      s += i;
  }
  return s;
}*/
int test3(int? a, int? b, int? c, int? d) {
  int s = 0;
  if (a != null && b != null && c != null && d != null) {
    for (int i = 1; i <= a + b + c + d; i++) s += i;
  }
  return s;
}

/*member: test4:function(a, b, c, d) {
  var t1, i, s = 0;
  if (A._isInt(a) && A._isInt(b) && A._isInt(c) && A._isInt(d)) {
    if (typeof a !== "number")
      return a.$add();
    if (typeof b !== "number")
      return A.iae(b);
    if (typeof c !== "number")
      return A.iae(c);
    t1 = a + b + c + d;
    i = 1;
    for (; i <= t1; ++i)
      s += i;
  }
  return s;
}*/
int test4(int? a, int? b, int? c, int? d) {
  int s = 0;
  if (a is int && b is int && c is int && d is int) {
    for (int i = 1; i <= a + b + c + d; i++) s += i;
  }
  return s;
}

/*member: main:ignore*/
main() {
  for (final a in [null, -1, 2]) {
    for (final b in [null, -1, 2]) {
      for (final c in [null, -1, 2]) {
        for (final d in [null, -1, 2]) {
          print(test1(a, b, c, d));
          print(test2(a, b, c, d));
          print(test3(a, b, c, d));
          print(test4(a, b, c, d));
        }
      }
    }
  }
}
