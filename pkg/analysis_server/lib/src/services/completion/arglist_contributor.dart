// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.completion.contributor.dart.arglist;

import 'dart:async';

import 'package:analysis_server/src/protocol_server.dart'
    hide Element, ElementKind;
import 'package:analysis_server/src/services/completion/dart_completion_manager.dart';
import 'package:analysis_server/src/services/completion/local_declaration_visitor.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';

void _addNamedParameterSuggestion(
    DartCompletionRequest request, List<String> namedArgs, String name) {
  if (name != null && name.length > 0 && !namedArgs.contains(name)) {
    request.addSuggestion(new CompletionSuggestion(
        CompletionSuggestionKind.NAMED_ARGUMENT, DART_RELEVANCE_NAMED_PARAMETER,
        '$name: ', name.length + 2, 0, false, false));
  }
}

/**
 * Determine the number of arguments.
 */
int _argCount(DartCompletionRequest request) {
  AstNode node = request.target.containingNode;
  if (node is ArgumentList) {
    return node.arguments.length;
  }
  return 0;
}

/**
 * Determine if the completion target is at the end of the list of arguments.
 */
bool _isAppendingToArgList(DartCompletionRequest request) {
  AstNode node = request.target.containingNode;
  if (node is ArgumentList) {
    var entity = request.target.entity;
    if (entity == node.rightParenthesis) {
      return true;
    }
    if (node.arguments.length > 0 && node.arguments.last == entity) {
      return entity is SimpleIdentifier;
    }
  }
  return false;
}

/**
 * Determine if the completion target is an emtpy argument list.
 */
bool _isEmptyArgList(DartCompletionRequest request) {
  AstNode node = request.target.containingNode;
  return node is ArgumentList &&
      node.leftParenthesis.next == node.rightParenthesis;
}

/**
 * Return a collection of currently specified named arguments
 */
Iterable<String> _namedArgs(DartCompletionRequest request) {
  AstNode node = request.target.containingNode;
  List<String> namedArgs = new List<String>();
  if (node is ArgumentList) {
    for (Expression arg in node.arguments) {
      if (arg is NamedExpression) {
        namedArgs.add(arg.name.label.name);
      }
    }
  }
  return namedArgs;
}

/**
 * A contributor for calculating `completion.getSuggestions` request results
 * when the cursor position is inside the arguments to a method call.
 */
class ArgListContributor extends DartCompletionContributor {
  _ArgSuggestionBuilder builder;

  @override
  bool computeFast(DartCompletionRequest request) {
    builder =
        request.target.containingNode.accept(new _ArgListAstVisitor(request));
    return builder == null;
  }

  @override
  Future<bool> computeFull(DartCompletionRequest request) {
    if (builder != null) {
      return builder.compute(request.target.containingNode);
    }
    return new Future.value(false);
  }
}

/**
 * A visitor for determining whether an argument list suggestion is needed
 * and instantiating the builder to create the suggestion.
 */
class _ArgListAstVisitor extends GeneralizingAstVisitor<_ArgSuggestionBuilder> {
  final DartCompletionRequest request;

  _ArgListAstVisitor(this.request);

  @override
  _ArgSuggestionBuilder visitArgumentList(ArgumentList node) {
    Token leftParen = node.leftParenthesis;
    if (leftParen != null && request.offset > leftParen.offset) {
      AstNode parent = node.parent;
      if (parent is MethodInvocation) {
        SimpleIdentifier selector = parent.methodName;
        if (selector != null) {
          String name = selector.name;
          if (name != null && name.length > 0) {
            if (parent.operator == null) {
              /*
               * If a local declaration is found, then return null
               * indicating that suggestions were added
               * and no further action is necessary
               */
              if (new _LocalArgSuggestionBuilder(request, request.offset, name)
                  .visit(node)) {
                return null;
              }
            } else {
              // determine target
            }
            return new _ArgSuggestionBuilder(request, name);
          }
        }
      }
      if (parent is InstanceCreationExpression) {
        ConstructorName constructorName = parent.constructorName;
        if (constructorName != null) {
          String name = constructorName.toSource();
          if (name.length > 0) {
            /*
             * If a local declaration is found, then return null
             * indicating that suggestions were added
             * and no further action is necessary
             */
            if (new _LocalArgSuggestionBuilder(request, request.offset, name)
                .visit(node)) {
              return null;
            }
            return new _ArgSuggestionBuilder(request, name);
          }
        }
      }
    }
    return null;
  }

