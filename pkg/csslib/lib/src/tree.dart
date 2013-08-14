// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of csslib.visitor;

/////////////////////////////////////////////////////////////////////////
// CSS specific types:
/////////////////////////////////////////////////////////////////////////

class Identifier extends TreeNode {
  String name;

  Identifier(this.name, Span span): super(span);

  visit(VisitorBase visitor) => visitor.visitIdentifier(this);

  String toString() => name;
}

class Wildcard extends TreeNode {
  Wildcard(Span span): super(span);
  visit(VisitorBase visitor) => visitor.visitWildcard(this);
}

class ThisOperator extends TreeNode {
  ThisOperator(Span span): super(span);
  visit(VisitorBase visitor) => visitor.visitThisOperator(this);
}

class Negation extends TreeNode {
  Negation(Span span): super(span);
  visit(VisitorBase visitor) => visitor.visitNegation(this);
}

// /*  ....   */
class CssComment extends TreeNode {
  final String comment;

  CssComment(this.comment, Span span): super(span);
  visit(VisitorBase visitor) => visitor.visitCssComment(this);
}

// CDO/CDC (Comment Definition Open <!-- and Comment Definition Close -->).
class CommentDefinition extends CssComment {
  CommentDefinition(String comment, Span span): super(comment, span);
  visit(VisitorBase visitor) => visitor.visitCommentDefinition(this);
}

class SelectorGroup extends TreeNode {
  List<Selector> _selectors;

  SelectorGroup(this._selectors, Span span): super(span);

  List<Selector> get selectors => _selectors;

  visit(VisitorBase visitor) => visitor.visitSelectorGroup(this);
}

class Selector extends TreeNode {
  final List<SimpleSelectorSequence> _simpleSelectorSequences;

  Selector(this._simpleSelectorSequences, Span span) : super(span);

  List<SimpleSelectorSequence> get simpleSelectorSequences =>
      _simpleSelectorSequences;

  add(SimpleSelectorSequence seq) => _simpleSelectorSequences.add(seq);

  int get length => _simpleSelectorSequences.length;

  visit(VisitorBase visitor) => visitor.visitSelector(this);
}

class SimpleSelectorSequence extends TreeNode {
  /** +, >, ~, NONE */
  final int _combinator;
  final SimpleSelector _selector;

  SimpleSelectorSequence(this._selector, Span span,
      [int combinator = TokenKind.COMBINATOR_NONE])
      : _combinator = combinator, super(span);

  get simpleSelector => _selector;

  bool get isCombinatorNone => _combinator == TokenKind.COMBINATOR_NONE;
  bool get isCombinatorPlus => _combinator == TokenKind.COMBINATOR_PLUS;
  bool get isCombinatorGreater => _combinator == TokenKind.COMBINATOR_GREATER;
  bool get isCombinatorTilde => _combinator == TokenKind.COMBINATOR_TILDE;
  bool get isCombinatorDescendant =>
      _combinator == TokenKind.COMBINATOR_DESCENDANT;

  String get _combinatorToString =>
      isCombinatorDescendant ? ' ' :
          isCombinatorPlus ? ' + ' :
              isCombinatorGreater ? ' > ' :
                  isCombinatorTilde ? ' ~ ' : '';

  visit(VisitorBase visitor) => visitor.visitSimpleSelectorSequence(this);
}

/* All other selectors (element, #id, .class, attribute, pseudo, negation,
 * namespace, *) are derived from this selector.
 */
class SimpleSelector extends TreeNode {
  final _name;

  SimpleSelector(this._name, Span span) : super(span);

  // Name can be an Identifier or WildCard we'll return either the name or '*'.
  String get name => isWildcard ? '*' : isThis ? '&' : _name.name;

  bool get isWildcard => _name is Wildcard;

  bool get isThis => _name is ThisOperator;

  visit(VisitorBase visitor) => visitor.visitSimpleSelector(this);
}

// element name
class ElementSelector extends SimpleSelector {
  ElementSelector(name, Span span) : super(name, span);
  visit(VisitorBase visitor) => visitor.visitElementSelector(this);
}

// namespace|element
class NamespaceSelector extends SimpleSelector {
  final _namespace;           // null, Wildcard or Identifier

  NamespaceSelector(this._namespace, var name, Span span) : super(name, span);

  String get namespace =>
      _namespace is Wildcard ? '*' : _namespace == null ? '' : _namespace.name;

