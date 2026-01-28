// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A library to help generate expression.
library;

import 'package:_fe_analyzer_shared/src/parser/parser.dart'
    show lengthForToken, lengthOfSpan;
import 'package:_fe_analyzer_shared/src/scanner/token.dart' show Token;
import 'package:front_end/src/codes/diagnostic.dart' as diag;
import 'package:front_end/src/type_inference/external_ast_helper.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/names.dart'
    show
        ampersandName,
        barName,
        callName,
        caretName,
        divisionName,
        equalsName,
        indexGetName,
        indexSetName,
        leftShiftName,
        lengthName,
        minusName,
        multiplyName,
        mustacheName,
        percentName,
        plusName,
        rightShiftName,
        tripleShiftName;
import 'package:kernel/src/unaliasing.dart';
import 'package:kernel/type_algebra.dart';

import '../base/compiler_context.dart';
import '../base/constant_context.dart' show ConstantContext;
import '../base/lookup_result.dart';
import '../base/messages.dart';
import '../base/problems.dart';
import '../builder/builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/factory_builder.dart';
import '../builder/member_builder.dart';
import '../builder/method_builder.dart';
import '../builder/named_type_builder.dart';
import '../builder/nullability_builder.dart';
import '../builder/prefix_builder.dart';
import '../builder/property_builder.dart';
import '../builder/type_builder.dart';
import '../source/check_helper.dart';
import '../source/source_member_builder.dart';
import '../source/stack_listener_impl.dart' show offsetForToken;
import 'constness.dart' show Constness;
import 'expression_generator_helper.dart';
import 'forest.dart';
import 'internal_ast.dart';
import 'load_library_builder.dart';
import 'utils.dart';

/// A generator represents a subexpression for which we can't yet build an
/// expression because we don't yet know the context in which it's used.
///
/// Once the context is known, a generator can be converted into an expression
/// by calling a `build` method.
///
/// For example, when building a kernel representation for `a[x] = b`, after
/// parsing `a[x]` but before parsing `= b`, we don't yet know whether to
/// generate an invocation of `operator[]` or `operator[]=`, so we create a
/// [Generator] object.  Later, after `= b` is parsed, [buildAssignment] will
/// be called.
abstract class Generator {
  /// Helper that provides access to contextual information.
  final ExpressionGeneratorHelper _helper;

  /// A token that defines a position subexpression that being built.
  final Token token;

  final int fileOffset;

  Generator(this._helper, this.token) : fileOffset = offsetForToken(token);

  /// Easy access to the [Forest] factory object.
  Forest get _forest => _helper.forest;

  // TODO(johnniwinther): Improve the semantic precision of this property or
  // remove it. It's unclear if the semantics is inconsistent. It's for instance
  // used both for the name of a variable in [VariableUseGenerator] and for
  // `[]` in [IndexedAccessGenerator], and while the former text occurs in the
  // underlying source code, the latter doesn't.
  String get _plainNameForRead;

  /// Internal name used for debugging.
  String get _debugName;

  /// The source uri for use in error messaging.
  Uri get _fileUri => _helper.uri;

  ProblemReporting get problemReporting => _helper.problemReporting;

  CompilerContext get compilerContext => _helper.compilerContext;

  /// Builds an [Expression] representing a read from the generator.
  ///
  /// The read of this subexpression does _not_ need to support a simultaneous
  /// write of the same subexpression.
  Expression buildSimpleRead();

  /// Builds an [Expression] representing an assignment with the generator on
  /// the LHS and [value] on the RHS.
  ///
  /// The returned expression evaluates to the assigned value, unless
  /// [voidContext] is true, in which case it may evaluate to anything.
  Expression buildAssignment(Expression value, {bool voidContext = false});

  /// Returns an [Expression] representing a null-aware assignment (`??=`) with
  /// the generator on the LHS and [value] on the RHS.
  ///
  /// The returned expression evaluates to the assigned value, unless
  /// [voidContext] is true, in which case it may evaluate to anything.
  ///
  /// [type] is the static type of the RHS.
  Expression buildIfNullAssignment(
    Expression value,
    DartType type,
    int offset, {
    bool voidContext = false,
  });

  /// Returns an [Expression] representing a compound assignment (e.g. `+=`)
  /// with the generator on the LHS and [value] on the RHS.
  Expression buildCompoundAssignment(
    Name binaryOperator,
    Expression value, {
    required int operatorOffset,
    bool voidContext = false,
    bool isPreIncDec = false,
    bool isPostIncDec = false,
  });

  /// Returns an [Expression] representing a pre-increment or pre-decrement of
  /// the generator.
  Expression buildPrefixIncrement(
    Name binaryOperator, {
    required int operatorOffset,
    bool voidContext = false,
  }) {
    return buildCompoundAssignment(
      binaryOperator,
      _forest.createIntLiteral(operatorOffset, 1),
      operatorOffset: operatorOffset,
      // TODO(johnniwinther): We are missing some void contexts here. For
      // instance `++a?.b;` is not providing a void context making it default
      // `true`.
      voidContext: voidContext,
      isPreIncDec: true,
    );
  }

  /// Returns an [Expression] representing a post-increment or post-decrement of
  /// the generator.
  Expression buildPostfixIncrement(
    Name binaryOperator, {
    required int operatorOffset,
    bool voidContext = false,
  });

  /// Returns a [Generator] or [Expression] representing an index access
  /// (e.g. `a[b]`) with the generator on the receiver and [index] as the
  /// index expression.
  Generator buildIndexedAccess(
    Expression index,
    Token token, {
    required bool isNullAware,
  });

  /// Returns an [Expression] representing a compile-time error.
  ///
  /// At runtime, an exception will be thrown.
  Expression _makeInvalidRead({
    required UnresolvedKind unresolvedKind,
    bool errorHasBeenReported = false,
  }) {
    return _helper.buildUnresolvedError(
      _plainNameForRead,
      fileOffset,
      kind: unresolvedKind,
      errorHasBeenReported: errorHasBeenReported,
    );
  }

  /// Returns an [Expression] representing a compile-time error wrapping
  /// [value].
  ///
  /// At runtime, [value] will be evaluated before throwing an exception.
  Expression _makeInvalidWrite({bool errorHasBeenReported = false}) {
    return _helper.buildUnresolvedError(
      _plainNameForRead,
      fileOffset,
      kind: UnresolvedKind.Setter,
      errorHasBeenReported: errorHasBeenReported,
    );
  }

  Expression buildForEffect() => buildSimpleRead();

  List<Initializer> buildFieldInitializer(Map<String, int>? initializedFields) {
    return <Initializer>[
      createInvalidInitializer(
        _helper.buildProblem(
          message: diag.invalidInitializer,
          fileUri: _helper.uri,
          fileOffset: fileOffset,
          length: lengthForToken(token),
        ),
      ),
    ];
  }

  /// Returns an expression, generator or initializer for an invocation of this
  /// subexpression with [typeArguments] and [arguments] at [offset]. Callers
  /// must pass `isInForest: true` iff [typeArguments] have already been added
  /// to [forest].
  ///
  /// For instance:
  /// * If this is a [PropertyAccessGenerator] for `a.b`, this will create
  ///   a [MethodInvocation] for `a.b(...)`.
  /// * If this is a [ThisAccessGenerator] for `this` in an initializer list,
  ///   this will create a [RedirectingInitializer] for `this(...)`.
  /// * If this is an [IncompleteErrorGenerator], this will return the error
  ///   generator itself.
  ///
  /// If the invocation has explicit type arguments
  /// [buildTypeWithResolvedArguments] called instead.
  Expression_Generator_Initializer doInvocation({
    required int offset,
    required List<TypeBuilder>? typeArgumentBuilders,
    required TypeArguments? typeArguments,
    required ActualArguments arguments,
    bool isTypeArgumentsInForest = false,
  });

  Expression_Generator_Initializer buildSelectorAccess(
    Selector selector,
    int operatorOffset,
    bool isNullAware,
  ) {
    selector.reportNewAsSelector();
    if (selector is InvocationSelector) {
      return _helper.buildMethodInvocation(
        buildSimpleRead(),
        selector.name,
        selector.typeArguments,
        selector.arguments,
        offsetForToken(selector.token),
        isNullAware: isNullAware,
        isConstantExpression: selector.isPotentiallyConstant,
      );
    } else {
      if (_helper.constantContext != ConstantContext.none &&
          selector.name != lengthName) {
        problemReporting.addProblem(
          diag.notAConstantExpression,
          fileOffset,
          token.length,
          _fileUri,
        );
      }
      return PropertyAccessGenerator.make(
        _helper,
        selector.token,
        buildSimpleRead(),
        selector.name,
        isNullAware,
      );
    }
  }

  Expression_Generator buildEqualsOperation(
    Token token,
    Expression right, {
    required bool isNot,
  }) {
    return _forest.createEquals(
      offsetForToken(token),
      buildSimpleRead(),
      right,
      isNot: isNot,
    );
  }

  Expression_Generator buildBinaryOperation(
    Token token,
    Name binaryName,
    Expression right,
  ) {
    return _forest.createBinary(
      offsetForToken(token),
      buildSimpleRead(),
      binaryName,
      right,
    );
  }

  Expression_Generator buildUnaryOperation(Token token, Name unaryName) {
    return _forest.createUnary(
      offsetForToken(token),
      unaryName,
      buildSimpleRead(),
    );
  }

  Expression_Generator applyTypeArguments(
    int fileOffset,
    List<TypeBuilder>? typeArguments,
  ) {
    return new Instantiation(
      buildSimpleRead(),
      _helper.buildDartTypeArguments(
        typeArguments,
        TypeUse.tearOffTypeArgument,
        allowPotentiallyConstantType: true,
      ),
    )..fileOffset = fileOffset;
  }

  /// Returns a [TypeBuilder] for this subexpression instantiated with the
  /// type [arguments]. If no type arguments are provided [arguments] is `null`.
  ///
  /// The type arguments have not been resolved and should be resolved to
  /// create a [TypeBuilder] for a valid type.
  TypeBuilder buildTypeWithResolvedArguments(
    NullabilityBuilder nullabilityBuilder,
    List<TypeBuilder>? arguments, {
    required bool allowPotentiallyConstantType,
    required bool performTypeCanonicalization,
  }) {
    Message message = diag.notAType.withArgumentsOld(token.lexeme);
    _helper.libraryBuilder.addProblem(
      message,
      fileOffset,
      lengthForToken(token),
      _fileUri,
    );
    return new NamedTypeBuilderImpl.forInvalidType(
      token.lexeme,
      nullabilityBuilder,
      message.withLocation(_fileUri, fileOffset, lengthForToken(token)),
    );
  }

  Expression_Generator qualifiedLookup(Token name) {
    return new UnexpectedQualifiedUseGenerator(
      _helper,
      name,
      this,
      errorHasBeenReported: false,
    );
  }

  Expression invokeConstructor({
    required String name,
    required List<TypeBuilder>? typeArgumentBuilders,
    required TypeArguments? typeArguments,
    required ActualArguments arguments,
    required Token nameToken,
    required Token nameLastToken,
    required Constness constness,
    required bool inImplicitCreationContext,
  }) {
    return _helper.createInstantiationAndInvocation(
      () => buildSimpleRead(),
      typeArgumentBuilders,
      _plainNameForRead,
      name,
      arguments,
      instantiationOffset: fileOffset,
      invocationOffset: nameLastToken.charOffset,
      inImplicitCreationContext: inImplicitCreationContext,
    );
  }

  void printOn(StringSink sink);

  @override
  String toString() {
    StringBuffer buffer = new StringBuffer();
    buffer.write(_debugName);
    buffer.write("(offset: ");
    buffer.write("${fileOffset}");
    printOn(buffer);
    buffer.write(")");
    return "$buffer";
  }
}

/// [VariableUseGenerator] represents the subexpression whose prefix is a
/// local variable or parameter name.
///
/// For instance:
///
///   method(a) {
///     var b;
///     a;         // a VariableUseGenerator is created for `a`.
///     b = a[];   // a VariableUseGenerator is created for `a` and `b`.
///     b();       // a VariableUseGenerator is created for `b`.
///     b.c = a.d; // a VariableUseGenerator is created for `a` and `b`.
///   }
///
/// If the variable is final or read-only (like a parameter in a catch clause) a
/// [ReadOnlyAccessGenerator] is created instead.
class VariableUseGenerator extends Generator {
  final ExpressionVariable variable;

  VariableUseGenerator(
    ExpressionGeneratorHelper helper,
    Token nameToken,
    this.variable,
  ) : assert(variable.isAssignable, 'Variable $variable is not assignable'),
      super(helper, nameToken);

  @override
  // Coverage-ignore(suite): Not run.
  String get _debugName => "VariableUseGenerator";

  @override
  String get _plainNameForRead => variable.cosmeticName!;

  int get _nameOffset => fileOffset;

  @override
  Expression buildSimpleRead() {
    return _createRead();
  }

  Expression _createRead() {
    return _helper.createVariableGet(variable, fileOffset);
  }

  @override
  Expression buildAssignment(Expression value, {bool voidContext = false}) {
    return _createWrite(fileOffset, value);
  }

  void _checkAssignment(int offset) {
    if (_helper.isDeclaredInEnclosingCase(variable)) {
      problemReporting.addProblem(
        diag.patternVariableAssignmentInsideGuard,
        offset,
        noLength,
        _fileUri,
      );
    }
  }

  Expression _createWrite(int offset, Expression value) {
    _checkAssignment(offset);
    _helper.registerVariableAssignment(variable);
    return new VariableSet(variable, value)..fileOffset = offset;
  }

  @override
  Expression buildIfNullAssignment(
    Expression value,
    DartType type,
    int offset, {
    bool voidContext = false,
  }) {
    Expression read = _createRead();
    Expression write = _createWrite(fileOffset, value);
    return new IfNullSet(read, write, forEffect: voidContext)
      ..fileOffset = offset;
  }

  @override
  Expression buildCompoundAssignment(
    Name binaryOperator,
    Expression value, {
    required int operatorOffset,
    bool voidContext = false,
    bool isPreIncDec = false,
    bool isPostIncDec = false,
  }) {
    Expression binary = _helper.forest.createBinary(
      operatorOffset,
      _createRead(),
      binaryOperator,
      value,
    );
    return _createWrite(fileOffset, binary);
  }

  Expression _buildPrePostfixIncrement(
    Name binaryOperator, {
    required int operatorOffset,
    required bool forEffect,
    required bool isPost,
  }) {
    _checkAssignment(_nameOffset);
    _helper.registerVariableRead(variable);
    _helper.registerVariableAssignment(variable);
    return new LocalIncDec(
      variable: variable as InternalExpressionVariable,
      forEffect: forEffect,
      isPost: isPost,
      isInc: binaryOperator == plusName,
      nameOffset: _nameOffset,
      operatorOffset: operatorOffset,
    )..fileOffset = _nameOffset;
  }

  @override
  Expression buildPrefixIncrement(
    Name binaryOperator, {
    required int operatorOffset,
    bool voidContext = false,
  }) {
    return _buildPrePostfixIncrement(
      binaryOperator,
      operatorOffset: operatorOffset,
      forEffect: voidContext,
      isPost: false,
    );
  }

  @override
  Expression buildPostfixIncrement(
    Name binaryOperator, {
    required int operatorOffset,
    bool voidContext = false,
  }) {
    return _buildPrePostfixIncrement(
      binaryOperator,
      operatorOffset: operatorOffset,
      forEffect: voidContext,
      isPost: true,
    );
  }

  @override
  Expression doInvocation({
    required int offset,
    required List<TypeBuilder>? typeArgumentBuilders,
    required TypeArguments? typeArguments,
    required ActualArguments arguments,
    bool isTypeArgumentsInForest = false,
  }) {
    return _helper.forest.createExpressionInvocation(
      adjustForImplicitCall(_plainNameForRead, offset),
      buildSimpleRead(),
      typeArguments,
      arguments,
    );
  }

