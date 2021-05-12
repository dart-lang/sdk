// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import "package:expect/expect.dart";
import "dart:typed_data";

// Test that optimized indexing and slow path indexing produce the same error.

@pragma('dart2js:noInline')
@pragma('dart2js:assumeDynamic')
confuse(x) => x;

class TooHigh {
  static load1() {
    var a = confuse(true) ? [10, 11] : [10, 11, 12, 13, 14];
    try {
      // dynamic receiver causes method to be called via interceptor.
      return confuse(a)[3];
    } catch (e) {
      return e;
    }
    Expect.fail('unreached');
  }

  static load2() {
    try {
      confuse(load2x)(3);
    } catch (e) {
      return e;
    }
    Expect.fail('unreached');
  }

  static load2x(i) {
    var a = confuse(true) ? [10, 11] : [10, 11, 12, 13, 14];
    // 'a' is inferred as JSArray of unknown length so has optimized check.
    return a[i];
  }

  static test() {
    var e1 = load1();
    var e2 = load2();
    Expect.equals('$e1', '$e2', '\n  A: "$e1"\n  B: "$e2"\n');
  }
}

class Negative {
  static load1() {
    var a = confuse(true) ? [10, 11] : [10, 11, 12, 13, 14];
    try {
      // dynamic receiver causes method to be called via interceptor.
      return confuse(a)[-3];
    } catch (e) {
      return e;
    }
    Expect.fail('unreached');
  }

  static load2() {
    try {
      confuse(load2x)(-3);
    } catch (e) {
      return e;
    }
    Expect.fail('unreached');
  }

  static load2x(i) {
    var a = confuse(true) ? [10, 11] : [10, 11, 12, 13, 14];
    // 'a' is inferred as JSArray of unknown length so has optimized check.
    return a[i];
  }

  static test() {
    var e1 = load1();
    var e2 = load2();
    Expect.equals('$e1', '$e2', '\n  A: "$e1"\n  B: "$e2"\n');
  }
}

class Empty {
  static load1() {
    var a = confuse(true) ? [] : [10, 11, 12, 13, 14];
    try {
      // dynamic receiver causes method to be called via interceptor.
      return confuse(a)[-3];
    } catch (e) {
      return e;
    }
    Expect.fail('unreached');
  }

  static load2() {
    try {
      confuse(load2x)(-3);
    } catch (e) {
      return e;
    }
    Expect.fail('unreached');
  }

  static load2x(i) {
    var a = confuse(true) ? [] : [10, 11, 12, 13, 14];
    // 'a' is inferred as JSArray of unknown length so has optimized check.
    return a[i];
  }

  static test() {
    var e1 = load1();
    var e2 = load2();
    Expect.equals('$e1', '$e2', '\n  A: "$e1"\n  B: "$e2"\n');
  }
}

class BadType {
  static load1() {
    var a = confuse(true) ? [10, 11] : [10, 11, 12, 13, 14];
    try {
      // dynamic receiver causes method to be called via interceptor.
      return confuse(a)['a'];
    } catch (e) {
      return e;
    }
    Expect.fail('unreached');
  }

  static load2() {
    try {
      confuse(load2x)('a');
    } catch (e) {
      return e;
    }
    Expect.fail('unreached');
  }

  static load2x(i) {
    var a = confuse(true) ? [10, 11] : [10, 11, 12, 13, 14];
    // 'a' is inferred as JSArray of unknown length so has optimized check.
    return a[i];
  }

  static test() {
    var e1 = load1();
    var e2 = load2();
    Expect.equals('$e1', '$e2', '\n  A: "$e1"\n  B: "$e2"\n');
  }
}

main() {
  TooHigh.test();
  Negative.test();
  Empty.test();
  BadType.test();
}
