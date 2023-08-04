// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that `createStaticInteropMock` correctly instantiates to bounds for type
// parameters.

import 'dart:js_interop';
import 'package:js/js_util.dart';

import 'functional_test_lib.dart';

@JSExport()
class Valid {
  JSArray superMethod(JSAny param) => throw UnimplementedError();

  JSArray get getSet => throw UnimplementedError();
  set getSet(JSAny val) => throw UnimplementedError();
  JSArray method(JSAny param) => throw UnimplementedError();
  Params interopTypeMethod(Supertype param) => throw UnimplementedError();
  JSArray genericMethod(JSAny param) => throw UnimplementedError();
}

@JSExport()
class Invalid {
  JSAny superMethod(JSArray param) => throw UnimplementedError();

  @JSExport('getSet') // Rename to avoid getter/setter type conflicts.
  JSAny get getter => throw UnimplementedError();
  set getSet(JSArray val) => throw UnimplementedError();
  JSAny method(JSArray param) => throw UnimplementedError();
  Supersupertype interopTypeMethod(Params param) => throw UnimplementedError();
  JSAny genericMethod(JSArray param) => throw UnimplementedError();
}

@JSExport()
class InvalidContravariant {
  JSArray superMethod(JSArray param) => throw UnimplementedError();

  JSArray get getSet => throw UnimplementedError();
  set getSet(JSArray val) => throw UnimplementedError();
  JSArray method(JSArray param) => throw UnimplementedError();
  Params interopTypeMethod(Params param) => throw UnimplementedError();
  JSArray genericMethod(JSArray param) => throw UnimplementedError();
}

@JSExport()
class InvalidCovariant {
  JSAny superMethod(JSAny param) => throw UnimplementedError();

  JSAny get getSet => throw UnimplementedError();
  set getSet(JSAny val) => throw UnimplementedError();
  JSAny method(JSAny param) => throw UnimplementedError();
  Supersupertype interopTypeMethod(Supersupertype param) =>
      throw UnimplementedError();
  JSAny genericMethod(JSAny param) => throw UnimplementedError();
}

void main() {
  createStaticInteropMock<
//^
// [web] Type argument 'Params<JSArray, Params<JSObject, Supertype<JSObject>>>' has type parameters that do not match their bound. createStaticInteropMock requires instantiating all type parameters to their bound to ensure mocking conformance.
// [web] Type argument 'ParamsImpl<JSArray, JSArray, Params<JSObject, Supertype<JSObject>>>' has type parameters that do not match their bound. createStaticInteropMock requires instantiating all type parameters to their bound to ensure mocking conformance.
          Params<JSArray, Params>,
          ParamsImpl<JSArray, JSArray, Params>>(
      ParamsImpl<JSArray, JSArray, Params>());
  createStaticInteropMock<Params<JSObject, Supertype>,
          ParamsImpl<JSObject, JSObject, Supertype>>(
      ParamsImpl<JSObject, JSObject, Supertype>());

  // Note that this is fine, but might fail at runtime due to runtime covariant
  // checks. This is no different than casting a `List<JSObject>` to `List` and
  // trying to add a `JSString`. On the JS backends, this will fail, and on
  // dart2wasm, this will succeed because all JS types get erased to JSValue.
  createStaticInteropMock<Params, ParamsImpl>(
      ParamsImpl<JSArray, JSArray, Supertype>());
  createStaticInteropMock<Params, ParamsImpl>(ParamsImpl());
  createStaticInteropMock<Params, Valid>(Valid());

  createStaticInteropMock<Params, Invalid>(Invalid());
//^
// [web] Dart class 'Invalid' does not have any members that implement any of the following extension member(s) with export name 'genericMethod': ParamsExtension.genericMethod (FunctionType(JSObject Function(JSObject))).
// [web] Dart class 'Invalid' does not have any members that implement any of the following extension member(s) with export name 'getSet': ParamsExtension.getSet (FunctionType(JSObject Function())), ParamsExtension.getSet= (FunctionType(void Function(JSObject))).
// [web] Dart class 'Invalid' does not have any members that implement any of the following extension member(s) with export name 'interopTypeMethod': ParamsExtension.interopTypeMethod (FunctionType(Supertype<JSObject> Function(Supertype<JSObject>))).
// [web] Dart class 'Invalid' does not have any members that implement any of the following extension member(s) with export name 'method': ParamsExtension.method (FunctionType(JSObject Function(JSObject))).
// [web] Dart class 'Invalid' does not have any members that implement any of the following extension member(s) with export name 'superMethod': SupertypeExtension.superMethod (FunctionType(JSObject Function(JSObject))).
  createStaticInteropMock<Params, InvalidContravariant>(InvalidContravariant());
//^
// [web] Dart class 'InvalidContravariant' does not have any members that implement any of the following extension member(s) with export name 'genericMethod': ParamsExtension.genericMethod (FunctionType(JSObject Function(JSObject))).
// [web] Dart class 'InvalidContravariant' does not have any members that implement any of the following extension member(s) with export name 'interopTypeMethod': ParamsExtension.interopTypeMethod (FunctionType(Supertype<JSObject> Function(Supertype<JSObject>))).
// [web] Dart class 'InvalidContravariant' does not have any members that implement any of the following extension member(s) with export name 'method': ParamsExtension.method (FunctionType(JSObject Function(JSObject))).
// [web] Dart class 'InvalidContravariant' does not have any members that implement any of the following extension member(s) with export name 'superMethod': SupertypeExtension.superMethod (FunctionType(JSObject Function(JSObject))).
// [web] Dart class 'InvalidContravariant' has a getter, but does not have a setter to implement any of the following extension member(s) with export name 'getSet': ParamsExtension.getSet= (FunctionType(void Function(JSObject))).
  createStaticInteropMock<Params, InvalidCovariant>(InvalidCovariant());
//^
// [web] Dart class 'InvalidCovariant' does not have any members that implement any of the following extension member(s) with export name 'genericMethod': ParamsExtension.genericMethod (FunctionType(JSObject Function(JSObject))).
// [web] Dart class 'InvalidCovariant' does not have any members that implement any of the following extension member(s) with export name 'interopTypeMethod': ParamsExtension.interopTypeMethod (FunctionType(Supertype<JSObject> Function(Supertype<JSObject>))).
// [web] Dart class 'InvalidCovariant' does not have any members that implement any of the following extension member(s) with export name 'method': ParamsExtension.method (FunctionType(JSObject Function(JSObject))).
// [web] Dart class 'InvalidCovariant' does not have any members that implement any of the following extension member(s) with export name 'superMethod': SupertypeExtension.superMethod (FunctionType(JSObject Function(JSObject))).
// [web] Dart class 'InvalidCovariant' has a setter, but does not have a getter to implement any of the following extension member(s) with export name 'getSet': ParamsExtension.getSet (FunctionType(JSObject Function())).
}
