// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary2/ast_binary_reader.dart';
import 'package:analyzer/src/summary2/linked_bundle_context.dart';
import 'package:analyzer/src/summary2/reference.dart';

/// The context of a unit - the context of the bundle, and the unit tokens.
class LinkedUnitContext {
  final LinkedBundleContext bundleContext;
  final UnlinkedTokens tokens;

  LinkedUnitContext(this.bundleContext, this.tokens);

  Iterable<LinkedNode> classFields(LinkedNode class_) sync* {
    for (var declaration in class_.classOrMixinDeclaration_members) {
      if (declaration.kind == LinkedNodeKind.fieldDeclaration) {
        var variableList = declaration.fieldDeclaration_fields;
        for (var field in variableList.variableDeclarationList_variables) {
          yield field;
        }
      }
    }
  }

  String getCommentText(LinkedNode comment) {
    if (comment == null) return null;

    return comment.comment_tokens.map(getTokenLexeme).join('\n');
  }

  String getConstructorDeclarationName(LinkedNode node) {
    var name = node.constructorDeclaration_name;
    if (name != null) {
      return getSimpleName(name);
    }
    return '';
  }

  String getFormalParameterName(LinkedNode node) {
    return getSimpleName(node.normalFormalParameter_identifier);
  }

  List<LinkedNode> getFormalParameters(LinkedNode node) {
    LinkedNode parameterList;
    var kind = node.kind;
    if (kind == LinkedNodeKind.constructorDeclaration) {
      parameterList = node.constructorDeclaration_parameters;
    } else if (kind == LinkedNodeKind.functionDeclaration) {
      parameterList = node.functionDeclaration_functionExpression
          .functionExpression_formalParameters;
    } else if (kind == LinkedNodeKind.functionTypeAlias) {
      parameterList = node.functionTypeAlias_formalParameters;
    } else if (kind == LinkedNodeKind.methodDeclaration) {
      parameterList = node.methodDeclaration_formalParameters;
    } else {
      throw UnimplementedError('$kind');
    }
    return parameterList?.formalParameterList_parameters;
  }

  LinkedNode getImplementsClause(LinkedNode node) {
    var kind = node.kind;
    if (kind == LinkedNodeKind.classDeclaration) {
      return node.classOrMixinDeclaration_implementsClause;
    } else if (kind == LinkedNodeKind.classTypeAlias) {
      return node.classTypeAlias_implementsClause;
    } else {
      throw UnimplementedError('$kind');
    }
  }

  InterfaceType getInterfaceType(LinkedNodeType linkedType) {
    return bundleContext.getInterfaceType(linkedType);
  }

  String getMethodName(LinkedNode node) {
    return getSimpleName(node.methodDeclaration_name);
  }

  DartType getReturnType(LinkedNode node) {
    var kind = node.kind;
    if (kind == LinkedNodeKind.functionDeclaration) {
      return getType(node.functionDeclaration_returnType2);
    } else if (kind == LinkedNodeKind.methodDeclaration) {
      return getType(node.methodDeclaration_returnType2);
    } else {
      throw UnimplementedError('$kind');
    }
  }

  String getSimpleName(LinkedNode node) {
    return getTokenLexeme(node.simpleIdentifier_token);
  }

  int getSimpleOffset(LinkedNode node) {
    return tokens.offset[node.simpleIdentifier_token];
  }

  String getTokenLexeme(int token) {
    return tokens.lexeme[token];
  }

  DartType getType(LinkedNodeType linkedType) {
    return bundleContext.getType(linkedType);
  }

  DartType getTypeAnnotationType(LinkedNode node) {
    var kind = node.kind;
    if (kind == LinkedNodeKind.typeName) {
      return getType(node.typeName_type);
    } else {
      throw UnimplementedError('$kind');
    }
  }

