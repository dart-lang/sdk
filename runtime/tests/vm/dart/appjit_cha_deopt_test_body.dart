// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify that app-jit snapshot contains dependencies between classes and CHA
// optimized code.

import "package:expect/expect.dart";

class A {
  String getMyName() => "A";
}

class B extends A {
  String getMyName() => "B";
}

final Function makeA = () => new A();
final Function makeB = () => new B();

@pragma("vm:never-inline")
dependentCode1(bool isTraining) {
  dependentCode2(isTraining);
  A obj = (isTraining ? makeA : makeB)();
  Expect.equals(isTraining ? "A" : "B", obj.getMyName());
}

@pragma("vm:never-inline")
dependentCode2(bool isTraining) {
  dependentCode3(isTraining);
  A obj = (isTraining ? makeA : makeB)();
  Expect.equals(isTraining ? "A" : "B", obj.getMyName());
}

@pragma("vm:never-inline")
dependentCode3(bool isTraining) {
  dependentCode4(isTraining);
  A obj = (isTraining ? makeA : makeB)();
  Expect.equals(isTraining ? "A" : "B", obj.getMyName());
}

@pragma("vm:never-inline")
dependentCode4(bool isTraining) {
  dependentCode5(isTraining);
  A obj = (isTraining ? makeA : makeB)();
  Expect.equals(isTraining ? "A" : "B", obj.getMyName());
}

@pragma("vm:never-inline")
dependentCode5(bool isTraining) {
  dependentCode6(isTraining);
  A obj = (isTraining ? makeA : makeB)();
  Expect.equals(isTraining ? "A" : "B", obj.getMyName());
}

@pragma("vm:never-inline")
dependentCode6(bool isTraining) {
  dependentCode7(isTraining);
  A obj = (isTraining ? makeA : makeB)();
  Expect.equals(isTraining ? "A" : "B", obj.getMyName());
}

@pragma("vm:never-inline")
dependentCode7(bool isTraining) {
  dependentCode8(isTraining);
  A obj = (isTraining ? makeA : makeB)();
  Expect.equals(isTraining ? "A" : "B", obj.getMyName());
}

@pragma("vm:never-inline")
dependentCode8(bool isTraining) {
  A obj = (isTraining ? makeA : makeB)();
  Expect.equals(isTraining ? "A" : "B", obj.getMyName());
}

main(List<String> args) {
  final isTraining = args.contains("--train");
  for (var i = 0; i < 200; i++) {
    dependentCode1(isTraining);
  }
  if (isTraining) {
    print("OK(Trained)");
  } else {
    print("OK(Run)");
  }
}
