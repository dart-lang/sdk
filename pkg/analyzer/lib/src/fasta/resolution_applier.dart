// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/fasta/resolution_storer.dart';

/// Visitor that applies resolution data from the front end (obtained via
/// [ResolutionStorer]) to an analyzer AST.
class ResolutionApplier extends GeneralizingAstVisitor {
  final List<Element> _declaredElements;
  int _declaredElementIndex = 0;

  final List<Element> _referencedElements;
  int _referencedElementIndex = 0;

  final List<DartType> _types;
  int _typeIndex = 0;

  /// The [ExecutableElementImpl] inside of which resolution is being applied.
  ExecutableElementImpl enclosingExecutable;

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
  void visitFunctionDeclaration(FunctionDeclaration node) {
    DartType returnType = _getTypeFor(node);
    if (node.returnType != null) {
      _applyToTypeAnnotation(returnType, node.returnType);
    }

    // Associate the element with the node.
    FunctionElementImpl element = _getDeclarationFor(node);
    if (element != null && enclosingExecutable != null) {
      enclosingExecutable.encloseElement(element);

      node.name.staticElement = element;
      node.name.staticType = element.type;
    }

    // Visit components of the FunctionExpression.
    FunctionExpression functionExpression = node.functionExpression;
    functionExpression.element = element;
    functionExpression.typeParameters?.accept(this);
    functionExpression.body?.accept(this);
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
    DartType invokeType = _getTypeFor(node.methodName);
    node.staticInvokeType = invokeType;
    node.methodName.staticType = invokeType;
    // TODO(paulberry): store resolution of node.methodName.
    // TODO(paulberry): store resolution of node.typeArguments.
    node.argumentList.accept(this);
    node.methodName.staticElement = _getReferenceFor(node.methodName);
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
  void visitSimpleIdentifier(SimpleIdentifier node) {
    node.staticElement = _getReferenceFor(node);
    super.visitSimpleIdentifier(node);
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
      DartType type = _getTypeFor(node.name);
      node.name.staticType = type;

      VariableElementImpl element = _getDeclarationFor(node.name);
      if (element != null && enclosingExecutable != null) {
        node.name.staticElement = element;
        element.type = type;
        enclosingExecutable.encloseElement(element);
      }
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
      if (type is InterfaceType) {
        // TODO(scheglov) Support other types, e.g. dynamic.
        Identifier name = typeAnnotation.name;
        if (name is SimpleIdentifier) {
          name.staticElement = type.element;
        } else {
          throw new UnimplementedError('${name.runtimeType}');
        }
      }
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

  final List<int> _declaredElementOffsets;
  final List<int> _referencedElementOffsets;
  final List<int> _typeOffsets;

  ValidatingResolutionApplier(
      List<Element> declaredElements,
      List<Element> referencedElements,
      List<DartType> types,
      this._declaredElementOffsets,
      this._referencedElementOffsets,
      this._typeOffsets)
      : super(declaredElements, referencedElements, types);

  @override
  void checkDone() {
    if (_declaredElementIndex != _declaredElements.length) {
      throw new StateError('Some declarations were not consumed, starting at '
          'offset ${_declaredElementOffsets[_declaredElementIndex]}');
    }
    if (_referencedElementIndex != _referencedElements.length) {
      throw new StateError('Some references were not consumed, starting at '
          'offset ${_referencedElementOffsets[_referencedElementIndex]}');
    }
    if (_typeIndex != _types.length) {
      throw new StateError('Some types were not consumed, starting at offset '
          '${_typeOffsets[_typeIndex]}');
    }
  }

  @override
  Element _getDeclarationFor(AstNode node) {
    int nodeOffset = node.offset;
    if (_debug) {
      print('Getting declaration element for $node at $nodeOffset');
    }
    int elementOffset = _declaredElementOffsets[_declaredElementIndex];
    if (nodeOffset != elementOffset) {
      throw new StateError(
          'Expected element declaration for analyzer offset $nodeOffset; '
          'got one for kernel offset $elementOffset');
    }
    return super._getDeclarationFor(node);
  }

  @override
  Element _getReferenceFor(AstNode node) {
    int nodeOffset = node.offset;
    if (_debug) {
      print('Getting reference element for $node at $nodeOffset');
    }
    int elementOffset = _referencedElementOffsets[_referencedElementIndex];
    if (nodeOffset != elementOffset) {
      throw new StateError(
          'Expected element reference for analyzer offset $nodeOffset; '
          'got one for kernel offset $elementOffset');
    }
    return super._getReferenceFor(node);
  }

  @override
  DartType _getTypeFor(AstNode node) {
    var nodeOffset = node.offset;
    if (_debug) {
      print('Getting type for $node at $nodeOffset');
    }
    if (nodeOffset != _typeOffsets[_typeIndex]) {
      throw new StateError('Expected a type for analyzer offset $nodeOffset; '
          'got one for kernel offset ${_typeOffsets[_typeIndex]}');
    }
    return super._getTypeFor(node);
  }
}
