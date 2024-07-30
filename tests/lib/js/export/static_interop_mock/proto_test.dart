// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that providing a proto object to createStaticInteropMock does not break
// any functionality, and allows instanceof/is checks to pass.

@JS()
library proto_test;

import 'dart:html';

import 'package:expect/minitest.dart'; // ignore: deprecated_member_use_from_same_package
import 'package:js/js.dart';
import 'package:js/js_util.dart';

import 'functional_test_lib.dart' as functional_test;

@JS('Window.prototype')
external Object get windowProto;

@JS('Window')
external Object get windowType;

@JS()
@staticInterop
class JSWindow {}

@JSExport()
class DartWindow {
  int _unused = 0;
}

void main() {
  // Test that everything still works the same.
  functional_test.test(windowProto);
  // Test instanceof/is checks.
  var jsMock =
      createStaticInteropMock<JSWindow, DartWindow>(DartWindow(), windowProto);
  expect(jsMock is Window, true);
  expect(instanceof(jsMock, windowType), true);
}
