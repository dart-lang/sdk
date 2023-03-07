// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This library exists to act as a uniform abstraction layer between the user
/// facing JS interop libraries and backend specific internal representations of
/// JS types. For consistency, all of the web backends have a version of this
/// library.
library _js_types;

import 'dart:_js_annotations';
import 'dart:_interceptors' as interceptors;
import 'dart:_internal' show patch;
import 'dart:typed_data';

/// For the time being, all JS types are conflated with Dart types on JS
/// backends. See `sdk/lib/_internal/wasm/lib/js_types.dart` for more details.

/// For specific details of the JS type hierarchy, please see
/// `sdk/lib/js_interop/js_interop.dart`.
/// TODO(joshualitt): Some users may want type safety instead of conflating Dart
/// types and JS types. For those users, we should have an opt-in flag where we
/// swap out these typedef for actual types that would not implicitly coerce
/// statically to their Dart counterparts and back.
typedef JSAny = Object;
typedef JSObject = interceptors.JSObject;
typedef JSFunction = Function;
typedef JSExportedDartFunction = Function;
typedef JSArray = List<JSAny?>;
typedef JSExportedDartObject = Object;
typedef JSArrayBuffer = ByteBuffer;
typedef JSDataView = ByteData;
typedef JSTypedArray = TypedData;
typedef JSInt8Array = Int8List;
typedef JSUint8Array = Uint8List;
typedef JSUint8ClampedArray = Uint8ClampedList;
typedef JSInt16Array = Int16List;
typedef JSUint16Array = Uint16List;
typedef JSInt32Array = Int32List;
typedef JSUint32Array = Uint32List;
typedef JSFloat32Array = Float32List;
typedef JSFloat64Array = Float64List;
typedef JSNumber = double;
typedef JSBoolean = bool;
typedef JSString = String;
typedef JSVoid = void;

@JS()
@staticInterop
class JSPromise {}
