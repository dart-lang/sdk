// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test that optimized codeUnitAt and slow path codeUnitAt produce the same
// error.

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

void check(String name, f1, f2, [f3, f4]) {
  check2(name, 'f1', f1, 'f2', f2);
  if (f3 != null) check2(name, 'f1', f1, 'f3', f3);
  if (f4 != null) check2(name, 'f1', f1, 'f4', f4);
}

class TooHigh {
  static f1() {
    return confuse('AB').codeUnitAt(3); // dynamic receiver.
  }

  static f2() {
    var a = confuse(true) ? 'AB' : 'ABCDE'; // String with unknown length.
    var i = confuse(3);
    return a.codeUnitAt(i);
  }

  static f3() {
    var a = confuse(true) ? 'AB' : 'ABCDE'; // String with unknown length.
    return a.codeUnitAt(3);
  }

  static test() {
    check('TooHigh', f1, f2, f3);
  }
}

class Negative {
  static f1() {
    return confuse('AB').codeUnitAt(-3); // dynamic receiver.
  }

  static f2() {
    var a = confuse(true) ? 'AB' : 'ABCDE'; // String with unknown length.
    var i = confuse(-3);
    return a.codeUnitAt(i);
  }

  static f3() {
    var a = confuse(true) ? 'AB' : 'ABCDE'; // String with unknown length.
    var i = confuse(true) ? -3 : 0;
    return a.codeUnitAt(i);
  }

  static f4() {
    var a = confuse(true) ? 'AB' : 'ABCDE'; // String with unknown length.
    return a.codeUnitAt(-3);
  }

  static test() {
    check('Negative', f1, f2, f3, f4);
  }
}

class Empty {
  static f1() {
    return confuse('').codeUnitAt(0); // dynamic receiver.
  }

  static f2() {
    var a = confuse(true) ? '' : 'ABCDE'; // Empty String with unknown length.
    var i = confuse(true) ? 0 : 1;
    return a.codeUnitAt(i);
  }

  static f3() {
    var a = confuse(true) ? '' : 'ABCDE'; // Empty String with unknown length.
    return a.codeUnitAt(0);
  }

  static test() {
    check('Empty', f1, f2, f3);
  }
}

class BadType {
  static f1() {
    return confuse('AB').codeUnitAt('a'); // dynamic receiver.
  }

  static f2() {
    var a = confuse(true) ? 'AB' : 'ABCDE'; // String with unknown length.
    var i = confuse('a');
    return a.codeUnitAt(i);
  }

  static f3() {
    var a = confuse(true) ? 'AB' : 'ABCDE'; // String with unknown length.
    return a.codeUnitAt(('a' as dynamic));
  }

  static test() {
    check('BadType', f1, f2, f3);
  }
}

main() {
  TooHigh.test();
  Negative.test();
  Empty.test();
  BadType.test();
}
