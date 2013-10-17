// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** Ported from `polymer/src/boot.js`. **/
part of polymer;

/** Prevent a flash of unstyled content. */
preventFlashOfUnstyledContent() {
  var style = new StyleElement();
  style.text = r'body {opacity: 0;}';
  // Note: we use `query` and not `document.head` to make sure this code works
  // with the shadow_dom polyfill (a limitation of the polyfill is that it can't
  // override the definitions of document, document.head, or document.body).
  var head = query('head');
  head.insertBefore(style, head.firstChild);

  Polymer.onReady.then((_) {
    document.body.style.transition = 'opacity 0.3s';
    document.body.style.opacity = '1';
  });
}
