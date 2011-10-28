// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Implementation of a custom scrolling behavior.
 * This behavior overrides native scrolling for an area. This area can be a
 * single defined part of a page, the entire page, or several different parts
 * of a page.
 *
 * To use this scrolling behavior you need to define a frame and the content.
 * The frame defines the area that the content will scroll within. The frame and
 * content must both be HTML Elements, with the content being a direct child of
 * the frame. Usually the frame is smaller in size than the content. This is
 * not necessary though, if the content is smaller then bouncing will occur to
 * provide feedback that you are past the scrollable area.
 *
 * The scrolling behavior works using the webkit translate3d transformation,
 * which means browsers that do not have hardware accelerated transformations
 * will not perform as well using this. Simple scrolling should be fine even
 * without hardware acceleration, but animating momentum and deceleration is
 * unacceptably slow without it. There is also the option to use relative
 * positioning (setting the left and top styles).
 *
 * For this to work properly you need to set -webkit-text-size-adjust to 'none'
 * on an ancestor element of the frame, or on the frame itself. If you forget
 * this you may see the text content of the scrollable area changing size as it
 * moves.
 *
 * The behavior is intended to support vertical and horizontal scrolling, and
 * scrolling with momentum when a touch gesture flicks with enough velocity.
 */

class Scroller implements Draggable, MomentumDelegate {

  /** Pixels to move each time an arrow key is pressed. */
  static final ARROW_KEY_DELTA = 30;
  static final SCROLL_WHEEL_VELOCITY = 0.01;
  static final FAST_SNAP_DECELERATION_FACTOR = 0.84;
  static final PAGE_KEY_SCROLL_FRACTION = .85;

  // TODO(jacobr): remove this static variable.
  static bool _dragInProgress = false;

  /** The node that will actually scroll. */
  Element _element;

  /**
   * Frame is the node that will serve as the container for the scrolling
   * content.
   */
  Element _frame;

  /** Touch manager to track the events on the scrollable area. */
  TouchHandler _touchHandler;

  Momentum _momentum;

  EventListenerList _onScrollerStart;
  EventListenerList _onScrollerEnd;
  EventListenerList _onScrollerDragEnd;
  EventListenerList _onContentMoved;
  EventListenerList _onDecelStart;

  /** Set if vertical scrolling should be enabled. */
  bool verticalEnabled;

  /** Set if horizontal scrolling should be enabled. */
  bool horizontalEnabled;

  /**
   * Set if momentum should be enabled.
   */
  bool _momentumEnabled;

  /** Set which type of scrolling translation technique should be used. */
  int _scrollTechnique;

  /**
   * The maximum coordinate that the left upper corner of the content can scroll
   * to.
   */
  Coordinate _maxPoint;

  /**
   * An offset to subtract from the maximum coordinate that the left upper
   * corner of the content can scroll to.
   */
  Coordinate _maxOffset;

  /**
   * An offset to add to the minimum coordinate that the left upper corner of
   * the content can scroll to.
   */
  Coordinate _minOffset;

  /** Initialize the current content offset. */
  Coordinate _contentOffset;

  // TODO(jacobr): the function type is
  // [:Function(Element, num, num)->void:].
  /**
   * The function to use that will actually translate the scrollable node.
   */
  Function _setOffsetFunction;
  /**
   * Function that returns the content size that can be specified instead of
   * querying the DOM.
   */
  Function _lookupContentSizeDelegate;

  Size _scrollSize;
  Size _contentSize;
  Coordinate _minPoint;
  bool _activeTransition = false;
  bool _isStopping = false;
  Coordinate _contentStartOffset;
  bool _started = false;
  bool _activeGesture = false;
  ScrollWatcher _scrollWatcher;

