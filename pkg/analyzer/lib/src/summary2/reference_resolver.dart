// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/scope_context.dart';
import 'package:analyzer/src/summary2/function_type_builder.dart';
import 'package:analyzer/src/summary2/link.dart';
import 'package:analyzer/src/summary2/named_type_builder.dart';
import 'package:analyzer/src/summary2/record_type_builder.dart';
import 'package:analyzer/src/summary2/types_builder.dart';
import 'package:analyzer/src/utilities/extensions/object.dart';

/// Recursive visitor of LinkedNodes that resolves explicit type annotations
/// in outlines.  This includes resolving element references in identifiers
/// in type annotation, and setting LinkedNodeTypes for corresponding type
/// annotation nodes.
///
/// Declarations that have type annotations, e.g. return types of methods, get
/// the corresponding type set (so, if there is an explicit type annotation,
/// the type is set, otherwise we keep it empty, so we will attempt to infer
/// it later).
class ReferenceResolver extends ThrowingAstVisitor<void> {
  /// The library fragment in which the AST nodes are being resolved.
  final LibraryFragmentImpl libraryFragment;

  final ScopeContext _scopeContext;
  final Linker linker;
  final TypeSystemImpl typeSystem;
  final NodesToBuildType nodesToBuildType;

  ReferenceResolver(
    this.linker,
    this.nodesToBuildType,
    this.typeSystem,
    Scope scope, {
    required this.libraryFragment,
  }) : _scopeContext = ScopeContext(
         libraryFragment: libraryFragment,
         nameScope: scope,
       );

  Scope get nameScope => _scopeContext.nameScope;

  @override
  void visitAnnotation(covariant AnnotationImpl node) {
    if (node.arguments != null) {
      var identifier = node.name;
      if (identifier is PrefixedIdentifierImpl) {
        var prefixNode = identifier.prefix;
        var prefixElement = nameScope.lookup(prefixNode.name).getter;
        prefixNode.element = prefixElement;

        if (prefixElement is PrefixElement) {
          var name = identifier.identifier.name;
          var element = prefixElement.scope.lookup(name).getter;
          identifier.identifier.element = element;
        }
      } else if (identifier is SimpleIdentifierImpl) {
        var element = nameScope.lookup(identifier.name).getter;
        identifier.element = element;
        return;
      }
    }
  }

  @override
  void visitBlockClassBody(BlockClassBody node) {
    node.members.accept(this);
  }

  @override
  void visitBlockFunctionBody(BlockFunctionBody node) {}

  @override
  void visitClassDeclaration(covariant ClassDeclarationImpl node) {
    _scopeContext.visitClassDeclaration(node, visitor: this);
    nodesToBuildType.addDeclaration(node);
  }

  @override
  void visitClassTypeAlias(covariant ClassTypeAliasImpl node) {
    _scopeContext.visitClassTypeAlias(node, visitor: this);
    nodesToBuildType.addDeclaration(node);
  }

  @override
  void visitComment(Comment node) {}

  @override
  void visitCompilationUnit(CompilationUnit node) {
    node.declarations.accept(this);
  }

  @override
  void visitConstructorDeclaration(covariant ConstructorDeclarationImpl node) {
    node.enclosingBodyScope = nameScope;
    node.metadata.accept(this);
    node.parameters.accept(this);
  }

  @override
  void visitDefaultFormalParameter(covariant DefaultFormalParameterImpl node) {
    node.scope = nameScope;
    node.parameter.accept(this);
  }

  @override
  void visitEmptyClassBody(EmptyClassBody node) {}

  @override
  void visitEmptyFunctionBody(EmptyFunctionBody node) {}

  @override
  void visitEnumBody(EnumBody node) {
    node.constants.accept(this);
    node.members.accept(this);
  }

  @override
  void visitEnumConstantDeclaration(EnumConstantDeclaration node) {}

  @override
  void visitEnumDeclaration(covariant EnumDeclarationImpl node) {
    var fragment = node.declaredFragment!;

    _scopeContext.visitEnumDeclaration(node, visitor: this);
    nodesToBuildType.addDeclaration(node);

    for (var field in fragment.fields) {
      if (field.isEnumConstant || field.isOriginEnumValues) {
        var fieldNode = linker.elementNodes[field];
        fieldNode as VariableDeclarationImpl;
        fieldNode.initializerScope = node.bodyScope;
      }
    }
  }

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {}

