// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_internal" show patch;
import "dart:nativewrappers" show NativeFieldWrapperClass1;

@patch
@pragma("vm:entry-point")
abstract interface class Mutex {
  @patch
  factory Mutex._(String debug_name) => _MutexImpl(debug_name);
}

@pragma("vm:entry-point")
base class _MutexImpl extends NativeFieldWrapperClass1 implements Mutex {
  _MutexImpl(this.debug_name) {
    _initialize();
  }

  @pragma("vm:external-name", "Mutex_Initialize")
  external void _initialize();

  @patch
  @pragma("vm:external-name", "Mutex_Lock")
  external void _lock();

  @patch
  @pragma("vm:external-name", "Mutex_Unlock")
  external void _unlock();

  R runLocked<R>(R Function() action) {
    _lock();
    try {
      return action();
    } finally {
      _unlock();
    }
  }

  String debug_name;
}

@patch
@pragma("vm:entry-point")
abstract interface class ConditionVariable {
  @patch
  factory ConditionVariable._() => _ConditionVariableImpl();
}

@pragma('vm:entry-point')
base class _ConditionVariableImpl extends NativeFieldWrapperClass1
    implements ConditionVariable {
  _ConditionVariableImpl() {
    _initialize();
  }

  @pragma("vm:external-name", "ConditionVariable_Initialize")
  external void _initialize();

  @patch
  @pragma("vm:external-name", "ConditionVariable_Wait")
  external void wait(Mutex mutex);

  @patch
  @pragma("vm:external-name", "ConditionVariable_Notify")
  external void notify();
}
