// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify that app-jit snapshot contains dependencies between classes and CHA
// optimized code.

import 'package:expect/expect.dart';

class A {
  void getMyName() => getMyNameImpl();

  void getMyNameImpl() => "A";
}

class B extends A {
  void getMyNameImpl() => "B";
}

final Function makeA = () => new A();
final Function makeB = () => new B();

void optimizeGetMyName(dynamic obj) {
  for (var i = 0; i < 100; i++) {
    obj.getMyName();
  }
  Expect.equals("A", obj.getMyName());
}

void main(List<String> args) {
  final isTraining = args.contains("--train");
  final dynamic obj = (isTraining ? makeA : makeB)();
  if (isTraining) {
    for (var i = 0; i < 10; i++) {
      optimizeGetMyName(obj);
    }
    Expect.equals('A', obj.getMyName());
    print('OK(Trained)');
  } else {
    Expect.equals('B', obj.getMyName());
    print('OK(Run)');
  }
}
