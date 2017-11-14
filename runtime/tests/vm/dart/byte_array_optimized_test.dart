// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization_counter_threshold=10 --no-background-compilation

// Library tag to be able to run in html test framework.
library byte_array_test;

import "package:expect/expect.dart";
import 'dart:typed_data';

// This test exercises optimized [] and []= operators
// on byte array views.
class OptimizedByteArrayTest {
  static testInt8ListImpl(Int8List array) {
    Expect.isTrue(array is List<int>);
    Expect.equals(10, array.length);
    Expect.equals(1, array.elementSizeInBytes);
    Expect.equals(10, array.lengthInBytes);
    Expect.listEquals([0, 0, 0, 0, 0, 0, 0, 0, 0, 0], array);
    Expect.throws(() {
      array[-1] = 0;
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      return array[-1];
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      array[10];
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      array[10] = 0;
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      array.add(0);
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      array.addAll([0]);
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      array.clear();
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      array.length = 0;
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      array.removeLast();
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      array.removeRange(0, array.length - 1);
    }, (e) {
      return e is UnsupportedError;
    });
    for (int i = 0; i < array.length; ++i) {
      array[i] = 1 + i;
    }
    Expect.listEquals([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], array);
    for (int i = 0; i < array.length; ++i) {
      array[i] = 0x100 + i;
    }
    Expect.listEquals([0, 1, 2, 3, 4, 5, 6, 7, 8, 9], array);
    for (int i = 0; i < array.length; ++i) {
      array[i] = -10 + i;
    }
    Expect.listEquals([-10, -9, -8, -7, -6, -5, -4, -3, -2, -1], array);
    for (int i = 0; i < array.length; ++i) {
      array[i] = 0x7F - i;
    }
    Expect
        .listEquals([127, 126, 125, 124, 123, 122, 121, 120, 119, 118], array);
    for (int i = 0; i < array.length; ++i) {
      array[i] = -0x80 + i;
    }
    Expect.listEquals(
        [-128, -127, -126, -125, -124, -123, -122, -121, -120, -119], array);
    for (int i = 0; i < array.length; ++i) {
      array[i] = i;
    }
    var copy = array.sublist(0, array.length);
    Expect.isFalse(identical(copy, array));
    Expect.isTrue(copy is Int8List);
    Expect.equals(10, copy.length);
    Expect.listEquals(array, copy);
    var empty = array.sublist(array.length, array.length);
    Expect.equals(0, empty.length);
    var region = array.sublist(3, array.length - 3);
    Expect.isTrue(copy is Int8List);
    Expect.equals(4, region.length);
    Expect.listEquals([3, 4, 5, 6], region);
    array.setRange(3, 7, [-128, 0, 1, 127]);
    Expect.listEquals([0, 1, 2, -128, 0, 1, 127, 7, 8, 9], array);
  }

  static testInt8List() {
    Expect.throws(() {
      new Int8List(-1);
    }, (e) {
      return e is ArgumentError;
    });
    var array = new Int8List(10);
    testInt8ListImpl(array);
  }

  static testUint8ListImpl(Uint8List array) {
    Expect.isTrue(array is List<int>);
    Expect.equals(10, array.length);
    Expect.equals(1, array.elementSizeInBytes);
    Expect.equals(10, array.lengthInBytes);
    Expect.listEquals([0, 0, 0, 0, 0, 0, 0, 0, 0, 0], array);
    Expect.throws(() {
      array[-1] = 0;
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      return array[-1];
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      array[10];
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      array[10] = 0;
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      array.add(0);
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      array.addAll([0]);
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      array.clear();
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      array.length = 0;
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      array.removeLast();
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      array.removeRange(0, array.length - 1);
    }, (e) {
      return e is UnsupportedError;
    });
    for (int i = 0; i < array.length; ++i) {
      array[i] = 1 + i;
    }
    Expect.listEquals([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], array);
    for (int i = 0; i < array.length; ++i) {
      array[i] = 0x100 + i;
    }
    Expect.listEquals([0, 1, 2, 3, 4, 5, 6, 7, 8, 9], array);
    for (int i = 0; i < array.length; ++i) {
      array[i] = 0xFF - i;
    }
    Expect.listEquals(
        [0xFF, 0xFE, 0xFD, 0xFC, 0xFB, 0xFA, 0xF9, 0xF8, 0xF7, 0xF6], array);
    for (int i = 0; i < array.length; ++i) {
      array[i] = i;
    }
    var copy = array.sublist(0, array.length);
    Expect.isFalse(identical(copy, array));
    Expect.isTrue(copy is Uint8List);
    Expect.equals(10, copy.length);
    Expect.listEquals(array, copy);
    var empty = array.sublist(array.length, array.length);
    Expect.equals(0, empty.length);
    var region = array.sublist(3, array.length - 3);
    Expect.isTrue(copy is Uint8List);
    Expect.equals(4, region.length);
    Expect.listEquals([3, 4, 5, 6], region);
    array.setRange(3, 7, [257, 0, 1, 255]);
    Expect.listEquals([0, 1, 2, 1, 0, 1, 255, 7, 8, 9], array);
  }

  static testUint8List() {
    Expect.throws(() {
      new Uint8List(-1);
    }, (e) {
      return e is ArgumentError;
    });
    var array = new Uint8List(10);
    testUint8ListImpl(array);
  }

  static testInt16ListImpl(Int16List array) {
    Expect.isTrue(array is List<int>);
    Expect.equals(10, array.length);
    Expect.equals(2, array.elementSizeInBytes);
    Expect.equals(20, array.lengthInBytes);
    Expect.listEquals([0, 0, 0, 0, 0, 0, 0, 0, 0, 0], array);
    Expect.throws(() {
      array[-1] = 0;
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      return array[-1];
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      array[10];
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      array[10] = 0;
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      array.add(0);
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      array.addAll([0]);
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      array.clear();
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      array.length = 0;
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      array.removeLast();
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      array.removeRange(0, array.length - 1);
    }, (e) {
      return e is UnsupportedError;
    });
    for (int i = 0; i < array.length; ++i) {
      array[i] = 1 + i;
    }
    Expect.listEquals([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], array);
    for (int i = 0; i < array.length; ++i) {
      array[i] = 0x10000 + i;
    }
    Expect.listEquals([0, 1, 2, 3, 4, 5, 6, 7, 8, 9], array);
    for (int i = 0; i < array.length; ++i) {
      array[i] = -10 + i;
    }
    Expect.listEquals([-10, -9, -8, -7, -6, -5, -4, -3, -2, -1], array);
    for (int i = 0; i < array.length; ++i) {
      array[i] = 0x7FFF - i;
    }
    Expect.listEquals([
      0x7FFF,
      0x7FFE,
      0x7FFD,
      0x7FFC,
      0x7FFB,
      0x7FFA,
      0x7FF9,
      0x7FF8,
      0x7FF7,
      0x7FF6
    ], array);
    for (int i = 0; i < array.length; ++i) {
      array[i] = -0x8000 + i;
    }
    Expect.listEquals([
      -0x8000,
      -0x7FFF,
      -0x7FFE,
      -0x7FFD,
      -0x7FFC,
      -0x7FFB,
      -0x7FFA,
      -0x7FF9,
      -0x7FF8,
      -0x7FF7
    ], array);
    for (int i = 0; i < array.length; ++i) {
      array[i] = i;
    }
    var copy = array.sublist(0, array.length);
    Expect.isFalse(identical(copy, array));
    Expect.isTrue(copy is Int16List);
    Expect.equals(10, copy.length);
    Expect.listEquals(array, copy);
    var empty = array.sublist(array.length, array.length);
    Expect.equals(0, empty.length);
    var region = array.sublist(3, array.length - 3);
    Expect.isTrue(copy is Int16List);
    Expect.equals(4, region.length);
    Expect.listEquals([3, 4, 5, 6], region);
    array.setRange(3, 7, [-32768, 0, 1, 32767]);
    Expect.listEquals([0, 1, 2, -32768, 0, 1, 32767, 7, 8, 9], array);
  }

  static testInt16List() {
    Expect.throws(() {
      new Int16List(-1);
    }, (e) {
      return e is ArgumentError;
    });
    var array = new Int16List(10);
    testInt16ListImpl(array);
  }

  static testUint16ListImpl(Uint16List array) {
    Expect.isTrue(array is List<int>);
    Expect.equals(10, array.length);
    Expect.equals(2, array.elementSizeInBytes);
    Expect.equals(20, array.lengthInBytes);
    Expect.listEquals([0, 0, 0, 0, 0, 0, 0, 0, 0, 0], array);
    Expect.throws(() {
      array[-1] = 0;
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      return array[-1];
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      array[10];
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      array[10] = 0;
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      array.add(0);
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      array.addAll([0]);
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      array.clear();
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      array.length = 0;
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      array.removeLast();
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      array.removeRange(0, array.length - 1);
    }, (e) {
      return e is UnsupportedError;
    });
    for (int i = 0; i < array.length; ++i) {
      array[i] = 1 + i;
    }
    Expect.listEquals([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], array);
    for (int i = 0; i < array.length; ++i) {
      array[i] = 0x10000 + i;
    }
    Expect.listEquals([0, 1, 2, 3, 4, 5, 6, 7, 8, 9], array);
    for (int i = 0; i < array.length; ++i) {
      array[i] = 0xFFFF - i;
    }
    Expect.listEquals([
      0xFFFF,
      0xFFFE,
      0xFFFD,
      0xFFFC,
      0xFFFB,
      0xFFFA,
      0xFFF9,
      0xFFF8,
      0xFFF7,
      0xFFF6
    ], array);
    for (int i = 0; i < array.length; ++i) {
      array[i] = i;
    }
    var copy = array.sublist(0, array.length);
    Expect.isFalse(identical(copy, array));
    Expect.isTrue(copy is Uint16List);
    Expect.equals(10, copy.length);
    Expect.listEquals(array, copy);
    var empty = array.sublist(array.length, array.length);
    Expect.equals(0, empty.length);
    var region = array.sublist(3, array.length - 3);
    Expect.isTrue(copy is Uint16List);
    Expect.equals(4, region.length);
    Expect.listEquals([3, 4, 5, 6], region);
    array.setRange(3, 7, [0x10001, 0, 1, 0xFFFF]);
    Expect.listEquals([0, 1, 2, 1, 0, 1, 0xFFFF, 7, 8, 9], array);
  }

