// Copyright 2013 The Polymer Authors. All rights reserved.
// Use of this source code is goverened by a BSD-style
// license that can be found in the LICENSE file.

(function() {
  var thisFile = 'shadowdom.js';
  var base = '';
  Array.prototype.forEach.call(document.querySelectorAll('script[src]'), function(s) {
    var src = s.getAttribute('src');
    var re = new RegExp(thisFile + '[^\\\\]*');
    var match = src.match(re);
    if (match) {
      base = src.slice(0, -match[0].length);
    }
  });
  base += '../../../third_party/polymer/ShadowDOM/src/';

  [
    'sidetable.js',
    'wrappers.js',
    'wrappers/events.js',
    'wrappers/NodeList.js',
    'wrappers/Node.js',
    'querySelector.js',
    'wrappers/node-interfaces.js',
    'wrappers/CharacterData.js',
    'wrappers/Element.js',
    'wrappers/HTMLElement.js',
    'wrappers/HTMLContentElement.js',
    'wrappers/HTMLShadowElement.js',
    'wrappers/HTMLTemplateElement.js',
    'wrappers/HTMLUnknownElement.js',
    'wrappers/generic.js',
    'wrappers/ShadowRoot.js',
    'ShadowRenderer.js',
    'wrappers/Document.js',
    'wrappers/Window.js',
    'wrappers/MutationObserver.js',
    'wrappers/override-constructors.js'
  ].forEach(function(src) {
    document.write('<script src="' + base + src + '"></script>');
  });

})();
