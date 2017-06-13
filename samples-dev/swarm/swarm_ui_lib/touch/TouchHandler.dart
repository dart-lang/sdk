// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of touch;

/**
 * Touch Handler. Class that handles all touch events and
 * uses them to interpret higher level gestures and behaviors. TouchEvent is a
 * built in mobile safari type:
 * [http://developer.apple.com/safari/library/documentation/UserExperience/Reference/TouchEventClassReference/TouchEvent/TouchEvent.html].
 *
 * Examples of higher level gestures this class is intended to support
 * - click, double click, long click
 * - dragging, swiping, zooming
 *
 * Touch Behavior:
 *      Use this class to make your elements 'touchable' (see Touchable.dart).
 *      Intended to work with all webkit browsers.
 *
 * Drag Behavior:
 *      Use this class to make your elements 'draggable' (see draggable.js).
 *      This behavior will handle all of the required events and report the
 *      properties of the drag to you while the touch is happening and at the
 *      end of the drag sequence. This behavior will NOT perform the actual
 *      dragging (redrawing the element) for you, this responsibility is left to
 *      the client code. This behavior contains a work around for a mobile
 *      safari bug where the 'touchend' event is not dispatched when the touch
 *      goes past the bottom of the browser window.
 *      This is intended to work well in iframes.
 *      Intended to work with all webkit browsers, tested only on iPhone 3.x so
 *      far.
 *
 * Click Behavior:
 *      Not yet implemented.
 *
 * Zoom Behavior:
 *      Not yet implemented.
 *
 * Swipe Behavior:
 *      Not yet implemented.
 */
class TouchHandler {
  Touchable _touchable;
  Element _element;

  /** The absolute sum of all touch y deltas. */
  int _totalMoveY;

  /** The absolute sum of all touch x deltas. */
  int _totalMoveX;

  /**
   * A list of tuples where the first item is the horizontal component of a
   * recent relevant touch and the second item is the touch's time stamp. Old
   * touches are removed based on the max tracking time and when direction
   * changes.
   */
  List<int> _recentTouchesX;

  /**
   * A list of tuples where the first item is the vertical component of a
   * recent relevant touch and the second item is the touch's time stamp. Old
   * touches are removed based on the max tracking time and when direction
   * changes.
   */
  List<int> _recentTouchesY;

  // TODO(jacobr): make customizable by passing optional parameters to the
  // TouchHandler constructor.
  /**
   * Minimum movement of touch required to be considered a drag.
   */
  static const _MIN_TRACKING_FOR_DRAG = 2;

  /**
   * The maximum number of ms to track a touch event. After an event is older
   * than this value, it will be ignored in velocity calculations.
   */
  static const _MAX_TRACKING_TIME = 250;

  /** The maximum number of touches to track. */
  static const _MAX_TRACKING_TOUCHES = 5;

  /**
   * The maximum velocity to return, in pixels per millisecond, that is used to
   * guard against errors in calculating end velocity of a drag. This is a very
   * fast drag velocity.
   */
  static const _MAXIMUM_VELOCITY = 5;

  /**
   * The velocity to return, in pixel per millisecond, when the time stamps on
   * the events are erroneous. The browser can return bad time stamps if the
   * thread is blocked for the duration of the drag. This is a low velocity to
   * prevent the content from moving quickly after a slow drag. It is less
   * jarring if the content moves slowly after a fast drag.
   */
  static const _VELOCITY_FOR_INCORRECT_EVENTS = 1;

  Draggable _draggable;
  bool _tracking;
  bool _dragging;
  bool _touching;
  int _startTouchX;
  int _startTouchY;
  int _startTime;
  TouchEvent _lastEvent;
  int _lastTouchX;
  int _lastTouchY;
  int _lastMoveX;
  int _lastMoveY;
  int _endTime;
  int _endTouchX;
  int _endTouchY;

  TouchHandler(Touchable touchable, [Element element = null])
      : _touchable = touchable,
        _totalMoveY = 0,
        _totalMoveX = 0,
        _recentTouchesX = new List<int>(),
        _recentTouchesY = new List<int>(),
        // TODO(jmesserly): I don't like having to initialize all booleans here
        // See b/5045736
        _dragging = false,
        _tracking = false,
        _touching = false {
    _element = element != null ? element : touchable.getElement();
  }

  /**
   * Begin tracking the touchable element, it is eligible for dragging.
   */
  void _beginTracking() {
    _tracking = true;
  }