  static testUint16List() {
    Expect.throws(() {
      new Uint16List(-1);
    }, (e) {
      return e is ArgumentError;
    });
    var array = new Uint16List(10);
    testUint16ListImpl(array);
  }

  static testInt32ListImpl(Int32List array) {
    Expect.isTrue(array is List<int>);
    Expect.equals(10, array.length);
    Expect.equals(4, array.elementSizeInBytes);
    Expect.equals(40, array.lengthInBytes);
    Expect.listEquals([0, 0, 0, 0, 0, 0, 0, 0, 0, 0], array);
    Expect.throws(() {
      array[-1] = 0;
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      return array[-1];
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      array[10];
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      array[10] = 0;
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      array.add(0);
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      array.addAll([0]);
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      array.clear();
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      array.length = 0;
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      array.removeLast();
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      array.removeRange(0, array.length - 1);
    }, (e) {
      return e is UnsupportedError;
    });
    for (int i = 0; i < array.length; ++i) {
      array[i] = 1 + i;
    }
    Expect.listEquals([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], array);
    for (int i = 0; i < array.length; ++i) {
      array[i] = 0x100000000 + i;
    }
    Expect.listEquals([0, 1, 2, 3, 4, 5, 6, 7, 8, 9], array);
    for (int i = 0; i < array.length; ++i) {
      array[i] = -10 + i;
    }
    Expect.listEquals([-10, -9, -8, -7, -6, -5, -4, -3, -2, -1], array);
    for (int i = 0; i < array.length; ++i) {
      array[i] = 0x7FFFFFFF - i;
    }
    Expect.listEquals([
      0x7FFFFFFF,
      0x7FFFFFFE,
      0x7FFFFFFD,
      0x7FFFFFFC,
      0x7FFFFFFB,
      0x7FFFFFFA,
      0x7FFFFFF9,
      0x7FFFFFF8,
      0x7FFFFFF7,
      0x7FFFFFF6
    ], array);
    for (int i = 0; i < array.length; ++i) {
      array[i] = -0x80000000 + i;
    }
    Expect.listEquals([
      -0x80000000,
      -0x7FFFFFFF,
      -0x7FFFFFFE,
      -0x7FFFFFFD,
      -0x7FFFFFFC,
      -0x7FFFFFFB,
      -0x7FFFFFFA,
      -0x7FFFFFF9,
      -0x7FFFFFF8,
      -0x7FFFFFF7
    ], array);
    for (int i = 0; i < array.length; ++i) {
      array[i] = i;
    }
    var copy = array.sublist(0, array.length);
    Expect.isFalse(identical(copy, array));
    Expect.isTrue(copy is Int32List);
    Expect.equals(10, copy.length);
    Expect.listEquals(array, copy);
    var empty = array.sublist(array.length, array.length);
    Expect.equals(0, empty.length);
    var region = array.sublist(3, array.length - 3);
    Expect.isTrue(copy is Int32List);
    Expect.equals(4, region.length);
    Expect.listEquals([3, 4, 5, 6], region);
    array.setRange(3, 7, [-0x80000000, 0, 1, 0x7FFFFFFF]);
    Expect.listEquals([0, 1, 2, -0x80000000, 0, 1, 0x7FFFFFFF, 7, 8, 9], array);
  }

  static testInt32List() {
    Expect.throws(() {
      new Int32List(-1);
    }, (e) {
      return e is ArgumentError;
    });
    var array = new Int32List(10);
    testInt32ListImpl(array);
  }

  static testUint32ListImpl(Uint32List array) {
    Expect.isTrue(array is List<int>);
    Expect.equals(10, array.length);
    Expect.equals(4, array.elementSizeInBytes);
    Expect.equals(40, array.lengthInBytes);
    Expect.listEquals([0, 0, 0, 0, 0, 0, 0, 0, 0, 0], array);
    Expect.throws(() {
      array[-1] = 0;
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      return array[-1];
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      array[10];
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      array[10] = 0;
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      array.add(0);
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      array.addAll([0]);
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      array.clear();
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      array.length = 0;
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      array.removeLast();
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      array.removeRange(0, array.length - 1);
    }, (e) {
      return e is UnsupportedError;
    });
    for (int i = 0; i < array.length; ++i) {
      array[i] = 1 + i;
    }
    Expect.listEquals([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], array);
    for (int i = 0; i < array.length; ++i) {
      array[i] = 0x100000000 + i;
    }
    Expect.listEquals([0, 1, 2, 3, 4, 5, 6, 7, 8, 9], array);
    for (int i = 0; i < array.length; ++i) {
      array[i] = 0xFFFFFFFF - i;
    }
    Expect.listEquals([
      0xFFFFFFFF,
      0xFFFFFFFE,
      0xFFFFFFFD,
      0xFFFFFFFC,
      0xFFFFFFFB,
      0xFFFFFFFA,
      0xFFFFFFF9,
      0xFFFFFFF8,
      0xFFFFFFF7,
      0xFFFFFFF6
    ], array);
    for (int i = 0; i < array.length; ++i) {
      array[i] = i;
    }
    var copy = array.sublist(0, array.length);
    Expect.isFalse(identical(copy, array));
    Expect.isTrue(copy is Uint32List);
    Expect.equals(10, copy.length);
    Expect.listEquals(array, copy);
    var empty = array.sublist(array.length, array.length);
    Expect.equals(0, empty.length);
    var region = array.sublist(3, array.length - 3);
    Expect.isTrue(copy is Uint32List);
    Expect.equals(4, region.length);
    Expect.listEquals([3, 4, 5, 6], region);
    array.setRange(3, 7, [0x100000001, 0, 1, 0xFFFFFFFF]);
    Expect.listEquals([0, 1, 2, 1, 0, 1, 0xFFFFFFFF, 7, 8, 9], array);
  }

  static testUint32List() {
    Expect.throws(() {
      new Uint32List(-1);
    }, (e) {
      return e is ArgumentError;
    });
    Expect.throws(() {
      new Uint32List(-1);
    }, (e) {
      return e is ArgumentError;
    });
    var array = new Uint32List(10);
    testUint32ListImpl(array);
  }

  static testInt64ListImpl(Int64List array) {
    Expect.isTrue(array is List<int>);
    Expect.equals(10, array.length);
    Expect.equals(8, array.elementSizeInBytes);
    Expect.equals(80, array.lengthInBytes);
    Expect.listEquals([0, 0, 0, 0, 0, 0, 0, 0, 0, 0], array);
    Expect.throws(() {
      array[-1] = 0;
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      return array[-1];
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      array[10];
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      array[10] = 0;
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      array.add(0);
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      array.addAll([0]);
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      array.clear();
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      array.length = 0;
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      array.removeLast();
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      array.removeRange(0, array.length - 1);
    }, (e) {
      return e is UnsupportedError;
    });
    for (int i = 0; i < array.length; ++i) {
      array[i] = 1 + i;
    }
    Expect.listEquals([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], array);
    for (int i = 0; i < array.length; ++i) {
      array[i] = 0x10000000000000000 + i;
    }
    Expect.listEquals([0, 1, 2, 3, 4, 5, 6, 7, 8, 9], array);
    for (int i = 0; i < array.length; ++i) {
      array[i] = -10 + i;
    }
    Expect.listEquals([-10, -9, -8, -7, -6, -5, -4, -3, -2, -1], array);
    for (int i = 0; i < array.length; ++i) {
      array[i] = 0x7FFFFFFFFFFFFFFF - i;
    }
    Expect.listEquals([
      0x7FFFFFFFFFFFFFFF,
      0x7FFFFFFFFFFFFFFE,
      0x7FFFFFFFFFFFFFFD,
      0x7FFFFFFFFFFFFFFC,
      0x7FFFFFFFFFFFFFFB,
      0x7FFFFFFFFFFFFFFA,
      0x7FFFFFFFFFFFFFF9,
      0x7FFFFFFFFFFFFFF8,
      0x7FFFFFFFFFFFFFF7,
      0x7FFFFFFFFFFFFFF6
    ], array);
    for (int i = 0; i < array.length; ++i) {
      array[i] = -0x8000000000000000 + i;
    }
    Expect.listEquals([
      -0x8000000000000000,
      -0x7FFFFFFFFFFFFFFF,
      -0x7FFFFFFFFFFFFFFE,
      -0x7FFFFFFFFFFFFFFD,
      -0x7FFFFFFFFFFFFFFC,
      -0x7FFFFFFFFFFFFFFB,
      -0x7FFFFFFFFFFFFFFA,
      -0x7FFFFFFFFFFFFFF9,
      -0x7FFFFFFFFFFFFFF8,
      -0x7FFFFFFFFFFFFFF7
    ], array);
    for (int i = 0; i < array.length; ++i) {
      array[i] = i;
    }
    var copy = array.sublist(0, array.length);
    Expect.isFalse(identical(copy, array));
    Expect.isTrue(copy is Int64List);
    Expect.equals(10, copy.length);
    Expect.listEquals(array, copy);
    var empty = array.sublist(array.length, array.length);
    Expect.equals(0, empty.length);
    var region = array.sublist(3, array.length - 3);
    Expect.isTrue(copy is Int64List);
    Expect.equals(4, region.length);
    Expect.listEquals([3, 4, 5, 6], region);
    array.setRange(3, 7, [-0x8000000000000000, 0, 1, 0x7FFFFFFFFFFFFFFF]);
    Expect.listEquals(
        [0, 1, 2, -0x8000000000000000, 0, 1, 0x7FFFFFFFFFFFFFFF, 7, 8, 9],
        array);
  }

