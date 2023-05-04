// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

/// A visitor that visits an [AstNode] and its parent recursively along with any
/// declarations in those nodes. Consumers typically call [visit] which catches
/// the exception thrown by [finished].
abstract class LocalDeclarationVisitor extends UnifyingAstVisitor {
  final int offset;

  LocalDeclarationVisitor(this.offset);

  void declaredClass(ClassDeclaration declaration) {}

  void declaredClassTypeAlias(ClassTypeAlias declaration) {}

  void declaredConstructor(ConstructorDeclaration declaration) {}

  void declaredEnum(EnumDeclaration declaration) {}

  void declaredExtension(ExtensionDeclaration declaration) {}

  void declaredField(FieldDeclaration fieldDecl, VariableDeclaration varDecl) {}

  void declaredFunction(FunctionDeclaration declaration) {}

  void declaredFunctionTypeAlias(FunctionTypeAlias declaration) {}

  void declaredGenericTypeAlias(GenericTypeAlias declaration) {}

  void declaredLabel(Label label, bool isCaseLabel) {}

  void declaredLocalVar(
    Token name,
    TypeAnnotation? type,
    LocalVariableElement declaredElement,
  ) {}

  void declaredMethod(MethodDeclaration declaration) {}

  void declaredMixin(MixinDeclaration declaration) {}

  void declaredParam(Token name, Element? element, TypeAnnotation? type) {}

  void declaredTopLevelVar(
      VariableDeclarationList varList, VariableDeclaration varDecl) {}

  void declaredTypeParameter(TypeParameter declaration) {}

  /// Throw an exception indicating that [LocalDeclarationVisitor] should
  /// stop visiting. This is caught in [visit] which then exits normally.
  void finished() {
    throw _LocalDeclarationVisitorFinished();
  }

  /// Visit the given [AstNode] and its parents recursively along with any
  /// declarations in those nodes. Return `true` if [finished] is called
  /// while visiting, else `false`.
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
    var exceptionParameter = node.exceptionParameter;
    if (exceptionParameter != null) {
      declaredParam(
        exceptionParameter.name,
        exceptionParameter.declaredElement,
        node.exceptionType,
      );
    }

    var stackTraceParameter = node.stackTraceParameter;
    if (stackTraceParameter != null) {
      declaredParam(
        stackTraceParameter.name,
        stackTraceParameter.declaredElement,
        null,
      );
    }

