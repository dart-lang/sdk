// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This file declares a "shadow hierarchy" of concrete classes which extend
/// the kernel class hierarchy, adding methods and fields needed by the
/// BodyBuilder.
///
/// Instances of these classes may be created using the factory methods in
/// `ast_factory.dart`.
///
/// Note that these classes represent the Dart language prior to desugaring.
/// When a single Dart construct desugars to a tree containing multiple kernel
/// AST nodes, the shadow class extends the kernel object at the top of the
/// desugared tree.
///
/// This means that in some cases multiple shadow classes may extend the same
/// kernel class, because multiple constructs in Dart may desugar to a tree
/// with the same kind of root node.

// ignore: UNDEFINED_HIDDEN_NAME
import 'dart:core' hide MapEntry;

import 'package:front_end/src/base/instrumentation.dart';
import 'package:front_end/src/fasta/fasta_codes.dart';
import 'package:front_end/src/fasta/kernel/body_builder.dart';
import 'package:front_end/src/fasta/kernel/fasta_accessors.dart';
import 'package:front_end/src/fasta/source/source_class_builder.dart';
import 'package:front_end/src/fasta/source/source_library_builder.dart';
import 'package:front_end/src/fasta/type_inference/interface_resolver.dart';
import 'package:front_end/src/fasta/type_inference/type_inference_engine.dart';
import 'package:front_end/src/fasta/type_inference/type_inference_listener.dart';
import 'package:front_end/src/fasta/type_inference/type_inferrer.dart';
import 'package:front_end/src/fasta/type_inference/type_promotion.dart';
import 'package:front_end/src/fasta/type_inference/type_schema.dart';
import 'package:front_end/src/fasta/type_inference/type_schema_elimination.dart';
import 'package:front_end/src/fasta/type_inference/type_schema_environment.dart';
import 'package:kernel/ast.dart' hide InvalidExpression, InvalidInitializer;
import 'package:kernel/frontend/accessors.dart';
import 'package:kernel/type_algebra.dart';

import '../problems.dart' show unhandled, unsupported;

/// Indicates whether type inference involving conditional expressions should
/// always use least upper bound.
///
/// A value of `true` matches the behavior of analyzer.  A value of `false`
/// matches the informal specification in
/// https://github.com/dart-lang/sdk/pull/29371.
///
/// TODO(paulberry): once compatibility with analyzer is no longer needed,
/// change this to `false`.
const bool _forceLub = true;

/// Computes the return type of a (possibly factory) constructor.
InterfaceType computeConstructorReturnType(Member constructor) {
  if (constructor is Constructor) {
    return constructor.enclosingClass.thisType;
  } else {
    return constructor.function.returnType;
  }
}

List<DartType> getExplicitTypeArguments(Arguments arguments) {
  if (arguments is ShadowArguments) {
    return arguments._hasExplicitTypeArguments ? arguments.types : null;
  } else {
    // This code path should only be taken in situations where there are no
    // type arguments at all, e.g. calling a user-definable operator.
    assert(arguments.types.isEmpty);
    return null;
  }
}

/// Information associated with a class during type inference.
class ClassInferenceInfo {
  /// The builder associated with this class.
  final SourceClassBuilder builder;

  /// The visitor for determining if a given type makes covariant use of one of
  /// the class's generic parameters, and therefore requires covariant checks.
  IncludesTypeParametersCovariantly needsCheckVisitor;

  /// Getters and methods in the class's API.  May include forwarding nodes.
  final gettersAndMethods = <Member>[];

  /// Setters in the class's API.  May include forwarding nodes.
  final setters = <Member>[];

  ClassInferenceInfo(this.builder);
}

/// Concrete shadow object representing a set of invocation arguments.
class ShadowArguments extends Arguments {
  bool _hasExplicitTypeArguments;

  ShadowArguments(List<Expression> positional,
      {List<DartType> types, List<NamedExpression> named})
      : _hasExplicitTypeArguments = types != null && types.isNotEmpty,
        super(positional, types: types, named: named);

  static void setExplicitArgumentTypes(
      ShadowArguments arguments, List<DartType> types) {
    arguments.types.clear();
    arguments.types.addAll(types);
    arguments._hasExplicitTypeArguments = true;
  }
}

/// Shadow object for [AsExpression].
class ShadowAsExpression extends AsExpression implements ShadowExpression {
  ShadowAsExpression(Expression operand, DartType type) : super(operand, type);

  @override
  DartType _inferExpression(ShadowTypeInferrer inferrer, DartType typeContext) {
    inferrer.listener.asExpressionEnter(this, typeContext);
    inferrer.inferExpression(operand, null, false);
    var inferredType = type;
    inferrer.listener.asExpressionExit(this, inferredType);
    return inferredType;
  }
}

/// Concrete shadow object representing an assert initializer in kernel form.
class ShadowAssertInitializer extends AssertInitializer
    implements ShadowInitializer {
  ShadowAssertInitializer(AssertStatement statement) : super(statement);

  @override
  void _inferInitializer(ShadowTypeInferrer inferrer) {
    inferrer.listener.assertInitializerEnter(this);
    inferrer.inferStatement(statement);
    inferrer.listener.assertInitializerExit(this);
  }
}

/// Concrete shadow object representing an assertion statement in kernel form.
class ShadowAssertStatement extends AssertStatement implements ShadowStatement {
  ShadowAssertStatement(Expression condition,
      {Expression message, int conditionStartOffset, int conditionEndOffset})
      : super(condition,
            message: message,
            conditionStartOffset: conditionStartOffset,
            conditionEndOffset: conditionEndOffset);

  @override
  void _inferStatement(ShadowTypeInferrer inferrer) {
    inferrer.listener.assertStatementEnter(this);
    var expectedType = inferrer.coreTypes.boolClass.rawType;
    var actualType =
        inferrer.inferExpression(condition, expectedType, !inferrer.isTopLevel);
    inferrer.checkAssignability(
        expectedType, actualType, condition, condition.fileOffset);
    if (message != null) {
      inferrer.inferExpression(message, null, false);
    }
    inferrer.listener.assertStatementExit(this);
  }
}

/// Shadow object for [AwaitExpression].
class ShadowAwaitExpression extends AwaitExpression
    implements ShadowExpression {
  ShadowAwaitExpression(Expression operand) : super(operand);

  @override
  DartType _inferExpression(ShadowTypeInferrer inferrer, DartType typeContext) {
    inferrer.listener.awaitExpressionEnter(this, typeContext);
    if (!inferrer.typeSchemaEnvironment.isEmptyContext(typeContext)) {
      typeContext = inferrer.wrapFutureOrType(typeContext);
    }
    var inferredType = inferrer.inferExpression(operand, typeContext, true);
    inferredType = inferrer.typeSchemaEnvironment.unfutureType(inferredType);
    inferrer.listener.awaitExpressionExit(this, inferredType);
    return inferredType;
  }
}

/// Concrete shadow object representing a statement block in kernel form.
class ShadowBlock extends Block implements ShadowStatement {
  ShadowBlock(List<Statement> statements) : super(statements);

  @override
  void _inferStatement(ShadowTypeInferrer inferrer) {
    inferrer.listener.blockEnter(this);
    for (var statement in statements) {
      inferrer.inferStatement(statement);
    }
    inferrer.listener.blockExit(this);
  }
}

/// Concrete shadow object representing a boolean literal in kernel form.
class ShadowBoolLiteral extends BoolLiteral implements ShadowExpression {
  ShadowBoolLiteral(bool value) : super(value);

  @override
  DartType _inferExpression(ShadowTypeInferrer inferrer, DartType typeContext) {
    inferrer.listener.boolLiteralEnter(this, typeContext);
    var inferredType = inferrer.coreTypes.boolClass.rawType;
    inferrer.listener.boolLiteralExit(this, inferredType);
    return inferredType;
  }
}

/// Concrete shadow object representing a break or continue statement in kernel
/// form.
class ShadowBreakStatement extends BreakStatement implements ShadowStatement {
  ShadowBreakStatement(LabeledStatement target) : super(target);

  @override
  void _inferStatement(ShadowTypeInferrer inferrer) {
    inferrer.listener.breakStatementEnter(this);
    // No inference needs to be done.
    inferrer.listener.breakStatementExit(this);
  }
}

/// Concrete shadow object representing a cascade expression.
///
/// A cascade expression of the form `a..b()..c()` is represented as the kernel
/// expression:
///
///     let v = a in
///         let _ = v.b() in
///             let _ = v.c() in
///                 v
///
/// In the documentation that follows, `v` is referred to as the "cascade
/// variable"--this is the variable that remembers the value of the expression
/// preceding the first `..` while the cascades are being evaluated.
///
/// After constructing a [ShadowCascadeExpression], the caller should
/// call [finalize] with an expression representing the expression after the
/// `..`.  If a further `..` follows that expression, the caller should call
/// [extend] followed by [finalize] for each subsequent cascade.
class ShadowCascadeExpression extends Let implements ShadowExpression {
  /// Pointer to the last "let" expression in the cascade.
  Let nextCascade;

  /// Creates a [ShadowCascadeExpression] using [variable] as the cascade
  /// variable.  Caller is responsible for ensuring that [variable]'s
  /// initializer is the expression preceding the first `..` of the cascade
  /// expression.
  ShadowCascadeExpression(ShadowVariableDeclaration variable)
      : super(
            variable,
            makeLet(new VariableDeclaration.forValue(new _UnfinishedCascade()),
                new VariableGet(variable))) {
    nextCascade = body;
  }

  /// Adds a new unfinalized section to the end of the cascade.  Should be
  /// called after the previous cascade section has been finalized.
  void extend() {
    assert(nextCascade.variable.initializer is! _UnfinishedCascade);
    Let newCascade = makeLet(
        new VariableDeclaration.forValue(new _UnfinishedCascade()),
        nextCascade.body);
    nextCascade.body = newCascade;
    newCascade.parent = nextCascade;
    nextCascade = newCascade;
  }

  /// Finalizes the last cascade section with the given [expression].
  void finalize(Expression expression) {
    assert(nextCascade.variable.initializer is _UnfinishedCascade);
    nextCascade.variable.initializer = expression;
    expression.parent = nextCascade.variable;
  }

  @override
  DartType _inferExpression(ShadowTypeInferrer inferrer, DartType typeContext) {
    inferrer.listener.cascadeExpressionEnter(this, typeContext);
    var lhsType =
        inferrer.inferExpression(variable.initializer, typeContext, true);
    if (inferrer.strongMode) {
      variable.type = lhsType;
    }
    Let section = body;
    while (true) {
      inferrer.inferExpression(section.variable.initializer, null, false);
      if (section.body is! Let) break;
      section = section.body;
    }
    inferrer.listener.cascadeExpressionExit(this, lhsType);
    return lhsType;
  }
}

/// Shadow object representing a class in kernel form.
class ShadowClass extends Class {
  ClassInferenceInfo _inferenceInfo;

  ShadowClass(
      {String name,
      Supertype supertype,
      Supertype mixedInType,
      List<TypeParameter> typeParameters,
      List<Supertype> implementedTypes,
      List<Procedure> procedures,
      List<Field> fields})
      : super(
            name: name,
            supertype: supertype,
            mixedInType: mixedInType,
            typeParameters: typeParameters,
            implementedTypes: implementedTypes,
            procedures: procedures,
            fields: fields);

