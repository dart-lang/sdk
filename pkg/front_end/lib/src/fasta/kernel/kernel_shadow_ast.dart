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

import 'dart:core' hide MapEntry;

import 'package:kernel/ast.dart';

import 'package:kernel/type_algebra.dart' show Substitution;

import '../../base/instrumentation.dart'
    show
        Instrumentation,
        InstrumentationValueForMember,
        InstrumentationValueForType,
        InstrumentationValueForTypeArgs;

import '../builder/library_builder.dart' show LibraryBuilder;

import '../fasta_codes.dart'
    show
        messageCantDisambiguateAmbiguousInformation,
        messageCantDisambiguateNotEnoughInformation,
        messageNonNullAwareSpreadIsNull,
        messageSwitchExpressionNotAssignableCause,
        messageVoidExpression,
        noLength,
        templateCantInferTypeDueToCircularity,
        templateForInLoopElementTypeNotAssignable,
        templateForInLoopTypeNotIterable,
        templateIntegerLiteralIsOutOfRange,
        templateSpreadElementTypeMismatch,
        templateSpreadMapEntryElementKeyTypeMismatch,
        templateSpreadMapEntryElementValueTypeMismatch,
        templateSpreadMapEntryTypeMismatch,
        templateSpreadTypeMismatch,
        templateSwitchExpressionNotAssignable,
        templateUndefinedMethod,
        templateWebLiteralCannotBeRepresentedExactly;

import '../problems.dart' show getFileUri, unhandled, unsupported;

import '../source/source_class_builder.dart' show SourceClassBuilder;

import '../source/source_library_builder.dart' show SourceLibraryBuilder;

import '../type_inference/inference_helper.dart' show InferenceHelper;

import '../type_inference/type_inference_engine.dart'
    show IncludesTypeParametersNonCovariantly, TypeInferenceEngine;

import '../type_inference/type_inferrer.dart';

import '../type_inference/type_promotion.dart'
    show TypePromoter, TypePromoterImpl, TypePromotionFact, TypePromotionScope;

import '../type_inference/type_schema.dart' show UnknownType;

import '../type_inference/type_schema_elimination.dart' show greatestClosure;

import '../type_inference/type_schema_environment.dart'
    show TypeSchemaEnvironment, getPositionalParameterType;

import 'body_builder.dart' show combineStatements;

import 'collections.dart'
    show
        ControlFlowMapEntry,
        ForElement,
        ForInElement,
        ForInMapEntry,
        ForMapEntry,
        IfElement,
        IfMapEntry,
        SpreadElement,
        SpreadMapEntry,
        convertToElement;

import 'expression_generator.dart' show makeLet;

import 'implicit_type_argument.dart' show ImplicitTypeArgument;

part "inference_visitor.dart";

/// Computes the return type of a (possibly factory) constructor.
InterfaceType computeConstructorReturnType(Member constructor) {
  if (constructor is Constructor) {
    return constructor.enclosingClass.thisType;
  } else {
    return constructor.function.returnType;
  }
}

int getExtensionTypeParameterCount(Arguments arguments) {
  if (arguments is ArgumentsImpl) {
    return arguments._extensionTypeParameterCount;
  } else {
    // TODO(johnniwinther): Remove this path or assert why it is accepted.
    return 0;
  }
}

int getExtensionTypeArgumentCount(Arguments arguments) {
  if (arguments is ArgumentsImpl) {
    return arguments._extensionTypeArgumentCount;
  } else {
    // TODO(johnniwinther): Remove this path or assert why it is accepted.
    return 0;
  }
}

List<DartType> getExplicitExtensionTypeArguments(Arguments arguments) {
  if (arguments is ArgumentsImpl) {
    if (arguments._extensionTypeArgumentCount == 0) {
      return null;
    } else {
      return arguments.types
          .take(arguments._extensionTypeArgumentCount)
          .toList();
    }
  } else {
    // TODO(johnniwinther): Remove this path or assert why it is accepted.
    return null;
  }
}

