// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing native float arrays.

// VMOptions=--optimization_counter_threshold=10 --no-background_compilation

// Library tag to be able to run in html test framework.
library FloatArrayTest;

import "package:expect/expect.dart";
import 'dart:typed_data';

void testCreateFloat32Array() {
  Float32List floatArray;

  floatArray = new Float32List(0);
  Expect.equals(0, floatArray.length);

  floatArray = new Float32List(10);
  Expect.equals(10, floatArray.length);
  for (int i = 0; i < 10; i++) {
    Expect.equals(0.0, floatArray[i]);
  }
}

void testSetRange32() {
  Float32List floatArray = new Float32List(3);

  List<double> list = [10.0, 11.0, 12.0];
  floatArray.setRange(0, 3, list);
  for (int i = 0; i < 3; i++) {
    Expect.equals(10 + i, floatArray[i]);
  }

  floatArray[0] = 20.0;
  floatArray[1] = 21.0;
  floatArray[2] = 22.0;
  list.setRange(0, 3, floatArray);
  for (int i = 0; i < 3; i++) {
    Expect.equals(20 + i, list[i]);
  }

  // 4.0e40 is larger than the largest representable float.
  floatArray.setRange(1, 3, const [8.0, 4.0e40]);
  Expect.equals(20, floatArray[0]);
  Expect.equals(8, floatArray[1]);
  Expect.equals(double.infinity, floatArray[2]);
}

void testIndexOutOfRange32() {
  Float32List floatArray = new Float32List(3);
  List<double> list = const [0.0, 1.0, 2.0, 3.0];

  Expect.throws(() {
    floatArray[5] = 2.0;
  });
  Expect.throws(() {
    floatArray.setRange(0, 4, list);
  });

  Expect.throws(() {
    floatArray.setRange(3, 4, list);
  });
}

void testIndexOf32() {
  var list = new Float32List(10);
  for (int i = 0; i < list.length; i++) {
    list[i] = i + 10.0;
  }
  Expect.equals(0, list.indexOf(10.0));
  Expect.equals(5, list.indexOf(15.0));
  Expect.equals(9, list.indexOf(19.0));
  Expect.equals(-1, list.indexOf(20.0));
}

void testCreateFloat64Array() {
  Float64List floatArray;

  floatArray = new Float64List(0);
  Expect.equals(0, floatArray.length);

  floatArray = new Float64List(10);
  Expect.equals(10, floatArray.length);
  for (int i = 0; i < 10; i++) {
    Expect.equals(0.0, floatArray[i]);
  }
}

void testSetRange64() {
  Float64List floatArray = new Float64List(3);

  List<double> list = [10.0, 11.0, 12.0];
  floatArray.setRange(0, 3, list);
  for (int i = 0; i < 3; i++) {
    Expect.equals(10 + i, floatArray[i]);
  }

  floatArray[0] = 20.0;
  floatArray[1] = 21.0;
  floatArray[2] = 22.0;
  list.setRange(0, 3, floatArray);
  for (int i = 0; i < 3; i++) {
    Expect.equals(20 + i, list[i]);
  }

  // Unlike Float32Array we can properly represent 4.0e40
  floatArray.setRange(1, 3, const [8.0, 4.0e40]);
  Expect.equals(20, floatArray[0]);
  Expect.equals(8, floatArray[1]);
  Expect.equals(4.0e40, floatArray[2]);
}

void testIndexOutOfRange64() {
  Float64List floatArray = new Float64List(3);
  List<double> list = const [0.0, 1.0, 2.0, 3.0];

  Expect.throws(() {
    floatArray[5] = 2.0;
  });
  Expect.throws(() {
    floatArray.setRange(0, 4, list);
  });

  Expect.throws(() {
    floatArray.setRange(3, 4, list);
  });
}

void testIndexOf64() {
  var list = new Float64List(10);
  for (int i = 0; i < list.length; i++) {
    list[i] = i + 10.0;
  }
  Expect.equals(0, list.indexOf(10.0));
  Expect.equals(5, list.indexOf(15.0));
  Expect.equals(9, list.indexOf(19.0));
  Expect.equals(-1, list.indexOf(20.0));
}

storeIt32(Float32List a, int index, value) {
  a[index] = value;
}

storeIt64(Float64List a, int index, value) {
  a[index] = value;
}

testPolymorphicLoad(var list) {
  return list[0];
}

main() {
  var a32 = new Float32List(5);
  for (int i = 0; i < 20; i++) {
    testCreateFloat32Array();
    testSetRange32();
    testIndexOutOfRange32();
    testIndexOf32();
    storeIt32(a32, 1, 2.0);
    testPolymorphicLoad(a32);
  }
  var a64 = new Float64List(5);
  for (int i = 0; i < 20; i++) {
    testCreateFloat64Array();
    testSetRange64();
    testIndexOutOfRange64();
    testIndexOf64();
    storeIt64(a64, 1, 2.0);
    testPolymorphicLoad(a64);
  }
  var f32x4 = new Float32x4List(5);
  for (int i = 0; i < 20; i++) {
    testPolymorphicLoad(f32x4);
  }

  // Check optimized (inlined) version of []=
  Expect.throws(() {
    storeIt32(a32, 1, 2);
  });
  Expect.throws(() {
    storeIt64(a64, 1, 2);
  });
}
