// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.completion.computer.dart.local;

import 'dart:async';

import 'package:analysis_server/src/protocol.dart' as protocol show Element,
    ElementKind;
import 'package:analysis_server/src/protocol.dart' hide Element, ElementKind;
import 'package:analysis_server/src/services/completion/dart_completion_manager.dart';
import 'package:analysis_server/src/services/completion/suggestion_builder.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/scanner.dart';

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
  static const DYNAMIC = 'dynamic';

  static final TypeName NO_RETURN_TYPE = new TypeName(
      new SimpleIdentifier(new StringToken(TokenType.IDENTIFIER, '', 0)),
      null);

  static final TypeName STACKTRACE_TYPE = new TypeName(
      new SimpleIdentifier(new StringToken(TokenType.IDENTIFIER, 'StackTrace', 0)),
      null);

  final DartCompletionRequest request;
  bool typesOnly = false;
  bool excludeVoidReturn;

  _LocalVisitor(this.request) {
    excludeVoidReturn = _computeExcludeVoidReturn(request.node);
  }

  @override
  visitBlock(Block node) {
    node.statements.forEach((Statement stmt) {
      if (stmt.offset < request.offset) {
        if (stmt is LabeledStatement) {
          stmt.labels.forEach((Label label) {
//            _addSuggestion(label.label, CompletionSuggestionKind.LABEL);
          });
        } else if (stmt is VariableDeclarationStatement) {
          var varList = stmt.variables;
          if (varList != null) {
            varList.variables.forEach((VariableDeclaration varDecl) {
              if (varDecl.end < request.offset) {
                _addLocalVarSuggestion(varDecl.name, varList.type);
              }
            });
          }
        }
      }
    });
    visitNode(node);
  }

  @override
  visitCascadeExpression(CascadeExpression node) {
    Expression target = node.target;
    // This computer handles the expression
    // while InvocationComputer handles the cascade selector
    if (target != null && request.offset <= target.end) {
      visitNode(node);
    }
  }

  @override
  visitCatchClause(CatchClause node) {
    _addParamSuggestion(node.exceptionParameter, node.exceptionType);
    _addParamSuggestion(node.stackTraceParameter, STACKTRACE_TYPE);
    visitNode(node);
  }

  @override
  visitClassDeclaration(ClassDeclaration node) {
    _addClassDeclarationMembers(node);
    visitInheritedTypes(node, (ClassDeclaration classNode) {
      _addClassDeclarationMembers(classNode);
    }, (String typeName) {
      // ignored
    });
    visitNode(node);
  }

  @override
  visitCombinator(Combinator node) {
    // Handled by ImportedComputer
  }

  @override
  visitCompilationUnit(CompilationUnit node) {
    node.declarations.forEach((Declaration declaration) {
      if (declaration is ClassDeclaration) {
        _addClassSuggestion(declaration);
      } else if (declaration is EnumDeclaration) {
//        _addSuggestion(d.name, CompletionSuggestionKind.ENUM);
      } else if (declaration is FunctionDeclaration) {
        _addFunctionSuggestion(declaration);
      } else if (declaration is TopLevelVariableDeclaration) {
        _addTopLevelVarSuggestions(declaration.variables);
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
    _addLocalVarSuggestion(id, type);
    visitNode(node);
  }

  @override
  visitForStatement(ForStatement node) {
    var varList = node.variables;
    if (varList != null) {
      varList.variables.forEach((VariableDeclaration varDecl) {
        _addLocalVarSuggestion(varDecl.name, varList.type);
      });
    }
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
  visitInterpolationExpression(InterpolationExpression node) {
    visitNode(node);
  }

  @override
  visitMethodDeclaration(MethodDeclaration node) {
    _addParamListSuggestions(node.parameters);
    visitNode(node);
  }

  @override
  visitMethodInvocation(MethodInvocation node) {
    // InvocationComputer adds suggestions for method selector
    Token period = node.period;
    if (period != null && period.offset < request.offset) {
      ArgumentList argumentList = node.argumentList;
      if (argumentList == null || request.offset <= argumentList.offset) {
        return;
      }
    }
    visitNode(node);
  }

  @override
  visitNamespaceDirective(NamespaceDirective node) {
    // No suggestions
  }

  @override
  visitNode(AstNode node) {
    node.parent.accept(this);
  }

  @override
  visitPrefixedIdentifier(PrefixedIdentifier node) {
    // InvocationComputer adds suggestions for prefixed elements
    // but this computer adds suggestions for the prefix itself
    SimpleIdentifier prefix = node.prefix;
    if (prefix == null || request.offset <= prefix.end) {
      visitNode(node);
    }
  }

  @override
  visitPropertyAccess(PropertyAccess node) {
    // InvocationComputer adds suggestions for property access selector
  }

  @override
  visitStringInterpolation(StringInterpolation node) {
    visitNode(node);
  }

  @override
  visitStringLiteral(StringLiteral node) {
    // ignore
  }

  @override
  visitTypeName(TypeName node) {
    // If suggesting completions within a TypeName node
    // then limit suggestions to only types
    typesOnly = true;
    return visitNode(node);
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

  void _addClassDeclarationMembers(ClassDeclaration node) {
    node.members.forEach((ClassMember classMbr) {
      if (classMbr is FieldDeclaration) {
        _addFieldSuggestions(node, classMbr);
      } else if (classMbr is MethodDeclaration) {
        _addMethodSuggestion(node, classMbr);
      }
    });
  }

  void _addClassSuggestion(ClassDeclaration declaration) {
    CompletionSuggestion suggestion =
        _addSuggestion(declaration.name, CompletionSuggestionKind.CLASS, null, null);
    if (suggestion != null) {
      suggestion.element = _createElement(
          protocol.ElementKind.CLASS,
          declaration.name,
          NO_RETURN_TYPE,
          declaration.isAbstract,
          _isDeprecated(declaration.metadata));
    }
  }

  void _addFieldSuggestions(ClassDeclaration node, FieldDeclaration fieldDecl) {
    if (typesOnly) {
      return;
    }
    bool isDeprecated = _isDeprecated(fieldDecl.metadata);
    fieldDecl.fields.variables.forEach((VariableDeclaration varDecl) {
      CompletionSuggestion suggestion = _addSuggestion(
          varDecl.name,
          CompletionSuggestionKind.GETTER,
          fieldDecl.fields.type,
          node);
      if (suggestion != null) {
        suggestion.element = _createElement(
            protocol.ElementKind.GETTER,
            varDecl.name,
            fieldDecl.fields.type,
            false,
            isDeprecated || _isDeprecated(varDecl.metadata));
      }
    });
  }

  void _addFunctionSuggestion(FunctionDeclaration declaration) {
    if (typesOnly) {
      return;
    }
    if (excludeVoidReturn && _isVoid(declaration.returnType)) {
      return;
    }
    CompletionSuggestion suggestion = _addSuggestion(
        declaration.name,
        CompletionSuggestionKind.FUNCTION,
        declaration.returnType,
        null);
    if (suggestion != null) {
      suggestion.element = _createElement(
          protocol.ElementKind.FUNCTION,
          declaration.name,
          declaration.returnType,
          false,
          _isDeprecated(declaration.metadata));
    }
  }

  void _addLocalVarSuggestion(SimpleIdentifier id, TypeName returnType) {
    if (typesOnly) {
      return;
    }
    CompletionSuggestion suggestion =
        _addSuggestion(id, CompletionSuggestionKind.LOCAL_VARIABLE, returnType, null);
    if (suggestion != null) {
      suggestion.element = _createElement(
          protocol.ElementKind.LOCAL_VARIABLE,
          id,
          returnType,
          false,
          false);
    }
  }

  void _addMethodSuggestion(ClassDeclaration node, MethodDeclaration classMbr) {
    if (typesOnly) {
      return;
    }
    protocol.ElementKind kind;
    CompletionSuggestionKind csKind;
    if (classMbr.isGetter) {
      kind = protocol.ElementKind.GETTER;
      csKind = CompletionSuggestionKind.GETTER;
    } else if (classMbr.isSetter) {
      if (excludeVoidReturn) {
        return;
      }
      kind = protocol.ElementKind.SETTER;
      csKind = CompletionSuggestionKind.SETTER;
    } else {
      if (excludeVoidReturn && _isVoid(classMbr.returnType)) {
        return;
      }
      kind = protocol.ElementKind.METHOD;
      csKind = CompletionSuggestionKind.METHOD;
    }
    CompletionSuggestion suggestion =
        _addSuggestion(classMbr.name, csKind, classMbr.returnType, node);
    if (suggestion != null) {
      suggestion.element = _createElement(
          kind,
          classMbr.name,
          classMbr.returnType,
          classMbr.isAbstract,
          _isDeprecated(classMbr.metadata));
    }
  }

  void _addParamListSuggestions(FormalParameterList paramList) {
    if (typesOnly) {
      return;
    }
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
        _addParamSuggestion(param.identifier, type);
      });
    }
  }

  void _addParamSuggestion(SimpleIdentifier identifier, TypeName type) {
    if (typesOnly) {
      return;
    }
    CompletionSuggestion suggestion =
        _addSuggestion(identifier, CompletionSuggestionKind.PARAMETER, type, null);
    if (suggestion != null) {
      suggestion.element =
          _createElement(protocol.ElementKind.PARAMETER, identifier, type, false, false);
    }
  }

  CompletionSuggestion _addSuggestion(SimpleIdentifier id,
      CompletionSuggestionKind kind, TypeName typeName, ClassDeclaration classDecl) {
    if (id != null) {
      String completion = id.name;
      if (completion != null && completion.length > 0 && completion != '_') {
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
        return suggestion;
      }
    }
    return null;
  }

  void _addTopLevelVarSuggestions(VariableDeclarationList varList) {
    if (typesOnly) {
      return;
    }
    if (varList != null) {
      bool isDeprecated = _isDeprecated(varList.metadata);
      varList.variables.forEach((VariableDeclaration varDecl) {
        CompletionSuggestion suggestion = _addSuggestion(
            varDecl.name,
            CompletionSuggestionKind.TOP_LEVEL_VARIABLE,
            varList.type,
            null);
        if (suggestion != null) {
          suggestion.element = _createElement(
              protocol.ElementKind.TOP_LEVEL_VARIABLE,
              varDecl.name,
              varList.type,
              false,
              isDeprecated || _isDeprecated(varDecl.metadata));
        }
      });
    }
  }

  bool _computeExcludeVoidReturn(AstNode node) {
    if (node is Block) {
      return false;
    } else if (node is SimpleIdentifier) {
      return node.parent is ExpressionStatement ? false : true;
    } else {
      return true;
    }
  }

  /**
   * Create a new protocol Element for inclusion in a completion suggestion.
   */
  protocol.Element _createElement(protocol.ElementKind kind,
      SimpleIdentifier id, TypeName returnType, bool isAbstract, bool isDeprecated) {
    String name = id.name;
    int flags = protocol.Element.makeFlags(
        isAbstract: isAbstract,
        isDeprecated: isDeprecated,
        isPrivate: Identifier.isPrivateName(name));
    return new protocol.Element(
        kind,
        name,
        flags,
        returnType: _nameForType(returnType));
  }

  /**
   * Return `true` if the @deprecated annotation is present
   */
  bool _isDeprecated(NodeList<Annotation> metadata) =>
      metadata != null &&
          metadata.any(
              (Annotation a) => a.name is SimpleIdentifier && a.name.name == 'deprecated');

  bool _isVoid(TypeName returnType) {
    if (returnType != null) {
      Identifier id = returnType.name;
      if (id != null && id.name == 'void') {
        return true;
      }
    }
    return false;
  }

  /**
   * Return the name for the given type.
   */
  String _nameForType(TypeName type) {
    if (type == NO_RETURN_TYPE) {
      return null;
    }
    if (type == null) {
      return DYNAMIC;
    }
    Identifier id = type.name;
    if (id == null) {
      return DYNAMIC;
    }
    String name = id.name;
    if (name == null || name.length <= 0) {
      return DYNAMIC;
    }
    TypeArgumentList typeArgs = type.typeArguments;
    if (typeArgs != null) {
      //TODO (danrubel) include type arguments
    }
    return name;
  }
}