  /**
   * Stop tracking the touchable element, it is no longer dragging.
   */
  void _endTracking() {
    _tracking = false;
    _dragging = false;
    _totalMoveY = 0;
    _totalMoveX = 0;
  }

  /**
   * Correct erroneous velocities by capping the velocity if we think it's too
   * high, or setting it to a default velocity if know that the event data is
   * bad. Returns the corrected velocity.
   */
  num _correctVelocity(num velocity) {
    num absVelocity = velocity.abs();
    if (absVelocity > _MAXIMUM_VELOCITY) {
      absVelocity = _recentTouchesY.length < 6
          ? _VELOCITY_FOR_INCORRECT_EVENTS
          : _MAXIMUM_VELOCITY;
    }
    return absVelocity * (velocity < 0 ? -1 : 1);
  }

  /**
   * Start listenting for events.
   * If [capture] is True the TouchHandler should listen during the capture
   * phase.
   */
  void enable([bool capture = false]) {
    Function onEnd = (e) {
      _onEnd(e.timeStamp.toInt(), e);
    };
    _addEventListeners(_element, (e) {
      _onStart(e);
    }, (e) {
      _onMove(e);
    }, onEnd, onEnd, capture);
  }

  /**
   * Get the current horizontal drag delta. Drag delta is defined as the deltaX
   * of the start touch position and the last touch position.
   */
  int getDragDeltaX() {
    return _lastTouchX - _startTouchX;
  }

  /**
   * Get the current vertical drag delta. Drag delta is defined as the deltaY of
   * the start touch position and the last touch position.
   */
  int getDragDeltaY() {
    return _lastTouchY - _startTouchY;
  }

  /**
   * Get end velocity of the drag. This method is specific to drag behavior, so
   * if touch behavior and drag behavior is split then this should go with drag
   * behavior. End velocity is defined as deltaXY / deltaTime where deltaXY is
   * the difference between endPosition and the oldest recent position, and
   * deltaTime is the difference between endTime and the oldest recent time
   * stamp.
   */
  Coordinate getEndVelocity() {
    num velocityX = 0;
    num velocityY = 0;

    if (_recentTouchesX.length > 0) {
      num timeDeltaX = Math.max(1, _endTime - _recentTouchesX[1]);
      velocityX = (_endTouchX - _recentTouchesX[0]) / timeDeltaX;
    }

    if (_recentTouchesY.length > 0) {
      num timeDeltaY = Math.max(1, _endTime - _recentTouchesY[1]);
      velocityY = (_endTouchY - _recentTouchesY[0]) / timeDeltaY;
    }
    velocityX = _correctVelocity(velocityX);
    velocityY = _correctVelocity(velocityY);
    return new Coordinate(velocityX, velocityY);
  }

  /**
   * Return the touch of the last event.
   */
  Touch _getLastTouch() {
    assert(_lastEvent != null); // Last event not set
    return _lastEvent.touches[0];
  }

  /**
   * Is the touch manager currently tracking touch moves to detect a drag?
   */
  bool isTracking() {
    return _tracking;
  }

  /**
   * Touch end handler.
   */
  void _onEnd(int timeStamp, [TouchEvent e = null]) {
    _touching = false;
    _touchable.onTouchEnd();
    if (!_tracking || _draggable == null) {
      return;
    }
    Touch touch = _getLastTouch();
    int clientX = touch.client.x;
    int clientY = touch.client.y;
    if (_dragging) {
      _endTime = timeStamp;
      _endTouchX = clientX;
      _endTouchY = clientY;
      _recentTouchesX = _removeOldTouches(_recentTouchesX, timeStamp);
      _recentTouchesY = _removeOldTouches(_recentTouchesY, timeStamp);
      _draggable.onDragEnd();
      if (e != null) {
        e.preventDefault();
      }
      ClickBuster.preventGhostClick(_startTouchX, _startTouchY);
    }
    _endTracking();
  }

