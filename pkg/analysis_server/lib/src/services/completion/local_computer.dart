// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.completion.computer.dart.local;

import 'dart:async';

import 'package:analysis_server/src/protocol.dart' as protocol
    show Element, ElementKind;
import 'package:analysis_server/src/protocol.dart' hide Element, ElementKind;
import 'package:analysis_server/src/services/completion/dart_completion_manager.dart';
import 'package:analysis_server/src/services/completion/local_declaration_visitor.dart';
import 'package:analysis_server/src/services/completion/optype.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';

const _DYNAMIC = 'dynamic';

final TypeName _NO_RETURN_TYPE = new TypeName(
    new SimpleIdentifier(new StringToken(TokenType.IDENTIFIER, '', 0)), null);

/**
 * Create a new protocol Element for inclusion in a completion suggestion.
 */
protocol.Element _createElement(protocol.ElementKind kind, SimpleIdentifier id,
    {String parameters, TypeName returnType, bool isAbstract: false,
    bool isDeprecated: false}) {
  String name = id != null ? id.name : '';
  int flags = protocol.Element.makeFlags(
      isAbstract: isAbstract,
      isDeprecated: isDeprecated,
      isPrivate: Identifier.isPrivateName(name));
  return new protocol.Element(kind, name, flags,
      parameters: parameters, returnType: _nameForType(returnType));
}

/**
 * Return `true` if the @deprecated annotation is present
 */
bool _isDeprecated(AnnotatedNode node) {
  if (node != null) {
    NodeList<Annotation> metadata = node.metadata;
    if (metadata != null) {
      return metadata.any((Annotation a) {
        return a.name is SimpleIdentifier && a.name.name == 'deprecated';
      });
    }
  }
  return false;
}

/**
 * Return the name for the given type.
 */
String _nameForType(TypeName type) {
  if (type == _NO_RETURN_TYPE) {
    return null;
  }
  if (type == null) {
    return _DYNAMIC;
  }
  Identifier id = type.name;
  if (id == null) {
    return _DYNAMIC;
  }
  String name = id.name;
  if (name == null || name.length <= 0) {
    return _DYNAMIC;
  }
  TypeArgumentList typeArgs = type.typeArguments;
  if (typeArgs != null) {
    //TODO (danrubel) include type arguments
  }
  return name;
}

/**
 * A computer for calculating `completion.getSuggestions` request results
 * for the local library in which the completion is requested.
 */
