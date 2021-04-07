// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library _late_helper;

import 'dart:_internal' show LateError;

void throwLateFieldADI(String fieldName) => throw LateError.fieldADI(fieldName);

/// A boxed variable used for lowering `late` variables when they are local or
/// uninitialized statics.
///
/// The [LateError]s produced have empty variable names.
class _Cell {
  Object? _value;

  _Cell() {
    // `this` is a unique sentinel.
    _value = this;
  }

  @pragma('dart2js:tryInline')
  @pragma('dart2js:as:trust')
  T readLocal<T>() => _readLocal() as T;

  @pragma('dart2js:tryInline')
  @pragma('dart2js:as:trust')
  T readField<T>() => _readField() as T;

  Object? _readLocal() {
    if (identical(_value, this)) throw LateError.localNI('');
    return _value;
  }

  Object? _readField() {
    if (identical(_value, this)) throw LateError.fieldNI('');
    return _value;
  }

  void set value(Object? v) {
    _value = v;
  }

  void set finalLocalValue(Object? v) {
    // TODO(fishythefish): Throw [LateError.localADI] if this occurs during
    // recursive initialization.
    if (!identical(_value, this)) throw LateError.localAI('');
    _value = v;
  }

  void set finalFieldValue(Object? v) {
    // TODO(fishythefish): Throw [LateError.fieldADI] if this occurs during
    // recursive initialization.
    if (!identical(_value, this)) throw LateError.fieldAI('');
    _value = v;
  }
}