  bool get isNamespaceWildcard => _namespace is Wildcard;

  SimpleSelector get nameAsSimpleSelector => _name;

  visit(VisitorBase visitor) => visitor.visitNamespaceSelector(this);
}

// [attr op value]
class AttributeSelector extends SimpleSelector {
  final int _op;
  final _value;

  AttributeSelector(Identifier name, this._op, this._value,
      Span span) : super(name, span);

  String matchOperator() {
    switch (_op) {
    case TokenKind.EQUALS:
      return '=';
    case TokenKind.INCLUDES:
      return '~=';
    case TokenKind.DASH_MATCH:
      return '|=';
    case TokenKind.PREFIX_MATCH:
      return '^=';
    case TokenKind.SUFFIX_MATCH:
      return '\$=';
    case TokenKind.SUBSTRING_MATCH:
      return '*=';
    case TokenKind.NO_MATCH:
      return '';
    }
  }

  // Return the TokenKind for operator used by visitAttributeSelector.
  String matchOperatorAsTokenString() {
    switch (_op) {
    case TokenKind.EQUALS:
      return 'EQUALS';
    case TokenKind.INCLUDES:
      return 'INCLUDES';
    case TokenKind.DASH_MATCH:
      return 'DASH_MATCH';
    case TokenKind.PREFIX_MATCH:
      return 'PREFIX_MATCH';
    case TokenKind.SUFFIX_MATCH:
      return 'SUFFIX_MATCH';
    case TokenKind.SUBSTRING_MATCH:
      return 'SUBSTRING_MATCH';
    }
  }

  String valueToString() {
    if (_value != null) {
      if (_value is Identifier) {
        return _value.name;
      } else {
        return '"${_value}"';
      }
    } else {
      return '';
    }
  }

  visit(VisitorBase visitor) => visitor.visitAttributeSelector(this);
}

// #id
class IdSelector extends SimpleSelector {
  IdSelector(Identifier name, Span span) : super(name, span);
  visit(VisitorBase visitor) => visitor.visitIdSelector(this);
}

// .class
class ClassSelector extends SimpleSelector {
  ClassSelector(Identifier name, Span span) : super(name, span);
  visit(VisitorBase visitor) => visitor.visitClassSelector(this);
}

// :pseudoClass
class PseudoClassSelector extends SimpleSelector {
  PseudoClassSelector(Identifier name, Span span) : super(name, span);
  visit(VisitorBase visitor) => visitor.visitPseudoClassSelector(this);
}

// ::pseudoElement
class PseudoElementSelector extends SimpleSelector {
  PseudoElementSelector(Identifier name, Span span) : super(name, span);
  visit(VisitorBase visitor) => visitor.visitPseudoElementSelector(this);
}

// :pseudoClassFunction(expression)
class PseudoClassFunctionSelector extends PseudoClassSelector {
  SelectorExpression expression;

  PseudoClassFunctionSelector(Identifier name, this.expression, Span span)
      : super(name, span);
  visit(VisitorBase visitor) => visitor.visitPseudoClassFunctionSelector(this);
}

// ::pseudoElementFunction(expression)
class PseudoElementFunctionSelector extends PseudoElementSelector {
  SelectorExpression expression;

  PseudoElementFunctionSelector(Identifier name, this.expression, Span span)
      : super(name, span);
  visit(VisitorBase visitor) =>
      visitor.visitPseudoElementFunctionSelector(this);
}

class SelectorExpression extends TreeNode {
  final List<Expression> _expressions = [];

  SelectorExpression(Span span): super(span);

  add(Expression expression) {
    _expressions.add(expression);
  }

  List<Expression> get expressions => _expressions;

  visit(VisitorBase visitor) => visitor.visitSelectorExpression(this);
}

// :NOT(negation_arg)
class NegationSelector extends SimpleSelector {
  SimpleSelector negationArg;

  NegationSelector(this.negationArg, Span span)
      : super(new Negation(span), span);

  visit(VisitorBase visitor) => visitor.visitNegationSelector(this);
}

class StyleSheet extends TreeNode {
  /**
   * Contains charset, ruleset, directives (media, page, etc.), and selectors.
   */
  final topLevels;

  StyleSheet(this.topLevels, Span span) : super(span) {
    for (final node in topLevels) {
      assert(node is TopLevelProduction || node is Directive);
    }
  }

