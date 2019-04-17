// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary2/ast_binary_reader.dart';
import 'package:analyzer/src/summary2/lazy_ast.dart';
import 'package:analyzer/src/summary2/linked_bundle_context.dart';
import 'package:analyzer/src/summary2/tokens_context.dart';

/// The context of a unit - the context of the bundle, and the unit tokens.
class LinkedUnitContext {
  final LinkedBundleContext bundleContext;
  final LinkedLibraryContext libraryContext;
  final int indexInLibrary;
  final String uriStr;
  final LinkedNodeUnit data;
  final TokensContext tokensContext;

  AstBinaryReader _astReader;

  CompilationUnit _unit;
  bool _hasDirectivesRead = false;

  /// Mapping from identifiers to real or synthetic type parameters.
  ///
  /// Real type parameters have corresponding [TypeParameter] nodes, and are
  /// referenced from other AST nodes.
  ///
  /// Synthetic type parameters are added when [readType] begins reading a
  /// [FunctionType], and removed when reading is done.
  final Map<int, TypeParameterElement> _typeParameters = {};

  int _nextSyntheticTypeParameterId = 0x10000;

  LinkedUnitContext(this.bundleContext, this.libraryContext,
      this.indexInLibrary, this.uriStr, this.data,
      {CompilationUnit unit})
      : tokensContext = data != null ? TokensContext(data.tokens) : null {
    _astReader = AstBinaryReader(this);
    _astReader.isLazy = unit == null;

    _unit = unit;
    _hasDirectivesRead = _unit != null;
  }

  CompilationUnit get unit => _unit;

  CompilationUnit get unit_withDeclarations {
    if (_unit == null) {
      _unit = _astReader.readNode(data.node);
    }
    return _unit;
  }

  CompilationUnit get unit_withDirectives {
    if (!_hasDirectivesRead) {
      var directiveDataList = data.node.compilationUnit_directives;
      for (var i = 0; i < directiveDataList.length; ++i) {
        var directiveData = directiveDataList[i];
        _unit.directives[i] = _astReader.readNode(directiveData);
      }
      _hasDirectivesRead = true;
    }
    return _unit;
  }

  /// Every [TypeParameter] node has [TypeParameterElement], which is created
  /// during reading of this node. All type parameter nodes are read before
  /// any nodes that reference them (bounds are read lazily later).
  void addTypeParameter(int id, TypeParameter node) {
    var element = TypeParameterElementImpl.forLinkedNode(null, null, node);
    _typeParameters[id] = element;
    node.name.staticElement = element;
  }

  /// Return the [LibraryElement] referenced in the [node].
  LibraryElement directiveLibrary(UriBasedDirective node) {
    var uriStr = LazyDirective.getSelectedUri(node);
    if (uriStr == null || uriStr.isEmpty) return null;
    return bundleContext.elementFactory.libraryOfUri(uriStr);
  }

  int getCodeLength(AstNode node) {
    if (node is ClassDeclaration) {
      return LazyClassDeclaration.get(node).data.codeLength;
    } else if (node is ClassTypeAlias) {
      return LazyClassTypeAlias.get(node).data.codeLength;
    } else if (node is ConstructorDeclaration) {
      return LazyConstructorDeclaration.get(node).data.codeLength;
    } else if (node is FormalParameter) {
      return LazyFormalParameter.get(node).data.codeLength;
    } else if (node is FunctionDeclaration) {
      return LazyFunctionDeclaration.get(node).data.codeLength;
    } else if (node is MethodDeclaration) {
      return LazyMethodDeclaration.get(node).data.codeLength;
    } else if (node is TypeParameter) {
      return LazyTypeParameter.get(node).data.codeLength;
    } else if (node is VariableDeclaration) {
      return LazyVariableDeclaration.get(node).data.codeLength;
    }
    throw UnimplementedError('${node.runtimeType}');
  }