  static testInt64List() {
    Expect.throws(() {
      new Int64List(-1);
    }, (e) {
      return e is ArgumentError;
    });
    var array = new Int64List(10);
    testInt64ListImpl(array);
  }

  static testUint64ListImpl(Uint64List array) {
    Expect.isTrue(array is List<int>);
    Expect.equals(10, array.length);
    Expect.equals(8, array.elementSizeInBytes);
    Expect.equals(80, array.lengthInBytes);
    Expect.listEquals([0, 0, 0, 0, 0, 0, 0, 0, 0, 0], array);
    Expect.throws(() {
      array[-1] = 0;
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      return array[-1];
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      array[10];
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      array[10] = 0;
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      array.add(0);
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      array.addAll([0]);
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      array.clear();
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      array.length = 0;
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      array.removeLast();
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      array.removeRange(0, array.length - 1);
    }, (e) {
      return e is UnsupportedError;
    });
    for (int i = 0; i < array.length; ++i) {
      array[i] = 1 + i;
    }
    Expect.listEquals([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], array);
    for (int i = 0; i < array.length; ++i) {
      array[i] = 0x10000000000000000 + i;
    }
    Expect.listEquals([0, 1, 2, 3, 4, 5, 6, 7, 8, 9], array);
    for (int i = 0; i < array.length; ++i) {
      array[i] = 0xFFFFFFFFFFFFFFFF - i;
    }
    Expect.listEquals([
      0xFFFFFFFFFFFFFFFF,
      0xFFFFFFFFFFFFFFFE,
      0xFFFFFFFFFFFFFFFD,
      0xFFFFFFFFFFFFFFFC,
      0xFFFFFFFFFFFFFFFB,
      0xFFFFFFFFFFFFFFFA,
      0xFFFFFFFFFFFFFFF9,
      0xFFFFFFFFFFFFFFF8,
      0xFFFFFFFFFFFFFFF7,
      0xFFFFFFFFFFFFFFF6
    ], array);
    for (int i = 0; i < array.length; ++i) {
      array[i] = i;
    }
    var copy = array.sublist(0, array.length);
    Expect.isFalse(identical(copy, array));
    Expect.isTrue(copy is Uint64List);
    Expect.equals(10, copy.length);
    Expect.listEquals(array, copy);
    var empty = array.sublist(array.length, array.length);
    Expect.equals(0, empty.length);
    var region = array.sublist(3, array.length - 3);
    Expect.isTrue(copy is Uint64List);
    Expect.equals(4, region.length);
    Expect.listEquals([3, 4, 5, 6], region);
    array.setRange(3, 7, [0x10000000000000001, 0, 1, 0xFFFFFFFFFFFFFFFF]);
    Expect.listEquals([0, 1, 2, 1, 0, 1, 0xFFFFFFFFFFFFFFFF, 7, 8, 9], array);
  }

  static testUint64List() {
    Expect.throws(() {
      new Uint64List(-1);
    }, (e) {
      return e is ArgumentError;
    });
    var array = new Uint64List(10);
    testUint64ListImpl(array);
  }

  static testFloat32ListImpl(Float32List array) {
    Expect.isTrue(array is List<double>);
    Expect.equals(10, array.length);
    Expect.equals(4, array.elementSizeInBytes);
    Expect.equals(40, array.lengthInBytes);
    Expect
        .listEquals([0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0], array);
    Expect.throws(() {
      array[-1] = 0.0;
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      return array[-1];
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      array[10];
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      array[10] = 0.0;
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      array.add(0.0);
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      array.addAll([0.0]);
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      array.clear();
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      array.length = 0;
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      array.removeLast();
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      array.removeRange(0, array.length - 1);
    }, (e) {
      return e is UnsupportedError;
    });
    for (int i = 0; i < array.length; ++i) {
      array[i] = 1.0 + i;
    }
    Expect
        .listEquals([1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0], array);
    // TODO: min, max, and round
    for (int i = 0; i < array.length; ++i) {
      array[i] = i * 1.0;
    }
    var copy = array.sublist(0, array.length);
    Expect.isFalse(identical(copy, array));
    Expect.isTrue(copy is Float32List);
    Expect.equals(10, copy.length);
    Expect.listEquals(array, copy);
    var empty = array.sublist(array.length, array.length);
    Expect.equals(0, empty.length);
    var region = array.sublist(3, array.length - 3);
    Expect.isTrue(copy is Float32List);
    Expect.equals(4, region.length);
    Expect.listEquals([3.0, 4.0, 5.0, 6.0], region);
    array.setRange(3, 7, [double.negativeInfinity, 0.0, 1.0, double.infinity]);
    Expect.listEquals([
      0.0,
      1.0,
      2.0,
      double.negativeInfinity,
      0.0,
      1.0,
      double.infinity,
      7.0,
      8.0,
      9.0
    ], array);
  }

  static testFloat32List() {
    Expect.throws(() {
      new Float32List(-1);
    }, (e) {
      return e is ArgumentError;
    });
    var array = new Float32List(10);
    testFloat32ListImpl(array);
  }

  static testFloat64ListImpl(Float64List array) {
    Expect.isTrue(array is List<double>);
    Expect.equals(10, array.length);
    Expect.equals(8, array.elementSizeInBytes);
    Expect.equals(80, array.lengthInBytes);
    Expect
        .listEquals([0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0], array);
    Expect.throws(() {
      array[-1] = 0.0;
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      return array[-1];
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      array[10];
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      array[10] = 0.0;
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      array.add(0.0);
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      array.addAll([0.0]);
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      array.clear();
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      array.length = 0;
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      array.removeLast();
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      array.removeRange(0, array.length - 1);
    }, (e) {
      return e is UnsupportedError;
    });
    for (int i = 0; i < array.length; ++i) {
      array[i] = 1.0 + i;
    }
    Expect
        .listEquals([1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0], array);
    // TODO: min, max
    for (int i = 0; i < array.length; ++i) {
      array[i] = i * 1.0;
    }
    var copy = array.sublist(0, array.length);
    Expect.isFalse(identical(copy, array));
    Expect.isTrue(copy is Float64List);
    Expect.equals(10, copy.length);
    Expect.listEquals(array, copy);
    var empty = array.sublist(array.length, array.length);
    Expect.equals(0, empty.length);
    var region = array.sublist(3, array.length - 3);
    Expect.isTrue(copy is Float64List);
    Expect.equals(4, region.length);
    Expect.listEquals([3.0, 4.0, 5.0, 6.0], region);
    array.setRange(3, 7, [double.negativeInfinity, 0.0, 1.0, double.infinity]);
    Expect.listEquals([
      0.0,
      1.0,
      2.0,
      double.negativeInfinity,
      0.0,
      1.0,
      double.infinity,
      7.0,
      8.0,
      9.0
    ], array);
  }

  static testFloat64List() {
    Expect.throws(() {
      new Float64List(-1);
    }, (e) {
      return e is ArgumentError;
    });
    var array = new Float64List(10);
    testFloat64ListImpl(array);
  }

  static testInt8ListViewImpl(var array) {
    Expect.equals(12, array.length);
    Expect.equals(1, array.elementSizeInBytes);
    Expect.equals(12, array.lengthInBytes);
    for (int i = 0; i < array.length; ++i) {
      array[i] = 0xFF;
    }
    Expect.throws(() {
      new Int8List.view(array.buffer, -1);
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      new Int8List.view(array.buffer, 0, -1);
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      new Int8List.view(array.buffer, array.lengthInBytes + 1);
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      new Int8List.view(array.buffer, 0, array.length + 1);
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      new Int8List.view(array.buffer, array.length - 1, 2);
    }, (e) {
      return e is RangeError;
    });
    var empty = new Int8List.view(array.buffer, array.lengthInBytes);
    Expect.isTrue(empty is List<int>);
    Expect.isTrue(empty is Int8List);
    Expect.equals(0, empty.length);
    var whole = new Int8List.view(array.buffer);
    Expect.isTrue(whole is List<int>);
    Expect.isTrue(whole is Int8List);
    Expect.equals(12, whole.length);
    var view = new Int8List.view(array.buffer, 1, array.length - 2);
    Expect.isTrue(view is List<int>);
    Expect.isTrue(view is Int8List);
    Expect.equals(10, view.length);
    Expect.equals(1, view.elementSizeInBytes);
    Expect.equals(10, view.lengthInBytes);
    Expect.listEquals([-1, -1, -1, -1, -1, -1, -1, -1, -1, -1], view);
    Expect.throws(() {
      view[-1] = 0;
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      return view[-1];
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      view[view.length];
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      view[10] = 0;
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      view.add(0);
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      view.addAll([0]);
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      view.clear();
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      view.length = 0;
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      view.removeLast();
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      view.removeRange(0, view.length - 1);
    }, (e) {
      return e is UnsupportedError;
    });
    for (int i = 0; i < view.length; ++i) {
      view[i] = 1 + i;
    }
    Expect.listEquals([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], view);
    Expect.listEquals([0xFF, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 0xFF], array);
    for (int i = 0; i < view.length; ++i) {
      view[i] = 0x100 + i;
    }
    Expect.listEquals([0, 1, 2, 3, 4, 5, 6, 7, 8, 9], view);
    Expect.listEquals([0xFF, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0xFF], array);
    for (int i = 0; i < view.length; ++i) {
      view[i] = -10 + i;
    }
    Expect.listEquals([-10, -9, -8, -7, -6, -5, -4, -3, -2, -1], view);
    Expect.listEquals([
      0xFF,
      0xF6,
      0xF7,
      0xF8,
      0xF9,
      0xFA,
      0xFB,
      0xFC,
      0xFD,
      0xFE,
      0xFF,
      0xFF
    ], array);
    for (int i = 0; i < view.length; ++i) {
      view[i] = 0x7F - i;
    }
    Expect.listEquals([127, 126, 125, 124, 123, 122, 121, 120, 119, 118], view);
    Expect.listEquals(
        [0xFF, 127, 126, 125, 124, 123, 122, 121, 120, 119, 118, 0xFF], array);
    for (int i = 0; i < view.length; ++i) {
      view[i] = -0x80 + i;
    }
    Expect.listEquals(
        [-128, -127, -126, -125, -124, -123, -122, -121, -120, -119], view);
    Expect.listEquals([
      0xFF,
      0x80,
      0x81,
      0x82,
      0x83,
      0x84,
      0x85,
      0x86,
      0x87,
      0x88,
      0x89,
      0xFF
    ], array);
    for (int i = 0; i < view.length; ++i) {
      view[i] = i;
    }
    var copy = view.sublist(0, view.length);
    Expect.isFalse(identical(copy, view));
    Expect.isTrue(copy is Int8List);
    Expect.equals(10, copy.length);
    Expect.listEquals(view, copy);
    var region = view.sublist(3, view.length - 3);
    Expect.isTrue(copy is Int8List);
    Expect.equals(4, region.length);
    Expect.listEquals([3, 4, 5, 6], region);
    view.setRange(3, 7, [-128, 0, 1, 127]);
    Expect.listEquals([0, 1, 2, -128, 0, 1, 127, 7, 8, 9], view);
    Expect.listEquals([0xFF, 0, 1, 2, 128, 0, 1, 127, 7, 8, 9, 0xFF], array);
  }

