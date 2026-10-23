// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/error/listener.dart';

/// Instances of the class `OverrideVerifier` visit all of the declarations in a
/// compilation unit to verify that if they have an override annotation it is
/// being used correctly.
class OverrideVerifier extends RecursiveAstVisitor2<void> {
  /// The error reporter used to report errors.
  final DiagnosticReporter _errorReporter;

  /// The current class or mixin.
  InterfaceElement? _currentClass;

  new(this._errorReporter);

  @override
  void visitClassDeclaration2(ClassDeclaration2 node) {
    _currentClass = node.declaredFragment?.element;
    super.visitClassDeclaration2(node);
    _currentClass = null;
  }

  @override
  void visitEnumDeclaration2(EnumDeclaration2 node) {
    _currentClass = node.declaredFragment?.element;
    super.visitEnumDeclaration2(node);
    _currentClass = null;
  }

  @override
  void visitFieldsDeclaration(FieldsDeclaration node) {
    for (var field in node.fields) {
      var fieldElement = field.declaredFragment!.element;
      if (fieldElement.metadata.hasOverride) {
        _checkField(fieldElement, field.name);
      }
    }
    super.visitFieldsDeclaration(node);
  }

  @override
  void visitGetterDeclaration(covariant GetterDeclarationImpl node) {
    _visitMethodDeclaration(node, () => super.visitGetterDeclaration(node));
  }

  @override
  void visitMethodDeclaration2(covariant MethodDeclaration2Impl node) {
    _visitMethodDeclaration(node, () => super.visitMethodDeclaration2(node));
  }

  @override
  void visitMixinDeclaration2(MixinDeclaration2 node) {
    _currentClass = node.declaredFragment?.element;
    super.visitMixinDeclaration2(node);
    _currentClass = null;
  }

  @override
  void visitOperatorDeclaration(covariant OperatorDeclarationImpl node) {
    _visitMethodDeclaration(node, () => super.visitOperatorDeclaration(node));
  }

  @override
  void visitPrimaryConstructorDeclaration(PrimaryConstructorDeclaration node) {
    for (var parameter in node.formalParameters.allFormalParameters) {
      var element = parameter.declaredFragment?.element;
      if (element is! FieldFormalParameterElement) continue;
      if (!element.metadata.hasOverride) continue;
      if (!element.isDeclaring) continue;

      var fieldElement = element.field;
      if (fieldElement == null) continue;
      _checkField(fieldElement, parameter.name!);
    }
  }

  @override
  void visitSetterDeclaration(covariant SetterDeclarationImpl node) {
    _visitMethodDeclaration(node, () => super.visitSetterDeclaration(node));
  }

  @override
  void visitTopLevelGetterDeclaration(TopLevelGetterDeclaration node) {
    var element = node.declaredFragment!.element;
    if (element.metadata.hasOverride) {
      _errorReporter.report(diag.overrideOnNonOverridingGetter.at(node.name));
    }
    super.visitTopLevelGetterDeclaration(node);
  }

  @override
  void visitTopLevelSetterDeclaration(TopLevelSetterDeclaration node) {
    var element = node.declaredFragment!.element;
    if (element.metadata.hasOverride) {
      _errorReporter.report(diag.overrideOnNonOverridingSetter.at(node.name));
    }
    super.visitTopLevelSetterDeclaration(node);
  }

  void _checkField(FieldElement fieldElement, Token errorNode) {
    var getter = fieldElement.getter;
    if (getter != null && _isOverride(getter)) return;

    var setter = fieldElement.setter;
    if (setter != null && _isOverride(setter)) return;

    _errorReporter.report(diag.overrideOnNonOverridingField.at(errorNode));
  }

  /// Returns whether the [member] overrides a member from a superinterface.
  bool _isOverride(ExecutableElement member) {
    var currentClass = _currentClass?.firstFragment;
    if (currentClass == null) {
      return false;
    }

    var name = Name.forElement(member);

    // We get `null` if the element does not have name.
    // This was already a parse error, avoid the warning.
    if (name == null) {
      return true;
    }

    return currentClass.element.getOverridden(name) != null;
  }

  void _visitMethodDeclaration(
    MethodDeclarationV1OriginImpl node,
    void Function() visitSuper,
  ) {
    var element = node.declaredFragment!.element;
    if (element.metadata.hasOverride && !_isOverride(element)) {
      switch (element) {
        case MethodElement():
          _errorReporter.report(
            diag.overrideOnNonOverridingMethod.at(node.nameToken),
          );
        case GetterElement():
          _errorReporter.report(
            diag.overrideOnNonOverridingGetter.at(node.nameToken),
          );
        case SetterElement():
          _errorReporter.report(
            diag.overrideOnNonOverridingSetter.at(node.nameToken),
          );
      }
    }
    visitSuper();
  }
}
