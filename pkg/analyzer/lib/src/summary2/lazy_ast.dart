// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary2/ast_binary_reader.dart';

/// Accessor for reading AST lazily, or read data that is stored in IDL, but
/// cannot be stored in AST, like inferred types.
class LazyAst {
  static const _returnTypeKey = 'lazyAst_returnType';
  static const _typeKey = 'lazyAst_type';

  final LinkedNode data;

  LazyAst(this.data);

  static DartType getReturnType(AstNode node) {
    return node.getProperty(_returnTypeKey);
  }

  static DartType getType(AstNode node) {
    return node.getProperty(_typeKey);
  }

  static void setReturnType(AstNode node, DartType type) {
    node.setProperty(_returnTypeKey, type);
  }

  static void setType(AstNode node, DartType type) {
    node.setProperty(_typeKey, type);
  }
}

class LazyClassDeclaration {
  static const _key = 'lazyAst';

  final LinkedNode data;

  bool _hasDocumentationComment = false;
  bool _hasExtendsClause = false;
  bool _hasImplementsClause = false;
  bool _hasMembers = false;
  bool _hasMetadata = false;
  bool _hasTypeParameters = false;
  bool _hasWithClause = false;

  LazyClassDeclaration(this.data);

  static LazyClassDeclaration get(ClassDeclaration node) {
    return node.getProperty(_key);
  }

  static void readDocumentationComment(
    AstBinaryReader reader,
    ClassDeclaration node,
  ) {
    var lazy = LazyClassDeclaration.get(node);
    if (lazy != null && !lazy._hasDocumentationComment) {
      node.documentationComment = reader.readNode(
        lazy.data.annotatedNode_comment,
      );
      lazy._hasDocumentationComment = true;
    }
  }

  static void readExtendsClause(
    AstBinaryReader reader,
    ClassDeclaration node,
  ) {
    var lazy = get(node);
    if (lazy != null && !lazy._hasExtendsClause) {
      node.extendsClause = reader.readNode(
        lazy.data.classDeclaration_extendsClause,
      );
      lazy._hasExtendsClause = true;
    }
  }

  static void readImplementsClause(
    AstBinaryReader reader,
    ClassDeclaration node,
  ) {
    var lazy = LazyClassDeclaration.get(node);
    if (lazy != null && !lazy._hasImplementsClause) {
      node.implementsClause = reader.readNode(
        lazy.data.classOrMixinDeclaration_implementsClause,
      );
      lazy._hasImplementsClause = true;
    }
  }

  static void readMembers(
    AstBinaryReader reader,
    ClassDeclaration node,
  ) {
    var lazy = LazyClassDeclaration.get(node);
    if (lazy != null && !lazy._hasMembers) {
      var dataList = lazy.data.classOrMixinDeclaration_members;
      for (var i = 0; i < dataList.length; ++i) {
        var data = dataList[i];
        node.members[i] = reader.readNode(data);
      }
      lazy._hasMembers = true;
    }
  }

  static void readMetadata(
    AstBinaryReader reader,
    ClassDeclaration node,
  ) {
    var lazy = LazyClassDeclaration.get(node);
    if (lazy != null && !lazy._hasMetadata) {
      var dataList = lazy.data.annotatedNode_metadata;
      for (var i = 0; i < dataList.length; ++i) {
        var data = dataList[i];
        node.metadata[i] = reader.readNode(data);
      }
      lazy._hasMetadata = true;
    }
  }

  static void readTypeParameters(
    AstBinaryReader reader,
    ClassDeclaration node,
  ) {
    var lazy = LazyClassDeclaration.get(node);
    if (lazy != null && !lazy._hasTypeParameters) {
      node.typeParameters = reader.readNode(
        lazy.data.classOrMixinDeclaration_typeParameters,
      );
      lazy._hasTypeParameters = true;
    }
  }

  static void readWithClause(
    AstBinaryReader reader,
    ClassDeclaration node,
  ) {
    var lazy = LazyClassDeclaration.get(node);
    if (lazy != null && !lazy._hasWithClause) {
      node.withClause = reader.readNode(
        lazy.data.classDeclaration_withClause,
      );
      lazy._hasWithClause = true;
    }
  }

  static void setData(ClassDeclaration node, LinkedNode data) {
    node.setProperty(_key, LazyClassDeclaration(data));
  }
}

