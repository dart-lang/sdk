// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify that app-jit snapshot contains dependencies between fields and
// field-guard optimized code.

import "package:expect/expect.dart";

class _A {
  dynamic field;
  _A(this.field);
}

@pragma("vm:never-inline")
dependentCode1(_A a, bool isInt, tail) {
  dependentCode2(a, isInt, tail);
  a.field++;
  if (isInt) {
    Expect.type<int>(a.field);
  } else {
    Expect.type<double>(a.field);
  }
}

@pragma("vm:never-inline")
dependentCode2(_A a, bool isInt, tail) {
  dependentCode3(a, isInt, tail);
  a.field++;
  if (isInt) {
    Expect.type<int>(a.field);
  } else {
    Expect.type<double>(a.field);
  }
}

@pragma("vm:never-inline")
dependentCode3(_A a, bool isInt, tail) {
  dependentCode4(a, isInt, tail);
  a.field++;
  if (isInt) {
    Expect.type<int>(a.field);
  } else {
    Expect.type<double>(a.field);
  }
}

@pragma("vm:never-inline")
dependentCode4(_A a, bool isInt, tail) {
  dependentCode5(a, isInt, tail);
  a.field++;
  if (isInt) {
    Expect.type<int>(a.field);
  } else {
    Expect.type<double>(a.field);
  }
}

@pragma("vm:never-inline")
dependentCode5(_A a, bool isInt, tail) {
  dependentCode6(a, isInt, tail);
  a.field++;
  if (isInt) {
    Expect.type<int>(a.field);
  } else {
    Expect.type<double>(a.field);
  }
}

@pragma("vm:never-inline")
dependentCode6(_A a, bool isInt, tail) {
  dependentCode7(a, isInt, tail);
  a.field++;
  if (isInt) {
    Expect.type<int>(a.field);
  } else {
    Expect.type<double>(a.field);
  }
}

@pragma("vm:never-inline")
dependentCode7(_A a, bool isInt, tail) {
  dependentCode8(a, isInt, tail);
  a.field++;
  if (isInt) {
    Expect.type<int>(a.field);
  } else {
    Expect.type<double>(a.field);
  }
}

@pragma("vm:never-inline")
dependentCode8(_A a, bool isInt, tail) {
  tail();
  a.field++;
  if (isInt) {
    Expect.type<int>(a.field);
  } else {
    Expect.type<double>(a.field);
  }
}

main(List<String> args) {
  final isTraining = args.contains("--train");
  if (isTraining) {
    var a = new _A(0);
    for (var i = 0; i < 200; i++) {
      dependentCode1(a, true, () {});
    }
    Expect.equals(a.field, 200 * 8);
    print("OK(Trained)");
  } else {
    var a = new _A(0);
    var b;
    dependentCode1(a, true, () {
      b = new _A(0.0);
    });
    Expect.equals(a.field, 8);
    for (var i = 0; i < 200; i++) {
      dependentCode1(b, false, () {});
    }
    Expect.equals(b.field, 200 * 8);
    print("OK(Run)");
  }
}
