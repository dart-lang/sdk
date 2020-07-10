// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "dart:typed_data";

// Test that optimized indexing and slow path indexing produce the same error.

@pragma('dart2js:noInline')
@pragma('dart2js:assumeDynamic')
confuse(x) => x;

class TooHigh {
  static load1() {
    var a = confuse(true)
        ? new Uint8List.fromList([10, 11])
        : new Uint8List.fromList([10, 11, 12, 13, 14]);
    try {
      return confuse(a)[3]; // dynamic receiver for indexer.
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
    var a = confuse(true)
        ? new Uint8List.fromList([10, 11])
        : new Uint8List.fromList([10, 11, 12, 13, 14]);
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
    var a = confuse(true)
        ? new Uint8List.fromList([10, 11])
        : new Uint8List.fromList([10, 11, 12, 13, 14]);
    try {
      return confuse(a)[-3]; // dynamic receiver for indexer.
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
    var a = confuse(true)
        ? new Uint8List.fromList([10, 11])
        : new Uint8List.fromList([10, 11, 12, 13, 14]);
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
    var a = confuse(true)
        ? new Uint8List.fromList([])
        : new Uint8List.fromList([10, 11, 12, 13, 14]);
    try {
      return confuse(a)[-3]; // dynamic receiver for indexer.
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
    var a = confuse(true)
        ? new Uint8List.fromList([])
        : new Uint8List.fromList([10, 11, 12, 13, 14]);
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
    var a = confuse(true)
        ? new Uint8List.fromList([10, 11])
        : new Uint8List.fromList([10, 11, 12, 13, 14]);
    try {
      return confuse(a)['a']; // dynamic receiver for indexer.
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
    var a = confuse(true)
        ? new Uint8List.fromList([10, 11])
        : new Uint8List.fromList([10, 11, 12, 13, 14]);
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
