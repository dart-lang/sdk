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
import 'package:front_end/src/base/instrumentation.dart';
import 'package:front_end/src/fasta/type_inference/dependency_collector.dart';
import 'package:front_end/src/fasta/type_inference/type_inference_engine.dart';
import 'package:front_end/src/fasta/type_inference/type_inference_listener.dart';
import 'package:front_end/src/fasta/type_inference/type_inferrer.dart';
import 'package:front_end/src/fasta/type_inference/type_promotion.dart';
import 'package:front_end/src/fasta/type_inference/type_schema.dart';
import 'package:front_end/src/fasta/type_inference/type_schema_elimination.dart';
import 'package:kernel/ast.dart'
    hide InvalidExpression, InvalidInitializer, InvalidStatement;
import 'package:kernel/frontend/accessors.dart';
import 'package:kernel/type_environment.dart';

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
  void _collectDependencies(ShadowDependencyCollector collector) {
    // No inference dependencies.
  }

  @override
  DartType _inferExpression(
      ShadowTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    typeNeeded =
        inferrer.listener.asExpressionEnter(this, typeContext) || typeNeeded;
    inferrer.inferExpression(operand, null, false);
    var inferredType = typeNeeded ? type : null;
    inferrer.listener.asExpressionExit(this, inferredType);
    return inferredType;
  }
}

