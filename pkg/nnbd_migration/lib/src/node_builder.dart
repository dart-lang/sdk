// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/handle.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:front_end/src/scanner/token.dart';
import 'package:meta/meta.dart';
import 'package:nnbd_migration/nnbd_migration.dart';
import 'package:nnbd_migration/src/conditional_discard.dart';
import 'package:nnbd_migration/src/decorated_type.dart';
import 'package:nnbd_migration/src/expression_checks.dart';
import 'package:nnbd_migration/src/nullability_node.dart';

import 'edge_origin.dart';

/// Visitor that builds nullability nodes based on visiting code to be migrated.
///
/// The return type of each `visit...` method is a [DecoratedType] indicating
/// the static type of the element declared by the visited node, along with the
/// constraint variables that will determine its nullability.  For `visit...`
/// methods that don't visit declarations, `null` will be returned.
class NodeBuilder extends GeneralizingAstVisitor<DecoratedType> {
  /// Constraint variables and decorated types are stored here.
  final VariableRecorder _variables;

  /// The file being analyzed.
  final Source _source;

  /// If the parameters of a function or method are being visited, the
  /// [DecoratedType]s of the function's named parameters that have been seen so
  /// far.  Otherwise `null`.
  Map<String, DecoratedType> _namedParameters;

  /// If the parameters of a function or method are being visited, the
  /// [DecoratedType]s of the function's positional parameters that have been
  /// seen so far.  Otherwise `null`.
  List<DecoratedType> _positionalParameters;

  final NullabilityMigrationListener /*?*/ listener;

  final NullabilityGraph _graph;

  final TypeProvider _typeProvider;

  /// For convenience, a [DecoratedType] representing non-nullable `Object`.
  final DecoratedType _nonNullableObjectType;

  NodeBuilder(this._variables, this._source, this.listener, this._graph,
      this._typeProvider)
      : _nonNullableObjectType =
            DecoratedType(_typeProvider.objectType, _graph.never);

  @override
  DecoratedType visitClassDeclaration(ClassDeclaration node) {
    node.metadata.accept(this);
    node.name.accept(this);
    node.typeParameters?.accept(this);
    node.nativeClause?.accept(this);
    node.members.accept(this);
    var classElement = node.declaredElement;
    _handleSupertypeClauses(classElement, node.extendsClause?.superclass,
        node.withClause, node.implementsClause, null);
    var constructors = classElement.constructors;
    if (constructors.length == 1) {
      var constructorElement = constructors[0];
      if (constructorElement.isSynthetic) {
        // Need to create a decorated type for the default constructor.
        var decoratedReturnType =
            _createDecoratedTypeForClass(classElement, node);
        var functionType = DecoratedType(constructorElement.type, _graph.never,
            returnType: decoratedReturnType,
            positionalParameters: [],
            namedParameters: {});
        _variables.recordDecoratedElementType(constructorElement, functionType);
      }
    }
    return null;
  }

  @override
  visitClassTypeAlias(ClassTypeAlias node) {
    node.metadata.accept(this);
    node.name.accept(this);
    node.typeParameters?.accept(this);
    var classElement = node.declaredElement;
    _handleSupertypeClauses(classElement, node.superclass, node.withClause,
        node.implementsClause, null);
    for (var constructorElement in classElement.constructors) {
      assert(constructorElement.isSynthetic);
      var decoratedReturnType =
          _createDecoratedTypeForClass(classElement, node);
      var functionType = DecoratedType.forImplicitFunction(
          constructorElement.type, _graph.never, _graph,
          returnType: decoratedReturnType);
      _variables.recordDecoratedElementType(constructorElement, functionType);
    }
    return null;
  }

  @override
  DecoratedType visitCompilationUnit(CompilationUnit node) {
    _graph.migrating(_source);
    return super.visitCompilationUnit(node);
  }

  @override
  DecoratedType visitConstructorDeclaration(ConstructorDeclaration node) {
    _handleExecutableDeclaration(node.declaredElement, null, node.parameters,
        node.body, node.redirectedConstructor, node);
    return null;
  }

  @override
  DecoratedType visitDefaultFormalParameter(DefaultFormalParameter node) {
    var decoratedType = node.parameter.accept(this);
    if (node.declaredElement.hasRequired || node.defaultValue != null) {
      return null;
    }
    if (decoratedType == null) {
      throw StateError('No type computed for ${node.parameter.runtimeType} '
          '(${node.parent.parent.toSource()}) offset=${node.offset}');
    }
    decoratedType.node.trackPossiblyOptional();
    _variables.recordPossiblyOptional(_source, node, decoratedType.node);
    return null;
  }

  @override
  DecoratedType visitFieldFormalParameter(FieldFormalParameter node) {
    return _handleFormalParameter(node.declaredElement, node.metadata,
        node.type, node.typeParameters, node.parameters);
  }

