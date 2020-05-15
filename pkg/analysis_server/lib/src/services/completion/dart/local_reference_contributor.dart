// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/protocol_server.dart'
    show CompletionSuggestion, CompletionSuggestionKind;
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analysis_server/src/utilities/strings.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer_plugin/src/utilities/completion/optype.dart';
import 'package:analyzer_plugin/src/utilities/visitors/local_declaration_visitor.dart'
    show LocalDeclarationVisitor;
import 'package:meta/meta.dart';

/// A contributor that produces suggestions based on the declarations in the
/// local file and containing library.
class LocalReferenceContributor extends DartCompletionContributor {
  @override
  Future<List<CompletionSuggestion>> computeSuggestions(
      DartCompletionRequest request, SuggestionBuilder builder) async {
    var opType = request.opType;
    var node = request.target.containingNode;

    // Suggest local fields for constructor initializers.
    var suggestLocalFields = node is ConstructorDeclaration &&
        node.initializers.contains(request.target.entity);

    // Collect suggestions from the specific child [AstNode] that contains the
    // completion offset and all of its parents recursively.
    if (!opType.isPrefixed) {
      if (opType.includeReturnValueSuggestions ||
          opType.includeTypeNameSuggestions ||
          opType.includeVoidReturnSuggestions ||
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
          node = node.parent.parent;
        }

        var visitor = _LocalVisitor(request, builder,
            suggestLocalFields: suggestLocalFields);
        try {
          builder.laterReplacesEarlier = false;
          visitor.visit(node);
        } finally {
          builder.laterReplacesEarlier = true;
        }
        return visitor.suggestions;
      }
    }
    return const <CompletionSuggestion>[];
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

  /// A flag indicating whether the suggestions should use the new relevance
  /// scores.
  final bool useNewRelevance;

  /// A flag indicating whether the target of the request is a function-valued
  /// argument in an argument list.
  final bool targetIsFunctionalArgument;

  /// A flag indicating whether local fields should be suggested.
  final bool suggestLocalFields;

  final Map<String, CompletionSuggestion> suggestionMap =
      <String, CompletionSuggestion>{};

  /// The context type of the completion offset, or `null` if there is no
  /// context type at that location.
  DartType contextType;

  /// Only used when [useNewRelevance] is `false`.
  int privateMemberRelevance = DART_RELEVANCE_DEFAULT;

  _LocalVisitor(this.request, this.builder, {@required this.suggestLocalFields})
      : opType = request.opType,
        useNewRelevance = request.useNewRelevance,
        targetIsFunctionalArgument = request.target.isFunctionalArgument(),
        super(request.offset) {
    // Suggestions for inherited members are provided by
    // InheritedReferenceContributor.
    if (useNewRelevance) {
      contextType = request.featureComputer
          .computeContextType(request.target.containingNode);
    } else {
      // If the user typed an identifier starting with '_' then do not suppress
      // the relevance of private members.
      var data = request.result != null
          ? request.result.content
          : request.sourceContents;
      var offset = request.offset;
      if (data != null && 0 < offset && offset <= data.length) {
        bool isIdentifierChar(int index) {
          var code = data.codeUnitAt(index);
          return isLetterOrDigit(code) || code == CHAR_UNDERSCORE;
        }

        if (isIdentifierChar(offset - 1)) {
          while (offset > 0 && isIdentifierChar(offset - 1)) {
            --offset;
          }
          if (data.codeUnitAt(offset) == CHAR_UNDERSCORE) {
            privateMemberRelevance = null;
          }
        }
      }
    }
  }

  /// Return the suggestions that have been computed.
  List<CompletionSuggestion> get suggestions => suggestionMap.values.toList();

  TypeProvider get typeProvider => request.libraryElement.typeProvider;

  CompletionSuggestionKind get _defaultKind => targetIsFunctionalArgument
      ? CompletionSuggestionKind.IDENTIFIER
      : opType.suggestKind;

  @override
  void declaredClass(ClassDeclaration declaration) {
    if (opType.includeTypeNameSuggestions) {
      builder.suggestClass(declaration.declaredElement, kind: _defaultKind);
    }
  }

  @override
  void declaredClassTypeAlias(ClassTypeAlias declaration) {
    if (opType.includeTypeNameSuggestions) {
      builder.suggestClass(declaration.declaredElement, kind: _defaultKind);
    }
  }

