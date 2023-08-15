// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=inline-class

@JS()
library external_extension_member_test;

import 'dart:js_interop';

import 'package:expect/minitest.dart';

@JS()
external dynamic eval(String code);

extension type ExtensionType._(JSObject _) {
  external ExtensionType();
}

extension E on ExtensionType {
  external String field;
  @JS('field')
  external String renamedField;
  external final String finalField;

  external String get getSet;
  external set getSet(String val);
  @JS('getSet')
  external String get renamedGetSet;
  @JS('getSet')
  external set renamedGetSet(String val);

  external String method();
  external String differentArgsMethod(String a, [String b = '']);
  @JS('method')
  external String renamedMethod();
}

void main() {
  eval('''
    globalThis.ExtensionType = function ExtensionType() {
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
  var extension = ExtensionType();

  // Fields.
  expect(extension.field, 'field');
  extension.field = 'modified';
  expect(extension.field, 'modified');
  expect(extension.renamedField, 'modified');
  extension.renamedField = 'renamedField';
  expect(extension.renamedField, 'renamedField');
  expect(extension.finalField, 'finalField');

  // Getters and setters.
  expect(extension.getSet, 'getSet');
  extension.getSet = 'modified';
  expect(extension.getSet, 'modified');
  expect(extension.renamedGetSet, 'modified');
  extension.renamedGetSet = 'renamedGetSet';
  expect(extension.renamedGetSet, 'renamedGetSet');

  // Methods.
  expect(extension.method(), 'method');
  expect(extension.differentArgsMethod('method'), 'methodundefined');
  expect(extension.renamedMethod(), 'method');
}