  /// Resolves all forwarding nodes for this class, propagates covariance
  /// annotations, and creates forwarding stubs as needed.
  void finalizeCovariance(InterfaceResolver interfaceResolver) {
    interfaceResolver.finalizeCovariance(
        this, _inferenceInfo.gettersAndMethods);
    interfaceResolver.finalizeCovariance(this, _inferenceInfo.setters);
    interfaceResolver.recordInstrumentation(this);
  }

  /// Creates API members for this class.
  void setupApiMembers(InterfaceResolver interfaceResolver) {
    interfaceResolver.createApiMembers(this, _inferenceInfo.gettersAndMethods,
        _inferenceInfo.setters, _inferenceInfo.builder.library);
  }

  static void clearClassInferenceInfo(ShadowClass class_) {
    class_._inferenceInfo = null;
  }

  static ClassInferenceInfo getClassInferenceInfo(Class class_) {
    if (class_ is ShadowClass) return class_._inferenceInfo;
    return null;
  }

  /// Initializes the class inference information associated with the given
  /// [class_], starting with the fact that it is associated with the given
  /// [builder].
  static void setBuilder(ShadowClass class_, SourceClassBuilder builder) {
    class_._inferenceInfo = new ClassInferenceInfo(builder);
  }
}

/// Abstract shadow object representing a complex assignment in kernel form.
///
/// Since there are many forms a complex assignment might have been desugared
/// to, this class wraps the desugared assignment rather than extending it.
///
/// TODO(paulberry): once we know exactly what constitutes a "complex
/// assignment", document it here.
abstract class ShadowComplexAssignment extends ShadowSyntheticExpression {
  /// In a compound assignment, the expression that reads the old value, or
  /// `null` if this is not a compound assignment.
  Expression read;

  /// The expression appearing on the RHS of the assignment.
  final Expression rhs;

  /// The expression that performs the write (e.g. `a.[]=(b, a.[](b) + 1)` in
  /// `++a[b]`).
  Expression write;

  /// In a compound assignment without shortcut semantics, the expression that
  /// combines the old and new values, or `null` if this is not a compound
  /// assignment.
  ///
  /// Note that in a compound assignment with shortcut semantics, this is not
  /// used; [nullAwareCombiner] is used instead.
  MethodInvocation combiner;

  /// In a compound assignment with shortcut semantics, the conditional
  /// expression that determines whether the assignment occurs.
  ///
  /// Note that in a compound assignment without shortcut semantics, this is not
  /// used; [combiner] is used instead.
  ConditionalExpression nullAwareCombiner;

  /// Indicates whether the expression arose from a post-increment or
  /// post-decrement.
  bool isPostIncDec = false;

  /// Indicates whether the expression arose from a pre-increment or
  /// pre-decrement.
  bool isPreIncDec = false;

  ShadowComplexAssignment(this.rhs) : super(null);

  String toString() {
    var parts = _getToStringParts();
    return '${runtimeType}(${parts.join(', ')})';
  }

  List<String> _getToStringParts() {
    List<String> parts = [];
    if (desugared != null) parts.add('desugared=$desugared');
    if (read != null) parts.add('read=$read');
    if (rhs != null) parts.add('rhs=$rhs');
    if (write != null) parts.add('write=$write');
    if (combiner != null) parts.add('combiner=$combiner');
    if (nullAwareCombiner != null) {
      parts.add('nullAwareCombiner=$nullAwareCombiner');
    }
    if (isPostIncDec) parts.add('isPostIncDec=true');
    if (isPreIncDec) parts.add('isPreIncDec=true');
    return parts;
  }

  DartType _getWriteType(ShadowTypeInferrer inferrer) => unhandled(
      '$runtimeType', 'ShadowComplexAssignment._getWriteType', -1, null);

  _ComplexAssignmentInferenceResult _inferRhs(
      ShadowTypeInferrer inferrer, DartType readType, DartType writeContext) {
    var writeOffset = write == null ? -1 : write.fileOffset;
    Procedure combinerMember;
    DartType combinedType;
    if (combiner != null) {
      bool isOverloadedArithmeticOperator = false;
      combinerMember =
          inferrer.findMethodInvocationMember(readType, combiner, silent: true);
      if (combinerMember is Procedure) {
        isOverloadedArithmeticOperator = inferrer.typeSchemaEnvironment
            .isOverloadedArithmeticOperatorAndType(combinerMember, readType);
      }
      DartType rhsType;
      var combinerType =
          inferrer.getCalleeFunctionType(combinerMember, readType, false);
      if (isPreIncDec || isPostIncDec) {
        rhsType = inferrer.coreTypes.intClass.rawType;
      } else {
        // Analyzer uses a null context for the RHS here.
        // TODO(paulberry): improve on this.
        rhsType = inferrer.inferExpression(rhs, null, true);
        // It's not necessary to call _storeLetType for [rhs] because the RHS
        // is always passed directly to the combiner; it's never stored in a
        // temporary variable first.
        assert(identical(combiner.arguments.positional[0], rhs));
        var expectedType = getPositionalParameterType(combinerType, 0);
        inferrer.checkAssignability(
            expectedType, rhsType, rhs, combiner.fileOffset);
      }
      if (isOverloadedArithmeticOperator) {
        combinedType = inferrer.typeSchemaEnvironment
            .getTypeOfOverloadedArithmetic(readType, rhsType);
      } else {
        combinedType = combinerType.returnType;
      }
      var checkKind = inferrer.preCheckInvocationContravariance(read, readType,
          combinerMember, combiner, combiner.arguments, combiner);
      var replacedCombiner = inferrer.handleInvocationContravariance(
          checkKind,
          combiner,
          combiner.arguments,
          combiner,
          combinedType,
          combinerType,
          combiner.fileOffset);
      var replacedCombiner2 = inferrer.checkAssignability(
          writeContext, combinedType, replacedCombiner, writeOffset);
      if (replacedCombiner2 != null) {
        replacedCombiner = replacedCombiner2;
      }
      _storeLetType(inferrer, replacedCombiner, combinedType);
    } else {
      var rhsType = inferrer.inferExpression(rhs, writeContext, true);
      var replacedRhs =
          inferrer.checkAssignability(writeContext, rhsType, rhs, writeOffset);
      _storeLetType(inferrer, replacedRhs ?? rhs, rhsType);
      if (nullAwareCombiner != null) {
        MethodInvocation equalsInvocation = nullAwareCombiner.condition;
        inferrer.findMethodInvocationMember(writeContext, equalsInvocation,
            silent: true);
        // Note: the case of readType=null only happens for erroneous code.
        combinedType = readType == null
            ? rhsType
            : inferrer.typeSchemaEnvironment
                .getLeastUpperBound(readType, rhsType);
        if (inferrer.strongMode) {
          nullAwareCombiner.staticType = combinedType;
        }
      } else {
        combinedType = rhsType;
      }
    }
    if (this is ShadowIndexAssign) {
      _storeLetType(inferrer, write, const VoidType());
    } else {
      _storeLetType(inferrer, write, combinedType);
    }
    return new _ComplexAssignmentInferenceResult(combinerMember,
        isPostIncDec ? (readType ?? const DynamicType()) : combinedType);
  }
}

/// Abstract shadow object representing a complex assignment involving a
/// receiver.
abstract class ShadowComplexAssignmentWithReceiver
    extends ShadowComplexAssignment {
  /// The receiver of the assignment target (e.g. `a` in `a[b] = c`).
  final Expression receiver;

  /// Indicates whether this assignment uses `super`.
  final bool isSuper;

  ShadowComplexAssignmentWithReceiver(
      this.receiver, Expression rhs, this.isSuper)
      : super(rhs);

  @override
  List<String> _getToStringParts() {
    var parts = super._getToStringParts();
    if (receiver != null) parts.add('receiver=$receiver');
    if (isSuper) parts.add('isSuper=true');
    return parts;
  }

  DartType _inferReceiver(ShadowTypeInferrer inferrer) {
    if (receiver != null) {
      var receiverType = inferrer.inferExpression(receiver, null, true);
      _storeLetType(inferrer, receiver, receiverType);
      return receiverType;
    } else if (isSuper) {
      return inferrer.classHierarchy.getTypeAsInstanceOf(
          inferrer.thisType, inferrer.thisType.classNode.supertype.classNode);
    } else {
      return inferrer.thisType;
    }
  }
}

/// Concrete shadow object representing a conditional expression in kernel form.
/// Shadow object for [ConditionalExpression].
class ShadowConditionalExpression extends ConditionalExpression
    implements ShadowExpression {
  ShadowConditionalExpression(
      Expression condition, Expression then, Expression otherwise)
      : super(condition, then, otherwise, null);

  @override
  DartType _inferExpression(ShadowTypeInferrer inferrer, DartType typeContext) {
    inferrer.listener.conditionalExpressionEnter(this, typeContext);
    var expectedType = inferrer.coreTypes.boolClass.rawType;
    var conditionType =
        inferrer.inferExpression(condition, expectedType, !inferrer.isTopLevel);
    inferrer.checkAssignability(
        expectedType, conditionType, condition, condition.fileOffset);
    DartType thenType = inferrer.inferExpression(then, typeContext, true);
    bool useLub = _forceLub || typeContext == null;
    DartType otherwiseType =
        inferrer.inferExpression(otherwise, typeContext, useLub);
    DartType type = useLub
        ? inferrer.typeSchemaEnvironment
            .getLeastUpperBound(thenType, otherwiseType)
        : greatestClosure(inferrer.coreTypes, typeContext);
    if (inferrer.strongMode) {
      staticType = type;
    }
    var inferredType = type;
    inferrer.listener.conditionalExpressionExit(this, inferredType);
    return inferredType;
  }
}

/// Shadow object for [ConstructorInvocation].
class ShadowConstructorInvocation extends ConstructorInvocation
    implements ShadowExpression {
  /// The name of the import prefix preceding the instantiated type; or `null`
  /// if the type is not prefixed.
  final String _prefixName;

  final Member _initialTarget;

  ShadowConstructorInvocation(this._prefixName, Constructor target,
      this._initialTarget, Arguments arguments,
      {bool isConst: false})
      : super(target, arguments, isConst: isConst);

  @override
  DartType _inferExpression(ShadowTypeInferrer inferrer, DartType typeContext) {
    inferrer.listener
        .constructorInvocationEnter(this, _prefixName, typeContext);
    var inferredType = inferrer.inferInvocation(
        typeContext,
        fileOffset,
        _initialTarget.function.functionType,
        computeConstructorReturnType(_initialTarget),
        arguments,
        isConst: isConst);
    if (inferrer.strongMode &&
        !inferrer.isTopLevel &&
        inferrer.typeSchemaEnvironment.isSuperBounded(inferredType)) {
      inferrer.helper.deprecated_addCompileTimeError(
          fileOffset,
          templateCantUseSuperBoundedTypeForInstanceCreation
              .withArguments(inferredType)
              .message);
    }
    inferrer.listener.constructorInvocationExit(this, inferredType);
    return inferredType;
  }

  /// Determines whether the given [ShadowConstructorInvocation] represents an
  /// invocation of a redirected factory constructor.
  ///
  /// This is static to avoid introducing a method that would be visible to the
  /// kernel.
  static bool isRedirected(ShadowConstructorInvocation expression) {
    return !identical(expression._initialTarget, expression.target);
  }
}

/// Concrete shadow object representing a continue statement from a switch
/// statement, in kernel form.
class ShadowContinueSwitchStatement extends ContinueSwitchStatement
    implements ShadowStatement {
  ShadowContinueSwitchStatement(SwitchCase target) : super(target);

  @override
  void _inferStatement(ShadowTypeInferrer inferrer) {
    inferrer.listener.continueSwitchStatementEnter(this);
    // No inference needs to be done.
    inferrer.listener.continueSwitchStatementExit(this);
  }
}

