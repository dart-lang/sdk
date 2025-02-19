// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/error/codes.dart';

/// Instances of the class `OverrideVerifier` visit all of the declarations in a
/// compilation unit to verify that if they have an override annotation it is
/// being used correctly.
class OverrideVerifier extends RecursiveAstVisitor<void> {
  /// The inheritance manager used to find overridden methods.
  final InheritanceManager3 _inheritance;

  /// The error reporter used to report errors.
  final ErrorReporter _errorReporter;

  /// The current class or mixin.
  InterfaceElement2? _currentClass;

  OverrideVerifier(this._inheritance, this._errorReporter);

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
      var fieldElement = field.declaredFragment?.element as FieldElement2;
      if (fieldElement.metadata2.hasOverride) {
        var getter = fieldElement.getter2;
        if (getter != null && _isOverride(getter)) continue;

        var setter = fieldElement.setter2;
        if (setter != null && _isOverride(setter)) continue;

        _errorReporter.atToken(
          field.name,
          WarningCode.OVERRIDE_ON_NON_OVERRIDING_FIELD,
        );
      }
    }
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    var element = node.declaredFragment!.element;
    if (element.metadata2.hasOverride && !_isOverride(element)) {
      if (element is MethodElement2) {
        _errorReporter.atToken(
          node.name,
          WarningCode.OVERRIDE_ON_NON_OVERRIDING_METHOD,
        );
      } else if (element is PropertyAccessorElement2) {
        if (element is GetterElement) {
          _errorReporter.atToken(
            node.name,
            WarningCode.OVERRIDE_ON_NON_OVERRIDING_GETTER,
          );
        } else {
          _errorReporter.atToken(
            node.name,
            WarningCode.OVERRIDE_ON_NON_OVERRIDING_SETTER,
          );
        }
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
  bool _isOverride(ExecutableElement2 member) {
    var currentClass = _currentClass?.firstFragment;
    if (currentClass != null) {
      var name = Name.forElement(member)!;
      return _inheritance.getOverridden4(currentClass.element, name) != null;
    } else {
      return false;
    }
  }
}
