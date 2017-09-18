// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

const excludedAlways = const Object();
const excludedOutline = const Object();

const forClassField = const Object();
const forFormalParameter = const Object();
const forMethod1 = const Object();
const forMethod2 = const Object();
const forSubexpression1 = const Object();
const forSubexpression2 = const Object();
const forTopLevelFunction = const Object();
const forTypedef = const Object();
const forTypeParameter = const Object();

@forTopLevelFunction
int publicFunction1(@forFormalParameter int p) => 0;

@excludedAlways
int publicFunction2(@excludedAlways int p) => 0;

@excludedAlways
int _privateFunction(@excludedAlways int p) => 0;

@forTypedef
typedef void F1();

@excludedAlways
typedef void F2();

class B1 {
  const B1(_);
}

class B2 {
  const B2(_);
}

class B3 {
  const B3(_);
}

class C1 {
  @forClassField
  int publicField;

  @excludedAlways
  int _privateField;

  @forMethod1
  void publicMethod1() {}

  @B1(forSubexpression1)
  void publicMethod2() {}

  @excludedAlways
  void _privateMethod() {}
}

class C2<@forTypeParameter T> {
  T field;
}
