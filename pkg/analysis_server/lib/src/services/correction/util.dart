// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:math';

import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:analysis_server/src/utilities/extensions/ast.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/precedence.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/utilities/extensions/string.dart';
import 'package:analyzer_plugin/src/utilities/string_utilities.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:path/path.dart' as path;

/// Climbs up [PrefixedIdentifier] and [PropertyAccess] nodes that include
/// [node].
Expression climbPropertyAccess(Expression node) {
  while (true) {
    var parent = node.parent;
    if (parent is PrefixedIdentifier && parent.identifier == node) {
      node = parent;
      continue;
    }
    if (parent is PropertyAccess && parent.propertyName == node) {
      node = parent;
      continue;
    }
    return node;
  }
}

/// Return references to the [element] inside the [root] node.
List<SimpleIdentifier> findLocalElementReferences(
    AstNode root, LocalElement element) {
  var collector = _ElementReferenceCollector(element);
  root.accept(collector);
  return collector.references;
}

/// Return references to the [element] inside the [root] node.
List<SimpleIdentifier> findPrefixElementReferences(
    AstNode root, PrefixElement element) {
  var collector = _ElementReferenceCollector(element);
  root.accept(collector);
  return collector.references;
}

// TODO(scheglov): replace with nodes once there will be
// [CompilationUnit.getComments].
/// Returns [SourceRange]s of all comments in [unit].
List<SourceRange> getCommentRanges(CompilationUnit unit) {
  var ranges = <SourceRange>[];
  var token = unit.beginToken;
  while (!token.isEof) {
    var commentToken = token.precedingComments;
    while (commentToken != null) {
      ranges.add(range.token(commentToken));
      commentToken = commentToken.next as CommentToken?;
    }
    token = token.next!;
  }
  return ranges;
}

/// Return all [LocalElement]s defined in the given [node].
List<LocalElement> getDefinedLocalElements(AstNode node) {
  var collector = _LocalElementsCollector();
  node.accept(collector);
  return collector.elements;
}

/// Return the name of the [Element] kind.
String getElementKindName(Element element) {
  return element.kind.displayName;
}

/// Returns the name to display in the UI for the given [Element].
String getElementQualifiedName(Element element) {
  var kind = element.kind;
  if (kind == ElementKind.FIELD || kind == ElementKind.METHOD) {
    return '${element.enclosingElement!.displayName}.${element.displayName}';
  } else if (kind == ElementKind.LIBRARY) {
    // Libraries may not have names, so use a path relative to the context root.
    var session = element.session!;
    var pathContext = session.resourceProvider.pathContext;
    var rootPath = session.analysisContext.contextRoot.root.path;
    var library = element as LibraryElement;

    return pathContext.relative(library.source.fullName, from: rootPath);
  } else {
    return element.displayName;
  }
}

/// Returns a class or an unit member enclosing the given [input].
AstNode? getEnclosingClassOrUnitMember(AstNode input) {
  var member = input;
  for (var node in input.withParents) {
    switch (node) {
      case ClassDeclaration _:
      case CompilationUnit _:
      case EnumDeclaration _:
      case ExtensionDeclaration _:
      case ExtensionTypeDeclaration _:
      case MixinDeclaration _:
        return member;
    }
    member = node;
  }
  return null;
}

/// Return the [ExecutableElement] of the enclosing executable [AstNode].
ExecutableElement? getEnclosingExecutableElement(AstNode input) {
  for (var node in input.withParents) {
    if (node is FunctionDeclaration) {
      return node.declaredElement;
    }
    if (node is ConstructorDeclaration) {
      return node.declaredElement;
    }
    if (node is MethodDeclaration) {
      return node.declaredElement;
    }
  }
  return null;
}

/// Return the enclosing executable [AstNode].
AstNode? getEnclosingExecutableNode(AstNode input) {
  for (var node in input.withParents) {
    if (node is FunctionDeclaration) {
      return node;
    }
    if (node is ConstructorDeclaration) {
      return node;
    }
    if (node is MethodDeclaration) {
      return node;
    }
  }
  return null;
}

