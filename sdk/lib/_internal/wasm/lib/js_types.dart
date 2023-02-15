// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This library exists to act as a uniform abstraction layer between the user
/// facing JS interop libraries and backend specific internal representations of
/// JS types. For consistency, all of the web backends have a version of this
/// library.
library _js_types;

import 'dart:_js_annotations';

/// Note that the semantics of JS types on Wasm backends are slightly different
/// from the JS backends as we use static interop, and thus [JSValue], to
/// implement all of the other JS types, whereas the JS backends conflate Dart
/// types and JS types.  Because we're not sure exactly where things will end
/// up, we're moving gradually towards consistent semantics across all web
/// backends. A gradual path to consistent semantics might look something like:
/// 1) Launch MVP with JS backends conflating Dart types and JS types, and Wasm
///    backends implementing JS types with boxes. On Wasm backends, users will
///    have to explicitly coerce Dart types to JS types, possibly with some
///    overhead, whereas on JS backends users will get coercion for free. This
///    will enable some level of API sharing, without any additional performance
///    overhead on all backends.
/// 2) Introduce a flag for JS backends to support statically decoupling JS
///    types and Dart types on JS backends, while still allowing runtime
///    conflation. This will require users on JS backends to explicitly coerce
///    Dart types to JS types, but will not introduce additional runtime
///    overhead.
/// 3) Introduce a flag for JS backends to fully decouple JS types from Dart
///    types using boxes. However, we will be able to elide boxes on all
///    backends in many cases, except when JS types are upcast to [Object].
/// TODO(joshualitt): A number of issues are still TBD:
/// 1) Today Wasm backends must copy JS arrays to Dart [List]s and vice versa.
///    To match semantics, we have a few options.
///    a) Copy on JS backends, this will introduce overhead, but users can
///       always leave JS types as JS types to avoid the overhead.
///    b) Experiment with proxying. While we can proxy on the Dart side of the
///       interop boundary, we may not be able to do so on the JS side, and even
///       if we can it will involve considerable overhead and may be observable.
///       Furthermore, 'live' [List]s backed by native JS objects can be quite
///       confusing to users.
/// 2) There are many open questions around how to handle JSNull and
///    JSUndefined. For efficiency reasons, these are currently conflated on JS
///    backends, but this is not efficient on Wasm backends. We may encourage a
///    set of best practices, while allowing some divergence in behavior between
///    JS and Wasm backends until we have a better story here.
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

@JS()
@staticInterop
class JSPromise implements JSObject {}

@JS('Array')
@staticInterop
class JSArray implements JSObject {
  external factory JSArray();
  external factory JSArray.withLength(JSNumber length);
}

@JS()
@staticInterop
class JSExportedDartObject implements JSObject {}

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
