// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of csslib.parser;


// TODO(terry): Detect invalid directive usage.  All @imports must occur before
//              all rules other than @charset directive.  Any @import directive
//              after any non @charset or @import directive are ignored. e.g.,
//                  @import "a.css";
//                  div { color: red; }
//                  @import "b.css";
//              becomes:
//                  @import "a.css";
//                  div { color: red; }
// <http://www.w3.org/TR/css3-syntax/#at-rules>

/**
 * Analysis phase will validate/fixup any new CSS feature or any SASS style
 * feature.
 */
class Analyzer {
  final List<StyleSheet> _styleSheets;
  final Messages _messages;
  VarDefinitions varDefs;

  Analyzer(this._styleSheets, this._messages);

  void run() {
    varDefs = new VarDefinitions(_styleSheets);

    // Any cycles?
    var cycles = findAllCycles();
    for (var cycle in cycles) {
      _messages.warning("var cycle detected var-${cycle.definedName}",
          cycle.span);
      // TODO(terry): What if no var definition for a var usage an error?
      // TODO(terry): Ensure a var definition imported from a different style
      //              sheet works.
    }

    // Remove any var definition from the stylesheet that has a cycle.
    _styleSheets.forEach((styleSheet) =>
        new RemoveVarDefinitions(cycles).visitStyleSheet(styleSheet));

    // Expand any nested selectors using selector desendant combinator to
    // signal CSS inheritance notation.
    _styleSheets.forEach((styleSheet) => new ExpandNestedSelectors()
        ..visitStyleSheet(styleSheet)
        ..flatten(styleSheet));
  }

  List<VarDefinition> findAllCycles() {
    var cycles = [];

    varDefs.map.values.forEach((value) {
      if (hasCycle(value.property)) cycles.add(value);
     });

    // Update our local list of known varDefs remove any varDefs with a cycle.
    // So the same varDef cycle isn't reported for each style sheet processed.
    for (var cycle in cycles) {
      varDefs.map.remove(cycle.property);
    }

    return cycles;
  }

  Iterable<VarUsage> variablesOf(Expressions exprs) =>
      exprs.expressions.where((e) => e is VarUsage);

  bool hasCycle(String varName, {Set<String> visiting, Set<String> visited}) {
    if (visiting == null) visiting = new Set();
    if (visited == null) visited = new Set();
    if (visiting.contains(varName)) return true;
    if (visited.contains(varName)) return false;
    visiting.add(varName);
    visited.add(varName);
    bool cycleDetected = false;
    if (varDefs.map[varName] != null) {
      for (var usage in variablesOf(varDefs.map[varName].expression)) {
        if (hasCycle(usage.name, visiting: visiting, visited: visited)) {
          cycleDetected = true;
          break;
        }
      }
    }
    visiting.remove(varName);
    return cycleDetected;
  }

  // TODO(terry): Need to start supporting @host, custom pseudo elements,
  //              composition, intrinsics, etc.
}


/** Find all var definitions from a list of stylesheets. */
class VarDefinitions extends Visitor {
  /** Map of variable name key to it's definition. */
  final Map<String, VarDefinition> map = new Map<String, VarDefinition>();

  VarDefinitions(List<StyleSheet> styleSheets) {
    for (var styleSheet in styleSheets) {
      visitTree(styleSheet);
    }
  }

  void visitVarDefinition(VarDefinition node) {
    // Replace with latest variable definition.
    map[node.definedName] = node;
    super.visitVarDefinition(node);
  }

  void visitVarDefinitionDirective(VarDefinitionDirective node) {
    visitVarDefinition(node.def);
  }
}

/**
 * Remove the var definition from the stylesheet where it is defined; if it is
 * a definition from the list to delete.
 */
class RemoveVarDefinitions extends Visitor {
  final List<VarDefinition> _varDefsToRemove;

  RemoveVarDefinitions(this._varDefsToRemove);

  void visitStyleSheet(StyleSheet ss) {
    var idx = ss.topLevels.length;
    while(--idx >= 0) {
      var topLevel = ss.topLevels[idx];
      if (topLevel is VarDefinitionDirective &&
          _varDefsToRemove.contains(topLevel.def)) {
        ss.topLevels.removeAt(idx);
      }
    }

    super.visitStyleSheet(ss);
  }

