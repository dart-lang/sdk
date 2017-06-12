// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

testSimpleBreak() {
  var x = 1;
  while (true) {
    try {
      x++;
      break;
    } finally {
      x++;
      break;
    }
  }
  return x;
}

testReturnFinally() {
  try {
    return 1;
  } finally {
    return 42;
  }
}

testNestedReturnFinally() {
  try {
    try {
      return 1;
    } finally {
      return 2;
    }
  } finally {
    return 42;
  }
}

testReturnInsideLoop() {
  while (true) {
    try {
      print("hello");
    } finally {
      return 42;
    }
  }
}

testStopContinueInsideLoop() {
  while (true) {
    try {
      continue;
    } finally {
      return 42;
    }
  }
}

testStopBreakInsideLoop() {
  var foo = 1;
  while (true) {
    try {
      if (foo == 1) {
        // 1st iteration we break.
        break;
      } else if (foo == 2) {
        // 2nd iteration we return.
        return 42;
      }
    } finally {
      // 1st iteration we overrwrite break with continue.
      if (foo == 1) {
        foo++;
        continue;
      } else {
        // Let return work
      }
    }
  }
  return foo;
}

testStopBreakInsideLoop2() {
  var foo = 1;
  while (true) {
    try {
      if (foo == 1) {
        // 1st iteration we break.
        break;
      } else if (foo == 2) {
        // 2nd iteration we return.
        return -1;
      }
    } finally {
      // 1st iteration we overrwrite break with continue.
      if (foo == 1) {
        foo++;
        continue;
      } else {
        // 2nd iteration we overrwrite return with break.
        foo = 42;
        break;
      }
    }
  }
  return foo;
}

testStopContinueInsideSwitch() {
  var foo = 1;
  switch (foo) {
    jump5:
    case 5:
      return -1;

    case 1:
      try {
        continue jump5;
      } finally {
        return 42;
      }
  }
}

testStopContinueInsideSwitch2() {
  var foo = 1;
  switch (foo) {
    jump5:
    case 5:
      return -1;

    jump42:
    case 5:
      return 42;

    case 1:
      try {
        continue jump5;
      } finally {
        continue jump42;
      }
  }
}

testNestedFinally() {
  var events = '';
  try {
    try {
      events = '$events|start';
    } finally {
      events = '$events|start-catch';
    }
    try {
      try {
        return;
      } finally {
        events = '$events|inner';
        throw 0;
      }
    } finally {
      events = '$events|middle';
    }
  } catch (e) {
    events = '$events|outer-catch';
  } finally {
    events = '$events|outer-finally';
  }
  Expect.equals(
      events, '|start|start-catch|inner|middle|outer-catch|outer-finally');
}

main() {
  Expect.isTrue(testSimpleBreak() == 3);
  Expect.isTrue(testReturnFinally() == 42);
  Expect.isTrue(testNestedReturnFinally() == 42);
  Expect.isTrue(testReturnInsideLoop() == 42);
  Expect.isTrue(testStopContinueInsideLoop() == 42);
  Expect.isTrue(testStopBreakInsideLoop() == 42);
  Expect.isTrue(testStopBreakInsideLoop2() == 42);
  Expect.isTrue(testStopContinueInsideLoop() == 42);
  Expect.isTrue(testStopContinueInsideSwitch() == 42);
  Expect.isTrue(testStopContinueInsideSwitch2() == 42);
  testNestedFinally();
}
