// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart'
    show CompletionSuggestionKind;
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analysis_server/src/services/completion/dart/visibility_tracker.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:analyzer_plugin/src/utilities/completion/completion_target.dart';
import 'package:analyzer_plugin/src/utilities/completion/optype.dart';
import 'package:analyzer_plugin/src/utilities/visitors/local_declaration_visitor.dart'
    show LocalDeclarationVisitor;

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
    var opType = request.opType;
    AstNode? node = request.target.containingNode;

    // Suggest local fields for constructor initializers.
    var suggestLocalFields = node is ConstructorDeclaration &&
        node.initializers.contains(request.target.entity);

    // Collect suggestions from the specific child [AstNode] that contains the
    // completion offset and all of its parents recursively.
    if (!opType.isPrefixed) {
      if (opType.includeReturnValueSuggestions ||
          opType.includeTypeNameSuggestions ||
          opType.includeAnnotationSuggestions ||
          opType.includeVoidReturnSuggestions ||
          opType.includeConstructorSuggestions ||
          suggestLocalFields) {
        // Do not suggest local variables within the current expression.
        while (node is Expression) {
          node = node.parent;
        }

        // Do not suggest loop variable of a ForEachStatement when completing
        // the expression of the ForEachStatement.
        if (node is ForStatement && node.forLoopParts is ForEachParts) {
          node = node.parent;
        } else if (node is ForEachParts) {
          node = node.parent?.parent;
        }

        if (node != null) {
          try {
            builder.laterReplacesEarlier = false;
            var localVisitor = _LocalVisitor(
                request, builder, visibilityTracker,
                suggestLocalFields: suggestLocalFields);
            localVisitor.visit(node);
          } finally {
            builder.laterReplacesEarlier = true;
          }
        }
      }
    }

    // From this point forward the logic is for the inherited references.
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

/// A visitor for collecting suggestions from the most specific child [AstNode]
/// that contains the completion offset to the [CompilationUnit].
class _LocalVisitor extends LocalDeclarationVisitor {
  /// The request for which suggestions are being computed.
  final DartCompletionRequest request;

  /// The builder used to build the suggestions.
  final SuggestionBuilder builder;

  /// The op type associated with the request.
  final OpType opType;

  /// A flag indicating whether the target of the request is a function-valued
  /// argument in an argument list.
  final bool targetIsFunctionalArgument;

  /// A flag indicating whether local fields should be suggested.
  final bool suggestLocalFields;

  /// A flag indicating whether suggestions are being made inside an `extends`
  /// clause.
  bool inExtendsClause = false;

  VisibilityTracker visibilityTracker;

  _LocalVisitor(this.request, this.builder, this.visibilityTracker,
      {required this.suggestLocalFields})
      : opType = request.opType,
        targetIsFunctionalArgument = request.target.isFunctionalArgument(),
        super(request.offset);

  CompletionSuggestionKind get _defaultKind => targetIsFunctionalArgument
      ? CompletionSuggestionKind.IDENTIFIER
      : opType.suggestKind;

  @override
  void declaredClass(ClassDeclaration declaration) {
    _declaredInterfaceElement(declaration.declaredElement);
  }

  @override
  void declaredClassTypeAlias(ClassTypeAlias declaration) {
    var declaredElement = declaration.declaredElement;
    if (declaredElement != null && opType.includeTypeNameSuggestions) {
      builder.suggestInterface(declaredElement);
    }
  }

  @override
  void declaredConstructor(ConstructorDeclaration declaration) {
    // ignored: constructor completions are handled in declaredClass() above
  }

  @override
  void declaredEnum(EnumDeclaration declaration) {
    _declaredInterfaceElement(declaration.declaredElement);
  }

  @override
  void declaredExtension(ExtensionDeclaration declaration) {
    var declaredElement = declaration.declaredElement;
    if (declaredElement != null &&
        visibilityTracker.isVisible(declaredElement) &&
        opType.includeReturnValueSuggestions &&
        declaration.name != null) {
      builder.suggestExtension(declaredElement, kind: _defaultKind);
    }
  }

  @override
  void declaredField(FieldDeclaration fieldDecl, VariableDeclaration varDecl) {
    var field = varDecl.declaredElement;
    if (field is FieldElement &&
        ((visibilityTracker.isVisible(field) &&
                opType.includeReturnValueSuggestions &&
                (!opType.inStaticMethodBody || fieldDecl.isStatic)) ||
            suggestLocalFields)) {
      var inheritanceDistance = 0.0;
      var enclosingClass = request.target.containingNode
          .thisOrAncestorOfType<ClassDeclaration>();
      var enclosingElement = enclosingClass?.declaredElement;
      if (enclosingElement != null) {
        var enclosingElement = field.enclosingElement;
        if (enclosingElement is InterfaceElement) {
          inheritanceDistance = request.featureComputer
              .inheritanceDistanceFeature(enclosingElement, enclosingElement);
        }
      }
      builder.suggestField(field, inheritanceDistance: inheritanceDistance);
    }
  }