  void visitDeclarationGroup(DeclarationGroup node) {
    var idx = node.declarations.length;
    while (--idx >= 0) {
      var decl = node.declarations[idx];
      if (decl is VarDefinition && _varDefsToRemove.contains(decl)) {
        node.declarations.removeAt(idx);
      }
    }

    super.visitDeclarationGroup(node);
  }
}

/**
 * Traverse all rulesets looking for nested ones.  If a ruleset is in a
 * declaration group (implies nested selector) then generate new ruleset(s) at
 * level 0 of CSS using selector inheritance syntax (flattens the nesting).
 *
 * How the AST works for a rule [RuleSet] and nested rules.  First of all a
 * CSS rule [RuleSet] consist of a selector and a declaration e.g.,
 *
 *    selector {
 *      declaration
 *    }
 *
 * AST structure of a [RuleSet] is:
 *
 *    RuleSet
 *       SelectorGroup
 *         List<Selector>
 *            List<SimpleSelectorSequence>
 *              Combinator      // +, >, ~, DESCENDENT, or NONE
 *              SimpleSelector  // class, id, element, namespace, attribute
 *        DeclarationGroup
 *          List                // Declaration or RuleSet
 *
 * For the simple rule:
 *
 *    div + span { color: red; }
 *
 * the AST [RuleSet] is:
 *
 *    RuleSet
 *       SelectorGroup
 *         List<Selector>
 *          [0]
 *            List<SimpleSelectorSequence>
 *              [0] Combinator = COMBINATOR_NONE
 *                  ElementSelector (name = div)
 *              [1] Combinator = COMBINATOR_PLUS
 *                  ElementSelector (name = span)
 *        DeclarationGroup
 *          List                // Declarations or RuleSets
 *            [0]
 *              Declaration (property = color, expression = red)
 *
 * Usually a SelectorGroup contains 1 Selector.  Consider the selectors:
 *
 *    div { color: red; }
 *    a { color: red; }
 *
 * are equivalent to
 *
 *    div, a { color : red; }
 *
 * In the above the RuleSet would have a SelectorGroup with 2 selectors e.g.,
 *
 *    RuleSet
 *       SelectorGroup
 *         List<Selector>
 *          [0]
 *            List<SimpleSelectorSequence>
 *              [0] Combinator = COMBINATOR_NONE
 *                  ElementSelector (name = div)
 *          [1]
 *            List<SimpleSelectorSequence>
 *              [0] Combinator = COMBINATOR_NONE
 *                  ElementSelector (name = a)
 *        DeclarationGroup
 *          List                // Declarations or RuleSets
 *            [0]
 *              Declaration (property = color, expression = red)
 *
 * For a nested rule e.g.,
 *
 *    div {
 *      color : blue;
 *      a { color : red; }
 *    }
 *
 * Would map to the follow CSS rules:
 *
 *    div { color: blue; }
 *    div a { color: red; }
 *
 * The AST for the former nested rule is:
 *
 *    RuleSet
 *       SelectorGroup
 *         List<Selector>
 *          [0]
 *            List<SimpleSelectorSequence>
 *              [0] Combinator = COMBINATOR_NONE
 *                  ElementSelector (name = div)
 *        DeclarationGroup
 *          List                // Declarations or RuleSets
 *            [0]
 *              Declaration (property = color, expression = blue)
 *            [1]
 *              RuleSet
 *                SelectorGroup
 *                  List<Selector>
 *                    [0]
 *                      List<SimpleSelectorSequence>
 *                        [0] Combinator = COMBINATOR_NONE
 *                            ElementSelector (name = a)
 *                DeclarationGroup
 *                  List                // Declarations or RuleSets
 *                    [0]
 *                      Declaration (property = color, expression = red)
 *
 * Nested rules is a terse mechanism to describe CSS inheritance.  The analyzer
 * will flatten and expand the nested rules to it's flatten strucure.  Using the
 * all parent [RuleSets] (selector expressions) and applying each nested
 * [RuleSet] to the list of [Selectors] in a [SelectorGroup].
 *
 * Then result is a style sheet where all nested rules have been flatten and
 * expanded.
 */