/// Returns [getExpressionPrecedence] for the parent of [node], or
/// ASSIGNMENT_PRECEDENCE if the parent node is a [ParenthesizedExpression].
///
/// The reason is that `(expr)` is always executed after `expr`.
Precedence getExpressionParentPrecedence(AstNode node) {
  var parent = node.parent!;
  if (parent is ParenthesizedExpression) {
    return Precedence.assignment;
  } else if (parent is IndexExpression && parent.index == node) {
    return Precedence.assignment;
  } else if (parent is AssignmentExpression &&
      node == parent.rightHandSide &&
      parent.parent is CascadeExpression) {
    // This is a hack to allow nesting of cascade expressions within other
    // cascade expressions. The problem is that if the precedence of two
    // expressions are equal it sometimes means that we don't need parentheses
    // (such as replacing the `b` in `a + b` with `c + d`) and sometimes do
    // (such as replacing the `v` in `..f = v` with `a..b`).
    return Precedence.conditional;
  }
  return getExpressionPrecedence(parent);
}

/// Returns the precedence of [node] it is an [Expression], NO_PRECEDENCE
/// otherwise.
Precedence getExpressionPrecedence(AstNode node) {
  if (node is Expression) {
    return node.precedence;
  }
  return Precedence.none;
}

/// Returns the namespace of the given [LibraryImportElement].
Map<String, Element> getImportNamespace(LibraryImportElement imp) {
  return imp.namespace.definedNames;
}

/// Computes the best URI to import [what] into [from].
String getLibrarySourceUri(
    path.Context pathContext, LibraryElement from, Uri what) {
  if (what.isScheme('file')) {
    var fromFolder = pathContext.dirname(from.source.fullName);
    var relativeFile = pathContext.relative(what.path, from: fromFolder);
    return pathContext.split(relativeFile).join('/');
  }
  return what.toString();
}

/// Return the [LocalVariableElement] if given [node] is a reference to a local
/// variable, or `null` in the other case.
LocalVariableElement? getLocalVariableElement(SimpleIdentifier node) {
  var element = node.staticElement;
  if (element is LocalVariableElement) {
    return element;
  }
  return null;
}

/// Return the nearest common ancestor of the given [nodes].
AstNode? getNearestCommonAncestor(List<AstNode> nodes) {
  // may be no nodes
  if (nodes.isEmpty) {
    return null;
  }
  // prepare parents
  var parents = <List<AstNode>>[];
  for (var node in nodes) {
    parents.add(getParents(node));
  }
  // find min length
  var minLength = 1 << 20;
  for (var parentList in parents) {
    minLength = min(minLength, parentList.length);
  }
  // find deepest parent
  var i = 0;
  for (; i < minLength; i++) {
    if (!_allListsIdentical(parents, i)) {
      break;
    }
  }
  return parents[0][i - 1];
}

/// Returns the [Expression] qualifier if given [node] is the name part of a
/// [PropertyAccess] or a [PrefixedIdentifier]. Maybe `null`.
Expression? getNodeQualifier(SimpleIdentifier node) {
  var parent = node.parent;
  if (parent is MethodInvocation && identical(parent.methodName, node)) {
    return parent.target;
  }
  if (parent is PropertyAccess && identical(parent.propertyName, node)) {
    return parent.target;
  }
  if (parent is PrefixedIdentifier && identical(parent.identifier, node)) {
    return parent.prefix;
  }
  return null;
}

/// Returns the [ParameterElement] if the given [node] is a reference to a
/// parameter, or `null` in the other case.
ParameterElement? getParameterElement(SimpleIdentifier node) {
  var element = node.staticElement;
  if (element is ParameterElement) {
    return element;
  }
  return null;
}

/// Return parent [AstNode]s from compilation unit (at index "0") to the given
/// [node].
List<AstNode> getParents(AstNode node) {
  return node.withParents.toList().reversed.toList();
}

