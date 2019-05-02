// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary2/function_type_builder.dart';
import 'package:analyzer/src/summary2/lazy_ast.dart';
import 'package:analyzer/src/summary2/linked_element_factory.dart';
import 'package:analyzer/src/summary2/linking_bundle_context.dart';
import 'package:analyzer/src/summary2/linking_node_scope.dart';
import 'package:analyzer/src/summary2/named_type_builder.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:analyzer/src/summary2/types_builder.dart';

//class ReferenceResolver {
//  final LinkingBundleContext linkingBundleContext;
//  final TypesToBuild typesToBuild;
//  final UnitBuilder unit;
//
//  /// TODO(scheglov) Update scope with local scopes (formal / type parameters).
//  Scope scope;
//
//  Reference reference;
//
//  ReferenceResolver(
//    this.linkingBundleContext,
//    this.typesToBuild,
//    this.unit,
//    this.scope,
//    this.reference,
//  );
//
//  LinkedNodeTypeBuilder get _dynamicType {
//    return LinkedNodeTypeBuilder(
//      kind: LinkedNodeTypeKind.dynamic_,
//    );
//  }
//
//  void resolve() {
//    _node(unit.node);
//  }
//
//  void _classDeclaration(LinkedNodeBuilder node) {
//    var name = unit.context.getUnitMemberName(node);
//    reference = reference.getChild('@class').getChild(name);
//
//    var typeParameters = node.classOrMixinDeclaration_typeParameters;
//    _withTypeParameters(typeParameters, () {
//      _extendsClause(node.classDeclaration_extendsClause);
//      _withClause(node.classDeclaration_withClause);
//      _implementsClause(node.classOrMixinDeclaration_implementsClause);
//
//      for (var member in node.classOrMixinDeclaration_members) {
//        if (member.kind != LinkedNodeKind.constructorDeclaration) {
//          _node(member);
//        }
//      }
//      for (var member in node.classOrMixinDeclaration_members) {
//        if (member.kind == LinkedNodeKind.constructorDeclaration) {
//          _node(member);
//        }
//      }
//    });
//
//    reference = reference.parent.parent;
//  }
//
//  void _classTypeAlias(LinkedNodeBuilder node) {
//    var name = unit.context.getUnitMemberName(node);
//    reference = reference.getChild('@class').getChild(name);
//
//    var typeParameters = node.classTypeAlias_typeParameters;
//    _withTypeParameters(typeParameters, () {
//      _typeName(node.classTypeAlias_superclass);
//      _withClause(node.classTypeAlias_withClause);
//      _implementsClause(node.classTypeAlias_implementsClause);
//    });
//
//    reference = reference.parent.parent;
//  }
//
//  void _compilationUnit(LinkedNodeBuilder node) {
//    _nodeList(node.compilationUnit_directives);
//    _nodeList(node.compilationUnit_declarations);
//  }
//
//  void _constructorDeclaration(LinkedNodeBuilder node) {
//    _node(node.constructorDeclaration_parameters);
//  }
//
//  void _enumConstantDeclaration(LinkedNodeBuilder node) {}
//
//  void _enumDeclaration(LinkedNodeBuilder node) {
//    _nodeList(node.enumDeclaration_constants);
//  }
//
//  void _exportDirective(LinkedNodeBuilder node) {}
//
//  void _extendsClause(LinkedNodeBuilder node) {
//    if (node == null) return;
//
//    _typeName(node.extendsClause_superclass);
//  }
//
//  void _fieldDeclaration(LinkedNodeBuilder node) {
//    _node(node.fieldDeclaration_fields);
//  }
//
//  void _fieldFormalParameter(LinkedNodeBuilder node) {
//    var typeNode = node.fieldFormalParameter_type;
//    if (typeNode != null) {
//      _node(typeNode);
//    }
//
//    var formalParameters = node.fieldFormalParameter_formalParameters;
//    if (formalParameters != null) {
//      _formalParameters(formalParameters);
//    }
//
//    if (typeNode != null || formalParameters != null) {
//      typesToBuild.declarations.add(node);
//    }
//  }
//
//  void _formalParameters(LinkedNodeBuilder node) {
//    for (var parameter in node.formalParameterList_parameters) {
//      _node(parameter);
//    }
//  }
//
//  void _functionDeclaration(LinkedNodeBuilder node) {
//    var name = unit.context.getUnitMemberName(node);
//    reference = reference.getChild('@function').getChild(name);
//
//    var function = node.functionDeclaration_functionExpression;
//    var typeParameters = function.functionExpression_typeParameters;
//    _withTypeParameters(typeParameters, () {
//      var returnType = node.functionDeclaration_returnType;
//      if (returnType != null) {
//        _node(returnType);
//        typesToBuild.declarations.add(node);
//      } else {
//        node.functionDeclaration_returnType2 = _dynamicType;
//      }
//
//      _node(function.functionExpression_formalParameters);
//    });
//
//    reference = reference.parent.parent;
//  }
//
//  void _functionExpression(LinkedNodeBuilder node) {
//    var typeParameters = node.functionExpression_typeParameters;
//    _withTypeParameters(typeParameters, () {
//      _node(node.functionExpression_formalParameters);
//    });
//  }
//
//  void _functionTypeAlias(LinkedNodeBuilder node) {
//    var name = unit.context.getUnitMemberName(node);
//    reference = reference.getChild('@typeAlias').getChild(name);
//
//    var typeParameters = node.functionTypeAlias_typeParameters;
//    _withTypeParameters(typeParameters, () {
//      var returnType = node.functionTypeAlias_returnType;
//      if (returnType != null) {
//        _node(returnType);
//        typesToBuild.declarations.add(node);
//      } else {
//        node.functionTypeAlias_returnType2 = _dynamicType;
//      }
//
//      _node(node.functionTypeAlias_formalParameters);
//    });
//
//    reference = reference.parent.parent;
//  }
//
//  void _functionTypedFormalParameter(LinkedNodeBuilder node) {
//    var typeParameters = node.functionTypedFormalParameter_typeParameters;
//    _withTypeParameters(typeParameters, () {
//      var typeNode = node.functionTypedFormalParameter_returnType;
//      if (typeNode != null) {
//        _node(typeNode);
//      }
//
//      _formalParameters(node.functionTypedFormalParameter_formalParameters);
//      typesToBuild.declarations.add(node);
//    });
//  }
//
//  void _genericFunctionType(LinkedNodeBuilder node) {
//    reference = reference.getChild('@function');
//
//    var name = '${reference.numOfChildren}';
//    reference = reference.getChild(name);
//
//    var typeParameters = node.genericFunctionType_typeParameters;
//    _withTypeParameters(typeParameters, () {
//      var returnType = node.genericFunctionType_returnType;
//      if (returnType != null) {
//        _node(returnType);
//        typesToBuild.declarations.add(node);
//      }
//
//      _formalParameters(node.genericFunctionType_formalParameters);
//
//      typesToBuild.typeAnnotations.add(node);
//    });
//
//    reference = reference.parent.parent;
//  }
//
//  void _genericTypeAlias(LinkedNodeBuilder node) {
//    var name = unit.context.getSimpleName(
//      node.namedCompilationUnitMember_name,
//    );
//    reference = reference.getChild('@typeAlias').getChild(name);
//
//    var typeParameters = node.genericTypeAlias_typeParameters;
//    _withTypeParameters(typeParameters, () {
//      _node(node.genericTypeAlias_functionType);
//    });
//
//    reference = reference.parent.parent;
//  }
//
//  void _implementsClause(LinkedNodeBuilder node) {
//    if (node == null) return;
//
//    _typeNameList(node.implementsClause_interfaces);
//  }
//
//  void _importDirective(LinkedNodeBuilder node) {}
//
//  void _libraryDirective(LinkedNodeBuilder node) {}
//
//  void _methodDeclaration(LinkedNodeBuilder node) {
//    var name = unit.context.getMethodName(node);
//    reference = reference.getChild('@method').getChild(name);
//
//    var typeParameters = node.methodDeclaration_typeParameters;
//    _withTypeParameters(typeParameters, () {
//      var returnType = node.methodDeclaration_returnType;
//      if (returnType != null) {
//        _node(returnType);
//        typesToBuild.declarations.add(node);
//      }
//
//      _node(node.methodDeclaration_formalParameters);
//    });
//
//    reference = reference.parent.parent;
//  }
//
//  void _mixinDeclaration(LinkedNodeBuilder node) {
//    var name = unit.context.getUnitMemberName(node);
//    reference = reference.getChild('@class').getChild(name);
//
//    var typeParameters = node.classOrMixinDeclaration_typeParameters;
//    _withTypeParameters(typeParameters, () {
//      _onClause(node.mixinDeclaration_onClause);
//      _implementsClause(node.classOrMixinDeclaration_implementsClause);
//      _nodeList(node.classOrMixinDeclaration_members);
//    });
//
//    reference = reference.parent.parent;
//  }
//
//  void _node(LinkedNodeBuilder node) {
//    if (node == null) return;
//
//    if (node.kind == LinkedNodeKind.classDeclaration) {
//      _classDeclaration(node);
//    } else if (node.kind == LinkedNodeKind.classTypeAlias) {
//      _classTypeAlias(node);
//    } else if (node.kind == LinkedNodeKind.compilationUnit) {
//      _compilationUnit(node);
//    } else if (node.kind == LinkedNodeKind.constructorDeclaration) {
//      _constructorDeclaration(node);
//    } else if (node.kind == LinkedNodeKind.defaultFormalParameter) {
//      _node(node.defaultFormalParameter_parameter);
//    } else if (node.kind == LinkedNodeKind.enumDeclaration) {
//      _enumDeclaration(node);
//    } else if (node.kind == LinkedNodeKind.enumConstantDeclaration) {
//      _enumConstantDeclaration(node);
//    } else if (node.kind == LinkedNodeKind.exportDirective) {
//      _exportDirective(node);
//    } else if (node.kind == LinkedNodeKind.fieldDeclaration) {
//      _fieldDeclaration(node);
//    } else if (node.kind == LinkedNodeKind.fieldFormalParameter) {
//      _fieldFormalParameter(node);
//    } else if (node.kind == LinkedNodeKind.formalParameterList) {
//      _formalParameters(node);
//    } else if (node.kind == LinkedNodeKind.functionDeclaration) {
//      _functionDeclaration(node);
//    } else if (node.kind == LinkedNodeKind.functionExpression) {
//      _functionExpression(node);
//    } else if (node.kind == LinkedNodeKind.functionTypeAlias) {
//      _functionTypeAlias(node);
//    } else if (node.kind == LinkedNodeKind.functionTypedFormalParameter) {
//      _functionTypedFormalParameter(node);
//    } else if (node.kind == LinkedNodeKind.genericFunctionType) {
//      _genericFunctionType(node);
//    } else if (node.kind == LinkedNodeKind.genericTypeAlias) {
//      _genericTypeAlias(node);
//    } else if (node.kind == LinkedNodeKind.importDirective) {
//      _importDirective(node);
//    } else if (node.kind == LinkedNodeKind.libraryDirective) {
//      _libraryDirective(node);
//    } else if (node.kind == LinkedNodeKind.methodDeclaration) {
//      _methodDeclaration(node);
//    } else if (node.kind == LinkedNodeKind.mixinDeclaration) {
//      _mixinDeclaration(node);
//    } else if (node.kind == LinkedNodeKind.partDirective) {
//      _partDirective(node);
//    } else if (node.kind == LinkedNodeKind.partOfDirective) {
//      _partOfDirective(node);
//    } else if (node.kind == LinkedNodeKind.simpleFormalParameter) {
//      _simpleFormalParameter(node);
//    } else if (node.kind == LinkedNodeKind.topLevelVariableDeclaration) {
//      _topLevelVariableDeclaration(node);
//    } else if (node.kind == LinkedNodeKind.typeArgumentList) {
//      _typeArgumentList(node);
//    } else if (node.kind == LinkedNodeKind.typeName) {
//      _typeName(node);
//    } else if (node.kind == LinkedNodeKind.typeParameter) {
//      _typeParameter(node);
//    } else if (node.kind == LinkedNodeKind.typeParameterList) {
//      _typeParameterList(node);
//    } else if (node.kind == LinkedNodeKind.variableDeclarationList) {
//      _variableDeclarationList(node);
//    } else {
//      // TODO(scheglov) implement
//      throw UnimplementedError('${node.kind}');
//    }
//  }
//
//  void _nodeList(List<LinkedNode> nodeList) {
//    if (nodeList == null) return;
//
//    for (var i = 0; i < nodeList.length; ++i) {
//      var node = nodeList[i];
//      _node(node);
//    }
//  }
//
//  void _onClause(LinkedNodeBuilder node) {
//    if (node == null) return;
//
//    _typeNameList(node.onClause_superclassConstraints);
//  }
//
//  void _partDirective(LinkedNodeBuilder node) {}
//
//  void _partOfDirective(LinkedNodeBuilder node) {}
//
//  void _setSimpleElement(LinkedNodeBuilder identifier, Reference reference) {
//    var referenceIndex = linkingBundleContext.indexOfReference(reference);
//    identifier.simpleIdentifier_element = referenceIndex;
//  }
//
//  void _simpleFormalParameter(LinkedNodeBuilder node) {
//    var typeNode = node.simpleFormalParameter_type;
//    if (typeNode != null) {
//      _node(typeNode);
//      typesToBuild.declarations.add(node);
//    } else {
//      // TODO(scheglov) might be inferred
//      node.simpleFormalParameter_type2 = _dynamicType;
//    }
//
//    if (node.normalFormalParameter_covariantKeyword != 0) {
//      node.normalFormalParameter_isCovariant = true;
//    } else {
//      // TODO(scheglov) might be inferred
//    }
//  }
//
//  void _topLevelVariableDeclaration(LinkedNodeBuilder node) {
//    _node(node.topLevelVariableDeclaration_variableList);
//  }
//
//  void _typeArgumentList(LinkedNodeBuilder node) {
//    for (var typeArgument in node.typeArgumentList_arguments) {
//      _typeName(typeArgument);
//    }
//  }
//
//  void _typeName(LinkedNodeBuilder node) {
//    if (node == null) return;
//
//    var identifier = node.typeName_name;
//    Reference reference;
//
//    if (identifier.kind == LinkedNodeKind.simpleIdentifier) {
//      var name = unit.context.getSimpleName(identifier);
//
//      if (name == 'void') {
//        node.typeName_type = LinkedNodeTypeBuilder(
//          kind: LinkedNodeTypeKind.void_,
//        );
//        return;
//      }
//
//      reference = scope.lookup(name);
//    } else {
//      var prefixNode = identifier.prefixedIdentifier_prefix;
//      var prefixName = unit.context.getSimpleName(prefixNode);
//      var prefixReference = scope.lookup(prefixName);
//      _setSimpleElement(prefixNode, prefixReference);
//
//      identifier = identifier.prefixedIdentifier_identifier;
//      var name = unit.context.getSimpleName(identifier);
//
//      if (prefixReference != null && prefixReference.isPrefix) {
//        var prefixScope = prefixReference.prefixScope;
//        reference = prefixScope.lookup(name);
//      } else {
//        identifier.simpleIdentifier_element = 0;
//        node.typeName_type = _dynamicType;
//        return;
//      }
//    }
//
//    if (reference == null) {
//      identifier.simpleIdentifier_element = 0;
//      node.typeName_type = _dynamicType;
//      return;
//    }
//
//    _setSimpleElement(identifier, reference);
//
//    var typeArgumentList = node.typeName_typeArguments;
//    if (typeArgumentList != null) {
//      _node(typeArgumentList);
//    }
//
//    typesToBuild.typeAnnotations.add(node);
//  }
//
//  void _typeNameList(List<LinkedNode> nodeList) {
//    for (var i = 0; i < nodeList.length; ++i) {
//      var node = nodeList[i];
//      _typeName(node);
//    }
//  }
//
//  void _typeParameter(LinkedNodeBuilder node) {
//    _node(node.typeParameter_bound);
//    // TODO(scheglov) set Object bound if no explicit?
//  }
//
//  void _typeParameterList(LinkedNodeBuilder node) {
//    for (var typeParameter in node.typeParameterList_typeParameters) {
//      _node(typeParameter);
//    }
//  }
//
//  void _variableDeclarationList(LinkedNodeBuilder node) {
//    var typeNode = node.variableDeclarationList_type;
//    if (typeNode != null) {
//      _node(typeNode);
//      typesToBuild.declarations.add(node);
//    }
//  }
//
//  void _withClause(LinkedNodeBuilder node) {
//    if (node == null) return;
//
//    _typeNameList(node.withClause_mixinTypes);
//  }
//
//  /// Enter the type parameters scope, visit them, and run [f].
//  void _withTypeParameters(LinkedNode typeParameterList, void f()) {
//    if (typeParameterList == null) {
//      f();
//      return;
//    }
//
//    scope = Scope(this.scope, {});
//
//    var containerRef = this.reference.getChild('@typeParameter');
//    var typeParameters = typeParameterList.typeParameterList_typeParameters;
//    for (var typeParameter in typeParameters) {
//      var name = unit.context.getSimpleName(typeParameter.typeParameter_name);
//      var reference = containerRef.getChild(name);
//      reference.node = typeParameter;
//      scope.declare(name, reference);
//    }
//
//    _node(typeParameterList);
//    f();
//
//    if (typeParameterList != null) {
//      scope = scope.parent;
//    }
//  }
//}

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
  final LinkingBundleContext linkingContext;
  final NodesToBuildType nodesToBuildType;
  final LinkedElementFactory elementFactory;
  final LibraryElement _libraryElement;
  final Reference unitReference;
  final bool nnbd;

  Reference reference;
  Scope scope;

  ReferenceResolver(
    this.linkingContext,
    this.nodesToBuildType,
    this.elementFactory,
    this._libraryElement,
    this.unitReference,
    this.nnbd,
    this.scope,
  ) : reference = unitReference;

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
    scope = new TypeParameterScope(scope, element);
    scope = new ClassScope(scope, element);
    LinkingNodeContext(node, scope);

    node.typeParameters?.accept(this);
    node.extendsClause?.accept(this);
    node.implementsClause?.accept(this);
    node.withClause?.accept(this);
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
    scope = new TypeParameterScope(scope, element);
    scope = new ClassScope(scope, element);
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

    scope = outerScope;
    reference = outerReference;
  }

  @override
  void visitDefaultFormalParameter(DefaultFormalParameter node) {
    node.parameter.accept(this);
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
  void visitFieldDeclaration(FieldDeclaration node) {
    node.fields.accept(this);
  }

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    node.type?.accept(this);
    node.parameters?.accept(this);
    nodesToBuildType.addDeclaration(node);
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
    scope = new FunctionScope(scope, element);
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
    reference.node2 = node;

    var element = ParameterElementImpl.forLinkedNode(
      outerReference.element,
      reference,
      node,
    );
    node.identifier.staticElement = element;
    _createTypeParameterElements(node.typeParameters);

    scope = new EnclosedScope(scope);
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

    var id = linkingContext.nextGenericFunctionTypeId();
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
    var builder = FunctionTypeBuilder.of(node, nullabilitySuffix);
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
    scope = new FunctionScope(scope, element);
    LinkingNodeContext(node, scope);

    node.returnType?.accept(this);
    node.parameters?.accept(this);
    node.typeParameters?.accept(this);
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
    scope = new TypeParameterScope(scope, element);
    scope = new ClassScope(scope, element);
    LinkingNodeContext(node, scope);

    node.typeParameters?.accept(this);
    node.onClause?.accept(this);
    node.implementsClause?.accept(this);
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
        element,
        nullabilitySuffix: nullabilitySuffix,
      );
    } else {
      var builder = NamedTypeBuilder.of(
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
    reference.node2 = node;

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
    if (nnbd) {
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