  static testInt8ListView() {
    var array = new Uint8List(12);
    testInt8ListViewImpl(array);
  }

  static testUint8ListViewImpl(var array) {
    Expect.isTrue(array is List<int>);
    Expect.equals(12, array.length);
    Expect.equals(1, array.elementSizeInBytes);
    Expect.equals(12, array.lengthInBytes);
    for (int i = 0; i < array.length; ++i) {
      array[i] = -1;
    }
    Expect.throws(() {
      new Uint8List.view(array.buffer, -1);
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      new Uint8List.view(array.buffer, 0, -1);
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      new Uint8List.view(array.buffer, array.lengthInBytes + 1);
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      new Uint8List.view(array.buffer, 0, array.length + 1);
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      new Uint8List.view(array.buffer, array.length - 1, 2);
    }, (e) {
      return e is RangeError;
    });
    var empty = new Uint8List.view(array.buffer, array.lengthInBytes);
    Expect.isTrue(empty is List<int>);
    Expect.isTrue(empty is Uint8List);
    Expect.equals(0, empty.length);
    var whole = new Uint8List.view(array.buffer);
    Expect.isTrue(whole is List<int>);
    Expect.isTrue(whole is Uint8List);
    Expect.equals(12, whole.length);
    var view = new Uint8List.view(array.buffer, 1, array.length - 2);
    Expect.isTrue(view is List<int>);
    Expect.isTrue(view is Uint8List);
    Expect.equals(10, view.length);
    Expect.equals(1, view.elementSizeInBytes);
    Expect.equals(10, view.lengthInBytes);
    Expect.listEquals(
        [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF], view);
    Expect.throws(() {
      view[-1] = 0;
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      return view[-1];
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      view[view.length];
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      view[view.length] = 0;
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      view.add(0);
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      view.addAll([0]);
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      view.clear();
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      view.length = 0;
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      view.removeLast();
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      view.removeRange(0, view.length - 1);
    }, (e) {
      return e is UnsupportedError;
    });
    for (int i = 0; i < view.length; ++i) {
      view[i] = 1 + i;
    }
    Expect.listEquals([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], view);
    Expect.listEquals([-1, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, -1], array);
    for (int i = 0; i < view.length; ++i) {
      view[i] = 0x100 + i;
    }
    Expect.listEquals([0, 1, 2, 3, 4, 5, 6, 7, 8, 9], view);
    Expect.listEquals([-1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, -1], array);
    for (int i = 0; i < view.length; ++i) {
      view[i] = 0xFF - i;
    }
    Expect.listEquals(
        [0xFF, 0xFE, 0xFD, 0xFC, 0xFB, 0xFA, 0xF9, 0xF8, 0xF7, 0xF6], view);
    Expect.listEquals([-1, -1, -2, -3, -4, -5, -6, -7, -8, -9, -10, -1], array);
    for (int i = 0; i < view.length; ++i) {
      view[i] = i;
    }
    var copy = view.sublist(0, view.length);
    Expect.isFalse(identical(copy, view));
    Expect.isTrue(copy is Uint8List);
    Expect.equals(10, copy.length);
    Expect.listEquals(view, copy);
    var region = view.sublist(3, view.length - 3);
    Expect.isTrue(copy is Uint8List);
    Expect.equals(4, region.length);
    Expect.listEquals([3, 4, 5, 6], region);
    view.setRange(3, 7, [257, 0, 1, 255]);
    Expect.listEquals([0, 1, 2, 1, 0, 1, 255, 7, 8, 9], view);
  }

  static testUint8ListView() {
    var array = new Int8List(12);
    testUint8ListViewImpl(array);
  }

  static testInt16ListViewImpl(var array) {
    Expect.equals(24, array.length);
    Expect.equals(1, array.elementSizeInBytes);
    Expect.equals(24, array.lengthInBytes);
    for (int i = 0; i < array.length; ++i) {
      array[i] = 0xFF;
    }
    Expect.throws(() {
      new Int16List.view(array.buffer, -1);
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      new Int16List.view(array.buffer, 0, -1);
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      new Int16List.view(array.buffer, array.lengthInBytes + 1);
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      new Int16List.view(array.buffer, 0, array.length + 1);
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      new Int16List.view(array.buffer, array.length - 1, 2);
    }, (e) {
      return e is RangeError;
    });
    var empty = new Int16List.view(array.buffer, array.lengthInBytes);
    Expect.isTrue(empty is List<int>);
    Expect.isTrue(empty is Int16List);
    Expect.equals(0, empty.length);
    var whole = new Int16List.view(array.buffer);
    Expect.isTrue(whole is List<int>);
    Expect.isTrue(whole is Int16List);
    Expect.equals(12, whole.length);
    var view = new Int16List.view(array.buffer, 2, 10);
    Expect.isTrue(view is List<int>);
    Expect.isTrue(view is Int16List);
    Expect.equals(10, view.length);
    Expect.equals(2, view.elementSizeInBytes);
    Expect.equals(20, view.lengthInBytes);
    Expect.listEquals([-1, -1, -1, -1, -1, -1, -1, -1, -1, -1], view);
    Expect.throws(() {
      view[-1] = 0;
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      return view[-1];
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      view[view.length];
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      view[10] = 0;
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      view.add(0);
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      view.addAll([0]);
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      view.clear();
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      view.length = 0;
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      view.removeLast();
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      view.removeRange(0, view.length - 1);
    }, (e) {
      return e is UnsupportedError;
    });
    for (int i = 0; i < view.length; ++i) {
      view[i] = 1 + i;
    }
    Expect.listEquals([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], view);
    Expect.listEquals([
      0xFF,
      0xFF,
      0x01,
      0x00,
      0x02,
      0x00,
      0x03,
      0x00,
      0x04,
      0x00,
      0x05,
      0x00,
      0x06,
      0x00,
      0x07,
      0x00,
      0x08,
      0x00,
      0x09,
      0x00,
      0x0A,
      0x00,
      0xFF,
      0xFF
    ], array);
    for (int i = 0; i < view.length; ++i) {
      view[i] = 0x10000 + i;
    }
    Expect.listEquals([0, 1, 2, 3, 4, 5, 6, 7, 8, 9], view);
    Expect.listEquals([
      0xFF,
      0xFF,
      0x00,
      0x00,
      0x01,
      0x00,
      0x02,
      0x00,
      0x03,
      0x00,
      0x04,
      0x00,
      0x05,
      0x00,
      0x06,
      0x00,
      0x07,
      0x00,
      0x08,
      0x00,
      0x09,
      0x00,
      0xFF,
      0xFF
    ], array);
    for (int i = 0; i < view.length; ++i) {
      view[i] = -10 + i;
    }
    Expect.listEquals([-10, -9, -8, -7, -6, -5, -4, -3, -2, -1], view);
    Expect.listEquals([
      0xFF,
      0xFF,
      0xF6,
      0xFF,
      0xF7,
      0xFF,
      0xF8,
      0xFF,
      0xF9,
      0xFF,
      0xFA,
      0xFF,
      0xFB,
      0xFF,
      0xFC,
      0xFF,
      0xFD,
      0xFF,
      0xFE,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF
    ], array);
    for (int i = 0; i < view.length; ++i) {
      view[i] = 0x7FFF - i;
    }
    Expect.listEquals([
      0x7FFF,
      0x7FFE,
      0x7FFD,
      0x7FFC,
      0x7FFB,
      0x7FFA,
      0x7FF9,
      0x7FF8,
      0x7FF7,
      0x7FF6
    ], view);
    Expect.listEquals([
      0xFF,
      0xFF,
      0xFF,
      0x7F,
      0xFE,
      0x7F,
      0xFD,
      0x7F,
      0xFC,
      0x7F,
      0xFB,
      0x7F,
      0xFA,
      0x7F,
      0xF9,
      0x7F,
      0xF8,
      0x7F,
      0xF7,
      0x7F,
      0xF6,
      0x7F,
      0xFF,
      0xFF
    ], array);
    for (int i = 0; i < view.length; ++i) {
      view[i] = -0x8000 + i;
    }
    Expect.listEquals([
      -0x8000,
      -0x7FFF,
      -0x7FFE,
      -0x7FFD,
      -0x7FFC,
      -0x7FFB,
      -0x7FFA,
      -0x7FF9,
      -0x7FF8,
      -0x7FF7
    ], view);
    Expect.listEquals([
      0xFF,
      0xFF,
      0x00,
      0x80,
      0x01,
      0x80,
      0x02,
      0x80,
      0x03,
      0x80,
      0x04,
      0x80,
      0x05,
      0x80,
      0x06,
      0x80,
      0x07,
      0x80,
      0x08,
      0x80,
      0x09,
      0x80,
      0xFF,
      0xFF
    ], array);
    for (int i = 0; i < view.length; ++i) {
      view[i] = i;
    }
    var copy = view.sublist(0, view.length);
    Expect.isFalse(identical(copy, view));
    Expect.isTrue(copy is Int16List);
    Expect.equals(10, copy.length);
    Expect.listEquals(view, copy);
    var region = view.sublist(3, view.length - 3);
    Expect.isTrue(copy is Int16List);
    Expect.equals(4, region.length);
    Expect.listEquals([3, 4, 5, 6], region);
    view.setRange(3, 7, [-32768, 0, 1, 32767]);
    Expect.listEquals([0, 1, 2, -32768, 0, 1, 32767, 7, 8, 9], view);
    Expect.listEquals([
      0xFF,
      0xFF,
      0x00,
      0x00,
      0x01,
      0x00,
      0x02,
      0x00,
      0x00,
      0x80,
      0x00,
      0x00,
      0x01,
      0x00,
      0xFF,
      0x7F,
      0x07,
      0x00,
      0x08,
      0x00,
      0x09,
      0x00,
      0xFF,
      0xFF
    ], array);
  }

