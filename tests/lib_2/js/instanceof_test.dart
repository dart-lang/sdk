// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library instanceof_test;

import 'package:js/js.dart';
import 'package:expect/expect.dart';
import 'dart:js_util';

@JS()
external void eval(String code);

@JS('Class')
class Class {
  external Class();
  external Constructor get constructor;
}

@JS()
class Constructor {}

void main() {
  eval("self.Class = function Class() {}");
  var o = new Class();
  var constructor = o.constructor;
  Expect.isTrue(instanceof(o, constructor));
}