class ExpandNestedSelectors extends Visitor {
  /** Parent [RuleSet] if a nested rule otherwise [null]. */
  RuleSet _parentRuleSet;

  /** Top-most rule if nested rules. */
  SelectorGroup _topLevelSelectorGroup;

  /** SelectorGroup at each nesting level. */
  SelectorGroup _nestedSelectorGroup;

  /** Declaration (sans the nested selectors). */
  DeclarationGroup _flatDeclarationGroup;

  /** Each nested selector get's a flatten RuleSet. */
  List<RuleSet> _expandedRuleSets = [];

  /** Maping of a nested rule set to the fully expanded list of RuleSet(s). */
  final Map<RuleSet, List<RuleSet>> _expansions = new Map();

  void visitRuleSet(RuleSet node) {
    final oldParent = _parentRuleSet;

    var oldNestedSelectorGroups = _nestedSelectorGroup;

    if (_nestedSelectorGroup == null) {
      // Create top-level selector (may have nested rules).
      final newSelectors = node.selectorGroup.selectors.toList();
      _topLevelSelectorGroup = new SelectorGroup(newSelectors, node.span);
      _nestedSelectorGroup = _topLevelSelectorGroup;
    } else {
      // Generate new selector groups from the nested rules.
      _nestedSelectorGroup = _mergeToFlatten(node);
    }

    _parentRuleSet = node;

    super.visitRuleSet(node);

    _parentRuleSet = oldParent;

    // Remove nested rules; they're all flatten and in the _expandedRuleSets.
    node.declarationGroup.declarations.removeWhere((declaration) =>
        declaration is RuleSet);

    _nestedSelectorGroup = oldNestedSelectorGroups;

    // If any expandedRuleSets and we're back at the top-level rule set then
    // there were nested rule set(s).
    if (_parentRuleSet == null) {
      if (!_expandedRuleSets.isEmpty) {
        // Remember ruleset to replace with these flattened rulesets.
        _expansions[node] = _expandedRuleSets;
        _expandedRuleSets = [];
      }
      assert(_flatDeclarationGroup == null);
      assert(_nestedSelectorGroup == null);
    }
  }

  /**
   * Build up the list of all inherited sequences from the parent selector
   * [node] is the current nested selector and it's parent is the last entry in
   * the [_nestedSelectorGroup].
   */
  SelectorGroup _mergeToFlatten(RuleSet node) {
    // Create a new SelectorGroup for this nesting level.
    var nestedSelectors = _nestedSelectorGroup.selectors;
    var selectors = node.selectorGroup.selectors;

    // Create a merged set of previous parent selectors and current selectors.
    var newSelectors = [];
    for (Selector selector in selectors) {
      for (Selector nestedSelector in nestedSelectors) {
        var seq = _mergeNestedSelector(nestedSelector.simpleSelectorSequences,
            selector.simpleSelectorSequences);
        newSelectors.add(new Selector(seq, node.span));
      }
    }

    return new SelectorGroup(newSelectors, node.span);
  }

  /**
   * Merge the nested selector sequences [current] to the [parent] sequences or
   * substitue any & with the parent selector.
   */
  List<SimpleSelectorSequence> _mergeNestedSelector(
      List<SimpleSelectorSequence> parent,
      List<SimpleSelectorSequence> current) {

    // If any & operator then the parent selector will be substituted otherwise
    // the parent selector is pre-pended to the current selector.
    var hasThis = current.any((s) => s.simpleSelector.isThis);

    var newSequence = [];

    if (!hasThis) {
      // If no & in the sector group then prefix with the parent selector.
      newSequence.addAll(parent);
      newSequence.addAll(_convertToDescendentSequence(current));
    } else {
      for (var sequence in current) {
        if (sequence.simpleSelector.isThis) {
          // Substitue the & with the parent selector and only use a combinator
          // descendant if & is prefix by a sequence with an empty name e.g.,
          // "... + &", "&", "... ~ &", etc.
          var hasPrefix = !newSequence.isEmpty &&
              !newSequence.last.simpleSelector.name.isEmpty;
          newSequence.addAll(
              hasPrefix ? _convertToDescendentSequence(parent) : parent);
        } else {
          newSequence.add(sequence);
        }
      }
    }

    return newSequence;
  }