  static testInt16ListView() {
    var array = new Uint8List(24);
    testInt16ListViewImpl(array);
  }

  static testUint16ListViewImpl(var array) {
    Expect.isTrue(array is List<int>);
    Expect.equals(24, array.length);
    Expect.equals(1, array.elementSizeInBytes);
    Expect.equals(24, array.lengthInBytes);
    for (int i = 0; i < array.length; ++i) {
      array[i] = -1;
    }
    Expect.throws(() {
      new Uint16List.view(array.buffer, -1);
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      new Uint16List.view(array.buffer, 0, -1);
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      new Uint16List.view(array.buffer, array.lengthInBytes + 1);
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      new Uint16List.view(array.buffer, 0, array.length + 1);
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      new Uint16List.view(array.buffer, array.length - 1, 2);
    }, (e) {
      return e is RangeError;
    });
    var empty = new Uint16List.view(array.buffer, array.lengthInBytes);
    Expect.isTrue(empty is List<int>);
    Expect.isTrue(empty is Uint16List);
    Expect.equals(0, empty.length);
    var whole = new Uint16List.view(array.buffer);
    Expect.isTrue(whole is List<int>);
    Expect.isTrue(whole is Uint16List);
    Expect.equals(12, whole.length);
    var view = new Uint16List.view(array.buffer, 2, 10);
    Expect.isTrue(view is List<int>);
    Expect.isTrue(view is Uint16List);
    Expect.equals(10, view.length);
    Expect.equals(2, view.elementSizeInBytes);
    Expect.equals(20, view.lengthInBytes);
    Expect.listEquals([
      0xFFFF,
      0xFFFF,
      0xFFFF,
      0xFFFF,
      0xFFFF,
      0xFFFF,
      0xFFFF,
      0xFFFF,
      0xFFFF,
      0xFFFF
    ], view);
    Expect.throws(() {
      view[-1] = 0;
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      return view[-1];
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      view[view.length];
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      view[view.length] = 0;
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      view.add(0);
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      view.addAll([0]);
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      view.clear();
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      view.length = 0;
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      view.removeLast();
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      view.removeRange(0, view.length - 1);
    }, (e) {
      return e is UnsupportedError;
    });
    for (int i = 0; i < view.length; ++i) {
      view[i] = 1 + i;
    }
    Expect.listEquals([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], view);
    Expect.listEquals([
      -1,
      -1,
      1,
      0,
      2,
      0,
      3,
      0,
      4,
      0,
      5,
      0,
      6,
      0,
      7,
      0,
      8,
      0,
      9,
      0,
      10,
      0,
      -1,
      -1
    ], array);
    for (int i = 0; i < view.length; ++i) {
      view[i] = 0x10000 + i;
    }
    Expect.listEquals([0, 1, 2, 3, 4, 5, 6, 7, 8, 9], view);
    Expect.listEquals([
      -1,
      -1,
      0,
      0,
      1,
      0,
      2,
      0,
      3,
      0,
      4,
      0,
      5,
      0,
      6,
      0,
      7,
      0,
      8,
      0,
      9,
      0,
      -1,
      -1
    ], array);
    for (int i = 0; i < view.length; ++i) {
      view[i] = 0xFFFF - i;
    }
    Expect.listEquals([
      0xFFFF,
      0xFFFE,
      0xFFFD,
      0xFFFC,
      0xFFFB,
      0xFFFA,
      0xFFF9,
      0xFFF8,
      0xFFF7,
      0xFFF6
    ], view);
    Expect.listEquals([
      -1,
      -1,
      -1,
      -1,
      -2,
      -1,
      -3,
      -1,
      -4,
      -1,
      -5,
      -1,
      -6,
      -1,
      -7,
      -1,
      -8,
      -1,
      -9,
      -1,
      -10,
      -1,
      -1,
      -1
    ], array);
    for (int i = 0; i < view.length; ++i) {
      view[i] = i;
    }
    var copy = view.sublist(0, view.length);
    Expect.isFalse(identical(copy, view));
    Expect.isTrue(copy is Uint16List);
    Expect.equals(10, copy.length);
    Expect.listEquals(view, copy);
    var region = view.sublist(3, view.length - 3);
    Expect.isTrue(copy is Uint16List);
    Expect.equals(4, region.length);
    Expect.listEquals([3, 4, 5, 6], region);
    view.setRange(3, 7, [0x10001, 0, 1, 0xFFFF]);
    Expect.listEquals([0, 1, 2, 1, 0, 1, 0xFFFF, 7, 8, 9], view);
    Expect.listEquals([
      -1,
      -1,
      0,
      0,
      1,
      0,
      2,
      0,
      1,
      0,
      0,
      0,
      1,
      0,
      -1,
      -1,
      7,
      0,
      8,
      0,
      9,
      0,
      -1,
      -1
    ], array);
  }

  static testUint16ListView() {
    var array = new Int8List(24);
    testUint16ListViewImpl(array);
  }

