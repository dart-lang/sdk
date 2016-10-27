// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

testSimpleThrowCatch() {
  var x = 1;
  try {
    throw x++;
  } on int catch (e) {
    Expect.isTrue(e == 1);
    Expect.isTrue(x == 2);
    x++;
  }
  Expect.isTrue(x == 3);
}

testNestedThrowCatch() {
  var x = 1;
  try {
    throw x++;
  } catch (e) {
    Expect.isTrue(e == 1);
    Expect.isTrue(x == 2);
    x++;

    try {
      throw x++;
    } catch (e) {
      Expect.isTrue(e == 3);
      Expect.isTrue(x == 4);
      x++;
    }
  }
  Expect.isTrue(x == 5);
}

testNestedThrowCatch2() {
  var x = 1;
  try {
    try {
      throw x++;
    } catch (e) {
      Expect.isTrue(e == 1);
      Expect.isTrue(x == 2);
      x++;
    }
    throw x++;
  } catch (e) {
    Expect.isTrue(e == 3);
    Expect.isTrue(x == 4);
    x++;
  }
  Expect.isTrue(x == 5);
}

testSiblingThrowCatch() {
  var x = 1;
  try {
    throw x++;
  } catch (e) {
    Expect.isTrue(e == 1);
    Expect.isTrue(x == 2);
    x++;
  }
  try {
    throw x++;
  } catch (e) {
    Expect.isTrue(e == 3);
    Expect.isTrue(x == 4);
    x++;
  }

  Expect.isTrue(x == 5);
}

testTypedCatch() {
  var good = false;
  try {
    throw 1;
  } on int catch (e) {
    Expect.isTrue(e == 1);
    good = true;
  } on String catch (_) {
    Expect.isTrue(false);
  }
  Expect.isTrue(good);
}

testTypedCatch2() {
  var good = false;
  try {
    throw 'a';
  } on int catch (_) {
    Expect.isTrue(false);
  } on String catch (e) {
    Expect.isTrue(e == 'a');
    good = true;
  }
  Expect.isTrue(good);
}

testThrowNull() {
  var good = false;
  try {
    throw null;
  } on NullThrownError catch (_) {
    good = true;
  }
  Expect.isTrue(good);
}

testFinally() {
  var x = 0;
  try {
    throw x++;
  } catch (_) {
    x++;
  } finally {
    x++;
  }
  Expect.isTrue(x == 3);
}

testFinally2() {
  var x = 0;
  try {
    try {
      throw x++;
    } catch (_) {
      x++;
    } finally {
      x++;
    }
  } finally {
    x++;
  }
  Expect.isTrue(x == 4);
}

testFinally3() {
  try {
    var x = 0;
    try {
      throw x++;
    } finally {
      x++;
    }
    Expect.isTrue(x == 2);
  } catch (_) {}
}

testSuccessfulBody() {
  var x = 0;
  try {
    x++;
  } finally {
    x++;
  }
  Expect.isTrue(x == 2);
}

testSuccessfulBody2() {
  var x = 0;
  try {
    try {
      x++;
    } finally {
      x++;
      throw 1;
    }
  } on int {}
  Expect.isTrue(x == 2);
}

main() {
  testSimpleThrowCatch();
  testNestedThrowCatch();
  testNestedThrowCatch2();
  testSiblingThrowCatch();
  testTypedCatch();
  testTypedCatch2();
  testThrowNull();
  testFinally();
  testFinally2();
  testFinally3();
  testSuccessfulBody();
  testSuccessfulBody2();
}
