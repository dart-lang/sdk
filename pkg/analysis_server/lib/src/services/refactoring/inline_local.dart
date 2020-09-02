// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart' hide Element;
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server/src/services/refactoring/refactoring.dart';
import 'package:analysis_server/src/services/refactoring/refactoring_internal.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/analysis/session_helper.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// [InlineLocalRefactoring] implementation.
class InlineLocalRefactoringImpl extends RefactoringImpl
    implements InlineLocalRefactoring {
  final SearchEngine searchEngine;
  final ResolvedUnitResult resolveResult;
  final int offset;
  CorrectionUtils utils;

  Element _variableElement;
  VariableDeclaration _variableNode;
  List<SearchMatch> _references;

  InlineLocalRefactoringImpl(
      this.searchEngine, this.resolveResult, this.offset) {
    utils = CorrectionUtils(resolveResult);
  }

  @override
  String get refactoringName => 'Inline Local Variable';

  @override
  int get referenceCount {
    if (_references == null) {
      return 0;
    }
    return _references.length;
  }

  @override
  String get variableName {
    if (_variableElement == null) {
      return null;
    }
    return _variableElement.name;
  }

  @override
  Future<RefactoringStatus> checkFinalConditions() {
    var result = RefactoringStatus();
    return Future.value(result);
  }

  @override
  Future<RefactoringStatus> checkInitialConditions() async {
    var result = RefactoringStatus();
    // prepare variable
    {
      var offsetNode = NodeLocator(offset).searchWithin(resolveResult.unit);
      if (offsetNode is SimpleIdentifier) {
        var element = offsetNode.staticElement;
        if (element is LocalVariableElement) {
          _variableElement = element;
          var declarationResult =
              await AnalysisSessionHelper(resolveResult.session)
                  .getElementDeclaration(element);
          _variableNode = declarationResult.node;
        }
      }
    }
    // validate node declaration
    if (!_isVariableDeclaredInStatement()) {
      result = RefactoringStatus.fatal(
          'Local variable declaration or reference must be selected '
          'to activate this refactoring.');
      return Future<RefactoringStatus>.value(result);
    }
    // should have initializer at declaration
    if (_variableNode.initializer == null) {
      var message = format(
          "Local variable '{0}' is not initialized at declaration.",
          _variableElement.displayName);
      result =
          RefactoringStatus.fatal(message, newLocation_fromNode(_variableNode));
      return Future<RefactoringStatus>.value(result);
    }
    // prepare references
    _references = await searchEngine.searchReferences(_variableElement);
    // should not have assignments
    for (var reference in _references) {
      if (reference.kind != MatchKind.READ) {
        var message = format("Local variable '{0}' is assigned more than once.",
            [_variableElement.displayName]);
        return RefactoringStatus.fatal(
            message, newLocation_fromMatch(reference));
      }
    }
    // done
    return result;
  }

  @override
  Future<SourceChange> createChange() {
    var change = SourceChange(refactoringName);
    // remove declaration
    {
      Statement declarationStatement =
          _variableNode.thisOrAncestorOfType<VariableDeclarationStatement>();
      var range = utils.getLinesRangeStatements([declarationStatement]);
      doSourceChange_addElementEdit(change, resolveResult.unit.declaredElement,
          newSourceEdit_range(range, ''));
    }
    // prepare initializer
    var initializer = _variableNode.initializer;
    var initializerCode = utils.getNodeText(initializer);
    // replace references
    for (var reference in _references) {
      var editRange = reference.sourceRange;
      // prepare context
      var offset = editRange.offset;
      var node = utils.findNode(offset);
      var parent = node.parent;
      // prepare code
      String codeForReference;
      if (parent is InterpolationExpression) {
        StringInterpolation target = parent.parent;
        if (initializer is SingleStringLiteral &&
            !initializer.isRaw &&
            initializer.isSingleQuoted == target.isSingleQuoted &&
            (!initializer.isMultiline || target.isMultiline)) {
          editRange = range.node(parent);
          // unwrap the literal being inlined
          var initOffset = initializer.contentsOffset;
          var initLength = initializer.contentsEnd - initOffset;
          codeForReference = utils.getText(initOffset, initLength);
        } else if (_shouldBeExpressionInterpolation(parent, initializer)) {
          codeForReference = '{$initializerCode}';
        } else {
          codeForReference = initializerCode;
        }
      } else if (_shouldUseParenthesis(initializer, node)) {
        codeForReference = '($initializerCode)';
      } else {
        codeForReference = initializerCode;
      }
      // do replace
      doSourceChange_addElementEdit(change, resolveResult.unit.declaredElement,
          newSourceEdit_range(editRange, codeForReference));
    }
    // done
    return Future.value(change);
  }

  bool _isVariableDeclaredInStatement() {
    if (_variableNode == null) {
      return false;
    }
    var parent = _variableNode.parent;
    if (parent is VariableDeclarationList) {
      parent = parent.parent;
      if (parent is VariableDeclarationStatement) {
        parent = parent.parent;
        return parent is Block || parent is SwitchCase;
      }
    }
    return false;
  }

  static bool _shouldBeExpressionInterpolation(
      InterpolationExpression target, Expression expression) {
    var targetType = target.beginToken.type;
    return targetType == TokenType.STRING_INTERPOLATION_IDENTIFIER &&
        expression is! SimpleIdentifier;
  }

  static bool _shouldUseParenthesis(Expression init, AstNode node) {
    // check precedence
    var initPrecedence = getExpressionPrecedence(init);
    if (initPrecedence < getExpressionParentPrecedence(node)) {
      return true;
    }
    // special case for '-'
    var parent = node.parent;
    if (init is PrefixExpression && parent is PrefixExpression) {
      if (parent.operator.type == TokenType.MINUS) {
        var initializerOperator = init.operator.type;
        if (initializerOperator == TokenType.MINUS ||
            initializerOperator == TokenType.MINUS_MINUS) {
          return true;
        }
      }
    }
    // no () is needed
    return false;
  }
}
