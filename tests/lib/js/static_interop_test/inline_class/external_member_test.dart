// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=inline-class

@JS()
library external_member_test;

import 'dart:js_interop';

import 'package:expect/minitest.dart';

@JS()
external dynamic eval(String code);

@JS()
inline class External {
  final JSObject obj;
  external External();

  external String field;
  @JS('field')
  external String renamedField;
  external final String finalField;

  // TODO(srujzs): CFE incorrectly type-checks getters and setters with the same
  // name. Uncomment these tests once
  // https://github.com/dart-lang/sdk/issues/51299 is resolved.
  // external String get getSet;
  // external set getSet(String val);
  // @JS('getSet')
  // external String get renamedGetSet;
  // @JS('getSet')
  // external set renamedGetSet(String val);

  external String method();
  external String differentArgsMethod(String a, [String b = '']);
  @JS('method')
  external String renamedMethod();
}

void main() {
  eval('''
    globalThis.External = function External() {
      this.field = 'field';
      this.finalField = 'finalField';
      this.getSet = 'getSet';
      this.method = function() {
        return 'method';
      }
      this.differentArgsMethod = function(a, b) {
        return a + b;
      }
    }
  ''');
  var external = External();

  // Fields.
  expect(external.field, 'field');
  external.field = 'modified';
  expect(external.field, 'modified');
  expect(external.renamedField, 'modified');
  external.renamedField = 'renamedField';
  expect(external.renamedField, 'renamedField');
  expect(external.finalField, 'finalField');

  // Getters and setters.
  // expect(external.getSet, 'getSet');
  // external.getSet = 'modified';
  // expect(external.getSet, 'modified');
  // expect(external.renamedGetSet, 'modified');
  // external.renamedGetSet = 'renamedGetSet';
  // expect(external.renamedGetSet, 'renamedGetSet');

  // Methods.
  expect(external.method(), 'method');
  expect(external.differentArgsMethod('method'), 'methodundefined');
  expect(external.renamedMethod(), 'method');
}
