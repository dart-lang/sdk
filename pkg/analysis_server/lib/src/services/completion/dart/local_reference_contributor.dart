// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/protocol_server.dart'
    show CompletionSuggestion, CompletionSuggestionKind, Location;
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart'
    show DartCompletionRequestImpl;
import 'package:analysis_server/src/services/completion/dart/optype.dart';
import 'package:analysis_server/src/services/completion/dart/utilities.dart';
import 'package:analysis_server/src/services/correction/strings.dart';
import 'package:analysis_server/src/utilities/documentation.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_resolution_map.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/generated/utilities_dart.dart' show ParameterKind;
import 'package:analyzer_plugin/protocol/protocol_common.dart' as protocol
    show Element, ElementKind;
import 'package:analyzer_plugin/src/utilities/visitors/local_declaration_visitor.dart'
    show LocalDeclarationVisitor;

/**
 * A contributor for calculating suggestions for declarations in the local
 * file and containing library.
 */
class LocalReferenceContributor extends DartCompletionContributor {
  @override
  Future<List<CompletionSuggestion>> computeSuggestions(
      DartCompletionRequest request) async {
    OpType optype = (request as DartCompletionRequestImpl).opType;
    AstNode node = request.target.containingNode;

    // Suggest local fields for constructor initializers
    bool suggestLocalFields = node is ConstructorDeclaration &&
        node.initializers.contains(request.target.entity);

    // Collect suggestions from the specific child [AstNode] that contains
    // the completion offset and all of its parents recursively.
    if (!optype.isPrefixed) {
      if (optype.includeReturnValueSuggestions ||
          optype.includeTypeNameSuggestions ||
          optype.includeVoidReturnSuggestions ||
          suggestLocalFields) {
        // Do not suggest local vars within the current expression
        while (node is Expression) {
          node = node.parent;
        }

        // Do not suggest loop variable of a ForEachStatement
        // when completing the expression of the ForEachStatement
        if (node is ForEachStatement) {
          node = node.parent;
        }

        _LocalVisitor visitor = new _LocalVisitor(
            request, request.offset, optype,
            suggestLocalFields: suggestLocalFields);
        visitor.visit(node);
        return visitor.suggestions;
      }
    }
    return EMPTY_LIST;
  }
}

/**
 * A visitor for collecting suggestions from the most specific child [AstNode]
 * that contains the completion offset to the [CompilationUnit].
 */
class _LocalVisitor extends LocalDeclarationVisitor {
  final DartCompletionRequest request;
  final OpType optype;
  final bool suggestLocalFields;
  final Map<String, CompletionSuggestion> suggestionMap =
      <String, CompletionSuggestion>{};
  int privateMemberRelevance = DART_RELEVANCE_DEFAULT;
  bool targetIsFunctionalArgument;

