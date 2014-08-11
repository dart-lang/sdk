// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.completion.computer.dart.local;

import 'dart:async';

import 'package:analysis_services/completion/completion_computer.dart';
import 'package:analysis_services/completion/completion_suggestion.dart';
import 'package:analyzer/src/generated/ast.dart';

/**
 * A computer for calculating `completion.getSuggestions` request results
 * for the local library in which the completion is requested.
 */
class LocalComputer extends CompletionComputer {

  @override
  bool computeFast(CompilationUnit unit,
      List<CompletionSuggestion> suggestions) {

    // Find the specific child [AstNode] that contains the completion offset
    // and collect suggestions starting with that node
    AstNode node = new NodeLocator.con1(offset).searchWithin(unit);
    if (node != null) {
      node.accept(new _LocalVisitor(offset, suggestions));
    }

    // If the unit is not a part and does not reference any parts
    // then work is complete
    return !unit.directives.any(
        (Directive directive) =>
            directive is PartOfDirective || directive is PartDirective);
  }

  @override
  Future<bool> computeFull(CompilationUnit unit,
      List<CompletionSuggestion> suggestions) {
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
  final int offset;
  final List<CompletionSuggestion> suggestions;

  _LocalVisitor(this.offset, this.suggestions);

  void addSuggestion(SimpleIdentifier id, CompletionSuggestionKind kind) {
    if (id != null) {
      String completion = id.name;
      if (completion != null && completion.length > 0) {
        suggestions.add(
            new CompletionSuggestion(
                kind,
                CompletionRelevance.DEFAULT,
                completion,
                completion.length,
                0,
                false,
                false));
      }
    }
  }

  void addSuggestions(VariableDeclarationList variables,
      CompletionSuggestionKind kind) {
    variables.variables.forEach((VariableDeclaration varDecl) {
      addSuggestion(varDecl.name, kind);
    });
  }

  visitBlock(Block node) {
    node.statements.forEach((Statement stmt) {
      if (stmt.offset < offset) {
        if (stmt is LabeledStatement) {
          stmt.labels.forEach((Label label) {
//            addSuggestion(label.label, CompletionSuggestionKind.LABEL);
          });
        } else if (stmt is VariableDeclarationStatement) {
          stmt.variables.variables.forEach((VariableDeclaration varDecl) {
            if (varDecl.end < offset) {
              addSuggestion(
                  varDecl.name,
                  CompletionSuggestionKind.LOCAL_VARIABLE);
            }
          });
        }
      }
    });
    visitNode(node);
  }

  visitCatchClause(CatchClause node) {
    addSuggestion(node.exceptionParameter, CompletionSuggestionKind.PARAMETER);
    addSuggestion(node.stackTraceParameter, CompletionSuggestionKind.PARAMETER);
    visitNode(node);
  }

  visitClassDeclaration(ClassDeclaration node) {
    node.members.forEach((ClassMember classMbr) {
      if (classMbr is FieldDeclaration) {
        addSuggestions(classMbr.fields, CompletionSuggestionKind.FIELD);
      } else if (classMbr is MethodDeclaration) {
        addSuggestion(classMbr.name, CompletionSuggestionKind.METHOD_NAME);
      }
    });
    visitNode(node);
  }

  visitCompilationUnit(CompilationUnit node) {
    node.directives.forEach((Directive directive) {
      if (directive is ImportDirective) {
        addSuggestion(
            directive.prefix,
            CompletionSuggestionKind.LIBRARY_PREFIX);
      }
    });
    node.declarations.forEach((Declaration declaration) {
      if (declaration is ClassDeclaration) {
        addSuggestion(declaration.name, CompletionSuggestionKind.CLASS);
      } else if (declaration is EnumDeclaration) {
//        addSuggestion(d.name, CompletionSuggestionKind.ENUM);
      } else if (declaration is FunctionDeclaration) {
        addSuggestion(declaration.name, CompletionSuggestionKind.FUNCTION);
      } else if (declaration is TopLevelVariableDeclaration) {
        addSuggestions(
            declaration.variables,
            CompletionSuggestionKind.TOP_LEVEL_VARIABLE);
      } else if (declaration is ClassTypeAlias) {
        addSuggestion(declaration.name, CompletionSuggestionKind.CLASS_ALIAS);
      } else if (declaration is FunctionTypeAlias) {
        addSuggestion(
            declaration.name,
            CompletionSuggestionKind.FUNCTION_TYPE_ALIAS);
      }
    });
  }

  visitForEachStatement(ForEachStatement node) {
    addSuggestion(node.identifier, CompletionSuggestionKind.LOCAL_VARIABLE);
    visitNode(node);
  }

  visitForStatement(ForStatement node) {
    addSuggestions(node.variables, CompletionSuggestionKind.LOCAL_VARIABLE);
    visitNode(node);
  }

  visitFunctionDeclaration(FunctionDeclaration node) {
    // This is added by the compilation unit containing it
    //addSuggestion(node.name, CompletionSuggestionKind.FUNCTION);
    visitNode(node);
  }

  visitFunctionExpression(FunctionExpression node) {
    node.parameters.parameters.forEach((FormalParameter param) {
      addSuggestion(param.identifier, CompletionSuggestionKind.PARAMETER);
    });
    visitNode(node);
  }

  visitMethodDeclaration(MethodDeclaration node) {
    node.parameters.parameters.forEach((FormalParameter param) {
      if (param.identifier != null) {
        addSuggestion(param.identifier, CompletionSuggestionKind.PARAMETER);
      }
    });
    visitNode(node);
  }

  visitNode(AstNode node) {
    node.parent.accept(this);
  }
}
