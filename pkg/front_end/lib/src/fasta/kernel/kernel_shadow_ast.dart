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
import 'package:front_end/src/fasta/type_inference/type_inference_engine.dart';
import 'package:front_end/src/fasta/type_inference/type_inference_listener.dart';
import 'package:front_end/src/fasta/type_inference/type_inferrer.dart';
import 'package:front_end/src/fasta/type_inference/type_promotion.dart';
import 'package:front_end/src/fasta/type_inference/type_schema.dart';
import 'package:front_end/src/fasta/type_inference/type_schema_elimination.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/type_algebra.dart';

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
  DartType _inferExpression(
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    // TODO(scheglov): implement.
    return typeNeeded ? const DynamicType() : null;
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
  DartType _inferExpression(
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    typeNeeded =
        inferrer.listener.boolLiteralEnter(this, typeContext) || typeNeeded;
    var inferredType = typeNeeded ? inferrer.coreTypes.boolClass.rawType : null;
    inferrer.listener.boolLiteralExit(this, inferredType);
    return inferredType;
  }
}

/// Concrete shadow object representing a conditional expression in kernel form.
/// Shadow object for [ConditionalExpression].
class KernelConditionalExpression extends ConditionalExpression
    implements KernelExpression {
  KernelConditionalExpression(
      Expression condition, Expression then, Expression otherwise)
      : super(condition, then, otherwise, const DynamicType());

  @override
  DartType _inferExpression(
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    typeNeeded =
        inferrer.listener.conditionalExpressionEnter(this, typeContext) ||
            typeNeeded;
    inferrer.inferExpression(
        condition, inferrer.coreTypes.boolClass.rawType, false);
    // TODO(paulberry): is it correct to pass the context down?
    DartType thenType = inferrer.inferExpression(then, typeContext, true);
    DartType otherwiseType =
        inferrer.inferExpression(otherwise, typeContext, true);
    // TODO(paulberry): the spec proposal says we should only use LUB if the
    // typeContext is `null`.  If typeContext is non-null, we should use the
    // greatest closure of the context with respect to `?`
    DartType type = inferrer.typeSchemaEnvironment
        .getLeastUpperBound(thenType, otherwiseType);
    staticType = type;
    var inferredType = typeNeeded ? type : null;
    inferrer.listener.conditionalExpressionExit(this, inferredType);
    return inferredType;
  }
}

/// Shadow object for [ConstructorInvocation].
class KernelConstructorInvocation extends ConstructorInvocation
    implements KernelExpression {
  KernelConstructorInvocation(Constructor target, Arguments arguments,
      {bool isConst: false})
      : super(target, arguments, isConst: isConst);

  KernelConstructorInvocation.byReference(
      Reference targetReference, Arguments arguments)
      : super.byReference(targetReference, arguments);

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
        target.function.functionType,
        target.enclosingClass.thisType,
        arguments);
    inferrer.listener.constructorInvocationExit(this, inferredType);
    return inferredType;
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
  DartType _inferExpression(
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    // TODO(scheglov): implement.
    return typeNeeded ? const DynamicType() : null;
  }
}

/// Shadow object for [DirectPropertySet].
class KernelDirectPropertySet extends DirectPropertySet
    implements KernelExpression {
  KernelDirectPropertySet(Expression receiver, Member target, Expression value)
      : super(receiver, target, value);

  KernelDirectPropertySet.byReference(
      Expression receiver, Reference targetReference, Expression value)
      : super.byReference(receiver, targetReference, value);

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
  KernelFactoryConstructorInvocation(Procedure target, Arguments arguments,
      {bool isConst: false})
      : super(target, arguments, isConst: isConst);

  @override
  DartType _inferExpression(
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    typeNeeded =
        inferrer.listener.constructorInvocationEnter(this, typeContext) ||
            typeNeeded;
    var returnType = target.enclosingClass.thisType;
    if (target.enclosingClass.typeParameters.isNotEmpty) {
      // target.enclosingClass.typeParameters is not the same as
      // target.function.functionType.typeParameters, so we have to substitute.
      // TODO(paulberrry): it would be easier if we could just use
      // target.function.functionType.returnType, but that's `dynamic` for
      // factory constructors.  Investigate whether this can be changed.
      returnType = Substitution
          .fromPairs(
              target.enclosingClass.typeParameters,
              target.function.functionType.typeParameters
                  .map((p) => new TypeParameterType(p))
                  .toList())
          .substituteType(returnType);
    }
    var inferredType = inferrer.inferInvocation(typeContext, typeNeeded,
        fileOffset, target.function.functionType, returnType, arguments);
    inferrer.listener.constructorInvocationExit(this, inferredType);
    return inferredType;
  }
}

