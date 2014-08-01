// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library csslib.visitor;

import 'package:source_span/source_span.dart';
import 'parser.dart';

part 'src/css_printer.dart';
part 'src/tree.dart';
part 'src/tree_base.dart';
part 'src/tree_printer.dart';

abstract class VisitorBase {
  void visitCssComment(CssComment node);
  void visitCommentDefinition(CommentDefinition node);
  void visitStyleSheet(StyleSheet node);
  void visitNoOp(NoOp node);
  void visitTopLevelProduction(TopLevelProduction node);
  void visitDirective(Directive node);
  void visitMediaExpression(MediaExpression node);
  void visitMediaQuery(MediaQuery node);
  void visitMediaDirective(MediaDirective node);
  void visitHostDirective(HostDirective node);
  void visitPageDirective(PageDirective node);
  void visitCharsetDirective(CharsetDirective node);
  void visitImportDirective(ImportDirective node);
  void visitKeyFrameDirective(KeyFrameDirective node);
  void visitKeyFrameBlock(KeyFrameBlock node);
  void visitFontFaceDirective(FontFaceDirective node);
  void visitStyletDirective(StyletDirective node);
  void visitNamespaceDirective(NamespaceDirective node);
  void visitVarDefinitionDirective(VarDefinitionDirective node);
  void visitMixinDefinition(MixinDefinition node);
  void visitMixinRulesetDirective(MixinRulesetDirective node);
  void visitMixinDeclarationDirective(MixinDeclarationDirective node);
  void visitIncludeDirective(IncludeDirective node);
  void visitContentDirective(ContentDirective node);

  void visitRuleSet(RuleSet node);
  void visitDeclarationGroup(DeclarationGroup node);
  void visitMarginGroup(DeclarationGroup node);
  void visitDeclaration(Declaration node);
  void visitVarDefinition(VarDefinition node);
  void visitIncludeMixinAtDeclaration(IncludeMixinAtDeclaration node);
  void visitExtendDeclaration(ExtendDeclaration node);
  void visitSelectorGroup(SelectorGroup node);
  void visitSelector(Selector node);
  void visitSimpleSelectorSequence(SimpleSelectorSequence node);
  void visitSimpleSelector(SimpleSelector node);
  void visitElementSelector(ElementSelector node);
  void visitNamespaceSelector(NamespaceSelector node);
  void visitAttributeSelector(AttributeSelector node);
  void visitIdSelector(IdSelector node);
  void visitClassSelector(ClassSelector node);
  void visitPseudoClassSelector(PseudoClassSelector node);
  void visitPseudoElementSelector(PseudoElementSelector node);
  void visitPseudoClassFunctionSelector(PseudoClassFunctionSelector node);
  void visitPseudoElementFunctionSelector(PseudoElementFunctionSelector node);
  void visitNegationSelector(NegationSelector node);
  void visitSelectorExpression(SelectorExpression node);

  void visitUnicodeRangeTerm(UnicodeRangeTerm node);
  void visitLiteralTerm(LiteralTerm node);
  void visitHexColorTerm(HexColorTerm node);
  void visitNumberTerm(NumberTerm node);
  void visitUnitTerm(UnitTerm node);
  void visitLengthTerm(LengthTerm node);
  void visitPercentageTerm(PercentageTerm node);
  void visitEmTerm(EmTerm node);
  void visitExTerm(ExTerm node);
  void visitAngleTerm(AngleTerm node);
  void visitTimeTerm(TimeTerm node);
  void visitFreqTerm(FreqTerm node);
  void visitFractionTerm(FractionTerm node);
  void visitUriTerm(UriTerm node);
  void visitResolutionTerm(ResolutionTerm node);
  void visitChTerm(ChTerm node);
  void visitRemTerm(RemTerm node);
  void visitViewportTerm(ViewportTerm node);
  void visitFunctionTerm(FunctionTerm node);
  void visitGroupTerm(GroupTerm node);
  void visitItemTerm(ItemTerm node);
  void visitIE8Term(IE8Term node);
  void visitOperatorSlash(OperatorSlash node);
  void visitOperatorComma(OperatorComma node);
  void visitOperatorPlus(OperatorPlus node);
  void visitOperatorMinus(OperatorMinus node);
  void visitVarUsage(VarUsage node);

  void visitExpressions(Expressions node);
  void visitBinaryExpression(BinaryExpression node);
  void visitUnaryExpression(UnaryExpression node);

  void visitIdentifier(Identifier node);
  void visitWildcard(Wildcard node);
  void visitThisOperator(ThisOperator node);
  void visitNegation(Negation node);

  void visitDartStyleExpression(DartStyleExpression node);
  void visitFontExpression(FontExpression node);
  void visitBoxExpression(BoxExpression node);
  void visitMarginExpression(MarginExpression node);
  void visitBorderExpression(BorderExpression node);
  void visitHeightExpression(HeightExpression node);
  void visitPaddingExpression(PaddingExpression node);
  void visitWidthExpression(WidthExpression node);
}