  @override
  DecoratedType visitFunctionDeclaration(FunctionDeclaration node) {
    _handleExecutableDeclaration(
        node.declaredElement,
        node.returnType,
        node.functionExpression.parameters,
        node.functionExpression.body,
        null,
        node);
    return null;
  }

  @override
  DecoratedType visitFunctionTypeAlias(FunctionTypeAlias node) {
    // TODO(brianwilkerson)
    _unimplemented(node, 'FunctionTypeAlias');
  }

  @override
  DecoratedType visitFunctionTypedFormalParameter(
      FunctionTypedFormalParameter node) {
    return _handleFormalParameter(node.declaredElement, node.metadata,
        node.returnType, node.typeParameters, node.parameters);
  }

  @override
  DecoratedType visitMethodDeclaration(MethodDeclaration node) {
    _handleExecutableDeclaration(node.declaredElement, node.returnType,
        node.parameters, node.body, null, node);
    return null;
  }

  @override
  visitMixinDeclaration(MixinDeclaration node) {
    node.metadata.accept(this);
    node.name?.accept(this);
    node.typeParameters?.accept(this);
    node.members.accept(this);
    _handleSupertypeClauses(
        node.declaredElement, null, null, node.implementsClause, node.onClause);
    return null;
  }

  @override
  DecoratedType visitNode(AstNode node) {
    if (listener != null) {
      try {
        return super.visitNode(node);
      } catch (exception, stackTrace) {
        listener.addDetail('''
$exception

$stackTrace''');
        return null;
      }
    } else {
      return super.visitNode(node);
    }
  }

  @override
  DecoratedType visitSimpleFormalParameter(SimpleFormalParameter node) {
    return _handleFormalParameter(
        node.declaredElement, node.metadata, node.type, null, null);
  }

  @override
  DecoratedType visitTypeAnnotation(TypeAnnotation node) {
    assert(node != null); // TODO(paulberry)
    var type = node.type;
    if (type.isVoid || type.isDynamic) {
      var nullabilityNode = NullabilityNode.forTypeAnnotation(node.end);
      _graph.connect(_graph.always, nullabilityNode,
          AlwaysNullableTypeOrigin(_source, node.offset));
      var decoratedType =
          DecoratedTypeAnnotation(type, nullabilityNode, node.offset);
      _variables.recordDecoratedTypeAnnotation(_source, node, decoratedType,
          potentialModification: false);
      return decoratedType;
    }
    var typeArguments = const <DecoratedType>[];
    DecoratedType decoratedReturnType;
    var positionalParameters = const <DecoratedType>[];
    var namedParameters = const <String, DecoratedType>{};
    if (type is InterfaceType && type.typeParameters.isNotEmpty) {
      if (node is TypeName) {
        if (node.typeArguments == null) {
          typeArguments = type.typeArguments
              .map((t) => DecoratedType.forImplicitType(t, _graph))
              .toList();
        } else {
          typeArguments =
              node.typeArguments.arguments.map((t) => t.accept(this)).toList();
        }
      } else {
        assert(false); // TODO(paulberry): is this possible?
      }
    }
    if (node is GenericFunctionType) {
      var returnType = node.returnType;
      decoratedReturnType = returnType == null
          ? DecoratedType.forImplicitType(DynamicTypeImpl.instance, _graph)
          : returnType.accept(this);
      if (node.typeParameters != null) {
        // TODO(paulberry)
        _unimplemented(node, 'Generic function type with type parameters');
      }
      positionalParameters = <DecoratedType>[];
      namedParameters = <String, DecoratedType>{};
    }
    if (node is GenericFunctionType) {
      var previousPositionalParameters = _positionalParameters;
      var previousNamedParameters = _namedParameters;
      try {
        _positionalParameters = positionalParameters;
        _namedParameters = namedParameters;
        node.parameters.accept(this);
      } finally {
        _positionalParameters = previousPositionalParameters;
        _namedParameters = previousNamedParameters;
      }
    }
    NullabilityNode nullabilityNode;
    var parent = node.parent;
    if (parent is ExtendsClause ||
        parent is ImplementsClause ||
        parent is WithClause ||
        parent is OnClause ||
        parent is ClassTypeAlias) {
      nullabilityNode = _graph.never;
    } else {
      nullabilityNode = NullabilityNode.forTypeAnnotation(node.end);
    }
    var decoratedType = DecoratedTypeAnnotation(type, nullabilityNode, node.end,
        typeArguments: typeArguments,
        returnType: decoratedReturnType,
        positionalParameters: positionalParameters,
        namedParameters: namedParameters);
    _variables.recordDecoratedTypeAnnotation(_source, node, decoratedType);
    var commentToken = node.endToken.next.precedingComments;
    switch (_classifyComment(commentToken)) {
      case _NullabilityComment.bang:
        _graph.connect(decoratedType.node, _graph.never,
            NullabilityCommentOrigin(_source, commentToken.offset),
            hard: true);
        break;
      case _NullabilityComment.question:
        _graph.connect(_graph.always, decoratedType.node,
            NullabilityCommentOrigin(_source, commentToken.offset));
        break;
      case _NullabilityComment.none:
        break;
    }
    return decoratedType;
  }

