// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/generated/migration.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:nnbd_migration/src/decorated_class_hierarchy.dart';
import 'package:nnbd_migration/src/fix_aggregator.dart';
import 'package:nnbd_migration/src/variables.dart';

/// Problem reported by [FixBuilder] when encountering a compound assignment
/// for which the combination result is nullable.  This occurs if the compound
/// assignment resolves to a user-defined operator that returns a nullable type,
/// but the target of the assignment expects a non-nullable type.  We need to
/// add a null check but it's nontrivial to do so because we would have to
/// rewrite the assignment as an ordinary assignment (e.g. change `x += y` to
/// `x = (x + y)!`), but that might change semantics by causing subexpressions
/// of the target to be evaluated twice.
///
/// TODO(paulberry): consider alternatives.
/// See https://github.com/dart-lang/sdk/issues/38675.
class CompoundAssignmentCombinedNullable implements Problem {
  const CompoundAssignmentCombinedNullable();
}

/// Problem reported by [FixBuilder] when encountering a compound assignment
/// for which the value read from the target of the assignment has a nullable
/// type.  We need to add a null check but it's nontrivial to do so because we
/// would have to rewrite the assignment as an ordinary assignment (e.g. change
/// `x += y` to `x = x! + y`), but that might change semantics by causing
/// subexpressions of the target to be evaluated twice.
///
/// TODO(paulberry): consider alternatives.
/// See https://github.com/dart-lang/sdk/issues/38676.
class CompoundAssignmentReadNullable implements Problem {
  const CompoundAssignmentReadNullable();
}

/// This class runs the analyzer's resolver over the code being migrated, after
/// graph propagation, to figure out what changes need to be made.  It doesn't
/// actually make the changes; it simply reports what changes are necessary
/// through abstract methods.
class FixBuilder {
  /// The type provider providing non-nullable types.
  final TypeProvider typeProvider;

  final Map<AstNode, NodeChange> changes = {};

  final Map<AstNode, Set<Problem>> problems = {};

  /// The NNBD type system.
  final TypeSystemImpl _typeSystem;

  /// Variables for this migration run.
  final Variables _variables;

  /// The file being analyzed.
  final Source source;

  ResolverVisitor _resolver;

  FixBuilder(
      Source source,
      DecoratedClassHierarchy decoratedClassHierarchy,
      TypeProvider typeProvider,
      Dart2TypeSystem typeSystem,
      Variables variables,
      LibraryElement definingLibrary)
      : this._(
            decoratedClassHierarchy,
            _makeNnbdTypeSystem(
                (typeProvider as TypeProviderImpl).asNonNullableByDefault,
                typeSystem),
            variables,
            source,
            definingLibrary);

  FixBuilder._(
      DecoratedClassHierarchy decoratedClassHierarchy,
      this._typeSystem,
      this._variables,
      this.source,
      LibraryElement definingLibrary)
      : typeProvider = _typeSystem.typeProvider {
    // TODO(paulberry): make use of decoratedClassHierarchy
    assert(_typeSystem.isNonNullableByDefault);
    assert((typeProvider as TypeProviderImpl).isNonNullableByDefault);
    var inheritanceManager = InheritanceManager3();
    // TODO(paulberry): is it a bad idea to throw away errors?
    var errorListener = AnalysisErrorListener.NULL_LISTENER;
    // TODO(paulberry): once the feature is no longer experimental, change the
    // way we enable it in the resolver.
    // ignore: invalid_use_of_visible_for_testing_member
    var featureSet = FeatureSet.forTesting(
        sdkVersion: '2.6.0', additionalFeatures: [Feature.non_nullable]);
    _resolver = ResolverVisitorForMigration(
        inheritanceManager,
        definingLibrary,
        source,
        typeProvider,
        errorListener,
        _typeSystem,
        featureSet,
        MigrationResolutionHooksImpl(this));
  }

