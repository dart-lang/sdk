// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Wraps a callback with translations of mouse events to touch events. Use
 * this function to invoke your callback that expects touch events after
 * touch events are created from the actual mouse events.
 */
EventListener mouseToTouchCallback(EventListener callback) {
  return (MouseEvent e) {
    var touches = <Touch>[];
    var targetTouches = <Touch>[];
    var changedTouches = <Touch>[];
    final mockTouch = new MockTouch(e);
    final mockTouchList = <Touch>[mockTouch];
    if (e.type == 'mouseup') {
      changedTouches = mockTouchList;
    } else {
      touches = mockTouchList;
      targetTouches = mockTouchList;
    }
    callback(new MockTouchEvent(e, touches, targetTouches, changedTouches));
    // Required to prevent spurious selection changes while tracking touches
    // on devices that don't support touch events.
    e.preventDefault();
  };
}

/** Helper method to attach event listeners to a [node]. */
void _addEventListeners(Element node,
    EventListener onStart, EventListener onMove, EventListener onEnd,
    EventListener onCancel, [bool capture = false]) {

  Function removeListeners;

  onEndWrapper(e) {
    removeListeners();
    return onEnd(e);
  }

  onLeaveWrapper(e) {
    removeListeners();
    return onEnd(e);
  }

  onCancelWrapper(e) {
    removeListeners();
    return onCancel(e);
  }

  if (Device.supportsTouch) {
    removeListeners = () {
      document.on.touchMove.remove(onMove, capture);
      document.on.touchEnd.remove(onEndWrapper, capture);
      document.on.touchLeave.remove(onLeaveWrapper, capture);
      document.on.touchCancel.remove(onCancelWrapper, capture);
    };

    node.on.touchStart.add((e) {
      document.on.touchMove.add(onMove, capture);
      document.on.touchEnd.add(onEndWrapper, capture);
      document.on.touchLeave.add(onLeaveWrapper, capture);
      document.on.touchCancel.add(onCancelWrapper, capture);
      return onStart(e);
    }, capture);
  } else {
    onStart = mouseToTouchCallback(onStart);
    onMove = mouseToTouchCallback(onMove);
    onEnd = mouseToTouchCallback(onEnd);
    // onLeave will never be called if the device does not support touches.

    removeListeners = () {
      document.on.mouseMove.remove(onMove, capture);
      document.on.mouseUp.remove(onEndWrapper, capture);
      document.on.touchCancel.remove(onCancelWrapper, capture);
    };

    node.on.mouseDown.add((e) {
      document.on.mouseMove.add(onMove, capture);
      document.on.mouseUp.add(onEndWrapper, capture);
      document.on.touchCancel.add(onCancelWrapper, capture);
      return onStart(e);
    }, capture);
  }
}

/**
 * Gets whether the given touch event targets the node, or one of the node's
 * children.
 */
bool _touchEventTargetsNode(event, Node node) {
  Node target = event.changedTouches[0].target;

  // TODO(rnystrom): Move this into Dom.
  // Walk up the parents looking for the node.
  while (target != null) {
    if (target == node) {
      return true;
    }
    target = target.parent;
  }

  return false;
}

interface Touchable {
  /**
   * Provide the HTML element that should respond to touch events.
   */
  Element getElement();

  /**
   * The object has received a touchend event.
   */
  void onTouchEnd();

  /**
   * The object has received a touchstart event.
   * Returns return true if you want to allow a drag sequence to begin,
   *      false you want to disable dragging for the duration of this touch.
   */
  bool onTouchStart(TouchEvent e);
}

interface Draggable extends Touchable {
  /**
   * The object's drag sequence is now complete.
   */
  void onDragEnd();

  /**
   * The object has been dragged to a new position.
   */
  void onDragMove();

  /**
   * The object has started dragging.
   * Returns true to allow a drag sequence to begin (custom behavior),
   * false to disable dragging for this touch duration (allow native scrolling).
   */
  bool onDragStart(TouchEvent e);

  bool get verticalEnabled();
  bool get horizontalEnabled();
}

class MockTouch implements Touch {
  MouseEvent wrapped;

  MockTouch(MouseEvent this.wrapped) {}

  int get clientX() => wrapped.clientX;

  int get clientY() => wrapped.clientY;

  int get identifier() => 0;

  int get pageX() => wrapped.pageX;

  int get pageY() => wrapped.pageY;

  int get screenX() => wrapped.screenX;

  int get screenY() {return wrapped.screenY; }

  EventTarget get target() => wrapped.target;

  num get webkitForce() { throw new NotImplementedException(); }
  int get webkitRadiusX() { throw new NotImplementedException(); }
  int get webkitRadiusY() { throw new NotImplementedException(); }
  num get webkitRotationAngle() { throw new NotImplementedException(); }
}

class MockTouchEvent implements TouchEvent {
  MouseEvent wrapped;
  // TODO(jacobr): these are currently Lists instead of a TouchList.
  final List<Touch> touches;
  final List<Touch> targetTouches;
  final List<Touch> changedTouches;
  MockTouchEvent(MouseEvent this.wrapped, List<Touch> this.touches,
      List<Touch> this.targetTouches,
      List<Touch> this.changedTouches) {}

  bool get bubbles() => wrapped.bubbles;

  bool get cancelBubble() => wrapped.cancelBubble;

  void set cancelBubble(bool value) { wrapped.cancelBubble = value; }

  bool get cancelable() => wrapped.cancelable;

  EventTarget get currentTarget() => wrapped.currentTarget;

  bool get defaultPrevented() => wrapped.defaultPrevented;

  int get eventPhase() => wrapped.eventPhase;

  void set returnValue(bool value) { wrapped.returnValue = value; }

  bool get returnValue() => wrapped.returnValue;

  EventTarget get srcElement() => wrapped.srcElement;

  EventTarget get target() => wrapped.target;

  int get timeStamp() => wrapped.timeStamp;

  String get type() => wrapped.type;

  void preventDefault() { wrapped.preventDefault(); }

  void stopImmediatePropagation() { wrapped.stopImmediatePropagation(); }

  void stopPropagation() { wrapped.stopPropagation(); }

  int get charCode() => wrapped.charCode;

  int get detail() => wrapped.detail;

  int get keyCode() => wrapped.keyCode;

  int get layerX() => wrapped.layerX;

  int get layerY() => wrapped.layerY;

  int get pageX() => wrapped.pageX;

  int get pageY() => wrapped.pageY;

  Window get view() => wrapped.view;

  int get which() => wrapped.which;

  bool get altKey() => wrapped.altKey;

  bool get ctrlKey() => wrapped.ctrlKey;

  bool get metaKey() => wrapped.metaKey;

  bool get shiftKey() => wrapped.shiftKey;
}
