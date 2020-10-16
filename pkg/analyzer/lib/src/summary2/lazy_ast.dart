// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/resolver/variance.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary2/apply_resolution.dart';
import 'package:analyzer/src/summary2/ast_binary_flags.dart';
import 'package:analyzer/src/summary2/ast_binary_reader.dart';
import 'package:analyzer/src/summary2/linked_unit_context.dart';
import 'package:pub_semver/pub_semver.dart';

/// Accessor for reading AST lazily, or read data that is stored in IDL, but
/// cannot be stored in AST, like inferred types.
class LazyAst {
  static const _defaultTypeKey = 'lazyAst_defaultType';
  static const _genericFunctionTypeIdKey = 'lazyAst_genericFunctionTypeId';
  static const _hasOverrideInferenceKey = 'lazyAst_hasOverrideInference';
  static const _inheritsCovariantKey = 'lazyAst_isCovariant';
  static const _isSimplyBoundedKey = 'lazyAst_simplyBounded';
  static const _isOperatorEqualParameterTypeFromObjectKey =
      'lazyAst_isOperatorEqualParameterTypeFromObject';
  static const _rawFunctionTypeKey = 'lazyAst_rawFunctionType';
  static const _returnTypeKey = 'lazyAst_returnType';
  static const _typeInferenceErrorKey = 'lazyAst_typeInferenceError';
  static const _typeKey = 'lazyAst_type';
  static const _varianceKey = 'lazyAst_variance';

  static final Expando<LinkedNode> _dataExpando = Expando();

  final LinkedNode data;

  LazyAst(this.data);

  static void applyResolution(AstNode node) {
    if (node is ClassDeclaration) {
      var lazy = LazyClassDeclaration.get(node);
      lazy?.applyResolution();
    } else if (node is ClassTypeAlias) {
      var lazy = LazyClassTypeAlias.get(node);
      lazy?.applyResolution();
    } else if (node is CompilationUnit) {
      // TODO(scheglov)
    } else if (node is ConstructorDeclaration) {
      var lazy = LazyConstructorDeclaration.get(node);
      lazy?.applyResolution();
    } else if (node is Directive) {
      var lazy = LazyDirective.get(node);
      lazy?.applyResolution();
    } else if (node is EnumDeclaration) {
      var lazy = LazyEnumDeclaration.get(node);
      lazy?.applyResolution();
    } else if (node is ExtensionDeclaration) {
      var lazy = LazyExtensionDeclaration.get(node);
      if (lazy?.data != null) {
        lazy?.applyResolution();
      }
    } else if (node is FieldFormalParameter) {
      // TODO(scheglov)
    } else if (node is FunctionDeclaration) {
      var lazy = LazyFunctionDeclaration.get(node);
      lazy?.applyResolution();
    } else if (node is FunctionTypeAlias) {
      var lazy = LazyFunctionTypeAlias.get(node);
      lazy?.applyResolution();
    } else if (node is GenericFunctionType) {
      // TODO(scheglov)
    } else if (node is GenericTypeAlias) {
      var lazy = LazyGenericTypeAlias.get(node);
      lazy?.applyResolution();
    } else if (node is ImportDirective) {
      // TODO(scheglov)
    } else if (node is MethodDeclaration) {
      var lazy = LazyMethodDeclaration.get(node);
      lazy?.applyResolution();
    } else if (node is MixinDeclaration) {
      var lazy = LazyMixinDeclaration.get(node);
      if (lazy?.data != null) {
        lazy?.applyResolution();
      }
    } else if (node is SimpleFormalParameter) {
      // TODO(scheglov)
    } else if (node is VariableDeclaration) {
      var parent2 = node.parent.parent;
      if (parent2 is FieldDeclaration) {
        var lazy = LazyFieldDeclaration.get(parent2);
        lazy?.applyResolution();
      } else if (parent2 is TopLevelVariableDeclaration) {
        var lazy = LazyTopLevelVariableDeclaration.get(parent2);
        lazy?.applyResolution();
      } else {
        throw UnimplementedError('${parent2.runtimeType}');
      }
    }
  }

  static LinkedNode getData(AstNode node) {
    return _dataExpando[node];
  }

  static DartType getDefaultType(TypeParameter node) {
    return node.getProperty(_defaultTypeKey);
  }

  static int getGenericFunctionTypeId(GenericFunctionType node) {
    return node.getProperty(_genericFunctionTypeIdKey);
  }

  static bool getInheritsCovariant(AstNode node) {
    return node.getProperty(_inheritsCovariantKey) ?? false;
  }

  static DartType getRawFunctionType(AstNode node) {
    return node.getProperty(_rawFunctionTypeKey);
  }

  static DartType getReturnType(AstNode node) {
    return node.getProperty(_returnTypeKey);
  }

  static DartType getType(AstNode node) {
    return node.getProperty(_typeKey);
  }

  static TopLevelInferenceError getTypeInferenceError(AstNode node) {
    return node.getProperty(_typeInferenceErrorKey);
  }

  static Variance getVariance(TypeParameter node) {
    return node.getProperty(_varianceKey);
  }

  static bool hasOperatorEqualParameterTypeFromObject(AstNode node) {
    return node.getProperty(_isOperatorEqualParameterTypeFromObjectKey) ??
        false;
  }

  static bool hasOverrideInferenceDone(AstNode node) {
    return node.getProperty(_hasOverrideInferenceKey) ?? false;
  }