  List<LinkedNode> getTypeParameters(LinkedNode node) {
    LinkedNode typeParameterList;
    var kind = node.kind;
    if (kind == LinkedNodeKind.classTypeAlias) {
      typeParameterList = node.classTypeAlias_typeParameters;
    } else if (kind == LinkedNodeKind.classDeclaration ||
        kind == LinkedNodeKind.mixinDeclaration) {
      typeParameterList = node.classOrMixinDeclaration_typeParameters;
    } else if (kind == LinkedNodeKind.functionDeclaration) {
      return getTypeParameters(node.functionDeclaration_functionExpression);
    } else if (kind == LinkedNodeKind.functionExpression) {
      typeParameterList = node.functionExpression_typeParameters;
    } else if (kind == LinkedNodeKind.functionTypeAlias) {
      typeParameterList = node.functionTypeAlias_typeParameters;
    } else if (kind == LinkedNodeKind.methodDeclaration) {
      typeParameterList = node.methodDeclaration_typeParameters;
    } else {
      throw UnimplementedError('$kind');
    }
    return typeParameterList?.typeParameterList_typeParameters;
  }

  String getUnitMemberName(LinkedNode node) {
    return getSimpleName(node.namedCompilationUnitMember_name);
  }

  String getVariableName(LinkedNode node) {
    return getSimpleName(node.variableDeclaration_name);
  }

  bool isAbstract(LinkedNode node) {
    return node.kind == LinkedNodeKind.methodDeclaration &&
        node.methodDeclaration_body.kind == LinkedNodeKind.emptyFunctionBody;
  }

  bool isAsynchronous(LinkedNode node) {
    LinkedNode body = _getFunctionBody(node);
    if (body.kind == LinkedNodeKind.blockFunctionBody) {
      return body.blockFunctionBody_keyword != 0;
    } else if (body.kind == LinkedNodeKind.emptyFunctionBody) {
      return false;
    } else {
      return body.expressionFunctionBody_keyword != 0;
    }
  }

  bool isConst(LinkedNode node) {
    var kind = node.kind;
    if (kind == LinkedNodeKind.variableDeclaration) {
      return node.variableDeclaration_declaration.isConst;
    }
    throw UnimplementedError('$kind');
  }

  bool isConstKeyword(int token) {
    return tokens.type[token] == UnlinkedTokenType.CONST;
  }

  bool isConstVariableList(LinkedNode node) {
    return isConstKeyword(node.variableDeclarationList_keyword);
  }

  bool isExternal(LinkedNode node) {
    var kind = node.kind;
    if (kind == LinkedNodeKind.constructorDeclaration) {
      return node.constructorDeclaration_externalKeyword != 0;
    } else if (kind == LinkedNodeKind.functionDeclaration) {
      return node.functionDeclaration_externalKeyword != 0;
    } else if (kind == LinkedNodeKind.methodDeclaration) {
      return node.methodDeclaration_externalKeyword != 0;
    } else {
      throw UnimplementedError('$kind');
    }
  }

  bool isFinal(LinkedNode node) {
    var kind = node.kind;
    if (kind == LinkedNodeKind.variableDeclaration) {
      return node.variableDeclaration_declaration.isFinal;
    }
    throw UnimplementedError('$kind');
  }

  bool isFinalKeyword(int token) {
    return tokens.type[token] == UnlinkedTokenType.FINAL;
  }

  bool isFinalVariableList(LinkedNode node) {
    return isFinalKeyword(node.variableDeclarationList_keyword);
  }

  bool isFunction(LinkedNode node) {
    return node.kind == LinkedNodeKind.functionDeclaration;
  }

  bool isGenerator(LinkedNode node) {
    LinkedNode body = _getFunctionBody(node);
    if (body.kind == LinkedNodeKind.blockFunctionBody) {
      return body.blockFunctionBody_star != 0;
    }
    return false;
  }

  bool isGetter(LinkedNode node) {
    return isGetterMethod(node) || isGetterFunction(node);
  }

  bool isGetterFunction(LinkedNode node) {
    return isFunction(node) &&
        _isGetToken(node.functionDeclaration_propertyKeyword);
  }