  @override
  Generator buildIndexedAccess(
    Expression index,
    Token token, {
    required bool isNullAware,
  }) {
    return new IndexedAccessGenerator(
      _helper,
      token,
      buildSimpleRead(),
      index,
      isNullAware: isNullAware,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  void printOn(StringSink sink) {
    sink.write(", variable: ");
    printNodeOn(variable, sink);
  }
}

/// A [VariableUseGenerator] subclass for late final for-in loop variables
///
/// The special case of late final for-in loop variables is determined by the
/// following requirements to the error reporting.
///
///   * Even though the loop can be executed only once, initializing the
///     variable exactly once, it is still reasonable to report the error for
///     assigning to the late variable.
///
///   * The variable should be considered assigned in the statements following
///     the loop.
///
/// To have both of the effect, [ForInLateFinalVariableUseGenerator] is emitted
/// for the assignments of such variables. It extends [VariableUseGenerator],
/// but reports an error on assignment, similarly to
/// [AbstractReadOnlyAccessGenerator].
class ForInLateFinalVariableUseGenerator extends VariableUseGenerator {
  ForInLateFinalVariableUseGenerator(
    ExpressionGeneratorHelper helper,
    Token token,
    ExpressionVariable variable,
  ) : super(helper, token, variable);

  @override
  // Coverage-ignore(suite): Not run.
  String get _debugName => "ForInLateFinalVariableUseGenerator";

  @override
  Expression buildAssignment(Expression value, {bool voidContext = false}) {
    InvalidExpression error = _helper.buildProblem(
      message: diag.cannotAssignToFinalVariable.withArgumentsOld(
        variable.cosmeticName!,
      ),
      fileUri: _helper.uri,
      fileOffset: fileOffset,
      length: lengthForToken(token),
    )..parent = variable;
    Expression assignment = super.buildAssignment(
      value,
      voidContext: voidContext,
    );
    if (assignment is VariableSet) {
      assignment.value = error..parent = assignment;
    }
    return assignment;
  }
}

/// A [PropertyAccessGenerator] represents a subexpression whose prefix is
/// an explicit property access.
///
/// For instance
///
///   method(a) {
///     a.b;      // a PropertyAccessGenerator is created for `a.b`.
///     a.b();    // a PropertyAccessGenerator is created for `a.b`.
///     a.b = c;  // a PropertyAccessGenerator is created for `a.b`.
///     a.b += c; // a PropertyAccessGenerator is created for `a.b`.
///   }
///
/// If the receiver is `this`, a [ThisPropertyAccessGenerator] is created
/// instead. If the access is null-aware, e.g. `a?.b`, a
/// [NullAwarePropertyAccessGenerator] is created instead.
class PropertyAccessGenerator extends Generator {
  /// The receiver expression. `a` in the examples in the class documentation.
  final Expression receiver;

  /// The name for the accessed property. `b` in the examples in the class
  /// documentation.
  final Name name;

  PropertyAccessGenerator(
    ExpressionGeneratorHelper helper,
    Token nameToken,
    this.receiver,
    this.name,
  ) : super(helper, nameToken);

  @override
  // Coverage-ignore(suite): Not run.
  String get _debugName => "PropertyAccessGenerator";

  @override
  String get _plainNameForRead => name.text;

  /// The file offset for the [name].
  int get _nameOffset => fileOffset;

  @override
  // Coverage-ignore(suite): Not run.
  Expression doInvocation({
    required int offset,
    required List<TypeBuilder>? typeArgumentBuilders,
    required TypeArguments? typeArguments,
    required ActualArguments arguments,
    bool isTypeArgumentsInForest = false,
  }) {
    return _helper.buildMethodInvocation(
      receiver,
      name,
      typeArguments,
      arguments,
      offset,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  void printOn(StringSink sink) {
    sink.write(", receiver: ");
    printNodeOn(receiver, sink);
    sink.write(", name: ");
    sink.write(name.text);
  }

  @override
  Expression buildSimpleRead() {
    return _forest.createPropertyGet(
      fileOffset,
      receiver,
      name,
      isNullAware: false,
    );
  }

  @override
  Expression buildAssignment(Expression value, {bool voidContext = false}) {
    return _helper.forest.createPropertySet(
      fileOffset,
      receiver,
      name,
      value,
      forEffect: voidContext,
      isNullAware: false,
    );
  }

  @override
  Expression buildIfNullAssignment(
    Expression value,
    DartType type,
    int offset, {
    bool voidContext = false,
  }) {
    return new IfNullPropertySet(
      receiver,
      name,
      value,
      forEffect: voidContext,
      readOffset: fileOffset,
      writeOffset: fileOffset,
      isNullAware: false,
    )..fileOffset = offset;
  }

  @override
  Expression buildCompoundAssignment(
    Name binaryOperator,
    Expression value, {
    required int operatorOffset,
    bool voidContext = false,
    bool isPreIncDec = false,
    bool isPostIncDec = false,
  }) {
    return new CompoundPropertySet(
      receiver: receiver,
      propertyName: name,
      binaryName: binaryOperator,
      value: value,
      forEffect: voidContext,
      readOffset: fileOffset,
      binaryOffset: operatorOffset,
      writeOffset: fileOffset,
      isNullAware: false,
    )..fileOffset = operatorOffset;
  }

  Expression _buildPrePostfixIncrement(
    Name binaryOperator, {
    required int operatorOffset,
    required bool forEffect,
    required bool isPost,
  }) {
    return new PropertyIncDec(
      receiver,
      name,
      forEffect: forEffect,
      isInc: binaryOperator == plusName,
      isPost: isPost,
      isNullAware: false,
      operatorOffset: operatorOffset,
      nameOffset: _nameOffset,
    )..fileOffset = _nameOffset;
  }

  @override
  Expression buildPrefixIncrement(
    Name binaryOperator, {
    required int operatorOffset,
    bool voidContext = false,
  }) {
    return _buildPrePostfixIncrement(
      binaryOperator,
      operatorOffset: operatorOffset,
      forEffect: voidContext,
      isPost: false,
    );
  }

  @override
  Expression buildPostfixIncrement(
    Name binaryOperator, {
    required int operatorOffset,
    bool voidContext = false,
  }) {
    return _buildPrePostfixIncrement(
      binaryOperator,
      operatorOffset: operatorOffset,
      forEffect: voidContext,
      isPost: true,
    );
  }

  @override
  Generator buildIndexedAccess(
    Expression index,
    Token token, {
    required bool isNullAware,
  }) {
    return new IndexedAccessGenerator(
      _helper,
      token,
      buildSimpleRead(),
      index,
      isNullAware: isNullAware,
    );
  }

  /// Creates a [Generator] for the access of property [name] on [receiver].
  static Generator make(
    ExpressionGeneratorHelper helper,
    Token token,
    Expression receiver,
    Name name,
    bool isNullAware,
  ) {
    if (helper.forest.isThisExpression(receiver)) {
      // Coverage-ignore-block(suite): Not run.
      return new ThisPropertyAccessGenerator(
        helper,
        token,
        name,
        thisVariable: null,
        thisOffset: receiver.fileOffset,
        isNullAware: isNullAware,
      );
    } else {
      return isNullAware
          ? new NullAwarePropertyAccessGenerator(helper, token, receiver, name)
          : new PropertyAccessGenerator(helper, token, receiver, name);
    }
  }
}

/// A [ThisPropertyAccessGenerator] represents a subexpression whose prefix is
/// an implicit or explicit access on `this`.
///
/// For instance
///
///   class C {
///     var b;
///     method() {
///       b;           // a ThisPropertyAccessGenerator is created for `b`.
///       b();         // a ThisPropertyAccessGenerator is created for `b`.
///       b = c;       // a ThisPropertyAccessGenerator is created for `b`.
///       b += c;      // a ThisPropertyAccessGenerator is created for `b`.
///       this.b;      // a ThisPropertyAccessGenerator is created for `this.b`.
///       this.b();    // a ThisPropertyAccessGenerator is created for `this.b`.
///       this.b = c;  // a ThisPropertyAccessGenerator is created for `this.b`.
///       this.b += c; // a ThisPropertyAccessGenerator is created for `this.b`.
///     }
///   }
///
/// This is a special case of [PropertyAccessGenerator] to avoid creating an
/// indirect access to 'this' in for instance `this.b += c` which by
/// [PropertyAccessGenerator] would have been created as
///
///     let #1 = this in #.b = #.b + c
///
/// instead of
///
///     this.b = this.b + c
///
class ThisPropertyAccessGenerator extends Generator {
  /// The name for the accessed property. `b` in the examples in the class
  /// documentation.
  final Name name;

  /// The offset of `this` if explicit. Otherwise `null`.
  final int? thisOffset;
  final bool isNullAware;

  /// The synthetic variable used for 'this' in instance extension members
  /// and instance extension type members/constructor bodies.
  VariableDeclaration? thisVariable;

  ThisPropertyAccessGenerator(
    ExpressionGeneratorHelper helper,
    Token nameToken,
    this.name, {
    this.thisVariable,
    this.thisOffset,
    this.isNullAware = false,
  }) : super(helper, nameToken);

  @override
  // Coverage-ignore(suite): Not run.
  String get _debugName => "ThisPropertyAccessGenerator";

  @override
  String get _plainNameForRead => name.text;

  /// The file offset for the [name].
  int get _nameOffset => fileOffset;

  Expression get _thisExpression => thisVariable != null
      ? _forest.createVariableGet(thisOffset ?? fileOffset, thisVariable!)
      : _forest.createThisExpression(thisOffset ?? fileOffset);

  @override
  Expression buildSimpleRead() {
    return _createRead();
  }

  Expression _createRead() {
    _helper.readInternalThisVariable();
    return _forest.createPropertyGet(
      fileOffset,
      _thisExpression,
      name,
      isNullAware: false,
    );
  }

  @override
  Expression buildAssignment(Expression value, {bool voidContext = false}) {
    return _createWrite(fileOffset, value, forEffect: voidContext);
  }

  Expression _createWrite(
    int offset,
    Expression value, {
    required bool forEffect,
  }) {
    _helper.readInternalThisVariable();
    return _helper.forest.createPropertySet(
      fileOffset,
      _thisExpression,
      name,
      value,
      forEffect: forEffect,
      isNullAware: false,
    );
  }

  @override
  Expression buildIfNullAssignment(
    Expression value,
    DartType type,
    int offset, {
    bool voidContext = false,
  }) {
    return new IfNullSet(
      _createRead(),
      _createWrite(offset, value, forEffect: voidContext),
      forEffect: voidContext,
    )..fileOffset = offset;
  }

  @override
  Expression buildCompoundAssignment(
    Name binaryOperator,
    Expression value, {
    required int operatorOffset,
    bool voidContext = false,
    bool isPreIncDec = false,
    bool isPostIncDec = false,
  }) {
    Expression binary = _helper.forest.createBinary(
      operatorOffset,
      _createRead(),
      binaryOperator,
      value,
    );
    return _createWrite(fileOffset, binary, forEffect: voidContext);
  }

  Expression _buildPrePostfixIncrement(
    Name binaryOperator, {
    required int operatorOffset,
    required bool forEffect,
    required bool isPost,
  }) {
    _helper.readInternalThisVariable();
    return new PropertyIncDec(
      _thisExpression,
      name,
      forEffect: forEffect,
      isInc: binaryOperator == plusName,
      isPost: isPost,
      isNullAware: false,
      operatorOffset: operatorOffset,
      nameOffset: _nameOffset,
    )..fileOffset = fileOffset;
  }

  @override
  Expression buildPrefixIncrement(
    Name binaryOperator, {
    required int operatorOffset,
    bool voidContext = false,
  }) {
    return _buildPrePostfixIncrement(
      binaryOperator,
      operatorOffset: operatorOffset,
      forEffect: voidContext,
      isPost: false,
    );
  }

  @override
  Expression buildPostfixIncrement(
    Name binaryOperator, {
    required int operatorOffset,
    bool voidContext = false,
  }) {
    return _buildPrePostfixIncrement(
      binaryOperator,
      operatorOffset: operatorOffset,
      forEffect: voidContext,
      isPost: true,
    );
  }

  @override
  Expression doInvocation({
    required int offset,
    required List<TypeBuilder>? typeArgumentBuilders,
    required TypeArguments? typeArguments,
    required ActualArguments arguments,
    bool isTypeArgumentsInForest = false,
  }) {
    _helper.readInternalThisVariable();
    return _helper.buildMethodInvocation(
      _thisExpression,
      name,
      typeArguments,
      arguments,
      offset,
    );
  }

  @override
  Generator buildIndexedAccess(
    Expression index,
    Token token, {
    required bool isNullAware,
  }) {
    return new IndexedAccessGenerator(
      _helper,
      token,
      buildSimpleRead(),
      index,
      isNullAware: isNullAware,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  void printOn(StringSink sink) {
    sink.write(", name: ");
    sink.write(name.text);
  }
}

class NullAwarePropertyAccessGenerator extends Generator {
  final Expression receiver;

  final Name name;

  NullAwarePropertyAccessGenerator(
    ExpressionGeneratorHelper helper,
    Token nameToken,
    this.receiver,
    this.name,
  ) : super(helper, nameToken);

  @override
  // Coverage-ignore(suite): Not run.
  String get _debugName => "NullAwarePropertyAccessGenerator";

  @override
  // Coverage-ignore(suite): Not run.
  String get _plainNameForRead => name.text;

  /// The file offset of the [name].
  int get _nameOffset => fileOffset;

  @override
  Expression buildSimpleRead() {
    return _forest.createPropertyGet(
      fileOffset,
      receiver,
      name,
      isNullAware: true,
    );
  }

  @override
  Expression buildAssignment(Expression value, {bool voidContext = false}) {
    return _forest.createPropertySet(
      fileOffset,
      receiver,
      name,
      value,
      forEffect: voidContext,
      isNullAware: true,
    );
  }

  @override
  Expression buildIfNullAssignment(
    Expression value,
    DartType type,
    int offset, {
    bool voidContext = false,
  }) {
    return new IfNullPropertySet(
      receiver,
      name,
      value,
      forEffect: voidContext,
      readOffset: fileOffset,
      writeOffset: fileOffset,
      isNullAware: true,
    )..fileOffset = offset;
  }

  @override
  Expression buildCompoundAssignment(
    Name binaryOperator,
    Expression value, {
    required int operatorOffset,
    bool voidContext = false,
    bool isPreIncDec = false,
    bool isPostIncDec = false,
  }) {
    return new CompoundPropertySet(
      receiver: receiver,
      propertyName: name,
      binaryName: binaryOperator,
      value: value,
      forEffect: voidContext,
      readOffset: fileOffset,
      binaryOffset: operatorOffset,
      writeOffset: fileOffset,
      isNullAware: true,
    )..fileOffset = operatorOffset;
  }

  Expression _buildPrePostfixIncrement(
    Name binaryOperator, {
    required int operatorOffset,
    required bool forEffect,
    required bool isPost,
  }) {
    return new PropertyIncDec(
      receiver,
      name,
      forEffect: forEffect,
      isInc: binaryOperator == plusName,
      isPost: isPost,
      isNullAware: true,
      operatorOffset: operatorOffset,
      nameOffset: _nameOffset,
    )..fileOffset = fileOffset;
  }

  @override
  Expression buildPrefixIncrement(
    Name binaryOperator, {
    required int operatorOffset,
    bool voidContext = false,
  }) {
    return _buildPrePostfixIncrement(
      binaryOperator,
      operatorOffset: operatorOffset,
      forEffect: voidContext,
      isPost: false,
    );
  }

  @override
  Expression buildPostfixIncrement(
    Name binaryOperator, {
    required int operatorOffset,
    bool voidContext = false,
  }) {
    return _buildPrePostfixIncrement(
      binaryOperator,
      operatorOffset: operatorOffset,
      forEffect: voidContext,
      isPost: true,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  Expression doInvocation({
    required int offset,
    required List<TypeBuilder>? typeArgumentBuilders,
    required TypeArguments? typeArguments,
    required ActualArguments arguments,
    bool isTypeArgumentsInForest = false,
  }) {
    return unsupported("doInvocation", offset, _fileUri);
  }

  @override
  Generator buildIndexedAccess(
    Expression index,
    Token token, {
    required bool isNullAware,
  }) {
    return new IndexedAccessGenerator(
      _helper,
      token,
      buildSimpleRead(),
      index,
      isNullAware: isNullAware,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  void printOn(StringSink sink) {
    sink.write(", receiver: ");
    printNodeOn(receiver, sink);
    sink.write(", name: ");
    sink.write(name.text);
  }
}

class SuperPropertyAccessGenerator extends Generator {
  final Name name;

  final Member? getter;

  final Member? setter;

  SuperPropertyAccessGenerator(
    ExpressionGeneratorHelper helper,
    Token nameToken,
    this.name,
    this.getter,
    this.setter,
  ) : super(helper, nameToken);

  @override
  // Coverage-ignore(suite): Not run.
  String get _debugName => "SuperPropertyAccessGenerator";

  @override
  // Coverage-ignore(suite): Not run.
  String get _plainNameForRead => name.text;

  int get _nameOffset => fileOffset;

  @override
  Expression buildSimpleRead() {
    return _createRead();
  }

  Expression _createRead() {
    Member? getter = this.getter;
    if (getter == null) {
      return _helper.buildUnresolvedError(
        name.text,
        fileOffset,
        isSuper: true,
        kind: UnresolvedKind.Getter,
      );
    } else {
      _helper.readInternalThisVariable();
      return new SuperPropertyGet(new ThisExpression(), name, getter)
        ..fileOffset = fileOffset;
    }
  }

  @override
  Expression buildAssignment(Expression value, {bool voidContext = false}) {
    return _createWrite(fileOffset, value);
  }

  Expression _createWrite(int offset, Expression value) {
    Member? setter = this.setter;
    if (setter == null) {
      return _helper.buildUnresolvedError(
        name.text,
        fileOffset,
        isSuper: true,
        kind: UnresolvedKind.Setter,
      );
    } else {
      _helper.readInternalThisVariable();
      return new SuperPropertySet(new ThisExpression(), name, value, setter)
        ..fileOffset = offset;
    }
  }

  @override
  Expression buildCompoundAssignment(
    Name binaryOperator,
    Expression value, {
    required int operatorOffset,
    bool voidContext = false,
    bool isPreIncDec = false,
    bool isPostIncDec = false,
  }) {
    Expression binary = _helper.forest.createBinary(
      operatorOffset,
      _createRead(),
      binaryOperator,
      value,
    );
    return _createWrite(fileOffset, binary);
  }

  Expression _buildPrePostfixIncrement(
    Name binaryOperator, {
    required int operatorOffset,
    required bool voidContext,
    required bool isPost,
  }) {
    Member? getter = this.getter;
    Member? setter = this.setter;
    if (getter == null) {
      return _helper.buildUnresolvedError(
        name.text,
        fileOffset,
        isSuper: true,
        kind: UnresolvedKind.Getter,
      );
    } else if (setter == null) {
      return _helper.buildUnresolvedError(
        name.text,
        fileOffset,
        isSuper: true,
        kind: UnresolvedKind.Setter,
      );
    }
    _helper.readInternalThisVariable();
    return new SuperIncDec(
      getter: getter,
      setter: setter,
      name: name,
      forEffect: voidContext,
      isPost: isPost,
      isInc: binaryOperator == plusName,
      nameOffset: _nameOffset,
      operatorOffset: operatorOffset,
    )..fileOffset = _nameOffset;
  }

  @override
  Expression buildPrefixIncrement(
    Name binaryOperator, {
    required int operatorOffset,
    bool voidContext = false,
  }) {
    return _buildPrePostfixIncrement(
      binaryOperator,
      operatorOffset: operatorOffset,
      voidContext: voidContext,
      isPost: false,
    );
  }

  @override
  Expression buildPostfixIncrement(
    Name binaryOperator, {
    required int operatorOffset,
    bool voidContext = false,
  }) {
    return _buildPrePostfixIncrement(
      binaryOperator,
      operatorOffset: operatorOffset,
      voidContext: voidContext,
      isPost: true,
    );
  }

  @override
  Expression buildIfNullAssignment(
    Expression value,
    DartType type,
    int offset, {
    bool voidContext = false,
  }) {
    return new IfNullSet(
      _createRead(),
      _createWrite(fileOffset, value),
      forEffect: voidContext,
    )..fileOffset = offset;
  }

  @override
  // Coverage-ignore(suite): Not run.
  Expression doInvocation({
    required int offset,
    required List<TypeBuilder>? typeArgumentBuilders,
    required TypeArguments? typeArguments,
    required ActualArguments arguments,
    bool isTypeArgumentsInForest = false,
  }) {
    if (_helper.constantContext != ConstantContext.none) {
      // TODO(brianwilkerson) Fix the length
      problemReporting.addProblem(
        diag.notAConstantExpression,
        offset,
        1,
        _fileUri,
      );
    }
    if (getter == null) {
      return _helper.buildUnresolvedError(
        name.text,
        fileOffset,
        isSuper: true,
        kind: UnresolvedKind.Method,
      );
    } else if (isFieldOrGetter(getter)) {
      return _helper.forest.createExpressionInvocation(
        offset,
        buildSimpleRead(),
        typeArguments,
        arguments,
      );
    } else {
      // TODO(ahe): This could be something like "super.property(...)" where
      // property is a setter.
      return unhandled(
        "${getter.runtimeType}",
        "doInvocation",
        offset,
        _fileUri,
      );
    }
  }

  @override
  Generator buildIndexedAccess(
    Expression index,
    Token token, {
    required bool isNullAware,
  }) {
    return new IndexedAccessGenerator(
      _helper,
      token,
      buildSimpleRead(),
      index,
      isNullAware: isNullAware,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  void printOn(StringSink sink) {
    sink.write(", name: ");
    sink.write(name.text);
    sink.write(", getter: ");
    printQualifiedNameOn(getter, sink);
    sink.write(", setter: ");
    printQualifiedNameOn(setter, sink);
  }
}

class IndexedAccessGenerator extends Generator {
  final Expression receiver;

  final Expression index;

  final bool isNullAware;

  IndexedAccessGenerator(
    ExpressionGeneratorHelper helper,
    Token token,
    this.receiver,
    this.index, {
    required this.isNullAware,
  }) : super(helper, token);

  @override
  // Coverage-ignore(suite): Not run.
  String get _plainNameForRead => "[]";

  @override
  // Coverage-ignore(suite): Not run.
  String get _debugName => "IndexedAccessGenerator";

  @override
  Expression buildSimpleRead() {
    _helper.readInternalThisVariable();
    return _forest.createIndexGet(
      fileOffset,
      receiver,
      index,
      isNullAware: isNullAware,
    );
  }

  @override
  Expression buildAssignment(Expression value, {bool voidContext = false}) {
    return _forest.createIndexSet(
      fileOffset,
      receiver,
      index,
      value,
      forEffect: voidContext,
      isNullAware: isNullAware,
    );
  }

  @override
  Expression buildIfNullAssignment(
    Expression value,
    DartType type,
    int offset, {
    bool voidContext = false,
  }) {
    return new IfNullIndexSet(
      receiver: receiver,
      index: index,
      value: value,
      readOffset: fileOffset,
      testOffset: offset,
      writeOffset: fileOffset,
      forEffect: voidContext,
      isNullAware: isNullAware,
    )..fileOffset = offset;
  }

  @override
  Expression buildCompoundAssignment(
    Name binaryOperator,
    Expression value, {
    required int operatorOffset,
    bool voidContext = false,
    bool isPreIncDec = false,
    bool isPostIncDec = false,
  }) {
    return new CompoundIndexSet(
      receiver: receiver,
      index: index,
      binaryName: binaryOperator,
      value: value,
      readOffset: fileOffset,
      binaryOffset: operatorOffset,
      writeOffset: fileOffset,
      forEffect: voidContext,
      forPostIncDec: isPostIncDec,
      isNullAware: isNullAware,
    )..fileOffset = operatorOffset;
  }

  @override
  Expression buildPostfixIncrement(
    Name binaryOperator, {
    required int operatorOffset,
    bool voidContext = false,
  }) {
    Expression value = _forest.createIntLiteral(operatorOffset, 1);
    return buildCompoundAssignment(
      binaryOperator,
      value,
      operatorOffset: operatorOffset,
      voidContext: voidContext,
      isPostIncDec: true,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  Expression doInvocation({
    required int offset,
    required List<TypeBuilder>? typeArgumentBuilders,
    required TypeArguments? typeArguments,
    required ActualArguments arguments,
    bool isTypeArgumentsInForest = false,
  }) {
    _helper.readInternalThisVariable();
    return _helper.forest.createExpressionInvocation(
      arguments.fileOffset,
      buildSimpleRead(),
      typeArguments,
      arguments,
    );
  }

  @override
  Generator buildIndexedAccess(
    Expression index,
    Token token, {
    required bool isNullAware,
  }) {
    return new IndexedAccessGenerator(
      _helper,
      token,
      buildSimpleRead(),
      index,
      isNullAware: isNullAware,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  void printOn(StringSink sink) {
    sink.write(", receiver: ");
    printNodeOn(receiver, sink);
    sink.write(", index: ");
    printNodeOn(index, sink);
    sink.write(", isNullAware: ${isNullAware}");
  }

  static Generator make(
    ExpressionGeneratorHelper helper,
    Token token,
    Expression receiver,
    Expression index, {
    required bool isNullAware,
  }) {
    if (helper.forest.isThisExpression(receiver)) {
      // Coverage-ignore-block(suite): Not run.
      return new ThisIndexedAccessGenerator(
        helper,
        token,
        index,
        thisOffset: receiver.fileOffset,
        isNullAware: isNullAware,
      );
    } else {
      return new IndexedAccessGenerator(
        helper,
        token,
        receiver,
        index,
        isNullAware: isNullAware,
      );
    }
  }
}

/// Special case of [IndexedAccessGenerator] to avoid creating an indirect
/// access to 'this'.
class ThisIndexedAccessGenerator extends Generator {
  final Expression index;

  final int? thisOffset;
  final bool isNullAware;

  ThisIndexedAccessGenerator(
    ExpressionGeneratorHelper helper,
    Token token,
    this.index, {
    this.thisOffset,
    this.isNullAware = false,
  }) : super(helper, token);

  @override
  // Coverage-ignore(suite): Not run.
  String get _plainNameForRead => "[]";

  @override
  // Coverage-ignore(suite): Not run.
  String get _debugName => "ThisIndexedAccessGenerator";

  @override
  Expression buildSimpleRead() {
    _helper.readInternalThisVariable();
    Expression receiver = _helper.forest.createThisExpression(fileOffset);
    return _forest.createIndexGet(
      fileOffset,
      receiver,
      index,
      isNullAware: isNullAware,
    );
  }

  @override
  Expression buildAssignment(Expression value, {bool voidContext = false}) {
    _helper.readInternalThisVariable();
    Expression receiver = _helper.forest.createThisExpression(fileOffset);
    return _forest.createIndexSet(
      fileOffset,
      receiver,
      index,
      value,
      forEffect: voidContext,
      isNullAware: isNullAware,
    );
  }

  @override
  Expression buildIfNullAssignment(
    Expression value,
    DartType type,
    int offset, {
    bool voidContext = false,
  }) {
    _helper.readInternalThisVariable();
    Expression receiver = _helper.forest.createThisExpression(fileOffset);
    return new IfNullIndexSet(
      receiver: receiver,
      index: index,
      value: value,
      readOffset: fileOffset,
      testOffset: offset,
      writeOffset: fileOffset,
      forEffect: voidContext,
      isNullAware: isNullAware,
    )..fileOffset = offset;
  }

  @override
  Expression buildCompoundAssignment(
    Name binaryOperator,
    Expression value, {
    required int operatorOffset,
    bool voidContext = false,
    bool isPreIncDec = false,
    bool isPostIncDec = false,
  }) {
    _helper.readInternalThisVariable();
    Expression receiver = _helper.forest.createThisExpression(fileOffset);
    return new CompoundIndexSet(
      receiver: receiver,
      index: index,
      binaryName: binaryOperator,
      value: value,
      readOffset: fileOffset,
      binaryOffset: operatorOffset,
      writeOffset: fileOffset,
      forEffect: voidContext,
      forPostIncDec: isPostIncDec,
      isNullAware: isNullAware,
    )..fileOffset = operatorOffset;
  }

  @override
  Expression buildPostfixIncrement(
    Name binaryOperator, {
    required int operatorOffset,
    bool voidContext = false,
  }) {
    Expression value = _forest.createIntLiteral(operatorOffset, 1);
    return buildCompoundAssignment(
      binaryOperator,
      value,
      operatorOffset: operatorOffset,
      voidContext: voidContext,
      isPostIncDec: true,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  Expression doInvocation({
    required int offset,
    required List<TypeBuilder>? typeArgumentBuilders,
    required TypeArguments? typeArguments,
    required ActualArguments arguments,
    bool isTypeArgumentsInForest = false,
  }) {
    return _helper.forest.createExpressionInvocation(
      offset,
      buildSimpleRead(),
      typeArguments,
      arguments,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  Generator buildIndexedAccess(
    Expression index,
    Token token, {
    required bool isNullAware,
  }) {
    return new IndexedAccessGenerator(
      _helper,
      token,
      buildSimpleRead(),
      index,
      isNullAware: isNullAware,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  void printOn(StringSink sink) {
    sink.write(", index: ");
    printNodeOn(index, sink);
  }
}

class SuperIndexedAccessGenerator extends Generator {
  final Expression index;

  final Procedure? getter;

  final Procedure? setter;

  SuperIndexedAccessGenerator(
    ExpressionGeneratorHelper helper,
    Token token,
    this.index,
    this.getter,
    this.setter,
  ) : super(helper, token);

  @override
  // Coverage-ignore(suite): Not run.
  String get _plainNameForRead => "[]";

  @override
  // Coverage-ignore(suite): Not run.
  String get _debugName => "SuperIndexedAccessGenerator";

  @override
  Expression buildSimpleRead() {
    Procedure? getter = this.getter;
    if (getter == null) {
      return _helper.buildUnresolvedError(
        indexGetName.text,
        fileOffset,
        isSuper: true,
        kind: UnresolvedKind.Method,
        length: noLength,
      );
    } else {
      _helper.readInternalThisVariable();
      return _helper.forest.createSuperMethodInvocation(
        fileOffset,
        indexGetName,
        getter,
        null,
        _helper.forest.createArguments(
          fileOffset,
          arguments: [new PositionalArgument(index)],
          hasNamedBeforePositional: false,
          positionalCount: 1,
        ),
      );
    }
  }

  @override
  Expression buildAssignment(Expression value, {bool voidContext = false}) {
    Procedure? setter = this.setter;
    if (setter == null) {
      return _helper.buildUnresolvedError(
        indexSetName.text,
        fileOffset,
        isSuper: true,
        kind: UnresolvedKind.Method,
        length: noLength,
      );
    } else {
      if (voidContext) {
        _helper.readInternalThisVariable();
        return _helper.forest.createSuperMethodInvocation(
          fileOffset,
          indexSetName,
          setter,
          null,
          _helper.forest.createArguments(
            fileOffset,
            arguments: [
              new PositionalArgument(index),
              new PositionalArgument(value),
            ],
            hasNamedBeforePositional: false,
            positionalCount: 2,
          ),
        );
      } else {
        _helper.readInternalThisVariable();
        return new SuperIndexSet(setter, index, value)..fileOffset = fileOffset;
      }
    }
  }

  @override
  Expression buildIfNullAssignment(
    Expression value,
    DartType type,
    int offset, {
    bool voidContext = false,
  }) {
    _helper.readInternalThisVariable();
    return new IfNullSuperIndexSet(
      getter: getter,
      setter: setter,
      index: index,
      value: value,
      readOffset: fileOffset,
      testOffset: offset,
      writeOffset: fileOffset,
      forEffect: voidContext,
    )..fileOffset = offset;
  }

  @override
  Expression buildCompoundAssignment(
    Name binaryOperator,
    Expression value, {
    required int operatorOffset,
    bool voidContext = false,
    bool isPreIncDec = false,
    bool isPostIncDec = false,
  }) {
    Procedure? getter = this.getter;
    Procedure? setter = this.setter;
    if (getter == null || setter == null) {
      return buildAssignment(
        buildBinaryOperation(token, binaryOperator, value),
      );
    } else {
      _helper.readInternalThisVariable();
      return new CompoundSuperIndexSet(
        getter: getter,
        setter: setter,
        index: index,
        binaryName: binaryOperator,
        value: value,
        readOffset: fileOffset,
        binaryOffset: operatorOffset,
        writeOffset: fileOffset,
        forEffect: voidContext,
        forPostIncDec: isPostIncDec,
      );
    }
  }

  @override
  Expression buildPostfixIncrement(
    Name binaryOperator, {
    required int operatorOffset,
    bool voidContext = false,
  }) {
    Expression value = _forest.createIntLiteral(operatorOffset, 1);
    return buildCompoundAssignment(
      binaryOperator,
      value,
      operatorOffset: operatorOffset,
      voidContext: voidContext,
      isPostIncDec: true,
    );
  }

  @override
  Expression doInvocation({
    required int offset,
    required List<TypeBuilder>? typeArgumentBuilders,
    required TypeArguments? typeArguments,
    required ActualArguments arguments,
    bool isTypeArgumentsInForest = false,
  }) {
    _helper.readInternalThisVariable();
    return _helper.forest.createExpressionInvocation(
      offset,
      buildSimpleRead(),
      typeArguments,
      arguments,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  Generator buildIndexedAccess(
    Expression index,
    Token token, {
    required bool isNullAware,
  }) {
    return new IndexedAccessGenerator(
      _helper,
      token,
      buildSimpleRead(),
      index,
      isNullAware: isNullAware,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  void printOn(StringSink sink) {
    sink.write(", index: ");
    printNodeOn(index, sink);
    sink.write(", getter: ");
    printQualifiedNameOn(getter, sink);
    sink.write(", setter: ");
    printQualifiedNameOn(setter, sink);
  }
}

/// A [StaticAccessGenerator] represents a subexpression whose prefix is
/// a static or top-level member, including static extension members.
///
/// For instance
///
///   get property => 0;
///   set property(_) {}
///   var field;
///   method() {}
///
///   main() {
///     property;     // a StaticAccessGenerator is created for `property`.
///     property = 0; // a StaticAccessGenerator is created for `property`.
///     field = 0;    // a StaticAccessGenerator is created for `field`.
///     method;       // a StaticAccessGenerator is created for `method`.
///     method();     // a StaticAccessGenerator is created for `method`.
///   }
///
///   class A {}
///   extension B on A {
///     static get property => 0;
///     static set property(_) {}
///     static var field;
///     static method() {
///       property;     // this StaticAccessGenerator is created for `property`.
///       property = 0; // this StaticAccessGenerator is created for `property`.
///       field = 0;    // this StaticAccessGenerator is created for `field`.
///       method;       // this StaticAccessGenerator is created for `method`.
///       method();     // this StaticAccessGenerator is created for `method`.
///     }
///   }
///
class StaticAccessGenerator extends Generator {
  /// The name of the original target;
  final Name targetName;

  /// The static [Member] used for performing a read on this subexpression.
  ///
  /// This can be `null` if the subexpression doesn't have a readable target.
  /// For instance if the subexpression is a setter without a corresponding
  /// getter.
  final Member? readTarget;

  /// The static [Member] used for performing an invocation on this
  /// subexpression.
  ///
  /// This can be `null` if the subexpression doesn't have an invokable target.
  /// For instance if the subexpression is a setter without a corresponding
  /// getter.
  final Member? invokeTarget;

  /// The static [Member] used for performing a write on this subexpression.
  ///
  /// This can be `null` if the subexpression doesn't have a writable target.
  /// For instance if the subexpression is a final field, a method, or a getter
  /// without a corresponding setter.
  final Member? writeTarget;

  /// The offset of the type name if explicit. Otherwise `null`.
  final int? typeOffset;
  final bool isNullAware;

  StaticAccessGenerator(
    ExpressionGeneratorHelper helper,
    Token nameToken,
    this.targetName,
    this.readTarget,
    this.invokeTarget,
    this.writeTarget, {
    this.typeOffset,
    this.isNullAware = false,
  }) : assert(
         readTarget != null || invokeTarget != null || writeTarget != null,
         "No targets for $targetName.",
       ),
       super(helper, nameToken);

  factory StaticAccessGenerator.fromBuilder(
    ExpressionGeneratorHelper helper,
    Name targetName,
    Token nameToken,
    MemberBuilder? getterBuilder,
    MemberBuilder? setterBuilder, {
    int? typeOffset,
    bool isNullAware = false,
  }) {
    // If both [getterBuilder] and [setterBuilder] exist, they must both be
    // either top level (potentially from different libraries) or from the same
    // class/extension.
    assert(
      getterBuilder == null ||
          setterBuilder == null ||
          getterBuilder.declarationBuilder == setterBuilder.declarationBuilder,
      "Invalid builders for $targetName: $getterBuilder vs $setterBuilder.",
    );
    return new StaticAccessGenerator(
      helper,
      nameToken,
      targetName,
      getterBuilder?.readTarget,
      getterBuilder?.invokeTarget,
      setterBuilder?.writeTarget,
      typeOffset: typeOffset,
      isNullAware: isNullAware,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  String get _debugName => "StaticAccessGenerator";

  @override
  String get _plainNameForRead => targetName.text;

  int get _nameOffset => fileOffset;

  @override
  Expression buildSimpleRead() {
    return _createRead();
  }

  Expression _createRead() {
    Expression read;
    Member? readTarget = this.readTarget;
    if (readTarget == null) {
      read = _makeInvalidRead(unresolvedKind: UnresolvedKind.Getter);
    } else {
      if (readTarget is Procedure && readTarget.kind == ProcedureKind.Method) {
        read = _helper.forest.createStaticTearOff(fileOffset, readTarget);
      } else {
        read = _helper.forest.createStaticGet(fileOffset, readTarget);
      }
    }
    return read;
  }

  @override
  Expression buildAssignment(Expression value, {bool voidContext = false}) {
    return _createWrite(fileOffset, value);
  }

  Expression _createWrite(int offset, Expression value) {
    Expression write;
    if (writeTarget == null) {
      write = _makeInvalidWrite();
    } else {
      write = new StaticSet(writeTarget!, value)..fileOffset = offset;
    }
    return write;
  }

  @override
  Expression buildIfNullAssignment(
    Expression value,
    DartType type,
    int offset, {
    bool voidContext = false,
  }) {
    return new IfNullSet(
      _createRead(),
      _createWrite(offset, value),
      forEffect: voidContext,
    )..fileOffset = offset;
  }

  @override
  Expression buildCompoundAssignment(
    Name binaryOperator,
    Expression value, {
    required int operatorOffset,
    bool voidContext = false,
    bool isPreIncDec = false,
    bool isPostIncDec = false,
  }) {
    Expression binary = _helper.forest.createBinary(
      operatorOffset,
      _createRead(),
      binaryOperator,
      value,
    );
    return _createWrite(fileOffset, binary);
  }

  Expression _buildPrePostfixIncrement(
    Name binaryOperator, {
    required int operatorOffset,
    required bool voidContext,
    required bool isPost,
  }) {
    Member? getter = readTarget;
    Member? setter = writeTarget;
    if (getter == null) {
      return _makeInvalidRead(unresolvedKind: UnresolvedKind.Getter);
    } else if (setter == null) {
      return _makeInvalidRead(unresolvedKind: UnresolvedKind.Setter);
    }

    return new StaticIncDec(
      getter: getter,
      setter: setter,
      name: targetName,
      forEffect: voidContext,
      isPost: isPost,
      isInc: binaryOperator == plusName,
      nameOffset: _nameOffset,
      operatorOffset: operatorOffset,
    )..fileOffset = _nameOffset;
  }

  @override
  Expression buildPrefixIncrement(
    Name binaryOperator, {
    required int operatorOffset,
    bool voidContext = false,
  }) {
    return _buildPrePostfixIncrement(
      binaryOperator,
      operatorOffset: operatorOffset,
      voidContext: voidContext,
      isPost: false,
    );
  }

  @override
  Expression buildPostfixIncrement(
    Name binaryOperator, {
    required int operatorOffset,
    bool voidContext = false,
  }) {
    return _buildPrePostfixIncrement(
      binaryOperator,
      operatorOffset: operatorOffset,
      voidContext: voidContext,
      isPost: true,
    );
  }

  @override
  Expression doInvocation({
    required int offset,
    required List<TypeBuilder>? typeArgumentBuilders,
    required TypeArguments? typeArguments,
    required ActualArguments arguments,
    bool isTypeArgumentsInForest = false,
  }) {
    if (_helper.constantContext != ConstantContext.none &&
        !_helper.isIdentical(invokeTarget) &&
        !_helper.libraryFeatures.constFunctions.isEnabled) {
      return _helper.buildProblem(
        message: diag.notConstantExpression.withArgumentsOld(
          'Method invocation',
        ),
        fileUri: _helper.uri,
        fileOffset: offset,
        length: invokeTarget?.name.text.length ?? 0,
      );
    }
    if (invokeTarget == null ||
        (readTarget != null && isFieldOrGetter(readTarget!))) {
      return _helper.forest.createExpressionInvocation(
        offset + (readTarget?.name.text.length ?? 0),
        buildSimpleRead(),
        typeArguments,
        arguments,
      );
    } else {
      return _helper.buildStaticInvocation(
        target: invokeTarget as Procedure,
        typeArguments: typeArguments,
        arguments: arguments,
        fileOffset: offset,
      );
    }
  }

  @override
  Generator buildIndexedAccess(
    Expression index,
    Token token, {
    required bool isNullAware,
  }) {
    return new IndexedAccessGenerator(
      _helper,
      token,
      buildSimpleRead(),
      index,
      isNullAware: isNullAware,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  void printOn(StringSink sink) {
    sink.write(", targetName: ");
    sink.write(targetName);
    sink.write(", readTarget: ");
    printQualifiedNameOn(readTarget, sink);
    sink.write(", writeTarget: ");
    printQualifiedNameOn(writeTarget, sink);
  }
}

/// An [ExtensionInstanceAccessGenerator] represents a subexpression whose
/// prefix is an extension instance member.
///
/// For instance
///
///   class A {}
///   extension B on A {
///     get property => 0;
///     set property(_) {}
///     method() {
///       property;     // this generator is created for `property`.
///       property = 0; // this generator is created for `property`.
///       method;       // this generator is created for `method`.
///       method();     // this generator is created for `method`.
///     }
///   }
///
/// These can only occur within an extension instance member.
class ExtensionInstanceAccessGenerator extends Generator {
  final Extension extension;

  /// The original name of the target.
  final Name targetName;

  /// The static [Member] generated for an instance extension member which is
  /// used for performing a read on this subexpression.
  ///
  /// This can be `null` if the subexpression doesn't have a readable target.
  /// For instance if the subexpression is a setter without a corresponding
  /// getter.
  final Procedure? readTarget;

  /// The static [Member] generated for an instance extension member which is
  /// used for performing an invocation on this subexpression.
  ///
  /// This can be `null` if the subexpression doesn't have an invokable target.
  /// For instance if the subexpression is a getter or setter.
  final Procedure? invokeTarget;

  /// The static [Member] generated for an instance extension member which is
  /// used for performing a write on this subexpression.
  ///
  /// This can be `null` if the subexpression doesn't have a writable target.
  /// For instance if the subexpression is a final field, a method, or a getter
  /// without a corresponding setter.
  final Procedure? writeTarget;

  /// The parameter holding the value for `this` within the current extension
  /// instance method.
  // TODO(johnniwinther): Handle static access to extension instance members,
  // in which case the access is erroneous and [extensionThis] is `null`.
  final VariableDeclaration extensionThis;

  /// The type parameters synthetically added to  the current extension
  /// instance method.
  final List<TypeParameter>? extensionTypeParameters;

  ExtensionInstanceAccessGenerator(
    ExpressionGeneratorHelper helper,
    Token token,
    this.extension,
    this.targetName,
    this.readTarget,
    this.invokeTarget,
    this.writeTarget,
    this.extensionThis,
    this.extensionTypeParameters,
  ) : assert(readTarget != null || invokeTarget != null || writeTarget != null),
      super(helper, token);

  factory ExtensionInstanceAccessGenerator.fromBuilder(
    ExpressionGeneratorHelper helper,
    Token token,
    Extension extension,
    Name targetName,
    VariableDeclaration extensionThis,
    List<TypeParameter>? extensionTypeParameters,
    MemberBuilder? getterBuilder,
    MemberBuilder? setterBuilder,
  ) {
    Procedure? readTarget;
    Procedure? invokeTarget;
    if (getterBuilder != null) {
      assert(!getterBuilder.isStatic);
      if (getterBuilder is PropertyBuilder) {
        assert(!getterBuilder.hasConcreteField);
        readTarget = getterBuilder.readTarget as Procedure?;
      } else if (getterBuilder is MethodBuilder) {
        if (getterBuilder.isOperator) {
          // Coverage-ignore-block(suite): Not run.
          invokeTarget = getterBuilder.invokeTarget as Procedure?;
        } else {
          readTarget = getterBuilder.readTarget as Procedure?;
          invokeTarget = getterBuilder.invokeTarget as Procedure?;
        }
      } else {
        return unhandled(
          "${getterBuilder.runtimeType}",
          "ExtensionInstanceAccessGenerator.fromBuilder",
          offsetForToken(token),
          helper.uri,
        );
      }
    }
    Procedure? writeTarget;
    if (setterBuilder != null) {
      if (setterBuilder is PropertyBuilder) {
        assert(!setterBuilder.isStatic && !setterBuilder.hasConcreteField);
        writeTarget = setterBuilder.writeTarget as Procedure?;
      } else {
        return unhandled(
          "${setterBuilder.runtimeType}",
          "ExtensionInstanceAccessGenerator.fromBuilder",
          offsetForToken(token),
          helper.uri,
        );
      }
    }
    return new ExtensionInstanceAccessGenerator(
      helper,
      token,
      extension,
      targetName,
      readTarget,
      invokeTarget,
      writeTarget,
      extensionThis,
      extensionTypeParameters,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  String get _debugName => "InstanceExtensionAccessGenerator";

  @override
  String get _plainNameForRead => targetName.text;

  /// Creates an access to the implicit `this` variable.
  Expression _createThisAccess() =>
      _helper.createVariableGet(extensionThis, fileOffset);

  /// Creates the implicit type arguments for the extension access. These
  /// are the type parameter type of the extension type parameters.
  List<DartType>? _createThisTypeArguments() {
    List<DartType>? extensionTypeArguments;
    if (extensionTypeParameters != null) {
      extensionTypeArguments = [];
      for (TypeParameter typeParameter in extensionTypeParameters!) {
        extensionTypeArguments.add(
          _forest.createTypeParameterTypeWithDefaultNullabilityForLibrary(
            typeParameter,
            extension.enclosingLibrary,
          ),
        );
      }
    }
    return extensionTypeArguments;
  }

  /// Returns `true` if performing a read operation is a tear off.
  ///
  /// This is the case if [invokeTarget] is non-null, since extension methods
  /// have both a [readTarget] and an [invokeTarget], whereas extension getters
  /// only have a [readTarget].
  bool get isReadTearOff => invokeTarget != null;

  @override
  Expression buildSimpleRead() {
    return _createRead();
  }

  Expression _createRead() {
    Procedure? getter = readTarget;
    Expression read;
    if (getter == null) {
      read = _makeInvalidRead(unresolvedKind: UnresolvedKind.Getter);
    } else if (isReadTearOff) {
      read = new ExtensionTearOff.implicit(
        extension: extension,
        thisTypeArguments: _createThisTypeArguments(),
        thisAccess: _createThisAccess(),
        name: targetName,
        tearOff: getter,
      )..fileOffset = fileOffset;
    } else {
      read = new ExtensionGet.implicit(
        extension: extension,
        thisTypeArguments: _createThisTypeArguments(),
        thisAccess: _createThisAccess(),
        name: targetName,
        getter: getter,
      )..fileOffset = fileOffset;
    }
    return read;
  }

  @override
  Expression buildAssignment(Expression value, {bool voidContext = false}) {
    return _createWrite(fileOffset, value, forEffect: voidContext);
  }

  Expression _createWrite(
    int offset,
    Expression value, {
    required bool forEffect,
  }) {
    Procedure? setter = writeTarget;
    if (setter == null) {
      return _makeInvalidWrite();
    } else {
      return new ExtensionSet.implicit(
        extension: extension,
        thisTypeArguments: _createThisTypeArguments(),
        thisAccess: _createThisAccess(),
        name: targetName,
        setter: setter,
        value: value,
        forEffect: forEffect,
      )..fileOffset = offset;
    }
  }

  @override
  Expression buildIfNullAssignment(
    Expression value,
    DartType type,
    int offset, {
    bool voidContext = false,
  }) {
    Procedure? getter = readTarget;
    Procedure? setter = writeTarget;
    // Coverage-ignore(suite): Not run.
    if (getter == null) {
      return _makeInvalidRead(unresolvedKind: UnresolvedKind.Getter);
    } else if (setter == null) {
      return _makeInvalidRead(unresolvedKind: UnresolvedKind.Setter);
    }
    return new ExtensionIfNullSet.implicit(
      extension: extension,
      thisTypeArguments: _createThisTypeArguments(),
      thisAccess: _createThisAccess(),
      propertyName: targetName,
      getter: getter,
      rhs: value,
      setter: setter,
      forEffect: voidContext,
      readOffset: fileOffset,
      binaryOffset: offset,
      writeOffset: fileOffset,
    )..fileOffset = offset;
  }

  @override
  Expression buildCompoundAssignment(
    Name binaryOperator,
    Expression value, {
    required int operatorOffset,
    bool voidContext = false,
    bool isPreIncDec = false,
    bool isPostIncDec = false,
  }) {
    Procedure? getter = readTarget;
    Procedure? setter = writeTarget;
    // Coverage-ignore(suite): Not run.
    if (getter == null) {
      return _makeInvalidRead(unresolvedKind: UnresolvedKind.Getter);
    } else if (setter == null) {
      return _makeInvalidRead(unresolvedKind: UnresolvedKind.Setter);
    }
    return new ExtensionCompoundSet.implicit(
      extension: extension,
      thisTypeArguments: _createThisTypeArguments(),
      thisAccess: _createThisAccess(),
      propertyName: targetName,
      getter: getter,
      binaryName: binaryOperator,
      rhs: value,
      setter: setter,
      forEffect: voidContext,
      readOffset: fileOffset,
      binaryOffset: operatorOffset,
      writeOffset: fileOffset,
    );
  }

  Expression _buildPrePostfixIncrement(
    Name binaryOperator, {
    required int operatorOffset,
    required bool forEffect,
    required bool isPost,
  }) {
    Procedure? getter = readTarget;
    Procedure? setter = writeTarget;
    // Coverage-ignore(suite): Not run.
    if (getter == null) {
      return _makeInvalidRead(unresolvedKind: UnresolvedKind.Getter);
    } else if (setter == null) {
      return _makeInvalidRead(unresolvedKind: UnresolvedKind.Setter);
    }
    return new ExtensionIncDec.implicit(
      extension: extension,
      thisTypeArguments: _createThisTypeArguments(),
      thisAccess: _createThisAccess(),
      name: targetName,
      getter: getter,
      setter: setter,
      isPost: isPost,
      isInc: binaryOperator == plusName,
      forEffect: forEffect,
    )..fileOffset = operatorOffset;
  }

  @override
  Expression buildPrefixIncrement(
    Name binaryOperator, {
    required int operatorOffset,
    bool voidContext = false,
  }) {
    return _buildPrePostfixIncrement(
      binaryOperator,
      operatorOffset: operatorOffset,
      forEffect: voidContext,
      isPost: false,
    );
  }

  @override
  Expression buildPostfixIncrement(
    Name binaryOperator, {
    required int operatorOffset,
    bool voidContext = false,
  }) {
    return _buildPrePostfixIncrement(
      binaryOperator,
      operatorOffset: operatorOffset,
      forEffect: voidContext,
      isPost: true,
    );
  }

  @override
  Expression doInvocation({
    required int offset,
    required List<TypeBuilder>? typeArgumentBuilders,
    required TypeArguments? typeArguments,
    required ActualArguments arguments,
    bool isTypeArgumentsInForest = false,
  }) {
    Procedure? method = invokeTarget;
    Procedure? getter = readTarget;
    if (method != null) {
      Expression thisAccess = _createThisAccess();
      List<TypeParameter> typeParameters = method.function.typeParameters;
      LocatedMessage? argMessage = problemReporting.checkArgumentsForFunction(
        function: method.function,
        explicitTypeArguments: typeArguments,
        arguments: arguments,
        fileOffset: offset,
        fileUri: _fileUri,
        typeParameters: typeParameters,
        extension: extension,
      );
      if (argMessage != null) {
        // Coverage-ignore-block(suite): Not run.
        return problemReporting.buildProblemWithContextFromMember(
          compilerContext: compilerContext,
          name: targetName.text,
          member: method,
          message: argMessage,
          fileUri: _fileUri,
        );
      }
      return new ExtensionMethodInvocation.implicit(
        extension: extension,
        thisTypeArguments: _createThisTypeArguments(),
        thisAccess: thisAccess,
        name: targetName,
        target: method,
        typeArguments: typeArguments,
        arguments: arguments,
      )..fileOffset = fileOffset;
    } else if (getter != null) {
      Expression thisAccess = _createThisAccess();
      return new ExtensionGetterInvocation.implicit(
        extension: extension,
        thisTypeArguments: _createThisTypeArguments(),
        thisAccess: thisAccess,
        name: targetName,
        target: getter,
        typeArguments: typeArguments,
        arguments: arguments,
      )..fileOffset = fileOffset;
    } else {
      return _makeInvalidRead(unresolvedKind: UnresolvedKind.Getter);
    }
  }

  @override
  // Coverage-ignore(suite): Not run.
  Generator buildIndexedAccess(
    Expression index,
    Token token, {
    required bool isNullAware,
  }) {
    return new IndexedAccessGenerator(
      _helper,
      token,
      buildSimpleRead(),
      index,
      isNullAware: isNullAware,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  void printOn(StringSink sink) {
    sink.write(", targetName: ");
    sink.write(targetName);
    sink.write(", readTarget: ");
    printQualifiedNameOn(readTarget, sink);
    sink.write(", writeTarget: ");
    printQualifiedNameOn(writeTarget, sink);
  }
}

/// An [ExplicitExtensionInstanceAccessGenerator] represents a subexpression
/// whose prefix is a forced extension instance member access.
///
/// For instance
///
///   class A<T> {}
///   extension B on A<int> {
///     method() {}
///   }
///   extension C<T> {
///     T get field => 0;
///     set field(T _) {}
///   }
///
///   method(A a) {
///     B(a).method;     // this generator is created for `B(a).method`.
///     B(a).method();   // this generator is created for `B(a).method`.
///     C<int>(a).field; // this generator is created for `C<int>(a).field`.
///     C(a).field = 0;  // this generator is created for `C(a).field`.
///   }
///
class ExplicitExtensionInstanceAccessGenerator extends Generator {
  /// The file offset used for the explicit extension application type
  /// arguments.
  final int? extensionTypeArgumentOffset;

  final Extension extension;

  /// The name of the original target;
  final Name targetName;

  /// The static [Member] generated for an instance extension member which is
  /// used for performing a read on this subexpression.
  ///
  /// This can be `null` if the subexpression doesn't have a readable target.
  /// For instance if the subexpression is a setter without a corresponding
  /// getter.
  final Procedure? readTarget;

  /// The static [Member] generated for an instance extension member which is
  /// used for performing an invocation on this subexpression.
  ///
  /// This can be `null` if the subexpression doesn't have an invokable target.
  /// For instance if the subexpression is a getter or setter.
  final Procedure? invokeTarget;

  /// The static [Member] generated for an instance extension member which is
  /// used for performing a write on this subexpression.
  ///
  /// This can be `null` if the subexpression doesn't have a writable target.
  /// For instance if the subexpression is a final field, a method, or a getter
  /// without a corresponding setter.
  final Procedure? writeTarget;

  /// The expression holding the receiver value for the explicit extension
  /// access, that is, `a` in `Extension<int>(a).method<String>()`.
  final Expression receiver;

  /// The type arguments explicitly passed to the explicit extension access,
  /// like `<int>` in `Extension<int>(a).method<String>()`.
  final TypeArguments? explicitTypeArguments;

  /// The number of type parameters declared on the extension declaration.
  final int extensionTypeParameterCount;

  /// If `true` the access is null-aware, like `Extension(c)?.foo`.
  final bool isNullAware;

  ExplicitExtensionInstanceAccessGenerator(
    ExpressionGeneratorHelper helper,
    Token token,
    this.extensionTypeArgumentOffset,
    this.extension,
    this.targetName,
    this.readTarget,
    this.invokeTarget,
    this.writeTarget,
    this.receiver,
    this.explicitTypeArguments,
    this.extensionTypeParameterCount, {
    required this.isNullAware,
  }) : assert(
         readTarget != null || invokeTarget != null || writeTarget != null,
       ),
       super(helper, token);

  factory ExplicitExtensionInstanceAccessGenerator.fromBuilder({
    required ExpressionGeneratorHelper helper,
    required Token token,
    required int? extensionTypeArgumentOffset,
    required Extension extension,
    required Name name,
    required MemberBuilder? getter,
    required MemberBuilder? setter,
    required Expression receiver,
    required TypeArguments? explicitTypeArguments,
    required int extensionTypeParameterCount,
    required bool isNullAware,
  }) {
    assert(getter != null || setter != null);
    Procedure? readTarget;
    Procedure? invokeTarget;
    if (getter != null) {
      assert(!getter.isStatic);
      if (getter is PropertyBuilder) {
        readTarget = getter.readTarget as Procedure?;
      } else if (getter is MethodBuilder) {
        if (getter.isOperator) {
          invokeTarget = getter.invokeTarget as Procedure?;
        } else {
          readTarget = getter.readTarget as Procedure?;
          invokeTarget = getter.invokeTarget as Procedure?;
        }
      } else {
        return unhandled(
          "$getter (${getter.runtimeType})",
          "InstanceExtensionAccessGenerator.fromBuilder",
          offsetForToken(token),
          helper.uri,
        );
      }
    }
    Procedure? writeTarget;
    if (setter != null) {
      assert(!setter.isStatic);
      if (setter is PropertyBuilder) {
        if (setter.hasSetter) {
          writeTarget = setter.writeTarget as Procedure?;
        }
      } else {
        return unhandled(
          "$setter (${setter.runtimeType})",
          "InstanceExtensionAccessGenerator.fromBuilder",
          offsetForToken(token),
          helper.uri,
        );
      }
    }
    return new ExplicitExtensionInstanceAccessGenerator(
      helper,
      token,
      extensionTypeArgumentOffset,
      extension,
      name,
      readTarget,
      invokeTarget,
      writeTarget,
      receiver,
      explicitTypeArguments,
      extensionTypeParameterCount,
      isNullAware: isNullAware,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  String get _debugName => "ExplicitExtensionIndexedAccessGenerator";

  @override
  String get _plainNameForRead => targetName.text;

  /// Returns `true` if performing a read operation is a tear off.
  ///
  /// This is the case if [invokeTarget] is non-null, since extension methods
  /// have both a [readTarget] and an [invokeTarget], whereas extension getters
  /// only have a [readTarget].
  bool get isReadTearOff => invokeTarget != null;

  @override
  Expression buildSimpleRead() {
    return _createRead(receiver, isNullAware: isNullAware);
  }

  Expression _createRead(Expression receiver, {required bool isNullAware}) {
    Procedure? getter = readTarget;
    if (getter == null) {
      // Coverage-ignore-block(suite): Not run.
      return _makeInvalidRead(unresolvedKind: UnresolvedKind.Getter);
    } else if (isReadTearOff) {
      return new ExtensionTearOff.explicit(
        extension: extension,
        explicitTypeArguments: explicitTypeArguments?.types,
        receiver: receiver,
        name: targetName,
        tearOff: getter,
        isNullAware: isNullAware,
        extensionTypeArgumentOffset: extensionTypeArgumentOffset,
      )..fileOffset = fileOffset;
    } else {
      return new ExtensionGet.explicit(
        extension: extension,
        explicitTypeArguments: explicitTypeArguments?.types,
        receiver: receiver,
        name: targetName,
        getter: getter,
        isNullAware: isNullAware,
        extensionTypeArgumentOffset: extensionTypeArgumentOffset,
      )..fileOffset = fileOffset;
    }
  }

  @override
  Expression buildAssignment(Expression value, {bool voidContext = false}) {
    return _createWrite(
      fileOffset,
      receiver,
      value,
      forEffect: voidContext,
      isNullAware: isNullAware,
    );
  }

  Expression _createWrite(
    int offset,
    Expression receiver,
    Expression value, {
    required bool forEffect,
    required bool isNullAware,
  }) {
    Procedure? setter = writeTarget;
    if (setter == null) {
      // Coverage-ignore-block(suite): Not run.
      return _makeInvalidWrite();
    } else {
      return new ExtensionSet.explicit(
        extension: extension,
        explicitTypeArguments: explicitTypeArguments?.types,
        receiver: receiver,
        name: targetName,
        setter: setter,
        value: value,
        forEffect: forEffect,
        isNullAware: isNullAware,
        extensionTypeArgumentOffset: extensionTypeArgumentOffset,
      )..fileOffset = offset;
    }
  }

  @override
  Expression buildIfNullAssignment(
    Expression value,
    DartType type,
    int offset, {
    bool voidContext = false,
  }) {
    Procedure? getter = readTarget;
    Procedure? setter = writeTarget;
    // Coverage-ignore(suite): Not run.
    if (getter == null) {
      return _makeInvalidRead(unresolvedKind: UnresolvedKind.Getter);
    } else if (setter == null) {
      return _makeInvalidRead(unresolvedKind: UnresolvedKind.Setter);
    }
    return new ExtensionIfNullSet.explicit(
      extension: extension,
      explicitTypeArguments: explicitTypeArguments?.types,
      receiver: receiver,
      propertyName: targetName,
      getter: getter,
      rhs: value,
      setter: setter,
      forEffect: voidContext,
      readOffset: fileOffset,
      binaryOffset: offset,
      writeOffset: fileOffset,
      isNullAware: isNullAware,
      extensionTypeArgumentOffset: extensionTypeArgumentOffset,
    )..fileOffset = offset;
  }

  @override
  Expression buildCompoundAssignment(
    Name binaryOperator,
    Expression value, {
    required int operatorOffset,
    bool voidContext = false,
    bool isPreIncDec = false,
    bool isPostIncDec = false,
  }) {
    Procedure? getter = readTarget;
    Procedure? setter = writeTarget;
    // Coverage-ignore(suite): Not run.
    if (getter == null) {
      return _makeInvalidRead(unresolvedKind: UnresolvedKind.Getter);
    } else if (setter == null) {
      return _makeInvalidRead(unresolvedKind: UnresolvedKind.Setter);
    }
    return new ExtensionCompoundSet.explicit(
      extension: extension,
      explicitTypeArguments: explicitTypeArguments?.types,
      receiver: receiver,
      propertyName: targetName,
      getter: getter,
      binaryName: binaryOperator,
      rhs: value,
      setter: setter,
      forEffect: voidContext,
      readOffset: fileOffset,
      binaryOffset: operatorOffset,
      writeOffset: fileOffset,
      isNullAware: isNullAware,
      extensionTypeArgumentOffset: extensionTypeArgumentOffset,
    )..fileOffset = operatorOffset;
  }

  Expression _buildPrePostfixIncrement(
    Name binaryOperator, {
    required int operatorOffset,
    required bool forEffect,
    required bool isPost,
  }) {
    Procedure? getter = readTarget;
    Procedure? setter = writeTarget;
    if (getter == null) {
      // Coverage-ignore-block(suite): Not run.
      return _makeInvalidRead(unresolvedKind: UnresolvedKind.Getter);
    } else if (setter == null) {
      return _makeInvalidRead(unresolvedKind: UnresolvedKind.Setter);
    }
    return new ExtensionIncDec.explicit(
      extension: extension,
      explicitTypeArguments: explicitTypeArguments?.types,
      receiver: receiver,
      name: targetName,
      getter: getter,
      setter: setter,
      isPost: isPost,
      isInc: binaryOperator == plusName,
      forEffect: forEffect,
      isNullAware: isNullAware,
      extensionTypeArgumentOffset: extensionTypeArgumentOffset,
    )..fileOffset = operatorOffset;
  }

  @override
  Expression buildPrefixIncrement(
    Name binaryOperator, {
    required int operatorOffset,
    bool voidContext = false,
  }) {
    return _buildPrePostfixIncrement(
      binaryOperator,
      operatorOffset: operatorOffset,
      forEffect: voidContext,
      isPost: false,
    );
  }

  @override
  Expression buildPostfixIncrement(
    Name binaryOperator, {
    required int operatorOffset,
    bool voidContext = false,
  }) {
    return _buildPrePostfixIncrement(
      binaryOperator,
      operatorOffset: operatorOffset,
      forEffect: voidContext,
      isPost: true,
    );
  }

  @override
  Expression doInvocation({
    required int offset,
    required List<TypeBuilder>? typeArgumentBuilders,
    required TypeArguments? typeArguments,
    required ActualArguments arguments,
    bool isTypeArgumentsInForest = false,
  }) {
    Procedure? method = invokeTarget;
    Procedure? getter = readTarget;
    if (method != null) {
      List<TypeParameter> typeParameters = method.function.typeParameters;
      LocatedMessage? argMessage = problemReporting.checkArgumentsForFunction(
        function: method.function,
        explicitTypeArguments: typeArguments,
        arguments: arguments,
        fileOffset: offset,
        fileUri: _fileUri,
        typeParameters: typeParameters,
        extension: extension,
      );
      if (argMessage != null) {
        return problemReporting.buildProblemWithContextFromMember(
          compilerContext: compilerContext,
          name: targetName.text,
          member: method,
          message: argMessage,
          fileUri: _fileUri,
        );
      }
      return new ExtensionMethodInvocation.explicit(
        extension: extension,
        explicitTypeArguments: explicitTypeArguments?.types,
        receiver: receiver,
        name: targetName,
        target: method,
        typeArguments: typeArguments,
        arguments: arguments,
        isNullAware: isNullAware,
        extensionTypeArgumentOffset: extensionTypeArgumentOffset,
      )..fileOffset = fileOffset;
    } else if (getter != null) {
      return new ExtensionGetterInvocation.explicit(
        extension: extension,
        explicitTypeArguments: explicitTypeArguments?.types,
        receiver: receiver,
        name: targetName,
        target: getter,
        typeArguments: typeArguments,
        arguments: arguments,
        isNullAware: isNullAware,
        extensionTypeArgumentOffset: extensionTypeArgumentOffset,
      )..fileOffset = fileOffset;
    } else {
      return _makeInvalidRead(unresolvedKind: UnresolvedKind.Getter);
    }
  }

  @override
  Generator buildIndexedAccess(
    Expression index,
    Token token, {
    required bool isNullAware,
  }) {
    return new IndexedAccessGenerator(
      _helper,
      token,
      buildSimpleRead(),
      index,
      isNullAware: isNullAware,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  void printOn(StringSink sink) {
    sink.write(", targetName: ");
    sink.write(targetName);
    sink.write(", readTarget: ");
    printQualifiedNameOn(readTarget, sink);
    sink.write(", writeTarget: ");
    printQualifiedNameOn(writeTarget, sink);
  }
}

class ExplicitExtensionIndexedAccessGenerator extends Generator {
  /// The file offset used for the explicit extension application type
  /// arguments.
  final int? extensionTypeArgumentOffset;

  final Extension extension;

  /// The static [Member] generated for the [] operation.
  ///
  /// This can be `null` if the extension doesn't have an [] method.
  final Procedure? readTarget;

  /// The static [Member] generated for the []= operation.
  ///
  /// This can be `null` if the extension doesn't have an []= method.
  final Procedure? writeTarget;

  /// The expression holding the receiver value for the explicit extension
  /// access, that is, `a` in `Extension<int>(a)[index]`.
  final Expression receiver;

  /// The index expression;
  final Expression index;

  /// The type arguments explicitly passed to the explicit extension access,
  /// like `<int>` in `Extension<int>(a)[b]`.
  final TypeArguments? explicitTypeArguments;

  /// The number of type parameters declared on the extension declaration.
  final int extensionTypeParameterCount;

  final bool isNullAware;

  ExplicitExtensionIndexedAccessGenerator(
    ExpressionGeneratorHelper helper,
    Token token,
    this.extensionTypeArgumentOffset,
    this.extension,
    this.readTarget,
    this.writeTarget,
    this.receiver,
    this.index,
    this.explicitTypeArguments,
    this.extensionTypeParameterCount, {
    required this.isNullAware,
  }) : assert(readTarget != null || writeTarget != null),
       super(helper, token);

  factory ExplicitExtensionIndexedAccessGenerator.fromBuilder(
    ExpressionGeneratorHelper helper,
    Token token,
    int? extensionTypeArgumentOffset,
    Extension extension,
    MemberBuilder? getterBuilder,
    MemberBuilder? setterBuilder,
    Expression receiver,
    Expression index,
    TypeArguments? explicitTypeArguments,
    int extensionTypeParameterCount, {
    required bool isNullAware,
  }) {
    Procedure? readTarget = getterBuilder?.invokeTarget as Procedure?;
    Procedure? writeTarget = setterBuilder?.invokeTarget as Procedure?;
    return new ExplicitExtensionIndexedAccessGenerator(
      helper,
      token,
      extensionTypeArgumentOffset,
      extension,
      readTarget,
      writeTarget,
      receiver,
      index,
      explicitTypeArguments,
      extensionTypeParameterCount,
      isNullAware: isNullAware,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  String get _plainNameForRead => "[]";

  @override
  // Coverage-ignore(suite): Not run.
  String get _debugName => "ExplicitExtensionIndexedAccessGenerator";

  @override
  Expression buildSimpleRead() {
    Procedure? getter = readTarget;
    if (getter == null) {
      // Coverage-ignore-block(suite): Not run.
      return _makeInvalidRead(unresolvedKind: UnresolvedKind.Method);
    }
    return new ExtensionIndexGet(
      extension,
      explicitTypeArguments,
      receiver,
      getter,
      index,
      isNullAware: isNullAware,
      extensionTypeArgumentOffset: extensionTypeArgumentOffset,
    )..fileOffset = fileOffset;
  }

  @override
  Expression buildAssignment(Expression value, {bool voidContext = false}) {
    Procedure? setter = writeTarget;
    if (setter == null) {
      // Coverage-ignore-block(suite): Not run.
      return _makeInvalidWrite();
    }
    return new ExtensionIndexSet(
      extension,
      explicitTypeArguments,
      receiver,
      setter,
      index,
      value,
      isNullAware: isNullAware,
      forEffect: voidContext,
      extensionTypeArgumentOffset: extensionTypeArgumentOffset,
    )..fileOffset = fileOffset;
  }

  @override
  Expression buildIfNullAssignment(
    Expression value,
    DartType type,
    int offset, {
    bool voidContext = false,
  }) {
    Procedure? getter = readTarget;
    Procedure? setter = writeTarget;
    // Coverage-ignore(suite): Not run.
    if (getter == null) {
      return _makeInvalidRead(unresolvedKind: UnresolvedKind.Member);
    } else if (setter == null) {
      return _makeInvalidRead(unresolvedKind: UnresolvedKind.Member);
    }

    return new ExtensionIfNullIndexSet(
      extension: extension,
      knownTypeArguments: explicitTypeArguments?.types,
      receiver: receiver,
      getter: getter,
      setter: setter,
      index: index,
      value: value,
      readOffset: fileOffset,
      testOffset: offset,
      writeOffset: fileOffset,
      forEffect: voidContext,
      isNullAware: isNullAware,
      extensionTypeArgumentOffset: extensionTypeArgumentOffset,
    )..fileOffset = offset;
  }

  @override
  Expression buildCompoundAssignment(
    Name binaryOperator,
    Expression value, {
    required int operatorOffset,
    bool voidContext = false,
    bool isPreIncDec = false,
    bool isPostIncDec = false,
  }) {
    Procedure? getter = readTarget;
    Procedure? setter = writeTarget;
    // Coverage-ignore(suite): Not run.
    if (getter == null) {
      return _makeInvalidRead(unresolvedKind: UnresolvedKind.Member);
    } else if (setter == null) {
      return _makeInvalidRead(unresolvedKind: UnresolvedKind.Member);
    }

    return new ExtensionCompoundIndexSet(
      extension: extension,
      explicitTypeArguments: explicitTypeArguments,
      receiver: receiver,
      getter: getter,
      setter: setter,
      index: index,
      binaryName: binaryOperator,
      rhs: value,
      readOffset: fileOffset,
      binaryOffset: operatorOffset,
      writeOffset: fileOffset,
      forEffect: voidContext,
      forPostIncDec: isPostIncDec,
      isNullAware: isNullAware,
      extensionTypeArgumentOffset: extensionTypeArgumentOffset,
    );
  }

  @override
  Expression buildPostfixIncrement(
    Name binaryOperator, {
    required int operatorOffset,
    bool voidContext = false,
  }) {
    Expression value = _forest.createIntLiteral(operatorOffset, 1);
    return buildCompoundAssignment(
      binaryOperator,
      value,
      operatorOffset: operatorOffset,
      voidContext: voidContext,
      isPostIncDec: true,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  Expression doInvocation({
    required int offset,
    required List<TypeBuilder>? typeArgumentBuilders,
    required TypeArguments? typeArguments,
    required ActualArguments arguments,
    bool isTypeArgumentsInForest = false,
  }) {
    return _helper.forest.createExpressionInvocation(
      offset,
      buildSimpleRead(),
      typeArguments,
      arguments,
    );
  }

  @override
  Generator buildIndexedAccess(
    Expression index,
    Token token, {
    required bool isNullAware,
  }) {
    return new IndexedAccessGenerator(
      _helper,
      token,
      buildSimpleRead(),
      index,
      isNullAware: isNullAware,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  void printOn(StringSink sink) {
    sink.write(", index: ");
    printNodeOn(index, sink);
    sink.write(", readTarget: ");
    printQualifiedNameOn(readTarget, sink);
    sink.write(", writeTarget: ");
    printQualifiedNameOn(writeTarget, sink);
  }
}

/// An [ExplicitExtensionAccessGenerator] represents a subexpression whose
/// prefix is an explicit extension application.
///
/// For instance
///
///   class A<T> {}
///   extension B on A<int> {
///     method() {}
///   }
///   extension C<T> on A<T> {
///     T get field => 0;
///     set field(T _) {}
///   }
///
///   method(A a) {
///     B(a).method;     // this generator is created for `B(a)`.
///     B(a).method();   // this generator is created for `B(a)`.
///     C<int>(a).field; // this generator is created for `C<int>(a)`.
///     C(a).field = 0;  // this generator is created for `C(a)`.
///   }
///
/// When an access is performed on this generator a
/// [ExplicitExtensionInstanceAccessGenerator] is created.
class ExplicitExtensionAccessGenerator extends Generator {
  final ExtensionBuilder extensionBuilder;
  final Expression receiver;
  final TypeArguments? explicitTypeArguments;
  final int? extensionTypeArgumentOffset;

  ExplicitExtensionAccessGenerator({
    required ExpressionGeneratorHelper helper,
    required Token token,
    required this.extensionBuilder,
    required this.receiver,
    required this.explicitTypeArguments,
    required this.extensionTypeArgumentOffset,
  }) : super(helper, token);

  @override
  // Coverage-ignore(suite): Not run.
  String get _plainNameForRead {
    return unsupported(
      "ExplicitExtensionAccessGenerator.plainNameForRead",
      fileOffset,
      _fileUri,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  String get _debugName => "ExplicitExtensionAccessGenerator";

  @override
  Expression buildSimpleRead() {
    return _makeInvalidRead();
  }

  @override
  // Coverage-ignore(suite): Not run.
  Expression buildAssignment(Expression value, {bool voidContext = false}) {
    return _makeInvalidWrite();
  }

  @override
  // Coverage-ignore(suite): Not run.
  Expression buildIfNullAssignment(
    Expression value,
    DartType type,
    int offset, {
    bool voidContext = false,
  }) {
    return _makeInvalidRead();
  }

  @override
  Expression buildCompoundAssignment(
    Name binaryOperator,
    Expression value, {
    required int operatorOffset,
    bool voidContext = false,
    bool isPreIncDec = false,
    bool isPostIncDec = false,
  }) {
    return _makeInvalidRead();
  }

  @override
  Expression buildPostfixIncrement(
    Name binaryOperator, {
    required int operatorOffset,
    bool voidContext = false,
  }) {
    return _makeInvalidRead();
  }

  Generator _createInstanceAccess(
    Token token,
    Name name, {
    bool isNullAware = false,
  }) {
    MemberLookupResult? result = extensionBuilder.lookupExtensionMemberByName(
      name,
    );
    if (result == null) {
      return new UnresolvedNameGenerator(
        _helper,
        token,
        name,
        unresolvedReadKind: UnresolvedKind.Member,
      );
    }
    if (result.isInvalidLookup) {
      return new UnresolvedNameGenerator(
        _helper,
        token,
        name,
        unresolvedReadKind: UnresolvedKind.Member,
        errorHasBeenReported: true,
      );
    }
    if (result.isStatic) {
      return new UnresolvedNameGenerator(
        _helper,
        token,
        name,
        unresolvedReadKind: UnresolvedKind.Member,
      );
    }
    return new ExplicitExtensionInstanceAccessGenerator.fromBuilder(
      helper: _helper,
      token: token,
      extensionTypeArgumentOffset: extensionTypeArgumentOffset,
      extension: extensionBuilder.extension,
      name: name,
      getter: result.getable,
      setter: result.setable,
      receiver: receiver,
      explicitTypeArguments: explicitTypeArguments,
      extensionTypeParameterCount: extensionBuilder.typeParameters?.length ?? 0,
      isNullAware: isNullAware,
    );
  }

  @override
  Expression_Generator buildSelectorAccess(
    Selector selector,
    int operatorOffset,
    bool isNullAware,
  ) {
    selector.reportNewAsSelector();
    if (_helper.constantContext != ConstantContext.none) {
      // Coverage-ignore-block(suite): Not run.
      problemReporting.addProblem(
        diag.notAConstantExpression,
        fileOffset,
        token.length,
        _fileUri,
      );
    }
    Generator generator = _createInstanceAccess(
      selector.token,
      selector.name,
      isNullAware: isNullAware,
    );
    if (selector.arguments != null) {
      return generator.doInvocation(
        offset: offsetForToken(selector.token),
        typeArgumentBuilders: selector.typeArgumentBuilders,
        typeArguments: selector.typeArguments,
        arguments: selector.arguments!,
        isTypeArgumentsInForest: selector.isTypeArgumentsInForest,
      );
    } else {
      return generator;
    }
  }

  @override
  Expression_Generator buildBinaryOperation(
    Token token,
    Name binaryName,
    Expression right,
  ) {
    int fileOffset = offsetForToken(token);
    Generator generator = _createInstanceAccess(token, binaryName);
    return generator.doInvocation(
      offset: fileOffset,
      typeArgumentBuilders: null,
      typeArguments: null,
      arguments: _forest.createArguments(
        fileOffset,
        arguments: [new PositionalArgument(right)],
        hasNamedBeforePositional: false,
        positionalCount: 1,
      ),
    );
  }

  @override
  Expression_Generator buildUnaryOperation(Token token, Name unaryName) {
    int fileOffset = offsetForToken(token);
    Generator generator = _createInstanceAccess(token, unaryName);
    return generator.doInvocation(
      offset: fileOffset,
      typeArgumentBuilders: null,
      typeArguments: null,
      arguments: _forest.createArgumentsEmpty(fileOffset),
    );
  }

  @override
  Expression_Generator_Initializer doInvocation({
    required int offset,
    required List<TypeBuilder>? typeArgumentBuilders,
    required TypeArguments? typeArguments,
    required ActualArguments arguments,
    bool isTypeArgumentsInForest = false,
  }) {
    Generator generator = _createInstanceAccess(token, callName);
    return generator.doInvocation(
      offset: offset,
      typeArgumentBuilders: typeArgumentBuilders,
      typeArguments: typeArguments,
      arguments: arguments,
      isTypeArgumentsInForest: isTypeArgumentsInForest,
    );
  }

  @override
  Expression _makeInvalidRead({
    UnresolvedKind? unresolvedKind,
    bool errorHasBeenReported = false,
  }) {
    return _helper.buildProblem(
      message: diag.explicitExtensionAsExpression,
      fileUri: _helper.uri,
      fileOffset: fileOffset,
      length: lengthForToken(token),
      errorHasBeenReported: errorHasBeenReported,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  Expression _makeInvalidWrite({bool errorHasBeenReported = false}) {
    return _helper.buildProblem(
      message: diag.explicitExtensionAsLvalue,
      fileUri: _helper.uri,
      fileOffset: fileOffset,
      length: lengthForToken(token),
    );
  }

  @override
  Generator buildIndexedAccess(
    Expression index,
    Token token, {
    required bool isNullAware,
  }) {
    MemberLookupResult? result = extensionBuilder.lookupExtensionMemberByName(
      indexGetName,
    );

    if (result == null) {
      // Coverage-ignore-block(suite): Not run.
      return new UnresolvedNameGenerator(
        _helper,
        token,
        indexGetName,
        unresolvedReadKind: UnresolvedKind.Method,
      );
    } else if (result.isInvalidLookup) {
      // Coverage-ignore-block(suite): Not run.
      return new UnresolvedNameGenerator(
        _helper,
        token,
        indexGetName,
        unresolvedReadKind: UnresolvedKind.Method,
        errorHasBeenReported: true,
      );
    }
    return new ExplicitExtensionIndexedAccessGenerator.fromBuilder(
      _helper,
      token,
      extensionTypeArgumentOffset,
      extensionBuilder.extension,
      result.getable,
      result.setable,
      receiver,
      index,
      explicitTypeArguments,
      extensionBuilder.typeParameters?.length ?? 0,
      isNullAware: isNullAware,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  void printOn(StringSink sink) {
    sink.write(", extensionBuilder: ");
    sink.write(extensionBuilder);
    sink.write(", receiver: ");
    sink.write(receiver);
  }
}

class LoadLibraryGenerator extends Generator {
  final LoadLibraryBuilder builder;

  LoadLibraryGenerator(
    ExpressionGeneratorHelper helper,
    Token token,
    this.builder,
  ) : super(helper, token);

  @override
  // Coverage-ignore(suite): Not run.
  String get _plainNameForRead => 'loadLibrary';

  @override
  // Coverage-ignore(suite): Not run.
  String get _debugName => "LoadLibraryGenerator";

  @override
  Expression buildSimpleRead() {
    builder.importDependency.targetLibrary;
    LoadLibraryTearOff read = new LoadLibraryTearOff(
      builder.importDependency,
      builder.createTearoffMethod(_helper.forest),
    )..fileOffset = fileOffset;
    return read;
  }

  @override
  // Coverage-ignore(suite): Not run.
  Expression buildAssignment(Expression value, {bool voidContext = false}) {
    return _makeInvalidWrite();
  }

  @override
  // Coverage-ignore(suite): Not run.
  Expression buildIfNullAssignment(
    Expression value,
    DartType type,
    int offset, {
    bool voidContext = false,
  }) {
    Expression read = buildSimpleRead();
    Expression write = _makeInvalidWrite();
    return new IfNullSet(read, write, forEffect: voidContext)
      ..fileOffset = offset;
  }

  @override
  // Coverage-ignore(suite): Not run.
  Expression buildCompoundAssignment(
    Name binaryOperator,
    Expression value, {
    required int operatorOffset,
    bool voidContext = false,
    bool isPreIncDec = false,
    bool isPostIncDec = false,
  }) {
    return _makeInvalidWrite();
  }

  @override
  // Coverage-ignore(suite): Not run.
  Expression buildPostfixIncrement(
    Name binaryOperator, {
    required int operatorOffset,
    bool voidContext = false,
  }) {
    Expression value = _forest.createIntLiteral(operatorOffset, 1);
    return buildCompoundAssignment(
      binaryOperator,
      value,
      operatorOffset: operatorOffset,
      voidContext: voidContext,
      isPostIncDec: true,
    );
  }

  @override
  Expression doInvocation({
    required int offset,
    required List<TypeBuilder>? typeArgumentBuilders,
    required TypeArguments? typeArguments,
    required ActualArguments arguments,
    bool isTypeArgumentsInForest = false,
  }) {
    if (arguments.positionalCount > 0 || arguments.namedCount > 0) {
      _helper.addProblemErrorIfConst(
        diag.loadLibraryTakesNoArguments,
        offset,
        'loadLibrary'.length,
      );
    }
    return builder.createLoadLibrary(offset, _forest, arguments);
  }

  @override
  // Coverage-ignore(suite): Not run.
  Generator buildIndexedAccess(
    Expression index,
    Token token, {
    required bool isNullAware,
  }) {
    return new IndexedAccessGenerator(
      _helper,
      token,
      buildSimpleRead(),
      index,
      isNullAware: isNullAware,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  void printOn(StringSink sink) {
    sink.write(", builder: ");
    sink.write(builder);
  }
}

class DeferredAccessGenerator extends Generator {
  final PrefixUseGenerator prefixGenerator;

  final Generator suffixGenerator;

  DeferredAccessGenerator(
    ExpressionGeneratorHelper helper,
    Token token,
    this.prefixGenerator,
    this.suffixGenerator,
  ) : super(helper, token);

  @override
  Expression buildSimpleRead() {
    return _helper.wrapInDeferredCheck(
      suffixGenerator.buildSimpleRead(),
      prefixGenerator.prefix,
      token.charOffset,
    );
  }

  @override
  Expression buildAssignment(Expression value, {bool voidContext = false}) {
    return _helper.wrapInDeferredCheck(
      suffixGenerator.buildAssignment(value, voidContext: voidContext),
      prefixGenerator.prefix,
      token.charOffset,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  Expression buildIfNullAssignment(
    Expression value,
    DartType type,
    int offset, {
    bool voidContext = false,
  }) {
    return _helper.wrapInDeferredCheck(
      suffixGenerator.buildIfNullAssignment(
        value,
        type,
        offset,
        voidContext: voidContext,
      ),
      prefixGenerator.prefix,
      token.charOffset,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  Expression buildCompoundAssignment(
    Name binaryOperator,
    Expression value, {
    required int operatorOffset,
    bool voidContext = false,
    bool isPreIncDec = false,
    bool isPostIncDec = false,
  }) {
    return _helper.wrapInDeferredCheck(
      suffixGenerator.buildCompoundAssignment(
        binaryOperator,
        value,
        operatorOffset: operatorOffset,
        voidContext: voidContext,
        isPreIncDec: isPreIncDec,
        isPostIncDec: isPostIncDec,
      ),
      prefixGenerator.prefix,
      token.charOffset,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  Expression buildPostfixIncrement(
    Name binaryOperator, {
    required int operatorOffset,
    bool voidContext = false,
  }) {
    return _helper.wrapInDeferredCheck(
      suffixGenerator.buildPostfixIncrement(
        binaryOperator,
        operatorOffset: operatorOffset,
        voidContext: voidContext,
      ),
      prefixGenerator.prefix,
      token.charOffset,
    );
  }

  @override
  Expression_Generator buildSelectorAccess(
    Selector selector,
    int operatorOffset,
    bool isNullAware,
  ) {
    selector.reportNewAsSelector();
    Object propertyAccess = suffixGenerator.buildSelectorAccess(
      selector,
      operatorOffset,
      isNullAware,
    );
    if (propertyAccess is Generator) {
      return new DeferredAccessGenerator(
        _helper,
        token,
        prefixGenerator,
        propertyAccess,
      );
    } else {
      Expression expression = propertyAccess as Expression;
      return _helper.wrapInDeferredCheck(
        expression,
        prefixGenerator.prefix,
        token.charOffset,
      );
    }
  }

  @override
  // Coverage-ignore(suite): Not run.
  String get _plainNameForRead {
    return unsupported(
      "deferredAccessor.plainNameForRead",
      fileOffset,
      _fileUri,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  String get _debugName => "DeferredAccessGenerator";

  @override
  TypeBuilder buildTypeWithResolvedArguments(
    NullabilityBuilder nullabilityBuilder,
    List<TypeBuilder>? arguments, {
    required bool allowPotentiallyConstantType,
    required bool performTypeCanonicalization,
  }) {
    String name =
        "${prefixGenerator._plainNameForRead}."
        "${suffixGenerator._plainNameForRead}";
    TypeBuilder type = suffixGenerator.buildTypeWithResolvedArguments(
      nullabilityBuilder,
      arguments,
      allowPotentiallyConstantType: allowPotentiallyConstantType,
      performTypeCanonicalization: performTypeCanonicalization,
    );
    LocatedMessage message;
    TypeDeclarationBuilder? declaration = type.declaration;
    if (declaration is InvalidBuilder) {
      // Coverage-ignore-block(suite): Not run.
      message = declaration.message;
    } else {
      int charOffset = offsetForToken(prefixGenerator.token);
      message = diag.deferredTypeAnnotation
          .withArgumentsOld(
            _helper.buildDartType(
              type,
              TypeUse.deferredTypeError,
              allowPotentiallyConstantType: allowPotentiallyConstantType,
            ),
            prefixGenerator._plainNameForRead,
          )
          .withLocation(
            _fileUri,
            charOffset,
            lengthOfSpan(prefixGenerator.token, token),
          );
    }
    _helper.libraryBuilder.addProblem(
      message.messageObject,
      message.charOffset,
      message.length,
      message.uri,
    );
    return new NamedTypeBuilderImpl.forInvalidType(
      name,
      nullabilityBuilder,
      message,
    );
  }

  @override
  Expression_Generator_Initializer doInvocation({
    required int offset,
    required List<TypeBuilder>? typeArgumentBuilders,
    required TypeArguments? typeArguments,
    required ActualArguments arguments,
    bool isTypeArgumentsInForest = false,
  }) {
    Object suffix = suffixGenerator.doInvocation(
      offset: offset,
      typeArgumentBuilders: typeArgumentBuilders,
      typeArguments: typeArguments,
      arguments: arguments,
      isTypeArgumentsInForest: isTypeArgumentsInForest,
    );
    if (suffix is Expression) {
      return _helper.wrapInDeferredCheck(
        suffix,
        prefixGenerator.prefix,
        fileOffset,
      );
    } else {
      return new DeferredAccessGenerator(
        _helper,
        token,
        prefixGenerator,
        suffix as Generator,
      );
    }
  }

  @override
  Expression invokeConstructor({
    required String name,
    required List<TypeBuilder>? typeArgumentBuilders,
    required TypeArguments? typeArguments,
    required ActualArguments arguments,
    required Token nameToken,
    required Token nameLastToken,
    required Constness constness,
    required bool inImplicitCreationContext,
  }) {
    return _helper.wrapInDeferredCheck(
      suffixGenerator.invokeConstructor(
        name: name,
        typeArgumentBuilders: typeArgumentBuilders,
        typeArguments: typeArguments,
        arguments: arguments,
        nameToken: nameToken,
        nameLastToken: nameLastToken,
        constness: constness,
        inImplicitCreationContext: inImplicitCreationContext,
      ),
      prefixGenerator.prefix,
      offsetForToken(suffixGenerator.token),
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  Generator buildIndexedAccess(
    Expression index,
    Token token, {
    required bool isNullAware,
  }) {
    return new IndexedAccessGenerator(
      _helper,
      token,
      buildSimpleRead(),
      index,
      isNullAware: isNullAware,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  void printOn(StringSink sink) {
    sink.write(", prefixGenerator: ");
    sink.write(prefixGenerator);
    sink.write(", suffixGenerator: ");
    sink.write(suffixGenerator);
  }
}

/// [TypeUseGenerator] represents the subexpression whose prefix is the name of
/// a class, enum, type parameter, typedef, mixin declaration, extension
/// declaration or built-in type, like dynamic and void.
///
/// For instance:
///
///   class A<T> {}
///   typedef B = Function();
///   mixin C<T> on A<T> {}
///   extension D<T> on A<T> {}
///
///   method<T>() {
///     C<B>        // a TypeUseGenerator is created for `C` and `B`.
///     B b;        // a TypeUseGenerator is created for `B`.
///     D.foo();    // a TypeUseGenerator is created for `D`.
///     new A<T>(); // a TypeUseGenerator is created for `A` and `T`.
///     T();        // a TypeUseGenerator is created for `T`.
///   }
///
class TypeUseGenerator extends AbstractReadOnlyAccessGenerator {
  final TypeDeclarationBuilder declaration;
  List<TypeBuilder>? typeArguments;

  final TypeName typeName;

  Expression? _expression;

  TypeUseGenerator(
    ExpressionGeneratorHelper helper,
    Token token,
    this.declaration,
    this.typeName,
  ) : super(
        helper,
        token,
        // TODO(johnniwinther): InvalidTypeDeclarationBuilder is currently
        // misused for import conflict.
        declaration is InvalidBuilder
            ? ReadOnlyAccessKind.InvalidDeclaration
            : ReadOnlyAccessKind.TypeLiteral,
      );

  @override
  String get targetName => typeName.name;

  @override
  // Coverage-ignore(suite): Not run.
  String get _debugName => "TypeUseGenerator";

  @override
  TypeBuilder buildTypeWithResolvedArguments(
    NullabilityBuilder nullabilityBuilder,
    List<TypeBuilder>? arguments, {
    required bool allowPotentiallyConstantType,
    required bool performTypeCanonicalization,
  }) {
    return new NamedTypeBuilderImpl(
      typeName,
      nullabilityBuilder,
      arguments: arguments,
      fileUri: _fileUri,
      charOffset: fileOffset,
      instanceTypeParameterAccess: _helper.instanceTypeParameterAccessState,
    )..bind(_helper.libraryBuilder, declaration);
  }

  @override
  Expression invokeConstructor({
    required String name,
    required List<TypeBuilder>? typeArgumentBuilders,
    required TypeArguments? typeArguments,
    required ActualArguments arguments,
    required Token nameToken,
    required Token nameLastToken,
    required Constness constness,
    required bool inImplicitCreationContext,
  }) {
    return switch (_helper.resolveAndBuildConstructorInvocation(
      declaration,
      nameToken,
      nameLastToken,
      arguments,
      name,
      typeArgumentBuilders,
      typeArguments,
      offsetForToken(nameToken),
      constness,
      unresolvedKind: UnresolvedKind.Constructor,
      isTypeArgumentsInForest: false,
    )) {
      SuccessfulConstructorResolutionResult(:var constructorInvocation) =>
        constructorInvocation,
      ErroneousConstructorResolutionResult(:var errorExpression) =>
        errorExpression,
      UnresolvedConstructorResolutionResult unresolvedResult =>
        unresolvedResult.buildErrorExpression(),
    };
  }

  @override
  // Coverage-ignore(suite): Not run.
  void printOn(StringSink sink) {
    sink.write(", declaration: ");
    sink.write(declaration);
    sink.write(", plainNameForRead: ");
    sink.write(_plainNameForRead);
  }

  @override
  Expression get expression {
    if (_expression == null) {
      if (declaration is InvalidBuilder) {
        InvalidBuilder declaration = this.declaration as InvalidBuilder;
        _expression = _helper.buildProblemErrorIfConst(
          declaration.message.messageObject,
          fileOffset,
          token.length,
        );
      } else {
        _expression = _forest.createTypeLiteral(
          offsetForToken(token),
          _helper.buildDartType(
            buildTypeWithResolvedArguments(
              const NullabilityBuilder.omitted(),
              typeArguments,
              allowPotentiallyConstantType: true,
              performTypeCanonicalization: true,
            ),
            TypeUse.typeLiteral,
            allowPotentiallyConstantType:
                _helper.libraryFeatures.constructorTearoffs.isEnabled,
          ),
        );
      }
    }
    return _expression!;
  }

  MemberLookupResult? _findStaticExtensionMember(Name name) {
    MemberLookupResult? memberLookupResult;
    _helper.extensionScope.forEachExtension((
      ExtensionBuilder extensionBuilder,
    ) {
      // TODO(cstefantsova): Report an error on more than one found members.
      if (extensionBuilder.onType.declaration == declaration) {
        memberLookupResult = extensionBuilder.lookupExtensionMemberByName(name);
        if (memberLookupResult != null) {
          if (!memberLookupResult!.isStatic) {
            memberLookupResult = null;
          }
        }
      }
    });
    return memberLookupResult;
  }

  @override
  Expression_Generator buildSelectorAccess(
    Selector send,
    int operatorOffset,
    bool isNullAware,
  ) {
    int nameOffset = offsetForToken(send.token);
    Name name = send.name;
    ActualArguments? arguments = send.arguments;

    TypeDeclarationBuilder? declarationBuilder = declaration;
    TypeAliasBuilder? aliasBuilder;
    List<TypeBuilder>? unaliasedTypeArguments;
    bool isGenericTypedefTearOff = false;
    if (declarationBuilder is TypeAliasBuilder) {
      aliasBuilder = declarationBuilder;
      declarationBuilder = aliasBuilder.unaliasDeclaration(
        null,
        isUsedAsClass: true,
        usedAsClassCharOffset: this.fileOffset,
        usedAsClassFileUri: _fileUri,
      );

      bool supportsConstructorTearOff =
          _helper.libraryFeatures.constructorTearoffs.isEnabled &&
          switch (declarationBuilder) {
            ClassBuilder() => true,
            ExtensionBuilder() => false,
            ExtensionTypeDeclarationBuilder() => true,
            // Coverage-ignore(suite): Not run.
            TypeAliasBuilder() => false,
            // Coverage-ignore(suite): Not run.
            NominalParameterBuilder() => false,
            // Coverage-ignore(suite): Not run.
            StructuralParameterBuilder() => false,
            // Coverage-ignore(suite): Not run.
            InvalidBuilder() => false,
            // Coverage-ignore(suite): Not run.
            BuiltinTypeDeclarationBuilder() => false,
            null => false,
          };
      bool isConstructorTearOff =
          send is PropertySelector && supportsConstructorTearOff;
      List<TypeBuilder>? aliasedTypeArguments = typeArguments
          ?.map(
            (unknownType) => _helper.validateTypeParameterUse(
              unknownType,
              allowPotentiallyConstantType: isConstructorTearOff,
            ),
          )
          .toList();
      if (aliasedTypeArguments != null &&
          aliasedTypeArguments.length != aliasBuilder.typeParametersCount) {
        // Coverage-ignore-block(suite): Not run.
        _helper.libraryBuilder.addProblem(
          diag.typeArgumentMismatch.withArgumentsOld(
            aliasBuilder.typeParametersCount,
          ),
          fileOffset,
          noLength,
          _fileUri,
        );
      } else {
        if (declarationBuilder is DeclarationBuilder) {
          if (aliasedTypeArguments != null) {
            new NamedTypeBuilderImpl(
                typeName,
                const NullabilityBuilder.omitted(),
                arguments: aliasedTypeArguments,
                fileUri: _fileUri,
                charOffset: fileOffset,
                instanceTypeParameterAccess:
                    _helper.instanceTypeParameterAccessState,
              )
              ..bind(_helper.libraryBuilder, aliasBuilder)
              ..build(_helper.libraryBuilder, TypeUse.instantiation);
          }

          // If the arguments weren't supplied, the tear off is treated as
          // generic, and the aliased type arguments match type parameters of
          // the type alias.
          if (aliasedTypeArguments == null &&
              aliasBuilder.typeParametersCount != 0) {
            isGenericTypedefTearOff = true;
            aliasedTypeArguments = <TypeBuilder>[];
            for (NominalParameterBuilder typeParameter
                in aliasBuilder.typeParameters!) {
              aliasedTypeArguments.add(
                new NamedTypeBuilderImpl(
                  new SyntheticTypeName(typeParameter.name, fileOffset),
                  const NullabilityBuilder.omitted(),
                  fileUri: _fileUri,
                  charOffset: fileOffset,
                  instanceTypeParameterAccess:
                      _helper.instanceTypeParameterAccessState,
                )..bind(_helper.libraryBuilder, typeParameter),
              );
            }
          }
          unaliasedTypeArguments = aliasBuilder.unaliasTypeArguments(
            aliasedTypeArguments,
          );
        }
      }
    }
    if (declarationBuilder is DeclarationBuilder) {
      MemberLookupResult? result = declarationBuilder.findStaticBuilder(
        name.text,
        nameOffset,
        _fileUri,
        _helper.libraryBuilder,
      );
      if (result != null && result.isInvalidLookup) {
        return new DuplicateDeclarationGenerator(
          _helper,
          send.token,
          result,
          name,
          name.text.length,
        );
      }

      Generator generator;
      bool supportsConstructorTearOff =
          _helper.libraryFeatures.constructorTearoffs.isEnabled &&
          switch (declarationBuilder) {
            ClassBuilder() => true,
            ExtensionBuilder() => false,
            ExtensionTypeDeclarationBuilder() => true,
          };

      if (result == null) {
        // TODO(johnniwinther): Update the comment below.
        // If we find a setter, [member] is a [SourcePropertyBuilder] or an
        // [AccessErrorBuilder], not null.
        if (send is PropertySelector) {
          assert(
            send.typeArgumentBuilders == null,
            "Unexpected non-null typeArguments of "
            "an IncompletePropertyAccessGenerator object: "
            "'${send.typeArgumentBuilders.runtimeType}'.",
          );
          if (supportsConstructorTearOff) {
            MemberLookupResult? result = declarationBuilder
                .findConstructorOrFactory(name.text, _helper.libraryBuilder);
            Expression? tearOffExpression;
            if (result != null && !result.isInvalidLookup) {
              MemberBuilder? constructor = result.getable;
              Member? tearOff = constructor?.readTarget;
              if (tearOff is Constructor) {
                if (declarationBuilder is ClassBuilder &&
                    declarationBuilder.isAbstract) {
                  return _helper.buildProblem(
                    message: diag.abstractClassConstructorTearOff,
                    fileUri: _helper.uri,
                    fileOffset: nameOffset,
                    length: name.text.length,
                  );
                } else if (declarationBuilder.isEnum) {
                  return _helper.buildProblem(
                    message: diag.enumConstructorTearoff,
                    fileUri: _helper.uri,
                    fileOffset: nameOffset,
                    length: name.text.length,
                  );
                }
                tearOffExpression = _helper.forest.createConstructorTearOff(
                  token.charOffset,
                  tearOff,
                );
              } else if (tearOff is Procedure) {
                if (tearOff.isRedirectingFactory) {
                  tearOffExpression = _helper.forest
                      .createRedirectingFactoryTearOff(
                        token.charOffset,
                        tearOff,
                      );
                } else if (tearOff.isFactory) {
                  tearOffExpression = _helper.forest.createConstructorTearOff(
                    token.charOffset,
                    tearOff,
                  );
                } else {
                  tearOffExpression = _helper.forest.createStaticTearOff(
                    token.charOffset,
                    tearOff,
                  );
                }
              } else if (tearOff != null) {
                unhandled(
                  "${tearOff.runtimeType}",
                  "buildPropertyAccess",
                  operatorOffset,
                  _helper.uri,
                );
              }
            }
            if (tearOffExpression != null) {
              List<DartType>? builtTypeArguments;
              if (unaliasedTypeArguments != null) {
                if (unaliasedTypeArguments.length !=
                    declarationBuilder.typeParametersCount) {
                  // The type arguments are either aren't provided or mismatch
                  // in number with the type parameters of the RHS declaration.
                  // We substitute them with the default types here: in the
                  // first case that would be exactly what type inference fills
                  // in for the RHS, and in the second case it's a reasonable
                  // fallback, as the error is reported during a check on the
                  // typedef.
                  builtTypeArguments = <DartType>[];
                  switch (declarationBuilder) {
                    case ClassBuilder():
                      for (TypeParameter typeParameter
                          in declarationBuilder.cls.typeParameters) {
                        builtTypeArguments.add(typeParameter.defaultType);
                      }
                    // Coverage-ignore(suite): Not run.
                    case ExtensionTypeDeclarationBuilder():
                      for (TypeParameter typeParameter
                          in declarationBuilder
                              .extensionTypeDeclaration
                              .typeParameters) {
                        builtTypeArguments.add(typeParameter.defaultType);
                      }
                    // Coverage-ignore(suite): Not run.
                    case ExtensionBuilder():
                      throw new UnsupportedError(
                        "Unexpected declaration $declarationBuilder",
                      );
                  }
                } else {
                  builtTypeArguments = unaliasTypes(
                    declarationBuilder.buildAliasedTypeArguments(
                      _helper.libraryBuilder,
                      unaliasedTypeArguments,
                      /* hierarchy = */ null,
                    ),
                  )!;
                }
              } else if (typeArguments != null) {
                builtTypeArguments = _helper.buildDartTypeArguments(
                  typeArguments,
                  TypeUse.tearOffTypeArgument,
                  allowPotentiallyConstantType: true,
                );
              }
              if (isGenericTypedefTearOff) {
                if (isProperRenameForTypeDeclaration(
                  _helper.typeEnvironment,
                  aliasBuilder!.typedef,
                  aliasBuilder.libraryBuilder.library,
                )) {
                  return tearOffExpression;
                }
                Procedure? tearOffLowering = aliasBuilder
                    .findConstructorOrFactory(
                      name.text,
                      nameOffset,
                      _fileUri,
                      _helper.libraryBuilder,
                    );
                if (tearOffLowering != null) {
                  if (tearOffLowering.isFactory) {
                    // Coverage-ignore-block(suite): Not run.
                    return _helper.forest.createConstructorTearOff(
                      token.charOffset,
                      tearOffLowering,
                    );
                  } else {
                    return _helper.forest.createStaticTearOff(
                      token.charOffset,
                      tearOffLowering,
                    );
                  }
                }
                FreshStructuralParametersFromTypeParameters
                freshTypeParameters =
                    getFreshStructuralParametersFromTypeParameters(
                      aliasBuilder.typedef.typeParameters,
                    );
                List<DartType>? substitutedTypeArguments;
                if (builtTypeArguments != null) {
                  substitutedTypeArguments = <DartType>[];
                  for (DartType builtTypeArgument in builtTypeArguments) {
                    substitutedTypeArguments.add(
                      freshTypeParameters.substitute(builtTypeArgument),
                    );
                  }
                }
                substitutedTypeArguments = unaliasTypes(
                  substitutedTypeArguments,
                );

                tearOffExpression = _helper.forest.createTypedefTearOff(
                  token.charOffset,
                  freshTypeParameters.freshTypeParameters,
                  tearOffExpression,
                  substitutedTypeArguments ?? const <DartType>[],
                );
              } else {
                if (builtTypeArguments != null &&
                    builtTypeArguments.isNotEmpty) {
                  builtTypeArguments = unaliasTypes(builtTypeArguments)!;

                  tearOffExpression = _helper.forest.createInstantiation(
                    token.charOffset,
                    tearOffExpression,
                    builtTypeArguments,
                  );
                }
              }
              return tearOffExpression;
            }
          }

          MemberLookupResult? memberLookupResult =
              _helper.libraryFeatures.staticExtensions.isEnabled
              ? _findStaticExtensionMember(name)
              : null;
          if (memberLookupResult != null) {
            if (memberLookupResult.isInvalidLookup) {
              // Coverage-ignore-block(suite): Not run.
              generator = new UnresolvedNameGenerator(
                _helper,
                send.token,
                name,
                unresolvedReadKind: UnresolvedKind.Member,
                errorHasBeenReported: true,
              );
            } else {
              generator = new StaticAccessGenerator.fromBuilder(
                _helper,
                name,
                send.token,
                memberLookupResult.getable,
                memberLookupResult.setable,
                typeOffset: fileOffset,
                isNullAware: isNullAware,
              );
            }
          } else {
            generator = new UnresolvedNameGenerator(
              _helper,
              send.token,
              name,
              unresolvedReadKind: UnresolvedKind.Member,
            );
          }
        } else {
          switch (_helper.resolveAndBuildConstructorInvocation(
            declarationBuilder,
            send.token,
            send.token,
            arguments!,
            name.text,
            send.typeArgumentBuilders,
            send.typeArguments,
            token.charOffset,
            Constness.implicit,
            isTypeArgumentsInForest: send.isTypeArgumentsInForest,
            typeAliasBuilder: aliasBuilder,
            unresolvedKind: isNullAware
                ? UnresolvedKind.Method
                : UnresolvedKind.Member,
          )) {
            case SuccessfulConstructorResolutionResult(
              :var constructorInvocation,
            ):
              return constructorInvocation;
            case ErroneousConstructorResolutionResult(
              // Coverage-ignore(suite): Not run.
              :var errorExpression,
            ):
              return errorExpression;
            case UnresolvedConstructorResolutionResult unresolvedResult:
              MemberLookupResult? memberLookupResult =
                  _helper.libraryFeatures.staticExtensions.isEnabled
                  ? _findStaticExtensionMember(name)
                  : null;
              if (memberLookupResult != null) {
                if (memberLookupResult.isInvalidLookup) {
                  // Coverage-ignore-block(suite): Not run.
                  generator = new UnresolvedNameGenerator(
                    _helper,
                    send.token,
                    name,
                    unresolvedReadKind: UnresolvedKind.Member,
                    errorHasBeenReported: true,
                  );
                } else {
                  generator = new StaticAccessGenerator.fromBuilder(
                    _helper,
                    name,
                    send.token,
                    memberLookupResult.getable,
                    memberLookupResult.setable,
                    typeOffset: fileOffset,
                    isNullAware: isNullAware,
                  );
                }
              } else {
                return unresolvedResult.buildErrorExpression();
              }
          }
        }
      } else {
        Builder? getable = result.getable;
        Builder? setable = result.setable;
        if (getable != null) {
          if (getable.isStatic &&
              getable is! FactoryBuilder &&
              typeArguments != null) {
            return _helper.buildProblem(
              message: diag.staticTearOffFromInstantiatedClass,
              fileUri: _helper.uri,
              fileOffset: send.fileOffset,
              length: send.name.text.length,
            );
          } else {
            generator = new StaticAccessGenerator.fromBuilder(
              _helper,
              name,
              send.token,
              getable is MemberBuilder ? getable : null,
              setable is MemberBuilder ? setable : null,
              typeOffset: fileOffset,
              isNullAware: isNullAware,
            );
          }
        } else {
          generator = new StaticAccessGenerator.fromBuilder(
            _helper,
            name,
            send.token,
            getable is MemberBuilder ? getable : null,
            setable is MemberBuilder ? setable : null,
            typeOffset: fileOffset,
            isNullAware: isNullAware,
          );
        }
      }

      return arguments == null
          ? generator
          : generator.doInvocation(
              offset: offsetForToken(send.token),
              typeArgumentBuilders: send.typeArgumentBuilders,
              typeArguments: send.typeArguments,
              arguments: arguments,
              isTypeArgumentsInForest: send.isTypeArgumentsInForest,
            );
    } else {
      // `SomeType?.toString` is the same as `SomeType.toString`, not
      // `(SomeType).toString`.
      return super.buildSelectorAccess(send, operatorOffset, isNullAware);
    }
  }

  @override
  Expression_Generator_Builder doInvocation({
    required int offset,
    required List<TypeBuilder>? typeArgumentBuilders,
    required TypeArguments? typeArguments,
    required ActualArguments arguments,
    bool isTypeArgumentsInForest = false,
  }) {
    if (declaration is ExtensionBuilder) {
      ExtensionBuilder extensionBuilder = declaration as ExtensionBuilder;
      if (arguments.positionalCount != 1 || arguments.namedCount > 0) {
        return _helper.buildProblem(
          message: diag.explicitExtensionArgumentMismatch,
          fileUri: _helper.uri,
          fileOffset: fileOffset,
          length: lengthForToken(token),
        );
      }
      int? extensionTypeArgumentOffset;
      if (typeArguments != null) {
        int typeParameterCount = extensionBuilder.typeParameters?.length ?? 0;
        if (typeArguments.types.length != typeParameterCount) {
          return _helper.buildProblem(
            message: diag.explicitExtensionTypeArgumentMismatch
                .withArgumentsOld(extensionBuilder.name, typeParameterCount),
            fileUri: _helper.uri,
            fileOffset: fileOffset,
            length: lengthForToken(token),
          );
        }
        // TODO(johnniwinther): Provide the type arguments offsets.
        extensionTypeArgumentOffset = arguments.fileOffset;
      }
      // TODO(johnniwinther): Check argument and type argument count.
      return new ExplicitExtensionAccessGenerator(
        helper: _helper,
        token: token,
        extensionBuilder: declaration as ExtensionBuilder,
        receiver: arguments.argumentList.single.expression,
        explicitTypeArguments: typeArguments,
        extensionTypeArgumentOffset: extensionTypeArgumentOffset,
      );
    } else {
      return switch (_helper.resolveAndBuildConstructorInvocation(
        declaration,
        token,
        token,
        arguments,
        "",
        typeArgumentBuilders,
        typeArguments,
        token.charOffset,
        Constness.implicit,
        isTypeArgumentsInForest: isTypeArgumentsInForest,
        unresolvedKind: UnresolvedKind.Constructor,
      )) {
        SuccessfulConstructorResolutionResult(:var constructorInvocation) =>
          constructorInvocation,
        ErroneousConstructorResolutionResult(:var errorExpression) =>
          errorExpression,
        UnresolvedConstructorResolutionResult unresolvedResult =>
          unresolvedResult.buildErrorExpression(),
      };
    }
  }

  @override
  Expression_Generator applyTypeArguments(
    int fileOffset,
    List<TypeBuilder>? typeArguments,
  ) {
    return new TypeUseGenerator(_helper, token, declaration, typeName)
      ..typeArguments = typeArguments;
  }
}

enum ReadOnlyAccessKind {
  ConstVariable,
  FinalVariable,
  ExtensionThis,
  LetVariable,
  TypeLiteral,
  ParenthesizedExpression,
  InvalidDeclaration,
}

/// [ReadOnlyAccessGenerator] represents the subexpression whose prefix is the
/// name of final local variable, final parameter, or catch clause variable or
/// `this` in an instance method in an extension declaration.
///
/// For instance:
///
///   method(final a) {
///     final b = null;
///     a;         // a ReadOnlyAccessGenerator is created for `a`.
///     a[];       // a ReadOnlyAccessGenerator is created for `a`.
///     b();       // a ReadOnlyAccessGenerator is created for `b`.
///     b.c = a.d; // a ReadOnlyAccessGenerator is created for `a` and `b`.
///
///     try {
///     } catch (a) {
///       a;       // a ReadOnlyAccessGenerator is created for `a`.
///     }
///   }
///
///   extension on Foo {
///     method() {
///       this;         // a ReadOnlyAccessGenerator is created for `this`.
///       this.a;       // a ReadOnlyAccessGenerator is created for `this`.
///       this.b();     // a ReadOnlyAccessGenerator is created for `this`.
///     }
///   }
///
class ReadOnlyAccessGenerator extends AbstractReadOnlyAccessGenerator {
  @override
  final String targetName;

  @override
  Expression expression;

  ReadOnlyAccessGenerator(
    ExpressionGeneratorHelper helper,
    Token token,
    this.expression,
    this.targetName,
    ReadOnlyAccessKind kind,
  ) : super(helper, token, kind);
}

abstract class AbstractReadOnlyAccessGenerator extends Generator {
  final ReadOnlyAccessKind kind;

  AbstractReadOnlyAccessGenerator(
    ExpressionGeneratorHelper helper,
    Token token,
    this.kind,
  ) : super(helper, token);

  String get targetName;

  Expression get expression;

  @override
  // Coverage-ignore(suite): Not run.
  String get _debugName => "ReadOnlyAccessGenerator";

  @override
  String get _plainNameForRead => targetName;

  @override
  Expression buildSimpleRead() => _createRead();

  Expression _createRead() => expression;

  @override
  Expression _makeInvalidWrite({bool errorHasBeenReported = false}) {
    switch (kind) {
      case ReadOnlyAccessKind.ConstVariable:
        return _helper.buildProblem(
          message: diag.cannotAssignToConstVariable.withArgumentsOld(
            targetName,
          ),
          fileUri: _helper.uri,
          fileOffset: fileOffset,
          length: lengthForToken(token),
          errorHasBeenReported: errorHasBeenReported,
        );
      case ReadOnlyAccessKind.FinalVariable:
        return _helper.buildProblem(
          message: diag.cannotAssignToFinalVariable.withArgumentsOld(
            targetName,
          ),
          fileUri: _helper.uri,
          fileOffset: fileOffset,
          length: lengthForToken(token),
          errorHasBeenReported: errorHasBeenReported,
        );
      case ReadOnlyAccessKind.ExtensionThis:
        return _helper.buildProblem(
          message: diag.cannotAssignToExtensionThis,
          fileUri: _helper.uri,
          fileOffset: fileOffset,
          length: lengthForToken(token),
          errorHasBeenReported: errorHasBeenReported,
        );
      case ReadOnlyAccessKind.TypeLiteral:
        return _helper.buildProblem(
          message: diag.cannotAssignToTypeLiteral,
          fileUri: _helper.uri,
          fileOffset: fileOffset,
          length: lengthForToken(token),
          errorHasBeenReported: errorHasBeenReported,
        );
      case ReadOnlyAccessKind.ParenthesizedExpression:
        return _helper.buildProblem(
          message: diag.cannotAssignToParenthesizedExpression,
          fileUri: _helper.uri,
          fileOffset: fileOffset,
          length: lengthForToken(token),
          errorHasBeenReported: errorHasBeenReported,
        );
      case ReadOnlyAccessKind.LetVariable:
      case ReadOnlyAccessKind.InvalidDeclaration:
        break;
    }
    return super._makeInvalidWrite(errorHasBeenReported: errorHasBeenReported);
  }

  @override
  Expression buildAssignment(Expression value, {bool voidContext = false}) {
    return _makeInvalidWrite();
  }

  @override
  Expression buildIfNullAssignment(
    Expression value,
    DartType type,
    int offset, {
    bool voidContext = false,
  }) {
    Expression read = _createRead();
    Expression write = _makeInvalidWrite();
    return new IfNullSet(read, write, forEffect: voidContext)
      ..fileOffset = offset;
  }

  @override
  Expression buildCompoundAssignment(
    Name binaryOperator,
    Expression value, {
    required int operatorOffset,
    bool voidContext = false,
    bool isPreIncDec = false,
    bool isPostIncDec = false,
  }) {
    return _makeInvalidWrite();
  }

  @override
  Expression buildPostfixIncrement(
    Name binaryOperator, {
    required int operatorOffset,
    bool voidContext = false,
  }) {
    Expression value = _forest.createIntLiteral(operatorOffset, 1);
    return buildCompoundAssignment(
      binaryOperator,
      value,
      operatorOffset: operatorOffset,
      voidContext: voidContext,
      isPostIncDec: true,
    );
  }

  @override
  Expression_Generator_Initializer doInvocation({
    required int offset,
    required List<TypeBuilder>? typeArgumentBuilders,
    required TypeArguments? typeArguments,
    required ActualArguments arguments,
    bool isTypeArgumentsInForest = false,
  }) {
    return _helper.forest.createExpressionInvocation(
      adjustForImplicitCall(targetName, offset),
      _createRead(),
      typeArguments,
      arguments,
    );
  }

  @override
  Generator buildIndexedAccess(
    Expression index,
    Token token, {
    required bool isNullAware,
  }) {
    // TODO(johnniwinther): The read-only quality of the variable should be
    // passed on to the generator.
    return new IndexedAccessGenerator(
      _helper,
      token,
      _createRead(),
      index,
      isNullAware: isNullAware,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  void printOn(StringSink sink) {
    sink.write(", expression: ");
    printNodeOn(expression, sink);
    sink.write(", plainNameForRead: ");
    sink.write(targetName);
    sink.write(", kind: ");
    sink.write(kind);
  }
}

abstract class ErroneousExpressionGenerator extends Generator {
  ErroneousExpressionGenerator(ExpressionGeneratorHelper helper, Token token)
    : super(helper, token);

  InvalidExpression buildError({
    required UnresolvedKind kind,
    int? charOffset,
    bool errorHasBeenReported = false,
  });

  // Coverage-ignore(suite): Not run.
  Name get name => unsupported("name", fileOffset, _fileUri);

  @override
  String get _plainNameForRead => name.text;

  @override
  List<Initializer> buildFieldInitializer(Map<String, int>? initializedFields) {
    return <Initializer>[
      createInvalidInitializer(buildError(kind: UnresolvedKind.Setter)),
    ];
  }

  @override
  Expression_Generator_Initializer doInvocation({
    required int offset,
    required List<TypeBuilder>? typeArgumentBuilders,
    required TypeArguments? typeArguments,
    required ActualArguments arguments,
    bool isTypeArgumentsInForest = false,
  }) {
    return buildError(charOffset: offset, kind: UnresolvedKind.Method);
  }

  @override
  Expression_Generator buildSelectorAccess(
    Selector send,
    int operatorOffset,
    bool isNullAware,
  ) {
    return send.withReceiver(
      buildSimpleRead(),
      operatorOffset,
      isNullAware: isNullAware,
    );
  }

  @override
  Expression buildAssignment(Expression value, {bool voidContext = false}) {
    return buildError(kind: UnresolvedKind.Setter);
  }

  @override
  // Coverage-ignore(suite): Not run.
  Expression buildCompoundAssignment(
    Name binaryOperator,
    Expression value, {
    required int operatorOffset,
    bool voidContext = false,
    bool isPreIncDec = false,
    bool isPostIncDec = false,
  }) {
    return buildError(kind: UnresolvedKind.Getter);
  }

  @override
  Expression buildPrefixIncrement(
    Name binaryOperator, {
    required int operatorOffset,
    bool voidContext = false,
  }) {
    return buildError(kind: UnresolvedKind.Getter)..fileOffset = operatorOffset;
  }

  @override
  Expression buildPostfixIncrement(
    Name binaryOperator, {
    required int operatorOffset,
    bool voidContext = false,
  }) {
    return buildError(kind: UnresolvedKind.Getter)..fileOffset = operatorOffset;
  }

  @override
  // Coverage-ignore(suite): Not run.
  Expression buildIfNullAssignment(
    Expression value,
    DartType type,
    int offset, {
    bool voidContext = false,
  }) {
    return buildError(kind: UnresolvedKind.Setter);
  }

  @override
  Expression buildSimpleRead() {
    return buildError(kind: UnresolvedKind.Member);
  }

  @override
  // Coverage-ignore(suite): Not run.
  Expression _makeInvalidRead({
    required UnresolvedKind unresolvedKind,
    bool errorHasBeenReported = false,
  }) {
    return buildError(
      kind: unresolvedKind,
      errorHasBeenReported: errorHasBeenReported,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  Expression _makeInvalidWrite({bool errorHasBeenReported = false}) {
    return buildError(
      kind: UnresolvedKind.Setter,
      errorHasBeenReported: errorHasBeenReported,
    );
  }

  @override
  Expression invokeConstructor({
    required String name,
    required List<TypeBuilder>? typeArgumentBuilders,
    required TypeArguments? typeArguments,
    required ActualArguments arguments,
    required Token nameToken,
    required Token nameLastToken,
    required Constness constness,
    required bool inImplicitCreationContext,
  }) {
    return buildError(kind: UnresolvedKind.Constructor);
  }

  @override
  // Coverage-ignore(suite): Not run.
  Generator buildIndexedAccess(
    Expression index,
    Token token, {
    required bool isNullAware,
  }) {
    return new IndexedAccessGenerator(
      _helper,
      token,
      buildSimpleRead(),
      index,
      isNullAware: isNullAware,
    );
  }
}

class DuplicateDeclarationGenerator extends ErroneousExpressionGenerator {
  final LookupResult _lookupResult;
  @override
  final Name name;
  final int _nameLength;

  DuplicateDeclarationGenerator(
    super.helper,
    super.token,
    this._lookupResult,
    this.name,
    this._nameLength,
  );

  @override
  // Coverage-ignore(suite): Not run.
  String get _debugName => 'DuplicateDeclarationGenerator';

  LocatedMessage _createInvalidMessage() {
    return LookupResult.createDuplicateMessage(
      _lookupResult,
      name: name.text,
      fileUri: _helper.uri,
      fileOffset: fileOffset,
      length: _nameLength,
    );
  }

  InvalidExpression _createInvalidExpression() {
    return LookupResult.createDuplicateExpression(
      _lookupResult,
      context: _helper.libraryBuilder.loader.target.context,
      name: name.text,
      fileUri: _helper.uri,
      fileOffset: fileOffset,
      length: _nameLength,
    );
  }

  @override
  InvalidExpression buildError({
    required UnresolvedKind kind,
    int? charOffset,
    bool errorHasBeenReported = false,
  }) {
    return _createInvalidExpression();
  }

  @override
  // Coverage-ignore(suite): Not run.
  Expression _makeInvalidRead({
    UnresolvedKind? unresolvedKind,
    bool errorHasBeenReported = false,
  }) {
    return _createInvalidExpression();
  }

  @override
  // Coverage-ignore(suite): Not run.
  Expression _makeInvalidWrite({bool errorHasBeenReported = false}) {
    return _createInvalidExpression();
  }

  @override
  // Coverage-ignore(suite): Not run.
  List<Initializer> buildFieldInitializer(Map<String, int>? initializedFields) {
    return <Initializer>[createInvalidInitializer(_createInvalidExpression())];
  }

  @override
  Expression_Generator qualifiedLookup(Token name) {
    return new UnexpectedQualifiedUseGenerator(
      _helper,
      name,
      this,
      errorHasBeenReported: true,
    );
  }

  @override
  TypeBuilder buildTypeWithResolvedArguments(
    NullabilityBuilder nullabilityBuilder,
    List<TypeBuilder>? arguments, {
    required bool allowPotentiallyConstantType,
    required bool performTypeCanonicalization,
  }) {
    return new NamedTypeBuilderImpl.forInvalidType(
      token.lexeme,
      nullabilityBuilder,
      _createInvalidMessage(),
    );
  }

  @override
  Expression invokeConstructor({
    required String name,
    required List<TypeBuilder>? typeArgumentBuilders,
    required TypeArguments? typeArguments,
    required ActualArguments arguments,
    required Token nameToken,
    required Token nameLastToken,
    required Constness constness,
    required bool inImplicitCreationContext,
  }) {
    return _createInvalidExpression();
  }

  @override
  // Coverage-ignore(suite): Not run.
  void printOn(StringSink sink) {
    sink.write(", name: ");
    sink.write(name.text);
  }
}

class UnresolvedNameGenerator extends ErroneousExpressionGenerator {
  @override
  final Name name;

  final UnresolvedKind unresolvedReadKind;

  final bool errorHasBeenReported;

  factory UnresolvedNameGenerator(
    ExpressionGeneratorHelper helper,
    Token token,
    Name name, {
    required UnresolvedKind unresolvedReadKind,
    bool errorHasBeenReported = false,
  }) {
    if (name.text.isEmpty) {
      unhandled("empty", "name", offsetForToken(token), helper.uri);
    }
    return new UnresolvedNameGenerator.internal(
      helper,
      token,
      name,
      unresolvedReadKind,
      errorHasBeenReported,
    );
  }

  UnresolvedNameGenerator.internal(
    ExpressionGeneratorHelper helper,
    Token token,
    this.name,
    this.unresolvedReadKind,
    this.errorHasBeenReported,
  ) : super(helper, token);

  @override
  // Coverage-ignore(suite): Not run.
  String get _debugName => "UnresolvedNameGenerator";

  @override
  Expression doInvocation({
    required int offset,
    required List<TypeBuilder>? typeArgumentBuilders,
    required TypeArguments? typeArguments,
    required ActualArguments arguments,
    bool isTypeArgumentsInForest = false,
  }) {
    return buildError(
      charOffset: offset,
      kind: UnresolvedKind.Method,
      errorHasBeenReported: errorHasBeenReported,
    );
  }

  @override
  InvalidExpression buildError({
    required UnresolvedKind kind,
    int? charOffset,
    bool errorHasBeenReported = false,
  }) {
    charOffset ??= fileOffset;
    return _helper.buildUnresolvedError(
      _plainNameForRead,
      charOffset,
      kind: kind,
      errorHasBeenReported: errorHasBeenReported,
    );
  }

  @override
  Expression_Generator qualifiedLookup(Token name) {
    return new UnexpectedQualifiedUseGenerator(
      _helper,
      name,
      this,
      errorHasBeenReported: errorHasBeenReported,
    );
  }

  @override
  Expression buildAssignment(Expression value, {bool voidContext = false}) {
    return _buildUnresolvedVariableAssignment(false, value);
  }

  @override
  Expression buildCompoundAssignment(
    Name binaryOperator,
    Expression value, {
    required int operatorOffset,
    bool voidContext = false,
    bool isPreIncDec = false,
    bool isPostIncDec = false,
  }) {
    return _buildUnresolvedVariableAssignment(true, value);
  }

  @override
  Expression buildSimpleRead() {
    return buildError(
      kind: unresolvedReadKind,
      errorHasBeenReported: errorHasBeenReported,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  void printOn(StringSink sink) {
    sink.write(", name: ");
    sink.write(name.text);
  }

  Expression _buildUnresolvedVariableAssignment(
    bool isCompound,
    Expression value,
  ) {
    return buildError(
      kind: UnresolvedKind.Setter,
      errorHasBeenReported: errorHasBeenReported,
    );
  }

  @override
  Generator buildIndexedAccess(
    Expression index,
    Token token, {
    required bool isNullAware,
  }) {
    return new IndexedAccessGenerator(
      _helper,
      token,
      buildSimpleRead(),
      index,
      isNullAware: isNullAware,
    );
  }
}

abstract class ContextAwareGenerator extends Generator {
  final Generator generator;

  ContextAwareGenerator(
    ExpressionGeneratorHelper helper,
    Token token,
    this.generator,
  ) : super(helper, token);

  @override
  // Coverage-ignore(suite): Not run.
  String get _plainNameForRead {
    return unsupported("plainNameForRead", token.charOffset, _helper.uri);
  }

  @override
  // Coverage-ignore(suite): Not run.
  Never doInvocation({
    required int offset,
    required List<TypeBuilder>? typeArgumentBuilders,
    required TypeArguments? typeArguments,
    required ActualArguments arguments,
    bool isTypeArgumentsInForest = false,
  }) {
    return unhandled("${runtimeType}", "doInvocation", offset, _fileUri);
  }

  @override
  // Coverage-ignore(suite): Not run.
  Expression buildAssignment(Expression value, {bool voidContext = false}) {
    return _makeInvalidWrite();
  }

  @override
  // Coverage-ignore(suite): Not run.
  Expression buildIfNullAssignment(
    Expression value,
    DartType type,
    int offset, {
    bool voidContext = false,
  }) {
    return _makeInvalidWrite();
  }

  @override
  // Coverage-ignore(suite): Not run.
  Expression buildCompoundAssignment(
    Name binaryOperator,
    Expression value, {
    required int operatorOffset,
    bool voidContext = false,
    bool isPreIncDec = false,
    bool isPostIncDec = false,
  }) {
    return _makeInvalidWrite();
  }

  @override
  // Coverage-ignore(suite): Not run.
  Expression buildPrefixIncrement(
    Name binaryOperator, {
    required int operatorOffset,
    bool voidContext = false,
  }) {
    return _makeInvalidWrite();
  }

  @override
  // Coverage-ignore(suite): Not run.
  Expression buildPostfixIncrement(
    Name binaryOperator, {
    required int operatorOffset,
    bool voidContext = false,
  }) {
    return _makeInvalidWrite();
  }

  @override
  // Coverage-ignore(suite): Not run.
  Never _makeInvalidRead({
    UnresolvedKind? unresolvedKind,
    bool errorHasBeenReported = false,
  }) {
    return unsupported("makeInvalidRead", token.charOffset, _helper.uri);
  }

  @override
  // Coverage-ignore(suite): Not run.
  Expression _makeInvalidWrite({bool errorHasBeenReported = false}) {
    return _helper.buildProblem(
      message: diag.illegalAssignmentToNonAssignable,
      fileUri: _helper.uri,
      fileOffset: fileOffset,
      length: lengthForToken(token),
      errorHasBeenReported: errorHasBeenReported,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  Generator buildIndexedAccess(
    Expression index,
    Token token, {
    required bool isNullAware,
  }) {
    return new IndexedAccessGenerator(
      _helper,
      token,
      buildSimpleRead(),
      index,
      isNullAware: isNullAware,
    );
  }
}

class DelayedAssignment extends ContextAwareGenerator {
  final Expression value;

  String assignmentOperator;

  DelayedAssignment(
    ExpressionGeneratorHelper helper,
    Token token,
    Generator generator,
    this.value,
    this.assignmentOperator,
  ) : super(helper, token, generator);

  @override
  // Coverage-ignore(suite): Not run.
  String get _debugName => "DelayedAssignment";

  @override
  Expression buildSimpleRead() {
    return handleAssignment(false);
  }

  @override
  Expression buildForEffect() {
    return handleAssignment(true);
  }

  Expression handleAssignment(bool voidContext) {
    if (_helper.constantContext != ConstantContext.none) {
      return _helper.buildProblem(
        message: diag.notAConstantExpression,
        fileUri: _helper.uri,
        fileOffset: fileOffset,
        length: token.length,
      );
    }
    if (identical("=", assignmentOperator)) {
      return generator.buildAssignment(value, voidContext: voidContext);
    } else if (identical("+=", assignmentOperator)) {
      return generator.buildCompoundAssignment(
        plusName,
        value,
        operatorOffset: fileOffset,
        voidContext: voidContext,
      );
    } else if (identical("-=", assignmentOperator)) {
      return generator.buildCompoundAssignment(
        minusName,
        value,
        operatorOffset: fileOffset,
        voidContext: voidContext,
      );
    } else if (identical("*=", assignmentOperator)) {
      return generator.buildCompoundAssignment(
        multiplyName,
        value,
        operatorOffset: fileOffset,
        voidContext: voidContext,
      );
    } else if (identical("%=", assignmentOperator)) {
      // Coverage-ignore-block(suite): Not run.
      return generator.buildCompoundAssignment(
        percentName,
        value,
        operatorOffset: fileOffset,
        voidContext: voidContext,
      );
    } else if (identical("&=", assignmentOperator)) {
      return generator.buildCompoundAssignment(
        ampersandName,
        value,
        operatorOffset: fileOffset,
        voidContext: voidContext,
      );
    } else if (identical("/=", assignmentOperator)) {
      // Coverage-ignore-block(suite): Not run.
      return generator.buildCompoundAssignment(
        divisionName,
        value,
        operatorOffset: fileOffset,
        voidContext: voidContext,
      );
    } else if (identical("<<=", assignmentOperator)) {
      // Coverage-ignore-block(suite): Not run.
      return generator.buildCompoundAssignment(
        leftShiftName,
        value,
        operatorOffset: fileOffset,
        voidContext: voidContext,
      );
    } else if (identical(">>=", assignmentOperator)) {
      // Coverage-ignore-block(suite): Not run.
      return generator.buildCompoundAssignment(
        rightShiftName,
        value,
        operatorOffset: fileOffset,
        voidContext: voidContext,
      );
    } else if (identical(">>>=", assignmentOperator)) {
      return generator.buildCompoundAssignment(
        tripleShiftName,
        value,
        operatorOffset: fileOffset,
        voidContext: voidContext,
      );
    } else if (identical("??=", assignmentOperator)) {
      return generator.buildIfNullAssignment(
        value,
        const DynamicType(),
        fileOffset,
        voidContext: voidContext,
      );
    }
    // Coverage-ignore(suite): Not run.
    else if (identical("^=", assignmentOperator)) {
      return generator.buildCompoundAssignment(
        caretName,
        value,
        operatorOffset: fileOffset,
        voidContext: voidContext,
      );
    } else if (identical("|=", assignmentOperator)) {
      return generator.buildCompoundAssignment(
        barName,
        value,
        operatorOffset: fileOffset,
        voidContext: voidContext,
      );
    } else if (identical("~/=", assignmentOperator)) {
      return generator.buildCompoundAssignment(
        mustacheName,
        value,
        operatorOffset: fileOffset,
        voidContext: voidContext,
      );
    } else {
      return unhandled(
        assignmentOperator,
        "handleAssignment",
        token.charOffset,
        _helper.uri,
      );
    }
  }

  @override
  List<Initializer> buildFieldInitializer(Map<String, int>? initializedFields) {
    if (!identical("=", assignmentOperator) ||
        generator is! ThisPropertyAccessGenerator) {
      return generator.buildFieldInitializer(initializedFields);
    }
    return _helper.createFieldInitializer(
      generator._plainNameForRead,
      offsetForToken(generator.token),
      fileOffset,
      value,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  void printOn(StringSink sink) {
    sink.write(", value: ");
    printNodeOn(value, sink);
    sink.write(", assignmentOperator: ");
    sink.write(assignmentOperator);
  }
}

class DelayedPostfixIncrement extends ContextAwareGenerator {
  final Name binaryOperator;

  DelayedPostfixIncrement(
    ExpressionGeneratorHelper helper,
    Token token,
    Generator generator,
    this.binaryOperator,
  ) : super(helper, token, generator);

  @override
  // Coverage-ignore(suite): Not run.
  String get _debugName => "DelayedPostfixIncrement";

  @override
  Expression buildSimpleRead() {
    return generator.buildPostfixIncrement(
      binaryOperator,
      operatorOffset: fileOffset,
      voidContext: false,
    );
  }

  @override
  Expression buildForEffect() {
    return generator.buildPostfixIncrement(
      binaryOperator,
      operatorOffset: fileOffset,
      voidContext: true,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  void printOn(StringSink sink) {
    sink.write(", binaryOperator: ");
    sink.write(binaryOperator.text);
  }
}

class PrefixUseGenerator extends Generator {
  final PrefixBuilder prefix;

  PrefixUseGenerator(ExpressionGeneratorHelper helper, Token token, this.prefix)
    : super(helper, token);

  @override
  String get _plainNameForRead => prefix.name;

  @override
  // Coverage-ignore(suite): Not run.
  String get _debugName => "PrefixUseGenerator";

  @override
  Expression buildSimpleRead() => _makeInvalidRead();

  @override
  Expression buildAssignment(Expression value, {bool voidContext = false}) {
    return _makeInvalidWrite();
  }

  @override
  // Coverage-ignore(suite): Not run.
  Expression buildIfNullAssignment(
    Expression value,
    DartType type,
    int offset, {
    bool voidContext = false,
  }) {
    return _makeInvalidRead();
  }

  @override
  // Coverage-ignore(suite): Not run.
  Expression buildCompoundAssignment(
    Name binaryOperator,
    Expression value, {
    required int operatorOffset,
    bool voidContext = false,
    bool isPreIncDec = false,
    bool isPostIncDec = false,
  }) {
    return _makeInvalidRead();
  }

  @override
  // Coverage-ignore(suite): Not run.
  Expression buildPostfixIncrement(
    Name binaryOperator, {
    required int operatorOffset,
    bool voidContext = false,
  }) {
    return _makeInvalidRead();
  }

  @override
  Generator qualifiedLookup(Token nameToken) {
    if (_helper.constantContext != ConstantContext.none && prefix.deferred) {
      problemReporting.addProblem(
        diag.cantUseDeferredPrefixAsConstant.withArgumentsOld(token),
        fileOffset,
        lengthForToken(token),
        _fileUri,
      );
    }
    String name = nameToken.lexeme;
    Generator result = _helper.processLookupResult(
      lookupResult: prefix.prefixScope.lookup(name),
      name: name,
      nameToken: nameToken,
      nameOffset: nameToken.charOffset,
      prefix: prefix,
      prefixToken: token,
      forStatementScope: false,
    );

    if (prefix.deferred) {
      if (result is! LoadLibraryGenerator) {
        result = new DeferredAccessGenerator(_helper, nameToken, this, result);
      }
    }
    return result;
  }

  @override
  Expression doInvocation({
    required int offset,
    required List<TypeBuilder>? typeArgumentBuilders,
    required TypeArguments? typeArguments,
    required ActualArguments arguments,
    bool isTypeArgumentsInForest = false,
  }) {
    return problemReporting.wrapInLocatedProblem(
      compilerContext: compilerContext,
      expression: _helper.evaluateArgumentsBefore(
        arguments,
        _forest.createNullLiteral(fileOffset),
      ),
      message: diag.cantUsePrefixAsExpression.withLocation(
        _helper.uri,
        fileOffset,
        lengthForToken(token),
      ),
    );
  }

  @override
  Expression_Generator buildSelectorAccess(
    Selector selector,
    int operatorOffset,
    bool isNullAware,
  ) {
    assert(
      selector.name.text == selector.token.lexeme,
      "'${selector.name.text}' != ${selector.token.lexeme}",
    );
    selector.reportNewAsSelector();
    Object result = qualifiedLookup(selector.token);
    if (selector is InvocationSelector) {
      result = _helper.finishSend(
        result,
        selector.typeArgumentBuilders,
        selector.typeArguments,
        selector.arguments,
        selector.fileOffset,
        isTypeArgumentsInForest: selector.isTypeArgumentsInForest,
      );
    }
    if (isNullAware) {
      result = problemReporting.wrapInLocatedProblem(
        compilerContext: compilerContext,
        expression: _helper.toValue(result),
        message: diag.cantUsePrefixWithNullAware.withLocation(
          _helper.uri,
          fileOffset,
          lengthForToken(token),
        ),
      );
    }
    return result;
  }

  @override
  Expression _makeInvalidRead({
    UnresolvedKind? unresolvedKind,
    bool errorHasBeenReported = false,
  }) {
    return _helper.buildProblem(
      message: diag.cantUsePrefixAsExpression,
      fileUri: _helper.uri,
      fileOffset: fileOffset,
      length: lengthForToken(token),
      errorHasBeenReported: errorHasBeenReported,
    );
  }

  @override
  Expression _makeInvalidWrite({bool errorHasBeenReported = false}) =>
      _makeInvalidRead(errorHasBeenReported: errorHasBeenReported);

  @override
  // Coverage-ignore(suite): Not run.
  Generator buildIndexedAccess(
    Expression index,
    Token token, {
    required bool isNullAware,
  }) {
    return new IndexedAccessGenerator(
      _helper,
      token,
      buildSimpleRead(),
      index,
      isNullAware: isNullAware,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  void printOn(StringSink sink) {
    sink.write(", prefix: ");
    sink.write(prefix.name);
    sink.write(", deferred: ");
    sink.write(prefix.deferred);
  }
}

class UnexpectedQualifiedUseGenerator extends Generator {
  final Generator prefixGenerator;

  /// If `true` an error has already been reported.
  final bool errorHasBeenReported;

  UnexpectedQualifiedUseGenerator(
    ExpressionGeneratorHelper helper,
    Token token,
    this.prefixGenerator, {
    required this.errorHasBeenReported,
  }) : super(helper, token);

  @override
  String get _plainNameForRead =>
      "${prefixGenerator._plainNameForRead}.${token.lexeme}";

  @override
  // Coverage-ignore(suite): Not run.
  String get _debugName => "UnexpectedQualifiedUseGenerator";

  @override
  Expression buildSimpleRead() => _makeInvalidRead(
    unresolvedKind: UnresolvedKind.Member,
    errorHasBeenReported: errorHasBeenReported,
  );

  @override
  // Coverage-ignore(suite): Not run.
  Expression buildAssignment(Expression value, {bool voidContext = false}) {
    return _makeInvalidWrite(errorHasBeenReported: errorHasBeenReported);
  }

  @override
  // Coverage-ignore(suite): Not run.
  Expression buildIfNullAssignment(
    Expression value,
    DartType type,
    int offset, {
    bool voidContext = false,
  }) {
    return _makeInvalidRead(
      unresolvedKind: UnresolvedKind.Member,
      errorHasBeenReported: errorHasBeenReported,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  Expression buildCompoundAssignment(
    Name binaryOperator,
    Expression value, {
    required int operatorOffset,
    bool voidContext = false,
    bool isPreIncDec = false,
    bool isPostIncDec = false,
  }) {
    return _makeInvalidRead(
      unresolvedKind: UnresolvedKind.Member,
      errorHasBeenReported: errorHasBeenReported,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  Expression buildPostfixIncrement(
    Name binaryOperator, {
    required int operatorOffset,
    bool voidContext = false,
  }) {
    return _makeInvalidRead(
      unresolvedKind: UnresolvedKind.Member,
      errorHasBeenReported: errorHasBeenReported,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  Expression doInvocation({
    required int offset,
    required List<TypeBuilder>? typeArgumentBuilders,
    required TypeArguments? typeArguments,
    required ActualArguments arguments,
    bool isTypeArgumentsInForest = false,
  }) {
    return _helper.buildUnresolvedError(
      _plainNameForRead,
      fileOffset,
      kind: UnresolvedKind.Method,
      errorHasBeenReported: errorHasBeenReported,
    );
  }

  @override
  TypeBuilder buildTypeWithResolvedArguments(
    NullabilityBuilder nullabilityBuilder,
    List<TypeBuilder>? arguments, {
    required bool allowPotentiallyConstantType,
    required bool performTypeCanonicalization,
  }) {
    Message message = diag.notAPrefixInTypeAnnotation.withArgumentsOld(
      prefixGenerator.token.lexeme,
      token.lexeme,
    );
    if (!errorHasBeenReported) {
      _helper.libraryBuilder.addProblem(
        message,
        offsetForToken(prefixGenerator.token),
        lengthOfSpan(prefixGenerator.token, token),
        _fileUri,
      );
    }
    return new NamedTypeBuilderImpl.forInvalidType(
      _plainNameForRead,
      nullabilityBuilder,
      message.withLocation(
        _fileUri,
        offsetForToken(prefixGenerator.token),
        lengthOfSpan(prefixGenerator.token, token),
      ),
    );
  }

  @override
  Expression invokeConstructor({
    required String name,
    required List<TypeBuilder>? typeArgumentBuilders,
    required TypeArguments? typeArguments,
    required ActualArguments arguments,
    required Token nameToken,
    required Token nameLastToken,
    required Constness constness,
    required bool inImplicitCreationContext,
  }) {
    Message message = diag.constructorNotFound.withArgumentsOld(
      _helper.constructorNameForDiagnostics(name, className: _plainNameForRead),
    );
    return _helper.buildProblem(
      message: message,
      fileUri: _helper.uri,
      fileOffset: offsetForToken(prefixGenerator.token),
      length: lengthOfSpan(prefixGenerator.token, nameLastToken),
      errorHasBeenReported: errorHasBeenReported,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  Generator buildIndexedAccess(
    Expression index,
    Token token, {
    required bool isNullAware,
  }) {
    return new IndexedAccessGenerator(
      _helper,
      token,
      buildSimpleRead(),
      index,
      isNullAware: isNullAware,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  void printOn(StringSink sink) {
    sink.write(", prefixGenerator: ");
    prefixGenerator.printOn(sink);
  }
}

class ParserErrorGenerator extends Generator {
  final Message message;

  ParserErrorGenerator(
    ExpressionGeneratorHelper helper,
    Token token,
    this.message,
  ) : super(helper, token);

  @override
  // Coverage-ignore(suite): Not run.
  String get _plainNameForRead => "#parser-error";

  @override
  // Coverage-ignore(suite): Not run.
  String get _debugName => "ParserErrorGenerator";

  @override
  // Coverage-ignore(suite): Not run.
  void printOn(StringSink sink) {}

  InvalidExpression buildProblem() {
    return buildProblemExpression(_helper, message, fileOffset);
  }

  static InvalidExpression buildProblemExpression(
    ExpressionGeneratorHelper _helper,
    Message message,
    int fileOffset,
  ) {
    return _helper.buildProblem(
      message: message,
      fileUri: _helper.uri,
      fileOffset: fileOffset,
      length: noLength,
      errorHasBeenReported: true,
    );
  }

  @override
  Expression buildSimpleRead() => buildProblem();

  @override
  Expression buildAssignment(Expression value, {bool voidContext = false}) {
    return buildProblem();
  }

  @override
  // Coverage-ignore(suite): Not run.
  Expression buildIfNullAssignment(
    Expression value,
    DartType type,
    int offset, {
    bool voidContext = false,
  }) {
    return buildProblem();
  }

  @override
  // Coverage-ignore(suite): Not run.
  Expression buildCompoundAssignment(
    Name binaryOperator,
    Expression value, {
    required int operatorOffset,
    bool voidContext = false,
    bool isPreIncDec = false,
    bool isPostIncDec = false,
  }) {
    return buildProblem();
  }

  @override
  // Coverage-ignore(suite): Not run.
  Expression buildPrefixIncrement(
    Name binaryOperator, {
    required int operatorOffset,
    bool voidContext = false,
  }) {
    return buildProblem();
  }

  @override
  // Coverage-ignore(suite): Not run.
  Expression buildPostfixIncrement(
    Name binaryOperator, {
    required int operatorOffset,
    bool voidContext = false,
  }) {
    return buildProblem();
  }

  @override
  // Coverage-ignore(suite): Not run.
  Expression _makeInvalidRead({
    UnresolvedKind? unresolvedKind,
    bool errorHasBeenReported = false,
  }) => buildProblem();

  @override
  // Coverage-ignore(suite): Not run.
  Expression _makeInvalidWrite({bool errorHasBeenReported = false}) =>
      buildProblem();

  @override
  List<Initializer> buildFieldInitializer(Map<String, int>? initializedFields) {
    return <Initializer>[createInvalidInitializer(buildProblem())];
  }

  @override
  Expression doInvocation({
    required int offset,
    required List<TypeBuilder>? typeArgumentBuilders,
    required TypeArguments? typeArguments,
    required ActualArguments arguments,
    bool isTypeArgumentsInForest = false,
  }) {
    return buildProblem();
  }

  @override
  Expression buildSelectorAccess(
    Selector send,
    int operatorOffset,
    bool isNullAware,
  ) {
    return buildProblem();
  }

  @override
  TypeBuilder buildTypeWithResolvedArguments(
    NullabilityBuilder nullabilityBuilder,
    List<TypeBuilder>? arguments, {
    required bool allowPotentiallyConstantType,
    required bool performTypeCanonicalization,
  }) {
    _helper.libraryBuilder.addProblem(message, fileOffset, noLength, _fileUri);
    return new NamedTypeBuilderImpl.forInvalidType(
      token.lexeme,
      nullabilityBuilder,
      message.withLocation(_fileUri, fileOffset, noLength),
    );
  }

  TypeBuilder buildTypeWithResolvedArgumentsDoNotAddProblem(
    NullabilityBuilder nullabilityBuilder,
  ) {
    return new NamedTypeBuilderImpl.forInvalidType(
      token.lexeme,
      nullabilityBuilder,
      message.withLocation(_fileUri, fileOffset, noLength),
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  Expression qualifiedLookup(Token name) {
    return buildProblem();
  }

  @override
  // Coverage-ignore(suite): Not run.
  Expression invokeConstructor({
    required String name,
    required List<TypeBuilder>? typeArgumentBuilders,
    required TypeArguments? typeArguments,
    required ActualArguments arguments,
    required Token nameToken,
    required Token nameLastToken,
    required Constness constness,
    required bool inImplicitCreationContext,
  }) {
    return buildProblem();
  }

  @override
  // Coverage-ignore(suite): Not run.
  Generator buildIndexedAccess(
    Expression index,
    Token token, {
    required bool isNullAware,
  }) {
    return new IndexedAccessGenerator(
      _helper,
      token,
      buildSimpleRead(),
      index,
      isNullAware: isNullAware,
    );
  }
}

/// A [ThisAccessGenerator] represents a subexpression whose prefix is `this`
/// or `super`.
///
/// For instance
///
///   class C {
///     var b = this.c; // a ThisAccessGenerator is created for `this`.
///     var c;
///     C(this.c) :     // a ThisAccessGenerator is created for `this`.
///       this.b = c;   // a ThisAccessGenerator is created for `this`.
///     method() {
///       this.b;       // a ThisAccessGenerator is created for `this`.
///       super.b();    // a ThisAccessGenerator is created for `super`.
///       this.b = c;   // a ThisAccessGenerator is created for `this`.
///       this.b += c;  // a ThisAccessGenerator is created for `this`.
///     }
///   }
///
/// If this `this` occurs in an instance member on an extension declaration,
/// a [ReadOnlyAccessGenerator] is created instead.
///
class ThisAccessGenerator extends Generator {
  /// `true` if this access is in an initializer list.
  ///
  /// For instance in `<init>` in
  ///
  ///    class Class {
  ///      Class() : <init>;
  ///    }
  ///
  final bool isInitializer;

  /// `true` if this access is in a field initializer either directly or within
  /// an initializer list.
  ///
  /// For instance in `<init>` in
  ///
  ///    var foo = <init>;
  ///    class Class {
  ///      var bar = <init>;
  ///      Class() : <init>;
  ///    }
  ///
  final bool inFieldInitializer;

  /// `true` if this access is directly in a field initializer of a late field.
  ///
  /// For instance in `<init>` in
  ///
  ///    late var foo = <init>;
  ///    class Class {
  ///      late var bar = <init>;
  ///      Class() : bar = 42;
  ///    }
  ///
  final bool inLateFieldInitializer;

  /// `true` if this subexpression represents a `super` prefix.
  final bool isSuper;

  ThisAccessGenerator(
    ExpressionGeneratorHelper helper,
    Token token,
    this.isInitializer,
    this.inFieldInitializer,
    this.inLateFieldInitializer, {
    this.isSuper = false,
  }) : super(helper, token);

  @override
  // Coverage-ignore(suite): Not run.
  String get _plainNameForRead {
    return unsupported(
      "${isSuper ? 'super' : 'this'}.plainNameForRead",
      fileOffset,
      _fileUri,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  String get _debugName => "ThisAccessGenerator";

  @override
  Expression buildSimpleRead() {
    if (!isSuper) {
      if (inFieldInitializer && !inLateFieldInitializer) {
        return buildFieldInitializerError(null);
      } else {
        _helper.readInternalThisVariable();
        return _forest.createThisExpression(fileOffset);
      }
    } else {
      return _helper.buildProblem(
        message: diag.superAsExpression,
        fileUri: _helper.uri,
        fileOffset: fileOffset,
        length: lengthForToken(token),
      );
    }
  }

  InvalidExpression buildFieldInitializerError(
    Map<String, int>? initializedFields,
  ) {
    String keyword = isSuper ? "super" : "this";
    return _helper.buildProblem(
      message: diag.thisOrSuperAccessInFieldInitializer.withArgumentsOld(
        keyword,
      ),
      fileUri: _helper.uri,
      fileOffset: fileOffset,
      length: keyword.length,
    );
  }

  @override
  List<Initializer> buildFieldInitializer(Map<String, int>? initializedFields) {
    InvalidExpression error = buildFieldInitializerError(initializedFields);
    return <Initializer>[createInvalidInitializer(error)];
  }

  @override
  Expression_Generator_Initializer buildSelectorAccess(
    Selector selector,
    int operatorOffset,
    bool isNullAware,
  ) {
    Name name = selector.name;
    ActualArguments? arguments = selector.arguments;
    int offset = offsetForToken(selector.token);
    if (isInitializer && selector is InvocationSelector) {
      if (isNullAware) {
        problemReporting.addProblem(
          diag.invalidUseOfNullAwareAccess,
          operatorOffset,
          2,
          _fileUri,
        );
      }
      return buildConstructorInitializer(offset, name, arguments!);
    }
    selector.reportNewAsSelector();
    if (inFieldInitializer && !inLateFieldInitializer && !isInitializer) {
      return buildFieldInitializerError(null);
    }
    if (selector is InvocationSelector) {
      // Notice that 'this' or 'super' can't be null. So we can ignore the
      // value of [isNullAware].
      if (isSuper) {
        _helper.readInternalThisVariable();
        return _helper.buildSuperInvocation(
          name,
          selector.typeArguments,
          selector.arguments,
          offsetForToken(selector.token),
        );
      } else {
        _helper.readInternalThisVariable();
        return _helper.buildMethodInvocation(
          _forest.createThisExpression(fileOffset),
          name,
          selector.typeArguments,
          selector.arguments,
          offsetForToken(selector.token),
        );
      }
    } else {
      if (isSuper) {
        Member? getter = _helper.lookupSuperMember(name);
        Member? setter = _helper.lookupSuperMember(name, isSetter: true);
        return new SuperPropertyAccessGenerator(
          _helper,
          // TODO(ahe): This is not the 'super' token.
          selector.token,
          name,
          getter,
          setter,
        );
      } else {
        return new ThisPropertyAccessGenerator(
          _helper,
          // TODO(ahe): This is not the 'this' token.
          selector.token,
          name,
          thisVariable: null,
          thisOffset: fileOffset,
          isNullAware: isNullAware,
        );
      }
    }
  }

  @override
  Expression_Generator_Initializer doInvocation({
    required int offset,
    required List<TypeBuilder>? typeArgumentBuilders,
    required TypeArguments? typeArguments,
    required ActualArguments arguments,
    bool isTypeArgumentsInForest = false,
  }) {
    if (isInitializer) {
      return buildConstructorInitializer(offset, new Name(""), arguments);
    } else if (isSuper) {
      _helper.readInternalThisVariable();
      return _helper.buildSuperInvocation(
        Name.callName,
        typeArguments,
        arguments,
        offset,
        isImplicitCall: true,
      );
    } else {
      _helper.readInternalThisVariable();
      return _helper.forest.createExpressionInvocation(
        offset,
        _forest.createThisExpression(fileOffset),
        typeArguments,
        arguments,
      );
    }
  }

  @override
  Expression_Generator buildEqualsOperation(
    Token token,
    Expression right, {
    required bool isNot,
  }) {
    if (isSuper) {
      int offset = offsetForToken(token);
      _helper.readInternalThisVariable();
      Expression result = _helper.buildSuperInvocation(
        equalsName,
        null,
        _forest.createArguments(
          offset,
          arguments: [new PositionalArgument(right)],
          hasNamedBeforePositional: false,
          positionalCount: 1,
        ),
        offset,
      );
      if (isNot) {
        result = _forest.createNot(offset, result);
      }
      return result;
    }
    // Coverage-ignore(suite): Not run.
    return super.buildEqualsOperation(token, right, isNot: isNot);
  }

  @override
  Expression_Generator buildBinaryOperation(
    Token token,
    Name binaryName,
    Expression right,
  ) {
    if (isSuper) {
      int offset = offsetForToken(token);
      _helper.readInternalThisVariable();
      return _helper.buildSuperInvocation(
        binaryName,
        null,
        _forest.createArguments(
          offset,
          arguments: [new PositionalArgument(right)],
          hasNamedBeforePositional: false,
          positionalCount: 1,
        ),
        offset,
      );
    }
    return super.buildBinaryOperation(token, binaryName, right);
  }

  @override
  Expression_Generator buildUnaryOperation(Token token, Name unaryName) {
    if (isSuper) {
      int offset = offsetForToken(token);
      _helper.readInternalThisVariable();
      return _helper.buildSuperInvocation(
        unaryName,
        null,
        _forest.createArgumentsEmpty(offset),
        offset,
      );
    }
    return super.buildUnaryOperation(token, unaryName);
  }

  Expression_Initializer buildConstructorInitializer(
    int offset,
    Name name,
    ActualArguments arguments,
  ) {
    if (isSuper) {
      MemberLookupResult? result = _helper.lookupSuperConstructor(
        name.text,
        _helper.libraryBuilder,
      );
      Constructor? constructor;
      if (result != null) {
        if (result.isInvalidLookup) {
          return createInvalidInitializer(
            LookupResult.createDuplicateExpression(
              result,
              context: _helper.libraryBuilder.loader.target.context,
              name: name.text,
              fileUri: _helper.uri,
              fileOffset: offset,
              length: noLength,
            ),
          );
        }
        MemberBuilder? memberBuilder = result.getable;
        Member? member = memberBuilder?.invokeTarget;
        // TODO(johnniwinther): Passing the library builder to
        // `lookupSuperConstructor` doesn't correctly account for privacy
        // checking when the target class is a mixin application. In this case
        // the constructor name space can include private constructors from
        // another library but the mixin application itself is the current
        // library. Change `lookupSuperConstructor` to avoid this deficiency.
        if (member is Constructor &&
            member.name.libraryReference == name.libraryReference) {
          constructor = member;
        }
      }
      if (constructor == null) {
        String fullName = _helper.superConstructorNameForDiagnostics(name.text);
        return createInvalidInitializer(
          _helper.buildProblem(
            message: diag.superclassHasNoConstructor.withArgumentsOld(fullName),
            fileUri: _fileUri,
            fileOffset: fileOffset,
            length: lengthForToken(token),
          ),
        );
      } else {
        _helper.readInternalThisVariable();
        return _helper.buildSuperInitializer(
          false,
          constructor,
          arguments,
          offset,
        );
      }
    } else {
      _helper.readInternalThisVariable();
      return _helper.buildRedirectingInitializer(
        name,
        arguments,
        fileOffset: offset,
      );
    }
  }

  @override
  // Coverage-ignore(suite): Not run.
  Expression buildAssignment(Expression value, {bool voidContext = false}) {
    return buildAssignmentError();
  }

  @override
  // Coverage-ignore(suite): Not run.
  Expression buildIfNullAssignment(
    Expression value,
    DartType type,
    int offset, {
    bool voidContext = false,
  }) {
    return buildAssignmentError();
  }

  @override
  // Coverage-ignore(suite): Not run.
  Expression buildCompoundAssignment(
    Name binaryOperator,
    Expression value, {
    required int operatorOffset,
    bool voidContext = false,
    bool isPreIncDec = false,
    bool isPostIncDec = false,
  }) {
    return buildAssignmentError();
  }

  @override
  // Coverage-ignore(suite): Not run.
  Expression buildPrefixIncrement(
    Name binaryOperator, {
    required int operatorOffset,
    bool voidContext = false,
  }) {
    return buildAssignmentError();
  }

  @override
  // Coverage-ignore(suite): Not run.
  Expression buildPostfixIncrement(
    Name binaryOperator, {
    required int operatorOffset,
    bool voidContext = false,
  }) {
    return buildAssignmentError();
  }

  @override
  Generator buildIndexedAccess(
    Expression index,
    Token token, {
    required bool isNullAware,
  }) {
    if (isSuper) {
      return new SuperIndexedAccessGenerator(
        _helper,
        token,
        index,
        _helper.lookupSuperMember(indexGetName) as Procedure?,
        _helper.lookupSuperMember(indexSetName) as Procedure?,
      );
    } else {
      return new ThisIndexedAccessGenerator(
        _helper,
        token,
        index,
        thisOffset: fileOffset,
        isNullAware: isNullAware,
      );
    }
  }

  // Coverage-ignore(suite): Not run.
  Expression buildAssignmentError() {
    return _helper.buildProblem(
      message: isSuper ? diag.cannotAssignToSuper : diag.notAnLvalue,
      fileUri: _helper.uri,
      fileOffset: fileOffset,
      length: token.length,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  void printOn(StringSink sink) {
    sink.write(", isInitializer: ");
    sink.write(isInitializer);
    sink.write(", inFieldInitializer: ");
    sink.write(inFieldInitializer);
    sink.write(", inLateFieldInitializer: ");
    sink.write(inLateFieldInitializer);
    sink.write(", isSuper: ");
    sink.write(isSuper);
  }
}

class IncompleteErrorGenerator extends ErroneousExpressionGenerator {
  final Message message;

  IncompleteErrorGenerator(
    ExpressionGeneratorHelper helper,
    Token token,
    this.message,
  ) : super(helper, token);

  @override
  // Coverage-ignore(suite): Not run.
  String get _plainNameForRead => token.lexeme;

  @override
  // Coverage-ignore(suite): Not run.
  String get _debugName => "IncompleteErrorGenerator";

  @override
  InvalidExpression buildError({
    required UnresolvedKind kind,
    String? name,
    int? charOffset,
    int? charLength,
    bool errorHasBeenReported = false,
  }) {
    if (charOffset == null) {
      charOffset = fileOffset;
      charLength ??= lengthForToken(token);
    }
    charLength ??= noLength;
    return _helper.buildProblem(
      message: message,
      fileUri: _helper.uri,
      fileOffset: charOffset,
      length: charLength,
      errorHasBeenReported: errorHasBeenReported,
    );
  }

  @override
  Generator doInvocation({
    required int offset,
    required List<TypeBuilder>? typeArgumentBuilders,
    required TypeArguments? typeArguments,
    required ActualArguments arguments,
    bool isTypeArgumentsInForest = false,
  }) => this;

  @override
  Expression buildSimpleRead() {
    return buildError(kind: UnresolvedKind.Member)..fileOffset = fileOffset;
  }

  @override
  // Coverage-ignore(suite): Not run.
  void printOn(StringSink sink) {
    sink.write(", message: ");
    sink.write(message.code.name);
  }
}

/// [ParenthesizedExpressionGenerator] represents the subexpression whose prefix
/// is a parenthesized expression.
///
/// For instance:
///
///   method(final a) {
///     final b = null;
///     (a);           // this generator is created for `(a)`.
///     (a)[];         // this generator is created for `(a)`.
///     (b)();         // this generator is created for `(b)`.
///     (b).c = (a.d); // this generator is created for `(a.d)` and `(b)`.
///   }
///
// TODO(johnniwinther): Remove this in favor of [ParenthesizedExpression] when
// the [TypePromoter] is replaced by [FlowAnalysis].
class ParenthesizedExpressionGenerator extends AbstractReadOnlyAccessGenerator {
  @override
  final Expression expression;

  ParenthesizedExpressionGenerator(
    ExpressionGeneratorHelper helper,
    Token token,
    this.expression,
  ) : super(helper, token, ReadOnlyAccessKind.ParenthesizedExpression);

  @override
  String get targetName => '';

  @override
  Expression buildSimpleRead() => _createRead();

  @override
  Expression _createRead() =>
      _helper.forest.createParenthesized(expression.fileOffset, expression);

  @override
  // Coverage-ignore(suite): Not run.
  String get _debugName => "ParenthesizedExpressionGenerator";

  @override
  Expression_Generator buildSelectorAccess(
    Selector selector,
    int operatorOffset,
    bool isNullAware,
  ) {
    selector.reportNewAsSelector();
    if (selector is InvocationSelector) {
      return _helper.buildMethodInvocation(
        _createRead(),
        selector.name,
        selector.typeArguments,
        selector.arguments,
        offsetForToken(selector.token),
        isNullAware: isNullAware,
        isConstantExpression: selector.isPotentiallyConstant,
      );
    } else {
      if (_helper.constantContext != ConstantContext.none &&
          // Coverage-ignore(suite): Not run.
          selector.name != lengthName) {
        // Coverage-ignore-block(suite): Not run.
        problemReporting.addProblem(
          diag.notAConstantExpression,
          fileOffset,
          token.length,
          _fileUri,
        );
      }
      return PropertyAccessGenerator.make(
        _helper,
        selector.token,
        _createRead(),
        selector.name,
        isNullAware,
      );
    }
  }
}

int adjustForImplicitCall(String? name, int offset) {
  // Normally the offset is at the start of the token, but in this case,
  // because we insert a '.call', we want it at the end instead.
  return offset + (name?.length ?? 0);
}

bool isFieldOrGetter(Member? member) {
  return member is Field || (member is Procedure && member.isGetter);
}

/// A [Selector] is a part of an object access after `.` or `..` or `?.`,
/// including arguments, if present.
///
/// For instance, an [InvocationSelector] is created for `b()` in
///
///    a.b();
///    a..b();
///    a?.b();
///
/// and a [PropertySelector] is created for `b` in
///
///    a.b;
///    a.b = c;
///    a..b;
///    a..b = c;
///    a?.b;
///    a?.b = c;
///
abstract class Selector {
  final ExpressionGeneratorHelper _helper;
  final Token token;

  Selector(this._helper, this.token);

  int get fileOffset => offsetForToken(token);

  Name get name;

  /// Applies this selector to [receiver].
  Expression_Generator withReceiver(
    Object? receiver,
    int operatorOffset, {
    bool isNullAware = false,
  });

  List<TypeBuilder>? get typeArgumentBuilders => null;

  // Coverage-ignore(suite): Not run.
  bool get isTypeArgumentsInForest => true;

  // Coverage-ignore(suite): Not run.
  TypeArguments? get typeArguments => null;

  ActualArguments? get arguments => null;

  /// Internal name used for debugging.
  String get _debugName;

  void printOn(StringSink sink);

  /// Report an error if the selector name "new" when the constructor-tearoff
  /// feature is enabled.
  void reportNewAsSelector() {
    if (name.text == 'new' &&
        _helper.libraryFeatures.constructorTearoffs.isEnabled) {
      _helper.problemReporting.addProblem(
        diag.newAsSelector,
        fileOffset,
        name.text.length,
        _helper.uri,
      );
    }
  }

  @override
  String toString() {
    StringBuffer buffer = new StringBuffer();
    buffer.write(_debugName);
    buffer.write("(offset: ");
    buffer.write("${fileOffset}");
    printOn(buffer);
    buffer.write(")");
    return "$buffer";
  }
}

/// An [InvocationSelector] is the part of an object invocation after `.` or
/// `..` or `?.` including arguments.
///
/// For instance, an [InvocationSelector] is created for `b()` in
///
///    a.b();
///    a..b();
///    a?.b();
///
class InvocationSelector extends Selector {
  @override
  final Name name;

  @override
  final List<TypeBuilder>? typeArgumentBuilders;

  @override
  final TypeArguments? typeArguments;

  @override
  final bool isTypeArgumentsInForest;

  @override
  final ActualArguments arguments;

  final bool isPotentiallyConstant;

  InvocationSelector(
    ExpressionGeneratorHelper helper,
    Token token,
    this.name,
    this.typeArgumentBuilders,
    this.typeArguments,
    this.arguments, {
    this.isPotentiallyConstant = false,
    this.isTypeArgumentsInForest = true,
  }) : super(helper, token);

  @override
  // Coverage-ignore(suite): Not run.
  String get _debugName => 'InvocationSelector';

  @override
  Expression_Generator withReceiver(
    Object? receiver,
    int operatorOffset, {
    bool isNullAware = false,
  }) {
    if (receiver is Generator) {
      return receiver.buildSelectorAccess(this, operatorOffset, isNullAware);
    }
    reportNewAsSelector();
    return _helper.buildMethodInvocation(
      _helper.toValue(receiver),
      name,
      typeArguments,
      arguments,
      fileOffset,
      isNullAware: isNullAware,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  void printOn(StringSink sink) {
    sink.write(", name: ");
    sink.write(name.text);
    sink.write(", arguments: ");
    printNodeOn(arguments, sink);
  }
}

/// A [PropertySelector] is the part of an object access after `.` or `..` or
/// `?.`.
///
/// For instance a [PropertySelector] is created for `b` in
///
///    a.b;
///    a.b = c;
///    a..b;
///    a..b = c;
///    a?.b;
///    a?.b = c;
///
class PropertySelector extends Selector {
  @override
  final Name name;

  PropertySelector(ExpressionGeneratorHelper helper, Token token, this.name)
    : super(helper, token);

  @override
  // Coverage-ignore(suite): Not run.
  String get _debugName => 'PropertySelector';

  @override
  Expression_Generator withReceiver(
    Object? receiver,
    int operatorOffset, {
    bool isNullAware = false,
  }) {
    if (receiver is Generator) {
      return receiver.buildSelectorAccess(this, operatorOffset, isNullAware);
    }
    reportNewAsSelector();
    return PropertyAccessGenerator.make(
      _helper,
      token,
      _helper.toValue(receiver),
      name,
      isNullAware,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  void printOn(StringSink sink) {
    sink.write(", name: ");
    sink.write(name.text);
  }
}

// Coverage-ignore(suite): Not run.
class AugmentSuperAccessGenerator extends Generator {
  final AugmentSuperTarget augmentSuperTarget;

  AugmentSuperAccessGenerator(
    ExpressionGeneratorHelper helper,
    Token token,
    this.augmentSuperTarget,
  ) : super(helper, token);

  @override
  String get _debugName => "AugmentSuperGenerator";

  @override
  String get _plainNameForRead {
    return unsupported("augment super.plainNameForRead", fileOffset, _fileUri);
  }

  Expression _createRead() {
    Member? readTarget = augmentSuperTarget.readTarget;
    if (readTarget != null) {
      return new AugmentSuperGet(readTarget, fileOffset: fileOffset);
    } else {
      return _helper.buildProblem(
        message: diag.noAugmentSuperReadTarget,
        fileUri: _helper.uri,
        fileOffset: fileOffset,
        length: noLength,
      );
    }
  }

  @override
  Expression buildAssignment(Expression value, {bool voidContext = false}) {
    return _createWrite(fileOffset, value, forEffect: voidContext);
  }

  Expression _createWrite(
    int offset,
    Expression value, {
    required bool forEffect,
  }) {
    Member? writeTarget = augmentSuperTarget.writeTarget;
    if (writeTarget != null) {
      return new AugmentSuperSet(
        writeTarget,
        value,
        forEffect: forEffect,
        fileOffset: fileOffset,
      );
    } else {
      return _helper.buildProblem(
        message: diag.noAugmentSuperWriteTarget,
        fileUri: _helper.uri,
        fileOffset: offset,
        length: noLength,
      );
    }
  }

  @override
  Expression buildCompoundAssignment(
    Name binaryOperator,
    Expression value, {
    required int operatorOffset,
    bool voidContext = false,
    bool isPreIncDec = false,
    bool isPostIncDec = false,
  }) {
    // TODO(johnniwinther): Is this ever valid? Augment getters have no access
    // to the augmented setter, augmenting setters have no access to the
    // augmented getters, and augmenting fields only have read access to the
    // augmented field initializer expression.

    Expression binary = _helper.forest.createBinary(
      operatorOffset,
      _createRead(),
      binaryOperator,
      value,
    );
    return _createWrite(fileOffset, binary, forEffect: voidContext);
  }

  @override
  Expression buildIfNullAssignment(
    Expression value,
    DartType type,
    int offset, {
    bool voidContext = false,
  }) {
    // TODO(johnniwinther): Is this ever valid? Augment getters have no access
    // to the augmented setter, augmenting setters have no access to the
    // augmented getters, and augmenting fields only have read access to the
    // augmented field initializer expression.
    return new IfNullSet(
      _createRead(),
      _createWrite(offset, value, forEffect: voidContext),
      forEffect: voidContext,
    )..fileOffset = offset;
  }

  @override
  Generator buildIndexedAccess(
    Expression index,
    Token token, {
    required bool isNullAware,
  }) {
    // TODO(johnniwinther): The semantics is unclear. Is this accessing the
    // invoke target, which must be an `operator []` or the read target with a
    // type that has an `operator []`.
    throw new UnimplementedError();
  }

  @override
  Expression buildPostfixIncrement(
    Name binaryOperator, {
    required int operatorOffset,
    bool voidContext = false,
  }) {
    // TODO(johnniwinther): Is this ever valid? Augment getters have no access
    // to the augmented setter, augmenting setters have no access to the
    // augmented getters, and augmenting fields only have read access to the
    // augmented field initializer expression.
    throw new UnimplementedError();
  }

  @override
  Expression buildSimpleRead() {
    return _createRead();
  }

  @override
  Expression_Generator_Initializer doInvocation({
    required int offset,
    required List<TypeBuilder>? typeArgumentBuilders,
    required TypeArguments? typeArguments,
    required ActualArguments arguments,
    bool isTypeArgumentsInForest = false,
  }) {
    Member? invokeTarget = augmentSuperTarget.invokeTarget;
    if (invokeTarget != null) {
      return new AugmentSuperInvocation(
        invokeTarget,
        typeArguments,
        arguments,
        fileOffset: fileOffset,
      );
    } else {
      return _helper.buildProblem(
        message: diag.noAugmentSuperInvokeTarget,
        fileUri: _helper.uri,
        fileOffset: offset,
        length: noLength,
      );
    }
  }

  @override
  void printOn(StringSink sink) {
    sink.write(", augmentSuperTarget: ");
    sink.write(augmentSuperTarget);
  }
}
