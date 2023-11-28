// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart'
    show CompletionSuggestionKind;
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analysis_server/src/services/completion/dart/visibility_tracker.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:analyzer_plugin/src/utilities/completion/completion_target.dart';

/// A contributor that produces suggestions based on the declarations in the
/// local file and containing library.  This contributor also produces
/// suggestions based on the instance members from the supertypes of a given
/// type. More concretely, this class produces suggestions for places where an
/// inherited instance member might be invoked via an implicit target of `this`.
class LocalReferenceContributor extends DartCompletionContributor {
  /// The builder used to build some suggestions.
  late MemberSuggestionBuilder memberBuilder;

  /// The kind of suggestion to make.
  late CompletionSuggestionKind classMemberSuggestionKind;

  /// The [_VisibilityTracker] tracks the set of elements already added in the
  /// completion list, this object helps prevents suggesting elements that have
  /// been shadowed by local declarations.
  VisibilityTracker visibilityTracker = VisibilityTracker();

  LocalReferenceContributor(super.request, super.builder);

  @override
  Future<void> computeSuggestions({
    required OperationPerformanceImpl performance,
  }) async {
    // The remaining logic is for the inherited references.
    if (request.includeIdentifiers) {
      var member = _enclosingMember(request.target);
      if (member != null) {
        var enclosingNode = member.parent;
        if (enclosingNode is ClassDeclaration) {
          _addForInterface(enclosingNode.declaredElement!);
        } else if (enclosingNode is MixinDeclaration) {
          _addForInterface(enclosingNode.declaredElement!);
        }
      }
    }
  }

  void _addForInterface(InterfaceElement interface) {
    memberBuilder = MemberSuggestionBuilder(request, builder);
    _computeSuggestionsForClass(interface);
  }

  void _addSuggestionsForType(InterfaceType type, double inheritanceDistance,
      {bool isFunctionalArgument = false}) {
    var opType = request.opType;
    if (!isFunctionalArgument) {
      for (var accessor in type.accessors) {
        if (!accessor.isStatic) {
          if (visibilityTracker.isVisible(accessor.declaration)) {
            if (accessor.isGetter) {
              if (opType.includeReturnValueSuggestions) {
                memberBuilder.addSuggestionForAccessor(
                    accessor: accessor,
                    inheritanceDistance: inheritanceDistance);
              }
            } else {
              if (opType.includeVoidReturnSuggestions) {
                memberBuilder.addSuggestionForAccessor(
                    accessor: accessor,
                    inheritanceDistance: inheritanceDistance);
              }
            }
          }
        }
      }
    }
    for (var method in type.methods) {
      if (!method.isStatic) {
        if (visibilityTracker.isVisible(method.declaration)) {
          if (method.returnType is! VoidType) {
            if (opType.includeReturnValueSuggestions) {
              memberBuilder.addSuggestionForMethod(
                  method: method,
                  inheritanceDistance: inheritanceDistance,
                  kind: classMemberSuggestionKind);
            }
          } else {
            if (opType.includeVoidReturnSuggestions) {
              memberBuilder.addSuggestionForMethod(
                  method: method,
                  inheritanceDistance: inheritanceDistance,
                  kind: classMemberSuggestionKind);
            }
          }
        }
      }
    }
  }

  void _computeSuggestionsForClass(InterfaceElement interface) {
    var isFunctionalArgument = request.target.isFunctionalArgument();
    classMemberSuggestionKind = isFunctionalArgument
        ? CompletionSuggestionKind.IDENTIFIER
        : CompletionSuggestionKind.INVOCATION;
    for (var type in interface.allSupertypes) {
      var inheritanceDistance = request.featureComputer
          .inheritanceDistanceFeature(interface, type.element);
      _addSuggestionsForType(type, inheritanceDistance,
          isFunctionalArgument: isFunctionalArgument);
    }
  }

  /// Return the class member containing the target or `null` if the target is
  /// in a static method or static field or not in a class member.
  ClassMember? _enclosingMember(CompletionTarget target) {
    AstNode? node = target.containingNode;
    while (node != null) {
      if (node is MethodDeclaration) {
        if (!node.isStatic) {
          return node;
        }
      } else if (node is FieldDeclaration) {
        if (!node.isStatic) {
          return node;
        }
      } else if (node is ConstructorDeclaration) {
        return node;
      }
      node = node.parent;
    }
    return null;
  }
}
