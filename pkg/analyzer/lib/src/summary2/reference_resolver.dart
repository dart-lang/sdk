// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary2/builder/source_library_builder.dart';
import 'package:analyzer/src/summary2/declaration.dart';
import 'package:analyzer/src/summary2/linking_bundle_context.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:analyzer/src/summary2/scope.dart';

/// Recursive visitor of [LinkedNode]s that resolves explicit type annotations
/// in outlines.  This includes resolving element references in identifiers
/// in type annotation, and setting [LinkedNodeType]s for corresponding type
/// annotation nodes.
///
/// Declarations that have type annotations, e.g. return types of methods, get
/// the corresponding type set (so, if there is an explicit type annotation,
/// the type is set, otherwise we keep it empty, so we will attempt to infer
/// it later).
class ReferenceResolver {
  final LinkingBundleContext linkingBundleContext;
  final UnitBuilder unit;

  /// TODO(scheglov) Update scope with local scopes (formal / type parameters).
  Scope scope;

  Reference reference;

  ReferenceResolver(
    this.linkingBundleContext,
    this.unit,
    this.scope,
    this.reference,
  );

  LinkedNodeTypeBuilder get _dynamicType {
    return LinkedNodeTypeBuilder(
      kind: LinkedNodeTypeKind.dynamic_,
    );
  }

  void resolve() {
    _node(unit.node);
  }

  void _classDeclaration(LinkedNodeBuilder node) {
    var name = unit.context.getUnitMemberName(node);
    reference = reference.getChild('@class').getChild(name);

    var typeParameters = node.classOrMixinDeclaration_typeParameters;
    _withTypeParameters(typeParameters, () {
      var extendsClause = node.classDeclaration_extendsClause;
      if (extendsClause != null) {
        _typeName(extendsClause.extendsClause_superclass);
      }

      _nodeList(
        node.classDeclaration_withClause?.withClause_mixinTypes,
      );

      _nodeList(
        node.classOrMixinDeclaration_implementsClause
            ?.implementsClause_interfaces,
      );

      for (var field in node.classOrMixinDeclaration_members) {
        if (field.kind != LinkedNodeKind.constructorDeclaration) {
          _node(field);
        }
      }
      for (var field in node.classOrMixinDeclaration_members) {
        if (field.kind == LinkedNodeKind.constructorDeclaration) {
          _node(field);
        }
      }
    });

    reference = reference.parent.parent;
  }

  void _classTypeAlias(LinkedNodeBuilder node) {
    var name = unit.context.getUnitMemberName(node);
    reference = reference.getChild('@class').getChild(name);

    var typeParameters = node.classTypeAlias_typeParameters;
    _withTypeParameters(typeParameters, () {
      var superclass = node.classTypeAlias_superclass;
      if (superclass != null) {
        _typeName(superclass);
      }

      _nodeList(
        node.classTypeAlias_withClause?.withClause_mixinTypes,
      );

      _nodeList(
        node.classTypeAlias_implementsClause?.implementsClause_interfaces,
      );
    });

    reference = reference.parent.parent;
  }

  void _compilationUnit(LinkedNodeBuilder node) {
    _nodeList(node.compilationUnit_directives);
    _nodeList(node.compilationUnit_declarations);
  }

  void _constructorDeclaration(LinkedNodeBuilder node) {
    _node(node.constructorDeclaration_parameters);
  }

  void _enumConstantDeclaration(LinkedNodeBuilder node) {}

  void _enumDeclaration(LinkedNodeBuilder node) {
    _nodeList(node.enumDeclaration_constants);
  }

  void _fieldDeclaration(LinkedNodeBuilder node) {
    _node(node.fieldDeclaration_fields);
  }

  void _fieldFormalParameter(LinkedNodeBuilder node) {
    var typeNode = node.fieldFormalParameter_type;
    if (typeNode != null) {
      _node(typeNode);
      node.fieldFormalParameter_type2 = _getTypeAnnotationType(typeNode);
    }

    var formalParameters = node.fieldFormalParameter_formalParameters;
    if (formalParameters != null) {
      _node(formalParameters);
      throw 'incomplete';
    }
  }

  void _formalParameters(LinkedNodeBuilder node) {
    for (var parameter in node.formalParameterList_parameters) {
      _node(parameter);
    }
  }

  void _functionDeclaration(LinkedNodeBuilder node) {
    var name = unit.context.getUnitMemberName(node);
    reference = reference.getChild('@function').getChild(name);

    var function = node.functionDeclaration_functionExpression;
    var typeParameters = function.functionExpression_typeParameters;
    _withTypeParameters(typeParameters, () {
      var returnType = node.functionDeclaration_returnType;
      if (returnType != null) {
        _node(returnType);
        node.functionDeclaration_returnType2 =
            _getTypeAnnotationType(returnType);
      } else {
        node.functionDeclaration_returnType2 = _dynamicType;
      }

      _node(function.functionExpression_formalParameters);
    });

    reference = reference.parent.parent;
  }

  void _functionExpression(LinkedNodeBuilder node) {
    var typeParameters = node.functionExpression_typeParameters;
    _withTypeParameters(typeParameters, () {
      _node(node.functionExpression_formalParameters);
    });
  }

