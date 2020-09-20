// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analysis_server/src/protocol_server.dart' hide Element;
import 'package:analysis_server/src/services/correction/name_suggestion.dart';
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analysis_server/src/services/refactoring/naming_conventions.dart';
import 'package:analysis_server/src/services/refactoring/refactoring.dart';
import 'package:analysis_server/src/services/refactoring/refactoring_internal.dart';
import 'package:analysis_server/src/utilities/strings.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

const String _TOKEN_SEPARATOR = '\uFFFF';

/// [ExtractLocalRefactoring] implementation.
class ExtractLocalRefactoringImpl extends RefactoringImpl
    implements ExtractLocalRefactoring {
  final ResolvedUnitResult resolveResult;
  final int selectionOffset;
  final int selectionLength;
  SourceRange selectionRange;
  CorrectionUtils utils;

  String name;
  bool extractAll = true;
  @override
  final List<int> coveringExpressionOffsets = <int>[];
  @override
  final List<int> coveringExpressionLengths = <int>[];
  @override
  final List<String> names = <String>[];
  @override
  final List<int> offsets = <int>[];
  @override
  final List<int> lengths = <int>[];

  FunctionBody coveringFunctionBody;
  Expression singleExpression;
  String stringLiteralPart;
  final List<SourceRange> occurrences = <SourceRange>[];
  final Map<Element, int> elementIds = <Element, int>{};
  Set<String> excludedVariableNames = <String>{};

  ExtractLocalRefactoringImpl(
      this.resolveResult, this.selectionOffset, this.selectionLength) {
    selectionRange = SourceRange(selectionOffset, selectionLength);
    utils = CorrectionUtils(resolveResult);
  }

  String get file => resolveResult.path;

  @override
  String get refactoringName => 'Extract Local Variable';

  CompilationUnit get unit => resolveResult.unit;

  CompilationUnitElement get unitElement => unit.declaredElement;

  String get _declarationKeyword {
    if (_isPartOfConstantExpression(singleExpression)) {
      return 'const';
    } else if (_isLintEnabled(LintNames.prefer_final_locals)) {
      return 'final';
    } else {
      return 'var';
    }
  }

  @override
  Future<RefactoringStatus> checkFinalConditions() {
    var result = RefactoringStatus();
    result.addStatus(checkName());
    return Future.value(result);
  }

  @override
  Future<RefactoringStatus> checkInitialConditions() {
    var result = RefactoringStatus();
    // selection
    result.addStatus(_checkSelection());
    if (result.hasFatalError) {
      return Future.value(result);
    }
    // occurrences
    _prepareOccurrences();
    _prepareOffsetsLengths();
    // names
    excludedVariableNames =
        utils.findPossibleLocalVariableConflicts(selectionOffset);
    _prepareNames();
    // done
    return Future.value(result);
  }

  @override
  RefactoringStatus checkName() {
    var result = RefactoringStatus();
    result.addStatus(validateVariableName(name));
    if (excludedVariableNames.contains(name)) {
      result.addError(
          format("The name '{0}' is already used in the scope.", name));
    }
    return result;
  }

  @override
  Future<SourceChange> createChange() {
    var change = SourceChange(refactoringName);
    // prepare occurrences
    List<SourceRange> occurrences;
    if (extractAll) {
      occurrences = this.occurrences;
    } else {
      occurrences = [selectionRange];
    }
    occurrences.sort((a, b) => a.offset - b.offset);
    // If the whole expression of a statement is selected, like '1 + 2',
    // then convert it into a variable declaration statement.
    if (singleExpression?.parent is ExpressionStatement &&
        occurrences.length == 1) {
      var keyword = _declarationKeyword;
      var declarationSource = '$keyword $name = ';
      var edit = SourceEdit(singleExpression.offset, 0, declarationSource);
      doSourceChange_addElementEdit(change, unitElement, edit);
      return Future.value(change);
    }
    // prepare positions
    var positions = <Position>[];
    var occurrencesShift = 0;
    void addPosition(int offset) {
      positions.add(Position(file, offset));
    }

    // add variable declaration
    {
      String declarationCode;
      int nameOffsetInDeclarationCode;
      if (stringLiteralPart != null) {
        declarationCode = 'var ';
        nameOffsetInDeclarationCode = declarationCode.length;
        declarationCode += "$name = '$stringLiteralPart';";
      } else {
        var keyword = _declarationKeyword;
        var initializerCode = utils.getRangeText(selectionRange);
        declarationCode = '$keyword ';
        nameOffsetInDeclarationCode = declarationCode.length;
        declarationCode += '$name = $initializerCode;';
      }
      // prepare location for declaration
      var target = _findDeclarationTarget(occurrences);
      var eol = utils.endOfLine;
      // insert variable declaration
      if (target is Statement) {
        var prefix = utils.getNodePrefix(target);
        var edit = SourceEdit(target.offset, 0, declarationCode + eol + prefix);
        doSourceChange_addElementEdit(change, unitElement, edit);
        addPosition(edit.offset + nameOffsetInDeclarationCode);
        occurrencesShift = edit.replacement.length;
      } else if (target is ExpressionFunctionBody) {
        var prefix = utils.getNodePrefix(target.parent);
        var indent = utils.getIndent(1);
        var expr = target.expression;
        {
          var code = '{' + eol + prefix + indent;
          addPosition(
              target.offset + code.length + nameOffsetInDeclarationCode);
          code += declarationCode + eol;
          code += prefix + indent + 'return ';
          var edit =
              SourceEdit(target.offset, expr.offset - target.offset, code);
          occurrencesShift = target.offset + code.length - expr.offset;
          doSourceChange_addElementEdit(change, unitElement, edit);
        }
        doSourceChange_addElementEdit(
            change,
            unitElement,
            SourceEdit(
                expr.end, target.end - expr.end, ';' + eol + prefix + '}'));
      }
    }
    // prepare replacement
    var occurrenceReplacement = name;
    if (stringLiteralPart != null) {
      occurrenceReplacement = '\${$name}';
      occurrencesShift += 2;
    }
    // replace occurrences with variable reference
    for (var range in occurrences) {
      var edit = newSourceEdit_range(range, occurrenceReplacement);
      addPosition(range.offset + occurrencesShift);
      occurrencesShift += name.length - range.length;
      doSourceChange_addElementEdit(change, unitElement, edit);
    }
    // add the linked group
    change.addLinkedEditGroup(LinkedEditGroup(
        positions,
        name.length,
        names
            .map((name) =>
                LinkedEditSuggestion(name, LinkedEditSuggestionKind.VARIABLE))
            .toList()));
    // done
    return Future.value(change);
  }

  @override
  bool isAvailable() {
    return !_checkSelection().hasFatalError;
  }

  /// Checks if [selectionRange] selects [Expression] which can be extracted,
  /// and location of this [Expression] in AST allows extracting.
  RefactoringStatus _checkSelection() {
    if (selectionOffset <= 0) {
      return RefactoringStatus.fatal(
          'The selection offset must be greater than zero.');
    }
    if (selectionOffset + selectionLength >= resolveResult.content.length) {
      return RefactoringStatus.fatal(
          'The selection end offset must be less then the length of the file.');
    }

    var selectionStr = utils.getRangeText(selectionRange);

    // exclude whitespaces
    {
      var numLeading = countLeadingWhitespaces(selectionStr);
      var numTrailing = countTrailingWhitespaces(selectionStr);
      var offset = selectionRange.offset + numLeading;
      var end = selectionRange.end - numTrailing;
      selectionRange = SourceRange(offset, end - offset);
    }

    // get covering node
    var coveringNode = NodeLocator(selectionRange.offset, selectionRange.end)
        .searchWithin(unit);

    // We need an enclosing function.
    // If it has a block body, we can add a new variable declaration statement
    // into this block.  If it has an expression body, we can convert it into
    // the block body first.
    coveringFunctionBody = coveringNode?.thisOrAncestorOfType<FunctionBody>();
    if (coveringFunctionBody == null) {
      return RefactoringStatus.fatal(
          'An expression inside a function must be selected '
          'to activate this refactoring.');
    }

    // part of string literal
    if (coveringNode is StringLiteral) {
      if (selectionRange.length != 0 &&
          selectionRange.offset > coveringNode.offset &&
          selectionRange.end < coveringNode.end) {
        stringLiteralPart = selectionStr;
        return RefactoringStatus();
      }
    }
    // compute covering expressions
    for (var node = coveringNode; node != null; node = node.parent) {
      var parent = node.parent;
      // skip some nodes
      if (node is ArgumentList ||
          node is AssignmentExpression ||
          node is NamedExpression ||
          node is TypeArgumentList) {
        continue;
      }
      if (node is ConstructorName || node is Label || node is TypeName) {
        singleExpression = null;
        coveringExpressionOffsets.clear();
        coveringExpressionLengths.clear();
        continue;
      }
      // cannot extract the name part of a property access
      if (parent is PrefixedIdentifier && parent.identifier == node ||
          parent is PropertyAccess && parent.propertyName == node) {
        continue;
      }
      // stop if not an Expression
      if (node is! Expression) {
        break;
      }
      // stop at void method invocations
      if (node is MethodInvocation) {
        var invocation = node;
        var element = invocation.methodName.staticElement;
        if (element is ExecutableElement &&
            element.returnType != null &&
            element.returnType.isVoid) {
          if (singleExpression == null) {
            return RefactoringStatus.fatal(
                'Cannot extract the void expression.',
                newLocation_fromNode(node));
          }
          break;
        }
      }
      // fatal selection problems
      if (coveringExpressionOffsets.isEmpty) {
        if (node is SimpleIdentifier) {
          if (node.inDeclarationContext()) {
            return RefactoringStatus.fatal(
                'Cannot extract the name part of a declaration.',
                newLocation_fromNode(node));
          }
          var element = node.staticElement;
          if (element is FunctionElement || element is MethodElement) {
            continue;
          }
        }
        if (parent is AssignmentExpression && parent.leftHandSide == node) {
          return RefactoringStatus.fatal(
              'Cannot extract the left-hand side of an assignment.',
              newLocation_fromNode(node));
        }
      }
      // set selected expression
      singleExpression ??= node;
      // add the expression range
      coveringExpressionOffsets.add(node.offset);
      coveringExpressionLengths.add(node.length);
    }
    // single node selected
    if (singleExpression != null) {
      selectionRange = range.node(singleExpression);
      return RefactoringStatus();
    }
    // invalid selection
    return RefactoringStatus.fatal(
        'Expression must be selected to activate this refactoring.');
  }

  /// Return an unique identifier for the given [Element], or `null` if
  /// [element] is `null`.
  int _encodeElement(Element element) {
    if (element == null) {
      return null;
    }
    var id = elementIds[element];
    if (id == null) {
      id = elementIds.length;
      elementIds[element] = id;
    }
    return id;
  }

  /// Returns an [Element]-sensitive encoding of [tokens].
  /// Each [Token] with a [LocalVariableElement] has a suffix of the element id.
  ///
  /// So, we can distinguish different local variables with the same name, if
  /// there are multiple variables with the same name are declared in the
  /// function we are searching occurrences in.
  String _encodeExpressionTokens(Expression expr, List<Token> tokens) {
    // no expression, i.e. a part of a string
    if (expr == null) {
      return tokens.join(_TOKEN_SEPARATOR);
    }
    // prepare Token -> LocalElement map
    Map<Token, Element> map = HashMap<Token, Element>(
        equals: (Token a, Token b) => a.lexeme == b.lexeme,
        hashCode: (Token t) => t.lexeme.hashCode);
    expr.accept(_TokenLocalElementVisitor(map));
    // map and join tokens
    var result = tokens.map((Token token) {
      var tokenString = token.lexeme;
      // append token's Element id
      var element = map[token];
      if (element != null) {
        var elementId = _encodeElement(element);
        if (elementId != null) {
          tokenString += '-$elementId';
        }
      }
      // done
      return tokenString;
    }).join(_TOKEN_SEPARATOR);
    return result + _TOKEN_SEPARATOR;
  }

  /// Return the [AstNode] to defined the variable before.
  /// It should be accessible by all the given [occurrences].
  AstNode _findDeclarationTarget(List<SourceRange> occurrences) {
    var nodes = _findNodes(occurrences);
    var commonParent = getNearestCommonAncestor(nodes);
    // Block
    if (commonParent is Block) {
      var firstParents = getParents(nodes[0]);
      var commonIndex = firstParents.indexOf(commonParent);
      return firstParents[commonIndex + 1];
    }
    // ExpressionFunctionBody
    AstNode expressionBody = _getEnclosingExpressionBody(commonParent);
    if (expressionBody != null) {
      return expressionBody;
    }
    // single Statement
    AstNode target = commonParent.thisOrAncestorOfType<Statement>();
    while (target.parent is! Block) {
      target = target.parent;
    }
    return target;
  }

  /// Returns [AstNode]s at the offsets of the given [SourceRange]s.
  List<AstNode> _findNodes(List<SourceRange> ranges) {
    var nodes = <AstNode>[];
    for (var range in ranges) {
      var node = NodeLocator(range.offset).searchWithin(unit);
      nodes.add(node);
    }
    return nodes;
  }

  /// Returns the [ExpressionFunctionBody] that encloses [node], or `null`
  /// if [node] is not enclosed with an [ExpressionFunctionBody].
  ExpressionFunctionBody _getEnclosingExpressionBody(AstNode node) {
    while (node != null) {
      if (node is Statement) {
        return null;
      }
      if (node is ExpressionFunctionBody) {
        return node;
      }
      node = node.parent;
    }
    return null;
  }

  bool _isLintEnabled(String name) {
    var analysisOptions = unitElement.context.analysisOptions;
    return analysisOptions.isLintEnabled(name);
  }

  bool _isPartOfConstantExpression(AstNode node) {
    if (node is TypedLiteral) {
      return node.isConst;
    }
    if (node is InstanceCreationExpression) {
      return node.isConst;
    }
    if (node is ArgumentList ||
        node is ConditionalExpression ||
        node is BinaryExpression ||
        node is ParenthesizedExpression ||
        node is PrefixExpression ||
        node is Literal ||
        node is MapLiteralEntry) {
      return _isPartOfConstantExpression(node.parent);
    }
    return false;
  }

  void _prepareNames() {
    names.clear();
    if (stringLiteralPart != null) {
      names.addAll(getVariableNameSuggestionsForText(
          stringLiteralPart, excludedVariableNames));
    } else if (singleExpression != null) {
      names.addAll(getVariableNameSuggestionsForExpression(
          singleExpression.staticType,
          singleExpression,
          excludedVariableNames));
    }
  }

  /// Prepares all occurrences of the source which matches given selection,
  /// sorted by offsets.
  void _prepareOccurrences() {
    occurrences.clear();
    elementIds.clear();

    // prepare selection
    String selectionSource;
    if (singleExpression != null) {
      var tokens = TokenUtils.getNodeTokens(singleExpression);
      selectionSource = _encodeExpressionTokens(singleExpression, tokens);
    }
    // visit function
    coveringFunctionBody.accept(_OccurrencesVisitor(
        this, occurrences, selectionSource, unit.featureSet));
  }

  void _prepareOffsetsLengths() {
    offsets.clear();
    lengths.clear();
    for (var occurrence in occurrences) {
      offsets.add(occurrence.offset);
      lengths.add(occurrence.length);
    }
  }
}

