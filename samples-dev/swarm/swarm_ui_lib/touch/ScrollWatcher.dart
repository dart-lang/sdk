// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of touch;

abstract class ScrollListener {
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
 * listen for scroll events from instances of Scroller.
 * TODO(jacobr): this class is obsolete.
 */
class ScrollWatcher {
  Scroller _scroller;

  List<ScrollListener> _listeners;

  Element _scrollerEl;

  ScrollWatcher(Scroller scroller)
      : _scroller = scroller,
        _listeners = new List<ScrollListener>() {}

  void addListener(ScrollListener listener) {
    _listeners.add(listener);
  }

  /**
   * Send the scroll event to all listeners.
   * [decelerating] is true if the offset is changing because of deceleration.
   */
  void _dispatchScroll(num scrollX, num scrollY, [bool decelerating = false]) {
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
    _scroller.onContentMoved.listen((e) {
      _onContentMoved(e);
    });
  }

  /**
   * This callback is invoked any time the scroller content offset changes.
   */
  void _onContentMoved(Event e) {
    num scrollX = _scroller.getHorizontalOffset();
    num scrollY = _scroller.getVerticalOffset();
    _dispatchScroll(scrollX, scrollY);
  }
}