  @override
  void declaredEnum(EnumDeclaration declaration) {
    if (opType.includeTypeNameSuggestions) {
      builder.suggestClass(declaration.declaredElement, kind: _defaultKind);
      for (var enumConstant in declaration.constants) {
        if (!enumConstant.isSynthetic) {
          builder.suggestEnumConstant(enumConstant.declaredElement);
        }
      }
    }
  }

  @override
  void declaredExtension(ExtensionDeclaration declaration) {
    if (opType.includeReturnValueSuggestions && declaration.name != null) {
      builder.suggestExtension(declaration.declaredElement, kind: _defaultKind);
    }
  }

  @override
  void declaredField(FieldDeclaration fieldDecl, VariableDeclaration varDecl) {
    if ((opType.includeReturnValueSuggestions &&
            (!opType.inStaticMethodBody || fieldDecl.isStatic)) ||
        suggestLocalFields) {
      var field = varDecl.declaredElement;
      var inheritanceDistance = -1.0;
      var enclosingClass = request.target.containingNode
          .thisOrAncestorOfType<ClassDeclaration>();
      if (enclosingClass != null) {
        inheritanceDistance = request.featureComputer
            .inheritanceDistanceFeature(
                enclosingClass.declaredElement, field.enclosingElement);
      }
      builder.suggestField(field, inheritanceDistance: inheritanceDistance);
    }
  }

  @override
  void declaredFunction(FunctionDeclaration declaration) {
    if (opType.includeReturnValueSuggestions ||
        opType.includeVoidReturnSuggestions) {
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
        builder.suggestTopLevelPropertyAccessor(declaredElement,
            kind: _defaultKind);
      }
    }
  }

  @override
  void declaredFunctionTypeAlias(FunctionTypeAlias declaration) {
    if (opType.includeTypeNameSuggestions) {
      builder.suggestFunctionTypeAlias(declaration.declaredElement,
          kind: _defaultKind);
    }
  }

  @override
  void declaredGenericTypeAlias(GenericTypeAlias declaration) {
    if (opType.includeTypeNameSuggestions) {
      builder.suggestFunctionTypeAlias(declaration.declaredElement,
          kind: _defaultKind);
    }
  }

  @override
  void declaredLabel(Label label, bool isCaseLabel) {
    // ignored
  }

  @override
  void declaredLocalVar(SimpleIdentifier id, TypeAnnotation typeName) {
    if (opType.includeReturnValueSuggestions) {
      builder.suggestLocalVariable(id.staticElement as LocalVariableElement);
    }
  }

  @override
  void declaredMethod(MethodDeclaration declaration) {
    if ((opType.includeReturnValueSuggestions ||
            opType.includeVoidReturnSuggestions) &&
        (!opType.inStaticMethodBody || declaration.isStatic)) {
      var element = declaration.declaredElement;
      var inheritanceDistance = -1.0;
      var enclosingClass = request.target.containingNode
          .thisOrAncestorOfType<ClassDeclaration>();
      if (enclosingClass != null) {
        inheritanceDistance = request.featureComputer
            .inheritanceDistanceFeature(
                enclosingClass.declaredElement, element.enclosingElement);
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
    if (opType.includeTypeNameSuggestions) {
      builder.suggestClass(declaration.declaredElement, kind: _defaultKind);
    }
  }

  @override
  void declaredParam(SimpleIdentifier id, TypeAnnotation typeName) {
    if (opType.includeReturnValueSuggestions) {
      if (_isUnused(id.name)) {
        return;
      }
      var element = id.staticElement;
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
    if (opType.includeReturnValueSuggestions) {
      var variableElement = varDecl.declaredElement;
      builder.suggestTopLevelPropertyAccessor(
          (variableElement as TopLevelVariableElement).getter);
    }
  }

  @override
  void declaredTypeParameter(TypeParameter node) {
    if (opType.includeTypeNameSuggestions) {
      builder.suggestTypeParameter(node.declaredElement);
    }
  }

  /// Return `true` if the [identifier] is composed of one or more underscore
  /// characters and nothing else.
  bool _isUnused(String identifier) => RegExp(r'^_+$').hasMatch(identifier);

  bool _isVoid(TypeAnnotation returnType) {
    if (returnType is TypeName) {
      var id = returnType.name;
      if (id != null && id.name == 'void') {
        return true;
      }
    }
    return false;
  }
}
