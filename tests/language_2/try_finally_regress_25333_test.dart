// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test correct handling of try-catch inside try-finally.

import "package:expect/expect.dart";

void main() {
  print("== test1 ==");
  bool caught = false;
  try {
    test1();
    print("Unexpected 1"); // should never go here
    Expect.isTrue(false);
  } catch (e) {
    caught = true;
    print("main catch 1: $e");
    Expect.equals(e, "Ball");
  }
  Expect.isTrue(caught);
  print("== test2 ==");
  caught = false;
  try {
    test2();
    print("Unexpected 2"); // should never go here
    Expect.isTrue(false);
  } catch (e) {
    caught = true;
    print("main catch 2: $e");
    Expect.equals(e, "Ball");
  }
  Expect.isTrue(caught);
}

void test1() {
  try {
    throw "Ball";
  } finally {
    try {
      throw "Frisbee";
    } catch (e) {
      print("test 1 catch: $e");
      Expect.equals(e, "Frisbee");
    }
  }
}

void test2() {
  try {
    throwError(); // call a method that throws an error
  } finally {
    try {
      throw "Frisbee";
    } catch (e) {
      print("test 2 catch: $e");
      Expect.equals(e, "Frisbee");
    }
  }
}

void throwError() {
  throw "Ball";
}
