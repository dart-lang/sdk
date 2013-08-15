// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

(function(scope) {
  // TODO(terry): Remove shimShadowDOMStyling2 until wrap/unwrap from a
  //              dart:html Element to a JS DOM node is available.
  /**
   * Given the content of a STYLE tag and the name of a component shim the CSS
   * and return the new scoped CSS to replace the STYLE's content.  The content
   * is replaced in Dart's implementation of PolymerElement.
   */
  function shimShadowDOMStyling2(styleContent, name) {
    if (window.ShadowDOMPolyfill) {
      var content = this.convertPolyfillDirectives(styleContent, name);

      // applyShimming calls shimAtHost and shipScoping
      // shimAtHost code:
      var r = '', l=0, matches;
      while (matches = hostRuleRe.exec(content)) {
        r += content.substring(l, matches.index);
        r += this.scopeHostCss(matches[1], name);
        l = hostRuleRe.lastIndex;
      }
      r += content.substring(l, content.length);
      var re = new RegExp('^' + name + selectorReSuffix, 'm');
      var atHostCssText = rulesToCss(this.findAtHostRules(cssToRules(r), re));

      // shimScoping code:
      // strip comments for easier processing
      content = content.replace(cssCommentRe, '');

      content = this.convertPseudos(content);
      var rules = cssToRules(content);
      var cssText = this.scopeRules(rules, name);

      return atHostCssText + cssText;
    }
  }

  // Minimal copied code from ShadowCSS, that is not exposed in
  // PlatForm.ShadowCSS (local code).
  var hostRuleRe = /@host[^{]*{(([^}]*?{[^{]*?}[\s\S]*?)+)}/gim,
    cssCommentRe = /\/\*[^*]*\*+([^/*][^*]*\*+)*\//gim,
    selectorReSuffix = '([>\\s~+\[.,{:][\\s\\S]*)?$';

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

  // exports
  scope.ShadowCSS.shimShadowDOMStyling2 = shimShadowDOMStyling2;
})(window.Platform);
