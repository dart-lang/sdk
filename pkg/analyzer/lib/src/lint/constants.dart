// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/dart/constant/compute.dart';
import 'package:analyzer/src/dart/constant/constant_verifier.dart';
import 'package:analyzer/src/dart/constant/evaluation.dart';
import 'package:analyzer/src/dart/constant/potentially_constant.dart';
import 'package:analyzer/src/dart/constant/utilities.dart';
import 'package:analyzer/src/error/codes.dart';

/// A diagnostic listener that only records whether any constant-related
/// diagnostics have been reported.
class _ConstantDiagnosticListener extends DiagnosticListener {
  /// A flag indicating whether any constant-related diagnostics have been
  /// reported to this listener.
  bool hasConstError = false;

  @override
  void onDiagnostic(Diagnostic diagnostic) {
    DiagnosticCode diagnosticCode = diagnostic.diagnosticCode;
    if (diagnosticCode is CompileTimeErrorCode) {
      switch (diagnosticCode) {
        case CompileTimeErrorCode.constConstructorConstantFromDeferredLibrary:
        case CompileTimeErrorCode
            .constConstructorWithFieldInitializedByNonConst:
        case CompileTimeErrorCode.constEvalExtensionMethod:
        case CompileTimeErrorCode.constEvalExtensionTypeMethod:
        case CompileTimeErrorCode.constEvalMethodInvocation:
        case CompileTimeErrorCode.constEvalPropertyAccess:
        case CompileTimeErrorCode.constEvalTypeBool:
        case CompileTimeErrorCode.constEvalTypeBoolInt:
        case CompileTimeErrorCode.constEvalTypeBoolNumString:
        case CompileTimeErrorCode.constEvalTypeInt:
        case CompileTimeErrorCode.constEvalTypeNum:
        case CompileTimeErrorCode.constEvalTypeNumString:
        case CompileTimeErrorCode.constEvalTypeString:
        case CompileTimeErrorCode.constEvalThrowsException:
        case CompileTimeErrorCode.constEvalThrowsIdbze:
        case CompileTimeErrorCode.constEvalForElement:
        case CompileTimeErrorCode.constMapKeyNotPrimitiveEquality:
        case CompileTimeErrorCode.constSetElementNotPrimitiveEquality:
        case CompileTimeErrorCode.constTypeParameter:
        case CompileTimeErrorCode.constWithNonConst:
        case CompileTimeErrorCode.constWithNonConstantArgument:
        case CompileTimeErrorCode.constWithTypeParameters:
        case CompileTimeErrorCode.constWithTypeParametersConstructorTearoff:
        case CompileTimeErrorCode.invalidConstant:
        case CompileTimeErrorCode.missingConstInListLiteral:
        case CompileTimeErrorCode.missingConstInMapLiteral:
        case CompileTimeErrorCode.missingConstInSetLiteral:
        case CompileTimeErrorCode.nonBoolCondition:
        case CompileTimeErrorCode.nonConstantListElement:
        case CompileTimeErrorCode.nonConstantMapElement:
        case CompileTimeErrorCode.nonConstantMapKey:
        case CompileTimeErrorCode.nonConstantMapValue:
        case CompileTimeErrorCode.nonConstantRecordField:
        case CompileTimeErrorCode.nonConstantSetElement:
          hasConstError = true;
      }
    }
  }
}

extension AstNodeExtension on AstNode {
  /// Whether [ConstantVerifier] reports an error when computing the value of
  /// `this` as a constant.
  bool get hasConstantVerifierError {
    var unitNode = thisOrAncestorOfType<CompilationUnitImpl>();
    var unitFragment = unitNode?.declaredFragment;
    if (unitFragment == null) return false;

    var libraryElement = unitFragment.element;
    var declaredVariables = libraryElement.session.declaredVariables;

    var dependenciesFinder = ConstantExpressionsDependenciesFinder();
    accept(dependenciesFinder);
    computeConstants(
      declaredVariables: declaredVariables,
      constants: dependenciesFinder.dependencies.toList(),
      featureSet: libraryElement.featureSet,
      configuration: ConstantEvaluationConfiguration(),
    );

    var listener = _ConstantDiagnosticListener();
    var errorReporter = DiagnosticReporter(listener, unitFragment.source);

    accept(ConstantVerifier(errorReporter, libraryElement, declaredVariables));
    return listener.hasConstError;
  }
}

extension ConstructorDeclarationExtension on ConstructorDeclaration {
  bool get canBeConst {
    var element = declaredFragment!.element;

    var classElement = element.enclosingElement;
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
