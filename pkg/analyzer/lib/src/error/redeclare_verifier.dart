// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/error/codes.dart';

/// Instances of the class `RedeclareVerifier` visit all of the members of any
/// extension type declarations in a compilation unit to verify that if they
/// have a redeclare annotation it is being used correctly.
class RedeclareVerifier extends RecursiveAstVisitor<void> {
  /// The inheritance manager used to find redeclared members.
  final InheritanceManager3 _inheritance;

  /// The error reporter used to report errors.
  final ErrorReporter _errorReporter;

  /// The current extension type.
  InterfaceElement2? _currentExtensionType;

  RedeclareVerifier(this._inheritance, this._errorReporter);

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

    if (element.metadata2.hasRedeclare && !_redeclaresMember(element)) {
      switch (element) {
        case MethodElement2():
          _errorReporter.atToken(
            node.name,
            WarningCode.REDECLARE_ON_NON_REDECLARING_MEMBER,
            arguments: [
              'method',
            ],
          );
        case GetterElement():
          _errorReporter.atToken(
            node.name,
            WarningCode.REDECLARE_ON_NON_REDECLARING_MEMBER,
            arguments: [
              'getter',
            ],
          );
        case SetterElement():
          _errorReporter.atToken(
            node.name,
            WarningCode.REDECLARE_ON_NON_REDECLARING_MEMBER,
            arguments: [
              'setter',
            ],
          );
      }
    }
  }

  /// Return `true` if the [member] redeclares a member from a superinterface.
  bool _redeclaresMember(ExecutableElement2 member) {
    var currentType = _currentExtensionType;
    if (currentType != null) {
      var interface = _inheritance.getInterface2(currentType);
      var redeclared = interface.redeclared2;
      var name = Name.forElement(member);
      return redeclared.containsKey(name);
    }

    return false;
  }
}
