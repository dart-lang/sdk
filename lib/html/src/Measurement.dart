// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef Object ComputeValue();

class _MeasurementRequest<T> {
  final ComputeValue computeValue;
  final Completer<T> completer;
  Object value;
  bool exception = false;
  _MeasurementRequest(this.computeValue, this.completer);
}

const _MEASUREMENT_MESSAGE = "DART-MEASURE";
List<_MeasurementRequest> _pendingRequests;
List<TimeoutHandler> _pendingMeasurementFrameCallbacks;
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
    // after the current event loop is unwound and calling the function is
    // a noop when zero requests are pending.
    window.on.message.add((e) => _completeMeasurementFutures());
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
void _addMeasurementFrameCallback(TimeoutHandler callback) {
  if (_pendingMeasurementFrameCallbacks === null) {
    _pendingMeasurementFrameCallbacks = <TimeoutHandler>[];
    _maybeScheduleMeasurementFrame();
  }
  _pendingMeasurementFrameCallbacks.add(callback);
}

/**
 * Returns a [Future] whose value will be the result of evaluating
 * [computeValue] during the next safe measurement interval.
 * The next safe measurement interval is after the current event loop has
 * unwound but before the browser has rendered the page.
 * It is important that the [computeValue] function only queries the html
 * layout and html in any way.
 */
Future _createMeasurementFuture(ComputeValue computeValue,
                                Completer completer) {
  if (_pendingRequests === null) {
    _pendingRequests = <_MeasurementRequest>[];
    _maybeScheduleMeasurementFrame();
  }
  _pendingRequests.add(new _MeasurementRequest(computeValue, completer));
  return completer.future;
}

/**
 * Complete all pending measurement futures evaluating them in a single batch
 * so that the the browser is guaranteed to avoid multiple layouts.
 */
void _completeMeasurementFutures() {
  if (_nextMeasurementFrameScheduled == false) {
    // Ignore spurious call to this function.
    return;
  }

  _nextMeasurementFrameScheduled = false;
  // We must compute all new values before fulfilling the futures as
  // the onComplete callbacks for the futures could modify the DOM making
  // subsequent measurement calculations expensive to compute.
  if (_pendingRequests !== null) {
    for (_MeasurementRequest request in _pendingRequests) {
      try {
        request.value = request.computeValue();
      } catch (e) {
        request.value = e;
        request.exception = true;
      }
    }
  }

  final completedRequests = _pendingRequests;
  final readyMeasurementFrameCallbacks = _pendingMeasurementFrameCallbacks;
  _pendingRequests = null;
  _pendingMeasurementFrameCallbacks = null;
  if (completedRequests !== null) {
    for (_MeasurementRequest request in completedRequests) {
      if (request.exception) {
        request.completer.completeException(request.value);
      } else {
        request.completer.complete(request.value);
      }
    }
  }

  if (readyMeasurementFrameCallbacks !== null) {
    for (TimeoutHandler handler in readyMeasurementFrameCallbacks) {
      // TODO(jacobr): wrap each call to a handler in a try-catch block.
      handler();
    }
  }
}
