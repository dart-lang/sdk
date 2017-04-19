// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of touch;

/**
 * Common events related helpers.
 */
class EventUtil {
  /**
   * Add an event listener to an element.
   * The event callback is specified by [handler].
   * If [capture] is true, the listener gets events on the capture phase.
   * If [removeHandlerOnFocus] is true the handler is removed when there is any
   * focus event, and added back on blur events.
   */
  static void observe(
      /*Element or Document*/ element, Stream stream, Function handler,
      [bool removeHandlerOnFocus = false]) {
    var subscription = stream.listen(handler);
    // TODO(jacobr): this remove on focus behavior seems really ugly.
    if (removeHandlerOnFocus) {
      element.onFocus.listen((e) {
        subscription.cancel();
      });
      element.onBlur.listen((e) {
        subscription.cancel();
      });
    }
  }

  /**
   * Clear the keyboard focus of the currently focused element (if there is
   * one). If there is no currently focused element then this function will do
   * nothing. For most browsers this will cause the keyboard to be dismissed.
   */
  static void blurFocusedElement() {
    Element focusedEl = document.querySelector("*:focus");
    if (focusedEl != null) {
      focusedEl.blur();
    }
  }
}
