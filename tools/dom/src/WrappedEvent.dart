// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.html;

/**
 * Helper class to implement custom events which wrap DOM events.
 */
class _WrappedEvent implements Event {
  final Event wrapped;
  _WrappedEvent(this.wrapped);

  bool get bubbles => wrapped.bubbles;

  bool get cancelBubble => wrapped.bubbles;
  void set cancelBubble(bool value) {
    wrapped.cancelBubble = value;
  }

  bool get cancelable => wrapped.cancelable;

  DataTransfer get clipboardData => wrapped.clipboardData;

  EventTarget get currentTarget => wrapped.currentTarget;

  bool get defaultPrevented => wrapped.defaultPrevented;

  int get eventPhase => wrapped.eventPhase;

  EventTarget get target => wrapped.target;

  int get timeStamp => wrapped.timeStamp;

  String get type => wrapped.type;

  void $dom_initEvent(String eventTypeArg, bool canBubbleArg,
      bool cancelableArg) {
    throw new UnsupportedError(
        'Cannot initialize this Event.');
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
}
