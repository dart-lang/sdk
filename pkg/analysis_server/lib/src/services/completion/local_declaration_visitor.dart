// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.completion.computer.dart.local.Declaration.visitor;

import 'package:analysis_server/src/services/completion/suggestion_builder.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/scanner.dart';

/**
 * `LocalDeclarationCollector` visits an [AstNode] and its parent recursively
 * along with any declarations in those nodes. Setting the [finished] flag
 * `true` will prevent further recursion.
 */
abstract class LocalDeclarationVisitor extends GeneralizingAstVisitor<bool> {

  static final TypeName STACKTRACE_TYPE = new TypeName(
      new SimpleIdentifier(new StringToken(TokenType.IDENTIFIER, 'StackTrace', 0)),
      null);

  final int offset;
  bool finished = false;

  LocalDeclarationVisitor(this.offset);

  void declaredClass(ClassDeclaration declaration);

  void declaredClassTypeAlias(ClassTypeAlias declaration);

  void declaredField(FieldDeclaration fieldDecl, VariableDeclaration varDecl);

  void declaredFunction(FunctionDeclaration declaration);

  void declaredFunctionTypeAlias(FunctionTypeAlias declaration);

  void declaredLabel(Label label);

  void declaredLocalVar(SimpleIdentifier name, TypeName type);

  void declaredMethod(MethodDeclaration declaration);

  void declaredParam(SimpleIdentifier name, TypeName type);

  void declaredTopLevelVar(VariableDeclarationList varList,
      VariableDeclaration varDecl);

  @override
  bool visitBlock(Block node) {
    node.statements.forEach((Statement stmt) {
      if (stmt.offset < offset) {
        if (stmt is LabeledStatement) {
          stmt.labels.forEach((Label label) {
            declaredLabel(label);
          });
        } else if (stmt is VariableDeclarationStatement) {
          VariableDeclarationList varList = stmt.variables;
          if (varList != null) {
            varList.variables.forEach((VariableDeclaration varDecl) {
              if (varDecl.end < offset) {
                declaredLocalVar(varDecl.name, varList.type);
              }
            });
          }
        }
      }
    });
    return visitNode(node);
  }

  @override
  bool visitCatchClause(CatchClause node) {
    SimpleIdentifier param = node.exceptionParameter;
    if (param != null) {
      declaredParam(param, node.exceptionType);
    }
    param = node.stackTraceParameter;
    if (param != null) {
      declaredParam(param, STACKTRACE_TYPE);
    }
    return visitNode(node);
  }

  @override
  bool visitClassDeclaration(ClassDeclaration node) {
    _visitClassDeclarationMembers(node);
    visitInheritedTypes(node, (ClassDeclaration classNode) {
      _visitClassDeclarationMembers(classNode);
    }, (String typeName) {
      // ignored
    });
    return visitNode(node);
  }

  @override
  bool visitCompilationUnit(CompilationUnit node) {
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
    return finished;
  }

  @override
  bool visitExpressionStatement(ExpressionStatement node) {
    Expression expression = node.expression;
    if (expression is SimpleIdentifier) {
      if (expression.end < offset) {
        return finished;
      }
    }
    return visitNode(node);
  }

  @override
  bool visitForEachStatement(ForEachStatement node) {
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
    return visitNode(node);
  }

  @override
  bool visitForStatement(ForStatement node) {
    VariableDeclarationList varList = node.variables;
    if (varList != null) {
      varList.variables.forEach((VariableDeclaration varDecl) {
        declaredLocalVar(varDecl.name, varList.type);
      });
    }
    return visitNode(node);
  }

  @override
  bool visitFunctionDeclaration(FunctionDeclaration node) {
    // declaredFunction is called by the compilation unit containing it
    return visitNode(node);
  }

  @override
  bool visitFunctionExpression(FunctionExpression node) {
    _visitParamList(node.parameters);
    return visitNode(node);
  }

  @override
  bool visitInterpolationExpression(InterpolationExpression node) {
    return visitNode(node);
  }

  @override
  bool visitMethodDeclaration(MethodDeclaration node) {
    _visitParamList(node.parameters);
    return visitNode(node);
  }

  @override
  bool visitNode(AstNode node) {
    if (finished) {
      return true;
    }
    return node.parent.accept(this);
  }

  @override
  bool visitStringInterpolation(StringInterpolation node) {
    return visitNode(node);
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
