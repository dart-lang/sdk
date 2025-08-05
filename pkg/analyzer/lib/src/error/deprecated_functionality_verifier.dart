// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
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
    _checkForDeprecatedImplement(node.implementsClause);
  }

  void classTypeAlias(ClassTypeAlias node) {
    _checkForDeprecatedExtend(node.superclass);
    _checkForDeprecatedImplement(node.implementsClause);
  }

  void enumDeclaration(EnumDeclaration node) {
    _checkForDeprecatedImplement(node.implementsClause);
  }

  void _checkForDeprecatedExtend(NamedType? node) {
    if (node == null) return;
    var element = node.element;
    if (element == null) return;
    if (node.type?.element is InterfaceElement) {
      if (element.library == _currentLibrary) return;
      if (element.hasDeprecatedWithField('_isExtend')) {
        _diagnosticReporter.atNode(
          node,
          WarningCode.DEPRECATED_EXTEND,
          arguments: [element.name!],
        );
      }
    }
  }

  void _checkForDeprecatedImplement(ImplementsClause? node) {
    if (node == null) return;
    var interfaces = node.interfaces;
    for (var interface in interfaces) {
      var element = interface.element;
      if (element == null) continue;
      if (interface.type?.element is InterfaceElement) {
        if (element.library == _currentLibrary) continue;
        if (element.hasDeprecatedWithField('_isImplement')) {
          _diagnosticReporter.atNode(
            interface,
            WarningCode.DEPRECATED_IMPLEMENT,
            arguments: [element.name!],
          );
        }
      }
    }
  }
}

extension on Element {
  /// Whether this Element is annotated with a `Deprecated` annotation with a
  /// `true` value for [fieldName].
  bool hasDeprecatedWithField(String fieldName) {
    return metadata.annotations.where((e) => e.isDeprecated).any((annotation) {
      var value = annotation.computeConstantValue();
      return value?.getField(fieldName)?.toBoolValue() ?? false;
    });
  }
}