  static bool isSimplyBounded(AstNode node) {
    return node.getProperty(_isSimplyBoundedKey);
  }

  static void setData(AstNode node, LinkedNode data) {
    _dataExpando[node] = data;
  }

  static void setDefaultType(TypeParameter node, DartType type) {
    node.setProperty(_defaultTypeKey, type);
  }

  static void setGenericFunctionTypeId(GenericFunctionType node, int id) {
    node.setProperty(_genericFunctionTypeIdKey, id);
  }

  static void setInheritsCovariant(AstNode node, bool value) {
    node.setProperty(_inheritsCovariantKey, value);
  }

  static void setOperatorEqualParameterTypeFromObject(AstNode node, bool b) {
    node.setProperty(_isOperatorEqualParameterTypeFromObjectKey, b);
  }

  static void setOverrideInferenceDone(AstNode node) {
    node.setProperty(_hasOverrideInferenceKey, true);
  }

  static void setRawFunctionType(AstNode node, DartType type) {
    node.setProperty(_rawFunctionTypeKey, type);
  }

  static void setReturnType(AstNode node, DartType type) {
    node.setProperty(_returnTypeKey, type);
  }

  static void setSimplyBounded(AstNode node, bool simplyBounded) {
    node.setProperty(_isSimplyBoundedKey, simplyBounded);
  }

  static void setType(AstNode node, DartType type) {
    node.setProperty(_typeKey, type);
  }

  static void setTypeInferenceError(
      AstNode node, TopLevelInferenceError error) {
    node.setProperty(_typeInferenceErrorKey, error);
  }

  static void setVariance(TypeParameter node, Variance variance) {
    return node.setProperty(_varianceKey, variance);
  }
}

class LazyClassDeclaration {
  static const _key = 'lazyAst';

  final LinkedUnitContext unitContext;
  final LinkedNode data;
  final ClassDeclaration node;

  bool _hasDocumentationComment = false;
  bool _hasMembers = false;
  bool _hasResolutionApplied = false;

  LazyClassDeclaration(this.unitContext, this.data, this.node);

  void applyResolution() {
    if (_hasResolutionApplied) {
      return;
    }
    _hasResolutionApplied = true;

    unitContext.pushTypeParameterStack();

    var visitor = ApplyResolutionVisitor(unitContext, data.resolution);
    node.accept(visitor);

    unitContext.popTypeParameterStack();
  }

  static LazyClassDeclaration get(ClassDeclaration node) {
    return node.getProperty(_key);
  }

  static int getCodeLength(
    LinkedUnitContext context,
    ClassDeclaration node,
  ) {
    var lazy = get(node);
    if (lazy != null) {
      return context.getInformativeData(lazy.data)?.codeLength ?? 0;
    }
    return node.length;
  }

  static int getCodeOffset(
    LinkedUnitContext context,
    ClassDeclaration node,
  ) {
    var lazy = get(node);
    if (lazy != null) {
      return context.getInformativeData(lazy.data)?.codeOffset ?? 0;
    }
    return node.offset;
  }

  static void readDocumentationComment(
    LinkedUnitContext context,
    ClassDeclaration node,
  ) {
    var lazy = get(node);
    if (lazy != null && !lazy._hasDocumentationComment) {
      node.documentationComment = context.createComment(lazy.data);
      lazy._hasDocumentationComment = true;
    }
  }

  static void readMembers(
    AstBinaryReader reader,
    ClassDeclaration node,
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

  static void setData(
    LinkedUnitContext unitContext,
    LinkedNode data,
    ClassDeclaration node,
  ) {
    node.setProperty(_key, LazyClassDeclaration(unitContext, data, node));
    LazyAst.setSimplyBounded(node, data.simplyBoundable_isSimplyBounded);
  }
}

class LazyClassTypeAlias {
  static const _key = 'lazyAst';

  final LinkedUnitContext unitContext;
  final LinkedNode data;
  final ClassTypeAlias node;

  bool _hasDocumentationComment = false;
  bool _hasResolutionApplied = false;

  LazyClassTypeAlias(this.unitContext, this.data, this.node);

  void applyResolution() {
    if (_hasResolutionApplied) {
      return;
    }
    _hasResolutionApplied = true;

    unitContext.pushTypeParameterStack();

    var visitor = ApplyResolutionVisitor(unitContext, data.resolution);
    node.accept(visitor);

    unitContext.popTypeParameterStack();
  }

  static LazyClassTypeAlias get(ClassTypeAlias node) {
    return node.getProperty(_key);
  }

  static int getCodeLength(
    LinkedUnitContext context,
    ClassTypeAlias node,
  ) {
    var lazy = get(node);
    if (lazy != null) {
      return context.getInformativeData(lazy.data)?.codeLength ?? 0;
    }
    return node.length;
  }

  static int getCodeOffset(
    LinkedUnitContext context,
    ClassTypeAlias node,
  ) {
    var lazy = get(node);
    if (lazy != null) {
      return context.getInformativeData(lazy.data)?.codeOffset ?? 0;
    }
    return node.offset;
  }

  static void readDocumentationComment(
    LinkedUnitContext context,
    ClassTypeAlias node,
  ) {
    var lazy = get(node);
    if (lazy != null && !lazy._hasDocumentationComment) {
      node.documentationComment = context.createComment(lazy.data);
      lazy._hasDocumentationComment = true;
    }
  }