  Scroller(Element scrollableElem, [this.verticalEnabled = false,
           this.horizontalEnabled = false,
           this._momentumEnabled = true,
           this._lookupContentSizeDelegate = null,
           num defaultDecelerationFactor = 1,
           int scrollTechnique = null, bool capture = false])
      : _element = scrollableElem,
        _frame = scrollableElem.parent,
        _scrollTechnique = scrollTechnique !== null
            ? scrollTechnique : ScrollerScrollTechnique.TRANSFORM_3D,
        _minPoint = new Coordinate(0, 0),
        _maxPoint = new Coordinate(0, 0),
        _maxOffset = new Coordinate(0, 0),
        _minOffset = new Coordinate(0, 0),
        _contentOffset = new Coordinate(0, 0) {
    _touchHandler = new TouchHandler(this, scrollableElem.parent);
    _momentum = new Momentum(this, defaultDecelerationFactor);

    Element parentElem = scrollableElem.parent;
    assert(parentElem != null);
    _setOffsetFunction = _getOffsetFunction(_scrollTechnique);
    _element.on.transitionEnd.add((event) { onTransitionEnd(event); });
    _touchHandler.setDraggable(this);
    _touchHandler.enable(capture);

    _frame.on.mouseWheel.add((e) {
      if (e.wheelDeltaY != 0 && verticalEnabled ||
          e.wheelDeltaX != 0 && horizontalEnabled) {
        num x = horizontalEnabled ? e.wheelDeltaX : 0;
        num y = verticalEnabled ? e.wheelDeltaY : 0;
        if (throwDelta(x, y, FAST_SNAP_DECELERATION_FACTOR)) {
          e.preventDefault();
        }
      }
    });

    _frame.on.keyDown.add((KeyboardEvent e) {
        bool handled = false;
        // We ignore key events where further scrolling in that direction
        // would have no impact which matches default browser behavior with
        // nested scrollable areas.

        switch(e.keyCode) {
          case 33: // page-up
            handled = throwDelta(
                0,
                _scrollSize.height * PAGE_KEY_SCROLL_FRACTION);
            break;
          case 34: // page-down
            handled = throwDelta(
                0, -_scrollSize.height * PAGE_KEY_SCROLL_FRACTION);
            break;
          case 35: // End
            handled = throwTo(_maxPoint.x, _minPoint.y,
                FAST_SNAP_DECELERATION_FACTOR);
            break;
          case 36: // Home
            handled = throwTo(_maxPoint.x,_maxPoint.y,
                FAST_SNAP_DECELERATION_FACTOR);
            break;
/* TODO(jacobr): enable arrow keys when the don't conflict with other
   application keyboard shortcuts.
          case 38: // up
            handled = throwDelta(
                0,
                ARROW_KEY_DELTA,
                FAST_SNAP_DECELERATION_FACTOR);
            break;
          case 40: // down
            handled = throwDelta(
                0, -ARROW_KEY_DELTA,
                FAST_SNAP_DECELERATION_FACTOR);
            break;
          case 37: // left
            handled = throwDelta(
                ARROW_KEY_DELTA, 0,
                FAST_SNAP_DECELERATION_FACTOR);
            break;
          case 39: // right
            handled = throwDelta(
                -ARROW_KEY_DELTA,
                0,
                FAST_SNAP_DECELERATION_FACTOR);
            break;
            */
        }
        if (handled) {
          e.preventDefault();
        }
      });
    // The scrollable element must be relatively positioned.
    assert(_scrollTechnique != ScrollerScrollTechnique.RELATIVE_POSITIONING ||
           window.getComputedStyle(_element, null).position != "static");
    _initLayer();
  }

  EventListenerList get onScrollerStart() {
    if (_onScrollerStart === null) {
      _onScrollerStart = new SimpleEventListenerList();
    }
    return _onScrollerStart;
  }

  EventListenerList get onScrollerEnd() {
    if (_onScrollerEnd === null) {
      _onScrollerEnd = new SimpleEventListenerList();
    }
    return _onScrollerEnd;
  }

  EventListenerList get onScrollerDragEnd() {
    if (_onScrollerDragEnd === null) {
      _onScrollerDragEnd = new SimpleEventListenerList();
    }
    return _onScrollerDragEnd;
  }

  EventListenerList get onContentMoved() {
    if (_onContentMoved === null) {
      _onContentMoved = new SimpleEventListenerList();
    }
    return _onContentMoved;
  }

  EventListenerList get onDecelStart() {
    if (_onDecelStart === null) {
      _onDecelStart = new SimpleEventListenerList();
    }
    return _onDecelStart;
  }


  /**
   * Add a scroll listener. This allows other classes to subscribe to scroll
   * notifications from this scroller.
   */
  void addScrollListener(ScrollListener listener) {
    if (_scrollWatcher === null) {
      _scrollWatcher = new ScrollWatcher(this);
      _scrollWatcher.initialize();
    }
    _scrollWatcher.addListener(listener);
  }

