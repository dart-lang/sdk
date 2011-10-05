// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface ScrollListener {
  /**
   * The callback invoked for a scroll event.
   * [decelerating] specifies whether or not the content is moving due
   * to deceleration. It should be false if the content is moving because the
   * user is dragging the content.
   */
  void onScrollerMoved(double scrollX, double scrollY, bool decelerating);
}

/**
 * The scroll watcher is intended to provide a single way to
 * listen for scroll events from instances of Scroller, abstracting the
 * various nuances between momentum strategies that require different scroll
 * listening strategies.
 */
class ScrollWatcher {
  Scroller _scroller;

  List<ScrollListener> _listeners;

  TimeoutHandler _boundOnDecel;
  Element _scrollerEl;
  int _decelIntervalId;

  ScrollWatcher(Scroller scroller)
      : _scroller = scroller, _listeners = new List<ScrollListener>() {
    _boundOnDecel = () { _onDecelerate(); };
  }

  void addListener(ScrollListener listener) {
    _listeners.add(listener);
  }

  /**
   * Send the scroll event to all listeners.
   * [decelerating] is true if the offset is changing because of deceleration.
   */
  void _dispatchScroll(num scrollX, num scrollY,
                       [bool decelerating = false]) {
    for (final listener in _listeners) {
      listener.onScrollerMoved(scrollX, scrollY, decelerating);
    }
  }

  /**
   * Initializes elements and event handlers. Must be called after construction
   * and before usage.
   */
  void initialize() {
    _scrollerEl = _scroller.getElement();
    _scroller.onContentMoved.add((e) { _onContentMoved(e); });
  }

  /**
   * This callback is invoked any time the scroller content offset changes.
   */
  void _onContentMoved(Event e) {
    num scrollX = _scroller.getHorizontalOffset();
    num scrollY = _scroller.getVerticalOffset();
    _dispatchScroll(scrollX, scrollY);
  }

  /**
   * This callback is invoked every 30ms while deceleration is happening.
   */
  void _onDecelerate() {
    final transform = StyleUtil.getCurrentTransformMatrix(_scrollerEl);
    num scrollX = transform.m41;
    num scrollY = transform.m42;
    _dispatchScroll(scrollX, scrollY, true);
  }

  /**
   * When deceleration begins, clear the interval if it already exists and set
   * up a new one.
   */
  void _onDecelerationStart(Event e) {
    if (_decelIntervalId !== null) {
      window.clearInterval(_decelIntervalId);
    }
    // TODO(jacobr): use Env.requestAnimationFrame and renable this.
    // Right now this would kill our performance and is not relevant given
    // we are using timeout based momentum.
    // _decelIntervalId = window.setInterval(_boundOnDecel, 30);
  }

  /**
   * When scrolling ends, clear the interval if it exists.
   */
  void _onScrollerEnd(Event e) {
    if (_decelIntervalId !== null) {
      window.clearInterval(_decelIntervalId);
    }
    _onContentMoved(e);
  }
}