  /// Visits the entire compilation [unit] using the analyzer's resolver and
  /// makes note of changes that need to be made.
  void visitAll(CompilationUnit unit) {
    unit.accept(_resolver);
    unit.accept(_AdditionalMigrationsVisitor(this));
  }

  /// Called whenever an AST node is found that needs to be changed.
  void _addChange(AstNode node, NodeChange change) {
    assert(!changes.containsKey(node));
    changes[node] = change;
  }

  /// Called whenever an AST node is found that can't be automatically fixed.
  void _addProblem(AstNode node, Problem problem) {
    var newlyAdded = (problems[node] ??= {}).add(problem);
    assert(newlyAdded);
  }

  /// Computes the type that [element] will have after migration.
  ///
  /// If [targetType] is present, and [element] is a class member, it is the
  /// type of the class within which [element] is being accessed; this is used
  /// to perform the correct substitutions.
  DartType _computeMigratedType(Element element) {
    element = element.declaration;
    if (element is ClassElement || element is TypeParameterElement) {
      return typeProvider.typeType;
    } else if (element is PropertyAccessorElement && element.isSynthetic) {
      var variableType = _variables
          .decoratedElementType(element.variable)
          .toFinalType(typeProvider);
      if (element.isSetter) {
        return FunctionTypeImpl(
            returnType: typeProvider.voidType,
            typeFormals: [],
            parameters: [
              ParameterElementImpl.synthetic(
                  'value', variableType, ParameterKind.REQUIRED)
            ],
            nullabilitySuffix: NullabilitySuffix.none);
      } else {
        return FunctionTypeImpl(
            returnType: variableType,
            typeFormals: [],
            parameters: [],
            nullabilitySuffix: NullabilitySuffix.none);
      }
    } else {
      return _variables.decoratedElementType(element).toFinalType(typeProvider);
    }
  }

  static TypeSystemImpl _makeNnbdTypeSystem(
      TypeProvider nnbdTypeProvider, Dart2TypeSystem typeSystem) {
    // TODO(paulberry): do we need to test both possible values of
    // strictInference?
    return TypeSystemImpl(
        implicitCasts: typeSystem.implicitCasts,
        isNonNullableByDefault: true,
        strictInference: typeSystem.strictInference,
        typeProvider: nnbdTypeProvider);
  }
}

/// Implementation of [MigrationResolutionHooks] that interfaces with
/// [FixBuilder].
class MigrationResolutionHooksImpl implements MigrationResolutionHooks {
  final FixBuilder _fixBuilder;

  final Expando<List<CollectionElement>> _collectionElements = Expando();

  final Set<TypeAnnotation> _fixedTypeAnnotations = {};

  FlowAnalysis<AstNode, Statement, Expression, PromotableElement, DartType>
      _flowAnalysis;

  MigrationResolutionHooksImpl(this._fixBuilder);

  @override
  bool getConditionalKnownValue(AstNode node) {
    // TODO(paulberry): handle conditional expressions.
    var conditionalDiscard =
        _fixBuilder._variables.getConditionalDiscard(_fixBuilder.source, node);
    if (conditionalDiscard == null) {
      return null;
    } else {
      if (conditionalDiscard.keepTrue && conditionalDiscard.keepFalse) {
        return null;
      }
      var conditionValue = conditionalDiscard.keepTrue;
      _fixBuilder._addChange(node, EliminateDeadIf(conditionValue));
      return conditionValue;
    }
  }

  @override
  List<ParameterElement> getExecutableParameters(ExecutableElement element) =>
      getExecutableType(element).parameters;

  @override
  DartType getExecutableReturnType(FunctionTypedElement element) =>
      getExecutableType(element).returnType;

  @override
  FunctionType getExecutableType(FunctionTypedElement element) {
    var type = _fixBuilder._computeMigratedType(element);
    Element baseElement = element;
    if (baseElement is Member) {
      type = baseElement.substitution.substituteType(type);
    }
    return type as FunctionType;
  }

