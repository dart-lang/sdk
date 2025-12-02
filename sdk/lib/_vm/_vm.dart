// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart._vm;

import "dart:_internal" show unsafeCast;

@pragma("vm:deeply-immutable")
@pragma('vm:entry-point')
final class ThreadLocal<T> {
  /// Creates dart thread local variable.
  ThreadLocal() : _id = _allocateId();

  /// Returns the value of this thread-local variable or throws [StateError]
  /// if it has no value.
  T get value {
    if (!_hasValue(_id)) {
      throw StateError(
        "Attempt to access variable that was not assigned a value.",
      );
    }
    return unsafeCast<T>(_getValue(_id));
  }

  /// Sets the value of this variable. Overwrites old value if it was previously
  /// set.
  set value(T newValue) {
    _setValue(_id, newValue);
  }

  /// Returns `true` if some value was assigned to this variable.
  bool get hasValue => _hasValue(_id);

  // Clears this variable of its assigned value.
  void clearValue() {
    _clearValue(_id);
  }

  @pragma("vm:external-name", "ScopedThreadLocal_allocateId")
  external static int _allocateId();

  @pragma("vm:external-name", "ScopedThreadLocal_hasValue")
  external static bool _hasValue(int id);

  @pragma("vm:external-name", "ScopedThreadLocal_getValue")
  external static Object? _getValue(int id);

  @pragma("vm:external-name", "ScopedThreadLocal_setValue")
  external static void _setValue(int id, Object? value);

  @pragma("vm:external-name", "ScopedThreadLocal_clearValue")
  external static void _clearValue(int id);

  final int _id;
}

@pragma("vm:deeply-immutable")
@pragma('vm:entry-point')
final class ScopedThreadLocal<T> {
  /// Creates scoped thread-local variable with given [initializer] function.
  ///
  /// [initializer] must be trivially shareable.
  ScopedThreadLocal([this._initializer]);

  /// Execute [f] binding this [ScopedThreadLocal] to the given
  /// [value] for the duration of the execution.
  R runWith<R>(T new_value, R Function(T) f) {
    bool had_value = variable.hasValue;
    T? previous_value = had_value ? variable.value : null;
    variable.value = new_value;
    R result = f(new_value);
    if (had_value) {
      variable.value = previous_value as T;
    } else {
      variable.clearValue();
    }
    return result;
  }

  /// Execute [f] initializing this [ScopedThreadLocal] using default initializer if needed.
  /// Throws [StateError] if this [ScopedThreadLocal] does not have an initializer.
  R runInitialized<R>(R Function(T) f) {
    bool had_value = variable.hasValue;
    T? previous_value = had_value ? variable.value : null;
    if (!variable.hasValue) {
      if (_initializer == null) {
        throw StateError(
          "No initializer was provided for this ScopedThreadLocal.",
        );
      }
      variable.value = _initializer!();
    }
    R result = f(variable.value);
    if (had_value) {
      variable.value = previous_value as T;
    } else {
      variable.clearValue();
    }
    return result;
  }

  /// Returns the value specified by the closest enclosing invocation of
  /// [runWith] or [runInititalized] or throws [StateError] if this
  /// [ScopedThreadLocal] is not bound to a value.
  T get value => variable.value;

  /// Returns `true` if this [ScopedThreadLocal] is bound to a value.
  bool get isBound => variable.hasValue;
  final T Function()? _initializer;

  final variable = ThreadLocal<T>();
}

@pragma("vm:deeply-immutable")
@pragma('vm:entry-point')
final class FinalThreadLocal<T> {
  /// Creates thread local value with the given [initializer] function.
  ///
  /// The value can be assigned only once, remains assigned for the duration
  /// of this dart thread lifetime.
  ///
  /// [initializer] must be trivially shareable.
  FinalThreadLocal(this._initializer);

  /// Returns the value bound to [FinalThreadLocal].
  T get value {
    if (!variable.hasValue) {
      variable.value = _initializer();
    }
    return variable.value;
  }

  set value(_) {
    throw StateError("Final value can not be updated");
  }

  final T Function() _initializer;

  final variable = ThreadLocal<T>();
}