class _OccurrencesVisitor extends GeneralizingAstVisitor<void> {
  final ExtractLocalRefactoringImpl ref;
  final List<SourceRange> occurrences;
  final String selectionSource;
  final FeatureSet featureSet;

  _OccurrencesVisitor(
      this.ref, this.occurrences, this.selectionSource, this.featureSet);

  @override
  void visitExpression(Expression node) {
    _tryToFindOccurrence(node);
    super.visitExpression(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    var parent = node.parent;
    if (parent is VariableDeclaration && parent.name == node ||
        parent is AssignmentExpression && parent.leftHandSide == node) {
      return;
    }
    super.visitSimpleIdentifier(node);
  }

  @override
  void visitStringLiteral(StringLiteral node) {
    if (ref.stringLiteralPart != null) {
      var length = ref.stringLiteralPart.length;
      var value = ref.utils.getNodeText(node);
      var lastIndex = 0;
      while (true) {
        var index = value.indexOf(ref.stringLiteralPart, lastIndex);
        if (index == -1) {
          break;
        }
        lastIndex = index + length;
        var start = node.offset + index;
        var range = SourceRange(start, length);
        occurrences.add(range);
      }
      return;
    }
    visitExpression(node);
  }

  void _addOccurrence(SourceRange range) {
    if (range.intersects(ref.selectionRange)) {
      occurrences.add(ref.selectionRange);
    } else {
      occurrences.add(range);
    }
  }

  void _tryToFindOccurrence(Expression node) {
    var nodeTokens = TokenUtils.getNodeTokens(node);
    var nodeSource = ref._encodeExpressionTokens(node, nodeTokens);
    if (nodeSource == selectionSource) {
      _addOccurrence(range.node(node));
    }
  }
}

class _TokenLocalElementVisitor extends RecursiveAstVisitor<void> {
  final Map<Token, Element> map;

  _TokenLocalElementVisitor(this.map);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    var element = node.staticElement;
    if (element is LocalVariableElement) {
      map[node.token] = element;
    }
  }
}
