// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "utils.dart";

class A {
  int x = 42;
  String arity1(int val) {
    val += 10;
    return val.toString();
  }
}

String arity1(int val) {
  val += 10;
  return val.toString();
}

dynamic dynamicFunction = arity1;

void main() {
  dynamic instanceOfA = A();
  // Call an instance of a class with no call() method.
  try {
    instanceOfA();
  } on NoSuchMethodError catch (error) {
    var message = error.toString();
    expectStringContains("NoSuchMethodError: 'call'", message);
    expectStringContains("Receiver: Instance of 'A'", message);
  }

  dynamic tearOff = instanceOfA.arity1;
  // Dynamic call of a class method with too many arguments.
  try {
    tearOff(1, 2);
  } on NoSuchMethodError catch (error) {
    var message = error.toString();
    expectStringContains("NoSuchMethodError: 'bound arity1'", message);
    expectStringContains("too many arguments", message);
  }

  // Dynamic call of a class method with too few arguments.
  try {
    tearOff();
  } on NoSuchMethodError catch (error) {
    var message = error.toString();
    expectStringContains("NoSuchMethodError: 'bound arity1'", message);
    expectStringContains("too few arguments", message);
  }

  // Dynamic call of a top level funciton with too many arguments.
  try {
    dynamicFunction(1, 2);
  } on NoSuchMethodError catch (error) {
    var message = error.toString();
    expectStringContains("NoSuchMethodError: 'arity1'", message);
    expectStringContains("too many arguments", message);
  }

  // Dynamic call of a top level funciton with too few arguments.
  try {
    dynamicFunction();
  } on NoSuchMethodError catch (error) {
    var message = error.toString();
    expectStringContains("NoSuchMethodError: 'arity1'", message);
    expectStringContains("too few arguments", message);
  }

  // Function.apply() with too many arguments.
  try {
    Function.apply(dynamicFunction, [1, 2]);
  } on NoSuchMethodError catch (error) {
    var message = error.toString();
    expectStringContains("NoSuchMethodError: 'arity1'", message);
    expectStringContains("too many arguments", message);
  }

  // Function.apply() with too few arguments.
  try {
    Function.apply(dynamicFunction, []);
  } on NoSuchMethodError catch (error) {
    var message = error.toString();
    expectStringContains("NoSuchMethodError: 'arity1'", message);
    expectStringContains("too few arguments", message);
  }
}