  @override
  void declaredFunction(FunctionDeclaration declaration) {
    if (visibilityTracker.isVisible(declaration.declaredElement) &&
        (opType.includeReturnValueSuggestions ||
            opType.includeVoidReturnSuggestions)) {
      if (declaration.isSetter) {
        if (!opType.includeVoidReturnSuggestions) {
          return;
        }
      } else if (!declaration.isGetter) {
        if (!opType.includeVoidReturnSuggestions &&
            _isVoid(declaration.returnType)) {
          return;
        }
      }
      var declaredElement = declaration.declaredElement;
      if (declaredElement is FunctionElement) {
        builder.suggestTopLevelFunction(declaredElement, kind: _defaultKind);
      } else if (declaredElement is PropertyAccessorElement) {
        builder.suggestTopLevelPropertyAccessor(declaredElement);
      }
    }
  }

  @override
  void declaredFunctionTypeAlias(FunctionTypeAlias declaration) {
    var declaredElement = declaration.declaredElement;
    if (declaredElement != null && opType.includeTypeNameSuggestions) {
      builder.suggestTypeAlias(declaredElement);
    }
  }

  @override
  void declaredGenericTypeAlias(GenericTypeAlias declaration) {
    var declaredElement = declaration.declaredElement;
    if (declaredElement is TypeAliasElement &&
        opType.includeTypeNameSuggestions) {
      builder.suggestTypeAlias(declaredElement);
    }
  }

  @override
  void declaredLabel(Label label, bool isCaseLabel) {
    // ignored: handled by the label_contributor.dart
  }

  @override
  void declaredMethod(MethodDeclaration declaration) {
    var element = declaration.declaredElement;
    if (visibilityTracker.isVisible(element) &&
        (opType.includeReturnValueSuggestions ||
            opType.includeVoidReturnSuggestions) &&
        (!opType.inStaticMethodBody || declaration.isStatic)) {
      var inheritanceDistance = 0.0;
      var enclosingClass = request.target.containingNode
          .thisOrAncestorOfType<ClassDeclaration>();
      if (enclosingClass != null) {
        var enclosingElement = element?.enclosingElement;
        if (enclosingElement is InterfaceElement) {
          inheritanceDistance = request.featureComputer
              .inheritanceDistanceFeature(
                  enclosingClass.declaredElement!, enclosingElement);
        }
      }
      if (element is MethodElement) {
        builder.suggestMethod(element,
            inheritanceDistance: inheritanceDistance, kind: _defaultKind);
      } else if (element is PropertyAccessorElement) {
        builder.suggestAccessor(element,
            inheritanceDistance: inheritanceDistance);
      }
    }
  }

  @override
  void declaredMixin(MixinDeclaration declaration) {
    var declaredElement = declaration.declaredElement;
    if (!inExtendsClause &&
        declaredElement != null &&
        visibilityTracker.isVisible(declaredElement) &&
        opType.includeTypeNameSuggestions) {
      builder.suggestInterface(declaredElement);
    }
  }

  @override
  void declaredTopLevelVar(
      VariableDeclarationList varList, VariableDeclaration varDecl) {
    var variableElement = varDecl.declaredElement;
    if (variableElement is TopLevelVariableElement &&
        visibilityTracker.isVisible(variableElement) &&
        (opType.includeReturnValueSuggestions ||
            (opType.includeAnnotationSuggestions && variableElement.isConst))) {
      var getter = variableElement.getter;
      if (getter != null) {
        builder.suggestTopLevelPropertyAccessor(getter);
      }
    }
  }

  @override
  void declaredTypeParameter(TypeParameter node) {
    var declaredElement = node.declaredElement;
    if (declaredElement != null &&
        visibilityTracker.isVisible(declaredElement) &&
        opType.includeTypeNameSuggestions) {
      builder.suggestTypeParameter(declaredElement);
    }
  }

  @override
  void visitExtendsClause(ExtendsClause node) {
    inExtendsClause = true;
    super.visitExtendsClause(node);
  }

  void _declaredInterfaceElement(InterfaceElement? element) {
    if (element != null && visibilityTracker.isVisible(element)) {
      if (opType.includeTypeNameSuggestions) {
        builder.suggestInterface(element);
      }

      final includeConstructors = opType.includeConstructorSuggestions ||
          opType.includeAnnotationSuggestions;
      final includeOnlyConstConstructors =
          opType.includeAnnotationSuggestions &&
              !opType.includeConstructorSuggestions;
      if (!opType.isPrefixed &&
          includeConstructors &&
          element is ClassElement) {
        for (final constructor in element.constructors) {
          if (!element.isConstructable && !constructor.isFactory) {
            continue;
          }
          if (includeOnlyConstConstructors && !constructor.isConst) {
            continue;
          }
          builder.suggestConstructor(constructor);
        }
      }

      if (!opType.isPrefixed && opType.includeReturnValueSuggestions) {
        final typeSystem = request.libraryElement.typeSystem;
        final contextType = request.contextType;
        if (contextType is InterfaceType) {
          // TODO(scheglov) This looks not ideal - we should suggest getters.
          for (final field in element.fields) {
            if (field.isStatic &&
                typeSystem.isSubtypeOf(field.type, contextType)) {
              builder.suggestStaticField(field);
            }
          }
        }
      }
    }
  }

  bool _isVoid(TypeAnnotation? returnType) {
    if (returnType is NamedType) {
      if (returnType.name2.lexeme == 'void') {
        return true;
      }
    }
    return false;
  }
}
