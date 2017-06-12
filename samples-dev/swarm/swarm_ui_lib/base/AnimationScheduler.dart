// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of base;

typedef void AnimationCallback(num currentTime);

class CallbackData {
  final AnimationCallback callback;
  final num minTime;
  int id;

  static int _nextId;

  bool ready(num time) => minTime == null || minTime <= time;

  CallbackData(this.callback, this.minTime) {
    // TODO(jacobr): static init needs cleanup, see http://b/4161827
    if (_nextId == null) {
      _nextId = 1;
    }
    id = _nextId++;
  }
}

/**
 * Animation scheduler implementing the functionality provided by
 * [:window.requestAnimationFrame:] for platforms that do not support it
 * or support it badly.  When multiple UI components are animating at once,
 * this approach yields superior performance to calling setTimeout/Timer
 * directly as all pieces of the UI will animate at the same time resulting in
 * fewer layouts.
 */
// TODO(jacobr): use window.requestAnimationFrame when it is available and
// 60fps for the current browser.
class AnimationScheduler {
  static const FRAMES_PER_SECOND = 60;
  static const MS_PER_FRAME = 1000 ~/ FRAMES_PER_SECOND;

  /** List of callbacks to be executed next animation frame. */
  List<CallbackData> _callbacks;
  bool _isMobileSafari = false;
  CssStyleDeclaration _safariHackStyle;
  int _frameCount = 0;

  AnimationScheduler() : _callbacks = new List<CallbackData>() {
    if (_isMobileSafari) {
      // TODO(jacobr): find a better workaround for the issue that 3d transforms
      // sometimes don't render on iOS without forcing a layout.
      final element = new Element.tag('div');
      document.body.nodes.add(element);
      _safariHackStyle = element.style;
      _safariHackStyle.position = 'absolute';
    }
  }

  /**
   * Cancel the pending callback matching the specified [id].
   * This is not heavily optimized as typically users don't cancel animation
   * frames.
   */
  void cancelRequestAnimationFrame(int id) {
    _callbacks = _callbacks.where((CallbackData e) => e.id != id).toList();
  }

  /**
   * Schedule [callback] to execute at the next animation frame that occurs
   * at or after [minTime].  If [minTime] is not specified, the first available
   * animation frame is used.  Returns an id that can be used to cancel the
   * pending callback.
   */
  int requestAnimationFrame(AnimationCallback callback,
      [Element element = null, num minTime = null]) {
    final callbackData = new CallbackData(callback, minTime);
    _requestAnimationFrameHelper(callbackData);
    return callbackData.id;
  }

  void _requestAnimationFrameHelper(CallbackData callbackData) {
    _callbacks.add(callbackData);
    _setupInterval();
  }

  void _setupInterval() {
    window.requestAnimationFrame((num ignored) {
      _step();
    });
  }

  void _step() {
    if (_callbacks.isEmpty) {
      // Cancel the interval on the first frame where there aren't actually
      // any available callbacks.
    } else {
      _setupInterval();
    }
    int numRemaining = 0;
    int minTime = new DateTime.now().millisecondsSinceEpoch + MS_PER_FRAME;

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
        } catch (e) {
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
      _safariHackStyle.left = '${offset}px';
    }
  }
}
