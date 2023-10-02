// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library subtype_js_types_static_test;

import 'dart:js_interop';

@JS()
@staticInterop
class ExtendsJSAny extends JSAny {}
//    ^
// [web] The superclass, 'JSAny', has no unnamed constructor that takes no arguments.
//                         ^^^^^
// [analyzer] COMPILE_TIME_ERROR.NO_GENERATIVE_CONSTRUCTORS_IN_SUPERCLASS

@JS()
@staticInterop
class ImplementsJSAny implements JSAny {}

@JS()
@staticInterop
class ExtendsJSObject extends JSObject {}
//    ^
// [web] The superclass, 'JSObject', has no unnamed constructor that takes no arguments.
//                            ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NO_GENERATIVE_CONSTRUCTORS_IN_SUPERCLASS

@JS()
@staticInterop
class ImplementsJSObject implements JSObject {}

@JS()
@staticInterop
class ExtendsJSFunction extends JSFunction {}
//    ^
// [web] `@staticInterop` class 'ExtendsJSFunction' cannot have 'JSFunction' as a supertype. `JSObject` and `JSAny` are the only valid supertypes from `dart:js_interop` for `@staticInterop` classes.

@JS()
@staticInterop
class ImplementsJSFunction implements JSFunction {}
//    ^
// [web] `@staticInterop` class 'ImplementsJSFunction' cannot have 'JSFunction' as a supertype. `JSObject` and `JSAny` are the only valid supertypes from `dart:js_interop` for `@staticInterop` classes.

@JS()
@staticInterop
class ExtendsJSExportedDartFunction extends JSExportedDartFunction {}
//    ^
// [web] `@staticInterop` class 'ExtendsJSExportedDartFunction' cannot have 'JSExportedDartFunction' as a supertype. `JSObject` and `JSAny` are the only valid supertypes from `dart:js_interop` for `@staticInterop` classes.

@JS()
@staticInterop
class ImplementsJSExportedDartFunction implements JSExportedDartFunction {}
//    ^
// [web] `@staticInterop` class 'ImplementsJSExportedDartFunction' cannot have 'JSExportedDartFunction' as a supertype. `JSObject` and `JSAny` are the only valid supertypes from `dart:js_interop` for `@staticInterop` classes.

@JS()
@staticInterop
class ExtendsJSArray extends JSArray {
//    ^
// [web] `@staticInterop` class 'ExtendsJSArray' cannot have 'JSArray' as a supertype. `JSObject` and `JSAny` are the only valid supertypes from `dart:js_interop` for `@staticInterop` classes.

  // Silence error about extending class with only factories.
  external factory ExtendsJSArray();
}

@JS()
@staticInterop
class ImplementsJSArray implements JSArray {}
//    ^
// [web] `@staticInterop` class 'ImplementsJSArray' cannot have 'JSArray' as a supertype. `JSObject` and `JSAny` are the only valid supertypes from `dart:js_interop` for `@staticInterop` classes.

@JS()
@staticInterop
class ExtendsJSBoxedDartObject extends JSBoxedDartObject {}
//    ^
// [web] `@staticInterop` class 'ExtendsJSBoxedDartObject' cannot have 'JSBoxedDartObject' as a supertype. `JSObject` and `JSAny` are the only valid supertypes from `dart:js_interop` for `@staticInterop` classes.

@JS()
@staticInterop
class ImplementsJSBoxedDartObject implements JSBoxedDartObject {}
//    ^
// [web] `@staticInterop` class 'ImplementsJSBoxedDartObject' cannot have 'JSBoxedDartObject' as a supertype. `JSObject` and `JSAny` are the only valid supertypes from `dart:js_interop` for `@staticInterop` classes.

@JS()
@staticInterop
class ExtendsJSArrayBuffer extends JSArrayBuffer {}
//    ^
// [web] `@staticInterop` class 'ExtendsJSArrayBuffer' cannot have 'JSArrayBuffer' as a supertype. `JSObject` and `JSAny` are the only valid supertypes from `dart:js_interop` for `@staticInterop` classes.

@JS()
@staticInterop
class ImplementsJSArrayBuffer implements JSArrayBuffer {}
//    ^
// [web] `@staticInterop` class 'ImplementsJSArrayBuffer' cannot have 'JSArrayBuffer' as a supertype. `JSObject` and `JSAny` are the only valid supertypes from `dart:js_interop` for `@staticInterop` classes.

@JS()
@staticInterop
class ExtendsJSDataView extends JSDataView {}
//    ^
// [web] `@staticInterop` class 'ExtendsJSDataView' cannot have 'JSDataView' as a supertype. `JSObject` and `JSAny` are the only valid supertypes from `dart:js_interop` for `@staticInterop` classes.

@JS()
@staticInterop
class ImplementsJSDataView implements JSDataView {}
//    ^
// [web] `@staticInterop` class 'ImplementsJSDataView' cannot have 'JSDataView' as a supertype. `JSObject` and `JSAny` are the only valid supertypes from `dart:js_interop` for `@staticInterop` classes.