  static testInt32ListView() {
    var array = new Uint8List(48);
    Expect.equals(48, array.length);
    Expect.equals(1, array.elementSizeInBytes);
    Expect.equals(48, array.lengthInBytes);
    for (int i = 0; i < array.length; ++i) {
      array[i] = 0xFF;
    }
    Expect.throws(() {
      new Int32List.view(array.buffer, -1);
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      new Int32List.view(array.buffer, 0, -1);
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      new Int32List.view(array.buffer, array.lengthInBytes + 1);
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      new Int32List.view(array.buffer, 0, array.length + 1);
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      new Int32List.view(array.buffer, array.length - 1, 2);
    }, (e) {
      return e is RangeError;
    });
    var empty = new Int32List.view(array.buffer, array.lengthInBytes);
    Expect.isTrue(empty is List<int>);
    Expect.isTrue(empty is Int32List);
    Expect.equals(0, empty.length);
    var whole = new Int32List.view(array.buffer);
    Expect.isTrue(whole is List<int>);
    Expect.isTrue(whole is Int32List);
    Expect.equals(12, whole.length);
    var view = new Int32List.view(array.buffer, 4, 10);
    Expect.isTrue(view is List<int>);
    Expect.isTrue(view is Int32List);
    Expect.equals(10, view.length);
    Expect.equals(4, view.elementSizeInBytes);
    Expect.equals(40, view.lengthInBytes);
    Expect.listEquals([-1, -1, -1, -1, -1, -1, -1, -1, -1, -1], view);
    Expect.throws(() {
      view[-1] = 0;
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      return view[-1];
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      view[view.length];
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      view[10] = 0;
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      view.add(0);
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      view.addAll([0]);
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      view.clear();
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      view.length = 0;
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      view.removeLast();
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      view.removeRange(0, view.length - 1);
    }, (e) {
      return e is UnsupportedError;
    });
    for (int i = 0; i < view.length; ++i) {
      view[i] = 1 + i;
    }
    Expect.listEquals([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], view);
    Expect.listEquals([
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0x01,
      0x00,
      0x00,
      0x00,
      0x02,
      0x00,
      0x00,
      0x00,
      0x03,
      0x00,
      0x00,
      0x00,
      0x04,
      0x00,
      0x00,
      0x00,
      0x05,
      0x00,
      0x00,
      0x00,
      0x06,
      0x00,
      0x00,
      0x00,
      0x07,
      0x00,
      0x00,
      0x00,
      0x08,
      0x00,
      0x00,
      0x00,
      0x09,
      0x00,
      0x00,
      0x00,
      0x0A,
      0x00,
      0x00,
      0x00,
      0xFF,
      0xFF,
      0xFF,
      0xFF
    ], array);
    for (int i = 0; i < view.length; ++i) {
      view[i] = 0x100000000 + i;
    }
    Expect.listEquals([0, 1, 2, 3, 4, 5, 6, 7, 8, 9], view);
    Expect.listEquals([
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0x00,
      0x00,
      0x00,
      0x00,
      0x01,
      0x00,
      0x00,
      0x00,
      0x02,
      0x00,
      0x00,
      0x00,
      0x03,
      0x00,
      0x00,
      0x00,
      0x04,
      0x00,
      0x00,
      0x00,
      0x05,
      0x00,
      0x00,
      0x00,
      0x06,
      0x00,
      0x00,
      0x00,
      0x07,
      0x00,
      0x00,
      0x00,
      0x08,
      0x00,
      0x00,
      0x00,
      0x09,
      0x00,
      0x00,
      0x00,
      0xFF,
      0xFF,
      0xFF,
      0xFF
    ], array);
    for (int i = 0; i < view.length; ++i) {
      view[i] = -10 + i;
    }
    Expect.listEquals([-10, -9, -8, -7, -6, -5, -4, -3, -2, -1], view);
    Expect.listEquals([
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xF6,
      0xFF,
      0xFF,
      0xFF,
      0xF7,
      0xFF,
      0xFF,
      0xFF,
      0xF8,
      0xFF,
      0xFF,
      0xFF,
      0xF9,
      0xFF,
      0xFF,
      0xFF,
      0xFA,
      0xFF,
      0xFF,
      0xFF,
      0xFB,
      0xFF,
      0xFF,
      0xFF,
      0xFC,
      0xFF,
      0xFF,
      0xFF,
      0xFD,
      0xFF,
      0xFF,
      0xFF,
      0xFE,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF
    ], array);
    for (int i = 0; i < view.length; ++i) {
      view[i] = 0x7FFFFFFF - i;
    }
    Expect.listEquals([
      0x7FFFFFFF,
      0x7FFFFFFE,
      0x7FFFFFFD,
      0x7FFFFFFC,
      0x7FFFFFFB,
      0x7FFFFFFA,
      0x7FFFFFF9,
      0x7FFFFFF8,
      0x7FFFFFF7,
      0x7FFFFFF6
    ], view);
    Expect.listEquals([
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0x7F,
      0xFE,
      0xFF,
      0xFF,
      0x7F,
      0xFD,
      0xFF,
      0xFF,
      0x7F,
      0xFC,
      0xFF,
      0xFF,
      0x7F,
      0xFB,
      0xFF,
      0xFF,
      0x7F,
      0xFA,
      0xFF,
      0xFF,
      0x7F,
      0xF9,
      0xFF,
      0xFF,
      0x7F,
      0xF8,
      0xFF,
      0xFF,
      0x7F,
      0xF7,
      0xFF,
      0xFF,
      0x7F,
      0xF6,
      0xFF,
      0xFF,
      0x7F,
      0xFF,
      0xFF,
      0xFF,
      0xFF
    ], array);
    for (int i = 0; i < view.length; ++i) {
      view[i] = -0x80000000 + i;
    }
    Expect.listEquals([
      -0x80000000,
      -0x7FFFFFFF,
      -0x7FFFFFFE,
      -0x7FFFFFFD,
      -0x7FFFFFFC,
      -0x7FFFFFFB,
      -0x7FFFFFFA,
      -0x7FFFFFF9,
      -0x7FFFFFF8,
      -0x7FFFFFF7
    ], view);
    Expect.listEquals([
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0x00,
      0x00,
      0x00,
      0x80,
      0x01,
      0x00,
      0x00,
      0x80,
      0x02,
      0x00,
      0x00,
      0x80,
      0x03,
      0x00,
      0x00,
      0x80,
      0x04,
      0x00,
      0x00,
      0x80,
      0x05,
      0x00,
      0x00,
      0x80,
      0x06,
      0x00,
      0x00,
      0x80,
      0x07,
      0x00,
      0x00,
      0x80,
      0x08,
      0x00,
      0x00,
      0x80,
      0x09,
      0x00,
      0x00,
      0x80,
      0xFF,
      0xFF,
      0xFF,
      0xFF
    ], array);
    for (int i = 0; i < view.length; ++i) {
      view[i] = i;
    }
    var copy = view.sublist(0, view.length);
    Expect.isFalse(identical(copy, view));
    Expect.isTrue(copy is Int32List);
    Expect.equals(10, copy.length);
    Expect.listEquals(view, copy);
    var region = view.sublist(3, view.length - 3);
    Expect.isTrue(copy is Int32List);
    Expect.equals(4, region.length);
    Expect.listEquals([3, 4, 5, 6], region);
    view.setRange(3, 7, [-0x80000000, 0, 1, 0x7FFFFFFF]);
    Expect.listEquals([0, 1, 2, -0x80000000, 0, 1, 0x7FFFFFFF, 7, 8, 9], view);
    Expect.listEquals([
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0x00,
      0x00,
      0x00,
      0x00,
      0x01,
      0x00,
      0x00,
      0x00,
      0x02,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x80,
      0x00,
      0x00,
      0x00,
      0x00,
      0x01,
      0x00,
      0x00,
      0x00,
      0xFF,
      0xFF,
      0xFF,
      0x7F,
      0x07,
      0x00,
      0x00,
      0x00,
      0x08,
      0x00,
      0x00,
      0x00,
      0x09,
      0x00,
      0x00,
      0x00,
      0xFF,
      0xFF,
      0xFF,
      0xFF
    ], array);
  }

  static testUint32ListViewImpl(var array) {
    Expect.isTrue(array is List<int>);
    Expect.equals(48, array.length);
    Expect.equals(1, array.elementSizeInBytes);
    Expect.equals(48, array.lengthInBytes);
    for (int i = 0; i < array.length; ++i) {
      array[i] = -1;
    }
    Expect.throws(() {
      new Uint32List.view(array.buffer, -1);
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      new Uint32List.view(array.buffer, 0, -1);
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      new Uint32List.view(array.buffer, array.lengthInBytes + 1);
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      new Uint32List.view(array.buffer, 0, array.length + 1);
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      new Uint32List.view(array.buffer, array.length - 1, 2);
    }, (e) {
      return e is RangeError;
    });
    var empty = new Uint32List.view(array.buffer, array.lengthInBytes);
    Expect.isTrue(empty is List<int>);
    Expect.isTrue(empty is Uint32List);
    Expect.equals(0, empty.length);
    var whole = new Uint32List.view(array.buffer);
    Expect.isTrue(whole is List<int>);
    Expect.isTrue(whole is Uint32List);
    Expect.equals(12, whole.length);
    var view = new Uint32List.view(array.buffer, 4, 10);
    Expect.isTrue(view is List<int>);
    Expect.isTrue(view is Uint32List);
    Expect.equals(10, view.length);
    Expect.equals(4, view.elementSizeInBytes);
    Expect.equals(40, view.lengthInBytes);
    Expect.listEquals([
      0xFFFFFFFF,
      0xFFFFFFFF,
      0xFFFFFFFF,
      0xFFFFFFFF,
      0xFFFFFFFF,
      0xFFFFFFFF,
      0xFFFFFFFF,
      0xFFFFFFFF,
      0xFFFFFFFF,
      0xFFFFFFFF
    ], view);
    Expect.throws(() {
      view[-1] = 0;
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      return view[-1];
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      view[view.length];
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      view[view.length] = 0;
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      view.add(0);
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      view.addAll([0]);
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      view.clear();
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      view.length = 0;
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      view.removeLast();
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      view.removeRange(0, view.length - 1);
    }, (e) {
      return e is UnsupportedError;
    });
    for (int i = 0; i < view.length; ++i) {
      view[i] = 1 + i;
    }
    Expect.listEquals([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], view);
    Expect.listEquals([
      -1,
      -1,
      -1,
      -1,
      1,
      0,
      0,
      0,
      2,
      0,
      0,
      0,
      3,
      0,
      0,
      0,
      4,
      0,
      0,
      0,
      5,
      0,
      0,
      0,
      6,
      0,
      0,
      0,
      7,
      0,
      0,
      0,
      8,
      0,
      0,
      0,
      9,
      0,
      0,
      0,
      10,
      0,
      0,
      0,
      -1,
      -1,
      -1,
      -1
    ], array);
    for (int i = 0; i < view.length; ++i) {
      view[i] = 0x100000000 + i;
    }
    Expect.listEquals([0, 1, 2, 3, 4, 5, 6, 7, 8, 9], view);
    Expect.listEquals([
      -1,
      -1,
      -1,
      -1,
      0,
      0,
      0,
      0,
      1,
      0,
      0,
      0,
      2,
      0,
      0,
      0,
      3,
      0,
      0,
      0,
      4,
      0,
      0,
      0,
      5,
      0,
      0,
      0,
      6,
      0,
      0,
      0,
      7,
      0,
      0,
      0,
      8,
      0,
      0,
      0,
      9,
      0,
      0,
      0,
      -1,
      -1,
      -1,
      -1
    ], array);
    for (int i = 0; i < view.length; ++i) {
      view[i] = 0xFFFFFFFF - i;
    }
    Expect.listEquals([
      0xFFFFFFFF,
      0xFFFFFFFE,
      0xFFFFFFFD,
      0xFFFFFFFC,
      0xFFFFFFFB,
      0xFFFFFFFA,
      0xFFFFFFF9,
      0xFFFFFFF8,
      0xFFFFFFF7,
      0xFFFFFFF6
    ], view);
    Expect.listEquals([
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -2,
      -1,
      -1,
      -1,
      -3,
      -1,
      -1,
      -1,
      -4,
      -1,
      -1,
      -1,
      -5,
      -1,
      -1,
      -1,
      -6,
      -1,
      -1,
      -1,
      -7,
      -1,
      -1,
      -1,
      -8,
      -1,
      -1,
      -1,
      -9,
      -1,
      -1,
      -1,
      -10,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1
    ], array);
    for (int i = 0; i < view.length; ++i) {
      view[i] = i;
    }
    var copy = view.sublist(0, view.length);
    Expect.isFalse(identical(copy, view));
    Expect.isTrue(copy is Uint32List);
    Expect.equals(10, copy.length);
    Expect.listEquals(view, copy);
    var region = view.sublist(3, view.length - 3);
    Expect.isTrue(copy is Uint32List);
    Expect.equals(4, region.length);
    Expect.listEquals([3, 4, 5, 6], region);
    view.setRange(3, 7, [0x100000001, 0, 1, 0xFFFFFFFF]);
    Expect.listEquals([0, 1, 2, 1, 0, 1, 0xFFFFFFFF, 7, 8, 9], view);
    Expect.listEquals([
      -1,
      -1,
      -1,
      -1,
      0,
      0,
      0,
      0,
      1,
      0,
      0,
      0,
      2,
      0,
      0,
      0,
      1,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
      0,
      0,
      -1,
      -1,
      -1,
      -1,
      7,
      0,
      0,
      0,
      8,
      0,
      0,
      0,
      9,
      0,
      0,
      0,
      -1,
      -1,
      -1,
      -1
    ], array);
  }

