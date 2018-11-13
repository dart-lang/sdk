// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class SubclassOfError extends Error {}

fail() => throw "Fail";

// == Rethrow, skipping through typed handlers. ==

@pragma("vm:entry-point") // Prevent obfuscation
aa1() {
  try {
    bb1();
    fail();
  } catch (error
          , stacktrace // //# withtraceparameter: ok
  ) {
    expectTrace(
        ['gg1', 'ff1', 'ee1', 'dd1', 'cc1', 'bb1', 'aa1'], error.stackTrace);
    expectTrace(['gg1', 'ff1', 'ee1', 'dd1', 'cc1', 'bb1', 'aa1'], stacktrace); // //# withtraceparameter: continued
  }
}

@pragma("vm:entry-point") // Prevent obfuscation
bb1() => cc1();

@pragma("vm:entry-point") // Prevent obfuscation
cc1() {
  try {
    dd1();
  } on String catch (e) {
    fail();
  } on int catch (e) {
    fail();
  }
}

@pragma("vm:entry-point") // Prevent obfuscation
dd1() => ee1();

@pragma("vm:entry-point") // Prevent obfuscation
ee1() {
  try {
    ff1();
  } catch (e) {
    rethrow;
  }
}

@pragma("vm:entry-point") // Prevent obfuscation
ff1() => gg1();

@pragma("vm:entry-point") // Prevent obfuscation
gg1() => throw new SubclassOfError();

// == Rethrow, rethrow again in typed handler. ==

@pragma("vm:entry-point") // Prevent obfuscation
aa2() {
  try {
    bb2();
    fail();
  } catch (error
          , stacktrace // //# withtraceparameter: continued
  ) {
    expectTrace(
        ['gg2', 'ff2', 'ee2', 'dd2', 'cc2', 'bb2', 'aa2'], error.stackTrace);
    expectTrace(['gg2', 'ff2', 'ee2', 'dd2', 'cc2', 'bb2', 'aa2'], stacktrace); // //# withtraceparameter: continued
  }
}

@pragma("vm:entry-point") // Prevent obfuscation
bb2() => cc2();

@pragma("vm:entry-point") // Prevent obfuscation
cc2() {
  try {
    dd2();
  } on SubclassOfError catch (e) {
    rethrow;
  } on int catch (e) {
    fail();
  }
}

@pragma("vm:entry-point") // Prevent obfuscation
dd2() => ee2();

@pragma("vm:entry-point") // Prevent obfuscation
ee2() {
  try {
    ff2();
  } catch (e) {
    rethrow;
  }
}

@pragma("vm:entry-point") // Prevent obfuscation
ff2() => gg2();

@pragma("vm:entry-point") // Prevent obfuscation
gg2() => throw new SubclassOfError();

// == Rethrow, with intervening catch without a trace parameter.

@pragma("vm:entry-point") // Prevent obfuscation
aa3() {
  try {
    bb3();
    fail();
  } catch (error
          , stacktrace // //# withtraceparameter: continued
  ) {
    expectTrace(
        ['gg3', 'ff3', 'ee3', 'dd3', 'cc3', 'bb3', 'aa3'], error.stackTrace);
    expectTrace(['cc3', 'bb3', 'aa3'], stacktrace); // //# withtraceparameter: continued
  }
}

@pragma("vm:entry-point") // Prevent obfuscation
bb3() => cc3();

@pragma("vm:entry-point") // Prevent obfuscation
cc3() {
  try {
    dd3();
  } catch (e) {
    throw e;
  }
}

@pragma("vm:entry-point") // Prevent obfuscation
dd3() => ee3();

@pragma("vm:entry-point") // Prevent obfuscation
ee3() {
  try {
    ff3();
  } catch (e) {
    rethrow;
  }
}

@pragma("vm:entry-point") // Prevent obfuscation
ff3() => gg3();

@pragma("vm:entry-point") // Prevent obfuscation
gg3() => throw new SubclassOfError();

expectTrace(functionNames, stacktrace) {
  // Note we don't expect functionNames to cover the whole trace, only the
  // top portion, because the frames below main are an implementation detail.
  var traceLines = stacktrace.toString().split('\n');
  var expectedIndex = 0;
  var actualIndex = 0;
  print(stacktrace);
  print(functionNames);
  while (expectedIndex < functionNames.length) {
    var expected = functionNames[expectedIndex];
    var actual = traceLines[actualIndex];
    if (actual.indexOf(expected) == -1) {
      if (expectedIndex == 0) {
        actualIndex++; // Skip over some helper frames at the top
      } else {
        throw "Expected: $expected actual: $actual";
      }
    } else {
      actualIndex++;
      expectedIndex++;
    }
  }
}

main() {
  aa1();
  aa2();
  aa3();
}
