// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that optional parameters are not passed if the invocation does not pass
// them when using dart:js_interop. We check for declarations both in the
// current library and another library.

library js_default_test;

import 'dart:js_interop';

import 'package:expect/minitest.dart';

import 'js_default_other_library.dart' as other;

@JS()
external void eval(String code);

@JS()
@staticInterop
class SimpleObject {
  external factory SimpleObject();
  external factory SimpleObject.twoOptional([JSNumber n1, JSNumber n2]);
  external factory SimpleObject.oneOptional(JSNumber n1, [JSNumber n2]);

  external static JSNumber twoOptionalStatic([JSNumber n1, JSNumber n2]);
  external static JSNumber oneOptionalStatic(JSNumber n1, [JSNumber n2]);
}

extension SimpleObjectExtension on SimpleObject {
  external JSNumber get initialArguments;
  external JSNumber twoOptional([JSNumber n1, JSNumber n2]);
  external JSNumber oneOptional(JSNumber n1, [JSNumber n2]);
}

@JS()
external JSNumber twoOptional([JSNumber n1, JSNumber n2]);

@JS()
external JSNumber oneOptional(JSNumber n1, [JSNumber n2]);

void testCurrentLibrary() {
  // Test top level methods.
  expect(0, twoOptional().toDart);
  expect(1, twoOptional(4.0.toJS).toDart);
  expect(2, twoOptional(4.0.toJS, 5.0.toJS).toDart);

  expect(1, oneOptional(4.0.toJS).toDart);
  expect(2, oneOptional(4.0.toJS, 5.0.toJS).toDart);

  // Test factories.
  expect(0, SimpleObject.twoOptional().initialArguments.toDart);
  expect(1, SimpleObject.twoOptional(4.0.toJS).initialArguments.toDart);
  expect(
      2, SimpleObject.twoOptional(4.0.toJS, 5.0.toJS).initialArguments.toDart);

  expect(1, SimpleObject.oneOptional(4.0.toJS).initialArguments.toDart);
  expect(
      2, SimpleObject.oneOptional(4.0.toJS, 5.0.toJS).initialArguments.toDart);

  // Test static methods.
  expect(0, SimpleObject.twoOptionalStatic().toDart);
  expect(1, SimpleObject.twoOptionalStatic(4.0.toJS).toDart);
  expect(2, SimpleObject.twoOptionalStatic(4.0.toJS, 5.0.toJS).toDart);

  expect(1, SimpleObject.oneOptionalStatic(4.0.toJS).toDart);
  expect(2, SimpleObject.oneOptionalStatic(4.0.toJS, 5.0.toJS).toDart);

  // Test extension methods.
  final s = SimpleObject();
  expect(0, s.twoOptional().toDart);
  expect(1, s.twoOptional(4.0.toJS).toDart);
  expect(2, s.twoOptional(4.0.toJS, 5.0.toJS).toDart);

  expect(1, s.oneOptional(4.0.toJS).toDart);
  expect(2, s.oneOptional(4.0.toJS, 5.0.toJS).toDart);
}

void testOtherLibrary() {
  // Test top level methods.
  expect(1, other.oneOptional(4.0.toJS).toDart);
  expect(2, other.oneOptional(4.0.toJS, 5.0.toJS).toDart);

  // Test factories.
  expect(1, other.SimpleObject.oneOptional(4.0.toJS).initialArguments.toDart);
  expect(
      2,
      other.SimpleObject.oneOptional(4.0.toJS, 5.0.toJS)
          .initialArguments
          .toDart);

  // Test static methods.
  expect(1, other.SimpleObject.oneOptionalStatic(4.0.toJS).toDart);
  expect(2, other.SimpleObject.oneOptionalStatic(4.0.toJS, 5.0.toJS).toDart);

  // Test extension methods.
  final s = other.SimpleObject();
  expect(1, s.oneOptional(4.0.toJS).toDart);
  expect(2, s.oneOptional(4.0.toJS, 5.0.toJS).toDart);
}

void main() {
  eval('''
  globalThis.twoOptional = function(n1, n2) {
    return arguments.length;
  }
  globalThis.oneOptional = function(n1, n2) {
    return arguments.length;
  }
  globalThis.SimpleObject = function(i1, i2) {
    this.twoOptional = function(n1, n2) {
      return arguments.length;
    }
    this.oneOptional = function(n1, n2) {
      return arguments.length;
    }
    this.initialArguments = arguments.length;
    return this;
  }
  globalThis.SimpleObject.twoOptionalStatic = function(n1, n2) {
    return arguments.length;
  }
  globalThis.SimpleObject.oneOptionalStatic = function(n1, n2) {
    return arguments.length;
  }
  ''');
  testCurrentLibrary();
  testOtherLibrary();
}
