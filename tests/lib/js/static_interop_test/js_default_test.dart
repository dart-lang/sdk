// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that optional parameters are not passed if the invocation does not pass
// them when using dart:js_interop. We check for declarations both in the
// current library and another library.

library js_default_test;

import 'dart:js_interop';

import 'package:expect/minitest.dart'; // ignore: deprecated_member_use_from_same_package

import 'js_default_with_namespaces.dart' as namespace;

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

@JS('SimpleObject')
extension type SimpleObject2._(JSObject _) implements JSObject {
  external factory SimpleObject2();
  external factory SimpleObject2.twoOptional([JSNumber n1, JSNumber n2]);
  external factory SimpleObject2.oneOptional(JSNumber n1, [JSNumber n2]);

  external static JSNumber twoOptionalStatic([JSNumber n1, JSNumber n2]);
  external static JSNumber oneOptionalStatic(JSNumber n1, [JSNumber n2]);

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
  expect(0, twoOptional().toDartInt);
  expect(1, twoOptional(4.0.toJS).toDartInt);
  expect(2, twoOptional(4.0.toJS, 5.0.toJS).toDartInt);

  expect(1, oneOptional(4.0.toJS).toDartInt);
  expect(2, oneOptional(4.0.toJS, 5.0.toJS).toDartInt);

  // Test factories.
  expect(0, SimpleObject.twoOptional().initialArguments.toDartInt);
  expect(1, SimpleObject.twoOptional(4.0.toJS).initialArguments.toDartInt);
  expect(2,
      SimpleObject.twoOptional(4.0.toJS, 5.0.toJS).initialArguments.toDartInt);

  expect(1, SimpleObject.oneOptional(4.0.toJS).initialArguments.toDartInt);
  expect(2,
      SimpleObject.oneOptional(4.0.toJS, 5.0.toJS).initialArguments.toDartInt);

  // Test static methods.
  expect(0, SimpleObject.twoOptionalStatic().toDartInt);
  expect(1, SimpleObject.twoOptionalStatic(4.0.toJS).toDartInt);
  expect(2, SimpleObject.twoOptionalStatic(4.0.toJS, 5.0.toJS).toDartInt);

  expect(1, SimpleObject.oneOptionalStatic(4.0.toJS).toDartInt);
  expect(2, SimpleObject.oneOptionalStatic(4.0.toJS, 5.0.toJS).toDartInt);

  // Test extension methods.
  final s = SimpleObject();
  expect(0, s.twoOptional().toDartInt);
  expect(1, s.twoOptional(4.0.toJS).toDartInt);
  expect(2, s.twoOptional(4.0.toJS, 5.0.toJS).toDartInt);

  expect(1, s.oneOptional(4.0.toJS).toDartInt);
  expect(2, s.oneOptional(4.0.toJS, 5.0.toJS).toDartInt);

  // Test extension type factories.
  expect(0, SimpleObject2.twoOptional().initialArguments.toDartInt);
  expect(1, SimpleObject2.twoOptional(4.0.toJS).initialArguments.toDartInt);
  expect(2,
      SimpleObject2.twoOptional(4.0.toJS, 5.0.toJS).initialArguments.toDartInt);

  expect(1, SimpleObject2.oneOptional(4.0.toJS).initialArguments.toDartInt);
  expect(2,
      SimpleObject2.oneOptional(4.0.toJS, 5.0.toJS).initialArguments.toDartInt);

  // Test extension type static methods.
  expect(0, SimpleObject2.twoOptionalStatic().toDartInt);
  expect(1, SimpleObject2.twoOptionalStatic(4.0.toJS).toDartInt);
  expect(2, SimpleObject2.twoOptionalStatic(4.0.toJS, 5.0.toJS).toDartInt);

  expect(1, SimpleObject2.oneOptionalStatic(4.0.toJS).toDartInt);
  expect(2, SimpleObject2.oneOptionalStatic(4.0.toJS, 5.0.toJS).toDartInt);

  // Test extension type methods.
  final s2 = SimpleObject2();
  expect(0, s2.twoOptional().toDartInt);
  expect(1, s2.twoOptional(4.0.toJS).toDartInt);
  expect(2, s2.twoOptional(4.0.toJS, 5.0.toJS).toDartInt);

  expect(1, s2.oneOptional(4.0.toJS).toDartInt);
  expect(2, s2.oneOptional(4.0.toJS, 5.0.toJS).toDartInt);
}

void testOtherLibrary() {
  // Test top level methods.
  expect(1, namespace.oneOptional(4.0.toJS).toDartInt);
  expect(2, namespace.oneOptional(4.0.toJS, 5.0.toJS).toDartInt);

  // Test factories.
  expect(1,
      namespace.SimpleObject.oneOptional(4.0.toJS).initialArguments.toDartInt);
  expect(
      2,
      namespace.SimpleObject.oneOptional(4.0.toJS, 5.0.toJS)
          .initialArguments
          .toDartInt);

  // Test static methods.
  expect(1, namespace.SimpleObject.oneOptionalStatic(4.0.toJS).toDartInt);
  expect(2,
      namespace.SimpleObject.oneOptionalStatic(4.0.toJS, 5.0.toJS).toDartInt);

  // Test extension methods.
  final s = namespace.SimpleObject();
  expect(1, s.oneOptional(4.0.toJS).toDartInt);
  expect(2, s.oneOptional(4.0.toJS, 5.0.toJS).toDartInt);

  // Test extension type factories.
  expect(1,
      namespace.SimpleObject.oneOptional(4.0.toJS).initialArguments.toDartInt);
  expect(
      2,
      namespace.SimpleObject.oneOptional(4.0.toJS, 5.0.toJS)
          .initialArguments
          .toDartInt);

  // Test extension type static methods.
  expect(1, namespace.SimpleObject.oneOptionalStatic(4.0.toJS).toDartInt);
  expect(2,
      namespace.SimpleObject.oneOptionalStatic(4.0.toJS, 5.0.toJS).toDartInt);

  // Test extension type methods.
  final s2 = namespace.SimpleObject();
  expect(1, s2.oneOptional(4.0.toJS).toDartInt);
  expect(2, s2.oneOptional(4.0.toJS, 5.0.toJS).toDartInt);
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
  // Move the declarations to a namespace and delete the declarations on
  // globalThis to make sure we incorporate the library prefix in
  // invocation-level lowering.
  eval('''
  var library1 = {};
  globalThis.library1 = library1;

  library1.twoOptional = globalThis.twoOptional;
  library1.oneOptional = globalThis.oneOptional;
  delete globalThis.twoOptional;
  delete globalThis.oneOptional;
  library1.SimpleObject = globalThis.SimpleObject;
  delete globalThis.SimpleObject;
  ''');
  testOtherLibrary();
}
