// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart' hide Element;
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server/src/services/refactoring/legacy/refactoring.dart';
import 'package:analysis_server/src/services/refactoring/legacy/refactoring_internal.dart';
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
  final CorrectionUtils utils;

  _InitialState? _initialState;

  InlineLocalRefactoringImpl(this.searchEngine, this.resolveResult, this.offset)
      : utils = CorrectionUtils(resolveResult);

  @override
  String get refactoringName => 'Inline Local Variable';

  @override
  int get referenceCount {
    return _initialState?.references.length ?? 0;
  }

  @override
  String? get variableName {
    return _initialState?.element.name;
  }

  @override
  Future<RefactoringStatus> checkFinalConditions() {
    var result = RefactoringStatus();
    return Future.value(result);
  }

  @override
  Future<RefactoringStatus> checkInitialConditions() async {
    // prepare variable
    Element? element;
    var offsetNode = NodeLocator(offset).searchWithin(resolveResult.unit);
    if (offsetNode is SimpleIdentifier) {
      element = offsetNode.staticElement;
    } else if (offsetNode is VariableDeclaration) {
      element = offsetNode.declaredElement;
    }

    if (element is! LocalVariableElement) {
      return _noLocalVariableStatus();
    }

    var helper = AnalysisSessionHelper(resolveResult.session);
    var declarationResult = await helper.getElementDeclaration(element);
    var node = declarationResult?.node;
    if (node is! VariableDeclaration) {
      return _noLocalVariableStatus();
    }
    // validate node declaration
    var declarationStatement = _declarationStatement(node);
    if (declarationStatement == null) {
      return _noLocalVariableStatus();
    }
    // should have initializer at declaration
    var initializer = node.initializer;
    if (initializer == null) {
      var message = format(
        "Local variable '{0}' is not initialized at declaration.",
        element.displayName,
      );
      return RefactoringStatus.fatal(
        message,
        newLocation_fromNode(node),
      );
    }
    // prepare references
    var references = await searchEngine.searchReferences(element);
    // should not have assignments
    for (var reference in references) {
      if (reference.kind != MatchKind.READ) {
        var message = format(
          "Local variable '{0}' is assigned more than once.",
          [element.displayName],
        );
        return RefactoringStatus.fatal(
          message,
          newLocation_fromMatch(reference),
        );
      }
    }
    // done
    _initialState = _InitialState(
      element: element,
      node: node,
      initializer: initializer,
      declarationStatement: declarationStatement,
      references: references,
    );
    return RefactoringStatus();
  }

  @override
  Future<SourceChange> createChange() {
    var change = SourceChange(refactoringName);
    var unitElement = resolveResult.unit.declaredElement!;
    var state = _initialState!;
    // remove declaration
    {
      var range = utils.getLinesRangeStatements([state.declarationStatement]);
      doSourceChange_addElementEdit(
          change, unitElement, newSourceEdit_range(range, ''));
    }
    // prepare initializer
    var initializer = state.initializer;
    var initializerCode = utils.getNodeText(initializer);
    // replace references
    for (var reference in state.references) {
      var editRange = reference.sourceRange;
      // prepare context
      var offset = editRange.offset;
      var node = utils.findNode(offset)!;
      var parent = node.parent;
      // prepare code
      String codeForReference;
      if (parent is InterpolationExpression) {
        var target = parent.parent;
        if (target is StringInterpolation &&
            initializer is SingleStringLiteral &&
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
      doSourceChange_addElementEdit(change, unitElement,
          newSourceEdit_range(editRange, codeForReference));
    }
    // done
    return Future.value(change);
  }

  @override
  bool isAvailable() {
    return !_checkOffset().hasFatalError;
  }

  /// Checks if [offset] is a variable that can be inlined.
  RefactoringStatus _checkOffset() {
    Element? element;
    var offsetNode = NodeLocator(offset).searchWithin(resolveResult.unit);
    if (offsetNode is SimpleIdentifier) {
      element = offsetNode.staticElement;
    } else if (offsetNode is VariableDeclaration) {
      element = offsetNode.declaredElement;
    }

    if (element is! LocalVariableElement) {
      return _noLocalVariableStatus();
    }

    return RefactoringStatus();
  }

  RefactoringStatus _noLocalVariableStatus() {
    return RefactoringStatus.fatal(
      'Local variable declaration or reference must be selected '
      'to activate this refactoring.',
    );
  }

  static VariableDeclarationStatement? _declarationStatement(
    VariableDeclaration declaration,
  ) {
    var declarationList = declaration.parent;
    if (declarationList is VariableDeclarationList) {
      var statement = declarationList.parent;
      if (statement is VariableDeclarationStatement) {
        var parent = statement.parent;
        if (parent is Block ||
            parent is SwitchCase ||
            parent is SwitchPatternCase) {
          return statement;
        }
      }
    }
    return null;
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

class _InitialState {
  final LocalVariableElement element;
  final VariableDeclaration node;
  final Expression initializer;
  final VariableDeclarationStatement declarationStatement;
  final List<SearchMatch> references;

  _InitialState({
    required this.element,
    required this.node,
    required this.initializer,
    required this.declarationStatement,
    required this.references,
  });
}
