// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/error/listener.dart';

/// Instances of the class `OverrideVerifier` visit all of the declarations in a
/// compilation unit to verify that if they have an override annotation it is
/// being used correctly.
class OverrideVerifier extends RecursiveAstVisitor<void> {
  /// The error reporter used to report errors.
  final DiagnosticReporter _errorReporter;

  /// The current class or mixin.
  InterfaceElement? _currentClass;

  OverrideVerifier(this._errorReporter);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    _currentClass = node.declaredFragment?.element;
    super.visitClassDeclaration(node);
    _currentClass = null;
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    _currentClass = node.declaredFragment?.element;
    super.visitEnumDeclaration(node);
    _currentClass = null;
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    for (VariableDeclaration field in node.fields.variables) {
      var fieldElement = field.declaredFragment?.element as FieldElement;
      if (fieldElement.metadata.hasOverride) {
        _checkField(fieldElement, field.name);
      }
    }
    super.visitFieldDeclaration(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    var element = node.declaredFragment!.element;
    if (element.metadata.hasOverride) {
      switch (element) {
        case GetterElement():
          _errorReporter.report(
            diag.overrideOnNonOverridingGetter.at(node.name),
          );
        case SetterElement():
          _errorReporter.report(
            diag.overrideOnNonOverridingSetter.at(node.name),
          );
      }
    }
    super.visitFunctionDeclaration(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    var element = node.declaredFragment!.element;
    if (element.metadata.hasOverride && !_isOverride(element)) {
      switch (element) {
        case MethodElement():
          _errorReporter.report(
            diag.overrideOnNonOverridingMethod.at(node.name),
          );
        case GetterElement():
          _errorReporter.report(
            diag.overrideOnNonOverridingGetter.at(node.name),
          );
        case SetterElement():
          _errorReporter.report(
            diag.overrideOnNonOverridingSetter.at(node.name),
          );
      }
    }
    super.visitMethodDeclaration(node);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    _currentClass = node.declaredFragment?.element;
    super.visitMixinDeclaration(node);
    _currentClass = null;
  }

  @override
  void visitPrimaryConstructorDeclaration(PrimaryConstructorDeclaration node) {
    for (var parameter in node.formalParameters.parameters) {
      var element = parameter.declaredFragment?.element;
      if (element is! FieldFormalParameterElement) continue;
      if (!element.metadata.hasOverride) continue;
      if (!element.isDeclaring) continue;

      var fieldElement = element.field;
      if (fieldElement == null) continue;
      _checkField(fieldElement, parameter.name!);
    }
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
}
