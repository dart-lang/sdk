// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {}

class B extends A {}

class C extends B {}

combine_empty(bool b, Object v) {
  if (b) {
    v is int || (throw 1);
  } else {
    v is String || (throw 2);
  }
  v;
}

conditional_isNotType(bool b, Object v) {
  if (b ? (v is! int) : (v is! num)) {
    v;
  } else {
    v;
  }
  v;
}

conditional_isType(bool b, Object v) {
  if (b ? (v is int) : (v is num)) {
    v;
  } else {
    v;
  }
  v;
}

isNotType(v) {
  if (v is! String) {
    v;
  } else {
    /*String*/ v;
  }
  v;
}

isNotType_return(v) {
  if (v is! String) return;
  /*String*/ v;
}

isNotType_throw(v) {
  if (v is! String) throw 42;
  /*String*/ v;
}

isType(v) {
  if (v is String) {
    /*String*/ v;
  } else {
    v;
  }
  v;
}

isType_thenNonBoolean(Object x) {
  if ((x is String) != 3) {
    x;
  }
}

joinIntersectsPromotedTypes(Object a, bool b) {
  if (b) {
    a as A;
    /*A*/ a as C;
  } else {
    a as B;
    /*B*/ a as C;
  }
  /*C*/ a;
}

logicalNot_isType(v) {
  if (!(v is String)) {
    v;
  } else {
    /*String*/ v;
  }
  v;
}

void isNotType_return2(bool b, Object x) {
  if (b) {
    if (x is! String) return;
  }
  x;
}
