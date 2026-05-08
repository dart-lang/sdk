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
library _js_types;

import 'dart:_native_typed_data' as typed_data;
import 'dart:_interceptors' as interceptors;

extension type JSAnyType(Object _jsAnyType) implements Object {}

extension type JSObjectType(interceptors.JSObject _jsObjectType)
    implements JSAnyType {}

extension type JSFunctionType(interceptors.JavaScriptFunction _jsFunctionType)
    implements JSObjectType {}

extension type JSExportedDartFunctionType(
  interceptors.JavaScriptFunction _jsExportedDartFunctionType
)
    implements JSFunctionType {}

extension type JSArrayType(interceptors.JSArray<Object?> _jsArrayType)
    implements JSObjectType {}

extension type JSBoxedDartObjectType(
  interceptors.JSObject _jsBoxedDartObjectType
)
    implements JSObjectType {}

extension type JSArrayBufferType(
  typed_data.NativeArrayBuffer _jsArrayBufferType
)
    implements JSObjectType {}

extension type JSDataViewType(typed_data.NativeByteData _jsDataViewType)
    implements JSObjectType {}

extension type JSTypedArrayType(typed_data.NativeTypedData _jsTypedArrayType)
    implements JSObjectType {}

extension type JSInt8ArrayType(typed_data.NativeInt8List _jsInt8ArrayType)
    implements JSTypedArrayType {}

extension type JSUint8ArrayType(typed_data.NativeUint8List _jsUint8ArrayType)
    implements JSTypedArrayType {}

extension type JSUint8ClampedArrayType(
  typed_data.NativeUint8ClampedList _jsUint8ClampedArrayType
)
    implements JSTypedArrayType {}

extension type JSInt16ArrayType(typed_data.NativeInt16List _jsInt16ArrayType)
    implements JSTypedArrayType {}

extension type JSUint16ArrayType(typed_data.NativeUint16List _jsUint16ArrayType)
    implements JSTypedArrayType {}

extension type JSInt32ArrayType(typed_data.NativeInt32List _jsInt32ArrayType)
    implements JSTypedArrayType {}

extension type JSUint32ArrayType(typed_data.NativeUint32List _jsUint32ArrayType)
    implements JSTypedArrayType {}

extension type JSFloat32ArrayType(
  typed_data.NativeFloat32List _jsFloat32ArrayType
)
    implements JSTypedArrayType {}

extension type JSFloat64ArrayType(
  typed_data.NativeFloat64List _jsFloat64ArrayType
)
    implements JSTypedArrayType {}

extension type JSNumberType(double _jsNumberType) implements JSAnyType {}

extension type JSBooleanType(bool _jsBooleanType) implements JSAnyType {}

extension type JSStringType(String _jsStringType) implements JSAnyType {}

extension type JSPromiseType(interceptors.JSObject _jsPromiseType)
    implements JSObjectType {}

extension type JSSymbolType(interceptors.JavaScriptSymbol _jsSymbolType)
    implements JSAnyType {}

extension type JSBigIntType(interceptors.JavaScriptBigInt _jsBigIntType)
    implements JSAnyType {}

// While this type is not a JS type, it is here for convenience so we don't need
// to create a new shared library.
typedef ExternalDartReferenceType<T> = T;

// JSVoid is just a typedef for void.
typedef JSVoidType = void;

// Extensions to expose the representation field to other internal libraries.
// Prefer this over making the representation field public as that pollutes the
// public namespace of implementing types.

extension JSAnyTypeExtension on JSAnyType {
  Object get self => _jsAnyType;
}

extension JSObjectTypeExtension on JSObjectType {
  interceptors.JSObject get self => _jsObjectType;
}

extension JSFunctionTypeExtension on JSFunctionType {
  interceptors.JavaScriptFunction get self => _jsFunctionType;
}

extension JSExportedDartFunctionTypeExtension on JSExportedDartFunctionType {
  interceptors.JavaScriptFunction get self => _jsExportedDartFunctionType;
}

extension JSArrayTypeExtension on JSArrayType {
  interceptors.JSArray<Object?> get self => _jsArrayType;
}

extension JSBoxedDartObjectTypeExtension on JSBoxedDartObjectType {
  interceptors.JSObject get self => _jsBoxedDartObjectType;
}

extension JSArrayBufferTypeExtension on JSArrayBufferType {
  typed_data.NativeArrayBuffer get self => _jsArrayBufferType;
}

extension JSDataViewTypeExtension on JSDataViewType {
  typed_data.NativeByteData get self => _jsDataViewType;
}

extension JSTypedArrayTypeExtension on JSTypedArrayType {
  typed_data.NativeTypedData get self => _jsTypedArrayType;
}

extension JSInt8ArrayTypeExtension on JSInt8ArrayType {
  typed_data.NativeInt8List get self => _jsInt8ArrayType;
}

extension JSUint8ArrayTypeExtension on JSUint8ArrayType {
  typed_data.NativeUint8List get self => _jsUint8ArrayType;
}

extension JSUint8ClampedArrayTypeExtension on JSUint8ClampedArrayType {
  typed_data.NativeUint8ClampedList get self => _jsUint8ClampedArrayType;
}

extension JSInt16ArrayTypeExtension on JSInt16ArrayType {
  typed_data.NativeInt16List get self => _jsInt16ArrayType;
}

extension JSUint16ArrayTypeExtension on JSUint16ArrayType {
  typed_data.NativeUint16List get self => _jsUint16ArrayType;
}

extension JSInt32ArrayTypeExtension on JSInt32ArrayType {
  typed_data.NativeInt32List get self => _jsInt32ArrayType;
}

extension JSUint32ArrayTypeExtension on JSUint32ArrayType {
  typed_data.NativeUint32List get self => _jsUint32ArrayType;
}

extension JSFloat32ArrayTypeExtension on JSFloat32ArrayType {
  typed_data.NativeFloat32List get self => _jsFloat32ArrayType;
}

extension JSFloat64ArrayTypeExtension on JSFloat64ArrayType {
  typed_data.NativeFloat64List get self => _jsFloat64ArrayType;
}

extension JSNumberTypeExtension on JSNumberType {
  double get self => _jsNumberType;
}

extension JSBooleanTypeExtension on JSBooleanType {
  bool get self => _jsBooleanType;
}

extension JSStringTypeExtension on JSStringType {
  String get self => _jsStringType;
}

extension JSPromiseTypeExtension on JSPromiseType {
  interceptors.JSObject get self => _jsPromiseType;
}

extension JSSymbolTypeExtension on JSSymbolType {
  interceptors.JavaScriptSymbol get self => _jsSymbolType;
}

extension JSBigIntTypeExtension on JSBigIntType {
  interceptors.JavaScriptBigInt get self => _jsBigIntType;
}