  /**
   * Return selector sequences with first sequence combinator being a
   * descendant.  Used for nested selectors when the parent selector needs to
   * be prefixed to a nested selector or to substitute the this (&) with the
   * parent selector.
   */
  List<SimpleSelectorSequence> _convertToDescendentSequence(
      List<SimpleSelectorSequence> sequences) {
    if (sequences.isEmpty) return sequences;

    var newSequences = [];
    var first = sequences.first;
    newSequences.add(new SimpleSelectorSequence(first.simpleSelector,
        first.span, TokenKind.COMBINATOR_DESCENDANT));
    newSequences.addAll(sequences.skip(1));

    return newSequences;
  }

  void visitDeclarationGroup(DeclarationGroup node) {
    var span = node.span;

    var currentGroup = new DeclarationGroup([], span);

    var oldGroup = _flatDeclarationGroup;
    _flatDeclarationGroup = currentGroup;

    var expandedLength = _expandedRuleSets.length;

    super.visitDeclarationGroup(node);

    // We're done with the group.
    _flatDeclarationGroup = oldGroup;

    // No nested rule to process it's a top-level rule.
    if (_nestedSelectorGroup == _topLevelSelectorGroup) return;

    // If flatten selector's declaration is empty skip this selector, no need
    // to emit an empty nested selector.
    if (currentGroup.declarations.isEmpty) return;

    var selectorGroup = _nestedSelectorGroup;

    // Build new rule set from the nested selectors and declarations.
    var newRuleSet = new RuleSet(selectorGroup, currentGroup, span);

    // Place in order so outer-most rule is first.
    if (expandedLength == _expandedRuleSets.length) {
      _expandedRuleSets.add(newRuleSet);
    } else {
      _expandedRuleSets.insert(expandedLength, newRuleSet);
    }
  }

  // Record all declarations in a nested selector (Declaration, VarDefinition
  // and MarginGroup) but not the nested rule in the Declaration.

  void visitDeclaration(Declaration node) {
    if (_parentRuleSet != null) {
      _flatDeclarationGroup.declarations.add(node);
    }
    super.visitDeclaration(node);
  }

  void visitVarDefinition(VarDefinition node) {
    if (_parentRuleSet != null) {
      _flatDeclarationGroup.declarations.add(node);
    }
    super.visitVarDefinition(node);
  }

  void visitMarginGroup(MarginGroup node) {
    if (_parentRuleSet != null) {
      _flatDeclarationGroup.declarations.add(node);
    }
    super.visitMarginGroup(node);
  }

  /**
   * Replace the rule set that contains nested rules with the flatten rule sets.
   */
  void flatten(StyleSheet styleSheet) {
    // TODO(terry): Iterate over topLevels instead of _expansions it's already
    //              a map (this maybe quadratic).
    _expansions.forEach((RuleSet ruleSet, List<RuleSet> newRules) {
      var index = styleSheet.topLevels.indexOf(ruleSet);
      if (index == -1) {
        // Check any @media directives for nested rules and replace them.
        var found = _MediaRulesReplacer.replace(styleSheet, ruleSet, newRules);
        assert(found);
      } else {
        styleSheet.topLevels.insertAll(index + 1, newRules);
      }
    });
    _expansions.clear();
  }
}

class _MediaRulesReplacer extends Visitor {
  RuleSet _ruleSet;
  List<RuleSet> _newRules;
  bool _foundAndReplaced = false;

  /**
   * Look for the [ruleSet] inside of an @media directive; if found then replace
   * with the [newRules].  If [ruleSet] is found and replaced return true.
   */
  static bool replace(StyleSheet styleSheet, RuleSet ruleSet,
                      List<RuleSet>newRules) {
    var visitor = new _MediaRulesReplacer(ruleSet, newRules);
    visitor.visitStyleSheet(styleSheet);
    return visitor._foundAndReplaced;
  }

  _MediaRulesReplacer(this._ruleSet, this._newRules);

  visitMediaDirective(MediaDirective node) {
    var index = node.rulesets.indexOf(_ruleSet);
    if (index != -1) {
      node.rulesets.insertAll(index + 1, _newRules);
      _foundAndReplaced = true;
    }
  }
}
