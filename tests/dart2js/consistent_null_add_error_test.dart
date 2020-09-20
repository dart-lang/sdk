// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test that optimized 'null + x' and slow path '+' produce the same error.
//
// They don't, sometimes we generate null.$add, sometimes JSNull_methods.$add.

@pragma('dart2js:noInline')
@pragma('dart2js:assumeDynamic')
confuse(x) => x;

void check2(String name, name1, f1, name2, f2) {
  Error? trap(part, f) {
    try {
      f();
    } on Error catch (e) {
      return e;
    }
    Expect.fail('should throw: $name.$part');
  }

  var e1 = trap(name1, f1);
  var e2 = trap(name2, f2);
  var s1 = '$e1';
  var s2 = '$e2';
  Expect.equals(s1, s2, '\n  $name.$name1: "$s1"\n  $name.$name2: "$s2"\n');
}

void check(String name, f1, f2, [f3, f4, f5, f6]) {
  check2(name, 'f1', f1, 'f2', f2);
  if (f3 != null) check2(name, 'f1', f1, 'f3', f3);
  if (f4 != null) check2(name, 'f1', f1, 'f4', f4);
  if (f5 != null) check2(name, 'f1', f1, 'f5', f5);
  if (f6 != null) check2(name, 'f1', f1, 'f6', f6);
}

class NullPlusInt {
  static f1() {
    return confuse(null) + confuse(1);
  }

  static f2() {
    return confuse(null) + 1;
  }

  static f3() {
    return (confuse(null) as int) + confuse(1);
  }

  static f4() {
    return (confuse(null) as int) + 1;
  }

  static f5() {
    var a = null;
    return a + confuse(1);
  }

  static f6() {
    var a = null;
    return a + 1;
  }

  static test() {
    // Sometimes we generate null.$add, sometimes JSNull_methods.$add. The best
    // we can do is check there is an error.
    check('NullPlusInt', f1, f1);
    check('NullPlusInt', f2, f2);
    check('NullPlusInt', f3, f3);
    check('NullPlusInt', f4, f4);
    check('NullPlusInt', f5, f5);
    check('NullPlusInt', f6, f6);
  }
}

main() {
  NullPlusInt.test();
}