  /** Selectors only in this tree. */
  StyleSheet.selector(this.topLevels, Span span) : super(span);

  visit(VisitorBase visitor) => visitor.visitStyleSheet(this);
}

class TopLevelProduction extends TreeNode {
  TopLevelProduction(Span span) : super(span);
  visit(VisitorBase visitor) => visitor.visitTopLevelProduction(this);
}

class RuleSet extends TopLevelProduction {
  final SelectorGroup _selectorGroup;
  final DeclarationGroup _declarationGroup;

  RuleSet(this._selectorGroup, this._declarationGroup, Span span) : super(span);

  SelectorGroup get selectorGroup => _selectorGroup;
  DeclarationGroup get declarationGroup => _declarationGroup;

  visit(VisitorBase visitor) => visitor.visitRuleSet(this);
}

class Directive extends TreeNode {
  Directive(Span span) : super(span);

  bool get isBuiltIn => true;       // Known CSS directive?
  bool get isExtension => false;    // SCSS extension?

  visit(VisitorBase visitor) => visitor.visitDirective(this);
}

class ImportDirective extends Directive {
  /** import name specified. */
  final String import;

  /** Any media queries for this import. */
  final List<MediaQuery> mediaQueries;

  ImportDirective(this.import, this.mediaQueries, Span span) : super(span);

  visit(VisitorBase visitor) => visitor.visitImportDirective(this);
}

/**
 *  MediaExpression grammar:
 *    '(' S* media_feature S* [ ':' S* expr ]? ')' S*
 */
class MediaExpression extends TreeNode {
  final bool andOperator;
  final Identifier _mediaFeature;
  final Expressions exprs;

  MediaExpression(this.andOperator, this._mediaFeature, this.exprs, Span span)
      : super(span);

  String get mediaFeature => _mediaFeature.name;

  visit(VisitorBase visitor) => visitor.visitMediaExpression(this);
}

/**
 * MediaQuery grammar:
 *    : [ONLY | NOT]? S* media_type S* [ AND S* media_expression ]*
 *    | media_expression [ AND S* media_expression ]*
 *   media_type
 *    : IDENT
 *   media_expression
 *    : '(' S* media_feature S* [ ':' S* expr ]? ')' S*
 *   media_feature
 *    : IDENT
 */
class MediaQuery extends TreeNode {
  /** not, only or no operator. */
  final int _mediaUnary;
  final Identifier _mediaType;
  final List<MediaExpression> expressions;

  MediaQuery(this._mediaUnary, this._mediaType, this.expressions, Span span)
      : super(span);

  bool get hasMediaType => _mediaType != null;
  String get mediaType => _mediaType.name;

  bool get hasUnary => _mediaUnary != -1;
  String get unary =>
      TokenKind.idToValue(TokenKind.MEDIA_OPERATORS, _mediaUnary).toUpperCase();

  visit(VisitorBase visitor) => visitor.visitMediaQuery(this);
}

class MediaDirective extends Directive {
  List<MediaQuery> mediaQueries;
  List<RuleSet> rulesets;

  MediaDirective(this.mediaQueries, this.rulesets, Span span) : super(span);

  visit(VisitorBase visitor) => visitor.visitMediaDirective(this);
}

class HostDirective extends Directive {
  List<RuleSet> rulesets;

  HostDirective(this.rulesets, Span span) : super(span);

  visit(VisitorBase visitor) => visitor.visitHostDirective(this);
}

class PageDirective extends Directive {
  final String _ident;
  final String _pseudoPage;
  List<DeclarationGroup> _declsMargin;

  PageDirective(this._ident, this._pseudoPage, this._declsMargin,
      Span span) : super(span);

  visit(VisitorBase visitor) => visitor.visitPageDirective(this);

  bool get hasIdent => _ident != null && _ident.length > 0;
  bool get hasPseudoPage => _pseudoPage != null && _pseudoPage.length > 0;
}

class CharsetDirective extends Directive {
  final String charEncoding;

  CharsetDirective(this.charEncoding, Span span) : super(span);
  visit(VisitorBase visitor) => visitor.visitCharsetDirective(this);
}

class KeyFrameDirective extends Directive {
  /*
   * Either @keyframe or keyframe prefixed with @-webkit-, @-moz-, @-ms-, @-o-.
   */
  final int _keyframeName;
  final _name;
  final List<KeyFrameBlock> _blocks;

