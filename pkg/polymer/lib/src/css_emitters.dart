// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library polymer.src.css_emitters;

import 'package:csslib/visitor.dart' show Visitor, CssPrinter, ElementSelector,
       UriTerm, Selector, HostDirective, SimpleSelectorSequence, StyleSheet;

import 'info.dart';
import 'paths.dart' show PathMapper;
import 'utils.dart';

void rewriteCssUris(PathMapper pathMapper, String cssPath, bool rewriteUrls,
    StyleSheet styleSheet) {
  new _UriVisitor(pathMapper, cssPath, rewriteUrls).visitTree(styleSheet);
}

/** Compute each CSS URI resource relative from the generated CSS file. */
class _UriVisitor extends Visitor {
  /**
   * Relative path from the output css file to the location of the original
   * css file that contained the URI to each resource.
   */
  final String _pathToOriginalCss;

  factory _UriVisitor(PathMapper pathMapper, String cssPath, bool rewriteUrl) {
    var cssDir = path.dirname(cssPath);
    var outCssDir = rewriteUrl ? pathMapper.outputDirPath(cssPath)
        : path.dirname(cssPath);
    return new _UriVisitor._internal(path.relative(cssDir, from: outCssDir));
  }

  _UriVisitor._internal(this._pathToOriginalCss);

  void visitUriTerm(UriTerm node) {
    // Don't touch URIs that have any scheme (http, etc.).
    var uri = Uri.parse(node.text);
    if (uri.host != '') return;
    if (uri.scheme != '' && uri.scheme != 'package') return;

    node.text = pathToUrl(
        path.normalize(path.join(_pathToOriginalCss, node.text)));
  }
}


/** Emit the contents of the style tag outside of a component. */
String emitStyleSheet(StyleSheet ss, FileInfo file) =>
  (new _CssEmitter(file.components.keys.toSet())
      ..visitTree(ss, pretty: true)).toString();

/** Emit a component's style tag content emulating scoped css. */
String emitComponentStyleSheet(StyleSheet ss, String tagName) =>
    (new _ComponentCssEmitter(tagName)..visitTree(ss, pretty: true)).toString();

String emitOriginalCss(StyleSheet css) =>
    (new CssPrinter()..visitTree(css)).toString();

/** Only x-tag name element selectors are emitted as [is="x-"]. */
class _CssEmitter extends CssPrinter {
  final Set _componentsTag;
  _CssEmitter(this._componentsTag);

  void visitElementSelector(ElementSelector node) {
    // If element selector is a component's tag name, then change selector to
    // find element who's is attribute's the component's name.
    if (_componentsTag.contains(node.name)) {
      emit('[is="${node.name}"]');
      return;
    }
    super.visitElementSelector(node);
  }
}

/**
 * Emits a css stylesheet applying rules to emulate scoped css. The rules adjust
 * element selectors to include the component's tag name.
 */
class _ComponentCssEmitter extends CssPrinter {
  final String _componentTagName;
  bool _inHostDirective = false;
  bool _selectorStartInHostDirective = false;

  _ComponentCssEmitter(this._componentTagName);

  /** Is the element selector an x-tag name. */
  bool _isSelectorElementXTag(Selector node) {
    if (node.simpleSelectorSequences.length > 0) {
      var selector = node.simpleSelectorSequences[0].simpleSelector;
      return selector is ElementSelector && selector.name == _componentTagName;
    }
    return false;
  }

  void visitSelector(Selector node) {
    // If the selector starts with an x-tag name don't emit it twice.
    if (!_isSelectorElementXTag(node)) {
      if (_inHostDirective) {
        // Style the element that's hosting the component, therefore don't emit
        // the descendent combinator (first space after the [is="x-..."]).
        emit('[is="$_componentTagName"]');
        // Signal that first simpleSelector must be checked.
        _selectorStartInHostDirective = true;
      } else {
        // Emit its scoped as a descendent (space at end).
        emit('[is="$_componentTagName"] ');
      }
    }
    super.visitSelector(node);
  }

  /**
   * If first simple selector of a ruleset in a @host directive is a wildcard
   * then don't emit the wildcard.
   */
  void visitSimpleSelectorSequence(SimpleSelectorSequence node) {
    if (_selectorStartInHostDirective) {
      _selectorStartInHostDirective = false;
      if (node.simpleSelector.isWildcard) {
        // Skip the wildcard if first item in the sequence.
        return;
      }
      assert(node.isCombinatorNone);
    }

    super.visitSimpleSelectorSequence(node);
  }

  void visitElementSelector(ElementSelector node) {
    // If element selector is the component's tag name, then change selector to
    // find element who's is attribute is the component's name.
    if (_componentTagName == node.name) {
      emit('[is="$_componentTagName"]');
      return;
    }
    super.visitElementSelector(node);
  }

  /**
   * If we're polyfilling scoped styles the @host directive is stripped.  Any
   * ruleset(s) processed in an @host will fixup the first selector.  See
   * visitSelector and visitSimpleSelectorSequence in this class, they adjust
   * the selectors so it styles the element hosting the compopnent.
   */
  void visitHostDirective(HostDirective node) {
    _inHostDirective = true;
    emit('/* @host */');
    for (var ruleset in node.rulesets) {
      ruleset.visit(this);
    }
    _inHostDirective = false;
    emit('/* end of @host */\n');
  }
}
