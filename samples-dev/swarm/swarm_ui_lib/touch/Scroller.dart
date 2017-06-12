// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of touch;

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
typedef void Callback();

// Helper method to await the completion of 2 futures.
void joinFutures(List<Future> futures, Callback callback) {
  int count = 0;
  int len = futures.length;
  void helper(value) {
    count++;
    if (count == len) {
      callback();
    }
  }

  for (Future p in futures) {
    p.then(helper);
  }
}

class Scroller implements Draggable, MomentumDelegate {
  /** Pixels to move each time an arrow key is pressed. */
  static const ARROW_KEY_DELTA = 30;
  static const SCROLL_WHEEL_VELOCITY = 0.01;
  static const FAST_SNAP_DECELERATION_FACTOR = 0.84;
  static const PAGE_KEY_SCROLL_FRACTION = .85;

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

  StreamController<Event> _onScrollerStart;
  Stream<Event> _onScrollerStartStream;
  StreamController<Event> _onScrollerEnd;
  Stream<Event> _onScrollerEndStream;
  StreamController<Event> _onScrollerDragEnd;
  Stream<Event> _onScrollerDragEndStream;
  StreamController<Event> _onContentMoved;
  Stream<Event> _onContentMovedStream;
  StreamController<Event> _onDecelStart;
  Stream<Event> _onDecelStartStream;

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
  bool _isStopping = false;
  Coordinate _contentStartOffset;
  bool _started = false;
  bool _activeGesture = false;
  ScrollWatcher _scrollWatcher;

  Scroller(Element scrollableElem,
      [this.verticalEnabled = false,
      this.horizontalEnabled = false,
      momentumEnabled = true,
      lookupContentSizeDelegate = null,
      num defaultDecelerationFactor = 1,
      int scrollTechnique = null,
      bool capture = false])
      : _momentumEnabled = momentumEnabled,
        _lookupContentSizeDelegate = lookupContentSizeDelegate,
        _element = scrollableElem,
        _frame = scrollableElem.parent,
        _scrollTechnique = scrollTechnique != null
            ? scrollTechnique
            : ScrollerScrollTechnique.TRANSFORM_3D,
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
    _touchHandler.setDraggable(this);
    _touchHandler.enable(capture);

    _frame.onMouseWheel.listen((e) {
      if (e.deltaY != 0 && verticalEnabled ||
          e.deltaX != 0 && horizontalEnabled) {
        num x = horizontalEnabled ? e.deltaX : 0;
        num y = verticalEnabled ? e.deltaY : 0;
        throwDelta(x, y, FAST_SNAP_DECELERATION_FACTOR);
        e.preventDefault();
      }
    });

