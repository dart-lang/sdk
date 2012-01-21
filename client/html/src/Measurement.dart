// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

bool _inMeasurementFrame = false;

final _MEASUREMENT_MESSAGE = "DART-MEASURE";

Queue<MeasurementCallback> _pendingMeasurementFrameCallbacks;
bool _nextMeasurementFrameScheduled = false;
bool _firstMeasurementRequest = true;

void _maybeScheduleMeasurementFrame() {
  if (_nextMeasurementFrameScheduled) return;

  _nextMeasurementFrameScheduled = true;
  // postMessage gives us a way to receive a callback after the current
  // event listener has unwound but before the browser has repainted.
  if (_firstMeasurementRequest) {
    // Messages from other windows do not cause a security risk as
    // all we care about is that _onCompleteMeasurementRequests is called
    // after the current event loop is unwound and calling
    // _runMeasurementFrames is a noop when zero requests are pending.
    window.on.message.add((e) => _runMeasurementFrames());
    _firstMeasurementRequest = false;
  }

  // TODO(jacobr): other mechanisms such as setImmediate and
  // requestAnimationFrame may work better of platforms that support them.
  // The key is we need a way to execute code immediately after the current
  // event listener queue unwinds.
  window.postMessage(_MEASUREMENT_MESSAGE, "*");
}

/**
 * Registers a [callback] which is called after the next batch of measurements
 * completes. Even if no measurements completed, the callback is triggered
 * when they would have completed to avoid confusing bugs if it happened that
 * no measurements were actually requested.
 */
void _addMeasurementFrameCallback(MeasurementCallback callback) {
  assert(callback != null);
  if (_pendingMeasurementFrameCallbacks === null) {
    _pendingMeasurementFrameCallbacks = new Queue<MeasurementCallback>();
  }
  _maybeScheduleMeasurementFrame();
  _pendingMeasurementFrameCallbacks.add(callback);
}

/**
 * Run all pending measurement frames evaluating them in a single batch
 * so that the the browser is guaranteed to avoid multiple layouts.
 */
void _runMeasurementFrames() {
  if (_nextMeasurementFrameScheduled == false || _inMeasurementFrame) {
    // Ignore spurious call to this function.
    return;
  }

  _inMeasurementFrame = true;

  final layoutCallbacks = <LayoutCallback>[];
  while (!_pendingMeasurementFrameCallbacks.isEmpty()) {
    MeasurementCallback measurementCallback =
        _pendingMeasurementFrameCallbacks.removeFirst();
    try {
      final layoutCallback = measurementCallback();
      if (layoutCallback != null) {
        layoutCallbacks.add(layoutCallback);
      }
    } catch (Object e) {
      window.console.error(
          'Caught exception in measurement frame callback: ${e}');
      // TODO(jacobr): throw this exception again in the correct way.
    }
  }

  _inMeasurementFrame = false;
  _nextMeasurementFrameScheduled = false;

  for (LayoutCallback layoutCallback in layoutCallbacks) {
    try {
      layoutCallback();
    } catch (Object e) {
      window.console.error('Caught exception in layout callback: ${e}');
      // TODO(jacobr): throw this exception again in the correct way.
    }
  }
}
