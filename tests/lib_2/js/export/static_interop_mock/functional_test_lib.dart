// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test basic functionality of `createStaticInteropMock`. Basic methods, fields
// (final and not), getters, and setters are tested along with potential
// renames.

@JS()
library functional_test_lib;

import 'dart:js_interop';

import 'package:expect/minitest.dart';
import 'package:js/js_util.dart';

@JS()
@staticInterop
class Methods {}

extension on Methods {
  external String concat(String foo, String bar);
  // Sanity-check that non-externals are unaffected.
  String nonExternal() => 'nonExternal';
  @JS('_rename')
  external String rename();
  external String optionalConcat(String foo, String bar,
      [String boo, String? baz]);
}

@JSExport()
class MethodsDart {
  String concat(String foo, String bar) => foo + bar;
  String nonExternal() => 'initialized';
  String _rename() => 'initialized';
  String optionalConcat(String foo, String bar, [String? boo, String? baz]) =>
      foo + bar + (boo ?? '') + (baz ?? '');
}

@JS()
@staticInterop
class Fields {}

extension on Fields {
  external String field;
  external final String finalField;
  @JS('_renamedField')
  external String renamedField;
  @JS('_renamedFinalField')
  external final String renamedFinalField;
}

@JSExport()
class FieldsDart {
  String field = 'initialized';
  String finalField = 'initialized';
  String _renamedField = 'initialized';
  final String _renamedFinalField = 'initialized';
}

@JS()
@staticInterop
class GetSet {}

extension on GetSet {
  external String get getSet;
  external set getSet(String val);
  @JS('_renamedGetSet')
  external String get renamedGetSet;
  @JS('_renamedGetSet')
  external set renamedGetSet(String val);
  @JS('_sameNameDifferentRenameGet')
  external String get sameNameDifferentRename;
  @JS('_sameNameDifferentRenameSet')
  external set sameNameDifferentRename(String val);
  @JS('_differentNameSameRename')
  external String get differentNameSameRenameGet;
  @JS('_differentNameSameRename')
  external set differentNameSameRenameSet(String val);
}

@JSExport()
class GetSetDart {
  String getSet = 'initialized';
  String _renamedGetSet = 'initialized';
  String _sameNameDifferentRenameGet = 'initialized';
  String _sameNameDifferentRenameSet = 'initialized';
  String _differentNameSameRename = 'initialized';
}

@JS()
@staticInterop
class Supersupertype {}

@JS()
@staticInterop
class Supertype<T extends JSObject> implements Supersupertype {}

extension SupertypeExtension<T extends JSObject> on Supertype<T> {
  external T superMethod(T param);
}

// Note that even though `Supertype` is instantiated with `JSArray`, we still
// require users to implement `superMethod` using the `JSObject` bound.
// Functionally, this means `superMethod` needs to accept a `JSObject` (or a
// supertype), even though an object typed `Params` can never actually call
// `superMethod` with a type less specific than `JSArray`. This is probably
// rare, but can be a bit frustrating. A similar analysis can be made for the
// type parameters on `Params`. A user may want to mock only a
// `Params<JSArray, Params>`, but we require them to mock a
// `Params<JSObject, Supertype>` as those are the bounds. Unlike the
// `superMethod` case however, we have an error check when trying to pass in
// such a type to `createStaticInteropMock` to reduce confusion.
@JS()
@staticInterop
class Params<T extends JSObject, U extends Supertype>
    extends Supertype<JSArray> {
  external factory Params();
}

extension ParamsExtension<T extends JSObject, U extends Supertype>
    on Params<T, U> {
  external T get getSet;
  external set getSet(T val);
  external T method(T param);
  external U interopTypeMethod(U param);
  external V genericMethod<V extends JSObject>(V param);
}

late JSObject _jsObject;

@JSExport()
class ParamsImpl<S extends JSObject, T extends JSObject, U extends Supertype> {
  S superMethod(S param) => param;

  T get getSet => _jsObject as T;
  set getSet(T val) => _jsObject = val;
  T method(T param) => param;
  U interopTypeMethod(U param) => param;
  JSObject genericMethod(JSObject param) => param;
}