class LazyClassTypeAlias {
  static const _key = 'lazyAst';

  final LinkedNode data;

  bool _hasDocumentationComment = false;
  bool _hasImplementsClause = false;
  bool _hasMetadata = false;
  bool _hasSuperclass = false;
  bool _hasTypeParameters = false;
  bool _hasWithClause = false;

  LazyClassTypeAlias(this.data);

  static LazyClassTypeAlias get(ClassTypeAlias node) {
    return node.getProperty(_key);
  }

  static void readDocumentationComment(
    AstBinaryReader reader,
    ClassTypeAlias node,
  ) {
    var lazy = LazyClassTypeAlias.get(node);
    if (lazy != null && !lazy._hasDocumentationComment) {
      node.documentationComment = reader.readNode(
        lazy.data.annotatedNode_comment,
      );
      lazy._hasDocumentationComment = true;
    }
  }

  static void readImplementsClause(
    AstBinaryReader reader,
    ClassTypeAlias node,
  ) {
    var lazy = LazyClassTypeAlias.get(node);
    if (lazy != null && !lazy._hasImplementsClause) {
      node.implementsClause = reader.readNode(
        lazy.data.classTypeAlias_implementsClause,
      );
      lazy._hasImplementsClause = true;
    }
  }

  static void readMetadata(
    AstBinaryReader reader,
    ClassTypeAlias node,
  ) {
    var lazy = get(node);
    if (lazy != null && !lazy._hasMetadata) {
      var dataList = lazy.data.annotatedNode_metadata;
      for (var i = 0; i < dataList.length; ++i) {
        var data = dataList[i];
        node.metadata[i] = reader.readNode(data);
      }
      lazy._hasMetadata = true;
    }
  }

  static void readSuperclass(
    AstBinaryReader reader,
    ClassTypeAlias node,
  ) {
    if (reader.isLazy) {
      var lazy = get(node);
      if (!lazy._hasSuperclass) {
        node.superclass = reader.readNode(
          lazy.data.classTypeAlias_superclass,
        );
        lazy._hasSuperclass = true;
      }
    }
  }

  static void readTypeParameters(
    AstBinaryReader reader,
    ClassTypeAlias node,
  ) {
    var lazy = get(node);
    if (lazy != null && !lazy._hasTypeParameters) {
      node.typeParameters = reader.readNode(
        lazy.data.classTypeAlias_typeParameters,
      );
      lazy._hasTypeParameters = true;
    }
  }

  static void readWithClause(
    AstBinaryReader reader,
    ClassTypeAlias node,
  ) {
    var lazy = LazyClassTypeAlias.get(node);
    if (lazy != null && !lazy._hasWithClause) {
      node.withClause = reader.readNode(
        lazy.data.classTypeAlias_withClause,
      );
      lazy._hasWithClause = true;
    }
  }

  static void setData(ClassTypeAlias node, LinkedNode data) {
    node.setProperty(_key, LazyClassTypeAlias(data));
  }
}

class LazyConstructorDeclaration {
  static const _key = 'lazyAst';

  final LinkedNode data;

  bool _hasBody = false;
  bool _hasDocumentationComment = false;
  bool _hasFormalParameters = false;
  bool _hasInitializers = false;
  bool _hasMetadata = false;
  bool _hasRedirectedConstructor = false;

  LazyConstructorDeclaration(this.data);

  static LazyConstructorDeclaration get(ConstructorDeclaration node) {
    return node.getProperty(_key);
  }

  static void readBody(
    AstBinaryReader reader,
    ConstructorDeclaration node,
  ) {
    var lazy = get(node);
    if (lazy != null && !lazy._hasBody) {
      node.body = reader.readNode(
        lazy.data.constructorDeclaration_body,
      );
      lazy._hasBody = true;
    }
  }

  static void readDocumentationComment(
    AstBinaryReader reader,
    ConstructorDeclaration node,
  ) {
    var lazy = LazyConstructorDeclaration.get(node);
    if (lazy != null && !lazy._hasDocumentationComment) {
      node.documentationComment = reader.readNode(
        lazy.data.annotatedNode_comment,
      );
      lazy._hasDocumentationComment = true;
    }
  }

  static void readFormalParameters(
    AstBinaryReader reader,
    ConstructorDeclaration node,
  ) {
    var lazy = LazyConstructorDeclaration.get(node);
    if (lazy != null && !lazy._hasFormalParameters) {
      node.parameters = reader.readNode(
        lazy.data.constructorDeclaration_parameters,
      );
      lazy._hasFormalParameters = true;
    }
  }

