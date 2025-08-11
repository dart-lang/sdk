// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:js_interop';

import 'package:expect/expect.dart';
import 'package:expect/variations.dart';

const soundNullSafety = !unsoundNullSafety;

@JS()
external void eval(String code);

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
  external R addMethodGeneric<R extends JSAny?, P extends JSAny?>(
    P a,
    P b, [
    bool dontAddNull,
  ]);

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
      this.addMethod = function(a, b, dontAddNull) {
        if (dontAddNull && (a == null || b == null)) {
          return null;
        }
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
  Expect.equals('field', external.field);
  external.field = 'modified';
  Expect.equals('modified', external.field);
  Expect.equals('modified', external.renamedField);
  external.renamedField = 'renamedField';
  Expect.equals('renamedField', external.renamedField);
  Expect.equals('finalField', external.finalField);

  // Getters and setters.
  Expect.equals('getSet', external.getSet);
  external.getSet = 'modified';
  Expect.equals('modified', external.getSet);
  Expect.equals('modified', external.renamedGetSet);
  external.renamedGetSet = 'renamedGetSet';
  Expect.equals('renamedGetSet', external.renamedGetSet);

  // Methods.
  Expect.equals('method', external.method());
  Expect.equals('methodundefined', external.addMethod('method'));
  Expect.equals('methodmethod', external.addMethod('method', 'method'));
  Expect.equals('method', external.renamedMethod());

  // Check that type parameters operate as expected on external interfaces.
  final value = 'value';
  final jsValue = value.toJS;
  external.fieldT = jsValue;
  Expect.equals(value, external.fieldT.toDart);
  Expect.equals('$value$value', external.addMethodT(jsValue, jsValue).toDart);
  Expect.equals(
    0,
    external.addMethodGeneric<JSNumber, JSNumber>(0.toJS, 0.toJS).toDartInt,
  );

  external.nested = Nested(jsValue);
  Expect.equals(value, (external.nested as Nested<JSString>).value.toDart);
  Expect.equals(
    '$value$value',
    (external.combineNested(Nested(value.toJS), Nested(jsValue))
            as Nested<JSString>)
        .value
        .toDart,
  );

  external.nestedU = Nested(jsValue);
  Expect.equals(value, (external.nestedU as Nested<JSString>).value.toDart);
  Expect.equals(
    '$value$value',
    (external.combineNestedU(Nested(jsValue), Nested(jsValue))
            as Nested<JSString>)
        .value
        .toDart,
  );
  Expect.equals(
    '$value$value',
    external
        .combineNestedGeneric(Nested(jsValue), Nested(jsValue))
        .value
        .toDart,
  );

  // Try invalid generics.
  (external as External<JSNumber, Nested>).fieldT = 0.toJS;
  // dart2wasm uses a JSStringImpl here for conversion without validating the
  // extern ref, so we would only see that it's not a String when we call
  // methods on it.
  Expect.throws(() => external.fieldT.toDart.split('foo'));
  (external as External<JSNumber?, Nested>).fieldT = null;
  Expect.throwsWhen(
    soundNullSafety && checkedImplicitDowncasts,
    () => external.fieldT,
  );
  Expect.throws(
    () => external
        .addMethodGeneric<JSNumber, JSString>(value.toJS, value.toJS)
        .toDartInt,
  );
  Expect.throws(
    () => external
        .addMethodGeneric<JSString, JSNumber>(0.toJS, 0.toJS)
        .toDart
        .split('foo'),
  );
  Expect.throwsWhen(
    soundNullSafety && checkedImplicitDowncasts,
    () => external.addMethodGeneric<JSString, JSString?>(null, null, true),
  );
  external.addMethodGeneric<JSString?, JSString?>(''.toJS, null, true);
}