  @override
  _ArgSuggestionBuilder visitNode(AstNode node) {
    return null;
  }
}

/**
 * A [_ArgSuggestionBuilder] determines which method or function is being
 * invoked, then builds the argument list suggestion.
 * This operation is instantiated during `computeFast`
 * and calculates the suggestions during `computeFull`.
 */
class _ArgSuggestionBuilder {
  final DartCompletionRequest request;
  final String methodName;

  _ArgSuggestionBuilder(this.request, this.methodName);

  Future<bool> compute(ArgumentList node) {
    AstNode parent = node.parent;
    if (parent is MethodInvocation) {
      SimpleIdentifier methodName = parent.methodName;
      if (methodName != null) {
        Element methodElem = methodName.bestElement;
        if (methodElem is ExecutableElement) {
          _addSuggestions(methodElem.parameters);
        }
      }
    }
    if (parent is InstanceCreationExpression) {
      ConstructorName constructorName = parent.constructorName;
      if (constructorName != null) {
        ConstructorElement element = constructorName.staticElement;
        if (element is ExecutableElement) {
          _addSuggestions(element.parameters);
        }
      }
    }
    return new Future.value(false);
  }

  void _addArgListSuggestion(Iterable<ParameterElement> requiredParam) {
    StringBuffer completion = new StringBuffer('(');
    List<String> paramNames = new List<String>();
    List<String> paramTypes = new List<String>();
    for (ParameterElement param in requiredParam) {
      String name = param.name;
      if (name != null && name.length > 0) {
        if (completion.length > 1) {
          completion.write(', ');
        }
        completion.write(name);
        paramNames.add(name);
        paramTypes.add(_getParamType(param));
      }
    }
    completion.write(')');
    CompletionSuggestion suggestion = new CompletionSuggestion(
        CompletionSuggestionKind.ARGUMENT_LIST, DART_RELEVANCE_HIGH,
        completion.toString(), completion.length, 0, false, false);
    suggestion.parameterNames = paramNames;
    suggestion.parameterTypes = paramTypes;
    request.addSuggestion(suggestion);
  }

  void _addDefaultParamSuggestions(Iterable<ParameterElement> parameters) {
    Iterable<String> namedArgs = _namedArgs(request);
    for (ParameterElement param in parameters) {
      if (param.parameterKind == ParameterKind.NAMED) {
        _addNamedParameterSuggestion(request, namedArgs, param.name);
      }
    }
  }

  void _addSuggestions(Iterable<ParameterElement> parameters) {
    if (parameters == null || parameters.length == 0) {
      return;
    }
    Iterable<ParameterElement> requiredParam = parameters.where(
        (ParameterElement p) => p.parameterKind == ParameterKind.REQUIRED);
    int requiredCount = requiredParam.length;
    if (requiredCount > 0 && _isEmptyArgList(request)) {
      _addArgListSuggestion(requiredParam);
      return;
    }
    if (_isAppendingToArgList(request)) {
      if (requiredCount == 0 || requiredCount < _argCount(request)) {
        _addDefaultParamSuggestions(parameters);
      }
    }
  }

  String _getParamType(ParameterElement param) {
    DartType type = param.type;
    if (type != null) {
      return type.displayName;
    }
    return 'dynamic';
  }
}

/**
 * [_LocalArgSuggestionBuilder] visits an [AstNode] and its parent recursively
 * looking for a matching declaration. If found, it adds the appropriate
 * suggestions and sets finished to `true`.
 */
class _LocalArgSuggestionBuilder extends LocalDeclarationVisitor {
  final DartCompletionRequest request;
  final String name;

  _LocalArgSuggestionBuilder(this.request, int offset, this.name)
      : super(offset);

