// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library js_typed_interop_anonymous_unreachable_test;

import 'dart:html';
import 'dart:js' as js;

import 'package:js/js.dart';
import 'package:expect/minitest.dart';

@JS()
@anonymous
class Literal {
  external factory Literal({required int x, required String y, required num z});

  external int get x;
  external String get y;
  external num get z;
}

main() {
  test('nothing to do', () {
    // This test is empty, but it is a regression for Issue# 24974: dart2js
    // would crash trying to compile code that used @anonymous and that was
    // not reachable from main.
  });
}
