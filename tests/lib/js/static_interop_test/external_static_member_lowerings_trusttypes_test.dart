// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library external_static_member_lowerings_trusttypes_test;

import 'dart:js_interop';

import 'package:expect/minitest.dart';
import 'package:js/js.dart' show trustTypes;

@JS()
external void eval(String code);

@JS('ExternalStatic')
@staticInterop
@trustTypes
class ExternalStaticTrustType {
  external static double field;
  external static double get getSet;
  external static double method();
}

// dart2js is smart enough to see that the expectations below will never be true
// as the types are incompatible. Therefore, it optimizes the expectation code
// to *always fail*, even if the values are the same! Since we're breaking
// soundness with @trustTypes, we need to confuse dart2js enough that it doesn't
// do those optimizations, hence this.
@pragma('dart2js:noInline')
@pragma('dart2js:assumeDynamic')
confuse(x) => x;

void main() {
  eval('''
    globalThis.ExternalStatic = function ExternalStatic() {}
    globalThis.ExternalStatic.method = function() {
      return 'method';
    }
    globalThis.ExternalStatic.field = 'field';
    globalThis.ExternalStatic.getSet = 'getSet';
  ''');

  // Use wrong return type in conjunction with `@trustTypes`.
  expect(confuse(ExternalStaticTrustType.field), 'field');

  expect(confuse(ExternalStaticTrustType.getSet), 'getSet');

  expect(confuse(ExternalStaticTrustType.method()), 'method');
}
