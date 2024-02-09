// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This library exists to act as a uniform abstraction layer between the user
/// facing JS interop libraries and backend specific internal representations of
/// JS types.
///
/// For consistency, all of the web backends have a version of this library.
///
/// **WARNING**: You should *not* rely on these runtime types. Not only is this
/// library not guaranteed to be consistent across platforms, these types may
/// change in the future.
library _js_types;

import 'dart:_native_typed_data' as typed_data;
import 'dart:_interceptors' as interceptors;

typedef JSAnyRepType = Object;

typedef JSObjectRepType = interceptors.JSObject;

typedef JSFunctionRepType = interceptors.JavaScriptFunction;

typedef JSExportedDartFunctionRepType = interceptors.JavaScriptFunction;

typedef JSArrayRepType = interceptors.JSArray<Object?>;

typedef JSBoxedDartObjectRepType = interceptors.JSObject;

typedef JSArrayBufferRepType = typed_data.NativeByteBuffer;

typedef JSDataViewRepType = typed_data.NativeByteData;

typedef JSTypedArrayRepType = typed_data.NativeTypedData;

typedef JSInt8ArrayRepType = typed_data.NativeInt8List;

typedef JSUint8ArrayRepType = typed_data.NativeUint8List;

typedef JSUint8ClampedArrayRepType = typed_data.NativeUint8ClampedList;

typedef JSInt16ArrayRepType = typed_data.NativeInt16List;

typedef JSUint16ArrayRepType = typed_data.NativeUint16List;

typedef JSInt32ArrayRepType = typed_data.NativeInt32List;

typedef JSUint32ArrayRepType = typed_data.NativeUint32List;

typedef JSFloat32ArrayRepType = typed_data.NativeFloat32List;

typedef JSFloat64ArrayRepType = typed_data.NativeFloat64List;

typedef JSNumberRepType = double;

typedef JSBooleanRepType = bool;

typedef JSStringRepType = String;

typedef JSPromiseRepType = interceptors.JSObject;

typedef JSSymbolRepType = interceptors.JavaScriptSymbol;

typedef JSBigIntRepType = interceptors.JavaScriptBigInt;

/// [JSVoid] is just a typedef for [void]. While we could just use
/// `JSUndefined`, in the future we may be able to use this to elide `return`s
/// in JS trampolines.
typedef JSVoidRepType = void;