  static void readInitializers(
    AstBinaryReader reader,
    ConstructorDeclaration node,
  ) {
    var lazy = get(node);
    if (lazy != null && !lazy._hasInitializers) {
      var dataList = lazy.data.constructorDeclaration_initializers;
      for (var i = 0; i < dataList.length; ++i) {
        var data = dataList[i];
        node.initializers[i] = reader.readNode(data);
      }
      lazy._hasInitializers = true;
    }
  }

  static void readMetadata(
    AstBinaryReader reader,
    ConstructorDeclaration node,
  ) {
    var lazy = get(node);
    if (lazy != null && !lazy._hasMetadata) {
      var dataList = lazy.data.annotatedNode_metadata;
      for (var i = 0; i < dataList.length; ++i) {
        var data = dataList[i];
        node.metadata[i] = reader.readNode(data);
      }
      lazy._hasMetadata = true;
    }
  }

  static void readRedirectedConstructor(
    AstBinaryReader reader,
    ConstructorDeclaration node,
  ) {
    var lazy = get(node);
    if (lazy != null && !lazy._hasRedirectedConstructor) {
      node.redirectedConstructor = reader.readNode(
        lazy.data.constructorDeclaration_redirectedConstructor,
      );
      lazy._hasRedirectedConstructor = true;
    }
  }

  static void setData(ConstructorDeclaration node, LinkedNode data) {
    node.setProperty(_key, LazyConstructorDeclaration(data));
  }
}

class LazyDirective {
  static const _key = 'lazyAst';

  final LinkedNode data;

  bool _hasMetadata = false;

  LazyDirective(this.data);

  static LazyDirective get(Directive node) {
    return node.getProperty(_key);
  }

  static void readMetadata(AstBinaryReader reader, Directive node) {
    var lazy = get(node);
    if (lazy != null && !lazy._hasMetadata) {
      var dataList = lazy.data.annotatedNode_metadata;
      for (var i = 0; i < dataList.length; ++i) {
        var data = dataList[i];
        node.metadata[i] = reader.readNode(data);
      }
      lazy._hasMetadata = true;
    }
  }

  static void setData(Directive node, LinkedNode data) {
    node.setProperty(_key, LazyDirective(data));
  }
}

class LazyEnumConstantDeclaration {
  static const _key = 'lazyAst';

  final LinkedNode data;

  bool _hasDocumentationComment = false;
  bool _hasMetadata = false;

  LazyEnumConstantDeclaration(this.data);

  static LazyEnumConstantDeclaration get(EnumConstantDeclaration node) {
    return node.getProperty(_key);
  }

  static void readDocumentationComment(
    AstBinaryReader reader,
    EnumConstantDeclaration node,
  ) {
    var lazy = get(node);
    if (lazy != null && !lazy._hasDocumentationComment) {
      node.documentationComment = reader.readNode(
        lazy.data.annotatedNode_comment,
      );
      lazy._hasDocumentationComment = true;
    }
  }

  static void readMetadata(
    AstBinaryReader reader,
    EnumConstantDeclaration node,
  ) {
    var lazy = get(node);
    if (lazy != null && !lazy._hasMetadata) {
      var dataList = lazy.data.annotatedNode_metadata;
      for (var i = 0; i < dataList.length; ++i) {
        var data = dataList[i];
        node.metadata[i] = reader.readNode(data);
      }
      lazy._hasMetadata = true;
    }
  }

  static void setData(EnumConstantDeclaration node, LinkedNode data) {
    node.setProperty(_key, LazyEnumConstantDeclaration(data));
  }
}

class LazyEnumDeclaration {
  static const _key = 'lazyAst';

  final LinkedNode data;

  bool _hasConstants = false;
  bool _hasDocumentationComment = false;
  bool _hasMetadata = false;

  LazyEnumDeclaration(this.data);

  static LazyEnumDeclaration get(EnumDeclaration node) {
    return node.getProperty(_key);
  }

  static void readConstants(
    AstBinaryReader reader,
    EnumDeclaration node,
  ) {
    var lazy = get(node);
    if (lazy != null && !lazy._hasConstants) {
      var dataList = lazy.data.enumDeclaration_constants;
      for (var i = 0; i < dataList.length; ++i) {
        var data = dataList[i];
        node.constants[i] = reader.readNode(data);
      }
      lazy._hasConstants = true;
    }
  }

