// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This library exists to act as a uniform abstraction layer between the user
/// facing JS interop libraries and backend specific internal representations of
/// JS types.
///
/// For consistency, all of the web backends have a version of this library.
///
/// For the time being, all JS types are erased to their respective Dart type at
/// runtime e.g. [JSString] -> [String]. Eventually, when we have inline
/// classes, we may choose to either:
///
/// 1. Use [Object] as the representation type.
/// 2. Have some analog to dart2wasm's [JSValue] as the representation type in
/// order to separate the Dart and JS type hierarchies at runtime.
/// 3. Continue using the respective Dart type.
///
/// Note that we can't use [Interceptor] to do option #2. [Interceptor] is a
/// supertype of types like [interceptors.JSString], but not a supertype of the
/// core types like [String]. This becomes relevant when we use external APIs.
/// External APIs get lowered to `js_util` calls, which cast the return value.
/// If a function returns a JavaScript string, it gets reified as a Dart
/// [String] for example. Then when we cast to [JSString] in `js_util`, we get
/// a cast failure, as [String] is not a subtype of [Interceptor].
///
/// For specific details of the JS type hierarchy, please see
/// `sdk/lib/js_interop/js_interop.dart`.
library _js_types;

import 'dart:_js_annotations';

@JS()
@staticInterop
class JSAny {}

@JS()
@staticInterop
class JSObject implements JSAny {}

@JS()
@staticInterop
class JSFunction implements JSObject {}

@JS()
@staticInterop
class JSExportedDartFunction implements JSFunction {}

@JS('Array')
@staticInterop
class JSArray implements JSObject {
  external factory JSArray();
  external factory JSArray.withLength(JSNumber length);
}

@JS()
@staticInterop
class JSBoxedDartObject implements JSObject {}

@JS()
@staticInterop
class JSArrayBuffer implements JSObject {}

@JS()
@staticInterop
class JSDataView implements JSObject {}

@JS()
@staticInterop
class JSTypedArray implements JSObject {}

@JS()
@staticInterop
class JSInt8Array implements JSTypedArray {}

@JS()
@staticInterop
class JSUint8Array implements JSTypedArray {}

@JS()
@staticInterop
class JSUint8ClampedArray implements JSTypedArray {}

@JS()
@staticInterop
class JSInt16Array implements JSTypedArray {}

@JS()
@staticInterop
class JSUint16Array implements JSTypedArray {}

@JS()
@staticInterop
class JSInt32Array implements JSTypedArray {}

@JS()
@staticInterop
class JSUint32Array implements JSTypedArray {}

@JS()
@staticInterop
class JSFloat32Array implements JSTypedArray {}

@JS()
@staticInterop
class JSFloat64Array implements JSTypedArray {}

@JS()
@staticInterop
class JSNumber implements JSAny {}

@JS()
@staticInterop
class JSBoolean implements JSAny {}

@JS()
@staticInterop
class JSString implements JSAny {}

/// [JSVoid] is just a typedef for [void]. While we could just use
/// `JSUndefined`, in the future we may be able to use this to elide `return`s
/// in JS trampolines.
typedef JSVoid = void;

@JS()
@staticInterop
class JSPromise implements JSObject {}
