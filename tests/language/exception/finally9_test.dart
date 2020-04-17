// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// This test ensures that the finally block executes correctly when
// there are throw, break and return statements in the finally block.

import "package:expect/expect.dart";

class Hello {
  static var sum;

  static foo() {
    sum = 0;
    try {
      sum += 1;
      return 'hi';
    } catch (e) {
      sum += 1;
      throw 'ball';
      sum += 1;
    } finally {
      sum += 1;
      throw 'ball';
      sum += 1;
    }
  }

  static foo1() {
    bool loop = true;
    sum = 0;
    L:
    while (loop) {
      try {
        sum += 1;
        return 'hi';
      } catch (ex) {
        sum += 1;
      } finally {
        try {
          L1:
          while (loop) {
            sum += 1;
            break L;
            sum += 1;
          }
        } catch (ex) {
          sum += 1;
        } finally {
          sum += 1;
        }
      }
    }
  }

  static void main() {
    foo1();
    Expect.equals(3, sum);
    try {
      foo();
    } catch (e) {
      // Ignore.
    }
    Expect.equals(2, sum);
  }
}

main() {
  Hello.main();
}
