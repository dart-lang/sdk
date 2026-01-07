// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:meta/meta.dart';

/// Checks whether a declaration violates the rules of [immutable].
class ImmutableVerifier extends SimpleAstVisitor<void> {
  final DiagnosticReporter _diagnosticReporter;

  ImmutableVerifier(this._diagnosticReporter);

  /// Checks whether [node] violates the rules of [immutable].
  ///
  /// If [node] is marked with [immutable] or inherits from a class or mixin
  /// marked with [immutable], this function searches the fields of [node] and
  /// its superclasses, reporting a warning if any non-final instance fields are
  /// found.
  void checkDeclaration(
    CompilationUnitMember node, {
    required Token nameToken,
  }) {
    var element = node.declaredFragment!.element as InterfaceElement;
    if (!_isOrInheritsImmutable(element, HashSet<InterfaceElement>())) {
      return;
    }

    Iterable<String> nonFinalFieldNames =
        _declaredAndInheritedNonFinalInstanceFields(
          element,
          HashSet<InterfaceElement>(),
        );
    if (nonFinalFieldNames.isNotEmpty) {
      _diagnosticReporter.atToken(
        nameToken,
        diag.mustBeImmutable,
        arguments: [nonFinalFieldNames.join(', ')],
      );
    }
  }

  /// Returns all of the declared and ihherited non-final instance fields of
  /// [element].
  ///
  /// [visited] is used to avoid visiting supertypes multiple times.
  static Iterable<String> _declaredAndInheritedNonFinalInstanceFields(
    InterfaceElement element,
    Set<InterfaceElement> visited,
  ) {
    if (!visited.add(element)) {
      // Already checked `element`.
      return const [];
    }
    return [
      ...element.nonFinalInstanceFieldNames,
      ...element.mixins.expand(
        (mixin) => mixin.element.nonFinalInstanceFieldNames,
      ),
      if (element.supertype case var supertype?)
        ..._declaredAndInheritedNonFinalInstanceFields(
          supertype.element,
          visited,
        ),
    ];
  }

  /// Returns whether the given class [element] or any superclass of it is
  /// annotated with the `@immutable` annotation.
  static bool _isOrInheritsImmutable(
    InterfaceElement element,
    Set<InterfaceElement> visited,
  ) {
    if (visited.add(element)) {
      if (element.metadata.hasImmutable) {
        return true;
      }
      for (InterfaceType interface in element.mixins) {
        if (_isOrInheritsImmutable(interface.element, visited)) {
          return true;
        }
      }
      for (InterfaceType mixin in element.interfaces) {
        if (_isOrInheritsImmutable(mixin.element, visited)) {
          return true;
        }
      }
      if (element.supertype != null) {
        return _isOrInheritsImmutable(element.supertype!.element, visited);
      }
    }
    return false;
  }
}

extension on InterfaceElement {
  List<String> get nonFinalInstanceFieldNames {
    var nonFinalFields = fields
        .where((f) => !f.isStatic && !f.isFinal && !f.isOriginGetterSetter)
        .toList();
    if (nonFinalFields.isEmpty) {
      return const [];
    }
    return List.generate(nonFinalFields.length, (i) {
      var field = nonFinalFields[i];
      return '$name.${field.name}';
    });
  }
}