  static void setData(
    LinkedUnitContext unitContext,
    LinkedNode data,
    ClassTypeAlias node,
  ) {
    node.setProperty(_key, LazyClassTypeAlias(unitContext, data, node));
    LazyAst.setSimplyBounded(node, data.simplyBoundable_isSimplyBounded);
  }
}

class LazyCombinator {
  static const _key = 'lazyAst';

  final LinkedNode data;

  LazyCombinator(Combinator node, this.data) {
    node.setProperty(_key, this);
  }

  static LazyCombinator get(Combinator node) {
    return node.getProperty(_key);
  }

  static int getEnd(
    LinkedUnitContext context,
    Combinator node,
  ) {
    var lazy = get(node);
    if (lazy != null) {
      var informativeData = context.getInformativeData(lazy.data);
      return informativeData?.combinatorEnd ?? 0;
    }
    return node.end;
  }
}

class LazyCompilationUnit {
  static const _key = 'lazyAst';

  final LinkedNode data;

  LazyCompilationUnit(CompilationUnit node, this.data) {
    node.setProperty(_key, this);
  }

  static LazyCompilationUnit get(CompilationUnit node) {
    return node.getProperty(_key);
  }

  static LibraryLanguageVersion getLanguageVersion(CompilationUnit node) {
    var lazy = get(node);
    if (lazy != null) {
      var package = lazy.data.compilationUnit_languageVersion.package;
      var override = lazy.data.compilationUnit_languageVersion.override2;
      return LibraryLanguageVersion(
        package: Version(package.major, package.minor, 0),
        override: override != null
            ? Version(override.major, override.minor, 0)
            : null,
      );
    }
    return (node as CompilationUnitImpl).languageVersion;
  }
}

class LazyConstructorDeclaration {
  static const _key = 'lazyAst';

  final LinkedUnitContext unitContext;
  final LinkedNode data;
  final ConstructorDeclaration node;

  bool _hasDocumentationComment = false;
  bool _hasResolutionApplied = false;

  LazyConstructorDeclaration(this.unitContext, this.data, this.node);

  void applyResolution() {
    if (_hasResolutionApplied) {
      return;
    }
    _hasResolutionApplied = true;

    unitContext.pushTypeParameterStack();

    var visitor = ApplyResolutionVisitor(unitContext, data.resolution);
    visitor.addParentTypeParameters(node);
    node.accept(visitor);

    unitContext.popTypeParameterStack();
  }

  static LazyConstructorDeclaration get(ConstructorDeclaration node) {
    return node.getProperty(_key);
  }

  static int getCodeLength(
    LinkedUnitContext context,
    ConstructorDeclaration node,
  ) {
    var lazy = get(node);
    if (lazy != null) {
      return context.getInformativeData(lazy.data)?.codeLength ?? 0;
    }
    return node.length;
  }

  static int getCodeOffset(
    LinkedUnitContext context,
    ConstructorDeclaration node,
  ) {
    var lazy = get(node);
    if (lazy != null) {
      return context.getInformativeData(lazy.data)?.codeOffset ?? 0;
    }
    return node.offset;
  }

  static void readDocumentationComment(
    LinkedUnitContext context,
    ConstructorDeclaration node,
  ) {
    var lazy = get(node);
    if (lazy != null && !lazy._hasDocumentationComment) {
      node.documentationComment = context.createComment(lazy.data);
      lazy._hasDocumentationComment = true;
    }
  }

  static void setData(
    LinkedUnitContext unitContext,
    LinkedNode data,
    ConstructorDeclaration node,
  ) {
    node.setProperty(_key, LazyConstructorDeclaration(unitContext, data, node));
  }
}

class LazyDirective {
  static const _key = 'lazyAst';
  static const _uriKey = 'lazyAst_selectedUri';

  final LinkedUnitContext unitContext;
  final LinkedNode data;
  final Directive node;

  bool _hasResolutionApplied = false;

  LazyDirective(this.unitContext, this.data, this.node);

  void applyResolution() {
    if (_hasResolutionApplied) {
      return;
    }

    var visitor = ApplyResolutionVisitor(unitContext, data.resolution);
    node.accept(visitor);

    _hasResolutionApplied = true;
  }

  static LazyDirective get(Directive node) {
    return node.getProperty(_key);
  }

  static String getSelectedUri(UriBasedDirective node) {
    return node.getProperty(_uriKey);
  }

  static void setData(
    LinkedUnitContext unitContext,
    LinkedNode data,
    Directive node,
  ) {
    node.setProperty(_key, LazyDirective(unitContext, data, node));
    if (node is NamespaceDirective) {
      node.setProperty(_uriKey, data.namespaceDirective_selectedUri);
    }
  }

  static void setSelectedUri(UriBasedDirective node, String uriStr) {
    node.setProperty(_uriKey, uriStr);
  }
}

class LazyEnumConstantDeclaration {
  static const _key = 'lazyAst';

  final LinkedNode data;

  bool _hasDocumentationComment = false;

  LazyEnumConstantDeclaration(this.data);

  static LazyEnumConstantDeclaration get(EnumConstantDeclaration node) {
    return node.getProperty(_key);
  }

  static int getCodeLength(
    LinkedUnitContext context,
    EnumConstantDeclaration node,
  ) {
    var lazy = get(node);
    if (lazy != null) {
      return context.getInformativeData(lazy.data)?.codeLength ?? 0;
    }
    return node.length;
  }