  @override
  DecoratedType visitTypeName(TypeName node) => visitTypeAnnotation(node);

  @override
  DecoratedType visitTypeParameter(TypeParameter node) {
    var element = node.declaredElement;
    var bound = node.bound;
    DecoratedType decoratedBound;
    if (bound != null) {
      decoratedBound = bound.accept(this);
    } else {
      var nullabilityNode = NullabilityNode.forInferredType();
      _graph.union(_graph.always, nullabilityNode,
          AlwaysNullableTypeOrigin(_source, node.offset));
      decoratedBound = DecoratedType(_typeProvider.objectType, nullabilityNode);
    }
    _variables.recordDecoratedElementType(element, decoratedBound);
    return null;
  }

  @override
  DecoratedType visitVariableDeclarationList(VariableDeclarationList node) {
    node.metadata.accept(this);
    var typeAnnotation = node.type;
    var type = typeAnnotation?.accept(this);
    for (var variable in node.variables) {
      variable.metadata.accept(this);
      var declaredElement = variable.declaredElement;
      _variables.recordDecoratedElementType(declaredElement,
          type ?? DecoratedType.forImplicitType(declaredElement.type, _graph));
      variable.initializer?.accept(this);
    }
    return null;
  }

  _NullabilityComment _classifyComment(Token token) {
    if (token is CommentToken) {
      if (token.lexeme == '/*!*/') return _NullabilityComment.bang;
      if (token.lexeme == '/*?*/') return _NullabilityComment.question;
    }
    return _NullabilityComment.none;
  }

  DecoratedType _createDecoratedTypeForClass(
      ClassElement classElement, AstNode node) {
    var typeArguments = classElement.typeParameters
        .map((t) => DecoratedType(t.type, _graph.never))
        .toList();
    return DecoratedType(classElement.type, _graph.never,
        typeArguments: typeArguments);
  }

  /// Common handling of function and method declarations.
  void _handleExecutableDeclaration(
      ExecutableElement declaredElement,
      TypeAnnotation returnType,
      FormalParameterList parameters,
      FunctionBody body,
      ConstructorName redirectedConstructor,
      AstNode enclosingNode) {
    var functionType = declaredElement.type;
    DecoratedType decoratedReturnType;
    if (returnType != null) {
      decoratedReturnType = returnType.accept(this);
    } else if (declaredElement is ConstructorElement) {
      // Constructors have no explicit return type annotation, so use the
      // implicit return type.
      decoratedReturnType = _createDecoratedTypeForClass(
          declaredElement.enclosingElement, parameters.parent);
    } else {
      // Inferred return type.
      decoratedReturnType =
          DecoratedType.forImplicitType(functionType.returnType, _graph);
    }
    var previousPositionalParameters = _positionalParameters;
    var previousNamedParameters = _namedParameters;
    _positionalParameters = [];
    _namedParameters = {};
    DecoratedType decoratedFunctionType;
    try {
      parameters?.accept(this);
      body?.accept(this);
      redirectedConstructor?.accept(this);
      decoratedFunctionType = DecoratedType(functionType, _graph.never,
          returnType: decoratedReturnType,
          positionalParameters: _positionalParameters,
          namedParameters: _namedParameters);
    } finally {
      _positionalParameters = previousPositionalParameters;
      _namedParameters = previousNamedParameters;
    }
    _variables.recordDecoratedElementType(
        declaredElement, decoratedFunctionType);
  }

  DecoratedType _handleFormalParameter(
      ParameterElement declaredElement,
      NodeList<Annotation> metadata,
      TypeAnnotation type,
      TypeParameterList typeParameters,
      FormalParameterList parameters) {
    if (typeParameters != null || parameters != null) {
      _unimplemented(parameters, 'FunctionTypedFormalParameter');
    }
    metadata?.accept(this);
    var decoratedType = type != null
        ? type.accept(this)
        : DecoratedType.forImplicitType(declaredElement.type, _graph);
    _variables.recordDecoratedElementType(declaredElement, decoratedType);
    if (declaredElement.isNamed) {
      _namedParameters[declaredElement.name] = decoratedType;
    } else {
      _positionalParameters.add(decoratedType);
    }
    return decoratedType;
  }

