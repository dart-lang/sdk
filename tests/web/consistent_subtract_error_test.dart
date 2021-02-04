// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// dart2jsOptions=--omit-implicit-checks

import "package:expect/expect.dart";

// Test that optimized '-' and slow path '-' produce the same error.

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

void check(String name, f1, f2, [f3, f4, f5, f6, f7]) {
  check2(name, 'f1', f1, 'f2', f2);
  if (f3 != null) check2(name, 'f1', f1, 'f3', f3);
  if (f4 != null) check2(name, 'f1', f1, 'f4', f4);
  if (f5 != null) check2(name, 'f1', f1, 'f5', f5);
  if (f6 != null) check2(name, 'f1', f1, 'f6', f6);
  if (f7 != null) check2(name, 'f1', f1, 'f7', f7);
}

class IntMinusNull {
  static f1() {
    return confuse(1) - confuse(null);
  }

  static f2() {
    return confuse(1) - null;
  }

  static f3() {
    return (confuse(1) as int) - confuse(null);
  }

  static f4() {
    return (confuse(1) as int) - (null as dynamic);
  }

  static f5() {
    var a = confuse(true) ? 1 : 2; // Small int with unknown value.
    return a - confuse(null);
  }

  static f6() {
    var a = confuse(true) ? 1 : 2; // Small int with unknown value.
    return a - (null as dynamic);
  }

  static f7() {
    return 1 - (null as dynamic);
  }

  static test() {
    check('IntMinusNull', f1, f2, f3, f4, f5, f6, f7);
  }
}

class IntMinusString {
  static f1() {
    return confuse(1) - confuse('a');
  }

  static f2() {
    return confuse(1) - 'a';
  }

  static f3() {
    var a = confuse(true) ? 1 : 2; // Small int with unknown value.
    return a - confuse('a');
  }

  static f4() {
    return (confuse(1) as int) - confuse('a');
  }

  static test() {
    check('IntMinusString', f1, f2, f3, f4);
  }
}

main() {
  IntMinusNull.test();
  IntMinusString.test();
}
