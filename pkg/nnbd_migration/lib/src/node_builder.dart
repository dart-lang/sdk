// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:nnbd_migration/instrumentation.dart';
import 'package:nnbd_migration/nnbd_migration.dart';
import 'package:nnbd_migration/src/decorated_type.dart';
import 'package:nnbd_migration/src/edit_plan.dart';
import 'package:nnbd_migration/src/hint_action.dart';
import 'package:nnbd_migration/src/nullability_node.dart';
import 'package:nnbd_migration/src/nullability_node_target.dart';
import 'package:nnbd_migration/src/utilities/completeness_tracker.dart';
import 'package:nnbd_migration/src/utilities/hint_utils.dart';
import 'package:nnbd_migration/src/utilities/permissive_mode.dart';
import 'package:nnbd_migration/src/utilities/resolution_utils.dart';
import 'package:nnbd_migration/src/variables.dart';

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
  final Variables _variables;

  @override
  final Source? source;

  /// If the parameters of a function or method are being visited, the
  /// [DecoratedType]s of the function's named parameters that have been seen so
  /// far.  Otherwise `null`.
  Map<String, DecoratedType>? _namedParameters;

  /// If the parameters of a function or method are being visited, the
  /// [DecoratedType]s of the function's positional parameters that have been
  /// seen so far.  Otherwise `null`.
  List<DecoratedType>? _positionalParameters;

  /// If the child types of a node are being visited, the
  /// [NullabilityNodeTarget] that should be used in [visitTypeAnnotation].
  /// Otherwise `null`.
  NullabilityNodeTarget? _target;

  /// [ClassDeclaration] for the current class or `null` if we are currently
  /// not inside a class declaration.
  ClassDeclaration? _classDeclaration;

  final NullabilityMigrationListener? listener;

  final NullabilityMigrationInstrumentation? instrumentation;

  final NullabilityGraph _graph;

  final TypeProvider _typeProvider;

  /// Indicates whether the declaration currently being visited is marked
  /// `external`.
  bool _visitingExternalDeclaration = false;

  NodeBuilder(this._variables, this.source, this.listener, this._graph,
      this._typeProvider,
      {this.instrumentation});

  NullabilityNodeTarget get safeTarget {
    var target = _target;
    if (target != null) return target;
    assert(false, 'Unknown nullability node target');
    return NullabilityNodeTarget.text('unknown');
  }

  bool get _isInjectable =>
      _classDeclaration?.metadata
          .any((ann) => _isAngularConstructor(ann.element, 'Injectable')) ??
      false;
  bool get _isInsideAngularComponent =>
      _classDeclaration?.metadata
          .toList()
          .any((ann) => _isAngularConstructor(ann.element, 'Component')) ??
      false;

  @override
  DecoratedType? visitAsExpression(AsExpression node) {
    node.expression.accept(this);
    _pushNullabilityNodeTarget(
        NullabilityNodeTarget.text('cast type'), () => node.type.accept(this));
    return null;
  }

  @override
  DecoratedType? visitCatchClause(CatchClause node) {
    var exceptionElement = node.exceptionParameter?.declaredElement;
    var target = exceptionElement == null
        ? NullabilityNodeTarget.text('exception type')
        : NullabilityNodeTarget.element(exceptionElement);
    DecoratedType? exceptionType = _pushNullabilityNodeTarget(
        target, () => node.exceptionType?.accept(this));
    if (node.exceptionParameter != null) {
      // If there is no `on Type` part of the catch clause, the type is dynamic.
      if (exceptionType == null) {
        exceptionType = DecoratedType.forImplicitType(_typeProvider,
            _typeProvider.dynamicType, _graph, target.withCodeRef(node));
        instrumentation?.implicitType(
            source, node.exceptionParameter, exceptionType);
      }
      _variables.recordDecoratedElementType(
          node.exceptionParameter?.declaredElement, exceptionType);
    }
    if (node.stackTraceParameter != null) {
      // The type of stack traces is always StackTrace (non-nullable).
      var target = NullabilityNodeTarget.text('stack trace').withCodeRef(node);
      var nullabilityNode = NullabilityNode.forInferredType(target);
      _graph.makeNonNullableUnion(nullabilityNode,
          StackTraceTypeOrigin(source, node.stackTraceParameter));
      var stackTraceType =
          DecoratedType(_typeProvider.stackTraceType, nullabilityNode);
      _variables.recordDecoratedElementType(
          node.stackTraceParameter?.declaredElement, stackTraceType);
      instrumentation?.implicitType(
          source, node.stackTraceParameter, stackTraceType);
    }
    node.stackTraceParameter?.accept(this);
    node.body.accept(this);
    return null;
  }

  @override
  DecoratedType? visitClassDeclaration(ClassDeclaration node) {
    node.metadata.accept(this);
    node.typeParameters?.accept(this);
    node.nativeClause?.accept(this);
    _classDeclaration = node;
    node.members.accept(this);
    _classDeclaration = null;
    var classElement = node.declaredElement!;
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
  DecoratedType? visitClassTypeAlias(ClassTypeAlias node) {
    node.metadata.accept(this);
    node.typeParameters?.accept(this);
    var classElement = node.declaredElement!;
    _handleSupertypeClauses(node, classElement, node.superclass,
        node.withClause, node.implementsClause, null);
    for (var constructorElement in classElement.constructors) {
      assert(constructorElement.isSynthetic);
      var decoratedReturnType =
          _createDecoratedTypeForClass(classElement, node);
      var target = NullabilityNodeTarget.element(constructorElement);
      var functionType = DecoratedType.forImplicitFunction(
          _typeProvider, constructorElement.type, _graph.never, _graph, target,
          returnType: decoratedReturnType);
      _variables.recordDecoratedElementType(constructorElement, functionType);
      for (var parameter in constructorElement.parameters) {
        var parameterType = DecoratedType.forImplicitType(
            _typeProvider, parameter.type, _graph, target);
        _variables.recordDecoratedElementType(parameter, parameterType);
      }
    }
    return null;
  }

  @override
  DecoratedType? visitCompilationUnit(CompilationUnit node) {
    _graph.migrating(node.declaredElement!.library.source);
    _graph.migrating(node.declaredElement!.source);
    return super.visitCompilationUnit(node);
  }

  @override
  DecoratedType? visitConstructorDeclaration(ConstructorDeclaration node) {
    _handleExecutableDeclaration(
        node,
        node.declaredElement!,
        node.metadata,
        null,
        null,
        node.parameters,
        node.initializers,
        node.body,
        node.redirectedConstructor,
        isExternal: node.externalKeyword != null);
    return null;
  }

  @override
  DecoratedType? visitConstructorName(ConstructorName node) {
    _pushNullabilityNodeTarget(NullabilityNodeTarget.text('constructed type'),
        () => node.type.accept(this));
    node.name?.accept(this);
    return null;
  }

  @override
  DecoratedType? visitDeclaredIdentifier(DeclaredIdentifier node) {
    node.metadata.accept(this);
    var declaredElement = node.declaredElement!;
    var target = NullabilityNodeTarget.element(declaredElement);
    DecoratedType? type =
        _pushNullabilityNodeTarget(target, () => node.type?.accept(this));
    if (type == null) {
      type = DecoratedType.forImplicitType(
          _typeProvider, declaredElement.type, _graph, target);
      instrumentation?.implicitType(source, node, type);
    }
    _variables.recordDecoratedElementType(node.declaredElement, type);
    return type;
  }

  @override
  DecoratedType? visitDefaultFormalParameter(DefaultFormalParameter node) {
    var decoratedType = node.parameter.accept(this);
    var hint = getPrefixHint(node.firstTokenAfterCommentAndMetadata!);
    if (node.defaultValue != null) {
      node.defaultValue!.accept(this);
      return null;
    } else if (node.declaredElement!.hasRequired) {
      return null;
    } else if (hint != null && hint.kind == HintCommentKind.required) {
      _variables.recordRequiredHint(source, node, hint);
      return null;
    }
    if (decoratedType == null) {
      throw StateError('No type computed for ${node.parameter.runtimeType} '
          '(${node.parent!.parent!.toSource()}) offset=${node.offset}');
    }
    decoratedType.node.trackPossiblyOptional();
    return null;
  }

  @override
  DecoratedType? visitEnumDeclaration(EnumDeclaration node) {
    node.metadata.accept(this);
    var classElement = node.declaredElement!;
    _variables.recordDecoratedElementType(
        classElement, DecoratedType(classElement.thisType, _graph.never));

    makeNonNullNode(NullabilityNodeTarget target, [AstNode? forNode]) {
      forNode ??= node;
      final graphNode = NullabilityNode.forInferredType(target);
      _graph.makeNonNullableUnion(graphNode, EnumValueOrigin(source, forNode));
      return graphNode;
    }

    for (var item in node.constants) {
      var declaredElement = item.declaredElement!;
      var target = NullabilityNodeTarget.element(declaredElement);
      _variables.recordDecoratedElementType(declaredElement,
          DecoratedType(classElement.thisType, makeNonNullNode(target, item)));
    }
    final valuesGetter = classElement.getGetter('values')!;
    var valuesTarget = NullabilityNodeTarget.element(valuesGetter);
    _variables.recordDecoratedElementType(
        valuesGetter,
        DecoratedType(valuesGetter.type, makeNonNullNode(valuesTarget),
            returnType: DecoratedType(valuesGetter.returnType,
                makeNonNullNode(valuesTarget.returnType()),
                typeArguments: [
                  DecoratedType(classElement.thisType,
                      makeNonNullNode(valuesTarget.typeArgument(0)))
                ])));
    return null;
  }

  @override
  DecoratedType? visitExtensionDeclaration(ExtensionDeclaration node) {
    node.metadata.accept(this);
    node.typeParameters?.accept(this);
    var type = _pushNullabilityNodeTarget(
        NullabilityNodeTarget.text('extended type'),
        () => node.extendedType.accept(this));
    _variables.recordDecoratedElementType(node.declaredElement, type);
    node.members.accept(this);
    return null;
  }

  @override
  DecoratedType? visitFieldFormalParameter(FieldFormalParameter node) {
    return _handleFormalParameter(
        node, node.type, node.typeParameters, node.parameters);
  }

  @override
  DecoratedType? visitFormalParameterList(FormalParameterList node) {
    int index = 0;
    for (var parameter in node.parameters) {
      var element = parameter.declaredElement!;
      NullabilityNodeTarget newTarget;
      if (element.isNamed) {
        newTarget = safeTarget.namedParameter(element.name);
      } else {
        newTarget = safeTarget.positionalParameter(index++);
      }
      _pushNullabilityNodeTarget(newTarget, () => parameter.accept(this));
    }
    return null;
  }

  @override
  DecoratedType? visitFunctionDeclaration(FunctionDeclaration node) {
    _handleExecutableDeclaration(
        node,
        node.declaredElement!,
        node.metadata,
        node.returnType,
        node.functionExpression.typeParameters,
        node.functionExpression.parameters,
        null,
        node.functionExpression.body,
        null,
        isExternal: node.externalKeyword != null);
    return null;
  }

  @override
  DecoratedType? visitFunctionExpression(FunctionExpression node) {
    _handleExecutableDeclaration(node, node.declaredElement!, null, null,
        node.typeParameters, node.parameters, null, node.body, null,
        isExternal: false);
    return null;
  }

  @override
  DecoratedType? visitFunctionExpressionInvocation(
      FunctionExpressionInvocation node) {
    node.function.accept(this);
    _pushNullabilityNodeTarget(NullabilityNodeTarget.text('type argument'),
        () => node.typeArguments?.accept(this));
    node.argumentList.accept(this);
    return null;
  }

  @override
  DecoratedType? visitFunctionTypeAlias(FunctionTypeAlias node) {
    node.metadata.accept(this);
    var declaredElement = node.declaredElement!;
    var functionElement =
        declaredElement.aliasedElement as GenericFunctionTypeElement;
    var functionType = functionElement.type;
    var returnType = node.returnType;
    DecoratedType? decoratedReturnType;
    var target = NullabilityNodeTarget.element(declaredElement);
    if (returnType != null) {
      _pushNullabilityNodeTarget(target.returnType(), () {
        decoratedReturnType = returnType.accept(this);
      });
    } else {
      // Inferred return type.
      decoratedReturnType = DecoratedType.forImplicitType(
          _typeProvider, functionType.returnType, _graph, target.returnType());
      instrumentation?.implicitReturnType(source, node, decoratedReturnType);
    }
    var previousPositionalParameters = _positionalParameters;
    var previousNamedParameters = _namedParameters;
    _positionalParameters = [];
    _namedParameters = {};
    DecoratedType decoratedFunctionType;
    try {
      node.typeParameters?.accept(this);
      _pushNullabilityNodeTarget(target, () => node.parameters.accept(this));
      // Note: we don't pass _typeFormalBounds into DecoratedType because we're
      // not defining a generic function type, we're defining a generic typedef
      // of an ordinary (non-generic) function type.
      decoratedFunctionType = DecoratedType(functionType, _graph.never,
          returnType: decoratedReturnType,
          positionalParameters: _positionalParameters,
          namedParameters: _namedParameters);
    } finally {
      _positionalParameters = previousPositionalParameters;
      _namedParameters = previousNamedParameters;
    }
    _variables.recordDecoratedElementType(
        functionElement, decoratedFunctionType);
    return null;
  }

  @override
  DecoratedType? visitFunctionTypedFormalParameter(
      FunctionTypedFormalParameter node) {
    return _handleFormalParameter(
        node, node.returnType, node.typeParameters, node.parameters);
  }

  @override
  DecoratedType? visitGenericTypeAlias(GenericTypeAlias node) {
    node.metadata.accept(this);
    DecoratedType? decoratedFunctionType;
    node.typeParameters?.accept(this);
    var target = NullabilityNodeTarget.element(node.declaredElement!);
    _pushNullabilityNodeTarget(target, () {
      decoratedFunctionType = node.functionType!.accept(this);
    });
    _variables.recordDecoratedElementType(
        (node.declaredElement as TypeAliasElement).aliasedElement,
        decoratedFunctionType);
    return null;
  }

  @override
  DecoratedType? visitIsExpression(IsExpression node) {
    node.expression.accept(this);
    _pushNullabilityNodeTarget(NullabilityNodeTarget.text('tested type'),
        () => node.type.accept(this));
    return null;
  }

  @override
  DecoratedType? visitListLiteral(ListLiteral node) {
    _pushNullabilityNodeTarget(NullabilityNodeTarget.text('list element type'),
        () => node.typeArguments?.accept(this));
    node.elements.accept(this);
    return null;
  }

  @override
  DecoratedType? visitMethodDeclaration(MethodDeclaration node) {
    var declaredElement = node.declaredElement;
    var decoratedType = _handleExecutableDeclaration(
        node,
        declaredElement!,
        node.metadata,
        node.returnType,
        node.typeParameters,
        node.parameters,
        null,
        node.body,
        null,
        isExternal: node.externalKeyword != null);
    if (declaredElement is PropertyAccessorElement) {
      // Store a decorated type for the synthetic field so that in case we try
      // to access it later we won't crash (this could happen due to errors in
      // the source code).
      if (declaredElement.isGetter) {
        _variables.recordDecoratedElementType(
            declaredElement.variable, decoratedType.returnType);
      } else {
        var type = decoratedType.positionalParameters![0];
        _variables.recordDecoratedElementType(declaredElement.variable, type,
            soft: true);
        if (_getAngularAnnotation(node.metadata) == _AngularAnnotation.child) {
          _graph.makeNullable(type.node, AngularAnnotationOrigin(source, node));
        }
      }
    }
    return null;
  }

  @override
  DecoratedType? visitMethodInvocation(MethodInvocation node) {
    node.target?.accept(this);
    node.methodName.accept(this);
    _pushNullabilityNodeTarget(NullabilityNodeTarget.text('type argument'),
        () => node.typeArguments?.accept(this));
    node.argumentList.accept(this);
    return null;
  }

  @override
  DecoratedType? visitMixinDeclaration(MixinDeclaration node) {
    node.metadata.accept(this);
    node.typeParameters?.accept(this);
    node.members.accept(this);
    _handleSupertypeClauses(node, node.declaredElement!, null, null,
        node.implementsClause, node.onClause);
    return null;
  }

  @override
  DecoratedType visitNamedType(NamedType node) {
    namedTypeVisited(node); // Note this has been visited to NamedTypeTracker.
    return visitTypeAnnotation(node);
  }

  @override
  DecoratedType? visitSetOrMapLiteral(SetOrMapLiteral node) {
    var typeArguments = node.typeArguments;
    if (typeArguments != null) {
      var arguments = typeArguments.arguments;
      if (arguments.length == 2) {
        _pushNullabilityNodeTarget(NullabilityNodeTarget.text('map key type'),
            () => arguments[0].accept(this));
        _pushNullabilityNodeTarget(NullabilityNodeTarget.text('map value type'),
            () => arguments[1].accept(this));
      } else {
        _pushNullabilityNodeTarget(
            NullabilityNodeTarget.text('set element type'),
            () => typeArguments.accept(this));
      }
    }
    node.elements.accept(this);
    return null;
  }

  @override
  DecoratedType? visitSimpleFormalParameter(SimpleFormalParameter node) {
    return _handleFormalParameter(node, node.type, null, null);
  }

  @override
  DecoratedType visitTypeAnnotation(TypeAnnotation node) {
    var type = node.type!;
    var target = safeTarget.withCodeRef(node);
    if (type is VoidType || type is DynamicType) {
      var nullabilityNode = NullabilityNode.forTypeAnnotation(target);
      var decoratedType = DecoratedType(type, nullabilityNode);
      _variables.recordDecoratedTypeAnnotation(source, node, decoratedType);
      if (_visitingExternalDeclaration) {
        _graph.makeNullableUnion(
            nullabilityNode, ExternalDynamicOrigin(source, node));
      }
      return decoratedType;
    }
    var typeArguments = const <DecoratedType>[];
    DecoratedType? decoratedReturnType;
    List<DecoratedType> positionalParameters = const <DecoratedType>[];
    Map<String, DecoratedType> namedParameters =
        const <String, DecoratedType>{};
    if (type is InterfaceType && type.element.typeParameters.isNotEmpty) {
      if (node is NamedType) {
        if (node.typeArguments == null) {
          int index = 0;
          typeArguments = type.typeArguments
              .map((t) => DecoratedType.forImplicitType(
                  _typeProvider, t, _graph, target.typeArgument(index++)))
              .toList();
          instrumentation?.implicitTypeArguments(source, node, typeArguments);
        } else {
          int index = 0;
          typeArguments = node.typeArguments!.arguments
              .map((t) => _pushNullabilityNodeTarget(
                  target.typeArgument(index++), () => t.accept(this)!))
              .toList();
        }
      } else {
        assert(false); // TODO(paulberry): is this possible?
      }
    }
    if (node is GenericFunctionType) {
      var returnType = node.returnType;
      if (returnType == null) {
        decoratedReturnType = DecoratedType.forImplicitType(_typeProvider,
            DynamicTypeImpl.instance, _graph, target.returnType());
        instrumentation?.implicitReturnType(source, node, decoratedReturnType);
      } else {
        // If [_target] is non-null, then it represents the return type for
        // a FunctionTypeAlias. Otherwise, create a return type target for
        // `target`.
        _pushNullabilityNodeTarget(target.returnType(), () {
          decoratedReturnType = returnType.accept(this);
        });
      }
      positionalParameters = <DecoratedType>[];
      namedParameters = <String, DecoratedType>{};
      var previousPositionalParameters = _positionalParameters;
      var previousNamedParameters = _namedParameters;
      try {
        _positionalParameters = positionalParameters;
        _namedParameters = namedParameters;
        node.typeParameters?.accept(this);
        node.parameters.accept(this);
      } finally {
        _positionalParameters = previousPositionalParameters;
        _namedParameters = previousNamedParameters;
      }
    }
    NullabilityNode nullabilityNode;
    if (typeIsNonNullableByContext(node)) {
      nullabilityNode = _graph.never;
    } else {
      nullabilityNode = NullabilityNode.forTypeAnnotation(target);
      nullabilityNode.hintActions
        ..[HintActionKind.addNullableHint] = {
          node.end: [AtomicEdit.insert('/*?*/')]
        }
        ..[HintActionKind.addNonNullableHint] = {
          node.end: [AtomicEdit.insert('/*!*/')]
        };
    }
    DecoratedType decoratedType;
    if (type is FunctionType && node is! GenericFunctionType) {
      (node as NamedType).typeArguments?.accept(this);
      // node is a reference to a typedef.  Treat it like an inferred type (we
      // synthesize new nodes for it).  These nodes will be unioned with the
      // typedef nodes by the edge builder.
      decoratedType = DecoratedType.forImplicitFunction(
          _typeProvider, type, nullabilityNode, _graph, target);
    } else {
      decoratedType = DecoratedType(type, nullabilityNode,
          typeArguments: typeArguments,
          returnType: decoratedReturnType,
          positionalParameters: positionalParameters,
          namedParameters: namedParameters);
    }
    _variables.recordDecoratedTypeAnnotation(source, node, decoratedType);
    _handleNullabilityHint(node, decoratedType);
    return decoratedType;
  }

  @override
  DecoratedType? visitTypeParameter(TypeParameter node) {
    var element = node.declaredElement!;
    var bound = node.bound;
    DecoratedType? decoratedBound;
    var target = NullabilityNodeTarget.typeParameterBound(element);
    if (bound != null) {
      decoratedBound =
          _pushNullabilityNodeTarget(target, () => bound.accept(this));
    } else {
      var nullabilityNode = NullabilityNode.forInferredType(target);
      decoratedBound = DecoratedType(_typeProvider.objectType, nullabilityNode);
      _graph.connect(_graph.always, nullabilityNode,
          AlwaysNullableTypeOrigin.forElement(element, false));
    }
    DecoratedTypeParameterBounds.current!.put(element, decoratedBound);
    return null;
  }

  @override
  DecoratedType? visitVariableDeclarationList(VariableDeclarationList node) {
    node.metadata.accept(this);
    var typeAnnotation = node.type;
    var declaredType = _pushNullabilityNodeTarget(
        NullabilityNodeTarget.element(node.variables.first.declaredElement!),
        () => typeAnnotation?.accept(this));
    var hint = getPrefixHint(node.firstTokenAfterCommentAndMetadata);
    if (hint != null && hint.kind == HintCommentKind.late_) {
      _variables.recordLateHint(source, node, hint);
    }
    if (hint != null && hint.kind == HintCommentKind.lateFinal) {
      _variables.recordLateHint(source, node, hint);
    }
    var parent = node.parent;
    for (var variable in node.variables) {
      variable.metadata.accept(this);
      var declaredElement = variable.declaredElement;
      var type = declaredType;
      if (type == null) {
        var target = NullabilityNodeTarget.element(declaredElement!);
        type = DecoratedType.forImplicitType(
            _typeProvider, declaredElement.type, _graph, target);
        instrumentation?.implicitType(source, node, type);
      }
      _variables.recordDecoratedElementType(declaredElement, type);
      variable.initializer?.accept(this);
      if (parent is FieldDeclaration) {
        var angularAnnotation = _getAngularAnnotation(parent.metadata);
        if (angularAnnotation != null) {
          switch (angularAnnotation) {
            case _AngularAnnotation.child:
              _graph.makeNullable(
                  type.node, AngularAnnotationOrigin(source, node));
              break;
            case _AngularAnnotation.children:
              _graph.preventLate(
                  type.node, AngularAnnotationOrigin(source, node));
              break;
          }
        }
      }
    }
    return null;
  }

  DecoratedType _createDecoratedTypeForClass(
      InterfaceElement classElement, AstNode? node) {
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

  /// Determines if the given [metadata] contains a reference to one of the
  /// Angular annotations that we have special behaviors for.  If it does,
  /// returns an enumerated value describing the type of annotation.
  _AngularAnnotation? _getAngularAnnotation(NodeList<Annotation> metadata) {
    for (var annotation in metadata) {
      var element = annotation.element;
      if (element is ConstructorElement) {
        var name = element.enclosingElement.name;
        if (_isAngularUri(element.librarySource.uri)) {
          if (name == 'ViewChild' || name == 'ContentChild') {
            return _AngularAnnotation.child;
          } else if (name == 'ViewChildren' || name == 'ContentChildren') {
            return _AngularAnnotation.children;
          }
        }
      }
    }
    return null;
  }

  /// Common handling of function and method declarations.
  DecoratedType _handleExecutableDeclaration(
      AstNode node,
      ExecutableElement declaredElement,
      NodeList<Annotation>? metadata,
      TypeAnnotation? returnType,
      TypeParameterList? typeParameters,
      FormalParameterList? parameters,
      NodeList<ConstructorInitializer>? initializers,
      FunctionBody body,
      ConstructorName? redirectedConstructor,
      {required bool isExternal}) {
    metadata?.accept(this);
    var previouslyVisitingExternalDeclaration = _visitingExternalDeclaration;
    try {
      if (isExternal) {
        _visitingExternalDeclaration = true;
      }
      var functionType = declaredElement.type;
      DecoratedType? decoratedReturnType;
      var target = NullabilityNodeTarget.element(declaredElement);
      if (returnType != null) {
        _pushNullabilityNodeTarget(target.returnType(), () {
          decoratedReturnType = returnType.accept(this);
        });
      } else if (declaredElement is ConstructorElement) {
        // Constructors have no explicit return type annotation, so use the
        // implicit return type.
        decoratedReturnType = _createDecoratedTypeForClass(
            declaredElement.enclosingElement, parameters!.parent);
        instrumentation?.implicitReturnType(source, node, decoratedReturnType);
      } else {
        // If the function expression just throws, analyzer will infer `Null`
        // return type is legacy mode. This causes unnecessary casts at the
        // fix generation phase. So change it back to `Never`.
        if (body is ExpressionFunctionBody &&
            body.expression is ThrowExpression &&
            functionType.returnType == _typeProvider.nullType) {
          functionType = FunctionTypeImpl(
              typeFormals: functionType.typeFormals,
              parameters: functionType.parameters,
              returnType: _typeProvider.neverType,
              nullabilitySuffix: functionType.nullabilitySuffix);
        }
        // Inferred return type.
        decoratedReturnType = DecoratedType.forImplicitType(
            _typeProvider, functionType.returnType, _graph, target);
        instrumentation?.implicitReturnType(source, node, decoratedReturnType);
        if (isExternal && functionType.returnType is DynamicType) {
          _graph.makeNullableUnion(
              decoratedReturnType.node, ExternalDynamicOrigin(source, node));
        }
      }
      var previousPositionalParameters = _positionalParameters;
      var previousNamedParameters = _namedParameters;
      _positionalParameters = [];
      _namedParameters = {};
      DecoratedType decoratedFunctionType;
      try {
        typeParameters?.accept(this);
        _pushNullabilityNodeTarget(target, () => parameters?.accept(this));
        redirectedConstructor?.accept(this);
        initializers?.accept(this);
        decoratedFunctionType = DecoratedType(functionType, _graph.never,
            returnType: decoratedReturnType,
            positionalParameters: _positionalParameters,
            namedParameters: _namedParameters);
        body.accept(this);
      } finally {
        _positionalParameters = previousPositionalParameters;
        _namedParameters = previousNamedParameters;
      }
      _variables.recordDecoratedElementType(
          declaredElement, decoratedFunctionType);
      return decoratedFunctionType;
    } finally {
      _visitingExternalDeclaration = previouslyVisitingExternalDeclaration;
    }
  }

  DecoratedType? _handleFormalParameter(
      FormalParameter node,
      TypeAnnotation? type,
      TypeParameterList? typeParameters,
      FormalParameterList? parameters) {
    var declaredElement = node.declaredElement!;
    node.metadata.accept(this);
    DecoratedType? decoratedType;
    var target = safeTarget;
    if (parameters == null) {
      if (type != null) {
        decoratedType = type.accept(this);
      } else {
        decoratedType = DecoratedType.forImplicitType(
            _typeProvider, declaredElement.type, _graph, target);
        if (_visitingExternalDeclaration) {
          _graph.makeNullableUnion(
              decoratedType.node, ExternalDynamicOrigin(source, node));
        }
        instrumentation?.implicitType(source, node, decoratedType);
      }
    } else {
      DecoratedType? decoratedReturnType;
      if (type == null) {
        decoratedReturnType = DecoratedType.forImplicitType(_typeProvider,
            DynamicTypeImpl.instance, _graph, target.returnType());
        instrumentation?.implicitReturnType(source, node, decoratedReturnType);
        if (_visitingExternalDeclaration) {
          _graph.makeNullableUnion(
              decoratedReturnType.node, ExternalDynamicOrigin(source, node));
        }
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
      final nullabilityNode = NullabilityNode.forTypeAnnotation(target);
      decoratedType = DecoratedType(declaredElement.type, nullabilityNode,
          returnType: decoratedReturnType,
          positionalParameters: positionalParameters,
          namedParameters: namedParameters);
      _handleNullabilityHint(node, decoratedType);
    }
    _variables.recordDecoratedElementType(declaredElement, decoratedType);
    var isAnnotated = false;
    for (var annotation in node.metadata) {
      var element = annotation.element;
      if (_isAngularConstructor(element, 'Optional') ||
          _isAngularConstructor(element, 'Attribute')) {
        isAnnotated = true;
        if (_isAngularConstructor(element, 'Optional') ||
            _isInsideAngularComponent) {
          _graph.makeNullable(
              decoratedType!.node, AngularAnnotationOrigin(source, node));
        }
      }
    }
    final enclosingElement = declaredElement.enclosingElement;
    if ((enclosingElement is ConstructorElement &&
                (_isInsideAngularComponent || _isInjectable) ||
            (enclosingElement is FunctionElement) &&
                _hasInjectable(enclosingElement)) &&
        !isAnnotated) {
      _graph.makeNonNullable(
          decoratedType!.node, AngularConstructorArgumentOrigin(source, node));
    }

    if (declaredElement.isNamed) {
      _namedParameters![declaredElement.name] = decoratedType!;
    } else {
      _positionalParameters!.add(decoratedType!);
    }
    return decoratedType;
  }

  /// Nullability hints can be added to [TypeAnnotation]s,
  /// [FunctionTypedFormalParameter]s, and function-typed
  /// [FieldFormalParameter]s.
  void _handleNullabilityHint(AstNode node, DecoratedType decoratedType) {
    assert(node is TypeAnnotation ||
        node is FunctionTypedFormalParameter ||
        (node is FieldFormalParameter && node.parameters != null));
    var hint = getPostfixHint(node.endToken);
    if (hint != null) {
      switch (hint.kind) {
        case HintCommentKind.bang:
          _graph.makeNonNullableUnion(decoratedType.node,
              NullabilityCommentOrigin(source, node, false));
          _variables.recordNullabilityHint(source, node, hint);
          decoratedType.node.hintActions[HintActionKind.removeNonNullableHint] =
              hint.changesToRemove(source!.contents.data);
          decoratedType.node.hintActions[HintActionKind.changeToNullableHint] =
              hint.changesToReplace(source!.contents.data, '/*?*/');
          break;
        case HintCommentKind.question:
          _graph.makeNullableUnion(
              decoratedType.node, NullabilityCommentOrigin(source, node, true));
          _variables.recordNullabilityHint(source, node, hint);
          decoratedType.node.hintActions[HintActionKind.removeNullableHint] =
              hint.changesToRemove(source!.contents.data);
          decoratedType
                  .node.hintActions[HintActionKind.changeToNonNullableHint] =
              hint.changesToReplace(source!.contents.data, '/*!*/');
          break;
        default:
          break;
      }

      decoratedType.node.hintActions
        ..remove(HintActionKind.addNonNullableHint)
        ..remove(HintActionKind.addNullableHint);
    }
  }

  void _handleSupertypeClauses(
      NamedCompilationUnitMember astNode,
      InterfaceElement declaredElement,
      NamedType? superclass,
      WithClause? withClause,
      ImplementsClause? implementsClause,
      OnClause? onClause) {
    var supertypes = <NamedType?>[];
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
    var decoratedSupertypes = <InterfaceElement, DecoratedType?>{};
    _pushNullabilityNodeTarget(
        NullabilityNodeTarget.element(declaredElement).supertype, () {
      for (var supertype in supertypes) {
        DecoratedType? decoratedSupertype;
        if (supertype == null) {
          var nullabilityNode =
              NullabilityNode.forInferredType(_target!.withCodeRef(astNode));
          _graph.makeNonNullableUnion(
              nullabilityNode, NonNullableObjectSuperclass(source, astNode));
          decoratedSupertype =
              DecoratedType(_typeProvider.objectType, nullabilityNode);
        } else {
          decoratedSupertype = supertype.accept(this);
        }
        var class_ = (decoratedSupertype!.type as InterfaceType).element;
        decoratedSupertypes[class_] = decoratedSupertype;
      }
    });
    _variables.recordDecoratedDirectSupertypes(
        declaredElement, decoratedSupertypes);
  }

  bool _hasInjectable(Element element) => element.metadata
      .any((ann) => _isAngularConstructor(ann.element, 'Injectable'));

  /// Determines whether [element] is a constructor named [name] from Angular
  /// package.
  bool _isAngularConstructor(Element? element, String name) =>
      element is ConstructorElement &&
      element.enclosingElement.name == name &&
      _isAngularUri(element.librarySource.uri);

  /// Determines whether the given [uri] comes from the Angular package.
  bool _isAngularUri(Uri uri) {
    if (!uri.isScheme('package')) return false;
    var packageName = uri.pathSegments[0];
    if (packageName == 'angular') return true;
    if (packageName == 'third_party.dart_src.angular.angular') {
      // This name is used for angular development internally at Google.
      return true;
    }
    return false;
  }

  T _pushNullabilityNodeTarget<T>(
      NullabilityNodeTarget target, T Function() fn) {
    NullabilityNodeTarget? previousTarget = _target;
    try {
      _target = target;
      return fn();
    } finally {
      _target = previousTarget;
    }
  }

  Never _unimplemented(AstNode node, String message) {
    CompilationUnit unit = node.root as CompilationUnit;
    StringBuffer buffer = StringBuffer();
    buffer.write(message);
    buffer.write(' in "');
    buffer.write(node.toSource());
    buffer.write('" on line ');
    buffer.write(unit.lineInfo.getLocation(node.offset).lineNumber);
    buffer.write(' of "');
    buffer.write(unit.declaredElement!.source.fullName);
    buffer.write('"');
    throw UnimplementedError(buffer.toString());
  }
}

/// Enum describing the kinds of annotations supplied by the angular package for
/// which we have special migration behaviors.
enum _AngularAnnotation {
  /// Either the `@ViewChild` or `@ContentChild` annotation.  Fields with these
  /// annotations should always be nullable and should never be late.
  child,

  /// Either the `@ViewChildren` or `@ContentChildren` annotation.  Fields with
  /// these annotations should never be late.
  children,
}