  int getCodeOffset(AstNode node) {
    if (node is ClassDeclaration) {
      return LazyClassDeclaration.get(node).data.codeOffset;
    } else if (node is ClassTypeAlias) {
      return LazyClassTypeAlias.get(node).data.codeOffset;
    } else if (node is ConstructorDeclaration) {
      return LazyConstructorDeclaration.get(node).data.codeOffset;
    } else if (node is FormalParameter) {
      return LazyFormalParameter.get(node).data.codeOffset;
    } else if (node is FunctionDeclaration) {
      return LazyFunctionDeclaration.get(node).data.codeOffset;
    } else if (node is MethodDeclaration) {
      return LazyMethodDeclaration.get(node).data.codeOffset;
    } else if (node is TypeParameter) {
      return LazyTypeParameter.get(node).data.codeOffset;
    } else if (node is VariableDeclaration) {
      return LazyVariableDeclaration.get(node).data.codeOffset;
    }
    throw UnimplementedError('${node.runtimeType}');
  }

  String getConstructorDeclarationName(LinkedNode node) {
    var name = node.constructorDeclaration_name;
    if (name != null) {
      return getSimpleName(name);
    }
    return '';
  }

  List<ConstructorInitializer> getConstructorInitializers(
    ConstructorDeclaration node,
  ) {
    LazyConstructorDeclaration.readInitializers(_astReader, node);
    return node.initializers;
  }

  ConstructorName getConstructorRedirected(ConstructorDeclaration node) {
    LazyConstructorDeclaration.readRedirectedConstructor(_astReader, node);
    return node.redirectedConstructor;
  }

  Iterable<ConstructorDeclaration> getConstructors(AstNode node) sync* {
    if (node is ClassOrMixinDeclaration) {
      var members = _getClassOrMixinMembers(node);
      for (var member in members) {
        if (member is ConstructorDeclaration) {
          yield member;
        }
      }
    }
  }

  Comment getDocumentationComment(AstNode node) {
    if (node is ClassDeclaration) {
      LazyClassDeclaration.readDocumentationComment(_astReader, node);
      return node.documentationComment;
    } else if (node is ClassTypeAlias) {
      LazyClassTypeAlias.readDocumentationComment(_astReader, node);
      return node.documentationComment;
    } else if (node is ConstructorDeclaration) {
      LazyConstructorDeclaration.readDocumentationComment(_astReader, node);
      return node.documentationComment;
    } else if (node is EnumConstantDeclaration) {
      LazyEnumConstantDeclaration.readDocumentationComment(_astReader, node);
      return node.documentationComment;
    } else if (node is EnumDeclaration) {
      LazyEnumDeclaration.readDocumentationComment(_astReader, node);
      return node.documentationComment;
    } else if (node is FunctionDeclaration) {
      LazyFunctionDeclaration.readDocumentationComment(_astReader, node);
      return node.documentationComment;
    } else if (node is FunctionTypeAlias) {
      LazyFunctionTypeAlias.readDocumentationComment(_astReader, node);
      return node.documentationComment;
    } else if (node is GenericTypeAlias) {
      LazyGenericTypeAlias.readDocumentationComment(_astReader, node);
      return node.documentationComment;
    } else if (node is MethodDeclaration) {
      LazyMethodDeclaration.readDocumentationComment(_astReader, node);
      return node.documentationComment;
    } else if (node is MixinDeclaration) {
      LazyMixinDeclaration.readDocumentationComment(_astReader, node);
      return node.documentationComment;
    } else if (node is VariableDeclaration) {
      var parent2 = node.parent.parent;
      if (parent2 is FieldDeclaration) {
        LazyFieldDeclaration.readDocumentationComment(_astReader, parent2);
        return parent2.documentationComment;
      } else if (parent2 is TopLevelVariableDeclaration) {
        LazyTopLevelVariableDeclaration.readDocumentationComment(
          _astReader,
          parent2,
        );
        return parent2.documentationComment;
      } else {
        throw UnimplementedError('${parent2.runtimeType}');
      }
    } else {
      throw UnimplementedError('${node.runtimeType}');
    }
  }

  List<EnumConstantDeclaration> getEnumConstants(EnumDeclaration node) {
    LazyEnumDeclaration.readConstants(_astReader, node);
    return node.constants;
  }

  String getFieldFormalParameterName(AstNode node) {
    if (node is DefaultFormalParameter) {
      return getFieldFormalParameterName(node.parameter);
    } else if (node is FieldFormalParameter) {
      return node.identifier.name;
    } else {
      throw StateError('${node.runtimeType}');
    }
  }