  static void readDocumentationComment(
    AstBinaryReader reader,
    EnumDeclaration node,
  ) {
    var lazy = get(node);
    if (lazy != null && !lazy._hasDocumentationComment) {
      node.documentationComment = reader.readNode(
        lazy.data.annotatedNode_comment,
      );
      lazy._hasDocumentationComment = true;
    }
  }

  static void readMetadata(
    AstBinaryReader reader,
    EnumDeclaration node,
  ) {
    var lazy = get(node);
    if (lazy != null && !lazy._hasMetadata) {
      var dataList = lazy.data.annotatedNode_metadata;
      for (var i = 0; i < dataList.length; ++i) {
        var data = dataList[i];
        node.metadata[i] = reader.readNode(data);
      }
      lazy._hasMetadata = true;
    }
  }

  static void setData(EnumDeclaration node, LinkedNode data) {
    node.setProperty(_key, LazyEnumDeclaration(data));
  }
}

class LazyFieldDeclaration {
  static const _key = 'lazyAst';

  final LinkedNode data;

  bool _hasDocumentationComment = false;
  bool _hasMetadata = false;

  LazyFieldDeclaration(this.data);

  static LazyFieldDeclaration get(FieldDeclaration node) {
    return node.getProperty(_key);
  }

  static void readDocumentationComment(
    AstBinaryReader reader,
    FieldDeclaration node,
  ) {
    var lazy = get(node);
    if (lazy != null && !lazy._hasDocumentationComment) {
      node.documentationComment = reader.readNode(
        lazy.data.annotatedNode_comment,
      );
      lazy._hasDocumentationComment = true;
    }
  }

  static void readMetadata(
    AstBinaryReader reader,
    FieldDeclaration node,
  ) {
    var lazy = get(node);
    if (lazy != null && !lazy._hasMetadata) {
      var dataList = lazy.data.annotatedNode_metadata;
      for (var i = 0; i < dataList.length; ++i) {
        var data = dataList[i];
        node.metadata[i] = reader.readNode(data);
      }
      lazy._hasMetadata = true;
    }
  }

  static void setData(FieldDeclaration node, LinkedNode data) {
    node.setProperty(_key, LazyFieldDeclaration(data));
  }
}

class LazyFormalParameter {
  static const _key = 'lazyAst';

  final LinkedNode data;

  bool _hasDefaultValue = false;
  bool _hasMetadata = false;
  bool _hasType = false;

  LazyFormalParameter(this.data);

  static LazyFormalParameter get(FormalParameter node) {
    return node.getProperty(_key);
  }

  static DartType getType(
    AstBinaryReader reader,
    FormalParameter node,
  ) {
    if (reader.isLazy) {
      var lazy = get(node);
      if (!lazy._hasType) {
        var type = reader.readType(lazy.data.actualType);
        LazyAst.setType(node, type);
        lazy._hasType = true;
      }
    }
    return LazyAst.getType(node);
  }

  static void readDefaultValue(
    AstBinaryReader reader,
    DefaultFormalParameter node,
  ) {
    if (reader.isLazy) {
      var lazy = LazyFormalParameter.get(node);
      if (lazy != null && !lazy._hasDefaultValue) {
        node.defaultValue = reader.readNode(
          lazy.data.defaultFormalParameter_defaultValue,
        );
        lazy._hasDefaultValue = true;
      }
    }
  }

  static void readMetadata(
    AstBinaryReader reader,
    FormalParameter node,
  ) {
    var lazy = get(node);
    if (lazy != null && !lazy._hasMetadata) {
      var dataList = lazy.data.normalFormalParameter_metadata;
      for (var i = 0; i < dataList.length; ++i) {
        var data = dataList[i];
        node.metadata[i] = reader.readNode(data);
      }
      lazy._hasMetadata = true;
    }
  }

  static void setData(FormalParameter node, LinkedNode data) {
    node.setProperty(_key, LazyFormalParameter(data));
  }
}

class LazyFunctionDeclaration {
  static const _key = 'lazyAst';

  final LinkedNode data;

  bool _hasDocumentationComment = false;
  bool _hasMetadata = false;
  bool _hasReturnType = false;

  LazyFunctionDeclaration(this.data);