/// Concrete shadow object representing a field in kernel form.
class KernelField extends Field {
  bool _implicitlyTyped = true;

  FieldNode _fieldNode;

  bool _isInferred = false;

  KernelTypeInferrer _typeInferrer;

  KernelField(Name name, {String fileUri}) : super(name, fileUri: fileUri) {}

  @override
  void set type(DartType value) {
    _implicitlyTyped = false;
    super.type = value;
  }

  String get _fileUri {
    // TODO(paulberry): This is a hack.  We should use this.fileUri, because we
    // want the URI of the compilation unit.  But that gives a relative URI,
    // and I don't know what it's relative to or how to convert it to an
    // absolute URI.
    return enclosingLibrary.importUri.toString();
  }

  void _setInferredType(DartType inferredType) {
    _isInferred = true;
    super.type = inferredType;
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
    var oldClosureContext = inferrer.closureContext;
    inferrer.closureContext =
        new ClosureContext(inferrer, function.asyncMarker, function.returnType);
    inferrer.inferStatement(function.body);
    inferrer.closureContext = oldClosureContext;
    inferrer.listener.functionDeclarationExit(this);
  }
}

/// Concrete shadow object representing a function expression in kernel form.
class KernelFunctionExpression extends FunctionExpression
    implements KernelExpression {
  KernelFunctionExpression(FunctionNode function) : super(function);

  @override
  DartType _inferExpression(
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    typeNeeded = inferrer.listener.functionExpressionEnter(this, typeContext) ||
        typeNeeded;
    // TODO(paulberry): do we also need to visit default parameter values?

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

/// Concrete shadow object representing an integer literal in kernel form.
class KernelIntLiteral extends IntLiteral implements KernelExpression {
  KernelIntLiteral(int value) : super(value);

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
    for (var expression in expressions) {
      var expressionType = inferrer.inferExpression(
          expression, inferredTypeArgument, inferenceNeeded);
      if (inferenceNeeded) {
        formalTypes.add(listType.typeArguments[0]);
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
  DartType _inferExpression(
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    // TODO(scheglov): implement.
    return typeNeeded ? const DynamicType() : null;
  }
}

/// Shadow object for [MapLiteral].
class KernelMapLiteral extends MapLiteral implements KernelExpression {
  KernelMapLiteral(List<MapEntry> entries,
      {DartType keyType: const DynamicType(),
      DartType valueType: const DynamicType(),
      bool isConst: false})
      : super(entries,
            keyType: keyType, valueType: valueType, isConst: isConst);

  @override
  DartType _inferExpression(
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    // TODO(scheglov): implement.
    return typeNeeded ? const DynamicType() : null;
  }
}

/// Shadow object for [MethodInvocation].
class KernelMethodInvocation extends MethodInvocation
    implements KernelExpression {
  KernelMethodInvocation(Expression receiver, Name name, Arguments arguments,
      [Procedure interfaceTarget])
      : super(receiver, name, arguments, interfaceTarget);

  KernelMethodInvocation.byReference(Expression receiver, Name name,
      Arguments arguments, Reference interfaceTargetReference)
      : super.byReference(receiver, name, arguments, interfaceTargetReference);

  @override
  DartType _inferExpression(
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    typeNeeded = inferrer.listener.methodInvocationEnter(this, typeContext) ||
        typeNeeded;
    // First infer the receiver so we can look up the method that was invoked.
    var receiverType = inferrer.inferExpression(receiver, null, true);
    bool isOverloadedArithmeticOperator = false;
    Member interfaceMember;
    if (receiverType is InterfaceType) {
      interfaceMember = inferrer.classHierarchy
          .getInterfaceMember(receiverType.classNode, name);
      if (interfaceMember is Procedure) {
        // Our non-strong golden files currently don't include interface
        // targets, so we can't store the interface target without causing tests
        // to fail.  TODO(paulberry): fix this.
        if (inferrer.strongMode) {
          interfaceTarget = interfaceMember;
        }
        isOverloadedArithmeticOperator = inferrer.typeSchemaEnvironment
            .isOverloadedArithmeticOperator(interfaceMember);
      }
    }
    var calleeType = inferrer.getCalleeFunctionType(
        interfaceMember, receiverType, name, fileOffset);
    var inferredType = inferrer.inferInvocation(typeContext, typeNeeded,
        fileOffset, calleeType, calleeType.returnType, arguments,
        isOverloadedArithmeticOperator: isOverloadedArithmeticOperator,
        receiverType: receiverType);
    inferrer.listener.methodInvocationExit(this, inferredType);
    return inferredType;
  }
}

/// Shadow object for [Not].
class KernelNot extends Not implements KernelExpression {
  KernelNot(Expression operand) : super(operand);

  @override
  DartType _inferExpression(
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    // TODO(scheglov): implement.
    return typeNeeded ? const DynamicType() : null;
  }
}

/// Concrete shadow object representing a null literal in kernel form.
class KernelNullLiteral extends NullLiteral implements KernelExpression {
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

/// Shadow object for [PropertyGet].
class KernelPropertyGet extends PropertyGet implements KernelExpression {
  KernelPropertyGet(Expression receiver, Name name, [Member interfaceTarget])
      : super(receiver, name, interfaceTarget);

  KernelPropertyGet.byReference(
      Expression receiver, Name name, Reference interfaceTargetReference)
      : super.byReference(receiver, name, interfaceTargetReference);

  @override
  DartType _inferExpression(
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    // TODO(scheglov): implement.
    return typeNeeded ? const DynamicType() : null;
  }
}

/// Shadow object for [PropertyGet].
class KernelPropertySet extends PropertySet implements KernelExpression {
  KernelPropertySet(Expression receiver, Name name, Expression value,
      [Member interfaceTarget])
      : super(receiver, name, value, interfaceTarget);

  KernelPropertySet.byReference(Expression receiver, Name name,
      Expression value, Reference interfaceTargetReference)
      : super.byReference(receiver, name, value, interfaceTargetReference);

  @override
  DartType _inferExpression(
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    // TODO(scheglov): implement.
    return typeNeeded ? const DynamicType() : null;
  }
}

/// Shadow object for [Rethrow].
class KernelRethrow extends Rethrow implements KernelExpression {
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

/// Concrete shadow object representing a read of a static variable in kernel
/// form.
class KernelStaticGet extends StaticGet implements KernelExpression {
  KernelStaticGet(Member target) : super(target);

  @override
  DartType _inferExpression(
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    typeNeeded =
        inferrer.listener.staticGetEnter(this, typeContext) || typeNeeded;
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

/// Shadow object for [StaticSet].
class KernelStaticSet extends StaticSet implements KernelExpression {
  KernelStaticSet(Member target, Expression value) : super(target, value);

  KernelStaticSet.byReference(Reference targetReference, Expression value)
      : super.byReference(targetReference, value);

  @override
  DartType _inferExpression(
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    // TODO(scheglov): implement.
    return typeNeeded ? const DynamicType() : null;
  }
}

/// Concrete shadow object representing a string concatenation in kernel form.
class KernelStringConcatenation extends StringConcatenation
    implements KernelExpression {
  KernelStringConcatenation(List<Expression> expressions) : super(expressions);

  @override
  DartType _inferExpression(
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    typeNeeded =
        inferrer.listener.stringConcatenationEnter(this, typeContext) ||
            typeNeeded;
    for (Expression expression in expressions) {
      inferrer.inferExpression(expression, null, false);
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
  DartType _inferExpression(
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    // TODO(scheglov): implement.
    return typeNeeded ? const DynamicType() : null;
  }
}

/// Shadow object for [SuperPropertySet].
class KernelSuperPropertySet extends SuperPropertySet
    implements KernelExpression {
  KernelSuperPropertySet(Name name, Expression value, Member interfaceTarget)
      : super(name, value, interfaceTarget);

  KernelSuperPropertySet.byReference(
      Name name, Expression value, Reference interfaceTargetReference)
      : super.byReference(name, value, interfaceTargetReference);

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
  DartType _inferExpression(
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    // TODO(scheglov): implement.
    return typeNeeded ? const DynamicType() : null;
  }
}

/// Shadow object for [ThisExpression].
class KernelThisExpression extends ThisExpression implements KernelExpression {
  @override
  DartType _inferExpression(
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    // TODO(scheglov): implement.
    return typeNeeded ? const DynamicType() : null;
  }
}

/// Shadow object for [Throw].
class KernelThrow extends Throw implements KernelExpression {
  KernelThrow(Expression expression) : super(expression);

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
  void clearFieldInitializer(KernelField field) {
    field.initializer = null;
  }

  @override
  FieldNode createFieldNode(KernelField field) {
    FieldNode fieldNode = new FieldNode(this, field);
    field._fieldNode = fieldNode;
    return fieldNode;
  }

  @override
  KernelTypeInferrer createLocalTypeInferrer(
      Uri uri, TypeInferenceListener listener) {
    return new KernelTypeInferrer._(this, uri.toString(), listener);
  }

  @override
  KernelTypeInferrer createTopLevelTypeInferrer(
      KernelField field, TypeInferenceListener listener) {
    return field._typeInferrer =
        new KernelTypeInferrer._(this, getFieldUri(field), listener);
  }

  @override
  bool fieldHasInitializer(KernelField field) {
    return field.initializer != null;
  }

  @override
  DartType getFieldDeclaredType(KernelField field) {
    return field._implicitlyTyped ? null : field.type;
  }

  @override
  List<FieldNode> getFieldDependencies(KernelField field) {
    return field._fieldNode?.dependencies;
  }

  @override
  int getFieldOffset(KernelField field) {
    return field.fileOffset;
  }

  @override
  KernelTypeInferrer getFieldTypeInferrer(KernelField field) {
    return field._typeInferrer;
  }

  @override
  String getFieldUri(KernelField field) {
    return field._fileUri;
  }

  @override
  bool isFieldInferred(KernelField field) {
    return field._isInferred;
  }

  @override
  void setFieldInferredType(KernelField field, DartType inferredType) {
    field._setInferredType(inferredType);
  }
}

/// Concrete implementation of [TypeInferrer] specialized to work with kernel
/// objects.
class KernelTypeInferrer extends TypeInferrerImpl {
  @override
  final typePromoter = new KernelTypePromoter();

  KernelTypeInferrer._(KernelTypeInferenceEngine engine, String uri,
      TypeInferenceListener listener)
      : super(engine, uri, listener);

  @override
  Expression getFieldInitializer(KernelField field) {
    return field.initializer;
  }

  @override
  FieldNode getFieldNodeForReadTarget(Member readTarget) {
    if (readTarget is KernelField) {
      return readTarget._fieldNode;
    } else {
      return null;
    }
  }

  @override
  DartType inferExpression(
      Expression expression, DartType typeContext, bool typeNeeded) {
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
  DartType inferFieldInitializer(
      KernelField field, DartType type, bool typeNeeded) {
    return inferExpression(field.initializer, type, typeNeeded);
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
  DartType _inferExpression(
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    // TODO(scheglov): implement.
    return typeNeeded ? const DynamicType() : null;
  }
}

/// Concrete implementation of [TypePromoter] specialized to work with kernel
/// objects.
///
/// Note: the second type parameter really ought to be
/// KernelVariableDeclaration, but we can't do that yet because BodyBuilder
/// still uses raw VariableDeclaration objects sometimes.
/// TODO(paulberry): fix this.
class KernelTypePromoter
    extends TypePromoterImpl<Expression, VariableDeclaration> {
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
  final TypePromotionFact<VariableDeclaration> _fact;

  final TypePromotionScope _scope;

  KernelVariableGet(VariableDeclaration variable, this._fact, this._scope)
      : super(variable);

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

/// Concrete shadow object representing a write to a variable in kernel form.
class KernelVariableSet extends VariableSet implements KernelExpression {
  KernelVariableSet(VariableDeclaration variable, Expression value)
      : super(variable, value);

  @override
  DartType _inferExpression(
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    var variable = this.variable as KernelVariableDeclaration;
    typeNeeded =
        inferrer.listener.variableSetEnter(this, typeContext) || typeNeeded;
    var inferredType =
        inferrer.inferExpression(value, variable.type, typeNeeded);
    inferrer.listener.variableSetExit(this, inferredType);
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
    var inferredType = inferrer.inferExpression(
        expression, typeContext, closureContext != null);
    closureContext.handleYield(inferrer, isYieldStar, inferredType);
    inferrer.listener.yieldStatementExit(this);
  }
}
