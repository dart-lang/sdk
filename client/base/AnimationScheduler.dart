// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef void AnimationCallback(num currentTime);

class CallbackData {
  final AnimationCallback callback;
  final num minTime;
  int id;

  static int _nextId;

  bool ready(num time) => minTime === null || minTime <= time;

  CallbackData(this.callback, this.minTime) {
    // TODO(jacobr): static init needs cleanup, see http://b/4161827
    if (_nextId === null) {
      _nextId = 1;
    }
    id = _nextId++;
  }
}

/**
 * Animation scheduler implementing the functionality provided by
 * [:window.requestAnimationFrame:] for platforms that do not support it
 * or support it badly.  When multiple UI components are animating at once,
 * this approach yields superior performance to calling setTimeout directly as
 * all pieces of the UI will animate at the same time resulting in fewer
 * layouts.
 */
// TODO(jacobr): use window.requestAnimationFrame when it is available and
// 60fps for the current browser.
class AnimationScheduler {
  static final FRAMES_PER_SECOND = 60;
  static final MS_PER_FRAME = 1000 ~/ FRAMES_PER_SECOND;
  static final USE_INTERVALS = false;

  /** List of callbacks to be executed next animation frame. */
  List<CallbackData> _callbacks;
  int _intervalId;
  bool _isMobileSafari = false;
  Css _safariHackCss;
  int _frameCount = 0;
  bool _webkitAnimationFrameMaybeAvailable = true;

  AnimationScheduler()
    : _callbacks = new List<CallbackData>() {
    if (_isMobileSafari) {
      // TODO(jacobr): find a better workaround for the issue that 3d transforms
      // sometimes don't render on iOS without forcing a layout.
      final element = new Element.tag('div');
      document.body.nodes.add(element);
      _safariHackCss = new Css(element.style);
      _safariHackCss.position = 'absolute';
    }
  }

  /**
   * Cancel the pending callback matching the specified [id].
   * This is not heavily optimized as typically users don't cancel animation
   * frames.
   */
  void cancelRequestAnimationFrame(int id) {
    _callbacks = _callbacks.filter((CallbackData e) => e.id != id);
  }

  /**
   * Schedule [callback] to execute at the next animation frame that occurs
   * at or after [minTime].  If [minTime] is not specified, the first available
   * animation frame is used.  Returns an id that can be used to cancel the
   * pending callback.
   */
  int requestAnimationFrame(AnimationCallback callback,
                            [Element element = null,
                             num minTime = null]) {
    final callbackData = new CallbackData(callback, minTime);
    _requestAnimationFrameHelper(callbackData);
    return callbackData.id;
  }

  void _requestAnimationFrameHelper(CallbackData callbackData) {
    _callbacks.add(callbackData);
    if (_intervalId === null) {
      _setupInterval();
    }
  }

  void _setupInterval() {
    // Assert that we never schedule multiple frames at once.
    assert(_intervalId === null);
    if (USE_INTERVALS) {
      _intervalId = window.setInterval(_step, MS_PER_FRAME);
    } else {
      if (_webkitAnimationFrameMaybeAvailable) {
        try {
          // TODO(jacobr): passing in document should not be required.
          _intervalId = window.webkitRequestAnimationFrame(
              (int ignored) { _step(); }, document);
              // TODO(jacobr) fix this odd type error.
        } catch (var e) {
          _webkitAnimationFrameMaybeAvailable = false;
        }
      }
      if (!_webkitAnimationFrameMaybeAvailable) {
        _intervalId = window.setTimeout(() { _step(); }, MS_PER_FRAME);
      }
    }
  }

  void _step() {
    if (_callbacks.isEmpty()) {
      // Cancel the interval on the first frame where there aren't actually
      // any available callbacks.
      assert(_intervalId != null);
      if (USE_INTERVALS) {
        window.clearInterval(_intervalId);
      }
      _intervalId = null;
    } else if (USE_INTERVALS == false) {
      _intervalId = null;
      _setupInterval();
    }
    int numRemaining = 0;
    int minTime = new Date.now().value + MS_PER_FRAME;

    int len = _callbacks.length;
    for (final callback in _callbacks) {
      if (!callback.ready(minTime)) {
        numRemaining++;
      }
    }

    if (numRemaining == len) {
      // TODO(jacobr): we could be more clever about this case if delayed
      // requests really become the main use case...
      return;
    }
    // Some callbacks need to be executed.
    final currentCallbacks = _callbacks;
    _callbacks = new List<CallbackData>();

    for (final callbackData in currentCallbacks) {
      if (callbackData.ready(minTime)) {
        try {
          (callbackData.callback)(minTime);
        } catch (var e) {
          final msg = e.toString();
          print('Suppressed exception ${msg} triggered by callback');
        }
      } else {
        _callbacks.add(callbackData);
      }
    }

    _frameCount++;
    if (_isMobileSafari) {
      // Hack to work around an iOS bug where sometimes animations do not
      // render if only webkit transforms were modified.
      // TODO(jacobr): find a cleaner workaround.
      int offset = _frameCount % 2;
      _safariHackCss.left = '${offset}px';
    }
  }
}
