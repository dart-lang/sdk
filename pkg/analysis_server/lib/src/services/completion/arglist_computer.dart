// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.completion.computer.dart.arglist;

import 'dart:async';

import 'package:analysis_server/src/protocol_server.dart' hide Element,
    ElementKind;
import 'package:analysis_server/src/services/completion/dart_completion_manager.dart';
import 'package:analysis_server/src/services/completion/local_declaration_visitor.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/scanner.dart';

/**
 * A computer for calculating `completion.getSuggestions` request results
 * for the import combinators show and hide.
 */
class ArgListComputer extends DartCompletionComputer {
  _ArgListSuggestionBuilder builder;

  @override
  bool computeFast(DartCompletionRequest request) {
    builder = request.node.accept(new _ArgListAstVisitor(request));
    return builder == null;
  }

  @override
  Future<bool> computeFull(DartCompletionRequest request) {
    if (builder != null) {
      return builder.compute(request.node);
    }
    return new Future.value(false);
  }
}

/**
 * A visitor for determining whether an argument list suggestion is needed
 * and instantiating the builder to create the suggestion.
 */
class _ArgListAstVisitor extends
    GeneralizingAstVisitor<_ArgListSuggestionBuilder> {
  final DartCompletionRequest request;

  _ArgListAstVisitor(this.request);

  @override
  _ArgListSuggestionBuilder visitArgumentList(ArgumentList node) {
    Token leftParen = node.leftParenthesis;
    if (leftParen != null && request.offset > leftParen.offset) {
      AstNode parent = node.parent;
      if (parent is MethodInvocation) {
        SimpleIdentifier selector = parent.methodName;
        if (selector != null) {
          String name = selector.name;
          if (name != null && name.length > 0) {
            if (parent.period == null) {
              /*
               * If a local declaration is found, then return null
               * indicating that suggestions were added
               * and no further action is necessary
               */
              if (node.accept(
                  new _LocalDeclarationFinder(request, request.offset, name))) {
                return null;
              }
            } else {
              // determine target
            }
          }
        }
      }
      return new _ArgListSuggestionBuilder(request);
    }
    return null;
  }

  @override
  _ArgListSuggestionBuilder visitNode(AstNode node) {
    return null;
  }
}

/**
 * A `_ArgListSuggestionBuilder` determines which method or function is being
 * invoked, then builds the argument list suggestion.
 * This operation is instantiated during `computeFast`
 * and calculates the suggestions during `computeFull`.
 */
class _ArgListSuggestionBuilder {
  final DartCompletionRequest request;

  _ArgListSuggestionBuilder(this.request);

  Future<bool> compute(ArgumentList node) {
    return new Future.value(false);
  }
}

/**
 * `_LocalDeclarationFinder` visits an [AstNode] and its parent recursively
 * looking for a matching declaration. If found, it adds the appropriate
 * suggestions and sets finished to `true`.
 */
class _LocalDeclarationFinder extends LocalDeclarationVisitor {

  final DartCompletionRequest request;
  final String name;

  _LocalDeclarationFinder(this.request, int offset, this.name) : super(offset);

  @override
  void declaredClass(ClassDeclaration declaration) {
  }

  @override
  void declaredClassTypeAlias(ClassTypeAlias declaration) {
  }

  @override
  void declaredField(FieldDeclaration fieldDecl, VariableDeclaration varDecl) {
  }

  @override
  void declaredFunction(FunctionDeclaration declaration) {
    SimpleIdentifier selector = declaration.name;
    if (selector != null && name == selector.name) {
      finished = true;
      _addArgListSuggestion(declaration.functionExpression.parameters);
    }
  }

  @override
  void declaredFunctionTypeAlias(FunctionTypeAlias declaration) {
  }

  @override
  void declaredLabel(Label label) {
  }

  @override
  void declaredLocalVar(SimpleIdentifier name, TypeName type) {
  }

  @override
  void declaredMethod(MethodDeclaration declaration) {
    SimpleIdentifier selector = declaration.name;
    if (selector != null && name == selector.name) {
      finished = true;
      _addArgListSuggestion(declaration.parameters);
    }
  }

  @override
  void declaredParam(SimpleIdentifier name, TypeName type) {
  }

  @override
  void declaredTopLevelVar(VariableDeclarationList varList,
      VariableDeclaration varDecl) {
  }

  void _addArgListSuggestion(FormalParameterList parameters) {
    if (parameters.parameters.length == 0) {
      return;
    }
    StringBuffer completion = new StringBuffer('(');
    List<String> paramNames = new List<String>();
    List<String> paramTypes = new List<String>();
    for (FormalParameter param in parameters.parameters) {
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
        CompletionSuggestionKind.ARGUMENT_LIST,
        CompletionRelevance.HIGH,
        completion.toString(),
        completion.length,
        0,
        false,
        false);
    suggestion.parameterNames = paramNames;
    suggestion.parameterTypes = paramTypes;
    request.suggestions.add(suggestion);
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