  static LazyFunctionDeclaration get(FunctionDeclaration node) {
    return node.getProperty(_key);
  }

  static DartType getReturnType(
    AstBinaryReader reader,
    FunctionDeclaration node,
  ) {
    if (reader.isLazy) {
      var lazy = get(node);
      if (!lazy._hasReturnType) {
        var type = reader.readType(lazy.data.actualReturnType);
        LazyAst.setReturnType(node, type);
        lazy._hasReturnType = true;
      }
    }
    return LazyAst.getReturnType(node);
  }

  static void readDocumentationComment(
    AstBinaryReader reader,
    FunctionDeclaration node,
  ) {
    var lazy = LazyFunctionDeclaration.get(node);
    if (lazy != null && !lazy._hasDocumentationComment) {
      node.documentationComment = reader.readNode(
        lazy.data.annotatedNode_comment,
      );
      lazy._hasDocumentationComment = true;
    }
  }

  static void readFunctionExpression(
    AstBinaryReader reader,
    FunctionDeclaration node,
  ) {
    if (node.functionExpression == null) {
      var lazy = LazyFunctionDeclaration.get(node);
      node.functionExpression = reader.readNode(
        lazy.data.functionDeclaration_functionExpression,
      );
    }
  }

  static void readMetadata(
    AstBinaryReader reader,
    FunctionDeclaration node,
  ) {
    var lazy = get(node);
    if (lazy != null && !lazy._hasMetadata) {
      var dataList = lazy.data.annotatedNode_metadata;
      for (var i = 0; i < dataList.length; ++i) {
        var data = dataList[i];
        node.metadata[i] = reader.readNode(data);
      }
      lazy._hasMetadata = true;
    }
  }

  static void setData(FunctionDeclaration node, LinkedNode data) {
    node.setProperty(_key, LazyFunctionDeclaration(data));
  }
}

class LazyFunctionExpression {
  static const _key = 'lazyAst';

  final LinkedNode data;

  bool _hasBody = false;
  bool _hasFormalParameters = false;
  bool _hasTypeParameters = false;

  LazyFunctionExpression(this.data);

  static LazyFunctionExpression get(FunctionExpression node) {
    return node.getProperty(_key);
  }

  static void readBody(
    AstBinaryReader reader,
    FunctionExpression node,
  ) {
    var lazy = get(node);
    if (lazy != null && !lazy._hasBody) {
      node.body = reader.readNode(
        lazy.data.functionExpression_body,
      );
      lazy._hasBody = true;
    }
  }

  static void readFormalParameters(
    AstBinaryReader reader,
    FunctionExpression node,
  ) {
    var lazy = get(node);
    if (lazy != null && !lazy._hasFormalParameters) {
      node.parameters = reader.readNode(
        lazy.data.functionExpression_formalParameters,
      );
      lazy._hasFormalParameters = true;
    }
  }

  static void readTypeParameters(
    AstBinaryReader reader,
    FunctionExpression node,
  ) {
    var lazy = get(node);
    if (lazy != null && !lazy._hasTypeParameters) {
      node.typeParameters = reader.readNode(
        lazy.data.functionExpression_typeParameters,
      );
      lazy._hasTypeParameters = true;
    }
  }

  static void setData(FunctionExpression node, LinkedNode data) {
    node.setProperty(_key, LazyFunctionExpression(data));
  }
}

class LazyFunctionTypeAlias {
  static const _key = 'lazyAst';

  final LinkedNode data;

  bool _hasDocumentationComment = false;
  bool _hasFormalParameters = false;
  bool _hasMetadata = false;
  bool _hasReturnType = false;
  bool _hasTypeParameters = false;

  LazyFunctionTypeAlias(this.data);

  static LazyFunctionTypeAlias get(FunctionTypeAlias node) {
    return node.getProperty(_key);
  }

  static DartType getReturnType(
    AstBinaryReader reader,
    FunctionTypeAlias node,
  ) {
    if (reader.isLazy) {
      var lazy = get(node);
      if (!lazy._hasReturnType) {
        var type = reader.readType(lazy.data.actualReturnType);
        LazyAst.setReturnType(node, type);
        lazy._hasReturnType = true;
      }
    }
    return LazyAst.getReturnType(node);
  }

