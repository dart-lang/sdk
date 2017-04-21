// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of swarmlib;

/**
 * The base class for UI state that intends to support browser history.
 */
abstract class UIState {
  /**
   * The event listener we hook to the window's "popstate" event.
   * This event is triggered by the back button or by the first page load.
   */
  StreamSubscription _historyTracking;

  UIState();

  void startHistoryTracking() {
    stopHistoryTracking();

    bool firstEvent = true;
    var handler = EventBatch.wrap((event) {
      String state = window.location.hash;
      if (state.startsWith('#')) {
        // TODO(jimhug): Support default argument on substring.
        state = state.substring(1, state.length);
      }

      if (firstEvent && state != '') {
        // TODO(jmesserly): When loading a bookmark or refreshing, we replace
        // the app state with a clean app state so the back button works. It
        // would be better to support jumping to the previous story.
        // We'd need to do some history manipulation here and some fixes to
        // the views for this.
        window.history.replaceState(null, document.title, '#');
      } else if (state != '') {
        loadFromHistory(JSON.decode(state));
      }
      firstEvent = false;
    });

    _historyTracking = window.onPopState.listen(handler);
  }

  void stopHistoryTracking() {
    if (_historyTracking != null) {
      _historyTracking.cancel();
    }
  }

  /** Pushes a state onto the browser history stack */
  void pushToHistory() {
    if (_historyTracking == null) {
      throw 'history tracking not started';
    }

    String state = JSON.encode(toHistory());

    // TODO(jmesserly): [state] should be an Object, and we should pass it to
    // the state parameter instead of as a #hash URL. Right now we're working
    //  around b/4582542.
    window.history
        .pushState(null, '${document.title}', '${document.title}#$state');
  }

  /**
   * Serialize the state to a form suitable for storing in browser history.
   */
  Map<String, String> toHistory();

  /**
   * Load the UI state from the given [values].
   */
  void loadFromHistory(Map<String, String> values);
}
