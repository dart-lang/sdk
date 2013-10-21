// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** Dart APIs for interacting with the JavaScript Custom Elements polyfill. */
library custom_element.polyfill;

import 'dart:async';
import 'dart:html';
import 'dart:js' as js;

/**
 * A future that completes once all custom elements in the initial HTML page
 * have been upgraded.
 *
 * This is needed because the native implementation can update the elements
 * while parsing the HTML document, but the custom element polyfill cannot,
 * so it completes this future once all elements are upgraded.
 */
Future customElementsReady = () {
  if (_isReady) return new Future.value();

  // Not upgraded. Wait for the polyfill to fire the WebComponentsReady event.
  return document.body.on['WebComponentsReady'].first;
}();

// Return true if we are using the polyfill and upgrade is complete, or if we
// have native document.register and therefore the browser took care of it.
// Otherwise return false, including the case where we can't find the polyfill.
bool get _isReady {
  // If we don't have dart:js, assume things are ready
  if (js.context == null) return true;

  var customElements = js.context['CustomElements'];
  if (customElements == null) {
    // Return true if native document.register, otherwise false.
    // (Maybe the polyfill isn't loaded yet. Wait for it.)
    return document.supportsRegister;
  }

  return customElements['ready'] == true;
}