  static void readDocumentationComment(
    AstBinaryReader reader,
    FunctionTypeAlias node,
  ) {
    var lazy = get(node);
    if (lazy != null && !lazy._hasDocumentationComment) {
      node.documentationComment = reader.readNode(
        lazy.data.annotatedNode_comment,
      );
      lazy._hasDocumentationComment = true;
    }
  }

  static void readFormalParameters(
    AstBinaryReader reader,
    FunctionTypeAlias node,
  ) {
    var lazy = LazyFunctionTypeAlias.get(node);
    if (lazy != null && !lazy._hasFormalParameters) {
      node.parameters = reader.readNode(
        lazy.data.functionTypeAlias_formalParameters,
      );
      lazy._hasFormalParameters = true;
    }
  }

  static void readMetadata(
    AstBinaryReader reader,
    FunctionTypeAlias node,
  ) {
    var lazy = get(node);
    if (lazy != null && !lazy._hasMetadata) {
      var dataList = lazy.data.annotatedNode_metadata;
      for (var i = 0; i < dataList.length; ++i) {
        var data = dataList[i];
        node.metadata[i] = reader.readNode(data);
      }
      lazy._hasMetadata = true;
    }
  }

  static void readTypeParameters(
    AstBinaryReader reader,
    FunctionTypeAlias node,
  ) {
    var lazy = get(node);
    if (lazy != null && !lazy._hasTypeParameters) {
      node.typeParameters = reader.readNode(
        lazy.data.functionTypeAlias_typeParameters,
      );
      lazy._hasTypeParameters = true;
    }
  }

  static void setData(FunctionTypeAlias node, LinkedNode data) {
    node.setProperty(_key, LazyFunctionTypeAlias(data));
  }
}

class LazyGenericFunctionType {
  static const _key = 'lazyAst';

  final LinkedNode data;

  bool _hasFormalParameters = false;
  bool _hasReturnType = false;

  LazyGenericFunctionType(this.data);

  static LazyGenericFunctionType get(GenericFunctionType node) {
    return node.getProperty(_key);
  }

  static DartType getReturnType(
    AstBinaryReader reader,
    GenericFunctionType node,
  ) {
    if (reader.isLazy) {
      var lazy = get(node);
      if (!lazy._hasReturnType) {
        var type = reader.readType(lazy.data.actualReturnType);
        LazyAst.setReturnType(node, type);
        lazy._hasReturnType = true;
      }
    }
    return LazyAst.getReturnType(node);
  }

  static void readFormalParameters(
    AstBinaryReader reader,
    GenericFunctionType node,
  ) {
    var lazy = get(node);
    if (lazy != null && !lazy._hasFormalParameters) {
      node.parameters = reader.readNode(
        lazy.data.genericFunctionType_formalParameters,
      );
      lazy._hasFormalParameters = true;
    }
  }

  static void setData(GenericFunctionType node, LinkedNode data) {
    node.setProperty(_key, LazyGenericFunctionType(data));
  }
}

class LazyGenericTypeAlias {
  static const _key = 'lazyAst';

  final LinkedNode data;

  bool _hasDocumentationComment = false;
  bool _hasFunction = false;
  bool _hasTypeParameters = false;

  LazyGenericTypeAlias(this.data);

  static LazyGenericTypeAlias get(GenericTypeAlias node) {
    return node.getProperty(_key);
  }

  static void readDocumentationComment(
    AstBinaryReader reader,
    GenericTypeAlias node,
  ) {
    var lazy = get(node);
    if (lazy != null && !lazy._hasDocumentationComment) {
      node.documentationComment = reader.readNode(
        lazy.data.annotatedNode_comment,
      );
      lazy._hasDocumentationComment = true;
    }
  }

  static void readFunctionType(
    AstBinaryReader reader,
    GenericTypeAlias node,
  ) {
    var lazy = get(node);
    if (lazy != null && !lazy._hasFunction) {
      node.functionType = reader.readNode(
        lazy.data.genericTypeAlias_functionType,
      );
      lazy._hasFunction = true;
    }
  }

  static void readTypeParameters(
    AstBinaryReader reader,
    GenericTypeAlias node,
  ) {
    var lazy = get(node);
    if (lazy != null && !lazy._hasTypeParameters) {
      node.typeParameters = reader.readNode(
        lazy.data.genericTypeAlias_typeParameters,
      );
      lazy._hasTypeParameters = true;
    }
  }