  void _functionTypeAlias(LinkedNodeBuilder node) {
    var name = unit.context.getUnitMemberName(node);
    reference = reference.getChild('@typeAlias').getChild(name);

    var typeParameters = node.functionTypeAlias_typeParameters;
    _withTypeParameters(typeParameters, () {
      var returnType = node.functionTypeAlias_returnType;
      if (returnType != null) {
        _node(returnType);
        node.functionTypeAlias_returnType2 = _getTypeAnnotationType(returnType);
      } else {
        node.functionTypeAlias_returnType2 = _dynamicType;
      }

      _node(node.functionTypeAlias_formalParameters);
    });

    reference = reference.parent.parent;
  }

  void _genericFunctionType(LinkedNodeBuilder node) {
    reference = reference.getChild('@function');

    var name = '${reference.numOfChildren}';
    reference = reference.getChild(name);

    var typeParameters = node.genericFunctionType_typeParameters;
    _withTypeParameters(typeParameters, () {
      var returnType = node.genericFunctionType_returnType;
      if (returnType != null) {
        _node(returnType);
        node.genericFunctionType_returnType2 =
            _getTypeAnnotationType(returnType);
      } else {
        node.genericFunctionType_returnType2 = _dynamicType;
      }

      _node(node.genericFunctionType_formalParameters);
    });

    reference = reference.parent.parent;
  }

  void _genericTypeAlias(LinkedNodeBuilder node) {
    var name = unit.context.getSimpleName(
      node.namedCompilationUnitMember_name,
    );
    reference = reference.getChild('@typeAlias').getChild(name);

    var typeParameters = node.genericTypeAlias_typeParameters;
    _withTypeParameters(typeParameters, () {
      _node(node.genericTypeAlias_functionType);
    });

    reference = reference.parent.parent;
  }

  LinkedNodeTypeBuilder _getTypeAnnotationType(LinkedNodeBuilder node) {
    var kind = node.kind;
    if (kind == LinkedNodeKind.typeName) {
      return node.typeName_type;
    } else {
      throw UnimplementedError('$kind');
    }
  }

  void _importDirective(LinkedNodeBuilder node) {}

  void _libraryDirective(LinkedNodeBuilder node) {}

  void _methodDeclaration(LinkedNodeBuilder node) {
    var name = unit.context.getMethodName(node);
    reference = reference.getChild('@method').getChild(name);

    var typeParameters = node.methodDeclaration_typeParameters;
    _withTypeParameters(typeParameters, () {
      var returnType = node.methodDeclaration_returnType;
      if (returnType != null) {
        _node(returnType);
        node.methodDeclaration_returnType2 = _getTypeAnnotationType(returnType);
      }

      _node(node.methodDeclaration_formalParameters);
    });

    reference = reference.parent.parent;
  }

  void _node(LinkedNodeBuilder node) {
    if (node == null) return;

    if (node.kind == LinkedNodeKind.classDeclaration) {
      _classDeclaration(node);
    } else if (node.kind == LinkedNodeKind.classTypeAlias) {
      _classTypeAlias(node);
    } else if (node.kind == LinkedNodeKind.compilationUnit) {
      _compilationUnit(node);
    } else if (node.kind == LinkedNodeKind.constructorDeclaration) {
      _constructorDeclaration(node);
    } else if (node.kind == LinkedNodeKind.defaultFormalParameter) {
      _node(node.defaultFormalParameter_parameter);
    } else if (node.kind == LinkedNodeKind.enumDeclaration) {
      _enumDeclaration(node);
    } else if (node.kind == LinkedNodeKind.enumConstantDeclaration) {
      _enumConstantDeclaration(node);
    } else if (node.kind == LinkedNodeKind.fieldDeclaration) {
      _fieldDeclaration(node);
    } else if (node.kind == LinkedNodeKind.fieldFormalParameter) {
      _fieldFormalParameter(node);
    } else if (node.kind == LinkedNodeKind.formalParameterList) {
      _formalParameters(node);
    } else if (node.kind == LinkedNodeKind.functionDeclaration) {
      _functionDeclaration(node);
    } else if (node.kind == LinkedNodeKind.functionExpression) {
      _functionExpression(node);
    } else if (node.kind == LinkedNodeKind.functionTypeAlias) {
      _functionTypeAlias(node);
    } else if (node.kind == LinkedNodeKind.genericFunctionType) {
      _genericFunctionType(node);
    } else if (node.kind == LinkedNodeKind.genericTypeAlias) {
      _genericTypeAlias(node);
    } else if (node.kind == LinkedNodeKind.importDirective) {
      _importDirective(node);
    } else if (node.kind == LinkedNodeKind.libraryDirective) {
      _libraryDirective(node);
    } else if (node.kind == LinkedNodeKind.methodDeclaration) {
      _methodDeclaration(node);
    } else if (node.kind == LinkedNodeKind.simpleFormalParameter) {
      _simpleFormalParameter(node);
    } else if (node.kind == LinkedNodeKind.topLevelVariableDeclaration) {
      _topLevelVariableDeclaration(node);
    } else if (node.kind == LinkedNodeKind.typeArgumentList) {
      _typeArgumentList(node);
    } else if (node.kind == LinkedNodeKind.typeName) {
      _typeName(node);
    } else if (node.kind == LinkedNodeKind.typeParameter) {
      _typeParameter(node);
    } else if (node.kind == LinkedNodeKind.typeParameterList) {
      _typeParameterList(node);
    } else if (node.kind == LinkedNodeKind.variableDeclarationList) {
      _variableDeclarationList(node);
    } else {
      // TODO(scheglov) implement
      throw UnimplementedError('${node.kind}');
    }
  }

