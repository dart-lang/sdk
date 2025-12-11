// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
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
        var getter = fieldElement.getter;
        if (getter != null && _isOverride(getter)) continue;

        var setter = fieldElement.setter;
        if (setter != null && _isOverride(setter)) continue;

        _errorReporter.report(diag.overrideOnNonOverridingField.at(field.name));
      }
    }
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
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    _currentClass = node.declaredFragment?.element;
    super.visitMixinDeclaration(node);
    _currentClass = null;
  }

  /// Return `true` if the [member] overrides a member from a superinterface.
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
