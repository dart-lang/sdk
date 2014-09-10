// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.completion.computer.dart.local;

import 'dart:async';

import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_server/src/services/completion/dart_completion_manager.dart';
import 'package:analyzer/src/generated/ast.dart';

/**
 * A computer for calculating `completion.getSuggestions` request results
 * for the local library in which the completion is requested.
 */
class LocalComputer extends DartCompletionComputer {

  @override
  bool computeFast(DartCompletionRequest request) {

    // Find the specific child [AstNode] that contains the completion offset
    // and collect suggestions starting with that node
    request.node.accept(new _LocalVisitor(request));

    // If the unit is not a part and does not reference any parts
    // then work is complete
    return !request.unit.directives.any(
        (Directive directive) =>
            directive is PartOfDirective || directive is PartDirective);
  }

  @override
  Future<bool> computeFull(DartCompletionRequest request) {
    // TODO: implement computeFull
    // include results from part files that are included in the library
    return new Future.value(false);
  }
}

/**
 * A visitor for collecting suggestions from the most specific child [AstNode]
 * that contains the completion offset to the [CompilationUnit].
 */
class _LocalVisitor extends GeneralizingAstVisitor<dynamic> {
  final DartCompletionRequest request;

  _LocalVisitor(this.request);

  @override
  visitBlock(Block node) {
    node.statements.forEach((Statement stmt) {
      if (stmt.offset < request.offset) {
        if (stmt is LabeledStatement) {
          stmt.labels.forEach((Label label) {
//            _addSuggestion(label.label, CompletionSuggestionKind.LABEL);
          });
        } else if (stmt is VariableDeclarationStatement) {
          VariableDeclarationList varList = stmt.variables;
          if (varList != null) {
            varList.variables.forEach((VariableDeclaration varDecl) {
              if (varDecl.end < request.offset) {
                _addSuggestion(
                    varDecl.name,
                    CompletionSuggestionKind.LOCAL_VARIABLE,
                    varList.type,
                    null);
              }
            });
          }
        }
      }
    });
    visitNode(node);
  }

  @override
  visitCatchClause(CatchClause node) {
    _addSuggestion(
        node.exceptionParameter,
        CompletionSuggestionKind.PARAMETER,
        node.exceptionType,
        null);
    // TODO (danrubel) add stack trace types
    _addSuggestion(
        node.stackTraceParameter,
        CompletionSuggestionKind.PARAMETER,
        null,
        null);
    visitNode(node);
  }

  @override
  visitClassDeclaration(ClassDeclaration node) {
    node.members.forEach((ClassMember classMbr) {
      if (classMbr is FieldDeclaration) {
        _addVarListSuggestions(
            classMbr.fields,
            CompletionSuggestionKind.FIELD,
            node);
      } else if (classMbr is MethodDeclaration) {
        _addSuggestion(
            classMbr.name,
            CompletionSuggestionKind.METHOD_NAME,
            classMbr.returnType,
            node);
      }
    });
    visitNode(node);
  }

  @override
  visitCompilationUnit(CompilationUnit node) {
    node.directives.forEach((Directive directive) {
      if (directive is ImportDirective) {
        _addSuggestion(
            directive.prefix,
            CompletionSuggestionKind.LIBRARY_PREFIX,
            null,
            null);
      }
    });
    node.declarations.forEach((Declaration declaration) {
      if (declaration is ClassDeclaration) {
        _addSuggestion(
            declaration.name,
            CompletionSuggestionKind.CLASS,
            null,
            null);
      } else if (declaration is EnumDeclaration) {
//        _addSuggestion(d.name, CompletionSuggestionKind.ENUM);
      } else if (declaration is FunctionDeclaration) {
        _addSuggestion(
            declaration.name,
            CompletionSuggestionKind.FUNCTION,
            declaration.returnType,
            null);
      } else if (declaration is TopLevelVariableDeclaration) {
        _addVarListSuggestions(
            declaration.variables,
            CompletionSuggestionKind.TOP_LEVEL_VARIABLE,
            null);
      } else if (declaration is ClassTypeAlias) {
        _addSuggestion(
            declaration.name,
            CompletionSuggestionKind.CLASS_ALIAS,
            null,
            null);
      } else if (declaration is FunctionTypeAlias) {
        _addSuggestion(
            declaration.name,
            CompletionSuggestionKind.FUNCTION_TYPE_ALIAS,
            declaration.returnType,
            null);
      }
    });
  }

