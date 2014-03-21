/*
 * Copyright 2013 The Polymer Authors. All rights reserved.
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file.
 */
(function() {
  // TODO(jmesserly): fix dart:html to use unprefixed name
  if (Element.prototype.webkitCreateShadowRoot) {
    Element.prototype.webkitCreateShadowRoot = function() {
      return window.ShadowDOMPolyfill.wrapIfNeeded(this).createShadowRoot();
    };
  }
})();
