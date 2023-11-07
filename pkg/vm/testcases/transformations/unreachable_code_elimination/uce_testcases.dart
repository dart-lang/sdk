// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const bool constTrue = const bool.fromEnvironment('test.define.isTrue');
const bool constFalse = const bool.fromEnvironment('test.define.isFalse');
const bool constTrue2 = !constFalse;
const bool constFalse2 = const bool.fromEnvironment('test.define.notDefined');

bool? foo() => null;

Never throws() => throw 'oops';

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
  if (constTrue && foo()!) {
    print('1_yes');
  }
  if (constFalse && foo()!) {
    print('2_no');
  }
  if (constTrue && constFalse) {
    print('3_no');
  }
  if (constTrue && constTrue && constFalse) {
    print('4_no');
  }
  if (throws() && constTrue) {
    print('5_calls_throw');
  }
  if (throws() && constFalse) {
    print('6_calls_throw');
  }
}

void testOrConditions() {
  if (constTrue || foo()!) {
    print('1_yes');
  }
  if (constFalse || foo()!) {
    print('2_yes');
  }
  if (constFalse || constFalse2) {
    print('3_no');
  }
  if (constFalse || !constTrue || constTrue2) {
    print('4_yes');
  }
  if (throws() || constTrue) {
    print('5_calls_throw');
  }
  if (throws() || constFalse) {
    print('6_calls_throw');
  }
}

void testNotConditions() {
  if (!constTrue) {
    print('1_no');
  }
  if (!constFalse) {
    print('2_yes');
  }
  if (!(!(!constTrue && foo()!) || foo()!)) {
    print('3_no');
  }
}

testConditionalExpressions() {
  print(!constFalse && constTrue ? '1_yes' : '2_no');
  print(constFalse && foo()! ? '3_no' : '4_yes ${foo()}');
}

void testAsserts() {
  assert(foo()!);
  assert(!foo()!, "oops!");
}

class TestAssertInitializer {
  TestAssertInitializer() : assert(foo()!) {}
}

testRemovalOfStatementBodies() {
  if (foo()!) assert(foo()!);
  while (foo()!) assert(foo()!);
  do assert(foo()!); while (foo()!);
  for (;;) assert(foo()!);
  for (var i in [1, 2]) assert(foo()!);
  try {
    assert(foo()!);
  } finally {
    assert(foo()!);
  }
  try {
    assert(foo()!);
  } catch (e) {
    assert(foo()!);
  }
  try {
    assert(foo()!);
  } catch (e) {
    assert(foo()!);
    rethrow;
  }
  switch (42) {
    case 10:
      assert(foo()!);
  }
  switch (42) {
    default:
      assert(foo()!);
  }
}

enum TestPlatform {
  linux,
  macos,
  windows,
}

const switchTestString = "noMatch";
const switchTestInt = 23;

testConstantSwitches() {
  switch (constTrue) {
    case true:
      print('1_yes');
      break;
    case false:
      print('2_no');
      break;
  }
  switch (constFalse) {
    case true:
      print('3_yes');
      break;
    default:
      print('4_not_yes');
  }
  switch (TestPlatform.windows) {
    case TestPlatform.linux:
      print("5_linux");
      break;
    case TestPlatform.macos:
      print("6_macos");
      break;
    case TestPlatform.windows:
      print("7_windows");
      break;
  }
  switch (TestPlatform.macos) {
    case TestPlatform.linux:
    case TestPlatform.macos:
      print("8_not_windows");
      break;
    case TestPlatform.windows:
      print("9_windows");
      break;
  }
  switch (TestPlatform.linux) {
    case TestPlatform.linux:
      continue L1_macos;
    L1_macos:
    case TestPlatform.macos:
      print("10_not_windows");
      break;
    case TestPlatform.windows:
      print("11_windows");
      break;
  }
  switch (TestPlatform.windows) {
    case TestPlatform.linux:
      print("12_linux");
      break;
    case TestPlatform.macos:
      print("13_macos");
      break;
    default:
      print("14_default");
  }
  switch (TestPlatform.windows) {
    case TestPlatform.linux:
      print("15_linux");
      break;
    case TestPlatform.macos:
      print("16_macos");
      break;
    case TestPlatform.windows:
      continue L2_default;
    L2_default:
    default:
      print("17_default");
  }
  switch (TestPlatform.macos) {
    L3_linux:
    case TestPlatform.linux:
      print("18_notwindows");
      break;
    case TestPlatform.macos:
      continue L3_linux;
    case TestPlatform.windows:
      print("19_windows");
      break;
    default:
      print("20_default");
  }
  switch (TestPlatform.macos) {
    L4_linux:
    case TestPlatform.linux:
      print("21_notwindows");
      break;
    case TestPlatform.macos:
      if (foo()!) {
        continue L4_linux;
      }
      break;
    case TestPlatform.windows:
      print("22_windows");
      break;
    default:
      print("23_default");
  }
  switch (switchTestString) {
    case "isMatch":
      print("24_isMatch");
      break;
    case "isNotMatch":
      print("25_isNotMatch");
      break;
    default:
      print("26_default");
  }
  switch (switchTestString) {
    case "isMatch":
      print("27_isMatch");
      break;
    L5_isNotMatch:
    case "isNotMatch":
      print("28_isNotMatch");
      break;
    default:
      continue L5_isNotMatch;
  }
  switch (switchTestInt) {
    case 0:
      print("29_zero");
      break;
    case 1:
      print("30_one");
      break;
    default:
      print("31_default");
  }
  switch (switchTestInt) {
    case 0:
      print("32_zero");
      break;
    case 23:
      print("33_twentythree");
      break;
    default:
      print("34_default");
  }
  switch (switchTestString) {
    case "foo":
      switch (switchTestInt) {
        case 0:
          print("35_foo_zero");
          break;
        default:
          print("36_foo_nonzero");
      }
      break;
    default:
      switch (switchTestInt) {
        case 1:
          print("37_default_one");
          break;
        default:
          print("38_default_default");
      }
  }
  switch (switchTestString) {
    L6_foo:
    case "foo":
      switch (switchTestInt) {
        case 0:
          print("39_foo_zero");
          break;
        default:
          print("40_foo_nonzero");
      }
      break;
    default:
      switch (switchTestInt) {
        case 1:
          print("41_default_one");
          break;
        default:
          continue L6_foo;
      }
  }
  switch (switchTestString) {
    case "foo":
      switch (switchTestInt) {
        case 0:
          continue L7_default;
        default:
          print("42_foo_nonzero");
      }
      break;
    L7_default:
    default:
      switch (switchTestInt) {
        case 23:
          print("43_default_twentythree");
          break;
        default:
          print("44_default_default");
      }
  }
  switch (switchTestString) {
    L8_foo:
    case "foo":
      switch (switchTestInt) {
        case 23:
          continue L9_default;
        default:
          print("45_foo_nontwentythree");
      }
      break;
    L9_default:
    default:
      switch (switchTestInt) {
        case 23:
          print("46_default_twentythree");
          break;
        default:
          continue L8_foo;
      }
  }
  switch (switchTestString) {
    L10_foo:
    case "foo":
      switch (switchTestInt) {
        case 23:
          continue L11_default;
        default:
          print("47_foo_nontwentythree");
      }
      break;
    L11_default:
    default:
      switch (switchTestInt) {
        case 0:
          print("48_default_zero");
          break;
        default:
          continue L10_foo;
      }
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