  @override
  visitExpressionStatement(ExpressionStatement node) {
    Expression expression = node.expression;
    if (expression is SimpleIdentifier) {
      if (expression.end < request.offset) {
        // TODO (danrubel) suggest possible names for variable declaration
        // based upon variable type
        return;
      }
    }
    visitNode(node);
  }

  @override
  visitForEachStatement(ForEachStatement node) {
    // TODO (danrubel) supply type of local variable
    _addSuggestion(
        node.identifier,
        CompletionSuggestionKind.LOCAL_VARIABLE,
        null,
        null);
    visitNode(node);
  }

  @override
  visitForStatement(ForStatement node) {
    _addVarListSuggestions(
        node.variables,
        CompletionSuggestionKind.LOCAL_VARIABLE,
        null);
    visitNode(node);
  }

  @override
  visitFunctionDeclaration(FunctionDeclaration node) {
    // This is added by the compilation unit containing it
    //_addSuggestion(node.name, CompletionSuggestionKind.FUNCTION);
    visitNode(node);
  }

  @override
  visitFunctionExpression(FunctionExpression node) {
    _addParamListSuggestions(node.parameters);
    visitNode(node);
  }

  @override
  visitMethodDeclaration(MethodDeclaration node) {
    _addParamListSuggestions(node.parameters);
    visitNode(node);
  }

  @override
  visitNode(AstNode node) {
    node.parent.accept(this);
  }

  @override
  visitVariableDeclaration(VariableDeclaration node) {
    // Do not add suggestions if editing the name in a var declaration
    SimpleIdentifier name = node.name;
    if (name == null ||
        name.offset < request.offset ||
        request.offset > name.end) {
      visitNode(node);
    }
  }

  void _addParamListSuggestions(FormalParameterList paramList) {
    if (paramList != null) {
      paramList.parameters.forEach((FormalParameter param) {
        NormalFormalParameter normalParam;
        if (param is DefaultFormalParameter) {
          normalParam = param.parameter;
        } else if (param is NormalFormalParameter) {
          normalParam = param;
        }
        TypeName type = null;
        if (normalParam is FieldFormalParameter) {
          type = normalParam.type;
        } else if (normalParam is FunctionTypedFormalParameter) {
          type = normalParam.returnType;
        } else if (normalParam is SimpleFormalParameter) {
          type = normalParam.type;
        }
        _addSuggestion(
            param.identifier,
            CompletionSuggestionKind.PARAMETER,
            type,
            null);
      });
    }
  }

  void _addSuggestion(SimpleIdentifier id, CompletionSuggestionKind kind,
      TypeName typeName, ClassDeclaration classDecl) {
    if (id != null) {
      String completion = id.name;
      if (completion != null && completion.length > 0) {
        CompletionSuggestion suggestion = new CompletionSuggestion(
            kind,
            CompletionRelevance.DEFAULT,
            completion,
            completion.length,
            0,
            false,
            false);
        if (classDecl != null) {
          SimpleIdentifier identifier = classDecl.name;
          if (identifier != null) {
            String name = identifier.name;
            if (name != null && name.length > 0) {
              suggestion.declaringType = name;
            }
          }
        }
        if (typeName != null) {
          Identifier identifier = typeName.name;
          if (identifier != null) {
            String name = identifier.name;
            if (name != null && name.length > 0) {
              suggestion.returnType = name;
            }
          }
        }
        request.suggestions.add(suggestion);
      }
    }
  }

  void _addVarListSuggestions(VariableDeclarationList variables,
      CompletionSuggestionKind kind, ClassDeclaration classDecl) {
    variables.variables.forEach((VariableDeclaration varDecl) {
      _addSuggestion(varDecl.name, kind, variables.type, classDecl);
    });
  }
}
