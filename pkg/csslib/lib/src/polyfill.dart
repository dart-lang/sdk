// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of csslib.parser;

/**
 * CSS polyfill emits CSS to be understood by older parsers that which do not
 * understand (var, calc, etc.).
 */
class PolyFill {
  final Messages _messages;
  final bool _warningsAsErrors;

  Set<StyleSheet> allStyleSheets = new Set<StyleSheet>();

  /**
   * [_pseudoElements] list of known pseudo attributes found in HTML, any
   * CSS pseudo-elements 'name::custom-element' is mapped to the manged name
   * associated with the pseudo-element key.
   */
  PolyFill(this._messages, this._warningsAsErrors);

  /**
   * Run the analyzer on every file that is a style sheet or any component that
   * has a style tag.
   */
  void process(StyleSheet stylesheet) {
    // TODO(terry): Process all imported stylesheets.

    var styleSheets = processVars([stylesheet]);
    allStyleSheets.addAll(styleSheets);

    normalize();
  }

  void normalize() {
    // Remove all var definitions for all style sheets analyzed.
    for (var tree in allStyleSheets)
      new _RemoveVarDefinitions().visitTree(tree);
  }

  List<StyleSheet> processVars(List<StyleSheet> styleSheets) {
    // TODO(terry): Process all dependencies.
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
    for (var tree in styleSheets) {
      new _ResolveVarUsages(varDefs).visitTree(tree);
    }

    return styleSheets;
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
