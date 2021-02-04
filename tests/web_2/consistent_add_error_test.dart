// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import "package:expect/expect.dart";

// Test that optimized '+' and slow path '+' produce the same error.

@pragma('dart2js:noInline')
@pragma('dart2js:assumeDynamic')
confuse(x) => x;

void check2(String name, name1, f1, name2, f2) {
  Error trap(part, f) {
    try {
      f();
    } catch (e) {
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

void check(String name, f1, f2, [f3, f4, f5, f6, f7]) {
  check2(name, 'f1', f1, 'f2', f2);
  if (f3 != null) check2(name, 'f1', f1, 'f3', f3);
  if (f4 != null) check2(name, 'f1', f1, 'f4', f4);
  if (f5 != null) check2(name, 'f1', f1, 'f5', f5);
  if (f6 != null) check2(name, 'f1', f1, 'f6', f6);
  if (f7 != null) check2(name, 'f1', f1, 'f7', f7);
}

class IntPlusNull {
  static f1() {
    return confuse(1) + confuse(null);
  }

  static f2() {
    return confuse(1) + null;
  }

  static f3() {
    return (confuse(1) as int) + confuse(null);
  }

  static f4() {
    return (confuse(1) as int) + null;
  }

  static f5() {
    var a = confuse(true) ? 1 : 2; // Small int with unknown value.
    return a + confuse(null);
  }

  static f6() {
    var a = confuse(true) ? 1 : 2; // Small int with unknown value.
    return a + null;
  }

  static f7() {
    return 1 + null;
  }

  static test() {
    check('IntPlusNull', f1, f2, f3, f4, f5, f6, f7);
  }
}

class StringPlusNull {
  static f1() {
    return confuse('a') + confuse(null);
  }

  static f2() {
    return confuse('a') + null;
  }

  static f3() {
    return (confuse('a') as String) + confuse(null);
  }

  static f4() {
    return (confuse('a') as String) + null;
  }

  static f5() {
    var a = confuse(true) ? 'a' : 'bc';
    return a + confuse(null);
  }

  static f6() {
    var a = confuse(true) ? 'a' : 'bc';
    return a + null;
  }

  static f7() {
    return 'a' + null;
  }

  static test() {
    check('StringPlusNull', f1, f2, f3, f4, f5, f6, f7);
  }
}

class IntPlusString {
  static f1() {
    return confuse(1) + confuse('a');
  }

  static f2() {
    return confuse(1) + 'a';
  }

  static f3() {
    var a = confuse(true) ? 1 : 2; // Small int with unknown value.
    return a + confuse('a');
  }

  static f4() {
    return (confuse(1) as int) + confuse('a');
  }

  static test() {
    check('IntPlusString', f1, f2, f3, f4);
  }
}

class StringPlusInt {
  static f1() {
    return confuse('a') + confuse(1);
  }

  static f2() {
    return confuse('a') + 1;
  }

  static f3() {
    return (confuse('a') as String) + confuse(1);
  }

  static f4() {
    var a = confuse(true) ? 'a' : 'bc';
    return a + confuse(1);
  }

  static test() {
    check('StringPlusInt', f1, f2, f3, f4);
  }
}

main() {
  IntPlusNull.test();
  StringPlusNull.test();
  IntPlusString.test();
  StringPlusInt.test();
}
