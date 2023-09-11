// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=inline-class

@JS()
library external_member_test;

import 'dart:js_interop';

import 'package:expect/expect.dart';
import 'package:expect/minitest.dart';

@JS()
external dynamic eval(String code);

extension type External<T extends JSAny?, U extends Nested>._(JSObject _) {
  external External();

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
  external String addMethod(String a, [String b]);
  @JS('method')
  external String renamedMethod();

  @JS('field')
  external T fieldT;
  @JS('addMethod')
  external T addMethodT(T a, T b);
  @JS('addMethod')
  external R addMethodGeneric<R extends JSAny?, P extends JSAny?>(P a, [P b]);

  external Nested nested;
  external Nested combineNested(Nested a, Nested b);

  @JS('nested')
  external U nestedU;
  @JS('combineNested')
  external U combineNestedU(U a, [U b]);
  @JS('combineNested')
  external R combineNestedGeneric<R extends Nested>(R a, [R b]);
}

extension type Nested<T extends JSAny?>._(JSObject _) {
  external Nested(T value);

  external T get value;
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
      this.addMethod = function(a, b) {
        return a + b;
      }
      this.combineNested = function(a, b) {
        return new Nested(a.value + b.value);
      }
    }
    globalThis.Nested = function Nested(value) {
      this.value = value;
    }
  ''');
  final external = External<JSString, Nested>();

  // Fields.
  expect(external.field, 'field');
  external.field = 'modified';
  expect(external.field, 'modified');
  expect(external.renamedField, 'modified');
  external.renamedField = 'renamedField';
  expect(external.renamedField, 'renamedField');
  expect(external.finalField, 'finalField');

  // Getters and setters.
  expect(external.getSet, 'getSet');
  external.getSet = 'modified';
  expect(external.getSet, 'modified');
  expect(external.renamedGetSet, 'modified');
  external.renamedGetSet = 'renamedGetSet';
  expect(external.renamedGetSet, 'renamedGetSet');

  // Methods.
  expect(external.method(), 'method');
  expect(external.addMethod('method'), 'methodundefined');
  expect(external.addMethod('method', 'method'), 'methodmethod');
  expect(external.renamedMethod(), 'method');

  // Check that type parameters operate as expected on external interfaces.
  final value = 'value';
  final jsValue = value.toJS;
  external.fieldT = jsValue;
  expect(external.fieldT.toDart, value);
  expect(external.addMethodT(jsValue, jsValue).toDart, '$value$value');
  expect(
      external.addMethodGeneric<JSNumber, JSNumber>(0.toJS, 0.toJS).toDartInt,
      0);

  external.nested = Nested(jsValue);
  expect((external.nested as Nested<JSString>).value.toDart, value);
  expect(
      (external.combineNested(Nested(value.toJS), Nested(jsValue))
              as Nested<JSString>)
          .value
          .toDart,
      '$value$value');

  external.nestedU = Nested(jsValue);
  expect((external.nestedU as Nested<JSString>).value.toDart, value);
  expect(
      (external.combineNestedU(Nested(jsValue), Nested(jsValue))
              as Nested<JSString>)
          .value
          .toDart,
      '$value$value');
  expect(
      external
          .combineNestedGeneric(Nested(jsValue), Nested(jsValue))
          .value
          .toDart,
      '$value$value');

  // Try invalid generics.
  (external as External<JSNumber, Nested>).fieldT = 0.toJS;
  // dart2wasm uses a JSStringImpl here for conversion without validating the
  // extern ref, so we would only see that it's not a String when we call
  // methods on it.
  Expect.throws(() => external.fieldT.toDart.toLowerCase());
  Expect.throws(() => external
      .addMethodGeneric<JSNumber, JSString>(value.toJS, value.toJS)
      .toDartInt
      .isEven);
  Expect.throws(() => external
      .addMethodGeneric<JSString, JSNumber>(0.toJS, 0.toJS)
      .toDart
      .toLowerCase());
}