  /**
   * Adjust the new calculated scroll position based on the minimum allowed
   * position and returns the adjusted scroll value.
   */
  num _adjustValue(num newPosition, num minPosition,
                      num maxPosition) {
    assert(minPosition <= maxPosition);

    if (newPosition < minPosition) {
      newPosition -= (newPosition - minPosition) / 2;
    } else {
      if (newPosition > maxPosition) {
        newPosition -= (newPosition - maxPosition) / 2;
      }
    }
    return newPosition;
  }

  /**
   * Coordinate we would end up at if we did nothing.
   */
  Coordinate get currentTarget() {
    Coordinate end = _momentum.destination;
    if (end === null) {
      end = _contentOffset;
    }
    return end;
  }

  Coordinate get contentOffset() => _contentOffset;

  /**
   * Animate the position of the scroller to the specified [x], [y] coordinates
   * by applying the throw gesture with the correct velocity to end at that
   * location.
   * Return false if no delta needs to be applied.
   */
  bool throwTo(num x, num y,
               [num decelerationFactor = null]) {
    reconfigure();
    final snappedTarget = _snapToBounds(x, y);
    // If a deceleration factor is not specified, use the existing
    // deceleration factor specified by the momentum simulator.
    if (decelerationFactor == null) {
      decelerationFactor = _momentum.decelerationFactor;
    }

    if (snappedTarget != currentTarget) {
      _momentum.abort();
      reconfigure();

      _startDeceleration(
          _momentum.calculateVelocity(
              _contentOffset,
              snappedTarget,
              decelerationFactor),
          decelerationFactor);
      onDecelStart.dispatch(new Event(ScrollerEventType.DECEL_START));
      return true;
    } else {
      return false;
    }
  }

  bool throwDelta(num deltaX, num deltaY, [num decelerationFactor = null]) {
    Coordinate start = _contentOffset;
    Coordinate end = currentTarget;
    int x = end.x.toInt();
    int y = end.y.toInt();
    // If we are throwing in the opposite direction of the existing momentum,
    // cancel the current momentum.
    if (deltaX != 0 && deltaX.isNegative() != (end.x - start.x).isNegative()) {
      x = start.x;
    }
    if (deltaY != 0 && deltaY.isNegative() != (end.y - start.y).isNegative()) {
      y = start.y;
    }
    x += deltaX.toInt();
    y += deltaY.toInt();
    return throwTo(x, y, decelerationFactor);
  }

  void animateTo(num x, num y, [num duration = null,
                 String timingFunction = null]) {
    if (duration !== null && duration != 0
        && _scrollTechnique == ScrollerScrollTechnique.TRANSFORM_3D) {
      _setWebkitTransition(_element, duration, StyleUtil.TRANSFORM_STYLE,
                           timingFunction);
    }
    _setContentOffset(x, y);
  }

  void setPosition(num x, num y) {
    _momentum.abort();
    _contentOffset.x = x;
    _contentOffset.y = y;
    _snapContentOffsetToBounds();
    _setContentOffset(_contentOffset.x, _contentOffset.y);
  }
  /**
   * Adjusted content size is a size with the combined largest height and width
   * of both the content and the frame.
   */
  Size _getAdjustedContentSize() {
    return new Size(Math.max(_scrollSize.width, _contentSize.width),
                    Math.max(_scrollSize.height, _contentSize.height));
  }

  // TODO(jmesserly): these should be properties instead of get* methods
  num getDefaultVerticalOffset() =>  _maxPoint.y;
  Element getElement() => _element;
  Element getFrame() => _frame;
  num getHorizontalOffset() => _contentOffset.x;

  /**
   * [x] Value to use as reference for percent measurement. If
   *      none is provided then the content's current x offset will be used.
   * Returns the percent of the page scrolled horizontally.
   */
  num getHorizontalScrollPercent([num x = null]) {
    x = x !== null ? x : _contentOffset.x;
    return (x - _minPoint.x) / (_maxPoint.x - _minPoint.x);
  }

  num getMaxPointY()=> _maxPoint.y;
  num getMinPointY() => _minPoint.y;
  Momentum get momentum() => _momentum;

  /**
   * Provide access to the touch handler that the scroller created to manage
   * touch events.
   */
  TouchHandler getTouchHandler() => _touchHandler;
  num getVerticalOffset() => _contentOffset.y;