/// Shadow object representing a deferred check in kernel form.
class ShadowDeferredCheck extends Let implements ShadowExpression {
  ShadowDeferredCheck(VariableDeclaration variable, Expression body)
      : super(variable, body);

  @override
  DartType _inferExpression(ShadowTypeInferrer inferrer, DartType typeContext) {
    inferrer.listener.deferredCheckEnter(this, typeContext);
    // Since the variable is not used in the body we don't need to type infer
    // it.  We can just type infer the body.
    var inferredType = inferrer.inferExpression(body, typeContext, true);
    inferrer.listener.deferredCheckExit(this, inferredType);
    return inferredType;
  }
}

/// Concrete shadow object representing a do loop in kernel form.
class ShadowDoStatement extends DoStatement implements ShadowStatement {
  ShadowDoStatement(Statement body, Expression condition)
      : super(body, condition);

  @override
  void _inferStatement(ShadowTypeInferrer inferrer) {
    inferrer.listener.doStatementEnter(this);
    inferrer.inferStatement(body);
    var boolType = inferrer.coreTypes.boolClass.rawType;
    var actualType =
        inferrer.inferExpression(condition, boolType, !inferrer.isTopLevel);
    inferrer.checkAssignability(
        boolType, actualType, condition, condition.fileOffset);
    inferrer.listener.doStatementExit(this);
  }
}

/// Concrete shadow object representing a double literal in kernel form.
class ShadowDoubleLiteral extends DoubleLiteral implements ShadowExpression {
  ShadowDoubleLiteral(double value) : super(value);

  @override
  DartType _inferExpression(ShadowTypeInferrer inferrer, DartType typeContext) {
    inferrer.listener.doubleLiteralEnter(this, typeContext);
    var inferredType = inferrer.coreTypes.doubleClass.rawType;
    inferrer.listener.doubleLiteralExit(this, inferredType);
    return inferredType;
  }
}

/// Common base class for shadow objects representing expressions in kernel
/// form.
abstract class ShadowExpression implements Expression {
  /// Calls back to [inferrer] to perform type inference for whatever concrete
  /// type of [ShadowExpression] this is.
  DartType _inferExpression(ShadowTypeInferrer inferrer, DartType typeContext);
}

/// Concrete shadow object representing an expression statement in kernel form.
class ShadowExpressionStatement extends ExpressionStatement
    implements ShadowStatement {
  ShadowExpressionStatement(Expression expression) : super(expression);

  @override
  void _inferStatement(ShadowTypeInferrer inferrer) {
    inferrer.listener.expressionStatementEnter(this);
    inferrer.inferExpression(expression, null, false);
    inferrer.listener.expressionStatementExit(this);
  }
}

/// Shadow object for [StaticInvocation] when the procedure being invoked is a
/// factory constructor.
class ShadowFactoryConstructorInvocation extends StaticInvocation
    implements ShadowExpression {
  /// The name of the import prefix preceding the instantiated type; or `null`
  /// if the type is not prefixed.
  final String _prefixName;

  final Member _initialTarget;

  ShadowFactoryConstructorInvocation(this._prefixName, Procedure target,
      this._initialTarget, Arguments arguments,
      {bool isConst: false})
      : super(target, arguments, isConst: isConst);

  @override
  DartType _inferExpression(ShadowTypeInferrer inferrer, DartType typeContext) {
    inferrer.listener
        .constructorInvocationEnter(this, _prefixName, typeContext);
    var inferredType = inferrer.inferInvocation(
        typeContext,
        fileOffset,
        _initialTarget.function.functionType,
        computeConstructorReturnType(_initialTarget),
        arguments);
    inferrer.listener.constructorInvocationExit(this, inferredType);
    return inferredType;
  }
}

/// Concrete shadow object representing a field in kernel form.
class ShadowField extends Field implements ShadowMember {
  @override
  InferenceNode _inferenceNode;

  ShadowTypeInferrer _typeInferrer;

  final bool _isImplicitlyTyped;

  ShadowField(Name name, this._isImplicitlyTyped, {Uri fileUri})
      : super(name, fileUri: fileUri) {}

  @override
  void setInferredType(
      TypeInferenceEngineImpl engine, Uri uri, DartType inferredType) {
    type = inferredType;
  }

  static bool isImplicitlyTyped(ShadowField field) => field._isImplicitlyTyped;

  static void setInferenceNode(ShadowField field, InferenceNode node) {
    assert(field._inferenceNode == null);
    field._inferenceNode = node;
  }
}

/// Concrete shadow object representing a field initializer in kernel form.
class ShadowFieldInitializer extends FieldInitializer
    implements ShadowInitializer {
  ShadowFieldInitializer(Field field, Expression value) : super(field, value);

  @override
  void _inferInitializer(ShadowTypeInferrer inferrer) {
    inferrer.listener.fieldInitializerEnter(this);
    var initializerType = inferrer.inferExpression(value, field.type, true);
    inferrer.checkAssignability(field.type, initializerType, value, fileOffset);
    inferrer.listener.fieldInitializerExit(this);
  }
}

/// Concrete shadow object representing a for-in loop in kernel form.
class ShadowForInStatement extends ForInStatement implements ShadowStatement {
  final bool _declaresVariable;

  final ShadowSyntheticExpression _syntheticAssignment;

  ShadowForInStatement(VariableDeclaration variable, Expression iterable,
      Statement body, this._declaresVariable, this._syntheticAssignment,
      {bool isAsync: false})
      : super(variable, iterable, body, isAsync: isAsync);

  @override
  void _inferStatement(ShadowTypeInferrer inferrer) {
    var iterableClass = isAsync
        ? inferrer.coreTypes.streamClass
        : inferrer.coreTypes.iterableClass;
    DartType context;
    bool typeNeeded = false;
    bool typeChecksNeeded = !inferrer.isTopLevel;
    ShadowVariableDeclaration variable;
    var syntheticAssignment = _syntheticAssignment;
    Expression syntheticWrite;
    DartType syntheticWriteType;
    if (_declaresVariable) {
      variable = this.variable;
      if (inferrer.strongMode && variable._implicitlyTyped) {
        typeNeeded = true;
        context = const UnknownType();
      } else {
        context = variable.type;
      }
    } else if (syntheticAssignment is ShadowComplexAssignment) {
      syntheticWrite = syntheticAssignment.write;
      syntheticWriteType =
          context = syntheticAssignment._getWriteType(inferrer);
    } else {
      context = const UnknownType();
    }
    context = inferrer.wrapType(context, iterableClass);
    inferrer.listener.forInStatementEnter(this, variable, syntheticWrite);
    var inferredExpressionType = inferrer.resolveTypeParameter(inferrer
        .inferExpression(iterable, context, typeNeeded || typeChecksNeeded));
    inferrer.checkAssignability(
        inferrer.wrapType(const DynamicType(), iterableClass),
        inferredExpressionType,
        iterable,
        iterable.fileOffset);
    DartType inferredType;
    if (typeNeeded || typeChecksNeeded) {
      inferredType = const DynamicType();
      if (inferredExpressionType is InterfaceType) {
        InterfaceType supertype = inferrer.classHierarchy
            .getTypeAsInstanceOf(inferredExpressionType, iterableClass);
        if (supertype != null) {
          inferredType = supertype.typeArguments[0];
        }
      }
      if (typeNeeded) {
        inferrer.instrumentation?.record(inferrer.uri, variable.fileOffset,
            'type', new InstrumentationValueForType(inferredType));
        variable.type = inferredType;
      }
      if (!_declaresVariable) {
        this.variable.type = inferredType;
      }
    }
    inferrer.inferStatement(body);
    if (_declaresVariable) {
      var tempVar =
          new VariableDeclaration(null, type: inferredType, isFinal: true);
      var variableGet = new VariableGet(tempVar)
        ..fileOffset = this.variable.fileOffset;
      var implicitDowncast = inferrer.checkAssignability(
          variable.type, inferredType, variableGet, fileOffset);
      if (implicitDowncast != null) {
        this.variable = tempVar..parent = this;
        variable.initializer = implicitDowncast..parent = variable;
        body = combineStatements(variable, body)..parent = this;
      }
    } else if (syntheticAssignment is ShadowSyntheticExpression) {
      if (syntheticAssignment is ShadowComplexAssignment) {
        inferrer.checkAssignability(
            greatestClosure(inferrer.coreTypes, syntheticWriteType),
            this.variable.type,
            syntheticAssignment.rhs,
            syntheticAssignment.rhs.fileOffset);
        if (syntheticAssignment is ShadowPropertyAssign) {
          syntheticAssignment._handleWriteContravariance(
              inferrer, inferrer.thisType);
        }
      }
      syntheticAssignment._replaceWithDesugared();
    }
    inferrer.listener.forInStatementExit(this, variable);
  }
}

/// Concrete shadow object representing a classic for loop in kernel form.
class ShadowForStatement extends ForStatement implements ShadowStatement {
  ShadowForStatement(List<VariableDeclaration> variables, Expression condition,
      List<Expression> updates, Statement body)
      : super(variables, condition, updates, body);

  @override
  void _inferStatement(ShadowTypeInferrer inferrer) {
    inferrer.listener.forStatementEnter(this);
    variables.forEach(inferrer.inferStatement);
    if (condition != null) {
      var expectedType = inferrer.coreTypes.boolClass.rawType;
      var conditionType = inferrer.inferExpression(
          condition, expectedType, !inferrer.isTopLevel);
      inferrer.checkAssignability(
          expectedType, conditionType, condition, condition.fileOffset);
    }
    for (var update in updates) {
      inferrer.inferExpression(update, null, false);
    }
    inferrer.inferStatement(body);
    inferrer.listener.forStatementExit(this);
  }
}

/// Concrete shadow object representing a local function declaration in kernel
/// form.
class ShadowFunctionDeclaration extends FunctionDeclaration
    implements ShadowStatement {
  bool _hasImplicitReturnType = false;

  ShadowFunctionDeclaration(VariableDeclaration variable, FunctionNode function)
      : super(variable, function);

  @override
  void _inferStatement(ShadowTypeInferrer inferrer) {
    inferrer.listener.functionDeclarationEnter(this);
    inferrer.inferLocalFunction(
        function,
        null,
        fileOffset,
        _hasImplicitReturnType
            ? (inferrer.strongMode ? null : const DynamicType())
            : function.returnType);
    variable.type = function.functionType;
    inferrer.listener.functionDeclarationExit(this);
  }

  static void setHasImplicitReturnType(
      ShadowFunctionDeclaration declaration, bool hasImplicitReturnType) {
    declaration._hasImplicitReturnType = hasImplicitReturnType;
  }
}

/// Concrete shadow object representing a function expression in kernel form.
class ShadowFunctionExpression extends FunctionExpression
    implements ShadowExpression {
  ShadowFunctionExpression(FunctionNode function) : super(function);

  @override
  DartType _inferExpression(ShadowTypeInferrer inferrer, DartType typeContext) {
    inferrer.listener.functionExpressionEnter(this, typeContext);
    var inferredType =
        inferrer.inferLocalFunction(function, typeContext, fileOffset, null);
    inferrer.listener.functionExpressionExit(this, inferredType);
    return inferredType;
  }
}

/// Concrete shadow object representing an if-null expression.
///
/// An if-null expression of the form `a ?? b` is represented as the kernel
/// expression:
///
///     let v = a in v == null ? b : v
class ShadowIfNullExpression extends Let implements ShadowExpression {
  ShadowIfNullExpression(VariableDeclaration variable, Expression body)
      : super(variable, body);