    visitNode(node);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    _visitClassOrMixinMembers(node.members);
    visitNode(node);
  }

  @override
  void visitCompilationUnit(CompilationUnit node) {
    _visitCompilationUnit(node);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    _visitParamList(node.parameters);
    visitNode(node);
  }

  @override
  void visitDeclaredVariablePattern(DeclaredVariablePattern node) {
    _visitDeclaredVariablePattern(node);
    visitNode(node);
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    _visitClassOrMixinMembers(node.members);
    visitNode(node);
  }

  @override
  void visitForElement(ForElement node) {
    var forLoopParts = node.forLoopParts;
    if (forLoopParts is ForEachPartsWithDeclaration) {
      var loopVariable = forLoopParts.loopVariable;
      declaredLocalVar(
          loopVariable.name, loopVariable.type, loopVariable.declaredElement!);
    } else if (forLoopParts is ForPartsWithDeclarations) {
      var varList = forLoopParts.variables;
      for (var varDecl in varList.variables) {
        declaredLocalVar(varDecl.name, varList.type,
            varDecl.declaredElement as LocalVariableElement);
      }
    }
    visitNode(node);
  }

  @override
  void visitForStatement(ForStatement node) {
    var forLoopParts = node.forLoopParts;
    if (forLoopParts is ForEachPartsWithDeclaration) {
      var loopVariable = forLoopParts.loopVariable;
      declaredLocalVar(
          loopVariable.name, loopVariable.type, loopVariable.declaredElement!);
    } else if (forLoopParts is ForPartsWithDeclarations) {
      var varList = forLoopParts.variables;
      for (var varDecl in varList.variables) {
        declaredLocalVar(varDecl.name, varList.type,
            varDecl.declaredElement as LocalVariableElement);
      }
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
    _visitTypeParameters(node, node.typeParameters);
    _visitParamList(node.parameters);
    visitNode(node);
  }

  @override
  void visitGenericFunctionType(GenericFunctionType node) {
    _visitTypeParameters(node, node.typeParameters);
    visitNode(node);
  }

  @override
  void visitIfElement(IfElement node) {
    var elseKeyword = node.elseKeyword;
    if (elseKeyword == null || offset < elseKeyword.offset) {
      var pattern = node.caseClause?.guardedPattern.pattern;
      if (pattern != null) {
        _visitVariablesIn(pattern);
      }
    }
    visitNode(node);
  }

  @override
  void visitIfStatement(IfStatement node) {
    var elseKeyword = node.elseKeyword;
    if (elseKeyword == null || offset < elseKeyword.offset) {
      var pattern = node.caseClause?.guardedPattern.pattern;
      if (pattern != null) {
        _visitVariablesIn(pattern);
      }
    }
    visitNode(node);
  }

  @override
  void visitInterpolationExpression(InterpolationExpression node) {
    visitNode(node);
  }

  @override
  void visitLabeledStatement(LabeledStatement node) {
    for (var label in node.labels) {
      declaredLabel(label, false);
    }
    visitNode(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _visitTypeParameters(node, node.typeParameters);
    _visitParamList(node.parameters);
    visitNode(node);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    _visitClassOrMixinMembers(node.members);
    visitNode(node);
  }

  @override
  void visitNode(AstNode node) {
    // Support the case of searching partial ASTs by aborting on nodes with no
    // parents. This is useful for the angular plugin.
    node.parent?.accept(this);
  }

  @override
  void visitStringInterpolation(StringInterpolation node) {
    visitNode(node);
  }

  @override
  void visitSwitchCase(SwitchCase node) {
    _visitStatements(node.statements);
    visitNode(node);
  }

  @override
  void visitSwitchDefault(SwitchDefault node) {
    _visitStatements(node.statements);
    visitNode(node);
  }

  @override
  void visitSwitchExpressionCase(SwitchExpressionCase node) {
    if (offset > node.arrow.end) {
      _visitVariablesIn(node.guardedPattern.pattern);
    }
    visitNode(node);
  }

  @override
  void visitSwitchPatternCase(SwitchPatternCase node) {
    _visitStatements(node.statements);
    visitNode(node);
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    var members = node.members;
    for (var member in members) {
      for (var label in member.labels) {
        declaredLabel(label, true);
      }
    }
    var first = true;
    for (var i = members.length - 1; i >= 0; i--) {
      var member = members[i];
      if (!first && member.statements.isNotEmpty) {
        break;
      }
      if (member is SwitchPatternCase && offset >= member.colon.end) {
        _visitVariablesIn(member.guardedPattern.pattern);
      } else {
        break;
      }
      first = false;
    }
    visitNode(node);
  }

  /// Recursively traverse the given [pattern], adding all of the declared
  /// variable patterns that appear in the structure to the list of [variables].
  void _addVariables(
      List<DeclaredVariablePattern> variables, DartPattern pattern) {
    if (pattern is CastPattern) {
      _addVariables(variables, pattern.pattern);
    } else if (pattern is DeclaredVariablePattern) {
      variables.add(pattern);
    } else if (pattern is ListPattern) {
      for (var element in pattern.elements) {
        if (element is DartPattern) {
          _addVariables(variables, element);
        } else if (element is RestPatternElement) {
          var elementPattern = element.pattern;
          if (elementPattern != null) {
            _addVariables(variables, elementPattern);
          }
        }
      }
    } else if (pattern is LogicalAndPattern) {
      _addVariables(variables, pattern.leftOperand);
      _addVariables(variables, pattern.rightOperand);
    } else if (pattern is LogicalOrPattern) {
      _addVariables(variables, pattern.leftOperand);
      _addVariables(variables, pattern.rightOperand);
    } else if (pattern is MapPattern) {
      for (var element in pattern.elements) {
        if (element is MapPatternEntry) {
          _addVariables(variables, element.value);
        } else if (element is RestPatternElement) {
          var elementPattern = element.pattern;
          if (elementPattern != null) {
            _addVariables(variables, elementPattern);
          }
        }
      }
    } else if (pattern is NullAssertPattern) {
      _addVariables(variables, pattern.pattern);
    } else if (pattern is NullCheckPattern) {
      _addVariables(variables, pattern.pattern);
    } else if (pattern is ObjectPattern) {
      for (var field in pattern.fields) {
        _addVariables(variables, field.pattern);
      }
    } else if (pattern is ParenthesizedPattern) {
      _addVariables(variables, pattern.pattern);
    } else if (pattern is RecordPattern) {
      for (var field in pattern.fields) {
        _addVariables(variables, field.pattern);
      }
    }
  }

  void _visitClassOrMixinMembers(List<ClassMember> members) {
    for (var member in members) {
      if (member is FieldDeclaration) {
        for (var varDecl in member.fields.variables) {
          declaredField(member, varDecl);
        }
      } else if (member is MethodDeclaration) {
        declaredMethod(member);
        _visitTypeParameters(member, member.typeParameters);
      }
    }
  }

  void _visitCompilationUnit(CompilationUnit node) {
    for (var declaration in node.declarations) {
      if (declaration is ClassDeclaration) {
        declaredClass(declaration);
        _visitTypeParameters(declaration, declaration.typeParameters);
        // Call declaredConstructor all ConstructorDeclarations when the class
        // is called: constructors are accessible if the class is accessible.
        for (var classDeclaration
            in node.declarations.whereType<ClassDeclaration>()) {
          for (var constructor
              in classDeclaration.members.whereType<ConstructorDeclaration>()) {
            declaredConstructor(constructor);
          }
        }
      } else if (declaration is EnumDeclaration) {
        declaredEnum(declaration);
      } else if (declaration is ExtensionDeclaration) {
        declaredExtension(declaration);
        _visitTypeParameters(declaration, declaration.typeParameters);
      } else if (declaration is FunctionDeclaration) {
        declaredFunction(declaration);
        _visitTypeParameters(
          declaration,
          declaration.functionExpression.typeParameters,
        );
      } else if (declaration is TopLevelVariableDeclaration) {
        var varList = declaration.variables;
        for (var varDecl in varList.variables) {
          declaredTopLevelVar(varList, varDecl);
        }
      } else if (declaration is ClassTypeAlias) {
        declaredClassTypeAlias(declaration);
        _visitTypeParameters(declaration, declaration.typeParameters);
      } else if (declaration is FunctionTypeAlias) {
        declaredFunctionTypeAlias(declaration);
        _visitTypeParameters(declaration, declaration.typeParameters);
      } else if (declaration is GenericTypeAlias) {
        declaredGenericTypeAlias(declaration);
        _visitTypeParameters(declaration, declaration.typeParameters);

        var type = declaration.type;
        if (type is GenericFunctionType) {
          _visitTypeParameters(type, type.typeParameters);
        }
      } else if (declaration is MixinDeclaration) {
        declaredMixin(declaration);
        _visitTypeParameters(declaration, declaration.typeParameters);
      }
    }
  }

  /// Visit the given [pattern] without visiting any of its parents.
  void _visitDeclaredVariablePattern(DeclaredVariablePattern pattern) {
    var declaredElement = pattern.declaredElement;
    if (declaredElement != null) {
      declaredLocalVar(pattern.name, pattern.type, declaredElement);
    }
  }

  void _visitParamList(FormalParameterList? paramList) {
    if (paramList != null) {
      for (var param in paramList.parameters) {
        NormalFormalParameter? normalParam;
        if (param is DefaultFormalParameter) {
          normalParam = param.parameter;
        } else if (param is NormalFormalParameter) {
          normalParam = param;
        }
        TypeAnnotation? type;
        if (normalParam is FieldFormalParameter) {
          type = normalParam.type;
        } else if (normalParam is FunctionTypedFormalParameter) {
          type = normalParam.returnType;
        } else if (normalParam is SimpleFormalParameter) {
          type = normalParam.type;
        }
        declaredParam(param.name!, param.declaredElement, type);
      }
    }
  }

  void _visitStatements(NodeList<Statement> statements) {
    for (var stmt in statements) {
      if (stmt.offset < offset) {
        if (stmt is VariableDeclarationStatement) {
          var varList = stmt.variables;
          for (var varDecl in varList.variables) {
            if (varDecl.end < offset) {
              declaredLocalVar(varDecl.name, varList.type,
                  varDecl.declaredElement as LocalVariableElement);
            }
          }
        } else if (stmt is FunctionDeclarationStatement) {
          var declaration = stmt.functionDeclaration;
          if (declaration.offset < offset) {
            var name = declaration.name.lexeme;
            if (name.isNotEmpty) {
              declaredFunction(declaration);
              _visitTypeParameters(
                declaration,
                declaration.functionExpression.typeParameters,
              );
            }
          }
        } else if (stmt is PatternVariableDeclarationStatement) {
          var declaration = stmt.declaration;
          if (declaration.end < offset) {
            _visitVariablesIn(declaration.pattern);
          }
        }
      }
    }
  }

  void _visitTypeParameters(AstNode node, TypeParameterList? typeParameters) {
    if (typeParameters == null) return;

    if (node.offset < offset && offset < node.end) {
      for (var typeParameter in typeParameters.typeParameters) {
        declaredTypeParameter(typeParameter);
      }
    }
  }

  void _visitVariablesIn(DartPattern pattern) {
    var variables = <DeclaredVariablePattern>[];
    _addVariables(variables, pattern);
    for (var variable in variables) {
      _visitDeclaredVariablePattern(variable);
    }
  }
}

/// Internal exception used to indicate that [LocalDeclarationVisitor]
/// should stop visiting.
class _LocalDeclarationVisitorFinished {}