  static void setData(GenericTypeAlias node, LinkedNode data) {
    node.setProperty(_key, LazyGenericTypeAlias(data));
  }
}

class LazyMethodDeclaration {
  static const _key = 'lazyAst';

  final LinkedNode data;

  bool _hasBody = false;
  bool _hasDocumentationComment = false;
  bool _hasFormalParameters = false;
  bool _hasMetadata = false;
  bool _hasReturnType = false;
  bool _hasTypeParameters = false;

  LazyMethodDeclaration(this.data);

  static LazyMethodDeclaration get(MethodDeclaration node) {
    return node.getProperty(_key);
  }

  static DartType getReturnType(
    AstBinaryReader reader,
    MethodDeclaration node,
  ) {
    if (reader.isLazy) {
      var lazy = get(node);
      if (!lazy._hasReturnType) {
        var type = reader.readType(lazy.data.actualReturnType);
        LazyAst.setReturnType(node, type);
        lazy._hasReturnType = true;
      }
    }
    return LazyAst.getReturnType(node);
  }

  static void readBody(
    AstBinaryReader reader,
    MethodDeclaration node,
  ) {
    var lazy = get(node);
    if (lazy != null && !lazy._hasBody) {
      node.body = reader.readNode(
        lazy.data.methodDeclaration_body,
      );
      lazy._hasBody = true;
    }
  }

  static void readDocumentationComment(
    AstBinaryReader reader,
    MethodDeclaration node,
  ) {
    var lazy = LazyMethodDeclaration.get(node);
    if (lazy != null && !lazy._hasDocumentationComment) {
      node.documentationComment = reader.readNode(
        lazy.data.annotatedNode_comment,
      );
      lazy._hasDocumentationComment = true;
    }
  }

  static void readFormalParameters(
    AstBinaryReader reader,
    MethodDeclaration node,
  ) {
    var lazy = LazyMethodDeclaration.get(node);
    if (lazy != null && !lazy._hasFormalParameters) {
      node.parameters = reader.readNode(
        lazy.data.methodDeclaration_formalParameters,
      );
      lazy._hasFormalParameters = true;
    }
  }

  static void readMetadata(
    AstBinaryReader reader,
    MethodDeclaration node,
  ) {
    var lazy = get(node);
    if (lazy != null && !lazy._hasMetadata) {
      var dataList = lazy.data.annotatedNode_metadata;
      for (var i = 0; i < dataList.length; ++i) {
        var data = dataList[i];
        node.metadata[i] = reader.readNode(data);
      }
      lazy._hasMetadata = true;
    }
  }

  static void readTypeParameters(
    AstBinaryReader reader,
    MethodDeclaration node,
  ) {
    var lazy = get(node);
    if (lazy != null && !lazy._hasTypeParameters) {
      node.typeParameters = reader.readNode(
        lazy.data.methodDeclaration_typeParameters,
      );
      lazy._hasTypeParameters = true;
    }
  }

  static void setData(MethodDeclaration node, LinkedNode data) {
    node.setProperty(_key, LazyMethodDeclaration(data));
  }
}

class LazyMixinDeclaration {
  static const _key = 'lazyAst';

  final LinkedNode data;

  bool _hasDocumentationComment = false;
  bool _hasOnClause = false;
  bool _hasImplementsClause = false;
  bool _hasMembers = false;
  bool _hasTypeParameters = false;

  LazyMixinDeclaration(this.data);

  static LazyMixinDeclaration get(MixinDeclaration node) {
    return node.getProperty(_key);
  }

  static void readDocumentationComment(
    AstBinaryReader reader,
    MixinDeclaration node,
  ) {
    var lazy = get(node);
    if (lazy != null && !lazy._hasDocumentationComment) {
      node.documentationComment = reader.readNode(
        lazy.data.annotatedNode_comment,
      );
      lazy._hasDocumentationComment = true;
    }
  }

  static void readImplementsClause(
    AstBinaryReader reader,
    MixinDeclarationImpl node,
  ) {
    var lazy = get(node);
    if (lazy != null && !lazy._hasImplementsClause) {
      node.implementsClause = reader.readNode(
        lazy.data.classOrMixinDeclaration_implementsClause,
      );
      lazy._hasImplementsClause = true;
    }
  }