  static int getCodeOffset(
    LinkedUnitContext context,
    EnumConstantDeclaration node,
  ) {
    var lazy = get(node);
    if (lazy != null) {
      return context.getInformativeData(lazy.data)?.codeOffset ?? 0;
    }
    return node.offset;
  }

  static void readDocumentationComment(
    LinkedUnitContext context,
    EnumConstantDeclaration node,
  ) {
    var lazy = get(node);
    if (lazy != null && !lazy._hasDocumentationComment) {
      node.documentationComment = context.createComment(lazy.data);
      lazy._hasDocumentationComment = true;
    }
  }

  static void setData(EnumConstantDeclaration node, LinkedNode data) {
    node.setProperty(_key, LazyEnumConstantDeclaration(data));
  }
}

class LazyEnumDeclaration {
  static const _key = 'lazyAst';

  final LinkedUnitContext unitContext;
  final LinkedNode data;
  final EnumDeclaration node;

  bool _hasDocumentationComment = false;
  bool _hasResolutionApplied = false;

  LazyEnumDeclaration(this.unitContext, this.data, this.node);

  void applyResolution() {
    if (_hasResolutionApplied) {
      return;
    }
    _hasResolutionApplied = true;

    unitContext.pushTypeParameterStack();

    var visitor = ApplyResolutionVisitor(unitContext, data.resolution);
    node.accept(visitor);

    unitContext.popTypeParameterStack();
  }

  static LazyEnumDeclaration get(EnumDeclaration node) {
    return node.getProperty(_key);
  }

  static int getCodeLength(
    LinkedUnitContext context,
    EnumDeclaration node,
  ) {
    var lazy = get(node);
    if (lazy != null) {
      return context.getInformativeData(lazy.data)?.codeLength ?? 0;
    }
    return node.length;
  }

  static int getCodeOffset(
    LinkedUnitContext context,
    EnumDeclaration node,
  ) {
    var lazy = get(node);
    if (lazy != null) {
      return context.getInformativeData(lazy.data)?.codeOffset ?? 0;
    }
    return node.offset;
  }

  static void readDocumentationComment(
    LinkedUnitContext context,
    EnumDeclaration node,
  ) {
    var lazy = get(node);
    if (lazy != null && !lazy._hasDocumentationComment) {
      node.documentationComment = context.createComment(lazy.data);
      lazy._hasDocumentationComment = true;
    }
  }

  static void setData(
    LinkedUnitContext unitContext,
    LinkedNode data,
    EnumDeclaration node,
  ) {
    node.setProperty(_key, LazyEnumDeclaration(unitContext, data, node));
  }
}

class LazyExtensionDeclaration {
  static const _key = 'lazyAst';

  final LinkedUnitContext unitContext;
  final LinkedNode data;
  final ExtensionDeclaration node;

  bool _hasDocumentationComment = false;
  bool _hasMembers = false;
  bool _hasResolutionApplied = false;

  /// The name for use in `Reference`. If the extension is named, the name
  /// of the extension. If the extension is unnamed, a synthetic name.
  String _refName;

  LazyExtensionDeclaration(this.unitContext, this.data, this.node) {
    node.setProperty(_key, this);
    if (data != null) {
      _refName = data.extensionDeclaration_refName;
    }
  }

  String get refName => _refName;

  void applyResolution() {
    if (_hasResolutionApplied) {
      return;
    }
    _hasResolutionApplied = true;

    var visitor = ApplyResolutionVisitor(unitContext, data.resolution);
    node.accept(visitor);
  }

  void put(LinkedNodeBuilder builder) {
    assert(_refName != null);
    builder.extensionDeclaration_refName = _refName;
  }

  void setRefName(String referenceName) {
    _refName = referenceName;
  }

  static LazyExtensionDeclaration get(ExtensionDeclaration node) {
    LazyExtensionDeclaration lazy = node.getProperty(_key);
    if (lazy == null) {
      return LazyExtensionDeclaration(null, null, node);
    }
    return lazy;
  }

  static int getCodeLength(
    LinkedUnitContext context,
    ExtensionDeclaration node,
  ) {
    var lazy = get(node);
    if (lazy?.data != null) {
      return context.getInformativeData(lazy.data)?.codeLength ?? 0;
    }
    return node.length;
  }

  static int getCodeOffset(
    LinkedUnitContext context,
    ExtensionDeclaration node,
  ) {
    var lazy = get(node);
    if (lazy?.data != null) {
      return context.getInformativeData(lazy.data)?.codeOffset ?? 0;
    }
    return node.offset;
  }

  static void readDocumentationComment(
    LinkedUnitContext context,
    ExtensionDeclaration node,
  ) {
    var lazy = get(node);
    if (lazy?.data != null && !lazy._hasDocumentationComment) {
      node.documentationComment = context.createComment(lazy.data);
      lazy._hasDocumentationComment = true;
    }
  }

  static void readMembers(
    AstBinaryReader reader,
    ExtensionDeclaration node,
  ) {
    var lazy = get(node);
    if (lazy?.data != null && !lazy._hasMembers) {
      var dataList = lazy.data.extensionDeclaration_members;
      for (var i = 0; i < dataList.length; ++i) {
        var data = dataList[i];
        node.members[i] = reader.readNode(data);
      }
      lazy._hasMembers = true;
    }
  }
}

class LazyFieldDeclaration {
  static const _key = 'lazyAst';

