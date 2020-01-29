// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:meta/meta.dart';
import 'package:nnbd_migration/instrumentation.dart';
import 'package:nnbd_migration/nnbd_migration.dart';
import 'package:nnbd_migration/src/conditional_discard.dart';
import 'package:nnbd_migration/src/decorated_type.dart';
import 'package:nnbd_migration/src/expression_checks.dart';
import 'package:nnbd_migration/src/nullability_node.dart';
import 'package:nnbd_migration/src/potential_modification.dart';
import 'package:nnbd_migration/src/utilities/completeness_tracker.dart';
import 'package:nnbd_migration/src/utilities/permissive_mode.dart';

import 'edge_origin.dart';

/// Visitor that builds nullability nodes based on visiting code to be migrated.
///
/// The return type of each `visit...` method is a [DecoratedType] indicating
/// the static type of the element declared by the visited node, along with the
/// constraint variables that will determine its nullability.  For `visit...`
/// methods that don't visit declarations, `null` will be returned.
class NodeBuilder extends GeneralizingAstVisitor<DecoratedType>
    with
        PermissiveModeVisitor<DecoratedType>,
        CompletenessTracker<DecoratedType> {
  /// Constraint variables and decorated types are stored here.
  final VariableRecorder _variables;

  @override
  final Source source;

  /// If the parameters of a function or method are being visited, the
  /// [DecoratedType]s of the function's named parameters that have been seen so
  /// far.  Otherwise `null`.
  Map<String, DecoratedType> _namedParameters;

  /// If the parameters of a function or method are being visited, the
  /// [DecoratedType]s of the function's positional parameters that have been
  /// seen so far.  Otherwise `null`.
  List<DecoratedType> _positionalParameters;

  /// If the type parameters of a function or method are being visited, the
  /// [DecoratedType]s of the bounds of the function's type formals that have
  /// been seen so far.  Otherwise `null`.
  List<DecoratedType> _typeFormalBounds;

  final NullabilityMigrationListener /*?*/ listener;

  final NullabilityMigrationInstrumentation /*?*/ instrumentation;

  final NullabilityGraph _graph;

  final TypeProvider _typeProvider;

  NodeBuilder(this._variables, this.source, this.listener, this._graph,
      this._typeProvider,
      {this.instrumentation});

  @override
  DecoratedType visitCatchClause(CatchClause node) {
    DecoratedType exceptionType = node.exceptionType?.accept(this);
    if (node.exceptionParameter != null) {
      // If there is no `on Type` part of the catch clause, the type is dynamic.
      if (exceptionType == null) {
        exceptionType = DecoratedType.forImplicitType(
            _typeProvider, _typeProvider.dynamicType, _graph);
        instrumentation?.implicitType(
            source, node.exceptionParameter, exceptionType);
      }
      _variables.recordDecoratedElementType(
          node.exceptionParameter.staticElement, exceptionType);
    }
    if (node.stackTraceParameter != null) {
      // The type of stack traces is always StackTrace (non-nullable).
      var nullabilityNode = NullabilityNode.forInferredType();
      _graph.makeNonNullableUnion(nullabilityNode,
          StackTraceTypeOrigin(source, node.stackTraceParameter));
      var stackTraceType =
          DecoratedType(_typeProvider.stackTraceType, nullabilityNode);
      _variables.recordDecoratedElementType(
          node.stackTraceParameter.staticElement, stackTraceType);
      instrumentation?.implicitType(
          source, node.stackTraceParameter, stackTraceType);
    }
    node.stackTraceParameter?.accept(this);
    node.body?.accept(this);
    return null;
  }

  @override
  DecoratedType visitClassDeclaration(ClassDeclaration node) {
    node.metadata.accept(this);
    node.name.accept(this);
    node.typeParameters?.accept(this);
    node.nativeClause?.accept(this);
    node.members.accept(this);
    var classElement = node.declaredElement;
    _handleSupertypeClauses(node, classElement, node.extendsClause?.superclass,
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
            positionalParameters: const [],
            namedParameters: {});
        _variables.recordDecoratedElementType(constructorElement, functionType);
      }
    }
    return null;
  }

  @override
  DecoratedType visitClassTypeAlias(ClassTypeAlias node) {
    node.metadata.accept(this);
    node.name.accept(this);
    node.typeParameters?.accept(this);
    var classElement = node.declaredElement;
    _handleSupertypeClauses(node, classElement, node.superclass,
        node.withClause, node.implementsClause, null);
    for (var constructorElement in classElement.constructors) {
      assert(constructorElement.isSynthetic);
      var decoratedReturnType =
          _createDecoratedTypeForClass(classElement, node);
      var functionType = DecoratedType.forImplicitFunction(
          _typeProvider, constructorElement.type, _graph.never, _graph,
          returnType: decoratedReturnType);
      _variables.recordDecoratedElementType(constructorElement, functionType);
    }
    return null;
  }

  @override
  DecoratedType visitCompilationUnit(CompilationUnit node) {
    _graph.migrating(node.declaredElement.library.source);
    return super.visitCompilationUnit(node);
  }

  @override
  DecoratedType visitConstructorDeclaration(ConstructorDeclaration node) {
    _handleExecutableDeclaration(
        node,
        node.declaredElement,
        node.metadata,
        null,
        null,
        node.parameters,
        node.initializers,
        node.body,
        node.redirectedConstructor);
    return null;
  }

  @override
  DecoratedType visitDeclaredIdentifier(DeclaredIdentifier node) {
    node.metadata.accept(this);
    DecoratedType type = node.type?.accept(this);
    if (node.identifier != null) {
      if (type == null) {
        type = DecoratedType.forImplicitType(
            _typeProvider, node.declaredElement.type, _graph);
        instrumentation?.implicitType(source, node, type);
      }
      _variables.recordDecoratedElementType(
          node.identifier.staticElement, type);
    }
    return type;
  }

  @override
  DecoratedType visitDefaultFormalParameter(DefaultFormalParameter node) {
    var decoratedType = node.parameter.accept(this);
    if (node.defaultValue != null) {
      node.defaultValue.accept(this);
      return null;
    } else if (node.declaredElement.hasRequired) {
      return null;
    }
    if (decoratedType == null) {
      throw StateError('No type computed for ${node.parameter.runtimeType} '
          '(${node.parent.parent.toSource()}) offset=${node.offset}');
    }
    decoratedType.node.trackPossiblyOptional();
    _variables.recordPossiblyOptional(source, node, decoratedType.node);
    return null;
  }

  @override
  DecoratedType visitEnumDeclaration(EnumDeclaration node) {
    node.metadata.accept(this);
    node.name.accept(this);
    var classElement = node.declaredElement;
    _variables.recordDecoratedElementType(
        classElement, DecoratedType(classElement.thisType, _graph.never));

    makeNonNullNode([AstNode forNode]) {
      forNode ??= node;
      final graphNode = NullabilityNode.forInferredType();
      _graph.makeNonNullableUnion(graphNode, EnumValueOrigin(source, forNode));
      return graphNode;
    }

    for (var item in node.constants) {
      _variables.recordDecoratedElementType(item.declaredElement,
          DecoratedType(classElement.thisType, makeNonNullNode(item)));
    }
    final valuesGetter = classElement.getGetter('values');
    _variables.recordDecoratedElementType(
        valuesGetter,
        DecoratedType(valuesGetter.type, makeNonNullNode(),
            returnType: DecoratedType(
                valuesGetter.returnType, makeNonNullNode(), typeArguments: [
              DecoratedType(classElement.thisType, makeNonNullNode())
            ])));
    final indexGetter = classElement.getGetter('index');
    _variables.recordDecoratedElementType(
        indexGetter,
        DecoratedType(indexGetter.type, makeNonNullNode(),
            returnType:
                DecoratedType(indexGetter.returnType, makeNonNullNode())));
    final toString = classElement.getMethod('toString');
    _variables.recordDecoratedElementType(
        toString,
        DecoratedType(toString.type, makeNonNullNode(),
            returnType: DecoratedType(toString.returnType, makeNonNullNode())));
    return null;
  }

  @override
  DecoratedType visitExtensionDeclaration(ExtensionDeclaration node) {
    node.metadata.accept(this);
    node.typeParameters?.accept(this);
    var type = node.extendedType.accept(this);
    _variables.recordDecoratedElementType(node.declaredElement, type);
    node.members.accept(this);
    return null;
  }

  @override
  DecoratedType visitFieldFormalParameter(FieldFormalParameter node) {
    return _handleFormalParameter(
        node, node.type, node.typeParameters, node.parameters);
  }

  @override
  DecoratedType visitFunctionDeclaration(FunctionDeclaration node) {
    _handleExecutableDeclaration(
        node,
        node.declaredElement,
        node.metadata,
        node.returnType,
        node.functionExpression.typeParameters,
        node.functionExpression.parameters,
        null,
        node.functionExpression.body,
        null);
    return null;
  }

  @override
  DecoratedType visitFunctionExpression(FunctionExpression node) {
    _handleExecutableDeclaration(node, node.declaredElement, null, null,
        node.typeParameters, node.parameters, null, node.body, null);
    return null;
  }

  @override
  DecoratedType visitFunctionTypeAlias(FunctionTypeAlias node) {
    node.metadata.accept(this);
    var declaredElement = node.declaredElement;
    var functionType = declaredElement.function.type;
    var returnType = node.returnType;
    DecoratedType decoratedReturnType;
    if (returnType != null) {
      decoratedReturnType = returnType.accept(this);
    } else {
      // Inferred return type.
      decoratedReturnType = DecoratedType.forImplicitType(
          _typeProvider, functionType.returnType, _graph);
      instrumentation?.implicitReturnType(source, node, decoratedReturnType);
    }
    var previousPositionalParameters = _positionalParameters;
    var previousNamedParameters = _namedParameters;
    var previousTypeFormalBounds = _typeFormalBounds;
    _positionalParameters = [];
    _namedParameters = {};
    _typeFormalBounds = [];
    DecoratedType decoratedFunctionType;
    try {
      node.typeParameters?.accept(this);
      node.parameters?.accept(this);
      // Note: we don't pass _typeFormalBounds into DecoratedType because we're
      // not defining a generic function type, we're defining a generic typedef
      // of an ordinary (non-generic) function type.
      decoratedFunctionType = DecoratedType(functionType, _graph.never,
          typeFormalBounds: const [],
          returnType: decoratedReturnType,
          positionalParameters: _positionalParameters,
          namedParameters: _namedParameters);
    } finally {
      _positionalParameters = previousPositionalParameters;
      _namedParameters = previousNamedParameters;
      _typeFormalBounds = previousTypeFormalBounds;
    }
    _variables.recordDecoratedElementType(
        declaredElement, decoratedFunctionType);
    return null;
  }

  @override
  DecoratedType visitFunctionTypedFormalParameter(
      FunctionTypedFormalParameter node) {
    return _handleFormalParameter(
        node, node.returnType, node.typeParameters, node.parameters);
  }

  @override
  DecoratedType visitGenericTypeAlias(GenericTypeAlias node) {
    node.metadata.accept(this);
    var previousTypeFormalBounds = _typeFormalBounds;
    _typeFormalBounds = [];
    DecoratedType decoratedFunctionType;
    try {
      node.typeParameters?.accept(this);
      decoratedFunctionType = node.functionType.accept(this);
    } finally {
      _typeFormalBounds = previousTypeFormalBounds;
    }
    _variables.recordDecoratedElementType(
        node.declaredElement, decoratedFunctionType);
    return null;
  }

  @override
  DecoratedType visitMethodDeclaration(MethodDeclaration node) {
    _handleExecutableDeclaration(
        node,
        node.declaredElement,
        node.metadata,
        node.returnType,
        node.typeParameters,
        node.parameters,
        null,
        node.body,
        null);
    return null;
  }

  @override
  visitMixinDeclaration(MixinDeclaration node) {
    node.metadata.accept(this);
    node.name?.accept(this);
    node.typeParameters?.accept(this);
    node.members.accept(this);
    _handleSupertypeClauses(node, node.declaredElement, null, null,
        node.implementsClause, node.onClause);
    return null;
  }

  @override
  DecoratedType visitSimpleFormalParameter(SimpleFormalParameter node) {
    return _handleFormalParameter(node, node.type, null, null);
  }

  @override
  DecoratedType visitTypeAnnotation(TypeAnnotation node) {
    assert(node != null); // TODO(paulberry)
    var type = node.type;
    if (type.isVoid || type.isDynamic) {
      var nullabilityNode = NullabilityNode.forTypeAnnotation(node.end);
      var decoratedType = DecoratedType(type, nullabilityNode);
      _variables.recordDecoratedTypeAnnotation(
          source, node, decoratedType, null);
      return decoratedType;
    }
    var typeArguments = const <DecoratedType>[];
    DecoratedType decoratedReturnType;
    var positionalParameters = const <DecoratedType>[];
    var namedParameters = const <String, DecoratedType>{};
    var typeFormalBounds = const <DecoratedType>[];
    if (type is InterfaceType && type.element.typeParameters.isNotEmpty) {
      if (node is TypeName) {
        if (node.typeArguments == null) {
          typeArguments = type.typeArguments
              .map((t) =>
                  DecoratedType.forImplicitType(_typeProvider, t, _graph))
              .toList();
          instrumentation?.implicitTypeArguments(source, node, typeArguments);
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
      if (returnType == null) {
        decoratedReturnType = DecoratedType.forImplicitType(
            _typeProvider, DynamicTypeImpl.instance, _graph);
        instrumentation?.implicitReturnType(source, node, decoratedReturnType);
      } else {
        decoratedReturnType = returnType.accept(this);
      }
      positionalParameters = <DecoratedType>[];
      namedParameters = <String, DecoratedType>{};
      typeFormalBounds = <DecoratedType>[];
      var previousPositionalParameters = _positionalParameters;
      var previousNamedParameters = _namedParameters;
      var previousTypeFormalBounds = _typeFormalBounds;
      try {
        _positionalParameters = positionalParameters;
        _namedParameters = namedParameters;
        _typeFormalBounds = typeFormalBounds;
        node.typeParameters?.accept(this);
        node.parameters.accept(this);
      } finally {
        _positionalParameters = previousPositionalParameters;
        _namedParameters = previousNamedParameters;
        _typeFormalBounds = previousTypeFormalBounds;
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
    DecoratedType decoratedType;
    if (type is FunctionType && node is! GenericFunctionType) {
      (node as TypeName).typeArguments?.accept(this);
      // node is a reference to a typedef.  Treat it like an inferred type (we
      // synthesize new nodes for it).  These nodes will be unioned with the
      // typedef nodes by the edge builder.
      decoratedType = DecoratedType.forImplicitFunction(
          _typeProvider, type, nullabilityNode, _graph);
    } else {
      decoratedType = DecoratedType(type, nullabilityNode,
          typeArguments: typeArguments,
          returnType: decoratedReturnType,
          positionalParameters: positionalParameters,
          namedParameters: namedParameters,
          typeFormalBounds: typeFormalBounds);
    }
    _variables.recordDecoratedTypeAnnotation(
        source,
        node,
        decoratedType,
        PotentiallyAddQuestionSuffix(
            nullabilityNode, decoratedType.type, node.end));
    var commentToken = node.endToken.next.precedingComments;
    switch (_classifyComment(commentToken)) {
      case _NullabilityComment.bang:
        _graph.makeNonNullableUnion(
            decoratedType.node, NullabilityCommentOrigin(source, node));
        break;
      case _NullabilityComment.question:
        _graph.makeNullableUnion(
            decoratedType.node, NullabilityCommentOrigin(source, node));
        break;
      case _NullabilityComment.none:
        break;
    }
    return decoratedType;
  }

  @override
  DecoratedType visitTypeName(TypeName node) {
    typeNameVisited(node); // Note this has been visited to TypeNameTracker.
    return visitTypeAnnotation(node);
  }

  @override
  DecoratedType visitTypeParameter(TypeParameter node) {
    var element = node.declaredElement;
    var bound = node.bound;
    DecoratedType decoratedBound;
    if (bound != null) {
      decoratedBound = bound.accept(this);
    } else {
      var nullabilityNode = NullabilityNode.forInferredType();
      decoratedBound = DecoratedType(_typeProvider.objectType, nullabilityNode);
      _graph.connect(_graph.always, nullabilityNode,
          AlwaysNullableTypeOrigin.forElement(element));
    }
    _typeFormalBounds?.add(decoratedBound);
    _variables.recordDecoratedTypeParameterBound(element, decoratedBound);
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
      if (type == null) {
        type = DecoratedType.forImplicitType(
            _typeProvider, declaredElement.type, _graph);
        instrumentation?.implicitType(source, node, type);
      }
      _variables.recordDecoratedElementType(declaredElement, type);
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
        .map((t) => t.instantiate(nullabilitySuffix: NullabilitySuffix.star))
        .toList();
    var decoratedTypeArguments =
        typeArguments.map((t) => DecoratedType(t, _graph.never)).toList();
    return DecoratedType(
      classElement.instantiate(
        typeArguments: typeArguments,
        nullabilitySuffix: NullabilitySuffix.star,
      ),
      _graph.never,
      typeArguments: decoratedTypeArguments,
    );
  }

  /// Common handling of function and method declarations.
  void _handleExecutableDeclaration(
      AstNode node,
      ExecutableElement declaredElement,
      NodeList<Annotation> metadata,
      TypeAnnotation returnType,
      TypeParameterList typeParameters,
      FormalParameterList parameters,
      NodeList<ConstructorInitializer> initializers,
      FunctionBody body,
      ConstructorName redirectedConstructor) {
    metadata?.accept(this);
    var functionType = declaredElement.type;
    DecoratedType decoratedReturnType;
    if (returnType != null) {
      decoratedReturnType = returnType.accept(this);
    } else if (declaredElement is ConstructorElement) {
      // Constructors have no explicit return type annotation, so use the
      // implicit return type.
      decoratedReturnType = _createDecoratedTypeForClass(
          declaredElement.enclosingElement, parameters.parent);
      instrumentation?.implicitReturnType(source, node, decoratedReturnType);
    } else {
      // Inferred return type.
      decoratedReturnType = DecoratedType.forImplicitType(
          _typeProvider, functionType.returnType, _graph);
      instrumentation?.implicitReturnType(source, node, decoratedReturnType);
    }
    var previousPositionalParameters = _positionalParameters;
    var previousNamedParameters = _namedParameters;
    var previousTypeFormalBounds = _typeFormalBounds;
    _positionalParameters = [];
    _namedParameters = {};
    _typeFormalBounds = [];
    DecoratedType decoratedFunctionType;
    try {
      typeParameters?.accept(this);
      parameters?.accept(this);
      redirectedConstructor?.accept(this);
      initializers?.accept(this);
      decoratedFunctionType = DecoratedType(functionType, _graph.never,
          typeFormalBounds: _typeFormalBounds,
          returnType: decoratedReturnType,
          positionalParameters: _positionalParameters,
          namedParameters: _namedParameters);
      body?.accept(this);
    } finally {
      _positionalParameters = previousPositionalParameters;
      _namedParameters = previousNamedParameters;
      _typeFormalBounds = previousTypeFormalBounds;
    }
    _variables.recordDecoratedElementType(
        declaredElement, decoratedFunctionType);
  }

  DecoratedType _handleFormalParameter(
      FormalParameter node,
      TypeAnnotation type,
      TypeParameterList typeParameters,
      FormalParameterList parameters) {
    var declaredElement = node.declaredElement;
    node.metadata?.accept(this);
    DecoratedType decoratedType;
    if (parameters == null) {
      if (type != null) {
        decoratedType = type.accept(this);
      } else {
        decoratedType = DecoratedType.forImplicitType(
            _typeProvider, declaredElement.type, _graph,
            offset: node.offset);
        instrumentation?.implicitType(source, node, decoratedType);
      }
    } else {
      DecoratedType decoratedReturnType;
      if (type == null) {
        decoratedReturnType = DecoratedType.forImplicitType(
            _typeProvider, DynamicTypeImpl.instance, _graph);
        instrumentation?.implicitReturnType(source, node, decoratedReturnType);
      } else {
        decoratedReturnType = type.accept(this);
      }
      if (typeParameters != null) {
        // TODO(paulberry)
        _unimplemented(
            typeParameters, 'Function-typed parameter with type parameters');
      }
      var positionalParameters = <DecoratedType>[];
      var namedParameters = <String, DecoratedType>{};
      var previousPositionalParameters = _positionalParameters;
      var previousNamedParameters = _namedParameters;
      try {
        _positionalParameters = positionalParameters;
        _namedParameters = namedParameters;
        parameters.accept(this);
      } finally {
        _positionalParameters = previousPositionalParameters;
        _namedParameters = previousNamedParameters;
      }
      decoratedType = DecoratedType(
          declaredElement.type, NullabilityNode.forTypeAnnotation(node.end),
          returnType: decoratedReturnType,
          positionalParameters: positionalParameters,
          namedParameters: namedParameters);
    }
    _variables.recordDecoratedElementType(declaredElement, decoratedType);
    if (declaredElement.isNamed) {
      _namedParameters[declaredElement.name] = decoratedType;
    } else {
      _positionalParameters.add(decoratedType);
    }
    return decoratedType;
  }

  void _handleSupertypeClauses(
      NamedCompilationUnitMember astNode,
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
        var nullabilityNode = NullabilityNode.forInferredType();
        _graph.makeNonNullableUnion(
            nullabilityNode, NonNullableObjectSuperclass(source, astNode));
        decoratedSupertype =
            DecoratedType(_typeProvider.objectType, nullabilityNode);
      } else {
        decoratedSupertype = supertype.accept(this);
      }
      var class_ = (decoratedSupertype.type as InterfaceType).element;
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
  void recordDecoratedTypeAnnotation(Source source, TypeAnnotation node,
      DecoratedType type, PotentiallyAddQuestionSuffix potentialModification);

  /// Stores he decorated bound of the given [typeParameter].
  void recordDecoratedTypeParameterBound(
      TypeParameterElement typeParameter, DecoratedType bound);

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

  /// Retrieves the decorated bound of the given [typeParameter].
  DecoratedType decoratedTypeParameterBound(TypeParameterElement typeParameter);

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
      Source source, Expression expression, ExpressionChecksOrigin origin);

  /// Records the fact that prior to migration, an unnecessary cast existed at
  /// [node].
  void recordUnnecessaryCast(Source source, AsExpression node);
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
