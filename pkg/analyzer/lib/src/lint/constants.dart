// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/dart/constant/compute.dart';
import 'package:analyzer/src/dart/constant/constant_verifier.dart';
import 'package:analyzer/src/dart/constant/evaluation.dart';
import 'package:analyzer/src/dart/constant/potentially_constant.dart';
import 'package:analyzer/src/dart/constant/utilities.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/utilities/extensions/ast.dart';

/// Whether an instance field initializer in [members] has an invalid named
/// read.
///
/// A const constructor requires these initializers to be constant, but they
/// are not in the constructor, so [AstNodeExtension.hasConstantVerifierError]
/// of the constructor does not check them for invalid named reads.
bool _hasInvalidNamedReadInFieldInitializers(List<AnnotatedNode> members) {
  for (var member in members) {
    if (member is FieldDeclaration && !member.isStatic) {
      for (var variable in member.fields.variables) {
        if (variable.initializer2?._hasInvalidNamedRead ?? false) {
          return true;
        }
      }
    }
  }
  return false;
}

/// A diagnostic listener that only records whether any constant-related
/// diagnostics have been reported.
class _ConstantDiagnosticListener extends DiagnosticListener {
  /// A flag indicating whether any constant-related diagnostics have been
  /// reported to this listener.
  bool hasConstError = false;

  @override
  void onDiagnostic(Diagnostic diagnostic) {
    DiagnosticCode diagnosticCode = diagnostic.diagnosticCode;
    switch (diagnosticCode) {
      case diag.constConstructorConstantFromDeferredLibrary:
      case diag.constConstructorWithFieldInitializedByNonConst:
      case diag.constEvalExtensionMethod:
      case diag.constEvalExtensionTypeMethod:
      case diag.constEvalMethodInvocation:
      case diag.constEvalPropertyAccess:
      case diag.constEvalTypeBool:
      case diag.constEvalTypeBoolInt:
      case diag.constEvalTypeBoolNumString:
      case diag.constEvalTypeInt:
      case diag.constEvalTypeNum:
      case diag.constEvalTypeNumString:
      case diag.constEvalTypeString:
      case diag.constEvalThrowsException:
      case diag.constEvalThrowsIdbze:
      case diag.constEvalForElement:
      case diag.constMapKeyNotPrimitiveEquality:
      case diag.constSetElementNotPrimitiveEquality:
      case diag.constTypeParameter:
      case diag.constWithNonConst:
      case diag.constWithNonConstantArgument:
      case diag.constWithTypeParameters:
      case diag.constWithTypeParametersConstructorTearoff:
      case diag.invalidConstant:
      case diag.missingConstInListLiteral:
      case diag.missingConstInMapLiteral:
      case diag.missingConstInSetLiteral:
      case diag.nonBoolCondition:
      case diag.nonConstantListElement:
      case diag.nonConstantMapElement:
      case diag.nonConstantMapKey:
      case diag.nonConstantMapValue:
      case diag.nonConstantRecordField:
      case diag.nonConstantSetElement:
        hasConstError = true;
    }
  }
}

/// Finds whether a node has an invalid named read.
class _InvalidNamedReadFinder extends UnifyingAstVisitor2<void> {
  bool found = false;

  @override
  void visitNode(AstNode node) {
    if (found) return;
    if (node is Expression && node.isInvalidNamedRead) {
      found = true;
      return;
    }
    node.visitChildren2(this);
  }
}

extension AstNodeExtension on AstNode {
  /// Whether `this` is not valid as a constant.
  ///
  /// It is not when `this` has an invalid named read, such as an undefined
  /// name, or when [ConstantVerifier] reports an error when computing the
  /// value of `this` as a constant. [ConstantVerifier] does not report invalid
  /// named reads, because resolution has already reported them, but they are
  /// still not constant.
  bool get hasConstantVerifierError {
    if (_hasInvalidNamedRead) return true;

    var unitNode = thisOrAncestorOfType2<CompilationUnitImpl>();
    var unitFragment = unitNode?.declaredFragment;
    if (unitFragment == null) return false;

    var libraryElement = unitFragment.element;
    var declaredVariables = libraryElement.session.declaredVariables;

    var dependenciesFinder = ConstantExpressionsDependenciesFinder();
    accept2(dependenciesFinder);
    computeConstants(
      declaredVariables: declaredVariables,
      constants: dependenciesFinder.dependencies.toList(),
      featureSet: libraryElement.featureSet,
      configuration: ConstantEvaluationConfiguration(),
    );

    var listener = _ConstantDiagnosticListener();
    var errorReporter = DiagnosticReporter(listener, unitFragment.source);

    accept2(ConstantVerifier(errorReporter, libraryElement, declaredVariables));
    return listener.hasConstError;
  }

  bool get _hasInvalidNamedRead {
    var finder = _InvalidNamedReadFinder();
    accept2(finder);
    return finder.found;
  }
}

extension ConstructorDeclarationExtension on ConstructorDeclaration {
  bool get canBeConst {
    var element = declaredFragment!.element;

    var classElement = element.enclosingElement;
    if (classElement is ClassElement && classElement.hasNonFinalField) {
      return false;
    }

    var self = this as ConstructorDeclarationImpl;
    if (_hasInvalidNamedReadInFieldInitializers(self.parent2.classMembers2)) {
      return false;
    }

    var oldKeyword = constKeyword;
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

extension PrimaryConstructorDeclarationExtension
    on PrimaryConstructorDeclaration {
  bool get canBeConst {
    var element = declaredFragment!.element;

    var classElement = element.enclosingElement;
    if (classElement is ClassElement && classElement.hasNonFinalField) {
      return false;
    }

    var self = this as PrimaryConstructorDeclarationImpl;
    if (_hasInvalidNamedReadInFieldInitializers(self.parent2.classMembers2)) {
      return false;
    }

    var oldKeyword = constKeyword;
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
