// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/extensions.dart';
import 'package:analyzer/src/error/codes.dart';

class DeprecatedFunctionalityVerifier {
  final DiagnosticReporter _diagnosticReporter;

  final LibraryElement _currentLibrary;

  DeprecatedFunctionalityVerifier(
    this._diagnosticReporter,
    this._currentLibrary,
  );

  void classDeclaration(ClassDeclaration node) {
    _checkForDeprecatedExtend(node.extendsClause?.superclass);
    _checkForDeprecatedImplement(node.implementsClause?.interfaces);
    _checkForDeprecatedMixin(node.withClause);
    _checkForDeprecatedSubclass(node.withClause?.mixinTypes);
  }

  void classTypeAlias(ClassTypeAlias node) {
    _checkForDeprecatedExtend(node.superclass);
    _checkForDeprecatedImplement(node.implementsClause?.interfaces);
    _checkForDeprecatedMixin(node.withClause);
  }

  void constructorName(ConstructorName node) {
    var classElement = node.type.element;
    if (classElement == null) return;
    if (classElement.isDeprecatedWithKind('instantiate')) {
      _diagnosticReporter.atNode(
        node,
        WarningCode.deprecatedInstantiate,
        arguments: [classElement.name!],
      );
    }
  }

  void enumDeclaration(EnumDeclaration node) {
    _checkForDeprecatedImplement(node.implementsClause?.interfaces);
    _checkForDeprecatedMixin(node.withClause);
  }

  void mixinDeclaration(MixinDeclaration node) {
    _checkForDeprecatedImplement(node.implementsClause?.interfaces);
    // Not technically "implementing," but is similar enough for
    // `@Deprecated.implement` and `@Deprecated.subclass`.
    _checkForDeprecatedImplement(node.onClause?.superclassConstraints);
  }

  void _checkForDeprecatedExtend(NamedType? node) {
    if (node == null) return;
    var element = node.element;
    if (element == null) return;
    if (node.type?.element is InterfaceElement) {
      if (element.library == _currentLibrary) return;
      if (element.isDeprecatedWithKind('extend')) {
        _diagnosticReporter.atNode(
          node,
          WarningCode.deprecatedExtend,
          arguments: [element.name!],
        );
      } else if (element.isDeprecatedWithKind('subclass')) {
        _diagnosticReporter.atNode(
          node,
          WarningCode.deprecatedSubclass,
          arguments: [element.name!],
        );
      }
    }
  }

  void _checkForDeprecatedImplement(List<NamedType>? namedTypes) {
    if (namedTypes == null) return;
    for (var namedType in namedTypes) {
      var element = namedType.element;
      if (element == null) continue;
      if (element.library == _currentLibrary) continue;
      if (namedType.type?.element is InterfaceElement) {
        if (element.isDeprecatedWithKind('implement')) {
          _diagnosticReporter.atNode(
            namedType,
            WarningCode.deprecatedImplement,
            arguments: [element.name!],
          );
        } else if (element.isDeprecatedWithKind('subclass')) {
          _diagnosticReporter.atNode(
            namedType,
            WarningCode.deprecatedSubclass,
            arguments: [element.name!],
          );
        }
      }
    }
  }

  void _checkForDeprecatedMixin(WithClause? node) {
    if (node == null) return;
    for (var mixin in node.mixinTypes) {
      var element = mixin.type?.element;
      if (element is! InterfaceElement) continue;
      if (element.library == _currentLibrary) continue;
      if (element.isDeprecatedWithKind('mixin')) {
        _diagnosticReporter.atNode(
          mixin,
          WarningCode.deprecatedMixin,
          arguments: [element.name!],
        );
      }
    }
  }

  void _checkForDeprecatedSubclass(List<NamedType>? namedTypes) {
    if (namedTypes == null) return;
    for (var namedType in namedTypes) {
      var element = namedType.element;
      if (element == null) continue;
      if (element.library == _currentLibrary) continue;
      if (namedType.type?.element is InterfaceElement) {
        if (element.isDeprecatedWithKind('subclass')) {
          _diagnosticReporter.atNode(
            namedType,
            WarningCode.deprecatedSubclass,
            arguments: [element.name!],
          );
        }
      }
    }
  }
}