  static testUint32ListView() {
    var array = new Int8List(48);
    testUint32ListViewImpl(array);
  }

  static testInt64ListViewImpl(var array) {
    Expect.equals(96, array.length);
    Expect.equals(1, array.elementSizeInBytes);
    Expect.equals(96, array.lengthInBytes);
    for (int i = 0; i < array.length; ++i) {
      array[i] = 0xFF;
    }
    Expect.throws(() {
      new Int64List.view(array.buffer, -1);
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      new Int64List.view(array.buffer, 0, -1);
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      new Int64List.view(array.buffer, array.lengthInBytes + 1);
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      new Int64List.view(array.buffer, 0, array.length + 1);
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      new Int64List.view(array.buffer, array.length - 1, 2);
    }, (e) {
      return e is RangeError;
    });
    var empty = new Int64List.view(array.buffer, array.lengthInBytes);
    Expect.isTrue(empty is List<int>);
    Expect.isTrue(empty is Int64List);
    Expect.equals(0, empty.length);
    var whole = new Int64List.view(array.buffer);
    Expect.isTrue(whole is List<int>);
    Expect.isTrue(whole is Int64List);
    Expect.equals(12, whole.length);
    var view = new Int64List.view(array.buffer, 8, 10);
    Expect.isTrue(view is List<int>);
    Expect.isTrue(view is Int64List);
    Expect.equals(10, view.length);
    Expect.equals(8, view.elementSizeInBytes);
    Expect.equals(80, view.lengthInBytes);
    Expect.listEquals([-1, -1, -1, -1, -1, -1, -1, -1, -1, -1], view);
    Expect.throws(() {
      view[-1] = 0;
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      return view[-1];
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      view[view.length];
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      view[10] = 0;
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      view.add(0);
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      view.addAll([0]);
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      view.clear();
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      view.length = 0;
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      view.removeLast();
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      view.removeRange(0, view.length - 1);
    }, (e) {
      return e is UnsupportedError;
    });
    for (int i = 0; i < view.length; ++i) {
      view[i] = 1 + i;
    }
    Expect.listEquals([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], view);
    Expect.listEquals([
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0x01,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x02,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x03,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x04,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x05,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x06,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x07,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x08,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x09,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x0A,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF
    ], array);
    for (int i = 0; i < view.length; ++i) {
      view[i] = 0x10000000000000000 + i;
    }
    Expect.listEquals([0, 1, 2, 3, 4, 5, 6, 7, 8, 9], view);
    Expect.listEquals([
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x01,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x02,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x03,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x04,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x05,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x06,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x07,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x08,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x09,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF
    ], array);
    for (int i = 0; i < view.length; ++i) {
      view[i] = -10 + i;
    }
    Expect.listEquals([-10, -9, -8, -7, -6, -5, -4, -3, -2, -1], view);
    Expect.listEquals([
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xF6,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xF7,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xF8,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xF9,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFA,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFB,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFC,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFD,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFE,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF
    ], array);
    for (int i = 0; i < view.length; ++i) {
      view[i] = 0x7FFFFFFFFFFFFFFF - i;
    }
    Expect.listEquals([
      0x7FFFFFFFFFFFFFFF,
      0x7FFFFFFFFFFFFFFE,
      0x7FFFFFFFFFFFFFFD,
      0x7FFFFFFFFFFFFFFC,
      0x7FFFFFFFFFFFFFFB,
      0x7FFFFFFFFFFFFFFA,
      0x7FFFFFFFFFFFFFF9,
      0x7FFFFFFFFFFFFFF8,
      0x7FFFFFFFFFFFFFF7,
      0x7FFFFFFFFFFFFFF6
    ], view);
    Expect.listEquals([
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0x7F,
      0xFE,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0x7F,
      0xFD,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0x7F,
      0xFC,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0x7F,
      0xFB,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0x7F,
      0xFA,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0x7F,
      0xF9,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0x7F,
      0xF8,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0x7F,
      0xF7,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0x7F,
      0xF6,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0x7F,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF
    ], array);
    for (int i = 0; i < view.length; ++i) {
      view[i] = -0x8000000000000000 + i;
    }
    Expect.listEquals([
      -0x8000000000000000,
      -0x7FFFFFFFFFFFFFFF,
      -0x7FFFFFFFFFFFFFFE,
      -0x7FFFFFFFFFFFFFFD,
      -0x7FFFFFFFFFFFFFFC,
      -0x7FFFFFFFFFFFFFFB,
      -0x7FFFFFFFFFFFFFFA,
      -0x7FFFFFFFFFFFFFF9,
      -0x7FFFFFFFFFFFFFF8,
      -0x7FFFFFFFFFFFFFF7
    ], view);
    Expect.listEquals([
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x80,
      0x01,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x80,
      0x02,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x80,
      0x03,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x80,
      0x04,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x80,
      0x05,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x80,
      0x06,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x80,
      0x07,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x80,
      0x08,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x80,
      0x09,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x80,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF
    ], array);
    for (int i = 0; i < view.length; ++i) {
      view[i] = i;
    }
    var copy = view.sublist(0, view.length);
    Expect.isFalse(identical(copy, view));
    Expect.isTrue(copy is Int64List);
    Expect.equals(10, copy.length);
    Expect.listEquals(view, copy);
    var region = view.sublist(3, view.length - 3);
    Expect.isTrue(copy is Int64List);
    Expect.equals(4, region.length);
    Expect.listEquals([3, 4, 5, 6], region);
    view.setRange(3, 7, [-0x8000000000000000, 0, 1, 0x7FFFFFFFFFFFFFFF]);
    Expect.listEquals(
        [0, 1, 2, -0x8000000000000000, 0, 1, 0x7FFFFFFFFFFFFFFF, 7, 8, 9],
        view);
    Expect.listEquals([
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x01,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x02,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x80,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x01,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0x7F,
      0x07,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x08,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x09,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF
    ], array);
  }

  static testInt64ListView() {
    var array = new Uint8List(96);
    testInt64ListViewImpl(array);
  }

  static testUint64ListViewImpl(var array) {
    Expect.isTrue(array is List<int>);
    Expect.equals(96, array.length);
    Expect.equals(1, array.elementSizeInBytes);
    Expect.equals(96, array.lengthInBytes);
    for (int i = 0; i < array.length; ++i) {
      array[i] = -1;
    }
    Expect.throws(() {
      new Uint64List.view(array.buffer, -1);
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      new Uint64List.view(array.buffer, 0, -1);
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      new Uint64List.view(array.buffer, array.lengthInBytes + 1);
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      new Uint64List.view(array.buffer, 0, array.length + 1);
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      new Uint64List.view(array.buffer, array.length - 1, 2);
    }, (e) {
      return e is RangeError;
    });
    var empty = new Uint64List.view(array.buffer, array.lengthInBytes);
    Expect.isTrue(empty is List<int>);
    Expect.isTrue(empty is Uint64List);
    Expect.equals(0, empty.length);
    var whole = new Uint64List.view(array.buffer);
    Expect.isTrue(whole is List<int>);
    Expect.isTrue(whole is Uint64List);
    Expect.equals(12, whole.length);
    var view = new Uint64List.view(array.buffer, 8, 10);
    Expect.isTrue(view is List<int>);
    Expect.isTrue(view is Uint64List);
    Expect.equals(10, view.length);
    Expect.equals(8, view.elementSizeInBytes);
    Expect.equals(80, view.lengthInBytes);
    Expect.listEquals([
      0xFFFFFFFFFFFFFFFF,
      0xFFFFFFFFFFFFFFFF,
      0xFFFFFFFFFFFFFFFF,
      0xFFFFFFFFFFFFFFFF,
      0xFFFFFFFFFFFFFFFF,
      0xFFFFFFFFFFFFFFFF,
      0xFFFFFFFFFFFFFFFF,
      0xFFFFFFFFFFFFFFFF,
      0xFFFFFFFFFFFFFFFF,
      0xFFFFFFFFFFFFFFFF
    ], view);
    Expect.throws(() {
      view[-1] = 0;
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      return view[-1];
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      view[view.length];
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      view[view.length] = 0;
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      view.add(0);
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      view.addAll([0]);
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      view.clear();
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      view.length = 0;
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      view.removeLast();
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      view.removeRange(0, view.length - 1);
    }, (e) {
      return e is UnsupportedError;
    });
    for (int i = 0; i < view.length; ++i) {
      view[i] = 1 + i;
    }
    Expect.listEquals([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], view);
    Expect.listEquals([
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      1,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      2,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      3,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      4,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      5,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      6,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      7,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      8,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      9,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      10,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1
    ], array);
    for (int i = 0; i < view.length; ++i) {
      view[i] = 0x10000000000000000 + i;
    }
    Expect.listEquals([0, 1, 2, 3, 4, 5, 6, 7, 8, 9], view);
    Expect.listEquals([
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      2,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      3,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      4,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      5,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      6,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      7,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      8,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      9,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1
    ], array);
    for (int i = 0; i < view.length; ++i) {
      view[i] = 0xFFFFFFFFFFFFFFFF - i;
    }
    Expect.listEquals([
      0xFFFFFFFFFFFFFFFF,
      0xFFFFFFFFFFFFFFFE,
      0xFFFFFFFFFFFFFFFD,
      0xFFFFFFFFFFFFFFFC,
      0xFFFFFFFFFFFFFFFB,
      0xFFFFFFFFFFFFFFFA,
      0xFFFFFFFFFFFFFFF9,
      0xFFFFFFFFFFFFFFF8,
      0xFFFFFFFFFFFFFFF7,
      0xFFFFFFFFFFFFFFF6
    ], view);
    Expect.listEquals([
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -2,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -3,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -4,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -5,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -6,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -7,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -8,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -9,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -10,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1
    ], array);
    for (int i = 0; i < view.length; ++i) {
      view[i] = i;
    }
    var copy = view.sublist(0, view.length);
    Expect.isFalse(identical(copy, view));
    Expect.isTrue(copy is Uint64List);
    Expect.equals(10, copy.length);
    Expect.listEquals(view, copy);
    var region = view.sublist(3, view.length - 3);
    Expect.isTrue(copy is Uint64List);
    Expect.equals(4, region.length);
    Expect.listEquals([3, 4, 5, 6], region);
    view.setRange(3, 7, [0x10000000000000001, 0, 1, 0xFFFFFFFFFFFFFFFF]);
    Expect.listEquals([0, 1, 2, 1, 0, 1, 0xFFFFFFFFFFFFFFFF, 7, 8, 9], view);
    Expect.listEquals([
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      2,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      7,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      8,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      9,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1,
      -1
    ], array);
  }