  @override
  ConditionalExpression get body => super.body;

  /// Returns the expression to the left of `??`.
  Expression get _lhs => variable.initializer;

  /// Returns the expression to the right of `??`.
  Expression get _rhs => body.then;

  @override
  DartType _inferExpression(ShadowTypeInferrer inferrer, DartType typeContext) {
    inferrer.listener.ifNullEnter(this, typeContext);
    // To infer `e0 ?? e1` in context K:
    // - Infer e0 in context K to get T0
    var lhsType = inferrer.inferExpression(_lhs, typeContext, true);
    if (inferrer.strongMode) {
      variable.type = lhsType;
    }
    inferrer.listener.ifNullBeforeRhs(this);
    // - Let J = T0 if K is `_` else K.
    var rhsContext = typeContext ?? lhsType;
    // - Infer e1 in context J to get T1
    bool useLub = _forceLub || typeContext == null;
    var rhsType = inferrer.inferExpression(_rhs, rhsContext, useLub);
    // - Let T = greatest closure of K with respect to `?` if K is not `_`, else
    //   UP(t0, t1)
    // - Then the inferred type is T.
    var inferredType = useLub
        ? inferrer.typeSchemaEnvironment.getLeastUpperBound(lhsType, rhsType)
        : greatestClosure(inferrer.coreTypes, typeContext);
    if (inferrer.strongMode) {
      body.staticType = inferredType;
    }
    inferrer.listener.ifNullExit(this, inferredType);
    return inferredType;
  }
}

/// Concrete shadow object representing an if statement in kernel form.
class ShadowIfStatement extends IfStatement implements ShadowStatement {
  ShadowIfStatement(Expression condition, Statement then, Statement otherwise)
      : super(condition, then, otherwise);

  @override
  void _inferStatement(ShadowTypeInferrer inferrer) {
    inferrer.listener.ifStatementEnter(this);
    var expectedType = inferrer.coreTypes.boolClass.rawType;
    var conditionType =
        inferrer.inferExpression(condition, expectedType, !inferrer.isTopLevel);
    inferrer.checkAssignability(
        expectedType, conditionType, condition, condition.fileOffset);
    inferrer.inferStatement(then);
    if (otherwise != null) inferrer.inferStatement(otherwise);
    inferrer.listener.ifStatementExit(this);
  }
}

/// Concrete shadow object representing an assignment to a target for which
/// assignment is not allowed.
class ShadowIllegalAssignment extends ShadowComplexAssignment {
  ShadowIllegalAssignment(Expression rhs) : super(rhs);

  @override
  DartType _getWriteType(ShadowTypeInferrer inferrer) {
    return const UnknownType();
  }

  @override
  DartType _inferExpression(ShadowTypeInferrer inferrer, DartType typeContext) {
    if (write != null) {
      inferrer.inferExpression(write, null, false);
    }
    _replaceWithDesugared();
    return const DynamicType();
  }
}

/// Concrete shadow object representing an assignment to a target of the form
/// `a[b]`.
class ShadowIndexAssign extends ShadowComplexAssignmentWithReceiver {
  /// In an assignment to an index expression, the index expression.
  Expression index;

  ShadowIndexAssign(Expression receiver, this.index, Expression rhs,
      {bool isSuper: false})
      : super(receiver, rhs, isSuper);

  Arguments _getInvocationArguments(
      ShadowTypeInferrer inferrer, Expression invocation) {
    if (invocation is MethodInvocation) {
      return invocation.arguments;
    } else if (invocation is SuperMethodInvocation) {
      return invocation.arguments;
    } else {
      throw unhandled("${invocation.runtimeType}", "_getInvocationArguments",
          fileOffset, inferrer.uri);
    }
  }

  @override
  List<String> _getToStringParts() {
    var parts = super._getToStringParts();
    if (index != null) parts.add('index=$index');
    return parts;
  }

  @override
  DartType _inferExpression(ShadowTypeInferrer inferrer, DartType typeContext) {
    inferrer.listener.indexAssignEnter(desugared, typeContext);
    var receiverType = _inferReceiver(inferrer);
    inferrer.listener.indexAssignAfterReceiver(write, typeContext);
    var writeMember = inferrer.findMethodInvocationMember(receiverType, write);
    // To replicate analyzer behavior, we base type inference on the write
    // member.  TODO(paulberry): would it be better to use the read member
    // when doing compound assignment?
    var calleeType =
        inferrer.getCalleeFunctionType(writeMember, receiverType, false);
    DartType expectedIndexTypeForWrite;
    DartType indexContext;
    DartType writeContext;
    if (calleeType.positionalParameters.length >= 2) {
      // TODO(paulberry): we ought to get a context for the index expression
      // from the index formal parameter, but analyzer doesn't so for now we
      // replicate its behavior.
      indexContext = null;
      expectedIndexTypeForWrite = calleeType.positionalParameters[0];
      writeContext = calleeType.positionalParameters[1];
    }
    var indexType = inferrer.inferExpression(index, indexContext, true);
    _storeLetType(inferrer, index, indexType);
    if (writeContext != null) {
      inferrer.checkAssignability(
          expectedIndexTypeForWrite,
          indexType,
          _getInvocationArguments(inferrer, write).positional[0],
          write.fileOffset);
    }
    InvocationExpression read = this.read;
    DartType readType;
    if (read != null) {
      var readMember =
          inferrer.findMethodInvocationMember(receiverType, read, silent: true);
      var calleeFunctionType =
          inferrer.getCalleeFunctionType(readMember, receiverType, false);
      inferrer.checkAssignability(
          getPositionalParameterType(calleeFunctionType, 0),
          indexType,
          _getInvocationArguments(inferrer, read).positional[0],
          read.fileOffset);
      readType = calleeFunctionType.returnType;
      var desugaredInvocation = read is MethodInvocation ? read : null;
      var checkKind = inferrer.preCheckInvocationContravariance(receiver,
          receiverType, readMember, desugaredInvocation, read.arguments, read);
      var replacedRead = inferrer.handleInvocationContravariance(
          checkKind,
          desugaredInvocation,
          read.arguments,
          read,
          readType,
          calleeFunctionType,
          read.fileOffset);
      _storeLetType(inferrer, replacedRead, readType);
    }
    var inferredResult = _inferRhs(inferrer, readType, writeContext);
    inferrer.listener.indexAssignExit(desugared, write, writeMember,
        inferredResult.combiner, inferredResult.type);
    _replaceWithDesugared();
    return inferredResult.type;
  }
}

/// Common base class for shadow objects representing initializers in kernel
/// form.
abstract class ShadowInitializer implements Initializer {
  /// Performs type inference for whatever concrete type of [ShadowInitializer]
  /// this is.
  void _inferInitializer(ShadowTypeInferrer inferrer);
}

/// Concrete shadow object representing an integer literal in kernel form.
class ShadowIntLiteral extends IntLiteral implements ShadowExpression {
  ShadowIntLiteral(int value) : super(value);

  @override
  DartType _inferExpression(ShadowTypeInferrer inferrer, DartType typeContext) {
    inferrer.listener.intLiteralEnter(this, typeContext);
    var inferredType = inferrer.coreTypes.intClass.rawType;
    inferrer.listener.intLiteralExit(this, inferredType);
    return inferredType;
  }
}

/// Concrete shadow object representing an invalid initializer in kernel form.
class ShadowInvalidInitializer extends LocalInitializer
    implements ShadowInitializer {
  ShadowInvalidInitializer(VariableDeclaration variable) : super(variable);

  @override
  void _inferInitializer(ShadowTypeInferrer inferrer) {
    inferrer.listener.invalidInitializerEnter(this);
    inferrer.inferExpression(variable.initializer, null, false);
    inferrer.listener.invalidInitializerExit(this);
  }
}

/// Concrete shadow object representing a non-inverted "is" test in kernel form.
class ShadowIsExpression extends IsExpression implements ShadowExpression {
  ShadowIsExpression(Expression operand, DartType type) : super(operand, type);

  @override
  DartType _inferExpression(ShadowTypeInferrer inferrer, DartType typeContext) {
    inferrer.listener.isExpressionEnter(this, typeContext);
    inferrer.inferExpression(operand, null, false);
    var inferredType = inferrer.coreTypes.boolClass.rawType;
    inferrer.listener.isExpressionExit(this, inferredType);
    return inferredType;
  }
}

/// Concrete shadow object representing an inverted "is" test in kernel form.
class ShadowIsNotExpression extends Not implements ShadowExpression {
  ShadowIsNotExpression(Expression operand, DartType type, int charOffset)
      : super(new IsExpression(operand, type)..fileOffset = charOffset);

  @override
  DartType _inferExpression(ShadowTypeInferrer inferrer, DartType typeContext) {
    IsExpression isExpression = this.operand;

    inferrer.listener.isNotExpressionEnter(this, typeContext);
    inferrer.inferExpression(isExpression.operand, null, false);
    var inferredType = inferrer.coreTypes.boolClass.rawType;
    inferrer.listener
        .isNotExpressionExit(this, isExpression.type, inferredType);
    return inferredType;
  }
}

/// Concrete shadow object representing a labeled statement in kernel form.
class ShadowLabeledStatement extends LabeledStatement
    implements ShadowStatement {
  ShadowLabeledStatement(Statement body) : super(body);

  @override
  void _inferStatement(ShadowTypeInferrer inferrer) {
    inferrer.listener.labeledStatementEnter(this);
    inferrer.inferStatement(body);
    inferrer.listener.labeledStatementExit(this);
  }
}

/// Concrete shadow object representing a list literal in kernel form.
class ShadowListLiteral extends ListLiteral implements ShadowExpression {
  final DartType _declaredTypeArgument;

  ShadowListLiteral(List<Expression> expressions,
      {DartType typeArgument, bool isConst: false})
      : _declaredTypeArgument = typeArgument,
        super(expressions,
            typeArgument: typeArgument ?? const DynamicType(),
            isConst: isConst);

  @override
  DartType _inferExpression(ShadowTypeInferrer inferrer, DartType typeContext) {
    inferrer.listener.listLiteralEnter(this, typeContext);
    var listClass = inferrer.coreTypes.listClass;
    var listType = listClass.thisType;
    List<DartType> inferredTypes;
    DartType inferredTypeArgument;
    List<DartType> formalTypes;
    List<DartType> actualTypes;
    bool inferenceNeeded = _declaredTypeArgument == null && inferrer.strongMode;
    bool typeChecksNeeded = !inferrer.isTopLevel;
    if (inferenceNeeded || typeChecksNeeded) {
      formalTypes = [];
      actualTypes = [];
    }
    if (inferenceNeeded) {
      inferredTypes = [const UnknownType()];
      inferrer.typeSchemaEnvironment.inferGenericFunctionOrType(listType,
          listClass.typeParameters, null, null, typeContext, inferredTypes,
          isConst: isConst);
      inferredTypeArgument = inferredTypes[0];
    } else {
      inferredTypeArgument = _declaredTypeArgument ?? const DynamicType();
    }
    if (inferenceNeeded || typeChecksNeeded) {
      for (var expression in expressions) {
        var expressionType = inferrer.inferExpression(expression,
            inferredTypeArgument, inferenceNeeded || typeChecksNeeded);
        if (inferenceNeeded) {
          formalTypes.add(listType.typeArguments[0]);
        }
        actualTypes.add(expressionType);
      }
    }
    if (inferenceNeeded) {
      inferrer.typeSchemaEnvironment.inferGenericFunctionOrType(
          listType,
          listClass.typeParameters,
          formalTypes,
          actualTypes,
          typeContext,
          inferredTypes);
      inferredTypeArgument = inferredTypes[0];
      inferrer.instrumentation?.record(inferrer.uri, fileOffset, 'typeArgs',
          new InstrumentationValueForTypeArgs([inferredTypeArgument]));
      typeArgument = inferredTypeArgument;
    }
    if (typeChecksNeeded) {
      for (int i = 0; i < expressions.length; i++) {
        inferrer.checkAssignability(typeArgument, actualTypes[i],
            expressions[i], expressions[i].fileOffset);
      }
    }
    var inferredType = new InterfaceType(listClass, [inferredTypeArgument]);
    inferrer.listener.listLiteralExit(this, inferredType);
    return inferredType;
  }
}

