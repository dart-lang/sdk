// (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

@pragma("vm:entry-point") // Prevent obfuscation.
void func1() {
  throw new Exception("Test full stacktrace");
}

@pragma("vm:entry-point") // Prevent obfuscation.
void func2() {
  func1();
}

@pragma("vm:entry-point") // Prevent obfuscation.
void func3() {
  try {
    func2();
  } on Object catch (e, s) {
    var fullTrace = s.toString();
    Expect.isTrue(fullTrace.contains("func1"));
    Expect.isTrue(fullTrace.contains("func2"));
    Expect.isTrue(fullTrace.contains("func3"));
    Expect.isTrue(fullTrace.contains("func4"));
    Expect.isTrue(fullTrace.contains("func5"));
    Expect.isTrue(fullTrace.contains("func6"));
    Expect.isTrue(fullTrace.contains("func7"));
    Expect.isTrue(fullTrace.contains("main"));

    rethrow; // This is a rethrow.
  }
}

@pragma("vm:entry-point") // Prevent obfuscation.
int func4() {
  func3();
  return 1;
}

@pragma("vm:entry-point") // Prevent obfuscation.
int func5() {
  try {
    func4();
  } on Object catch (e, s) {
    var fullTrace = s.toString();
    Expect.isTrue(fullTrace.contains("func1"));
    Expect.isTrue(fullTrace.contains("func2"));
    Expect.isTrue(fullTrace.contains("func3"));
    Expect.isTrue(fullTrace.contains("func4"));
    Expect.isTrue(fullTrace.contains("func5"));
    Expect.isTrue(fullTrace.contains("func6"));
    Expect.isTrue(fullTrace.contains("func7"));
    Expect.isTrue(fullTrace.contains("main"));
  }
  return 1;
}

@pragma("vm:entry-point") // Prevent obfuscation.
int func6() {
  func5();
  return 1;
}

@pragma("vm:entry-point") // Prevent obfuscation.
int func7() {
  func6();
  return 1;
}

main() {
  var i = func7();
  Expect.equals(1, i);
}