  @override
  DartType getFieldType(FieldElement element) {
    assert(!element.isSynthetic);
    return _fixBuilder._computeMigratedType(element);
  }

  @override
  List<CollectionElement> getListElements(ListLiteral node) {
    return _collectionElements[node] ??=
        _transformCollectionElements(node.elements, node.typeArguments);
  }

  @override
  List<TypeAnnotation> getListTypeArguments(ListLiteral node) {
    _fixTypeArguments(node.typeArguments);
    return node.typeArguments?.arguments;
  }

  @override
  DartType getMigratedTypeAnnotationType(TypeAnnotation node) {
    _fixTypeAnnotation(node);
    return node.type;
  }

  @override
  List<CollectionElement> getSetOrMapElements(SetOrMapLiteral node) {
    return _collectionElements[node] ??=
        _transformCollectionElements(node.elements, node.typeArguments);
  }

  @override
  List<TypeAnnotation> getSetOrMapTypeArguments(SetOrMapLiteral node) {
    _fixTypeArguments(node.typeArguments);
    return node.typeArguments?.arguments;
  }

  @override
  DartType getVariableType(VariableElement variable) {
    if (variable.library == null) {
      // This is a synthetic variable created during resolution (e.g. a
      // parameter of a function type), so the type it currently has is the
      // correct post-migration type.
      return variable.type;
    }
    return _fixBuilder._computeMigratedType(variable);
  }

  @override
  DartType modifyExpressionType(Expression node, DartType type) {
    if (type.isDynamic) return type;
    if (!_fixBuilder._typeSystem.isNullable(type)) return type;
    var ancestor = _findNullabilityContextAncestor(node);
    if (_needsNullCheckDueToStructure(ancestor)) {
      return _addNullCheck(node, type);
    }
    var context =
        InferenceContext.getContext(ancestor) ?? DynamicTypeImpl.instance;
    if (!_fixBuilder._typeSystem.isNullable(context)) {
      return _addNullCheck(node, type);
    }
    return type;
  }

  @override
  void setFlowAnalysis(
      FlowAnalysis<AstNode, Statement, Expression, PromotableElement, DartType>
          flowAnalysis) {
    _flowAnalysis = flowAnalysis;
  }

  DartType _addNullCheck(Expression node, DartType type) {
    _fixBuilder._addChange(node, NullCheck());
    _flowAnalysis.nonNullAssert_end(node);
    return _fixBuilder._typeSystem.promoteToNonNull(type as TypeImpl);
  }

  Expression _findNullabilityContextAncestor(Expression node) {
    while (true) {
      var parent = node.parent;
      if (parent is BinaryExpression &&
          parent.operator.type == TokenType.QUESTION_QUESTION &&
          identical(node, parent.rightOperand)) {
        node = parent;
        continue;
      }
      return node;
    }
  }

  void _fixTypeAnnotation(TypeAnnotation node) {
    if (!_fixedTypeAnnotations.add(node)) return;
    var decoratedType = _fixBuilder._variables
        .decoratedTypeAnnotation(_fixBuilder.source, node);
    var type = decoratedType.type;
    if (!type.isDynamic && !type.isVoid && decoratedType.node.isNullable) {
      var decoratedType = _fixBuilder._variables
          .decoratedTypeAnnotation(_fixBuilder.source, node);
      _fixBuilder._addChange(node, MakeNullable(decoratedType));
    }
    if (node is TypeNameImpl) {
      var typeArguments = node.typeArguments;
      _fixTypeArguments(typeArguments);
      node.type = decoratedType.toFinalType(_fixBuilder.typeProvider);
    } else if (node is GenericFunctionTypeImpl) {
      // TODO(paulberry): handle type parameter bounds that need to be made
      // nullable.
      node.type = decoratedType.toFinalType(_fixBuilder.typeProvider);
    } else {
      throw StateError(
          'Unrecognized type annotation type: ${node.runtimeType}');
    }
  }