  final LinkedUnitContext unitContext;
  final LinkedNode data;
  final FieldDeclaration node;

  bool _hasDocumentationComment = false;
  bool _hasResolutionApplied = false;

  LazyFieldDeclaration(this.unitContext, this.data, this.node);

  void applyResolution() {
    if (_hasResolutionApplied) {
      return;
    }
    _hasResolutionApplied = true;

    unitContext.pushTypeParameterStack();

    var visitor = ApplyResolutionVisitor(unitContext, data.resolution);
    visitor.addParentTypeParameters(node);
    node.accept(visitor);

    unitContext.popTypeParameterStack();
  }

  static LazyFieldDeclaration get(FieldDeclaration node) {
    return node.getProperty(_key);
  }

  static void readDocumentationComment(
    LinkedUnitContext context,
    FieldDeclaration node,
  ) {
    var lazy = get(node);
    if (lazy != null && !lazy._hasDocumentationComment) {
      node.documentationComment = context.createComment(lazy.data);
      lazy._hasDocumentationComment = true;
    }
  }

  static void setData(
    LinkedUnitContext unitContext,
    LinkedNode data,
    FieldDeclaration node,
  ) {
    node.setProperty(_key, LazyFieldDeclaration(unitContext, data, node));
  }
}

class LazyFormalParameter {
  static const _key = 'lazyAst';

  final LinkedNode data;

  bool _hasTypeInferenceError = false;

  LazyFormalParameter(this.data);

  static LazyFormalParameter get(FormalParameter node) {
    return node.getProperty(_key);
  }

  static int getCodeLength(
    LinkedUnitContext context,
    FormalParameter node,
  ) {
    var lazy = get(node);
    if (lazy != null) {
      return context.getInformativeData(lazy.data)?.codeLength ?? 0;
    }
    return node.length;
  }

  static int getCodeOffset(
    LinkedUnitContext context,
    FormalParameter node,
  ) {
    var lazy = get(node);
    if (lazy != null) {
      return context.getInformativeData(lazy.data)?.codeOffset ?? 0;
    }
    return node.offset;
  }

  static String getDefaultValueCode(
    LinkedUnitContext context,
    DefaultFormalParameter node,
  ) {
    var lazy = get(node);
    if (lazy != null) {
      if (lazy.data.defaultFormalParameter_defaultValue == null) {
        return null;
      }
      return context.getDefaultValueCodeData(lazy.data);
    } else {
      return node.defaultValue?.toSource();
    }
  }

  static TopLevelInferenceError getTypeInferenceError(FormalParameter node) {
    var lazy = get(node);
    if (lazy != null && !lazy._hasTypeInferenceError) {
      var error = lazy.data.topLevelTypeInferenceError;
      LazyAst.setTypeInferenceError(node, error);
      lazy._hasTypeInferenceError = true;
    }
    return LazyAst.getTypeInferenceError(node);
  }

  static bool hasDefaultValue(DefaultFormalParameter node) {
    var lazy = get(node);
    if (lazy != null) {
      return AstBinaryFlags.hasInitializer(lazy.data.flags);
    } else {
      return node.defaultValue != null;
    }
  }

  static void setData(FormalParameter node, LinkedNode data) {
    node.setProperty(_key, LazyFormalParameter(data));
  }
}

class LazyFunctionDeclaration {
  static const _key = 'lazyAst';

  final LinkedUnitContext unitContext;
  final LinkedNode data;
  final FunctionDeclaration node;

  bool _hasDocumentationComment = false;
  bool _hasResolutionApplied = false;

  LazyFunctionDeclaration(this.unitContext, this.data, this.node);

  void applyResolution() {
    if (_hasResolutionApplied) {
      return;
    }
    _hasResolutionApplied = true;

    unitContext.pushTypeParameterStack();

    var visitor = ApplyResolutionVisitor(unitContext, data.resolution);
    node.accept(visitor);

    unitContext.popTypeParameterStack();
  }

  static LazyFunctionDeclaration get(FunctionDeclaration node) {
    return node.getProperty(_key);
  }

  static int getCodeLength(
    LinkedUnitContext context,
    FunctionDeclaration node,
  ) {
    var lazy = get(node);
    if (lazy != null) {
      return context.getInformativeData(lazy.data)?.codeLength ?? 0;
    }
    return node.length;
  }

  static int getCodeOffset(
    LinkedUnitContext context,
    FunctionDeclaration node,
  ) {
    var lazy = get(node);
    if (lazy != null) {
      return context.getInformativeData(lazy.data)?.codeOffset ?? 0;
    }
    return node.offset;
  }

  static void readDocumentationComment(
    LinkedUnitContext context,
    FunctionDeclaration node,
  ) {
    var lazy = get(node);
    if (lazy != null && !lazy._hasDocumentationComment) {
      node.documentationComment = context.createComment(lazy.data);
      lazy._hasDocumentationComment = true;
    }
  }

  static void setData(
    LinkedUnitContext unitContext,
    LinkedNode data,
    FunctionDeclaration node,
  ) {
    node.setProperty(_key, LazyFunctionDeclaration(unitContext, data, node));
  }
}

class LazyFunctionExpression {
  static const _key = 'lazyAst';

  final LinkedNode data;

  bool _hasBody = false;

  LazyFunctionExpression(this.data);

