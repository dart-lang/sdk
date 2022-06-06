// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart.js_util;

import "dart:_internal";
import "dart:_js_helper";

@patch
dynamic jsify(Object? object) => JSValue.box(jsifyRaw(object));

@patch
Object get globalThis => JSValue(globalThisRaw());

@patch
T newObject<T>() => JSValue(newObjectRaw()) as T;

@patch
bool hasProperty(Object o, String name) =>
    hasPropertyRaw(jsifyRaw(o)!, name.toJS().toAnyRef());

@patch
T getProperty<T>(Object o, String name) =>
    toDart(getPropertyRaw(jsifyRaw(o)!, name.toJS().toAnyRef())) as T;

@patch
T setProperty<T>(Object o, String name, T? value) => toDart(
    setPropertyRaw(jsifyRaw(o)!, name.toJS().toAnyRef(), jsifyRaw(value))) as T;

@patch
T callMethod<T>(Object o, String method, List<Object?> args) =>
    toDart(callMethodVarArgsRaw(
        jsifyRaw(o)!, method.toJS().toAnyRef(), args.toJS().toAnyRef())) as T;

@patch
bool instanceof(Object? o, Object type) => throw 'unimplemented';

@patch
T callConstructor<T>(Object o, List<Object?> args) =>
    toDart(callConstructorVarArgsRaw(jsifyRaw(o)!, args.toJS().toAnyRef()))!
        as T;

@patch
T add<T>(Object? first, Object? second) => throw 'unimplemented';

@patch
T subtract<T>(Object? first, Object? second) => throw 'unimplemented';

@patch
T multiply<T>(Object? first, Object? second) => throw 'unimplemented';

@patch
T divide<T>(Object? first, Object? second) => throw 'unimplemented';

@patch
T exponentiate<T>(Object? first, Object? second) => throw 'unimplemented';

@patch
T modulo<T>(Object? first, Object? second) => throw 'unimplemented';

@patch
bool equal<T>(Object? first, Object? second) => throw 'unimplemented';

@patch
bool strictEqual<T>(Object? first, Object? second) => throw 'unimplemented';

@patch
bool notEqual<T>(Object? first, Object? second) => throw 'unimplemented';

@patch
bool strictNotEqual<T>(Object? first, Object? second) => throw 'unimplemented';

@patch
bool greaterThan<T>(Object? first, Object? second) => throw 'unimplemented';

@patch
bool greaterThanOrEqual<T>(Object? first, Object? second) =>
    throw 'unimplemented';

@patch
bool lessThan<T>(Object? first, Object? second) => throw 'unimplemented';

@patch
bool lessThanOrEqual<T>(Object? first, Object? second) => throw 'unimplemented';

@patch
Future<T> promiseToFuture<T>(Object jsPromise) => throw 'unimplemented';

@patch
Object? objectGetPrototypeOf(Object? object) => throw 'unimplemented';

@patch
Object? get objectPrototype => throw 'unimplemented';

@patch
List<Object?> objectKeys(Object? object) => throw 'unimplemented';

@patch
Object? dartify(Object? object) {
  if (object is JSValue) {
    return jsObjectToDartObject(dartifyRaw(object.toAnyRef())!);
  } else {
    return object;
  }
}