  _LocalVisitor(this.request, int offset, this.optype,
      {this.suggestLocalFields})
      : super(offset) {
    // Suggestions for inherited members provided by InheritedReferenceContributor
    targetIsFunctionalArgument = request.target.isFunctionalArgument();

    // If user typed identifier starting with '_'
    // then do not suppress the relevance of private members
    var data = request.result != null
        ? request.result.content
        : request.sourceContents;
    int offset = request.offset;
    if (data != null && 0 < offset && offset <= data.length) {
      bool isIdentifierChar(int index) {
        int code = data.codeUnitAt(index);
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

  List<CompletionSuggestion> get suggestions => suggestionMap.values.toList();

  @override
  void declaredClass(ClassDeclaration declaration) {
    if (optype.includeTypeNameSuggestions) {
      _addLocalSuggestion_includeTypeNameSuggestions(
          declaration.documentationComment,
          declaration.name,
          NO_RETURN_TYPE,
          protocol.ElementKind.CLASS,
          isAbstract: declaration.isAbstract,
          isDeprecated: isDeprecated(declaration));
    }
  }

  @override
  void declaredClassTypeAlias(ClassTypeAlias declaration) {
    if (optype.includeTypeNameSuggestions) {
      _addLocalSuggestion_includeTypeNameSuggestions(
          declaration.documentationComment,
          declaration.name,
          NO_RETURN_TYPE,
          protocol.ElementKind.CLASS_TYPE_ALIAS,
          isAbstract: true,
          isDeprecated: isDeprecated(declaration));
    }
  }

  @override
  void declaredEnum(EnumDeclaration declaration) {
    if (optype.includeTypeNameSuggestions) {
      _addLocalSuggestion_includeTypeNameSuggestions(
          declaration.documentationComment,
          declaration.name,
          NO_RETURN_TYPE,
          protocol.ElementKind.ENUM,
          isDeprecated: isDeprecated(declaration));
      for (EnumConstantDeclaration enumConstant in declaration.constants) {
        if (!enumConstant.isSynthetic) {
          _addLocalSuggestion_includeReturnValueSuggestions_enumConstant(
              enumConstant, declaration,
              isDeprecated: isDeprecated(declaration));
        }
      }
    }
  }

  @override
  void declaredField(FieldDeclaration fieldDecl, VariableDeclaration varDecl) {
    if ((optype.includeReturnValueSuggestions &&
            (!optype.inStaticMethodBody || fieldDecl.isStatic)) ||
        suggestLocalFields) {
      bool deprecated = isDeprecated(fieldDecl) || isDeprecated(varDecl);
      TypeAnnotation typeName = fieldDecl.fields.type;
      _addLocalSuggestion_includeReturnValueSuggestions(
          fieldDecl.documentationComment,
          varDecl.name,
          typeName,
          protocol.ElementKind.FIELD,
          isDeprecated: deprecated,
          relevance: DART_RELEVANCE_LOCAL_FIELD,
          classDecl: fieldDecl.parent);
    }
  }

  @override
  void declaredFunction(FunctionDeclaration declaration) {
    if (optype.includeReturnValueSuggestions ||
        optype.includeVoidReturnSuggestions) {
      TypeAnnotation typeName = declaration.returnType;
      protocol.ElementKind elemKind;
      int relevance = DART_RELEVANCE_DEFAULT;
      if (declaration.isGetter) {
        elemKind = protocol.ElementKind.GETTER;
        relevance = DART_RELEVANCE_LOCAL_ACCESSOR;
      } else if (declaration.isSetter) {
        if (!optype.includeVoidReturnSuggestions) {
          return;
        }
        elemKind = protocol.ElementKind.SETTER;
        typeName = NO_RETURN_TYPE;
        relevance = DART_RELEVANCE_LOCAL_ACCESSOR;
      } else {
        if (!optype.includeVoidReturnSuggestions && _isVoid(typeName)) {
          return;
        }
        elemKind = protocol.ElementKind.FUNCTION;
        relevance = DART_RELEVANCE_LOCAL_FUNCTION;
      }
      _addLocalSuggestion_includeReturnValueSuggestions(
          declaration.documentationComment,
          declaration.name,
          typeName,
          elemKind,
          isDeprecated: isDeprecated(declaration),
          param: declaration.functionExpression.parameters,
          relevance: relevance);
    }
  }

  @override
  void declaredFunctionTypeAlias(FunctionTypeAlias declaration) {
    if (optype.includeTypeNameSuggestions) {
      // TODO (danrubel) determine parameters and return type
      _addLocalSuggestion_includeTypeNameSuggestions(
          declaration.documentationComment,
          declaration.name,
          declaration.returnType,
          protocol.ElementKind.FUNCTION_TYPE_ALIAS,
          isAbstract: true,
          isDeprecated: isDeprecated(declaration));
    }
  }

  @override
  void declaredLabel(Label label, bool isCaseLabel) {
    // ignored
  }

  @override
  void declaredLocalVar(SimpleIdentifier id, TypeAnnotation typeName) {
    if (optype.includeReturnValueSuggestions) {
      _addLocalSuggestion_includeReturnValueSuggestions(
          null, id, typeName, protocol.ElementKind.LOCAL_VARIABLE,
          relevance: DART_RELEVANCE_LOCAL_VARIABLE);
    }
  }

  @override
  void declaredMethod(MethodDeclaration declaration) {
    if ((optype.includeReturnValueSuggestions ||
            optype.includeVoidReturnSuggestions) &&
        (!optype.inStaticMethodBody || declaration.isStatic)) {
      protocol.ElementKind elemKind;
      FormalParameterList param;
      TypeAnnotation typeName = declaration.returnType;
      int relevance = DART_RELEVANCE_DEFAULT;
      if (declaration.isGetter) {
        elemKind = protocol.ElementKind.GETTER;
        param = null;
        relevance = DART_RELEVANCE_LOCAL_ACCESSOR;
      } else if (declaration.isSetter) {
        if (!optype.includeVoidReturnSuggestions) {
          return;
        }
        elemKind = protocol.ElementKind.SETTER;
        typeName = NO_RETURN_TYPE;
        relevance = DART_RELEVANCE_LOCAL_ACCESSOR;
      } else {
        if (!optype.includeVoidReturnSuggestions && _isVoid(typeName)) {
          return;
        }
        elemKind = protocol.ElementKind.METHOD;
        param = declaration.parameters;
        relevance = DART_RELEVANCE_LOCAL_METHOD;
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
          relevance: relevance);
    }
  }

  @override
  void declaredParam(SimpleIdentifier id, TypeAnnotation typeName) {
    if (optype.includeReturnValueSuggestions) {
      _addLocalSuggestion_includeReturnValueSuggestions(
          null, id, typeName, protocol.ElementKind.PARAMETER,
          relevance: DART_RELEVANCE_PARAMETER);
    }
  }

  @override
  void declaredTopLevelVar(
      VariableDeclarationList varList, VariableDeclaration varDecl) {
    if (optype.includeReturnValueSuggestions) {
      _addLocalSuggestion_includeReturnValueSuggestions(
          varDecl.documentationComment,
          varDecl.name,
          varList.type,
          protocol.ElementKind.TOP_LEVEL_VARIABLE,
          isDeprecated: isDeprecated(varList) || isDeprecated(varDecl),
          relevance: DART_RELEVANCE_LOCAL_TOP_LEVEL_VARIABLE);
    }
  }

  void _addLocalSuggestion(Comment documentationComment, SimpleIdentifier id,
      TypeAnnotation typeName, protocol.ElementKind elemKind,
      {bool isAbstract: false,
      bool isDeprecated: false,
      ClassDeclaration classDecl,
      FormalParameterList param,
      int relevance: DART_RELEVANCE_DEFAULT}) {
    CompletionSuggestionKind kind = targetIsFunctionalArgument
        ? CompletionSuggestionKind.IDENTIFIER
        : optype.suggestKind;
    CompletionSuggestion suggestion = createLocalSuggestion(
        id, isDeprecated, relevance, typeName,
        classDecl: classDecl, kind: kind);
    if (suggestion != null) {
      _setDocumentation(suggestion, documentationComment);
      if (privateMemberRelevance != null &&
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
      {bool isAbstract: false,
      bool isDeprecated: false,
      int relevance: DART_RELEVANCE_DEFAULT}) {
    String completion =
        '${enumDeclaration.name.name}.${constantDeclaration.name.name}';
    CompletionSuggestion suggestion = new CompletionSuggestion(
        CompletionSuggestionKind.INVOCATION,
        isDeprecated ? DART_RELEVANCE_LOW : relevance,
        completion,
        completion.length,
        0,
        isDeprecated,
        false,
        returnType: enumDeclaration.name.name);

    suggestionMap.putIfAbsent(suggestion.completion, () => suggestion);
    int flags = protocol.Element.makeFlags(
        isAbstract: isAbstract,
        isDeprecated: isDeprecated,
        isPrivate: Identifier.isPrivateName(constantDeclaration.name.name));
    suggestion.element = new protocol.Element(
        protocol.ElementKind.ENUM_CONSTANT,
        constantDeclaration.name.name,
        flags,
        location: new Location(
            request.source.fullName,
            constantDeclaration.name.offset,
            constantDeclaration.name.length,
            0,
            0));
  }

  void _addLocalSuggestion_includeReturnValueSuggestions(
      Comment documentationComment,
      SimpleIdentifier id,
      TypeAnnotation typeName,
      protocol.ElementKind elemKind,
      {bool isAbstract: false,
      bool isDeprecated: false,
      ClassDeclaration classDecl,
      FormalParameterList param,
      int relevance: DART_RELEVANCE_DEFAULT}) {
    relevance = optype.returnValueSuggestionsFilter(
        _staticTypeOfIdentifier(id), relevance);
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
      {bool isAbstract: false,
      bool isDeprecated: false,
      int relevance: DART_RELEVANCE_DEFAULT}) {
    ClassElement classElement =
        resolutionMap.elementDeclaredByEnumDeclaration(enumDeclaration);
    relevance =
        optype.returnValueSuggestionsFilter(classElement?.type, relevance);
    if (relevance != null) {
      _addLocalSuggestion_enumConstant(constantDeclaration, enumDeclaration,
          isAbstract: isAbstract,
          isDeprecated: isDeprecated,
          relevance: relevance);
    }
  }

  void _addLocalSuggestion_includeTypeNameSuggestions(
      Comment documentationComment,
      SimpleIdentifier id,
      TypeAnnotation typeName,
      protocol.ElementKind elemKind,
      {bool isAbstract: false,
      bool isDeprecated: false,
      ClassDeclaration classDecl,
      FormalParameterList param,
      int relevance: DART_RELEVANCE_DEFAULT}) {
    relevance = optype.typeNameSuggestionsFilter(
        _staticTypeOfIdentifier(id), relevance);
    if (relevance != null) {
      _addLocalSuggestion(documentationComment, id, typeName, elemKind,
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
      TypeAnnotation type = null;
      if (param is DefaultFormalParameter) {
        NormalFormalParameter child = param.parameter;
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
        Identifier typeId = type.name;
        if (typeId == null) {
          return 'dynamic';
        }
        return typeId.name;
      }
      // TODO(brianwilkerson) Support function types.
      return 'dynamic';
    }).toList();

    Iterable<ParameterElement> requiredParameters = paramList
        .where((FormalParameter param) => param.kind == ParameterKind.REQUIRED)
        .map((p) => p.element);
    suggestion.requiredParameterCount = requiredParameters.length;

    Iterable<ParameterElement> namedParameters = paramList
        .where((FormalParameter param) => param.kind == ParameterKind.NAMED)
        .map((p) => p.element);
    suggestion.hasNamedParameters = namedParameters.isNotEmpty;

    addDefaultArgDetails(suggestion, null, requiredParameters, namedParameters);
  }

  bool _isVoid(TypeAnnotation returnType) {
    if (returnType is TypeName) {
      Identifier id = returnType.name;
      if (id != null && id.name == 'void') {
        return true;
      }
    }
    return false;
  }

  DartType _staticTypeOfIdentifier(Identifier id) {
    if (id.staticElement is ClassElement) {
      return (id.staticElement as ClassElement).type;
    } else {
      return id.staticType;
    }
  }

  /**
   * If the given [documentationComment] is not `null`, fill the [suggestion]
   * documentation fields.
   */
  static void _setDocumentation(
      CompletionSuggestion suggestion, Comment documentationComment) {
    if (documentationComment != null) {
      String text = documentationComment.tokens
          .map((Token t) => t.toString())
          .join('\n')
          .replaceAll('\r\n', '\n');
      String doc = removeDartDocDelimiters(text);
      suggestion.docComplete = doc;
      suggestion.docSummary = getDartDocSummary(doc);
    }
  }
}
