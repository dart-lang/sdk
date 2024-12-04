// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/dart/constant/compute.dart';
import 'package:analyzer/src/dart/constant/constant_verifier.dart';
import 'package:analyzer/src/dart/constant/evaluation.dart';
import 'package:analyzer/src/dart/constant/potentially_constant.dart';
import 'package:analyzer/src/dart/constant/utilities.dart';
import 'package:analyzer/src/dart/constant/value.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/error/codes.dart';

/// The result of attempting to evaluate an expression as a constant.
final class LinterConstantEvaluationResult {
  /// The value of the expression, or `null` if has [errors].
  final DartObject? value;

  /// The errors reported during the evaluation.
  final List<AnalysisError> errors;

  LinterConstantEvaluationResult._(this.value, this.errors);
}

/// An error listener that only records whether any constant related errors have
/// been reported.
class _ConstantAnalysisErrorListener extends AnalysisErrorListener {
  /// A flag indicating whether any constant related errors have been reported
  /// to this listener.
  bool hasConstError = false;

  @override
  void onError(AnalysisError error) {
    ErrorCode errorCode = error.errorCode;
    if (errorCode is CompileTimeErrorCode) {
      switch (errorCode) {
        case CompileTimeErrorCode
              .CONST_CONSTRUCTOR_CONSTANT_FROM_DEFERRED_LIBRARY:
        case CompileTimeErrorCode
              .CONST_CONSTRUCTOR_WITH_FIELD_INITIALIZED_BY_NON_CONST:
        case CompileTimeErrorCode.CONST_EVAL_EXTENSION_METHOD:
        case CompileTimeErrorCode.CONST_EVAL_EXTENSION_TYPE_METHOD:
        case CompileTimeErrorCode.CONST_EVAL_METHOD_INVOCATION:
        case CompileTimeErrorCode.CONST_EVAL_PROPERTY_ACCESS:
        case CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL:
        case CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL_INT:
        case CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL_NUM_STRING:
        case CompileTimeErrorCode.CONST_EVAL_TYPE_INT:
        case CompileTimeErrorCode.CONST_EVAL_TYPE_NUM:
        case CompileTimeErrorCode.CONST_EVAL_TYPE_NUM_STRING:
        case CompileTimeErrorCode.CONST_EVAL_TYPE_STRING:
        case CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION:
        case CompileTimeErrorCode.CONST_EVAL_THROWS_IDBZE:
        case CompileTimeErrorCode.CONST_EVAL_FOR_ELEMENT:
        case CompileTimeErrorCode.CONST_MAP_KEY_NOT_PRIMITIVE_EQUALITY:
        case CompileTimeErrorCode.CONST_SET_ELEMENT_NOT_PRIMITIVE_EQUALITY:
        case CompileTimeErrorCode.CONST_TYPE_PARAMETER:
        case CompileTimeErrorCode.CONST_WITH_NON_CONST:
        case CompileTimeErrorCode.CONST_WITH_NON_CONSTANT_ARGUMENT:
        case CompileTimeErrorCode.CONST_WITH_TYPE_PARAMETERS:
        case CompileTimeErrorCode
              .CONST_WITH_TYPE_PARAMETERS_CONSTRUCTOR_TEAROFF:
        case CompileTimeErrorCode.INVALID_CONSTANT:
        case CompileTimeErrorCode.MISSING_CONST_IN_LIST_LITERAL:
        case CompileTimeErrorCode.MISSING_CONST_IN_MAP_LITERAL:
        case CompileTimeErrorCode.MISSING_CONST_IN_SET_LITERAL:
        case CompileTimeErrorCode.NON_BOOL_CONDITION:
        case CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT:
        case CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT:
        case CompileTimeErrorCode.NON_CONSTANT_MAP_KEY:
        case CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE:
        case CompileTimeErrorCode.NON_CONSTANT_RECORD_FIELD:
        case CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT:
          hasConstError = true;
      }
    }
  }
}

