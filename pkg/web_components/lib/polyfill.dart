// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** Dart APIs for interacting with the JavaScript Custom Elements polyfill. */
library web_components.polyfill;

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
// TODO(jmesserly): rename to webComponentsReady to match the event?
Future customElementsReady = () {
  if (_isReady) return new Future.value();

  // Not upgraded. Wait for the polyfill to fire the WebComponentsReady event.
  // Note: we listen on document (not on document.body) to allow this polyfill
  // to be loaded in the HEAD element.
  return document.on['WebComponentsReady'].first;
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

/**
 * *Note* this API is primarily intended for tests. In other code it is better
 * to write it in a style that works with or without the polyfill, rather than
 * using this method.
 *
 * Synchronously trigger evaluation of pending lifecycle events, which otherwise
 * need to wait for a [MutationObserver] to signal the changes in the polyfill.
 * This method can be used to resolve differences in timing between native and
 * polyfilled custom elements.
 */
void customElementsTakeRecords() {
  var customElements = js.context['CustomElements'];
  if (customElements != null) {
    customElements.callMethod('takeRecords');
  }
}