List<DartType> getExplicitTypeArguments(Arguments arguments) {
  if (arguments is ArgumentsImpl) {
    if (arguments._explicitTypeArgumentCount == 0) {
      return null;
    } else if (arguments._extensionTypeParameterCount == 0) {
      return arguments.types;
    } else {
      return arguments.types
          .skip(arguments._extensionTypeParameterCount)
          .toList();
    }
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
  IncludesTypeParametersNonCovariantly needsCheckVisitor;

  /// Getters and methods in the class's API.  May include forwarding nodes.
  final gettersAndMethods = <Member>[];

  /// Setters in the class's API.  May include forwarding nodes.
  final setters = <Member>[];

  ClassInferenceInfo(this.builder);
}

enum InternalExpressionKind {
  Cascade,
  CompoundPropertyAssignment,
  DeferredCheck,
  IfNullPropertySet,
  IndexSet,
  LoadLibraryTearOff,
  LocalPostIncDec,
  NullAwareMethodInvocation,
  NullAwarePropertyGet,
  NullAwarePropertySet,
  PropertyPostIncDec,
}

/// Common base class for internal expressions.
abstract class InternalExpression extends Expression {
  InternalExpressionKind get kind;

  /// Replaces this [InternalExpression] with a semantically equivalent
  /// [Expression] and returns the replacing [Expression].
  ///
  /// This method most be called after inference has been performed to ensure
  /// that [InternalExpression] nodes do not leak.
  Expression replace() {
    throw new UnsupportedError('$runtimeType.replace()');
  }

  @override
  R accept<R>(ExpressionVisitor<R> visitor) => visitor.defaultExpression(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> visitor, A arg) =>
      visitor.defaultExpression(this, arg);

  @override
  DartType getStaticType(types) =>
      unsupported("${runtimeType}.getStaticType", -1, null);
}

/// Front end specific implementation of [Argument].
class ArgumentsImpl extends Arguments {
  // TODO(johnniwinther): Move this to the static invocation instead.
  final int _extensionTypeParameterCount;

  final int _extensionTypeArgumentCount;

  int _explicitTypeArgumentCount;

  ArgumentsImpl(List<Expression> positional,
      {List<DartType> types, List<NamedExpression> named})
      : _explicitTypeArgumentCount = types?.length ?? 0,
        _extensionTypeParameterCount = 0,
        _extensionTypeArgumentCount = 0,
        super(positional, types: types, named: named);

  ArgumentsImpl.forExtensionMethod(int extensionTypeParameterCount,
      int typeParameterCount, Expression receiver,
      {List<DartType> extensionTypeArguments = const <DartType>[],
      List<DartType> typeArguments = const <DartType>[],
      List<Expression> positionalArguments = const <Expression>[],
      List<NamedExpression> namedArguments = const <NamedExpression>[]})
      : _extensionTypeParameterCount = extensionTypeParameterCount,
        _extensionTypeArgumentCount = extensionTypeArguments.length,
        _explicitTypeArgumentCount = typeArguments.length,
        assert(
            extensionTypeArguments.isEmpty ||
                extensionTypeArguments.length == extensionTypeParameterCount,
            "Extension type arguments must be empty or complete."),
        super(<Expression>[receiver]..addAll(positionalArguments),
            named: namedArguments,
            types: <DartType>[]
              ..addAll(_normalizeTypeArguments(
                  extensionTypeParameterCount, extensionTypeArguments))
              ..addAll(
                  _normalizeTypeArguments(typeParameterCount, typeArguments)));

  static List<DartType> _normalizeTypeArguments(
      int length, List<DartType> arguments) {
    if (arguments.isEmpty && length > 0) {
      return new List<DartType>.filled(length, const UnknownType());
    }
    return arguments;
  }

  static void setNonInferrableArgumentTypes(
      ArgumentsImpl arguments, List<DartType> types) {
    arguments.types.clear();
    arguments.types.addAll(types);
    arguments._explicitTypeArgumentCount = types.length;
  }

  static void removeNonInferrableArgumentTypes(ArgumentsImpl arguments) {
    arguments.types.clear();
    arguments._explicitTypeArgumentCount = 0;
  }
}

/// Internal expression representing a cascade expression.
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
/// After constructing a [Cascade], the caller should
/// call [finalize] with an expression representing the expression after the
/// `..`.  If a further `..` follows that expression, the caller should call
/// [extend] followed by [finalize] for each subsequent cascade.
// TODO(johnniwinther): Change the representation to be direct and perform
// the [Let] encoding in [replace].
class Cascade extends InternalExpression {
  VariableDeclaration variable;

  /// Pointer to the first "let" expression in the cascade, i.e. `e1` in
  /// `e..e1..e2..e3`;
  Let _firstCascade;

  /// Pointer to the last "let" expression in the cascade, i.e. `e3` in
  //  /// `e..e1..e2..e3`;
  Let _lastCascade;

  /// Creates a [Cascade] using [variable] as the cascade
  /// variable.  Caller is responsible for ensuring that [variable]'s
  /// initializer is the expression preceding the first `..` of the cascade
  /// expression.
  Cascade(this.variable) {
    _lastCascade = _firstCascade = makeLet(
        new VariableDeclaration.forValue(new _UnfinishedCascade()),
        new VariableGet(variable));
    variable.parent = this;
    _firstCascade.parent = this;
  }

  @override
  InternalExpressionKind get kind => InternalExpressionKind.Cascade;

  /// The initial expression of the cascade, i.e. `e` in `e..e1..e2..e3`.
  Expression get expression => variable.initializer;

  /// Returns the cascade expressions of the cascade, i.e. `e1`, `e2`, and `e3`
  /// in `e..e1..e2..e3`.
  Iterable<Expression> get cascades sync* {
    Let section = _firstCascade;
    while (true) {
      yield section.variable.initializer;
      if (section.body is! Let) break;
      section = section.body;
    }
  }

  /// Adds a new unfinalized section to the end of the cascade.  Should be
  /// called after the previous cascade section has been finalized.
  void extend() {
    assert(_lastCascade.variable.initializer is! _UnfinishedCascade);
    Let newCascade = makeLet(
        new VariableDeclaration.forValue(new _UnfinishedCascade()),
        _lastCascade.body);
    _lastCascade.body = newCascade;
    newCascade.parent = _lastCascade;
    _lastCascade = newCascade;
  }

  /// Finalizes the last cascade section with the given [expression].
  void finalize(Expression expression) {
    assert(_lastCascade.variable.initializer is _UnfinishedCascade);
    _lastCascade.variable.initializer = expression;
    expression.parent = _lastCascade.variable;
  }

  @override
  Expression replace() {
    Expression replacement;
    parent.replaceChild(
        this,
        replacement = new Let(variable, _firstCascade)
          ..fileOffset = fileOffset);
    return replacement;
  }

  @override
  void visitChildren(Visitor<dynamic> v) {
    variable?.accept(v);
    _firstCascade?.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    if (variable != null) {
      variable = variable.accept<TreeNode>(v);
      variable?.parent = this;
    }
    if (_firstCascade != null) {
      _firstCascade = _firstCascade.accept<TreeNode>(v);
      _firstCascade?.parent = this;
    }
  }
}

/// Abstract shadow object representing a complex assignment in kernel form.
///
/// Since there are many forms a complex assignment might have been desugared
/// to, this class wraps the desugared assignment rather than extending it.
///
/// TODO(paulberry): once we know exactly what constitutes a "complex
/// assignment", document it here.
abstract class ComplexAssignmentJudgment extends SyntheticExpressionJudgment {
  /// In a compound assignment, the expression that reads the old value, or
  /// `null` if this is not a compound assignment.
  Expression read;

  /// The expression appearing on the RHS of the assignment.
  Expression rhs;

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

  ComplexAssignmentJudgment._(this.rhs) : super._(null);

  String toString() {
    List<String> parts = _getToStringParts();
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

  _ComplexAssignmentInferenceResult _inferRhs(
      ShadowTypeInferrer inferrer, DartType readType, DartType writeContext) {
    assert(writeContext != null);
    if (readType is VoidType &&
        (combiner != null || nullAwareCombiner != null)) {
      inferrer.helper
          ?.addProblem(messageVoidExpression, read.fileOffset, noLength);
    }
    int writeOffset = write == null ? -1 : write.fileOffset;
    ObjectAccessTarget combinerTarget = const ObjectAccessTarget.unresolved();
    DartType combinedType;
    if (combiner != null) {
      bool isOverloadedArithmeticOperator = false;
      combinerTarget = inferrer.findMethodInvocationMember(readType, combiner,
          instrumented: false);
      assert(!combinerTarget.isCallFunction);
      if (combinerTarget.isInstanceMember &&
          combinerTarget.member is Procedure) {
        isOverloadedArithmeticOperator = inferrer.typeSchemaEnvironment
            .isOverloadedArithmeticOperatorAndType(
                combinerTarget.member, readType);
      }
      DartType rhsType;
      FunctionType combinerType =
          inferrer.getFunctionType(combinerTarget, readType, false);
      if (isPreIncDec || isPostIncDec) {
        rhsType = inferrer.coreTypes.intRawType(inferrer.library.nonNullable);
      } else {
        // It's not necessary to call _storeLetType for [rhs] because the RHS
        // is always passed directly to the combiner; it's never stored in a
        // temporary variable first.
        assert(identical(combiner.arguments.positional.first, rhs));
        // Analyzer uses a null context for the RHS here.
        // TODO(paulberry): improve on this.
        ExpressionInferenceResult rhsResult =
            inferrer.inferExpression(rhs, const UnknownType(), true);
        if (rhsResult.replacement != null) {
          rhs = rhsResult.replacement;
        }
        rhsType = rhsResult.inferredType;
        // Do not use rhs after this point because it may be a Shadow node
        // that has been replaced in the tree with its desugaring.
        DartType expectedType = getPositionalParameterType(combinerType, 0);
        inferrer.ensureAssignable(expectedType, rhsType,
            combiner.arguments.positional.first, combiner.fileOffset);
      }
      if (isOverloadedArithmeticOperator) {
        combinedType = inferrer.typeSchemaEnvironment
            .getTypeOfOverloadedArithmetic(readType, rhsType);
      } else {
        combinedType = combinerType.returnType;
      }
      MethodContravarianceCheckKind checkKind =
          inferrer.preCheckInvocationContravariance(read, readType,
              combinerTarget, combiner, combiner.arguments, combiner);
      Expression replacedCombiner = inferrer.handleInvocationContravariance(
          checkKind,
          combiner,
          combiner.arguments,
          combiner,
          combinedType,
          combinerType,
          combiner.fileOffset);
      Expression replacedCombiner2 = inferrer.ensureAssignable(
          writeContext, combinedType, replacedCombiner, writeOffset);
      if (replacedCombiner2 != null) {
        replacedCombiner = replacedCombiner2;
      }
      _storeLetType(inferrer, replacedCombiner, combinedType);
    } else {
      ExpressionInferenceResult rhsResult = inferrer.inferExpression(
          rhs, writeContext ?? const UnknownType(), true,
          isVoidAllowed: true);
      if (rhsResult.replacement != null) {
        rhs = rhsResult.replacement;
      }
      DartType rhsType = rhsResult.inferredType;
      Expression replacedRhs = inferrer.ensureAssignable(
          writeContext, rhsType, rhs, writeOffset,
          isVoidAllowed: writeContext is VoidType);
      _storeLetType(inferrer, replacedRhs ?? rhs, rhsType);
      if (nullAwareCombiner != null) {
        MethodInvocation equalsInvocation = nullAwareCombiner.condition;
        inferrer.findMethodInvocationMember(
            greatestClosure(inferrer.coreTypes, writeContext), equalsInvocation,
            instrumented: false);
        // Note: the case of readType=null only happens for erroneous code.
        combinedType = readType == null
            ? rhsType
            : inferrer.typeSchemaEnvironment
                .getStandardUpperBound(readType, rhsType);
        nullAwareCombiner.staticType = combinedType;
      } else {
        combinedType = rhsType;
      }
    }
    if (this is IndexAssignmentJudgment) {
      _storeLetType(inferrer, write, const VoidType());
    } else {
      _storeLetType(inferrer, write, combinedType);
    }
    DartType inferredType =
        isPostIncDec ? (readType ?? const DynamicType()) : combinedType;
    return new _ComplexAssignmentInferenceResult(
        combinerTarget.member, inferredType);
  }
}

/// Abstract shadow object representing a complex assignment involving a
/// receiver.
abstract class ComplexAssignmentJudgmentWithReceiver
    extends ComplexAssignmentJudgment {
  /// The receiver of the assignment target (e.g. `a` in `a[b] = c`).
  final Expression receiver;

  /// Indicates whether this assignment uses `super`.
  final bool isSuper;

  ComplexAssignmentJudgmentWithReceiver._(
      this.receiver, Expression rhs, this.isSuper)
      : super._(rhs);

  @override
  List<String> _getToStringParts() {
    List<String> parts = super._getToStringParts();
    if (receiver != null) parts.add('receiver=$receiver');
    if (isSuper) parts.add('isSuper=true');
    return parts;
  }

  DartType _inferReceiver(ShadowTypeInferrer inferrer) {
    if (receiver != null) {
      DartType receiverType = inferrer
          .inferExpression(receiver, const UnknownType(), true)
          .inferredType;
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

/// Internal expression representing a deferred check.
// TODO(johnniwinther): Change the representation to be direct and perform
// the [Let] encoding in [replace].
class DeferredCheck extends InternalExpression {
  VariableDeclaration _variable;
  Expression expression;

  DeferredCheck(this._variable, this.expression) {
    _variable.parent = this;
    expression.parent = this;
  }

  InternalExpressionKind get kind => InternalExpressionKind.DeferredCheck;

  @override
  Expression replace() {
    Expression replacement;
    parent.replaceChild(this,
        replacement = new Let(_variable, expression)..fileOffset = fileOffset);
    return replacement;
  }

  @override
  void visitChildren(Visitor<dynamic> v) {
    _variable?.accept(v);
    expression?.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    if (_variable != null) {
      _variable = _variable.accept<TreeNode>(v);
      _variable?.parent = this;
    }
    if (expression != null) {
      expression = expression.accept<TreeNode>(v);
      expression?.parent = this;
    }
  }
}

/// Common base class for shadow objects representing expressions in kernel
/// form.
abstract class ExpressionJudgment extends Expression {
  /// Calls back to [inferrer] to perform type inference for whatever concrete
  /// type of [Expression] this is.
  ExpressionInferenceResult acceptInference(
      InferenceVisitor visitor, DartType typeContext);
}

/// Shadow object for [StaticInvocation] when the procedure being invoked is a
/// factory constructor.
class FactoryConstructorInvocationJudgment extends StaticInvocation
    implements ExpressionJudgment {
  bool hasBeenInferred = false;

  FactoryConstructorInvocationJudgment(
      Procedure target, ArgumentsImpl arguments,
      {bool isConst: false})
      : super(target, arguments, isConst: isConst);

  @override
  ExpressionInferenceResult acceptInference(
      InferenceVisitor visitor, DartType typeContext) {
    return visitor.visitFactoryConstructorInvocationJudgment(this, typeContext);
  }
}

/// Front end specific implementation of [FunctionDeclaration].
class FunctionDeclarationImpl extends FunctionDeclaration {
  bool _hasImplicitReturnType = false;

  FunctionDeclarationImpl(
      VariableDeclarationImpl variable, FunctionNode function)
      : super(variable, function);

  static void setHasImplicitReturnType(
      FunctionDeclarationImpl declaration, bool hasImplicitReturnType) {
    declaration._hasImplicitReturnType = hasImplicitReturnType;
  }
}

/// Concrete shadow object representing a super initializer in kernel form.
class InvalidSuperInitializerJudgment extends LocalInitializer
    implements InitializerJudgment {
  final Constructor target;
  final ArgumentsImpl argumentsJudgment;

  InvalidSuperInitializerJudgment(
      this.target, this.argumentsJudgment, VariableDeclaration variable)
      : super(variable);

  @override
  void acceptInference(InferenceVisitor visitor) {
    return visitor.visitInvalidSuperInitializerJudgment(this);
  }
}

/// Concrete shadow object representing an if-null expression.
///
/// An if-null expression of the form `a ?? b` is represented as the kernel
/// expression:
///
///     let v = a in v == null ? b : v
class IfNullJudgment extends Let implements ExpressionJudgment {
  IfNullJudgment(VariableDeclaration variable, Expression body)
      : super(variable, body);

  @override
  ConditionalExpression get body => super.body;

  /// Returns the expression to the left of `??`.
  Expression get left => variable.initializer;

  /// Returns the expression to the right of `??`.
  Expression get right => body.then;

  @override
  ExpressionInferenceResult acceptInference(
      InferenceVisitor visitor, DartType typeContext) {
    return visitor.visitIfNullJudgment(this, typeContext);
  }
}

/// Concrete shadow object representing an assignment to a target for which
/// assignment is not allowed.
class IllegalAssignmentJudgment extends ComplexAssignmentJudgment {
  /// The offset at which the invalid assignment should be stored.
  /// If `-1`, then there is no separate location for invalid assignment.
  final int assignmentOffset;

  IllegalAssignmentJudgment._(Expression rhs, {this.assignmentOffset: -1})
      : super._(rhs) {
    rhs.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
      InferenceVisitor visitor, DartType typeContext) {
    return visitor.visitIllegalAssignmentJudgment(this, typeContext);
  }
}

/// Concrete shadow object representing an assignment to a target of the form
/// `a[b]`.
class IndexAssignmentJudgment extends ComplexAssignmentJudgmentWithReceiver {
  /// In an assignment to an index expression, the index expression.
  Expression index;

  IndexAssignmentJudgment._(Expression receiver, this.index, Expression rhs,
      {bool isSuper: false})
      : super._(receiver, rhs, isSuper);

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
    List<String> parts = super._getToStringParts();
    if (index != null) parts.add('index=$index');
    return parts;
  }

  @override
  ExpressionInferenceResult acceptInference(
      InferenceVisitor visitor, DartType typeContext) {
    return visitor.visitIndexAssignmentJudgment(this, typeContext);
  }
}

/// Common base class for shadow objects representing initializers in kernel
/// form.
abstract class InitializerJudgment implements Initializer {
  /// Performs type inference for whatever concrete type of
  /// [InitializerJudgment] this is.
  void acceptInference(InferenceVisitor visitor);
}

Expression checkWebIntLiteralsErrorIfUnexact(
    ShadowTypeInferrer inferrer, int value, String literal, int charOffset) {
  if (value >= 0 && value <= (1 << 53)) return null;
  if (inferrer.isTopLevel) return null;
  if (!inferrer.library.loader.target.backendTarget
      .errorOnUnexactWebIntLiterals) return null;
  BigInt asInt = new BigInt.from(value).toUnsigned(64);
  BigInt asDouble = new BigInt.from(asInt.toDouble());
  if (asInt == asDouble) return null;
  String text = literal ?? value.toString();
  String nearest = text.startsWith('0x') || text.startsWith('0X')
      ? '0x${asDouble.toRadixString(16)}'
      : asDouble.toString();
  int length = literal?.length ?? noLength;
  return inferrer.helper.desugarSyntheticExpression(inferrer.helper
      .buildProblem(
          templateWebLiteralCannotBeRepresentedExactly.withArguments(
              text, nearest),
          charOffset,
          length));
}

/// Concrete shadow object representing an integer literal in kernel form.
class IntJudgment extends IntLiteral implements ExpressionJudgment {
  final String literal;

  IntJudgment(int value, this.literal) : super(value);

  double asDouble({bool negated: false}) {
    if (value == 0 && negated) return -0.0;
    BigInt intValue = new BigInt.from(negated ? -value : value);
    double doubleValue = intValue.toDouble();
    return intValue == new BigInt.from(doubleValue) ? doubleValue : null;
  }

  @override
  ExpressionInferenceResult acceptInference(
      InferenceVisitor visitor, DartType typeContext) {
    return visitor.visitIntJudgment(this, typeContext);
  }
}

class ShadowLargeIntLiteral extends IntLiteral implements ExpressionJudgment {
  final String literal;
  final int fileOffset;
  bool isParenthesized = false;

  ShadowLargeIntLiteral(this.literal, this.fileOffset) : super(0);

  double asDouble({bool negated: false}) {
    BigInt intValue = BigInt.tryParse(negated ? '-${literal}' : literal);
    if (intValue == null) return null;
    double doubleValue = intValue.toDouble();
    return !doubleValue.isNaN &&
            !doubleValue.isInfinite &&
            intValue == new BigInt.from(doubleValue)
        ? doubleValue
        : null;
  }

  int asInt64({bool negated: false}) {
    return int.tryParse(negated ? '-${literal}' : literal);
  }

  @override
  ExpressionInferenceResult acceptInference(
      InferenceVisitor visitor, DartType typeContext) {
    return visitor.visitShadowLargeIntLiteral(this, typeContext);
  }
}

/// Concrete shadow object representing an invalid initializer in kernel form.
class ShadowInvalidInitializer extends LocalInitializer
    implements InitializerJudgment {
  ShadowInvalidInitializer(VariableDeclaration variable) : super(variable);

  @override
  void acceptInference(InferenceVisitor visitor) {
    return visitor.visitShadowInvalidInitializer(this);
  }
}

/// Concrete shadow object representing an invalid initializer in kernel form.
class ShadowInvalidFieldInitializer extends LocalInitializer
    implements InitializerJudgment {
  final Field field;
  final Expression value;

  ShadowInvalidFieldInitializer(
      this.field, this.value, VariableDeclaration variable)
      : super(variable) {
    value?.parent = this;
  }

  @override
  void acceptInference(InferenceVisitor visitor) {
    return visitor.visitShadowInvalidFieldInitializer(this);
  }
}

/// Front end specific implementation of [MethodInvocation].
class MethodInvocationImpl extends MethodInvocation {
  /// Indicates whether this method invocation is a call to a `call` method
  /// resulting from the invocation of a function expression.
  final bool isImplicitCall;

  MethodInvocationImpl(Expression receiver, Name name, ArgumentsImpl arguments,
      {this.isImplicitCall: false, Member interfaceTarget})
      : super(receiver, name, arguments, interfaceTarget);
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
class NamedFunctionExpressionJudgment extends Let
    implements ExpressionJudgment {
  NamedFunctionExpressionJudgment(VariableDeclarationImpl variable)
      : super(variable, new VariableGet(variable));

  @override
  ExpressionInferenceResult acceptInference(
      InferenceVisitor visitor, DartType typeContext) {
    return visitor.visitNamedFunctionExpressionJudgment(this, typeContext);
  }
}

/// Internal expression representing a null-aware method invocation.
///
/// A null-aware method invocation of the form `a?.b(...)` is encoded as:
///
///     let v = a in v == null ? null : v.b(...)
///
class NullAwareMethodInvocation extends InternalExpression {
  /// The synthetic variable whose initializer hold the receiver.
  VariableDeclaration variable;

  /// The expression that invokes the method on [variable].
  Expression invocation;

  NullAwareMethodInvocation(this.variable, this.invocation) {
    variable.parent = this;
    invocation.parent = this;
  }

  @override
  InternalExpressionKind get kind =>
      InternalExpressionKind.NullAwareMethodInvocation;

  @override
  void visitChildren(Visitor<dynamic> v) {
    variable?.accept(v);
    invocation?.accept(v);
  }

  @override
  transformChildren(Transformer v) {
    if (variable != null) {
      variable = variable.accept<TreeNode>(v);
      variable?.parent = this;
    }
    if (invocation != null) {
      invocation = invocation.accept<TreeNode>(v);
      invocation?.parent = this;
    }
  }
}

/// Internal expression representing a null-aware read from a property.
///
/// A null-aware property get of the form `a?.b` is encoded as:
///
///     let v = a in v == null ? null : v.b
///
class NullAwarePropertyGet extends InternalExpression {
  /// The synthetic variable whose initializer hold the receiver.
  VariableDeclaration variable;

  /// The expression that reads the property from [variable].
  Expression read;

  NullAwarePropertyGet(this.variable, this.read) {
    variable.parent = this;
    read.parent = this;
  }

  @override
  InternalExpressionKind get kind =>
      InternalExpressionKind.NullAwarePropertyGet;

  @override
  void visitChildren(Visitor<dynamic> v) {
    variable?.accept(v);
    read?.accept(v);
  }

  @override
  transformChildren(Transformer v) {
    if (variable != null) {
      variable = variable.accept<TreeNode>(v);
      variable?.parent = this;
    }
    if (read != null) {
      read = read.accept<TreeNode>(v);
      read?.parent = this;
    }
  }
}

/// Internal expression representing a null-aware read from a property.
///
/// A null-aware property get of the form `a?.b = c` is encoded as:
///
///     let v = a in v == null ? null : v.b = c
///
class NullAwarePropertySet extends InternalExpression {
  /// The synthetic variable whose initializer hold the receiver.
  VariableDeclaration variable;

  /// The expression that writes the value to the property in [variable].
  Expression write;

  NullAwarePropertySet(this.variable, this.write) {
    variable.parent = this;
    write.parent = this;
  }

  @override
  InternalExpressionKind get kind =>
      InternalExpressionKind.NullAwarePropertySet;

  @override
  void visitChildren(Visitor<dynamic> v) {
    variable?.accept(v);
    write?.accept(v);
  }

  @override
  transformChildren(Transformer v) {
    if (variable != null) {
      variable = variable.accept<TreeNode>(v);
      variable?.parent = this;
    }
    if (write != null) {
      write = write.accept<TreeNode>(v);
      write?.parent = this;
    }
  }
}

/// Concrete shadow object representing an assignment to a property.
class PropertyAssignmentJudgment extends ComplexAssignmentJudgmentWithReceiver {
  /// If this assignment uses null-aware access (`?.`), the conditional
  /// expression that guards the access; otherwise `null`.
  ConditionalExpression nullAwareGuard;

  PropertyAssignmentJudgment._(Expression receiver, Expression rhs,
      {bool isSuper: false})
      : super._(receiver, rhs, isSuper);

  @override
  List<String> _getToStringParts() {
    List<String> parts = super._getToStringParts();
    if (nullAwareGuard != null) parts.add('nullAwareGuard=$nullAwareGuard');
    return parts;
  }

  ObjectAccessTarget _handleWriteContravariance(
      ShadowTypeInferrer inferrer, DartType receiverType) {
    return inferrer.findPropertySetMember(receiverType, write);
  }

  @override
  ExpressionInferenceResult acceptInference(
      InferenceVisitor visitor, DartType typeContext) {
    return visitor.visitPropertyAssignmentJudgment(this, typeContext);
  }
}

/// Front end specific implementation of [ReturnStatement].
class ReturnStatementImpl extends ReturnStatement {
  final bool isArrow;

  ReturnStatementImpl(this.isArrow, [Expression expression])
      : super(expression);
}

/// Concrete shadow object representing an assignment to a static variable.
class StaticAssignmentJudgment extends ComplexAssignmentJudgment {
  StaticAssignmentJudgment._(Expression rhs) : super._(rhs);

  @override
  ExpressionInferenceResult acceptInference(
      InferenceVisitor visitor, DartType typeContext) {
    return visitor.visitStaticAssignmentJudgment(this, typeContext);
  }
}

/// Synthetic judgment class representing an attempt to invoke an unresolved
/// constructor, or a constructor that cannot be invoked, or a resolved
/// constructor with wrong number of arguments.
// TODO(ahe): Remove this?
class InvalidConstructorInvocationJudgment extends SyntheticExpressionJudgment {
  final Member constructor;
  final Arguments arguments;

  InvalidConstructorInvocationJudgment._(
      Expression desugared, this.constructor, this.arguments)
      : super._(desugared);

  @override
  ExpressionInferenceResult acceptInference(
      InferenceVisitor visitor, DartType typeContext) {
    return visitor.visitInvalidConstructorInvocationJudgment(this, typeContext);
  }
}

/// Synthetic judgment class representing an attempt to assign to the
/// [expression] which is not assignable.
class InvalidWriteJudgment extends SyntheticExpressionJudgment {
  final Expression expression;

  InvalidWriteJudgment._(Expression desugared, this.expression)
      : super._(desugared);

  @override
  ExpressionInferenceResult acceptInference(
      InferenceVisitor visitor, DartType typeContext) {
    return visitor.visitInvalidWriteJudgment(this, typeContext);
  }
}

/// Shadow object for expressions that are introduced by the front end as part
/// of desugaring or the handling of error conditions.
///
/// These expressions are removed by type inference and replaced with their
/// desugared equivalents.
class SyntheticExpressionJudgment extends Let implements ExpressionJudgment {
  SyntheticExpressionJudgment._(Expression desugared)
      : super(new VariableDeclaration('_', initializer: new NullLiteral()),
            desugared);

  /// The desugared kernel representation of this synthetic expression.
  Expression get desugared => body;

  void set desugared(Expression value) {
    this.body = value;
    value.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
      InferenceVisitor visitor, DartType typeContext) {
    return visitor.visitSyntheticExpressionJudgment(this, typeContext);
  }

  /// Removes this expression from the expression tree, replacing it with
  /// [desugared].
  Expression _replaceWithDesugared() {
    Expression replacement = desugared;
    if (replacement is InternalExpression) {
      // This is needed because some (StaticAssignmentJudgment at least) do
      // not visit their desugared expression during inference.
      InternalExpression internalExpression = replacement;
      replacement = internalExpression.replace();
    }
    parent.replaceChild(this, replacement);
    parent = null;
    return replacement;
  }

  /// Updates any [Let] nodes in the desugared expression to account for the
  /// fact that [expression] has the given [type].
  void _storeLetType(
      TypeInferrerImpl inferrer, Expression expression, DartType type) {
    Expression desugared = this.desugared;
    while (true) {
      if (desugared is Let) {
        Let desugaredLet = desugared;
        VariableDeclaration variable = desugaredLet.variable;
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

  @override
  R accept<R>(ExpressionVisitor<R> v) {
    // This is designed to throw an exception during serialization. It can also
    // lead to exceptions during transformations, but we have to accept a
    // [Transformer] as this is used to implement `replaceChild`.
    if (v is Transformer) return super.accept(v);
    throw unsupported("${runtimeType}.accept", fileOffset, getFileUri(this));
  }

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) {
    throw unsupported("${runtimeType}.accept1", fileOffset, getFileUri(this));
  }

  @override
  visitChildren(Visitor<dynamic> v) {
    unsupported("${runtimeType}.visitChildren", fileOffset, getFileUri(this));
  }
}

/// Concrete implementation of [TypeInferenceEngine] specialized to work with
/// kernel objects.
class ShadowTypeInferenceEngine extends TypeInferenceEngine {
  ShadowTypeInferenceEngine(Instrumentation instrumentation)
      : super(instrumentation);

  @override
  ShadowTypeInferrer createLocalTypeInferrer(
      Uri uri, InterfaceType thisType, SourceLibraryBuilder library) {
    return new TypeInferrer(this, uri, false, thisType, library);
  }

  @override
  ShadowTypeInferrer createTopLevelTypeInferrer(
      Uri uri, InterfaceType thisType, SourceLibraryBuilder library) {
    return new TypeInferrer(this, uri, true, thisType, library);
  }
}

/// Concrete implementation of [TypeInferrer] specialized to work with kernel
/// objects.
class ShadowTypeInferrer extends TypeInferrerImpl {
  @override
  final TypePromoter typePromoter;

  ShadowTypeInferrer.private(ShadowTypeInferenceEngine engine, Uri uri,
      bool topLevel, InterfaceType thisType, SourceLibraryBuilder library)
      : typePromoter = new TypePromoter(engine.typeSchemaEnvironment),
        super.private(engine, uri, topLevel, thisType, library);

  @override
  Expression getFieldInitializer(Field field) {
    return field.initializer;
  }

  @override
  ExpressionInferenceResult inferExpression(
      Expression expression, DartType typeContext, bool typeNeeded,
      {bool isVoidAllowed: false}) {
    // `null` should never be used as the type context.  An instance of
    // `UnknownType` should be used instead.
    assert(typeContext != null);

    // It isn't safe to do type inference on an expression without a parent,
    // because type inference might cause us to have to replace one expression
    // with another, and we can only replace a node if it has a parent pointer.
    assert(expression.parent != null);

    // For full (non-top level) inference, we need access to the
    // ExpressionGeneratorHelper so that we can perform error recovery.
    assert(isTopLevel || helper != null);

    // When doing top level inference, we skip subexpressions whose type isn't
    // needed so that we don't induce bogus dependencies on fields mentioned in
    // those subexpressions.
    if (!typeNeeded) return const ExpressionInferenceResult(null);

    InferenceVisitor visitor = new InferenceVisitor(this);
    ExpressionInferenceResult result;
    if (expression is ExpressionJudgment) {
      result = expression.acceptInference(visitor, typeContext);
    } else {
      result = expression.accept1(visitor, typeContext);
    }
    DartType inferredType = result.inferredType;
    assert(inferredType != null, "No type inferred for $expression.");
    if (inferredType is VoidType && !isVoidAllowed) {
      if (expression.parent is! ArgumentsImpl) {
        helper?.addProblem(
            messageVoidExpression, expression.fileOffset, noLength);
      }
    }
    return result;
  }

  @override
  void inferInitializer(InferenceHelper helper, Initializer initializer) {
    this.helper = helper;
    // Use polymorphic dispatch on [KernelInitializer] to perform whatever
    // kind of type inference is correct for this kind of initializer.
    // TODO(paulberry): experiment to see if dynamic dispatch would be better,
    // so that the type hierarchy will be simpler (which may speed up "is"
    // checks).
    if (initializer is InitializerJudgment) {
      initializer.acceptInference(new InferenceVisitor(this));
    } else {
      initializer.accept(new InferenceVisitor(this));
    }
    this.helper = null;
  }

  @override
  void inferStatement(Statement statement) {
    // For full (non-top level) inference, we need access to the
    // ExpressionGeneratorHelper so that we can perform error recovery.
    if (!isTopLevel) assert(helper != null);
    if (statement != null) {
      statement.accept(new InferenceVisitor(this));
    }
  }
}

/// Concrete implementation of [TypePromoter] specialized to work with kernel
/// objects.
class ShadowTypePromoter extends TypePromoterImpl {
  ShadowTypePromoter.private(TypeSchemaEnvironment typeSchemaEnvironment)
      : super.private(typeSchemaEnvironment);

  @override
  int getVariableFunctionNestingLevel(VariableDeclaration variable) {
    if (variable is VariableDeclarationImpl) {
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
    assert(variable is VariableDeclarationImpl);
    VariableDeclarationImpl kernelVariableDeclaration = variable;
    return !kernelVariableDeclaration._isLocalFunction;
  }

  @override
  bool sameExpressions(Expression a, Expression b) {
    return identical(a, b);
  }

  @override
  void setVariableMutatedAnywhere(VariableDeclaration variable) {
    if (variable is VariableDeclarationImpl) {
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
    if (variable is VariableDeclarationImpl) {
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
    if (variable is VariableDeclarationImpl) {
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

class VariableAssignmentJudgment extends ComplexAssignmentJudgment {
  VariableAssignmentJudgment._(Expression rhs) : super._(rhs);

  @override
  ExpressionInferenceResult acceptInference(
      InferenceVisitor visitor, DartType typeContext) {
    return visitor.visitVariableAssignmentJudgment(this, typeContext);
  }
}

/// Front end specific implementation of [VariableDeclaration].
class VariableDeclarationImpl extends VariableDeclaration {
  final bool forSyntheticToken;

  final bool _implicitlyTyped;

  // TODO(ahe): Remove this field. We can get rid of it by recording closure
  // mutation in [BodyBuilder].
  final int _functionNestingLevel;

  // TODO(ahe): Remove this field. It's only used locally when compiling a
  // method, and this can thus be tracked in a [Set] (actually, tracking this
  // information in a [List] is probably even faster as the average size will
  // be close to zero).
  bool _mutatedInClosure = false;

  // TODO(ahe): Investigate if this can be removed.
  bool _mutatedAnywhere = false;

  // TODO(ahe): Investigate if this can be removed.
  final bool _isLocalFunction;

  VariableDeclarationImpl(String name, this._functionNestingLevel,
      {this.forSyntheticToken: false,
      Expression initializer,
      DartType type,
      bool isFinal: false,
      bool isConst: false,
      bool isFieldFormal: false,
      bool isCovariant: false,
      bool isLocalFunction: false,
      bool isLate: false,
      bool isRequired: false})
      : _implicitlyTyped = type == null,
        _isLocalFunction = isLocalFunction,
        super(name,
            initializer: initializer,
            type: type ?? const DynamicType(),
            isFinal: isFinal,
            isConst: isConst,
            isFieldFormal: isFieldFormal,
            isCovariant: isCovariant,
            isLate: isLate,
            isRequired: isRequired);

  VariableDeclarationImpl.forEffect(Expression initializer)
      : forSyntheticToken = false,
        _functionNestingLevel = 0,
        _implicitlyTyped = false,
        _isLocalFunction = false,
        super.forValue(initializer);

  VariableDeclarationImpl.forValue(Expression initializer)
      : forSyntheticToken = false,
        _functionNestingLevel = 0,
        _implicitlyTyped = true,
        _isLocalFunction = false,
        super.forValue(initializer);

  /// Determine whether the given [VariableDeclarationImpl] had an implicit
  /// type.
  ///
  /// This is static to avoid introducing a method that would be visible to
  /// the kernel.
  static bool isImplicitlyTyped(VariableDeclarationImpl variable) =>
      variable._implicitlyTyped;

  /// Determines whether the given [VariableDeclarationImpl] represents a
  /// local function.
  ///
  /// This is static to avoid introducing a method that would be visible to the
  /// kernel.
  static bool isLocalFunction(VariableDeclarationImpl variable) =>
      variable._isLocalFunction;
}

/// Synthetic judgment class representing an attempt to invoke an unresolved
/// target.
class UnresolvedTargetInvocationJudgment extends SyntheticExpressionJudgment {
  final ArgumentsImpl argumentsJudgment;

  UnresolvedTargetInvocationJudgment._(
      Expression desugared, this.argumentsJudgment)
      : super._(desugared);

  @override
  ExpressionInferenceResult acceptInference(
      InferenceVisitor visitor, DartType typeContext) {
    return visitor.visitUnresolvedTargetInvocationJudgment(this, typeContext);
  }
}

/// Synthetic judgment class representing an attempt to assign to an unresolved
/// variable.
class UnresolvedVariableAssignmentJudgment extends SyntheticExpressionJudgment {
  final bool isCompound;
  final Expression rhs;

  UnresolvedVariableAssignmentJudgment._(
      Expression desugared, this.isCompound, this.rhs)
      : super._(desugared);

  @override
  ExpressionInferenceResult acceptInference(
      InferenceVisitor visitor, DartType typeContext) {
    return visitor.visitUnresolvedVariableAssignmentJudgment(this, typeContext);
  }
}

/// Front end specific implementation of [VariableGet].
class VariableGetImpl extends VariableGet {
  final TypePromotionFact _fact;

  final TypePromotionScope _scope;

  VariableGetImpl(VariableDeclaration variable, this._fact, this._scope)
      : super(variable);
}

/// Front end specific implementation of [LoadLibrary].
class LoadLibraryImpl extends LoadLibrary {
  final Arguments arguments;

  LoadLibraryImpl(LibraryDependency import, this.arguments) : super(import);
}

/// Internal expression representing a tear-off of a `loadLibrary` function.
class LoadLibraryTearOff extends InternalExpression {
  LibraryDependency import;
  Procedure target;

  LoadLibraryTearOff(this.import, this.target);

  @override
  InternalExpressionKind get kind => InternalExpressionKind.LoadLibraryTearOff;

  @override
  Expression replace() {
    Expression replacement;
    parent.replaceChild(
        this, replacement = new StaticGet(target)..fileOffset = fileOffset);
    return replacement;
  }

  @override
  void visitChildren(Visitor<dynamic> v) {
    import?.accept(v);
    target?.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    if (import != null) {
      import = import.accept<TreeNode>(v);
      import?.parent = this;
    }
    if (target != null) {
      target = target.accept<TreeNode>(v);
      target?.parent = this;
    }
  }
}

/// The result of inference for a RHS of an assignment.
class _ComplexAssignmentInferenceResult {
  /// The resolved combiner [Procedure], e.g. `operator+` for `a += 2`, or
  /// `null` if the assignment is not compound.
  final Procedure combiner;

  /// The inferred type of the RHS.
  final DartType inferredType;

  _ComplexAssignmentInferenceResult(this.combiner, this.inferredType);
}

class _UnfinishedCascade extends Expression {
  R accept<R>(v) => unsupported("accept", -1, null);

  R accept1<R, A>(v, arg) => unsupported("accept1", -1, null);

  DartType getStaticType(types) => unsupported("getStaticType", -1, null);

  void transformChildren(v) => unsupported("transformChildren", -1, null);

  void visitChildren(v) => unsupported("visitChildren", -1, null);
}

class SyntheticWrapper {
  static Expression wrapIllegalAssignment(Expression rhs,
      {int assignmentOffset: -1}) {
    return new IllegalAssignmentJudgment._(rhs,
        assignmentOffset: assignmentOffset)
      ..fileOffset = rhs.fileOffset;
  }

  static Expression wrapIndexAssignment(
      Expression receiver, Expression index, Expression rhs,
      {bool isSuper: false}) {
    return new IndexAssignmentJudgment._(receiver, index, rhs, isSuper: isSuper)
      ..fileOffset = index.fileOffset;
  }

  static Expression wrapInvalidConstructorInvocation(
      Expression desugared, Member constructor, Arguments arguments) {
    return new InvalidConstructorInvocationJudgment._(
        desugared, constructor, arguments)
      ..fileOffset = desugared.fileOffset;
  }

  static Expression wrapInvalidWrite(
      Expression desugared, Expression expression) {
    return new InvalidWriteJudgment._(desugared, expression)
      ..fileOffset = desugared.fileOffset;
  }

  static Expression wrapPropertyAssignment(Expression receiver, Expression rhs,
      {bool isSuper: false}) {
    return new PropertyAssignmentJudgment._(receiver, rhs, isSuper: isSuper)
      ..fileOffset = rhs.fileOffset;
  }

  static Expression wrapStaticAssignment(Expression rhs) {
    return new StaticAssignmentJudgment._(rhs)..fileOffset = rhs.fileOffset;
  }

  static Expression wrapSyntheticExpression(Expression desugared) {
    return new SyntheticExpressionJudgment._(desugared)
      ..fileOffset = desugared.fileOffset;
  }

  static Expression wrapUnresolvedTargetInvocation(
      Expression desugared, Arguments arguments) {
    return new UnresolvedTargetInvocationJudgment._(desugared, arguments)
      ..fileOffset = desugared.fileOffset;
  }

  static Expression wrapUnresolvedVariableAssignment(
      Expression desugared, bool isCompound, Expression rhs) {
    return new UnresolvedVariableAssignmentJudgment._(
        desugared, isCompound, rhs)
      ..fileOffset = desugared.fileOffset;
  }

  static Expression wrapVariableAssignment(Expression rhs) {
    return new VariableAssignmentJudgment._(rhs)..fileOffset = rhs.fileOffset;
  }
}

/// Internal expression representing an if-null assignment.
///
/// An if-null assignment of the form `o.a ??= b` is, if used for value,
/// encoded as the expression:
///
///     let v1 = o in let v2 = v1.a in v2 == null ? v1.a = b : v2
///
/// and, if used for effect, encoded as the expression:
///
///     let v1 = o in v1.a == null ? v1.a = b : null
///
class IfNullPropertySet extends InternalExpression {
  /// The synthetic variable whose initializer hold the receiver.
  VariableDeclaration variable;

  /// The expression that reads the property from [variable].
  Expression read;

  /// The expression that writes the value to the property on [variable].
  Expression write;

  /// If `true`, the expression is only need for effect and not for its value.
  final bool forEffect;

  IfNullPropertySet(this.variable, this.read, this.write, {this.forEffect})
      : assert(forEffect != null) {
    variable.parent = this;
    read.parent = this;
    write.parent = this;
  }

  @override
  InternalExpressionKind get kind => InternalExpressionKind.IfNullPropertySet;

  @override
  void visitChildren(Visitor<dynamic> v) {
    variable?.accept(v);
    read?.accept(v);
    write?.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    if (variable != null) {
      variable = variable.accept<TreeNode>(v);
    }
    if (read != null) {
      read = read.accept<TreeNode>(v);
    }
    if (write != null) {
      write = write.accept<TreeNode>(v);
    }
  }
}

/// Internal expression representing an compound property assignment.
///
/// An compound property assignment of the form `o.a += b` is encoded as the
/// expression:
///
///     let v1 = o in v1.a = v1.a + b
///
class CompoundPropertyAssignment extends InternalExpression {
  /// The synthetic variable whose initializer hold the receiver.
  VariableDeclaration variable;

  /// The expression that writes the result of the binary operation to the
  /// property on [variable].
  Expression write;

  CompoundPropertyAssignment(this.variable, this.write) {
    variable.parent = this;
    write.parent = this;
  }

  @override
  InternalExpressionKind get kind =>
      InternalExpressionKind.CompoundPropertyAssignment;

  @override
  Expression replace() {
    Expression replacement;
    replaceWith(
        replacement = new Let(variable, write)..fileOffset = fileOffset);
    return replacement;
  }

  @override
  void visitChildren(Visitor<dynamic> v) {
    variable?.accept(v);
    write?.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    if (variable != null) {
      variable = variable.accept<TreeNode>(v);
    }
    if (write != null) {
      write = write.accept<TreeNode>(v);
    }
  }
}

/// Internal expression representing an compound property assignment.
///
/// An compound property assignment of the form `o.a++` is encoded as the
/// expression:
///
///     let v1 = o in let v2 = v1.a in let v3 = v1.a = v2 + 1 in v2
///
class PropertyPostIncDec extends InternalExpression {
  /// The synthetic variable whose initializer hold the receiver.
  VariableDeclaration variable;

  /// The expression that reads the property on [variable].
  VariableDeclaration read;

  /// The expression that writes the result of the binary operation to the
  /// property on [variable].
  VariableDeclaration write;

  PropertyPostIncDec(this.variable, this.read, this.write) {
    variable.parent = this;
    read.parent = this;
    write.parent = this;
  }

  @override
  InternalExpressionKind get kind => InternalExpressionKind.PropertyPostIncDec;

  @override
  Expression replace() {
    Expression replacement;
    replaceWith(replacement = new Let(
        variable,
        new Let(
            read,
            new Let(write, new VariableGet(read)..fileOffset = fileOffset)
              ..fileOffset = fileOffset)
          ..fileOffset = fileOffset)
      ..fileOffset = fileOffset);
    return replacement;
  }

  @override
  void visitChildren(Visitor<dynamic> v) {
    variable?.accept(v);
    read?.accept(v);
    write?.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    if (variable != null) {
      variable = variable.accept<TreeNode>(v);
    }
    if (write != null) {
      write = write.accept<TreeNode>(v);
    }
  }
}

/// Internal expression representing an local variable post inc/dec expression.
///
/// An local variable post inc/dec expression of the form `a++` is encoded as
/// the expression:
///
///     let v1 = a in let v2 = a = a + 1 in v1
///
class LocalPostIncDec extends InternalExpression {
  /// The expression that reads the local variable.
  VariableDeclaration read;

  /// The expression that writes the result of the binary operation to the
  /// property on [variable].
  VariableDeclaration write;

  LocalPostIncDec(this.read, this.write) {
    read.parent = this;
    write.parent = this;
  }

  @override
  InternalExpressionKind get kind => InternalExpressionKind.LocalPostIncDec;

  @override
  Expression replace() {
    Expression replacement;
    replaceWith(replacement = new Let(
        read,
        new Let(write, new VariableGet(read)..fileOffset = fileOffset)
          ..fileOffset = fileOffset)
      ..fileOffset = fileOffset);
    return replacement;
  }

  @override
  void visitChildren(Visitor<dynamic> v) {
    read?.accept(v);
    write?.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    if (read != null) {
      read = read.accept<TreeNode>(v);
    }
    if (write != null) {
      write = write.accept<TreeNode>(v);
    }
  }
}

/// Internal expression representing an index set expression.
///
/// An index set expression of the form `o[a] = b` used for value is encoded as
/// the expression:
///
///     let v1 = o in let v2 = a in let v3 = b in let _ = o.[]=(v2, v3) in v3
///
/// An index set expression used for effect is encoded as
///
///    o.[]=(a, b)
///
/// using [MethodInvocationImpl].
///
class IndexSet extends InternalExpression {
  /// The receiver on which the index set operation is performed.
  Expression receiver;

  /// The index expression of the operation.
  Expression index;

  /// The value expression of the operation.
  Expression value;

  IndexSet(this.receiver, this.index, this.value) {
    receiver?.parent = this;
    index?.parent = this;
    value?.parent = this;
  }

  @override
  InternalExpressionKind get kind => InternalExpressionKind.IndexSet;

  @override
  void visitChildren(Visitor<dynamic> v) {
    receiver?.accept(v);
    index?.accept(v);
    value?.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    if (receiver != null) {
      receiver = receiver.accept<TreeNode>(v);
    }
    if (index != null) {
      index = index.accept<TreeNode>(v);
    }
    if (value != null) {
      value = value.accept<TreeNode>(v);
    }
  }
}

MethodInvocation createEqualsNull(
    int fileOffset, Expression left, Member equalsMember) {
  return new MethodInvocation(left, new Name('=='),
      new Arguments(<Expression>[new NullLiteral()..fileOffset = fileOffset]))
    ..fileOffset = fileOffset
    ..interfaceTarget = equalsMember;
}