  static void readMembers(
    AstBinaryReader reader,
    MixinDeclaration node,
  ) {
    var lazy = get(node);
    if (lazy != null && !lazy._hasMembers) {
      var dataList = lazy.data.classOrMixinDeclaration_members;
      for (var i = 0; i < dataList.length; ++i) {
        var data = dataList[i];
        node.members[i] = reader.readNode(data);
      }
      lazy._hasMembers = true;
    }
  }

  static void readOnClause(
    AstBinaryReader reader,
    MixinDeclarationImpl node,
  ) {
    var lazy = get(node);
    if (!lazy._hasOnClause) {
      node.onClause = reader.readNode(
        lazy.data.mixinDeclaration_onClause,
      );
      lazy._hasOnClause = true;
    }
  }

  static void readTypeParameters(
    AstBinaryReader reader,
    MixinDeclarationImpl node,
  ) {
    var lazy = get(node);
    if (lazy != null && !lazy._hasTypeParameters) {
      node.typeParameters = reader.readNode(
        lazy.data.classOrMixinDeclaration_typeParameters,
      );
      lazy._hasTypeParameters = true;
    }
  }

  static void setData(MixinDeclaration node, LinkedNode data) {
    node.setProperty(_key, LazyMixinDeclaration(data));
  }
}

class LazyTopLevelVariableDeclaration {
  static const _key = 'lazyAst';

  final LinkedNode data;

  bool _hasDocumentationComment = false;
  bool _hasMetadata = false;

  LazyTopLevelVariableDeclaration(this.data);

  static LazyTopLevelVariableDeclaration get(TopLevelVariableDeclaration node) {
    return node.getProperty(_key);
  }

  static void readDocumentationComment(
    AstBinaryReader reader,
    TopLevelVariableDeclaration node,
  ) {
    var lazy = get(node);
    if (lazy != null && !lazy._hasDocumentationComment) {
      node.documentationComment = reader.readNode(
        lazy.data.annotatedNode_comment,
      );
      lazy._hasDocumentationComment = true;
    }
  }

  static void readMetadata(
    AstBinaryReader reader,
    TopLevelVariableDeclaration node,
  ) {
    var lazy = get(node);
    if (lazy != null && !lazy._hasMetadata) {
      var dataList = lazy.data.annotatedNode_metadata;
      for (var i = 0; i < dataList.length; ++i) {
        var data = dataList[i];
        node.metadata[i] = reader.readNode(data);
      }
      lazy._hasMetadata = true;
    }
  }

  static void setData(TopLevelVariableDeclaration node, LinkedNode data) {
    node.setProperty(_key, LazyTopLevelVariableDeclaration(data));
  }
}

class LazyTypeParameter {
  static const _key = 'lazyAst';

  final LinkedNode data;

  bool _hasBound = false;

  LazyTypeParameter(this.data);

  static LazyTypeParameter get(TypeParameter node) {
    return node.getProperty(_key);
  }

  static void readBound(AstBinaryReader reader, TypeParameter node) {
    var lazy = get(node);
    if (lazy != null && !lazy._hasBound) {
      node.bound = reader.readNode(lazy.data.typeParameter_bound);
      lazy._hasBound = true;
    }
  }

  static void setData(TypeParameter node, LinkedNode data) {
    node.setProperty(_key, LazyTypeParameter(data));
  }
}

class LazyVariableDeclaration {
  static const _key = 'lazyAst';

  final LinkedNode data;

  bool _hasInitializer = false;
  bool _hasType = false;

  LazyVariableDeclaration(this.data);

  static LazyVariableDeclaration get(VariableDeclaration node) {
    return node.getProperty(_key);
  }

  static DartType getType(
    AstBinaryReader reader,
    VariableDeclaration node,
  ) {
    if (reader.isLazy) {
      var lazy = get(node);
      if (!lazy._hasType) {
        var type = reader.readType(lazy.data.actualType);
        LazyAst.setType(node, type);
        lazy._hasType = true;
      }
    }
    return LazyAst.getType(node);
  }

  static void readInitializer(
    AstBinaryReader reader,
    VariableDeclaration node,
  ) {
    if (reader.isLazy) {
      var lazy = get(node);
      if (lazy != null && !lazy._hasInitializer) {
        node.initializer = reader.readNode(
          lazy.data.variableDeclaration_initializer,
        );
        lazy._hasInitializer = true;
      }
    }
  }

  static void setData(VariableDeclaration node, LinkedNode data) {
    node.setProperty(_key, LazyVariableDeclaration(data));
  }
}
