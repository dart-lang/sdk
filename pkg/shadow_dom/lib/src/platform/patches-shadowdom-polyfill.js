/*
 * Copyright 2013 The Polymer Authors. All rights reserved.
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file.
 */
(function() {
  var ShadowDOMPolyfill = window.ShadowDOMPolyfill;
  var wrap = ShadowDOMPolyfill.wrap;

  // patch in prefixed name
  Object.defineProperties(HTMLElement.prototype, {
    //TODO(sjmiles): review accessor alias with Arv
    webkitShadowRoot: {
      get: function() {
        return this.shadowRoot;
      }
    }
  });

  //TODO(sjmiles): review method alias with Arv
  HTMLElement.prototype.webkitCreateShadowRoot =
      HTMLElement.prototype.createShadowRoot;

  // TODO(jmesserly): we need to wrap document somehow (a dart:html hook?)
  window.dartExperimentalFixupGetTag = function(originalGetTag) {
    var NodeList = ShadowDOMPolyfill.wrappers.NodeList;
    var ShadowRoot = ShadowDOMPolyfill.wrappers.ShadowRoot;
    var isWrapper = ShadowDOMPolyfill.isWrapper;
    var unwrap = ShadowDOMPolyfill.unwrap;
    function getTag(obj) {
      if (obj instanceof NodeList) return 'NodeList';
      if (obj instanceof ShadowRoot) return 'ShadowRoot';
      if (obj instanceof MutationRecord) return 'MutationRecord';
      if (obj instanceof MutationObserver) return 'MutationObserver';

      if (isWrapper(obj)) {
        obj = unwrap(obj);

        // Fix up class names for Firefox. For some of them like
        // HTMLFormElement and HTMLInputElement, the "constructor" property of
        // the unwrapped nodes points at the wrapper for some reason.
        // TODO(jmesserly): figure out why this is happening.
        var ctor = obj.constructor;
        if (ctor && ctor._ShadowDOMPolyfill$isGeneratedWrapper) {
          var name = ctor._ShadowDOMPolyfill$cacheTag_;
          if (!name) {
            name = Object.prototype.toString.call(obj);
            name = name.substring(8, name.length - 1);
            ctor._ShadowDOMPolyfill$cacheTag_ = name;
          }
          return name;
        }
      }
      return originalGetTag(obj);
    }

    return getTag;
  };
})();