  @override
  void declaredClass(ClassDeclaration declaration) {
    String className = null;
    if (declaration.name != null) {
      className = declaration.name.name;
    }
    if (className != null && className.length > 0) {
      for (ClassMember member in declaration.members) {
        if (member is ConstructorDeclaration) {
          String selector = className;
          if (member.name != null) {
            selector = '$selector.${member.name.name}';
          }
          if (selector == name) {
            _addSuggestions(member.parameters);
            finished();
          }
        }
      }
    }
  }

  @override
  void declaredClassTypeAlias(ClassTypeAlias declaration) {}

  @override
  void declaredField(FieldDeclaration fieldDecl, VariableDeclaration varDecl) {}

  @override
  void declaredFunction(FunctionDeclaration declaration) {
    SimpleIdentifier selector = declaration.name;
    if (selector != null && name == selector.name) {
      _addSuggestions(declaration.functionExpression.parameters);
      finished();
    }
  }

  @override
  void declaredFunctionTypeAlias(FunctionTypeAlias declaration) {}

  @override
  void declaredLabel(Label label, bool isCaseLabel) {}

  @override
  void declaredLocalVar(SimpleIdentifier name, TypeName type) {}

  @override
  void declaredMethod(MethodDeclaration declaration) {
    SimpleIdentifier selector = declaration.name;
    if (selector != null && name == selector.name) {
      _addSuggestions(declaration.parameters);
      finished();
    }
  }

  @override
  void declaredParam(SimpleIdentifier name, TypeName type) {}

  @override
  void declaredTopLevelVar(
      VariableDeclarationList varList, VariableDeclaration varDecl) {}

  void _addArgListSuggestion(Iterable<FormalParameter> requiredParam) {
    StringBuffer completion = new StringBuffer('(');
    List<String> paramNames = new List<String>();
    List<String> paramTypes = new List<String>();
    for (FormalParameter param in requiredParam) {
      SimpleIdentifier paramId = param.identifier;
      if (paramId != null) {
        String name = paramId.name;
        if (name != null && name.length > 0) {
          if (completion.length > 1) {
            completion.write(', ');
          }
          completion.write(name);
          paramNames.add(name);
          paramTypes.add(_getParamType(param));
        }
      }
    }
    completion.write(')');
    CompletionSuggestion suggestion = new CompletionSuggestion(
        CompletionSuggestionKind.ARGUMENT_LIST, DART_RELEVANCE_HIGH,
        completion.toString(), completion.length, 0, false, false);
    suggestion.parameterNames = paramNames;
    suggestion.parameterTypes = paramTypes;
    request.addSuggestion(suggestion);
  }

  void _addDefaultParamSuggestions(FormalParameterList parameters) {
    Iterable<String> namedArgs = _namedArgs(request);
    for (FormalParameter param in parameters.parameters) {
      if (param.kind == ParameterKind.NAMED) {
        SimpleIdentifier paramId = param.identifier;
        if (paramId != null) {
          _addNamedParameterSuggestion(request, namedArgs, paramId.name);
        }
      }
    }
  }

  void _addSuggestions(FormalParameterList parameters) {
    if (parameters == null || parameters.parameters.length == 0) {
      return;
    }
    Iterable<FormalParameter> requiredParam = parameters.parameters
        .where((FormalParameter p) => p.kind == ParameterKind.REQUIRED);
    int requiredCount = requiredParam.length;
    if (requiredCount > 0 && _isEmptyArgList(request)) {
      _addArgListSuggestion(requiredParam);
      return;
    }
    if (_isAppendingToArgList(request)) {
      if (requiredCount == 0 || requiredCount < _argCount(request)) {
        _addDefaultParamSuggestions(parameters);
      }
    }
  }

  String _getParamType(FormalParameter param) {
    TypeName type;
    if (param is SimpleFormalParameter) {
      type = param.type;
    }
    if (type != null) {
      Identifier id = type.name;
      if (id != null) {
        String name = id.name;
        if (name != null && name.length > 0) {
          return name;
        }
      }
    }
    return 'dynamic';
  }
}
