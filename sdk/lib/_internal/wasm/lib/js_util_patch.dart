// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart.js_util;

import "dart:_internal";

Never _unsupported() =>
    throw UnsupportedError('js_util is not supported by dart2wasm');

@patch
dynamic jsify(Object? object) => _unsupported();

@patch
Object get globalThis => _unsupported();

@patch
T newObject<T>() => _unsupported();

@patch
bool hasProperty(Object o, Object name) => _unsupported();

@patch
T getProperty<T>(Object o, Object name) => _unsupported();

@patch
T setProperty<T>(Object o, Object name, T? value) => _unsupported();

@patch
T callMethod<T>(Object o, Object method, List<Object?> args) => _unsupported();

@patch
bool instanceof(Object? o, Object type) => _unsupported();

@patch
T callConstructor<T>(Object o, List<Object?>? args) => _unsupported();

@patch
T add<T>(Object? first, Object? second) => _unsupported();

@patch
T subtract<T>(Object? first, Object? second) => _unsupported();

@patch
T multiply<T>(Object? first, Object? second) => _unsupported();

@patch
T divide<T>(Object? first, Object? second) => _unsupported();

@patch
T exponentiate<T>(Object? first, Object? second) => _unsupported();

@patch
T modulo<T>(Object? first, Object? second) => _unsupported();

@patch
bool equal<T>(Object? first, Object? second) => _unsupported();

@patch
bool strictEqual<T>(Object? first, Object? second) => _unsupported();

@patch
bool notEqual<T>(Object? first, Object? second) => _unsupported();

@patch
bool strictNotEqual<T>(Object? first, Object? second) => _unsupported();

@patch
bool greaterThan<T>(Object? first, Object? second) => _unsupported();

@patch
bool greaterThanOrEqual<T>(Object? first, Object? second) => _unsupported();

@patch
bool lessThan<T>(Object? first, Object? second) => _unsupported();

@patch
bool lessThanOrEqual<T>(Object? first, Object? second) => _unsupported();

@patch
bool typeofEquals<T>(Object? o, String type) => _unsupported();

@patch
Future<T> promiseToFuture<T>(Object jsPromise) => _unsupported();

@patch
Object? objectGetPrototypeOf(Object? object) => _unsupported();

@patch
Object? get objectPrototype => _unsupported();

@patch
List<Object?> objectKeys(Object? o) => _unsupported();

@patch
Object? dartify(Object? object) => _unsupported();

@patch
F allowInterop<F extends Function>(F f) => _unsupported();

@patch
Function allowInteropCaptureThis(Function f) => _unsupported();
