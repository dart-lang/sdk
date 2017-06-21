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
import 'package:kernel/type_algebra.dart';
import 'package:kernel/type_environment.dart';

import '../errors.dart' show internalError;

/// Computes the return type of a (possibly factory) constructor.
InterfaceType computeConstructorReturnType(Member constructor) {
  if (constructor is Constructor) {
    return constructor.enclosingClass.thisType;
  } else {
    return constructor.function.returnType;
  }
}

List<DartType> getExplicitTypeArguments(Arguments arguments) {
  if (arguments is KernelArguments) {
    return arguments._hasExplicitTypeArguments ? arguments.types : null;
  } else {
    // This code path should only be taken in situations where there are no
    // type arguments at all, e.g. calling a user-definable operator.
    assert(arguments.types.isEmpty);
    return null;
  }
}

/// Concrete shadow object representing a set of invocation arguments.
class KernelArguments extends Arguments {
  bool _hasExplicitTypeArguments;

  KernelArguments(List<Expression> positional,
      {List<DartType> types, List<NamedExpression> named})
      : _hasExplicitTypeArguments = types != null && types.isNotEmpty,
        super(positional, types: types, named: named);

  static void setExplicitArgumentTypes(
      KernelArguments arguments, List<DartType> types) {
    arguments.types.clear();
    arguments.types.addAll(types);
    arguments._hasExplicitTypeArguments = true;
  }
}

/// Shadow object for [AsExpression].
class KernelAsExpression extends AsExpression implements KernelExpression {
  KernelAsExpression(Expression operand, DartType type) : super(operand, type);

  @override
  void _collectDependencies(KernelDependencyCollector collector) {
    // No inference dependencies.
  }

  @override
  DartType _inferExpression(
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    typeNeeded =
        inferrer.listener.asExpressionEnter(this, typeContext) || typeNeeded;
    inferrer.inferExpression(operand, null, false);
    var inferredType = typeNeeded ? type : null;
    inferrer.listener.asExpressionExit(this, inferredType);
    return inferredType;
  }
}