/// If given [node] is name of qualified property extraction, returns target
/// from which this property is extracted, otherwise `null`.
Expression? getQualifiedPropertyTarget(AstNode node) {
  var parent = node.parent;
  if (parent is PrefixedIdentifier) {
    var prefixed = parent;
    if (prefixed.identifier == node) {
      return parent.prefix;
    }
  }
  if (parent is PropertyAccess) {
    var access = parent;
    if (access.propertyName == node) {
      return access.realTarget;
    }
  }
  return null;
}

/// Returns the given [statement] if not a block, or the first child statement
/// if a block, or `null` if more than one child.
Statement? getSingleStatement(Statement? statement) {
  if (statement is Block) {
    List<Statement> blockStatements = statement.statements;
    if (blockStatements.length != 1) {
      return null;
    }
    return blockStatements[0];
  }
  return statement;
}

/// Returns the given [statement] if not a block, or all the children statements
/// if a block.
List<Statement> getStatements(Statement statement) {
  if (statement is Block) {
    return statement.statements;
  }
  return [statement];
}

/// Checks if the given [element]'s display name equals to the given [name].
bool hasDisplayName(Element? element, String name) {
  return element?.displayName == name;
}

/// Return whether the specified [name] is declared inside the [root] node
/// or not.
bool isDeclaredIn(AstNode root, String name) {
  bool isDeclaredIn(FormalParameterList? parameters) {
    if (parameters != null) {
      for (var parameter in parameters.parameters) {
        if (parameter.name?.lexeme == name) {
          return true;
        }
      }
    }
    return false;
  }

  if (root is MethodDeclaration && isDeclaredIn(root.parameters)) {
    return true;
  }
  if (root is FunctionDeclaration &&
      isDeclaredIn(root.functionExpression.parameters)) {
    return true;
  }

  var collector = _DeclarationCollector(name);
  root.accept(collector);
  return collector.isDeclared;
}

/// Checks if given [DartNode] is the left hand side of an assignment, or a
/// declaration of a variable.
bool isLeftHandOfAssignment(SimpleIdentifier node) {
  if (node.inSetterContext()) {
    return true;
  }
  return node.parent is VariableDeclaration &&
      (node.parent as VariableDeclaration).name == node.token;
}

/// Return `true` if the given [node] is the name of a [NamedExpression].
bool isNamedExpressionName(SimpleIdentifier node) {
  var parent = node.parent;
  if (parent is Label) {
    var label = parent;
    if (identical(label.label, node)) {
      var parent2 = label.parent;
      if (parent2 is NamedExpression) {
        return identical(parent2.name, label);
      }
    }
  }
  return false;
}

/// If the given [expression] is the `expression` property of a
/// [NamedExpression] then returns this [NamedExpression], otherwise returns
/// [expression].
Expression stepUpNamedExpression(Expression expression) {
  var parent = expression.parent;
  return parent is NamedExpression ? parent : expression;
}

/// Return `true` if the given [lists] are identical at the given [position].
bool _allListsIdentical(List<List<Object>> lists, int position) {
  var element = lists[0][position];
  for (var list in lists) {
    if (list[position] != element) {
      return false;
    }
  }
  return true;
}

final class CorrectionUtils {
  static const String _oneIndent = '  ';

  static const String _twoIndents = _oneIndent + _oneIndent;

  final CompilationUnit _unit;

  final String _buffer;

  String? _endOfLine;

  CorrectionUtils(ParsedUnitResult result)
      : _unit = result.unit,
        _buffer = result.content;

  /// The EOL sequence to use for this [CompilationUnit].
  String get endOfLine {
    var endOfLine = _endOfLine;
    if (endOfLine != null) {
      return endOfLine;
    }

    if (_buffer.contains('\r\n')) {
      return _endOfLine = '\r\n';
    }

    if (_buffer.contains('\n')) {
      return _endOfLine = '\n';
    }

    return Platform.lineTerminator;
  }

