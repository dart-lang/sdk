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

  * ::part(): These rules are converted to rules that take advantage of the
  part attribute. For example, a shadowRoot like this inside an x-foo

    <div part="special">Special</div>

  with a rule like this:

    x-foo::part(special) { ... }

  becomes:

    x-foo [part=special] { ... }

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
  // 3. shim polyfill directives /* @polyfill */ and /* @polyfill-rule */
  // 4. shim @host and scoping
  shimStyling: function(root, name, extendsName) {
    var typeExtension = this.isTypeExtension(extendsName);
    // use caching to make working with styles nodes easier and to facilitate
    // lookup of extendee
    var def = this.registerDefinition(root, name, extendsName);
    // find styles and apply shimming...
    if (this.strictStyling) {
      this.applyScopeToContent(root, name);
    }
    // insert @polyfill and @polyfill-rule rules into style elements
    // scoping process takes care of shimming these
    this.insertPolyfillDirectives(def.rootStyles);
    this.insertPolyfillRules(def.rootStyles);
    var cssText = this.stylesToShimmedCssText(def.scopeStyles, name,
        typeExtension);
    // note: we only need to do rootStyles since these are unscoped.
    cssText += this.extractPolyfillUnscopedRules(def.rootStyles);
    // provide shimmedStyle for user extensibility
    def.shimmedStyle = cssTextToStyle(cssText);
    if (root) {
      root.shimmedStyle = def.shimmedStyle;
    }
    // remove existing style elements
    for (var i=0, l=def.rootStyles.length, s; (i<l) && (s=def.rootStyles[i]);
        i++) {
      s.parentNode.removeChild(s);
    }
    // add style to document
    addCssToDocument(cssText);
  },
  registerDefinition: function(root, name, extendsName) {
    var def = this.registry[name] = {
      root: root,
      name: name,
      extendsName: extendsName
    }
    var styles = root ? root.querySelectorAll('style') : [];
    styles = styles ? Array.prototype.slice.call(styles, 0) : [];
    def.rootStyles = styles;
    def.scopeStyles = def.rootStyles;
    var extendee = this.registry[def.extendsName];
    if (extendee && (!root || root.querySelector('shadow'))) {
      def.scopeStyles = extendee.scopeStyles.concat(def.scopeStyles);
    }
    return def;
  },
  isTypeExtension: function(extendsName) {
    return extendsName && extendsName.indexOf('-') < 0;
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
   * (comment start) @polyfill :host menu-item (comment end)
   * shadow::-webkit-distributed(menu-item) {
   *
   * to this:
   *
   * scopeName menu-item {
   *
  **/
  insertPolyfillDirectives: function(styles) {
    if (styles) {
      Array.prototype.forEach.call(styles, function(s) {
        s.textContent = this.insertPolyfillDirectivesInCssText(s.textContent);
      }, this);
    }
  },
  insertPolyfillDirectivesInCssText: function(cssText) {
    return cssText.replace(cssPolyfillCommentRe, function(match, p1) {
      // remove end comment delimiter and add block start
      return p1.slice(0, -2) + '{';
    });
  },
  /*
   * Process styles to add rules which will only apply under the polyfill
   *
   * For example, we convert this rule:
   *
   * (comment start) @polyfill-rule :host menu-item {
   * ... } (comment end)
   *
   * to this:
   *
   * scopeName menu-item {...}
   *
  **/
  insertPolyfillRules: function(styles) {
    if (styles) {
      Array.prototype.forEach.call(styles, function(s) {
        s.textContent = this.insertPolyfillRulesInCssText(s.textContent);
      }, this);
    }
  },
  insertPolyfillRulesInCssText: function(cssText) {
    return cssText.replace(cssPolyfillRuleCommentRe, function(match, p1) {
      // remove end comment delimiter
      return p1.slice(0, -1);
    });
  },
  /*
   * Process styles to add rules which will only apply under the polyfill
   * and do not process via CSSOM. (CSSOM is destructive to rules on rare
   * occasions, e.g. -webkit-calc on Safari.)
   * For example, we convert this rule:
   *
   * (comment start) @polyfill-unscoped-rule menu-item {
   * ... } (comment end)
   *
   * to this:
   *
   * menu-item {...}
   *
  **/
  extractPolyfillUnscopedRules: function(styles) {
    var cssText = '';
    if (styles) {
      Array.prototype.forEach.call(styles, function(s) {
        cssText += this.extractPolyfillUnscopedRulesFromCssText(
            s.textContent) + '\n\n';
      }, this);
    }
    return cssText;
  },
  extractPolyfillUnscopedRulesFromCssText: function(cssText) {
    var r = '', matches;
    while (matches = cssPolyfillUnscopedRuleCommentRe.exec(cssText)) {
      r += matches[1].slice(0, -1) + '\n\n';
    }
    return r;
  },
  // apply @host and scope shimming
  stylesToShimmedCssText: function(styles, name, typeExtension) {
    return this.shimAtHost(styles, name, typeExtension) +
        this.shimScoping(styles, name, typeExtension);
  },
  // form: @host { .foo { declarations } }
  // becomes: scopeName.foo { declarations }
  shimAtHost: function(styles, name, typeExtension) {
    if (styles) {
      return this.convertAtHostStyles(styles, name, typeExtension);
    }
  },
  convertAtHostStyles: function(styles, name, typeExtension) {
    var cssText = stylesToCssText(styles), self = this;
    cssText = cssText.replace(hostRuleRe, function(m, p1) {
      return self.scopeHostCss(p1, name, typeExtension);
    });
    cssText = rulesToCss(this.findAtHostRules(cssToRules(cssText),
      new RegExp('^' + name + selectorReSuffix, 'm')));
    return cssText;
  },
  scopeHostCss: function(cssText, name, typeExtension) {
    var self = this;
    return cssText.replace(selectorRe, function(m, p1, p2) {
      return self.scopeHostSelector(p1, name, typeExtension) + ' ' + p2 + '\n\t';
    });
  },
  // supports scopig by name and  [is=name] syntax
  scopeHostSelector: function(selector, name, typeExtension) {
    var r = [], parts = selector.split(','), is = '[is=' + name + ']';
    parts.forEach(function(p) {
      p = p.trim();
      // selector: *|:scope -> name
      if (p.match(hostElementRe)) {
        p = p.replace(hostElementRe, typeExtension ? is + '$1$3' :
            name + '$1$3');
      // selector: .foo -> name.foo (OR) [bar] -> name[bar]
      } else if (p.match(hostFixableRe)) {
        p = typeExtension ? is + p : name + p;
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
  shimScoping: function(styles, name, typeExtension) {
    if (styles) {
      return this.convertScopedStyles(styles, name, typeExtension);
    }
  },
  convertScopedStyles: function(styles, name, typeExtension) {
    var cssText = stylesToCssText(styles).replace(hostRuleRe, '');
    cssText = this.insertPolyfillHostInCssText(cssText);
    cssText = this.convertColonHost(cssText);
    cssText = this.convertPseudos(cssText);
    cssText = this.convertParts(cssText);
    cssText = this.convertCombinators(cssText);
    var rules = cssToRules(cssText);
    cssText = this.scopeRules(rules, name, typeExtension);
    return cssText;
  },
  convertPseudos: function(cssText) {
    return cssText.replace(cssPseudoRe, ' [pseudo=$1]');
  },
  convertParts: function(cssText) {
    return cssText.replace(cssPartRe, ' [part=$1]');
  },
  /*
   * convert a rule like :host(.foo) > .bar { }
   *
   * to
   *
   * scopeName.foo > .bar, .foo scopeName > .bar { }
   * TODO(sorvell): file bug since native impl does not do the former yet.
   * http://jsbin.com/OganOCI/2/edit
  */
  convertColonHost: function(cssText) {
    // p1 = :host, p2 = contents of (), p3 rest of rule
    return cssText.replace(cssColonHostRe, function(m, p1, p2, p3) {
      return p2 ? polyfillHostNoCombinator + p2 + p3 + ', '
          + p2 + ' ' + p1 + p3 :
          p1 + p3;
    });
  },
  /*
   * Convert ^ and ^^ combinators by replacing with space.
  */
  convertCombinators: function(cssText) {
    return cssText.replace('^^', ' ').replace('^', ' ');
  },
  // change a selector like 'div' to 'name div'
  scopeRules: function(cssRules, name, typeExtension) {
    var cssText = '';
    Array.prototype.forEach.call(cssRules, function(rule) {
      if (rule.selectorText && (rule.style && rule.style.cssText)) {
        cssText += this.scopeSelector(rule.selectorText, name, typeExtension,
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
  scopeSelector: function(selector, name, typeExtension, strict) {
    var r = [], parts = selector.split(',');
    parts.forEach(function(p) {
      p = p.trim();
      if (this.selectorNeedsScoping(p, name, typeExtension)) {
        p = strict ? this.applyStrictSelectorScope(p, name) :
          this.applySimpleSelectorScope(p, name, typeExtension);
      }
      r.push(p);
    }, this);
    return r.join(', ');
  },
  selectorNeedsScoping: function(selector, name, typeExtension) {
    var matchScope = typeExtension ? name : '\\[is=' + name + '\\]';
    var re = new RegExp('^(' + matchScope + ')' + selectorReSuffix, 'm');
    return !selector.match(re);
  },
  // scope via name and [is=name]
  applySimpleSelectorScope: function(selector, name, typeExtension) {
    var scoper = typeExtension ? '[is=' + name + ']' : name;
    if (selector.match(polyfillHostRe)) {
      selector = selector.replace(polyfillHostNoCombinator, scoper);
      return selector.replace(polyfillHostRe, scoper + ' ');
    } else {
      return scoper + ' ' + selector;
    }
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
        // remove :host since it should be unnecessary
        var t = p.trim().replace(polyfillHostRe, '');
        if (t && (splits.indexOf(t) < 0) && (t.indexOf(attrName) < 0)) {
          p = t.replace(/([^:]*)(:*)(.*)/, '$1' + attrName + '$2$3')
        }
        return p;
      }).join(sep);
    });
    return scoped;
  },
  insertPolyfillHostInCssText: function(selector) {
    return selector.replace(hostRe, polyfillHost).replace(colonHostRe,
        polyfillHost);
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
    cssPolyfillRuleCommentRe = /\/\*\s@polyfill-rule([^*]*\*+([^/*][^*]*\*+)*)\//gim,
    cssPolyfillUnscopedRuleCommentRe = /\/\*\s@polyfill-unscoped-rule([^*]*\*+([^/*][^*]*\*+)*)\//gim,
    cssPseudoRe = /::(x-[^\s{,(]*)/gim,
    cssPartRe = /::part\(([^)]*)\)/gim,
    // note: :host pre-processed to -host.
    cssColonHostRe = /(-host)(?:\(([^)]*)\))?([^,{]*)/gim,
    selectorReSuffix = '([>\\s~+\[.,{:][\\s\\S]*)?$',
    hostRe = /@host/gim,
    colonHostRe = /\:host/gim,
    polyfillHost = '-host',
    /* host name without combinator */
    polyfillHostNoCombinator = '-host-no-combinator',
    polyfillHostRe = /-host/gim;

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

function cssTextToStyle(cssText) {
  var style = document.createElement('style');
  style.textContent = cssText;
  return style;
}

function cssToRules(cssText) {
  var style = cssTextToStyle(cssText);
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