/// Shadow object for [LogicalExpression].
class ShadowLogicalExpression extends LogicalExpression
    implements ShadowExpression {
  ShadowLogicalExpression(Expression left, String operator, Expression right)
      : super(left, operator, right);

  @override
  DartType _inferExpression(ShadowTypeInferrer inferrer, DartType typeContext) {
    inferrer.listener.logicalExpressionEnter(this, typeContext);
    var boolType = inferrer.coreTypes.boolClass.rawType;
    var leftType =
        inferrer.inferExpression(left, boolType, !inferrer.isTopLevel);
    inferrer.listener.logicalExpressionBeforeRhs(this);
    var rightType =
        inferrer.inferExpression(right, boolType, !inferrer.isTopLevel);
    inferrer.checkAssignability(boolType, leftType, left, left.fileOffset);
    inferrer.checkAssignability(boolType, rightType, right, right.fileOffset);
    var inferredType = boolType;
    inferrer.listener.logicalExpressionExit(this, inferredType);
    return inferredType;
  }
}

/// Shadow object for synthetic assignments added at the top of a for-in loop.
///
/// This covers the case where a for-in loop refers to a variable decleared
/// elsewhere, so it is desugared into a for-in loop that assigns to the
/// variable at the top of the loop body.
class ShadowLoopAssignmentStatement extends ExpressionStatement
    implements ShadowStatement {
  ShadowLoopAssignmentStatement(Expression expression) : super(expression);

  @override
  void _inferStatement(ShadowTypeInferrer inferrer) {}
}

/// Shadow object for [MapLiteral].
class ShadowMapLiteral extends MapLiteral implements ShadowExpression {
  final DartType _declaredKeyType;
  final DartType _declaredValueType;

  ShadowMapLiteral(List<MapEntry> entries,
      {DartType keyType, DartType valueType, bool isConst: false})
      : _declaredKeyType = keyType,
        _declaredValueType = valueType,
        super(entries,
            keyType: keyType ?? const DynamicType(),
            valueType: valueType ?? const DynamicType(),
            isConst: isConst);

  @override
  DartType _inferExpression(ShadowTypeInferrer inferrer, DartType typeContext) {
    inferrer.listener.mapLiteralEnter(this, typeContext);
    var mapClass = inferrer.coreTypes.mapClass;
    var mapType = mapClass.thisType;
    List<DartType> inferredTypes;
    DartType inferredKeyType;
    DartType inferredValueType;
    List<DartType> formalTypes;
    List<DartType> actualTypes;
    assert((_declaredKeyType == null) == (_declaredValueType == null));
    bool inferenceNeeded = _declaredKeyType == null && inferrer.strongMode;
    bool typeChecksNeeded = !inferrer.isTopLevel;
    if (inferenceNeeded || typeChecksNeeded) {
      formalTypes = [];
      actualTypes = [];
    }
    if (inferenceNeeded) {
      inferredTypes = [const UnknownType(), const UnknownType()];
      inferrer.typeSchemaEnvironment.inferGenericFunctionOrType(mapType,
          mapClass.typeParameters, null, null, typeContext, inferredTypes,
          isConst: isConst);
      inferredKeyType = inferredTypes[0];
      inferredValueType = inferredTypes[1];
    } else {
      inferredKeyType = _declaredKeyType ?? const DynamicType();
      inferredValueType = _declaredValueType ?? const DynamicType();
    }
    if (inferenceNeeded || typeChecksNeeded) {
      for (var entry in entries) {
        var keyType = inferrer.inferExpression(
            entry.key, inferredKeyType, inferenceNeeded || typeChecksNeeded);
        var valueType = inferrer.inferExpression(entry.value, inferredValueType,
            inferenceNeeded || typeChecksNeeded);
        if (inferenceNeeded) {
          formalTypes.addAll(mapType.typeArguments);
        }
        actualTypes.add(keyType);
        actualTypes.add(valueType);
      }
    }
    if (inferenceNeeded) {
      inferrer.typeSchemaEnvironment.inferGenericFunctionOrType(
          mapType,
          mapClass.typeParameters,
          formalTypes,
          actualTypes,
          typeContext,
          inferredTypes);
      inferredKeyType = inferredTypes[0];
      inferredValueType = inferredTypes[1];
      inferrer.instrumentation?.record(
          inferrer.uri,
          fileOffset,
          'typeArgs',
          new InstrumentationValueForTypeArgs(
              [inferredKeyType, inferredValueType]));
      keyType = inferredKeyType;
      valueType = inferredValueType;
    }
    if (typeChecksNeeded) {
      for (int i = 0; i < entries.length; i++) {
        var entry = entries[i];
        var key = entry.key;
        inferrer.checkAssignability(
            keyType, actualTypes[2 * i], key, key.fileOffset);
        var value = entry.value;
        inferrer.checkAssignability(
            valueType, actualTypes[2 * i + 1], value, value.fileOffset);
      }
    }
    var inferredType =
        new InterfaceType(mapClass, [inferredKeyType, inferredValueType]);
    inferrer.listener.mapLiteralExit(this, inferredType);
    return inferredType;
  }
}

/// Abstract shadow object representing a field or procedure in kernel form.
abstract class ShadowMember implements Member {
  Uri get fileUri;

  InferenceNode get _inferenceNode;

  void set _inferenceNode(InferenceNode value);

  void setInferredType(
      TypeInferenceEngineImpl engine, Uri uri, DartType inferredType);

  static void resolveInferenceNode(Member member) {
    if (member is ShadowMember) {
      if (member._inferenceNode != null) {
        member._inferenceNode.resolve();
        member._inferenceNode = null;
      }
    }
  }
}

/// Shadow object for [MethodInvocation].
class ShadowMethodInvocation extends MethodInvocation
    implements ShadowExpression {
  /// Indicates whether this method invocation is a call to a `call` method
  /// resulting from the invocation of a function expression.
  final bool _isImplicitCall;

  ShadowMethodInvocation(Expression receiver, Name name, Arguments arguments,
      {bool isImplicitCall: false, Member interfaceTarget})
      : _isImplicitCall = isImplicitCall,
        super(receiver, name, arguments, interfaceTarget);

  @override
  DartType _inferExpression(ShadowTypeInferrer inferrer, DartType typeContext) {
    return inferrer.inferMethodInvocation(
        this, receiver, fileOffset, _isImplicitCall, typeContext,
        desugaredInvocation: this);
  }
}

/// Concrete shadow object representing a named function expression.
///
/// Named function expressions are not legal in Dart, but they are accepted by
/// the parser and BodyBuilder for error recovery purposes.
///
/// A named function expression of the form `f() { ... }` is represented as the
/// kernel expression:
///
///     let f = () { ... } in f
class ShadowNamedFunctionExpression extends Let implements ShadowExpression {
  ShadowNamedFunctionExpression(VariableDeclaration variable)
      : super(variable, new VariableGet(variable));

  @override
  DartType _inferExpression(ShadowTypeInferrer inferrer, DartType typeContext) {
    inferrer.listener.namedFunctionExpressionEnter(this, typeContext);
    var inferredType =
        inferrer.inferExpression(variable.initializer, typeContext, true);
    if (inferrer.strongMode) variable.type = inferredType;
    inferrer.listener.namedFunctionExpressionExit(this, inferredType);
    return inferredType;
  }
}

/// Shadow object for [Not].
class ShadowNot extends Not implements ShadowExpression {
  ShadowNot(Expression operand) : super(operand);

  @override
  DartType _inferExpression(ShadowTypeInferrer inferrer, DartType typeContext) {
    inferrer.listener.notEnter(this, typeContext);
    // First infer the receiver so we can look up the method that was invoked.
    var boolType = inferrer.coreTypes.boolClass.rawType;
    var actualType =
        inferrer.inferExpression(operand, boolType, !inferrer.isTopLevel);
    inferrer.checkAssignability(boolType, actualType, operand, fileOffset);
    DartType inferredType = boolType;
    inferrer.listener.notExit(this, inferredType);
    return inferredType;
  }
}

/// Concrete shadow object representing a null-aware method invocation.
///
/// A null-aware method invocation of the form `a?.b(...)` is represented as the
/// expression:
///
///     let v = a in v == null ? null : v.b(...)
class ShadowNullAwareMethodInvocation extends Let implements ShadowExpression {
  ShadowNullAwareMethodInvocation(VariableDeclaration variable, Expression body)
      : super(variable, body);

  @override
  ConditionalExpression get body => super.body;

  MethodInvocation get _desugaredInvocation => body.otherwise;

  @override
  DartType _inferExpression(ShadowTypeInferrer inferrer, DartType typeContext) {
    var inferredType = inferrer.inferMethodInvocation(
        this, variable.initializer, fileOffset, false, typeContext,
        receiverVariable: variable, desugaredInvocation: _desugaredInvocation);
    if (inferrer.strongMode) {
      body.staticType = inferredType;
    }
    return inferredType;
  }
}

/// Concrete shadow object representing a null-aware read from a property.
///
/// A null-aware property get of the form `a?.b` is represented as the kernel
/// expression:
///
///     let v = a in v == null ? null : v.b
class ShadowNullAwarePropertyGet extends Let implements ShadowExpression {
  ShadowNullAwarePropertyGet(
      VariableDeclaration variable, ConditionalExpression body)
      : super(variable, body);

  @override
  ConditionalExpression get body => super.body;

  PropertyGet get _desugaredGet => body.otherwise;

  @override
  DartType _inferExpression(ShadowTypeInferrer inferrer, DartType typeContext) {
    var inferredType = inferrer.inferPropertyGet(
        this, variable.initializer, fileOffset, typeContext,
        receiverVariable: variable, desugaredGet: _desugaredGet);
    if (inferrer.strongMode) {
      body.staticType = inferredType;
    }
    return inferredType;
  }
}

/// Concrete shadow object representing a null literal in kernel form.
class ShadowNullLiteral extends NullLiteral implements ShadowExpression {
  @override
  DartType _inferExpression(ShadowTypeInferrer inferrer, DartType typeContext) {
    inferrer.listener.nullLiteralEnter(this, typeContext);
    var inferredType = inferrer.coreTypes.nullClass.rawType;
    inferrer.listener.nullLiteralExit(this, inferredType);
    return inferredType;
  }
}

/// Concrete shadow object representing a procedure in kernel form.
class ShadowProcedure extends Procedure implements ShadowMember {
  @override
  InferenceNode _inferenceNode;

  final bool _hasImplicitReturnType;

  ShadowProcedure(Name name, ProcedureKind kind, FunctionNode function,
      this._hasImplicitReturnType,
      {Uri fileUri, bool isAbstract: false})
      : super(name, kind, function, fileUri: fileUri, isAbstract: isAbstract);