/// Shadow object for [AwaitExpression].
class KernelAwaitExpression extends AwaitExpression
    implements KernelExpression {
  KernelAwaitExpression(Expression operand) : super(operand);

  @override
  void _collectDependencies(KernelDependencyCollector collector) {
    // Inference dependencies are the dependencies of the awaited expression.
    collector.collectDependencies(operand);
  }

  @override
  DartType _inferExpression(
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
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
class KernelBlock extends Block implements KernelStatement {
  KernelBlock(List<Statement> statements) : super(statements);

  @override
  void _inferStatement(KernelTypeInferrer inferrer) {
    inferrer.listener.blockEnter(this);
    for (var statement in statements) {
      inferrer.inferStatement(statement);
    }
    inferrer.listener.blockExit(this);
  }
}

/// Concrete shadow object representing a boolean literal in kernel form.
class KernelBoolLiteral extends BoolLiteral implements KernelExpression {
  KernelBoolLiteral(bool value) : super(value);

  @override
  void _collectDependencies(KernelDependencyCollector collector) {
    // No inference dependencies.
  }

  @override
  DartType _inferExpression(
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    typeNeeded =
        inferrer.listener.boolLiteralEnter(this, typeContext) || typeNeeded;
    var inferredType = typeNeeded ? inferrer.coreTypes.boolClass.rawType : null;
    inferrer.listener.boolLiteralExit(this, inferredType);
    return inferredType;
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
/// After constructing a [KernelCascadeExpression], the caller should
/// call [finalize] with an expression representing the expression after the
/// `..`.  If a further `..` follows that expression, the caller should call
/// [extend] followed by [finalize] for each subsequent cascade.
class KernelCascadeExpression extends Let implements KernelExpression {
  /// Pointer to the last "let" expression in the cascade.
  Let nextCascade;

  /// Creates a [KernelCascadeExpression] using [variable] as the cascade
  /// variable.  Caller is responsible for ensuring that [variable]'s
  /// initializer is the expression preceding the first `..` of the cascade
  /// expression.
  KernelCascadeExpression(KernelVariableDeclaration variable)
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
  void _collectDependencies(KernelDependencyCollector collector) {
    // The inference dependencies are the inference dependencies of the cascade
    // target.
    collector.collectDependencies(variable.initializer);
  }

  @override
  DartType _inferExpression(
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
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
abstract class KernelComplexAssignment extends Expression
    implements KernelExpression {
  /// The full desugared assignment expression
  Expression desugared;

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

  KernelComplexAssignment(this.rhs);

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

  String toString() {
    var parts = _getToStringParts();
    return '${runtimeType}(${parts.join(', ')})';
  }

  @override
  transformChildren(Transformer v) => desugared.transformChildren(v);

  @override
  visitChildren(Visitor v) => desugared.visitChildren(v);

  @override
  void _collectDependencies(KernelDependencyCollector collector) {
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

  DartType _inferRhs(KernelTypeInferrer inferrer, DartType writeContext) {
    DartType inferredType = writeContext ?? const DynamicType();
    if (nullAwareCombiner != null) {
      var rhsType = inferrer.inferExpression(rhs, writeContext, true);
      MethodInvocation equalsInvocation = nullAwareCombiner.condition;
      inferrer.findMethodInvocationMember(writeContext, equalsInvocation,
          silent: true);
      return inferrer.typeSchemaEnvironment
          .getLeastUpperBound(inferredType, rhsType);
    } else if (combiner != null) {
      bool isOverloadedArithmeticOperator = false;
      var combinerMember = inferrer
          .findMethodInvocationMember(writeContext, combiner, silent: true);
      if (combinerMember is Procedure) {
        isOverloadedArithmeticOperator = inferrer.typeSchemaEnvironment
            .isOverloadedArithmeticOperatorAndType(
                combinerMember, writeContext);
      }
      if (isPostIncDec) {
        return inferredType;
      } else {
        DartType rhsType;
        if (isPreIncDec) {
          rhsType = inferrer.coreTypes.intClass.rawType;
        } else {
          // Analyzer uses a null context for the RHS here.
          // TODO(paulberry): improve on this.
          rhsType = inferrer.inferExpression(rhs, null, true);
        }
        if (isOverloadedArithmeticOperator) {
          return inferrer.typeSchemaEnvironment
              .getTypeOfOverloadedArithmetic(inferredType, rhsType);
        } else {
          return inferrer
              .getCalleeFunctionType(
                  combinerMember, writeContext, combiner.name, false)
              .returnType;
        }
      }
    } else {
      return inferrer.inferExpression(rhs, writeContext, true);
    }
  }
}

/// Abstract shadow object representing a complex assignment involving a
/// receiver.
abstract class KernelComplexAssignmentWithReceiver
    extends KernelComplexAssignment {
  /// The receiver of the assignment target (e.g. `a` in `a[b] = c`).
  final Expression receiver;

  /// Indicates whether this assignment uses `super`.
  final bool isSuper;

  KernelComplexAssignmentWithReceiver(
      this.receiver, Expression rhs, this.isSuper)
      : super(rhs);

  @override
  List<String> _getToStringParts() {
    var parts = super._getToStringParts();
    if (receiver != null) parts.add('receiver=$receiver');
    if (isSuper) parts.add('isSuper=true');
    return parts;
  }

  DartType _inferReceiver(KernelTypeInferrer inferrer) {
    if (receiver != null) {
      return inferrer.inferExpression(receiver, null, true);
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
class KernelConditionalExpression extends ConditionalExpression
    implements KernelExpression {
  KernelConditionalExpression(
      Expression condition, Expression then, Expression otherwise)
      : super(condition, then, otherwise, null);

  @override
  void _collectDependencies(KernelDependencyCollector collector) {
    // Inference dependencies are the union of the inference dependencies of the
    // two returned sub-expressions.
    collector.collectDependencies(then);
    collector.collectDependencies(otherwise);
  }

  @override
  DartType _inferExpression(
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    typeNeeded =
        inferrer.listener.conditionalExpressionEnter(this, typeContext) ||
            typeNeeded;
    if (!inferrer.isTopLevel) {
      inferrer.inferExpression(
          condition, inferrer.coreTypes.boolClass.rawType, false);
    }
    DartType thenType = inferrer.inferExpression(then, typeContext, true);
    DartType otherwiseType =
        inferrer.inferExpression(otherwise, typeContext, true);
    DartType type = inferrer.typeSchemaEnvironment
        .getLeastUpperBound(thenType, otherwiseType);
    if (inferrer.strongMode) {
      staticType = type;
    }
    var inferredType = typeNeeded ? type : null;
    inferrer.listener.conditionalExpressionExit(this, inferredType);
    return inferredType;
  }
}

/// Shadow object for [ConstructorInvocation].
class KernelConstructorInvocation extends ConstructorInvocation
    implements KernelExpression {
  final Member _initialTarget;

  KernelConstructorInvocation(
      Constructor target, this._initialTarget, Arguments arguments,
      {bool isConst: false})
      : super(target, arguments, isConst: isConst);

  @override
  void _collectDependencies(KernelDependencyCollector collector) {
    // No inference dependencies.
  }

  @override
  DartType _inferExpression(
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
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

/// Concrete implementation of [DependencyCollector] specialized to work with
/// kernel objects.
class KernelDependencyCollector extends DependencyCollectorImpl {
  @override
  void collectDependencies(Expression expression) {
    if (expression is KernelExpression) {
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
class KernelDirectMethodInvocation extends DirectMethodInvocation
    implements KernelExpression {
  KernelDirectMethodInvocation(
      Expression receiver, Procedure target, Arguments arguments)
      : super(receiver, target, arguments);

  KernelDirectMethodInvocation.byReference(
      Expression receiver, Reference targetReference, Arguments arguments)
      : super.byReference(receiver, targetReference, arguments);

  @override
  void _collectDependencies(KernelDependencyCollector collector) {
    // TODO(paulberry): Determine the right thing to do here.
    throw 'TODO(paulberry)';
  }

  @override
  DartType _inferExpression(
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    // TODO(scheglov): implement.
    return typeNeeded ? const DynamicType() : null;
  }
}

/// Shadow object for [DirectPropertyGet].
class KernelDirectPropertyGet extends DirectPropertyGet
    implements KernelExpression {
  KernelDirectPropertyGet(Expression receiver, Member target)
      : super(receiver, target);

  KernelDirectPropertyGet.byReference(
      Expression receiver, Reference targetReference)
      : super.byReference(receiver, targetReference);

  @override
  void _collectDependencies(KernelDependencyCollector collector) {
    // TODO(paulberry): Determine the right thing to do here.
    throw 'TODO(paulberry)';
  }

  @override
  DartType _inferExpression(
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    // TODO(scheglov): implement.
    return typeNeeded ? const DynamicType() : null;
  }
}

/// Concrete shadow object representing a double literal in kernel form.
class KernelDoubleLiteral extends DoubleLiteral implements KernelExpression {
  KernelDoubleLiteral(double value) : super(value);

  @override
  void _collectDependencies(KernelDependencyCollector collector) {
    // No inference dependencies.
  }

  @override
  DartType _inferExpression(
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
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
abstract class KernelExpression implements Expression {
  /// Collects any dependencies of [expression], and reports errors if the
  /// expression does not have an immediately evident type.
  void _collectDependencies(KernelDependencyCollector collector);

  /// Calls back to [inferrer] to perform type inference for whatever concrete
  /// type of [KernelExpression] this is.
  DartType _inferExpression(
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded);
}

/// Concrete shadow object representing an expression statement in kernel form.
class KernelExpressionStatement extends ExpressionStatement
    implements KernelStatement {
  KernelExpressionStatement(Expression expression) : super(expression);

  @override
  void _inferStatement(KernelTypeInferrer inferrer) {
    inferrer.listener.expressionStatementEnter(this);
    inferrer.inferExpression(expression, null, false);
    inferrer.listener.expressionStatementExit(this);
  }
}

/// Shadow object for [StaticInvocation] when the procedure being invoked is a
/// factory constructor.
class KernelFactoryConstructorInvocation extends StaticInvocation
    implements KernelExpression {
  final Member _initialTarget;

  KernelFactoryConstructorInvocation(
      Procedure target, this._initialTarget, Arguments arguments,
      {bool isConst: false})
      : super(target, arguments, isConst: isConst);

  @override
  void _collectDependencies(KernelDependencyCollector collector) {
    // No inference dependencies.
  }

  @override
  DartType _inferExpression(
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
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
class KernelField extends Field implements KernelMember {
  @override
  AccessorNode _accessorNode;

  @override
  KernelTypeInferrer _typeInferrer;

  KernelField(Name name, {String fileUri}) : super(name, fileUri: fileUri) {}

  @override
  void setInferredType(
      TypeInferenceEngineImpl engine, String uri, DartType inferredType) {
    engine.instrumentation?.record(Uri.parse(uri), fileOffset, 'topType',
        new InstrumentationValueForType(inferredType));
    type = inferredType;
  }
}

/// Concrete shadow object representing a for-in loop in kernel form.
class KernelForInStatement extends ForInStatement implements KernelStatement {
  final bool _declaresVariable;

  KernelForInStatement(VariableDeclaration variable, Expression iterable,
      Statement body, this._declaresVariable,
      {bool isAsync: false})
      : super(variable, iterable, body, isAsync: isAsync);

  @override
  void _inferStatement(KernelTypeInferrer inferrer) {
    inferrer.listener.forInStatementEnter(this);
    var iterableClass = isAsync
        ? inferrer.coreTypes.streamClass
        : inferrer.coreTypes.iterableClass;
    DartType context;
    bool typeNeeded = false;
    KernelVariableDeclaration variable;
    if (_declaresVariable) {
      variable = this.variable;
      if (variable._implicitlyTyped) {
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
    var inferredExpressionType =
        inferrer.inferExpression(iterable, context, typeNeeded);
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

/// Concrete shadow object representing a local function declaration in kernel
/// form.
class KernelFunctionDeclaration extends FunctionDeclaration
    implements KernelStatement {
  KernelFunctionDeclaration(VariableDeclaration variable, FunctionNode function)
      : super(variable, function);

  @override
  void _inferStatement(KernelTypeInferrer inferrer) {
    inferrer.listener.functionDeclarationEnter(this);
    for (var parameter in function.positionalParameters) {
      if (parameter.initializer != null) {
        inferrer.inferExpression(parameter.initializer, parameter.type, false);
      }
    }
    for (var parameter in function.namedParameters) {
      if (parameter.initializer != null) {
        inferrer.inferExpression(parameter.initializer, parameter.type, false);
      }
    }
    if (!inferrer.isTopLevel) {
      var oldClosureContext = inferrer.closureContext;
      inferrer.closureContext = new ClosureContext(
          inferrer, function.asyncMarker, function.returnType);
      inferrer.inferStatement(function.body);
      inferrer.closureContext = oldClosureContext;
    }
    inferrer.listener.functionDeclarationExit(this);
  }
}

/// Concrete shadow object representing a function expression in kernel form.
class KernelFunctionExpression extends FunctionExpression
    implements KernelExpression {
  KernelFunctionExpression(FunctionNode function) : super(function);

  @override
  void _collectDependencies(KernelDependencyCollector collector) {
    for (KernelVariableDeclaration parameter in function.positionalParameters) {
      if (parameter._implicitlyTyped) {
        collector.recordNotImmediatelyEvident(parameter.fileOffset);
      }
    }
    for (KernelVariableDeclaration parameter in function.namedParameters) {
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
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    typeNeeded = inferrer.listener.functionExpressionEnter(this, typeContext) ||
        typeNeeded;

    if (!inferrer.isTopLevel) {
      for (var parameter in function.positionalParameters) {
        if (parameter.initializer != null) {
          inferrer.inferExpression(
              parameter.initializer, parameter.type, false);
        }
      }
      for (var parameter in function.namedParameters) {
        if (parameter.initializer != null) {
          inferrer.inferExpression(
              parameter.initializer, parameter.type, false);
        }
      }
    }

    // Let `<T0, ..., Tn>` be the set of type parameters of the closure (with
    // `n`=0 if there are no type parameters).
    List<TypeParameter> typeParameters = function.typeParameters;

    // Let `(P0 x0, ..., Pm xm)` be the set of formal parameters of the closure
    // (including required, positional optional, and named optional parameters).
    // If any type `Pi` is missing, denote it as `_`.
    List<VariableDeclaration> formals = function.positionalParameters.toList()
      ..addAll(function.namedParameters);

    // Let `B` denote the closure body.  If `B` is an expression function body
    // (`=> e`), treat it as equivalent to a block function body containing a
    // single `return` statement (`{ return e; }`).

    // Attempt to match `K` as a function type compatible with the closure (that
    // is, one having n type parameters and a compatible set of formal
    // parameters).  If there is a successful match, let `<S0, ..., Sn>` be the
    // set of matched type parameters and `(Q0, ..., Qm)` be the set of matched
    // formal parameter types, and let `N` be the return type.
    Substitution substitution;
    List<DartType> formalTypesFromContext =
        new List<DartType>.filled(formals.length, null);
    DartType returnContext;
    if (inferrer.strongMode && typeContext is FunctionType) {
      for (int i = 0; i < formals.length; i++) {
        if (i < function.positionalParameters.length) {
          formalTypesFromContext[i] =
              inferrer.getPositionalParameterType(typeContext, i);
        } else {
          formalTypesFromContext[i] =
              inferrer.getNamedParameterType(typeContext, formals[i].name);
        }
      }
      returnContext = typeContext.returnType;

      // Let `[T/S]` denote the type substitution where each `Si` is replaced with
      // the corresponding `Ti`.
      var substitutionMap = <TypeParameter, DartType>{};
      for (int i = 0; i < typeContext.typeParameters.length; i++) {
        substitutionMap[typeContext.typeParameters[i]] =
            i < typeParameters.length
                ? new TypeParameterType(typeParameters[i])
                : const DynamicType();
      }
      substitution = Substitution.fromMap(substitutionMap);
    } else {
      // If the match is not successful because  `K` is `_`, let all `Si`, all
      // `Qi`, and `N` all be `_`.

      // If the match is not successful for any other reason, this will result in
      // a type error, so the implementation is free to choose the best error
      // recovery path.
      substitution = Substitution.empty;
    }

    // Define `Ri` as follows: if `Pi` is not `_`, let `Ri` be `Pi`.
    // Otherwise, if `Qi` is not `_`, let `Ri` be the greatest closure of
    // `Qi[T/S]` with respect to `?`.  Otherwise, let `Ri` be `dynamic`.
    for (int i = 0; i < formals.length; i++) {
      KernelVariableDeclaration formal = formals[i];
      if (KernelVariableDeclaration.isImplicitlyTyped(formal)) {
        DartType inferredType;
        if (formalTypesFromContext[i] != null) {
          inferredType = greatestClosure(inferrer.coreTypes,
              substitution.substituteType(formalTypesFromContext[i]));
        } else {
          inferredType = const DynamicType();
        }
        inferrer.instrumentation?.record(
            Uri.parse(inferrer.uri),
            formal.fileOffset,
            'type',
            new InstrumentationValueForType(inferredType));
        formal.type = inferredType;
      }
    }

    // Let `N'` be `N[T/S]`.  The [ClosureContext] constructor will adjust
    // accordingly if the closure is declared with `async`, `async*`, or
    // `sync*`.
    if (returnContext != null) {
      returnContext = substitution.substituteType(returnContext);
    }

    // Apply type inference to `B` in return context `N’`, with any references
    // to `xi` in `B` having type `Pi`.  This produces `B’`.
    bool isExpressionFunction = function.body is ReturnStatement;
    bool needToSetReturnType = isExpressionFunction || inferrer.strongMode;
    ClosureContext oldClosureContext = inferrer.closureContext;
    ClosureContext closureContext =
        new ClosureContext(inferrer, function.asyncMarker, returnContext);
    inferrer.closureContext = closureContext;
    inferrer.inferStatement(function.body);

    // If the closure is declared with `async*` or `sync*`, let `M` be the least
    // upper bound of the types of the `yield` expressions in `B’`, or `void` if
    // `B’` contains no `yield` expressions.  Otherwise, let `M` be the least
    // upper bound of the types of the `return` expressions in `B’`, or `void`
    // if `B’` contains no `return` expressions.
    DartType inferredReturnType;
    if (needToSetReturnType || typeNeeded) {
      inferredReturnType =
          closureContext.inferReturnType(inferrer, isExpressionFunction);
    }

    // Then the result of inference is `<T0, ..., Tn>(R0 x0, ..., Rn xn) B` with
    // type `<T0, ..., Tn>(R0, ..., Rn) -> M’` (with some of the `Ri` and `xi`
    // denoted as optional or named parameters, if appropriate).
    if (needToSetReturnType) {
      inferrer.instrumentation?.record(Uri.parse(inferrer.uri), fileOffset,
          'returnType', new InstrumentationValueForType(inferredReturnType));
      function.returnType = inferredReturnType;
    }
    inferrer.closureContext = oldClosureContext;
    var inferredType = typeNeeded ? function.functionType : null;
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
class KernelIfNullExpression extends Let implements KernelExpression {
  KernelIfNullExpression(VariableDeclaration variable, Expression body)
      : super(variable, body);

  @override
  ConditionalExpression get body => super.body;

  /// Returns the expression to the left of `??`.
  Expression get _lhs => variable.initializer;

  /// Returns the expression to the right of `??`.
  Expression get _rhs => body.then;

  @override
  void _collectDependencies(KernelDependencyCollector collector) {
    // If-null expressions are not immediately evident expressions.
    collector.recordNotImmediatelyEvident(fileOffset);
  }

  @override
  DartType _inferExpression(
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
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
    var rhsType =
        inferrer.inferExpression(_rhs, rhsContext, typeContext == null);
    // - Let T = greatest closure of K with respect to `?` if K is not `_`, else
    //   UP(t0, t1)
    // - Then the inferred type is T.
    var inferredType = typeContext == null
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
class KernelIfStatement extends IfStatement implements KernelStatement {
  KernelIfStatement(Expression condition, Statement then, Statement otherwise)
      : super(condition, then, otherwise);

  @override
  void _inferStatement(KernelTypeInferrer inferrer) {
    inferrer.listener.ifStatementEnter(this);
    inferrer.inferExpression(
        condition, inferrer.coreTypes.boolClass.rawType, false);
    inferrer.inferStatement(then);
    if (otherwise != null) inferrer.inferStatement(otherwise);
    inferrer.listener.ifStatementExit(this);
  }
}

/// Concrete shadow object representing an assignment to a target of the form
/// `a[b]`.
class KernelIndexAssign extends KernelComplexAssignmentWithReceiver {
  /// In an assignment to an index expression, the index expression.
  Expression index;

  KernelIndexAssign(Expression receiver, this.index, Expression rhs,
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
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    typeNeeded = inferrer.listener.indexAssignEnter(desugared, typeContext) ||
        typeNeeded;
    // TODO(paulberry): record the appropriate types on let variables and
    // conditional expressions.
    var receiverType = _inferReceiver(inferrer);
    if (read != null) {
      inferrer.findMethodInvocationMember(receiverType, read, silent: true);
    }
    var writeMember = inferrer.findMethodInvocationMember(receiverType, write);
    // To replicate analyzer behavior, we base type inference on the write
    // member.  TODO(paulberry): would it be better to use the read member
    // when doing compound assignment?
    var calleeType =
        inferrer.getCalleeType(writeMember, receiverType, indexSetName);
    DartType indexContext;
    DartType writeContext;
    if (calleeType is FunctionType &&
        calleeType.positionalParameters.length >= 2) {
      // TODO(paulberry): we ought to get a context for the index expression
      // from the index formal parameter, but analyzer doesn't so for now we
      // replicate its behavior.
      indexContext = null;
      writeContext = calleeType.positionalParameters[1];
    }
    inferrer.inferExpression(index, indexContext, false);
    var inferredType = _inferRhs(inferrer, writeContext);
    inferrer.listener.indexAssignExit(desugared, inferredType);
    return inferredType;
  }
}

/// Common base class for shadow objects representing initializers in kernel
/// form.
abstract class KernelInitializer implements Initializer {
  /// Performs type inference for whatever concrete type of [KernelInitializer]
  /// this is.
  void _inferInitializer(KernelTypeInferrer inferrer);
}

/// Concrete shadow object representing an integer literal in kernel form.
class KernelIntLiteral extends IntLiteral implements KernelExpression {
  KernelIntLiteral(int value) : super(value);

  @override
  void _collectDependencies(KernelDependencyCollector collector) {
    // No inference dependencies.
  }

  @override
  DartType _inferExpression(
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    typeNeeded =
        inferrer.listener.intLiteralEnter(this, typeContext) || typeNeeded;
    var inferredType = typeNeeded ? inferrer.coreTypes.intClass.rawType : null;
    inferrer.listener.intLiteralExit(this, inferredType);
    return inferredType;
  }
}

/// Concrete shadow object representing a non-inverted "is" test in kernel form.
class KernelIsExpression extends IsExpression implements KernelExpression {
  KernelIsExpression(Expression operand, DartType type) : super(operand, type);

  @override
  void _collectDependencies(KernelDependencyCollector collector) {
    // No inference dependencies.
  }

  @override
  DartType _inferExpression(
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    typeNeeded =
        inferrer.listener.isExpressionEnter(this, typeContext) || typeNeeded;
    inferrer.inferExpression(operand, null, false);
    var inferredType = typeNeeded ? inferrer.coreTypes.boolClass.rawType : null;
    inferrer.listener.isExpressionExit(this, inferredType);
    return inferredType;
  }
}

/// Concrete shadow object representing an inverted "is" test in kernel form.
class KernelIsNotExpression extends Not implements KernelExpression {
  KernelIsNotExpression(Expression operand, DartType type, int charOffset)
      : super(new IsExpression(operand, type)..fileOffset = charOffset);

  @override
  void _collectDependencies(KernelDependencyCollector collector) {
    // No inference dependencies.
  }

  @override
  DartType _inferExpression(
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    IsExpression isExpression = this.operand;
    typeNeeded =
        inferrer.listener.isNotExpressionEnter(this, typeContext) || typeNeeded;
    inferrer.inferExpression(isExpression.operand, null, false);
    var inferredType = typeNeeded ? inferrer.coreTypes.boolClass.rawType : null;
    inferrer.listener.isNotExpressionExit(this, inferredType);
    return inferredType;
  }
}

/// Concrete shadow object representing a list literal in kernel form.
class KernelListLiteral extends ListLiteral implements KernelExpression {
  final DartType _declaredTypeArgument;

  KernelListLiteral(List<Expression> expressions,
      {DartType typeArgument, bool isConst: false})
      : _declaredTypeArgument = typeArgument,
        super(expressions,
            typeArgument: typeArgument ?? const DynamicType(),
            isConst: isConst);

  @override
  void _collectDependencies(KernelDependencyCollector collector) {
    if (_declaredTypeArgument == null) {
      expressions.forEach(collector.collectDependencies);
    }
  }

  @override
  DartType _inferExpression(
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
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
          listClass.typeParameters, null, null, typeContext, inferredTypes);
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
class KernelLogicalExpression extends LogicalExpression
    implements KernelExpression {
  KernelLogicalExpression(Expression left, String operator, Expression right)
      : super(left, operator, right);

  @override
  void _collectDependencies(KernelDependencyCollector collector) {
    // No inference dependencies.
  }

  @override
  DartType _inferExpression(
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    // TODO(scheglov): implement.
    return typeNeeded ? const DynamicType() : null;
  }
}

/// Shadow object for [MapLiteral].
class KernelMapLiteral extends MapLiteral implements KernelExpression {
  final DartType _declaredKeyType;
  final DartType _declaredValueType;

  KernelMapLiteral(List<MapEntry> entries,
      {DartType keyType, DartType valueType, bool isConst: false})
      : _declaredKeyType = keyType,
        _declaredValueType = valueType,
        super(entries,
            keyType: keyType ?? const DynamicType(),
            valueType: valueType ?? const DynamicType(),
            isConst: isConst);

  @override
  void _collectDependencies(KernelDependencyCollector collector) {
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
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
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
          mapClass.typeParameters, null, null, typeContext, inferredTypes);
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
abstract class KernelMember implements Member {
  String get fileUri;

  AccessorNode get _accessorNode;

  void set _accessorNode(AccessorNode value);

  KernelTypeInferrer get _typeInferrer;

  void set _typeInferrer(KernelTypeInferrer value);

  void setInferredType(
      TypeInferenceEngineImpl engine, String uri, DartType inferredType);

  static AccessorNode getAccessorNode(Member member) {
    if (member is KernelMember) return member._accessorNode;
    return null;
  }

  static void recordCrossOverride(
      KernelMember member, Member overriddenMember) {
    if (member._accessorNode != null) {
      member._accessorNode.crossOverrides.add(overriddenMember);
    }
  }

  static void recordOverride(KernelMember member, Member overriddenMember) {
    if (member._accessorNode != null) {
      member._accessorNode.overrides.add(overriddenMember);
    }
    if (member is KernelProcedure && member._methodNode != null) {
      member._methodNode.overrides.add(overriddenMember);
    }
  }
}

/// Shadow object for [MethodInvocation].
class KernelMethodInvocation extends MethodInvocation
    implements KernelExpression {
  /// Indicates whether this method invocation is a call to a `call` method
  /// resulting from the invocation of a function expression.
  final bool _isImplicitCall;

  KernelMethodInvocation(Expression receiver, Name name, Arguments arguments,
      {bool isImplicitCall: false, Member interfaceTarget})
      : _isImplicitCall = isImplicitCall,
        super(receiver, name, arguments, interfaceTarget);

  @override
  void _collectDependencies(KernelDependencyCollector collector) {
    // The inference dependencies are the inference dependencies of the
    // receiver.
    collector.collectDependencies(receiver);
    if (isOverloadableArithmeticOperator(name.name)) {
      collector.collectDependencies(arguments.positional[0]);
    }
  }

  @override
  DartType _inferExpression(
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    return inferrer.inferMethodInvocation(this, receiver, fileOffset, this,
        _isImplicitCall, typeContext, typeNeeded);
  }
}

/// Shadow object for [Not].
class KernelNot extends Not implements KernelExpression {
  KernelNot(Expression operand) : super(operand);

  @override
  void _collectDependencies(KernelDependencyCollector collector) {
    collector.collectDependencies(operand);
  }

  @override
  DartType _inferExpression(
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
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
class KernelNullAwareMethodInvocation extends Let implements KernelExpression {
  KernelNullAwareMethodInvocation(VariableDeclaration variable, Expression body)
      : super(variable, body);

  @override
  ConditionalExpression get body => super.body;

  MethodInvocation get _desugaredInvocation => body.otherwise;

  @override
  void _collectDependencies(KernelDependencyCollector collector) {
    // Null aware expressions are not immediately evident.
    collector.recordNotImmediatelyEvident(fileOffset);
  }

  @override
  DartType _inferExpression(
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    var inferredType = inferrer.inferMethodInvocation(
        this,
        variable.initializer,
        fileOffset,
        _desugaredInvocation,
        false,
        typeContext,
        typeNeeded || inferrer.strongMode,
        receiverVariable: variable);
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
class KernelNullAwarePropertyGet extends Let implements KernelExpression {
  KernelNullAwarePropertyGet(
      VariableDeclaration variable, ConditionalExpression body)
      : super(variable, body);

  @override
  ConditionalExpression get body => super.body;

  PropertyGet get _desugaredGet => body.otherwise;

  @override
  void _collectDependencies(KernelDependencyCollector collector) {
    // Null aware expressions are not immediately evident.
    collector.recordNotImmediatelyEvident(fileOffset);
  }

  @override
  DartType _inferExpression(
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    var inferredType = inferrer.inferPropertyGet(
        this,
        variable.initializer,
        fileOffset,
        _desugaredGet,
        typeContext,
        typeNeeded || inferrer.strongMode,
        receiverVariable: variable);
    if (inferrer.strongMode) {
      body.staticType = inferredType;
    }
    return inferredType;
  }
}

/// Concrete shadow object representing a null literal in kernel form.
class KernelNullLiteral extends NullLiteral implements KernelExpression {
  @override
  void _collectDependencies(KernelDependencyCollector collector) {
    // No inference dependencies.
  }

  @override
  DartType _inferExpression(
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    typeNeeded =
        inferrer.listener.nullLiteralEnter(this, typeContext) || typeNeeded;
    var inferredType = typeNeeded ? inferrer.coreTypes.nullClass.rawType : null;
    inferrer.listener.nullLiteralExit(this, inferredType);
    return inferredType;
  }
}

/// Concrete shadow object representing a procedure in kernel form.
class KernelProcedure extends Procedure implements KernelMember {
  @override
  AccessorNode _accessorNode;

  MethodNode _methodNode;

  @override
  KernelTypeInferrer _typeInferrer;

  final bool _hasImplicitReturnType;

  KernelProcedure(Name name, ProcedureKind kind, FunctionNode function,
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
      internalError(
          'setInferredType called on a procedure that is not an accessor');
    }
  }

  static MethodNode getMethodNode(Procedure procedure) {
    if (procedure is KernelProcedure) return procedure._methodNode;
    return null;
  }

  static bool hasImplicitReturnType(KernelProcedure procedure) {
    return procedure._hasImplicitReturnType;
  }
}

/// Concrete shadow object representing an assignment to a property.
class KernelPropertyAssign extends KernelComplexAssignmentWithReceiver {
  /// If this assignment uses null-aware access (`?.`), the conditional
  /// expression that guards the access; otherwise `null`.
  Expression nullAwareGuard;

  KernelPropertyAssign(Expression receiver, Expression rhs,
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
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    typeNeeded =
        inferrer.listener.propertyAssignEnter(desugared, typeContext) ||
            typeNeeded;
    // TODO(paulberry): record the appropriate types on let variables and
    // conditional expressions.
    var receiverType = _inferReceiver(inferrer);
    if (read != null) {
      inferrer.findPropertyGetMember(receiverType, read, silent: true);
    }
    Member writeMember;
    if (write != null) {
      writeMember = inferrer.findPropertySetMember(receiverType, write);
      if (inferrer.isTopLevel &&
          ((writeMember is Procedure &&
                  writeMember.kind == ProcedureKind.Setter) ||
              writeMember is Field)) {
        if (TypeInferenceEngineImpl.fullTopLevelInference) {
          if (writeMember is KernelField && writeMember._accessorNode != null) {
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
    var writeContext = writeMember?.setterType;
    var inferredType = _inferRhs(inferrer, writeContext);
    inferrer.listener.propertyAssignExit(desugared, inferredType);
    return inferredType;
  }
}

/// Shadow object for [PropertyGet].
class KernelPropertyGet extends PropertyGet implements KernelExpression {
  KernelPropertyGet(Expression receiver, Name name, [Member interfaceTarget])
      : super(receiver, name, interfaceTarget);

  KernelPropertyGet.byReference(
      Expression receiver, Name name, Reference interfaceTargetReference)
      : super.byReference(receiver, name, interfaceTargetReference);

  @override
  void _collectDependencies(KernelDependencyCollector collector) {
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
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    return inferrer.inferPropertyGet(
        this, receiver, fileOffset, this, typeContext, typeNeeded);
  }
}

/// Concrete shadow object representing a redirecting initializer in kernel
/// form.
class KernelRedirectingInitializer extends RedirectingInitializer
    implements KernelInitializer {
  KernelRedirectingInitializer(Constructor target, Arguments arguments)
      : super(target, arguments);

  @override
  _inferInitializer(KernelTypeInferrer inferrer) {
    inferrer.listener.redirectingInitializerEnter(this);
    inferrer.inferInvocation(null, false, fileOffset,
        target.function.functionType, target.enclosingClass.thisType, arguments,
        skipTypeArgumentInference: true);
    inferrer.listener.redirectingInitializerExit(this);
  }
}

/// Shadow object for [Rethrow].
class KernelRethrow extends Rethrow implements KernelExpression {
  @override
  void _collectDependencies(KernelDependencyCollector collector) {
    // No inference dependencies.
  }

  @override
  DartType _inferExpression(
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    // TODO(scheglov): implement.
    return typeNeeded ? const DynamicType() : null;
  }
}

/// Concrete shadow object representing a return statement in kernel form.
class KernelReturnStatement extends ReturnStatement implements KernelStatement {
  KernelReturnStatement([Expression expression]) : super(expression);

  @override
  void _inferStatement(KernelTypeInferrer inferrer) {
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
abstract class KernelStatement extends Statement {
  /// Calls back to [inferrer] to perform type inference for whatever concrete
  /// type of [KernelStatement] this is.
  void _inferStatement(KernelTypeInferrer inferrer);
}

/// Concrete shadow object representing an assignment to a static variable.
class KernelStaticAssignment extends KernelComplexAssignment {
  KernelStaticAssignment(Expression rhs) : super(rhs);

  @override
  DartType _inferExpression(
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    typeNeeded = inferrer.listener.staticAssignEnter(desugared, typeContext) ||
        typeNeeded;
    // TODO(paulberry): record the appropriate types on let variables and
    // conditional expressions.
    DartType writeContext;
    var write = this.write;
    if (write is StaticSet) {
      writeContext = write.target.setterType;
      var target = write.target;
      if (target is KernelField && target._accessorNode != null) {
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
class KernelStaticGet extends StaticGet implements KernelExpression {
  KernelStaticGet(Member target) : super(target);

  @override
  void _collectDependencies(KernelDependencyCollector collector) {
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
    if (target is KernelField && target._accessorNode != null) {
      collector.recordDependency(target._accessorNode);
    }
  }

  @override
  DartType _inferExpression(
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    typeNeeded =
        inferrer.listener.staticGetEnter(this, typeContext) || typeNeeded;
    var target = this.target;
    if (target is KernelField && target._accessorNode != null) {
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
class KernelStaticInvocation extends StaticInvocation
    implements KernelExpression {
  KernelStaticInvocation(Procedure target, Arguments arguments,
      {bool isConst: false})
      : super(target, arguments, isConst: isConst);

  KernelStaticInvocation.byReference(
      Reference targetReference, Arguments arguments)
      : super.byReference(targetReference, arguments);

  @override
  void _collectDependencies(KernelDependencyCollector collector) {
    // No inference dependencies.
  }

  @override
  DartType _inferExpression(
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
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
class KernelStringConcatenation extends StringConcatenation
    implements KernelExpression {
  KernelStringConcatenation(List<Expression> expressions) : super(expressions);

  @override
  void _collectDependencies(KernelDependencyCollector collector) {
    // No inference dependencies.
  }

  @override
  DartType _inferExpression(
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
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
class KernelStringLiteral extends StringLiteral implements KernelExpression {
  KernelStringLiteral(String value) : super(value);

  @override
  void _collectDependencies(KernelDependencyCollector collector) {
    // No inference dependencies.
  }

  @override
  DartType _inferExpression(
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    typeNeeded =
        inferrer.listener.stringLiteralEnter(this, typeContext) || typeNeeded;
    var inferredType =
        typeNeeded ? inferrer.coreTypes.stringClass.rawType : null;
    inferrer.listener.stringLiteralExit(this, inferredType);
    return inferredType;
  }
}

/// Shadow object for [SuperMethodInvocation].
class KernelSuperMethodInvocation extends SuperMethodInvocation
    implements KernelExpression {
  KernelSuperMethodInvocation(Name name, Arguments arguments,
      [Procedure interfaceTarget])
      : super(name, arguments, interfaceTarget);

  KernelSuperMethodInvocation.byReference(
      Name name, Arguments arguments, Reference interfaceTargetReference)
      : super.byReference(name, arguments, interfaceTargetReference);

  @override
  void _collectDependencies(KernelDependencyCollector collector) {
    // Super expressions should never occur in top level type inference.
    // TODO(paulberry): but could they occur due to invalid code?
    assert(false);
  }

  @override
  DartType _inferExpression(
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    // TODO(scheglov): implement.
    return typeNeeded ? const DynamicType() : null;
  }
}

/// Shadow object for [SuperPropertyGet].
class KernelSuperPropertyGet extends SuperPropertyGet
    implements KernelExpression {
  KernelSuperPropertyGet(Name name, [Member interfaceTarget])
      : super(name, interfaceTarget);

  KernelSuperPropertyGet.byReference(
      Name name, Reference interfaceTargetReference)
      : super.byReference(name, interfaceTargetReference);

  @override
  void _collectDependencies(KernelDependencyCollector collector) {
    // Super expressions should never occur in top level type inference.
    // TODO(paulberry): but could they occur due to invalid code?
    assert(false);
  }

  @override
  DartType _inferExpression(
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    // TODO(scheglov): implement.
    return typeNeeded ? const DynamicType() : null;
  }
}

/// Shadow object for [SymbolLiteral].
class KernelSymbolLiteral extends SymbolLiteral implements KernelExpression {
  KernelSymbolLiteral(String value) : super(value);

  @override
  void _collectDependencies(KernelDependencyCollector collector) {
    // No inference dependencies.
  }

  @override
  DartType _inferExpression(
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    // TODO(scheglov): implement.
    return typeNeeded ? const DynamicType() : null;
  }
}

/// Shadow object for [ThisExpression].
class KernelThisExpression extends ThisExpression implements KernelExpression {
  @override
  void _collectDependencies(KernelDependencyCollector collector) {
    // Field initializers are not allowed to refer to [this].  But if it
    // happens, we can still proceed; no additional type inference dependencies
    // are introduced.
  }

  @override
  DartType _inferExpression(
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    return typeNeeded ? (inferrer.thisType ?? const DynamicType()) : null;
  }
}

/// Shadow object for [Throw].
class KernelThrow extends Throw implements KernelExpression {
  KernelThrow(Expression expression) : super(expression);

  @override
  void _collectDependencies(KernelDependencyCollector collector) {
    // No inference dependencies.
  }

  @override
  DartType _inferExpression(
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    inferrer.inferExpression(expression, null, false);
    return typeNeeded ? const BottomType() : null;
  }
}

/// Concrete implementation of [TypeInferenceEngine] specialized to work with
/// kernel objects.
class KernelTypeInferenceEngine extends TypeInferenceEngineImpl {
  KernelTypeInferenceEngine(Instrumentation instrumentation, bool strongMode)
      : super(instrumentation, strongMode);

  @override
  AccessorNode createAccessorNode(KernelMember member) {
    AccessorNode accessorNode = new AccessorNode(this, member);
    member._accessorNode = accessorNode;
    return accessorNode;
  }

  @override
  KernelTypeInferrer createLocalTypeInferrer(
      Uri uri, TypeInferenceListener listener, InterfaceType thisType) {
    return new KernelTypeInferrer._(
        this, uri.toString(), listener, false, thisType, null);
  }

  @override
  MethodNode createMethodNode(KernelProcedure procedure) {
    MethodNode methodNode = new MethodNode(procedure);
    procedure._methodNode = methodNode;
    return methodNode;
  }

  @override
  KernelTypeInferrer createTopLevelTypeInferrer(TypeInferenceListener listener,
      InterfaceType thisType, KernelMember member) {
    return member._typeInferrer = new KernelTypeInferrer._(
        this, member.fileUri, listener, true, thisType, member._accessorNode);
  }

  @override
  KernelTypeInferrer getMemberTypeInferrer(KernelMember member) {
    return member._typeInferrer;
  }
}

/// Concrete implementation of [TypeInferrer] specialized to work with kernel
/// objects.
class KernelTypeInferrer extends TypeInferrerImpl {
  @override
  final typePromoter = new KernelTypePromoter();

  KernelTypeInferrer._(
      KernelTypeInferenceEngine engine,
      String uri,
      TypeInferenceListener listener,
      bool topLevel,
      InterfaceType thisType,
      AccessorNode accessorNode)
      : super(engine, uri, listener, topLevel, thisType, accessorNode);

  @override
  Expression getFieldInitializer(KernelField field) {
    return field.initializer;
  }

  @override
  DartType inferExpression(
      Expression expression, DartType typeContext, bool typeNeeded) {
    // When doing top level inference, we skip subexpressions whose type isn't
    // needed so that we don't induce bogus dependencies on fields mentioned in
    // those subexpressions.
    if (!typeNeeded && isTopLevel) return null;

    if (expression is KernelExpression) {
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
      KernelField field, DartType type, bool typeNeeded) {
    return inferExpression(field.initializer, type, typeNeeded);
  }

  @override
  void inferInitializer(Initializer initializer) {
    if (initializer is KernelInitializer) {
      // Use polymorphic dispatch on [KernelInitializer] to perform whatever
      // kind of type inference is correct for this kind of initializer.
      // TODO(paulberry): experiment to see if dynamic dispatch would be better,
      // so that the type hierarchy will be simpler (which may speed up "is"
      // checks).
      return initializer._inferInitializer(this);
    } else {
      // Encountered an initializer type for which type inference is not yet
      // implemented, so just skip it for now.
      // TODO(paulberry): once the BodyBuilder uses shadow classes for
      // everything, this case should no longer be needed.
    }
  }

  @override
  void inferStatement(Statement statement) {
    if (statement is KernelStatement) {
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
class KernelTypeLiteral extends TypeLiteral implements KernelExpression {
  KernelTypeLiteral(DartType type) : super(type);

  @override
  void _collectDependencies(KernelDependencyCollector collector) {
    // No inference dependencies.
  }

  @override
  DartType _inferExpression(
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    // TODO(scheglov): implement.
    return typeNeeded ? const DynamicType() : null;
  }
}

/// Concrete implementation of [TypePromoter] specialized to work with kernel
/// objects.
class KernelTypePromoter extends TypePromoterImpl {
  @override
  int getVariableFunctionNestingLevel(VariableDeclaration variable) {
    if (variable is KernelVariableDeclaration) {
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
    if (variable is KernelVariableDeclaration) {
      return !variable._isLocalFunction;
    } else {
      // Hack to deal with the fact that BodyBuilder still creates raw
      // VariableDeclaration objects sometimes.
      // TODO(paulberry): get rid of this once the type parameter is
      // KernelVariableDeclaration.
      return true;
    }
  }

  @override
  bool sameExpressions(Expression a, Expression b) {
    return identical(a, b);
  }

  @override
  void setVariableMutatedAnywhere(VariableDeclaration variable) {
    if (variable is KernelVariableDeclaration) {
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
    if (variable is KernelVariableDeclaration) {
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
    if (variable is KernelVariableDeclaration) {
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
class KernelVariableAssignment extends KernelComplexAssignment {
  KernelVariableAssignment(Expression rhs) : super(rhs);

  @override
  DartType _inferExpression(
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    typeNeeded =
        inferrer.listener.variableAssignEnter(desugared, typeContext) ||
            typeNeeded;
    // TODO(paulberry): record the appropriate types on let variables and
    // conditional expressions.
    DartType writeContext;
    var write = this.write;
    if (write is VariableSet) {
      writeContext = write.variable.type;
    }
    var inferredType = _inferRhs(inferrer, writeContext);
    inferrer.listener.variableAssignExit(desugared, inferredType);
    return inferredType;
  }
}

/// Concrete shadow object representing a variable declaration in kernel form.
class KernelVariableDeclaration extends VariableDeclaration
    implements KernelStatement {
  final bool _implicitlyTyped;

  final int _functionNestingLevel;

  bool _mutatedInClosure = false;

  bool _mutatedAnywhere = false;

  final bool _isLocalFunction;

  KernelVariableDeclaration(String name, this._functionNestingLevel,
      {Expression initializer,
      DartType type,
      bool isFinal: false,
      bool isConst: false,
      bool isLocalFunction: false})
      : _implicitlyTyped = type == null,
        _isLocalFunction = isLocalFunction,
        super(name,
            initializer: initializer,
            type: type ?? const DynamicType(),
            isFinal: isFinal,
            isConst: isConst);

  KernelVariableDeclaration.forValue(
      Expression initializer, this._functionNestingLevel)
      : _implicitlyTyped = true,
        _isLocalFunction = false,
        super.forValue(initializer);

  @override
  void _inferStatement(KernelTypeInferrer inferrer) {
    inferrer.listener.variableDeclarationEnter(this);
    var declaredType = _implicitlyTyped ? null : type;
    if (initializer != null) {
      var inferredType = inferrer.inferDeclarationType(inferrer.inferExpression(
          initializer, declaredType, _implicitlyTyped));
      if (inferrer.strongMode && _implicitlyTyped) {
        inferrer.instrumentation?.record(Uri.parse(inferrer.uri), fileOffset,
            'type', new InstrumentationValueForType(inferredType));
        type = inferredType;
      }
    }
    inferrer.listener.variableDeclarationExit(this);
  }

  /// Determine whether the given [KernelVariableDeclaration] had an implicit
  /// type.
  ///
  /// This is static to avoid introducing a method that would be visible to
  /// the kernel.
  static bool isImplicitlyTyped(KernelVariableDeclaration variable) =>
      variable._implicitlyTyped;
}

/// Concrete shadow object representing a read from a variable in kernel form.
class KernelVariableGet extends VariableGet implements KernelExpression {
  final TypePromotionFact _fact;

  final TypePromotionScope _scope;

  KernelVariableGet(VariableDeclaration variable, this._fact, this._scope)
      : super(variable);

  @override
  void _collectDependencies(KernelDependencyCollector collector) {
    // No inference dependencies.
  }

  @override
  DartType _inferExpression(
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    var variable = this.variable as KernelVariableDeclaration;
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

/// Concrete shadow object representing a yield statement in kernel form.
class KernelYieldStatement extends YieldStatement implements KernelStatement {
  KernelYieldStatement(Expression expression, {bool isYieldStar: false})
      : super(expression, isYieldStar: isYieldStar);

  @override
  void _inferStatement(KernelTypeInferrer inferrer) {
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
  accept(v) {
    return internalError("Internal error: Unsupported operation.");
  }

  accept1(v, arg) {
    return internalError("Internal error: Unsupported operation.");
  }

  getStaticType(types) {
    return internalError("Internal error: Unsupported operation.");
  }

  transformChildren(v) {
    return internalError("Internal error: Unsupported operation.");
  }

  visitChildren(v) {
    return internalError("Internal error: Unsupported operation.");
  }
}
