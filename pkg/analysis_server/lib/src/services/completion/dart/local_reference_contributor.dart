// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/computer/computer_hover.dart';
import 'package:analysis_server/src/protocol_server.dart'
    show CompletionSuggestion, CompletionSuggestionKind;
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/feature_computer.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analysis_server/src/services/completion/dart/utilities.dart';
import 'package:analysis_server/src/utilities/strings.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/src/util/comment.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' as protocol
    show ElementKind;
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
      var deprecated = isDeprecated(fieldDecl) || isDeprecated(varDecl);
      var fieldElement = varDecl.declaredElement;
      var fieldType = fieldElement.type;
      var typeName = fieldDecl.fields.type;
      int relevance;
      if (useNewRelevance) {
        relevance = _relevanceForType(fieldType);
      } else {
        relevance = DART_RELEVANCE_LOCAL_FIELD;
      }
      _addLocalSuggestion_includeReturnValueSuggestions(
        fieldElement,
        varDecl.name,
        typeName,
        protocol.ElementKind.FIELD,
        isDeprecated: deprecated,
        relevance: relevance,
        classDecl: fieldDecl.parent,
        type: fieldType,
      );
    }
  }

  @override
  void declaredFunction(FunctionDeclaration declaration) {
    if (opType.includeReturnValueSuggestions ||
        opType.includeVoidReturnSuggestions) {
      var typeName = declaration.returnType;
      protocol.ElementKind elemKind;
      var relevance = DART_RELEVANCE_DEFAULT;
      if (declaration.isGetter) {
        elemKind = protocol.ElementKind.GETTER;
        relevance = DART_RELEVANCE_LOCAL_ACCESSOR;
      } else if (declaration.isSetter) {
        if (!opType.includeVoidReturnSuggestions) {
          return;
        }
        elemKind = protocol.ElementKind.SETTER;
        typeName = NO_RETURN_TYPE;
        relevance = DART_RELEVANCE_LOCAL_ACCESSOR;
      } else {
        if (!opType.includeVoidReturnSuggestions && _isVoid(typeName)) {
          return;
        }
        elemKind = protocol.ElementKind.FUNCTION;
        relevance = DART_RELEVANCE_LOCAL_FUNCTION;
      }
      if (useNewRelevance) {
        relevance = _relevanceForType(declaration.declaredElement.returnType);
      }
      _addLocalSuggestion_includeReturnValueSuggestions(
        declaration.declaredElement,
        declaration.name,
        typeName,
        elemKind,
        isDeprecated: isDeprecated(declaration),
        param: declaration.functionExpression.parameters,
        relevance: relevance,
        type: declaration.declaredElement.type,
      );
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
      var variableType = (id.staticElement as LocalVariableElement)?.type;
      int relevance;
      if (useNewRelevance) {
        // TODO(brianwilkerson) Use the distance to the local variable as
        //  another feature.
        relevance = _relevanceForType(variableType);
      } else {
        relevance = DART_RELEVANCE_LOCAL_VARIABLE;
      }
      _addLocalSuggestion_includeReturnValueSuggestions(
        null,
        id,
        typeName,
        protocol.ElementKind.LOCAL_VARIABLE,
        relevance: relevance,
        type: variableType ?? typeProvider.dynamicType,
      );
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
      var parameterType = (id.staticElement as VariableElement).type;
      int relevance;
      if (useNewRelevance) {
        relevance = _relevanceForType(parameterType);
      } else {
        relevance = DART_RELEVANCE_PARAMETER;
      }
      _addLocalSuggestion_includeReturnValueSuggestions(
        null,
        id,
        typeName,
        protocol.ElementKind.PARAMETER,
        relevance: relevance,
        type: parameterType,
      );
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
      int relevance;
      if (useNewRelevance) {
        relevance = Relevance.typeParameter;
      } else {
        relevance = DART_RELEVANCE_TYPE_PARAMETER;
      }
      _addLocalSuggestion(
        null,
        node.name,
        null,
        protocol.ElementKind.TYPE_PARAMETER,
        isDeprecated: isDeprecated(node),
        kind: CompletionSuggestionKind.IDENTIFIER,
        relevance: relevance,
      );
    }
  }

  void _addLocalSuggestion(Element element, SimpleIdentifier id,
      TypeAnnotation typeName, protocol.ElementKind elemKind,
      {bool isAbstract = false,
      bool isDeprecated = false,
      ClassOrMixinDeclaration classDecl,
      CompletionSuggestionKind kind,
      FormalParameterList param,
      int relevance = DART_RELEVANCE_DEFAULT}) {
    if (id == null) {
      return null;
    }
    kind ??= _defaultKind;
    var suggestion = _createLocalSuggestion(
        id, isDeprecated, relevance, typeName,
        classDecl: classDecl, kind: kind);
    if (suggestion != null) {
      _setDocumentation(suggestion, element);
      if (!useNewRelevance &&
          privateMemberRelevance != null &&
          suggestion.completion.startsWith('_')) {
        suggestion.relevance = privateMemberRelevance;
      }
      suggestionMap.putIfAbsent(suggestion.completion, () => suggestion);
      suggestion.element = createLocalElement(request.source, elemKind, id,
          isAbstract: isAbstract,
          isDeprecated: isDeprecated,
          parameters: param?.toSource(),
          returnType: typeName);
      if ((elemKind == protocol.ElementKind.METHOD ||
              elemKind == protocol.ElementKind.FUNCTION) &&
          param != null) {
        _addParameterInfo(suggestion, param);
      }
    }
  }

  void _addLocalSuggestion_includeReturnValueSuggestions(
      Element element,
      SimpleIdentifier id,
      TypeAnnotation typeName,
      protocol.ElementKind elemKind,
      {bool isAbstract = false,
      bool isDeprecated = false,
      ClassOrMixinDeclaration classDecl,
      FormalParameterList param,
      int relevance = DART_RELEVANCE_DEFAULT,
      @required DartType type}) {
    if (!useNewRelevance) {
      relevance = opType.returnValueSuggestionsFilter(type, relevance);
    }
    if (relevance != null) {
      _addLocalSuggestion(element, id, typeName, elemKind,
          isAbstract: isAbstract,
          isDeprecated: isDeprecated,
          classDecl: classDecl,
          param: param,
          relevance: relevance);
    }
  }

  void _addParameterInfo(
      CompletionSuggestion suggestion, FormalParameterList parameters) {
    var paramList = parameters.parameters;
    suggestion.parameterNames = paramList
        .map((FormalParameter param) => param.identifier.name)
        .toList();
    suggestion.parameterTypes = paramList.map((FormalParameter param) {
      TypeAnnotation type;
      if (param is DefaultFormalParameter) {
        var child = param.parameter;
        if (child is SimpleFormalParameter) {
          type = child.type;
        } else if (child is FieldFormalParameter) {
          type = child.type;
        }
      }
      if (param is SimpleFormalParameter) {
        type = param.type;
      } else if (param is FieldFormalParameter) {
        type = param.type;
      }
      if (type == null) {
        return 'dynamic';
      }
      if (type is TypeName) {
        var typeId = type.name;
        if (typeId == null) {
          return 'dynamic';
        }
        return typeId.name;
      }
      // TODO(brianwilkerson) Support function types.
      return 'dynamic';
    }).toList();

    var requiredParameters = paramList
        .where((FormalParameter param) => param.isRequiredPositional)
        .map((p) => p.declaredElement);
    suggestion.requiredParameterCount = requiredParameters.length;

    var namedParameters = paramList
        .where((FormalParameter param) => param.isNamed)
        .map((p) => p.declaredElement);
    suggestion.hasNamedParameters = namedParameters.isNotEmpty;

    addDefaultArgDetails(suggestion, null, requiredParameters, namedParameters);
  }

  /// Create a new suggestion based upon the given information. Return the new
  /// suggestion or `null` if it could not be created.
  CompletionSuggestion _createLocalSuggestion(SimpleIdentifier id,
      bool isDeprecated, int relevance, TypeAnnotation returnType,
      {ClassOrMixinDeclaration classDecl,
      @required CompletionSuggestionKind kind}) {
    var completion = id.name;
    if (completion == null || completion.isEmpty || completion == '_') {
      return null;
    }
    if (!useNewRelevance) {
      relevance = isDeprecated ? DART_RELEVANCE_LOW : relevance;
    }
    var suggestion = CompletionSuggestion(
        kind, relevance, completion, completion.length, 0, isDeprecated, false,
        returnType: nameForType(id, returnType));
    var className = classDecl?.name?.name;
    if (className != null && className.isNotEmpty) {
      suggestion.declaringType = className;
    }
    return suggestion;
  }

  bool _isVoid(TypeAnnotation returnType) {
    if (returnType is TypeName) {
      var id = returnType.name;
      if (id != null && id.name == 'void') {
        return true;
      }
    }
    return false;
  }

  /// Return the relevance for an element with the given [elementType].
  int _relevanceForType(DartType elementType) {
    var contextTypeFeature =
        request.featureComputer.contextTypeFeature(contextType, elementType);
    // TODO(brianwilkerson) Figure out whether there are other features that
    //  ought to be used here and what the right default value is. It's possible
    //  that the right default value depends on where this is called from.
    return toRelevance(contextTypeFeature, 800);
  }

  /// If the given [documentationComment] is not `null`, fill the [suggestion]
  /// documentation fields.
  void _setDocumentation(CompletionSuggestion suggestion, Element element) {
    var doc = DartUnitHoverComputer.computeDocumentation(
        request.dartdocDirectiveInfo, element);
    if (doc != null) {
      suggestion.docComplete = doc;
      suggestion.docSummary = getDartDocSummary(doc);
    }
  }
}