  Iterable<VariableDeclaration> getFields(ClassOrMixinDeclaration node) sync* {
    var members = _getClassOrMixinMembers(node);
    for (var member in members) {
      if (member is FieldDeclaration) {
        for (var field in member.fields.variables) {
          yield field;
        }
      }
    }
  }

  String getFormalParameterName(LinkedNode node) {
    return getSimpleName(node.normalFormalParameter_identifier);
  }

  List<FormalParameter> getFormalParameters(AstNode node) {
    if (node is ConstructorDeclaration) {
      LazyConstructorDeclaration.readFormalParameters(_astReader, node);
      return node.parameters.parameters;
    } else if (node is FunctionDeclaration) {
      LazyFunctionDeclaration.readFunctionExpression(_astReader, node);
      return getFormalParameters(node.functionExpression);
    } else if (node is FunctionExpression) {
      LazyFunctionExpression.readFormalParameters(_astReader, node);
      return node.parameters?.parameters;
    } else if (node is FunctionTypeAlias) {
      LazyFunctionTypeAlias.readFormalParameters(_astReader, node);
      return node.parameters.parameters;
    } else if (node is GenericFunctionType) {
      LazyGenericFunctionType.readFormalParameters(_astReader, node);
      return node.parameters.parameters;
    } else if (node is MethodDeclaration) {
      LazyMethodDeclaration.readFormalParameters(_astReader, node);
      return node.parameters?.parameters;
    } else {
      throw UnimplementedError('${node.runtimeType}');
    }
//    if (kind == LinkedNodeKind.constructorDeclaration) {
//      parameterList = node.constructorDeclaration_parameters;
//    } else if (kind == LinkedNodeKind.functionDeclaration) {
//      return getFormalParameters(node.functionDeclaration_functionExpression);
//    } else if (kind == LinkedNodeKind.functionExpression) {
//      parameterList = node.functionExpression_formalParameters;
//    } else if (kind == LinkedNodeKind.functionTypeAlias) {
//      parameterList = node.functionTypeAlias_formalParameters;
//    } else if (kind == LinkedNodeKind.genericFunctionType) {
//      parameterList = node.genericFunctionType_formalParameters;
//    } else if (kind == LinkedNodeKind.methodDeclaration) {
//      parameterList = node.methodDeclaration_formalParameters;
//    } else {
//      throw UnimplementedError('$kind');
//    }
  }

  GenericFunctionType getGeneticTypeAliasFunction(GenericTypeAlias node) {
    LazyGenericTypeAlias.readFunctionType(_astReader, node);
    return node.functionType;
  }

  ImplementsClause getImplementsClause(AstNode node) {
    if (node is ClassDeclaration) {
      LazyClassDeclaration.readImplementsClause(_astReader, node);
      return node.implementsClause;
    } else if (node is ClassTypeAlias) {
      LazyClassTypeAlias.readImplementsClause(_astReader, node);
      return node.implementsClause;
    } else if (node is MixinDeclaration) {
      LazyMixinDeclaration.readImplementsClause(_astReader, node);
      return node.implementsClause;
    } else {
      throw UnimplementedError('${node.runtimeType}');
    }
  }

  InterfaceType getInterfaceType(LinkedNodeType linkedType) {
    var type = readType(linkedType);
    if (type is InterfaceType && !type.element.isEnum) {
      return type;
    }
    return null;
  }

  Comment getLibraryDocumentationComment(CompilationUnit unit) {
    for (var directive in unit.directives) {
      if (directive is LibraryDirective) {
        return directive.documentationComment;
      }
    }
    return null;
  }

  List<Annotation> getLibraryMetadata(CompilationUnit unit) {
    for (var directive in unit.directives) {
      if (directive is LibraryDirective) {
        return getMetadata(directive);
      }
    }
    return const <Annotation>[];
  }

