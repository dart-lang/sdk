// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart'
    show CompletionSuggestionKind;
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/resolver/applicable_extensions.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';

/// A contributor that produces suggestions based on the members of an
/// extension.
class ExtensionMemberContributor extends DartCompletionContributor {
  late final memberBuilder = MemberSuggestionBuilder(request, builder);

  ExtensionMemberContributor(super.request, super.builder);

  void addExtensions(List<ExtensionElement> extensions) {
    var containingLibrary = request.libraryElement;

    var defaultKind = request.target.isFunctionalArgument()
        ? CompletionSuggestionKind.IDENTIFIER
        : request.opType.suggestKind;

    // Recompute the target because resolution might have changed it.
    var expression = request.target.dotTarget;

    if (expression == null) {
      if (!request.includeIdentifiers) {
        return;
      }

      var thisClassType = request.target.enclosingInterfaceElement?.thisType;
      if (thisClassType != null) {
        _addExtensionMembers(extensions, defaultKind, thisClassType);
      } else {
        var thisExtendedType =
            request.target.enclosingExtensionElement?.extendedType;
        if (thisExtendedType is InterfaceType) {
          var types = [thisExtendedType, ...thisExtendedType.allSupertypes];
          for (var type in types) {
            var inheritanceDistance = memberBuilder.request.featureComputer
                .inheritanceDistanceFeature(
                    thisExtendedType.element, type.element);
            _addTypeMembers(type, defaultKind, inheritanceDistance);
          }
          _addExtensionMembers(extensions, defaultKind, thisExtendedType);
        }
        // TODO(scheglov) It seems that we don't support non-interface types.
      }
      return;
    }

    if (expression.isSynthetic) {
      return;
    }
    if (expression is Identifier) {
      var elem = expression.staticElement;
      if (elem is InterfaceElement) {
        // Suggestions provided by StaticMemberContributor.
        return;
      } else if (elem is ExtensionElement) {
        // Suggestions provided by StaticMemberContributor.
        return;
      } else if (elem is PrefixElement) {
        // Suggestions provided by LibraryMemberContributor.
        return;
      }
    }
    if (expression is ExtensionOverride) {
      _addInstanceMembers(expression.element, defaultKind, 0.0);
    } else {
      var type = expression.staticType;
      if (type == null) {
        // Without a type we can't find the extensions that apply. We shouldn't
        // get to this point, but there's an NPE if we invoke
        // `resolvedExtendedType` when `type` is `null`, so we guard against it
        // to ensure that we can return the suggestions from other providers.
        return;
      }
      var containingNode = request.target.containingNode;
      if (containingNode is PropertyAccess &&
          containingNode.operator.lexeme == '?.') {
        // After a null-safe operator we know that the member will only be
        // invoked on a non-null value.
        type = containingLibrary.typeSystem.promoteToNonNull(type);
      }
      _addExtensionMembers(extensions, defaultKind, type);
      expression.staticType;
    }
  }

  @override
  Future<void> computeSuggestions({
    required OperationPerformanceImpl performance,
  }) async {
    addExtensions(
      request.libraryElement.accessibleExtensions,
    );
  }

  void _addExtensionMembers(List<ExtensionElement> extensions,
      CompletionSuggestionKind kind, DartType type) {
    var applicableExtensions = extensions.applicableTo(
      targetLibrary: request.libraryElement,
      targetType: type,
    );
    for (var instantiatedExtension in applicableExtensions) {
      var extendedType = instantiatedExtension.extendedType;
      var inheritanceDistance = 0.0;
      if (type is InterfaceType && extendedType is InterfaceType) {
        inheritanceDistance = memberBuilder.request.featureComputer
            .inheritanceDistanceFeature(type.element, extendedType.element);
      }
      // TODO(brianwilkerson) We might want to apply the substitution to the
      //  members of the extension for display purposes.
      _addInstanceMembers(
          instantiatedExtension.extension, kind, inheritanceDistance);
    }
  }

  void _addInstanceMembers(ExtensionElement extension,
      CompletionSuggestionKind kind, double inheritanceDistance) {
    for (var method in extension.methods) {
      if (!method.isStatic) {
        memberBuilder.addSuggestionForMethod(
            method: method,
            kind: kind,
            inheritanceDistance: inheritanceDistance);
      }
    }
    for (var accessor in extension.accessors) {
      if (!accessor.isStatic) {
        memberBuilder.addSuggestionForAccessor(
            accessor: accessor, inheritanceDistance: inheritanceDistance);
      }
    }
  }

  void _addTypeMembers(InterfaceType type, CompletionSuggestionKind kind,
      double inheritanceDistance) {
    for (var method in type.methods) {
      memberBuilder.addSuggestionForMethod(
          method: method, kind: kind, inheritanceDistance: inheritanceDistance);
    }
    for (var accessor in type.accessors) {
      memberBuilder.addSuggestionForAccessor(
          accessor: accessor, inheritanceDistance: inheritanceDistance);
    }
  }
}