  KeyFrameDirective(this._keyframeName, this._name, Span span)
      : _blocks = [], super(span);

  add(KeyFrameBlock block) {
    _blocks.add(block);
  }

  String get keyFrameName {
    switch (_keyframeName) {
      case TokenKind.DIRECTIVE_KEYFRAMES:
      case TokenKind.DIRECTIVE_MS_KEYFRAMES:
        return '@keyframes';
      case TokenKind.DIRECTIVE_WEB_KIT_KEYFRAMES: return '@-webkit-keyframes';
      case TokenKind.DIRECTIVE_MOZ_KEYFRAMES: return '@-moz-keyframes';
      case TokenKind.DIRECTIVE_O_KEYFRAMES: return '@-o-keyframes';
    }
  }

  String get name => _name;

  visit(VisitorBase visitor) => visitor.visitKeyFrameDirective(this);
}

class KeyFrameBlock extends Expression {
  final Expressions _blockSelectors;
  final DeclarationGroup _declarations;

  KeyFrameBlock(this._blockSelectors, this._declarations, Span span)
      : super(span);

  visit(VisitorBase visitor) => visitor.visitKeyFrameBlock(this);
}

class FontFaceDirective extends Directive {
  final DeclarationGroup _declarations;

  FontFaceDirective(this._declarations, Span span) : super(span);

  visit(VisitorBase visitor) => visitor.visitFontFaceDirective(this);
}

class StyletDirective extends Directive {
  final String _dartClassName;
  final List<RuleSet> _rulesets;

  StyletDirective(this._dartClassName, this._rulesets, Span span) : super(span);

  bool get isBuiltIn => false;
  bool get isExtension => true;

  String get dartClassName => _dartClassName;
  List<RuleSet> get rulesets => _rulesets;

  visit(VisitorBase visitor) => visitor.visitStyletDirective(this);
}

class NamespaceDirective extends Directive {
  /** Namespace prefix. */
  final String _prefix;

  /** URI associated with this namespace. */
  final String _uri;

  NamespaceDirective(this._prefix, this._uri, Span span) : super(span);

  visit(VisitorBase visitor) => visitor.visitNamespaceDirective(this);

  String get prefix => _prefix.length > 0 ? '$_prefix ' : '';
}

/** To support Less syntax @name: expression */
class VarDefinitionDirective extends Directive {
  final VarDefinition def;

  VarDefinitionDirective(this.def, Span span) : super(span);

  visit(VisitorBase visitor) => visitor.visitVarDefinitionDirective(this);
}

class Declaration extends TreeNode {
  final Identifier _property;
  final Expression _expression;
  /** Style exposed to Dart. */
  var _dart;
  final bool important;

  /**
   * IE CSS hacks that can only be read by a particular IE version.
   *   7 implies IE 7 or older property (e.g., *background: blue;)
   *   Note:  IE 8 or older property (e.g., background: green\9;) is handled
   *          by IE8Term in declaration expression handling.
   *   Note:  IE 6 only property with a leading underscore is a valid IDENT
   *          since an ident can start with underscore (e.g., _background: red;)
   */
  final bool isIE7;

  Declaration(this._property, this._expression, this._dart, Span span,
              {important: false, ie7: false})
      : this.important = important, this.isIE7 = ie7, super(span);

  String get property => isIE7 ? '*${_property.name}' : _property.name;
  Expression get expression => _expression;

  bool get hasDartStyle => _dart != null;
  get dartStyle => _dart;
  set dartStyle(dStyle) {
    _dart = dStyle;
  }

  visit(VisitorBase visitor) => visitor.visitDeclaration(this);
}

// TODO(terry): Consider 2 kinds of VarDefinitions static at top-level and
//              dynamic when in a declaration.  Currently, Less syntax
//              '@foo: expression' and 'var-foo: expression' in a declaration
//              are statically resolved. Better solution, if @foo or var-foo
//              are top-level are then statically resolved and var-foo in a
//              declaration group (surrounded by a selector) would be dynamic.
class VarDefinition extends Declaration {
  VarDefinition(Identifier definedName, Expression expr, Span span)
      : super(definedName, expr, null, span);

  String get definedName => _property.name;

  set dartStyle(dStyle) { }

  visit(VisitorBase visitor) => visitor.visitVarDefinition(this);
}

