// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/error/codes.dart';

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

        _errorReporter.atToken(
          field.name,
          WarningCode.overrideOnNonOverridingField,
        );
      }
    }
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    var element = node.declaredFragment!.element;
    if (element.metadata.hasOverride && !_isOverride(element)) {
      switch (element) {
        case MethodElement():
          _errorReporter.atToken(
            node.name,
            WarningCode.overrideOnNonOverridingMethod,
          );
        case GetterElement():
          _errorReporter.atToken(
            node.name,
            WarningCode.overrideOnNonOverridingGetter,
          );
        case SetterElement():
          _errorReporter.atToken(
            node.name,
            WarningCode.overrideOnNonOverridingSetter,
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
    if (currentClass != null) {
      var name = Name.forElement(member)!;
      return currentClass.element.getOverridden(name) != null;
    } else {
      return false;
    }
  }
}
