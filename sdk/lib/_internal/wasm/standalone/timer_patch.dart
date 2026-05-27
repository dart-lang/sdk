// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_internal' show patch;
import 'dart:_embedder' as embedder;
import 'dart:_wasm';

@patch
class Timer {
  @patch
  static Timer _createTimer(Duration duration, void callback()) {
    return _OneShotTimer(duration, callback);
  }

  @patch
  static Timer _createPeriodicTimer(
    Duration duration,
    void callback(Timer timer),
  ) {
    return _PeriodicTimer(duration, callback);
  }
}

abstract class _Timer implements Timer {
  final int _microseconds;
  int _tick;
  WasmExternRef? _handle;

  @override
  int get tick => _tick;

  @override
  bool get isActive => !_handle.isNull;

  _Timer(Duration duration)
    : _microseconds = duration.inMicroseconds,
      _tick = 0,
      _handle = WasmExternRef.nullRef {
    _schedule();
  }

  void _schedule();
  void _processTick();

  @override
  void cancel() {
    if (!_handle.isNull) {
      embedder.clearSchedule(_handle);
      _handle = WasmExternRef.nullRef;
    }
  }

  static WasmVoid runtimeCallback(WasmAnyRef timer) {
    final dartTimer = timer.toObject() as _Timer;
    dartTimer._processTick();
    return WasmVoid();
  }
}

class _OneShotTimer extends _Timer {
  final void Function() _callback;

  _OneShotTimer(Duration duration, this._callback) : super(duration);

  @override
  void _schedule() {
    _handle = embedder.scheduleOnce(
      _microseconds.toWasmI64(),
      WasmFunction.fromFunction(_Timer.runtimeCallback),
      WasmAnyRef.fromObject(this),
    );
  }

  _processTick() {
    _tick++;
    _handle = WasmExternRef.nullRef;
    _callback();
  }
}

class _PeriodicTimer extends _Timer {
  final void Function(Timer) _callback;
  int _start = 0;

  _PeriodicTimer(Duration duration, this._callback) : super(duration);

  @override
  void _schedule() {
    _start = embedder.currentTimeMicros().toInt();
    _handle = embedder.scheduleRepeated(
      _microseconds.toWasmI64(),
      WasmFunction.fromFunction(_Timer.runtimeCallback),
      WasmAnyRef.fromObject(this),
    );
  }

  @override
  void _processTick() {
    _tick++;
    if (_microseconds > 0) {
      final int duration = embedder.currentTimeMicros().toInt() - _start;
      if (duration > _tick * _microseconds) {
        _tick = duration ~/ _microseconds;
      }
    }
    _callback(this);
  }
}

@patch
class _AsyncRun {
  @patch
  static void _scheduleImmediate(void callback()) {
    embedder.queueMicrotask(
      WasmFunction.fromFunction(_runtimeCallback),
      WasmAnyRef.fromObject(callback),
    );
  }

  static WasmVoid _runtimeCallback(WasmAnyRef callbackFunction) {
    final function = callbackFunction.toObject() as void Function();
    function();

    return WasmVoid();
  }
}
