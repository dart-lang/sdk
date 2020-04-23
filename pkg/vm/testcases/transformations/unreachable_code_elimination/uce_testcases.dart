// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const bool constTrue = const bool.fromEnvironment('test.define.isTrue');
const bool constFalse = const bool.fromEnvironment('test.define.isFalse');
const bool constTrue2 = !constFalse;
const bool constFalse2 = const bool.fromEnvironment('test.define.notDefined');

bool foo() => null;

void testSimpleConditions() {
  if (constTrue) {
    print('1_yes');
  }
  if (constFalse) {
    print('2_no');
  }
  if (constTrue2) {
    print('3_yes');
    if (constFalse2) {
      print('4_no');
    }
  }
}

void testAndConditions() {
  if (constTrue && foo()) {
    print('1_yes');
  }
  if (constFalse && foo()) {
    print('2_no');
  }
  if (constTrue && constFalse) {
    print('3_no');
  }
  if (constTrue && constTrue && constFalse) {
    print('4_no');
  }
}

void testOrConditions() {
  if (constTrue || foo()) {
    print('1_yes');
  }
  if (constFalse || foo()) {
    print('2_yes');
  }
  if (constFalse || constFalse2) {
    print('3_no');
  }
  if (constFalse || !constTrue || constTrue2) {
    print('4_yes');
  }
}

void testNotConditions() {
  if (!constTrue) {
    print('1_no');
  }
  if (!constFalse) {
    print('2_yes');
  }
  if (!(!(!constTrue && foo()) || foo())) {
    print('3_no');
  }
}

testConditionalExpressions() {
  print(!constFalse && constTrue ? '1_yes' : '2_no');
  print(constFalse && foo() ? '3_no' : '4_yes ${foo()}');
}

void testAsserts() {
  assert(foo());
  assert(!foo(), "oops!");
}

class TestAssertInitializer {
  TestAssertInitializer() : assert(foo()) {}
}

testRemovalOfStatementBodies() {
  if (foo()) assert(foo());
  while (foo()) assert(foo());
  do assert(foo()); while (foo());
  for (;;) assert(foo());
  for (var i in [1, 2]) assert(foo());
  try {
    assert(foo());
  } finally {
    assert(foo());
  }
  try {
    assert(foo());
  } catch (e) {
    assert(foo());
  }
  try {
    assert(foo());
  } catch (e) {
    assert(foo());
    rethrow;
  }
  switch (42) {
    case 10:
      assert(foo());
  }
  switch (42) {
    default:
      assert(foo());
  }
}

main(List<String> args) {
  testSimpleConditions();
  testAndConditions();
  testOrConditions();
  testNotConditions();
  testConditionalExpressions();
  testAsserts();
  new TestAssertInitializer();
  testRemovalOfStatementBodies();
}