  List<Annotation> getMetadata(AstNode node) {
    if (node is ClassDeclaration) {
      LazyClassDeclaration.readMetadata(_astReader, node);
      return node.metadata;
    } else if (node is ClassTypeAlias) {
      LazyClassTypeAlias.readMetadata(_astReader, node);
      return node.metadata;
    } else if (node is CompilationUnit) {
      assert(node == _unit);
      return _getPartDirectiveAnnotation();
    } else if (node is ConstructorDeclaration) {
      LazyConstructorDeclaration.readMetadata(_astReader, node);
      return node.metadata;
    } else if (node is DefaultFormalParameter) {
      return getMetadata(node.parameter);
    } else if (node is Directive) {
      LazyDirective.readMetadata(_astReader, node);
      return node.metadata;
    } else if (node is EnumConstantDeclaration) {
      LazyEnumConstantDeclaration.readMetadata(_astReader, node);
      return node.metadata;
    } else if (node is EnumDeclaration) {
      LazyEnumDeclaration.readMetadata(_astReader, node);
      return node.metadata;
    } else if (node is FormalParameter) {
      LazyFormalParameter.readMetadata(_astReader, node);
      return node.metadata;
    } else if (node is FunctionDeclaration) {
      LazyFunctionDeclaration.readMetadata(_astReader, node);
      return node.metadata;
    } else if (node is FunctionTypeAlias) {
      LazyFunctionTypeAlias.readMetadata(_astReader, node);
      return node.metadata;
    } else if (node is GenericTypeAlias) {
      LazyGenericTypeAlias.readMetadata(_astReader, node);
      return node.metadata;
    } else if (node is MethodDeclaration) {
      LazyMethodDeclaration.readMetadata(_astReader, node);
      return node.metadata;
    } else if (node is MixinDeclaration) {
      LazyMixinDeclaration.readMetadata(_astReader, node);
      return node.metadata;
    } else if (node is TypeParameter) {
      LazyTypeParameter.readMetadata(_astReader, node);
      return node.metadata;
    } else if (node is VariableDeclaration) {
      var parent2 = node.parent.parent;
      if (parent2 is FieldDeclaration) {
        LazyFieldDeclaration.readMetadata(_astReader, parent2);
        return parent2.metadata;
      } else if (parent2 is TopLevelVariableDeclaration) {
        LazyTopLevelVariableDeclaration.readMetadata(_astReader, parent2);
        return parent2.metadata;
      }
    }
//    var kind = node.kind;
//    if (kind == LinkedNodeKind.classDeclaration ||
//        kind == LinkedNodeKind.classTypeAlias ||
//        kind == LinkedNodeKind.constructorDeclaration ||
//        kind == LinkedNodeKind.enumConstantDeclaration ||
//        kind == LinkedNodeKind.enumDeclaration ||
//        kind == LinkedNodeKind.exportDirective ||
//        kind == LinkedNodeKind.functionDeclaration ||
//        kind == LinkedNodeKind.functionTypeAlias ||
//        kind == LinkedNodeKind.libraryDirective ||
//        kind == LinkedNodeKind.importDirective ||
//        kind == LinkedNodeKind.methodDeclaration ||
//        kind == LinkedNodeKind.mixinDeclaration ||
//        kind == LinkedNodeKind.partDirective ||
//        kind == LinkedNodeKind.partOfDirective ||
//        kind == LinkedNodeKind.variableDeclaration) {
//      return node.annotatedNode_metadata;
//    }
//    if (kind == LinkedNodeKind.defaultFormalParameter) {
//      return getMetadataOrEmpty(node.defaultFormalParameter_parameter);
//    }
//    if (kind == LinkedNodeKind.fieldFormalParameter ||
//        kind == LinkedNodeKind.functionTypedFormalParameter ||
//        kind == LinkedNodeKind.simpleFormalParameter) {
//      return node.normalFormalParameter_metadata;
//    }
    return const <Annotation>[];
  }

  String getMethodName(LinkedNode node) {
    return getSimpleName(node.methodDeclaration_name);
  }

  Iterable<MethodDeclaration> getMethods(AstNode node) sync* {
    if (node is ClassOrMixinDeclaration) {
      var members = _getClassOrMixinMembers(node);
      for (var member in members) {
        if (member is MethodDeclaration) {
          yield member;
        }
      }
    }
  }

