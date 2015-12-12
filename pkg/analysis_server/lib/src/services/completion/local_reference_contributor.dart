// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.completion.contributor.dart.local;

import 'dart:async';

import 'package:analysis_server/plugin/protocol/protocol.dart' as protocol
    show Element, ElementKind;
import 'package:analysis_server/plugin/protocol/protocol.dart'
    hide Element, ElementKind;
import 'package:analysis_server/src/services/completion/dart_completion_manager.dart';
import 'package:analysis_server/src/services/completion/local_declaration_visitor.dart';
import 'package:analysis_server/src/services/completion/local_suggestion_builder.dart';
import 'package:analysis_server/src/services/completion/optype.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';

/**
 * A contributor for calculating `completion.getSuggestions` request results
 * for the local library in which the completion is requested.
 */
class LocalReferenceContributor extends DartCompletionContributor {
  @override
  bool computeFast(DartCompletionRequest request) {
    // Don't suggest in comments.
    if (request.target.isCommentText) {
      return true;
    }

    OpType optype = request.optype;

    // Collect suggestions from the specific child [AstNode] that contains
    // the completion offset and all of its parents recursively.
    if (!optype.isPrefixed) {
      if (optype.includeReturnValueSuggestions ||
          optype.includeTypeNameSuggestions ||
          optype.includeVoidReturnSuggestions) {
        _LocalVisitor localVisitor =
            new _LocalVisitor(request, request.offset, optype);
        localVisitor.visit(request.target.containingNode);
      }
    }

    // If target is an argument in an argument list
    // then suggestions may need to be adjusted
    return request.target.argIndex == null;
  }

  @override
  Future<bool> computeFull(DartCompletionRequest request) {
    _updateSuggestions(request);
    return new Future.value(false);
  }

  /**
   * If target is a function argument, suggest identifiers not invocations
   */
  void _updateSuggestions(DartCompletionRequest request) {
    if (request.target.isFunctionalArgument()) {
      request.convertInvocationsToIdentifiers();
    }
  }
}

/**
 * A visitor for collecting suggestions from the most specific child [AstNode]
 * that contains the completion offset to the [CompilationUnit].
 */
class _LocalVisitor extends LocalDeclarationVisitor {
  final DartCompletionRequest request;
  final OpType optype;
  int privateMemberRelevance = DART_RELEVANCE_DEFAULT;

  _LocalVisitor(this.request, int offset, this.optype) : super(offset) {
    includeLocalInheritedTypes = !optype.inStaticMethodBody;
    if (request.replacementLength > 0) {
      var contents = request.context.getContents(request.source);
      if (contents != null &&
          contents.data != null &&
          contents.data.startsWith('_', request.replacementOffset)) {
        // If user typed identifier starting with '_'
        // then do not suppress the relevance of private members
        privateMemberRelevance = null;
      }
    }
  }

  @override
  void declaredClass(ClassDeclaration declaration) {
    if (optype.includeTypeNameSuggestions) {
      _addSuggestion(
          declaration.name, NO_RETURN_TYPE, protocol.ElementKind.CLASS,
          isAbstract: declaration.isAbstract,
          isDeprecated: isDeprecated(declaration));
    }
  }

  @override
  void declaredClassTypeAlias(ClassTypeAlias declaration) {
    if (optype.includeTypeNameSuggestions) {
      _addSuggestion(declaration.name, NO_RETURN_TYPE,
          protocol.ElementKind.CLASS_TYPE_ALIAS,
          isAbstract: true, isDeprecated: isDeprecated(declaration));
    }
  }

  @override
  void declaredEnum(EnumDeclaration declaration) {
    if (optype.includeTypeNameSuggestions) {
      _addSuggestion(
          declaration.name, NO_RETURN_TYPE, protocol.ElementKind.ENUM,
          isDeprecated: isDeprecated(declaration));
    }
  }

  @override
  void declaredField(FieldDeclaration fieldDecl, VariableDeclaration varDecl) {
    if (optype.includeReturnValueSuggestions &&
        (!optype.inStaticMethodBody || fieldDecl.isStatic)) {
      CompletionSuggestion suggestion =
          createFieldSuggestion(request.source, fieldDecl, varDecl);
      if (suggestion != null) {
        request.addSuggestion(suggestion);
      }
    }
  }

