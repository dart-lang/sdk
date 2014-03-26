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

  // ShadowCSS needs this:
  window.wrap = window.ShadowDOMPolyfill.wrap;
  window.unwrap = window.ShadowDOMPolyfill.unwrap;

  //TODO(sjmiles): review method alias with Arv
  HTMLElement.prototype.webkitCreateShadowRoot =
      HTMLElement.prototype.createShadowRoot;

  // TODO(jmesserly): we need to wrap document somehow (a dart:html hook?)
  window.dartExperimentalFixupGetTag = function(originalGetTag) {
    var NodeList = ShadowDOMPolyfill.wrappers.NodeList;
    var ShadowRoot = ShadowDOMPolyfill.wrappers.ShadowRoot;
    var unwrapIfNeeded = ShadowDOMPolyfill.unwrapIfNeeded;
    function getTag(obj) {
      // TODO(jmesserly): do we still need these?
      if (obj instanceof NodeList) return 'NodeList';
      if (obj instanceof ShadowRoot) return 'ShadowRoot';
      if (window.MutationRecord && (obj instanceof MutationRecord))
          return 'MutationRecord';
      if (window.MutationObserver && (obj instanceof MutationObserver))
          return 'MutationObserver';

      // TODO(jmesserly): this prevents incorrect interaction between ShadowDOM
      // and dart:html's <template> polyfill. Essentially, ShadowDOM is
      // polyfilling native template, but our Dart polyfill fails to detect this
      // because the unwrapped node is an HTMLUnknownElement, leading it to
      // think the node has no content.
      if (obj instanceof HTMLTemplateElement) return 'HTMLTemplateElement';

      var unwrapped = unwrapIfNeeded(obj);
      if (obj !== unwrapped) {
        // Fix up class names for Firefox.
        // For some of them (like HTMLFormElement and HTMLInputElement),
        // the "constructor" property of the unwrapped nodes points at the
        // same constructor as the wrapper.
        var ctor = obj.constructor
        if (ctor === unwrapped.constructor) {
          var name = ctor._ShadowDOMPolyfill$cacheTag_;
          if (!name) {
            name = Object.prototype.toString.call(unwrapped);
            name = name.substring(8, name.length - 1);
            ctor._ShadowDOMPolyfill$cacheTag_ = name;
          }
          return name;
        }

        obj = unwrapped;
      }
      return originalGetTag(obj);
    }

    return getTag;
  };
})();