/** Base vistor class for the style sheet AST. */
class Visitor implements VisitorBase {
  /** Helper function to walk a list of nodes. */
  void _visitNodeList(List<TreeNode> list) {
    // Don't use iterable otherwise the list can't grow while using Visitor.
    // It certainly can't have items deleted before the index being iterated
    // but items could be added after the index.
    for (var index = 0; index < list.length; index++) {
      list[index].visit(this);
    }
  }

  void visitTree(StyleSheet tree) => visitStyleSheet(tree);

  void visitStyleSheet(StyleSheet ss) {
    _visitNodeList(ss.topLevels);
  }

  void visitNoOp(NoOp node) { }

  void visitTopLevelProduction(TopLevelProduction node) { }

  void visitDirective(Directive node) { }

  void visitCssComment(CssComment node) { }

  void visitCommentDefinition(CommentDefinition node) { }

  void visitMediaExpression(MediaExpression node) {
    visitExpressions(node.exprs);
  }

  void visitMediaQuery(MediaQuery node) {
    for (var mediaExpr in node.expressions) {
      visitMediaExpression(mediaExpr);
    }
  }

  void visitMediaDirective(MediaDirective node) {
    for (var mediaQuery in node.mediaQueries) {
      visitMediaQuery(mediaQuery);
    }
    for (var ruleset in node.rulesets) {
      visitRuleSet(ruleset);
    }
  }

  void visitHostDirective(HostDirective node) {
    for (var ruleset in node.rulesets) {
      visitRuleSet(ruleset);
    }
  }

  void visitPageDirective(PageDirective node) {
    for (var declGroup in node._declsMargin) {
      if (declGroup is MarginGroup) {
        visitMarginGroup(declGroup);
      } else {
        visitDeclarationGroup(declGroup);
      }
    }
  }

  void visitCharsetDirective(CharsetDirective node) { }

  void visitImportDirective(ImportDirective node) {
    for (var mediaQuery in node.mediaQueries) {
      visitMediaQuery(mediaQuery);
    }
  }

  void visitKeyFrameDirective(KeyFrameDirective node) {
    visitIdentifier(node.name);
    _visitNodeList(node._blocks);
  }

  void visitKeyFrameBlock(KeyFrameBlock node) {
    visitExpressions(node._blockSelectors);
    visitDeclarationGroup(node._declarations);
  }

  void visitFontFaceDirective(FontFaceDirective node) {
    visitDeclarationGroup(node._declarations);
  }

  void visitStyletDirective(StyletDirective node) {
    _visitNodeList(node.rulesets);
  }

  void visitNamespaceDirective(NamespaceDirective node) { }

  void visitVarDefinitionDirective(VarDefinitionDirective node) {
    visitVarDefinition(node.def);
  }

  void visitMixinRulesetDirective(MixinRulesetDirective node) {
    _visitNodeList(node.rulesets);
  }

  void visitMixinDefinition(MixinDefinition node) { }

  void visitMixinDeclarationDirective(MixinDeclarationDirective node) {
    visitDeclarationGroup(node.declarations);
  }

  void visitIncludeDirective(IncludeDirective node) {
    for (var index = 0; index < node.args.length; index++) {
      var param = node.args[index];
      _visitNodeList(param);
    }
  }

  void visitContentDirective(ContentDirective node) {
    // TODO(terry): TBD
  }

  void visitRuleSet(RuleSet node) {
    visitSelectorGroup(node._selectorGroup);
    visitDeclarationGroup(node._declarationGroup);
  }

  void visitDeclarationGroup(DeclarationGroup node) {
    _visitNodeList(node.declarations);
  }

  void visitMarginGroup(MarginGroup node) => visitDeclarationGroup(node);

  void visitDeclaration(Declaration node) {
    visitIdentifier(node._property);
    if (node._expression != null) node._expression.visit(this);
  }

  void visitVarDefinition(VarDefinition node) {
    visitIdentifier(node._property);
    if (node._expression != null) node._expression.visit(this);
  }

  void visitIncludeMixinAtDeclaration(IncludeMixinAtDeclaration node) {
    visitIncludeDirective(node.include);
  }

  void visitExtendDeclaration(ExtendDeclaration node) {
    _visitNodeList(node.selectors);
  }

  void visitSelectorGroup(SelectorGroup node) {
    _visitNodeList(node.selectors);
  }

  void visitSelector(Selector node) {
    _visitNodeList(node.simpleSelectorSequences);
  }

  void visitSimpleSelectorSequence(SimpleSelectorSequence node) {
    node.simpleSelector.visit(this);
  }

  void visitSimpleSelector(SimpleSelector node) => node._name.visit(this);

