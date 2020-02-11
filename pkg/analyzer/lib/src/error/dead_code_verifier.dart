// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/resolver/exit_detector.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/type_system.dart';
import 'package:analyzer/src/task/strong/checker.dart';

/// A visitor that finds dead code and unused labels.
class DeadCodeVerifier extends RecursiveAstVisitor<void> {
  /// The error reporter by which errors will be reported.
  final ErrorReporter _errorReporter;

  ///  The type system for this visitor
  final TypeSystemImpl _typeSystem;

  /// The object used to track the usage of labels within a given label scope.
  _LabelTracker labelTracker;

  /// Is `true` if the library being analyzed is non-nullable by default.
  final bool _isNonNullableByDefault;

  /// Initialize a newly created dead code verifier that will report dead code
  /// to the given [errorReporter] and will use the given [typeSystem] if one is
  /// provided.
  DeadCodeVerifier(this._errorReporter, FeatureSet featureSet,
      {TypeSystemImpl typeSystem})
      : this._typeSystem = typeSystem ??
            TypeSystemImpl(
              implicitCasts: true,
              isNonNullableByDefault: false,
              strictInference: false,
              typeProvider: null,
            ),
        _isNonNullableByDefault = featureSet.isEnabled(Feature.non_nullable);

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    TokenType operatorType = node.operator.type;
    if (operatorType == TokenType.QUESTION_QUESTION_EQ) {
      _checkForDeadNullCoalesce(
          getReadType(node.leftHandSide), node.rightHandSide);
    }
    super.visitAssignmentExpression(node);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    Token operator = node.operator;
    bool isAmpAmp = operator.type == TokenType.AMPERSAND_AMPERSAND;
    bool isBarBar = operator.type == TokenType.BAR_BAR;
    bool isQuestionQuestion = operator.type == TokenType.QUESTION_QUESTION;
    if (isAmpAmp || isBarBar) {
      Expression lhsCondition = node.leftOperand;
      if (!_isDebugConstant(lhsCondition)) {
        EvaluationResultImpl lhsResult = _getConstantBooleanValue(lhsCondition);
        if (lhsResult != null) {
          bool value = lhsResult.value.toBoolValue();
          if (value == true && isBarBar) {
            // Report error on "else" block: true || !e!
            _errorReporter.reportErrorForNode(
                HintCode.DEAD_CODE, node.rightOperand);
            // Only visit the LHS:
            lhsCondition?.accept(this);
            return;
          } else if (value == false && isAmpAmp) {
            // Report error on "if" block: false && !e!
            _errorReporter.reportErrorForNode(
                HintCode.DEAD_CODE, node.rightOperand);
            // Only visit the LHS:
            lhsCondition?.accept(this);
            return;
          }
        }
      }
      // How do we want to handle the RHS? It isn't dead code, but "pointless"
      // or "obscure"...
//            Expression rhsCondition = node.getRightOperand();
//            ValidResult rhsResult = getConstantBooleanValue(rhsCondition);
//            if (rhsResult != null) {
//              if (rhsResult == ValidResult.RESULT_TRUE && isBarBar) {
//                // report error on else block: !e! || true
//                errorReporter.reportError(HintCode.DEAD_CODE, node.getRightOperand());
//                // only visit the RHS:
//                rhsCondition?.accept(this);
//                return null;
//              } else if (rhsResult == ValidResult.RESULT_FALSE && isAmpAmp) {
//                // report error on if block: !e! && false
//                errorReporter.reportError(HintCode.DEAD_CODE, node.getRightOperand());
//                // only visit the RHS:
//                rhsCondition?.accept(this);
//                return null;
//              }
//            }
    } else if (isQuestionQuestion) {
      _checkForDeadNullCoalesce(
          getReadType(node.leftOperand), node.rightOperand);
    }
    super.visitBinaryExpression(node);
  }

  /// For each block, this method reports and error on all statements between
  /// the end of the block and the first return statement (assuming there it is
  /// not at the end of the block.)
  @override
  void visitBlock(Block node) {
    NodeList<Statement> statements = node.statements;
    _checkForDeadStatementsInNodeList(statements);
  }

  @override
  void visitBreakStatement(BreakStatement node) {
    labelTracker?.recordUsage(node.label?.name);
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    Expression conditionExpression = node.condition;
    conditionExpression?.accept(this);
    if (!_isDebugConstant(conditionExpression)) {
      EvaluationResultImpl result =
          _getConstantBooleanValue(conditionExpression);
      if (result != null) {
        if (result.value.toBoolValue() == true) {
          // Report error on "else" block: true ? 1 : !2!
          _errorReporter.reportErrorForNode(
              HintCode.DEAD_CODE, node.elseExpression);
          node.thenExpression?.accept(this);
          return;
        } else {
          // Report error on "if" block: false ? !1! : 2
          _errorReporter.reportErrorForNode(
              HintCode.DEAD_CODE, node.thenExpression);
          node.elseExpression?.accept(this);
          return;
        }
      }
    }
    super.visitConditionalExpression(node);
  }

  @override
  void visitContinueStatement(ContinueStatement node) {
    labelTracker?.recordUsage(node.label?.name);
  }

  @override
  void visitExportDirective(ExportDirective node) {
    ExportElement exportElement = node.element;
    if (exportElement != null) {
      // The element is null when the URI is invalid.
      LibraryElement library = exportElement.exportedLibrary;
      if (library != null && !library.isSynthetic) {
        for (Combinator combinator in node.combinators) {
          _checkCombinator(library, combinator);
        }
      }
    }
    super.visitExportDirective(node);
  }

  @override
  void visitIfElement(IfElement node) {
    Expression conditionExpression = node.condition;
    conditionExpression?.accept(this);
    if (!_isDebugConstant(conditionExpression)) {
      EvaluationResultImpl result =
          _getConstantBooleanValue(conditionExpression);
      if (result != null) {
        if (result.value.toBoolValue() == true) {
          // Report error on else block: if(true) {} else {!}
          CollectionElement elseElement = node.elseElement;
          if (elseElement != null) {
            _errorReporter.reportErrorForNode(HintCode.DEAD_CODE, elseElement);
            node.thenElement?.accept(this);
            return;
          }
        } else {
          // Report error on if block: if (false) {!} else {}
          _errorReporter.reportErrorForNode(
              HintCode.DEAD_CODE, node.thenElement);
          node.elseElement?.accept(this);
          return;
        }
      }
    }
    super.visitIfElement(node);
  }

  @override
  void visitIfStatement(IfStatement node) {
    Expression conditionExpression = node.condition;
    conditionExpression?.accept(this);
    if (!_isDebugConstant(conditionExpression)) {
      EvaluationResultImpl result =
          _getConstantBooleanValue(conditionExpression);
      if (result != null) {
        if (result.value.toBoolValue() == true) {
          // Report error on else block: if(true) {} else {!}
          Statement elseStatement = node.elseStatement;
          if (elseStatement != null) {
            _errorReporter.reportErrorForNode(
                HintCode.DEAD_CODE, elseStatement);
            node.thenStatement?.accept(this);
            return;
          }
        } else {
          // Report error on if block: if (false) {!} else {}
          _errorReporter.reportErrorForNode(
              HintCode.DEAD_CODE, node.thenStatement);
          node.elseStatement?.accept(this);
          return;
        }
      }
    }
    super.visitIfStatement(node);
  }

  @override
  void visitImportDirective(ImportDirective node) {
    ImportElement importElement = node.element;
    if (importElement != null) {
      // The element is null when the URI is invalid, but not when the URI is
      // valid but refers to a non-existent file.
      LibraryElement library = importElement.importedLibrary;
      if (library != null && !library.isSynthetic) {
        for (Combinator combinator in node.combinators) {
          _checkCombinator(library, combinator);
        }
      }
    }
    super.visitImportDirective(node);
  }

  @override
  void visitLabeledStatement(LabeledStatement node) {
    _pushLabels(node.labels);
    try {
      super.visitLabeledStatement(node);
    } finally {
      _popLabels();
    }
  }

  @override
  void visitSwitchCase(SwitchCase node) {
    _checkForDeadStatementsInNodeList(node.statements, allowMandated: true);
    super.visitSwitchCase(node);
  }

  @override
  void visitSwitchDefault(SwitchDefault node) {
    _checkForDeadStatementsInNodeList(node.statements, allowMandated: true);
    super.visitSwitchDefault(node);
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    List<Label> labels = <Label>[];
    for (SwitchMember member in node.members) {
      labels.addAll(member.labels);
    }
    _pushLabels(labels);
    try {
      super.visitSwitchStatement(node);
    } finally {
      _popLabels();
    }
  }

  @override
  void visitTryStatement(TryStatement node) {
    node.body?.accept(this);
    node.finallyBlock?.accept(this);
    NodeList<CatchClause> catchClauses = node.catchClauses;
    int numOfCatchClauses = catchClauses.length;
    List<DartType> visitedTypes = <DartType>[];
    for (int i = 0; i < numOfCatchClauses; i++) {
      CatchClause catchClause = catchClauses[i];
      if (catchClause.onKeyword != null) {
        // An on-catch clause was found; verify that the exception type is not a
        // subtype of a previous on-catch exception type.
        DartType currentType = catchClause.exceptionType?.type;
        if (currentType != null) {
          if (currentType.isObject) {
            // Found catch clause clause that has Object as an exception type,
            // this is equivalent to having a catch clause that doesn't have an
            // exception type, visit the block, but generate an error on any
            // following catch clauses (and don't visit them).
            catchClause?.accept(this);
            if (i + 1 != numOfCatchClauses) {
              // This catch clause is not the last in the try statement.
              CatchClause nextCatchClause = catchClauses[i + 1];
              CatchClause lastCatchClause = catchClauses[numOfCatchClauses - 1];
              int offset = nextCatchClause.offset;
              int length = lastCatchClause.end - offset;
              _errorReporter.reportErrorForOffset(
                  HintCode.DEAD_CODE_CATCH_FOLLOWING_CATCH, offset, length);
              return;
            }
          }
          int length = visitedTypes.length;
          for (int j = 0; j < length; j++) {
            DartType type = visitedTypes[j];
            if (_typeSystem.isSubtypeOf2(currentType, type)) {
              CatchClause lastCatchClause = catchClauses[numOfCatchClauses - 1];
              int offset = catchClause.offset;
              int length = lastCatchClause.end - offset;
              _errorReporter.reportErrorForOffset(
                  HintCode.DEAD_CODE_ON_CATCH_SUBTYPE,
                  offset,
                  length,
                  [currentType, type]);
              return;
            }
          }
          visitedTypes.add(currentType);
        }
        catchClause?.accept(this);
      } else {
        // Found catch clause clause that doesn't have an exception type,
        // visit the block, but generate an error on any following catch clauses
        // (and don't visit them).
        catchClause?.accept(this);
        if (i + 1 != numOfCatchClauses) {
          // This catch clause is not the last in the try statement.
          CatchClause nextCatchClause = catchClauses[i + 1];
          CatchClause lastCatchClause = catchClauses[numOfCatchClauses - 1];
          int offset = nextCatchClause.offset;
          int length = lastCatchClause.end - offset;
          _errorReporter.reportErrorForOffset(
              HintCode.DEAD_CODE_CATCH_FOLLOWING_CATCH, offset, length);
          return;
        }
      }
    }
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    Expression conditionExpression = node.condition;
    conditionExpression?.accept(this);
    if (!_isDebugConstant(conditionExpression)) {
      EvaluationResultImpl result =
          _getConstantBooleanValue(conditionExpression);
      if (result != null) {
        if (result.value.toBoolValue() == false) {
          // Report error on while block: while (false) {!}
          _errorReporter.reportErrorForNode(HintCode.DEAD_CODE, node.body);
          return;
        }
      }
    }
    node.body?.accept(this);
  }

  /// Resolve the names in the given [combinator] in the scope of the given
  /// [library].
  void _checkCombinator(LibraryElement library, Combinator combinator) {
    Namespace namespace =
        NamespaceBuilder().createExportNamespaceForLibrary(library);
    NodeList<SimpleIdentifier> names;
    ErrorCode hintCode;
    if (combinator is HideCombinator) {
      names = combinator.hiddenNames;
      hintCode = HintCode.UNDEFINED_HIDDEN_NAME;
    } else {
      names = (combinator as ShowCombinator).shownNames;
      hintCode = HintCode.UNDEFINED_SHOWN_NAME;
    }
    for (SimpleIdentifier name in names) {
      String nameStr = name.name;
      Element element = namespace.get(nameStr);
      if (element == null) {
        element = namespace.get("$nameStr=");
      }
      if (element == null) {
        _errorReporter
            .reportErrorForNode(hintCode, name, [library.identifier, nameStr]);
      }
    }
  }

  void _checkForDeadNullCoalesce(TypeImpl lhsType, Expression rhs) {
    if (!_isNonNullableByDefault) return;

    if (_typeSystem.isStrictlyNonNullable(lhsType)) {
      _errorReporter.reportErrorForNode(
        StaticWarningCode.DEAD_NULL_COALESCE,
        rhs,
      );
    }
  }

  /// Given some list of [statements], loop through the list searching for dead
  /// statements. If [allowMandated] is true, then allow dead statements that
  /// are mandated by the language spec. This allows for a final break,
  /// continue, return, or throw statement at the end of a switch case, that are
  /// mandated by the language spec.
  void _checkForDeadStatementsInNodeList(NodeList<Statement> statements,
      {bool allowMandated = false}) {
    bool statementExits(Statement statement) {
      if (statement is BreakStatement) {
        return statement.label == null;
      } else if (statement is ContinueStatement) {
        return statement.label == null;
      }
      return ExitDetector.exits(statement);
    }

    int size = statements.length;
    for (int i = 0; i < size; i++) {
      Statement currentStatement = statements[i];
      currentStatement?.accept(this);
      if (statementExits(currentStatement) && i != size - 1) {
        Statement nextStatement = statements[i + 1];
        Statement lastStatement = statements[size - 1];
        // If mandated statements are allowed, and only the last statement is
        // dead, and it's a BreakStatement, then assume it is a statement
        // mandated by the language spec, there to avoid a
        // CASE_BLOCK_NOT_TERMINATED error.
        if (allowMandated && i == size - 2 && nextStatement is BreakStatement) {
          return;
        }
        int offset = nextStatement.offset;
        int length = lastStatement.end - offset;
        _errorReporter.reportErrorForOffset(HintCode.DEAD_CODE, offset, length);
        return;
      }
    }
  }

  /// Given some [expression], return [ValidResult.RESULT_TRUE] if it is `true`,
  /// [ValidResult.RESULT_FALSE] if it is `false`, or `null` if the expression
  /// is not a constant boolean value.
  EvaluationResultImpl _getConstantBooleanValue(Expression expression) {
    if (expression is BooleanLiteral) {
      return EvaluationResultImpl(
        DartObjectImpl(
          _typeSystem,
          _typeSystem.typeProvider.boolType,
          BoolState.from(expression.value),
        ),
      );
    }

    // Don't consider situations where we could evaluate to a constant boolean
    // expression with the ConstantVisitor
    // else {
    // EvaluationResultImpl result = expression.accept(new ConstantVisitor());
    // if (result == ValidResult.RESULT_TRUE) {
    // return ValidResult.RESULT_TRUE;
    // } else if (result == ValidResult.RESULT_FALSE) {
    // return ValidResult.RESULT_FALSE;
    // }
    // return null;
    // }
    return null;
  }

  /// Return `true` if the given [expression] is resolved to a constant
  /// variable.
  bool _isDebugConstant(Expression expression) {
    Element element;
    if (expression is Identifier) {
      element = expression.staticElement;
    } else if (expression is PropertyAccess) {
      element = expression.propertyName.staticElement;
    }
    if (element is PropertyAccessorElement) {
      PropertyInducingElement variable = element.variable;
      return variable != null && variable.isConst;
    }
    return false;
  }

  /// Exit the most recently entered label scope after reporting any labels that
  /// were not referenced within that scope.
  void _popLabels() {
    for (Label label in labelTracker.unusedLabels()) {
      _errorReporter
          .reportErrorForNode(HintCode.UNUSED_LABEL, label, [label.label.name]);
    }
    labelTracker = labelTracker.outerTracker;
  }

  /// Enter a new label scope in which the given [labels] are defined.
  void _pushLabels(List<Label> labels) {
    labelTracker = _LabelTracker(labelTracker, labels);
  }
}

/// An object used to track the usage of labels within a single label scope.
class _LabelTracker {
  /// The tracker for the outer label scope.
  final _LabelTracker outerTracker;

  /// The labels whose usage is being tracked.
  final List<Label> labels;

  /// A list of flags corresponding to the list of [labels] indicating whether
  /// the corresponding label has been used.
  List<bool> used;

  /// A map from the names of labels to the index of the label in [labels].
  final Map<String, int> labelMap = <String, int>{};

  /// Initialize a newly created label tracker.
  _LabelTracker(this.outerTracker, this.labels) {
    used = List.filled(labels.length, false);
    for (int i = 0; i < labels.length; i++) {
      labelMap[labels[i].label.name] = i;
    }
  }

  /// Record that the label with the given [labelName] has been used.
  void recordUsage(String labelName) {
    if (labelName != null) {
      int index = labelMap[labelName];
      if (index != null) {
        used[index] = true;
      } else if (outerTracker != null) {
        outerTracker.recordUsage(labelName);
      }
    }
  }

  /// Return the unused labels.
  Iterable<Label> unusedLabels() sync* {
    for (int i = 0; i < labels.length; i++) {
      if (!used[i]) {
        yield labels[i];
      }
    }
  }
}
