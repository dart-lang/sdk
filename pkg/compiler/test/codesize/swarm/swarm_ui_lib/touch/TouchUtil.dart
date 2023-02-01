// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of touch;

/// Wraps a callback with translations of mouse events to touch events. Use
/// this function to invoke your callback that expects touch events after
/// touch events are created from the actual mouse events.
EventListener mouseToTouchCallback(EventListener callback) {
  return (Event e) {
    var touches = <Touch>[];
    var targetTouches = <Touch>[];
    var changedTouches = <Touch>[];
    final mockTouch = MockTouch(e as MouseEvent);
    final mockTouchList = <Touch>[mockTouch];
    if (e.type == 'mouseup') {
      changedTouches = mockTouchList;
    } else {
      touches = mockTouchList;
      targetTouches = mockTouchList;
    }
    callback(MockTouchEvent(e, touches, targetTouches, changedTouches));
    // Required to prevent spurious selection changes while tracking touches
    // on devices that don't support touch events.
    e.preventDefault();
  };
}

/// Helper method to attach event listeners to a [node]. */
void _addEventListeners(Element node, EventListener onStart,
    EventListener onMove, EventListener onEnd, EventListener onCancel,
    [bool capture = false]) {
  late final Function removeListeners;

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
    late StreamSubscription<TouchEvent> touchMoveSub;
    late StreamSubscription<TouchEvent> touchEndSub;
    late StreamSubscription<TouchEvent> touchLeaveSub;
    late StreamSubscription<TouchEvent> touchCancelSub;

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

    late StreamSubscription<MouseEvent> mouseMoveSub;
    late StreamSubscription<MouseEvent> mouseUpSub;
    late StreamSubscription<TouchEvent> touchCancelSub;

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

/// Gets whether the given touch event targets the node, or one of the node's
/// children.
bool _touchEventTargetsNode(event, Node node) {
  Node? target = event.changedTouches[0].target;

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
  /// Provide the HTML element that should respond to touch events.
  Element getElement();

  /// The object has received a touchend event.
  void onTouchEnd();

  /// The object has received a touchstart event.
  /// Returns return true if you want to allow a drag sequence to begin,
  ///      false you want to disable dragging for the duration of this touch.
  bool onTouchStart(TouchEvent e);
}

abstract class Draggable implements Touchable {
  /// The object's drag sequence is now complete.
  void onDragEnd();

  /// The object has been dragged to a new position.
  void onDragMove();

  /// The object has started dragging.
  /// Returns true to allow a drag sequence to begin (custom behavior),
  /// false to disable dragging for this touch duration (allow native scrolling).
  bool onDragStart(TouchEvent e);

  bool get verticalEnabled;
  bool get horizontalEnabled;
}

class MockTouch implements Touch {
  MouseEvent wrapped;

  MockTouch(this.wrapped);

  @override
  bool operator ==(Object other) {
    return identical(this, other);
  }

  num get clientX => wrapped.client.x;

  num get clientY => wrapped.client.y;

  @override
  get client => wrapped.client;

  @override
  int get identifier => 0;

  num get pageX => wrapped.page.x;

  num get pageY => wrapped.page.y;

  num get screenX => wrapped.screen.x;

  num get screenY => wrapped.screen.y;

  @override
  EventTarget? get target => wrapped.target;

  @override
  double get force {
    throw UnimplementedError();
  }

  @override
  Point get page {
    throw UnimplementedError();
  }

  @override
  int get radiusX {
    throw UnimplementedError();
  }

  @override
  int get radiusY {
    throw UnimplementedError();
  }

  @override
  String get region {
    throw UnimplementedError();
  }

  @override
  num get rotationAngle {
    throw UnimplementedError();
  }

  @override
  Point get screen {
    throw UnimplementedError();
  }

  num get webkitForce {
    throw UnimplementedError();
  }

  int get webkitRadiusX {
    throw UnimplementedError();
  }

  int get webkitRadiusY {
    throw UnimplementedError();
  }

  num get webkitRotationAngle {
    throw UnimplementedError();
  }
}

class MockTouchList extends Object
    with ListMixin<Touch>, ImmutableListMixin<Touch>
    implements TouchList {
  final List<Touch> values;

  MockTouchList(this.values);

  @override
  bool operator ==(Object other) {
    return identical(this, other);
  }

  static bool get supported => true;

  @override
  int get length => values.length;

  @override
  Touch operator [](int index) => values[index];

  @override
  void operator []=(int index, Touch value) {
    throw UnsupportedError("Cannot assign element of immutable List.");
  }

  @override
  set length(int value) {
    throw UnsupportedError("Cannot resize immutable List.");
  }

  @override
  Touch item(int index) => values[index];
}

class MockTouchEvent implements TouchEvent {
  dynamic /*MouseEvent*/ wrapped;
  @override
  final TouchList touches;
  @override
  final TouchList targetTouches;
  @override
  final TouchList changedTouches;
  MockTouchEvent(MouseEvent this.wrapped, List<Touch> touches,
      List<Touch> targetTouches, List<Touch> changedTouches)
      : touches = MockTouchList(touches),
        targetTouches = MockTouchList(targetTouches),
        changedTouches = MockTouchList(changedTouches);

  @override
  bool operator ==(Object other) {
    return identical(this, other);
  }

  @override
  bool get bubbles => wrapped.bubbles;

  bool get cancelBubble => wrapped.cancelBubble;

  set cancelBubble(bool value) {
    wrapped.cancelBubble = value;
  }

  @override
  bool get cancelable => wrapped.cancelable;

  @override
  EventTarget get currentTarget => wrapped.currentTarget;

  @override
  bool get defaultPrevented => wrapped.defaultPrevented;

  @override
  int get eventPhase => wrapped.eventPhase;

  set returnValue(bool value) {
    wrapped.returnValue = value;
  }

  bool get returnValue => wrapped.returnValue;

  @override
  EventTarget get target => wrapped.target;

  /*At different times, int, double, and String*/
  @override
  get timeStamp => wrapped.timeStamp;

  @override
  String get type => wrapped.type;

  @override
  void preventDefault() {
    wrapped.preventDefault();
  }

  @override
  void stopImmediatePropagation() {
    wrapped.stopImmediatePropagation();
  }

  @override
  void stopPropagation() {
    wrapped.stopPropagation();
  }

  int get charCode => wrapped.charCode;

  @override
  int get detail => wrapped.detail;

  // TODO(sra): keyCode is not on MouseEvent.
  //int get keyCode => (wrapped as KeyboardEvent).keyCode;

  int get layerX => wrapped.layer.x;

  int get layerY => wrapped.layer.y;

  int get pageX => wrapped.page.x;

  int get pageY => wrapped.page.y;

  @override
  Window get view => wrapped.view;

  int get which => wrapped.which;

  @override
  bool get altKey => wrapped.altKey;

  @override
  bool get ctrlKey => wrapped.ctrlKey;

  @override
  bool get metaKey => wrapped.metaKey;

  @override
  bool get shiftKey => wrapped.shiftKey;

  DataTransfer get clipboardData {
    throw UnimplementedError();
  }

  List<EventTarget> deepPath() {
    throw UnimplementedError();
  }

  @override
  bool get isTrusted {
    throw UnimplementedError();
  }

  Point get layer {
    throw UnimplementedError();
  }

  @override
  Element get matchingTarget {
    throw UnimplementedError();
  }

  Point get page {
    throw UnimplementedError();
  }

  @override
  List<EventTarget> get path {
    throw UnimplementedError();
  }

  bool get scoped {
    throw UnimplementedError();
  }

  Point get screen {
    throw UnimplementedError();
  }

  /*InputDeviceCapabilities*/ @override
  get sourceCapabilities {
    throw UnimplementedError();
  }

  /*InputDevice*/ get sourceDevice {
    throw UnimplementedError();
  }

  @override
  bool get composed {
    throw UnimplementedError();
  }

  @override
  List<EventTarget> composedPath() {
    throw UnimplementedError();
  }
}
