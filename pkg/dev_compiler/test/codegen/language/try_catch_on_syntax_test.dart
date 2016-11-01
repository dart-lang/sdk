// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class MyException { }

class MyException1 extends MyException { }

class MyException2 extends MyException { }

void test1() {
  var foo = 0;
  try {
    throw new MyException1();
  }
  on on MyException2 catch (e) { } /// 02: compile-time error
  catch MyException2 catch (e) { } /// 03: compile-time error
  catch catch catch (e) { } /// 04: compile-time error
  on (e) { } /// 05: compile-time error
  catch MyException2 catch (e) { } /// 06: compile-time error
  on MyException2 catch (e) {
    foo = 1;
  } on MyException1 catch (e) {
    foo = 2;
  } on MyException catch (e) {
    foo = 3;
  }
  on UndefinedClass /// 07: static type warning
  catch(e) { foo = 4; }
  Expect.equals(2, foo);
}

testFinal() {
  try {
    throw "catch this!";
    } catch (e, s) {
      // Test that the error and stack trace variables are final.
      e = null;  /// 10: runtime error
      s = null;  /// 11: runtime error
    }
}

main() {
  test1();
  testFinal();
}
