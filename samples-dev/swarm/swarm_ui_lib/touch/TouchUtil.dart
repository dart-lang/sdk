// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of touch;

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
void _addEventListeners(Element node, EventListener onStart,
    EventListener onMove, EventListener onEnd, EventListener onCancel,
    [bool capture = false]) {
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
    var touchMoveSub;
    var touchEndSub;
    var touchLeaveSub;
    var touchCancelSub;

    removeListeners = () {
      touchMoveSub.cancel();
      touchEndSub.cancel();
      touchLeaveSub.cancel();
      touchCancelSub.cancel();
    };

    Element.touchStartEvent.forTarget(node, useCapture: capture).listen((e) {
      touchMoveSub = Element.touchMoveEvent
          .forTarget(document, useCapture: capture)
          .listen(onMove);
      touchEndSub = Element.touchEndEvent
          .forTarget(document, useCapture: capture)
          .listen(onEndWrapper);
      touchLeaveSub = Element.touchLeaveEvent
          .forTarget(document, useCapture: capture)
          .listen(onLeaveWrapper);
      touchCancelSub = Element.touchCancelEvent
          .forTarget(document, useCapture: capture)
          .listen(onCancelWrapper);
      return onStart(e);
    });
  } else {
    onStart = mouseToTouchCallback(onStart);
    onMove = mouseToTouchCallback(onMove);
    onEnd = mouseToTouchCallback(onEnd);
    // onLeave will never be called if the device does not support touches.

    var mouseMoveSub;
    var mouseUpSub;
    var touchCancelSub;

    removeListeners = () {
      mouseMoveSub.cancel();
      mouseUpSub.cancel();
      touchCancelSub.cancel();
    };

    Element.mouseDownEvent.forTarget(node, useCapture: capture).listen((e) {
      mouseMoveSub = Element.mouseMoveEvent
          .forTarget(document, useCapture: capture)
          .listen(onMove);
      mouseUpSub = Element.mouseUpEvent
          .forTarget(document, useCapture: capture)
          .listen(onEndWrapper);
      touchCancelSub = Element.touchCancelEvent
          .forTarget(document, useCapture: capture)
          .listen(onCancelWrapper);
      return onStart(e);
    });
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

abstract class Touchable {
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

abstract class Draggable implements Touchable {
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

  bool get verticalEnabled;
  bool get horizontalEnabled;
}

class MockTouch implements Touch {
  MouseEvent wrapped;

  MockTouch(MouseEvent this.wrapped) {}

  int get clientX => wrapped.client.x;

  int get clientY => wrapped.client.y;

  get client => wrapped.client;

  int get identifier => 0;

  int get pageX => wrapped.page.x;

  int get pageY => wrapped.page.y;

  int get screenX => wrapped.screen.x;

  int get screenY {
    return wrapped.screen.y;
  }

  EventTarget get target => wrapped.target;

  double get force {
    throw new UnimplementedError();
  }

  Point get page {
    throw new UnimplementedError();
  }

  int get radiusX {
    throw new UnimplementedError();
  }

  int get radiusY {
    throw new UnimplementedError();
  }

  String get region {
    throw new UnimplementedError();
  }

  num get rotationAngle {
    throw new UnimplementedError();
  }

  Point get screen {
    throw new UnimplementedError();
  }

  num get webkitForce {
    throw new UnimplementedError();
  }

  int get webkitRadiusX {
    throw new UnimplementedError();
  }

  int get webkitRadiusY {
    throw new UnimplementedError();
  }

  num get webkitRotationAngle {
    throw new UnimplementedError();
  }
}

class MockTouchEvent implements TouchEvent {
  MouseEvent wrapped;
  // TODO(jacobr): these are currently Lists instead of a TouchList.
  final List<Touch> touches;
  final List<Touch> targetTouches;
  final List<Touch> changedTouches;
  MockTouchEvent(MouseEvent this.wrapped, List<Touch> this.touches,
      List<Touch> this.targetTouches, List<Touch> this.changedTouches) {}

  bool get bubbles => wrapped.bubbles;

  bool get cancelBubble => wrapped.cancelBubble;

  void set cancelBubble(bool value) {
    wrapped.cancelBubble = value;
  }

  bool get cancelable => wrapped.cancelable;

  EventTarget get currentTarget => wrapped.currentTarget;

  bool get defaultPrevented => wrapped.defaultPrevented;

  int get eventPhase => wrapped.eventPhase;

  void set returnValue(bool value) {
    wrapped.returnValue = value;
  }

  bool get returnValue => wrapped.returnValue;

  EventTarget get target => wrapped.target;

  /*At different times, int, double, and String*/
  get timeStamp => wrapped.timeStamp;

  String get type => wrapped.type;

  void preventDefault() {
    wrapped.preventDefault();
  }

  void stopImmediatePropagation() {
    wrapped.stopImmediatePropagation();
  }

  void stopPropagation() {
    wrapped.stopPropagation();
  }

  int get charCode => wrapped.charCode;

  int get detail => wrapped.detail;

  // TODO(sra): keyCode is not on MouseEvent.
  //int get keyCode => (wrapped as KeyboardEvent).keyCode;

  int get layerX => wrapped.layer.x;

  int get layerY => wrapped.layer.y;

  int get pageX => wrapped.page.x;

  int get pageY => wrapped.page.y;

  Window get view => wrapped.view;

  int get which => wrapped.which;

  bool get altKey => wrapped.altKey;

  bool get ctrlKey => wrapped.ctrlKey;

  bool get metaKey => wrapped.metaKey;

  bool get shiftKey => wrapped.shiftKey;

  DataTransfer get clipboardData {
    throw new UnimplementedError();
  }

  List<EventTarget> deepPath() {
    throw new UnimplementedError();
  }

  bool get isTrusted {
    throw new UnimplementedError();
  }

  Point get layer {
    throw new UnimplementedError();
  }

  Element get matchingTarget {
    throw new UnimplementedError();
  }

  Point get page {
    throw new UnimplementedError();
  }

  List get path {
    throw new UnimplementedError();
  }

  bool get scoped {
    throw new UnimplementedError();
  }

  Point get screen {
    throw new UnimplementedError();
  }

  /*InputDeviceCapabilities*/ get sourceCapabilities {
    throw new UnimplementedError();
  }

  /*InputDevice*/ get sourceDevice {
    throw new UnimplementedError();
  }
}
