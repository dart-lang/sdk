// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of csslib.parser;


// TODO(terry): Add optimizing phase to remove duplicated selectors in the same
//              selector group (e.g., .btn, .btn { color: red; }).  Also, look
//              at simplifying selectors expressions too (much harder).
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

  Analyzer(this._styleSheets, this._messages);

  // TODO(terry): Currently each feature walks the AST each time.  Once we have
  //               our complete feature set consider benchmarking the cost and
  //               possibly combine in one walk.
  void run() {
    // Expand top-level @include.
    _styleSheets.forEach((styleSheet) =>
        TopLevelIncludes.expand(_messages, _styleSheets));

    // Expand @include in declarations.
    _styleSheets.forEach((styleSheet) =>
        DeclarationIncludes.expand(_messages, _styleSheets));

    // Remove all @mixin and @include
    _styleSheets.forEach((styleSheet) => MixinsAndIncludes.remove(styleSheet));

    // Expand any nested selectors using selector desendant combinator to
    // signal CSS inheritance notation.
    _styleSheets.forEach((styleSheet) => new ExpandNestedSelectors()
        ..visitStyleSheet(styleSheet)
        ..flatten(styleSheet));

    // Expand any @extend.
    _styleSheets.forEach((styleSheet) {
        var allExtends = new AllExtends()..visitStyleSheet(styleSheet);
        new InheritExtends(_messages, allExtends)..visitStyleSheet(styleSheet);
    });
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
  /** Parent [RuleSet] if a nested rule otherwise [:null:]. */
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

  void visitExtendDeclaration(ExtendDeclaration node) {
    if (_parentRuleSet != null) {
      _flatDeclarationGroup.declarations.add(node);
    }
    super.visitExtendDeclaration(node);
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

/**
 * Expand all @include at the top-level the ruleset(s) associated with the
 * mixin.
 */
class TopLevelIncludes extends Visitor {
  StyleSheet _styleSheet;
  final Messages _messages;
  /** Map of variable name key to it's definition. */
  final Map<String, MixinDefinition> map = new Map<String, MixinDefinition>();
  MixinDefinition currDef;

  static void expand(Messages messages, List<StyleSheet> styleSheets) {
    new TopLevelIncludes(messages, styleSheets);
  }

  bool _anyRulesets(MixinRulesetDirective def) =>
      def.rulesets.any((rule) => rule is RuleSet);

  TopLevelIncludes(this._messages, List<StyleSheet> styleSheets) {
    for (var styleSheet in styleSheets) {
      visitTree(styleSheet);
    }
  }

  void visitStyleSheet(StyleSheet ss) {
    _styleSheet = ss;
    super.visitStyleSheet(ss);
    _styleSheet = null;
  }

  void visitIncludeDirective(IncludeDirective node) {
    if (map.containsKey(node.name)) {
      var mixinDef = map[node.name];
      if (mixinDef is MixinRulesetDirective) {
        _TopLevelIncludeReplacer.replace(_messages, _styleSheet, node,
            mixinDef.rulesets);
      } else if (currDef is MixinRulesetDirective && _anyRulesets(currDef)) {
        // currDef is MixinRulesetDirective
        MixinRulesetDirective mixinRuleset = currDef;
        int index = mixinRuleset.rulesets.indexOf(node as dynamic);
        mixinRuleset.rulesets.replaceRange(index, index + 1, [new NoOp()]);
        _messages.warning(
            'Using declaration mixin ${node.name} as top-level mixin',
            node.span);
      }
    } else {
      if (currDef is MixinRulesetDirective) {
        MixinRulesetDirective rulesetDirect = currDef as MixinRulesetDirective;
        var index = 0;
        rulesetDirect.rulesets.forEach((entry) {
          if (entry == node) {
            rulesetDirect.rulesets.replaceRange(index, index + 1, [new NoOp()]);
            _messages.warning('Undefined mixin ${node.name}', node.span);
          }
          index++;
        });
      }
    }
    super.visitIncludeDirective(node);
  }

  void visitMixinRulesetDirective(MixinRulesetDirective node) {
    currDef = node;

    super.visitMixinRulesetDirective(node);

    // Replace with latest top-level mixin definition.
    map[node.name] = node;
    currDef = null;
  }

  void visitMixinDeclarationDirective(MixinDeclarationDirective node) {
    currDef = node;

    super.visitMixinDeclarationDirective(node);

    // Replace with latest mixin definition.
    map[node.name] = node;
    currDef = null;
  }
}

/** @include as a top-level with ruleset(s). */
class _TopLevelIncludeReplacer extends Visitor {
  final Messages _messages;
  final IncludeDirective _include;
  final List<RuleSet> _newRules;
  bool _foundAndReplaced = false;

  /**
   * Look for the [ruleSet] inside of an @media directive; if found then replace
   * with the [newRules].  If [ruleSet] is found and replaced return true.
   */
  static bool replace(Messages messages, StyleSheet styleSheet,
      IncludeDirective include, List<RuleSet>newRules) {
    var visitor = new _TopLevelIncludeReplacer(messages, include, newRules);
    visitor.visitStyleSheet(styleSheet);
    return visitor._foundAndReplaced;
  }

  _TopLevelIncludeReplacer(this._messages, this._include, this._newRules);

  visitStyleSheet(StyleSheet node) {
    var index = node.topLevels.indexOf(_include);
    if (index != -1) {
      node.topLevels.insertAll(index + 1, _newRules);
      node.topLevels.replaceRange(index, index + 1, [new NoOp()]);
      _foundAndReplaced = true;
    }
    super.visitStyleSheet(node);
  }

  void visitMixinRulesetDirective(MixinRulesetDirective node) {
    var index = node.rulesets.indexOf(_include as dynamic);
    if (index != -1) {
      node.rulesets.insertAll(index + 1, _newRules);
      // Only the resolve the @include once.
      node.rulesets.replaceRange(index, index + 1, [new NoOp()]);
      _foundAndReplaced = true;
    }
    super.visitMixinRulesetDirective(node);
  }
}

/**
 * Utility function to match an include to a list of either Declarations or
 * RuleSets, depending on type of mixin (ruleset or declaration).  The include
 * can be an include in a declaration or an include directive (top-level).
 */
int _findInclude(List list, var node) {
  IncludeDirective matchNode = (node is IncludeMixinAtDeclaration) ?
      node.include : node;

  var index = 0;
  for (var item in list) {
    var includeNode = (item is IncludeMixinAtDeclaration) ?
        item.include : item;
    if (includeNode == matchNode) return index;
    index++;
  }
  return -1;
}

/**
 * Stamp out a mixin with the defined args substituted with the user's
 * parameters.
 */
class CallMixin extends Visitor {
  final MixinDefinition mixinDef;
  List _definedArgs;
  Expressions _currExpressions;
  int _currIndex = -1;

  final varUsages = new Map<String, Map<Expressions, Set<int>>>();

  /** Only var defs with more than one expression (comma separated). */
  final Map<String, VarDefinition> varDefs;

  CallMixin(this.mixinDef, [this.varDefs]) {
    if (mixinDef is MixinRulesetDirective) {
      visitMixinRulesetDirective(mixinDef);
    } else {
      visitMixinDeclarationDirective(mixinDef);
    }
  }

  /**
   * Given a mixin's defined arguments return a cloned mixin defintion that has
   * replaced all defined arguments with user's supplied VarUsages.
   */
  MixinDefinition transform(List<TreeNode> callArgs) {
    // TODO(terry): Handle default arguments and varArgs.
    // Transform mixin with callArgs.
    var index = 0;
    for (var index = 0; index < _definedArgs.length; index++) {
      var definedArg = _definedArgs[index];
      VarDefinition varDef;
      if (definedArg is VarDefinition) {
        varDef = definedArg;
      } else if (definedArg is VarDefinitionDirective) {
        VarDefinitionDirective varDirective = definedArg;
        varDef = varDirective.def;
      }
      var callArg = callArgs[index];

      // Is callArg a var definition with multi-args (expressions > 1).
      var defArgs = _varDefsAsCallArgs(callArg);
      if (defArgs.isNotEmpty) {
        // Replace call args with the var def parameters.
        callArgs.insertAll(index, defArgs);
        callArgs.removeAt(index + defArgs.length);
        callArg = callArgs[index];
      }

      var expressions = varUsages[varDef.definedName];
      expressions.forEach((k, v) {
        for (var usagesIndex in v) {
          k.expressions.replaceRange(usagesIndex, usagesIndex + 1, callArg);
        }
      });
    }

    // Clone the mixin
    return mixinDef.clone();
  }

  /** Rip apart var def with multiple parameters. */
  List<List<TreeNode>> _varDefsAsCallArgs(var callArg) {
    var defArgs = [];
    if (callArg is List && callArg[0] is VarUsage) {
      var varDef = varDefs[callArg[0].name];
      var expressions = varDef.expression.expressions;
      assert(expressions.length > 1);
      for (var expr in expressions) {
        if (expr is! OperatorComma) {
          defArgs.add([expr]);
        }
      }
    }
    return defArgs;
  }

  void visitExpressions(Expressions node) {
    var oldExpressions = _currExpressions;
    var oldIndex = _currIndex;

    _currExpressions = node;
    for (_currIndex = 0; _currIndex < node.expressions.length; _currIndex++) {
      node.expressions[_currIndex].visit(this);
    }

    _currIndex = oldIndex;
    _currExpressions = oldExpressions;
  }

  void _addExpression(Map<Expressions, Set<int>> expressions) {
    var indexSet = new Set<int>();
    indexSet.add(_currIndex);
    expressions[_currExpressions] = indexSet;
  }

  void visitVarUsage(VarUsage node) {
    assert(_currIndex != -1);
    assert(_currExpressions != null);
    if (varUsages.containsKey(node.name)) {
      Map<Expressions, Set<int>> expressions = varUsages[node.name];
      Set<int> allIndexes = expressions[_currExpressions];
      if (allIndexes == null) {
        _addExpression(expressions);
      } else {
        allIndexes.add(_currIndex);
      }
    } else {
      var newExpressions = new Map<Expressions, Set<int>>();
      _addExpression(newExpressions);
      varUsages[node.name] = newExpressions;
    }
    super.visitVarUsage(node);
  }

  void visitMixinDeclarationDirective(MixinDeclarationDirective node) {
    _definedArgs = node.definedArgs;
    super.visitMixinDeclarationDirective(node);
  }

  void visitMixinRulesetDirective(MixinRulesetDirective node) {
    _definedArgs = node.definedArgs;
    super.visitMixinRulesetDirective(node);
  }
}

/** Expand all @include inside of a declaration associated with a mixin. */
class DeclarationIncludes extends Visitor {
  StyleSheet _styleSheet;
  final Messages _messages;
  /** Map of variable name key to it's definition. */
  final Map<String, MixinDefinition> map = new Map<String, MixinDefinition>();
  /** Cache of mixin called with parameters. */
  final Map<String, CallMixin> callMap = new Map<String, CallMixin>();
  MixinDefinition currDef;
  DeclarationGroup currDeclGroup;

  /** Var definitions with more than 1 expression. */
  final Map<String, VarDefinition> varDefs = new Map<String, VarDefinition>();

  static void expand(Messages messages, List<StyleSheet> styleSheets) {
    new DeclarationIncludes(messages, styleSheets);
  }

  DeclarationIncludes(this._messages, List<StyleSheet> styleSheets) {
    for (var styleSheet in styleSheets) {
      visitTree(styleSheet);
    }
  }

  bool _allIncludes(rulesets) =>
      rulesets.every((rule) => rule is IncludeDirective || rule is NoOp);

  CallMixin _createCallDeclMixin(MixinDefinition mixinDef) {
    callMap.putIfAbsent(mixinDef.name, () =>
        callMap[mixinDef.name] = new CallMixin(mixinDef, varDefs));
    return callMap[mixinDef.name];
  }

  void visitStyleSheet(StyleSheet ss) {
    _styleSheet = ss;
    super.visitStyleSheet(ss);
    _styleSheet = null;
  }

  void visitDeclarationGroup(DeclarationGroup node) {
    currDeclGroup = node;
    super.visitDeclarationGroup(node);
    currDeclGroup = null;
  }

  void visitIncludeMixinAtDeclaration(IncludeMixinAtDeclaration node) {
    if (map.containsKey(node.include.name)) {
      var mixinDef = map[node.include.name];

      // Fix up any mixin that is really a Declaration but has includes.
      if (mixinDef is MixinRulesetDirective) {
        if (!_allIncludes(mixinDef.rulesets) && currDeclGroup != null) {
          var index = _findInclude(currDeclGroup.declarations, node);
          if (index != -1) {
            currDeclGroup.declarations.replaceRange(index, index + 1,
                [new NoOp()]);
          }
          _messages.warning(
              "Using top-level mixin ${node.include.name} as a declaration",
              node.span);
        } else {
          // We're a list of @include(s) inside of a mixin ruleset - convert
          // to a list of IncludeMixinAtDeclaration(s).
          var origRulesets = mixinDef.rulesets;
          var rulesets = [];
          if (origRulesets.every((ruleset) => ruleset is IncludeDirective)) {
            origRulesets.forEach((ruleset) {
              rulesets.add(new IncludeMixinAtDeclaration(ruleset,
                  ruleset.span));
            });
            _IncludeReplacer.replace(_styleSheet, node, rulesets);
          }
        }
      }

      if ( mixinDef.definedArgs.length > 0 && node.include.args.length > 0) {
        var callMixin = _createCallDeclMixin(mixinDef);
        mixinDef = callMixin.transform(node.include.args);
      }

      if (mixinDef is MixinDeclarationDirective) {
        _IncludeReplacer.replace(_styleSheet, node,
            mixinDef.declarations.declarations);
      }
    } else {
      _messages.warning("Undefined mixin ${node.include.name}", node.span);
    }

    super.visitIncludeMixinAtDeclaration(node);
  }

  void visitIncludeDirective(IncludeDirective node) {
    if (map.containsKey(node.name)) {
      var mixinDef = map[node.name];
      if (currDef is MixinDeclarationDirective &&
          mixinDef is MixinDeclarationDirective) {
        _IncludeReplacer.replace(_styleSheet, node,
            mixinDef.declarations.declarations);
      } else if (currDef is MixinDeclarationDirective) {
        var decls = (currDef as MixinDeclarationDirective)
            .declarations.declarations;
        var index = _findInclude(decls, node);
        if (index != -1) {
          decls.replaceRange(index, index + 1, [new NoOp()]);
        }
      }
    }

    super.visitIncludeDirective(node);
  }

  void visitMixinRulesetDirective(MixinRulesetDirective node) {
    currDef = node;

    super.visitMixinRulesetDirective(node);

    // Replace with latest top-level mixin definition.
    map[node.name] = node;
    currDef = null;
  }

  void visitMixinDeclarationDirective(MixinDeclarationDirective node) {
    currDef = node;

    super.visitMixinDeclarationDirective(node);

    // Replace with latest mixin definition.
    map[node.name] = node;
    currDef = null;
  }

  void visitVarDefinition(VarDefinition node) {
    // Only record var definitions that have multiple expressions (comma
    // separated for mixin parameter substitution.
    var exprs = (node.expression as Expressions).expressions;
    if (exprs.length > 1) {
      varDefs[node.definedName] = node;
    }
    super.visitVarDefinition(node);
 }

  void visitVarDefinitionDirective(VarDefinitionDirective node) {
    visitVarDefinition(node.def);
  }
}

/** @include as a top-level with ruleset(s). */
class _IncludeReplacer extends Visitor {
  final _include;
  final List<Declaration> _newDeclarations;
  bool _foundAndReplaced = false;

  /**
   * Look for the [ruleSet] inside of a @media directive; if found then replace
   * with the [newRules].
   */
  static void replace(StyleSheet ss, var include,
      List<Declaration> newDeclarations) {
    var visitor = new _IncludeReplacer(include, newDeclarations);
    visitor.visitStyleSheet(ss);
  }

  _IncludeReplacer(this._include, this._newDeclarations);

  void visitDeclarationGroup(DeclarationGroup node) {
    var index = _findInclude(node.declarations, _include);
    if (index != -1) {
      node.declarations.insertAll(index + 1, _newDeclarations);
      // Change @include to NoOp so it's processed only once.
      node.declarations.replaceRange(index, index + 1, [new NoOp()]);
      _foundAndReplaced = true;
    }
    super.visitDeclarationGroup(node);
  }
}

/**
 * Remove all @mixin and @include and any NoOp used as placeholder for @include.
 */
class MixinsAndIncludes extends Visitor {
  static void remove(StyleSheet styleSheet) {
    new MixinsAndIncludes()..visitStyleSheet(styleSheet);
  }

  bool _nodesToRemove(node) =>
      node is IncludeDirective || node is MixinDefinition || node is NoOp;

  void visitStyleSheet(StyleSheet ss) {
    var index = ss.topLevels.length;
    while (--index >= 0) {
      if (_nodesToRemove(ss.topLevels[index])) {
        ss.topLevels.removeAt(index);
      }
    }
    super.visitStyleSheet(ss);
  }

  void visitDeclarationGroup(DeclarationGroup node) {
    var index = node.declarations.length;
    while (--index >= 0) {
      if (_nodesToRemove(node.declarations[index])) {
        node.declarations.removeAt(index);
      }
    }
    super.visitDeclarationGroup(node);
  }
}

/** Find all @extend to create inheritance. */
class AllExtends extends Visitor {
  final Map<String, List<SelectorGroup>> inherits =
      new Map<String, List<SelectorGroup>>();

  SelectorGroup _currSelectorGroup;
  List _currDecls;
  int _currDeclIndex;
  List<int> _extendsToRemove = [];

  void visitRuleSet(RuleSet node) {
    var oldSelectorGroup = _currSelectorGroup;
    _currSelectorGroup = node.selectorGroup;

    super.visitRuleSet(node);

    _currSelectorGroup = oldSelectorGroup;
  }

  void visitExtendDeclaration(ExtendDeclaration node) {
    var inheritName = "";
    for (var selector in node.selectors) {
      inheritName += selector.toString();
    }
    if (inherits.containsKey(inheritName)) {
      inherits[inheritName].add(_currSelectorGroup);
    } else {
      inherits[inheritName] = [_currSelectorGroup];
    }

    // Remove this @extend
    _extendsToRemove.add(_currDeclIndex);

    super.visitExtendDeclaration(node);
  }

  void visitDeclarationGroup(DeclarationGroup node) {
    var oldDeclIndex = _currDeclIndex;

    var decls = node.declarations;
    for (_currDeclIndex = 0; _currDeclIndex < decls.length; _currDeclIndex++) {
      decls[_currDeclIndex].visit(this);
    }

    if (_extendsToRemove.isNotEmpty) {
      var removeTotal = _extendsToRemove.length - 1;
      for (var index = removeTotal; index >= 0; index--) {
        decls.removeAt(_extendsToRemove[index]);
      }
      _extendsToRemove.clear();
    }

    _currDeclIndex = oldDeclIndex;
  }
}

// TODO(terry): Need to handle merging selector sequences
// TODO(terry): Need to handle @extend-Only selectors.
// TODO(terry): Need to handle !optional glag.
/**
 * Changes any selector that matches @extend.
 */
class InheritExtends extends Visitor {
  final Messages _messages;
  final AllExtends _allExtends;

  InheritExtends(this._messages, this._allExtends);

  void visitSelectorGroup(SelectorGroup node) {
    for (var selectorsIndex = 0; selectorsIndex < node.selectors.length;
        selectorsIndex++) {
      var selectors = node.selectors[selectorsIndex];
      var isLastNone = false;
      var selectorName = "";
      for (var index = 0; index < selectors.simpleSelectorSequences.length;
          index++) {
        var simpleSeq = selectors.simpleSelectorSequences[index];
        var namePart = simpleSeq.simpleSelector.toString();
        selectorName = (isLastNone) ? (selectorName + namePart) : namePart;
        List<SelectorGroup> matches = _allExtends.inherits[selectorName];
        if (matches != null) {
          for (var match in matches) {
            // Create a new group.
            var newSelectors = selectors.clone();
            var newSeq = match.selectors[0].clone();
            if (isLastNone) {
              // Add the inherited selector.
              node.selectors.add(newSeq);
            } else {
              // Replace the selector sequence to the left of the pseudo class
              // or pseudo element.

              // Make new selector seq combinator the same as the original.
              var orgCombinator =
                  newSelectors.simpleSelectorSequences[index].combinator;
              newSeq.simpleSelectorSequences[0].combinator = orgCombinator;

              newSelectors.simpleSelectorSequences.replaceRange(index,
                  index + 1, newSeq.simpleSelectorSequences);
              node.selectors.add(newSelectors);
            }
            isLastNone = false;
          }
        } else {
          isLastNone = simpleSeq.isCombinatorNone;
        }
      }
    }
    super.visitSelectorGroup(node);
  }
}
