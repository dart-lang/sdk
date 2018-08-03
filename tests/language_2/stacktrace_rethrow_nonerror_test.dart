// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class NotASubclassOfError {}

fail() => throw "Fail";

// == Rethrow, skipping through typed handlers. ==

aa1() {
  try {
    bb1();
    fail();
  } catch (exception, stacktrace) {
    expectTrace(['gg1', 'ff1', 'ee1', 'dd1', 'cc1', 'bb1', 'aa1'], stacktrace);
  }
}

bb1() => cc1();

cc1() {
  try {
    dd1();
  } on String catch (e) {
    fail();
  } on int catch (e) {
    fail();
  }
}

dd1() => ee1();

ee1() {
  try {
    ff1();
  } catch (e) {
    rethrow;
  }
}

ff1() => gg1();

gg1() => throw new NotASubclassOfError();

// == Rethrow, rethrow again in typed handler. ==

aa2() {
  try {
    bb2();
    fail();
  } catch (exception, stacktrace) {
    expectTrace(['gg2', 'ff2', 'ee2', 'dd2', 'cc2', 'bb2', 'aa2'], stacktrace);
  }
}

bb2() => cc2();

cc2() {
  try {
    dd2();
  } on NotASubclassOfError catch (e) {
    rethrow;
  } on int catch (e) {
    fail();
  }
}

dd2() => ee2();

ee2() {
  try {
    ff2();
  } catch (e) {
    rethrow;
  }
}

ff2() => gg2();

gg2() => throw new NotASubclassOfError();

// == Rethrow, with intervening catch without a trace parameter.

aa3() {
  try {
    bb3();
    fail();
  } catch (exception, stacktrace) {
    expectTrace(['cc3', 'bb3', 'aa3'], stacktrace);
  }
}

bb3() => cc3();

cc3() {
  try {
    dd3();
  } catch (e) {
    throw e;
  }
}

dd3() => ee3();

ee3() {
  try {
    ff3();
  } catch (e) {
    rethrow;
  }
}

ff3() => gg3();

gg3() => throw new NotASubclassOfError();

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