  @override
  void visitExtendsClause(ExtendsClause node) {
    node.superclass.accept(this);
  }

  @override
  void visitExtensionDeclaration(covariant ExtensionDeclarationImpl node) {
    _scopeContext.visitExtensionDeclaration(node, visitor: this);
    nodesToBuildType.addDeclaration(node);
  }

  @override
  void visitExtensionOnClause(ExtensionOnClause node) {
    node.extendedType.accept(this);
  }

  @override
  void visitExtensionTypeDeclaration(
    covariant ExtensionTypeDeclarationImpl node,
  ) {
    _scopeContext.visitExtensionTypeDeclaration(node, visitor: this);
    nodesToBuildType.addDeclaration(node);
  }

  @override
  void visitFieldDeclaration(covariant FieldDeclarationImpl node) {
    node.metadata.accept(this);

    var fields = node.fields;
    fields.type?.accept(this);
    nodesToBuildType.addDeclaration(fields);

    void bindVariables() {
      for (var fieldNode in fields.variables) {
        fieldNode.initializerScope = nameScope;
      }
    }

    if (!node.isStatic && fields.lateKeyword == null) {
      var primaryConstructor = node.parent?.parent
          .tryCast<Declaration>()
          ?.declaredFragment!
          .element
          .tryCast<InterfaceElementImpl>()
          ?.primaryConstructor;
      if (primaryConstructor != null) {
        _scopeContext.withConstructorInitializerScope(
          primaryConstructor,
          bindVariables,
        );
        return;
      }
    }

    bindVariables();
  }

  @override
  void visitFieldFormalParameter(covariant FieldFormalParameterImpl node) {
    _scopeContext.visitFieldFormalParameter(node, visitor: this);
    nodesToBuildType.addDeclaration(node);
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    node.parameters.accept(this);
  }

  @override
  void visitFunctionDeclaration(covariant FunctionDeclarationImpl node) {
    _scopeContext.visitFunctionDeclaration(node, visitor: this);
    nodesToBuildType.addDeclaration(node);
  }

  @override
  void visitFunctionTypeAlias(covariant FunctionTypeAliasImpl node) {
    _scopeContext.visitFunctionTypeAlias(node, visitor: this);
    nodesToBuildType.addDeclaration(node);
  }

  @override
  void visitFunctionTypedFormalParameter(
    covariant FunctionTypedFormalParameterImpl node,
  ) {
    _scopeContext.visitFunctionTypedFormalParameter(node, visitor: this);
    nodesToBuildType.addDeclaration(node);
  }

  @override
  void visitGenericFunctionType(covariant GenericFunctionTypeImpl node) {
    _scopeContext.visitGenericFunctionType(node, visitor: this);

    var nullabilitySuffix = _getNullabilitySuffix(node.question != null);
    var builder = FunctionTypeBuilder.of(node, nullabilitySuffix);
    node.type = builder;
    nodesToBuildType.addDeclaration(node);
    nodesToBuildType.addTypeBuilder(builder);
  }

  @override
  void visitGenericTypeAlias(covariant GenericTypeAliasImpl node) {
    _scopeContext.visitGenericTypeAlias(node, visitor: this);
    nodesToBuildType.addDeclaration(node);
  }

  @override
  void visitImplementsClause(ImplementsClause node) {
    node.interfaces.accept(this);
  }

  @override
  void visitMethodDeclaration(covariant MethodDeclarationImpl node) {
    _scopeContext.visitMethodDeclaration(node, visitor: this);
    nodesToBuildType.addDeclaration(node);
  }

  @override
  void visitMixinDeclaration(covariant MixinDeclarationImpl node) {
    _scopeContext.visitMixinDeclaration(node, visitor: this);
    nodesToBuildType.addDeclaration(node);
  }

  @override
  void visitMixinOnClause(MixinOnClause node) {
    node.superclassConstraints.accept(this);
  }

