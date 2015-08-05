// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.completion.contributor.dart.local;

import 'dart:async';

import 'package:analysis_server/src/protocol.dart' as protocol
    show Element, ElementKind;
import 'package:analysis_server/src/protocol.dart' hide Element, ElementKind;
import 'package:analysis_server/src/services/completion/dart_completion_manager.dart';
import 'package:analysis_server/src/services/completion/local_declaration_visitor.dart';
import 'package:analysis_server/src/services/completion/local_suggestion_builder.dart';
import 'package:analysis_server/src/services/completion/optype.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';

/**
 * A contributor for calculating `completion.getSuggestions` request results
 * for the local library in which the completion is requested.
 */
class LocalReferenceContributor extends DartCompletionContributor {
  @override
  bool computeFast(DartCompletionRequest request) {
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
      if (optype.includeStatementLabelSuggestions ||
          optype.includeCaseLabelSuggestions) {
        _LabelVisitor labelVisitor = new _LabelVisitor(request,
            optype.includeStatementLabelSuggestions,
            optype.includeCaseLabelSuggestions);
        labelVisitor.visit(request.target.containingNode);
      }
      if (optype.includeConstructorSuggestions) {
        new _ConstructorVisitor(request).visit(request.target.containingNode);
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
 * A visitor for collecting constructor suggestions.
 */
class _ConstructorVisitor extends LocalDeclarationVisitor {
  final DartCompletionRequest request;

  _ConstructorVisitor(DartCompletionRequest request)
      : super(request.offset),
        request = request;

  @override
  void declaredClass(ClassDeclaration declaration) {
    bool found = false;
    for (ClassMember member in declaration.members) {
      if (member is ConstructorDeclaration) {
        found = true;
        _addSuggestion(declaration, member);
      }
    }
    if (!found) {
      _addSuggestion(declaration, null);
    }
  }

  @override
  void declaredClassTypeAlias(ClassTypeAlias declaration) {}

  @override
  void declaredField(FieldDeclaration fieldDecl, VariableDeclaration varDecl) {}

  @override
  void declaredFunction(FunctionDeclaration declaration) {}

  @override
  void declaredFunctionTypeAlias(FunctionTypeAlias declaration) {}

  @override
  void declaredLabel(Label label, bool isCaseLabel) {}

  @override
  void declaredLocalVar(SimpleIdentifier name, TypeName type) {}

  @override
  void declaredMethod(MethodDeclaration declaration) {}

  @override
  void declaredParam(SimpleIdentifier name, TypeName type) {}

  @override
  void declaredTopLevelVar(
      VariableDeclarationList varList, VariableDeclaration varDecl) {}

  /**
   * For the given class and constructor,
   * add a suggestion of the form B(...) or B.name(...).
   * If the given constructor is `null`
   * then add a default constructor suggestion.
   */
  CompletionSuggestion _addSuggestion(
      ClassDeclaration classDecl, ConstructorDeclaration constructorDecl) {
    SimpleIdentifier elemId;
    String completion = classDecl.name.name;
    if (constructorDecl != null) {
      elemId = constructorDecl.name;
      if (elemId != null) {
        String name = elemId.name;
        if (name != null && name.length > 0) {
          completion = '$completion.$name';
        }
      }
    }
    bool deprecated = constructorDecl != null && isDeprecated(constructorDecl);
    List<String> parameterNames = new List<String>();
    List<String> parameterTypes = new List<String>();
    int requiredParameterCount = 0;
    bool hasNamedParameters = false;
    StringBuffer paramBuf = new StringBuffer();
    paramBuf.write('(');
    int paramCount = 0;
    if (constructorDecl != null) {
      for (FormalParameter param in constructorDecl.parameters.parameters) {
        if (paramCount > 0) {
          paramBuf.write(', ');
        }
        String paramName;
        String typeName;
        if (param is NormalFormalParameter) {
          paramName = param.identifier.name;
          typeName = _nameForParamType(param);
          ++requiredParameterCount;
        } else if (param is DefaultFormalParameter) {
          NormalFormalParameter childParam = param.parameter;
          paramName = childParam.identifier.name;
          typeName = _nameForParamType(childParam);
          if (param.kind == ParameterKind.NAMED) {
            hasNamedParameters = true;
          }
          if (paramCount == requiredParameterCount) {
            paramBuf.write(hasNamedParameters ? '{' : '[');
          }
        }
        parameterNames.add(paramName);
        parameterTypes.add(typeName);
        paramBuf.write(typeName);
        paramBuf.write(' ');
        paramBuf.write(paramName);
        ++paramCount;
      }
    }
    if (paramCount > requiredParameterCount) {
      paramBuf.write(hasNamedParameters ? '}' : ']');
    }
    paramBuf.write(')');
    protocol.Element element = createElement(
        request.source, protocol.ElementKind.CONSTRUCTOR, elemId,
        parameters: paramBuf.toString());
    element.returnType = classDecl.name.name;
    CompletionSuggestion suggestion = new CompletionSuggestion(
        CompletionSuggestionKind.INVOCATION,
        deprecated ? DART_RELEVANCE_LOW : DART_RELEVANCE_DEFAULT, completion,
        completion.length, 0, deprecated, false,
        declaringType: classDecl.name.name,
        element: element,
        parameterNames: parameterNames,
        parameterTypes: parameterTypes,
        requiredParameterCount: requiredParameterCount,
        hasNamedParameters: hasNamedParameters);
    request.addSuggestion(suggestion);
    return suggestion;
  }

  /**
   * Determine the name of the type for the given constructor parameter.
   */
  String _nameForParamType(NormalFormalParameter param) {
    if (param is SimpleFormalParameter) {
      return nameForType(param.type);
    }
    SimpleIdentifier id = param.identifier;
    if (param is FieldFormalParameter && id != null) {
      String fieldName = id.name;
      AstNode classDecl = param.getAncestor((p) => p is ClassDeclaration);
      if (classDecl is ClassDeclaration) {
        for (ClassMember member in classDecl.members) {
          if (member is FieldDeclaration) {
            for (VariableDeclaration field in member.fields.variables) {
              if (field.name.name == fieldName) {
                return nameForType(member.fields.type);
              }
            }
          }
        }
      }
    }
    return DYNAMIC;
  }
}

/**
 * A visitor for collecting suggestions for break and continue labels.
 */
class _LabelVisitor extends LocalDeclarationVisitor {
  final DartCompletionRequest request;

  /**
   * True if statement labels should be included as suggestions.
   */
  final bool includeStatementLabels;

  /**
   * True if case labels should be included as suggestions.
   */
  final bool includeCaseLabels;

  _LabelVisitor(DartCompletionRequest request, this.includeStatementLabels,
      this.includeCaseLabels)
      : super(request.offset),
        request = request;

  @override
  void declaredClass(ClassDeclaration declaration) {
    // ignored
  }

  @override
  void declaredClassTypeAlias(ClassTypeAlias declaration) {
    // ignored
  }

  @override
  void declaredField(FieldDeclaration fieldDecl, VariableDeclaration varDecl) {
    // ignored
  }

  @override
  void declaredFunction(FunctionDeclaration declaration) {
    // ignored
  }

  @override
  void declaredFunctionTypeAlias(FunctionTypeAlias declaration) {
    // ignored
  }

  @override
  void declaredLabel(Label label, bool isCaseLabel) {
    if (isCaseLabel ? includeCaseLabels : includeStatementLabels) {
      CompletionSuggestion suggestion = _addSuggestion(label.label);
      if (suggestion != null) {
        suggestion.element = createElement(
            request.source, protocol.ElementKind.LABEL, label.label,
            returnType: NO_RETURN_TYPE);
      }
    }
  }

  @override
  void declaredLocalVar(SimpleIdentifier name, TypeName type) {
    // ignored
  }

  @override
  void declaredMethod(MethodDeclaration declaration) {
    // ignored
  }

  @override
  void declaredParam(SimpleIdentifier name, TypeName type) {
    // ignored
  }

  @override
  void declaredTopLevelVar(
      VariableDeclarationList varList, VariableDeclaration varDecl) {
    // ignored
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    // Labels are only accessible within the local function, so stop visiting
    // once we reach a function boundary.
    finished();
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    // Labels are only accessible within the local function, so stop visiting
    // once we reach a function boundary.
    finished();
  }

  CompletionSuggestion _addSuggestion(SimpleIdentifier id) {
    if (id != null) {
      String completion = id.name;
      if (completion != null && completion.length > 0 && completion != '_') {
        CompletionSuggestion suggestion = new CompletionSuggestion(
            CompletionSuggestionKind.IDENTIFIER, DART_RELEVANCE_DEFAULT,
            completion, completion.length, 0, false, false);
        request.addSuggestion(suggestion);
        return suggestion;
      }
    }
    return null;
  }
}

/**
 * A visitor for collecting suggestions from the most specific child [AstNode]
 * that contains the completion offset to the [CompilationUnit].
 */
class _LocalVisitor extends LocalDeclarationVisitor {
  final DartCompletionRequest request;
  final OpType optype;

  _LocalVisitor(this.request, int offset, this.optype) : super(offset);

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
    if (optype.includeReturnValueSuggestions) {
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
    if (optype.includeReturnValueSuggestions ||
        optype.includeVoidReturnSuggestions) {
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
    suggestion.requiredParameterCount = paramList.where(
        (FormalParameter param) => param is! DefaultFormalParameter).length;
    suggestion.hasNamedParameters = paramList
        .any((FormalParameter param) => param.kind == ParameterKind.NAMED);
  }

  void _addSuggestion(
      SimpleIdentifier id, TypeName typeName, protocol.ElementKind elemKind,
      {bool isAbstract: false, bool isDeprecated: false,
      ClassDeclaration classDecl, FormalParameterList param,
      int relevance: DART_RELEVANCE_DEFAULT}) {
    CompletionSuggestion suggestion = createSuggestion(
        id, isDeprecated, relevance, typeName, classDecl: classDecl);
    if (suggestion != null) {
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
