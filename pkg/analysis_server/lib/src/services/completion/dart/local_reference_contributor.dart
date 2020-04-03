// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/protocol_server.dart'
    show CompletionSuggestion, CompletionSuggestionKind, Location;
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/feature_computer.dart';
import 'package:analysis_server/src/services/completion/dart/utilities.dart';
import 'package:analysis_server/src/utilities/strings.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/src/util/comment.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' as protocol
    show Element, ElementKind;
import 'package:analyzer_plugin/src/utilities/completion/optype.dart';
import 'package:analyzer_plugin/src/utilities/visitors/local_declaration_visitor.dart'
    show LocalDeclarationVisitor;
import 'package:meta/meta.dart';

/// A contributor that produces suggestions based on the declarations in the
/// local file and containing library.
class LocalReferenceContributor extends DartCompletionContributor {
  @override
  Future<List<CompletionSuggestion>> computeSuggestions(
      DartCompletionRequest request) async {
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

        var visitor =
            _LocalVisitor(request, suggestLocalFields: suggestLocalFields);
        visitor.visit(node);
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

  _LocalVisitor(this.request, {@required this.suggestLocalFields})
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

  @override
  void declaredClass(ClassDeclaration declaration) {
    if (opType.includeTypeNameSuggestions) {
      _addLocalSuggestion_includeTypeNameSuggestions(
        declaration.documentationComment,
        declaration.name,
        NO_RETURN_TYPE,
        protocol.ElementKind.CLASS,
        isAbstract: declaration.isAbstract,
        isDeprecated: isDeprecated(declaration),
        type: _instantiateClassElement(declaration.declaredElement),
      );
    }
  }

  @override
  void declaredClassTypeAlias(ClassTypeAlias declaration) {
    if (opType.includeTypeNameSuggestions) {
      _addLocalSuggestion_includeTypeNameSuggestions(
        declaration.documentationComment,
        declaration.name,
        NO_RETURN_TYPE,
        protocol.ElementKind.CLASS_TYPE_ALIAS,
        isAbstract: true,
        isDeprecated: isDeprecated(declaration),
        type: _instantiateClassElement(declaration.declaredElement),
      );
    }
  }

  @override
  void declaredEnum(EnumDeclaration declaration) {
    if (opType.includeTypeNameSuggestions) {
      _addLocalSuggestion_includeTypeNameSuggestions(
        declaration.documentationComment,
        declaration.name,
        NO_RETURN_TYPE,
        protocol.ElementKind.ENUM,
        isDeprecated: isDeprecated(declaration),
        type: _instantiateClassElement(declaration.declaredElement),
      );
      for (var enumConstant in declaration.constants) {
        if (!enumConstant.isSynthetic) {
          _addLocalSuggestion_includeReturnValueSuggestions_enumConstant(
            enumConstant,
            declaration,
            isDeprecated: isDeprecated(declaration),
          );
        }
      }
    }
  }

  @override
  void declaredExtension(ExtensionDeclaration declaration) {
    if (opType.includeReturnValueSuggestions && declaration.name != null) {
      _addLocalSuggestion_includeReturnValueSuggestions(
        declaration.documentationComment,
        declaration.name,
        NO_RETURN_TYPE,
        protocol.ElementKind.EXTENSION,
        isDeprecated: isDeprecated(declaration),
        type: null,
      );
    }
  }

  @override
  void declaredField(FieldDeclaration fieldDecl, VariableDeclaration varDecl) {
    if ((opType.includeReturnValueSuggestions &&
            (!opType.inStaticMethodBody || fieldDecl.isStatic)) ||
        suggestLocalFields) {
      var deprecated = isDeprecated(fieldDecl) || isDeprecated(varDecl);
      var fieldType = varDecl.declaredElement.type;
      var typeName = fieldDecl.fields.type;
      int relevance;
      if (useNewRelevance) {
        relevance = _relevanceForType(fieldType);
      } else {
        relevance = DART_RELEVANCE_LOCAL_FIELD;
      }
      _addLocalSuggestion_includeReturnValueSuggestions(
        fieldDecl.documentationComment,
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
        declaration.documentationComment,
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
      // TODO (danrubel) determine parameters and return type
      _addLocalSuggestion_includeTypeNameSuggestions(
        declaration.documentationComment,
        declaration.name,
        declaration.returnType,
        protocol.ElementKind.FUNCTION_TYPE_ALIAS,
        isAbstract: true,
        isDeprecated: isDeprecated(declaration),
        type: _instantiateFunctionTypeAlias(declaration.declaredElement),
      );
    }
  }

  @override
  void declaredGenericTypeAlias(GenericTypeAlias declaration) {
    if (opType.includeTypeNameSuggestions) {
      // TODO (danrubel) determine parameters and return type
      _addLocalSuggestion_includeTypeNameSuggestions(
        declaration.documentationComment,
        declaration.name,
        declaration.functionType?.returnType,
        protocol.ElementKind.FUNCTION_TYPE_ALIAS,
        isAbstract: true,
        isDeprecated: isDeprecated(declaration),
        type: _instantiateFunctionTypeAlias(declaration.declaredElement),
      );
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
      protocol.ElementKind elemKind;
      FormalParameterList param;
      var typeName = declaration.returnType;
      var relevance = DART_RELEVANCE_DEFAULT;
      if (declaration.isGetter) {
        elemKind = protocol.ElementKind.GETTER;
        param = null;
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
        elemKind = protocol.ElementKind.METHOD;
        param = declaration.parameters;
        relevance = DART_RELEVANCE_LOCAL_METHOD;
      }
      if (useNewRelevance) {
        relevance = _relevanceForType(declaration.declaredElement.returnType);
      }
      _addLocalSuggestion_includeReturnValueSuggestions(
        declaration.documentationComment,
        declaration.name,
        typeName,
        elemKind,
        isAbstract: declaration.isAbstract,
        isDeprecated: isDeprecated(declaration),
        classDecl: declaration.parent,
        param: param,
        relevance: relevance,
        type: declaration.declaredElement.type,
      );
    }
  }

  @override
  void declaredMixin(MixinDeclaration declaration) {
    if (opType.includeTypeNameSuggestions) {
      _addLocalSuggestion_includeTypeNameSuggestions(
        declaration.documentationComment,
        declaration.name,
        NO_RETURN_TYPE,
        protocol.ElementKind.MIXIN,
        isAbstract: true,
        isDeprecated: isDeprecated(declaration),
        type: _instantiateClassElement(declaration.declaredElement),
      );
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
      var variableType = varDecl.declaredElement.type;
      int relevance;
      if (useNewRelevance) {
        relevance = _relevanceForType(variableType);
      } else {
        relevance = DART_RELEVANCE_LOCAL_TOP_LEVEL_VARIABLE;
      }
      _addLocalSuggestion_includeReturnValueSuggestions(
        varDecl.documentationComment,
        varDecl.name,
        varList.type,
        protocol.ElementKind.TOP_LEVEL_VARIABLE,
        isDeprecated: isDeprecated(varList) || isDeprecated(varDecl),
        relevance: relevance,
        type: variableType,
      );
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

  void _addLocalSuggestion(Comment documentationComment, SimpleIdentifier id,
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
    kind ??= targetIsFunctionalArgument
        ? CompletionSuggestionKind.IDENTIFIER
        : opType.suggestKind;
    var suggestion = _createLocalSuggestion(
        id, isDeprecated, relevance, typeName,
        classDecl: classDecl, kind: kind);
    if (suggestion != null) {
      _setDocumentation(suggestion, documentationComment);
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

  void _addLocalSuggestion_enumConstant(
      EnumConstantDeclaration constantDeclaration,
      EnumDeclaration enumDeclaration,
      {bool isDeprecated = false,
      int relevance = DART_RELEVANCE_DEFAULT}) {
    var constantNameNode = constantDeclaration.name;
    var constantName = constantNameNode.name;
    var enumName = enumDeclaration.name.name;
    var completion = '$enumName.$constantName';
    if (!useNewRelevance) {
      relevance = isDeprecated ? DART_RELEVANCE_LOW : relevance;
    }
    var suggestion = CompletionSuggestion(CompletionSuggestionKind.INVOCATION,
        relevance, completion, completion.length, 0, isDeprecated, false,
        returnType: enumName);

    suggestionMap.putIfAbsent(suggestion.completion, () => suggestion);
    var flags = protocol.Element.makeFlags(
        isDeprecated: isDeprecated,
        isPrivate: Identifier.isPrivateName(constantName));
    suggestion.element = protocol.Element(
        protocol.ElementKind.ENUM_CONSTANT, constantName, flags,
        location: Location(request.source.fullName, constantNameNode.offset,
            constantNameNode.length, 0, 0));
  }

  void _addLocalSuggestion_includeReturnValueSuggestions(
      Comment documentationComment,
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
      _addLocalSuggestion(documentationComment, id, typeName, elemKind,
          isAbstract: isAbstract,
          isDeprecated: isDeprecated,
          classDecl: classDecl,
          param: param,
          relevance: relevance);
    }
  }

  void _addLocalSuggestion_includeReturnValueSuggestions_enumConstant(
      EnumConstantDeclaration constantDeclaration,
      EnumDeclaration enumDeclaration,
      {@required bool isDeprecated}) {
    var enumElement = enumDeclaration.declaredElement;
    int relevance;
    if (useNewRelevance) {
      relevance = _relevanceForType(enumElement.thisType);
    } else {
      relevance = opType.returnValueSuggestionsFilter(
          _instantiateClassElement(enumElement), DART_RELEVANCE_DEFAULT);
    }
    if (relevance != null) {
      _addLocalSuggestion_enumConstant(constantDeclaration, enumDeclaration,
          isDeprecated: isDeprecated, relevance: relevance);
    }
  }

  void _addLocalSuggestion_includeTypeNameSuggestions(
      Comment documentationComment,
      SimpleIdentifier id,
      TypeAnnotation typeName,
      protocol.ElementKind elemKind,
      {bool isAbstract = false,
      bool isDeprecated = false,
      @required DartType type}) {
    int relevance;
    if (useNewRelevance) {
      relevance = _relevanceForType(type);
    } else {
      relevance =
          opType.typeNameSuggestionsFilter(type, DART_RELEVANCE_DEFAULT);
    }
    if (relevance != null) {
      _addLocalSuggestion(documentationComment, id, typeName, elemKind,
          isAbstract: isAbstract,
          isDeprecated: isDeprecated,
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

  InterfaceType _instantiateClassElement(ClassElement element) {
    var typeParameters = element.typeParameters;
    var typeArguments = const <DartType>[];
    if (typeParameters.isNotEmpty) {
      typeArguments = typeParameters.map((t) {
        return typeProvider.dynamicType;
      }).toList();
    }

    var nullabilitySuffix = request.featureSet.isEnabled(Feature.non_nullable)
        ? NullabilitySuffix.none
        : NullabilitySuffix.star;

    return element.instantiate(
      typeArguments: typeArguments,
      nullabilitySuffix: nullabilitySuffix,
    );
  }

  FunctionType _instantiateFunctionTypeAlias(FunctionTypeAliasElement element) {
    var typeParameters = element.typeParameters;
    var typeArguments = const <DartType>[];
    if (typeParameters.isNotEmpty) {
      typeArguments = typeParameters.map((t) {
        return typeProvider.dynamicType;
      }).toList();
    }

    var nullabilitySuffix = request.featureSet.isEnabled(Feature.non_nullable)
        ? NullabilitySuffix.none
        : NullabilitySuffix.star;

    return element.instantiate(
      typeArguments: typeArguments,
      nullabilitySuffix: nullabilitySuffix,
    );
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
  static void _setDocumentation(
      CompletionSuggestion suggestion, Comment documentationComment) {
    if (documentationComment != null) {
      var text = documentationComment.tokens
          .map((Token t) => t.toString())
          .join('\n')
          .replaceAll('\r\n', '\n');
      var doc = getDartDocPlainText(text);
      suggestion.docComplete = doc;
      suggestion.docSummary = getDartDocSummary(doc);
    }
  }
}