class DeclarationGroup extends TreeNode {
  /** Can be either Declaration or RuleSet (if nested selector). */
  final List _declarations;

  DeclarationGroup(this._declarations, Span span) : super(span);

  List get declarations => _declarations;

  visit(VisitorBase visitor) => visitor.visitDeclarationGroup(this);
}

class MarginGroup extends DeclarationGroup {
  final int margin_sym;       // TokenType for for @margin sym.

  MarginGroup(this.margin_sym, List<Declaration> decls, Span span)
      : super(decls, span);
  visit(VisitorBase visitor) => visitor.visitMarginGroup(this);
}

class VarUsage extends Expression {
  final String name;
  final List<Expression> defaultValues;

  VarUsage(this.name, this.defaultValues, Span span) : super(span);

  visit(VisitorBase visitor) => visitor.visitVarUsage(this);
}

class OperatorSlash extends Expression {
  OperatorSlash(Span span) : super(span);
  visit(VisitorBase visitor) => visitor.visitOperatorSlash(this);
}

class OperatorComma extends Expression {
  OperatorComma(Span span) : super(span);
  visit(VisitorBase visitor) => visitor.visitOperatorComma(this);
}

class OperatorPlus extends Expression {
  OperatorPlus(Span span) : super(span);
  visit(VisitorBase visitor) => visitor.visitOperatorPlus(this);
}

class OperatorMinus extends Expression {
  OperatorMinus(Span span) : super(span);
  visit(VisitorBase visitor) => visitor.visitOperatorMinus(this);
}

class UnicodeRangeTerm extends Expression {
  final String first;
  final String second;

  UnicodeRangeTerm(this.first, this.second, Span span) : super(span);

  bool get hasSecond => second != null;

  visit(VisitorBase visitor) => visitor.visitUnicodeRangeTerm(this);
}

class LiteralTerm extends Expression {
  // TODO(terry): value and text fields can be made final once all CSS resources
  //              are copied/symlink'd in the build tool and UriVisitor in
  //              web_ui is removed.
  var value;
  String text;

  LiteralTerm(this.value, this.text, Span span) : super(span);

  visit(VisitorBase visitor) => visitor.visitLiteralTerm(this);
}

class NumberTerm extends LiteralTerm {
  NumberTerm(value, String t, Span span) : super(value, t, span);
  visit(VisitorBase visitor) => visitor.visitNumberTerm(this);
}

class UnitTerm extends LiteralTerm {
  final int _unit;

  UnitTerm(value, String t, Span span, this._unit) : super(value, t, span);

  int get unit => _unit;

  visit(VisitorBase visitor) => visitor.visitUnitTerm(this);

  String unitToString() => TokenKind.unitToString(_unit);

  String toString() => '$text${unitToString()}';
}

class LengthTerm extends UnitTerm {
  LengthTerm(value, String t, Span span,
      [int unit = TokenKind.UNIT_LENGTH_PX]) : super(value, t, span, unit) {
    assert(this._unit == TokenKind.UNIT_LENGTH_PX ||
        this._unit == TokenKind.UNIT_LENGTH_CM ||
        this._unit == TokenKind.UNIT_LENGTH_MM ||
        this._unit == TokenKind.UNIT_LENGTH_IN ||
        this._unit == TokenKind.UNIT_LENGTH_PT ||
        this._unit == TokenKind.UNIT_LENGTH_PC);
  }

  visit(VisitorBase visitor) => visitor.visitLengthTerm(this);
}

class PercentageTerm extends LiteralTerm {
  PercentageTerm(value, String t, Span span) : super(value, t, span);
  visit(VisitorBase visitor) => visitor.visitPercentageTerm(this);
}

class EmTerm extends LiteralTerm {
  EmTerm(value, String t, Span span) : super(value, t, span);
  visit(VisitorBase visitor) => visitor.visitEmTerm(this);
}

class ExTerm extends LiteralTerm {
  ExTerm(value, String t, Span span) : super(value, t, span);
  visit(VisitorBase visitor) => visitor.visitExTerm(this);
}

class AngleTerm extends UnitTerm {
  AngleTerm(var value, String t, Span span,
    [int unit = TokenKind.UNIT_LENGTH_PX]) : super(value, t, span, unit) {
    assert(this._unit == TokenKind.UNIT_ANGLE_DEG ||
        this._unit == TokenKind.UNIT_ANGLE_RAD ||
        this._unit == TokenKind.UNIT_ANGLE_GRAD ||
        this._unit == TokenKind.UNIT_ANGLE_TURN);
  }

