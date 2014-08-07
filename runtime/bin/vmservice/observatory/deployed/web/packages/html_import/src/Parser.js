/*
 * Copyright 2013 The Polymer Authors. All rights reserved.
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file.
 */

(function(scope) {

var IMPORT_LINK_TYPE = 'import';

// highlander object for parsing a document tree

var importParser = {
  selectors: [
    'link[rel=' + IMPORT_LINK_TYPE + ']',
    'link[rel=stylesheet]',
    'style',
    'script:not([type])',
    'script[type="text/javascript"]'
  ],
  map: {
    link: 'parseLink',
    script: 'parseScript',
    style: 'parseGeneric'
  },
  parse: function(inDocument) {
    if (!inDocument.__importParsed) {
      // only parse once
      inDocument.__importParsed = true;
      // all parsable elements in inDocument (depth-first pre-order traversal)
      var elts = inDocument.querySelectorAll(importParser.selectors);
      // for each parsable node type, call the mapped parsing method
      forEach(elts, function(e) {
        importParser[importParser.map[e.localName]](e);
      });
    }
  },
  parseLink: function(linkElt) {
    if (isDocumentLink(linkElt)) {
      if (linkElt.content) {
        importParser.parse(linkElt.content);
      }
    } else {
      this.parseGeneric(linkElt);
    }
  },
  parseGeneric: function(elt) {
    if (needsMainDocumentContext(elt)) {
      document.head.appendChild(elt);
    }
  },
  parseScript: function(scriptElt) {
    if (needsMainDocumentContext(scriptElt)) {
      // acquire code to execute
      var code = (scriptElt.__resource || scriptElt.textContent).trim();
      if (code) {
        // calculate source map hint
        var moniker = scriptElt.__nodeUrl;
        if (!moniker) {
          var moniker = scope.path.documentUrlFromNode(scriptElt);
          // there could be more than one script this url
          var tag = '[' + Math.floor((Math.random()+1)*1000) + ']';
          // TODO(sjmiles): Polymer hack, should be pluggable if we need to allow 
          // this sort of thing
          var matches = code.match(/Polymer\(['"]([^'"]*)/);
          tag = matches && matches[1] || tag;
          // tag the moniker
          moniker += '/' + tag + '.js';
        }
        // source map hint
        code += "\n//# sourceURL=" + moniker + "\n";
        // evaluate the code
        eval.call(window, code);
      }
    }
  }
};

var forEach = Array.prototype.forEach.call.bind(Array.prototype.forEach);

function isDocumentLink(elt) {
  return elt.localName === 'link'
      && elt.getAttribute('rel') === IMPORT_LINK_TYPE;
}

function needsMainDocumentContext(node) {
  // nodes can be moved to the main document:
  // if they are in a tree but not in the main document and not children of <element>
  return node.parentNode && !inMainDocument(node) 
      && !isElementElementChild(node);
}

function inMainDocument(elt) {
  return elt.ownerDocument === document ||
    // TODO(sjmiles): ShadowDOMPolyfill intrusion
    elt.ownerDocument.impl === document;
}

function isElementElementChild(elt) {
  return elt.parentNode && elt.parentNode.localName === 'element';
}

// exports

scope.parser = importParser;

})(HTMLImports);