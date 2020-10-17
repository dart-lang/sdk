// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_ast_factory.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/resolver/variance.dart';
import 'package:analyzer/src/generated/testing/token_factory.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary2/ast_binary_reader.dart';
import 'package:analyzer/src/summary2/lazy_ast.dart';
import 'package:analyzer/src/summary2/linked_bundle_context.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:analyzer/src/summary2/type_builder.dart';

/// The context of a unit - the context of the bundle, and the unit tokens.
class LinkedUnitContext {
  final LinkedBundleContext bundleContext;
  final LinkedLibraryContext libraryContext;
  final int indexInLibrary;
  final String partUriStr;
  final String uriStr;
  final Reference reference;
  final bool isSynthetic;
  final LinkedNodeUnit data;

  /// Optional informative data for the unit.
  List<UnlinkedInformativeData> informativeData;

  AstBinaryReader _astReader;

  CompilationUnit _unit;
  bool _hasDirectivesRead = false;

  final List<List<TypeParameterElement>> _typeParameterStack = [];
  List<TypeParameterElement> typeParameterStack = [];

  LinkedUnitContext(
      this.bundleContext,
      this.libraryContext,
      this.indexInLibrary,
      this.partUriStr,
      this.uriStr,
      this.reference,
      this.isSynthetic,
      this.data,
      {CompilationUnit unit}) {
    _astReader = AstBinaryReader(this);
    _astReader.isLazy = unit == null;

    _unit = unit;
    _hasDirectivesRead = _unit != null;
  }

  bool get hasPartOfDirective {
    for (var directive in unit_withDirectives.directives) {
      if (directive is PartOfDirective) {
        return true;
      }
    }
    return false;
  }

  /// Return `true` if this unit is a part of a bundle that is being linked.
  bool get isLinking => bundleContext.isLinking;

  TypeProvider get typeProvider {
    var libraryReference = libraryContext.reference;
    var libraryElement = libraryReference.element as LibraryElementImpl;
    return libraryElement.typeProvider;
  }

  CompilationUnit get unit => _unit;

  CompilationUnit get unit_withDeclarations {
    _ensureUnitWithDeclarations();
    return _unit;
  }

