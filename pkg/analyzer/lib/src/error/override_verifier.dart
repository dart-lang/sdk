// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/error/codes.dart';

/// Instances of the class `OverrideVerifier` visit all of the declarations in a
/// compilation unit to verify that if they have an override annotation it is
/// being used correctly.
class OverrideVerifier extends RecursiveAstVisitor {
  /// The inheritance manager used to find overridden methods.
  final InheritanceManager3 _inheritance;

  /// The URI of the library being verified.
  final Uri _libraryUri;

  /// The error reporter used to report errors.
  final ErrorReporter _errorReporter;

  /// The current class or mixin.
  InterfaceType _currentType;

  OverrideVerifier(
      this._inheritance, LibraryElement library, this._errorReporter)
      : _libraryUri = library.source.uri;

  @override
  visitClassDeclaration(ClassDeclaration node) {
    _currentType = node.declaredElement.thisType;
    super.visitClassDeclaration(node);
    _currentType = null;
  }

  @override
  visitFieldDeclaration(FieldDeclaration node) {
    for (VariableDeclaration field in node.fields.variables) {
      FieldElement fieldElement = field.declaredElement;
      if (fieldElement.hasOverride) {
        PropertyAccessorElement getter = fieldElement.getter;
        if (getter != null && _isOverride(getter)) continue;

        PropertyAccessorElement setter = fieldElement.setter;
        if (setter != null && _isOverride(setter)) continue;

        _errorReporter.reportErrorForNode(
          HintCode.OVERRIDE_ON_NON_OVERRIDING_FIELD,
          field.name,
        );
      }
    }
  }

  @override
  visitMethodDeclaration(MethodDeclaration node) {
    ExecutableElement element = node.declaredElement;
    if (element.hasOverride && !_isOverride(element)) {
      if (element is MethodElement) {
        _errorReporter.reportErrorForNode(
          HintCode.OVERRIDE_ON_NON_OVERRIDING_METHOD,
          node.name,
        );
      } else if (element is PropertyAccessorElement) {
        if (element.isGetter) {
          _errorReporter.reportErrorForNode(
            HintCode.OVERRIDE_ON_NON_OVERRIDING_GETTER,
            node.name,
          );
        } else {
          _errorReporter.reportErrorForNode(
            HintCode.OVERRIDE_ON_NON_OVERRIDING_SETTER,
            node.name,
          );
        }
      }
    }
  }

  @override
  visitMixinDeclaration(MixinDeclaration node) {
    _currentType = node.declaredElement.thisType;
    super.visitMixinDeclaration(node);
    _currentType = null;
  }

  /// Return `true` if the [member] overrides a member from a superinterface.
  bool _isOverride(ExecutableElement member) {
    var name = Name(_libraryUri, member.name);
    return _inheritance.getOverridden(_currentType, name) != null;
  }
}
