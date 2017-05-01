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
import 'package:front_end/src/fasta/type_inference/type_inferrer.dart';
import 'package:front_end/src/fasta/type_inference/type_promotion.dart';
import 'package:kernel/ast.dart';

/// Concrete shadow object representing a statement block in kernel form.
class KernelBlock extends Block implements KernelStatement {
  KernelBlock(List<Statement> statements) : super(statements);

  @override
  void _inferStatement(KernelTypeInferrer inferrer) {
    for (var statement in statements) {
      inferrer.inferStatement(statement);
    }
  }
}

/// Concrete shadow object representing a double literal in kernel form.
class KernelDoubleLiteral extends DoubleLiteral implements KernelExpression {
  KernelDoubleLiteral(double value) : super(value);

  @override
  DartType _inferExpression(
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    return inferrer.inferDoubleLiteral(typeContext, typeNeeded);
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
    inferrer.inferExpressionStatement(expression);
  }
}

/// Concrete shadow object representing a field in kernel form.
class KernelField extends Field {
  bool _implicitlyTyped = true;

  FieldNode<KernelField> _fieldNode;

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

/// Concrete shadow object representing a function expression in kernel form.
class KernelFunctionExpression extends FunctionExpression
    implements KernelExpression {
  KernelFunctionExpression(FunctionNode function) : super(function);

  @override
  DartType _inferExpression(
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    var asyncMarker = function.asyncMarker;
    bool isAsync = asyncMarker == AsyncMarker.Async ||
        asyncMarker == AsyncMarker.AsyncStar;
    bool isGenerator = asyncMarker == AsyncMarker.SyncStar ||
        asyncMarker == AsyncMarker.AsyncStar;
    return inferrer.inferFunctionExpression(
        typeContext,
        typeNeeded,
        function.body,
        function.body is ReturnStatement,
        isAsync,
        isGenerator,
        fileOffset, (type) {
      function.returnType = type;
    }, () => function.functionType);
  }
}

/// Concrete shadow object representing an if statement in kernel form.
class KernelIfStatement extends IfStatement implements KernelStatement {
  KernelIfStatement(Expression condition, Statement then, Statement otherwise)
      : super(condition, then, otherwise);

  @override
  void _inferStatement(KernelTypeInferrer inferrer) {
    inferrer.inferIfStatement(condition, then, otherwise);
  }
}

/// Concrete shadow object representing an integer literal in kernel form.
class KernelIntLiteral extends IntLiteral implements KernelExpression {
  KernelIntLiteral(int value) : super(value);

  @override
  DartType _inferExpression(
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    return inferrer.inferIntLiteral(typeContext, typeNeeded);
  }
}

/// Concrete shadow object representing a non-inverted "is" test in kernel form.
class KernelIsExpression extends IsExpression implements KernelExpression {
  KernelIsExpression(Expression operand, DartType type) : super(operand, type);

  @override
  DartType _inferExpression(
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    return inferrer.inferIsExpression(typeContext, typeNeeded, operand);
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
    return inferrer.inferIsExpression(
        typeContext, typeNeeded, isExpression.operand);
  }
}

/// Concrete shadow object representing a list literal in kernel form.
class KernelListLiteral extends ListLiteral implements KernelExpression {
  KernelListLiteral(List<KernelExpression> expressions,
      {DartType typeArgument, bool isConst: false})
      : super(expressions, typeArgument: typeArgument, isConst: isConst);

  @override
  DartType _inferExpression(
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    // TODO(paulberry): implement.
    return typeNeeded ? const DynamicType() : null;
  }
}

/// Concrete shadow object representing a null literal in kernel form.
class KernelNullLiteral extends NullLiteral implements KernelExpression {
  @override
  DartType _inferExpression(
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    // TODO(paulberry): implement.
    return typeNeeded ? const DynamicType() : null;
  }
}

/// Concrete shadow object representing a return statement in kernel form.
class KernelReturnStatement extends ReturnStatement implements KernelStatement {
  KernelReturnStatement([KernelExpression expression]) : super(expression);

  @override
  void _inferStatement(KernelTypeInferrer inferrer) {
    // TODO(paulberry): implement.
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
    return inferrer.inferStaticGet(typeContext, typeNeeded, target.getterType);
  }
}

/// Concrete implementation of [TypeInferenceEngine] specialized to work with
/// kernel objects.
class KernelTypeInferenceEngine extends TypeInferenceEngineImpl<KernelField> {
  KernelTypeInferenceEngine(Instrumentation instrumentation, bool strongMode)
      : super(instrumentation, strongMode);

  @override
  void clearFieldInitializer(KernelField field) {
    field.initializer = null;
  }

  @override
  FieldNode<KernelField> createFieldNode(KernelField field) {
    FieldNode<KernelField> fieldNode = new FieldNode<KernelField>(this, field);
    field._fieldNode = fieldNode;
    return fieldNode;
  }

  @override
  KernelTypeInferrer createLocalTypeInferrer(Uri uri) {
    return new KernelTypeInferrer._(this, uri.toString());
  }

  @override
  KernelTypeInferrer createTopLevelTypeInferrer(KernelField field) {
    return field._typeInferrer =
        new KernelTypeInferrer._(this, getFieldUri(field));
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
  List<FieldNode<KernelField>> getFieldDependencies(KernelField field) {
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
class KernelTypeInferrer extends TypeInferrerImpl<Statement, Expression,
    VariableDeclaration, KernelField> {
  @override
  final typePromoter = new KernelTypePromoter();

  KernelTypeInferrer._(KernelTypeInferenceEngine engine, String uri)
      : super(engine, uri);

  @override
  Expression getFieldInitializer(KernelField field) {
    return field.initializer;
  }

  @override
  FieldNode<KernelField> getFieldNodeForReadTarget(Member readTarget) {
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

  KernelVariableDeclaration(String name, this._functionNestingLevel,
      {Expression initializer,
      DartType type,
      bool isFinal: false,
      bool isConst: false})
      : _implicitlyTyped = type == null,
        super(name,
            initializer: initializer,
            type: type ?? const DynamicType(),
            isFinal: isFinal,
            isConst: isConst);

  DartType get _declaredType => _implicitlyTyped ? null : type;

  @override
  void _inferStatement(KernelTypeInferrer inferrer) {
    inferrer.inferVariableDeclaration(
        _implicitlyTyped ? null : type, initializer, fileOffset, (type) {
      this.type = type;
    });
  }
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
    bool mutatedInClosure;
    DartType declaredType;
    var variable = this.variable;
    if (variable is KernelVariableDeclaration) {
      mutatedInClosure = variable._mutatedInClosure;
      declaredType = variable._declaredType;
    } else {
      // Hack to deal with the fact that BodyBuilder still creates raw
      // VariableDeclaration objects sometimes.
      // TODO(paulberry): get rid of this once the type parameter is
      // KernelVariableDeclaration.
      mutatedInClosure = true;
      declaredType = variable.type;
    }
    return inferrer.inferVariableGet(typeContext, typeNeeded, mutatedInClosure,
        _fact, _scope, fileOffset, declaredType, (type) {
      promotedType = type;
    });
  }
}
