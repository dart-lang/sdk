// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** Ported from `polymer/src/boot.js`. **/
part of polymer;

/** Prevent a flash of unstyled content. */
_preventFlashOfUnstyledContent() {

  var style = new StyleElement();
  style.text = '.$_VEILED_CLASS { '
      'opacity: 0; } \n'
      '.$_UNVEIL_CLASS{ '
      '-webkit-transition: opacity ${_TRANSITION_TIME}s; '
      'transition: opacity ${_TRANSITION_TIME}s; }\n';

  // Note: we use `query` and not `document.head` to make sure this code works
  // with the shadow_dom polyfill (a limitation of the polyfill is that it can't
  // override the definitions of document, document.head, or document.body).
  var head = document.querySelector('head');
  head.insertBefore(style, head.firstChild);

  _veilElements();

  // hookup auto-unveiling
  Polymer.onReady.then((_) {
    Polymer.unveilElements();
  });
}

// add polymer styles
const _VEILED_CLASS = 'polymer-veiled';
const _UNVEIL_CLASS = 'polymer-unveil';
const _TRANSITION_TIME = 0.3;

// apply veiled class
_veilElements() {
  for (var selector in Polymer.veiledElements) {
    for (var node in document.querySelectorAll(selector)) {
      node.classes.add(_VEILED_CLASS);
    }
  }
}