  int getNameOffset(AstNode node) {
    if (node is ConstructorDeclaration) {
      if (node.name != null) {
        return node.name.offset;
      } else {
        return node.returnType.offset;
      }
    } else if (node is EnumConstantDeclaration) {
      return node.name.offset;
    } else if (node is FormalParameter) {
      return node.identifier?.offset ?? -1;
    } else if (node is MethodDeclaration) {
      return node.name.offset;
    } else if (node is NamedCompilationUnitMember) {
      return node.name.offset;
    } else if (node is VariableDeclaration) {
      return node.name.offset;
    }
    throw UnimplementedError('${node.runtimeType}');
  }

  OnClause getOnClause(MixinDeclaration node) {
    LazyMixinDeclaration.readOnClause(_astReader, node);
    return node.onClause;
  }

  /// Return the actual return type for the [node] - explicit or inferred.
  DartType getReturnType(AstNode node) {
    if (node is FunctionDeclaration) {
      return LazyFunctionDeclaration.getReturnType(_astReader, node);
    } else if (node is FunctionTypeAlias) {
      return LazyFunctionTypeAlias.getReturnType(_astReader, node);
    } else if (node is GenericFunctionType) {
      return LazyGenericFunctionType.getReturnType(_astReader, node);
    } else if (node is MethodDeclaration) {
      return LazyMethodDeclaration.getReturnType(_astReader, node);
    } else {
      throw UnimplementedError('${node.runtimeType}');
    }
  }

  String getSimpleName(LinkedNode node) {
    return getTokenLexeme(node.simpleIdentifier_token);
  }

  List<String> getSimpleNameList(List<LinkedNode> nodeList) {
    return nodeList.map(getSimpleName).toList();
  }

  int getSimpleOffset(LinkedNode node) {
    return getTokenOffset(node.simpleIdentifier_token);
  }

  String getStringContent(LinkedNode node) {
    return node.simpleStringLiteral_value;
  }

  TypeName getSuperclass(AstNode node) {
    if (node is ClassDeclaration) {
      LazyClassDeclaration.readExtendsClause(_astReader, node);
      return node.extendsClause?.superclass;
    } else if (node is ClassTypeAlias) {
      LazyClassTypeAlias.readSuperclass(_astReader, node);
      return node.superclass;
    } else {
      throw StateError('${node.runtimeType}');
    }
  }

  String getTokenLexeme(int token) {
    return tokensContext.lexeme(token);
  }

  int getTokenOffset(int token) {
    return tokensContext.offset(token);
  }

  /// Return the actual type for the [node] - explicit or inferred.
  DartType getType(AstNode node) {
    if (node is DefaultFormalParameter) {
      return getType(node.parameter);
    } else if (node is FormalParameter) {
      return LazyFormalParameter.getType(_astReader, node);
    } else if (node is VariableDeclaration) {
      return LazyVariableDeclaration.getType(_astReader, node);
    } else {
      throw UnimplementedError('${node.runtimeType}');
    }
  }

  TypeAnnotation getTypeParameterBound(TypeParameter node) {
    LazyTypeParameter.readBound(_astReader, node);
    return node.bound;
  }

  TypeParameterList getTypeParameters2(AstNode node) {
    if (node is ClassDeclaration) {
      return node.typeParameters;
    } else if (node is ClassTypeAlias) {
      return node.typeParameters;
    } else if (node is ConstructorDeclaration) {
      return null;
    } else if (node is FunctionDeclaration) {
      LazyFunctionDeclaration.readFunctionExpression(_astReader, node);
      return getTypeParameters2(node.functionExpression);
    } else if (node is FunctionExpression) {
      return node.typeParameters;
    } else if (node is FunctionTypeAlias) {
      return node.typeParameters;
    } else if (node is GenericFunctionType) {
      return node.typeParameters;
    } else if (node is GenericTypeAlias) {
      return node.typeParameters;
    } else if (node is MethodDeclaration) {
      return node.typeParameters;
    } else if (node is MixinDeclaration) {
      return node.typeParameters;
    } else {
      throw UnimplementedError('${node.runtimeType}');
    }
  }

  String getUnitMemberName(LinkedNode node) {
    return getSimpleName(node.namedCompilationUnitMember_name);
  }

  String getVariableName(LinkedNode node) {
    return getSimpleName(node.variableDeclaration_name);
  }

  WithClause getWithClause(AstNode node) {
    if (node is ClassDeclaration) {
      LazyClassDeclaration.readWithClause(_astReader, node);
      return node.withClause;
    } else if (node is ClassTypeAlias) {
      LazyClassTypeAlias.readWithClause(_astReader, node);
      return node.withClause;
    } else {
      throw UnimplementedError('${node.runtimeType}');
    }
  }

