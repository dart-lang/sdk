// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:expect/expect.dart';
import 'package:expect/variations.dart';

void main() {
  final String s1 = '1' + '23';
  final String s2 = '12' + '3';
  final String s3 = '12' + '34';

  Expect.isTrue(jsIdentical(s1, s2));
  Expect.isFalse(jsIdentical(s1, s3));

  if (jsNumbers) {
    Expect.isTrue(identical(s1, s2));
    Expect.isFalse(identical(s1, s3));
  } else {
    Expect.isFalse(identical(s1, s2));
    Expect.isFalse(identical(s1, s3));
  }

  final JSAny x1 = globalContext;
  final JSAny x2 = globalContext;
  final JSAny x3 = globalContext.getProperty('Array'.toJS);

  Expect.isTrue(jsIdentical(x1, x2));
  Expect.isFalse(jsIdentical(x1, x3));

  if (jsNumbers) {
    Expect.isTrue(identical(x1, x2));
    Expect.isFalse(identical(x1, x3));
  } else {
    Expect.isFalse(identical(x1, x2));
    Expect.isFalse(identical(x1, x3));
  }

  final Object o1 = Object();
  final Object o2 = o1;
  final Object o3 = Object();

  Expect.isTrue(jsIdentical(o1, o2));
  Expect.isFalse(jsIdentical(o1, o3));

  globalContext.setProperty('test-array1'.toJS, JSArray());
  globalContext.setProperty('test-array2'.toJS, JSArray());
  final JSArray a1 = globalContext.getProperty('test-array1'.toJS);
  final JSArray a2 = globalContext.getProperty('test-array1'.toJS);
  final JSArray a3 = globalContext.getProperty('test-array2'.toJS);

  Expect.isTrue(jsIdentical(a1, a2));
  Expect.isFalse(jsIdentical(a1, a3));

  if (jsNumbers) {
    Expect.isTrue(identical(a1, a2));
    Expect.isFalse(identical(a1, a3));
  } else {
    Expect.isFalse(identical(a1, a2));
    Expect.isFalse(identical(a1, a3));
  }

  globalContext.setProperty('test-bytearray1'.toJS, JSUint8Array());
  globalContext.setProperty('test-bytearray2'.toJS, JSUint8Array());
  final JSUint8Array u1 = globalContext.getProperty('test-bytearray1'.toJS);
  final JSUint8Array u2 = globalContext.getProperty('test-bytearray1'.toJS);
  final JSUint8Array u3 = globalContext.getProperty('test-bytearray2'.toJS);

  Expect.isTrue(jsIdentical(u1, u2));
  Expect.isFalse(jsIdentical(u1, u3));

  if (jsNumbers) {
    Expect.isTrue(identical(u1, u2));
    Expect.isFalse(identical(u1, u3));
  } else {
    Expect.isFalse(identical(u1, u2));
    Expect.isFalse(identical(u1, u3));
  }

  globalContext.setProperty('test-arraybuffer1'.toJS, JSArrayBuffer(0));
  globalContext.setProperty('test-arraybuffer2'.toJS, JSArrayBuffer(0));
  final JSArrayBuffer b1 = globalContext.getProperty('test-arraybuffer1'.toJS);
  final JSArrayBuffer b2 = globalContext.getProperty('test-arraybuffer1'.toJS);
  final JSArrayBuffer b3 = globalContext.getProperty('test-arraybuffer2'.toJS);

  Expect.isTrue(jsIdentical(b1, b2));
  Expect.isFalse(jsIdentical(b1, b3));

  if (jsNumbers) {
    Expect.isTrue(identical(b1, b2));
    Expect.isFalse(identical(b1, b3));
  } else {
    Expect.isFalse(identical(b1, b2));
    Expect.isFalse(identical(b1, b3));
  }

  globalContext.setProperty('test-dataview1'.toJS, JSDataView(b1));
  globalContext.setProperty('test-dataview2'.toJS, JSDataView(b1));
  final JSDataView d1 = globalContext.getProperty('test-dataview1'.toJS);
  final JSDataView d2 = globalContext.getProperty('test-dataview1'.toJS);
  final JSDataView d3 = globalContext.getProperty('test-dataview2'.toJS);

  Expect.isTrue(jsIdentical(d1, d2));
  Expect.isFalse(jsIdentical(d1, d3));

  if (jsNumbers) {
    Expect.isTrue(identical(d1, d2));
    Expect.isFalse(identical(d1, d3));
  } else {
    Expect.isFalse(identical(d1, d2));
    Expect.isFalse(identical(d1, d3));
  }
}