  /**
   * Touch move handler.
   */
  void _onMove(TouchEvent e) {
    if (!_tracking || _draggable == null) {
      return;
    }
    final touch = e.touches[0];
    int clientX = touch.client.x;
    int clientY = touch.client.y;
    int moveX = _lastTouchX - clientX;
    int moveY = _lastTouchY - clientY;
    int timeStamp = e.timeStamp.toInt();
    _totalMoveX += moveX.abs();
    _totalMoveY += moveY.abs();
    _lastTouchX = clientX;
    _lastTouchY = clientY;
    if (!_dragging &&
        ((_totalMoveY > _MIN_TRACKING_FOR_DRAG && _draggable.verticalEnabled) ||
            (_totalMoveX > _MIN_TRACKING_FOR_DRAG &&
                _draggable.horizontalEnabled))) {
      _dragging = _draggable.onDragStart(e);
      if (!_dragging) {
        _endTracking();
      } else {
        _startTouchX = clientX;
        _startTouchY = clientY;
        _startTime = timeStamp;
      }
    }
    if (_dragging) {
      _draggable.onDragMove();
      _lastEvent = e;
      e.preventDefault();
      _recentTouchesX =
          _removeTouchesInWrongDirection(_recentTouchesX, _lastMoveX, moveX);
      _recentTouchesY =
          _removeTouchesInWrongDirection(_recentTouchesY, _lastMoveY, moveY);
      _recentTouchesX = _removeOldTouches(_recentTouchesX, timeStamp);
      _recentTouchesY = _removeOldTouches(_recentTouchesY, timeStamp);
      _recentTouchesX.add(clientX);
      _recentTouchesX.add(timeStamp);
      _recentTouchesY.add(clientY);
      _recentTouchesY.add(timeStamp);
    }
    _lastMoveX = moveX;
    _lastMoveY = moveY;
  }

  /**
   * Touch start handler.
   */
  void _onStart(TouchEvent e) {
    if (_touching) {
      return;
    }
    _touching = true;
    if (!_touchable.onTouchStart(e) || _draggable == null) {
      return;
    }
    final touch = e.touches[0];
    _startTouchX = _lastTouchX = touch.client.x;
    _startTouchY = _lastTouchY = touch.client.y;
    int timeStamp = e.timeStamp.toInt();
    _startTime = timeStamp;
    // TODO(jacobr): why don't we just clear the lists?
    _recentTouchesX = new List<int>();
    _recentTouchesY = new List<int>();
    _recentTouchesX.add(touch.client.x);
    _recentTouchesX.add(timeStamp);
    _recentTouchesY.add(touch.client.y);
    _recentTouchesY.add(timeStamp);
    _lastEvent = e;
    _beginTracking();
  }

  /**
   * Filters the provided recent touches list to remove all touches older than
   * the max tracking time or the 5th most recent touch.
   * [recentTouches] specifies a list of tuples where the first item is the x
   * or y component of the recent touch and the second item is the touch time
   * stamp. The time of the most recent event is specified by [recentTime].
   */
  List<int> _removeOldTouches(List<int> recentTouches, int recentTime) {
    int count = 0;
    final len = recentTouches.length;
    assert(len % 2 == 0);
    while (count < len &&
            recentTime - recentTouches[count + 1] > _MAX_TRACKING_TIME ||
        (len - count) > _MAX_TRACKING_TOUCHES * 2) {
      count += 2;
    }
    return count == 0 ? recentTouches : _removeFirstN(recentTouches, count);
  }

  static List<int> _removeFirstN(List<int> list, int n) {
    return list.sublist(n);
  }

  /**
   * Filters the provided recent touches list to remove all touches except the
   * last if the move direction has changed.
   * [recentTouches] specifies a list of tuples where the first item is the x
   * or y component of the recent touch and the second item is the touch time
   * stamp. The x or y component of the most recent move is specified by
   * [recentMove].
   */
  List<int> _removeTouchesInWrongDirection(
      List<int> recentTouches, int lastMove, int recentMove) {
    if (lastMove != 0 &&
        recentMove != 0 &&
        recentTouches.length > 2 &&
        _xor(lastMove > 0, recentMove > 0)) {
      return _removeFirstN(recentTouches, recentTouches.length - 2);
    }
    return recentTouches;
  }

  // TODO(jacobr): why doesn't bool implement the xor operator directly?
  static bool _xor(bool a, bool b) => a != b;

  /**
   * Reset the touchable element.
   */
  void reset() {
    _endTracking();
    _touching = false;
  }

  /**
   * Call this method to enable drag behavior on a draggable delegate.
   * The [draggable] object can be the same as the [_touchable] object, they are
   * assigned to different members to allow for strong typing with interfaces.
   */
  void setDraggable(Draggable draggable) {
    _draggable = draggable;
  }
}
