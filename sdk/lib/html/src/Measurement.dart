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

typedef void _MeasurementCallback();


/**
 * This class attempts to invoke a callback as soon as the current event stack
 * unwinds, but before the browser repaints.
 */
abstract class _MeasurementScheduler {
  bool _nextMeasurementFrameScheduled = false;
  _MeasurementCallback _callback;

  _MeasurementScheduler(this._callback);

  /**
   * Creates the best possible measurement scheduler for the current platform.
   */
  factory _MeasurementScheduler.best(_MeasurementCallback callback) {
    if (_isMutationObserverSupported()) {
      return new _MutationObserverScheduler(callback);
    }
    return new _PostMessageScheduler(callback);
  }

  /**
   * Schedules a measurement callback if one has not been scheduled already.
   */
  void maybeSchedule() {
    if (this._nextMeasurementFrameScheduled) {
      return;
    }
    this._nextMeasurementFrameScheduled = true;
    this._schedule();
  }

  /**
   * Does the actual scheduling of the callback.
   */
  void _schedule();

  /**
   * Handles the measurement callback and forwards it if necessary.
   */
  void _onCallback() {
    // Ignore spurious messages.
    if (!_nextMeasurementFrameScheduled) {
      return;
    }
    _nextMeasurementFrameScheduled = false;
    this._callback();
  }
}

/**
 * Scheduler which uses window.postMessage to schedule events.
 */
class _PostMessageScheduler extends _MeasurementScheduler {
  const _MEASUREMENT_MESSAGE = "DART-MEASURE";

  _PostMessageScheduler(_MeasurementCallback callback): super(callback) {
      // Messages from other windows do not cause a security risk as
      // all we care about is that _handleMessage is called
      // after the current event loop is unwound and calling the function is
      // a noop when zero requests are pending.
      window.on.message.add(this._handleMessage);
  }

  void _schedule() {
    window.postMessage(_MEASUREMENT_MESSAGE, "*");
  }

  _handleMessage(e) {
    this._onCallback();
  }
}

/**
 * Scheduler which uses a MutationObserver to schedule events.
 */
class _MutationObserverScheduler extends _MeasurementScheduler {
  MutationObserver _observer;
  Element _dummy;

  _MutationObserverScheduler(_MeasurementCallback callback): super(callback) {
    // Mutation events get fired as soon as the current event stack is unwound
    // so we just make a dummy event and listen for that.
    _observer = new MutationObserver(this._handleMutation);
    _dummy = new DivElement();
    _observer.observe(_dummy, attributes: true);
  }

  void _schedule() {
    // Toggle it to trigger the mutation event.
    _dummy.hidden = !_dummy.hidden;
  }

  _handleMutation(List<MutationRecord> mutations, MutationObserver observer) {
    this._onCallback();
  }
}


List<_MeasurementRequest> _pendingRequests;
List<TimeoutHandler> _pendingMeasurementFrameCallbacks;
_MeasurementScheduler _measurementScheduler = null;

void _maybeScheduleMeasurementFrame() {
  if (_measurementScheduler == null) {
    _measurementScheduler =
      new _MeasurementScheduler.best(_completeMeasurementFutures);
  }
  _measurementScheduler.maybeSchedule();
}

/**
 * Registers a [callback] which is called after the next batch of measurements
 * completes. Even if no measurements completed, the callback is triggered
 * when they would have completed to avoid confusing bugs if it happened that
 * no measurements were actually requested.
 */
void _addMeasurementFrameCallback(TimeoutHandler callback) {
  if (_pendingMeasurementFrameCallbacks == null) {
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
  if (_pendingRequests == null) {
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
  // We must compute all new values before fulfilling the futures as
  // the onComplete callbacks for the futures could modify the DOM making
  // subsequent measurement calculations expensive to compute.
  if (_pendingRequests != null) {
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
  if (completedRequests != null) {
    for (_MeasurementRequest request in completedRequests) {
      if (request.exception) {
        request.completer.completeException(request.value);
      } else {
        request.completer.complete(request.value);
      }
    }
  }

  if (readyMeasurementFrameCallbacks != null) {
    for (TimeoutHandler handler in readyMeasurementFrameCallbacks) {
      // TODO(jacobr): wrap each call to a handler in a try-catch block.
      handler();
    }
  }
}