  visit(VisitorBase visitor) => visitor.visitAngleTerm(this);
}

class TimeTerm extends UnitTerm {
  TimeTerm(var value, String t, Span span,
    [int unit = TokenKind.UNIT_LENGTH_PX]) : super(value, t, span, unit) {
    assert(this._unit == TokenKind.UNIT_ANGLE_DEG ||
        this._unit == TokenKind.UNIT_TIME_MS ||
        this._unit == TokenKind.UNIT_TIME_S);
  }

  visit(VisitorBase visitor) => visitor.visitTimeTerm(this);
}

class FreqTerm extends UnitTerm {
  FreqTerm(var value, String t, Span span,
    [int unit = TokenKind.UNIT_LENGTH_PX]) : super(value, t, span, unit) {
    assert(_unit == TokenKind.UNIT_FREQ_HZ || _unit == TokenKind.UNIT_FREQ_KHZ);
  }

  visit(VisitorBase visitor) => visitor.visitFreqTerm(this);
}

class FractionTerm extends LiteralTerm {
  FractionTerm(var value, String t, Span span) : super(value, t, span);

  visit(VisitorBase visitor) => visitor.visitFractionTerm(this);
}

class UriTerm extends LiteralTerm {
  UriTerm(String value, Span span) : super(value, value, span);

  visit(VisitorBase visitor) => visitor.visitUriTerm(this);
}

class ResolutionTerm extends UnitTerm {
  ResolutionTerm(var value, String t, Span span,
    [int unit = TokenKind.UNIT_LENGTH_PX]) : super(value, t, span, unit) {
    assert(_unit == TokenKind.UNIT_RESOLUTION_DPI ||
        _unit == TokenKind.UNIT_RESOLUTION_DPCM ||
        _unit == TokenKind.UNIT_RESOLUTION_DPPX);
  }

  visit(VisitorBase visitor) => visitor.visitResolutionTerm(this);
}

class ChTerm extends UnitTerm {
  ChTerm(var value, String t, Span span,
    [int unit = TokenKind.UNIT_LENGTH_PX]) : super(value, t, span, unit) {
    assert(_unit == TokenKind.UNIT_CH);
  }

  visit(VisitorBase visitor) => visitor.visitChTerm(this);
}

class RemTerm extends UnitTerm {
  RemTerm(var value, String t, Span span,
    [int unit = TokenKind.UNIT_LENGTH_PX]) : super(value, t, span, unit) {
    assert(_unit == TokenKind.UNIT_REM);
  }

  visit(VisitorBase visitor) => visitor.visitRemTerm(this);
}

class ViewportTerm extends UnitTerm {
  ViewportTerm(var value, String t, Span span,
    [int unit = TokenKind.UNIT_LENGTH_PX]) : super(value, t, span, unit) {
    assert(_unit == TokenKind.UNIT_VIEWPORT_VW ||
        _unit == TokenKind.UNIT_VIEWPORT_VH ||
        _unit == TokenKind.UNIT_VIEWPORT_VMIN ||
        _unit == TokenKind.UNIT_VIEWPORT_VMAX);
  }

  visit(VisitorBase visitor) => visitor.visitViewportTerm(this);
}

/** Type to signal a bad hex value for HexColorTerm.value. */
class BAD_HEX_VALUE { }

class HexColorTerm extends LiteralTerm {
  HexColorTerm(var value, String t, Span span) : super(value, t, span);

  visit(VisitorBase visitor) => visitor.visitHexColorTerm(this);
}

class FunctionTerm extends LiteralTerm {
  final Expressions _params;

  FunctionTerm(var value, String t, this._params, Span span)
      : super(value, t, span);

  visit(VisitorBase visitor) => visitor.visitFunctionTerm(this);
}

/**
 * A "\9" was encountered at the end of the expression and before a semi-colon.
 * This is an IE trick to ignore a property or value except by IE 8 and older
 * browsers.
 */
class IE8Term extends LiteralTerm {
  IE8Term(Span span) : super('\\9', '\\9', span);
  visit(VisitorBase visitor) => visitor.visitIE8Term(this);
}

class GroupTerm extends Expression {
  final List<LiteralTerm> _terms;

  GroupTerm(Span span) : _terms =  [], super(span);