  static LazyFunctionExpression get(FunctionExpression node) {
    return node.getProperty(_key);
  }

  static bool isAsynchronous(FunctionExpression node) {
    var lazy = get(node);
    if (lazy != null) {
      return AstBinaryFlags.isAsync(lazy.data.flags);
    } else {
      return node.body.isAsynchronous;
    }
  }

  static bool isGenerator(FunctionExpression node) {
    var lazy = get(node);
    if (lazy != null) {
      return AstBinaryFlags.isGenerator(lazy.data.flags);
    } else {
      return node.body.isGenerator;
    }
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

  static void setData(FunctionExpression node, LinkedNode data) {
    node.setProperty(_key, LazyFunctionExpression(data));
  }
}

class LazyFunctionTypeAlias {
  static const _key = 'lazyAst';
  static const _hasSelfReferenceKey = 'lazyAst_hasSelfReferenceKey';

  final LinkedUnitContext unitContext;
  final LinkedNode data;
  final FunctionTypeAlias node;

  bool _hasDocumentationComment = false;
  bool _hasResolutionApplied = false;

  LazyFunctionTypeAlias(this.unitContext, this.data, this.node);

  void applyResolution() {
    if (_hasResolutionApplied) {
      return;
    }

    var visitor = ApplyResolutionVisitor(unitContext, data.resolution);
    node.accept(visitor);

    _hasResolutionApplied = true;
  }

  static LazyFunctionTypeAlias get(FunctionTypeAlias node) {
    return node.getProperty(_key);
  }

  static int getCodeLength(
    LinkedUnitContext context,
    FunctionTypeAlias node,
  ) {
    var lazy = get(node);
    if (lazy != null) {
      return context.getInformativeData(lazy.data)?.codeLength ?? 0;
    }
    return node.length;
  }

  static int getCodeOffset(
    LinkedUnitContext context,
    FunctionTypeAlias node,
  ) {
    var lazy = get(node);
    if (lazy != null) {
      return context.getInformativeData(lazy.data)?.codeOffset ?? 0;
    }
    return node.offset;
  }

  static bool getHasSelfReference(FunctionTypeAlias node) {
    return node.getProperty(_hasSelfReferenceKey);
  }

  static void readDocumentationComment(
    LinkedUnitContext context,
    FunctionTypeAlias node,
  ) {
    var lazy = get(node);
    if (lazy != null && !lazy._hasDocumentationComment) {
      node.documentationComment = context.createComment(lazy.data);
      lazy._hasDocumentationComment = true;
    }
  }

  static void setData(
    LinkedUnitContext unitContext,
    LinkedNode data,
    FunctionTypeAlias node,
  ) {
    node.setProperty(_key, LazyFunctionTypeAlias(unitContext, data, node));
    LazyAst.setSimplyBounded(node, data.simplyBoundable_isSimplyBounded);
  }

  static void setHasSelfReference(FunctionTypeAlias node, bool value) {
    node.setProperty(_hasSelfReferenceKey, value);
  }
}

class LazyGenericTypeAlias {
  static const _key = 'lazyAst';
  static const _hasSelfReferenceKey = 'lazyAst_hasSelfReferenceKey';

  final LinkedUnitContext unitContext;
  final LinkedNode data;
  final GenericTypeAlias node;

  bool _hasDocumentationComment = false;
  bool _hasResolutionApplied = false;

  LazyGenericTypeAlias(this.unitContext, this.data, this.node);

  void applyResolution() {
    if (_hasResolutionApplied) {
      return;
    }

    var visitor = ApplyResolutionVisitor(unitContext, data.resolution);
    node.accept(visitor);

    _hasResolutionApplied = true;
  }

  static LazyGenericTypeAlias get(GenericTypeAlias node) {
    return node.getProperty(_key);
  }

  static int getCodeLength(
    LinkedUnitContext context,
    GenericTypeAlias node,
  ) {
    var lazy = get(node);
    if (lazy != null) {
      return context.getInformativeData(lazy.data)?.codeLength ?? 0;
    }
    return node.length;
  }

  static int getCodeOffset(
    LinkedUnitContext context,
    GenericTypeAlias node,
  ) {
    var lazy = get(node);
    if (lazy != null) {
      return context.getInformativeData(lazy.data)?.codeOffset ?? 0;
    }
    return node.offset;
  }

  static bool getHasSelfReference(GenericTypeAlias node) {
    return node.getProperty(_hasSelfReferenceKey);
  }

  static void readDocumentationComment(
    LinkedUnitContext context,
    GenericTypeAlias node,
  ) {
    var lazy = get(node);
    if (lazy != null && !lazy._hasDocumentationComment) {
      node.documentationComment = context.createComment(lazy.data);
      lazy._hasDocumentationComment = true;
    }
  }

  static void setData(
    LinkedUnitContext unitContext,
    LinkedNode data,
    GenericTypeAlias node,
  ) {
    node.setProperty(_key, LazyGenericTypeAlias(unitContext, data, node));
    LazyAst.setSimplyBounded(node, data.simplyBoundable_isSimplyBounded);
  }

  static void setHasSelfReference(GenericTypeAlias node, bool value) {
    node.setProperty(_hasSelfReferenceKey, value);
  }
}

class LazyMethodDeclaration {
  static const _key = 'lazyAst';

  final LinkedUnitContext unitContext;
  final LinkedNode data;
  final MethodDeclaration node;

