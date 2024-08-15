// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';
import 'package:expect/expect.dart';

// Test that unmodifiable typed data operations on optimized and slow paths
// produce the same error.

@pragma('dart2js:never-inline')
@pragma('dart2js:assumeDynamic')
confuse(x) => x;

void check2(String name, String name1, f1(), String name2, f2()) {
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

void check(String name, f1(), f2(), [f3()?, f4()?]) {
  check2(name, 'f1', f1, 'f2', f2);
  if (f3 != null) check2(name, 'f1', f1, 'f3', f3);
  if (f4 != null) check2(name, 'f1', f1, 'f4', f4);
}

void main() {
  ByteData a = ByteData(100);
  ByteData b = a.asUnmodifiableView();
  ByteData c = confuse(true) ? b : a;

  dynamic d = confuse(true) ? b : const [1];

  void setInt8Test() {
    void f1() {
      d.setInt8(0, 1); // dynamic receiver.
    }

    void f2() {
      b.setInt8(0, 1); // unmodifiable receiver
    }

    void f3() {
      c.setInt8(0, 1); // potentially unmodifiable receiver
    }

    check('setInt8', f1, f2, f3);
  }

  void setInt16Test() {
    void f1() {
      d.setInt16(0, 1); // dynamic receiver.
    }

    void f2() {
      b.setInt16(0, 1); // unmodifiable receiver
    }

    void f3() {
      c.setInt16(0, 1); // potentially unmodifiable receiver
    }

    check('setInt16', f1, f2, f3);
  }

  void setInt32Test() {
    void f1() {
      d.setInt32(0, 1); // dynamic receiver.
    }

    void f2() {
      b.setInt32(0, 1); // unmodifiable receiver
    }

    void f3() {
      c.setInt32(0, 1); // potentially unmodifiable receiver
    }

    check('setInt32', f1, f2, f3);
  }

  void setInt64Test() {
    void f1() {
      d.setInt64(0, 1); // dynamic receiver.
    }

    void f2() {
      b.setInt64(0, 1); // unmodifiable receiver
    }

    void f3() {
      c.setInt64(0, 1); // potentially unmodifiable receiver
    }

    check('setInt64', f1, f2, f3);
  }

  void setUint8Test() {
    void f1() {
      d.setUint8(0, 1); // dynamic receiver.
    }

    void f2() {
      b.setUint8(0, 1); // unmodifiable receiver
    }

    void f3() {
      c.setUint8(0, 1); // potentially unmodifiable receiver
    }

    check('setUint8', f1, f2, f3);
  }

  void setUint16Test() {
    void f1() {
      d.setUint16(0, 1); // dynamic receiver.
    }

    void f2() {
      b.setUint16(0, 1); // unmodifiable receiver
    }

    void f3() {
      c.setUint16(0, 1); // potentially unmodifiable receiver
    }

    check('setUint16', f1, f2, f3);
  }

  void setUint32Test() {
    void f1() {
      d.setUint32(0, 1); // dynamic receiver.
    }

    void f2() {
      b.setUint32(0, 1); // unmodifiable receiver
    }

    void f3() {
      c.setUint32(0, 1); // potentially unmodifiable receiver
    }

    check('setUint32', f1, f2, f3);
  }

  void setUint64Test() {
    void f1() {
      d.setUint64(0, 1); // dynamic receiver.
    }

    void f2() {
      b.setUint64(0, 1); // unmodifiable receiver
    }

    void f3() {
      c.setUint64(0, 1); // potentially unmodifiable receiver
    }

    check('setUint64', f1, f2, f3);
  }

  void setFloat32Test() {
    void f1() {
      d.setFloat32(0, 1.23); // dynamic receiver.
    }

    void f2() {
      b.setFloat32(0, 1.23); // unmodifiable receiver
    }

    void f3() {
      c.setFloat32(0, 1.23); // potentially unmodifiable receiver
    }

    check('setFloat32', f1, f2, f3);
  }

  void setFloat64Test() {
    void f1() {
      d.setFloat64(0, 1.23); // dynamic receiver.
    }

    void f2() {
      b.setFloat64(0, 1.23); // unmodifiable receiver
    }

    void f3() {
      c.setFloat64(0, 1.23); // potentially unmodifiable receiver
    }

    check('setFloat64', f1, f2, f3);
  }

  setInt8Test();
  setInt16Test();
  setInt32Test();
  setInt64Test();

  setUint8Test();
  setUint16Test();
  setUint32Test();
  setUint64Test();

  setFloat32Test();
  setFloat64Test();
}