extension on AstNode {
  /// Whether [ConstantVerifier] reports an error when computing the value of
  /// `this` as a constant.
  bool get hasConstantVerifierError {
    var unitElement = thisOrAncestorOfType<CompilationUnit>()?.declaredElement;
    if (unitElement == null) return false;
    var libraryElement = unitElement.library as LibraryElementImpl;

    var dependenciesFinder = ConstantExpressionsDependenciesFinder();
    accept(dependenciesFinder);
    computeConstants(
      declaredVariables: unitElement.session.declaredVariables,
      constants: dependenciesFinder.dependencies.toList(),
      featureSet: libraryElement.featureSet,
      configuration: ConstantEvaluationConfiguration(),
    );

    var listener = _ConstantAnalysisErrorListener();
    var errorReporter = ErrorReporter(listener, unitElement.source);

    accept(
      ConstantVerifier(
        errorReporter,
        libraryElement,
        unitElement.session.declaredVariables,
      ),
    );
    return listener.hasConstError;
  }
}

extension ConstructorDeclarationExtension on ConstructorDeclaration {
  bool get canBeConst {
    var element = declaredElement!;

    var classElement = element.enclosingElement3;
    if (classElement is ClassElement && classElement.hasNonFinalField) {
      return false;
    }

    var oldKeyword = constKeyword;
    var self = this as ConstructorDeclarationImpl;
    try {
      temporaryConstConstructorElements[element] = true;
      self.constKeyword = KeywordToken(Keyword.CONST, offset);
      return !hasConstantVerifierError;
    } finally {
      temporaryConstConstructorElements[element] = null;
      self.constKeyword = oldKeyword;
    }
  }
}

extension ExpressionExtension on Expression {
  /// Whether it would be valid for this expression to have a `const` keyword.
  ///
  /// Note that this method can cause constant evaluation to occur, which can be
  /// computationally expensive.
  bool get canBeConst {
    var self = this;
    return switch (self) {
      InstanceCreationExpressionImpl() => _canBeConstInstanceCreation(self),
      TypedLiteralImpl() => _canBeConstTypedLiteral(self),
      _ => false,
    };
  }

  /// Computes the constant value of `this`, if it has one.
  ///
  /// Returns a [LinterConstantEvaluationResult], containing both the computed
  /// constant value, and a list of errors that occurred during the computation.
  LinterConstantEvaluationResult computeConstantValue() {
    var unitElement = thisOrAncestorOfType<CompilationUnit>()?.declaredElement;
    if (unitElement == null) return LinterConstantEvaluationResult._(null, []);
    var libraryElement = unitElement.library as LibraryElementImpl;

    var errorListener = RecordingErrorListener();

    var evaluationEngine = ConstantEvaluationEngine(
      declaredVariables: unitElement.session.declaredVariables,
      configuration: ConstantEvaluationConfiguration(),
    );

    var dependencies = <ConstantEvaluationTarget>[];
    accept(ReferenceFinder(dependencies.add));

    computeConstants(
      declaredVariables: unitElement.session.declaredVariables,
      constants: dependencies,
      featureSet: libraryElement.featureSet,
      configuration: ConstantEvaluationConfiguration(),
    );

    var visitor = ConstantVisitor(
      evaluationEngine,
      libraryElement,
      ErrorReporter(errorListener, unitElement.source),
    );

    var constant = visitor.evaluateAndReportInvalidConstant(this);
    var dartObject = constant is DartObjectImpl ? constant : null;
    return LinterConstantEvaluationResult._(dartObject, errorListener.errors);
  }

  bool _canBeConstInstanceCreation(InstanceCreationExpressionImpl node) {
    var element = node.constructorName.staticElement;
    if (element == null || !element.isConst) return false;

    // Ensure that dependencies (e.g. default parameter values) are computed.
    var implElement = element.declaration as ConstructorElementImpl;
    implElement.computeConstantDependencies();

    // Verify that the evaluation of the constructor would not produce an
    // exception.
    var oldKeyword = node.keyword;
    try {
      node.keyword = KeywordToken(Keyword.CONST, offset);
      return !hasConstantVerifierError;
    } finally {
      node.keyword = oldKeyword;
    }
  }

  bool _canBeConstTypedLiteral(TypedLiteralImpl node) {
    var oldKeyword = node.constKeyword;
    try {
      node.constKeyword = KeywordToken(Keyword.CONST, offset);
      return !hasConstantVerifierError;
    } finally {
      node.constKeyword = oldKeyword;
    }
  }
}
