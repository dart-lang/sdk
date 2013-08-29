// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** Portion of the analyzer dealing with CSS sources. */
library polymer.src.css_analyzer;

import 'package:csslib/parser.dart' as css;
import 'package:csslib/visitor.dart';
import 'package:html5lib/dom.dart';
import 'package:html5lib/dom_parsing.dart';

import 'info.dart';
import 'files.dart' show SourceFile;
import 'messages.dart';
import 'compiler_options.dart';

void analyzeCss(String packageRoot, List<SourceFile> files,
                Map<String, FileInfo> info, Map<String, String> pseudoElements,
                Messages messages, {warningsAsErrors: false}) {
  var analyzer = new _AnalyzerCss(packageRoot, info, pseudoElements, messages,
      warningsAsErrors);
  for (var file in files) analyzer.process(file);
  analyzer.normalize();
}

class _AnalyzerCss {
  final String packageRoot;
  final Map<String, FileInfo> info;
  final Map<String, String> _pseudoElements;
  final Messages _messages;
  final bool _warningsAsErrors;

  Set<StyleSheet> allStyleSheets = new Set<StyleSheet>();

  /**
   * [_pseudoElements] list of known pseudo attributes found in HTML, any
   * CSS pseudo-elements 'name::custom-element' is mapped to the manged name
   * associated with the pseudo-element key.
   */
  _AnalyzerCss(this.packageRoot, this.info, this._pseudoElements,
               this._messages, this._warningsAsErrors);

  /**
   * Run the analyzer on every file that is a style sheet or any component that
   * has a style tag.
   */
  void process(SourceFile file) {
    var fileInfo = info[file.path];
    if (file.isStyleSheet || fileInfo.styleSheets.length > 0) {
      var styleSheets = processVars(fileInfo.inputUrl, fileInfo);

      // Add to list of all style sheets analyzed.
      allStyleSheets.addAll(styleSheets);
    }

    // Process any components.
    for (var component in fileInfo.declaredComponents) {
      var all = processVars(fileInfo.inputUrl, component);

      // Add to list of all style sheets analyzed.
      allStyleSheets.addAll(all);
    }

    processCustomPseudoElements();
  }

  void normalize() {
    // Remove all var definitions for all style sheets analyzed.
    for (var tree in allStyleSheets) new _RemoveVarDefinitions().visitTree(tree);
  }

  List<StyleSheet> processVars(inputUrl, libraryInfo) {
    // Get list of all stylesheet(s) dependencies referenced from this file.
    var styleSheets = _dependencies(inputUrl, libraryInfo).toList();

    var errors = [];
    css.analyze(styleSheets, errors: errors, options:
      [_warningsAsErrors ? '--warnings_as_errors' : '', 'memory']);

    // Print errors as warnings.
    for (var e in errors) {
      _messages.warning(e.message, e.span);
    }

    // Build list of all var definitions.
    Map varDefs = new Map();
    for (var tree in styleSheets) {
      var allDefs = (new _VarDefinitions()..visitTree(tree)).found;
      allDefs.forEach((key, value) {
        varDefs[key] = value;
      });
    }

    // Resolve all definitions to a non-VarUsage (terminal expression).
    varDefs.forEach((key, value) {
      for (var expr in (value.expression as Expressions).expressions) {
        var def = _findTerminalVarDefinition(varDefs, value);
        varDefs[key] = def;
      }
    });

    // Resolve all var usages.
    for (var tree in styleSheets) new _ResolveVarUsages(varDefs).visitTree(tree);

    return styleSheets;
  }

  processCustomPseudoElements() {
    var polyFiller = new _PseudoElementExpander(_pseudoElements);
    for (var tree in allStyleSheets) {
      polyFiller.visitTree(tree);
    }
  }

