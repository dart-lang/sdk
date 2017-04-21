// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of swarmlib;

/**
 * The base class that should be extended by all HTML applications.
 *
 * It should both be easy to use for users coming over from JavaScript, but
 * also offer a clear notion of OO encapsulation.
 *
 * This class or something similar belongs in the standard DOM library.
 */
class App {
  App() {}

  /** Begins executing code in this [App]. */
  void run() {
    // If the script is async, by the time we get here the DOM content may
    // already be loaded, so waiting on the DOMContentLoaded event is a no-op.
    // Guard against this by checking whether the document readiness state has
    // gotten as far as "interactive".  (We believe the transition to
    // "interactive" is when the DOMContentLoaded event fires, but haven't
    // found that specified; if that's not true it leaves a race bug.)
    if (document.readyState == "interactive" ||
        document.readyState == "complete" ||
        document.readyState == "loaded") {
      // We use a timer to insure that onLoad is always called in an async
      // manner even if the document is already loaded.
      Timer.run(onLoad);
    } else {
      window.onContentLoaded.listen(
          // TODO(sigmund):  Consider eliminating the call to "wrap", for
          // instance, modify event listeners to always wrap, or extend DOM code
          // to intercept the beginning & end of each event loop
          EventBatch.wrap((Event event) => onLoad()));
    }
  }

  /**
   * Called when the DOM is fully loaded but potentially before resources.
   *
   * For most apps, any startup code should be in this method. Be sure to call
   * the superclass implementation.
   */
  void onLoad() {
    // Prevent the default browser behavior of scrolling the window.
    document.onTouchMove.listen((Event event) => event.preventDefault());

    // Swap and reload the cache if ready
    if (!swapAndReloadCache()) {
      // Otherwise wait until an update to the cache is ready
      window.applicationCache.onUpdateReady.listen((e) => swapAndReloadCache());
    }
  }

  /**
   * Erase the static splash screen.
   *
   * Assumption: if a splash screen exists, an element #appSplash contains it.
   */
  void eraseSplashScreen() {
    final splash = document.querySelector("#appSplash");
    // Delete it if found, but it's okay for it not to be -- maybe
    // somebody just didn't want to use our splash mechanism.
    if (splash != null) {
      splash.remove();
    }
  }

  /**
   * Swaps and reloads the app cache if an update is ready. Returns false if
   * an update is not ready.
   */
  bool swapAndReloadCache() {
    ApplicationCache appCache = window.applicationCache;
    if (!identical(appCache.status, ApplicationCache.UPDATEREADY)) {
      return false;
    }

    print('App cache update ready, now swapping...');
    window.applicationCache.swapCache();
    print('App cache swapped, now reloading page...');
    window.location.reload();
    return true;
  }

  /** Returns true if we are running as a packaged application. */
  static bool get isPackaged {
    return window.location.protocol == 'chrome-extension:';
  }

  /**
    * Gets the server URL. This is needed when we are loaded from a packaged
    * Chrome app.
    */
  static String serverUrl(String url) {
    if (isPackaged) {
      // TODO(jmesserly): Several problems with this:
      //   * How do we authenticate against the server?
      //   * How do we talk to a server other than thump?
      assert(url.startsWith('/'));
      return 'http://thump.googleplex.com$url';
    } else {
      return url;
    }
  }
}