  CompilationUnit get unit_withDirectives {
    _ensureUnitWithDeclarations();
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

  Comment createComment(LinkedNode data) {
    var informativeData = getInformativeData(data);
    var tokenStringList = informativeData?.documentationComment_tokens;
    if (tokenStringList == null || tokenStringList.isEmpty) {
      return null;
    }

    var tokens = tokenStringList
        .map((lexeme) => TokenFactory.tokenFromString(lexeme))
        .toList();
    return astFactory.documentationComment(tokens);
  }

  /// Return the [LibraryElement] referenced in the [node].
  LibraryElement directiveLibrary(UriBasedDirective node) {
    var uriStr = LazyDirective.getSelectedUri(node);
    if (uriStr == null) return null;
    return bundleContext.elementFactory.libraryOfUri(uriStr);
  }

  T elementOfIndex<T extends Element>(int index) {
    if ((index & 0x1) == 0x1) {
      return typeParameterStack[index >> 1] as T;
    }
    return bundleContext.elementOfIndex(index);
  }

  int getCodeLength(AstNode node) {
    if (node is ClassDeclaration) {
      return LazyClassDeclaration.getCodeLength(this, node);
    } else if (node is ClassTypeAlias) {
      return LazyClassTypeAlias.getCodeLength(this, node);
    } else if (node is CompilationUnit) {
      if (data != null) {
        return getInformativeData(data.node)?.codeLength ?? 0;
      } else {
        return node.length;
      }
    } else if (node is ConstructorDeclaration) {
      return LazyConstructorDeclaration.getCodeLength(this, node);
    } else if (node is EnumConstantDeclaration) {
      return LazyEnumConstantDeclaration.getCodeLength(this, node);
    } else if (node is EnumDeclaration) {
      return LazyEnumDeclaration.getCodeLength(this, node);
    } else if (node is ExtensionDeclaration) {
      return LazyExtensionDeclaration.getCodeLength(this, node);
    } else if (node is FormalParameter) {
      return LazyFormalParameter.getCodeLength(this, node);
    } else if (node is FunctionDeclaration) {
      return LazyFunctionDeclaration.getCodeLength(this, node);
    } else if (node is FunctionTypeAliasImpl) {
      return LazyFunctionTypeAlias.getCodeLength(this, node);
    } else if (node is GenericTypeAlias) {
      return LazyGenericTypeAlias.getCodeLength(this, node);
    } else if (node is MethodDeclaration) {
      return LazyMethodDeclaration.getCodeLength(this, node);
    } else if (node is MixinDeclaration) {
      return LazyMixinDeclaration.getCodeLength(this, node);
    } else if (node is TypeParameter) {
      return LazyTypeParameter.getCodeLength(this, node);
    } else if (node is VariableDeclaration) {
      return LazyVariableDeclaration.getCodeLength(this, node);
    }
    throw UnimplementedError('${node.runtimeType}');
  }

  int getCodeOffset(AstNode node) {
    if (node is ClassDeclaration) {
      return LazyClassDeclaration.getCodeOffset(this, node);
    } else if (node is ClassTypeAlias) {
      return LazyClassTypeAlias.getCodeOffset(this, node);
    } else if (node is CompilationUnit) {
      return 0;
    } else if (node is ConstructorDeclaration) {
      return LazyConstructorDeclaration.getCodeOffset(this, node);
    } else if (node is EnumConstantDeclaration) {
      return LazyEnumConstantDeclaration.getCodeOffset(this, node);
    } else if (node is EnumDeclaration) {
      return LazyEnumDeclaration.getCodeOffset(this, node);
    } else if (node is ExtensionDeclaration) {
      return LazyExtensionDeclaration.getCodeOffset(this, node);
    } else if (node is FormalParameter) {
      return LazyFormalParameter.getCodeOffset(this, node);
    } else if (node is FunctionDeclaration) {
      return LazyFunctionDeclaration.getCodeOffset(this, node);
    } else if (node is FunctionTypeAliasImpl) {
      return LazyFunctionTypeAlias.getCodeOffset(this, node);
    } else if (node is GenericTypeAlias) {
      return LazyGenericTypeAlias.getCodeOffset(this, node);
    } else if (node is MethodDeclaration) {
      return LazyMethodDeclaration.getCodeOffset(this, node);
    } else if (node is MixinDeclaration) {
      return LazyMixinDeclaration.getCodeOffset(this, node);
    } else if (node is TypeParameter) {
      return LazyTypeParameter.getCodeOffset(this, node);
    } else if (node is VariableDeclaration) {
      return LazyVariableDeclaration.getCodeOffset(this, node);
    }
    throw UnimplementedError('${node.runtimeType}');
  }

  int getCombinatorEnd(ShowCombinator node) {
    return LazyCombinator.getEnd(this, node);
  }

  Iterable<ConstructorDeclaration> getConstructors(AstNode node) sync* {
    if (node is ClassOrMixinDeclaration) {
      var members = _getClassOrExtensionOrMixinMembers(node);
      for (var member in members) {
        if (member is ConstructorDeclaration) {
          yield member;
        }
      }
    }
  }

  DartType getDefaultType(TypeParameter node) {
    var type = LazyAst.getDefaultType(node);
    if (type is TypeBuilder) {
      type = (type as TypeBuilder).build();
      LazyAst.setDefaultType(node, type);
    }
    return type;
  }

  String getDefaultValueCode(AstNode node) {
    if (node is DefaultFormalParameter) {
      return LazyFormalParameter.getDefaultValueCode(this, node);
    }
    return null;
  }

  String getDefaultValueCodeData(LinkedNode data) {
    var informativeData = getInformativeData(data);
    return informativeData?.defaultFormalParameter_defaultValueCode;
  }

  int getDirectiveOffset(Directive node) {
    return node.keyword.offset;
  }

  Comment getDocumentationComment(AstNode node) {
    if (node is ClassDeclaration) {
      LazyClassDeclaration.readDocumentationComment(this, node);
      return node.documentationComment;
    } else if (node is ClassTypeAlias) {
      LazyClassTypeAlias.readDocumentationComment(this, node);
      return node.documentationComment;
    } else if (node is ConstructorDeclaration) {
      LazyConstructorDeclaration.readDocumentationComment(this, node);
      return node.documentationComment;
    } else if (node is EnumConstantDeclaration) {
      LazyEnumConstantDeclaration.readDocumentationComment(this, node);
      return node.documentationComment;
    } else if (node is EnumDeclaration) {
      LazyEnumDeclaration.readDocumentationComment(this, node);
      return node.documentationComment;
    } else if (node is ExtensionDeclaration) {
      LazyExtensionDeclaration.readDocumentationComment(this, node);
      return node.documentationComment;
    } else if (node is FunctionDeclaration) {
      LazyFunctionDeclaration.readDocumentationComment(this, node);
      return node.documentationComment;
    } else if (node is FunctionTypeAlias) {
      LazyFunctionTypeAlias.readDocumentationComment(this, node);
      return node.documentationComment;
    } else if (node is GenericTypeAlias) {
      LazyGenericTypeAlias.readDocumentationComment(this, node);
      return node.documentationComment;
    } else if (node is MethodDeclaration) {
      LazyMethodDeclaration.readDocumentationComment(this, node);
      return node.documentationComment;
    } else if (node is MixinDeclaration) {
      LazyMixinDeclaration.readDocumentationComment(this, node);
      return node.documentationComment;
    } else if (node is VariableDeclaration) {
      var parent2 = node.parent.parent;
      if (parent2 is FieldDeclaration) {
        LazyFieldDeclaration.readDocumentationComment(this, parent2);
        return parent2.documentationComment;
      } else if (parent2 is TopLevelVariableDeclaration) {
        LazyTopLevelVariableDeclaration.readDocumentationComment(
          this,
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

  String getExtensionRefName(ExtensionDeclaration node) {
    return LazyExtensionDeclaration.get(node).refName;
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

  Iterable<VariableDeclaration> getFields(CompilationUnitMember node) sync* {
    var members = _getClassOrExtensionOrMixinMembers(node);
    for (var member in members) {
      if (member is FieldDeclaration) {
        for (var field in member.fields.variables) {
          yield field;
        }
      }
    }
  }

  List<FormalParameter> getFormalParameters(AstNode node) {
    if (node is ConstructorDeclaration) {
      return node.parameters.parameters;
    } else if (node is FunctionDeclaration) {
      return getFormalParameters(node.functionExpression);
    } else if (node is FunctionExpression) {
      return node.parameters?.parameters;
    } else if (node is FormalParameter) {
      if (node is DefaultFormalParameter) {
        return getFormalParameters(node.parameter);
      } else if (node is FieldFormalParameter) {
        return node.parameters?.parameters;
      } else if (node is FunctionTypedFormalParameter) {
        return node.parameters.parameters;
      } else {
        return null;
      }
    } else if (node is FunctionTypeAlias) {
      return node.parameters.parameters;
    } else if (node is GenericFunctionType) {
      return node.parameters.parameters;
    } else if (node is MethodDeclaration) {
      return node.parameters?.parameters;
    } else {
      throw UnimplementedError('${node.runtimeType}');
    }
  }

  bool getHasTypedefSelfReference(AstNode node) {
    if (node is FunctionTypeAlias) {
      return LazyFunctionTypeAlias.getHasSelfReference(node);
    } else if (node is GenericTypeAlias) {
      return LazyGenericTypeAlias.getHasSelfReference(node);
    }
    return false;
  }

  ImplementsClause getImplementsClause(AstNode node) {
    if (node is ClassDeclaration) {
      return node.implementsClause;
    } else if (node is ClassTypeAlias) {
      return node.implementsClause;
    } else if (node is MixinDeclaration) {
      return node.implementsClause;
    } else {
      throw UnimplementedError('${node.runtimeType}');
    }
  }

  UnlinkedInformativeData getInformativeData(LinkedNode data) {
    if (informativeData == null) return null;

    var id = data.informativeId;
    if (id == 0) return null;

    return informativeData[id - 1];
  }

  bool getInheritsCovariant(AstNode node) {
    if (node is DefaultFormalParameter) {
      return getInheritsCovariant(node.parameter);
    } else if (node is FormalParameter) {
      return LazyAst.getInheritsCovariant(node);
    } else if (node is VariableDeclaration) {
      return LazyAst.getInheritsCovariant(node);
    } else {
      throw StateError('${node.runtimeType}');
    }
  }

  LibraryLanguageVersion getLanguageVersion(CompilationUnit node) {
    return LazyCompilationUnit.getLanguageVersion(node);
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
        LazyAst.applyResolution(directive);
        return getMetadata(directive);
      }
    }
    return const <Annotation>[];
  }

  List<Annotation> getMetadata(AstNode node) {
    if (node is ClassDeclaration) {
      return node.metadata;
    } else if (node is ClassTypeAlias) {
      return node.metadata;
    } else if (node is CompilationUnit) {
      assert(node == _unit);
      if (indexInLibrary != 0) {
        return _getPartDirectiveAnnotation();
      } else {
        return const <Annotation>[];
      }
    } else if (node is ConstructorDeclaration) {
      return node.metadata;
    } else if (node is DefaultFormalParameter) {
      return getMetadata(node.parameter);
    } else if (node is Directive) {
      return node.metadata;
    } else if (node is EnumConstantDeclaration) {
      return node.metadata;
    } else if (node is EnumDeclaration) {
      return node.metadata;
    } else if (node is ExtensionDeclaration) {
      return node.metadata;
    } else if (node is FormalParameter) {
      return node.metadata;
    } else if (node is FunctionDeclaration) {
      return node.metadata;
    } else if (node is FunctionTypeAlias) {
      return node.metadata;
    } else if (node is GenericTypeAlias) {
      return node.metadata;
    } else if (node is MethodDeclaration) {
      return node.metadata;
    } else if (node is MixinDeclaration) {
      return node.metadata;
    } else if (node is TypeParameter) {
      return node.metadata;
    } else if (node is VariableDeclaration) {
      var parent2 = node.parent.parent;
      if (parent2 is FieldDeclaration) {
        return parent2.metadata;
      } else if (parent2 is TopLevelVariableDeclaration) {
        return parent2.metadata;
      }
    }
    return const <Annotation>[];
  }

  Iterable<MethodDeclaration> getMethods(CompilationUnitMember node) sync* {
    var members = _getClassOrExtensionOrMixinMembers(node);
    for (var member in members) {
      if (member is MethodDeclaration) {
        yield member;
      }
    }
  }

  List<String> getMixinSuperInvokedNames(MixinDeclaration node) {
    return LazyMixinDeclaration.get(node).getSuperInvokedNames();
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
    } else if (node is ExtensionDeclaration) {
      return node.name?.offset ?? -1;
    } else if (node is FormalParameter) {
      return node.identifier?.offset ?? -1;
    } else if (node is MethodDeclaration) {
      return node.name.offset;
    } else if (node is NamedCompilationUnitMember) {
      return node.name.offset;
    } else if (node is TypeParameter) {
      return node.name.offset;
    } else if (node is VariableDeclaration) {
      return node.name.offset;
    }
    throw UnimplementedError('${node.runtimeType}');
  }

  /// Return the actual return type for the [node] - explicit or inferred.
  DartType getReturnType(AstNode node) {
    if (node is FunctionDeclaration) {
      return LazyAst.getReturnType(node);
    } else if (node is FunctionTypeAlias) {
      return LazyAst.getReturnType(node);
    } else if (node is GenericFunctionType) {
      return node.returnType?.type ?? DynamicTypeImpl.instance;
    } else if (node is MethodDeclaration) {
      return LazyAst.getReturnType(node);
    } else {
      throw UnimplementedError('${node.runtimeType}');
    }
  }

  TypeAnnotation getReturnTypeNode(AstNode node) {
    if (node is FunctionTypeAlias) {
      return node.returnType;
    } else if (node is GenericFunctionType) {
      return node.returnType;
    } else if (node is FunctionDeclaration) {
      return node.returnType;
    } else if (node is MethodDeclaration) {
      return node.returnType;
    } else {
      throw UnimplementedError('${node.runtimeType}');
    }
  }

  String getSelectedUri(UriBasedDirective node) {
    return LazyDirective.getSelectedUri(node);
  }

  TypeName getSuperclass(AstNode node) {
    if (node is ClassDeclaration) {
      return node.extendsClause?.superclass;
    } else if (node is ClassTypeAlias) {
      return node.superclass;
    } else {
      throw StateError('${node.runtimeType}');
    }
  }

  /// Return the actual type for the [node] - explicit or inferred.
  DartType getType(AstNode node) {
    if (node is DefaultFormalParameter) {
      return getType(node.parameter);
    } else if (node is FormalParameter) {
      return LazyAst.getType(node);
    } else if (node is VariableDeclaration) {
      return LazyAst.getType(node);
    } else {
      throw UnimplementedError('${node.runtimeType}');
    }
  }

  TopLevelInferenceError getTypeInferenceError(AstNode node) {
    if (node is MethodDeclaration) {
      return LazyMethodDeclaration.getTypeInferenceError(node);
    } else if (node is VariableDeclaration) {
      return LazyVariableDeclaration.getTypeInferenceError(node);
    } else {
      return null;
    }
  }

  TypeParameterList getTypeParameters(AstNode node) {
    if (node is ClassDeclaration) {
      return node.typeParameters;
    } else if (node is ClassTypeAlias) {
      return node.typeParameters;
    } else if (node is ConstructorDeclaration) {
      return null;
    } else if (node is DefaultFormalParameter) {
      return getTypeParameters(node.parameter);
    } else if (node is ExtensionDeclaration) {
      return node.typeParameters;
    } else if (node is FieldFormalParameter) {
      return node.typeParameters;
    } else if (node is FunctionDeclaration) {
      return getTypeParameters(node.functionExpression);
    } else if (node is FunctionExpression) {
      return node.typeParameters;
    } else if (node is FunctionTypedFormalParameter) {
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
    } else if (node is SimpleFormalParameter) {
      return null;
    } else {
      throw UnimplementedError('${node.runtimeType}');
    }
  }

  Variance getTypeParameterVariance(TypeParameter node) {
    return LazyAst.getVariance(node);
  }

  WithClause getWithClause(AstNode node) {
    if (node is ClassDeclaration) {
      return node.withClause;
    } else if (node is ClassTypeAlias) {
      return node.withClause;
    } else {
      throw UnimplementedError('${node.runtimeType}');
    }
  }

  bool hasDefaultValue(FormalParameter node) {
    if (node is DefaultFormalParameter) {
      return LazyFormalParameter.hasDefaultValue(node);
    }
    return false;
  }

  bool hasImplicitReturnType(AstNode node) {
    if (node is FunctionDeclaration) {
      return node.returnType == null;
    }
    if (node is MethodDeclaration) {
      return node.returnType == null;
    }
    return false;
  }

  bool hasImplicitType(AstNode node) {
    if (node is DefaultFormalParameter) {
      return hasImplicitType(node.parameter);
    } else if (node is SimpleFormalParameter) {
      return node.type == null;
    } else if (node is VariableDeclaration) {
      VariableDeclarationList parent = node.parent;
      LazyVariableDeclarationList.readTypeNode(_astReader, parent);
      return parent.type == null;
    }
    return false;
  }

  bool hasInitializer(VariableDeclaration node) {
    return LazyVariableDeclaration.hasInitializer(node);
  }

  bool hasOperatorEqualParameterTypeFromObject(MethodDeclaration node) {
    return LazyAst.hasOperatorEqualParameterTypeFromObject(node);
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
    } else if (node is ConstructorDeclaration) {
      return false;
    } else if (node is FunctionDeclaration) {
      return false;
    } else if (node is MethodDeclaration) {
      return LazyMethodDeclaration.isAbstract(node);
    } else if (node is VariableDeclaration) {
      var parent = node.parent;
      if (parent is VariableDeclarationList) {
        var grandParent = parent.parent;
        if (grandParent is FieldDeclaration) {
          return grandParent.abstractKeyword != null;
        } else {
          throw UnimplementedError('${grandParent.runtimeType}');
        }
      } else {
        throw UnimplementedError('${parent.runtimeType}');
      }
    } else if (node is EnumConstantDeclaration) {
      return false;
    }
    throw UnimplementedError('${node.runtimeType}');
  }

  bool isAsynchronous(AstNode node) {
    if (node is ConstructorDeclaration) {
      return false;
    } else if (node is FunctionDeclaration) {
      return isAsynchronous(node.functionExpression);
    } else if (node is FunctionExpression) {
      return LazyFunctionExpression.isAsynchronous(node);
    } else if (node is MethodDeclaration) {
      return LazyMethodDeclaration.isAsynchronous(node);
    } else {
      throw UnimplementedError('${node.runtimeType}');
    }
  }

  bool isConst(AstNode node) {
    if (node is FormalParameter) {
      return node.isConst;
    }
    if (node is VariableDeclaration) {
      VariableDeclarationList parent = node.parent;
      return parent.isConst;
    }
    throw UnimplementedError('${node.runtimeType}');
  }

  bool isExplicitlyCovariant(AstNode node) {
    if (node is DefaultFormalParameter) {
      return isExplicitlyCovariant(node.parameter);
    } else if (node is EnumConstantDeclaration) {
      return false;
    } else if (node is FormalParameter) {
      return node.covariantKeyword != null;
    } else if (node is VariableDeclaration) {
      var parent2 = node.parent.parent;
      return parent2 is FieldDeclaration && parent2.covariantKeyword != null;
    } else {
      throw StateError('${node.runtimeType}');
    }
  }

  bool isExternal(AstNode node) {
    if (node is ConstructorDeclaration) {
      return node.externalKeyword != null;
    } else if (node is FunctionDeclaration) {
      return node.externalKeyword != null;
    } else if (node is MethodDeclaration) {
      return node.externalKeyword != null || node.body is NativeFunctionBody;
    } else if (node is VariableDeclaration) {
      var parent = node.parent;
      if (parent is VariableDeclarationList) {
        var grandParent = parent.parent;
        if (grandParent is FieldDeclaration) {
          return grandParent.externalKeyword != null;
        } else if (grandParent is TopLevelVariableDeclaration) {
          return grandParent.externalKeyword != null;
        } else {
          throw UnimplementedError('${grandParent.runtimeType}');
        }
      } else {
        throw UnimplementedError('${parent.runtimeType}');
      }
    } else if (node is EnumConstantDeclaration) {
      return false;
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

  bool isGenerator(AstNode node) {
    if (node is ConstructorDeclaration) {
      return false;
    } else if (node is FunctionDeclaration) {
      return isGenerator(node.functionExpression);
    } else if (node is FunctionExpression) {
      return LazyFunctionExpression.isGenerator(node);
    } else if (node is MethodDeclaration) {
      return LazyMethodDeclaration.isGenerator(node);
    } else {
      throw UnimplementedError('${node.runtimeType}');
    }
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

  bool isLate(AstNode node) {
    if (node is VariableDeclaration) {
      return node.isLate;
    }
    if (node is EnumConstantDeclaration) {
      return false;
    }
    throw UnimplementedError('${node.runtimeType}');
  }

  bool isNative(AstNode node) {
    if (node is MethodDeclaration) {
      return node.body is NativeFunctionBody;
    } else {
      throw UnimplementedError('${node.runtimeType}');
    }
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

  /// Restore the stack previously saved by [pushTypeParameterStack].
  void popTypeParameterStack() {
    typeParameterStack = _typeParameterStack.removeLast();
  }

  /// We are about to start applying resolution to a declaration. But this
  /// might be a recursive process, and so we might still be applying
  /// resolution to some other declaration. These have their own indexes for
  /// type parameters, so we want to push the current stack, and start with
  /// a new one. Later we will restore it with [popTypeParameterStack].
  void pushTypeParameterStack() {
    _typeParameterStack.add(typeParameterStack);
    typeParameterStack = [];
  }

  Expression readInitializer(AstNode node) {
    if (node is DefaultFormalParameter) {
      return node.defaultValue;
    } else if (node is VariableDeclaration) {
      return node.initializer;
    } else {
      throw StateError('${node.runtimeType}');
    }
  }

  DartType readType(LinkedNodeType linkedType) {
    if (linkedType == null) return null;

    var kind = linkedType.kind;
    if (kind == LinkedNodeTypeKind.null_) {
      return null;
    } else if (kind == LinkedNodeTypeKind.dynamic_) {
      return DynamicTypeImpl.instance;
    } else if (kind == LinkedNodeTypeKind.function) {
      var typeParameterDataList = linkedType.functionTypeParameters;

      var typeParametersLength = typeParameterDataList.length;
      var typeParameters = List<TypeParameterElement>(typeParametersLength);
      for (var i = 0; i < typeParametersLength; ++i) {
        var typeParameterData = typeParameterDataList[i];
        var element = TypeParameterElementImpl(typeParameterData.name, -1);
        typeParameters[i] = element;
      }

      var typeParameterStackHeight = typeParameterStack.length;
      typeParameterStack.addAll(typeParameters);

      // Type parameters might use each other in bounds, including forward
      // references. So, we read bounds after reading all type parameters.
      for (var i = 0; i < typeParametersLength; ++i) {
        var typeParameterData = typeParameterDataList[i];
        TypeParameterElementImpl element = typeParameters[i];
        element.bound = readType(typeParameterData.bound);
      }

      var returnType = readType(linkedType.functionReturnType);
      var formalParameters = linkedType.functionFormalParameters.map((p) {
        var type = readType(p.type);
        var kind = _formalParameterKind(p.kind);
        return ParameterElementImpl.synthetic(p.name, type, kind);
      }).toList();

      typeParameterStack.length = typeParameterStackHeight;

      FunctionTypeAliasElement typedefElement;
      List<DartType> typedefTypeArguments = const <DartType>[];
      if (linkedType.functionTypedef != 0) {
        typedefElement =
            bundleContext.elementOfIndex(linkedType.functionTypedef);
        typedefTypeArguments =
            linkedType.functionTypedefTypeArguments.map(readType).toList();
      }

      var nullabilitySuffix = _nullabilitySuffix(linkedType.nullabilitySuffix);

      return FunctionTypeImpl(
        typeFormals: typeParameters,
        parameters: formalParameters,
        returnType: returnType,
        nullabilitySuffix: nullabilitySuffix,
        element: typedefElement,
        typeArguments: typedefTypeArguments,
      );
    } else if (kind == LinkedNodeTypeKind.interface) {
      var element = bundleContext.elementOfIndex(linkedType.interfaceClass);
      var nullabilitySuffix = _nullabilitySuffix(linkedType.nullabilitySuffix);
      return InterfaceTypeImpl(
        element: element,
        typeArguments: linkedType.interfaceTypeArguments.map(readType).toList(),
        nullabilitySuffix: nullabilitySuffix,
      );
    } else if (kind == LinkedNodeTypeKind.never) {
      var nullabilitySuffix = _nullabilitySuffix(linkedType.nullabilitySuffix);
      return NeverTypeImpl.instance.withNullability(nullabilitySuffix);
    } else if (kind == LinkedNodeTypeKind.typeParameter) {
      var element = elementOfIndex(linkedType.typeParameterId);
      var nullabilitySuffix = _nullabilitySuffix(linkedType.nullabilitySuffix);
      return TypeParameterTypeImpl(
        element: element,
        nullabilitySuffix: nullabilitySuffix,
      );
    } else if (kind == LinkedNodeTypeKind.void_) {
      return VoidTypeImpl.instance;
    } else {
      throw UnimplementedError('$kind');
    }
  }

  void setInheritsCovariant(AstNode node, bool value) {
    if (node is DefaultFormalParameter) {
      setInheritsCovariant(node.parameter, value);
    } else if (node is FormalParameter) {
      LazyAst.setInheritsCovariant(node, value);
    } else if (node is VariableDeclaration) {
      LazyAst.setInheritsCovariant(node, value);
    } else {
      throw StateError('${node.runtimeType}');
    }
  }

  void setOperatorEqualParameterTypeFromObject(AstNode node, bool value) {
    LazyAst.setOperatorEqualParameterTypeFromObject(node, value);
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
    if (node is DefaultFormalParameter) {
      setVariableType(node.parameter, type);
    } else {
      LazyAst.setType(node, type);
    }
  }

  bool shouldBeConstFieldElement(AstNode node) {
    if (node is VariableDeclaration) {
      VariableDeclarationList variableList = node.parent;
      if (variableList.isConst) return true;

      FieldDeclaration fieldDeclaration = variableList.parent;
      if (fieldDeclaration.staticKeyword != null) return false;

      if (variableList.isFinal) {
        var class_ = fieldDeclaration.parent;
        if (class_ is ClassOrMixinDeclaration) {
          for (var member in class_.members) {
            if (member is ConstructorDeclaration &&
                member.constKeyword != null) {
              return true;
            }
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

  void _ensureUnitWithDeclarations() {
    if (_unit == null) {
      _unit = _astReader.readNode(data.node);

      var informativeData = getInformativeData(data.node);
      var lineStarts = informativeData?.compilationUnit_lineStarts ?? [];
      if (lineStarts.isEmpty) {
        lineStarts = [0];
      }
      _unit.lineInfo = LineInfo(lineStarts);
    }
  }

  ParameterKind _formalParameterKind(LinkedNodeFormalParameterKind kind) {
    if (kind == LinkedNodeFormalParameterKind.optionalNamed) {
      return ParameterKind.NAMED;
    } else if (kind == LinkedNodeFormalParameterKind.optionalPositional) {
      return ParameterKind.POSITIONAL;
    } else if (kind == LinkedNodeFormalParameterKind.requiredNamed) {
      return ParameterKind.NAMED_REQUIRED;
    }
    return ParameterKind.REQUIRED;
  }

  List<ClassMember> _getClassOrExtensionOrMixinMembers(
    CompilationUnitMember node,
  ) {
    if (node is ClassDeclaration) {
      LazyClassDeclaration.readMembers(_astReader, node);
      return node.members;
    } else if (node is ClassTypeAlias) {
      return <ClassMember>[];
    } else if (node is ExtensionDeclaration) {
      LazyExtensionDeclaration.readMembers(_astReader, node);
      return node.members;
    } else if (node is MixinDeclaration) {
      LazyMixinDeclaration.readMembers(_astReader, node);
      return node.members;
    } else {
      throw StateError('${node.runtimeType}');
    }
  }

  NodeList<Annotation> _getPartDirectiveAnnotation() {
    var definingContext = libraryContext.definingUnit;
    var unit = definingContext.unit;
    var partDirectiveIndex = 0;
    for (var directive in unit.directives) {
      if (directive is PartDirective) {
        partDirectiveIndex++;
        if (partDirectiveIndex == indexInLibrary) {
          LazyAst.applyResolution(directive);
          return directive.metadata;
        }
      }
    }
    throw StateError('Expected to find $indexInLibrary part directive.');
  }

  static NullabilitySuffix _nullabilitySuffix(EntityRefNullabilitySuffix data) {
    switch (data) {
      case EntityRefNullabilitySuffix.starOrIrrelevant:
        return NullabilitySuffix.star;
      case EntityRefNullabilitySuffix.question:
        return NullabilitySuffix.question;
      case EntityRefNullabilitySuffix.none:
        return NullabilitySuffix.none;
      default:
        throw StateError('$data');
    }
  }
}
