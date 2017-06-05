// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_ast_factory.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/src/dart/ast/token.dart';

/**
 * A visitor that visits an [AstNode] and its parent recursively along with any
 * declarations in those nodes. Consumers typically call [visit] which catches
 * the exception thrown by [finished].
 */
abstract class LocalDeclarationVisitor extends GeneralizingAstVisitor {
  static final TypeName STACKTRACE_TYPE = astFactory.typeName(
      astFactory.simpleIdentifier(
          new StringToken(TokenType.IDENTIFIER, 'StackTrace', 0)),
      null);

  final int offset;

  LocalDeclarationVisitor(this.offset);

  void declaredClass(ClassDeclaration declaration);

  void declaredClassTypeAlias(ClassTypeAlias declaration);

  void declaredEnum(EnumDeclaration declaration) {}

  void declaredField(FieldDeclaration fieldDecl, VariableDeclaration varDecl);

  void declaredFunction(FunctionDeclaration declaration);

  void declaredFunctionTypeAlias(FunctionTypeAlias declaration);

  void declaredLabel(Label label, bool isCaseLabel);

  void declaredLocalVar(SimpleIdentifier name, TypeAnnotation type);

  void declaredMethod(MethodDeclaration declaration);

  void declaredParam(SimpleIdentifier name, TypeAnnotation type);

  void declaredTopLevelVar(
      VariableDeclarationList varList, VariableDeclaration varDecl);

  /**
   * Throw an exception indicating that [LocalDeclarationVisitor] should
   * stop visiting. This is caught in [visit] which then exits normally.
   */
  void finished() {
    throw new _LocalDeclarationVisitorFinished();
  }

  /**
   * Visit the given [AstNode] and its parent recursively along with any
   * declarations in those nodes. Return `true` if [finished] is called
   * while visiting, else `false`.
   */
  bool visit(AstNode node) {
    try {
      node.accept(this);
      return false;
    } on _LocalDeclarationVisitorFinished {
      return true;
    }
  }

  @override
  void visitBlock(Block node) {
    _visitStatements(node.statements);
    visitNode(node);
  }

  @override
  void visitCatchClause(CatchClause node) {
    SimpleIdentifier param = node.exceptionParameter;
    if (param != null) {
      declaredParam(param, node.exceptionType);
    }
    param = node.stackTraceParameter;
    if (param != null) {
      declaredParam(param, STACKTRACE_TYPE);
    }
    visitNode(node);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    _visitClassDeclarationMembers(node);
    visitNode(node);
  }

  @override
  void visitCompilationUnit(CompilationUnit node) {
    node.declarations.forEach((Declaration declaration) {
      if (declaration is ClassDeclaration) {
        declaredClass(declaration);
      } else if (declaration is EnumDeclaration) {
        declaredEnum(declaration);
      } else if (declaration is FunctionDeclaration) {
        declaredFunction(declaration);
      } else if (declaration is TopLevelVariableDeclaration) {
        var varList = declaration.variables;
        if (varList != null) {
          varList.variables.forEach((VariableDeclaration varDecl) {
            declaredTopLevelVar(varList, varDecl);
          });
        }
      } else if (declaration is ClassTypeAlias) {
        declaredClassTypeAlias(declaration);
      } else if (declaration is FunctionTypeAlias) {
        declaredFunctionTypeAlias(declaration);
      }
    });
  }

  @override
  visitConstructorDeclaration(ConstructorDeclaration node) {
    _visitParamList(node.parameters);
    visitNode(node);
  }

  @override
  void visitForEachStatement(ForEachStatement node) {
    SimpleIdentifier id;
    TypeAnnotation type;
    DeclaredIdentifier loopVar = node.loopVariable;
    if (loopVar != null) {
      id = loopVar.identifier;
      type = loopVar.type;
    } else {
      id = node.identifier;
      type = null;
    }
    if (id != null) {
      // If there is no loop variable, don't declare it.
      declaredLocalVar(id, type);
    }
    visitNode(node);
  }

  @override
  void visitForStatement(ForStatement node) {
    VariableDeclarationList varList = node.variables;
    if (varList != null) {
      varList.variables.forEach((VariableDeclaration varDecl) {
        declaredLocalVar(varDecl.name, varList.type);
      });
    }
    visitNode(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    // declaredFunction is called by the compilation unit containing it
    visitNode(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    _visitParamList(node.parameters);
    visitNode(node);
  }

  @override
  void visitInterpolationExpression(InterpolationExpression node) {
    visitNode(node);
  }

  @override
  void visitLabeledStatement(LabeledStatement node) {
    for (Label label in node.labels) {
      declaredLabel(label, false);
    }
    visitNode(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _visitParamList(node.parameters);
    visitNode(node);
  }

  @override
  void visitNode(AstNode node) {
    node.parent.accept(this);
  }

  @override
  void visitStringInterpolation(StringInterpolation node) {
    visitNode(node);
  }

  @override
  void visitSwitchMember(SwitchMember node) {
    _visitStatements(node.statements);
    visitNode(node);
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    for (SwitchMember member in node.members) {
      for (Label label in member.labels) {
        declaredLabel(label, true);
      }
    }
    visitNode(node);
  }

  void _visitClassDeclarationMembers(ClassDeclaration node) {
    for (ClassMember member in node.members) {
      if (member is FieldDeclaration) {
        member.fields.variables.forEach((VariableDeclaration varDecl) {
          declaredField(member, varDecl);
        });
      } else if (member is MethodDeclaration) {
        declaredMethod(member);
      }
    }
  }

  void _visitParamList(FormalParameterList paramList) {
    if (paramList != null) {
      paramList.parameters.forEach((FormalParameter param) {
        NormalFormalParameter normalParam;
        if (param is DefaultFormalParameter) {
          normalParam = param.parameter;
        } else if (param is NormalFormalParameter) {
          normalParam = param;
        }
        TypeAnnotation type = null;
        if (normalParam is FieldFormalParameter) {
          type = normalParam.type;
        } else if (normalParam is FunctionTypedFormalParameter) {
          type = normalParam.returnType;
        } else if (normalParam is SimpleFormalParameter) {
          type = normalParam.type;
        }
        SimpleIdentifier name = param.identifier;
        declaredParam(name, type);
      });
    }
  }

  _visitStatements(NodeList<Statement> statements) {
    for (Statement stmt in statements) {
      if (stmt.offset < offset) {
        if (stmt is VariableDeclarationStatement) {
          VariableDeclarationList varList = stmt.variables;
          if (varList != null) {
            for (VariableDeclaration varDecl in varList.variables) {
              if (varDecl.end < offset) {
                declaredLocalVar(varDecl.name, varList.type);
              }
            }
          }
        } else if (stmt is FunctionDeclarationStatement) {
          FunctionDeclaration declaration = stmt.functionDeclaration;
          if (declaration != null && declaration.offset < offset) {
            SimpleIdentifier id = declaration.name;
            if (id != null) {
              String name = id.name;
              if (name != null && name.length > 0) {
                declaredFunction(declaration);
              }
            }
          }
        }
      }
    }
  }
}

/**
 * Internal exception used to indicate that [LocalDeclarationVisitor]
 * should stop visiting.
 */
class _LocalDeclarationVisitorFinished {}