  /**
   * [y] value is used as reference for percent measurement. If
   * none is provided then the content's current y offset will be used.
   */
  num getVerticalScrollPercent([num y = null]) {
    y = y !== null ? y : _contentOffset.y;
    return (y - _minPoint.y) / Math.max(1, _maxPoint.y - _minPoint.y);
  }

  /**
   * Initialize the dom elements necessary for the scrolling to work.
   */
  void _initLayer() {
    // The scrollable node provided to Scroller must be a direct child
    // of the scrollable frame.
    // TODO(jacobr): Figure out why this is failing on dartium.
    // assert(_element.parent == _frame);
    _setContentOffset(_maxPoint.x, _maxPoint.y);
  }

  void onDecelerate(num x, num y, [num duration = 0,
                    String timingFunction = null]) {
    // TODO(jacobr): remove once dartc fixes default args.
    if (duration === null) {
      duration = 0;
    }
    animateTo(x, y, duration, timingFunction);
  }

  void onDecelerationEnd() {
    _setWebkitTransition(_element, 0);
    onScrollerEnd.dispatch(new Event(ScrollerEventType.SCROLLER_END));
    _started = false;
  }

  void onDragEnd() {
    _dragInProgress = false;

    bool decelerating = false;
    if (_activeGesture) {
      if (_momentumEnabled && !_activeTransition) {
        decelerating = _startDeceleration(_touchHandler.getEndVelocity());
      }
    }

    onScrollerDragEnd.dispatch(new Event(ScrollerEventType.DRAG_END));

    if (!decelerating) {
      _snapContentOffsetToBounds();
      onScrollerEnd.dispatch(new Event(ScrollerEventType.SCROLLER_END));
      _started = false;
    } else {
      onDecelStart.dispatch(new Event(ScrollerEventType.DECEL_START));
    }
    _activeGesture = false;
  }

  void onDragMove() {
    if (_isStopping || (!_activeGesture && _dragInProgress)) {
      return;
    }

    assert(_contentStartOffset != null); // Content start not set
    Coordinate contentStart = _contentStartOffset;
    num newX = contentStart.x + _touchHandler.getDragDeltaX();
    num newY = contentStart.y + _touchHandler.getDragDeltaY();
    newY = _shouldScrollVertically() ?
        _adjustValue(newY, _minPoint.y, _maxPoint.y) : 0;
    newX = _shouldScrollHorizontally() ?
        _adjustValue(newX, _minPoint.x, _maxPoint.x) : 0;
    if (!_activeGesture) {
      _activeGesture = true;
      _dragInProgress = true;
    }
    if (!_started) {
      _started = true;
      onScrollerStart.dispatch(new Event(ScrollerEventType.SCROLLER_START));
    }
    _setContentOffset(newX, newY);
  }

  bool onDragStart(TouchEvent e) {
    if (e.touches.length > 1) {
      return false;
    }
    bool shouldHorizontal = _shouldScrollHorizontally();
    bool shouldVertical = _shouldScrollVertically();
    bool verticalish = _touchHandler.getDragDeltaY().abs() >
        _touchHandler.getDragDeltaX().abs();
    return !!(shouldVertical || shouldHorizontal && !verticalish);
  }

  void onTouchEnd() {
  }

  /**
   * Prepare the scrollable area for possible movement.
   */
  bool onTouchStart(TouchEvent e) {
    reconfigure();
    final touch = e.touches[0];
    if (_momentum.decelerating) {
      e.preventDefault();
      e.stopPropagation();
      stop();
    } else {
      _setWebkitTransition(_element, 0);
    }
    _contentStartOffset = _contentOffset.clone();
    _snapContentOffsetToBounds();
    return true;
  }

  /**
   * Transition end event handler.
   */
  void onTransitionEnd(Event e) {
    if (e.target == _element) {
      _activeTransition = false;
      _momentum.onTransitionEnd();
    }
  }

  /**
   * Recalculate dimensions of the frame and the content. Adjust the minPoint
   * and maxPoint allowed for scrolling and scroll to a valid position. Call
   * this method if you know the frame or content has been updated. Called
   * internally on every touchstart event the frame receives.
   */
  void reconfigure() {
    _resize();
    _snapContentOffsetToBounds();
  }

  void reset() {
    stop();
    _touchHandler.reset();
    _setWebkitTransition(_element, 0);
    setMinOffset(0, 0);
    setMaxOffset(0, 0);
    reconfigure();
    _setContentOffset(_maxPoint.x, _maxPoint.y);
  }