  void _handleSupertypeClauses(
      ClassElement declaredElement,
      TypeName superclass,
      WithClause withClause,
      ImplementsClause implementsClause,
      OnClause onClause) {
    var supertypes = <TypeName>[];
    supertypes.add(superclass);
    if (withClause != null) {
      supertypes.addAll(withClause.mixinTypes);
    }
    if (implementsClause != null) {
      supertypes.addAll(implementsClause.interfaces);
    }
    if (onClause != null) {
      supertypes.addAll(onClause.superclassConstraints);
    }
    var decoratedSupertypes = <ClassElement, DecoratedType>{};
    for (var supertype in supertypes) {
      DecoratedType decoratedSupertype;
      if (supertype == null) {
        decoratedSupertype = _nonNullableObjectType;
      } else {
        decoratedSupertype = supertype.accept(this);
      }
      var class_ = (decoratedSupertype.type as InterfaceType).element;
      if (class_ is ClassElementHandle) {
        class_ = (class_ as ClassElementHandle).actualElement;
      }
      decoratedSupertypes[class_] = decoratedSupertype;
    }
    _variables.recordDecoratedDirectSupertypes(
        declaredElement, decoratedSupertypes);
  }

  @alwaysThrows
  void _unimplemented(AstNode node, String message) {
    CompilationUnit unit = node.root as CompilationUnit;
    StringBuffer buffer = StringBuffer();
    buffer.write(message);
    buffer.write(' in "');
    buffer.write(node.toSource());
    buffer.write('" on line ');
    buffer.write(unit.lineInfo.getLocation(node.offset).lineNumber);
    buffer.write(' of "');
    buffer.write(unit.declaredElement.source.fullName);
    buffer.write('"');
    throw UnimplementedError(buffer.toString());
  }
}

/// Repository of constraint variables and decorated types corresponding to the
/// code being migrated.
///
/// This data structure records the results of the first pass of migration
/// ([NodeBuilder], which finds all the variables that need to be
/// constrained).
abstract class VariableRecorder {
  /// Associates a [class_] with decorated type information for the superclasses
  /// it directly implements/extends/etc.
  void recordDecoratedDirectSupertypes(ClassElement class_,
      Map<ClassElement, DecoratedType> decoratedDirectSupertypes);

  /// Associates decorated type information with the given [element].
  void recordDecoratedElementType(Element element, DecoratedType type);

  /// Associates decorated type information with the given [type] node.
  void recordDecoratedTypeAnnotation(
      Source source, TypeAnnotation node, DecoratedTypeAnnotation type,
      {bool potentialModification: true});

  /// Records that [node] is associated with the question of whether the named
  /// [parameter] should be optional (should not have a `required`
  /// annotation added to it).
  void recordPossiblyOptional(
      Source source, DefaultFormalParameter parameter, NullabilityNode node);
}

/// Repository of constraint variables and decorated types corresponding to the
/// code being migrated.
///
/// This data structure allows the second pass of migration
/// ([ConstraintGatherer], which builds all the constraints) to access the
/// results of the first ([NodeBuilder], which finds all the
/// variables that need to be constrained).
abstract class VariableRepository {
  /// Given a [class_], gets the decorated type information for the superclasses
  /// it directly implements/extends/etc.
  Map<ClassElement, DecoratedType> decoratedDirectSupertypes(
      ClassElement class_);

  /// Retrieves the [DecoratedType] associated with the static type of the given
  /// [element].
  ///
  /// If no decorated type is found for the given element, and the element is in
  /// a library that's not being migrated, a decorated type is synthesized using
  /// [DecoratedType.forElement].
  DecoratedType decoratedElementType(Element element);

  /// Gets the [DecoratedType] associated with the given [typeAnnotation].
  DecoratedType decoratedTypeAnnotation(
      Source source, TypeAnnotation typeAnnotation);

  /// Records conditional discard information for the given AST node (which is
  /// an `if` statement or a conditional (`?:`) expression).
  void recordConditionalDiscard(
      Source source, AstNode node, ConditionalDiscard conditionalDiscard);

  /// Associates decorated type information with the given [element].
  ///
  /// TODO(paulberry): why is this in both [VariableRecorder] and
  /// [VariableRepository]?
  void recordDecoratedElementType(Element element, DecoratedType type);

  /// Associates decorated type information with the given expression [node].
  void recordDecoratedExpressionType(Expression node, DecoratedType type);

  /// Associates a set of nullability checks with the given expression [node].
  void recordExpressionChecks(
      Source source, Expression expression, ExpressionChecks checks);
}

/// Types of comments that can influence nullability
enum _NullabilityComment {
  /// The comment `/*!*/`, which indicates that the type should not have a `?`
  /// appended.
  bang,

  /// The comment `/*?*/`, which indicates that the type should have a `?`
  /// appended.
  question,

  /// No special comment.
  none,
}
