// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class MyException {}

class MyException1 extends MyException {}

class MyException2 extends MyException {}

void test1() {
  var foo = 0;
  try {
    throw new MyException1();
  }
  on on MyException2 catch (e) { } //# 02: syntax error
  catch MyException2 catch (e) { } //# 03: syntax error
  catch catch catch (e) { } //# 04: syntax error
  on (e) { } //# 05: syntax error
  catch MyException2 catch (e) { } //# 06: syntax error
  on MyException2 catch (e) {
    foo = 1;
  } on MyException1 catch (e) {
    foo = 2;
  } on MyException catch (e) {
    foo = 3;
  }
  on UndefinedClass //# 07: compile-time error
  catch (e) {
    foo = 4;
  }
  Expect.equals(2, foo);
}

testFinal() {
  try {
    throw "catch this!";
  } catch (e, s) {
    // Test that the error and stack trace variables are final.
      e = null; // //# 10: compile-time error
      s = null; // //# 11: compile-time error
  }
}

main() {
  test1();
  testFinal();
}