  static testUint64ListView() {
    var array = new Int8List(96);
    testUint64ListViewImpl(array);
  }

  static testFloat32ListViewImpl(var array) {
    Expect.isTrue(array is List<int>);
    Expect.equals(12, array.length);
    Expect.equals(4, array.elementSizeInBytes);
    Expect.equals(48, array.lengthInBytes);
    for (int i = 0; i < array.length; ++i) {
      array[i] = 0xBF800000;
    }
    Expect.throws(() {
      new Float32List.view(array.buffer, -1);
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      new Float32List.view(array.buffer, 0, -1);
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      new Float32List.view(array.buffer, array.lengthInBytes + 1);
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      new Float32List.view(array.buffer, 0, array.lengthInBytes + 1);
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      new Float32List.view(array.buffer, array.lengthInBytes - 1, 2);
    }, (e) {
      return e is RangeError;
    });
    var empty = new Float32List.view(array.buffer, array.lengthInBytes);
    Expect.isTrue(empty is List<double>);
    Expect.isTrue(empty is Float32List);
    Expect.equals(0, empty.length);
    var whole = new Float32List.view(array.buffer);
    Expect.isTrue(whole is List<double>);
    Expect.isTrue(whole is Float32List);
    Expect.equals(12, whole.length);
    var view = new Float32List.view(array.buffer, 4, 10);
    Expect.isTrue(view is List<double>);
    Expect.isTrue(view is Float32List);
    Expect.equals(10, view.length);
    Expect.equals(4, view.elementSizeInBytes);
    Expect.equals(40, view.lengthInBytes);
    Expect.listEquals(
        [-1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0], view);
    Expect.throws(() {
      view[-1] = 0.0;
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      return view[-1];
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      view[10];
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      view[10] = 0.0;
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      view.add(0.0);
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      view.addAll([0.0]);
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      view.clear();
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      view.length = 0;
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      view.removeLast();
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      view.removeRange(0, array.length - 1);
    }, (e) {
      return e is UnsupportedError;
    });
    for (int i = 0; i < view.length; ++i) {
      view[i] = 1.0 + i;
    }
    Expect
        .listEquals([1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0], view);
    Expect.listEquals([
      0xBF800000,
      0x3F800000,
      0x40000000,
      0x40400000,
      0x40800000,
      0x40A00000,
      0x40C00000,
      0x40E00000,
      0x41000000,
      0x41100000,
      0x41200000,
      0xBF800000
    ], array);
    // TODO: min, max, and round
    for (int i = 0; i < view.length; ++i) {
      view[i] = i * 1.0;
    }
    var copy = view.sublist(0, view.length);
    Expect.isFalse(identical(copy, view));
    Expect.isTrue(copy is Float32List);
    Expect.equals(10, copy.length);
    Expect.listEquals(view, copy);
    var region = view.sublist(3, view.length - 3);
    Expect.isTrue(copy is Float32List);
    Expect.equals(4, region.length);
    Expect.listEquals([3.0, 4.0, 5.0, 6.0], region);
    view.setRange(3, 7, [double.negativeInfinity, 0.0, 1.0, double.infinity]);
    Expect.listEquals([
      0.0,
      1.0,
      2.0,
      double.negativeInfinity,
      0.0,
      1.0,
      double.infinity,
      7.0,
      8.0,
      9.0
    ], view);
    Expect.listEquals([
      0xBF800000,
      0x00000000,
      0x3F800000,
      0x40000000,
      0xFF800000,
      0x00000000,
      0x3F800000,
      0x7F800000,
      0x40E00000,
      0x41000000,
      0x41100000,
      0xBF800000
    ], array);
  }

  static testFloat32ListView() {
    var array = new Uint32List(12);
    testFloat32ListViewImpl(array);
  }

  static testFloat64ListViewImpl(var array) {
    Expect.isTrue(array is List<int>);
    Expect.equals(12, array.length);
    Expect.equals(8, array.elementSizeInBytes);
    Expect.equals(96, array.lengthInBytes);
    for (int i = 0; i < array.length; ++i) {
      array[i] = 0xBFF0000000000000;
    }
    Expect.throws(() {
      new Float64List.view(array.buffer, -1);
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      new Float64List.view(array.buffer, 0, -1);
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      new Float64List.view(array.buffer, array.lengthInBytes + 1);
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      new Float64List.view(array.buffer, 0, array.lengthInBytes + 1);
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      new Float64List.view(array.buffer, array.lengthInBytes - 1, 2);
    }, (e) {
      return e is RangeError;
    });
    var empty = new Float64List.view(array.buffer, array.lengthInBytes);
    Expect.isTrue(empty is List<double>);
    Expect.isTrue(empty is Float64List);
    Expect.equals(0, empty.length);
    var whole = new Float64List.view(array.buffer);
    Expect.isTrue(whole is List<double>);
    Expect.isTrue(whole is Float64List);
    Expect.equals(12, whole.length);
    var view = new Float64List.view(array.buffer, 8, 10);
    Expect.isTrue(view is List<double>);
    Expect.isTrue(view is Float64List);
    Expect.equals(10, view.length);
    Expect.equals(8, view.elementSizeInBytes);
    Expect.equals(80, view.lengthInBytes);
    Expect.listEquals(
        [-1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0], view);
    Expect.throws(() {
      view[-1] = 0.0;
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      return view[-1];
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      view[10];
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      view[10] = 0.0;
    }, (e) {
      return e is RangeError;
    });
    Expect.throws(() {
      view.add(0.0);
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      view.addAll([0.0]);
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      view.clear();
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      view.length = 0;
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      view.removeLast();
    }, (e) {
      return e is UnsupportedError;
    });
    Expect.throws(() {
      view.removeRange(0, array.length - 1);
    }, (e) {
      return e is UnsupportedError;
    });
    for (int i = 0; i < view.length; ++i) {
      view[i] = 1.0 + i;
    }
    Expect
        .listEquals([1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0], view);
    Expect.listEquals([
      0xBFF0000000000000,
      0x3FF0000000000000,
      0x4000000000000000,
      0x4008000000000000,
      0x4010000000000000,
      0x4014000000000000,
      0x4018000000000000,
      0x401C000000000000,
      0x4020000000000000,
      0x4022000000000000,
      0x4024000000000000,
      0xBFF0000000000000
    ], array);
    // TODO: min, max
    for (int i = 0; i < view.length; ++i) {
      view[i] = i * 1.0;
    }
    var copy = view.sublist(0, view.length);
    Expect.isFalse(identical(copy, view));
    Expect.isTrue(copy is Float64List);
    Expect.equals(10, copy.length);
    Expect.listEquals(view, copy);
    var region = view.sublist(3, view.length - 3);
    Expect.isTrue(copy is Float64List);
    Expect.equals(4, region.length);
    Expect.listEquals([3.0, 4.0, 5.0, 6.0], region);
    view.setRange(3, 7, [double.negativeInfinity, 0.0, 1.0, double.infinity]);
    Expect.listEquals([
      0.0,
      1.0,
      2.0,
      double.negativeInfinity,
      0.0,
      1.0,
      double.infinity,
      7.0,
      8.0,
      9.0
    ], view);
    Expect.listEquals([
      0xBFF0000000000000,
      0x0000000000000000,
      0x3FF0000000000000,
      0x4000000000000000,
      0xFFF0000000000000,
      0x0000000000000000,
      0x3FF0000000000000,
      0x7FF0000000000000,
      0x401C000000000000,
      0x4020000000000000,
      0x4022000000000000,
      0xBFF0000000000000
    ], array);
  }

  static testFloat64ListView() {
    var array = new Uint64List(12);
    testFloat64ListViewImpl(array);
  }

  static testMain() {
    testInt8List();
    testUint8List();
    testInt16List();
    testUint16List();
    testInt32List();
    testUint32List();
    testInt64List();
    testUint64List();
    testFloat32List();
    testFloat64List();
    //testByteList();
    testInt8ListView();
    testUint8ListView();
    testInt16ListView();
    testUint16ListView();
    testInt32ListView();
    testUint32ListView();
    testInt64ListView();
    testUint64ListView();
    testFloat32ListView();
    testFloat64ListView();
  }
}

main() {
  for (var i = 0; i < 20; i++) {
    OptimizedByteArrayTest.testMain();
  }
}