    _frame.onKeyDown.listen((KeyboardEvent e) {
      bool handled = false;
      // We ignore key events where further scrolling in that direction
      // would have no impact which matches default browser behavior with
      // nested scrollable areas.

      switch (e.keyCode) {
        case 33: // page-up
          throwDelta(0, _scrollSize.height * PAGE_KEY_SCROLL_FRACTION);
          handled = true;
          break;
        case 34: // page-down
          throwDelta(0, -_scrollSize.height * PAGE_KEY_SCROLL_FRACTION);
          handled = true;
          break;
        case 35: // End
          throwTo(_maxPoint.x, _minPoint.y, FAST_SNAP_DECELERATION_FACTOR);
          handled = true;
          break;
        case 36: // Home
          throwTo(_maxPoint.x, _maxPoint.y, FAST_SNAP_DECELERATION_FACTOR);
          handled = true;
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
    // TODO(jacobr): this assert fires asynchronously which could be confusing.
    if (_scrollTechnique == ScrollerScrollTechnique.RELATIVE_POSITIONING) {
      assert(_element.getComputedStyle().position != "static");
    }

    _initLayer();
  }

  Stream<Event> get onScrollerStart {
    if (_onScrollerStart == null) {
      _onScrollerStart = new StreamController<Event>.broadcast(sync: true);
      _onScrollerStartStream = _onScrollerStart.stream;
    }
    return _onScrollerStartStream;
  }

  Stream<Event> get onScrollerEnd {
    if (_onScrollerEnd == null) {
      _onScrollerEnd = new StreamController<Event>.broadcast(sync: true);
      _onScrollerEndStream = _onScrollerEnd.stream;
    }
    return _onScrollerEndStream;
  }

  Stream<Event> get onScrollerDragEnd {
    if (_onScrollerDragEnd == null) {
      _onScrollerDragEnd = new StreamController<Event>.broadcast(sync: true);
      _onScrollerDragEndStream = _onScrollerDragEnd.stream;
    }
    return _onScrollerDragEndStream;
  }

  Stream<Event> get onContentMoved {
    if (_onContentMoved == null) {
      _onContentMoved = new StreamController<Event>.broadcast(sync: true);
      _onContentMovedStream = _onContentMoved.stream;
    }
    return _onContentMovedStream;
  }

  Stream<Event> get onDecelStart {
    if (_onDecelStart == null) {
      _onDecelStart = new StreamController<Event>.broadcast(sync: true);
      _onDecelStartStream = _onDecelStart.stream;
    }
    return _onDecelStartStream;
  }

  /**
   * Add a scroll listener. This allows other classes to subscribe to scroll
   * notifications from this scroller.
   */
  void addScrollListener(ScrollListener listener) {
    if (_scrollWatcher == null) {
      _scrollWatcher = new ScrollWatcher(this);
      _scrollWatcher.initialize();
    }
    _scrollWatcher.addListener(listener);
  }

  /**
   * Adjust the new calculated scroll position based on the minimum allowed
   * position and returns the adjusted scroll value.
   */
  num _adjustValue(num newPosition, num minPosition, num maxPosition) {
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
  Coordinate get currentTarget {
    Coordinate end = _momentum.destination;
    if (end == null) {
      end = _contentOffset;
    }
    return end;
  }

  Coordinate get contentOffset => _contentOffset;

  /**
   * Animate the position of the scroller to the specified [x], [y] coordinates
   * by applying the throw gesture with the correct velocity to end at that
   * location.
   */
  void throwTo(num x, num y, [num decelerationFactor = null]) {
    reconfigure(() {
      final snappedTarget = _snapToBounds(x, y);
      // If a deceleration factor is not specified, use the existing
      // deceleration factor specified by the momentum simulator.
      if (decelerationFactor == null) {
        decelerationFactor = _momentum.decelerationFactor;
      }

      if (snappedTarget != currentTarget) {
        _momentum.abort();

        _startDeceleration(
            _momentum.calculateVelocity(
                _contentOffset, snappedTarget, decelerationFactor),
            decelerationFactor);
        if (_onDecelStart != null) {
          _onDecelStart.add(new Event(ScrollerEventType.DECEL_START));
        }
      }
    });
  }

  void throwDelta(num deltaX, num deltaY, [num decelerationFactor = null]) {
    Coordinate start = _contentOffset;
    Coordinate end = currentTarget;
    int x = end.x.toInt();
    int y = end.y.toInt();
    // If we are throwing in the opposite direction of the existing momentum,
    // cancel the current momentum.
    if (deltaX != 0 && deltaX.isNegative != (end.x - start.x).isNegative) {
      x = start.x;
    }
    if (deltaY != 0 && deltaY.isNegative != (end.y - start.y).isNegative) {
      y = start.y;
    }
    x += deltaX.toInt();
    y += deltaY.toInt();
    throwTo(x, y, decelerationFactor);
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
  num getDefaultVerticalOffset() => _maxPoint.y;
  Element getElement() => _element;
  Element getFrame() => _frame;
  num getHorizontalOffset() => _contentOffset.x;

  /**
   * [x] Value to use as reference for percent measurement. If
   *      none is provided then the content's current x offset will be used.
   * Returns the percent of the page scrolled horizontally.
   */
  num getHorizontalScrollPercent([num x = null]) {
    x = x != null ? x : _contentOffset.x;
    return (x - _minPoint.x) / (_maxPoint.x - _minPoint.x);
  }

  num getMaxPointY() => _maxPoint.y;
  num getMinPointY() => _minPoint.y;
  Momentum get momentum => _momentum;

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
    y = y != null ? y : _contentOffset.y;
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

  void onDecelerate(num x, num y) {
    _setContentOffset(x, y);
  }

  void onDecelerationEnd() {
    if (_onScrollerEnd != null) {
      _onScrollerEnd.add(new Event(ScrollerEventType.SCROLLER_END));
    }
    _started = false;
  }

  void onDragEnd() {
    _dragInProgress = false;

    bool decelerating = false;
    if (_activeGesture) {
      if (_momentumEnabled) {
        decelerating = _startDeceleration(_touchHandler.getEndVelocity());
      }
    }

    if (_onScrollerDragEnd != null) {
      _onScrollerDragEnd.add(new Event(ScrollerEventType.DRAG_END));
    }

    if (!decelerating) {
      _snapContentOffsetToBounds();
      if (_onScrollerEnd != null) {
        _onScrollerEnd.add(new Event(ScrollerEventType.SCROLLER_END));
      }
      _started = false;
    } else {
      if (_onDecelStart != null) {
        _onDecelStart.add(new Event(ScrollerEventType.DECEL_START));
      }
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
    newY = _shouldScrollVertically()
        ? _adjustValue(newY, _minPoint.y, _maxPoint.y)
        : 0;
    newX = _shouldScrollHorizontally()
        ? _adjustValue(newX, _minPoint.x, _maxPoint.x)
        : 0;
    if (!_activeGesture) {
      _activeGesture = true;
      _dragInProgress = true;
    }
    if (!_started) {
      _started = true;
      if (_onScrollerStart != null) {
        _onScrollerStart.add(new Event(ScrollerEventType.SCROLLER_START));
      }
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

  void onTouchEnd() {}

  /**
   * Prepare the scrollable area for possible movement.
   */
  bool onTouchStart(TouchEvent e) {
    reconfigure(() {
      final touch = e.touches[0];
      if (_momentum.decelerating) {
        e.preventDefault();
        e.stopPropagation();
        stop();
      }
      _contentStartOffset = _contentOffset.clone();
      _snapContentOffsetToBounds();
    });
    return true;
  }

  /**
   * Recalculate dimensions of the frame and the content. Adjust the minPoint
   * and maxPoint allowed for scrolling and scroll to a valid position. Call
   * this method if you know the frame or content has been updated. Called
   * internally on every touchstart event the frame receives.
   */
  void reconfigure(Callback callback) {
    _resize(() {
      _snapContentOffsetToBounds();
      callback();
    });
  }

  void reset() {
    stop();
    _touchHandler.reset();
    _maxOffset.x = 0;
    _maxOffset.y = 0;
    _minOffset.x = 0;
    _minOffset.y = 0;
    reconfigure(() => _setContentOffset(_maxPoint.x, _maxPoint.y));
  }

  /**
   * Recalculate dimensions of the frame and the content. Adjust the minPoint
   * and maxPoint allowed for scrolling.
   */
  void _resize(Callback callback) {
    scheduleMicrotask(() {
      if (_lookupContentSizeDelegate != null) {
        _contentSize = _lookupContentSizeDelegate();
      } else {
        _contentSize = new Size(_element.scrollWidth, _element.scrollHeight);
      }

      _scrollSize = new Size(_frame.offset.width, _frame.offset.height);
      Size adjusted = _getAdjustedContentSize();
      _maxPoint = new Coordinate(-_maxOffset.x, -_maxOffset.y);
      _minPoint = new Coordinate(
          Math.min(
              _scrollSize.width - adjusted.width + _minOffset.x, _maxPoint.x),
          Math.min(_scrollSize.height - adjusted.height + _minOffset.y,
              _maxPoint.y));
      callback();
    });
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
    if (_onContentMoved != null) {
      _onContentMoved.add(new Event(ScrollerEventType.CONTENT_MOVED));
    }
  }

  /**
   * Enable or disable momentum.
   */
  void setMomentum(bool enable) {
    _momentumEnabled = enable;
  }

  /**
   * Sets the vertical scrolled offset of the element where [y] is the amount
   * of vertical space to be scrolled, in pixels.
   */
  void setVerticalOffset(num y) {
    _setContentOffset(_contentOffset.x, y);
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
    num clampX = GoogleMath.clamp(_minPoint.x, _contentOffset.x, _maxPoint.x);
    num clampY = GoogleMath.clamp(_minPoint.y, _contentOffset.y, _maxPoint.y);
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
    return _momentum.start(
        velocity, _minPoint, _maxPoint, _contentOffset, decelerationFactor);
  }

  Coordinate stop() {
    return _momentum.stop();
  }

  /**
   * Stop the deceleration of the scrollable content given a new position in px.
   */
  void _stopDecelerating(num x, num y) {
    _momentum.stop();
    _setContentOffset(x, y);
  }

  static Function _getOffsetFunction(int scrollTechnique) {
    return scrollTechnique == ScrollerScrollTechnique.TRANSFORM_3D
        ? (el, x, y) {
            FxUtil.setTranslate(el, x, y, 0);
          }
        : (el, x, y) {
            FxUtil.setLeftAndTop(el, x, y);
          };
  }
}

// TODO(jacobr): cleanup this class of enum constants.
class ScrollerEventType {
  static const SCROLLER_START = "scroller:scroll_start";
  static const SCROLLER_END = "scroller:scroll_end";
  static const DRAG_END = "scroller:drag_end";
  static const CONTENT_MOVED = "scroller:content_moved";
  static const DECEL_START = "scroller:decel_start";
}

class ScrollerScrollTechnique {
  static const TRANSFORM_3D = 1;
  static const RELATIVE_POSITIONING = 2;
}
