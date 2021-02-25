// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/generic_inferrer.dart'
    show GenericInferrer;
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';

/// A contributor that produces suggestions based on the members of an
/// extension.
class ExtensionMemberContributor extends DartCompletionContributor {
  MemberSuggestionBuilder memberBuilder;

  @override
  Future<void> computeSuggestions(
      DartCompletionRequest request, SuggestionBuilder builder) async {
    var containingLibrary = request.libraryElement;
    // Gracefully degrade if the library could not be determined, such as with a
    // detached part file or source change.
    if (containingLibrary == null) {
      return;
    }

    memberBuilder = MemberSuggestionBuilder(request, builder);

    // Recompute the target because resolution might have changed it.
    var expression = request.dotTarget;

    if (expression == null) {
      var classOrMixin = request.target.containingNode
          .thisOrAncestorOfType<ClassOrMixinDeclaration>();
      if (classOrMixin != null) {
        var type = classOrMixin.declaredElement.thisType;
        _addExtensionMembers(containingLibrary, type);
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
              _addTypeMembers(type, inheritanceDistance);
            }
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
      _addInstanceMembers(expression.staticElement, -1.0);
    } else {
      var type = expression.staticType;
      if (type == null) {
        // Without a type we can't find the extensions that apply. We shouldn't
        // get to this point, but there's an NPE if we invoke
        // `_resolveExtendedType` when `type` is `null`, so we guard against it
        // to ensure that we can return the suggestions from other providers.
        return;
      }
      _addExtensionMembers(containingLibrary, type);
      expression.staticType;
    }
  }

  void _addExtensionMembers(LibraryElement containingLibrary, DartType type) {
    var typeSystem = containingLibrary.typeSystem;
    var nameScope = containingLibrary.scope;
    for (var extension in nameScope.extensions) {
      var extendedType =
          _resolveExtendedType(containingLibrary, extension, type);
      if (extendedType != null && typeSystem.isSubtypeOf(type, extendedType)) {
        double inheritanceDistance;
        if (type is InterfaceType && extendedType is InterfaceType) {
          inheritanceDistance = memberBuilder.request.featureComputer
              .inheritanceDistanceFeature(type.element, extendedType.element);
        } else {
          inheritanceDistance = -1;
        }
        // TODO(brianwilkerson) We might want to apply the substitution to the
        //  members of the extension for display purposes.
        _addInstanceMembers(extension, inheritanceDistance);
      }
    }
  }

  void _addInstanceMembers(
      ExtensionElement extension, double inheritanceDistance) {
    for (var method in extension.methods) {
      if (!method.isStatic) {
        memberBuilder.addSuggestionForMethod(
            method: method, inheritanceDistance: inheritanceDistance);
      }
    }
    for (var accessor in extension.accessors) {
      if (!accessor.isStatic) {
        memberBuilder.addSuggestionForAccessor(
            accessor: accessor, inheritanceDistance: inheritanceDistance);
      }
    }
  }

  void _addTypeMembers(InterfaceType type, double inheritanceDistance) {
    for (var method in type.methods) {
      memberBuilder.addSuggestionForMethod(
          method: method, inheritanceDistance: inheritanceDistance);
    }
    for (var accessor in type.accessors) {
      memberBuilder.addSuggestionForAccessor(
          accessor: accessor, inheritanceDistance: inheritanceDistance);
    }
  }

  /// Use the [type] of the object being extended in the [library] to compute
  /// the actual type extended by the [extension]. Return the computed type,
  /// or `null` if the type cannot be computed.
  DartType _resolveExtendedType(
    LibraryElement library,
    ExtensionElement extension,
    DartType type,
  ) {
    var typeParameters = extension.typeParameters;
    var inferrer = GenericInferrer(library.typeSystem, typeParameters);
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