  /**
   * Given a component or file check if any stylesheets referenced.  If so then
   * return a list of all referenced stylesheet dependencies (@imports or <link
   * rel="stylesheet" ..>).
   */
  Set<StyleSheet> _dependencies(inputUrl, libraryInfo, {Set<StyleSheet> seen}) {
    if (seen == null) seen = new Set();

    for (var styleSheet in libraryInfo.styleSheets) {
      if (!seen.contains(styleSheet)) {
        // TODO(terry): VM uses expandos to implement hashes.  Currently, it's a
        //              linear (not constant) time cost (see dartbug.com/5746).
        //              If this bug isn't fixed and performance show's this a
        //              a problem we'll need to implement our own hashCode or
        //              use a different key for better perf.
        // Add the stylesheet.
        seen.add(styleSheet);

        // Any other imports in this stylesheet?
        var urlInfos = findImportsInStyleSheet(styleSheet, packageRoot,
            inputUrl, _messages);

        // Process other imports in this stylesheets.
        for (var importSS in urlInfos) {
          var importInfo = info[importSS.resolvedPath];
          if (importInfo != null) {
            // Add all known stylesheets processed.
            seen.addAll(importInfo.styleSheets);
            // Find dependencies for stylesheet referenced with a
            // @import
            for (var ss in importInfo.styleSheets) {
              var urls = findImportsInStyleSheet(ss, packageRoot, inputUrl,
                  _messages);
              for (var url in urls) {
                var fileInfo = info[url.resolvedPath];
                _dependencies(fileInfo.inputUrl, fileInfo, seen: seen);
              }
            }
          }
        }
      }
    }

    return seen;
  }
}

/**
 * Find var- definitions in a style sheet.
 * [found] list of known definitions.
 */
class _VarDefinitions extends Visitor {
  final Map<String, VarDefinition> found = new Map();

  void visitTree(StyleSheet tree) {
    visitStyleSheet(tree);
  }

  visitVarDefinition(VarDefinition node) {
    // Replace with latest variable definition.
    found[node.definedName] = node;
    super.visitVarDefinition(node);
  }

  void visitVarDefinitionDirective(VarDefinitionDirective node) {
    visitVarDefinition(node.def);
  }
}

/**
 * Resolve any CSS expression which contains a var() usage to the ultimate real
 * CSS expression value e.g.,
 *
 *    var-one: var(two);
 *    var-two: #ff00ff;
 *
 *    .test {
 *      color: var(one);
 *    }
 *
 * then .test's color would be #ff00ff
 */
class _ResolveVarUsages extends Visitor {
  final Map<String, VarDefinition> varDefs;
  bool inVarDefinition = false;
  bool inUsage = false;
  Expressions currentExpressions;

  _ResolveVarUsages(this.varDefs);

  void visitTree(StyleSheet tree) {
    visitStyleSheet(tree);
  }

  void visitVarDefinition(VarDefinition varDef) {
    inVarDefinition = true;
    super.visitVarDefinition(varDef);
    inVarDefinition = false;
  }

  void visitExpressions(Expressions node) {
    currentExpressions = node;
    super.visitExpressions(node);
    currentExpressions = null;
  }

  void visitVarUsage(VarUsage node) {
    // Don't process other var() inside of a varUsage.  That implies that the
    // default is a var() too.  Also, don't process any var() inside of a
    // varDefinition (they're just place holders until we've resolved all real
    // usages.
    if (!inUsage && !inVarDefinition && currentExpressions != null) {
      var expressions = currentExpressions.expressions;
      var index = expressions.indexOf(node);
      assert(index >= 0);
      var def = varDefs[node.name];
      if (def != null) {
        // Found a VarDefinition use it.
        _resolveVarUsage(currentExpressions.expressions, index, def);
      } else if (node.defaultValues.any((e) => e is VarUsage)) {
        // Don't have a VarDefinition need to use default values resolve all
        // default values.
        var terminalDefaults = [];
        for (var defaultValue in node.defaultValues) {
          terminalDefaults.addAll(resolveUsageTerminal(defaultValue));
        }
        expressions.replaceRange(index, index + 1, terminalDefaults);
      } else {
        // No VarDefinition but default value is a terminal expression; use it.
        expressions.replaceRange(index, index + 1, node.defaultValues);
      }
    }

    inUsage = true;
    super.visitVarUsage(node);
    inUsage = false;
  }

