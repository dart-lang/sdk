// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/scope.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/scope_context.dart';
import 'package:analyzer/src/summary2/function_type_builder.dart';
import 'package:analyzer/src/summary2/link.dart';
import 'package:analyzer/src/summary2/linking_node_scope.dart';
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
    var fragment = node.declaredFragment!;
    var element = fragment.element;

    withTypeParameterScope(element.typeParameters, () {
      node.metadata.accept(this);
      node.namePart.typeParameters?.accept(this);
      node.extendsClause?.accept(this);
      node.withClause?.accept(this);
      node.implementsClause?.accept(this);

      withInstanceScope(element, () {
        LinkingNodeContext(node, nameScope);

        node.namePart
            .tryCast<PrimaryConstructorDeclaration>()
            ?.formalParameters
            .accept(this);
        node.body.accept(this);
        nodesToBuildType.addDeclaration(node);
      });
    });
  }

  @override
  void visitClassTypeAlias(covariant ClassTypeAliasImpl node) {
    var fragment = node.declaredFragment!;
    var element = fragment.element;

    withTypeParameterScope(element.typeParameters, () {
      LinkingNodeContext(node, nameScope);

      node.metadata.accept(this);
      node.typeParameters?.accept(this);
      node.superclass.accept(this);
      node.withClause.accept(this);
      node.implementsClause?.accept(this);
      nodesToBuildType.addDeclaration(node);
    });
  }

  @override
  void visitComment(Comment node) {}

  @override
  void visitCompilationUnit(CompilationUnit node) {
    LinkingNodeContext(node, nameScope);
    node.declarations.accept(this);
  }

  @override
  void visitConstructorDeclaration(covariant ConstructorDeclarationImpl node) {
    var fragment = node.declaredFragment!;
    var element = fragment.element;

    withTypeParameterScope(element.typeParameters, () {
      LinkingNodeContext(node, nameScope);

      node.metadata.accept(this);
      node.parameters.accept(this);
    });
  }

  @override
  void visitDefaultFormalParameter(DefaultFormalParameter node) {
    LinkingNodeContext(node, nameScope);
    node.parameter.accept(this);
  }

  @override
  void visitEmptyClassBody(EmptyClassBody node) {}

  @override
  void visitEnumDeclaration(covariant EnumDeclarationImpl node) {
    var fragment = node.declaredFragment!;
    var element = fragment.element;

    withTypeParameterScope(element.typeParameters, () {
      node.metadata.accept(this);
      node.namePart.typeParameters?.accept(this);
      node.implementsClause?.accept(this);
      node.withClause?.accept(this);

      withInstanceScope(element, () {
        LinkingNodeContext(node, nameScope);

        node.namePart
            .tryCast<PrimaryConstructorDeclaration>()
            ?.formalParameters
            .accept(this);
        node.body.members.accept(this);
        nodesToBuildType.addDeclaration(node);

        for (var field in fragment.fields) {
          var isExplicitField =
              field.isOriginDeclaration && !field.isEnumConstant;
          if (!isExplicitField) {
            var node = linker.elementNodes[field];
            if (node != null) {
              LinkingNodeContext(node, nameScope);
            }
          }
        }
      });
    });
  }

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {}

  @override
  void visitExtendsClause(ExtendsClause node) {
    node.superclass.accept(this);
  }

  @override
  void visitExtensionDeclaration(covariant ExtensionDeclarationImpl node) {
    var fragment = node.declaredFragment!;
    var element = fragment.element;

    withTypeParameterScope(element.typeParameters, () {
      node.metadata.accept(this);
      node.typeParameters?.accept(this);
      node.onClause?.accept(this);

      withScope(ExtensionScope(nameScope, element), () {
        LinkingNodeContext(node, nameScope);

        node.body.members.accept(this);
        nodesToBuildType.addDeclaration(node);
      });
    });
  }

  @override
  void visitExtensionOnClause(ExtensionOnClause node) {
    node.extendedType.accept(this);
  }

  @override
  void visitExtensionTypeDeclaration(
    covariant ExtensionTypeDeclarationImpl node,
  ) {
    var fragment = node.declaredFragment!;
    var element = fragment.element;

    withTypeParameterScope(element.typeParameters, () {
      node.metadata.accept(this);
      node.primaryConstructor.typeParameters?.accept(this);
      node.implementsClause?.accept(this);

      withInstanceScope(element, () {
        LinkingNodeContext(node, nameScope);

        node.primaryConstructor.formalParameters.accept(this);
        node.body.accept(this);
        nodesToBuildType.addDeclaration(node);
      });
    });
  }

  @override
  void visitFieldDeclaration(covariant FieldDeclarationImpl node) {
    node.metadata.accept(this);

    var fields = node.fields;
    fields.type?.accept(this);
    nodesToBuildType.addDeclaration(fields);

    Scope variableScope = nameScope;
    if (!node.isStatic && fields.lateKeyword == null) {
      var primaryConstructor = node.parent?.parent
          .tryCast<Declaration>()
          ?.declaredFragment!
          .element
          .tryCast<InterfaceElementImpl>()
          ?.primaryConstructor;
      if (primaryConstructor != null) {
        variableScope = ConstructorInitializerScope(
          nameScope,
          primaryConstructor,
        );
      }
    }

    for (var variable in fields.variables) {
      var fragment = variable.declaredFragment!;
      var variableNode = linker.elementNodes[fragment]!;
      LinkingNodeContext(variableNode, variableScope);
    }
  }

  @override
  void visitFieldFormalParameter(covariant FieldFormalParameterImpl node) {
    var fragment = node.declaredFragment!;
    var element = fragment.element;

    withTypeParameterScope(element.typeParameters, () {
      node.type?.accept(this);
      node.typeParameters?.accept(this);
      node.parameters?.accept(this);
      nodesToBuildType.addDeclaration(node);
    });
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    node.parameters.accept(this);
  }

  @override
  void visitFunctionDeclaration(covariant FunctionDeclarationImpl node) {
    var fragment = node.declaredFragment!;
    var element = fragment.element;

    withTypeParameterScope(element.typeParameters, () {
      LinkingNodeContext(node, nameScope);

      node.metadata.accept(this);
      node.returnType?.accept(this);
      node.functionExpression.accept(this);
      nodesToBuildType.addDeclaration(node);
    });
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    node.typeParameters?.accept(this);
    node.parameters?.accept(this);
  }

  @override
  void visitFunctionTypeAlias(covariant FunctionTypeAliasImpl node) {
    var fragment = node.declaredFragment!;
    var element = fragment.element;

    withTypeParameterScope(element.typeParameters, () {
      node.returnType?.accept(this);
      node.typeParameters?.accept(this);
      node.parameters.accept(this);

      nodesToBuildType.addDeclaration(node);
    });
  }

  @override
  void visitFunctionTypedFormalParameter(
    covariant FunctionTypedFormalParameterImpl node,
  ) {
    var fragment = node.declaredFragment!;
    var element = fragment.element;

    withTypeParameterScope(element.typeParameters, () {
      node.returnType?.accept(this);
      node.typeParameters?.accept(this);
      node.parameters.accept(this);
      nodesToBuildType.addDeclaration(node);
    });
  }

  @override
  void visitGenericFunctionType(covariant GenericFunctionTypeImpl node) {
    var fragment = node.declaredFragment!;
    var element = fragment.element;

    withTypeParameterScope(element.typeParameters, () {
      node.returnType?.accept(this);
      node.typeParameters?.accept(this);
      node.parameters.accept(this);

      var nullabilitySuffix = _getNullabilitySuffix(node.question != null);
      var builder = FunctionTypeBuilder.of(node, nullabilitySuffix);
      node.type = builder;
      nodesToBuildType.addDeclaration(node);
      nodesToBuildType.addTypeBuilder(builder);
    });
  }

  @override
  void visitGenericTypeAlias(covariant GenericTypeAliasImpl node) {
    var fragment = node.declaredFragment!;
    var element = fragment.element;

    withTypeParameterScope(element.typeParameters, () {
      node.metadata.accept(this);
      node.typeParameters?.accept(this);
      node.type.accept(this);
      nodesToBuildType.addDeclaration(node);

      var aliasedType = node.type;
      if (aliasedType is GenericFunctionTypeImpl) {
        fragment.encloseElement(
          aliasedType.declaredFragment as GenericFunctionTypeFragmentImpl,
        );
      }
    });
  }

  @override
  void visitImplementsClause(ImplementsClause node) {
    node.interfaces.accept(this);
  }

  @override
  void visitMethodDeclaration(covariant MethodDeclarationImpl node) {
    var fragment = node.declaredFragment!;
    var element = fragment.element;

    withTypeParameterScope(element.typeParameters, () {
      LinkingNodeContext(node, nameScope);

      node.metadata.accept(this);
      node.returnType?.accept(this);
      node.typeParameters?.accept(this);
      node.parameters?.accept(this);
      nodesToBuildType.addDeclaration(node);
    });
  }

  @override
  void visitMixinDeclaration(covariant MixinDeclarationImpl node) {
    nodesToBuildType.addDeclaration(node);
    _scopeContext.walkMixinDeclarationScopes(
      node,
      visitor: this,
      enterBodyScope: () {
        LinkingNodeContext(node, nameScope);
      },
    );
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
  void visitPrimaryConstructorBody(PrimaryConstructorBody node) {
    LinkingNodeContext(node, nameScope);
  }

  @override
  void visitPrimaryConstructorDeclaration(
    covariant PrimaryConstructorDeclarationImpl node,
  ) {
    LinkingNodeContext(node, nameScope);
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
    var fragment = node.declaredFragment!;
    var element = fragment.element;

    withTypeParameterScope(element.typeParameters, () {
      node.type?.accept(this);
      node.typeParameters?.accept(this);
      node.parameters?.accept(this);
      nodesToBuildType.addDeclaration(node);
    });
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
      var fragment = variable.declaredFragment!;
      var node = linker.elementNodes[fragment]!;
      LinkingNodeContext(node, nameScope);
    }
  }

  @override
  void visitWithClause(WithClause node) {
    node.mixinTypes.accept(this);
  }

  // TODO(scheglov): Remove this temporary routing method.
  void withInstanceScope(InstanceElementImpl element, void Function() f) {
    _scopeContext.withInstanceScope(element, f);
  }

  // TODO(scheglov): Remove this temporary routing method.
  void withScope(Scope scope, void Function() f) {
    _scopeContext.withScope(scope, f);
  }

  // TODO(scheglov): Remove this temporary routing method.
  void withTypeParameterScope(
    List<TypeParameterElementImpl> elements,
    void Function() f,
  ) {
    _scopeContext.withTypeParameterScope(elements, f);
  }

  NullabilitySuffix _getNullabilitySuffix(bool hasQuestion) {
    if (hasQuestion) {
      return NullabilitySuffix.question;
    } else {
      return NullabilitySuffix.none;
    }
  }
}