  bool hasImplicitReturnType(AstNode node) {
    if (node is MethodDeclaration) {
      LazyMethodDeclaration.readReturnTypeNode(_astReader, node);
      return node.returnType == null;
    }
    return false;
  }

  bool hasImplicitType(AstNode node) {
    if (node is VariableDeclaration) {
      VariableDeclarationList parent = node.parent;
      return parent.type == null;
    } else if (node is SimpleFormalParameter) {
      return node.type == null;
    }
    return false;
  }

  bool hasOverrideInferenceDone(AstNode node) {
    // Only nodes in the libraries being linked might be not inferred yet.
    if (_astReader.isLazy) return true;

    return LazyAst.hasOverrideInferenceDone(node);
  }

  bool isAbstract(AstNode node) {
    if (node is ClassDeclaration) {
      return node.abstractKeyword != null;
    } else if (node is ClassTypeAlias) {
      return node.abstractKeyword != null;
    } else if (node is FunctionDeclaration) {
      return false;
    } else if (node is MethodDeclaration) {
      return node.isAbstract;
    }
    throw UnimplementedError('${node.runtimeType}');
  }

  bool isAsynchronous(AstNode node) {
    var body = _getFunctionBody(node);
    return body.isAsynchronous;
  }

  bool isAsyncKeyword(int token) {
    return tokensContext.type(token) == UnlinkedTokenType.ASYNC;
  }

  bool isConst(AstNode node) {
    if (node is FormalParameter) {
      return node.isConst;
    }
    if (node is VariableDeclaration) {
      VariableDeclarationList parent = node.parent;
      return parent.isConst;
    }
//    var kind = node.kind;
//    if (kind == LinkedNodeKind.defaultFormalParameter) {
//      return isConst(node.defaultFormalParameter_parameter);
//    }
//    if (kind == LinkedNodeKind.simpleFormalParameter) {
//      return isConstKeyword(node.simpleFormalParameter_keyword);
//    }
//    if (kind == LinkedNodeKind.variableDeclaration) {
//      return node.variableDeclaration_declaration.isConst;
//    }
    throw UnimplementedError('${node.runtimeType}');
  }

  bool isConstKeyword(int token) {
    return tokensContext.type(token) == UnlinkedTokenType.CONST;
  }

  bool isConstVariableList(LinkedNode node) {
    return isConstKeyword(node.variableDeclarationList_keyword);
  }

  bool isCovariant(AstNode node) {
    if (node is FormalParameter) {
      return node.covariantKeyword != null;
    } else if (node is VariableDeclaration) {
      var parent2 = node.parent.parent;
      return parent2 is FieldDeclaration && parent2.covariantKeyword != null;
    }
    return false;
  }

  bool isExternal(AstNode node) {
    if (node is ConstructorDeclaration) {
      return node.externalKeyword != null;
    } else if (node is FunctionDeclaration) {
      return node.externalKeyword != null;
    } else if (node is MethodDeclaration) {
      return node.externalKeyword != null;
    } else {
      throw UnimplementedError('${node.runtimeType}');
    }
  }

  bool isFinal(AstNode node) {
    if (node is EnumConstantDeclaration) {
      return false;
    }
    if (node is VariableDeclaration) {
      VariableDeclarationList parent = node.parent;
      return parent.isFinal;
    }
    throw UnimplementedError('${node.runtimeType}');
  }

  bool isFinalKeyword(int token) {
    return tokensContext.type(token) == UnlinkedTokenType.FINAL;
  }

  bool isFinalVariableList(LinkedNode node) {
    return isFinalKeyword(node.variableDeclarationList_keyword);
  }

  bool isFunction(LinkedNode node) {
    return node.kind == LinkedNodeKind.functionDeclaration;
  }

  bool isGenerator(AstNode node) {
    var body = _getFunctionBody(node);
    return body.isGenerator;
  }

  bool isGetter(AstNode node) {
    if (node is FunctionDeclaration) {
      return node.isGetter;
    } else if (node is MethodDeclaration) {
      return node.isGetter;
    } else {
      throw StateError('${node.runtimeType}');
    }
  }

