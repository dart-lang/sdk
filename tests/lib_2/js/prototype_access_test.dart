// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library prototest;

import 'package:js/js.dart';
import 'package:expect/expect.dart';

@JS('window.ArrayBuffer')
external Class get arrayBufferClass;

@JS('Function')
class Class {
  external dynamic get prototype;
  external dynamic get constructor;
}

class Normal {
  int prototype = 42;
  Normal constructor() {
    return this;
  }

  int operator [](int i) => prototype;
}

void main() {
  Expect.isTrue(arrayBufferClass.prototype != null);
  var normal = new Normal();
  Expect.equals(42, normal.prototype);
  Expect.equals(42, normal[0]);
  Expect.isTrue(arrayBufferClass.constructor != null);
  Expect.isTrue(arrayBufferClass.constructor is Function);
  Expect.isTrue(normal.constructor is Function);
  Expect.equals(normal, normal.constructor());
}
