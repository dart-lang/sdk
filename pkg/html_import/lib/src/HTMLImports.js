/*
 * Copyright 2013 The Polymer Authors. All rights reserved.
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file.
 */

(function(scope) {

if (!scope) {
  scope = window.HTMLImports = {flags:{}};
}

// imports

var xhr = scope.xhr;

// importer

var IMPORT_LINK_TYPE = 'import';
var STYLE_LINK_TYPE = 'stylesheet';

// highlander object represents a primary document (the argument to 'load')
// at the root of a tree of documents

// for any document, importer:
// - loads any linked documents (with deduping), modifies paths and feeds them back into importer
// - loads text of external script tags
// - loads text of external style tags inside of <element>, modifies paths

// when importer 'modifies paths' in a document, this includes
// - href/src/action in node attributes
// - paths in inline stylesheets
// - all content inside templates

// linked style sheets in an import have their own path fixed up when their containing import modifies paths
// linked style sheets in an <element> are loaded, and the content gets path fixups
// inline style sheets get path fixups when their containing import modifies paths

var loader;

var importer = {
  documents: {},
  cache: {},
  preloadSelectors: [
    'link[rel=' + IMPORT_LINK_TYPE + ']',
    'element link[rel=' + STYLE_LINK_TYPE + ']',
    'template',
    'script[src]:not([type])',
    'script[src][type="text/javascript"]'
  ].join(','),
  loader: function(inNext) {
    // construct a loader instance
    loader = new Loader(importer.loaded, inNext);
    // alias the loader cache (for debugging)
    loader.cache = importer.cache;
    return loader;
  },
  load: function(inDocument, inNext) {
    // construct a loader instance
    loader = importer.loader(inNext);
    // add nodes from document into loader queue
    importer.preload(inDocument);
  },
  preload: function(inDocument) {
    // all preloadable nodes in inDocument
    var nodes = inDocument.querySelectorAll(importer.preloadSelectors);
    // from the main document, only load imports
    // TODO(sjmiles): do this by altering the selector list instead
    nodes = this.filterMainDocumentNodes(inDocument, nodes);
    // extra link nodes from templates, filter templates out of the nodes list
    nodes = this.extractTemplateNodes(nodes);
    // add these nodes to loader's queue
    loader.addNodes(nodes);
  },
  filterMainDocumentNodes: function(inDocument, nodes) {
    if (inDocument === document) {
      nodes = Array.prototype.filter.call(nodes, function(n) {
        return !isScript(n);
      });
    }
    return nodes;
  },
  extractTemplateNodes: function(nodes) {
    var extra = [];
    nodes = Array.prototype.filter.call(nodes, function(n) {
      if (n.localName === 'template') {
        if (n.content) {
          var l$ = n.content.querySelectorAll('link[rel=' + STYLE_LINK_TYPE +
            ']');
          if (l$.length) {
            extra = extra.concat(Array.prototype.slice.call(l$, 0));
          }
        }
        return false;
      }
      return true;
    });
    if (extra.length) {
      nodes = nodes.concat(extra);
    }
    return nodes;
  },
  loaded: function(url, elt, resource) {
    if (isDocumentLink(elt)) {
      var document = importer.documents[url];
      // if we've never seen a document at this url
      if (!document) {
        // generate an HTMLDocument from data
        document = makeDocument(resource, url);
        // resolve resource paths relative to host document
        path.resolvePathsInHTML(document);
        // cache document
        importer.documents[url] = document;
        // add nodes from this document to the loader queue
        importer.preload(document);
      }
      // store import record
      elt.import = {
        href: url,
        ownerNode: elt,
        content: document
      };
      // store document resource
      elt.content = resource = document;
    }
    // store generic resource
    // TODO(sorvell): fails for nodes inside <template>.content
    // see https://code.google.com/p/chromium/issues/detail?id=249381.
    elt.__resource = resource;
    // css path fixups
    if (isStylesheetLink(elt)) {
      path.resolvePathsInStylesheet(elt);
    }
  }
};

function isDocumentLink(elt) {
  return isLinkRel(elt, IMPORT_LINK_TYPE);
}

function isStylesheetLink(elt) {
  return isLinkRel(elt, STYLE_LINK_TYPE);
}

function isLinkRel(elt, rel) {
  return elt.localName === 'link' && elt.getAttribute('rel') === rel;
}

function isScript(elt) {
  return elt.localName === 'script';
}

function makeDocument(resource, url) {
  // create a new HTML document
  var doc = resource;
  if (!(doc instanceof Document)) {
    doc = document.implementation.createHTMLDocument(IMPORT_LINK_TYPE);
    // install html
    doc.body.innerHTML = resource;
  }
  // cache the new document's source url
  doc._URL = url;
  // establish a relative path via <base>
  var base = doc.createElement('base');
  base.setAttribute('href', document.baseURI);
  doc.head.appendChild(base);
  // TODO(sorvell): MDV Polyfill intrusion: boostrap template polyfill
  if (window.HTMLTemplateElement && HTMLTemplateElement.bootstrap) {
    HTMLTemplateElement.bootstrap(doc);
  }
  return doc;
}

var Loader = function(inOnLoad, inOnComplete) {
  this.onload = inOnLoad;
  this.oncomplete = inOnComplete;
  this.inflight = 0;
  this.pending = {};
  this.cache = {};
};

Loader.prototype = {
  addNodes: function(inNodes) {
    // number of transactions to complete
    this.inflight += inNodes.length;
    // commence transactions
    forEach(inNodes, this.require, this);
    // anything to do?
    this.checkDone();
  },
  require: function(inElt) {
    var url = path.nodeUrl(inElt);
    // TODO(sjmiles): ad-hoc
    inElt.__nodeUrl = url;
    // deduplication
    if (!this.dedupe(url, inElt)) {
      // fetch this resource
      this.fetch(url, inElt);
    }
  },
  dedupe: function(inUrl, inElt) {
    if (this.pending[inUrl]) {
      // add to list of nodes waiting for inUrl
      this.pending[inUrl].push(inElt);
      // don't need fetch
      return true;
    }
    if (this.cache[inUrl]) {
      // complete load using cache data
      this.onload(inUrl, inElt, loader.cache[inUrl]);
      // finished this transaction
      this.tail();
      // don't need fetch
      return true;
    }
    // first node waiting for inUrl
    this.pending[inUrl] = [inElt];
    // need fetch (not a dupe)
    return false;
  },
  fetch: function(url, elt) {
    var receiveXhr = function(err, resource) {
      this.receive(url, elt, err, resource);
    }.bind(this);
    xhr.load(url, receiveXhr);
    // TODO(sorvell): blocked on 
    // https://code.google.com/p/chromium/issues/detail?id=257221
    // xhr'ing for a document makes scripts in imports runnable; otherwise
    // they are not; however, it requires that we have doctype=html in
    // the import which is unacceptable. This is only needed on Chrome
    // to avoid the bug above.
    /*
    if (isDocumentLink(elt)) {
      xhr.loadDocument(url, receiveXhr);
    } else {
      xhr.load(url, receiveXhr);
    }
    */
  },
  receive: function(inUrl, inElt, inErr, inResource) {
    if (!inErr) {
      loader.cache[inUrl] = inResource;
    }
    loader.pending[inUrl].forEach(function(e) {
      if (!inErr) {
        this.onload(inUrl, e, inResource);
      }
      this.tail();
    }, this);
    loader.pending[inUrl] = null;
  },
  tail: function() {
    --this.inflight;
    this.checkDone();
  },
  checkDone: function() {
    if (!this.inflight) {
      this.oncomplete();
    }
  }
};

var URL_ATTRS = ['href', 'src', 'action'];
var URL_ATTRS_SELECTOR = '[' + URL_ATTRS.join('],[') + ']';
var URL_TEMPLATE_SEARCH = '{{.*}}';

var path = {
  nodeUrl: function(inNode) {
    return path.resolveUrl(path.getDocumentUrl(document), path.hrefOrSrc(inNode));
  },
  hrefOrSrc: function(inNode) {
    return inNode.getAttribute("href") || inNode.getAttribute("src");
  },
  documentUrlFromNode: function(inNode) {
    return path.getDocumentUrl(inNode.ownerDocument || inNode);
  },
  getDocumentUrl: function(inDocument) {
    var url = inDocument &&
        // TODO(sjmiles): ShadowDOMPolyfill intrusion
        (inDocument._URL || (inDocument.impl && inDocument.impl._URL)
            || inDocument.baseURI || inDocument.URL)
                || '';
    // take only the left side if there is a #
    return url.split('#')[0];
  },
  resolveUrl: function(inBaseUrl, inUrl, inRelativeToDocument) {
    if (this.isAbsUrl(inUrl)) {
      return inUrl;
    }
    var url = this.compressUrl(this.urlToPath(inBaseUrl) + inUrl);
    if (inRelativeToDocument) {
      url = path.makeRelPath(path.getDocumentUrl(document), url);
    }
    return url;
  },
  isAbsUrl: function(inUrl) {
    return /(^data:)|(^http[s]?:)|(^\/)/.test(inUrl);
  },
  urlToPath: function(inBaseUrl) {
    var parts = inBaseUrl.split("/");
    parts.pop();
    parts.push('');
    return parts.join("/");
  },
  compressUrl: function(inUrl) {
    var parts = inUrl.split("/");
    for (var i=0, p; i<parts.length; i++) {
      p = parts[i];
      if (p === "..") {
        parts.splice(i-1, 2);
        i -= 2;
      }
    }
    return parts.join("/");
  },
  // make a relative path from source to target
  makeRelPath: function(inSource, inTarget) {
    var s, t;
    s = this.compressUrl(inSource).split("/");
    t = this.compressUrl(inTarget).split("/");
    while (s.length && s[0] === t[0]){
      s.shift();
      t.shift();
    }
    for(var i = 0, l = s.length-1; i < l; i++) {
      t.unshift("..");
    }
    var r = t.join("/");
    return r;
  },
  resolvePathsInHTML: function(root, url) {
    url = url || path.documentUrlFromNode(root)
    path.resolveAttributes(root, url);
    path.resolveStyleElts(root, url);
    // handle template.content
    var templates = root.querySelectorAll('template');
    if (templates) {
      forEach(templates, function(t) {
        if (t.content) {
          path.resolvePathsInHTML(t.content, url);
        }
      });
    }
  },
  resolvePathsInStylesheet: function(inSheet) {
    var docUrl = path.nodeUrl(inSheet);
    inSheet.__resource = path.resolveCssText(inSheet.__resource, docUrl);
  },
  resolveStyleElts: function(inRoot, inUrl) {
    var styles = inRoot.querySelectorAll('style');
    if (styles) {
      forEach(styles, function(style) {
        style.textContent = path.resolveCssText(style.textContent, inUrl);
      });
    }
  },
  resolveCssText: function(inCssText, inBaseUrl) {
    return inCssText.replace(/url\([^)]*\)/g, function(inMatch) {
      // find the url path, ignore quotes in url string
      var urlPath = inMatch.replace(/["']/g, "").slice(4, -1);
      urlPath = path.resolveUrl(inBaseUrl, urlPath, true);
      return "url(" + urlPath + ")";
    });
  },
  resolveAttributes: function(inRoot, inUrl) {
    // search for attributes that host urls
    var nodes = inRoot && inRoot.querySelectorAll(URL_ATTRS_SELECTOR);
    if (nodes) {
      forEach(nodes, function(n) {
        this.resolveNodeAttributes(n, inUrl);
      }, this);
    }
  },
  resolveNodeAttributes: function(inNode, inUrl) {
    URL_ATTRS.forEach(function(v) {
      var attr = inNode.attributes[v];
      if (attr && attr.value &&
         (attr.value.search(URL_TEMPLATE_SEARCH) < 0)) {
        var urlPath = path.resolveUrl(inUrl, attr.value, true);
        attr.value = urlPath;
      }
    });
  }
};

xhr = xhr || {
  async: true,
  ok: function(inRequest) {
    return (inRequest.status >= 200 && inRequest.status < 300)
        || (inRequest.status === 304)
        || (inRequest.status === 0);
  },
  load: function(url, next, nextContext) {
    var request = new XMLHttpRequest();
    if (scope.flags.debug || scope.flags.bust) {
      url += '?' + Math.random();
    }
    request.open('GET', url, xhr.async);
    request.addEventListener('readystatechange', function(e) {
      if (request.readyState === 4) {
        next.call(nextContext, !xhr.ok(request) && request,
          request.response, url);
      }
    });
    request.send();
    return request;
  },
  loadDocument: function(url, next, nextContext) {
    this.load(url, next, nextContext).responseType = 'document';
  }
};

var forEach = Array.prototype.forEach.call.bind(Array.prototype.forEach);

// exports

scope.path = path;
scope.xhr = xhr;
scope.importer = importer;
scope.getDocumentUrl = path.getDocumentUrl;
scope.IMPORT_LINK_TYPE = IMPORT_LINK_TYPE;

})(window.HTMLImports);