  @override
  void setInferredType(
      TypeInferenceEngineImpl engine, Uri uri, DartType inferredType) {
    if (isSetter) {
      if (function.positionalParameters.length > 0) {
        function.positionalParameters[0].type = inferredType;
      }
    } else if (isGetter) {
      function.returnType = inferredType;
    } else {
      unhandled("setInferredType", "not accessor", fileOffset, uri);
    }
  }

  static bool hasImplicitReturnType(ShadowProcedure procedure) {
    return procedure._hasImplicitReturnType;
  }
}

/// Concrete shadow object representing an assignment to a property.
class ShadowPropertyAssign extends ShadowComplexAssignmentWithReceiver {
  /// If this assignment uses null-aware access (`?.`), the conditional
  /// expression that guards the access; otherwise `null`.
  ConditionalExpression nullAwareGuard;

  ShadowPropertyAssign(Expression receiver, Expression rhs,
      {bool isSuper: false})
      : super(receiver, rhs, isSuper);

  @override
  List<String> _getToStringParts() {
    var parts = super._getToStringParts();
    if (nullAwareGuard != null) parts.add('nullAwareGuard=$nullAwareGuard');
    return parts;
  }

  @override
  DartType _getWriteType(ShadowTypeInferrer inferrer) {
    assert(receiver == null);
    var receiverType = inferrer.thisType;
    var writeMember = inferrer.findPropertySetMember(receiverType, write);
    return inferrer.getSetterType(writeMember, receiverType);
  }

  Object _handleWriteContravariance(
      ShadowTypeInferrer inferrer, DartType receiverType) {
    var writeMember = inferrer.findPropertySetMember(receiverType, write);
    inferrer.handlePropertySetContravariance(
        receiver, writeMember, write is PropertySet ? write : null, write);
    return writeMember;
  }

  @override
  DartType _inferExpression(ShadowTypeInferrer inferrer, DartType typeContext) {
    var receiverType = _inferReceiver(inferrer);

    inferrer.listener.propertyAssignEnter(desugared, write, typeContext);
    DartType readType;
    if (read != null) {
      var readMember =
          inferrer.findPropertyGetMember(receiverType, read, silent: true);
      readType = inferrer.getCalleeType(readMember, receiverType);
      inferrer.handlePropertyGetContravariance(receiver, readMember,
          read is PropertyGet ? read : null, read, readType, read.fileOffset);
      _storeLetType(inferrer, read, readType);
    }
    Member writeMember;
    if (write != null) {
      writeMember = _handleWriteContravariance(inferrer, receiverType);
    }
    // To replicate analyzer behavior, we base type inference on the write
    // member.  TODO(paulberry): would it be better to use the read member when
    // doing compound assignment?
    var writeContext = inferrer.getSetterType(writeMember, receiverType);
    var inferredResult = _inferRhs(inferrer, readType, writeContext);
    if (inferrer.strongMode) nullAwareGuard?.staticType = inferredResult.type;
    inferrer.listener.propertyAssignExit(desugared, write, writeMember,
        writeContext, inferredResult.combiner, inferredResult.type);
    _replaceWithDesugared();
    return inferredResult.type;
  }
}

/// Shadow object for [PropertyGet].
class ShadowPropertyGet extends PropertyGet implements ShadowExpression {
  ShadowPropertyGet(Expression receiver, Name name, [Member interfaceTarget])
      : super(receiver, name, interfaceTarget);

  ShadowPropertyGet.byReference(
      Expression receiver, Name name, Reference interfaceTargetReference)
      : super.byReference(receiver, name, interfaceTargetReference);

  @override
  DartType _inferExpression(ShadowTypeInferrer inferrer, DartType typeContext) {
    return inferrer.inferPropertyGet(this, receiver, fileOffset, typeContext,
        desugaredGet: this);
  }
}

/// Concrete shadow object representing a redirecting initializer in kernel
/// form.
class ShadowRedirectingInitializer extends RedirectingInitializer
    implements ShadowInitializer {
  ShadowRedirectingInitializer(Constructor target, Arguments arguments)
      : super(target, arguments);

  @override
  _inferInitializer(ShadowTypeInferrer inferrer) {
    inferrer.listener.redirectingInitializerEnter(this);
    inferrer.inferInvocation(null, fileOffset, target.function.functionType,
        target.enclosingClass.thisType, arguments,
        skipTypeArgumentInference: true);
    inferrer.listener.redirectingInitializerExit(this);
  }
}

/// Shadow object for [Rethrow].
class ShadowRethrow extends Rethrow implements ShadowExpression {
  @override
  DartType _inferExpression(ShadowTypeInferrer inferrer, DartType typeContext) {
    inferrer.listener.rethrowEnter(this, typeContext);
    var inferredType = const BottomType();
    inferrer.listener.rethrowExit(this, inferredType);
    return inferredType;
  }
}

/// Concrete shadow object representing a return statement in kernel form.
class ShadowReturnStatement extends ReturnStatement implements ShadowStatement {
  ShadowReturnStatement([Expression expression]) : super(expression);

  @override
  void _inferStatement(ShadowTypeInferrer inferrer) {
    inferrer.listener.returnStatementEnter(this);
    var closureContext = inferrer.closureContext;
    var typeContext =
        !closureContext.isGenerator ? closureContext.returnContext : null;
    var inferredType = expression != null
        ? inferrer.inferExpression(expression, typeContext, true)
        : const VoidType();
    // Analyzer treats bare `return` statements as having no effect on the
    // inferred type of the closure.  TODO(paulberry): is this what we want
    // for Fasta?
    if (expression != null) {
      closureContext.handleReturn(
          inferrer, inferredType, expression, fileOffset);
    }
    inferrer.listener.returnStatementExit(this);
  }
}

/// Common base class for shadow objects representing statements in kernel
/// form.
abstract class ShadowStatement extends Statement {
  /// Calls back to [inferrer] to perform type inference for whatever concrete
  /// type of [ShadowStatement] this is.
  void _inferStatement(ShadowTypeInferrer inferrer);
}

/// Concrete shadow object representing an assignment to a static variable.
class ShadowStaticAssignment extends ShadowComplexAssignment {
  /// The name of the import prefix preceding the [_targetClass], or the target
  /// [Procedure]; or `null` if the reference is not prefixed.
  final String _prefixName;

  /// If [_targetClass] is not `null`, the offset at which the explicit
  /// reference to it is; otherwise `-1`.
  final int _targetOffset;

  /// The [Class] that was explicitly referenced to get the target [Procedure],
  /// or `null` if the class is implicit.
  final Class _targetClass;

  ShadowStaticAssignment(
      this._prefixName, this._targetOffset, this._targetClass, Expression rhs)
      : super(rhs);

  @override
  DartType _getWriteType(ShadowTypeInferrer inferrer) {
    StaticSet write = this.write;
    return write.target.setterType;
  }

  @override
  DartType _inferExpression(ShadowTypeInferrer inferrer, DartType typeContext) {
    inferrer.listener.staticAssignEnter(desugared, _prefixName, _targetOffset,
        _targetClass, this.write, typeContext);
    DartType readType;
    var read = this.read;
    if (read is StaticGet) {
      readType = read.target.getterType;
      _storeLetType(inferrer, read, readType);
    }
    Member writeMember;
    DartType writeContext;
    var write = this.write;
    if (write is StaticSet) {
      writeContext = write.target.setterType;
      writeMember = write.target;
      if (writeMember is ShadowField && writeMember._inferenceNode != null) {
        writeMember._inferenceNode.resolve();
        writeMember._inferenceNode = null;
      }
    }
    var inferredResult = _inferRhs(inferrer, readType, writeContext);
    inferrer.listener.staticAssignExit(desugared, write, writeMember,
        writeContext, inferredResult.combiner, inferredResult.type);
    _replaceWithDesugared();
    return inferredResult.type;
  }
}

/// Concrete shadow object representing a read of a static variable in kernel
/// form.
class ShadowStaticGet extends StaticGet implements ShadowExpression {
  /// The name of the import prefix preceding the [_targetClass], or the target
  /// [Procedure]; or `null` if the reference is not prefixed.
  final String _prefixName;

  /// If [_targetClass] is not `null`, the offset at which the explicit
  /// reference to it is; otherwise `-1`.
  final int _targetOffset;

  /// The [Class] that was explicitly referenced to get the target [Procedure],
  /// or `null` if the class is implicit.
  final Class _targetClass;

  ShadowStaticGet(
      this._prefixName, this._targetOffset, this._targetClass, Member target)
      : super(target);

  @override
  DartType _inferExpression(ShadowTypeInferrer inferrer, DartType typeContext) {
    inferrer.listener.staticGetEnter(
        this, _prefixName, _targetOffset, _targetClass, typeContext);
    var target = this.target;
    if (target is ShadowField && target._inferenceNode != null) {
      target._inferenceNode.resolve();
      target._inferenceNode = null;
    }
    var type = target.getterType;
    if (target is Procedure && target.kind == ProcedureKind.Method) {
      type = inferrer.instantiateTearOff(type, typeContext, this);
    }
    var inferredType = type;
    inferrer.listener.staticGetExit(this, inferredType);
    return inferredType;
  }
}

/// Shadow object for [StaticInvocation].
class ShadowStaticInvocation extends StaticInvocation
    implements ShadowExpression {
  /// The name of the import prefix preceding the [_targetClass], or the target
  /// [Procedure]; or `null` if the reference is not prefixed.
  final String _prefixName;

  /// If [_targetClass] is not `null`, the offset at which the explicit
  /// reference to it is; otherwise `-1`.
  final int _targetOffset;

  /// The [Class] that was explicitly referenced to get the target [Procedure],
  /// or `null` if the class is implicit.
  final Class _targetClass;

  ShadowStaticInvocation(this._prefixName, this._targetOffset,
      this._targetClass, Procedure target, Arguments arguments,
      {bool isConst: false})
      : super(target, arguments, isConst: isConst);

  @override
  DartType _inferExpression(ShadowTypeInferrer inferrer, DartType typeContext) {
    inferrer.listener.staticInvocationEnter(
        this, _prefixName, _targetOffset, _targetClass, typeContext);
    var calleeType = target.function.functionType;
    var inferredType = inferrer.inferInvocation(
        typeContext, fileOffset, calleeType, calleeType.returnType, arguments);
    inferrer.listener.staticInvocationExit(this, inferrer.lastCalleeType,
        inferrer.lastInferredSubstitution, inferredType);
    return inferredType;
  }
}

/// Concrete shadow object representing a string concatenation in kernel form.
class ShadowStringConcatenation extends StringConcatenation
    implements ShadowExpression {
  ShadowStringConcatenation(List<Expression> expressions) : super(expressions);

  @override
  DartType _inferExpression(ShadowTypeInferrer inferrer, DartType typeContext) {
    inferrer.listener.stringConcatenationEnter(this, typeContext);
    if (!inferrer.isTopLevel) {
      for (Expression expression in expressions) {
        inferrer.inferExpression(expression, null, false);
      }
    }
    var inferredType = inferrer.coreTypes.stringClass.rawType;
    inferrer.listener.stringConcatenationExit(this, inferredType);
    return inferredType;
  }
}

/// Concrete shadow object representing a string literal in kernel form.
class ShadowStringLiteral extends StringLiteral implements ShadowExpression {
  ShadowStringLiteral(String value) : super(value);