  bool isLibraryKeyword(int token) {
    return tokensContext.type(token) == UnlinkedTokenType.LIBRARY;
  }

  bool isMethod(LinkedNode node) {
    return node.kind == LinkedNodeKind.methodDeclaration;
  }

  bool isSetter(AstNode node) {
    if (node is FunctionDeclaration) {
      return node.isSetter;
    } else if (node is MethodDeclaration) {
      return node.isSetter;
    } else {
      throw StateError('${node.runtimeType}');
    }
  }

  bool isSimplyBounded(AstNode node) {
    return LazyAst.isSimplyBounded(node);
  }

  bool isStatic(AstNode node) {
    if (node is FunctionDeclaration) {
      return true;
    } else if (node is MethodDeclaration) {
      return node.modifierKeyword != null;
    } else if (node is VariableDeclaration) {
      var parent2 = node.parent.parent;
      return parent2 is FieldDeclaration && parent2.isStatic;
    }
    throw UnimplementedError('${node.runtimeType}');
  }

  bool isSyncKeyword(int token) {
    return tokensContext.type(token) == UnlinkedTokenType.SYNC;
  }

  Expression readInitializer(AstNode node) {
    if (node is DefaultFormalParameter) {
      LazyFormalParameter.readDefaultValue(_astReader, node);
      return node.defaultValue;
    } else if (node is VariableDeclaration) {
      LazyVariableDeclaration.readInitializer(_astReader, node);
      return node.initializer;
    } else {
      throw StateError('${node.runtimeType}');
    }
  }

  AstNode readNode(LinkedNode linkedNode) {
    return _astReader.readNode(linkedNode);
  }

  DartType readType(LinkedNodeType linkedType) {
    if (linkedType == null) return null;

    var kind = linkedType.kind;
    if (kind == LinkedNodeTypeKind.bottom) {
      return BottomTypeImpl.instance;
    } else if (kind == LinkedNodeTypeKind.dynamic_) {
      return DynamicTypeImpl.instance;
    } else if (kind == LinkedNodeTypeKind.function) {
      var typeParameterDataList = linkedType.functionTypeParameters;

      var typeParameters = <TypeParameterElement>[];
      for (var typeParameterData in typeParameterDataList) {
        var element = TypeParameterElementImpl(typeParameterData.name, -1);
        typeParameters.add(element);
        _typeParameters[_nextSyntheticTypeParameterId++] = element;
      }

      var returnType = readType(linkedType.functionReturnType);
      var formalParameters = linkedType.functionFormalParameters.map((p) {
        var type = readType(p.type);
        var kind = _formalParameterKind(p.kind);
        return ParameterElementImpl.synthetic(p.name, type, kind);
      }).toList();

      for (var i = 0; i < typeParameterDataList.length; ++i) {
        _typeParameters.remove(--_nextSyntheticTypeParameterId);
      }

      return FunctionTypeImpl.synthetic(
        returnType,
        typeParameters,
        formalParameters,
      );
    } else if (kind == LinkedNodeTypeKind.interface) {
      var element = bundleContext.elementOfIndex(linkedType.interfaceClass);
      return InterfaceTypeImpl.explicit(
        element,
        linkedType.interfaceTypeArguments.map(readType).toList(),
      );
    } else if (kind == LinkedNodeTypeKind.typeParameter) {
      var id = linkedType.typeParameterId;
      var element = _typeParameters[id];
      assert(element != null);
      return TypeParameterTypeImpl(element);
    } else if (kind == LinkedNodeTypeKind.void_) {
      return VoidTypeImpl.instance;
    } else {
      throw UnimplementedError('$kind');
    }
  }

  void setOverrideInferenceDone(AstNode node) {
    // TODO(scheglov) This assert fails, check how to avoid this.
//    assert(!_astReader.isLazy);
    LazyAst.setOverrideInferenceDone(node);
  }

  void setReturnType(AstNode node, DartType type) {
    LazyAst.setReturnType(node, type);
  }

  void setVariableType(AstNode node, DartType type) {
    LazyAst.setType(node, type);
  }