  String get oneIndent => _oneIndent;

  String get twoIndents => _twoIndents;

  /// Returns the [AstNode] that encloses the given [offset].
  AstNode? findNode(int offset) => NodeLocator(offset).searchWithin(_unit);

  /// Skips whitespace characters and single EOL on the right from [index].
  ///
  /// If [index] the end of a statement or method, then in most cases this
  /// returns the start of the next line.
  int getLineContentEnd(int index) {
    var length = _buffer.length;
    // Skip whitespace characters.
    while (index < length) {
      var c = _buffer.codeUnitAt(index);
      if (!c.isWhitespace || c.isEOL) {
        break;
      }
      index++;
    }
    // Skip a single '\r' character.
    if (index < length && _buffer.codeUnitAt(index) == 0x0D) {
      index++;
    }
    // Skip a single '\n' character.
    if (index < length && _buffer.codeUnitAt(index) == 0x0A) {
      index++;
    }
    // Done.
    return index;
  }

  /// Skips spaces and tabs on the left from [index].
  ///
  /// If [index] is the start or a statement, then in most cases this returns
  /// the offset of the line in which [index] is found.
  int getLineContentStart(int index) {
    while (index > 0) {
      var c = _buffer.codeUnitAt(index - 1);
      if (!c.isSpace) {
        break;
      }
      index--;
    }
    return index;
  }

  /// Returns the index of the start of the line following the line which
  /// contains the given [index].
  int getLineNext(int index) {
    var length = _buffer.length;
    // skip to the end of the line
    while (index < length) {
      var c = _buffer.codeUnitAt(index);
      if (c == 0xD || c == 0xA) {
        break;
      }
      index++;
    }
    // Skip a single '\r'.
    if (index < length && _buffer.codeUnitAt(index) == 0xD) {
      index++;
    }
    // Skip a single '\n'.
    if (index < length && _buffer.codeUnitAt(index) == 0xA) {
      index++;
    }
    // Done.
    return index;
  }

  /// Returns the whitespace prefix of the line which contains given [index].
  String getLinePrefix(int index) {
    var lineStart = getLineThis(index);
    var length = _buffer.length;
    var lineNonWhitespace = lineStart;
    while (lineNonWhitespace < length) {
      var c = _buffer.codeUnitAt(lineNonWhitespace);
      if (c == 0xD || c == 0xA) {
        break;
      }
      if (!c.isWhitespace) {
        break;
      }
      lineNonWhitespace++;
    }
    return getText(lineStart, lineNonWhitespace - lineStart);
  }

  /// Returns a [SourceRange] that covers [sourceRange] and extends (if
  /// possible) to cover whole lines.
  SourceRange getLinesRange(SourceRange sourceRange,
      {bool skipLeadingEmptyLines = false}) {
    // Calculate the start:
    var startOffset = sourceRange.offset;
    var startLineOffset = getLineContentStart(startOffset);
    if (skipLeadingEmptyLines) {
      startLineOffset = _skipEmptyLinesLeft(startLineOffset);
    }
    // Calculate the end:
    var endOffset = sourceRange.end;
    var afterEndLineOffset = endOffset;
    var lineInfo = _unit.lineInfo;
    var lineStart = lineInfo
        .getOffsetOfLine(lineInfo.getLocation(startLineOffset).lineNumber - 1);
    if (lineStart == startLineOffset) {
      // Only consume line endings after the end of the range if there is
      // nothing else on the line containing the beginning of the range.
      // Otherwise this will end up incorrectly merging two line.
      afterEndLineOffset = getLineContentEnd(endOffset);
    }
    return range.startOffsetEndOffset(startLineOffset, afterEndLineOffset);
  }

  /// Returns a [SourceRange] that covers all the given [Statement]s.
  SourceRange getLinesRangeStatements(List<Statement> statements) {
    return getLinesRange(range.nodes(statements));
  }