void test([Object? proto]) {
  var jsMethods =
      createStaticInteropMock<Methods, MethodsDart>(MethodsDart(), proto);
  expect(jsMethods.concat('a', 'b'), 'ab');
  expect(jsMethods.nonExternal(), 'nonExternal');
  expect(jsMethods.rename(), 'initialized');
  expect(jsMethods.optionalConcat('a', 'b'), 'ab');
  expect(jsMethods.optionalConcat('a', 'b', 'c'), 'abc');
  expect(jsMethods.optionalConcat('a', 'b', 'c', 'd'), 'abcd');
  var dartFields = FieldsDart();
  var jsFields = createStaticInteropMock<Fields, FieldsDart>(dartFields, proto);
  expect(jsFields.field, 'initialized');
  expect(jsFields.finalField, 'initialized');
  expect(jsFields.renamedField, 'initialized');
  expect(jsFields.renamedFinalField, 'initialized');
  // Modify the JS mock and check for updates in the Dart mock.
  jsFields.field = 'jsModified';
  jsFields.renamedField = 'jsModified';
  expect(dartFields.field, 'jsModified');
  expect(dartFields._renamedField, 'jsModified');
  // Modify the Dart mock and check for updates in the JS mock.
  dartFields.field = 'dartModified';
  dartFields.finalField = 'dartModified';
  dartFields._renamedField = 'dartModified';
  expect(jsFields.field, 'dartModified');
  expect(jsFields.finalField, 'dartModified');
  expect(jsFields.renamedField, 'dartModified');
  var dartGetSet = GetSetDart();
  var jsGetSet = createStaticInteropMock<GetSet, GetSetDart>(dartGetSet, proto);
  expect(jsGetSet.getSet, 'initialized');
  expect(jsGetSet.renamedGetSet, 'initialized');
  expect(jsGetSet.sameNameDifferentRename, 'initialized');
  expect(jsGetSet.differentNameSameRenameGet, 'initialized');
  // Modify the JS mock and check for updates in the Dart mock.
  jsGetSet.getSet = 'jsModified';
  jsGetSet.renamedGetSet = 'jsModified';
  jsGetSet.sameNameDifferentRename = 'jsModified';
  jsGetSet.differentNameSameRenameSet = 'jsModified';
  expect(dartGetSet.getSet, 'jsModified');
  expect(dartGetSet._renamedGetSet, 'jsModified');
  expect(dartGetSet._sameNameDifferentRenameGet, 'initialized');
  expect(dartGetSet._sameNameDifferentRenameSet, 'jsModified');
  expect(dartGetSet._differentNameSameRename, 'jsModified');
  // Modify the Dart mock and check for updates in the JS mock.
  dartGetSet.getSet = 'dartModified';
  dartGetSet._renamedGetSet = 'dartModified';
  // Use different values to disambiguate.
  dartGetSet._sameNameDifferentRenameGet = 'dartModifiedGet';
  dartGetSet._sameNameDifferentRenameSet = 'dartModifiedSet';
  dartGetSet._differentNameSameRename = 'dartModified';
  expect(jsGetSet.getSet, 'dartModified');
  expect(jsGetSet.renamedGetSet, 'dartModified');
  expect(jsGetSet.sameNameDifferentRename, 'dartModifiedGet');
  expect(jsGetSet.differentNameSameRenameGet, 'dartModified');
  // Calling members with type parameters.
  final jsParams = createStaticInteropMock<Params, ParamsImpl>(ParamsImpl());
  final jsArray = JSArray();
  expect(jsParams.superMethod(jsArray), jsArray);
  _jsObject = newObject<JSObject>();
  expect(jsParams.getSet, _jsObject);
  final newJsObject = newObject<JSObject>();
  jsParams.getSet = newJsObject;
  expect(jsParams.getSet, newJsObject);
  expect(jsParams.method(_jsObject), _jsObject);
  expect(jsParams.interopTypeMethod(_jsObject as Supertype), _jsObject);
  expect(jsParams.genericMethod(_jsObject), _jsObject);
  expect(jsParams.genericMethod<JSObject>(_jsObject), _jsObject);
  expect(jsParams.genericMethod<JSArray>(jsArray), jsArray);
}