  @override
  void visitNamedType(covariant NamedTypeImpl node) {
    Element? element;
    var importPrefix = node.importPrefix;
    if (importPrefix != null) {
      var prefixToken = importPrefix.name;
      var prefixName = prefixToken.lexeme;
      var prefixElement = nameScope.lookup(prefixName).getter;
      importPrefix.element = prefixElement;

      if (prefixElement is PrefixElement) {
        var name = node.name.lexeme;
        element = prefixElement.scope.lookup(name).getter;
      }
    } else {
      var name = node.name.lexeme;

      if (name == 'void') {
        node.type = VoidTypeImpl.instance;
        return;
      }

      element = nameScope.lookup(name).getter;
    }
    node.element = element;

    node.typeArguments?.accept(this);

    var nullabilitySuffix = _getNullabilitySuffix(node.question != null);
    if (element == null) {
      node.type = InvalidTypeImpl.instance;
    } else if (element is TypeParameterElementImpl) {
      node.type = TypeParameterTypeImpl(
        element: element,
        nullabilitySuffix: nullabilitySuffix,
      );
    } else {
      var builder = NamedTypeBuilder.of(
        linker: linker,
        typeSystem: typeSystem,
        node: node,
        element: element,
        nullabilitySuffix: nullabilitySuffix,
      );
      node.type = builder;
      nodesToBuildType.addTypeBuilder(builder);
    }
  }

  @override
  void visitNameWithTypeParameters(NameWithTypeParameters node) {
    node.typeParameters?.accept(this);
  }

  @override
  void visitNativeClause(NativeClause node) {}

  @override
  void visitNativeFunctionBody(NativeFunctionBody node) {}

  @override
  void visitPrimaryConstructorBody(covariant PrimaryConstructorBodyImpl node) {
    node.enclosingBodyScope = nameScope;
  }

  @override
  void visitPrimaryConstructorDeclaration(
    covariant PrimaryConstructorDeclarationImpl node,
  ) {
    node.typeParameters?.accept(this);
    node.formalParameters.accept(this);
  }

  @override
  void visitRecordTypeAnnotation(covariant RecordTypeAnnotationImpl node) {
    node.positionalFields.accept(this);
    node.namedFields?.accept(this);

    var builder = RecordTypeBuilder.of(typeSystem, node);
    node.type = builder;
    nodesToBuildType.addTypeBuilder(builder);
  }

  @override
  void visitRecordTypeAnnotationNamedField(
    RecordTypeAnnotationNamedField node,
  ) {
    node.type.accept(this);
  }

  @override
  void visitRecordTypeAnnotationNamedFields(
    RecordTypeAnnotationNamedFields node,
  ) {
    node.fields.accept(this);
  }

  @override
  void visitRecordTypeAnnotationPositionalField(
    RecordTypeAnnotationPositionalField node,
  ) {
    node.type.accept(this);
  }

  @override
  void visitSimpleFormalParameter(SimpleFormalParameter node) {
    node.type?.accept(this);
    nodesToBuildType.addDeclaration(node);
  }

  @override
  void visitSuperFormalParameter(covariant SuperFormalParameterImpl node) {
    _scopeContext.visitSuperFormalParameter(node, visitor: this);
    nodesToBuildType.addDeclaration(node);
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    node.metadata.accept(this);
    node.variables.accept(this);
  }

  @override
  void visitTypeArgumentList(TypeArgumentList node) {
    node.arguments.accept(this);
  }

  @override
  void visitTypeParameter(covariant TypeParameterImpl node) {
    var bound = node.bound;
    if (bound != null) {
      bound.accept(this);
      var fragment = node.declaredFragment!;
      if (fragment.previousFragment == null) {
        fragment.element.bound = bound.type;
      }
      nodesToBuildType.addDeclaration(node);
    }
  }

  @override
  void visitTypeParameterList(TypeParameterList node) {
    node.typeParameters.accept(this);
  }

  @override
  void visitVariableDeclarationList(
    covariant VariableDeclarationListImpl node,
  ) {
    node.type?.accept(this);
    nodesToBuildType.addDeclaration(node);

    for (var variable in node.variables) {
      variable.initializerScope = nameScope;
    }
  }

  @override
  void visitWithClause(WithClause node) {
    node.mixinTypes.accept(this);
  }

  NullabilitySuffix _getNullabilitySuffix(bool hasQuestion) {
    if (hasQuestion) {
      return NullabilitySuffix.question;
    } else {
      return NullabilitySuffix.none;
    }
  }
}