@JS()
@staticInterop
class ExtendsJSTypedArray extends JSTypedArray {}
//    ^
// [web] `@staticInterop` class 'ExtendsJSTypedArray' cannot have 'JSTypedArray' as a supertype. `JSObject` and `JSAny` are the only valid supertypes from `dart:js_interop` for `@staticInterop` classes.

@JS()
@staticInterop
class ImplementsJSTypedArray implements JSTypedArray {}
//    ^
// [web] `@staticInterop` class 'ImplementsJSTypedArray' cannot have 'JSTypedArray' as a supertype. `JSObject` and `JSAny` are the only valid supertypes from `dart:js_interop` for `@staticInterop` classes.

@JS()
@staticInterop
class ExtendsJSInt8Array extends JSInt8Array {}
//    ^
// [web] `@staticInterop` class 'ExtendsJSInt8Array' cannot have 'JSInt8Array' as a supertype. `JSObject` and `JSAny` are the only valid supertypes from `dart:js_interop` for `@staticInterop` classes.

@JS()
@staticInterop
class ImplementsJSInt8Array implements JSInt8Array {}
//    ^
// [web] `@staticInterop` class 'ImplementsJSInt8Array' cannot have 'JSInt8Array' as a supertype. `JSObject` and `JSAny` are the only valid supertypes from `dart:js_interop` for `@staticInterop` classes.

@JS()
@staticInterop
class ExtendsJSUint8Array extends JSUint8Array {}
//    ^
// [web] `@staticInterop` class 'ExtendsJSUint8Array' cannot have 'JSUint8Array' as a supertype. `JSObject` and `JSAny` are the only valid supertypes from `dart:js_interop` for `@staticInterop` classes.

@JS()
@staticInterop
class ImplementsJSUint8Array implements JSUint8Array {}
//    ^
// [web] `@staticInterop` class 'ImplementsJSUint8Array' cannot have 'JSUint8Array' as a supertype. `JSObject` and `JSAny` are the only valid supertypes from `dart:js_interop` for `@staticInterop` classes.

@JS()
@staticInterop
class ExtendsJSUint8ClampedArray extends JSUint8ClampedArray {}
//    ^
// [web] `@staticInterop` class 'ExtendsJSUint8ClampedArray' cannot have 'JSUint8ClampedArray' as a supertype. `JSObject` and `JSAny` are the only valid supertypes from `dart:js_interop` for `@staticInterop` classes.

@JS()
@staticInterop
class ImplementsJSUint8ClampedArray implements JSUint8ClampedArray {}
//    ^
// [web] `@staticInterop` class 'ImplementsJSUint8ClampedArray' cannot have 'JSUint8ClampedArray' as a supertype. `JSObject` and `JSAny` are the only valid supertypes from `dart:js_interop` for `@staticInterop` classes.

@JS()
@staticInterop
class ExtendsJSInt16Array extends JSInt16Array {}
//    ^
// [web] `@staticInterop` class 'ExtendsJSInt16Array' cannot have 'JSInt16Array' as a supertype. `JSObject` and `JSAny` are the only valid supertypes from `dart:js_interop` for `@staticInterop` classes.

@JS()
@staticInterop
class ImplementsJSInt16Array implements JSInt16Array {}
//    ^
// [web] `@staticInterop` class 'ImplementsJSInt16Array' cannot have 'JSInt16Array' as a supertype. `JSObject` and `JSAny` are the only valid supertypes from `dart:js_interop` for `@staticInterop` classes.

@JS()
@staticInterop
class ExtendsJSUint16Array extends JSUint16Array {}
//    ^
// [web] `@staticInterop` class 'ExtendsJSUint16Array' cannot have 'JSUint16Array' as a supertype. `JSObject` and `JSAny` are the only valid supertypes from `dart:js_interop` for `@staticInterop` classes.

@JS()
@staticInterop
class ImplementsJSUint16Array implements JSUint16Array {}
//    ^
// [web] `@staticInterop` class 'ImplementsJSUint16Array' cannot have 'JSUint16Array' as a supertype. `JSObject` and `JSAny` are the only valid supertypes from `dart:js_interop` for `@staticInterop` classes.

@JS()
@staticInterop
class ExtendsJSInt32Array extends JSInt32Array {}
//    ^
// [web] `@staticInterop` class 'ExtendsJSInt32Array' cannot have 'JSInt32Array' as a supertype. `JSObject` and `JSAny` are the only valid supertypes from `dart:js_interop` for `@staticInterop` classes.

@JS()
@staticInterop
class ImplementsJSInt32Array implements JSInt32Array {}
//    ^
// [web] `@staticInterop` class 'ImplementsJSInt32Array' cannot have 'JSInt32Array' as a supertype. `JSObject` and `JSAny` are the only valid supertypes from `dart:js_interop` for `@staticInterop` classes.