  @override
  void declaredFunction(FunctionDeclaration declaration) {
    if (optype.includeReturnValueSuggestions ||
        optype.includeVoidReturnSuggestions) {
      TypeName typeName = declaration.returnType;
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
      _addSuggestion(declaration.name, typeName, elemKind,
          isDeprecated: isDeprecated(declaration),
          param: declaration.functionExpression.parameters,
          relevance: relevance);
    }
  }

  @override
  void declaredFunctionTypeAlias(FunctionTypeAlias declaration) {
    if (optype.includeTypeNameSuggestions) {
      // TODO (danrubel) determine parameters and return type
      _addSuggestion(declaration.name, declaration.returnType,
          protocol.ElementKind.FUNCTION_TYPE_ALIAS,
          isAbstract: true, isDeprecated: isDeprecated(declaration));
    }
  }

  @override
  void declaredLabel(Label label, bool isCaseLabel) {
    // ignored
  }

  @override
  void declaredLocalVar(SimpleIdentifier id, TypeName typeName) {
    if (optype.includeReturnValueSuggestions) {
      _addSuggestion(id, typeName, protocol.ElementKind.LOCAL_VARIABLE,
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
      TypeName typeName = declaration.returnType;
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
      _addSuggestion(declaration.name, typeName, elemKind,
          isAbstract: declaration.isAbstract,
          isDeprecated: isDeprecated(declaration),
          classDecl: declaration.parent,
          param: param,
          relevance: relevance);
    }
  }

  @override
  void declaredParam(SimpleIdentifier id, TypeName typeName) {
    if (optype.includeReturnValueSuggestions) {
      _addSuggestion(id, typeName, protocol.ElementKind.PARAMETER,
          relevance: DART_RELEVANCE_PARAMETER);
    }
  }

  @override
  void declaredTopLevelVar(
      VariableDeclarationList varList, VariableDeclaration varDecl) {
    if (optype.includeReturnValueSuggestions) {
      _addSuggestion(
          varDecl.name, varList.type, protocol.ElementKind.TOP_LEVEL_VARIABLE,
          isDeprecated: isDeprecated(varList) || isDeprecated(varDecl),
          relevance: DART_RELEVANCE_LOCAL_TOP_LEVEL_VARIABLE);
    }
  }

  void _addParameterInfo(
      CompletionSuggestion suggestion, FormalParameterList parameters) {
    var paramList = parameters.parameters;
    suggestion.parameterNames = paramList
        .map((FormalParameter param) => param.identifier.name)
        .toList();
    suggestion.parameterTypes = paramList.map((FormalParameter param) {
      TypeName type = null;
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
      Identifier typeId = type.name;
      if (typeId == null) {
        return 'dynamic';
      }
      return typeId.name;
    }).toList();
    suggestion.requiredParameterCount = paramList
        .where((FormalParameter param) => param is! DefaultFormalParameter)
        .length;
    suggestion.hasNamedParameters = paramList
        .any((FormalParameter param) => param.kind == ParameterKind.NAMED);
  }

  void _addSuggestion(
      SimpleIdentifier id, TypeName typeName, protocol.ElementKind elemKind,
      {bool isAbstract: false,
      bool isDeprecated: false,
      ClassDeclaration classDecl,
      FormalParameterList param,
      int relevance: DART_RELEVANCE_DEFAULT}) {
    CompletionSuggestion suggestion = createSuggestion(
        id, isDeprecated, relevance, typeName,
        classDecl: classDecl);
    if (suggestion != null) {
      if (privateMemberRelevance != null &&
          suggestion.completion.startsWith('_')) {
        suggestion.relevance = privateMemberRelevance;
      }
      request.addSuggestion(suggestion);
      suggestion.element = createElement(request.source, elemKind, id,
          isAbstract: isAbstract,
          isDeprecated: isDeprecated,
          parameters: param != null ? param.toSource() : null,
          returnType: typeName);
      if ((elemKind == protocol.ElementKind.METHOD ||
              elemKind == protocol.ElementKind.FUNCTION) &&
          param != null) {
        _addParameterInfo(suggestion, param);
      }
    }
  }

  bool _isVoid(TypeName returnType) {
    if (returnType != null) {
      Identifier id = returnType.name;
      if (id != null && id.name == 'void') {
        return true;
      }
    }
    return false;
  }
}
