// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';

/// Visitor that applies resolution data from the front end (obtained via
/// [ResolutionStorer]) to an analyzer AST.
class ResolutionApplier extends GeneralizingAstVisitor {
  final List<Element> _declaredElements;
  int _declaredElementIndex = 0;

  final List<Element> _referencedElements;
  int _referencedElementIndex = 0;

  final List<DartType> _types;
  int _typeIndex = 0;

  ResolutionApplier(
      this._declaredElements, this._referencedElements, this._types);

  /// Verifies that all types passed to the constructor have been applied.
  void checkDone() {
    if (_typeIndex != _types.length) {
      throw new StateError(
          'Some types were not consumed, starting at ${_types[_typeIndex]}');
    }
  }

  @override
  void visitExpression(Expression node) {
    visitNode(node);
    node.staticType = _getTypeFor(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    node.argumentList?.accept(this);
    // TODO(paulberry): store resolution of node.constructorName.
    node.staticType = _getTypeFor(node.constructorName);
  }

  @override
  void visitListLiteral(ListLiteral node) {
    node.elements.accept(this);
    DartType type = _getTypeFor(node);
    node.staticType = type;
    if (node.typeArguments != null) {
      _applyTypeArgumentsToList(type, node.typeArguments.arguments);
    }
  }

  @override
  void visitMapLiteral(MapLiteral node) {
    node.entries.accept(this);
    DartType type = _getTypeFor(node);
    node.staticType = type;
    if (node.typeArguments != null) {
      _applyTypeArgumentsToList(type, node.typeArguments.arguments);
    }
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    node.target?.accept(this);
    node.methodName.staticType = _getTypeFor(node.methodName);
    // TODO(paulberry): store resolution of node.methodName.
    // TODO(paulberry): store resolution of node.typeArguments.
    node.argumentList.accept(this);
    node.staticType = _getTypeFor(node.argumentList);
  }

  @override
  void visitNativeFunctionBody(NativeFunctionBody node) {
    // nothing to resolve
  }

  @override
  void visitParenthesizedExpression(ParenthesizedExpression node) {
    node.visitChildren(this);
    node.staticType = node.expression.staticType;
  }

  @override
  void visitTypeAnnotation(TypeAnnotation node) {
    _applyToTypeAnnotation(_getTypeFor(node), node);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    AstNode parent = node.parent;
    if (parent is VariableDeclarationList &&
        (parent.parent is TopLevelVariableDeclaration ||
            parent.parent is FieldDeclaration)) {
      // Don't visit the name; resolution for it will come from the outline.
    } else {
      node.name.accept(this);
      VariableElementImpl element = node.name.staticElement;
      element?.type = node.name.staticType;
    }
    node.initializer?.accept(this);
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    if (node.parent is TopLevelVariableDeclaration) {
      node.variables.accept(this);
    } else {
      if (node.variables.length != 1) {
        // TODO(paulberry): handle this case
        throw new UnimplementedError('Multiple variables in one declaration');
      }
      if (node.metadata.isNotEmpty) {
        // TODO(paulberry): handle this case
        throw new UnimplementedError('Metadata on a variable declaration list');
      }
      node.variables.accept(this);
      if (node.type != null) {
        _applyToTypeAnnotation(node.variables[0].name.staticType, node.type);
      }
    }
  }

  /// Apply the [type] to the [typeAnnotation] by setting the type of the
  /// [typeAnnotation] to the [type] and recursively applying each of the type
  /// arguments of the [type] to the corresponding type arguments of the
  /// [typeAnnotation].
  void _applyToTypeAnnotation(DartType type, TypeAnnotation typeAnnotation) {
    if (typeAnnotation is GenericFunctionTypeImpl) {
      // TODO(brianwilkerson) Finish adding support for generic function types.
      typeAnnotation.type = type;
    } else if (typeAnnotation is TypeNameImpl) {
      typeAnnotation.type = type;
    }
    if (typeAnnotation is NamedType) {
      TypeArgumentList typeArguments = typeAnnotation.typeArguments;
      if (typeArguments != null) {
        _applyTypeArgumentsToList(type, typeArguments.arguments);
      }
    }
  }

  /// Recursively apply each of the type arguments of the [type] to the
  /// corresponding type arguments of the [typeAnnotation].
  void _applyTypeArgumentsToList(
      DartType type, NodeList<TypeAnnotation> typeArguments) {
    if (type is InterfaceType) {
      List<DartType> argumentTypes = type.typeArguments;
      int argumentCount = argumentTypes.length;
      if (argumentCount != typeArguments.length) {
        throw new StateError('Found $argumentCount argument types '
            'for ${typeArguments.length} type arguments');
      }
      for (int i = 0; i < argumentCount; i++) {
        _applyToTypeAnnotation(argumentTypes[i], typeArguments[i]);
      }
    } else if (type is FunctionType) {
      // TODO(brianwilkerson) Add support for function types.
      throw new StateError('Support for function types is not yet implemented');
    } else {
      throw new StateError('Attempting to apply a non-interface type '
          '(${type.runtimeType}) to type arguments');
    }
  }

  /// Return the element associated with the declaration represented by the
  /// given [node].
  Element _getDeclarationFor(AstNode node) {
    return _declaredElements[_declaredElementIndex++];
  }

  /// Return the element associated with the reference represented by the
  /// given [node].
  Element _getReferenceFor(AstNode node) {
    return _referencedElements[_referencedElementIndex++];
  }

  /// Return the type associated with the given [node].
  DartType _getTypeFor(AstNode node) {
    return _types[_typeIndex++];
  }
}

/// Visitor that applies resolution data from the front end (obtained via
/// [ResolutionStorer]) to an analyzer AST, and also checks file offsets to
/// verify that the types are applied to the correct subexpressions.
class ValidatingResolutionApplier extends ResolutionApplier {
  /// Indicates whether debug messages should be printed.
  static const bool _debug = false;

  final List<int> _typeOffsets;

  ValidatingResolutionApplier(List<Element> declaredElements,
      List<Element> referencedElements, List<DartType> types, this._typeOffsets)
      : super(declaredElements, referencedElements, types);

  @override
  void checkDone() {
    if (_typeIndex != _types.length) {
      throw new StateError('Some types were not consumed, starting at offset '
          '${_typeOffsets[_typeIndex]}');
    }
  }

  @override
  Element _getDeclarationFor(AstNode node) {
    if (_debug) {
      print('Getting declaration element for $node');
    }
    int nodeOffset = node.offset;
    int elementOffset = _declaredElements[_declaredElementIndex].nameOffset;
    if (nodeOffset != elementOffset) {
      throw new StateError(
          'Expected a declared element for analyzer offset $nodeOffset; '
          'got one for kernel offset $elementOffset');
    }
    return super._getDeclarationFor(node);
  }

  @override
  Element _getReferenceFor(AstNode node) {
    if (_debug) {
      print('Getting reference element for $node');
    }
    int nodeOffset = node.offset;
    int elementOffset = _referencedElements[_referencedElementIndex].nameOffset;
    if (nodeOffset != elementOffset) {
      throw new StateError(
          'Expected a referenced element for analyzer offset $nodeOffset; '
          'got one for kernel offset $elementOffset');
    }
    return super._getReferenceFor(node);
  }

  @override
  DartType _getTypeFor(AstNode node) {
    if (_debug) print('Getting type for $node');
    if (node.offset != _typeOffsets[_typeIndex]) {
      throw new StateError(
          'Expected a type for analyzer offset ${node.offset}; '
          'got one for kernel offset ${_typeOffsets[_typeIndex]}');
    }
    return super._getTypeFor(node);
  }
}