@JS()
@staticInterop
class ExtendsJSUint32Array extends JSUint32Array {}
//    ^
// [web] `@staticInterop` class 'ExtendsJSUint32Array' cannot have 'JSUint32Array' as a supertype. `JSObject` and `JSAny` are the only valid supertypes from `dart:js_interop` for `@staticInterop` classes.

@JS()
@staticInterop
class ImplementsJSUint32Array implements JSUint32Array {}
//    ^
// [web] `@staticInterop` class 'ImplementsJSUint32Array' cannot have 'JSUint32Array' as a supertype. `JSObject` and `JSAny` are the only valid supertypes from `dart:js_interop` for `@staticInterop` classes.

@JS()
@staticInterop
class ExtendsJSFloat32Array extends JSFloat32Array {}
//    ^
// [web] `@staticInterop` class 'ExtendsJSFloat32Array' cannot have 'JSFloat32Array' as a supertype. `JSObject` and `JSAny` are the only valid supertypes from `dart:js_interop` for `@staticInterop` classes.

@JS()
@staticInterop
class ImplementsJSFloat32Array implements JSFloat32Array {}
//    ^
// [web] `@staticInterop` class 'ImplementsJSFloat32Array' cannot have 'JSFloat32Array' as a supertype. `JSObject` and `JSAny` are the only valid supertypes from `dart:js_interop` for `@staticInterop` classes.

@JS()
@staticInterop
class ExtendsJSFloat64Array extends JSFloat64Array {}
//    ^
// [web] `@staticInterop` class 'ExtendsJSFloat64Array' cannot have 'JSFloat64Array' as a supertype. `JSObject` and `JSAny` are the only valid supertypes from `dart:js_interop` for `@staticInterop` classes.

@JS()
@staticInterop
class ImplementsJSFloat64Array implements JSFloat64Array {}
//    ^
// [web] `@staticInterop` class 'ImplementsJSFloat64Array' cannot have 'JSFloat64Array' as a supertype. `JSObject` and `JSAny` are the only valid supertypes from `dart:js_interop` for `@staticInterop` classes.

@JS()
@staticInterop
class ExtendsJSNumber extends JSNumber {}
//    ^
// [web] `@staticInterop` class 'ExtendsJSNumber' cannot have 'JSNumber' as a supertype. `JSObject` and `JSAny` are the only valid supertypes from `dart:js_interop` for `@staticInterop` classes.

@JS()
@staticInterop
class ImplementsJSNumber implements JSNumber {}
//    ^
// [web] `@staticInterop` class 'ImplementsJSNumber' cannot have 'JSNumber' as a supertype. `JSObject` and `JSAny` are the only valid supertypes from `dart:js_interop` for `@staticInterop` classes.

@JS()
@staticInterop
class ExtendsJSBoolean extends JSBoolean {}
//    ^
// [web] `@staticInterop` class 'ExtendsJSBoolean' cannot have 'JSBoolean' as a supertype. `JSObject` and `JSAny` are the only valid supertypes from `dart:js_interop` for `@staticInterop` classes.

@JS()
@staticInterop
class ImplementsJSBoolean implements JSBoolean {}
//    ^
// [web] `@staticInterop` class 'ImplementsJSBoolean' cannot have 'JSBoolean' as a supertype. `JSObject` and `JSAny` are the only valid supertypes from `dart:js_interop` for `@staticInterop` classes.

@JS()
@staticInterop
class ExtendsJSString extends JSString {}
//    ^
// [web] `@staticInterop` class 'ExtendsJSString' cannot have 'JSString' as a supertype. `JSObject` and `JSAny` are the only valid supertypes from `dart:js_interop` for `@staticInterop` classes.

@JS()
@staticInterop
class ImplementsJSString implements JSString {}
//    ^
// [web] `@staticInterop` class 'ImplementsJSString' cannot have 'JSString' as a supertype. `JSObject` and `JSAny` are the only valid supertypes from `dart:js_interop` for `@staticInterop` classes.

@JS()
@staticInterop
class ExtendsJSPromise extends JSPromise {}
//    ^
// [web] The superclass, 'JSPromise', has no unnamed constructor that takes no arguments.
// [web] `@staticInterop` class 'ExtendsJSPromise' cannot have 'JSPromise' as a supertype. `JSObject` and `JSAny` are the only valid supertypes from `dart:js_interop` for `@staticInterop` classes.
//                             ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NO_GENERATIVE_CONSTRUCTORS_IN_SUPERCLASS

@JS()
@staticInterop
class ImplementsJSPromise implements JSPromise {}
//    ^
// [web] `@staticInterop` class 'ImplementsJSPromise' cannot have 'JSPromise' as a supertype. `JSObject` and `JSAny` are the only valid supertypes from `dart:js_interop` for `@staticInterop` classes.
