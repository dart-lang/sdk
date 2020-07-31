// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary2/function_type_builder.dart';
import 'package:analyzer/src/summary2/lazy_ast.dart';
import 'package:analyzer/src/summary2/linked_element_factory.dart';
import 'package:analyzer/src/summary2/linking_node_scope.dart';
import 'package:analyzer/src/summary2/named_type_builder.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:analyzer/src/summary2/types_builder.dart';

/// Recursive visitor of [LinkedNode]s that resolves explicit type annotations
/// in outlines.  This includes resolving element references in identifiers
/// in type annotation, and setting [LinkedNodeType]s for corresponding type
/// annotation nodes.
///
/// Declarations that have type annotations, e.g. return types of methods, get
/// the corresponding type set (so, if there is an explicit type annotation,
/// the type is set, otherwise we keep it empty, so we will attempt to infer
/// it later).
class ReferenceResolver extends ThrowingAstVisitor<void> {
  final TypeSystemImpl _typeSystem;
  final NodesToBuildType nodesToBuildType;
  final LinkedElementFactory elementFactory;
  final LibraryElement _libraryElement;
  final Reference unitReference;

  /// Indicates whether the library is opted into NNBD.
  final bool isNNBD;

  /// The depth-first number of the next [GenericFunctionType] node.
  int _nextGenericFunctionTypeId = 0;

  Reference reference;
  Scope scope;

  /// Is `true` if the current [ClassDeclaration] has a const constructor.
  bool _hasConstConstructor = false;

  ReferenceResolver(
    this.nodesToBuildType,
    this.elementFactory,
    this._libraryElement,
    this.unitReference,
    this.isNNBD,
    this.scope,
  )   : _typeSystem = _libraryElement.typeSystem,
        reference = unitReference;

  @override
  void visitBlockFunctionBody(BlockFunctionBody node) {}

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    var outerScope = scope;
    var outerReference = reference;

    var name = node.name.name;
    reference = reference.getChild('@class').getChild(name);

    ClassElementImpl element = reference.element;
    node.name.staticElement = element;

    _createTypeParameterElements(node.typeParameters);
    scope = TypeParameterScope(scope, element);

    node.typeParameters?.accept(this);
    node.extendsClause?.accept(this);
    node.implementsClause?.accept(this);
    node.withClause?.accept(this);

    scope = ClassScope(scope, element);
    LinkingNodeContext(node, scope);

    _hasConstConstructor = false;
    for (var member in node.members) {
      if (member is ConstructorDeclaration && member.constKeyword != null) {
        _hasConstConstructor = true;
        break;
      }
    }

    node.members.accept(this);
    nodesToBuildType.addDeclaration(node);