  /// Returns the start index of the line which contains the given [index].
  int getLineThis(int index) {
    while (index > 0) {
      var c = _buffer.codeUnitAt(index - 1);
      if (c == 0xD || c == 0xA) {
        break;
      }
      index--;
    }
    return index;
  }

  /// Returns the whitespace prefix of the line which contains given [node].
  String getNodePrefix(AstNode node) {
    var offset = node.offset;
    // function literal is special, it uses offset of enclosing line
    if (node is FunctionExpression) {
      return getLinePrefix(offset);
    }
    // use just prefix directly before node
    return getPrefix(offset);
  }

  /// Returns the text of the given [AstNode] in the unit, including preceding
  /// comments.
  String getNodeText(
    AstNode node, {
    bool withLeadingComments = false,
  }) {
    var firstToken = withLeadingComments
        ? node.beginToken.precedingComments ?? node.beginToken
        : node.beginToken;
    var offset = firstToken.offset;
    var end = node.endToken.end;
    var length = end - offset;
    return getText(offset, length);
  }

  /// Returns the whitespace prefix to the left of the given [endIndex].
  String getPrefix(int endIndex) {
    var startIndex = getLineContentStart(endIndex);
    return _buffer.substring(startIndex, endIndex);
  }

  /// Returns the text of the given range in the unit.
  String getRangeText(SourceRange range) => getText(range.offset, range.length);

  /// Returns the text of the given range in the unit.
  String getText(int offset, int length) =>
      _buffer.substring(offset, offset + length);