  bool isGetterMethod(LinkedNode node) {
    return isMethod(node) &&
        _isGetToken(node.methodDeclaration_propertyKeyword);
  }

  bool isLibraryKeyword(int token) {
    return tokens.type[token] == UnlinkedTokenType.LIBRARY;
  }

  bool isMethod(LinkedNode node) {
    return node.kind == LinkedNodeKind.methodDeclaration;
  }

  bool isSetter(LinkedNode node) {
    return isSetterMethod(node) || isSetterFunction(node);
  }

  bool isSetterFunction(LinkedNode node) {
    return isFunction(node) &&
        _isSetToken(node.functionDeclaration_propertyKeyword);
  }

  bool isSetterMethod(LinkedNode node) {
    return isMethod(node) &&
        _isSetToken(node.methodDeclaration_propertyKeyword);
  }

  bool isStatic(LinkedNode node) {
    var kind = node.kind;
    if (kind == LinkedNodeKind.functionDeclaration) {
      return true;
    } else if (kind == LinkedNodeKind.methodDeclaration) {
      return node.methodDeclaration_modifierKeyword != 0;
    } else if (kind == LinkedNodeKind.variableDeclaration) {
      return node.variableDeclaration_declaration.isStatic;
    }
    throw UnimplementedError('$kind');
  }

  void loadClassMemberReferences(Reference reference) {
    var node = reference.node;
    if (node.kind != LinkedNodeKind.classDeclaration &&
        node.kind != LinkedNodeKind.mixinDeclaration) {
      return;
    }

    var fieldContainerRef = reference.getChild('@field');
    var methodContainerRef = reference.getChild('@method');
    var getterContainerRef = reference.getChild('@getter');
    var setterContainerRef = reference.getChild('@setter');
    for (var member in node.classOrMixinDeclaration_members) {
      if (member.kind == LinkedNodeKind.fieldDeclaration) {
        var variableList = member.fieldDeclaration_fields;
        for (var field in variableList.variableDeclarationList_variables) {
          var name = getSimpleName(field.variableDeclaration_name);
          fieldContainerRef.getChild(name).node = field;
        }
      } else if (member.kind == LinkedNodeKind.methodDeclaration) {
        var name = getSimpleName(member.methodDeclaration_name);
        var propertyKeyword = member.methodDeclaration_propertyKeyword;
        if (_isGetToken(propertyKeyword)) {
          getterContainerRef.getChild(name).node = member;
        } else if (_isSetToken(propertyKeyword)) {
          setterContainerRef.getChild(name).node = member;
        } else {
          methodContainerRef.getChild(name).node = member;
        }
      }
    }
  }

  Expression readInitializer(LinkedNode linkedNode) {
    var reader = AstBinaryReader(
      bundleContext.elementFactory.rootReference,
      bundleContext.referencesData,
      tokens,
    );
    return reader.readNode(linkedNode.variableDeclaration_initializer);
  }

  Iterable<LinkedNode> topLevelVariables(LinkedNode unit) sync* {
    for (var declaration in unit.compilationUnit_declarations) {
      if (declaration.kind == LinkedNodeKind.topLevelVariableDeclaration) {
        var variableList = declaration.topLevelVariableDeclaration_variableList;
        for (var variable in variableList.variableDeclarationList_variables) {
          yield variable;
        }
      }
    }
  }

  LinkedNode _getFunctionBody(LinkedNode node) {
    var kind = node.kind;
    if (kind == LinkedNodeKind.constructorDeclaration) {
      return node.constructorDeclaration_body;
    } else if (kind == LinkedNodeKind.functionDeclaration) {
      return node
          .functionDeclaration_functionExpression.functionExpression_body;
    } else if (kind == LinkedNodeKind.methodDeclaration) {
      return node.methodDeclaration_body;
    } else {
      throw UnimplementedError('$kind');
    }
  }

  bool _isGetToken(int token) {
    return tokens.type[token] == UnlinkedTokenType.GET;
  }

  bool _isSetToken(int token) {
    return tokens.type[token] == UnlinkedTokenType.SET;
  }
}