  void visitNamespaceSelector(NamespaceSelector node) {
    if (node._namespace != null) node._namespace.visit(this);
    if (node.nameAsSimpleSelector != null) {
      node.nameAsSimpleSelector.visit(this);
    }
  }

  void visitElementSelector(ElementSelector node) => visitSimpleSelector(node);

  void visitAttributeSelector(AttributeSelector node) {
    visitSimpleSelector(node);
  }

  void visitIdSelector(IdSelector node) => visitSimpleSelector(node);

  void visitClassSelector(ClassSelector node) => visitSimpleSelector(node);

  void visitPseudoClassSelector(PseudoClassSelector node) =>
      visitSimpleSelector(node);

  void visitPseudoElementSelector(PseudoElementSelector node) =>
      visitSimpleSelector(node);

  void visitPseudoClassFunctionSelector(PseudoClassFunctionSelector node) =>
      visitSimpleSelector(node);

  void visitPseudoElementFunctionSelector(PseudoElementFunctionSelector node) =>
      visitSimpleSelector(node);

  void visitNegationSelector(NegationSelector node) =>
      visitSimpleSelector(node);

  void visitSelectorExpression(SelectorExpression node) {
    _visitNodeList(node.expressions);
  }

  void visitUnicodeRangeTerm(UnicodeRangeTerm node) { }

  void visitLiteralTerm(LiteralTerm node) { }

  void visitHexColorTerm(HexColorTerm node) { }

  void visitNumberTerm(NumberTerm node) { }

  void visitUnitTerm(UnitTerm node) { }

  void visitLengthTerm(LengthTerm node) {
    visitUnitTerm(node);
  }

  void visitPercentageTerm(PercentageTerm node) {
    visitLiteralTerm(node);
  }

  void visitEmTerm(EmTerm node) {
    visitLiteralTerm(node);
  }

  void visitExTerm(ExTerm node) {
    visitLiteralTerm(node);
  }

  void visitAngleTerm(AngleTerm node) {
    visitUnitTerm(node);
  }

  void visitTimeTerm(TimeTerm node) {
    visitUnitTerm(node);
  }

  void visitFreqTerm(FreqTerm node) {
    visitUnitTerm(node);
  }

  void visitFractionTerm(FractionTerm node) {
    visitLiteralTerm(node);
  }

  void visitUriTerm(UriTerm node) {
    visitLiteralTerm(node);
  }

  void visitResolutionTerm(ResolutionTerm node) {
    visitUnitTerm(node);
  }

  void visitChTerm(ChTerm node) {
    visitUnitTerm(node);
  }

  void visitRemTerm(RemTerm node) {
    visitUnitTerm(node);
  }

  void visitViewportTerm(ViewportTerm node) {
    visitUnitTerm(node);
  }

  void visitFunctionTerm(FunctionTerm node) {
    visitLiteralTerm(node);
    visitExpressions(node._params);
  }

  void visitGroupTerm(GroupTerm node) {
    for (var term in node._terms) {
      term.visit(this);
    }
  }

  void visitItemTerm(ItemTerm node) {
    visitNumberTerm(node);
  }

  void visitIE8Term(IE8Term node) { }

  void visitOperatorSlash(OperatorSlash node) { }

  void visitOperatorComma(OperatorComma node) { }

  void visitOperatorPlus(OperatorPlus node) { }

  void visitOperatorMinus(OperatorMinus node) { }

  void visitVarUsage(VarUsage node) {
    _visitNodeList(node.defaultValues);
  }

  void visitExpressions(Expressions node) {
    _visitNodeList(node.expressions);
  }

  void visitBinaryExpression(BinaryExpression node) {
    // TODO(terry): TBD
    throw UnimplementedError;
  }

  void visitUnaryExpression(UnaryExpression node) {
    // TODO(terry): TBD
    throw UnimplementedError;
  }

  void visitIdentifier(Identifier node) { }

  void visitWildcard(Wildcard node) { }

  void visitThisOperator(ThisOperator node) { }

  void visitNegation(Negation node) { }

  void visitDartStyleExpression(DartStyleExpression node) { }

  void visitFontExpression(FontExpression node) {
    // TODO(terry): TBD
    throw UnimplementedError;
  }

  void visitBoxExpression(BoxExpression node) {
    // TODO(terry): TBD
    throw UnimplementedError;
  }

  void visitMarginExpression(MarginExpression node) {
    // TODO(terry): TBD
    throw UnimplementedError;
  }

  void visitBorderExpression(BorderExpression node) {
    // TODO(terry): TBD
    throw UnimplementedError;
  }

  void visitHeightExpression(HeightExpression node) {
    // TODO(terry): TB
    throw UnimplementedError;
  }

  void visitPaddingExpression(PaddingExpression node) {
    // TODO(terry): TBD
    throw UnimplementedError;
  }

  void visitWidthExpression(WidthExpression node) {
    // TODO(terry): TBD
    throw UnimplementedError;
  }
}