class LocalComputer extends DartCompletionComputer {
  @override
  bool computeFast(DartCompletionRequest request) {
    OpType optype = request.optype;

    // Collect suggestions from the specific child [AstNode] that contains
    // the completion offset and all of its parents recursively.
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
  void declaredClassTypeAlias(ClassTypeAlias declaration) {
    // TODO: implement declaredClassTypeAlias
  }

  @override
  void declaredField(FieldDeclaration fieldDecl, VariableDeclaration varDecl) {
    // TODO: implement declaredField
  }

  @override
  void declaredFunction(FunctionDeclaration declaration) {
    // TODO: implement declaredFunction
  }

  @override
  void declaredFunctionTypeAlias(FunctionTypeAlias declaration) {
    // TODO: implement declaredFunctionTypeAlias
  }

  @override
  void declaredLabel(Label label, bool isCaseLabel) {
    // TODO: implement declaredLabel
  }

  @override
  void declaredLocalVar(SimpleIdentifier name, TypeName type) {
    // TODO: implement declaredLocalVar
  }

  @override
  void declaredMethod(MethodDeclaration declaration) {
    // TODO: implement declaredMethod
  }

  @override
  void declaredParam(SimpleIdentifier name, TypeName type) {
    // TODO: implement declaredParam
  }

  @override
  void declaredTopLevelVar(
      VariableDeclarationList varList, VariableDeclaration varDecl) {
    // TODO: implement declaredTopLevelVar
  }

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
    bool isDeprecated =
        constructorDecl != null && _isDeprecated(constructorDecl);
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
    protocol.Element element = _createElement(
        protocol.ElementKind.CONSTRUCTOR, elemId,
        parameters: paramBuf.toString());
    element.returnType = classDecl.name.name;
    CompletionSuggestion suggestion = new CompletionSuggestion(
        CompletionSuggestionKind.INVOCATION,
        isDeprecated ? DART_RELEVANCE_LOW : DART_RELEVANCE_DEFAULT, completion,
        completion.length, 0, isDeprecated, false,
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
      return _nameForType(param.type);
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
                return _nameForType(member.fields.type);
              }
            }
          }
        }
      }
    }
    return _DYNAMIC;
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
        suggestion.element =
            _createElement(protocol.ElementKind.LABEL, label.label);
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

  /**
   * Create a new protocol Element for inclusion in a completion suggestion.
   */
  protocol.Element _createElement(
      protocol.ElementKind kind, SimpleIdentifier id) {
    String name = id.name;
    int flags =
        protocol.Element.makeFlags(isPrivate: Identifier.isPrivateName(name));
    return new protocol.Element(kind, name, flags);
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
      bool isDeprecated = _isDeprecated(declaration);
      CompletionSuggestion suggestion = _addSuggestion(declaration.name,
          _NO_RETURN_TYPE, isDeprecated, DART_RELEVANCE_DEFAULT);
      if (suggestion != null) {
        suggestion.element = _createElement(
            protocol.ElementKind.CLASS, declaration.name,
            returnType: _NO_RETURN_TYPE,
            isAbstract: declaration.isAbstract,
            isDeprecated: isDeprecated);
      }
    }
  }

  @override
  void declaredClassTypeAlias(ClassTypeAlias declaration) {
    if (optype.includeTypeNameSuggestions) {
      bool isDeprecated = _isDeprecated(declaration);
      CompletionSuggestion suggestion = _addSuggestion(declaration.name,
          _NO_RETURN_TYPE, isDeprecated, DART_RELEVANCE_DEFAULT);
      if (suggestion != null) {
        suggestion.element = _createElement(
            protocol.ElementKind.CLASS_TYPE_ALIAS, declaration.name,
            returnType: _NO_RETURN_TYPE,
            isAbstract: true,
            isDeprecated: isDeprecated);
      }
    }
  }

  @override
  void declaredField(FieldDeclaration fieldDecl, VariableDeclaration varDecl) {
    if (optype.includeReturnValueSuggestions) {
      bool isDeprecated = _isDeprecated(fieldDecl) || _isDeprecated(varDecl);
      TypeName type = fieldDecl.fields.type;
      CompletionSuggestion suggestion = _addSuggestion(
          varDecl.name, type, isDeprecated, DART_RELEVANCE_LOCAL_FIELD,
          classDecl: fieldDecl.parent);
      if (suggestion != null) {
        suggestion.element = _createElement(
            protocol.ElementKind.FIELD, varDecl.name,
            returnType: type, isDeprecated: isDeprecated);
      }
    }
  }

  @override
  void declaredFunction(FunctionDeclaration declaration) {
    if (optype.includeReturnValueSuggestions ||
        optype.includeVoidReturnSuggestions) {
      TypeName returnType = declaration.returnType;
      bool isDeprecated = _isDeprecated(declaration);
      protocol.ElementKind kind;
      int defaultRelevance = DART_RELEVANCE_DEFAULT;
      if (declaration.isGetter) {
        kind = protocol.ElementKind.GETTER;
        defaultRelevance = DART_RELEVANCE_LOCAL_ACCESSOR;
      } else if (declaration.isSetter) {
        if (!optype.includeVoidReturnSuggestions) {
          return;
        }
        kind = protocol.ElementKind.SETTER;
        returnType = _NO_RETURN_TYPE;
        defaultRelevance = DART_RELEVANCE_LOCAL_ACCESSOR;
      } else {
        if (!optype.includeVoidReturnSuggestions && _isVoid(returnType)) {
          return;
        }
        kind = protocol.ElementKind.FUNCTION;
        defaultRelevance = DART_RELEVANCE_LOCAL_FUNCTION;
      }
      CompletionSuggestion suggestion = _addSuggestion(
          declaration.name, returnType, isDeprecated, defaultRelevance);
      if (suggestion != null) {
        FormalParameterList param = declaration.functionExpression.parameters;
        suggestion.element = _createElement(kind, declaration.name,
            parameters: param != null ? param.toSource() : null,
            returnType: returnType,
            isDeprecated: isDeprecated);
        if (kind == protocol.ElementKind.FUNCTION) {
          _addParameterInfo(
              suggestion, declaration.functionExpression.parameters);
        }
      }
    }
  }

  @override
  void declaredFunctionTypeAlias(FunctionTypeAlias declaration) {
    if (optype.includeTypeNameSuggestions) {
      bool isDeprecated = _isDeprecated(declaration);
      TypeName returnType = declaration.returnType;
      CompletionSuggestion suggestion = _addSuggestion(
          declaration.name, returnType, isDeprecated, DART_RELEVANCE_DEFAULT);
      if (suggestion != null) {
        // TODO (danrubel) determine parameters and return type
        suggestion.element = _createElement(
            protocol.ElementKind.FUNCTION_TYPE_ALIAS, declaration.name,
            returnType: returnType,
            isAbstract: true,
            isDeprecated: isDeprecated);
      }
    }
  }

  @override
  void declaredLabel(Label label, bool isCaseLabel) {
    // ignored
  }

  @override
  void declaredLocalVar(SimpleIdentifier name, TypeName type) {
    if (optype.includeReturnValueSuggestions) {
      CompletionSuggestion suggestion =
          _addSuggestion(name, type, false, DART_RELEVANCE_LOCAL_VARIABLE);
      if (suggestion != null) {
        suggestion.element = _createElement(
            protocol.ElementKind.LOCAL_VARIABLE, name, returnType: type);
      }
    }
  }

  @override
  void declaredMethod(MethodDeclaration declaration) {
    if (optype.includeReturnValueSuggestions ||
        optype.includeVoidReturnSuggestions) {
      protocol.ElementKind kind;
      String parameters;
      TypeName returnType = declaration.returnType;
      int defaultRelevance = DART_RELEVANCE_DEFAULT;
      if (declaration.isGetter) {
        kind = protocol.ElementKind.GETTER;
        parameters = null;
        defaultRelevance = DART_RELEVANCE_LOCAL_ACCESSOR;
      } else if (declaration.isSetter) {
        if (!optype.includeVoidReturnSuggestions) {
          return;
        }
        kind = protocol.ElementKind.SETTER;
        returnType = _NO_RETURN_TYPE;
        defaultRelevance = DART_RELEVANCE_LOCAL_ACCESSOR;
      } else {
        if (!optype.includeVoidReturnSuggestions && _isVoid(returnType)) {
          return;
        }
        kind = protocol.ElementKind.METHOD;
        parameters = declaration.parameters.toSource();
        defaultRelevance = DART_RELEVANCE_LOCAL_METHOD;
      }
      bool isDeprecated = _isDeprecated(declaration);
      CompletionSuggestion suggestion = _addSuggestion(
          declaration.name, returnType, isDeprecated, defaultRelevance,
          classDecl: declaration.parent);
      if (suggestion != null) {
        suggestion.element = _createElement(kind, declaration.name,
            parameters: parameters,
            returnType: returnType,
            isAbstract: declaration.isAbstract,
            isDeprecated: isDeprecated);
        if (kind == protocol.ElementKind.METHOD) {
          _addParameterInfo(suggestion, declaration.parameters);
        }
      }
    }
  }

  @override
  void declaredParam(SimpleIdentifier name, TypeName type) {
    if (optype.includeReturnValueSuggestions) {
      CompletionSuggestion suggestion =
          _addSuggestion(name, type, false, DART_RELEVANCE_PARAMETER);
      if (suggestion != null) {
        suggestion.element = _createElement(
            protocol.ElementKind.PARAMETER, name, returnType: type);
      }
    }
  }

  @override
  void declaredTopLevelVar(
      VariableDeclarationList varList, VariableDeclaration varDecl) {
    if (optype.includeReturnValueSuggestions) {
      bool isDeprecated = _isDeprecated(varList) || _isDeprecated(varDecl);
      CompletionSuggestion suggestion = _addSuggestion(varDecl.name,
          varList.type, isDeprecated, DART_RELEVANCE_LOCAL_TOP_LEVEL_VARIABLE);
      if (suggestion != null) {
        suggestion.element = _createElement(
            protocol.ElementKind.TOP_LEVEL_VARIABLE, varDecl.name,
            returnType: varList.type, isDeprecated: isDeprecated);
      }
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

  CompletionSuggestion _addSuggestion(SimpleIdentifier id, TypeName returnType,
      bool isDeprecated, int defaultRelevance, {ClassDeclaration classDecl}) {
    if (id != null) {
      String completion = id.name;
      if (completion != null && completion.length > 0 && completion != '_') {
        CompletionSuggestion suggestion = new CompletionSuggestion(
            CompletionSuggestionKind.INVOCATION,
            isDeprecated ? DART_RELEVANCE_LOW : defaultRelevance, completion,
            completion.length, 0, isDeprecated, false,
            returnType: _nameForType(returnType));
        if (classDecl != null) {
          SimpleIdentifier identifier = classDecl.name;
          if (identifier != null) {
            String name = identifier.name;
            if (name != null && name.length > 0) {
              suggestion.declaringType = name;
            }
          }
        }
        request.addSuggestion(suggestion);
        return suggestion;
      }
    }
    return null;
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