  void _nodeList(List<LinkedNode> nodeList) {
    if (nodeList == null) return;

    for (var i = 0; i < nodeList.length; ++i) {
      var node = nodeList[i];
      _node(node);
    }
  }

  void _simpleFormalParameter(LinkedNodeBuilder node) {
    var typeNode = node.simpleFormalParameter_type;
    if (typeNode != null) {
      _node(typeNode);
      node.simpleFormalParameter_type2 = _getTypeAnnotationType(typeNode);
    } else {
      // TODO(scheglov) might be inferred
      node.simpleFormalParameter_type2 = _dynamicType;
    }

    if (node.normalFormalParameter_covariantKeyword != 0) {
      node.normalFormalParameter_isCovariant = true;
    } else {
      // TODO(scheglov) might be inferred
    }
  }

  void _topLevelVariableDeclaration(LinkedNodeBuilder node) {
    _node(node.topLevelVariableDeclaration_variableList);
  }

  void _typeArgumentList(LinkedNodeBuilder node) {
    for (var typeArgument in node.typeArgumentList_arguments) {
      _typeName(typeArgument);
    }
  }

  void _typeName(LinkedNodeBuilder node) {
    if (node == null) return;

    var identifier = node.typeName_name;
    if (identifier.kind == LinkedNodeKind.simpleIdentifier) {
      var name = unit.context.getSimpleName(identifier);

      if (name == 'void') {
        node.typeName_type = LinkedNodeTypeBuilder(
          kind: LinkedNodeTypeKind.void_,
        );
        return;
      }

      var declaration = scope.lookup(name);
      if (declaration == null) {
        identifier.simpleIdentifier_element = 0;
        node.typeName_type = _dynamicType;
        return;
      }

      var reference = declaration.reference;
      var referenceIndex = linkingBundleContext.indexOfReference(reference);
      identifier.simpleIdentifier_element = referenceIndex;

      var typeArguments = const <LinkedNodeTypeBuilder>[];
      var typeArgumentList = node.typeName_typeArguments;
      if (typeArgumentList != null) {
        _node(typeArgumentList);
        typeArguments = typeArgumentList.typeArgumentList_arguments
            .map((node) => _getTypeAnnotationType(node))
            .toList();
      }

      if (reference.isClass) {
        node.typeName_type = LinkedNodeTypeBuilder(
          kind: LinkedNodeTypeKind.interface,
          interfaceClass: referenceIndex,
          interfaceTypeArguments: typeArguments,
        );
      } else if (reference.isEnum) {
        node.typeName_type = LinkedNodeTypeBuilder(
          kind: LinkedNodeTypeKind.interface,
          interfaceClass: referenceIndex,
        );
      } else if (reference.isTypeParameter) {
        node.typeName_type = LinkedNodeTypeBuilder(
          kind: LinkedNodeTypeKind.typeParameter,
          typeParameterParameter: referenceIndex,
        );
      } else {
        // TODO(scheglov) set Object? keep unresolved?
        throw UnimplementedError();
      }
    } else {
      // TODO(scheglov) implement
      throw UnimplementedError();
    }
  }

  void _typeParameter(LinkedNodeBuilder node) {
    _node(node.typeParameter_bound);
    // TODO(scheglov) set Object bound if no explicit?
  }

  void _typeParameterList(LinkedNodeBuilder node) {
    for (var typeParameter in node.typeParameterList_typeParameters) {
      _node(typeParameter);
    }
  }

  void _variableDeclarationList(LinkedNodeBuilder node) {
    var typeNode = node.variableDeclarationList_type;
    if (typeNode != null) {
      _node(typeNode);
      for (var field in node.variableDeclarationList_variables) {
        field.variableDeclaration_type2 = _getTypeAnnotationType(typeNode);
      }
    }
  }

  /// Enter the type parameters scope, visit them, and run [f].
  void _withTypeParameters(LinkedNode typeParameterList, void f()) {
    if (typeParameterList == null) {
      f();
      return;
    }

    scope = Scope(this.scope, {});

    var containerRef = this.reference.getChild('@typeParameter');
    var typeParameters = typeParameterList.typeParameterList_typeParameters;
    for (var typeParameter in typeParameters) {
      var name = unit.context.getSimpleName(typeParameter.typeParameter_name);
      var reference = containerRef.getChild(name);
      reference.node = typeParameter;
      scope.declare(name, Declaration(name, reference));
    }

    _node(typeParameterList);
    f();

    if (typeParameterList != null) {
      scope = scope.parent;
    }
  }
}