  add(LiteralTerm term) {
    _terms.add(term);
  }

  visit(VisitorBase visitor) => visitor.visitGroupTerm(this);
}

class ItemTerm extends NumberTerm {
  ItemTerm(var value, String t, Span span) : super(value, t, span);

  visit(VisitorBase visitor) => visitor.visitItemTerm(this);
}

class Expressions extends Expression {
  final List<Expression> expressions = [];

  Expressions(Span span): super(span);

  add(Expression expression) {
    expressions.add(expression);
  }

  visit(VisitorBase visitor) => visitor.visitExpressions(this);
}

class BinaryExpression extends Expression {
  final Token op;
  final Expression x;
  final Expression y;

  BinaryExpression(this.op, this.x, this.y, Span span): super(span);

  visit(VisitorBase visitor) => visitor.visitBinaryExpression(this);
}

class UnaryExpression extends Expression {
  final Token op;
  final Expression self;

  UnaryExpression(this.op, this.self, Span span): super(span);

  visit(VisitorBase visitor) => visitor.visitUnaryExpression(this);
}

abstract class DartStyleExpression extends TreeNode {
  static final int unknownType = 0;
  static final int fontStyle = 1;
  static final int marginStyle = 2;
  static final int borderStyle = 3;
  static final int paddingStyle = 4;
  static final int heightStyle = 5;
  static final int widthStyle = 6;

  final int _styleType;
  int priority;

  DartStyleExpression(this._styleType, Span span) : super(span);

  /*
   * Merges give 2 DartStyleExpression (or derived from DartStyleExpression,
   * e.g., FontExpression, etc.) will merge if the two expressions are of the
   * same property name (implies same exact type e.g, FontExpression).
   */
  merged(DartStyleExpression newDartExpr);

  bool get isUnknown => _styleType == 0 || _styleType == null;
  bool get isFont => _styleType == fontStyle;
  bool get isMargin => _styleType == marginStyle;
  bool get isBorder => _styleType == borderStyle;
  bool get isPadding => _styleType == paddingStyle;
  bool get isHeight => _styleType == heightStyle;
  bool get isWidth => _styleType == widthStyle;
  bool get isBoxExpression => isMargin || isBorder || isPadding;

  bool isSame(DartStyleExpression other) => this._styleType == other._styleType;

  visit(VisitorBase visitor) => visitor.visitDartStyleExpression(this);
}

class FontExpression extends DartStyleExpression {
  Font font;

  //   font-style font-variant font-weight font-size/line-height font-family
  FontExpression(Span span, {var size, List<String>family,
      int weight, String style, String variant, LineHeight lineHeight})
      : super(DartStyleExpression.fontStyle, span) {
    // TODO(terry): Only px/pt for now need to handle all possible units to
    //              support calc expressions on units.
    font = new Font(size : size is LengthTerm ? size.value : size,
        family: family, weight: weight, style: style, variant: variant,
        lineHeight: lineHeight);
  }

  merged(FontExpression newFontExpr) {
    if (this.isFont && newFontExpr.isFont) {
      return new FontExpression.merge(this, newFontExpr);
    }

    return null;
  }

  /**
   * Merge the two FontExpression and return the result.
   */
  factory FontExpression.merge(FontExpression x, FontExpression y) {
    return new FontExpression._merge(x, y, y.span);
  }

  FontExpression._merge(FontExpression x, FontExpression y, Span span)
      : super(DartStyleExpression.fontStyle, span),
        font = new Font.merge(x.font, y.font);

  visit(VisitorBase visitor) => visitor.visitFontExpression(this);
}

abstract class BoxExpression extends DartStyleExpression {
  final BoxEdge box;

  BoxExpression(int styleType, Span span, this.box)
      : super(styleType, span);

  /*
   * Merges give 2 DartStyleExpression (or derived from DartStyleExpression,
   * e.g., FontExpression, etc.) will merge if the two expressions are of the
   * same property name (implies same exact type e.g, FontExpression).
   */
  merged(BoxExpression newDartExpr);

  visit(VisitorBase visitor) => visitor.visitBoxExpression(this);

  String get formattedBoxEdge {
    if (box.top == box.left && box.top == box.bottom &&
        box.top== box.right) {
      return '.uniform(${box.top})';
    } else {
      var left = box.left == null ? 0 : box.left;
      var top = box.top == null ? 0 : box.top;
      var right = box.right == null ? 0 : box.right;
      var bottom = box.bottom == null ? 0 : box.bottom;
      return '.clockwiseFromTop($top,$right,$bottom,$left)';
    }
  }
}

