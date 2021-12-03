// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

var result;

int topLevelMethod() => 1;
int topLevelMethod() => 2;

int get topLevelGetter => 1;
int get topLevelGetter => 2;

void set topLevelSetter(value) {
  result = 1;
}

void set topLevelSetter(value) {
  result = 2;
}

int topLevelField = 1;
int topLevelField = 2;

int topLevelFieldAndSetter1 = 1;
void set topLevelFieldAndSetter1(int value) {
  result = 2;
}

void set topLevelFieldAndSetter2(int value) {
  result = 2;
}

int topLevelFieldAndSetter2 = 1;

late final int topLevelLateFinalFieldAndSetter1;
void set topLevelLateFinalFieldAndSetter1(int value) {
  result = 2;
}

void set topLevelLateFinalFieldAndSetter2(int value) {
  result = 2;
}

late final int topLevelLateFinalFieldAndSetter2;

final int topLevelDuplicateFieldAndSetter = 1;
final int topLevelDuplicateFieldAndSetter = 2;
void set topLevelDuplicateFieldAndSetter(int value) {
  result = 3;
}

final int topLevelFieldAndDuplicateSetter = 1;
void set topLevelFieldAndDuplicateSetter(int value) {
  result = 2;
}

void set topLevelFieldAndDuplicateSetter(int value) {
  result = 3;
}

final int topLevelDuplicateFieldAndDuplicateSetter = 1;
final int topLevelDuplicateFieldAndDuplicateSetter = 2;
void set topLevelDuplicateFieldAndDuplicateSetter(int value) {
  result = 3;
}

void set topLevelDuplicateFieldAndDuplicateSetter(int value) {
  result = 4;
}

int topLevelMethodAndSetter1() => 1;
void set topLevelMethodAndSetter1(int value) {
  result = 2;
}

void set topLevelMethodAndSetter2(int value) {
  result = 2;
}

int topLevelMethodAndSetter2() => 1;

var field = topLevelMethod;

@topLevelMethod
test() {
  topLevelMethod();
  (topLevelMethod)();
  if (topLevelMethod) {}
  topLevelMethod;
  @topLevelMethod
  var foo;
  switch (null) {
    case topLevelMethod;
  }
  topLevelMethod || topLevelMethod;
  topLevelMethod + 0;
  topLevelMethod ~ 0;
  topLevelMethod ?? topLevelMethod;
  topLevelMethod?.foo;
  topLevelMethod?.foo();
  topLevelGetter;
  topLevelSetter = 0;
  topLevelField;
  topLevelField = 0;
  topLevelDuplicateFieldAndSetter;
  topLevelDuplicateFieldAndSetter = 0;
  topLevelFieldAndDuplicateSetter;
  topLevelFieldAndDuplicateSetter = 0;
  topLevelDuplicateFieldAndDuplicateSetter;
  topLevelDuplicateFieldAndDuplicateSetter = 0;
  topLevelMethodAndSetter1 = 0;
  topLevelMethodAndSetter2 = 0;
}

main() {
  result = null;
  topLevelFieldAndSetter1 = 0;
  expect(null, result);
  expect(0, topLevelFieldAndSetter1);

  result = null;
  topLevelFieldAndSetter2 = 0;
  expect(null, result);
  expect(0, topLevelFieldAndSetter2);

  result = null;
  topLevelLateFinalFieldAndSetter1 = 0;
  expect(null, result);
  expect(0, topLevelLateFinalFieldAndSetter1);

  result = null;
  topLevelLateFinalFieldAndSetter2 = 0;
  expect(null, result);
  expect(0, topLevelLateFinalFieldAndSetter2);

  expect(1, topLevelMethodAndSetter1());

  expect(1, topLevelMethodAndSetter2());
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}

throws(dynamic Function() f) {
  try {
    f();
  } catch (e) {
    print(e);
    return;
  }
  throw 'Expected exception.';
}