  @override
  DartType _inferExpression(ShadowTypeInferrer inferrer, DartType typeContext) {
    inferrer.listener.stringLiteralEnter(this, typeContext);
    var inferredType = inferrer.coreTypes.stringClass.rawType;
    inferrer.listener.stringLiteralExit(this, inferredType);
    return inferredType;
  }
}

/// Concrete shadow object representing a super initializer in kernel form.
class ShadowSuperInitializer extends SuperInitializer
    implements ShadowInitializer {
  ShadowSuperInitializer(Constructor target, Arguments arguments)
      : super(target, arguments);

  @override
  void _inferInitializer(ShadowTypeInferrer inferrer) {
    inferrer.listener.superInitializerEnter(this);
    var substitution = Substitution.fromSupertype(inferrer.classHierarchy
        .getClassAsInstanceOf(
            inferrer.thisType.classNode, target.enclosingClass));
    inferrer.inferInvocation(
        null,
        fileOffset,
        substitution
            .substituteType(target.function.functionType.withoutTypeParameters),
        inferrer.thisType,
        arguments,
        skipTypeArgumentInference: true);
    inferrer.listener.superInitializerExit(this);
  }
}

/// Shadow object for [SuperMethodInvocation].
class ShadowSuperMethodInvocation extends SuperMethodInvocation
    implements ShadowExpression {
  ShadowSuperMethodInvocation(Name name, Arguments arguments,
      [Procedure interfaceTarget])
      : super(name, arguments, interfaceTarget);

  @override
  DartType _inferExpression(ShadowTypeInferrer inferrer, DartType typeContext) {
    if (interfaceTarget != null) {
      inferrer.instrumentation?.record(inferrer.uri, fileOffset, 'target',
          new InstrumentationValueForMember(interfaceTarget));
    }
    return inferrer.inferMethodInvocation(
        this, null, fileOffset, false, typeContext,
        interfaceMember: interfaceTarget,
        methodName: name,
        arguments: arguments);
  }
}

/// Shadow object for [SuperPropertyGet].
class ShadowSuperPropertyGet extends SuperPropertyGet
    implements ShadowExpression {
  ShadowSuperPropertyGet(Name name, [Member interfaceTarget])
      : super(name, interfaceTarget);

  @override
  DartType _inferExpression(ShadowTypeInferrer inferrer, DartType typeContext) {
    if (interfaceTarget != null) {
      inferrer.instrumentation?.record(inferrer.uri, fileOffset, 'target',
          new InstrumentationValueForMember(interfaceTarget));
    }
    return inferrer.inferPropertyGet(this, null, fileOffset, typeContext,
        interfaceMember: interfaceTarget, propertyName: name);
  }
}

/// Concrete shadow object representing a switch statement in kernel form.
class ShadowSwitchStatement extends SwitchStatement implements ShadowStatement {
  ShadowSwitchStatement(Expression expression, List<SwitchCase> cases)
      : super(expression, cases);

  @override
  void _inferStatement(ShadowTypeInferrer inferrer) {
    inferrer.listener.switchStatementEnter(this);
    var expressionType = inferrer.inferExpression(expression, null, true);
    for (var switchCase in cases) {
      for (var caseExpression in switchCase.expressions) {
        inferrer.inferExpression(caseExpression, expressionType, false);
      }
      inferrer.inferStatement(switchCase.body);
    }
    inferrer.listener.switchStatementExit(this);
  }
}

/// Shadow object for [SymbolLiteral].
class ShadowSymbolLiteral extends SymbolLiteral implements ShadowExpression {
  ShadowSymbolLiteral(String value) : super(value);

  @override
  DartType _inferExpression(ShadowTypeInferrer inferrer, DartType typeContext) {
    inferrer.listener.symbolLiteralEnter(this, typeContext);
    var inferredType = inferrer.coreTypes.symbolClass.rawType;
    inferrer.listener.symbolLiteralExit(this, inferredType);
    return inferredType;
  }
}

/// Shadow object for expressions that are introduced by the front end as part
/// of desugaring or the handling of error conditions.
///
/// These expressions are removed by type inference and replaced with their
/// desugared equivalents.
class ShadowSyntheticExpression extends Let implements ShadowExpression {
  ShadowSyntheticExpression(Expression desugared)
      : super(new VariableDeclaration('_', initializer: new NullLiteral()),
            desugared);

  /// The desugared kernel representation of this synthetic expression.
  Expression get desugared => body;

  void set desugared(Expression value) {
    this.body = value;
    value.parent = this;
  }

  @override
  DartType _inferExpression(ShadowTypeInferrer inferrer, DartType typeContext) {
    _replaceWithDesugared();
    return const DynamicType();
  }

  /// Removes this expression from the expression tree, replacing it with
  /// [desugared].
  void _replaceWithDesugared() {
    parent.replaceChild(this, desugared);
  }

  /// Updates any [Let] nodes in the desugared expression to account for the
  /// fact that [expression] has the given [type].
  void _storeLetType(
      TypeInferrerImpl inferrer, Expression expression, DartType type) {
    if (!inferrer.strongMode) return;
    Expression desugared = this.desugared;
    while (true) {
      if (desugared is Let) {
        Let desugaredLet = desugared;
        var variable = desugaredLet.variable;
        if (identical(variable.initializer, expression)) {
          variable.type = type;
          return;
        }
        desugared = desugaredLet.body;
      } else if (desugared is ConditionalExpression) {
        // When a null-aware assignment is desugared, often the "then" or "else"
        // branch of the conditional expression often contains "let" nodes that
        // need to be updated.
        ConditionalExpression desugaredConditionalExpression = desugared;
        if (desugaredConditionalExpression.then is Let) {
          desugared = desugaredConditionalExpression.then;
        } else {
          desugared = desugaredConditionalExpression.otherwise;
        }
      } else {
        break;
      }
    }
  }
}

/// Shadow object for [ThisExpression].
class ShadowThisExpression extends ThisExpression implements ShadowExpression {
  @override
  DartType _inferExpression(ShadowTypeInferrer inferrer, DartType typeContext) {
    inferrer.listener.thisExpressionEnter(this, typeContext);
    var inferredType = (inferrer.thisType ?? const DynamicType());
    inferrer.listener.thisExpressionExit(this, inferredType);
    return inferredType;
  }
}

/// Shadow object for [Throw].
class ShadowThrow extends Throw implements ShadowExpression {
  ShadowThrow(Expression expression) : super(expression);

  @override
  DartType _inferExpression(ShadowTypeInferrer inferrer, DartType typeContext) {
    inferrer.listener.throwEnter(this, typeContext);
    inferrer.inferExpression(expression, null, false);
    var inferredType = const BottomType();
    inferrer.listener.throwExit(this, inferredType);
    return inferredType;
  }
}

/// Concrete shadow object representing a try-catch block in kernel form.
class ShadowTryCatch extends TryCatch implements ShadowStatement {
  ShadowTryCatch(Statement body, List<Catch> catches) : super(body, catches);

  @override
  void _inferStatement(ShadowTypeInferrer inferrer) {
    inferrer.listener.tryCatchEnter(this);
    inferrer.inferStatement(body);
    for (var catch_ in catches) {
      inferrer.listener.catchStatementEnter(catch_);
      inferrer.inferStatement(catch_.body);
      inferrer.listener.catchStatementExit(catch_);
    }
    inferrer.listener.tryCatchExit(this);
  }
}

/// Concrete shadow object representing a try-finally block in kernel form.
class ShadowTryFinally extends TryFinally implements ShadowStatement {
  ShadowTryFinally(Statement body, Statement finalizer)
      : super(body, finalizer);

  @override
  void _inferStatement(ShadowTypeInferrer inferrer) {
    inferrer.listener.tryFinallyEnter(this);
    inferrer.inferStatement(body);
    inferrer.inferStatement(finalizer);
    inferrer.listener.tryFinallyExit(this);
  }
}

/// Concrete implementation of [TypeInferenceEngine] specialized to work with
/// kernel objects.
class ShadowTypeInferenceEngine extends TypeInferenceEngineImpl {
  ShadowTypeInferenceEngine(Instrumentation instrumentation, bool strongMode)
      : super(instrumentation, strongMode);

  @override
  TypeInferrer createDisabledTypeInferrer() =>
      new TypeInferrerDisabled(typeSchemaEnvironment);

  @override
  ShadowTypeInferrer createLocalTypeInferrer(
      Uri uri,
      TypeInferenceListener listener,
      InterfaceType thisType,
      SourceLibraryBuilder library) {
    return new ShadowTypeInferrer._(
        this, uri, listener, false, thisType, library);
  }

  @override
  ShadowTypeInferrer createTopLevelTypeInferrer(TypeInferenceListener listener,
      InterfaceType thisType, ShadowField field) {
    return field._typeInferrer = new ShadowTypeInferrer._(
        this, field.fileUri, listener, true, thisType, null);
  }

  @override
  ShadowTypeInferrer getFieldTypeInferrer(ShadowField field) {
    return field._typeInferrer;
  }
}

/// Concrete implementation of [TypeInferrer] specialized to work with kernel
/// objects.
class ShadowTypeInferrer extends TypeInferrerImpl {
  @override
  final typePromoter;

  ShadowTypeInferrer._(
      ShadowTypeInferenceEngine engine,
      Uri uri,
      TypeInferenceListener listener,
      bool topLevel,
      InterfaceType thisType,
      SourceLibraryBuilder library)
      : typePromoter = new ShadowTypePromoter(engine.typeSchemaEnvironment),
        super(engine, uri, listener, topLevel, thisType, library);

  @override
  Expression getFieldInitializer(ShadowField field) {
    return field.initializer;
  }

  @override
  DartType inferExpression(
      Expression expression, DartType typeContext, bool typeNeeded) {
    // It isn't safe to do type inference on an expression without a parent,
    // because type inference might cause us to have to replace one expression
    // with another, and we can only replace a node if it has a parent pointer.
    assert(expression.parent != null);

    // For full (non-top level) inference, we need access to the BuilderHelper
    // so that we can perform error recovery.
    assert(isTopLevel || helper != null);

    // When doing top level inference, we skip subexpressions whose type isn't
    // needed so that we don't induce bogus dependencies on fields mentioned in
    // those subexpressions.
    if (!typeNeeded && isTopLevel) return null;

    if (expression is ShadowExpression) {
      // Use polymorphic dispatch on [KernelExpression] to perform whatever kind
      // of type inference is correct for this kind of statement.
      // TODO(paulberry): experiment to see if dynamic dispatch would be better,
      // so that the type hierarchy will be simpler (which may speed up "is"
      // checks).
      return expression._inferExpression(this, typeContext);
    } else {
      // Encountered an expression type for which type inference is not yet
      // implemented, so just infer dynamic for now.
      // TODO(paulberry): once the BodyBuilder uses shadow classes for
      // everything, this case should no longer be needed.
      return typeNeeded ? const DynamicType() : null;
    }
  }

  @override
  DartType inferFieldTopLevel(
      ShadowField field, DartType type, bool typeNeeded) {
    if (field.initializer == null) return const DynamicType();
    return inferExpression(field.initializer, type, typeNeeded);
  }

  @override
  void inferInitializer(BuilderHelper helper, Initializer initializer) {
    assert(initializer is ShadowInitializer);
    this.helper = helper;
    // Use polymorphic dispatch on [KernelInitializer] to perform whatever
    // kind of type inference is correct for this kind of initializer.
    // TODO(paulberry): experiment to see if dynamic dispatch would be better,
    // so that the type hierarchy will be simpler (which may speed up "is"
    // checks).
    ShadowInitializer kernelInitializer = initializer;
    kernelInitializer._inferInitializer(this);
    this.helper = null;
  }