class MarginExpression extends BoxExpression {
  // TODO(terry): Does auto for margin need to be exposed to Dart UI framework?
  /** Margin expression ripped apart. */
  MarginExpression(Span span, {num top, num right, num bottom, num left})
      : super(DartStyleExpression.marginStyle, span,
              new BoxEdge(left, top, right, bottom));

  MarginExpression.boxEdge(Span span, BoxEdge box)
      : super(DartStyleExpression.marginStyle, span, box);

  merged(MarginExpression newMarginExpr) {
    if (this.isMargin && newMarginExpr.isMargin) {
      return new MarginExpression.merge(this, newMarginExpr);
    }

    return null;
  }

  /**
   * Merge the two MarginExpressions and return the result.
   */
  factory MarginExpression.merge(MarginExpression x, MarginExpression y) {
    return new MarginExpression._merge(x, y, y.span);
  }

  MarginExpression._merge(MarginExpression x, MarginExpression y, Span span)
      : super(x._styleType, span, new BoxEdge.merge(x.box, y.box));

  visit(VisitorBase visitor) => visitor.visitMarginExpression(this);
}

class BorderExpression extends BoxExpression {
  /** Border expression ripped apart. */
  BorderExpression(Span span, {num top, num right, num bottom, num left})
      : super(DartStyleExpression.borderStyle, span,
              new BoxEdge(left, top, right, bottom));

  BorderExpression.boxEdge(Span span, BoxEdge box)
      : super(DartStyleExpression.borderStyle, span, box);

  merged(BorderExpression newBorderExpr) {
    if (this.isBorder && newBorderExpr.isBorder) {
      return new BorderExpression.merge(this, newBorderExpr);
    }

    return null;
  }

  /**
   * Merge the two BorderExpression and return the result.
   */
  factory BorderExpression.merge(BorderExpression x, BorderExpression y) {
    return new BorderExpression._merge(x, y, y.span);
  }

  BorderExpression._merge(BorderExpression x, BorderExpression y,
      Span span)
      : super(DartStyleExpression.borderStyle, span,
              new BoxEdge.merge(x.box, y.box));

  visit(VisitorBase visitor) => visitor.visitBorderExpression(this);
}

class HeightExpression extends DartStyleExpression {
  final height;

  HeightExpression(Span span, this.height)
      : super(DartStyleExpression.heightStyle, span);

  merged(HeightExpression newHeightExpr) {
    if (this.isHeight && newHeightExpr.isHeight) {
      return newHeightExpr;
    }

    return null;
  }

  visit(VisitorBase visitor) => visitor.visitHeightExpression(this);
}

class WidthExpression extends DartStyleExpression {
  final width;

  WidthExpression(Span span, this.width)
      : super(DartStyleExpression.widthStyle, span);

  merged(WidthExpression newWidthExpr) {
    if (this.isWidth && newWidthExpr.isWidth) {
      return newWidthExpr;
    }

    return null;
  }

  visit(VisitorBase visitor) => visitor.visitWidthExpression(this);
}

class PaddingExpression extends BoxExpression {
  /** Padding expression ripped apart. */
  PaddingExpression(Span span, {num top, num right, num bottom, num left})
      : super(DartStyleExpression.paddingStyle, span,
              new BoxEdge(left, top, right, bottom));

  PaddingExpression.boxEdge(Span span, BoxEdge box)
      : super(DartStyleExpression.paddingStyle, span, box);

  merged(PaddingExpression newPaddingExpr) {
    if (this.isPadding && newPaddingExpr.isPadding) {
      return new PaddingExpression.merge(this, newPaddingExpr);
    }

    return null;
  }

  /**
   * Merge the two PaddingExpression and return the result.
   */
  factory PaddingExpression.merge(PaddingExpression x, PaddingExpression y) {
    return new PaddingExpression._merge(x, y, y.span);
  }

  PaddingExpression._merge(PaddingExpression x, PaddingExpression y, Span span)
      : super(DartStyleExpression.paddingStyle, span,
            new BoxEdge.merge(x.box, y.box));

  visit(VisitorBase visitor) => visitor.visitPaddingExpression(this);
}
