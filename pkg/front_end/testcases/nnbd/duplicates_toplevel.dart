// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.19

int topLevelMethod() => 1;
int topLevelMethod() => 2;

int get topLevelGetter => 1;
int get topLevelGetter => 2;

void set topLevelSetter(value) {}

void set topLevelSetter(value) {}

int topLevelField = 1;
int topLevelField = 2;

int topLevelFieldAndSetter1 = 1;
void set topLevelFieldAndSetter1(int value) {}

void set topLevelFieldAndSetter2(int value) {}

int topLevelFieldAndSetter2 = 1;

late final int topLevelLateFinalFieldAndSetter1;
void set topLevelLateFinalFieldAndSetter1(int value) {}

void set topLevelLateFinalFieldAndSetter2(int value) {}

late final int topLevelLateFinalFieldAndSetter2;

final int topLevelDuplicateFieldAndSetter = 1;
final int topLevelDuplicateFieldAndSetter = 2;
void set topLevelDuplicateFieldAndSetter(int value) {}

final int topLevelFieldAndDuplicateSetter = 1;
void set topLevelFieldAndDuplicateSetter(int value) {}

void set topLevelFieldAndDuplicateSetter(int value) {}

final int topLevelDuplicateFieldAndDuplicateSetter = 1;
final int topLevelDuplicateFieldAndDuplicateSetter = 2;
void set topLevelDuplicateFieldAndDuplicateSetter(int value) {}

void set topLevelDuplicateFieldAndDuplicateSetter(int value) {}

int topLevelMethodAndSetter1() => 1;
void set topLevelMethodAndSetter1(int value) {}

void set topLevelMethodAndSetter2(int value) {}

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
    case topLevelMethod:
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
  topLevelFieldAndSetter1;
  topLevelFieldAndSetter1 = 0;
  topLevelFieldAndSetter2;
  topLevelFieldAndSetter2 = 0;
  topLevelFieldAndDuplicateSetter;
  topLevelFieldAndDuplicateSetter = 0;
  topLevelDuplicateFieldAndDuplicateSetter;
  topLevelDuplicateFieldAndDuplicateSetter = 0;
  topLevelMethodAndSetter1 = 0;
  topLevelMethodAndSetter2 = 0;
  topLevelLateFinalFieldAndSetter1;
  topLevelLateFinalFieldAndSetter1 = 0;
  topLevelLateFinalFieldAndSetter2;
  topLevelLateFinalFieldAndSetter2 = 0;
  topLevelMethodAndSetter1();
  topLevelMethodAndSetter2();
}