  bool _hasDocumentationComment = false;
  bool _hasTypeInferenceError = false;
  bool _hasResolutionApplied = false;

  LazyMethodDeclaration(this.unitContext, this.data, this.node);

  void applyResolution() {
    if (_hasResolutionApplied) {
      return;
    }
    _hasResolutionApplied = true;

    unitContext.pushTypeParameterStack();

    var visitor = ApplyResolutionVisitor(unitContext, data.resolution);
    visitor.addParentTypeParameters(node);
    node.accept(visitor);

    unitContext.popTypeParameterStack();
  }

  static LazyMethodDeclaration get(MethodDeclaration node) {
    return node.getProperty(_key);
  }

  static int getCodeLength(
    LinkedUnitContext context,
    MethodDeclaration node,
  ) {
    var lazy = get(node);
    if (lazy != null) {
      return context.getInformativeData(lazy.data)?.codeLength ?? 0;
    }
    return node.length;
  }

  static int getCodeOffset(
    LinkedUnitContext context,
    MethodDeclaration node,
  ) {
    var lazy = get(node);
    if (lazy != null) {
      return context.getInformativeData(lazy.data)?.codeOffset ?? 0;
    }
    return node.offset;
  }

  static TopLevelInferenceError getTypeInferenceError(MethodDeclaration node) {
    var lazy = get(node);
    if (lazy != null && !lazy._hasTypeInferenceError) {
      var error = lazy.data.topLevelTypeInferenceError;
      LazyAst.setTypeInferenceError(node, error);
      lazy._hasTypeInferenceError = true;
    }
    return LazyAst.getTypeInferenceError(node);
  }

  static bool isAbstract(MethodDeclaration node) {
    var lazy = get(node);
    if (lazy != null) {
      return AstBinaryFlags.isAbstract(lazy.data.flags);
    } else {
      return node.isAbstract;
    }
  }

  static bool isAsynchronous(MethodDeclaration node) {
    var lazy = get(node);
    if (lazy != null) {
      return AstBinaryFlags.isAsync(lazy.data.flags);
    } else {
      return node.body.isAsynchronous;
    }
  }

  static bool isGenerator(MethodDeclaration node) {
    var lazy = get(node);
    if (lazy != null) {
      return AstBinaryFlags.isGenerator(lazy.data.flags);
    } else {
      return node.body.isGenerator;
    }
  }

  static void readDocumentationComment(
    LinkedUnitContext context,
    MethodDeclaration node,
  ) {
    var lazy = get(node);
    if (lazy != null && !lazy._hasDocumentationComment) {
      node.documentationComment = context.createComment(lazy.data);
      lazy._hasDocumentationComment = true;
    }
  }

  static void setData(
    LinkedUnitContext unitContext,
    LinkedNode data,
    MethodDeclaration node,
  ) {
    node.setProperty(_key, LazyMethodDeclaration(unitContext, data, node));
  }
}

class LazyMixinDeclaration {
  static const _key = 'lazyAst';

  final LinkedUnitContext unitContext;
  final LinkedNode data;
  final MixinDeclaration node;

  bool _hasDocumentationComment = false;
  bool _hasMembers = false;
  bool _hasResolutionApplied = false;

  List<String> _superInvokedNames;

  LazyMixinDeclaration(this.unitContext, this.data, this.node) {
    node.setProperty(_key, this);
    if (data != null) {
      LazyAst.setSimplyBounded(node, data.simplyBoundable_isSimplyBounded);
    }
  }

  void applyResolution() {
    if (_hasResolutionApplied) {
      return;
    }
    _hasResolutionApplied = true;

    unitContext.pushTypeParameterStack();

    var visitor = ApplyResolutionVisitor(unitContext, data.resolution);
    node.accept(visitor);

    unitContext.popTypeParameterStack();
  }

  List<String> getSuperInvokedNames() {
    return _superInvokedNames ??= data.mixinDeclaration_superInvokedNames;
  }

  void put(LinkedNodeBuilder builder) {
    builder.mixinDeclaration_superInvokedNames = _superInvokedNames ?? [];
  }

  void setSuperInvokedNames(List<String> value) {
    _superInvokedNames = value;
  }

  static LazyMixinDeclaration get(MixinDeclaration node) {
    LazyMixinDeclaration lazy = node.getProperty(_key);
    if (lazy == null) {
      return LazyMixinDeclaration(null, null, node);
    }
    return lazy;
  }

  static int getCodeLength(
    LinkedUnitContext context,
    MixinDeclaration node,
  ) {
    var lazy = get(node);
    if (lazy != null) {
      return context.getInformativeData(lazy.data)?.codeLength ?? 0;
    }
    return node.length;
  }

  static int getCodeOffset(
    LinkedUnitContext context,
    MixinDeclaration node,
  ) {
    var lazy = get(node);
    if (lazy != null) {
      return context.getInformativeData(lazy.data)?.codeOffset ?? 0;
    }
    return node.offset;
  }

  static void readDocumentationComment(
    LinkedUnitContext context,
    MixinDeclaration node,
  ) {
    var lazy = get(node);
    if (lazy.data != null && !lazy._hasDocumentationComment) {
      node.documentationComment = context.createComment(lazy.data);
      lazy._hasDocumentationComment = true;
    }
  }