  /**
   * Recalculate dimensions of the frame and the content. Adjust the minPoint
   * and maxPoint allowed for scrolling.
   */
  void _resize() {
    _scrollSize = new Size(_frame.offsetWidth, _frame.offsetHeight);
    _contentSize = _lookupContentSizeDelegate !== null ?
        _lookupContentSizeDelegate() :
        new Size(_element.scrollWidth, _element.scrollHeight);
    Size adjusted = _getAdjustedContentSize();
    _maxPoint = new Coordinate(-_maxOffset.x, -_maxOffset.y);
    _minPoint = new Coordinate(
        Math.min(
            _scrollSize.width - adjusted.width + _minOffset.x, _maxPoint.x),
        Math.min(
            _scrollSize.height - adjusted.height + _minOffset.y, _maxPoint.y));
  }

  Coordinate _snapToBounds(num x, num y) {
    num clampX = GoogleMath.clamp(_minPoint.x, x, _maxPoint.x);
    num clampY = GoogleMath.clamp(_minPoint.y, y, _maxPoint.y);
    return new Coordinate(clampX, clampY);
  }

  /**
   * Translate the content to a new position specified in px.
   */
  void _setContentOffset(num x, num y) {
    _contentOffset.x = x;
    _contentOffset.y = y;
    _setOffsetFunction(_element, x, y);
    onContentMoved.dispatch(new Event(ScrollerEventType.CONTENT_MOVED));
  }

  /**
   * Sets the offset to subtract from the maximum coordinate that the left upper
   * corner of the content can scroll to.
   */
  void setMaxOffset(num x, num y) {
    _maxOffset.x = x;
    _maxOffset.y = y;
    _resize();
  }

  /**
   * Sets the offset to add to the minimum coordinate that the left upper corner
   * of the content can scroll to.
   */
  void setMinOffset(num x, num y) {
    _minOffset.x = x;
    _minOffset.y = y;
    _resize();
  }

  /**
   * Enable or disable momentum.
   */
  void setMomentum(bool enable) {
    _momentumEnabled = enable;
  }

  /**
   * Update the scroll technique used for animating the scrollable area.
   */
  void setScrollTechnique(int technique) {
    _scrollTechnique = technique;
    _setOffsetFunction = _getOffsetFunction(technique);

    // The scrollable element must be relatively positioned.
    assert(technique != ScrollerScrollTechnique.RELATIVE_POSITIONING ||
        window.getComputedStyle(_element, null).position != "static");

    if (technique != ScrollerScrollTechnique.TRANSFORM_3D) {
      FxUtil.clearWebkitTransition(_element);
      FxUtil.clearWebkitTransform(_element);
    }
    if (technique != ScrollerScrollTechnique.RELATIVE_POSITIONING) {
      FxUtil.setLeftAndTop(_element, 0, 0);
    }
    _setOffsetFunction(_element, _contentOffset.x, _contentOffset.y);
  }

  /**
   * Sets the vertical scrolled offset of the element where [y] is the amount
   * of vertical space to be scrolled, in pixels.
   */
  void setVerticalOffset(num y) {
    _setContentOffset(_contentOffset.x, y);
  }

  /**
   * Applies a webkit transition on the element where the [duration] of the
   * animation is specified in ms.
   */
  void _setWebkitTransition(Element el, num duration, [String property = null,
                            String timingFunction = null]) {
    _activeTransition = duration > 0;
    FxUtil.setWebkitTransition(el, duration, property, timingFunction);
  }

  /**
   * Whether the scrollable area should scroll horizontally. Only
   * returns true if the client has enabled horizontal scrolling, and the
   * content is wider than the frame.
   */
  bool _shouldScrollHorizontally() {
    return horizontalEnabled && _scrollSize.width < _contentSize.width;
  }

  /**
   * Whether the scrollable area should scroll vertically. Only
   * returns true if the client has enabled vertical scrolling.
   * Vertical bouncing will occur even if frame is taller than content, because
   * this is what iPhone web apps tend to do. If this is not the desired
   * behavior, either disable vertical scrolling for this scroller or add a
   * 'bouncing' parameter to this interface.
   */
  bool _shouldScrollVertically() {
    return verticalEnabled;
  }

