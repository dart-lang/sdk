// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart'
    show CompletionSuggestionKind;
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analysis_server/src/utilities/extensions/element.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

/// A contributor that produces suggestions based on the members of an
/// extension.
class ExtensionMemberContributor extends DartCompletionContributor {
  late final memberBuilder = MemberSuggestionBuilder(request, builder);

  ExtensionMemberContributor(
    DartCompletionRequest request,
    SuggestionBuilder builder,
  ) : super(request, builder);

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

      var classOrMixin = request.target.containingNode
          .thisOrAncestorOfType<ClassOrMixinDeclaration>();
      if (classOrMixin != null) {
        var type = classOrMixin.declaredElement?.thisType;
        if (type != null) {
          _addExtensionMembers(extensions, defaultKind, type);
        }
      } else {
        var extension = request.target.containingNode
            .thisOrAncestorOfType<ExtensionDeclaration>();
        if (extension != null) {
          var extendedType = extension.extendedType.type;
          if (extendedType is InterfaceType) {
            var types = [extendedType, ...extendedType.allSupertypes];
            for (var type in types) {
              var inheritanceDistance = memberBuilder.request.featureComputer
                  .inheritanceDistanceFeature(
                      extendedType.element, type.element);
              _addTypeMembers(type, defaultKind, inheritanceDistance);
            }
            _addExtensionMembers(extensions, defaultKind, extendedType);
          }
        }
      }
      return;
    }

    if (expression.isSynthetic) {
      return;
    }
    if (expression is Identifier) {
      var elem = expression.staticElement;
      if (elem is ClassElement) {
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
      var staticElement = expression.staticElement;
      if (staticElement != null) {
        _addInstanceMembers(staticElement, defaultKind, 0.0);
      }
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
  Future<void> computeSuggestions() async {
    addExtensions(
      request.libraryElement.accessibleExtensions,
    );
  }

  void _addExtensionMembers(List<ExtensionElement> extensions,
      CompletionSuggestionKind? kind, DartType type) {
    var containingLibrary = request.libraryElement;
    var typeSystem = containingLibrary.typeSystem;
    for (var extension in extensions) {
      var extendedType =
          extension.resolvedExtendedType(containingLibrary, type);
      if (extendedType != null && typeSystem.isSubtypeOf(type, extendedType)) {
        var inheritanceDistance = 0.0;
        if (type is InterfaceType && extendedType is InterfaceType) {
          inheritanceDistance = memberBuilder.request.featureComputer
              .inheritanceDistanceFeature(type.element, extendedType.element);
        }
        // TODO(brianwilkerson) We might want to apply the substitution to the
        //  members of the extension for display purposes.
        _addInstanceMembers(extension, kind, inheritanceDistance);
      }
    }
  }

  void _addInstanceMembers(ExtensionElement extension,
      CompletionSuggestionKind? kind, double inheritanceDistance) {
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

  void _addTypeMembers(InterfaceType type, CompletionSuggestionKind? kind,
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