  /// Indents the given [source] left or right.
  String indentSourceLeftRight(String source, {bool indentLeft = true}) {
    var sb = StringBuffer();
    var indent = oneIndent;
    var eol = endOfLine;
    var lines = source.split(eol);
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i];
      // last line, stop if empty
      if (i == lines.length - 1 && isEmpty(line)) {
        break;
      }
      // update line
      if (indentLeft) {
        line = removeStart(line, indent)!;
      } else {
        line = '$indent$line';
      }
      // append line
      sb.write(line);
      sb.write(eol);
    }
    return sb.toString();
  }

  /// Returns the source of the inverted condition for the given logical
  /// expression.
  String invertCondition(Expression expression) =>
      _invertCondition0(expression)._source;

  /// Returns the source with indentation changed from [oldIndent] to
  /// [newIndent], keeping indentation of lines relative to each other.
  ///
  /// Indentation on the first line will only be updated if [includeLeading] is
  /// `true`.
  ///
  /// If [ensureTrailingNewline] is `true`, a newline will be added to
  /// the end of the returned code if it does not already have one.
  ///
  /// Usually [includeLeading] and [ensureTrailingNewline] are set together,
  /// when indenting a set of statements to go inside a block (as opposed to
  /// just wrapping a nested expression that might span multiple lines).
  String replaceSourceIndent(String source, String oldIndent, String newIndent,
      {bool includeLeading = false, bool ensureTrailingNewline = false}) {
    // Prepare token ranges.
    var lineRanges = <SourceRange>[];
    {
      var tokens = TokenUtils.getTokens(source, _unit.featureSet);
      for (var token in tokens) {
        if (token.type == TokenType.STRING) {
          lineRanges.add(range.token(token));
        }
      }
    }
    // Re-indent lines.
    var sb = StringBuffer();
    var eol = endOfLine;
    var lines = source.split(eol);
    var lineOffset = 0;
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i];
      // Exit early if this is the last line and it's already empty, to avoid
      // inserting any whitespace or appending an additional newline if
      // `ensureTrailingNewline`.
      if (i == lines.length - 1 && isEmpty(line)) {
        break;
      }
      // Don't replace whitespace on first line unless `includeLeading`.
      var doReplaceWhitespace = i != 0 || includeLeading;
      // Don't add eol to last line unless `ensureTrailingNewline`.
      var doAppendEol = i != lines.length - 1 || ensureTrailingNewline;

      // Check if "offset" is in one of the ranges.
      var inString = false;
      for (var lineRange in lineRanges) {
        if (lineOffset > lineRange.offset && lineOffset < lineRange.end) {
          inString = true;
        }
        if (lineOffset > lineRange.end) {
          break;
        }
      }
      lineOffset += line.length + eol.length;
      // Update line indent.
      if (!inString && doReplaceWhitespace) {
        line = '$newIndent${removeStart(line, oldIndent)}';
      }
      // Append line.
      sb.write(line);
      if (doAppendEol) {
        sb.write(eol);
      }
    }
    return sb.toString();
  }

  /// Returns the source of the given [SourceRange] with indentation changed
  /// from [oldIndent] to [newIndent], keeping indentation of lines relative
  /// to each other.
  ///
  /// Indentation on the first line will only be updated if [includeLeading] is
  /// `true`.
  ///
  /// If [ensureTrailingNewline] is `true`, a newline will be added to
  /// the end of the returned code if it does not already have one.
  ///
  /// Usually [includeLeading] and [ensureTrailingNewline] are set together,
  /// when indenting a set of statements to go inside a block (as opposed to
  /// just wrapping a nested expression that might span multiple lines).
  String replaceSourceRangeIndent(
      SourceRange range, String oldIndent, String newIndent,
      {bool includeLeading = false, bool ensureTrailingNewline = false}) {
    var oldSource = getRangeText(range);
    return replaceSourceIndent(oldSource, oldIndent, newIndent,
        includeLeading: includeLeading,
        ensureTrailingNewline: ensureTrailingNewline);
  }

  /// Returns the [_InvertedCondition] for the given logical expression.
  _InvertedCondition _invertCondition0(Expression expression) {
    if (expression is BooleanLiteral) {
      if (expression.value) {
        return _InvertedCondition._simple('false');
      } else {
        return _InvertedCondition._simple('true');
      }
    } else if (expression is BinaryExpression) {
      var operator = expression.operator.type;
      var le = expression.leftOperand;
      var re = expression.rightOperand;
      var ls = _InvertedCondition._simple(getNodeText(le));
      var rs = _InvertedCondition._simple(getNodeText(re));
      if (operator == TokenType.LT) {
        return _InvertedCondition._binary2(ls, ' >= ', rs);
      }
      if (operator == TokenType.GT) {
        return _InvertedCondition._binary2(ls, ' <= ', rs);
      }
      if (operator == TokenType.LT_EQ) {
        return _InvertedCondition._binary2(ls, ' > ', rs);
      }
      if (operator == TokenType.GT_EQ) {
        return _InvertedCondition._binary2(ls, ' < ', rs);
      }
      if (operator == TokenType.EQ_EQ) {
        return _InvertedCondition._binary2(ls, ' != ', rs);
      }
      if (operator == TokenType.BANG_EQ) {
        return _InvertedCondition._binary2(ls, ' == ', rs);
      }
      if (operator == TokenType.AMPERSAND_AMPERSAND) {
        ls = _invertCondition0(le);
        rs = _invertCondition0(re);
        return _InvertedCondition._binary(
            TokenType.BAR_BAR.precedence, ls, ' || ', rs);
      }
      if (operator == TokenType.BAR_BAR) {
        ls = _invertCondition0(le);
        rs = _invertCondition0(re);
        return _InvertedCondition._binary(
            TokenType.AMPERSAND_AMPERSAND.precedence, ls, ' && ', rs);
      }
    } else if (expression is IsExpression) {
      var expressionSource = getNodeText(expression.expression);
      var typeSource = getNodeText(expression.type);
      if (expression.notOperator == null) {
        return _InvertedCondition._simple('$expressionSource is! $typeSource');
      } else {
        return _InvertedCondition._simple('$expressionSource is $typeSource');
      }
    } else if (expression is PrefixExpression) {
      var operator = expression.operator.type;
      if (operator == TokenType.BANG) {
        var operand = expression.operand.unParenthesized;
        return _InvertedCondition._simple(getNodeText(operand));
      }
    } else if (expression is ParenthesizedExpression) {
      return _invertCondition0(expression.unParenthesized);
    }
    var type = expression.typeOrThrow;
    if (type.isDartCoreBool) {
      return _InvertedCondition._simple('!${getNodeText(expression)}');
    }
    return _InvertedCondition._simple(getNodeText(expression));
  }

  /// Skips whitespace and EOLs to the left of [index].
  ///
  /// If [index] is the start of a method declaration, then in most cases, this
  /// returns the end of the previous non-whitespace line.
  int _skipEmptyLinesLeft(int index) {
    var lastLine = index;
    while (index > 0) {
      var c = _buffer.codeUnitAt(index - 1);
      if (!c.isWhitespace) {
        return lastLine;
      }
      if (c.isEOL) {
        lastLine = index;
      }
      index--;
    }
    return 0;
  }
}

