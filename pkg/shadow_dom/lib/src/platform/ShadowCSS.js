/*
 * Copyright 2012 The Polymer Authors. All rights reserved.
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file.
 */

/*
  This is a limited shim for ShadowDOM css styling.
  https://dvcs.w3.org/hg/webcomponents/raw-file/tip/spec/shadow/index.html#styles

  The intention here is to support only the styling features which can be
  relatively simply implemented. The goal is to allow users to avoid the
  most obvious pitfalls and do so without compromising performance significantly.
  For ShadowDOM styling that's not covered here, a set of best practices
  can be provided that should allow users to accomplish more complex styling.

  The following is a list of specific ShadowDOM styling features and a brief
  discussion of the approach used to shim.

  Shimmed features:

  * @host: ShadowDOM allows styling of the shadowRoot's host element using the
  @host rule. To shim this feature, the @host styles are reformatted and
  prefixed with a given scope name and promoted to a document level stylesheet.
  For example, given a scope name of .foo, a rule like this:

    @host {
      * {
        background: red;
      }
    }

  becomes:

    .foo {
      background: red;
    }

  * encapsultion: Styles defined within ShadowDOM, apply only to
  dom inside the ShadowDOM. Polymer uses one of two techniques to imlement
  this feature.

  By default, rules are prefixed with the host element tag name
  as a descendant selector. This ensures styling does not leak out of the 'top'
  of the element's ShadowDOM. For example,

  div {
      font-weight: bold;
    }

  becomes:

  x-foo div {
      font-weight: bold;
    }

  becomes:


  Alternatively, if Platform.ShadowCSS.strictStyling is set to true then
  selectors are scoped by adding an attribute selector suffix to each
  simple selector that contains the host element tag name. Each element
  in the element's ShadowDOM template is also given the scope attribute.
  Thus, these rules match only elements that have the scope attribute.
  For example, given a scope name of x-foo, a rule like this:

    div {
      font-weight: bold;
    }

  becomes:

    div[x-foo] {
      font-weight: bold;
    }

  Note that elements that are dynamically added to a scope must have the scope
  selector added to them manually.

  * ::pseudo: These rules are converted to rules that take advantage of the
  pseudo attribute. For example, a shadowRoot like this inside an x-foo

    <div pseudo="x-special">Special</div>

  with a rule like this:

    x-foo::x-special { ... }

  becomes:

    x-foo [pseudo=x-special] { ... }

  Unaddressed ShadowDOM styling features:

  * upper/lower bound encapsulation: Styles which are defined outside a
  shadowRoot should not cross the ShadowDOM boundary and should not apply
  inside a shadowRoot.

  This styling behavior is not emulated. Some possible ways to do this that
  were rejected due to complexity and/or performance concerns include: (1) reset
  every possible property for every possible selector for a given scope name;
  (2) re-implement css in javascript.

  As an alternative, users should make sure to use selectors
  specific to the scope in which they are working.

  * ::distributed: This behavior is not emulated. It's often not necessary
  to style the contents of a specific insertion point and instead, descendants
  of the host element can be styled selectively. Users can also create an
  extra node around an insertion point and style that node's contents
  via descendent selectors. For example, with a shadowRoot like this:

    <style>
      content::-webkit-distributed(div) {
        background: red;
      }
    </style>
    <content></content>

  could become:

    <style>
      / *@polyfill .content-container div * /
      content::-webkit-distributed(div) {
        background: red;
      }
    </style>
    <div class="content-container">
      <content></content>
    </div>

  Note the use of @polyfill in the comment above a ShadowDOM specific style
  declaration. This is a directive to the styling shim to use the selector
  in comments in lieu of the next selector when running under polyfill.
*/
(function(scope) {

var ShadowCSS = {
  strictStyling: false,
  registry: {},
  // Shim styles for a given root associated with a name and extendsName
  // 1. cache root styles by name
  // 2. optionally tag root nodes with scope name
  // 3. shim polyfill directives /* @polyfill */
  // 4. shim @host and scoping
  shimStyling: function(root, name, extendsName) {
    if (root) {
      // use caching to make working with styles nodes easier and to facilitate
      // lookup of extendee
      var def = this.registerDefinition(root, name, extendsName);
      // find styles and apply shimming...
      if (this.strictStyling) {
        this.applyScopeToContent(root, name);
      }
      this.shimPolyfillDirectives(def.rootStyles, name);
      this.applyShimming(def.scopeStyles, name);
    }
  },
  // Shim styles to be placed inside a shadowRoot.
  // 1. shim polyfill directives /* @polyfill */
  // 2. shim @host and scoping
  shimShadowDOMStyling: function(styles, name) {
    this.shimPolyfillDirectives(styles, name);
    this.applyShimming(styles, name);
  },
  registerDefinition: function(root, name, extendsName) {
    var def = this.registry[name] = {
      root: root,
      name: name,
      extendsName: extendsName
    }
    var styles = root.querySelectorAll('style');
    styles = styles ? Array.prototype.slice.call(styles, 0) : [];
    def.rootStyles = styles;
    def.scopeStyles = def.rootStyles;
    var extendee = this.registry[def.extendsName];
    if (extendee) {
      def.scopeStyles = def.scopeStyles.concat(extendee.scopeStyles);
    }
    return def;
  },
  applyScopeToContent: function(root, name) {
    if (root) {
      // add the name attribute to each node in root.
      Array.prototype.forEach.call(root.querySelectorAll('*'),
          function(node) {
            node.setAttribute(name, '');
          });
      // and template contents too
      Array.prototype.forEach.call(root.querySelectorAll('template'),
          function(template) {
            this.applyScopeToContent(template.content, name);
          },
          this);
    }
  },
  /*
   * Process styles to convert native ShadowDOM rules that will trip
   * up the css parser; we rely on decorating the stylesheet with comments.
   *
   * For example, we convert this rule:
   *
   * (comment start) @polyfill @host g-menu-item (comment end)
   * shadow::-webkit-distributed(g-menu-item) {
   *
   * to this:
   *
   * scopeName g-menu-item {
   *
  **/
  shimPolyfillDirectives: function(styles, name) {
    if (styles) {
      Array.prototype.forEach.call(styles, function(s) {
        s.textContent = this.convertPolyfillDirectives(s.textContent, name);
      }, this);
    }
  },
  convertPolyfillDirectives: function(cssText, name) {
    var r = '', l = 0, matches, selector;
    while (matches = cssPolyfillCommentRe.exec(cssText)) {
      r += cssText.substring(l, matches.index);
      // remove end comment delimiter (*/)
      selector = matches[1].slice(0, -2).replace(hostRe, name);
      r += this.scopeSelector(selector, name) + '{';
      l = cssPolyfillCommentRe.lastIndex;
    }
    r += cssText.substring(l, cssText.length);
    return r;
  },
  // apply @host and scope shimming
  applyShimming: function(styles, name) {
    var cssText = this.shimAtHost(styles, name);
    cssText += this.shimScoping(styles, name);
    addCssToDocument(cssText);
  },
  // form: @host { .foo { declarations } }
  // becomes: scopeName.foo { declarations }
  shimAtHost: function(styles, name) {
    if (styles) {
      return this.convertAtHostStyles(styles, name);
    }
  },
  convertAtHostStyles: function(styles, name) {
    var cssText = stylesToCssText(styles);
    var r = '', l=0, matches;
    while (matches = hostRuleRe.exec(cssText)) {
      r += cssText.substring(l, matches.index);
      r += this.scopeHostCss(matches[1], name);
      l = hostRuleRe.lastIndex;
    }
    r += cssText.substring(l, cssText.length);
    var re = new RegExp('^' + name + selectorReSuffix, 'm');
    var cssText = rulesToCss(this.findAtHostRules(cssToRules(r),
      re));
    return cssText;
  },
  scopeHostCss: function(cssText, name) {
    var r = '', matches;
    while (matches = selectorRe.exec(cssText)) {
      r += this.scopeHostSelector(matches[1], name) +' ' + matches[2] + '\n\t';
    }
    return r;
  },
  // supports scopig by name and  [is=name] syntax
  scopeHostSelector: function(selector, name) {
    var r = [], parts = selector.split(','), is = '[is=' + name + ']';
    parts.forEach(function(p) {
      p = p.trim();
      // selector: *|:scope -> name
      if (p.match(hostElementRe)) {
        p = p.replace(hostElementRe, name + '$1$3, ' + is + '$1$3');
      // selector: .foo -> name.foo, [bar] -> name[bar]
      } else if (p.match(hostFixableRe)) {
        p = name + p + ', ' + is + p;
      }
      r.push(p);
    }, this);
    return r.join(', ');
  },
  // consider styles that do not include component name in the selector to be
  // unscoped and in need of promotion;
  // for convenience, also consider keyframe rules this way.
  findAtHostRules: function(cssRules, matcher) {
    return Array.prototype.filter.call(cssRules,
      this.isHostRule.bind(this, matcher));
  },
  isHostRule: function(matcher, cssRule) {
    return (cssRule.selectorText && cssRule.selectorText.match(matcher)) ||
      (cssRule.cssRules && this.findAtHostRules(cssRule.cssRules, matcher).length) ||
      (cssRule.type == CSSRule.WEBKIT_KEYFRAMES_RULE);
  },
  /* Ensure styles are scoped. Pseudo-scoping takes a rule like:
   *
   *  .foo {... }
   *
   *  and converts this to
   *
   *  scopeName .foo { ... }
  */
  shimScoping: function(styles, name) {
    if (styles) {
      return this.convertScopedStyles(styles, name);
    }
  },
  convertScopedStyles: function(styles, name) {
    Array.prototype.forEach.call(styles, function(s) {
      if (s.parentNode) {
        s.parentNode.removeChild(s);
      }
    });
    var cssText = stylesToCssText(styles).replace(hostRuleRe, '');
    cssText = this.convertPseudos(cssText);
    var rules = cssToRules(cssText);
    cssText = this.scopeRules(rules, name);
    return cssText;
  },
  convertPseudos: function(cssText) {
    return cssText.replace(cssPseudoRe, ' [pseudo=$1]');
  },
  // change a selector like 'div' to 'name div'
  scopeRules: function(cssRules, name) {
    var cssText = '';
    Array.prototype.forEach.call(cssRules, function(rule) {
      if (rule.selectorText && (rule.style && rule.style.cssText)) {
        cssText += this.scopeSelector(rule.selectorText, name,
          this.strictStyling) + ' {\n\t';
        cssText += this.propertiesFromRule(rule) + '\n}\n\n';
      } else if (rule.media) {
        cssText += '@media ' + rule.media.mediaText + ' {\n';
        cssText += this.scopeRules(rule.cssRules, name);
        cssText += '\n}\n\n';
      } else if (rule.cssText) {
        cssText += rule.cssText + '\n\n';
      }
    }, this);
    return cssText;
  },
  scopeSelector: function(selector, name, strict) {
    var r = [], parts = selector.split(',');
    parts.forEach(function(p) {
      p = p.trim();
      if (this.selectorNeedsScoping(p, name)) {
        p = strict ? this.applyStrictSelectorScope(p, name) :
          this.applySimpleSelectorScope(p, name);
      }
      r.push(p);
    }, this);
    return r.join(', ');
  },
  selectorNeedsScoping: function(selector, name) {
    var matchScope = '(' + name + '|\\[is=' + name + '\\])';
    var re = new RegExp('^' + matchScope + selectorReSuffix, 'm');
    return !selector.match(re);
  },
  // scope via name and [is=name]
  applySimpleSelectorScope: function(selector, name) {
    return name + ' ' + selector + ', ' + '[is=' + name + '] ' + selector;
  },
  // return a selector with [name] suffix on each simple selector
  // e.g. .foo.bar > .zot becomes .foo[name].bar[name] > .zot[name]
  applyStrictSelectorScope: function(selector, name) {
    var splits = [' ', '>', '+', '~'],
      scoped = selector,
      attrName = '[' + name + ']';
    splits.forEach(function(sep) {
      var parts = scoped.split(sep);
      scoped = parts.map(function(p) {
        var t = p.trim();
        if (t && (splits.indexOf(t) < 0) && (t.indexOf(attrName) < 0)) {
          p = t.replace(/([^:]*)(:*)(.*)/, '$1' + attrName + '$2$3')
        }
        return p;
      }).join(sep);
    });
    return scoped;
  },
  propertiesFromRule: function(rule) {
    var properties = rule.style.cssText;
    // TODO(sorvell): Chrome cssom incorrectly removes quotes from the content
    // property. (https://code.google.com/p/chromium/issues/detail?id=247231)
    if (rule.style.content && !rule.style.content.match(/['"]+/)) {
      properties = 'content: \'' + rule.style.content + '\';\n' +
        rule.style.cssText.replace(/content:[^;]*;/g, '');
    }
    return properties;
  }
};

var hostRuleRe = /@host[^{]*{(([^}]*?{[^{]*?}[\s\S]*?)+)}/gim,
    selectorRe = /([^{]*)({[\s\S]*?})/gim,
    hostElementRe = /(.*)((?:\*)|(?:\:scope))(.*)/,
    hostFixableRe = /^[.\[:]/,
    cssCommentRe = /\/\*[^*]*\*+([^/*][^*]*\*+)*\//gim,
    cssPolyfillCommentRe = /\/\*\s*@polyfill ([^*]*\*+([^/*][^*]*\*+)*\/)([^{]*?){/gim,
    cssPseudoRe = /::(x-[^\s{,(]*)/gim,
    selectorReSuffix = '([>\\s~+\[.,{:][\\s\\S]*)?$',
    hostRe = /@host/gim;

function stylesToCssText(styles, preserveComments) {
  var cssText = '';
  Array.prototype.forEach.call(styles, function(s) {
    cssText += s.textContent + '\n\n';
  });
  // strip comments for easier processing
  if (!preserveComments) {
    cssText = cssText.replace(cssCommentRe, '');
  }
  return cssText;
}

function cssToRules(cssText) {
  var style = document.createElement('style');
  style.textContent = cssText;
  document.head.appendChild(style);
  var rules = style.sheet.cssRules;
  style.parentNode.removeChild(style);
  return rules;
}

function rulesToCss(cssRules) {
  for (var i=0, css=[]; i < cssRules.length; i++) {
    css.push(cssRules[i].cssText);
  }
  return css.join('\n\n');
}

function addCssToDocument(cssText) {
  if (cssText) {
    getSheet().appendChild(document.createTextNode(cssText));
  }
}

var sheet;
function getSheet() {
  if (!sheet) {
    sheet = document.createElement("style");
    sheet.setAttribute('ShadowCSSShim', '');
  }
  return sheet;
}

// add polyfill stylesheet to document
if (window.ShadowDOMPolyfill) {
  addCssToDocument('style { display: none !important; }\n');
  var head = document.querySelector('head');
  head.insertBefore(getSheet(), head.childNodes[0]);
}

// exports
scope.ShadowCSS = ShadowCSS;

})(window.Platform);