/// Concrete shadow object representing an assert initializer in kernel form.
class ShadowAssertInitializer extends LocalInitializer
    implements ShadowInitializer {
  /// The assert statement performing the check
  AssertStatement _statement;

  ShadowAssertInitializer(VariableDeclaration variable, this._statement)
      : super(variable);

  @override
  void _inferInitializer(ShadowTypeInferrer inferrer) {
    inferrer.listener.assertInitializerEnter(this);
    inferrer.inferStatement(_statement);
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
    inferrer.inferExpression(
        condition, inferrer.coreTypes.boolClass.rawType, false);
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
  void _collectDependencies(ShadowDependencyCollector collector) {
    // Inference dependencies are the dependencies of the awaited expression.
    collector.collectDependencies(operand);
  }

  @override
  DartType _inferExpression(
      ShadowTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    typeNeeded =
        inferrer.listener.awaitExpressionEnter(this, typeContext) || typeNeeded;
    if (!inferrer.typeSchemaEnvironment.isEmptyContext(typeContext)) {
      typeContext = inferrer.wrapFutureOrType(typeContext);
    }
    var inferredType =
        inferrer.inferExpression(operand, typeContext, typeNeeded);
    inferredType = inferrer.typeSchemaEnvironment.flattenFutures(inferredType);
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
  void _collectDependencies(ShadowDependencyCollector collector) {
    // No inference dependencies.
  }

  @override
  DartType _inferExpression(
      ShadowTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    typeNeeded =
        inferrer.listener.boolLiteralEnter(this, typeContext) || typeNeeded;
    var inferredType = typeNeeded ? inferrer.coreTypes.boolClass.rawType : null;
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
  void _collectDependencies(ShadowDependencyCollector collector) {
    // The inference dependencies are the inference dependencies of the cascade
    // target.
    collector.collectDependencies(variable.initializer);
  }

  @override
  DartType _inferExpression(
      ShadowTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    typeNeeded = inferrer.listener.cascadeExpressionEnter(this, typeContext) ||
        typeNeeded;
    var lhsType = inferrer.inferExpression(
        variable.initializer, typeContext, typeNeeded || inferrer.strongMode);
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

  @override
  void _collectDependencies(ShadowDependencyCollector collector) {
    // Assignment expressions are not immediately evident expressions.
    collector.recordNotImmediatelyEvident(fileOffset);
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

  DartType _inferRhs(ShadowTypeInferrer inferrer, DartType writeContext) {
    DartType inferredType = writeContext ?? const DynamicType();
    if (nullAwareCombiner != null) {
      var rhsType = inferrer.inferExpression(rhs, writeContext, true);
      _storeLetType(inferrer, rhs, rhsType);
      MethodInvocation equalsInvocation = nullAwareCombiner.condition;
      inferrer.findMethodInvocationMember(writeContext, equalsInvocation,
          silent: true);
      var combinedType = inferrer.typeSchemaEnvironment
          .getLeastUpperBound(inferredType, rhsType);
      if (inferrer.strongMode) {
        nullAwareCombiner.staticType = combinedType;
      }
      return combinedType;
    } else if (combiner != null) {
      bool isOverloadedArithmeticOperator = false;
      var combinerMember = inferrer
          .findMethodInvocationMember(writeContext, combiner, silent: true);
      if (combinerMember is Procedure) {
        isOverloadedArithmeticOperator = inferrer.typeSchemaEnvironment
            .isOverloadedArithmeticOperatorAndType(
                combinerMember, writeContext);
      }
      DartType combinedType;
      if (isPostIncDec) {
        combinedType = inferredType;
      } else {
        DartType rhsType;
        if (isPreIncDec) {
          rhsType = inferrer.coreTypes.intClass.rawType;
        } else {
          // Analyzer uses a null context for the RHS here.
          // TODO(paulberry): improve on this.
          rhsType = inferrer.inferExpression(rhs, null, true);
          _storeLetType(inferrer, rhs, rhsType);
        }
        if (isOverloadedArithmeticOperator) {
          combinedType = inferrer.typeSchemaEnvironment
              .getTypeOfOverloadedArithmetic(inferredType, rhsType);
        } else {
          combinedType = inferrer
              .getCalleeFunctionType(combinerMember, writeContext, false)
              .returnType;
        }
      }
      _storeLetType(inferrer, combiner, combinedType);
      return combinedType;
    } else {
      var rhsType = inferrer.inferExpression(rhs, writeContext, true);
      _storeLetType(inferrer, rhs, rhsType);
      return rhsType;
    }
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
  void _collectDependencies(ShadowDependencyCollector collector) {
    // Inference dependencies are the union of the inference dependencies of the
    // two returned sub-expressions.
    collector.collectDependencies(then);
    collector.collectDependencies(otherwise);
  }

  @override
  DartType _inferExpression(
      ShadowTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    typeNeeded =
        inferrer.listener.conditionalExpressionEnter(this, typeContext) ||
            typeNeeded;
    if (!inferrer.isTopLevel ||
        TypeInferenceEngineImpl.expandedTopLevelInference) {
      inferrer.inferExpression(
          condition, inferrer.coreTypes.boolClass.rawType, false);
    }
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
    var inferredType = typeNeeded ? type : null;
    inferrer.listener.conditionalExpressionExit(this, inferredType);
    return inferredType;
  }
}

/// Shadow object for [ConstructorInvocation].
class ShadowConstructorInvocation extends ConstructorInvocation
    implements ShadowExpression {
  final Member _initialTarget;

  ShadowConstructorInvocation(
      Constructor target, this._initialTarget, Arguments arguments,
      {bool isConst: false})
      : super(target, arguments, isConst: isConst);

  @override
  void _collectDependencies(ShadowDependencyCollector collector) {
    // No inference dependencies.
  }

  @override
  DartType _inferExpression(
      ShadowTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    typeNeeded =
        inferrer.listener.constructorInvocationEnter(this, typeContext) ||
            typeNeeded;
    var inferredType = inferrer.inferInvocation(
        typeContext,
        typeNeeded,
        fileOffset,
        _initialTarget.function.functionType,
        computeConstructorReturnType(_initialTarget),
        arguments,
        isConst: isConst);
    inferrer.listener.constructorInvocationExit(this, inferredType);
    return inferredType;
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

/// Concrete implementation of [DependencyCollector] specialized to work with
/// kernel objects.
class ShadowDependencyCollector extends DependencyCollectorImpl {
  @override
  void collectDependencies(Expression expression) {
    if (expression is ShadowExpression) {
      // Use polymorphic dispatch on [KernelExpression] to perform whatever kind
      // of type inference is correct for this kind of statement.
      // TODO(paulberry): experiment to see if dynamic dispatch would be better,
      // so that the type hierarchy will be simpler (which may speed up "is"
      // checks).
      expression._collectDependencies(this);
    } else {
      // Encountered an expression type for which type inference is not yet
      // implemented, so just assume the expression does not have an immediately
      // evident type for now.
      // TODO(paulberry): once the BodyBuilder uses shadow classes for
      // everything, this case should no longer be needed.
      recordNotImmediatelyEvident(expression.fileOffset);
    }
  }
}

/// Shadow object for [DirectMethodInvocation].
class ShadowDirectMethodInvocation extends DirectMethodInvocation
    implements ShadowExpression {
  ShadowDirectMethodInvocation(
      Expression receiver, Procedure target, Arguments arguments)
      : super(receiver, target, arguments);

  @override
  void _collectDependencies(ShadowDependencyCollector collector) {
    // DirectMethodInvocation can only occur as a result of a use of `super`,
    // and `super` can't appear inside a field initializer.  So this code should
    // never be reached.
    unsupported(
        "DirectMethodInvocation._collectDependencies", fileOffset, null);
  }

  @override
  DartType _inferExpression(
      ShadowTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    inferrer.instrumentation?.record(Uri.parse(inferrer.uri), fileOffset,
        'target', new InstrumentationValueForMember(target));
    return inferrer.inferMethodInvocation(
        this, receiver, fileOffset, false, typeContext, typeNeeded,
        interfaceMember: target, methodName: target.name, arguments: arguments);
  }
}

/// Shadow object for [DirectPropertyGet].
class ShadowDirectPropertyGet extends DirectPropertyGet
    implements ShadowExpression {
  ShadowDirectPropertyGet(Expression receiver, Member target)
      : super(receiver, target);

  @override
  void _collectDependencies(ShadowDependencyCollector collector) {
    // DirectPropertyGet can only occur as a result of a use of `super`, and
    // `super` can't appear inside a field initializer.  So this code should
    // never be reached.
    unsupported("DirectPropertyGet._collectDependencies", fileOffset, null);
  }

  @override
  DartType _inferExpression(
      ShadowTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    return inferrer.inferPropertyGet(
        this, receiver, fileOffset, typeContext, typeNeeded,
        propertyName: target.name);
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
    inferrer.inferExpression(
        condition, inferrer.coreTypes.boolClass.rawType, false);
    inferrer.listener.doStatementExit(this);
  }
}

/// Concrete shadow object representing a double literal in kernel form.
class ShadowDoubleLiteral extends DoubleLiteral implements ShadowExpression {
  ShadowDoubleLiteral(double value) : super(value);

  @override
  void _collectDependencies(ShadowDependencyCollector collector) {
    // No inference dependencies.
  }

  @override
  DartType _inferExpression(
      ShadowTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    typeNeeded =
        inferrer.listener.doubleLiteralEnter(this, typeContext) || typeNeeded;
    var inferredType =
        typeNeeded ? inferrer.coreTypes.doubleClass.rawType : null;
    inferrer.listener.doubleLiteralExit(this, inferredType);
    return inferredType;
  }
}

/// Common base class for shadow objects representing expressions in kernel
/// form.
abstract class ShadowExpression implements Expression {
  /// Collects any dependencies of [expression], and reports errors if the
  /// expression does not have an immediately evident type.
  void _collectDependencies(ShadowDependencyCollector collector);

  /// Calls back to [inferrer] to perform type inference for whatever concrete
  /// type of [ShadowExpression] this is.
  DartType _inferExpression(
      ShadowTypeInferrer inferrer, DartType typeContext, bool typeNeeded);
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
  final Member _initialTarget;

  ShadowFactoryConstructorInvocation(
      Procedure target, this._initialTarget, Arguments arguments,
      {bool isConst: false})
      : super(target, arguments, isConst: isConst);

  @override
  void _collectDependencies(ShadowDependencyCollector collector) {
    // No inference dependencies.
  }

  @override
  DartType _inferExpression(
      ShadowTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    typeNeeded =
        inferrer.listener.constructorInvocationEnter(this, typeContext) ||
            typeNeeded;
    var inferredType = inferrer.inferInvocation(
        typeContext,
        typeNeeded,
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
  AccessorNode _accessorNode;

  @override
  ShadowTypeInferrer _typeInferrer;

  ShadowField(Name name, {String fileUri}) : super(name, fileUri: fileUri) {}

  @override
  void setInferredType(
      TypeInferenceEngineImpl engine, String uri, DartType inferredType) {
    engine.instrumentation?.record(Uri.parse(uri), fileOffset, 'topType',
        new InstrumentationValueForType(inferredType));
    type = inferredType;
  }
}

/// Concrete shadow object representing a field initializer in kernel form.
class ShadowFieldInitializer extends FieldInitializer
    implements ShadowInitializer {
  ShadowFieldInitializer(Field field, Expression value) : super(field, value);

  @override
  void _inferInitializer(ShadowTypeInferrer inferrer) {
    inferrer.listener.fieldInitializerEnter(this);
    inferrer.inferExpression(value, field.type, false);
    inferrer.listener.fieldInitializerExit(this);
  }
}

/// Concrete shadow object representing a for-in loop in kernel form.
class ShadowForInStatement extends ForInStatement implements ShadowStatement {
  final bool _declaresVariable;

  ShadowForInStatement(VariableDeclaration variable, Expression iterable,
      Statement body, this._declaresVariable,
      {bool isAsync: false})
      : super(variable, iterable, body, isAsync: isAsync);

  @override
  void _inferStatement(ShadowTypeInferrer inferrer) {
    inferrer.listener.forInStatementEnter(this);
    var iterableClass = isAsync
        ? inferrer.coreTypes.streamClass
        : inferrer.coreTypes.iterableClass;
    DartType context;
    bool typeNeeded = false;
    ShadowVariableDeclaration variable;
    if (_declaresVariable) {
      variable = this.variable;
      if (inferrer.strongMode && variable._implicitlyTyped) {
        typeNeeded = true;
        // TODO(paulberry): In this case, should the context be `Iterable<?>`?
      } else {
        context = inferrer.wrapType(variable.type, iterableClass);
      }
    } else {
      // TODO(paulberry): In this case, should the context be based on the
      // declared type of the loop variable?
      // TODO(paulberry): Note that when [_declaresVariable] is `false`, the
      // body starts with an assignment from the synthetic loop variable to
      // another variable.  We need to make sure any type inference diagnostics
      // that occur related to this assignment are reported at the correct
      // locations.
    }
    var inferredExpressionType = inferrer.resolveTypeParameter(
        inferrer.inferExpression(iterable, context, typeNeeded));
    if (typeNeeded) {
      var inferredType = const DynamicType();
      if (inferredExpressionType is InterfaceType) {
        InterfaceType supertype = inferrer.classHierarchy
            .getTypeAsInstanceOf(inferredExpressionType, iterableClass);
        if (supertype != null) {
          inferredType = supertype.typeArguments[0];
        }
      }
      inferrer.instrumentation?.record(
          Uri.parse(inferrer.uri),
          variable.fileOffset,
          'type',
          new InstrumentationValueForType(inferredType));
      variable.type = inferredType;
    }
    inferrer.inferStatement(body);
    inferrer.listener.forInStatementExit(this);
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
      inferrer.inferExpression(
          condition, inferrer.coreTypes.boolClass.rawType, false);
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
    inferrer.inferLocalFunction(function, null, false, fileOffset,
        _hasImplicitReturnType ? null : function.returnType);
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
  void _collectDependencies(ShadowDependencyCollector collector) {
    for (ShadowVariableDeclaration parameter in function.positionalParameters) {
      if (parameter._implicitlyTyped) {
        collector.recordNotImmediatelyEvident(parameter.fileOffset);
      }
    }
    for (ShadowVariableDeclaration parameter in function.namedParameters) {
      if (parameter._implicitlyTyped) {
        collector.recordNotImmediatelyEvident(parameter.fileOffset);
      }
    }
    var body = function.body;
    if (body is ReturnStatement) {
      // The inference dependencies are the inference dependencies of the return
      // expression.
      collector.collectDependencies(body.expression);
    } else {
      collector.recordNotImmediatelyEvident(fileOffset);
    }
  }

  @override
  DartType _inferExpression(
      ShadowTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    typeNeeded = inferrer.listener.functionExpressionEnter(this, typeContext) ||
        typeNeeded;
    var inferredType = inferrer.inferLocalFunction(
        function, typeContext, typeNeeded, fileOffset, null);
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
  void _collectDependencies(ShadowDependencyCollector collector) {
    // If-null expressions are not immediately evident expressions.
    collector.recordNotImmediatelyEvident(fileOffset);
  }

  @override
  DartType _inferExpression(
      ShadowTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    typeNeeded = inferrer.listener.ifNullEnter(this, typeContext) || typeNeeded;
    // To infer `e0 ?? e1` in context K:
    // - Infer e0 in context K to get T0
    var lhsType = inferrer.inferExpression(_lhs, typeContext, true);
    if (inferrer.strongMode) {
      variable.type = lhsType;
    }
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
    inferrer.inferExpression(
        condition, inferrer.coreTypes.boolClass.rawType, false);
    inferrer.inferStatement(then);
    if (otherwise != null) inferrer.inferStatement(otherwise);
    inferrer.listener.ifStatementExit(this);
  }
}

/// Concrete shadow object representing an assignment to a target for which
/// assignment is not allowed.
class ShadowIllegalAssignment extends ShadowComplexAssignment {
  ShadowIllegalAssignment(Expression rhs) : super(rhs);
}

/// Concrete shadow object representing an assignment to a target of the form
/// `a[b]`.
class ShadowIndexAssign extends ShadowComplexAssignmentWithReceiver {
  /// In an assignment to an index expression, the index expression.
  Expression index;

  ShadowIndexAssign(Expression receiver, this.index, Expression rhs,
      {bool isSuper: false})
      : super(receiver, rhs, isSuper);

  @override
  List<String> _getToStringParts() {
    var parts = super._getToStringParts();
    if (index != null) parts.add('index=$index');
    return parts;
  }

  @override
  DartType _inferExpression(
      ShadowTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    typeNeeded = inferrer.listener.indexAssignEnter(desugared, typeContext) ||
        typeNeeded;
    var receiverType = _inferReceiver(inferrer);
    if (read != null) {
      var readMember =
          inferrer.findMethodInvocationMember(receiverType, read, silent: true);
      var calleeFunctionType =
          inferrer.getCalleeFunctionType(readMember, receiverType, false);
      _storeLetType(inferrer, read, calleeFunctionType.returnType);
    }
    var writeMember = inferrer.findMethodInvocationMember(receiverType, write);
    // To replicate analyzer behavior, we base type inference on the write
    // member.  TODO(paulberry): would it be better to use the read member
    // when doing compound assignment?
    var calleeType =
        inferrer.getCalleeFunctionType(writeMember, receiverType, false);
    _storeLetType(inferrer, write, calleeType.returnType);
    DartType indexContext;
    DartType writeContext;
    if (calleeType.positionalParameters.length >= 2) {
      // TODO(paulberry): we ought to get a context for the index expression
      // from the index formal parameter, but analyzer doesn't so for now we
      // replicate its behavior.
      indexContext = null;
      writeContext = calleeType.positionalParameters[1];
    }
    var indexType = inferrer.inferExpression(index, indexContext, true);
    _storeLetType(inferrer, index, indexType);
    var inferredType = _inferRhs(inferrer, writeContext);
    inferrer.listener.indexAssignExit(desugared, inferredType);
    return inferredType;
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
  void _collectDependencies(ShadowDependencyCollector collector) {
    // No inference dependencies.
  }

  @override
  DartType _inferExpression(
      ShadowTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    typeNeeded =
        inferrer.listener.intLiteralEnter(this, typeContext) || typeNeeded;
    var inferredType = typeNeeded ? inferrer.coreTypes.intClass.rawType : null;
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
  void _collectDependencies(ShadowDependencyCollector collector) {
    // No inference dependencies.
  }

  @override
  DartType _inferExpression(
      ShadowTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    typeNeeded =
        inferrer.listener.isExpressionEnter(this, typeContext) || typeNeeded;
    inferrer.inferExpression(operand, null, false);
    var inferredType = typeNeeded ? inferrer.coreTypes.boolClass.rawType : null;
    inferrer.listener.isExpressionExit(this, inferredType);
    return inferredType;
  }
}

/// Concrete shadow object representing an inverted "is" test in kernel form.
class ShadowIsNotExpression extends Not implements ShadowExpression {
  ShadowIsNotExpression(Expression operand, DartType type, int charOffset)
      : super(new IsExpression(operand, type)..fileOffset = charOffset);

  @override
  void _collectDependencies(ShadowDependencyCollector collector) {
    // No inference dependencies.
  }

  @override
  DartType _inferExpression(
      ShadowTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    IsExpression isExpression = this.operand;
    typeNeeded =
        inferrer.listener.isNotExpressionEnter(this, typeContext) || typeNeeded;
    inferrer.inferExpression(isExpression.operand, null, false);
    var inferredType = typeNeeded ? inferrer.coreTypes.boolClass.rawType : null;
    inferrer.listener.isNotExpressionExit(this, inferredType);
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
  void _collectDependencies(ShadowDependencyCollector collector) {
    if (_declaredTypeArgument == null) {
      expressions.forEach(collector.collectDependencies);
    }
  }

  @override
  DartType _inferExpression(
      ShadowTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    typeNeeded =
        inferrer.listener.listLiteralEnter(this, typeContext) || typeNeeded;
    var listClass = inferrer.coreTypes.listClass;
    var listType = listClass.thisType;
    List<DartType> inferredTypes;
    DartType inferredTypeArgument;
    List<DartType> formalTypes;
    List<DartType> actualTypes;
    bool inferenceNeeded = _declaredTypeArgument == null && inferrer.strongMode;
    if (inferenceNeeded) {
      inferredTypes = [const UnknownType()];
      inferrer.typeSchemaEnvironment.inferGenericFunctionOrType(listType,
          listClass.typeParameters, null, null, typeContext, inferredTypes,
          isConst: isConst);
      inferredTypeArgument = inferredTypes[0];
      formalTypes = [];
      actualTypes = [];
    } else {
      inferredTypeArgument = _declaredTypeArgument ?? const DynamicType();
    }
    if (inferenceNeeded || !inferrer.isTopLevel) {
      for (var expression in expressions) {
        var expressionType = inferrer.inferExpression(
            expression, inferredTypeArgument, inferenceNeeded);
        if (inferenceNeeded) {
          formalTypes.add(listType.typeArguments[0]);
          actualTypes.add(expressionType);
        }
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
      inferrer.instrumentation?.record(
          Uri.parse(inferrer.uri),
          fileOffset,
          'typeArgs',
          new InstrumentationValueForTypeArgs([inferredTypeArgument]));
      typeArgument = inferredTypeArgument;
    }
    var inferredType = typeNeeded
        ? new InterfaceType(listClass, [inferredTypeArgument])
        : null;
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
  void _collectDependencies(ShadowDependencyCollector collector) {
    // No inference dependencies.
  }

  @override
  DartType _inferExpression(
      ShadowTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    typeNeeded = inferrer.listener.logicalExpressionEnter(this, typeContext) ||
        typeNeeded;
    var boolType = inferrer.coreTypes.boolClass.rawType;
    inferrer.inferExpression(left, boolType, false);
    inferrer.inferExpression(right, boolType, false);
    var inferredType = typeNeeded ? boolType : null;
    inferrer.listener.logicalExpressionExit(this, inferredType);
    return inferredType;
  }
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
  void _collectDependencies(ShadowDependencyCollector collector) {
    assert((_declaredKeyType == null) == (_declaredValueType == null));
    if (_declaredKeyType == null) {
      for (var entry in entries) {
        collector.collectDependencies(entry.key);
        collector.collectDependencies(entry.value);
      }
    }
  }

  @override
  DartType _inferExpression(
      ShadowTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    typeNeeded =
        inferrer.listener.mapLiteralEnter(this, typeContext) || typeNeeded;
    var mapClass = inferrer.coreTypes.mapClass;
    var mapType = mapClass.thisType;
    List<DartType> inferredTypes;
    DartType inferredKeyType;
    DartType inferredValueType;
    List<DartType> formalTypes;
    List<DartType> actualTypes;
    assert((_declaredKeyType == null) == (_declaredValueType == null));
    bool inferenceNeeded = _declaredKeyType == null && inferrer.strongMode;
    if (inferenceNeeded) {
      inferredTypes = [const UnknownType(), const UnknownType()];
      inferrer.typeSchemaEnvironment.inferGenericFunctionOrType(mapType,
          mapClass.typeParameters, null, null, typeContext, inferredTypes,
          isConst: isConst);
      inferredKeyType = inferredTypes[0];
      inferredValueType = inferredTypes[1];
      formalTypes = [];
      actualTypes = [];
    } else {
      inferredKeyType = _declaredKeyType ?? const DynamicType();
      inferredValueType = _declaredValueType ?? const DynamicType();
    }
    if (inferenceNeeded || !inferrer.isTopLevel) {
      for (var entry in entries) {
        var keyType = inferrer.inferExpression(
            entry.key, inferredKeyType, inferenceNeeded);
        var valueType = inferrer.inferExpression(
            entry.value, inferredValueType, inferenceNeeded);
        if (inferenceNeeded) {
          formalTypes.addAll(mapType.typeArguments);
          actualTypes.add(keyType);
          actualTypes.add(valueType);
        }
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
          Uri.parse(inferrer.uri),
          fileOffset,
          'typeArgs',
          new InstrumentationValueForTypeArgs(
              [inferredKeyType, inferredValueType]));
      keyType = inferredKeyType;
      valueType = inferredValueType;
    }
    var inferredType = typeNeeded
        ? new InterfaceType(mapClass, [inferredKeyType, inferredValueType])
        : null;
    inferrer.listener.mapLiteralExit(this, inferredType);
    return inferredType;
  }
}

/// Abstract shadow object representing a field or procedure in kernel form.
abstract class ShadowMember implements Member {
  String get fileUri;

  AccessorNode get _accessorNode;

  void set _accessorNode(AccessorNode value);

  ShadowTypeInferrer get _typeInferrer;

  void set _typeInferrer(ShadowTypeInferrer value);

  void setInferredType(
      TypeInferenceEngineImpl engine, String uri, DartType inferredType);

  static AccessorNode getAccessorNode(Member member) {
    if (member is ShadowMember) return member._accessorNode;
    return null;
  }

  static void recordCrossOverride(
      ShadowMember member, Member overriddenMember) {
    if (member._accessorNode != null) {
      member._accessorNode.crossOverrides.add(overriddenMember);
    }
  }

  static void recordOverride(ShadowMember member, Member overriddenMember) {
    if (member._accessorNode != null) {
      member._accessorNode.overrides.add(overriddenMember);
    }
    if (member is ShadowProcedure && member._methodNode != null) {
      member._methodNode.overrides.add(overriddenMember);
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
  void _collectDependencies(ShadowDependencyCollector collector) {
    // The inference dependencies are the inference dependencies of the
    // receiver.
    collector.collectDependencies(receiver);
    if (isOverloadableArithmeticOperator(name.name)) {
      collector.collectDependencies(arguments.positional[0]);
    }
  }

  @override
  DartType _inferExpression(
      ShadowTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    return inferrer.inferMethodInvocation(
        this, receiver, fileOffset, _isImplicitCall, typeContext, typeNeeded,
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
  void _collectDependencies(ShadowDependencyCollector collector) {
    collector.collectDependencies(variable.initializer);
  }

  @override
  DartType _inferExpression(
      ShadowTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    typeNeeded =
        inferrer.listener.namedFunctionExpressionEnter(this, typeContext) ||
            typeNeeded;
    var inferredType =
        inferrer.inferExpression(variable.initializer, typeContext, true);
    if (inferrer.strongMode) variable.type = inferredType;
    if (!typeNeeded) inferredType = null;
    inferrer.listener.namedFunctionExpressionExit(this, inferredType);
    return inferredType;
  }
}

/// Shadow object for [Not].
class ShadowNot extends Not implements ShadowExpression {
  ShadowNot(Expression operand) : super(operand);

  @override
  void _collectDependencies(ShadowDependencyCollector collector) {
    collector.collectDependencies(operand);
  }

  @override
  DartType _inferExpression(
      ShadowTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    typeNeeded = inferrer.listener.notEnter(this, typeContext) || typeNeeded;
    // First infer the receiver so we can look up the method that was invoked.
    var boolType = inferrer.coreTypes.boolClass.rawType;
    inferrer.inferExpression(operand, boolType, false);
    DartType inferredType = typeNeeded ? boolType : null;
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
  void _collectDependencies(ShadowDependencyCollector collector) {
    // Null aware expressions are not immediately evident.
    collector.recordNotImmediatelyEvident(fileOffset);
  }

  @override
  DartType _inferExpression(
      ShadowTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    var inferredType = inferrer.inferMethodInvocation(
        this,
        variable.initializer,
        fileOffset,
        false,
        typeContext,
        typeNeeded || inferrer.strongMode,
        receiverVariable: variable,
        desugaredInvocation: _desugaredInvocation);
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
  void _collectDependencies(ShadowDependencyCollector collector) {
    // Null aware expressions are not immediately evident.
    collector.recordNotImmediatelyEvident(fileOffset);
  }

  @override
  DartType _inferExpression(
      ShadowTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    var inferredType = inferrer.inferPropertyGet(this, variable.initializer,
        fileOffset, typeContext, typeNeeded || inferrer.strongMode,
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
  void _collectDependencies(ShadowDependencyCollector collector) {
    // No inference dependencies.
  }

  @override
  DartType _inferExpression(
      ShadowTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    typeNeeded =
        inferrer.listener.nullLiteralEnter(this, typeContext) || typeNeeded;
    var inferredType = typeNeeded ? inferrer.coreTypes.nullClass.rawType : null;
    inferrer.listener.nullLiteralExit(this, inferredType);
    return inferredType;
  }
}

/// Concrete shadow object representing a procedure in kernel form.
class ShadowProcedure extends Procedure implements ShadowMember {
  @override
  AccessorNode _accessorNode;

  MethodNode _methodNode;

  @override
  ShadowTypeInferrer _typeInferrer;

  final bool _hasImplicitReturnType;

  ShadowProcedure(Name name, ProcedureKind kind, FunctionNode function,
      this._hasImplicitReturnType,
      {String fileUri})
      : super(name, kind, function, fileUri: fileUri);

  @override
  void setInferredType(
      TypeInferenceEngineImpl engine, String uri, DartType inferredType) {
    if (isSetter) {
      if (function.positionalParameters.length > 0) {
        var parameter = function.positionalParameters[0];
        engine.instrumentation?.record(Uri.parse(uri), parameter.fileOffset,
            'topType', new InstrumentationValueForType(inferredType));
        parameter.type = inferredType;
      }
    } else if (isGetter) {
      engine.instrumentation?.record(Uri.parse(uri), fileOffset, 'topType',
          new InstrumentationValueForType(inferredType));
      function.returnType = inferredType;
    } else {
      unhandled("setInferredType", "not accessor", fileOffset, Uri.parse(uri));
    }
  }

  static MethodNode getMethodNode(Procedure procedure) {
    if (procedure is ShadowProcedure) return procedure._methodNode;
    return null;
  }

  static bool hasImplicitReturnType(ShadowProcedure procedure) {
    return procedure._hasImplicitReturnType;
  }

  static void inferSetterReturnType(
      ShadowProcedure procedure, TypeInferenceEngineImpl engine, String uri) {
    assert(procedure.isSetter);
    if (procedure._hasImplicitReturnType) {
      var inferredType = const VoidType();
      engine.instrumentation?.record(Uri.parse(uri), procedure.fileOffset,
          'topType', new InstrumentationValueForType(inferredType));
      procedure.function?.returnType = inferredType;
    }
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
  DartType _inferExpression(
      ShadowTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    typeNeeded =
        inferrer.listener.propertyAssignEnter(desugared, typeContext) ||
            typeNeeded;
    var receiverType = _inferReceiver(inferrer);
    if (read != null) {
      var readMember =
          inferrer.findPropertyGetMember(receiverType, read, silent: true);
      var readType = inferrer.getCalleeType(readMember, receiverType);
      _storeLetType(inferrer, read, readType);
    }
    Member writeMember;
    if (write != null) {
      writeMember = inferrer.findPropertySetMember(receiverType, write);
      if (inferrer.isTopLevel &&
          ((writeMember is Procedure &&
                  writeMember.kind == ProcedureKind.Setter) ||
              writeMember is Field)) {
        if (TypeInferenceEngineImpl.fullTopLevelInference) {
          if (writeMember is ShadowField && writeMember._accessorNode != null) {
            inferrer.engine.inferAccessorFused(
                writeMember._accessorNode, inferrer.accessorNode);
          }
        } else {
          // References to fields and setters can't be relied upon for top level
          // inference.
          inferrer.recordNotImmediatelyEvident(fileOffset);
        }
      }
    }
    // To replicate analyzer behavior, we base type inference on the write
    // member.  TODO(paulberry): would it be better to use the read member when
    // doing compound assignment?
    var writeContext = inferrer.getSetterType(writeMember, receiverType);
    _storeLetType(inferrer, write, writeContext);
    var inferredType = _inferRhs(inferrer, writeContext);
    if (inferrer.strongMode) nullAwareGuard?.staticType = inferredType;
    inferrer.listener.propertyAssignExit(desugared, inferredType);
    return inferredType;
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
  void _collectDependencies(ShadowDependencyCollector collector) {
    // A simple or qualified identifier referring to a top level function,
    // static variable, field, getter; or a static class variable, static getter
    // or method; or an instance method; has the inferred type of the referent.
    // - Otherwise, if the identifier has no inferred or annotated type then it
    //   is an error.
    // - Note: specifically, references to instance fields and instance getters
    //   are disallowed here.
    // - The inference dependency of the identifier is the referent if the
    //   referent is a candidate for inference.  Otherwise there are no
    //   inference dependencies.

    // For a property get, the only things we could be looking at are an
    // instance field, an instance getter, or an instance method.  For the first
    // two, we disallow them in [_inferExpression].  For the last, there are no
    // field dependencies.  So we don't need to do anything here.
  }

  @override
  DartType _inferExpression(
      ShadowTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    return inferrer.inferPropertyGet(
        this, receiver, fileOffset, typeContext, typeNeeded,
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
    inferrer.inferInvocation(null, false, fileOffset,
        target.function.functionType, target.enclosingClass.thisType, arguments,
        skipTypeArgumentInference: true);
    inferrer.listener.redirectingInitializerExit(this);
  }
}

/// Shadow object for [Rethrow].
class ShadowRethrow extends Rethrow implements ShadowExpression {
  @override
  void _collectDependencies(ShadowDependencyCollector collector) {
    // No inference dependencies.
  }

  @override
  DartType _inferExpression(
      ShadowTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    typeNeeded =
        inferrer.listener.rethrowEnter(this, typeContext) || typeNeeded;
    var inferredType = typeNeeded ? const BottomType() : null;
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
      closureContext.handleReturn(inferrer, inferredType);
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
  ShadowStaticAssignment(Expression rhs) : super(rhs);

  @override
  DartType _inferExpression(
      ShadowTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    typeNeeded = inferrer.listener.staticAssignEnter(desugared, typeContext) ||
        typeNeeded;
    var read = this.read;
    if (read is StaticGet) {
      _storeLetType(inferrer, read, read.target.getterType);
    }
    DartType writeContext;
    var write = this.write;
    if (write is StaticSet) {
      writeContext = write.target.setterType;
      _storeLetType(inferrer, write, writeContext);
      var target = write.target;
      if (target is ShadowField && target._accessorNode != null) {
        if (inferrer.isDryRun) {
          inferrer.recordDryRunDependency(target._accessorNode);
        }
        if (TypeInferenceEngineImpl.fusedTopLevelInference &&
            inferrer.isTopLevel) {
          inferrer.engine
              .inferAccessorFused(target._accessorNode, inferrer.accessorNode);
        }
      }
    }
    var inferredType = _inferRhs(inferrer, writeContext);
    inferrer.listener.staticAssignExit(desugared, inferredType);
    return inferredType;
  }
}

/// Concrete shadow object representing a read of a static variable in kernel
/// form.
class ShadowStaticGet extends StaticGet implements ShadowExpression {
  ShadowStaticGet(Member target) : super(target);

  @override
  void _collectDependencies(ShadowDependencyCollector collector) {
    // A simple or qualified identifier referring to a top level function,
    // static variable, field, getter; or a static class variable, static getter
    // or method; or an instance method; has the inferred type of the referent.
    // - Otherwise, if the identifier has no inferred or annotated type then it
    //   is an error.
    // - Note: specifically, references to instance fields and instance getters
    //   are disallowed here.
    // - The inference dependency of the identifier is the referent if the
    //   referent is a candidate for inference.  Otherwise there are no
    //   inference dependencies.
    // TODO(paulberry): implement the proper error checking logic.
    var target = this.target;
    if (target is ShadowField && target._accessorNode != null) {
      collector.recordDependency(target._accessorNode);
    }
  }

  @override
  DartType _inferExpression(
      ShadowTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    typeNeeded =
        inferrer.listener.staticGetEnter(this, typeContext) || typeNeeded;
    var target = this.target;
    if (target is ShadowField && target._accessorNode != null) {
      if (inferrer.isDryRun) {
        inferrer.recordDryRunDependency(target._accessorNode);
      }
      if (TypeInferenceEngineImpl.fusedTopLevelInference &&
          inferrer.isTopLevel) {
        inferrer.engine
            .inferAccessorFused(target._accessorNode, inferrer.accessorNode);
      }
    }
    var inferredType = typeNeeded ? target.getterType : null;
    inferrer.listener.staticGetExit(this, inferredType);
    return inferredType;
  }
}

/// Shadow object for [StaticInvocation].
class ShadowStaticInvocation extends StaticInvocation
    implements ShadowExpression {
  ShadowStaticInvocation(Procedure target, Arguments arguments,
      {bool isConst: false})
      : super(target, arguments, isConst: isConst);

  ShadowStaticInvocation.byReference(
      Reference targetReference, Arguments arguments)
      : super.byReference(targetReference, arguments);

  @override
  void _collectDependencies(ShadowDependencyCollector collector) {
    // No inference dependencies.
  }

  @override
  DartType _inferExpression(
      ShadowTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    typeNeeded = inferrer.listener.staticInvocationEnter(this, typeContext) ||
        typeNeeded;
    var calleeType = target.function.functionType;
    var inferredType = inferrer.inferInvocation(typeContext, typeNeeded,
        fileOffset, calleeType, calleeType.returnType, arguments);
    inferrer.listener.staticInvocationExit(this, inferredType);
    return inferredType;
  }
}

/// Concrete shadow object representing a string concatenation in kernel form.
class ShadowStringConcatenation extends StringConcatenation
    implements ShadowExpression {
  ShadowStringConcatenation(List<Expression> expressions) : super(expressions);

  @override
  void _collectDependencies(ShadowDependencyCollector collector) {
    // No inference dependencies.
  }

  @override
  DartType _inferExpression(
      ShadowTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    typeNeeded =
        inferrer.listener.stringConcatenationEnter(this, typeContext) ||
            typeNeeded;
    if (!inferrer.isTopLevel) {
      for (Expression expression in expressions) {
        inferrer.inferExpression(expression, null, false);
      }
    }
    var inferredType =
        typeNeeded ? inferrer.coreTypes.stringClass.rawType : null;
    inferrer.listener.stringConcatenationExit(this, inferredType);
    return inferredType;
  }
}

/// Concrete shadow object representing a string literal in kernel form.
class ShadowStringLiteral extends StringLiteral implements ShadowExpression {
  ShadowStringLiteral(String value) : super(value);

  @override
  void _collectDependencies(ShadowDependencyCollector collector) {
    // No inference dependencies.
  }

  @override
  DartType _inferExpression(
      ShadowTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    typeNeeded =
        inferrer.listener.stringLiteralEnter(this, typeContext) || typeNeeded;
    var inferredType =
        typeNeeded ? inferrer.coreTypes.stringClass.rawType : null;
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
    inferrer.inferInvocation(null, false, fileOffset,
        target.function.functionType, target.enclosingClass.thisType, arguments,
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
  void _collectDependencies(ShadowDependencyCollector collector) {
    // Super expressions should never occur in top level type inference.
    // TODO(paulberry): but could they occur due to invalid code?
    assert(false);
  }

  @override
  DartType _inferExpression(
      ShadowTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    if (interfaceTarget != null) {
      inferrer.instrumentation?.record(Uri.parse(inferrer.uri), fileOffset,
          'target', new InstrumentationValueForMember(interfaceTarget));
    }
    return inferrer.inferMethodInvocation(this, new ShadowThisExpression(),
        fileOffset, false, typeContext, typeNeeded,
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
  void _collectDependencies(ShadowDependencyCollector collector) {
    // Super expressions should never occur in top level type inference.
    // TODO(paulberry): but could they occur due to invalid code?
    assert(false);
  }

  @override
  DartType _inferExpression(
      ShadowTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    return inferrer.inferPropertyGet(
        this, new ShadowThisExpression(), fileOffset, typeContext, typeNeeded,
        propertyName: name);
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
  void _collectDependencies(ShadowDependencyCollector collector) {
    // No inference dependencies.
  }

  @override
  DartType _inferExpression(
      ShadowTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    typeNeeded =
        inferrer.listener.symbolLiteralEnter(this, typeContext) || typeNeeded;
    var inferredType =
        typeNeeded ? inferrer.coreTypes.symbolClass.rawType : null;
    inferrer.listener.symbolLiteralExit(this, inferredType);
    return inferredType;
  }
}

/// Shadow object for expressions that are introduced by the front end as part
/// of desugaring or the handling of error conditions.
///
/// By default, type inference skips these expressions entirely.  Some derived
/// classes have type inference behaviors.
///
/// Visitors skip over objects of this type, so it is not included in serialized
/// output.
class ShadowSyntheticExpression extends Expression implements ShadowExpression {
  /// The desugared kernel representation of this synthetic expression.
  Expression desugared;

  ShadowSyntheticExpression(this.desugared);

  @override
  void set parent(TreeNode node) {
    super.parent = node;
    desugared?.parent = node;
  }

  @override
  accept(ExpressionVisitor v) => desugared.accept(v);

  @override
  accept1(ExpressionVisitor1 v, arg) => desugared.accept1(v, arg);

  @override
  DartType getStaticType(TypeEnvironment types) =>
      desugared.getStaticType(types);

  @override
  transformChildren(Transformer v) => desugared.transformChildren(v);

  @override
  visitChildren(Visitor v) => desugared.visitChildren(v);

  @override
  _collectDependencies(ShadowDependencyCollector collector) {
    // No inference dependencies.
  }

  @override
  DartType _inferExpression(
      ShadowTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    return typeNeeded ? const DynamicType() : null;
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

/// Shadow object for statements that are introduced by the front end as part
/// of desugaring or the handling of error conditions.
///
/// By default, type inference skips these statements entirely.  Some derived
/// classes may have type inference behaviors.
///
/// Visitors skip over objects of this type, so it is not included in serialized
/// output.
class ShadowSyntheticStatement extends Statement implements ShadowStatement {
  /// The desugared kernel representation of this synthetic statement.
  Statement desugared;

  ShadowSyntheticStatement(this.desugared);

  @override
  void set parent(TreeNode node) {
    super.parent = node;
    desugared?.parent = node;
  }

  @override
  accept(StatementVisitor v) => desugared.accept(v);

  @override
  accept1(StatementVisitor1 v, arg) => desugared.accept1(v, arg);

  @override
  transformChildren(Transformer v) => desugared.transformChildren(v);

  @override
  visitChildren(Visitor v) => desugared.visitChildren(v);

  @override
  void _inferStatement(ShadowTypeInferrer inferrer) {}
}

/// Shadow object for [ThisExpression].
class ShadowThisExpression extends ThisExpression implements ShadowExpression {
  @override
  void _collectDependencies(ShadowDependencyCollector collector) {
    // Field initializers are not allowed to refer to [this].  But if it
    // happens, we can still proceed; no additional type inference dependencies
    // are introduced.
  }

  @override
  DartType _inferExpression(
      ShadowTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    typeNeeded =
        inferrer.listener.thisExpressionEnter(this, typeContext) || typeNeeded;
    var inferredType =
        typeNeeded ? (inferrer.thisType ?? const DynamicType()) : null;
    inferrer.listener.thisExpressionExit(this, inferredType);
    return inferredType;
  }
}

/// Shadow object for [Throw].
class ShadowThrow extends Throw implements ShadowExpression {
  ShadowThrow(Expression expression) : super(expression);

  @override
  void _collectDependencies(ShadowDependencyCollector collector) {
    // No inference dependencies.
  }

  @override
  DartType _inferExpression(
      ShadowTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    typeNeeded = inferrer.listener.throwEnter(this, typeContext) || typeNeeded;
    inferrer.inferExpression(expression, null, false);
    var inferredType = typeNeeded ? const BottomType() : null;
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
      inferrer.inferStatement(catch_.body);
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
  AccessorNode createAccessorNode(ShadowMember member) {
    AccessorNode accessorNode = new AccessorNode(this, member);
    member._accessorNode = accessorNode;
    return accessorNode;
  }

  @override
  TypeInferrer createDisabledTypeInferrer() =>
      new TypeInferrerDisabled(typeSchemaEnvironment);

  @override
  ShadowTypeInferrer createLocalTypeInferrer(
      Uri uri, TypeInferenceListener listener, InterfaceType thisType) {
    return new ShadowTypeInferrer._(
        this, uri.toString(), listener, false, thisType, null);
  }

  @override
  MethodNode createMethodNode(ShadowProcedure procedure) {
    MethodNode methodNode = new MethodNode(procedure);
    procedure._methodNode = methodNode;
    return methodNode;
  }

  @override
  ShadowTypeInferrer createTopLevelTypeInferrer(TypeInferenceListener listener,
      InterfaceType thisType, ShadowMember member) {
    return member._typeInferrer = new ShadowTypeInferrer._(
        this, member.fileUri, listener, true, thisType, member._accessorNode);
  }

  @override
  ShadowTypeInferrer getMemberTypeInferrer(ShadowMember member) {
    return member._typeInferrer;
  }
}

/// Concrete implementation of [TypeInferrer] specialized to work with kernel
/// objects.
class ShadowTypeInferrer extends TypeInferrerImpl {
  @override
  final typePromoter = new ShadowTypePromoter();

  ShadowTypeInferrer._(
      ShadowTypeInferenceEngine engine,
      String uri,
      TypeInferenceListener listener,
      bool topLevel,
      InterfaceType thisType,
      AccessorNode accessorNode)
      : super(engine, uri, listener, topLevel, thisType, accessorNode);

  @override
  Expression getFieldInitializer(ShadowField field) {
    return field.initializer;
  }

  @override
  DartType inferExpression(
      Expression expression, DartType typeContext, bool typeNeeded) {
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
      return expression._inferExpression(this, typeContext, typeNeeded);
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
  void inferInitializer(Initializer initializer) {
    assert(initializer is ShadowInitializer);
    // Use polymorphic dispatch on [KernelInitializer] to perform whatever
    // kind of type inference is correct for this kind of initializer.
    // TODO(paulberry): experiment to see if dynamic dispatch would be better,
    // so that the type hierarchy will be simpler (which may speed up "is"
    // checks).
    ShadowInitializer kernelInitializer = initializer;
    return kernelInitializer._inferInitializer(this);
  }

  @override
  void inferStatement(Statement statement) {
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
  ShadowTypeLiteral(DartType type) : super(type);

  @override
  void _collectDependencies(ShadowDependencyCollector collector) {
    // No inference dependencies.
  }

  @override
  DartType _inferExpression(
      ShadowTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    typeNeeded =
        inferrer.listener.typeLiteralEnter(this, typeContext) || typeNeeded;
    var inferredType = typeNeeded ? inferrer.coreTypes.typeClass.rawType : null;
    inferrer.listener.typeLiteralExit(this, inferredType);
    return inferredType;
  }
}

/// Concrete implementation of [TypePromoter] specialized to work with kernel
/// objects.
class ShadowTypePromoter extends TypePromoterImpl {
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
  DartType _inferExpression(
      ShadowTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    typeNeeded =
        inferrer.listener.variableAssignEnter(desugared, typeContext) ||
            typeNeeded;
    DartType writeContext;
    var write = this.write;
    if (write is VariableSet) {
      writeContext = write.variable.type;
      if (read != null) {
        _storeLetType(inferrer, read, writeContext);
      }
      _storeLetType(inferrer, write, writeContext);
    }
    var inferredType = _inferRhs(inferrer, writeContext);
    inferrer.listener.variableAssignExit(desugared, inferredType);
    return inferredType;
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
    if (initializer != null) {
      inferredType = inferrer.inferDeclarationType(inferrer.inferExpression(
          initializer, declaredType, _implicitlyTyped));
    } else {
      inferredType = const DynamicType();
    }
    if (inferrer.strongMode && _implicitlyTyped) {
      inferrer.instrumentation?.record(Uri.parse(inferrer.uri), fileOffset,
          'type', new InstrumentationValueForType(inferredType));
      type = inferredType;
    }
    inferrer.listener.variableDeclarationExit(this);
  }

  /// Determine whether the given [ShadowVariableDeclaration] had an implicit
  /// type.
  ///
  /// This is static to avoid introducing a method that would be visible to
  /// the kernel.
  static bool isImplicitlyTyped(ShadowVariableDeclaration variable) =>
      variable._implicitlyTyped;
}

/// Concrete shadow object representing a read from a variable in kernel form.
class ShadowVariableGet extends VariableGet implements ShadowExpression {
  final TypePromotionFact _fact;

  final TypePromotionScope _scope;

  ShadowVariableGet(VariableDeclaration variable, this._fact, this._scope)
      : super(variable);

  @override
  void _collectDependencies(ShadowDependencyCollector collector) {
    // No inference dependencies.
  }

  @override
  DartType _inferExpression(
      ShadowTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    var variable = this.variable as ShadowVariableDeclaration;
    bool mutatedInClosure = variable._mutatedInClosure;
    DartType declaredOrInferredType = variable.type;
    typeNeeded =
        inferrer.listener.variableGetEnter(this, typeContext) || typeNeeded;
    DartType promotedType = inferrer.typePromoter
        .computePromotedType(_fact, _scope, mutatedInClosure);
    if (promotedType != null) {
      inferrer.instrumentation?.record(Uri.parse(inferrer.uri), fileOffset,
          'promotedType', new InstrumentationValueForType(promotedType));
    }
    this.promotedType = promotedType;
    var inferredType =
        typeNeeded ? (promotedType ?? declaredOrInferredType) : null;
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
    inferrer.inferExpression(
        condition, inferrer.coreTypes.boolClass.rawType, false);
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
    closureContext.handleYield(inferrer, isYieldStar, inferredType);
    inferrer.listener.yieldStatementExit(this);
  }
}

class _UnfinishedCascade extends Expression {
  accept(v) => unsupported("accept", -1, null);

  accept1(v, arg) => unsupported("accept1", -1, null);

  getStaticType(types) => unsupported("getStaticType", -1, null);

  transformChildren(v) => unsupported("transformChildren", -1, null);

  visitChildren(v) => unsupported("visitChildren", -1, null);
}
