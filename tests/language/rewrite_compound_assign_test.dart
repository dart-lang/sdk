// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

var global = 0;

class Foo {
  var field = 0;
  static var staticField = 0;
}

field_compound1(obj) {
  return obj.field = obj.field + 5;
}

field_compound2(obj) {
  return obj.field = obj.field + 1;
}

field_compound3(obj) {
  return obj.field = obj.field - 1;
}

field_compound4(obj) {
  return obj.field = obj.field * 1;
}

static_compound1() {
  return Foo.staticField = Foo.staticField + 5;
}

static_compound2() {
  return Foo.staticField = Foo.staticField + 1;
}

static_compound3() {
  return Foo.staticField = Foo.staticField - 1;
}

static_compound4() {
  return Foo.staticField = Foo.staticField * 1;
}

global_compound1() {
  return global = global + 5;
}

global_compound2() {
  return global = global + 1;
}

global_compound3() {
  return global = global - 1;
}

global_compound4() {
  return global = global * 1;
}

local_compound1(x) {
  x = x + 5;
  if (x > 0) {
    return x;
  }
  return -x;
}

local_compound2(x) {
  x = x + 1;
  if (x > 0) {
    return x;
  }
  return -x;
}

local_compound3(x) {
  x = x - 1;
  if (x > 0) {
    return x;
  }
  return -x;
}

local_compound4(x) {
  x = x * 1;
  if (x > 0) {
    return x;
  }
  return -x;
}

main() {
  var obj = new Foo();
  Expect.equals(5, field_compound1(obj));
  Expect.equals(5, obj.field);
  Expect.equals(6, field_compound2(obj));
  Expect.equals(6, obj.field);
  Expect.equals(5, field_compound3(obj));
  Expect.equals(5, obj.field);
  Expect.equals(5, field_compound4(obj));
  Expect.equals(5, obj.field);

  Expect.equals(5, static_compound1());
  Expect.equals(5, Foo.staticField);
  Expect.equals(6, static_compound2());
  Expect.equals(6, Foo.staticField);
  Expect.equals(5, static_compound3());
  Expect.equals(5, Foo.staticField);
  Expect.equals(5, static_compound4());
  Expect.equals(5, Foo.staticField);

  Expect.equals(5, global_compound1());
  Expect.equals(5, global);
  Expect.equals(6, global_compound2());
  Expect.equals(6, global);
  Expect.equals(5, global_compound3());
  Expect.equals(5, global);
  Expect.equals(5, global_compound4());
  Expect.equals(5, global);

  Expect.equals(8, local_compound1(3));
  Expect.equals(3, local_compound1(-8));
  Expect.equals(4, local_compound2(3));
  Expect.equals(7, local_compound2(-8));
  Expect.equals(2, local_compound3(3));
  Expect.equals(9, local_compound3(-8));
  Expect.equals(3, local_compound4(3));
  Expect.equals(8, local_compound4(-8));
}