  void _fixTypeArguments(TypeArgumentList typeArguments) {
    if (typeArguments != null) {
      for (var arg in typeArguments.arguments) {
        _fixTypeAnnotation(arg);
      }
    }
  }

  bool _needsNullCheckDueToStructure(Expression node) {
    var parent = node.parent;
    if (parent is BinaryExpression) {
      if (identical(node, parent.leftOperand)) {
        var operatorType = parent.operator.type;
        if (operatorType == TokenType.QUESTION_QUESTION ||
            operatorType == TokenType.EQ_EQ ||
            operatorType == TokenType.BANG_EQ) {
          return false;
        } else {
          return true;
        }
      }
    } else if (parent is PrefixedIdentifier) {
      // TODO(paulberry): ok for toString etc. if the shape is correct
      return identical(node, parent.prefix);
    } else if (parent is PropertyAccess) {
      // TODO(paulberry): what about cascaded?
      // TODO(paulberry): ok for toString etc. if the shape is correct
      return parent.operator.type == TokenType.PERIOD &&
          identical(node, parent.target);
    } else if (parent is MethodInvocation) {
      // TODO(paulberry): what about cascaded?
      // TODO(paulberry): ok for toString etc. if the shape is correct
      return parent.operator.type == TokenType.PERIOD &&
          identical(node, parent.target);
    } else if (parent is IndexExpression) {
      return identical(node, parent.target);
    } else if (parent is ConditionalExpression) {
      return identical(node, parent.condition);
    } else if (parent is FunctionExpressionInvocation) {
      return identical(node, parent.function);
    } else if (parent is PrefixExpression) {
      // TODO(paulberry): for prefix increment/decrement, inserting a null check
      // isn't sufficient.
      return true;
    } else if (parent is ThrowExpression) {
      return true;
    }
    return false;
  }

  CollectionElement _transformCollectionElement(CollectionElement node) {
    while (node is IfElement) {
      var conditionalDiscard = _fixBuilder._variables
          .getConditionalDiscard(_fixBuilder.source, node);
      if (conditionalDiscard == null ||
          conditionalDiscard.keepTrue && conditionalDiscard.keepFalse) {
        return node;
      }
      var conditionValue = conditionalDiscard.keepTrue;
      var ifElement = node as IfElement;
      node = conditionValue ? ifElement.thenElement : ifElement.elseElement;
    }
    return node;
  }

  List<CollectionElement> _transformCollectionElements(
      NodeList<CollectionElement> elements, TypeArgumentList typeArguments) {
    _fixTypeArguments(typeArguments);
    return elements
        .map(_transformCollectionElement)
        .where((e) => e != null)
        .toList();
  }
}

/// Problem reported by [FixBuilder] when encountering a non-nullable unnamed
/// optional parameter that lacks a default value.
class NonNullableUnnamedOptionalParameter implements Problem {
  const NonNullableUnnamedOptionalParameter();
}

/// Common supertype for problems reported by [FixBuilder._addProblem].
abstract class Problem {}

/// Visitor that computes additional migrations on behalf of [FixBuilder] that
/// don't need to be integrated into the resolver itself.
class _AdditionalMigrationsVisitor extends RecursiveAstVisitor<void> {
  final FixBuilder _fixBuilder;

  _AdditionalMigrationsVisitor(this._fixBuilder);

  @override
  void visitDefaultFormalParameter(DefaultFormalParameter node) {
    var element = node.declaredElement;
    if (node.defaultValue == null &&
        !_fixBuilder._variables.decoratedElementType(element).node.isNullable) {
      if (element.isNamed) {
        _fixBuilder._addChange(node, const AddRequiredKeyword());
      } else {
        _fixBuilder._addProblem(
            node, const NonNullableUnnamedOptionalParameter());
      }
    }
  }
}
