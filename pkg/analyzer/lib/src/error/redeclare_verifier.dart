// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/error/codes.dart';

/// Instances of the class `RedeclareVerifier` visit all of the members of any
/// extension type declarations in a compilation unit to verify that if they
/// have a redeclare annotation it is being used correctly.
class RedeclareVerifier extends RecursiveAstVisitor<void> {
  /// The error reporter used to report errors.
  final DiagnosticReporter _errorReporter;

  /// The current extension type.
  InterfaceElement? _currentExtensionType;

  RedeclareVerifier(this._errorReporter);

  @override
  void visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) {
    _currentExtensionType = node.declaredFragment!.element;
    super.visitExtensionTypeDeclaration(node);
    _currentExtensionType = null;
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    // Only check if we're in an extension type declaration.
    if (_currentExtensionType == null) return;

    var element = node.declaredFragment!.element;

    // Static members can't redeclare.
    if (element.isStatic) return;

    if (element.metadata.hasRedeclare && !_redeclaresMember(element)) {
      switch (element) {
        case MethodElement():
          _errorReporter.atToken(
            node.name,
            WarningCode.redeclareOnNonRedeclaringMember,
            arguments: ['method'],
          );
        case GetterElement():
          _errorReporter.atToken(
            node.name,
            WarningCode.redeclareOnNonRedeclaringMember,
            arguments: ['getter'],
          );
        case SetterElement():
          _errorReporter.atToken(
            node.name,
            WarningCode.redeclareOnNonRedeclaringMember,
            arguments: ['setter'],
          );
      }
    }
  }

  /// Return `true` if the [member] redeclares a member from a superinterface.
  bool _redeclaresMember(ExecutableElement member) {
    var currentType = _currentExtensionType;
    if (currentType != null) {
      var name = Name.forElement(member);
      return name != null && currentType.getInheritedMember(name) != null;
    }

    return false;
  }
}
