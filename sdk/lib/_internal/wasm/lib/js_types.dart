// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This library exists to act as a uniform abstraction layer between the user
/// facing JS interop libraries and backend specific internal representations of
/// JS types.
///
/// For consistency, all of the web backends have a version of this library.
///
/// Note that the `Type`s are opaque extension types with platform-specific
/// representation types. They implement other `Type`s in a way that replicates
/// the JS type hierarchy. This allows users to potentially implement multiple
/// JS types that do not statically inherit one another and still have a valid
/// representation type that they can use. See
/// https://github.com/dart-lang/sdk/issues/62321 for more details.
///
/// **WARNING**: You should *not* rely on these runtime types. Not only is this
/// library not guaranteed to be consistent across platforms, these types may
/// change in the future.
library dart._js_types;

import 'dart:_error_utils';
import 'dart:_internal';
import 'dart:_js_helper' as js;
import 'dart:_object_helper';
import 'dart:_simd'
    show
        NaiveUnmodifiableInt32x4List,
        NaiveUnmodifiableFloat32x4List,
        NaiveUnmodifiableFloat64x2List;
import 'dart:_string';
import 'dart:_string_helper';
import 'dart:_wasm';
import 'dart:collection';
import 'dart:js_interop';
import 'dart:math';
import 'dart:typed_data';

part 'js_array.dart';
part 'js_typed_array.dart';

extension type JSAnyType(js.JSValue _jsAnyType) implements Object {}

extension type JSObjectType(js.JSValue _jsObjectType) implements JSAnyType {}

extension type JSFunctionType(js.JSValue _jsFunctionType)
    implements JSObjectType {}

extension type JSExportedDartFunctionType(
  js.JSValue _jsExportedDartFunctionType
)
    implements JSFunctionType {}

extension type JSArrayType(js.JSValue _jsArrayType) implements JSObjectType {}

extension type JSBoxedDartObjectType(js.JSValue _jsBoxedDartObjectType)
    implements JSObjectType {}

extension type JSArrayBufferType(js.JSValue _jsArrayBufferType)
    implements JSObjectType {}

extension type JSDataViewType(js.JSValue _jsDataViewType)
    implements JSObjectType {}

extension type JSTypedArrayType(js.JSValue _jsTypedArrayType)
    implements JSObjectType {}

extension type JSInt8ArrayType(js.JSValue _jsInt8ArrayType)
    implements JSTypedArrayType {}

extension type JSUint8ArrayType(js.JSValue _jsUint8ArrayType)
    implements JSTypedArrayType {}

extension type JSUint8ClampedArrayType(js.JSValue _jsUint8ClampedArrayType)
    implements JSTypedArrayType {}

extension type JSInt16ArrayType(js.JSValue _jsInt16ArrayType)
    implements JSTypedArrayType {}

extension type JSUint16ArrayType(js.JSValue _jsUint16ArrayType)
    implements JSTypedArrayType {}

extension type JSInt32ArrayType(js.JSValue _jsInt32ArrayType)
    implements JSTypedArrayType {}

extension type JSUint32ArrayType(js.JSValue _jsUint32ArrayType)
    implements JSTypedArrayType {}

extension type JSFloat32ArrayType(js.JSValue _jsFloat32ArrayType)
    implements JSTypedArrayType {}

extension type JSFloat64ArrayType(js.JSValue _jsFloat64ArrayType)
    implements JSTypedArrayType {}

extension type JSNumberType(js.JSValue _jsNumberType) implements JSAnyType {}

extension type JSBooleanType(js.JSValue _jsBooleanType) implements JSAnyType {}

extension type JSStringType(js.JSValue _jsStringType) implements JSAnyType {}

extension type JSPromiseType(js.JSValue _jsPromiseType)
    implements JSObjectType {}

extension type JSSymbolType(js.JSValue _jsSymbolType) implements JSAnyType {}

extension type JSBigIntType(js.JSValue _jsBigIntType) implements JSAnyType {}

// While this type is not a JS type, it is here for convenience so we don't need
// to create a new shared library.
typedef ExternalDartReferenceType<T> = js.JSValue?;

// JSVoid is just a typedef for void. While we could just use JSUndefined, in
// the future we may be able to use this to elide `return`s in JS trampolines.
typedef JSVoidType = void;

// Extensions to expose the representation field to other internal libraries.
// Prefer this over making the representation field public as that pollutes the
// public namespace of implementing types.

extension JSAnyTypeExtension on JSAnyType {
  js.JSValue get self => _jsAnyType;
}

extension JSObjectTypeExtension on JSObjectType {
  js.JSValue get self => _jsObjectType;
}

extension JSFunctionTypeExtension on JSFunctionType {
  js.JSValue get self => _jsFunctionType;
}

extension JSExportedDartFunctionTypeExtension on JSExportedDartFunctionType {
  js.JSValue get self => _jsExportedDartFunctionType;
}

extension JSArrayTypeExtension on JSArrayType {
  js.JSValue get self => _jsArrayType;
}

extension JSBoxedDartObjectTypeExtension on JSBoxedDartObjectType {
  js.JSValue get self => _jsBoxedDartObjectType;
}

extension JSArrayBufferTypeExtension on JSArrayBufferType {
  js.JSValue get self => _jsArrayBufferType;
}

extension JSDataViewTypeExtension on JSDataViewType {
  js.JSValue get self => _jsDataViewType;
}

extension JSTypedArrayTypeExtension on JSTypedArrayType {
  js.JSValue get self => _jsTypedArrayType;
}

extension JSInt8ArrayTypeExtension on JSInt8ArrayType {
  js.JSValue get self => _jsInt8ArrayType;
}

extension JSUint8ArrayTypeExtension on JSUint8ArrayType {
  js.JSValue get self => _jsUint8ArrayType;
}

extension JSUint8ClampedArrayTypeExtension on JSUint8ClampedArrayType {
  js.JSValue get self => _jsUint8ClampedArrayType;
}

extension JSInt16ArrayTypeExtension on JSInt16ArrayType {
  js.JSValue get self => _jsInt16ArrayType;
}

extension JSUint16ArrayTypeExtension on JSUint16ArrayType {
  js.JSValue get self => _jsUint16ArrayType;
}

extension JSInt32ArrayTypeExtension on JSInt32ArrayType {
  js.JSValue get self => _jsInt32ArrayType;
}

extension JSUint32ArrayTypeExtension on JSUint32ArrayType {
  js.JSValue get self => _jsUint32ArrayType;
}

extension JSFloat32ArrayTypeExtension on JSFloat32ArrayType {
  js.JSValue get self => _jsFloat32ArrayType;
}

extension JSFloat64ArrayTypeExtension on JSFloat64ArrayType {
  js.JSValue get self => _jsFloat64ArrayType;
}

extension JSNumberTypeExtension on JSNumberType {
  js.JSValue get self => _jsNumberType;
}

extension JSBooleanTypeExtension on JSBooleanType {
  js.JSValue get self => _jsBooleanType;
}

extension JSStringTypeExtension on JSStringType {
  js.JSValue get self => _jsStringType;
}

extension JSPromiseTypeExtension on JSPromiseType {
  js.JSValue get self => _jsPromiseType;
}

extension JSSymbolTypeExtension on JSSymbolType {
  js.JSValue get self => _jsSymbolType;
}

extension JSBigIntTypeExtension on JSBigIntType {
  js.JSValue get self => _jsBigIntType;
}
