// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class NotASubclassOfError {}

fail() => throw "Fail";

// == Rethrow, skipping through typed handlers. ==

@pragma("vm:entry-point")
aa1() {
  try {
    bb1();
    fail();
  } catch (exception, stacktrace) {
    expectTrace(['gg1', 'ff1', 'ee1', 'dd1', 'cc1', 'bb1', 'aa1'], stacktrace);
  }
}

@pragma("vm:entry-point")
bb1() => cc1();

@pragma("vm:entry-point")
cc1() {
  try {
    dd1();
  } on String catch (_) {
    fail();
  } on int catch (_) {
    fail();
  }
}

@pragma("vm:entry-point")
dd1() => ee1();

@pragma("vm:entry-point")
ee1() {
  try {
    ff1();
  } catch (_) {
    rethrow;
  }
}

@pragma("vm:entry-point")
ff1() => gg1();

@pragma("vm:entry-point")
gg1() => throw new NotASubclassOfError();

// == Rethrow, rethrow again in typed handler. ==

@pragma("vm:entry-point")
aa2() {
  try {
    bb2();
    fail();
  } catch (exception, stacktrace) {
    expectTrace(['gg2', 'ff2', 'ee2', 'dd2', 'cc2', 'bb2', 'aa2'], stacktrace);
  }
}

@pragma("vm:entry-point")
bb2() => cc2();

@pragma("vm:entry-point")
cc2() {
  try {
    dd2();
  } on NotASubclassOfError catch (_) {
    rethrow;
  } on int catch (_) {
    fail();
  }
}

@pragma("vm:entry-point")
dd2() => ee2();

@pragma("vm:entry-point")
ee2() {
  try {
    ff2();
  } catch (e) {
    rethrow;
  }
}

@pragma("vm:entry-point")
ff2() => gg2();

@pragma("vm:entry-point")
gg2() => throw new NotASubclassOfError();

// == Rethrow, with intervening catch without a trace parameter.

@pragma("vm:entry-point")
aa3() {
  try {
    bb3();
    fail();
  } catch (exception, stacktrace) {
    expectTrace(['cc3', 'bb3', 'aa3'], stacktrace);
  }
}

@pragma("vm:entry-point")
bb3() => cc3();

@pragma("vm:entry-point")
cc3() {
  try {
    dd3();
  } catch (e) {
    throw e;
  }
}

@pragma("vm:entry-point")
dd3() => ee3();

@pragma("vm:entry-point")
ee3() {
  try {
    ff3();
  } catch (e) {
    rethrow;
  }
}

@pragma("vm:entry-point")
ff3() => gg3();

@pragma("vm:entry-point")
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
