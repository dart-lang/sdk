// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.html;

/**
 * Helper class to implement custom events which wrap DOM events.
 */
class _WrappedEvent implements Event {
  final Event wrapped;

  /** The CSS selector involved with event delegation. */
  String? _selector;

  _WrappedEvent(this.wrapped);

  bool get bubbles => wrapped.bubbles!;

  bool get cancelable => wrapped.cancelable!;

  bool get composed => wrapped.composed!;

  EventTarget? get currentTarget => wrapped.currentTarget;

  bool get defaultPrevented => wrapped.defaultPrevented;

  int get eventPhase => wrapped.eventPhase;

  bool get isTrusted => wrapped.isTrusted!;

  EventTarget? get target => wrapped.target;

  double get timeStamp => wrapped.timeStamp as double;

  String get type => wrapped.type;

  void _initEvent(String type, [bool? bubbles, bool? cancelable]) {
    throw new UnsupportedError('Cannot initialize this Event.');
  }

  void preventDefault() {
    wrapped.preventDefault();
  }

  void stopImmediatePropagation() {
    wrapped.stopImmediatePropagation();
  }

  void stopPropagation() {
    wrapped.stopPropagation();
  }

  List<EventTarget> composedPath() => wrapped.composedPath();

  /**
   * A pointer to the element whose CSS selector matched within which an event
   * was fired. If this Event was not associated with any Event delegation,
   * accessing this value will throw an [UnsupportedError].
   */
  Element get matchingTarget {
    if (_selector == null) {
      throw new UnsupportedError('Cannot call matchingTarget if this Event did'
          ' not arise as a result of event delegation.');
    }
    Element? currentTarget = this.currentTarget as Element?;
    Element? target = this.target as Element?;
    do {
      if (target!.matches(_selector!)) return target;
      target = target.parent;
    } while (target != null && target != currentTarget!.parent);
    throw new StateError('No selector matched for populating matchedTarget.');
  }

  /**
   * This event's path, taking into account shadow DOM.
   *
   * ## Other resources
   *
   * * [Shadow DOM extensions to
   *   Event](http://w3c.github.io/webcomponents/spec/shadow/#extensions-to-event)
   *   from W3C.
   */
  // https://dvcs.w3.org/hg/webcomponents/raw-file/tip/spec/shadow/index.html#extensions-to-event
  List<Node> get path => wrapped.path as List<Node>;

  dynamic get _get_currentTarget => wrapped._get_currentTarget;

  dynamic get _get_target => wrapped._get_target;
}