  bool shouldBeConstFieldElement(AstNode node) {
    if (node is VariableDeclaration) {
      VariableDeclarationList variableList = node.parent;
      if (variableList.isConst) return true;

      if (variableList.isFinal) {
        ClassOrMixinDeclaration class_ = variableList.parent.parent;
        for (var member in class_.members) {
          if (member is ConstructorDeclaration && member.constKeyword != null) {
            return true;
          }
        }
      }
    }
    return false;
  }

  Iterable<VariableDeclaration> topLevelVariables(CompilationUnit unit) sync* {
    for (var declaration in unit.declarations) {
      if (declaration is TopLevelVariableDeclaration) {
        for (var variable in declaration.variables.variables) {
          yield variable;
        }
      }
    }
  }

  ParameterKind _formalParameterKind(LinkedNodeFormalParameterKind kind) {
    if (kind == LinkedNodeFormalParameterKind.optionalNamed) {
      return ParameterKind.NAMED;
    }
    if (kind == LinkedNodeFormalParameterKind.optionalPositional) {
      return ParameterKind.POSITIONAL;
    }
    return ParameterKind.REQUIRED;
  }

  List<ClassMember> _getClassOrMixinMembers(ClassOrMixinDeclaration node) {
    if (node is ClassDeclaration) {
      LazyClassDeclaration.readMembers(_astReader, node);
    } else if (node is MixinDeclaration) {
      LazyMixinDeclaration.readMembers(_astReader, node);
    } else {
      throw StateError('${node.runtimeType}');
    }
    return node.members;
  }

  FunctionBody _getFunctionBody(AstNode node) {
    if (node is ConstructorDeclaration) {
      LazyConstructorDeclaration.readBody(_astReader, node);
      return node.body;
    } else if (node is FunctionDeclaration) {
      LazyFunctionDeclaration.readFunctionExpression(_astReader, node);
      return _getFunctionBody(node.functionExpression);
    } else if (node is FunctionExpression) {
      LazyFunctionExpression.readBody(_astReader, node);
      return node.body;
    } else if (node is MethodDeclaration) {
      LazyMethodDeclaration.readBody(_astReader, node);
      return node.body;
    } else {
      throw UnimplementedError('${node.runtimeType}');
    }
  }

  NodeList<Annotation> _getPartDirectiveAnnotation() {
    if (indexInLibrary != 0) {
      var definingContext = libraryContext.definingUnit;
      var unit = definingContext.unit;
      var partDirectiveIndex = 0;
      for (var directive in unit.directives) {
        if (directive is PartDirective) {
          partDirectiveIndex++;
          if (partDirectiveIndex == indexInLibrary) {
            LazyDirective.readMetadata(definingContext._astReader, directive);
            return directive.metadata;
          }
        }
      }
    }
    throw StateError('Expected to find $indexInLibrary part directive.');
  }

  static List<LinkedNode> getTypeParameters(LinkedNode node) {
    LinkedNode typeParameterList;
    var kind = node.kind;
    if (kind == LinkedNodeKind.classTypeAlias) {
      typeParameterList = node.classTypeAlias_typeParameters;
    } else if (kind == LinkedNodeKind.classDeclaration ||
        kind == LinkedNodeKind.mixinDeclaration) {
      typeParameterList = node.classOrMixinDeclaration_typeParameters;
    } else if (kind == LinkedNodeKind.constructorDeclaration) {
      return const [];
    } else if (kind == LinkedNodeKind.functionDeclaration) {
      return getTypeParameters(node.functionDeclaration_functionExpression);
    } else if (kind == LinkedNodeKind.functionExpression) {
      typeParameterList = node.functionExpression_typeParameters;
    } else if (kind == LinkedNodeKind.functionTypeAlias) {
      typeParameterList = node.functionTypeAlias_typeParameters;
    } else if (kind == LinkedNodeKind.genericFunctionType) {
      typeParameterList = node.genericFunctionType_typeParameters;
    } else if (kind == LinkedNodeKind.genericTypeAlias) {
      typeParameterList = node.genericTypeAlias_typeParameters;
    } else if (kind == LinkedNodeKind.methodDeclaration) {
      typeParameterList = node.methodDeclaration_typeParameters;
    } else {
      throw UnimplementedError('$kind');
    }
    return typeParameterList?.typeParameterList_typeParameters;
  }
}
