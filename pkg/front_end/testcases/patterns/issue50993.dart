// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

String test1(int value) {
  switch (value) {
    case <2:
      return "case <2";
    case 2:
      return "case 2";
  }
  return "not matched";
}

String test2(int value) {
  switch (value) {
    case <2:
      return "case <2";
    case 2:
    default:
      return "case 2";
  }
  return "not matched";
}

String test3(int value) {
  switch (value) {
    case 2:
      return "case 2";
    case <2:
    default:
      return "case <2";
  }
  return "not matched";
}

String test4(int value) {
  switch (value) {
    case 2:
      return "case 2";
    case <2:
      return "case <2";
    default:
      return "default";
  }
}

String test5(int value) {
  switch (value) {
    case 2:
      return "case 2";
    case <2:
    case >3:
      return "case <2 >3";
    default:
      return "default";
  }
}

String test6(int value) {
  switch (value) {
    case 2:
      return "case 2";
    case 1:
    case 4:
      return "case 1/4";
    default:
      return "default";
  }
}

main() {
  expect("case <2", test1(1));
  expect("case 2", test1(2));
  expect("not matched", test1(3));

  expect("case <2", test2(1));
  expect("case 2", test2(2));
  expect("case 2", test2(3));

  expect("case <2", test3(1));
  expect("case 2", test3(2));
  expect("case <2", test3(3));

  expect("case <2", test4(1));
  expect("case 2", test4(2));
  expect("default", test4(3));

  expect("case <2", test4(1));
  expect("case 2", test4(2));
  expect("default", test4(3));

  expect("case <2 >3", test5(1));
  expect("case 2", test5(2));
  expect("default", test5(3));
  expect("case <2 >3", test5(4));

  expect("case 1/4", test6(1));
  expect("case 2", test6(2));
  expect("default", test6(3));
  expect("case 1/4", test6(4));
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}