// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of base;

/**
 * This class has static fields that hold objects that this isolate
 * uses to interact with the environment.  Which objects are available
 * depend on how the isolate was started.  In the UI isolate
 * of the browser, the window object is available.
 */
class Env {
  static AnimationScheduler _animationScheduler;

  /**
   * Provides functionality similar to [:window.requestAnimationFrame:] for
   * all platforms. [callback] is executed on the next animation frame that
   * occurs at or after [minTime].  If [minTime] is not specified, the first
   * available animation frame is used.  Returns an id that can be used to
   * cancel the pending callback.
   */
  static int requestAnimationFrame(AnimationCallback callback,
      [Element element = null, num minTime = null]) {
    if (_animationScheduler == null) {
      _animationScheduler = new AnimationScheduler();
    }
    return _animationScheduler.requestAnimationFrame(
        callback, element, minTime);
  }

  /**
   * Cancel the pending callback callback matching the specified [id].
   */
  static void cancelRequestAnimationFrame(int id) {
    _animationScheduler.cancelRequestAnimationFrame(id);
  }
}

typedef void XMLHttpRequestCompleted(HttpRequest req);