  List<Expression> resolveUsageTerminal(VarUsage usage) {
    var result = [];

    var varDef = varDefs[usage.name];
    var expressions;
    if (varDef == null) {
      // VarDefinition not found try the defaultValues.
      expressions = usage.defaultValues;
    } else {
      // Use the VarDefinition found.
      expressions = (varDef.expression as Expressions).expressions;
    }

    for (var expr in expressions) {
      if (expr is VarUsage) {
        // Get terminal value.
        result.addAll(resolveUsageTerminal(expr));
      }
    }

    // We're at a terminal just return the VarDefinition expression.
    if (result.isEmpty && varDef != null) {
      result = (varDef.expression as Expressions).expressions;
    }

    return result;
  }

  _resolveVarUsage(List<Expressions> expressions, int index,
                   VarDefinition def) {
    var defExpressions = (def.expression as Expressions).expressions;
    expressions.replaceRange(index, index + 1, defExpressions);
  }
}

/** Remove all var definitions. */
class _RemoveVarDefinitions extends Visitor {
  void visitTree(StyleSheet tree) {
    visitStyleSheet(tree);
  }

  void visitStyleSheet(StyleSheet ss) {
    ss.topLevels.removeWhere((e) => e is VarDefinitionDirective);
    super.visitStyleSheet(ss);
  }

  void visitDeclarationGroup(DeclarationGroup node) {
    node.declarations.removeWhere((e) => e is VarDefinition);
    super.visitDeclarationGroup(node);
  }
}

/**
 * Process all selectors looking for a pseudo-element in a selector.  If the
 * name is found in our list of known pseudo-elements.  Known pseudo-elements
 * are built when parsing a component looking for an attribute named "pseudo".
 * The value of the pseudo attribute is the name of the custom pseudo-element.
 * The name is mangled so Dart/JS can't directly access the pseudo-element only
 * CSS can access a custom pseudo-element (and see issue #510, querying needs
 * access to custom pseudo-elements).
 *
 * Change the custom pseudo-element to be a child of the pseudo attribute's
 * mangled custom pseudo element name. e.g,
 *
 *    .test::x-box
 *
 * would become:
 *
 *    .test > *[pseudo="x-box_2"]
 */
class _PseudoElementExpander extends Visitor {
  final Map<String, String> _pseudoElements;

  _PseudoElementExpander(this._pseudoElements);

  void visitTree(StyleSheet tree) => visitStyleSheet(tree);

  visitSelector(Selector node) {
    var selectors = node.simpleSelectorSequences;
    for (var index = 0; index < selectors.length; index++) {
      var selector = selectors[index].simpleSelector;
      if (selector is PseudoElementSelector) {
        if (_pseudoElements.containsKey(selector.name)) {
          // Pseudo Element is a custom element.
          var mangledName = _pseudoElements[selector.name];

          var span = selectors[index].span;

          var attrSelector = new AttributeSelector(
              new Identifier('pseudo', span), css.TokenKind.EQUALS,
              mangledName, span);
          // The wildcard * namespace selector.
          var wildCard = new ElementSelector(new Wildcard(span), span);
          selectors[index] = new SimpleSelectorSequence(wildCard, span,
                  css.TokenKind.COMBINATOR_GREATER);
          selectors.insert(++index,
              new SimpleSelectorSequence(attrSelector, span));
        }
      }
    }
  }
}

List<UrlInfo> findImportsInStyleSheet(StyleSheet styleSheet,
    String packageRoot, UrlInfo inputUrl, Messages messages) {
  var visitor = new _CssImports(packageRoot, inputUrl, messages);
  visitor.visitTree(styleSheet);
  return visitor.urlInfos;
}

/**
 * Find any imports in the style sheet; normalize the style sheet href and
 * return a list of all fully qualified CSS files.
 */
class _CssImports extends Visitor {
  final String packageRoot;

  /** Input url of the css file, used to normalize relative import urls. */
  final UrlInfo inputUrl;

  /** List of all imported style sheets. */
  final List<UrlInfo> urlInfos = [];

  final Messages _messages;

  _CssImports(this.packageRoot, this.inputUrl, this._messages);

  void visitTree(StyleSheet tree) {
    visitStyleSheet(tree);
  }