  @override
  void inferStatement(Statement statement) {
    // For full (non-top level) inference, we need access to the BuilderHelper
    // so that we can perform error recovery.
    if (!isTopLevel) assert(helper != null);

    if (statement is ShadowStatement) {
      // Use polymorphic dispatch on [KernelStatement] to perform whatever kind
      // of type inference is correct for this kind of statement.
      // TODO(paulberry): experiment to see if dynamic dispatch would be better,
      // so that the type hierarchy will be simpler (which may speed up "is"
      // checks).
      return statement._inferStatement(this);
    } else {
      // Encountered a statement type for which type inference is not yet
      // implemented, so just skip it for now.
      // TODO(paulberry): once the BodyBuilder uses shadow classes for
      // everything, this case should no longer be needed.
    }
  }
}

/// Shadow object for [TypeLiteral].
class ShadowTypeLiteral extends TypeLiteral implements ShadowExpression {
  /// The name of the import prefix preceding the referenced type literal;
  /// or `null` if the reference is not prefixed.
  final String prefixName;

  ShadowTypeLiteral(this.prefixName, DartType type) : super(type);

  @override
  DartType _inferExpression(ShadowTypeInferrer inferrer, DartType typeContext) {
    inferrer.listener.typeLiteralEnter(this, prefixName, typeContext);
    var inferredType = inferrer.coreTypes.typeClass.rawType;
    inferrer.listener.typeLiteralExit(this, inferredType);
    return inferredType;
  }
}

/// Concrete implementation of [TypePromoter] specialized to work with kernel
/// objects.
class ShadowTypePromoter extends TypePromoterImpl {
  ShadowTypePromoter(TypeSchemaEnvironment typeSchemaEnvironment)
      : super(typeSchemaEnvironment);

  @override
  int getVariableFunctionNestingLevel(VariableDeclaration variable) {
    if (variable is ShadowVariableDeclaration) {
      return variable._functionNestingLevel;
    } else {
      // Hack to deal with the fact that BodyBuilder still creates raw
      // VariableDeclaration objects sometimes.
      // TODO(paulberry): get rid of this once the type parameter is
      // KernelVariableDeclaration.
      return 0;
    }
  }

  @override
  bool isPromotionCandidate(VariableDeclaration variable) {
    assert(variable is ShadowVariableDeclaration);
    ShadowVariableDeclaration kernelVariableDeclaration = variable;
    return !kernelVariableDeclaration._isLocalFunction;
  }

  @override
  bool sameExpressions(Expression a, Expression b) {
    return identical(a, b);
  }

  @override
  void setVariableMutatedAnywhere(VariableDeclaration variable) {
    if (variable is ShadowVariableDeclaration) {
      variable._mutatedAnywhere = true;
    } else {
      // Hack to deal with the fact that BodyBuilder still creates raw
      // VariableDeclaration objects sometimes.
      // TODO(paulberry): get rid of this once the type parameter is
      // KernelVariableDeclaration.
    }
  }

  @override
  void setVariableMutatedInClosure(VariableDeclaration variable) {
    if (variable is ShadowVariableDeclaration) {
      variable._mutatedInClosure = true;
    } else {
      // Hack to deal with the fact that BodyBuilder still creates raw
      // VariableDeclaration objects sometimes.
      // TODO(paulberry): get rid of this once the type parameter is
      // KernelVariableDeclaration.
    }
  }

  @override
  bool wasVariableMutatedAnywhere(VariableDeclaration variable) {
    if (variable is ShadowVariableDeclaration) {
      return variable._mutatedAnywhere;
    } else {
      // Hack to deal with the fact that BodyBuilder still creates raw
      // VariableDeclaration objects sometimes.
      // TODO(paulberry): get rid of this once the type parameter is
      // KernelVariableDeclaration.
      return true;
    }
  }
}

/// Concrete shadow object representing an assignment to a local variable.
class ShadowVariableAssignment extends ShadowComplexAssignment {
  ShadowVariableAssignment(Expression rhs) : super(rhs);

  @override
  DartType _getWriteType(ShadowTypeInferrer inferrer) {
    VariableSet write = this.write;
    return write.variable.type;
  }

  @override
  DartType _inferExpression(ShadowTypeInferrer inferrer, DartType typeContext) {
    inferrer.listener.variableAssignEnter(desugared, typeContext, this.write);
    DartType readType;
    var read = this.read;
    if (read is VariableGet) {
      readType = read.promotedType ?? read.variable.type;
    }
    DartType writeContext;
    var write = this.write;
    if (write is VariableSet) {
      writeContext = write.variable.type;
      if (read != null) {
        _storeLetType(inferrer, read, writeContext);
      }
    }
    var inferredResult = _inferRhs(inferrer, readType, writeContext);
    inferrer.listener.variableAssignExit(desugared, writeContext, write,
        inferredResult.combiner, inferredResult.type);
    _replaceWithDesugared();
    return inferredResult.type;
  }
}

/// Concrete shadow object representing a variable declaration in kernel form.
class ShadowVariableDeclaration extends VariableDeclaration
    implements ShadowStatement {
  final bool _implicitlyTyped;

  final int _functionNestingLevel;

  bool _mutatedInClosure = false;

  bool _mutatedAnywhere = false;

  final bool _isLocalFunction;

  ShadowVariableDeclaration(String name, this._functionNestingLevel,
      {Expression initializer,
      DartType type,
      bool isFinal: false,
      bool isConst: false,
      bool isFieldFormal: false,
      bool isCovariant: false,
      bool isLocalFunction: false})
      : _implicitlyTyped = type == null,
        _isLocalFunction = isLocalFunction,
        super(name,
            initializer: initializer,
            type: type ?? const DynamicType(),
            isFinal: isFinal,
            isConst: isConst,
            isFieldFormal: isFieldFormal,
            isCovariant: isCovariant);

  ShadowVariableDeclaration.forEffect(
      Expression initializer, this._functionNestingLevel)
      : _implicitlyTyped = false,
        _isLocalFunction = false,
        super.forValue(initializer);

  ShadowVariableDeclaration.forValue(
      Expression initializer, this._functionNestingLevel)
      : _implicitlyTyped = true,
        _isLocalFunction = false,
        super.forValue(initializer);

  @override
  void _inferStatement(ShadowTypeInferrer inferrer) {
    inferrer.listener.variableDeclarationEnter(this);
    var declaredType = _implicitlyTyped ? null : type;
    DartType inferredType;
    DartType initializerType;
    if (initializer != null) {
      initializerType = inferrer.inferExpression(
          initializer, declaredType, !inferrer.isTopLevel || _implicitlyTyped);
      inferredType = inferrer.inferDeclarationType(initializerType);
    } else {
      inferredType = const DynamicType();
    }
    if (inferrer.strongMode && _implicitlyTyped) {
      inferrer.instrumentation?.record(inferrer.uri, fileOffset, 'type',
          new InstrumentationValueForType(inferredType));
      type = inferredType;
    }
    if (initializer != null) {
      var replacedInitializer = inferrer.checkAssignability(
          type, initializerType, initializer, fileOffset);
      if (replacedInitializer != null) {
        initializer = replacedInitializer;
      }
    }
    inferrer.listener.variableDeclarationExit(this, inferredType);
  }

  /// Determine whether the given [ShadowVariableDeclaration] had an implicit
  /// type.
  ///
  /// This is static to avoid introducing a method that would be visible to
  /// the kernel.
  static bool isImplicitlyTyped(ShadowVariableDeclaration variable) =>
      variable._implicitlyTyped;

  /// Determines whether the given [ShadowVariableDeclaration] represents a
  /// local function.
  ///
  /// This is static to avoid introducing a method that would be visible to the
  /// kernel.
  static bool isLocalFunction(ShadowVariableDeclaration variable) =>
      variable._isLocalFunction;
}

/// Concrete shadow object representing a read from a variable in kernel form.
class ShadowVariableGet extends VariableGet implements ShadowExpression {
  final TypePromotionFact _fact;

  final TypePromotionScope _scope;

  ShadowVariableGet(VariableDeclaration variable, this._fact, this._scope)
      : super(variable);

  @override
  DartType _inferExpression(ShadowTypeInferrer inferrer, DartType typeContext) {
    var variable = this.variable as ShadowVariableDeclaration;
    bool mutatedInClosure = variable._mutatedInClosure;
    DartType declaredOrInferredType = variable.type;

    inferrer.listener.variableGetEnter(this, typeContext);
    DartType promotedType = inferrer.typePromoter
        .computePromotedType(_fact, _scope, mutatedInClosure);
    if (promotedType != null) {
      inferrer.instrumentation?.record(inferrer.uri, fileOffset, 'promotedType',
          new InstrumentationValueForType(promotedType));
    }
    this.promotedType = promotedType;
    var type = promotedType ?? declaredOrInferredType;
    if (variable._isLocalFunction) {
      type = inferrer.instantiateTearOff(type, typeContext, this);
    }
    var inferredType = type;
    inferrer.listener.variableGetExit(this, inferredType);
    return inferredType;
  }
}

/// Concrete shadow object representing a while loop in kernel form.
class ShadowWhileStatement extends WhileStatement implements ShadowStatement {
  ShadowWhileStatement(Expression condition, Statement body)
      : super(condition, body);

  @override
  void _inferStatement(ShadowTypeInferrer inferrer) {
    inferrer.listener.whileStatementEnter(this);
    var expectedType = inferrer.coreTypes.boolClass.rawType;
    var actualType =
        inferrer.inferExpression(condition, expectedType, !inferrer.isTopLevel);
    inferrer.checkAssignability(
        expectedType, actualType, condition, condition.fileOffset);
    inferrer.inferStatement(body);
    inferrer.listener.whileStatementExit(this);
  }
}

/// Concrete shadow object representing a yield statement in kernel form.
class ShadowYieldStatement extends YieldStatement implements ShadowStatement {
  ShadowYieldStatement(Expression expression, {bool isYieldStar: false})
      : super(expression, isYieldStar: isYieldStar);

  @override
  void _inferStatement(ShadowTypeInferrer inferrer) {
    inferrer.listener.yieldStatementEnter(this);
    var closureContext = inferrer.closureContext;
    var typeContext =
        closureContext.isGenerator ? closureContext.returnContext : null;
    if (isYieldStar && typeContext != null) {
      typeContext = inferrer.wrapType(
          typeContext,
          closureContext.isAsync
              ? inferrer.coreTypes.streamClass
              : inferrer.coreTypes.iterableClass);
    }
    var inferredType = inferrer.inferExpression(expression, typeContext, true);
    closureContext.handleYield(
        inferrer, isYieldStar, inferredType, expression, fileOffset);
    inferrer.listener.yieldStatementExit(this);
  }
}

/// The result of inference for a RHS of an assignment.
class _ComplexAssignmentInferenceResult {
  /// The resolved combiner [Procedure], e.g. `operator+` for `a += 2`, or
  /// `null` if the assignment is not compound.
  final Procedure combiner;

  /// The inferred type of the assignment expression.
  final DartType type;

  _ComplexAssignmentInferenceResult(this.combiner, this.type);
}

class _UnfinishedCascade extends Expression {
  accept(v) => unsupported("accept", -1, null);

  accept1(v, arg) => unsupported("accept1", -1, null);

  getStaticType(types) => unsupported("getStaticType", -1, null);

  transformChildren(v) => unsupported("transformChildren", -1, null);

  visitChildren(v) => unsupported("visitChildren", -1, null);
}
