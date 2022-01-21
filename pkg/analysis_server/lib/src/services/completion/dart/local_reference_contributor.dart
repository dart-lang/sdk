// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart'
    show CompletionSuggestionKind;
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
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
  _VisibilityTracker visibilityTracker = _VisibilityTracker();

  LocalReferenceContributor(
    DartCompletionRequest request,
    SuggestionBuilder builder,
  ) : super(request, builder);

  @override
  Future<void> computeSuggestions() async {
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
        var classOrMixin = member.parent;
        if (classOrMixin is ClassOrMixinDeclaration) {
          var declaredElement = classOrMixin.declaredElement;
          if (declaredElement != null) {
            memberBuilder = MemberSuggestionBuilder(request, builder);
            _computeSuggestionsForClass(declaredElement);
          }
        }
      }
    }
  }

  void _addSuggestionsForType(InterfaceType type, double inheritanceDistance,
      {bool isFunctionalArgument = false}) {
    var opType = request.opType;
    if (!isFunctionalArgument) {
      for (var accessor in type.accessors) {
        if (visibilityTracker._isVisible(accessor.declaration)) {
          if (accessor.isGetter) {
            if (opType.includeReturnValueSuggestions) {
              memberBuilder.addSuggestionForAccessor(
                  accessor: accessor, inheritanceDistance: inheritanceDistance);
            }
          } else {
            if (opType.includeVoidReturnSuggestions) {
              memberBuilder.addSuggestionForAccessor(
                  accessor: accessor, inheritanceDistance: inheritanceDistance);
            }
          }
        }
      }
    }
    for (var method in type.methods) {
      if (visibilityTracker._isVisible(method.declaration)) {
        if (!method.returnType.isVoid) {
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

  void _computeSuggestionsForClass(ClassElement classElement) {
    var isFunctionalArgument = request.target.isFunctionalArgument();
    classMemberSuggestionKind = isFunctionalArgument
        ? CompletionSuggestionKind.IDENTIFIER
        : CompletionSuggestionKind.INVOCATION;
    for (var type in classElement.allSupertypes) {
      var inheritanceDistance = request.featureComputer
          .inheritanceDistanceFeature(classElement, type.element);
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

  _VisibilityTracker visibilityTracker;

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
    var classElt = declaration.declaredElement;
    if (classElt != null && visibilityTracker._isVisible(classElt)) {
      if (opType.includeTypeNameSuggestions) {
        builder.suggestClass(classElt);
      }

      // Generate the suggestions for the constructors. We are required to loop
      // through elements here instead of using declaredConstructor() due to
      // implicit constructors (i.e. there is no AstNode for an implicit
      // constructor)
      if (!opType.isPrefixed && opType.includeConstructorSuggestions) {
        for (var constructor in classElt.constructors) {
          if (!classElt.isAbstract || constructor.isFactory) {
            builder.suggestConstructor(constructor);
          }
        }
      }
    }
  }

  @override
  void declaredClassTypeAlias(ClassTypeAlias declaration) {
    var declaredElement = declaration.declaredElement;
    if (declaredElement != null && opType.includeTypeNameSuggestions) {
      builder.suggestClass(declaredElement);
    }
  }

  @override
  void declaredConstructor(ConstructorDeclaration declaration) {
    // ignored: constructor completions are handled in declaredClass() above
  }

  @override
  void declaredEnum(EnumDeclaration declaration) {
    var declaredElement = declaration.declaredElement;
    if (declaredElement != null &&
        visibilityTracker._isVisible(declaredElement) &&
        opType.includeTypeNameSuggestions) {
      builder.suggestClass(declaredElement);
      for (var enumConstant in declaration.constants) {
        if (!enumConstant.isSynthetic) {
          var constantElement = enumConstant.declaredElement;
          if (constantElement is FieldElement) {
            builder.suggestEnumConstant(constantElement);
          }
        }
      }
    }
  }

  @override
  void declaredExtension(ExtensionDeclaration declaration) {
    var declaredElement = declaration.declaredElement;
    if (declaredElement != null &&
        visibilityTracker._isVisible(declaredElement) &&
        opType.includeReturnValueSuggestions &&
        declaration.name != null) {
      builder.suggestExtension(declaredElement, kind: _defaultKind);
    }
  }

  @override
  void declaredField(FieldDeclaration fieldDecl, VariableDeclaration varDecl) {
    var field = varDecl.declaredElement;
    if (field is FieldElement &&
        ((visibilityTracker._isVisible(field) &&
                opType.includeReturnValueSuggestions &&
                (!opType.inStaticMethodBody || fieldDecl.isStatic)) ||
            suggestLocalFields)) {
      var inheritanceDistance = 0.0;
      var enclosingClass = request.target.containingNode
          .thisOrAncestorOfType<ClassDeclaration>();
      var enclosingElement = enclosingClass?.declaredElement;
      if (enclosingElement != null) {
        var enclosingElement = field.enclosingElement;
        if (enclosingElement is ClassElement) {
          inheritanceDistance = request.featureComputer
              .inheritanceDistanceFeature(enclosingElement, enclosingElement);
        }
      }
      builder.suggestField(field, inheritanceDistance: inheritanceDistance);
    }
  }

  @override
  void declaredFunction(FunctionDeclaration declaration) {
    if (visibilityTracker._isVisible(declaration.declaredElement) &&
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
  void declaredLocalVar(SimpleIdentifier name, TypeAnnotation? type) {
    if (visibilityTracker._isVisible(name.staticElement) &&
        opType.includeReturnValueSuggestions) {
      builder.suggestLocalVariable(name.staticElement as LocalVariableElement);
    }
  }

  @override
  void declaredMethod(MethodDeclaration declaration) {
    var element = declaration.declaredElement;
    if (visibilityTracker._isVisible(element) &&
        (opType.includeReturnValueSuggestions ||
            opType.includeVoidReturnSuggestions) &&
        (!opType.inStaticMethodBody || declaration.isStatic)) {
      var inheritanceDistance = 0.0;
      var enclosingClass = request.target.containingNode
          .thisOrAncestorOfType<ClassDeclaration>();
      if (enclosingClass != null) {
        var enclosingElement = element?.enclosingElement;
        if (enclosingElement is ClassElement) {
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
        visibilityTracker._isVisible(declaredElement) &&
        opType.includeTypeNameSuggestions) {
      builder.suggestClass(declaredElement);
    }
  }

  @override
  void declaredParam(SimpleIdentifier name, TypeAnnotation? type) {
    var element = name.staticElement;
    if (visibilityTracker._isVisible(element) &&
        opType.includeReturnValueSuggestions) {
      if (_isUnused(name.name)) {
        return;
      }
      if (element is ParameterElement) {
        builder.suggestParameter(element);
      } else if (element is LocalVariableElement) {
        builder.suggestCatchParameter(element);
      }
    }
  }

  @override
  void declaredTopLevelVar(
      VariableDeclarationList varList, VariableDeclaration varDecl) {
    var variableElement = varDecl.declaredElement;
    if (variableElement is TopLevelVariableElement &&
        visibilityTracker._isVisible(variableElement) &&
        opType.includeReturnValueSuggestions) {
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
        visibilityTracker._isVisible(declaredElement) &&
        opType.includeTypeNameSuggestions) {
      builder.suggestTypeParameter(declaredElement);
    }
  }

  @override
  void visitExtendsClause(ExtendsClause node) {
    inExtendsClause = true;
    super.visitExtendsClause(node);
  }

  /// Return `true` if the [identifier] is composed of one or more underscore
  /// characters and nothing else.
  bool _isUnused(String identifier) => RegExp(r'^_+$').hasMatch(identifier);

  bool _isVoid(TypeAnnotation? returnType) {
    if (returnType is NamedType) {
      var id = returnType.name;
      if (id.name == 'void') {
        return true;
      }
    }
    return false;
  }
}

/// This class tracks the set of elements already added in the completion list,
/// this object helps prevents suggesting elements that have been shadowed by
/// local declarations.
class _VisibilityTracker {
  /// The set of known previously declared names in this contributor.
  final Set<String> declaredNames = {};

  /// Before completions are added by this contributor, we verify with this
  /// method if the element has already been added, this prevents suggesting
  /// [Element]s that are shadowed.
  bool _isVisible(Element? element) {
    var name = element?.name;
    return name != null && declaredNames.add(name);
  }
}