  void visitImportDirective(ImportDirective node) {
    var urlInfo = UrlInfo.resolve(node.import, inputUrl,
        node.span, packageRoot, _messages, ignoreAbsolute: true);
    if (urlInfo == null) return;
    urlInfos.add(urlInfo);
  }
}

StyleSheet parseCss(String content, Messages messages,
    CompilerOptions options) {
  if (content.trim().isEmpty) return null;

  var errors = [];

  // TODO(terry): Add --checked when fully implemented and error handling.
  var stylesheet = css.parse(content, errors: errors, options:
      [options.warningsAsErrors ? '--warnings_as_errors' : '', 'memory']);

  // Note: errors aren't fatal in HTML (unless strict mode is on).
  // So just print them as warnings.
  for (var e in errors) {
    messages.warning(e.message, e.span);
  }

  return stylesheet;
}

/** Find terminal definition (non VarUsage implies real CSS value). */
VarDefinition _findTerminalVarDefinition(Map<String, VarDefinition> varDefs,
                                        VarDefinition varDef) {
  var expressions = varDef.expression as Expressions;
  for (var expr in expressions.expressions) {
    if (expr is VarUsage) {
      var usageName = (expr as VarUsage).name;
      var foundDef = varDefs[usageName];

      // If foundDef is unknown check if defaultValues; if it exist then resolve
      // to terminal value.
      if (foundDef == null) {
        // We're either a VarUsage or terminal definition if in varDefs;
        // either way replace VarUsage with it's default value because the
        // VarDefinition isn't found.
        var defaultValues = (expr as VarUsage).defaultValues;
        var replaceExprs = expressions.expressions;
        assert(replaceExprs.length == 1);
        replaceExprs.replaceRange(0, 1, defaultValues);
        return varDef;
      }
      if (foundDef is VarDefinition) {
        return _findTerminalVarDefinition(varDefs, foundDef);
      }
    } else {
      // Return real CSS property.
      return varDef;
    }
  }

  // Didn't point to a var definition that existed.
  return varDef;
}

/**
 * Find urls imported inside style tags under [info].  If [info] is a FileInfo
 * then process only style tags in the body (don't process any style tags in a
 * component).  If [info] is a ComponentInfo only process style tags inside of
 * the element are processed.  For an [info] of type FileInfo [node] is the
 * file's document and for an [info] of type ComponentInfo then [node] is the
 * component's element tag.
 */
List<UrlInfo> findUrlsImported(LibraryInfo info, UrlInfo inputUrl,
    String packageRoot, Node node, Messages messages, CompilerOptions options) {
  // Process any @imports inside of the <style> tag.
  var styleProcessor =
      new _CssStyleTag(packageRoot, info, inputUrl, messages, options);
  styleProcessor.visit(node);
  return styleProcessor.imports;
}

/* Process CSS inside of a style tag. */
class _CssStyleTag extends TreeVisitor {
  final String _packageRoot;

  /** Either a FileInfo or ComponentInfo. */
  final LibraryInfo _info;
  final Messages _messages;
  final CompilerOptions _options;

  /**
   * Path of the declaring file, for a [_info] of type FileInfo it's the file's
   * path for a type ComponentInfo it's the declaring file path.
   */
  final UrlInfo _inputUrl;

  /** List of @imports found. */
  List<UrlInfo> imports = [];

  _CssStyleTag(this._packageRoot, this._info, this._inputUrl, this._messages,
      this._options);

  void visitElement(Element node) {
    // Don't process any style tags inside of element if we're processing a
    // FileInfo.  The style tags inside of a component defintion will be
    // processed when _info is a ComponentInfo.
    if (node.tagName == 'polymer-element' && _info is FileInfo) return;
    if (node.tagName == 'style') {
      // Parse the contents of the scoped style tag.
      var styleSheet = parseCss(node.nodes.single.value, _messages, _options);
      if (styleSheet != null) {
        _info.styleSheets.add(styleSheet);

        // Find all imports return list of @imports in this style tag.
        var urlInfos = findImportsInStyleSheet(styleSheet, _packageRoot,
            _inputUrl, _messages);
        imports.addAll(urlInfos);
      }
    }
    super.visitElement(node);
  }
}
