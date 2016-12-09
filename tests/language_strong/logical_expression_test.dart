// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing if statement.

import "package:expect/expect.dart";

// For logical-or conditions dart2js sometimes inlined expressions, leading to
// completely broken programs.

int globalCounter = 0;

falseWithSideEffect() {
  bool confuse() => new DateTime.now().millisecondsSinceEpoch == 42;

  var result = confuse();

  // Make it harder to inline.
  if (result) {
    try {
      try {
        if (confuse()) falseWithSideEffect();
        if (confuse()) return 499;
      } catch (e) {
        rethrow;
      }
    } catch (e) {
      rethrow;
    }
  }
  globalCounter++;
  return result;
}

falseWithoutSideEffect() {
  bool confuse() => new DateTime.now().millisecondsSinceEpoch == 42;

  var result = confuse();

  // Make it harder to inline.
  if (result) {
    try {
      try {
        if (confuse()) falseWithSideEffect();
        if (confuse()) return 499;
      } catch (e) {
        rethrow;
      }
    } catch (e) {
      rethrow;
    }
  }
  return result;
}

testLogicalOr() {
  globalCounter = 0;
  bool cond1 = falseWithSideEffect();
  if (cond1 || falseWithoutSideEffect()) Expect.fail("must be false");
  if (cond1 || falseWithoutSideEffect()) Expect.fail("must be false");
  if (cond1 || falseWithoutSideEffect()) Expect.fail("must be false");
  Expect.equals(1, globalCounter);

  cond1 = (falseWithSideEffect() == 499);
  if (cond1 || falseWithoutSideEffect()) Expect.fail("must be false");
  if (cond1 || falseWithoutSideEffect()) Expect.fail("must be false");
  if (cond1 || falseWithoutSideEffect()) Expect.fail("must be false");
  Expect.equals(2, globalCounter);
}

List globalList = [];
void testLogicalOr2() {
  globalList.clear();
  testValueOr([]);
  testValueOr(null);
  Expect.listEquals([1, 2, 3], globalList);
}

void testValueOr(List list) {
  if (list == null) globalList.add(1);
  if (list == null || list.contains("2")) globalList.add(2);
  if (list == null || list.contains("3")) globalList.add(3);
}

testLogicalAnd() {
  globalCounter = 0;
  bool cond1 = falseWithSideEffect();
  if (cond1 && falseWithoutSideEffect()) Expect.fail("must be false");
  if (cond1 && falseWithoutSideEffect()) Expect.fail("must be false");
  if (cond1 && falseWithoutSideEffect()) Expect.fail("must be false");
  Expect.equals(1, globalCounter);

  cond1 = (falseWithSideEffect() == 499);
  if (cond1 && falseWithoutSideEffect()) Expect.fail("must be false");
  if (cond1 && falseWithoutSideEffect()) Expect.fail("must be false");
  if (cond1 && falseWithoutSideEffect()) Expect.fail("must be false");
  Expect.equals(2, globalCounter);
}

void testLogicalAnd2() {
  globalList.clear();
  testValueAnd([]);
  testValueAnd(null);
  Expect.listEquals([1, 2, 3], globalList);
}

void testValueAnd(List list) {
  if (list == null) globalList.add(1);
  if (list == null && globalList.contains(1)) globalList.add(2);
  if (list == null && globalList.contains(1)) globalList.add(3);
}

main() {
  testLogicalOr();
  testLogicalOr2();

  testLogicalAnd();
  testLogicalAnd2();
}
