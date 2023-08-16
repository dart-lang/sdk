// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/error/codes.dart';

/// Instances of the class `RedeclareVerifier` visit all of the members of any
/// extension type declarations in a compilation unit to verify that if they
/// have a redeclare annotation it is being used correctly.
class RedeclareVerifier extends RecursiveAstVisitor<void> {
  /// The inheritance manager used to find redeclared members.
  final InheritanceManager3 _inheritance;

  /// The URI of the library being verified.
  final Uri _libraryUri;

  /// The error reporter used to report errors.
  final ErrorReporter _errorReporter;

  /// The current extension type.
  InterfaceElement? _currentExtensionType;

  RedeclareVerifier(
      this._inheritance, LibraryElement library, this._errorReporter)
      : _libraryUri = library.source.uri;

  @override
  void visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) {
    _currentExtensionType = node.declaredElement;
    super.visitExtensionTypeDeclaration(node);
    _currentExtensionType = null;
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    // Only check if we're in an extension type declaration.
    if (_currentExtensionType == null) return;

    var element = node.declaredElement!;

    // Static members can't redeclare.
    if (element.isStatic) return;

    if (element.hasRedeclare && !_redeclaresMember(element)) {
      if (element is MethodElement) {
        _errorReporter.reportErrorForToken(
          WarningCode.REDECLARE_ON_NON_REDECLARING_MEMBER,
          node.name,
          [
            'method',
          ],
        );
      } else if (element is PropertyAccessorElement) {
        if (element.isGetter) {
          _errorReporter.reportErrorForToken(
            WarningCode.REDECLARE_ON_NON_REDECLARING_MEMBER,
            node.name,
            [
              'getter',
            ],
          );
        } else {
          _errorReporter.reportErrorForToken(
            WarningCode.REDECLARE_ON_NON_REDECLARING_MEMBER,
            node.name,
            [
              'setter',
            ],
          );
        }
      }
    }
  }

  /// Return `true` if the [member] redeclares a member from a superinterface.
  bool _redeclaresMember(ExecutableElement member) {
    var currentType = _currentExtensionType;
    if (currentType != null) {
      var interface = _inheritance.getInterface(currentType);
      var redeclared = interface.redeclared;
      var name = Name(_libraryUri, member.name);
      return redeclared.containsKey(name);
    }

    return false;
  }
}
