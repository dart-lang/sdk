// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_ast_factory.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/fasta/resolution_storer.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:front_end/src/base/syntactic_entity.dart';

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
    if (_declaredElementIndex != _declaredElements.length) {
      throw new StateError('Some declarations were not consumed, starting at '
          '${_declaredElements[_declaredElementIndex]}');
    }
    if (_referencedElementIndex != _referencedElements.length) {
      throw new StateError('Some references were not consumed, starting at '
          '${_referencedElements[_referencedElementIndex]}');
    }
    if (_typeIndex != _types.length) {
      throw new StateError(
          'Some types were not consumed, starting at ${_types[_typeIndex]}');
    }
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    node.leftHandSide.accept(this);
    node.rightHandSide.accept(this);
    node.staticType = node.rightHandSide.staticType;

    // TODO(scheglov) Support for compound assignment.
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    node.leftOperand.accept(this);

    node.staticElement = _getReferenceFor(node.operator);

    // Skip the function type of the operator.
    _getTypeFor(node.operator);

    node.rightOperand.accept(this);

    // Record the return type of the expression.
    node.staticType = _getTypeFor(node.operator);
  }

  @override
  void visitExpression(Expression node) {
    visitNode(node);
    node.staticType = _getTypeFor(node);
  }

  @override
  void visitFormalParameterList(FormalParameterList parameterList) {
    for (var parameter in parameterList.parameters) {
      if (parameter is DefaultFormalParameter) {
        if (parameter.defaultValue == null) {
          // Consume the Null type, for the implicit default value.
          _getTypeFor(null, synthetic: true);
        } else {
          throw new UnimplementedError();
        }
      }
    }
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    FunctionExpression functionExpression = node.functionExpression;
    FormalParameterList parameterList = functionExpression.parameters;

    // Apply resolution to default values of formal parameters.
    parameterList.accept(this);

    DartType returnType = _getTypeFor(node);
    if (node.returnType != null) {
      applyToTypeAnnotation(returnType, node.returnType);
    }

    // Associate the elements with the nodes.
    FunctionElementImpl element = _getDeclarationFor(node);
    if (element != null && enclosingExecutable != null) {
      enclosingExecutable.encloseElement(element);

      node.name.staticElement = element;
      node.name.staticType = element.type;

      _applyParameters(element.parameters, parameterList.parameters);
    }

    // Visit components of the FunctionExpression.
    functionExpression.element = element;
    functionExpression.typeParameters?.accept(this);
    functionExpression.body?.accept(this);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    node.function.accept(this);
    // TODO(brianwilkerson) Visit node.typeArguments.
    node.argumentList.accept(this);
    node.staticElement = _getReferenceFor(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    node.argumentList?.accept(this);

    ConstructorName constructorName = node.constructorName;

    DartType type = _getTypeFor(constructorName);
    ConstructorElement element = _getReferenceFor(constructorName);
    ClassElement classElement = element?.enclosingElement;

    node.staticElement = element;
    node.staticType = type;

    Identifier typeIdentifier = constructorName.type.name;
    if (typeIdentifier is SimpleIdentifier) {
      applyToTypeAnnotation(type, constructorName.type);
      if (constructorName.name != null) {
        constructorName.name.staticElement = element;
      }
    } else if (typeIdentifier is PrefixedIdentifier) {
      // TODO(scheglov) Rewrite AST using knowledge about prefixes.
      // TODO(scheglov) Add support for `new prefix.Type()`.
      // TODO(scheglov) Add support for `new prefix.Type.name()`.
      assert(constructorName.name == null);
      constructorName.period = typeIdentifier.period;
      constructorName.name = typeIdentifier.identifier;
      SimpleIdentifier classNode = typeIdentifier.prefix;
      constructorName.type = astFactory.typeName(classNode, null);
      classNode.staticElement = classElement;
      classNode.staticType = type;
      constructorName.name.staticElement = element;
    }

    _associateArgumentsWithParameters(element, node.argumentList);
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

    ExecutableElement calleeElement = _getReferenceFor(node.methodName);
    DartType invokeType = _getTypeFor(node.methodName);

    node.staticInvokeType = invokeType;
    node.methodName.staticType = invokeType;
    // TODO(paulberry): store resolution of node.typeArguments.

    // Apply resolution to arguments.
    // Skip names of named arguments.
    ArgumentList argumentList = node.argumentList;
    for (var argument in argumentList.arguments) {
      if (argument is NamedExpression) {
        argument.expression.accept(this);
      } else {
        argument.accept(this);
      }
    }

    node.methodName.staticElement = calleeElement;
    node.staticType = _getTypeFor(argumentList);

    _associateArgumentsWithParameters(calleeElement, argumentList);
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
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    node.prefix.accept(this);
    node.identifier.accept(this);
    node.staticType = node.identifier.staticType;
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    node.target?.accept(this);
    node.propertyName.accept(this);
    node.staticType = node.propertyName.staticType;
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    node.staticElement = _getReferenceFor(node);
    super.visitSimpleIdentifier(node);
  }

  @override
  void visitTypeAnnotation(TypeAnnotation node) {
    applyToTypeAnnotation(_getTypeFor(node), node);
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
        DartType type = node.variables[0].name.staticType;
        // TODO(brianwilkerson) Understand why the type is sometimes `null`.
        if (type != null) {
          applyToTypeAnnotation(type, node.type);
        }
      }
    }
  }

  /// Associate arguments of the [argumentList] with parameters of the
  /// given [executable].
  void _associateArgumentsWithParameters(
      ExecutableElement executable, ArgumentList argumentList) {
    if (executable != null) {
      List<Expression> arguments = argumentList.arguments;
      var correspondingParameters =
          new List<ParameterElement>(arguments.length);
      for (int i = 0; i < arguments.length; i++) {
        var argument = arguments[i];
        if (argument is NamedExpression) {
          for (var parameter in executable.parameters) {
            SimpleIdentifier label = argument.name.label;
            if (parameter.parameterKind == ParameterKind.NAMED &&
                parameter.name == label.name) {
              label.staticElement = parameter;
              correspondingParameters[i] = parameter;
              break;
            }
          }
        } else {
          correspondingParameters[i] = executable.parameters[i];
        }
      }
      argumentList.correspondingStaticParameters = correspondingParameters;
    }
  }

  /// Return the element associated with the declaration represented by the
  /// given [node].
  Element _getDeclarationFor(AstNode node) {
    return _declaredElements[_declaredElementIndex++];
  }

  /// Return the element associated with the reference represented by the
  /// given [entity].
  Element _getReferenceFor(SyntacticEntity entity) {
    return _referencedElements[_referencedElementIndex++];
  }

  /// Return the type associated with the given [entity].
  ///
  /// If [synthetic] is `true`, the [entity] must be `null` and the type is
  /// an implicit type, e.g. the type of the absent default values of an
  /// optional parameter (i.e. [Null]).
  DartType _getTypeFor(SyntacticEntity entity, {bool synthetic: false}) {
    assert(!synthetic || entity == null);
    return _types[_typeIndex++];
  }

  /// Apply the [type] to the [typeAnnotation] by setting the type of the
  /// [typeAnnotation] to the [type] and recursively applying each of the type
  /// arguments of the [type] to the corresponding type arguments of the
  /// [typeAnnotation].
  static void applyToTypeAnnotation(
      DartType type, TypeAnnotation typeAnnotation) {
    SimpleIdentifier nameForElement(Identifier identifier) {
      if (identifier is SimpleIdentifier) {
        return identifier;
      } else if (identifier is PrefixedIdentifier) {
        return identifier.identifier;
      } else {
        throw new UnimplementedError(
            'Unhandled class of identifier: ${identifier.runtimeType}');
      }
    }

    if (typeAnnotation is GenericFunctionTypeImpl) {
      if (type is! FunctionType) {
        throw new StateError('Non-function type ($type) '
            'for generic function annotation ($typeAnnotation)');
      }
      FunctionType functionType = type;
      typeAnnotation.type = type;
      applyToTypeAnnotation(functionType.returnType, typeAnnotation.returnType);
      _applyParameters(
          functionType.parameters, typeAnnotation.parameters.parameters);
    } else if (typeAnnotation is TypeNameImpl) {
      typeAnnotation.type = type;
      SimpleIdentifier name = nameForElement(typeAnnotation.name);
      name.staticElement = type.element;
      name.staticType = type;
    }
    if (typeAnnotation is NamedType) {
      TypeArgumentList typeArguments = typeAnnotation.typeArguments;
      if (typeArguments != null) {
        _applyTypeArgumentsToList(type, typeArguments.arguments);
      }
    }
  }

  /// Apply the types of the [parameterElements] to the [parameters] that have
  /// an explicit type annotation.
  static void _applyParameters(List<ParameterElement> parameterElements,
      List<FormalParameter> parameters) {
    int length = parameterElements.length;
    if (parameters.length != length) {
      throw new StateError('Parameter counts do not match');
    }
    for (int i = 0; i < length; i++) {
      ParameterElement element = parameterElements[i];
      FormalParameter parameter = parameters[i];

      NormalFormalParameter normalParameter;
      if (parameter is NormalFormalParameter) {
        normalParameter = parameter;
      } else if (parameter is DefaultFormalParameter) {
        normalParameter = parameter.parameter;
      }

      TypeAnnotation typeAnnotation = null;
      if (normalParameter is SimpleFormalParameter) {
        typeAnnotation = normalParameter.type;
      }
      if (typeAnnotation != null) {
        applyToTypeAnnotation(element.type, typeAnnotation);
      }

      if (normalParameter is SimpleFormalParameterImpl) {
        normalParameter.element = element;
      }
      if (normalParameter.identifier != null) {
        normalParameter.identifier.staticElement = element;
      }
    }
  }

  /// Recursively apply each of the type arguments of the [type] to the
  /// corresponding type arguments of the [typeAnnotation].
  static void _applyTypeArgumentsToList(
      DartType type, NodeList<TypeAnnotation> typeArguments) {
    if (type is InterfaceType) {
      List<DartType> argumentTypes = type.typeArguments;
      int argumentCount = argumentTypes.length;
      if (argumentCount != typeArguments.length) {
        throw new StateError('Found $argumentCount argument types '
            'for ${typeArguments.length} type arguments');
      }
      for (int i = 0; i < argumentCount; i++) {
        applyToTypeAnnotation(argumentTypes[i], typeArguments[i]);
      }
    } else if (type is FunctionType) {
      // TODO(brianwilkerson) Add support for function types.
      throw new StateError('Support for function types is not yet implemented');
    } else {
      throw new StateError('Attempting to apply a non-interface type '
          '(${type.runtimeType}) to type arguments');
    }
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
    if (_declaredElementIndex >= _declaredElements.length) {
      throw new StateError(
          'No declaration information for $node at $nodeOffset');
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
  Element _getReferenceFor(SyntacticEntity entity) {
    int entityOffset = entity.offset;
    if (_debug) {
      print('Getting reference element for $entity at $entityOffset');
    }
    if (_referencedElementIndex >= _referencedElements.length) {
      throw new StateError(
          'No reference information for $entity at $entityOffset');
    }
    int elementOffset = _referencedElementOffsets[_referencedElementIndex];
    if (entityOffset != elementOffset) {
      throw new StateError(
          'Expected element reference for analyzer offset $entityOffset; '
          'got one for kernel offset $elementOffset');
    }
    return super._getReferenceFor(entity);
  }

  @override
  DartType _getTypeFor(SyntacticEntity entity, {bool synthetic: false}) {
    var entityOffset = synthetic ? -1 : entity.offset;
    if (_debug) {
      print('Getting type for $entity at $entityOffset');
    }
    if (_typeIndex >= _types.length) {
      throw new StateError('No type information for $entity at $entityOffset');
    }
    if (entityOffset != _typeOffsets[_typeIndex]) {
      throw new StateError('Expected a type for $entity at $entityOffset; '
          'got one for kernel offset ${_typeOffsets[_typeIndex]}');
    }
    return super._getTypeFor(entity);
  }
}