  /**
   * In the event that the content is currently beyond the bounds of
   * the frame, snap it back in to place.
   */
  void _snapContentOffsetToBounds() {
    num clampX =
        GoogleMath.clamp(_minPoint.x, _contentOffset.x, _maxPoint.x);
    num clampY =
        GoogleMath.clamp(_minPoint.y, _contentOffset.y, _maxPoint.y);
    if (_contentOffset.x != clampX || _contentOffset.y != clampY) {
      _setContentOffset(clampX, clampY);
    }
  }

  /**
   * Initiate the deceleration behavior given a flick [velocity].
   * Returns true if deceleration has been initiated.
   */
  bool _startDeceleration(Coordinate velocity,
                          [num decelerationFactor = null]) {
    if (!_shouldScrollHorizontally()) {
      velocity.x = 0;
    }
    if (!_shouldScrollVertically()) {
      velocity.y = 0;
    }
    assert(_minPoint != null); // Min point is not set
    assert(_maxPoint != null); // Max point is not set
    return _momentum.start(velocity, _minPoint, _maxPoint, _contentOffset,
                           decelerationFactor);
  }

  Coordinate stop() {
    Coordinate velocity = _momentum.stop();

    if (_momentum.decelerating) {
      CSSMatrix transform1 = StyleUtil.getCurrentTransformMatrix(
          _element);
      if (!_activeTransition) {
        _stopDecelerating(transform1.m41, transform1.m42);
        return velocity;
      }
      _contentOffset.x = transform1.m41;
      _contentOffset.y = transform1.m42;
      _isStopping = true;
      window.setTimeout(() {
        CSSMatrix transform2 = StyleUtil.getCurrentTransformMatrix(
            _element);
        _setWebkitTransition(_element, 0);
        window.setTimeout(function() { _isStopping = false; }, 0);
        num deltaX = transform2.m41 - transform1.m41;
        num deltaY = transform2.m42 - transform1.m42;
        num newX = transform2.m41 + 2 * deltaX;
        num newY = transform2.m42 + 2 * deltaY;
        newX = GoogleMath.clamp(newX, _minPoint.x, _maxPoint.x);
        newY = GoogleMath.clamp(newY, _minPoint.y, _maxPoint.y);
        _stopDecelerating(newX, newY);
      }, 0);
    }
    return velocity;
  }

  /**
   * Stop the deceleration of the scrollable content given a new position in px.
   */
  void _stopDecelerating(num x, num y) {
    _momentum.stop();
    _setContentOffset(x, y);
  }

  static Function _getOffsetFunction(int scrollTechnique) {
    return scrollTechnique == ScrollerScrollTechnique.TRANSFORM_3D ?
        (el, x, y) { FxUtil.setTranslate(el, x, y, 0); } :
        (el, x, y) { FxUtil.setLeftAndTop(el, x, y); };
  }
}

// TODO(jacobr): cleanup this class of enum constants.
class ScrollerEventType {
  static final SCROLLER_START = "scroller:scroll_start";
  static final SCROLLER_END = "scroller:scroll_end";
  static final DRAG_END = "scroller:drag_end";
  static final CONTENT_MOVED = "scroller:content_moved";
  static final DECEL_START = "scroller:decel_start";
}

// TODO(jacobr): for now this ignores capture.
class SimpleEventListenerList implements EventListenerList {
  // Ignores capture for now.
  List<EventListener> _listeners;

  SimpleEventListenerList() : _listeners = new List<EventListener>() { }

  EventListenerList add(EventListener handler, [bool useCapture = false]) {
    _add(handler, useCapture);
    return this;
  }

  EventListenerList remove(EventListener handler, [bool useCapture = false]) {
    _remove(handler, useCapture);
    return this;
  }

  EventListenerList addCapture(EventListener handler) {
    _add(handler, true);
    return this;
  }

  EventListenerList removeCapture(EventListener handler) {
    _remove(handler, true);
    return this;
  }

  void _add(EventListener handler, bool useCapture) {
    _listeners.add(handler);
  }

  void _remove(EventListener handler, bool useCapture) {
    // TODO(jacobr): implemenet as needed.
    throw 'Not implemented yet.';
  }

  bool dispatch(Event evt) {
    for (EventListener listener in _listeners) {
      listener(evt);
    }
  }
}

class ScrollerScrollTechnique {
  static final TRANSFORM_3D = 1;
  static final RELATIVE_POSITIONING = 2;
}
