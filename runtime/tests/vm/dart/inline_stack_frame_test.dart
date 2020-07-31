// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--optimization_counter_threshold=10 --no-background-compilation

// This test tries to verify that we produce the correct stack trace when
// throwing exceptions even when functions are inlined.
// The test invokes a bunch of functions and then does a throw. There is a
// catch at the outer function which uses the stack trace produced to return
// a string. The test then verifies that the stack trace contains each
// method in the invocation chain. The test is run during warmup to ensure
// unoptimized code produces the correct result and is then run
// in a loop to ensure optimization kicks in and some inlining is done.
// Note: it appears that functions which have a throw are not inlined (func4)
//       and functions that have try/catch in them are not optimized (func1).
//       func2 is not inlined as func1 has not been optimized.

class Test {
  @pragma("vm:entry-point")
  String func1(var k) {
    try {
      for (var i = 0; i <= 50; i++) {
        func2(i * k);
      }
      return "";
    } catch (e, stacktrace) {
      var result = e.toString() + "\n" + stacktrace.toString();
      return result;
    }
  }

  @pragma("vm:entry-point")
  int func2(var i) {
    var result = 0;
    for (var k = 0; k <= 10; k++) {
      result += func3(i + k);
    }
    return result;
  }

  @pragma("vm:entry-point")
  int func3(var i) {
    var result = 0;
    for (var l = 0; l <= 1; l++) {
      result += func4(i + l);
    }
    return result;
  }

  @pragma("vm:entry-point")
  int func4(var i) {
    var result = 0;
    for (var j = 0; j <= 10; j++) {
      result += func5(i + j);
    }
    return result;
  }

  @pragma("vm:entry-point")
  int func5(var i) {
    if (i >= 520) throw "show me inlined functions";
    return i;
  }
}

expectHasSubstring(String string, String substring) {
  if (!string.contains(substring)) {
    var sb = new StringBuffer();
    sb.writeln("Expect string:");
    sb.writeln(string);
    sb.writeln("To have substring:");
    sb.writeln(substring);
    throw new Exception(sb.toString());
  }
}

main() {
  var x = new Test();
  var result = x.func1(100000);
  expectHasSubstring(result, "show me inlined functions");
  expectHasSubstring(result, "Test.func1");
  expectHasSubstring(result, "Test.func2");
  expectHasSubstring(result, "Test.func3");
  expectHasSubstring(result, "Test.func4");
  expectHasSubstring(result, "Test.func5");
  for (var i = 0; i <= 10; i++) {
    result = x.func1(i);
  }
  expectHasSubstring(result, "show me inlined functions");
  expectHasSubstring(result, "Test.func1");
  expectHasSubstring(result, "Test.func2");
  expectHasSubstring(result, "Test.func3");
  expectHasSubstring(result, "Test.func4");
  expectHasSubstring(result, "Test.func5");
}