/// Utilities to work with [Token]s.
class TokenUtils {
  /// Returns the tokens of the given Dart source, [s].
  ///
  /// The returned list may be empty if there are no tokens, or some exception
  /// is caught.
  static List<Token> getTokens(String s, FeatureSet featureSet) {
    try {
      var tokens = <Token>[];
      var scanner = Scanner(
        _SourceMock(),
        CharSequenceReader(s),
        AnalysisErrorListener.NULL_LISTENER,
      )..configureFeatures(
          featureSetForOverriding: featureSet,
          featureSet: featureSet,
        );
      var token = scanner.tokenize();
      while (!token.isEof) {
        tokens.add(token);
        token = token.next!;
      }
      return tokens;
    } catch (e) {
      return [];
    }
  }
}

class _DeclarationCollector extends RecursiveAstVisitor<void> {
  final String name;
  bool isDeclared = false;

  _DeclarationCollector(this.name);

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    if (node.name.lexeme == name) {
      isDeclared = true;
    }
  }
}

class _ElementReferenceCollector extends RecursiveAstVisitor<void> {
  final Element element;
  final List<SimpleIdentifier> references = [];

  _ElementReferenceCollector(this.element);

  @override
  void visitImportPrefixReference(ImportPrefixReference node) {
    if (node.element == element) {
      references.add(SimpleIdentifierImpl(node.name));
    }
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.staticElement == element) {
      references.add(node);
    }
  }
}

/// A container with a source and its precedence.
class _InvertedCondition {
  final int _precedence;

  final String _source;

  _InvertedCondition(this._precedence, this._source);

  static _InvertedCondition _binary(int precedence, _InvertedCondition left,
      String operation, _InvertedCondition right) {
    var src = _parenthesizeIfRequired(left, precedence) +
        operation +
        _parenthesizeIfRequired(right, precedence);
    return _InvertedCondition(precedence, src);
  }

  static _InvertedCondition _binary2(
      _InvertedCondition left, String operation, _InvertedCondition right) {
    // TODO(scheglov): consider merging with "_binary()" after testing
    return _InvertedCondition(
        1 << 20, '${left._source}$operation${right._source}');
  }

  /// Adds enclosing parenthesis if the precedence of the [_InvertedCondition]
  /// if less than the precedence of the expression we are going it to use in.
  static String _parenthesizeIfRequired(
      _InvertedCondition expr, int newOperatorPrecedence) {
    if (expr._precedence < newOperatorPrecedence) {
      return '(${expr._source})';
    }
    return expr._source;
  }

  static _InvertedCondition _simple(String source) =>
      _InvertedCondition(2147483647, source);
}

/// Visitor that collects defined [LocalElement]s.
class _LocalElementsCollector extends RecursiveAstVisitor<void> {
  final elements = <LocalElement>[];

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    var element = node.declaredElement;
    if (element is LocalVariableElement) {
      elements.add(element);
    }

    super.visitVariableDeclaration(node);
  }
}

class _SourceMock implements Source {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
