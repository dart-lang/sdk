// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/type_system.dart';

import '../../../protocol_server.dart' show CompletionSuggestion;

/// A contributor for calculating suggestions based on the members of
/// extensions.
class ExtensionMemberContributor extends DartCompletionContributor {
  MemberSuggestionBuilder builder;

  @override
  Future<List<CompletionSuggestion>> computeSuggestions(
      DartCompletionRequest request) async {
    LibraryElement containingLibrary = request.libraryElement;
    // Gracefully degrade if the library element is not resolved
    // e.g. detached part file or source change
    if (containingLibrary == null) {
      return const <CompletionSuggestion>[];
    }

    // Recompute the target since resolution may have changed it.
    Expression expression = request.dotTarget;
    if (expression == null || expression.isSynthetic) {
      return const <CompletionSuggestion>[];
    }
    if (expression is Identifier) {
      Element elem = expression.staticElement;
      if (elem is ClassElement) {
        // Suggestions provided by StaticMemberContributor
        return const <CompletionSuggestion>[];
      }
      if (elem is PrefixElement) {
        // Suggestions provided by LibraryMemberContributor
        return const <CompletionSuggestion>[];
      }
    }
    builder = MemberSuggestionBuilder(containingLibrary);
    if (expression is ExtensionOverride) {
      _addInstanceMembers(expression.staticElement);
    } else {
      var type = expression.staticType;
      LibraryScope nameScope = new LibraryScope(containingLibrary);
      for (var extension in nameScope.extensions) {
        var typeSystem = containingLibrary.context.typeSystem;
        var typeProvider = containingLibrary.context.typeProvider;
        var extendedType =
            _resolveExtendedType(typeSystem, typeProvider, extension, type);
        if (typeSystem.isSubtypeOf(type, extendedType)) {
          // TODO(brianwilkerson) We might want to apply the substitution to the
          //  members of the extension for display purposes.
          _addInstanceMembers(extension);
        }
      }
      expression.staticType;
    }
    return builder.suggestions.toList();
  }

  void _addInstanceMembers(ExtensionElement extension) {
    for (MethodElement method in extension.methods) {
      if (!method.isStatic) {
        builder.addSuggestion(method);
      }
    }
    for (PropertyAccessorElement accessor in extension.accessors) {
      if (!accessor.isStatic) {
        builder.addSuggestion(accessor);
      }
    }
  }

  /// Use the [typeProvider], [typeSystem] and the [type] of the object being
  /// extended to compute the actual type extended by the [extension]. Return
  /// the computed type, or `null` if the type cannot be computed.
  DartType _resolveExtendedType(TypeSystem typeSystem,
      TypeProvider typeProvider, ExtensionElement extension, DartType type) {
    var typeParameters = extension.typeParameters;
    var inferrer = GenericInferrer(
      typeProvider,
      typeSystem,
      typeParameters,
    );
    inferrer.constrainArgument(
      type,
      extension.extendedType,
      'extendedType',
    );
    var typeArguments = inferrer.infer(typeParameters, failAtError: true);
    if (typeArguments == null) {
      return null;
    }
    var substitution = Substitution.fromPairs(
      typeParameters,
      typeArguments,
    );
    return substitution.substituteType(
      extension.extendedType,
    );
  }
}