    scope = outerScope;
    reference = outerReference;
  }

  @override
  void visitClassTypeAlias(ClassTypeAlias node) {
    var outerScope = scope;
    var outerReference = reference;

    var name = node.name.name;
    reference = reference.getChild('@class').getChild(name);

    ClassElementImpl element = reference.element;
    node.name.staticElement = element;
    _createTypeParameterElements(node.typeParameters);
    scope = TypeParameterScope(scope, element);
    scope = ClassScope(scope, element);
    LinkingNodeContext(node, scope);

    node.typeParameters?.accept(this);
    node.superclass?.accept(this);
    node.withClause?.accept(this);
    node.implementsClause?.accept(this);
    nodesToBuildType.addDeclaration(node);

    scope = outerScope;
    reference = outerReference;
  }

  @override
  void visitCompilationUnit(CompilationUnit node) {
    LinkingNodeContext(node, scope);
    node.declarations.accept(this);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    var outerScope = scope;
    var outerReference = reference;

    var name = node.name?.name ?? '';
    reference = reference.getChild('@constructor').getChild(name);

    var element = ConstructorElementImpl.forLinkedNode(
      outerReference.element,
      reference,
      node,
    );

    var functionScope = FunctionScope(scope, element);
    functionScope.defineParameters();
    LinkingNodeContext(node, functionScope);

    node.parameters?.accept(this);
    node.initializers.accept(
      _SetGenericFunctionTypeIdVisitor(this),
    );

    scope = outerScope;
    reference = outerReference;
  }

  @override
  void visitDefaultFormalParameter(DefaultFormalParameter node) {
    node.parameter.accept(this);
    node.defaultValue?.accept(
      _SetGenericFunctionTypeIdVisitor(this),
    );
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {}

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {}

  @override
  void visitExtendsClause(ExtendsClause node) {
    node.superclass.accept(this);
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    var outerScope = scope;
    var outerReference = reference;

    var refName = LazyExtensionDeclaration.get(node).refName;
    reference = reference.getChild('@extension').getChild(refName);

    ExtensionElementImpl element = reference.element;
    node.name?.staticElement = element;

    _createTypeParameterElements(node.typeParameters);
    scope = TypeParameterScope(scope, element);

    node.typeParameters?.accept(this);
    node.extendedType.accept(this);

    scope = ExtensionScope(scope, element);
    LinkingNodeContext(node, scope);

    node.members.accept(this);
    nodesToBuildType.addDeclaration(node);

    scope = outerScope;
    reference = outerReference;
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    node.fields.accept(this);

    if (node.fields.isConst ||
        !node.isStatic && node.fields.isFinal && _hasConstConstructor) {
      var visitor = _SetGenericFunctionTypeIdVisitor(this);
      node.fields.variables.accept(visitor);
    }
  }

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    var outerScope = scope;
    var outerReference = reference;

    var name = node.identifier.name;
    reference = reference.getChild('@parameter').getChild(name);
    reference.node = node;

    var element = ParameterElementImpl.forLinkedNode(
      outerReference.element,
      reference,
      node,
    );
    node.identifier.staticElement = element;
    _createTypeParameterElements(node.typeParameters);

    scope = EnclosedScope(scope);
    for (var typeParameter in element.typeParameters) {
      scope.define(typeParameter);
    }

    node.type?.accept(this);
    node.typeParameters?.accept(this);
    node.parameters?.accept(this);
    nodesToBuildType.addDeclaration(node);

    scope = outerScope;
    reference = outerReference;
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    node.parameters.accept(this);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    var outerScope = scope;
    var outerReference = reference;

    var container = '@function';
    var propertyKeyword = node.propertyKeyword?.keyword;
    if (propertyKeyword == Keyword.GET) {
      container = '@getter';
    } else if (propertyKeyword == Keyword.SET) {
      container = '@setter';
    }

    var name = node.name.name;
    reference = reference.getChild(container).getChild(name);

    ExecutableElementImpl element = reference.element;
    node.name.staticElement = element;
    _createTypeParameterElements(node.functionExpression.typeParameters);
    scope = FunctionScope(scope, element);
    LinkingNodeContext(node, scope);

    node.returnType?.accept(this);
    node.functionExpression.accept(this);
    nodesToBuildType.addDeclaration(node);

    scope = outerScope;
    reference = outerReference;
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    node.typeParameters?.accept(this);
    node.parameters?.accept(this);
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    var outerScope = scope;
    var outerReference = reference;

    var name = node.name.name;
    reference = reference.getChild('@typeAlias').getChild(name);

    GenericTypeAliasElementImpl element = reference.element;
    node.name.staticElement = element;
    _createTypeParameterElements(node.typeParameters);
    scope = FunctionTypeScope(outerScope, element);

    node.returnType?.accept(this);
    node.typeParameters?.accept(this);

    reference = reference.getChild('@function');
    reference.element = element;
    node.parameters.accept(this);

    nodesToBuildType.addDeclaration(node);

    scope = outerScope;
    reference = outerReference;
  }

  @override
  void visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    var outerScope = scope;
    var outerReference = reference;

    var name = node.identifier.name;
    reference = reference.getChild('@parameter').getChild(name);
    reference.node = node;

    var element = ParameterElementImpl.forLinkedNode(
      outerReference.element,
      reference,
      node,
    );
    node.identifier.staticElement = element;
    _createTypeParameterElements(node.typeParameters);

    scope = EnclosedScope(scope);
    for (var typeParameter in element.typeParameters) {
      scope.define(typeParameter);
    }

    node.returnType?.accept(this);
    node.typeParameters?.accept(this);
    node.parameters.accept(this);
    nodesToBuildType.addDeclaration(node);

    scope = outerScope;
    reference = outerReference;
  }

  @override
  void visitGenericFunctionType(GenericFunctionType node) {
    var outerScope = scope;
    var outerReference = reference;

    var id = _nextGenericFunctionTypeId++;
    LazyAst.setGenericFunctionTypeId(node, id);

    var containerRef = unitReference.getChild('@genericFunctionType');
    reference = containerRef.getChild('$id');

    var element = GenericFunctionTypeElementImpl.forLinkedNode(
      unitReference.element,
      reference,
      node,
    );
    (node as GenericFunctionTypeImpl).declaredElement = element;
    _createTypeParameterElements(node.typeParameters);
    scope = TypeParameterScope(outerScope, element);

    node.returnType?.accept(this);
    node.typeParameters?.accept(this);
    node.parameters.accept(this);

    var nullabilitySuffix = _getNullabilitySuffix(node.question != null);
    var builder = FunctionTypeBuilder.of(isNNBD, node, nullabilitySuffix);
    (node as GenericFunctionTypeImpl).type = builder;
    nodesToBuildType.addTypeBuilder(builder);

    scope = outerScope;
    reference = outerReference;
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    var outerScope = scope;
    var outerReference = reference;

    var name = node.name.name;
    reference = reference.getChild('@typeAlias').getChild(name);

    GenericTypeAliasElementImpl element = reference.element;
    node.name.staticElement = element;
    _createTypeParameterElements(node.typeParameters);
    scope = TypeParameterScope(outerScope, element);

    node.typeParameters?.accept(this);
    node.functionType?.accept(this);
    nodesToBuildType.addDeclaration(node);

    scope = outerScope;
    reference = outerReference;
  }

  @override
  void visitImplementsClause(ImplementsClause node) {
    node.interfaces.accept(this);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    var outerScope = scope;
    var outerReference = reference;

    var container = '@method';
    var propertyKeyword = node.propertyKeyword?.keyword;
    if (propertyKeyword == Keyword.GET) {
      container = '@getter';
    } else if (propertyKeyword == Keyword.SET) {
      container = '@setter';
    }

    var name = node.name.name;
    reference = reference.getChild(container).getChild(name);

    var element = MethodElementImpl.forLinkedNode(
      outerReference.element,
      reference,
      node,
    );
    node.name.staticElement = element;
    _createTypeParameterElements(node.typeParameters);
    scope = FunctionScope(scope, element);
    LinkingNodeContext(node, scope);

    node.returnType?.accept(this);
    node.typeParameters?.accept(this);
    node.parameters?.accept(this);
    nodesToBuildType.addDeclaration(node);

    scope = outerScope;
    reference = outerReference;
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    var outerScope = scope;
    var outerReference = reference;

    var name = node.name.name;
    reference = reference.getChild('@mixin').getChild(name);

    MixinElementImpl element = reference.element;
    node.name.staticElement = element;

    _createTypeParameterElements(node.typeParameters);
    scope = TypeParameterScope(scope, element);

    node.typeParameters?.accept(this);
    node.onClause?.accept(this);
    node.implementsClause?.accept(this);

    scope = ClassScope(scope, element);
    LinkingNodeContext(node, scope);

    node.members.accept(this);
    nodesToBuildType.addDeclaration(node);

    scope = outerScope;
    reference = outerReference;
  }

  @override
  void visitOnClause(OnClause node) {
    node.superclassConstraints.accept(this);
  }

  @override
  void visitSimpleFormalParameter(SimpleFormalParameter node) {
    node.type?.accept(this);
    nodesToBuildType.addDeclaration(node);
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    node.variables.accept(this);
    if (node.variables.isConst) {
      var visitor = _SetGenericFunctionTypeIdVisitor(this);
      node.variables.variables.accept(visitor);
    }
  }

  @override
  void visitTypeArgumentList(TypeArgumentList node) {
    node.arguments.accept(this);
  }

  @override
  void visitTypeName(TypeName node) {
    var typeName = node.name;
    if (typeName is SimpleIdentifier && typeName.name == 'void') {
      node.type = VoidTypeImpl.instance;
      return;
    }

    var element = scope.lookup(typeName, _libraryElement);
    if (typeName is SimpleIdentifier) {
      typeName.staticElement = element;
    } else if (typeName is PrefixedIdentifier) {
      typeName.identifier.staticElement = element;
      SimpleIdentifier prefix = typeName.prefix;
      prefix.staticElement = scope.lookup(prefix, _libraryElement);
    }

    node.typeArguments?.accept(this);

    var nullabilitySuffix = _getNullabilitySuffix(node.question != null);
    if (element is TypeParameterElement) {
      node.type = TypeParameterTypeImpl(
        element: element,
        nullabilitySuffix: nullabilitySuffix,
      );
    } else {
      var builder = NamedTypeBuilder.of(
        _typeSystem,
        node,
        element,
        nullabilitySuffix,
      );
      node.type = builder;
      nodesToBuildType.addTypeBuilder(builder);
    }
  }

  @override
  void visitTypeParameter(TypeParameter node) {
    node.bound?.accept(this);
  }

  @override
  void visitTypeParameterList(TypeParameterList node) {
    node.typeParameters.accept(this);
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    node.type?.accept(this);
    nodesToBuildType.addDeclaration(node);
  }

  @override
  void visitWithClause(WithClause node) {
    node.mixinTypes.accept(this);
  }

  void _createTypeParameterElement(TypeParameter node) {
    var outerReference = this.reference;
    var containerRef = outerReference.getChild('@typeParameter');
    var reference = containerRef.getChild(node.name.name);
    reference.node = node;

    var element = TypeParameterElementImpl.forLinkedNode(
      outerReference.element,
      reference,
      node,
    );
    node.name.staticElement = element;
  }

  void _createTypeParameterElements(TypeParameterList typeParameterList) {
    if (typeParameterList == null) return;

    for (var typeParameter in typeParameterList.typeParameters) {
      _createTypeParameterElement(typeParameter);
    }
  }

  NullabilitySuffix _getNullabilitySuffix(bool hasQuestion) {
    if (isNNBD) {
      if (hasQuestion) {
        return NullabilitySuffix.question;
      } else {
        return NullabilitySuffix.none;
      }
    } else {
      return NullabilitySuffix.star;
    }
  }
}

/// For consistency we set identifiers for [GenericFunctionType]s in constant
/// variable initializers, and instance final fields of classes with constant
/// constructors.
class _SetGenericFunctionTypeIdVisitor extends RecursiveAstVisitor<void> {
  final ReferenceResolver resolver;

  _SetGenericFunctionTypeIdVisitor(this.resolver);

  @override
  void visitGenericFunctionType(GenericFunctionType node) {
    var id = resolver._nextGenericFunctionTypeId++;
    LazyAst.setGenericFunctionTypeId(node, id);

    super.visitGenericFunctionType(node);
  }
}
