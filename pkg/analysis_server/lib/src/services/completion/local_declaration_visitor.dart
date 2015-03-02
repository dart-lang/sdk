// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.completion.computer.dart.local.Declaration.visitor;

import 'package:analysis_server/src/services/completion/suggestion_builder.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/scanner.dart';

/**
 * `LocalDeclarationCollector` visits an [AstNode] and its parent recursively
 * along with any declarations in those nodes. Consumers typically call [visit]
 * which catches the exception thrown by [finished()].
 */
abstract class LocalDeclarationVisitor extends GeneralizingAstVisitor {
  static final TypeName STACKTRACE_TYPE = new TypeName(new SimpleIdentifier(
      new StringToken(TokenType.IDENTIFIER, 'StackTrace', 0)), null);

  final int offset;

  LocalDeclarationVisitor(this.offset);

  void declaredClass(ClassDeclaration declaration);

  void declaredClassTypeAlias(ClassTypeAlias declaration);

  void declaredField(FieldDeclaration fieldDecl, VariableDeclaration varDecl);

  void declaredFunction(FunctionDeclaration declaration);

  void declaredFunctionTypeAlias(FunctionTypeAlias declaration);

  void declaredLabel(Label label, bool isCaseLabel);

  void declaredLocalVar(SimpleIdentifier name, TypeName type);

  void declaredMethod(MethodDeclaration declaration);

  void declaredParam(SimpleIdentifier name, TypeName type);

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
    for (Statement stmt in node.statements) {
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
    visitInheritedTypes(node, (ClassDeclaration classNode) {
      _visitClassDeclarationMembers(classNode);
    }, (String typeName) {
      // ignored
    });
    visitNode(node);
  }

  @override
  void visitCompilationUnit(CompilationUnit node) {
    node.declarations.forEach((Declaration declaration) {
      if (declaration is ClassDeclaration) {
        declaredClass(declaration);
      } else if (declaration is EnumDeclaration) {
        // TODO (danrubel) enum support
//        declaredEnum(........)
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
  void visitForEachStatement(ForEachStatement node) {
    SimpleIdentifier id;
    TypeName type;
    DeclaredIdentifier loopVar = node.loopVariable;
    if (loopVar != null) {
      id = loopVar.identifier;
      type = loopVar.type;
    } else {
      id = node.identifier;
      type = null;
    }
    declaredLocalVar(id, type);
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
  void visitSwitchStatement(SwitchStatement node) {
    for (SwitchMember member in node.members) {
      for (Label label in member.labels) {
        declaredLabel(label, true);
      }
    }
    visitNode(node);
  }

  void _visitClassDeclarationMembers(ClassDeclaration node) {
    node.members.forEach((ClassMember member) {
      if (member is FieldDeclaration) {
        member.fields.variables.forEach((VariableDeclaration varDecl) {
          declaredField(member, varDecl);
        });
      } else if (member is MethodDeclaration) {
        declaredMethod(member);
      }
    });
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
        TypeName type = null;
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
}

/**
 * Internal exception used to indicate that [LocalDeclarationVisitor]
 * should stop visiting.
 */
class _LocalDeclarationVisitorFinished {}