  static void readMembers(
    AstBinaryReader reader,
    MixinDeclaration node,
  ) {
    var lazy = get(node);
    if (lazy.data != null && !lazy._hasMembers) {
      var dataList = lazy.data.classOrMixinDeclaration_members;
      for (var i = 0; i < dataList.length; ++i) {
        var data = dataList[i];
        node.members[i] = reader.readNode(data);
      }
      lazy._hasMembers = true;
    }
  }
}

class LazyTopLevelVariableDeclaration {
  static const _key = 'lazyAst';

  final LinkedUnitContext unitContext;
  final LinkedNode data;
  final TopLevelVariableDeclaration node;

  bool _hasDocumentationComment = false;
  bool _hasResolutionApplied = false;

  LazyTopLevelVariableDeclaration(this.unitContext, this.data, this.node);

  void applyResolution() {
    if (_hasResolutionApplied) {
      return;
    }
    _hasResolutionApplied = true;

    unitContext.pushTypeParameterStack();

    var visitor = ApplyResolutionVisitor(unitContext, data.resolution);
    node.accept(visitor);

    unitContext.popTypeParameterStack();
  }

  static LazyTopLevelVariableDeclaration get(TopLevelVariableDeclaration node) {
    return node.getProperty(_key);
  }

  static void readDocumentationComment(
    LinkedUnitContext context,
    TopLevelVariableDeclaration node,
  ) {
    var lazy = get(node);
    if (lazy != null && !lazy._hasDocumentationComment) {
      node.documentationComment = context.createComment(lazy.data);
      lazy._hasDocumentationComment = true;
    }
  }

  static void setData(
    LinkedUnitContext unitContext,
    LinkedNode data,
    TopLevelVariableDeclaration node,
  ) {
    node.setProperty(
      _key,
      LazyTopLevelVariableDeclaration(unitContext, data, node),
    );
  }
}

/// TODO(scheglov) remove completely?
class LazyTypeParameter {
  static const _key = 'lazyAst';

  final LinkedNode data;

  LazyTypeParameter(this.data);

  static LazyTypeParameter get(TypeParameter node) {
    return node.getProperty(_key);
  }

  static int getCodeLength(
    LinkedUnitContext context,
    TypeParameter node,
  ) {
    var lazy = get(node);
    if (lazy != null) {
      return context.getInformativeData(lazy.data)?.codeLength ?? 0;
    }
    return node.length;
  }

  static int getCodeOffset(
    LinkedUnitContext context,
    TypeParameter node,
  ) {
    var lazy = get(node);
    if (lazy != null) {
      return context.getInformativeData(lazy.data)?.codeOffset ?? 0;
    }
    return node.offset;
  }

  static void setData(TypeParameter node, LinkedNode data) {
    node.setProperty(_key, LazyTypeParameter(data));
  }
}

/// TODO(scheglov) remove completely?
class LazyVariableDeclaration {
  static const _key = 'lazyAst';

  final LinkedNode data;

  bool _hasTypeInferenceError = false;

  LazyVariableDeclaration(this.data);

  static LazyVariableDeclaration get(VariableDeclaration node) {
    return node.getProperty(_key);
  }

  static int getCodeLength(
    LinkedUnitContext context,
    VariableDeclaration node,
  ) {
    var lazy = get(node);
    if (lazy != null) {
      return context.getInformativeData(lazy.data)?.codeLength ?? 0;
    }
    VariableDeclarationList parent = node.parent;
    if (parent.variables[0] == node) {
      return node.end - parent.offset;
    } else {
      return node.end - node.offset;
    }
  }

  static int getCodeOffset(
    LinkedUnitContext context,
    VariableDeclaration node,
  ) {
    var lazy = get(node);
    if (lazy != null) {
      return context.getInformativeData(lazy.data)?.codeOffset ?? 0;
    }
    VariableDeclarationList parent = node.parent;
    if (parent.variables[0] == node) {
      return parent.offset;
    } else {
      return node.offset;
    }
  }

  static TopLevelInferenceError getTypeInferenceError(
      VariableDeclaration node) {
    var lazy = get(node);
    if (lazy != null && !lazy._hasTypeInferenceError) {
      var error = lazy.data.topLevelTypeInferenceError;
      LazyAst.setTypeInferenceError(node, error);
      lazy._hasTypeInferenceError = true;
    }
    return LazyAst.getTypeInferenceError(node);
  }

  static bool hasInitializer(VariableDeclaration node) {
    var lazy = get(node);
    if (lazy != null) {
      return AstBinaryFlags.hasInitializer(lazy.data.flags);
    } else {
      return node.initializer != null;
    }
  }

  static void setData(VariableDeclaration node, LinkedNode data) {
    node.setProperty(_key, LazyVariableDeclaration(data));
  }
}

class LazyVariableDeclarationList {
  static const _key = 'lazyAst';

  final LinkedNode data;

  bool _hasTypeNode = false;

  LazyVariableDeclarationList(this.data);

  static LazyVariableDeclarationList get(VariableDeclarationList node) {
    return node.getProperty(_key);
  }

  static void readTypeNode(
    AstBinaryReader reader,
    VariableDeclarationList node,
  ) {
    var lazy = get(node);
    if (lazy != null && !lazy._hasTypeNode) {
      node.type = reader.readNode(
        lazy.data.variableDeclarationList_type,
      );
      lazy._hasTypeNode = true;
    }
  }

  static void setData(VariableDeclarationList node, LinkedNode data) {
    node.setProperty(_key, LazyVariableDeclarationList(data));
  }
}
