// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A library to help generate expression.
library fasta.expression_generator;

import 'dart:core' hide MapEntry;

import 'package:_fe_analyzer_shared/src/parser/parser.dart'
    show lengthForToken, lengthOfSpan;

import 'package:_fe_analyzer_shared/src/scanner/token.dart' show Token;

import 'package:kernel/ast.dart';

import '../builder/builder.dart';
import '../builder/declaration_builder.dart';
import '../builder/extension_builder.dart';
import '../builder/invalid_type_declaration_builder.dart';
import '../builder/member_builder.dart';
import '../builder/named_type_builder.dart';
import '../builder/nullability_builder.dart';
import '../builder/prefix_builder.dart';
import '../builder/type_alias_builder.dart';
import '../builder/type_builder.dart';
import '../builder/type_declaration_builder.dart';
import '../builder/unresolved_type.dart';

import '../constant_context.dart' show ConstantContext;

import '../fasta_codes.dart';

import '../names.dart'
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

import '../problems.dart';

import '../scope.dart';

import '../source/stack_listener_impl.dart' show offsetForToken;

import 'body_builder.dart' show noLocation;

import 'constness.dart' show Constness;

import 'expression_generator_helper.dart' show ExpressionGeneratorHelper;

import 'forest.dart';

import 'kernel_api.dart' show NameSystem, printNodeOn, printQualifiedNameOn;

import 'kernel_ast_api.dart'
    show
        Arguments,
        DartType,
        DynamicType,
        Expression,
        Initializer,
        Member,
        Name,
        Procedure,
        VariableDeclaration;

import 'kernel_builder.dart' show LoadLibraryBuilder;

import 'internal_ast.dart';

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
  Uri get _uri => _helper.uri;

  /// Builds a [Expression] representing a read from the generator.
  ///
  /// The read of this subexpression does _not_ need to support a simultaneous
  /// write of the same subexpression.
  Expression buildSimpleRead();

  /// Builds a [Expression] representing an assignment with the generator on
  /// the LHS and [value] on the RHS.
  ///
  /// The returned expression evaluates to the assigned value, unless
  /// [voidContext] is true, in which case it may evaluate to anything.
  Expression buildAssignment(Expression value, {bool voidContext: false});

  /// Returns a [Expression] representing a null-aware assignment (`??=`) with
  /// the generator on the LHS and [value] on the RHS.
  ///
  /// The returned expression evaluates to the assigned value, unless
  /// [voidContext] is true, in which case it may evaluate to anything.
  ///
  /// [type] is the static type of the RHS.
  Expression buildIfNullAssignment(Expression value, DartType type, int offset,
      {bool voidContext: false});

  /// Returns a [Expression] representing a compound assignment (e.g. `+=`)
  /// with the generator on the LHS and [value] on the RHS.
  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      bool isPreIncDec: false,
      bool isPostIncDec: false});

  /// Returns a [Expression] representing a pre-increment or pre-decrement of
  /// the generator.
  Expression buildPrefixIncrement(Name binaryOperator,
      {int offset: TreeNode.noOffset, bool voidContext: false}) {
    return buildCompoundAssignment(
        binaryOperator, _forest.createIntLiteral(offset, 1),
        offset: offset,
        // TODO(johnniwinther): We are missing some void contexts here. For
        // instance `++a?.b;` is not providing a void context making it default
        // `true`.
        voidContext: voidContext,
        isPreIncDec: true);
  }

  /// Returns a [Expression] representing a post-increment or post-decrement of
  /// the generator.
  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset: TreeNode.noOffset, bool voidContext: false});

  /// Returns a [Generator] or [Expression] representing an index access
  /// (e.g. `a[b]`) with the generator on the receiver and [index] as the
  /// index expression.
  Generator buildIndexedAccess(Expression index, Token token,
      {bool isNullAware});

  /// Returns a [Expression] representing a compile-time error.
  ///
  /// At runtime, an exception will be thrown.
  Expression _makeInvalidRead() {
    return _helper.throwNoSuchMethodError(_forest.createNullLiteral(fileOffset),
        _plainNameForRead, _forest.createArgumentsEmpty(noLocation), fileOffset,
        isGetter: true);
  }

  /// Returns a [Expression] representing a compile-time error wrapping
  /// [value].
  ///
  /// At runtime, [value] will be evaluated before throwing an exception.
  Expression _makeInvalidWrite(Expression value) {
    return _helper.throwNoSuchMethodError(
        _forest.createNullLiteral(fileOffset),
        _plainNameForRead,
        _forest.createArguments(noLocation, <Expression>[value]),
        fileOffset,
        isSetter: true);
  }

  Expression buildForEffect() => buildSimpleRead();

  List<Initializer> buildFieldInitializer(Map<String, int> initializedFields) {
    return <Initializer>[
      _helper.buildInvalidInitializer(
          _helper.buildProblem(
              messageInvalidInitializer, fileOffset, lengthForToken(token)),
          fileOffset)
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
  /* Expression | Generator | Initializer */ doInvocation(
      int offset, List<UnresolvedType> typeArguments, Arguments arguments,
      {bool isTypeArgumentsInForest = false});

  /* Expression | Generator */ buildPropertyAccess(
      IncompleteSendGenerator send, int operatorOffset, bool isNullAware) {
    if (send is SendAccessGenerator) {
      return _helper.buildMethodInvocation(buildSimpleRead(), send.name,
          send.arguments, offsetForToken(send.token),
          isNullAware: isNullAware,
          isConstantExpression: send.isPotentiallyConstant);
    } else {
      if (_helper.constantContext != ConstantContext.none &&
          send.name != lengthName) {
        _helper.addProblem(
            messageNotAConstantExpression, fileOffset, token.length);
      }
      return PropertyAccessGenerator.make(
          _helper, send.token, buildSimpleRead(), send.name, isNullAware);
    }
  }

  /*Expression | Generator*/ buildEqualsOperation(Token token, Expression right,
      {bool isNot}) {
    assert(isNot != null);
    return _forest.createEquals(offsetForToken(token), buildSimpleRead(), right,
        isNot: isNot);
  }

  /*Expression | Generator*/ buildBinaryOperation(
      Token token, Name binaryName, Expression right) {
    return _forest.createBinary(
        offsetForToken(token), buildSimpleRead(), binaryName, right);
  }

  /*Expression | Generator*/ buildUnaryOperation(Token token, Name unaryName) {
    return _forest.createUnary(
        offsetForToken(token), unaryName, buildSimpleRead());
  }

  /// Returns a [TypeBuilder] for this subexpression instantiated with the
  /// type [arguments]. If no type arguments are provided [arguments] is `null`.
  ///
  /// The type arguments have not been resolved and should be resolved to
  /// create a [TypeBuilder] for a valid type.
  TypeBuilder buildTypeWithResolvedArguments(
      NullabilityBuilder nullabilityBuilder, List<UnresolvedType> arguments) {
    // TODO(johnniwinther): Could we use a FixedTypeBuilder(InvalidType()) here?
    NamedTypeBuilder result = new NamedTypeBuilder(
        token.lexeme,
        nullabilityBuilder,
        /* arguments = */ null,
        /* fileUri = */ null,
        /* charOffset = */ null);
    Message message = templateNotAType.withArguments(token.lexeme);
    _helper.libraryBuilder
        .addProblem(message, fileOffset, lengthForToken(token), _uri);
    result.bind(result.buildInvalidTypeDeclarationBuilder(
        message.withLocation(_uri, fileOffset, lengthForToken(token))));
    return result;
  }

  /* Expression | Generator */ Object qualifiedLookup(Token name) {
    return new UnexpectedQualifiedUseGenerator(_helper, name, this, false);
  }

  Expression invokeConstructor(
      List<UnresolvedType> typeArguments,
      String name,
      Arguments arguments,
      Token nameToken,
      Token nameLastToken,
      Constness constness) {
    if (typeArguments != null) {
      assert(_forest.argumentsTypeArguments(arguments).isEmpty);
      _forest.argumentsSetTypeArguments(
          arguments, _helper.buildDartTypeArguments(typeArguments));
    }
    return _helper.throwNoSuchMethodError(
        _forest.createNullLiteral(fileOffset),
        _helper.constructorNameForDiagnostics(name,
            className: _plainNameForRead),
        arguments,
        nameToken.charOffset);
  }

  void printOn(StringSink sink);

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
  final VariableDeclaration variable;

  final DartType promotedType;

  VariableUseGenerator(
      ExpressionGeneratorHelper helper, Token token, this.variable,
      [this.promotedType])
      : assert(variable.isAssignable, 'Variable $variable is not assignable'),
        super(helper, token);

  @override
  String get _debugName => "VariableUseGenerator";

  @override
  String get _plainNameForRead => variable.name;

  @override
  Expression buildSimpleRead() {
    return _createRead();
  }

  Expression _createRead() {
    return _helper.createVariableGet(variable, fileOffset);
  }

  @override
  Expression buildAssignment(Expression value, {bool voidContext: false}) {
    return _createWrite(fileOffset, value);
  }

  Expression _createWrite(int offset, Expression value) {
    _helper.registerVariableAssignment(variable);
    return new VariableSet(variable, value)..fileOffset = offset;
  }

  @override
  Expression buildIfNullAssignment(Expression value, DartType type, int offset,
      {bool voidContext: false}) {
    Expression read = _createRead();
    Expression write = _createWrite(fileOffset, value);
    return new IfNullSet(read, write, forEffect: voidContext)
      ..fileOffset = offset;
  }

  @override
  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      bool isPreIncDec: false,
      bool isPostIncDec: false}) {
    Expression binary = _helper.forest
        .createBinary(offset, _createRead(), binaryOperator, value);
    return _createWrite(fileOffset, binary);
  }

  @override
  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset = TreeNode.noOffset, bool voidContext = false}) {
    Expression value = _forest.createIntLiteral(offset, 1);
    if (voidContext) {
      return buildCompoundAssignment(binaryOperator, value,
          offset: offset, voidContext: voidContext, isPostIncDec: true);
    }
    VariableDeclaration read =
        _helper.forest.createVariableDeclarationForValue(_createRead());
    Expression binary = _helper.forest.createBinary(offset,
        _helper.createVariableGet(read, fileOffset), binaryOperator, value);
    VariableDeclaration write = _helper.forest
        .createVariableDeclarationForValue(_createWrite(offset, binary));
    return new LocalPostIncDec(read, write)..fileOffset = offset;
  }

  @override
  Expression doInvocation(
      int offset, List<UnresolvedType> typeArguments, Arguments arguments,
      {bool isTypeArgumentsInForest = false}) {
    return _helper.forest.createExpressionInvocation(
        adjustForImplicitCall(_plainNameForRead, offset),
        buildSimpleRead(),
        arguments);
  }

  @override
  Generator buildIndexedAccess(Expression index, Token token,
      {bool isNullAware}) {
    assert(isNullAware != null);
    return new IndexedAccessGenerator(_helper, token, buildSimpleRead(), index,
        isNullAware: isNullAware);
  }

  @override
  void printOn(StringSink sink) {
    NameSystem syntheticNames = new NameSystem();
    sink.write(", variable: ");
    printNodeOn(variable, sink, syntheticNames: syntheticNames);
    sink.write(", promotedType: ");
    printNodeOn(promotedType, sink, syntheticNames: syntheticNames);
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
      ExpressionGeneratorHelper helper, Token token, this.receiver, this.name)
      : super(helper, token);

  @override
  String get _debugName => "PropertyAccessGenerator";

  @override
  String get _plainNameForRead => name.text;

  @override
  Expression doInvocation(
      int offset, List<UnresolvedType> typeArguments, Arguments arguments,
      {bool isTypeArgumentsInForest = false}) {
    return _helper.buildMethodInvocation(receiver, name, arguments, offset);
  }

  @override
  void printOn(StringSink sink) {
    NameSystem syntheticNames = new NameSystem();
    sink.write(", receiver: ");
    printNodeOn(receiver, sink, syntheticNames: syntheticNames);
    sink.write(", name: ");
    sink.write(name.text);
  }

  @override
  Expression buildSimpleRead() {
    return _forest.createPropertyGet(fileOffset, receiver, name);
  }

  @override
  Expression buildAssignment(Expression value, {bool voidContext: false}) {
    return _helper.forest.createPropertySet(fileOffset, receiver, name, value,
        forEffect: voidContext);
  }

  @override
  Expression buildIfNullAssignment(Expression value, DartType type, int offset,
      {bool voidContext = false}) {
    return new IfNullPropertySet(receiver, name, value,
        forEffect: voidContext, readOffset: fileOffset, writeOffset: fileOffset)
      ..fileOffset = offset;
  }

  @override
  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      bool isPreIncDec: false,
      bool isPostIncDec: false}) {
    return new CompoundPropertySet(receiver, name, binaryOperator, value,
        forEffect: voidContext,
        readOffset: fileOffset,
        binaryOffset: offset,
        writeOffset: fileOffset)
      ..fileOffset = offset;
  }

  @override
  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset = TreeNode.noOffset, bool voidContext = false}) {
    Expression value = _forest.createIntLiteral(offset, 1);
    if (voidContext) {
      return buildCompoundAssignment(binaryOperator, value,
          offset: offset, voidContext: voidContext, isPostIncDec: true);
    }
    VariableDeclaration variable =
        _helper.forest.createVariableDeclarationForValue(receiver);
    VariableDeclaration read = _helper.forest.createVariableDeclarationForValue(
        _forest.createPropertyGet(fileOffset,
            _helper.createVariableGet(variable, receiver.fileOffset), name));
    Expression binary = _helper.forest.createBinary(offset,
        _helper.createVariableGet(read, fileOffset), binaryOperator, value);
    VariableDeclaration write = _helper.forest
        .createVariableDeclarationForValue(_helper.forest.createPropertySet(
            fileOffset,
            _helper.createVariableGet(variable, receiver.fileOffset),
            name,
            binary,
            forEffect: true));
    return new PropertyPostIncDec(variable, read, write)..fileOffset = offset;
  }

  @override
  Generator buildIndexedAccess(Expression index, Token token,
      {bool isNullAware}) {
    assert(isNullAware != null);
    return new IndexedAccessGenerator(_helper, token, buildSimpleRead(), index,
        isNullAware: isNullAware);
  }

  /// Creates a [Generator] for the access of property [name] on [receiver].
  static Generator make(ExpressionGeneratorHelper helper, Token token,
      Expression receiver, Name name, bool isNullAware) {
    if (helper.forest.isThisExpression(receiver)) {
      return new ThisPropertyAccessGenerator(helper, token, name,
          thisOffset: receiver.fileOffset, isNullAware: isNullAware);
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
  final int thisOffset;
  final bool isNullAware;

  ThisPropertyAccessGenerator(
      ExpressionGeneratorHelper helper, Token token, this.name,
      {this.thisOffset, this.isNullAware: false})
      : super(helper, token);

  @override
  String get _debugName => "ThisPropertyAccessGenerator";

  @override
  String get _plainNameForRead => name.text;

  void _reportNonNullableInNullAwareWarningIfNeeded() {
    if (isNullAware && _helper.libraryBuilder.isNonNullableByDefault) {
      _helper.libraryBuilder.addProblem(
          messageThisInNullAwareReceiver,
          thisOffset ?? fileOffset,
          thisOffset != null ? 4 : noLength,
          _helper.uri);
    }
  }

  @override
  Expression buildSimpleRead() {
    return _createRead();
  }

  Expression _createRead() {
    _reportNonNullableInNullAwareWarningIfNeeded();
    return _forest.createPropertyGet(
        fileOffset, _forest.createThisExpression(fileOffset), name);
  }

  @override
  Expression buildAssignment(Expression value, {bool voidContext: false}) {
    _reportNonNullableInNullAwareWarningIfNeeded();
    return _createWrite(fileOffset, value, forEffect: voidContext);
  }

  Expression _createWrite(int offset, Expression value, {bool forEffect}) {
    return _helper.forest.createPropertySet(
        fileOffset, _forest.createThisExpression(fileOffset), name, value,
        forEffect: forEffect);
  }

  @override
  Expression buildIfNullAssignment(Expression value, DartType type, int offset,
      {bool voidContext: false}) {
    return new IfNullSet(
        _createRead(), _createWrite(offset, value, forEffect: voidContext),
        forEffect: voidContext)
      ..fileOffset = offset;
  }

  @override
  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      bool isPreIncDec: false,
      bool isPostIncDec: false}) {
    _reportNonNullableInNullAwareWarningIfNeeded();
    _helper.forest.createBinary(
        offset,
        _forest.createPropertyGet(
            fileOffset, _forest.createThisExpression(fileOffset), name),
        binaryOperator,
        value);
    Expression binary = _helper.forest.createBinary(
        offset,
        _forest.createPropertyGet(
            fileOffset, _forest.createThisExpression(fileOffset), name),
        binaryOperator,
        value);
    return _createWrite(fileOffset, binary, forEffect: voidContext);
  }

  @override
  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset = TreeNode.noOffset, bool voidContext = false}) {
    Expression value = _forest.createIntLiteral(offset, 1);
    if (voidContext) {
      return buildCompoundAssignment(binaryOperator, value,
          offset: offset, voidContext: voidContext, isPostIncDec: true);
    }
    _reportNonNullableInNullAwareWarningIfNeeded();
    VariableDeclaration read = _helper.forest.createVariableDeclarationForValue(
        _forest.createPropertyGet(
            fileOffset, _forest.createThisExpression(fileOffset), name));
    Expression binary = _helper.forest.createBinary(offset,
        _helper.createVariableGet(read, fileOffset), binaryOperator, value);
    VariableDeclaration write = _helper.forest
        .createVariableDeclarationForValue(
            _createWrite(fileOffset, binary, forEffect: true));
    return new PropertyPostIncDec.onReadOnly(read, write)..fileOffset = offset;
  }

  @override
  Expression doInvocation(
      int offset, List<UnresolvedType> typeArguments, Arguments arguments,
      {bool isTypeArgumentsInForest = false}) {
    return _helper.buildMethodInvocation(
        _forest.createThisExpression(fileOffset), name, arguments, offset);
  }

  @override
  Generator buildIndexedAccess(Expression index, Token token,
      {bool isNullAware}) {
    assert(isNullAware != null);
    return new IndexedAccessGenerator(_helper, token, buildSimpleRead(), index,
        isNullAware: isNullAware);
  }

  @override
  void printOn(StringSink sink) {
    sink.write(", name: ");
    sink.write(name.text);
  }
}

class NullAwarePropertyAccessGenerator extends Generator {
  final VariableDeclaration receiver;

  final Expression receiverExpression;

  final Name name;

  NullAwarePropertyAccessGenerator(ExpressionGeneratorHelper helper,
      Token token, this.receiverExpression, this.name)
      : this.receiver =
            helper.forest.createVariableDeclarationForValue(receiverExpression),
        super(helper, token);

  @override
  String get _debugName => "NullAwarePropertyAccessGenerator";

  Expression receiverAccess() => new VariableGet(receiver);

  @override
  String get _plainNameForRead => name.text;

  @override
  Expression buildSimpleRead() {
    VariableDeclaration variable =
        _helper.forest.createVariableDeclarationForValue(receiverExpression);
    PropertyGet read = _forest.createPropertyGet(
        fileOffset,
        _helper.createVariableGet(variable, receiverExpression.fileOffset,
            forNullGuardedAccess: true),
        name);
    return new NullAwarePropertyGet(variable, read)
      ..fileOffset = receiverExpression.fileOffset;
  }

  @override
  Expression buildAssignment(Expression value, {bool voidContext = false}) {
    VariableDeclaration variable =
        _helper.forest.createVariableDeclarationForValue(receiverExpression);
    PropertySet read = _helper.forest.createPropertySet(
        fileOffset,
        _helper.createVariableGet(variable, receiverExpression.fileOffset,
            forNullGuardedAccess: true),
        name,
        value,
        forEffect: voidContext,
        readOnlyReceiver: true);
    return new NullAwarePropertySet(variable, read)
      ..fileOffset = receiverExpression.fileOffset;
  }

  Expression buildIfNullAssignment(Expression value, DartType type, int offset,
      {bool voidContext: false}) {
    return new NullAwareIfNullSet(receiverExpression, name, value,
        forEffect: voidContext,
        readOffset: fileOffset,
        testOffset: offset,
        writeOffset: fileOffset)
      ..fileOffset = offset;
  }

  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      bool isPreIncDec: false,
      bool isPostIncDec: false}) {
    return new NullAwareCompoundSet(
        receiverExpression, name, binaryOperator, value,
        readOffset: fileOffset,
        binaryOffset: offset,
        writeOffset: fileOffset,
        forEffect: voidContext,
        forPostIncDec: isPostIncDec);
  }

  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset: TreeNode.noOffset, bool voidContext: false}) {
    return buildCompoundAssignment(
        binaryOperator, _forest.createIntLiteral(offset, 1),
        offset: offset, voidContext: voidContext, isPostIncDec: true);
  }

  @override
  Expression doInvocation(
      int offset, List<UnresolvedType> typeArguments, Arguments arguments,
      {bool isTypeArgumentsInForest = false}) {
    return unsupported("doInvocation", offset, _uri);
  }

  @override
  Generator buildIndexedAccess(Expression index, Token token,
      {bool isNullAware}) {
    assert(isNullAware != null);
    return new IndexedAccessGenerator(_helper, token, buildSimpleRead(), index,
        isNullAware: isNullAware);
  }

  @override
  void printOn(StringSink sink) {
    NameSystem syntheticNames = new NameSystem();
    sink.write(", receiver: ");
    printNodeOn(receiver, sink, syntheticNames: syntheticNames);
    sink.write(", receiverExpression: ");
    printNodeOn(receiverExpression, sink, syntheticNames: syntheticNames);
    sink.write(", name: ");
    sink.write(name.text);
  }
}

class SuperPropertyAccessGenerator extends Generator {
  final Name name;

  final Member getter;

  final Member setter;

  SuperPropertyAccessGenerator(ExpressionGeneratorHelper helper, Token token,
      this.name, this.getter, this.setter)
      : super(helper, token);

  @override
  String get _debugName => "SuperPropertyAccessGenerator";

  @override
  String get _plainNameForRead => name.text;

  @override
  Expression buildSimpleRead() {
    return _createRead();
  }

  Expression _createRead() {
    if (getter == null) {
      _helper.warnUnresolvedGet(name, fileOffset, isSuper: true);
    }
    return new SuperPropertyGet(name, getter)..fileOffset = fileOffset;
  }

  @override
  Expression buildAssignment(Expression value, {bool voidContext = false}) {
    return _createWrite(fileOffset, value);
  }

  Expression _createWrite(int offset, Expression value) {
    if (setter == null) {
      _helper.warnUnresolvedSet(name, offset, isSuper: true);
    }
    SuperPropertySet write = new SuperPropertySet(name, value, setter)
      ..fileOffset = offset;
    return write;
  }

  @override
  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset = TreeNode.noOffset,
      bool voidContext = false,
      bool isPreIncDec = false,
      bool isPostIncDec = false}) {
    Expression binary = _helper.forest
        .createBinary(offset, _createRead(), binaryOperator, value);
    return _createWrite(fileOffset, binary);
  }

  @override
  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset = TreeNode.noOffset, bool voidContext = false}) {
    Expression value = _forest.createIntLiteral(offset, 1);
    if (voidContext) {
      return buildCompoundAssignment(binaryOperator, value,
          offset: offset, voidContext: voidContext, isPostIncDec: true);
    }
    VariableDeclaration read =
        _helper.forest.createVariableDeclarationForValue(_createRead());
    Expression binary = _helper.forest.createBinary(offset,
        _helper.createVariableGet(read, fileOffset), binaryOperator, value);
    VariableDeclaration write = _helper.forest
        .createVariableDeclarationForValue(_createWrite(fileOffset, binary));
    return new StaticPostIncDec(read, write)..fileOffset = offset;
  }

  @override
  Expression buildIfNullAssignment(Expression value, DartType type, int offset,
      {bool voidContext: false}) {
    return new IfNullSet(_createRead(), _createWrite(fileOffset, value),
        forEffect: voidContext)
      ..fileOffset = offset;
  }

  @override
  Expression doInvocation(
      int offset, List<UnresolvedType> typeArguments, Arguments arguments,
      {bool isTypeArgumentsInForest = false}) {
    if (_helper.constantContext != ConstantContext.none) {
      // TODO(brianwilkerson) Fix the length
      _helper.addProblem(messageNotAConstantExpression, offset, 1);
    }
    if (getter == null || isFieldOrGetter(getter)) {
      return _helper.forest
          .createExpressionInvocation(offset, buildSimpleRead(), arguments);
    } else {
      // TODO(ahe): This could be something like "super.property(...)" where
      // property is a setter.
      return unhandled("${getter.runtimeType}", "doInvocation", offset, _uri);
    }
  }

  @override
  Generator buildIndexedAccess(Expression index, Token token,
      {bool isNullAware}) {
    assert(isNullAware != null);
    return new IndexedAccessGenerator(_helper, token, buildSimpleRead(), index,
        isNullAware: isNullAware);
  }

  @override
  void printOn(StringSink sink) {
    NameSystem syntheticNames = new NameSystem();
    sink.write(", name: ");
    sink.write(name.text);
    sink.write(", getter: ");
    printQualifiedNameOn(getter, sink, syntheticNames: syntheticNames);
    sink.write(", setter: ");
    printQualifiedNameOn(setter, sink, syntheticNames: syntheticNames);
  }
}

class IndexedAccessGenerator extends Generator {
  final Expression receiver;

  final Expression index;

  final bool isNullAware;

  IndexedAccessGenerator(
      ExpressionGeneratorHelper helper, Token token, this.receiver, this.index,
      {this.isNullAware})
      : assert(isNullAware != null),
        super(helper, token);

  @override
  String get _plainNameForRead => "[]";

  @override
  String get _debugName => "IndexedAccessGenerator";

  @override
  Expression buildSimpleRead() {
    VariableDeclaration variable;
    Expression receiverValue;
    if (isNullAware) {
      variable = _forest.createVariableDeclarationForValue(receiver);
      receiverValue = _helper.createVariableGet(variable, fileOffset,
          forNullGuardedAccess: true);
    } else {
      receiverValue = receiver;
    }
    Expression result =
        _forest.createIndexGet(fileOffset, receiverValue, index);
    if (isNullAware) {
      result = new NullAwareMethodInvocation(variable, result)
        ..fileOffset = fileOffset;
    }
    return result;
  }

  @override
  Expression buildAssignment(Expression value, {bool voidContext: false}) {
    VariableDeclaration variable;
    Expression receiverValue;
    if (isNullAware) {
      variable = _forest.createVariableDeclarationForValue(receiver);
      receiverValue = _helper.createVariableGet(variable, fileOffset,
          forNullGuardedAccess: true);
    } else {
      receiverValue = receiver;
    }
    Expression result = _forest.createIndexSet(
        fileOffset, receiverValue, index, value,
        forEffect: voidContext);
    if (isNullAware) {
      result = new NullAwareMethodInvocation(variable, result)
        ..fileOffset = fileOffset;
    }
    return result;
  }

  @override
  Expression buildIfNullAssignment(Expression value, DartType type, int offset,
      {bool voidContext: false}) {
    VariableDeclaration variable;
    Expression receiverValue;
    if (isNullAware) {
      variable = _forest.createVariableDeclarationForValue(receiver);
      receiverValue = _helper.createVariableGet(variable, fileOffset,
          forNullGuardedAccess: true);
    } else {
      receiverValue = receiver;
    }

    Expression result = new IfNullIndexSet(receiverValue, index, value,
        readOffset: fileOffset,
        testOffset: offset,
        writeOffset: fileOffset,
        forEffect: voidContext)
      ..fileOffset = offset;
    if (isNullAware) {
      result = new NullAwareMethodInvocation(variable, result)
        ..fileOffset = fileOffset;
    }
    return result;
  }

  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      bool isPreIncDec: false,
      bool isPostIncDec: false}) {
    VariableDeclaration variable;
    Expression receiverValue;
    if (isNullAware) {
      variable = _forest.createVariableDeclarationForValue(receiver);
      receiverValue = _helper.createVariableGet(variable, fileOffset,
          forNullGuardedAccess: true);
    } else {
      receiverValue = receiver;
    }

    Expression result = new CompoundIndexSet(
        receiverValue, index, binaryOperator, value,
        readOffset: fileOffset,
        binaryOffset: offset,
        writeOffset: fileOffset,
        forEffect: voidContext,
        forPostIncDec: isPostIncDec);
    if (isNullAware) {
      result = new NullAwareMethodInvocation(variable, result)
        ..fileOffset = fileOffset;
    }
    return result;
  }

  @override
  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset = TreeNode.noOffset, bool voidContext = false}) {
    Expression value = _forest.createIntLiteral(offset, 1);
    return buildCompoundAssignment(binaryOperator, value,
        offset: offset, voidContext: voidContext, isPostIncDec: true);
  }

  @override
  Expression doInvocation(
      int offset, List<UnresolvedType> typeArguments, Arguments arguments,
      {bool isTypeArgumentsInForest = false}) {
    return _helper.forest.createExpressionInvocation(
        arguments.fileOffset, buildSimpleRead(), arguments);
  }

  @override
  Generator buildIndexedAccess(Expression index, Token token,
      {bool isNullAware}) {
    assert(isNullAware != null);
    return new IndexedAccessGenerator(_helper, token, buildSimpleRead(), index,
        isNullAware: isNullAware);
  }

  @override
  void printOn(StringSink sink) {
    NameSystem syntheticNames = new NameSystem();
    sink.write(", receiver: ");
    printNodeOn(receiver, sink, syntheticNames: syntheticNames);
    sink.write(", index: ");
    printNodeOn(index, sink, syntheticNames: syntheticNames);
    sink.write(", isNullAware: ${isNullAware}");
  }

  static Generator make(ExpressionGeneratorHelper helper, Token token,
      Expression receiver, Expression index,
      {bool isNullAware}) {
    assert(isNullAware != null);
    if (helper.forest.isThisExpression(receiver)) {
      return new ThisIndexedAccessGenerator(helper, token, index,
          thisOffset: receiver.fileOffset, isNullAware: isNullAware);
    } else {
      return new IndexedAccessGenerator(helper, token, receiver, index,
          isNullAware: isNullAware);
    }
  }
}

/// Special case of [IndexedAccessGenerator] to avoid creating an indirect
/// access to 'this'.
class ThisIndexedAccessGenerator extends Generator {
  final Expression index;

  final int thisOffset;
  final bool isNullAware;

  ThisIndexedAccessGenerator(
      ExpressionGeneratorHelper helper, Token token, this.index,
      {this.thisOffset, this.isNullAware: false})
      : super(helper, token);

  @override
  String get _plainNameForRead => "[]";

  @override
  String get _debugName => "ThisIndexedAccessGenerator";

  void _reportNonNullableInNullAwareWarningIfNeeded() {
    if (isNullAware && _helper.libraryBuilder.isNonNullableByDefault) {
      _helper.libraryBuilder.addProblem(
          messageThisInNullAwareReceiver,
          thisOffset ?? fileOffset,
          thisOffset != null ? 4 : noLength,
          _helper.uri);
    }
  }

  @override
  Expression buildSimpleRead() {
    _reportNonNullableInNullAwareWarningIfNeeded();
    Expression receiver = _helper.forest.createThisExpression(fileOffset);
    return _forest.createIndexGet(fileOffset, receiver, index);
  }

  @override
  Expression buildAssignment(Expression value, {bool voidContext: false}) {
    _reportNonNullableInNullAwareWarningIfNeeded();
    Expression receiver = _helper.forest.createThisExpression(fileOffset);
    return _forest.createIndexSet(fileOffset, receiver, index, value,
        forEffect: voidContext);
  }

  @override
  Expression buildIfNullAssignment(Expression value, DartType type, int offset,
      {bool voidContext: false}) {
    _reportNonNullableInNullAwareWarningIfNeeded();
    Expression receiver = _helper.forest.createThisExpression(fileOffset);
    return new IfNullIndexSet(receiver, index, value,
        readOffset: fileOffset,
        testOffset: offset,
        writeOffset: fileOffset,
        forEffect: voidContext)
      ..fileOffset = offset;
  }

  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      bool isPreIncDec: false,
      bool isPostIncDec: false}) {
    _reportNonNullableInNullAwareWarningIfNeeded();
    Expression receiver = _helper.forest.createThisExpression(fileOffset);
    return new CompoundIndexSet(receiver, index, binaryOperator, value,
        readOffset: fileOffset,
        binaryOffset: offset,
        writeOffset: fileOffset,
        forEffect: voidContext,
        forPostIncDec: isPostIncDec);
  }

  @override
  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset = TreeNode.noOffset, bool voidContext = false}) {
    Expression value = _forest.createIntLiteral(offset, 1);
    return buildCompoundAssignment(binaryOperator, value,
        offset: offset, voidContext: voidContext, isPostIncDec: true);
  }

  @override
  Expression doInvocation(
      int offset, List<UnresolvedType> typeArguments, Arguments arguments,
      {bool isTypeArgumentsInForest = false}) {
    return _helper.forest
        .createExpressionInvocation(offset, buildSimpleRead(), arguments);
  }

  @override
  Generator buildIndexedAccess(Expression index, Token token,
      {bool isNullAware}) {
    assert(isNullAware != null);
    return new IndexedAccessGenerator(_helper, token, buildSimpleRead(), index,
        isNullAware: isNullAware);
  }

  @override
  void printOn(StringSink sink) {
    NameSystem syntheticNames = new NameSystem();
    sink.write(", index: ");
    printNodeOn(index, sink, syntheticNames: syntheticNames);
  }
}

class SuperIndexedAccessGenerator extends Generator {
  final Expression index;

  final Member getter;

  final Member setter;

  SuperIndexedAccessGenerator(ExpressionGeneratorHelper helper, Token token,
      this.index, this.getter, this.setter)
      : super(helper, token);

  String get _plainNameForRead => "[]";

  String get _debugName => "SuperIndexedAccessGenerator";

  @override
  Expression buildSimpleRead() {
    if (getter == null) {
      _helper.warnUnresolvedMethod(indexGetName, fileOffset, isSuper: true);
    }
    return _helper.forest.createSuperMethodInvocation(
        fileOffset,
        indexGetName,
        getter,
        _helper.forest.createArguments(fileOffset, <Expression>[index]));
  }

  @override
  Expression buildAssignment(Expression value, {bool voidContext: false}) {
    if (voidContext) {
      if (setter == null) {
        _helper.warnUnresolvedMethod(indexSetName, fileOffset, isSuper: true);
      }
      return _helper.forest.createSuperMethodInvocation(
          fileOffset,
          indexSetName,
          setter,
          _helper.forest
              .createArguments(fileOffset, <Expression>[index, value]));
    } else {
      return new SuperIndexSet(setter, index, value)..fileOffset = fileOffset;
    }
  }

  @override
  Expression buildIfNullAssignment(Expression value, DartType type, int offset,
      {bool voidContext: false}) {
    return new IfNullSuperIndexSet(getter, setter, index, value,
        readOffset: fileOffset,
        testOffset: offset,
        writeOffset: fileOffset,
        forEffect: voidContext)
      ..fileOffset = offset;
  }

  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      bool isPreIncDec: false,
      bool isPostIncDec: false}) {
    return new CompoundSuperIndexSet(
        getter, setter, index, binaryOperator, value,
        readOffset: fileOffset,
        binaryOffset: offset,
        writeOffset: fileOffset,
        forEffect: voidContext,
        forPostIncDec: isPostIncDec);
  }

  @override
  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset = TreeNode.noOffset, bool voidContext = false}) {
    Expression value = _forest.createIntLiteral(offset, 1);
    return buildCompoundAssignment(binaryOperator, value,
        offset: offset, voidContext: voidContext, isPostIncDec: true);
  }

  @override
  Expression doInvocation(
      int offset, List<UnresolvedType> typeArguments, Arguments arguments,
      {bool isTypeArgumentsInForest = false}) {
    return _helper.forest
        .createExpressionInvocation(offset, buildSimpleRead(), arguments);
  }

  @override
  Generator buildIndexedAccess(Expression index, Token token,
      {bool isNullAware}) {
    assert(isNullAware != null);
    return new IndexedAccessGenerator(_helper, token, buildSimpleRead(), index,
        isNullAware: isNullAware);
  }

  @override
  void printOn(StringSink sink) {
    NameSystem syntheticNames = new NameSystem();
    sink.write(", index: ");
    printNodeOn(index, sink, syntheticNames: syntheticNames);
    sink.write(", getter: ");
    printQualifiedNameOn(getter, sink, syntheticNames: syntheticNames);
    sink.write(", setter: ");
    printQualifiedNameOn(setter, sink, syntheticNames: syntheticNames);
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
  final String targetName;

  /// The static [Member] used for performing a read or invocation on this
  /// subexpression.
  ///
  /// This can be `null` if the subexpression doesn't have a readable target.
  /// For instance if the subexpression is a setter without a corresponding
  /// getter.
  final Member readTarget;

  /// The static [Member] used for performing a write on this subexpression.
  ///
  /// This can be `null` if the subexpression doesn't have a writable target.
  /// For instance if the subexpression is a final field, a method, or a getter
  /// without a corresponding setter.
  final Member writeTarget;

  /// The offset of the type name if explicit. Otherwise `null`.
  final int typeOffset;
  final bool isNullAware;

  StaticAccessGenerator(ExpressionGeneratorHelper helper, Token token,
      this.targetName, this.readTarget, this.writeTarget,
      {this.typeOffset, this.isNullAware: false})
      : assert(targetName != null),
        assert(readTarget != null || writeTarget != null),
        super(helper, token);

  factory StaticAccessGenerator.fromBuilder(
      ExpressionGeneratorHelper helper,
      String targetName,
      Token token,
      MemberBuilder getterBuilder,
      MemberBuilder setterBuilder,
      {int typeOffset,
      bool isNullAware: false}) {
    return new StaticAccessGenerator(helper, token, targetName,
        getterBuilder?.readTarget, setterBuilder?.writeTarget,
        typeOffset: typeOffset, isNullAware: isNullAware);
  }

  void _reportNonNullableInNullAwareWarningIfNeeded() {
    if (isNullAware && _helper.libraryBuilder.isNonNullableByDefault) {
      String className = (readTarget ?? writeTarget).enclosingClass.name;
      _helper.libraryBuilder.addProblem(
          templateClassInNullAwareReceiver.withArguments(className),
          typeOffset ?? fileOffset,
          typeOffset != null ? className.length : noLength,
          _helper.uri);
    }
  }

  @override
  String get _debugName => "StaticAccessGenerator";

  @override
  String get _plainNameForRead => targetName;

  @override
  Expression buildSimpleRead() {
    return _createRead();
  }

  Expression _createRead() {
    Expression read;
    if (readTarget == null) {
      read = _makeInvalidRead();
    } else {
      _reportNonNullableInNullAwareWarningIfNeeded();
      read = _helper.makeStaticGet(readTarget, token);
    }
    return read;
  }

  @override
  Expression buildAssignment(Expression value, {bool voidContext = false}) {
    _reportNonNullableInNullAwareWarningIfNeeded();
    return _createWrite(fileOffset, value);
  }

  Expression _createWrite(int offset, Expression value) {
    Expression write;
    if (writeTarget == null) {
      write = _makeInvalidWrite(value);
    } else {
      _reportNonNullableInNullAwareWarningIfNeeded();
      write = new StaticSet(writeTarget, value)..fileOffset = offset;
    }
    return write;
  }

  @override
  Expression buildIfNullAssignment(Expression value, DartType type, int offset,
      {bool voidContext: false}) {
    return new IfNullSet(_createRead(), _createWrite(offset, value),
        forEffect: voidContext)
      ..fileOffset = offset;
  }

  @override
  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset = TreeNode.noOffset,
      bool voidContext = false,
      bool isPreIncDec = false,
      bool isPostIncDec = false}) {
    Expression binary = _helper.forest
        .createBinary(offset, _createRead(), binaryOperator, value);
    return _createWrite(fileOffset, binary);
  }

  @override
  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset = TreeNode.noOffset, bool voidContext = false}) {
    Expression value = _forest.createIntLiteral(offset, 1);
    if (voidContext) {
      return buildCompoundAssignment(binaryOperator, value,
          offset: offset, voidContext: voidContext, isPostIncDec: true);
    }
    VariableDeclaration read =
        _helper.forest.createVariableDeclarationForValue(_createRead());
    Expression binary = _helper.forest.createBinary(offset,
        _helper.createVariableGet(read, fileOffset), binaryOperator, value);
    VariableDeclaration write = _helper.forest
        .createVariableDeclarationForValue(_createWrite(offset, binary));
    return new StaticPostIncDec(read, write)..fileOffset = offset;
  }

  @override
  Expression doInvocation(
      int offset, List<UnresolvedType> typeArguments, Arguments arguments,
      {bool isTypeArgumentsInForest = false}) {
    if (_helper.constantContext != ConstantContext.none &&
        !_helper.isIdentical(readTarget)) {
      return _helper.buildProblem(
          templateNotConstantExpression.withArguments('Method invocation'),
          offset,
          readTarget?.name?.text?.length ?? 0);
    }
    if (readTarget == null || isFieldOrGetter(readTarget)) {
      return _helper.forest.createExpressionInvocation(
          offset + (readTarget?.name?.text?.length ?? 0),
          buildSimpleRead(),
          arguments);
    } else {
      return _helper.buildStaticInvocation(readTarget, arguments,
          charOffset: offset);
    }
  }

  @override
  Generator buildIndexedAccess(Expression index, Token token,
      {bool isNullAware}) {
    assert(isNullAware != null);
    return new IndexedAccessGenerator(_helper, token, buildSimpleRead(), index,
        isNullAware: isNullAware);
  }

  @override
  void printOn(StringSink sink) {
    NameSystem syntheticNames = new NameSystem();
    sink.write(", targetName: ");
    sink.write(targetName);
    sink.write(", readTarget: ");
    printQualifiedNameOn(readTarget, sink, syntheticNames: syntheticNames);
    sink.write(", writeTarget: ");
    printQualifiedNameOn(writeTarget, sink, syntheticNames: syntheticNames);
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
  final String targetName;

  /// The static [Member] generated for an instance extension member which is
  /// used for performing a read on this subexpression.
  ///
  /// This can be `null` if the subexpression doesn't have a readable target.
  /// For instance if the subexpression is a setter without a corresponding
  /// getter.
  final Procedure readTarget;

  /// The static [Member] generated for an instance extension member which is
  /// used for performing an invocation on this subexpression.
  ///
  /// This can be `null` if the subexpression doesn't have an invokable target.
  /// For instance if the subexpression is a getter or setter.
  final Procedure invokeTarget;

  /// The static [Member] generated for an instance extension member which is
  /// used for performing a write on this subexpression.
  ///
  /// This can be `null` if the subexpression doesn't have a writable target.
  /// For instance if the subexpression is a final field, a method, or a getter
  /// without a corresponding setter.
  final Procedure writeTarget;

  /// The parameter holding the value for `this` within the current extension
  /// instance method.
  // TODO(johnniwinther): Handle static access to extension instance members,
  // in which case the access is erroneous and [extensionThis] is `null`.
  final VariableDeclaration extensionThis;

  /// The type parameters synthetically added to  the current extension
  /// instance method.
  final List<TypeParameter> extensionTypeParameters;

  ExtensionInstanceAccessGenerator(
      ExpressionGeneratorHelper helper,
      Token token,
      this.extension,
      this.targetName,
      this.readTarget,
      this.invokeTarget,
      this.writeTarget,
      this.extensionThis,
      this.extensionTypeParameters)
      : assert(targetName != null),
        assert(
            readTarget != null || invokeTarget != null || writeTarget != null),
        assert(extensionThis != null),
        super(helper, token);

  factory ExtensionInstanceAccessGenerator.fromBuilder(
      ExpressionGeneratorHelper helper,
      Token token,
      Extension extension,
      String targetName,
      VariableDeclaration extensionThis,
      List<TypeParameter> extensionTypeParameters,
      MemberBuilder getterBuilder,
      MemberBuilder setterBuilder) {
    Procedure readTarget;
    Procedure invokeTarget;
    if (getterBuilder != null) {
      if (getterBuilder.isGetter) {
        assert(!getterBuilder.isStatic);
        readTarget = getterBuilder.readTarget;
      } else if (getterBuilder.isRegularMethod) {
        assert(!getterBuilder.isStatic);
        readTarget = getterBuilder.readTarget;
        invokeTarget = getterBuilder.invokeTarget;
      } else if (getterBuilder.isOperator) {
        assert(!getterBuilder.isStatic);
        invokeTarget = getterBuilder.invokeTarget;
      }
    }
    Procedure writeTarget;
    if (setterBuilder != null) {
      if (setterBuilder.isSetter) {
        assert(!setterBuilder.isStatic);
        writeTarget = setterBuilder.writeTarget;
        targetName ??= setterBuilder.name;
      } else {
        return unhandled(
            "${setterBuilder.runtimeType}",
            "ExtensionInstanceAccessGenerator.fromBuilder",
            offsetForToken(token),
            helper.uri);
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
        extensionTypeParameters);
  }

  @override
  String get _debugName => "InstanceExtensionAccessGenerator";

  @override
  String get _plainNameForRead => targetName;

  int get _extensionTypeParameterCount => extensionTypeParameters?.length ?? 0;

  List<DartType> _createExtensionTypeArguments() {
    List<DartType> extensionTypeArguments = const <DartType>[];
    if (extensionTypeParameters != null) {
      extensionTypeArguments = [];
      for (TypeParameter typeParameter in extensionTypeParameters) {
        extensionTypeArguments.add(
            _forest.createTypeParameterTypeWithDefaultNullabilityForLibrary(
                typeParameter, extension.enclosingLibrary));
      }
    }
    return extensionTypeArguments;
  }

  @override
  Expression buildSimpleRead() {
    return _createRead();
  }

  Expression _createRead() {
    Expression read;
    if (readTarget == null) {
      read = _makeInvalidRead();
    } else {
      read = _helper.buildExtensionMethodInvocation(
          fileOffset,
          readTarget,
          _helper.forest.createArgumentsForExtensionMethod(
              fileOffset,
              _extensionTypeParameterCount,
              0,
              _helper.createVariableGet(extensionThis, fileOffset),
              extensionTypeArguments: _createExtensionTypeArguments()),
          isTearOff: invokeTarget != null);
    }
    return read;
  }

  @override
  Expression buildAssignment(Expression value, {bool voidContext: false}) {
    return _createWrite(fileOffset, value, forEffect: voidContext);
  }

  Expression _createWrite(int offset, Expression value, {bool forEffect}) {
    Expression write;
    if (writeTarget == null) {
      write = _makeInvalidWrite(value);
    } else {
      write = new ExtensionSet(
          extension,
          _createExtensionTypeArguments(),
          _helper.createVariableGet(extensionThis, fileOffset),
          writeTarget,
          value,
          forEffect: forEffect);
    }
    write.fileOffset = offset;
    return write;
  }

  @override
  Expression buildIfNullAssignment(Expression value, DartType type, int offset,
      {bool voidContext: false}) {
    return new IfNullSet(
        _createRead(), _createWrite(fileOffset, value, forEffect: voidContext),
        forEffect: voidContext)
      ..fileOffset = offset;
  }

  @override
  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      bool isPreIncDec: false,
      bool isPostIncDec: false}) {
    Expression binary = _helper.forest
        .createBinary(offset, _createRead(), binaryOperator, value);
    return _createWrite(fileOffset, binary, forEffect: voidContext);
  }

  @override
  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset = TreeNode.noOffset, bool voidContext = false}) {
    Expression value = _forest.createIntLiteral(offset, 1);
    if (voidContext) {
      return buildCompoundAssignment(binaryOperator, value,
          offset: offset, voidContext: voidContext, isPostIncDec: true);
    }
    VariableDeclaration read =
        _helper.forest.createVariableDeclarationForValue(_createRead());
    Expression binary = _helper.forest.createBinary(offset,
        _helper.createVariableGet(read, fileOffset), binaryOperator, value);
    VariableDeclaration write = _helper.forest
        .createVariableDeclarationForValue(
            _createWrite(fileOffset, binary, forEffect: true));
    return new PropertyPostIncDec.onReadOnly(read, write)..fileOffset = offset;
  }

  @override
  Expression doInvocation(
      int offset, List<UnresolvedType> typeArguments, Arguments arguments,
      {bool isTypeArgumentsInForest = false}) {
    if (invokeTarget != null) {
      return _helper.buildExtensionMethodInvocation(
          offset,
          invokeTarget,
          _forest.createArgumentsForExtensionMethod(
              fileOffset,
              _extensionTypeParameterCount,
              invokeTarget.function.typeParameters.length -
                  _extensionTypeParameterCount,
              _helper.createVariableGet(extensionThis, offset),
              extensionTypeArguments: _createExtensionTypeArguments(),
              typeArguments: arguments.types,
              positionalArguments: arguments.positional,
              namedArguments: arguments.named),
          isTearOff: false);
    } else {
      return _helper.forest.createExpressionInvocation(
          adjustForImplicitCall(_plainNameForRead, offset),
          buildSimpleRead(),
          arguments);
    }
  }

  @override
  Generator buildIndexedAccess(Expression index, Token token,
      {bool isNullAware}) {
    assert(isNullAware != null);
    return new IndexedAccessGenerator(_helper, token, buildSimpleRead(), index,
        isNullAware: isNullAware);
  }

  @override
  void printOn(StringSink sink) {
    NameSystem syntheticNames = new NameSystem();
    sink.write(", targetName: ");
    sink.write(targetName);
    sink.write(", readTarget: ");
    printQualifiedNameOn(readTarget, sink, syntheticNames: syntheticNames);
    sink.write(", writeTarget: ");
    printQualifiedNameOn(writeTarget, sink, syntheticNames: syntheticNames);
  }
}

/// A [ExplicitExtensionInstanceAccessGenerator] represents a subexpression
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
  final int extensionTypeArgumentOffset;

  final Extension extension;

  /// The name of the original target;
  final Name targetName;

  /// The static [Member] generated for an instance extension member which is
  /// used for performing a read on this subexpression.
  ///
  /// This can be `null` if the subexpression doesn't have a readable target.
  /// For instance if the subexpression is a setter without a corresponding
  /// getter.
  final Procedure readTarget;

  /// The static [Member] generated for an instance extension member which is
  /// used for performing an invocation on this subexpression.
  ///
  /// This can be `null` if the subexpression doesn't have an invokable target.
  /// For instance if the subexpression is a getter or setter.
  final Procedure invokeTarget;

  /// The static [Member] generated for an instance extension member which is
  /// used for performing a write on this subexpression.
  ///
  /// This can be `null` if the subexpression doesn't have a writable target.
  /// For instance if the subexpression is a final field, a method, or a getter
  /// without a corresponding setter.
  final Procedure writeTarget;

  /// The expression holding the receiver value for the explicit extension
  /// access, that is, `a` in `Extension<int>(a).method<String>()`.
  final Expression receiver;

  /// The type arguments explicitly passed to the explicit extension access,
  /// like `<int>` in `Extension<int>(a).method<String>()`.
  final List<DartType> explicitTypeArguments;

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
      this.extensionTypeParameterCount,
      {this.isNullAware})
      : assert(targetName != null),
        assert(
            readTarget != null || invokeTarget != null || writeTarget != null),
        assert(receiver != null),
        assert(isNullAware != null),
        super(helper, token);

  factory ExplicitExtensionInstanceAccessGenerator.fromBuilder(
      ExpressionGeneratorHelper helper,
      Token token,
      int extensionTypeArgumentOffset,
      Extension extension,
      Name targetName,
      Builder getterBuilder,
      Builder setterBuilder,
      Expression receiver,
      List<DartType> explicitTypeArguments,
      int extensionTypeParameterCount,
      {bool isNullAware}) {
    assert(getterBuilder != null || setterBuilder != null);
    Procedure readTarget;
    Procedure invokeTarget;
    if (getterBuilder != null) {
      assert(!getterBuilder.isStatic);
      if (getterBuilder is AccessErrorBuilder) {
        AccessErrorBuilder error = getterBuilder;
        getterBuilder = error.builder;
        // We should only see an access error here if we've looked up a setter
        // when not explicitly looking for a setter.
        assert(getterBuilder.isSetter);
      } else if (getterBuilder.isGetter) {
        assert(!getterBuilder.isStatic);
        MemberBuilder memberBuilder = getterBuilder;
        readTarget = memberBuilder.readTarget;
      } else if (getterBuilder.isRegularMethod) {
        assert(!getterBuilder.isStatic);
        MemberBuilder procedureBuilder = getterBuilder;
        readTarget = procedureBuilder.readTarget;
        invokeTarget = procedureBuilder.invokeTarget;
      } else if (getterBuilder.isOperator) {
        assert(!getterBuilder.isStatic);
        MemberBuilder memberBuilder = getterBuilder;
        invokeTarget = memberBuilder.invokeTarget;
      } else {
        return unhandled(
            "$getterBuilder (${getterBuilder.runtimeType})",
            "InstanceExtensionAccessGenerator.fromBuilder",
            offsetForToken(token),
            helper.uri);
      }
    }
    Procedure writeTarget;
    if (setterBuilder != null) {
      assert(!setterBuilder.isStatic);
      if (setterBuilder is AccessErrorBuilder) {
        // No setter.
      } else if (setterBuilder.isSetter) {
        assert(!setterBuilder.isStatic);
        MemberBuilder memberBuilder = setterBuilder;
        writeTarget = memberBuilder.writeTarget;
      } else {
        return unhandled(
            "$setterBuilder (${setterBuilder.runtimeType})",
            "InstanceExtensionAccessGenerator.fromBuilder",
            offsetForToken(token),
            helper.uri);
      }
    }
    return new ExplicitExtensionInstanceAccessGenerator(
        helper,
        token,
        extensionTypeArgumentOffset,
        extension,
        targetName,
        readTarget,
        invokeTarget,
        writeTarget,
        receiver,
        explicitTypeArguments,
        extensionTypeParameterCount,
        isNullAware: isNullAware);
  }

  @override
  String get _debugName => "ExplicitExtensionIndexedAccessGenerator";

  @override
  String get _plainNameForRead => targetName.text;

  List<DartType> _createExtensionTypeArguments() {
    return explicitTypeArguments ?? const <DartType>[];
  }

  /// Returns `true` if performing a read operation is a tear off.
  ///
  /// This is the case if [invokeTarget] is non-null, since extension methods
  /// have both a [readTarget] and an [invokeTarget], whereas extension getters
  /// only have a [readTarget].
  bool get isReadTearOff => invokeTarget != null;

  @override
  Expression buildSimpleRead() {
    if (isNullAware) {
      VariableDeclaration variable =
          _helper.forest.createVariableDeclarationForValue(receiver);
      return new NullAwareExtension(
          variable,
          _createRead(_helper.createVariableGet(variable, variable.fileOffset,
              forNullGuardedAccess: true)))
        ..fileOffset = fileOffset;
    } else {
      return _createRead(receiver);
    }
  }

  Expression _createRead(Expression receiver) {
    Expression read;
    if (readTarget == null) {
      read = _makeInvalidRead();
    } else {
      read = _helper.buildExtensionMethodInvocation(
          fileOffset,
          readTarget,
          _helper.forest.createArgumentsForExtensionMethod(
              fileOffset, extensionTypeParameterCount, 0, receiver,
              extensionTypeArguments: _createExtensionTypeArguments(),
              extensionTypeArgumentOffset: extensionTypeArgumentOffset),
          isTearOff: isReadTearOff);
    }
    return read;
  }

  @override
  Expression buildAssignment(Expression value, {bool voidContext: false}) {
    if (isNullAware) {
      VariableDeclaration variable =
          _helper.forest.createVariableDeclarationForValue(receiver);
      return new NullAwareExtension(
          variable,
          _createWrite(
              fileOffset,
              _helper.createVariableGet(variable, variable.fileOffset,
                  forNullGuardedAccess: true),
              value,
              forEffect: voidContext))
        ..fileOffset = fileOffset;
    } else {
      return _createWrite(fileOffset, receiver, value, forEffect: voidContext);
    }
  }

  Expression _createWrite(int offset, Expression receiver, Expression value,
      {bool forEffect}) {
    Expression write;
    if (writeTarget == null) {
      write = _makeInvalidWrite(value);
    } else {
      write = new ExtensionSet(
          extension, explicitTypeArguments, receiver, writeTarget, value,
          forEffect: forEffect);
    }
    write.fileOffset = offset;
    return write;
  }

  @override
  Expression buildIfNullAssignment(Expression value, DartType type, int offset,
      {bool voidContext: false}) {
    if (isNullAware) {
      VariableDeclaration variable =
          _helper.forest.createVariableDeclarationForValue(receiver);
      Expression read = _createRead(_helper.createVariableGet(
          variable, receiver.fileOffset,
          forNullGuardedAccess: true));
      Expression write = _createWrite(
          fileOffset,
          _helper.createVariableGet(variable, receiver.fileOffset,
              forNullGuardedAccess: true),
          value,
          forEffect: voidContext);
      return new NullAwareExtension(
          variable,
          new IfNullSet(read, write, forEffect: voidContext)
            ..fileOffset = offset)
        ..fileOffset = fileOffset;
    } else {
      return new IfNullPropertySet(receiver, targetName, value,
          forEffect: voidContext,
          readOffset: fileOffset,
          writeOffset: fileOffset)
        ..fileOffset = offset;
    }
  }

  @override
  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      bool isPreIncDec: false,
      bool isPostIncDec: false}) {
    if (isNullAware) {
      VariableDeclaration variable =
          _helper.forest.createVariableDeclarationForValue(receiver);
      Expression binary = _helper.forest.createBinary(
          offset,
          _createRead(_helper.createVariableGet(variable, receiver.fileOffset,
              forNullGuardedAccess: true)),
          binaryOperator,
          value);
      Expression write = _createWrite(
          fileOffset,
          _helper.createVariableGet(variable, receiver.fileOffset,
              forNullGuardedAccess: true),
          binary,
          forEffect: voidContext);
      return new NullAwareExtension(variable, write)..fileOffset = offset;
    } else {
      return new CompoundExtensionSet(extension, explicitTypeArguments,
          receiver, targetName, readTarget, binaryOperator, value, writeTarget,
          forEffect: voidContext,
          readOffset: fileOffset,
          binaryOffset: offset,
          writeOffset: fileOffset)
        ..fileOffset = offset;
    }
  }

  @override
  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset = TreeNode.noOffset, bool voidContext = false}) {
    Expression value = _forest.createIntLiteral(offset, 1);
    if (voidContext) {
      return buildCompoundAssignment(binaryOperator, value,
          offset: offset, voidContext: voidContext, isPostIncDec: true);
    } else if (isNullAware) {
      VariableDeclaration variable =
          _helper.forest.createVariableDeclarationForValue(receiver);
      VariableDeclaration read = _helper.forest
          .createVariableDeclarationForValue(_createRead(
              _helper.createVariableGet(variable, receiver.fileOffset,
                  forNullGuardedAccess: true)));
      Expression binary = _helper.forest.createBinary(offset,
          _helper.createVariableGet(read, fileOffset), binaryOperator, value);
      VariableDeclaration write = _helper.forest
          .createVariableDeclarationForValue(_createWrite(
              fileOffset,
              _helper.createVariableGet(variable, receiver.fileOffset,
                  forNullGuardedAccess: true),
              binary,
              forEffect: voidContext)
            ..fileOffset = fileOffset);
      return new NullAwareExtension(
          variable, new LocalPostIncDec(read, write)..fileOffset = offset)
        ..fileOffset = fileOffset;
    } else {
      VariableDeclaration variable =
          _helper.forest.createVariableDeclarationForValue(receiver);
      VariableDeclaration read = _helper.forest
          .createVariableDeclarationForValue(_createRead(
              _helper.createVariableGet(variable, receiver.fileOffset)));
      Expression binary = _helper.forest.createBinary(offset,
          _helper.createVariableGet(read, fileOffset), binaryOperator, value);
      VariableDeclaration write = _helper.forest
          .createVariableDeclarationForValue(_createWrite(fileOffset,
              _helper.createVariableGet(variable, receiver.fileOffset), binary,
              forEffect: voidContext)
            ..fileOffset = fileOffset);
      return new PropertyPostIncDec(variable, read, write)..fileOffset = offset;
    }
  }

  @override
  Expression doInvocation(
      int offset, List<UnresolvedType> typeArguments, Arguments arguments,
      {bool isTypeArgumentsInForest = false}) {
    VariableDeclaration receiverVariable;
    Expression receiverExpression = receiver;
    if (isNullAware) {
      receiverVariable =
          _helper.forest.createVariableDeclarationForValue(receiver);
      receiverExpression = _helper.createVariableGet(
          receiverVariable, receiverVariable.fileOffset,
          forNullGuardedAccess: true);
    }
    Expression invocation;
    if (invokeTarget != null) {
      invocation = _helper.buildExtensionMethodInvocation(
          fileOffset,
          invokeTarget,
          _forest.createArgumentsForExtensionMethod(
              fileOffset,
              extensionTypeParameterCount,
              invokeTarget.function.typeParameters.length -
                  extensionTypeParameterCount,
              receiverExpression,
              extensionTypeArguments: _createExtensionTypeArguments(),
              extensionTypeArgumentOffset: extensionTypeArgumentOffset,
              typeArguments: arguments.types,
              positionalArguments: arguments.positional,
              namedArguments: arguments.named),
          isTearOff: false);
    } else {
      invocation = _helper.forest.createExpressionInvocation(
          adjustForImplicitCall(_plainNameForRead, offset),
          _createRead(receiverExpression),
          arguments);
    }
    if (isNullAware) {
      assert(receiverVariable != null);
      return new NullAwareExtension(receiverVariable, invocation)
        ..fileOffset = fileOffset;
    } else {
      return invocation;
    }
  }

  @override
  Generator buildIndexedAccess(Expression index, Token token,
      {bool isNullAware}) {
    assert(isNullAware != null);
    return new IndexedAccessGenerator(_helper, token, buildSimpleRead(), index,
        isNullAware: isNullAware);
  }

  @override
  void printOn(StringSink sink) {
    NameSystem syntheticNames = new NameSystem();
    sink.write(", targetName: ");
    sink.write(targetName);
    sink.write(", readTarget: ");
    printQualifiedNameOn(readTarget, sink, syntheticNames: syntheticNames);
    sink.write(", writeTarget: ");
    printQualifiedNameOn(writeTarget, sink, syntheticNames: syntheticNames);
  }
}

class ExplicitExtensionIndexedAccessGenerator extends Generator {
  /// The file offset used for the explicit extension application type
  /// arguments.
  final int extensionTypeArgumentOffset;

  final Extension extension;

  /// The static [Member] generated for the [] operation.
  ///
  /// This can be `null` if the extension doesn't have an [] method.
  final Procedure readTarget;

  /// The static [Member] generated for the []= operation.
  ///
  /// This can be `null` if the extension doesn't have an []= method.
  final Procedure writeTarget;

  /// The expression holding the receiver value for the explicit extension
  /// access, that is, `a` in `Extension<int>(a)[index]`.
  final Expression receiver;

  /// The index expression;
  final Expression index;

  /// The type arguments explicitly passed to the explicit extension access,
  /// like `<int>` in `Extension<int>(a)[b]`.
  final List<DartType> explicitTypeArguments;

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
      this.extensionTypeParameterCount,
      {this.isNullAware})
      : assert(readTarget != null || writeTarget != null),
        assert(receiver != null),
        assert(isNullAware != null),
        super(helper, token);

  factory ExplicitExtensionIndexedAccessGenerator.fromBuilder(
      ExpressionGeneratorHelper helper,
      Token token,
      int extensionTypeArgumentOffset,
      Extension extension,
      Builder getterBuilder,
      Builder setterBuilder,
      Expression receiver,
      Expression index,
      List<DartType> explicitTypeArguments,
      int extensionTypeParameterCount,
      {bool isNullAware}) {
    assert(isNullAware != null);
    Procedure readTarget;
    if (getterBuilder != null) {
      if (getterBuilder is AccessErrorBuilder) {
        AccessErrorBuilder error = getterBuilder;
        getterBuilder = error.builder;
        // We should only see an access error here if we've looked up a setter
        // when not explicitly looking for a setter.
        assert(getterBuilder is MemberBuilder);
      } else if (getterBuilder is MemberBuilder) {
        MemberBuilder procedureBuilder = getterBuilder;
        readTarget = procedureBuilder.member;
      } else {
        return unhandled(
            "${getterBuilder.runtimeType}",
            "InstanceExtensionAccessGenerator.fromBuilder",
            offsetForToken(token),
            helper.uri);
      }
    }
    Procedure writeTarget;
    if (setterBuilder is MemberBuilder) {
      MemberBuilder memberBuilder = setterBuilder;
      writeTarget = memberBuilder.member;
    }
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
        isNullAware: isNullAware);
  }

  List<DartType> _createExtensionTypeArguments() {
    return explicitTypeArguments ?? const <DartType>[];
  }

  String get _plainNameForRead => "[]";

  String get _debugName => "ExplicitExtensionIndexedAccessGenerator";

  @override
  Expression buildSimpleRead() {
    if (readTarget == null) {
      return _makeInvalidRead();
    }
    VariableDeclaration variable;
    Expression receiverValue;
    if (isNullAware) {
      variable = _forest.createVariableDeclarationForValue(receiver);
      receiverValue = _helper.createVariableGet(variable, fileOffset,
          forNullGuardedAccess: true);
    } else {
      receiverValue = receiver;
    }
    Expression result = _helper.buildExtensionMethodInvocation(
        fileOffset,
        readTarget,
        _forest.createArgumentsForExtensionMethod(
            fileOffset, extensionTypeParameterCount, 0, receiverValue,
            extensionTypeArguments: _createExtensionTypeArguments(),
            extensionTypeArgumentOffset: extensionTypeArgumentOffset,
            positionalArguments: <Expression>[index]),
        isTearOff: false);
    if (isNullAware) {
      result = new NullAwareMethodInvocation(variable, result)
        ..fileOffset = fileOffset;
    }
    return result;
  }

  @override
  Expression buildAssignment(Expression value, {bool voidContext: false}) {
    if (writeTarget == null) {
      return _makeInvalidWrite(value);
    }
    VariableDeclaration variable;
    Expression receiverValue;
    if (isNullAware) {
      variable = _forest.createVariableDeclarationForValue(receiver);
      receiverValue = _helper.createVariableGet(variable, fileOffset,
          forNullGuardedAccess: true);
    } else {
      receiverValue = receiver;
    }
    Expression result;
    if (voidContext) {
      result = _helper.buildExtensionMethodInvocation(
          fileOffset,
          writeTarget,
          _forest.createArgumentsForExtensionMethod(
              fileOffset, extensionTypeParameterCount, 0, receiverValue,
              extensionTypeArguments: _createExtensionTypeArguments(),
              extensionTypeArgumentOffset: extensionTypeArgumentOffset,
              positionalArguments: <Expression>[index, value]),
          isTearOff: false);
    } else {
      result = new ExtensionIndexSet(extension, explicitTypeArguments,
          receiverValue, writeTarget, index, value)
        ..fileOffset = fileOffset;
    }
    if (isNullAware) {
      result = new NullAwareMethodInvocation(variable, result)
        ..fileOffset = fileOffset;
    }
    return result;
  }

  @override
  Expression buildIfNullAssignment(Expression value, DartType type, int offset,
      {bool voidContext: false}) {
    VariableDeclaration variable;
    Expression receiverValue;
    if (isNullAware) {
      variable = _forest.createVariableDeclarationForValue(receiver);
      receiverValue = _helper.createVariableGet(variable, fileOffset,
          forNullGuardedAccess: true);
    } else {
      receiverValue = receiver;
    }
    Expression result = new IfNullExtensionIndexSet(
        extension,
        explicitTypeArguments,
        receiverValue,
        readTarget,
        writeTarget,
        index,
        value,
        readOffset: fileOffset,
        testOffset: offset,
        writeOffset: fileOffset,
        forEffect: voidContext)
      ..fileOffset = offset;
    if (isNullAware) {
      result = new NullAwareMethodInvocation(variable, result)
        ..fileOffset = fileOffset;
    }
    return result;
  }

  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      bool isPreIncDec: false,
      bool isPostIncDec: false}) {
    VariableDeclaration variable;
    Expression receiverValue;
    if (isNullAware) {
      variable = _forest.createVariableDeclarationForValue(receiver);
      receiverValue = _helper.createVariableGet(variable, fileOffset,
          forNullGuardedAccess: true);
    } else {
      receiverValue = receiver;
    }
    Expression result = new CompoundExtensionIndexSet(
        extension,
        explicitTypeArguments,
        receiverValue,
        readTarget,
        writeTarget,
        index,
        binaryOperator,
        value,
        readOffset: fileOffset,
        binaryOffset: offset,
        writeOffset: fileOffset,
        forEffect: voidContext,
        forPostIncDec: isPostIncDec);
    if (isNullAware) {
      result = new NullAwareMethodInvocation(variable, result)
        ..fileOffset = fileOffset;
    }
    return result;
  }

  @override
  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset = TreeNode.noOffset, bool voidContext = false}) {
    Expression value = _forest.createIntLiteral(offset, 1);
    return buildCompoundAssignment(binaryOperator, value,
        offset: offset, voidContext: voidContext, isPostIncDec: true);
  }

  @override
  Expression doInvocation(
      int offset, List<UnresolvedType> typeArguments, Arguments arguments,
      {bool isTypeArgumentsInForest = false}) {
    return _helper.forest
        .createExpressionInvocation(offset, buildSimpleRead(), arguments);
  }

  @override
  Generator buildIndexedAccess(Expression index, Token token,
      {bool isNullAware}) {
    assert(isNullAware != null);
    return new IndexedAccessGenerator(_helper, token, buildSimpleRead(), index,
        isNullAware: isNullAware);
  }

  @override
  void printOn(StringSink sink) {
    NameSystem syntheticNames = new NameSystem();
    sink.write(", index: ");
    printNodeOn(index, sink, syntheticNames: syntheticNames);
    sink.write(", readTarget: ");
    printQualifiedNameOn(readTarget, sink, syntheticNames: syntheticNames);
    sink.write(", writeTarget: ");
    printQualifiedNameOn(writeTarget, sink, syntheticNames: syntheticNames);
  }
}

/// A [ExplicitExtensionAccessGenerator] represents a subexpression whose
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
  final List<DartType> explicitTypeArguments;

  ExplicitExtensionAccessGenerator(
      ExpressionGeneratorHelper helper,
      Token token,
      this.extensionBuilder,
      this.receiver,
      this.explicitTypeArguments)
      : super(helper, token);

  @override
  String get _plainNameForRead {
    return unsupported(
        "ExplicitExtensionAccessGenerator.plainNameForRead", fileOffset, _uri);
  }

  @override
  String get _debugName => "ExplicitExtensionAccessGenerator";

  @override
  Expression buildSimpleRead() {
    return _makeInvalidRead();
  }

  @override
  Expression buildAssignment(Expression value, {bool voidContext: false}) {
    return _makeInvalidWrite(value);
  }

  @override
  Expression buildIfNullAssignment(Expression value, DartType type, int offset,
      {bool voidContext: false}) {
    return _makeInvalidRead();
  }

  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      bool isPreIncDec: false,
      bool isPostIncDec: false}) {
    return _makeInvalidRead();
  }

  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset: TreeNode.noOffset, bool voidContext: false}) {
    return _makeInvalidRead();
  }

  Generator _createInstanceAccess(Token token, Name name,
      {bool isNullAware: false}) {
    Builder getter = extensionBuilder.lookupLocalMemberByName(name);
    if (getter != null && (getter.isStatic || getter.isField)) {
      getter = null;
    }
    Builder setter =
        extensionBuilder.lookupLocalMemberByName(name, setter: true);
    if (setter != null && setter.isStatic) {
      setter = null;
    }
    if (getter == null && setter == null) {
      return new UnresolvedNameGenerator(_helper, token, name);
    }
    return new ExplicitExtensionInstanceAccessGenerator.fromBuilder(
        _helper,
        token,
        // TODO(johnniwinther): Improve this. This is the name of the extension
        // and not the type arguments (or arguments if type arguments are
        // omitted).
        fileOffset,
        extensionBuilder.extension,
        name,
        getter,
        setter,
        receiver,
        explicitTypeArguments,
        extensionBuilder.typeParameters?.length ?? 0,
        isNullAware: isNullAware);
  }

  /* Expression | Generator */ buildPropertyAccess(
      IncompleteSendGenerator send, int operatorOffset, bool isNullAware) {
    if (_helper.constantContext != ConstantContext.none) {
      _helper.addProblem(
          messageNotAConstantExpression, fileOffset, token.length);
    }
    Generator generator =
        _createInstanceAccess(send.token, send.name, isNullAware: isNullAware);
    if (send.arguments != null) {
      return generator.doInvocation(
          offsetForToken(send.token), send.typeArguments, send.arguments,
          isTypeArgumentsInForest: send.isTypeArgumentsInForest);
    } else {
      return generator;
    }
  }

  @override
  buildBinaryOperation(Token token, Name binaryName, Expression right) {
    int fileOffset = offsetForToken(token);
    Generator generator = _createInstanceAccess(token, binaryName);
    return generator.doInvocation(fileOffset, null,
        _forest.createArguments(fileOffset, <Expression>[right]));
  }

  @override
  buildUnaryOperation(Token token, Name unaryName) {
    int fileOffset = offsetForToken(token);
    Generator generator = _createInstanceAccess(token, unaryName);
    return generator.doInvocation(
        fileOffset, null, _forest.createArgumentsEmpty(fileOffset));
  }

  @override
  doInvocation(
      int offset, List<UnresolvedType> typeArguments, Arguments arguments,
      {bool isTypeArgumentsInForest = false}) {
    Generator generator = _createInstanceAccess(token, callName);
    return generator.doInvocation(offset, typeArguments, arguments,
        isTypeArgumentsInForest: isTypeArgumentsInForest);
  }

  @override
  Expression _makeInvalidRead() {
    return _helper.buildProblem(messageExplicitExtensionAsExpression,
        fileOffset, lengthForToken(token));
  }

  @override
  Expression _makeInvalidWrite(Expression value) {
    return _helper.buildProblem(
        messageExplicitExtensionAsLvalue, fileOffset, lengthForToken(token));
  }

  @override
  Generator buildIndexedAccess(Expression index, Token token,
      {bool isNullAware}) {
    assert(isNullAware != null);
    Builder getter = extensionBuilder.lookupLocalMemberByName(indexGetName);
    Builder setter = extensionBuilder.lookupLocalMemberByName(indexSetName);
    if (getter == null && setter == null) {
      return new UnresolvedNameGenerator(_helper, token, indexGetName);
    }

    return new ExplicitExtensionIndexedAccessGenerator.fromBuilder(
        _helper,
        token,
        // TODO(johnniwinther): Improve this. This is the name of the extension
        // and not the type arguments (or arguments if type arguments are
        // omitted).
        fileOffset,
        extensionBuilder.extension,
        getter,
        setter,
        receiver,
        index,
        explicitTypeArguments,
        extensionBuilder.typeParameters?.length ?? 0,
        isNullAware: isNullAware);
  }

  @override
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
      ExpressionGeneratorHelper helper, Token token, this.builder)
      : super(helper, token);

  @override
  String get _plainNameForRead => 'loadLibrary';

  @override
  String get _debugName => "LoadLibraryGenerator";

  @override
  Expression buildSimpleRead() {
    builder.importDependency.targetLibrary;
    LoadLibraryTearOff read = new LoadLibraryTearOff(
        builder.importDependency, builder.createTearoffMethod(_helper.forest))
      ..fileOffset = fileOffset;
    return read;
  }

  @override
  Expression buildAssignment(Expression value, {bool voidContext: false}) {
    return _makeInvalidWrite(value);
  }

  @override
  Expression buildIfNullAssignment(Expression value, DartType type, int offset,
      {bool voidContext: false}) {
    Expression read = buildSimpleRead();
    Expression write = _makeInvalidWrite(value);
    return new IfNullSet(read, write, forEffect: voidContext)
      ..fileOffset = offset;
  }

  @override
  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      bool isPreIncDec: false,
      bool isPostIncDec: false}) {
    Expression binary = _helper.forest
        .createBinary(offset, buildSimpleRead(), binaryOperator, value);
    return _makeInvalidWrite(binary);
  }

  @override
  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset = TreeNode.noOffset, bool voidContext = false}) {
    Expression value = _forest.createIntLiteral(offset, 1);
    return buildCompoundAssignment(binaryOperator, value,
        offset: offset, voidContext: voidContext, isPostIncDec: true);
  }

  @override
  Expression doInvocation(
      int offset, List<UnresolvedType> typeArguments, Arguments arguments,
      {bool isTypeArgumentsInForest = false}) {
    if (_forest.argumentsPositional(arguments).length > 0 ||
        _forest.argumentsNamed(arguments).length > 0) {
      _helper.addProblemErrorIfConst(
          messageLoadLibraryTakesNoArguments, offset, 'loadLibrary'.length);
    }
    return builder.createLoadLibrary(offset, _forest, arguments);
  }

  @override
  Generator buildIndexedAccess(Expression index, Token token,
      {bool isNullAware}) {
    assert(isNullAware != null);
    return new IndexedAccessGenerator(_helper, token, buildSimpleRead(), index,
        isNullAware: isNullAware);
  }

  @override
  void printOn(StringSink sink) {
    sink.write(", builder: ");
    sink.write(builder);
  }
}

class DeferredAccessGenerator extends Generator {
  final PrefixUseGenerator prefixGenerator;

  final Generator suffixGenerator;

  DeferredAccessGenerator(ExpressionGeneratorHelper helper, Token token,
      this.prefixGenerator, this.suffixGenerator)
      : super(helper, token);

  @override
  Expression buildSimpleRead() {
    return _helper.wrapInDeferredCheck(suffixGenerator.buildSimpleRead(),
        prefixGenerator.prefix, token.charOffset);
  }

  @override
  Expression buildAssignment(Expression value, {bool voidContext: false}) {
    return _helper.wrapInDeferredCheck(
        suffixGenerator.buildAssignment(value, voidContext: voidContext),
        prefixGenerator.prefix,
        token.charOffset);
  }

  @override
  Expression buildIfNullAssignment(Expression value, DartType type, int offset,
      {bool voidContext: false}) {
    return _helper.wrapInDeferredCheck(
        suffixGenerator.buildIfNullAssignment(value, type, offset,
            voidContext: voidContext),
        prefixGenerator.prefix,
        token.charOffset);
  }

  @override
  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      bool isPreIncDec: false,
      bool isPostIncDec: false}) {
    return _helper.wrapInDeferredCheck(
        suffixGenerator.buildCompoundAssignment(binaryOperator, value,
            offset: offset,
            voidContext: voidContext,
            isPreIncDec: isPreIncDec,
            isPostIncDec: isPostIncDec),
        prefixGenerator.prefix,
        token.charOffset);
  }

  @override
  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset: TreeNode.noOffset, bool voidContext: false}) {
    return _helper.wrapInDeferredCheck(
        suffixGenerator.buildPostfixIncrement(binaryOperator,
            offset: offset, voidContext: voidContext),
        prefixGenerator.prefix,
        token.charOffset);
  }

  @override
  buildPropertyAccess(
      IncompleteSendGenerator send, int operatorOffset, bool isNullAware) {
    Object propertyAccess =
        suffixGenerator.buildPropertyAccess(send, operatorOffset, isNullAware);
    if (propertyAccess is Generator) {
      return new DeferredAccessGenerator(
          _helper, token, prefixGenerator, propertyAccess);
    } else {
      Expression expression = propertyAccess;
      return _helper.wrapInDeferredCheck(
          expression, prefixGenerator.prefix, token.charOffset);
    }
  }

  @override
  String get _plainNameForRead {
    return unsupported("deferredAccessor.plainNameForRead", fileOffset, _uri);
  }

  @override
  String get _debugName => "DeferredAccessGenerator";

  @override
  TypeBuilder buildTypeWithResolvedArguments(
      NullabilityBuilder nullabilityBuilder, List<UnresolvedType> arguments) {
    String name = "${prefixGenerator._plainNameForRead}."
        "${suffixGenerator._plainNameForRead}";
    TypeBuilder type = suffixGenerator.buildTypeWithResolvedArguments(
        nullabilityBuilder, arguments);
    LocatedMessage message;
    if (type is NamedTypeBuilder &&
        type.declaration is InvalidTypeDeclarationBuilder) {
      InvalidTypeDeclarationBuilder declaration = type.declaration;
      message = declaration.message;
    } else {
      int charOffset = offsetForToken(prefixGenerator.token);
      message = templateDeferredTypeAnnotation
          .withArguments(
              _helper.buildDartType(new UnresolvedType(type, charOffset, _uri)),
              prefixGenerator._plainNameForRead,
              _helper.libraryBuilder.isNonNullableByDefault)
          .withLocation(
              _uri, charOffset, lengthOfSpan(prefixGenerator.token, token));
    }
    // TODO(johnniwinther): Could we use a FixedTypeBuilder(InvalidType()) here?
    NamedTypeBuilder result = new NamedTypeBuilder(
        name,
        nullabilityBuilder,
        /* arguments = */ null,
        /* fileUri = */ null,
        /* charOffset = */ null);
    _helper.libraryBuilder.addProblem(
        message.messageObject, message.charOffset, message.length, message.uri);
    result.bind(result.buildInvalidTypeDeclarationBuilder(message));
    return result;
  }

  @override
  doInvocation(
      int offset, List<UnresolvedType> typeArguments, Arguments arguments,
      {bool isTypeArgumentsInForest = false}) {
    Object suffix = suffixGenerator.doInvocation(
        offset, typeArguments, arguments,
        isTypeArgumentsInForest: isTypeArgumentsInForest);
    if (suffix is Expression) {
      return _helper.wrapInDeferredCheck(
          suffix, prefixGenerator.prefix, fileOffset);
    } else {
      return new DeferredAccessGenerator(
          _helper, token, prefixGenerator, suffix);
    }
  }

  @override
  Expression invokeConstructor(
      List<UnresolvedType> typeArguments,
      String name,
      Arguments arguments,
      Token nameToken,
      Token nameLastToken,
      Constness constness) {
    return _helper.wrapInDeferredCheck(
        suffixGenerator.invokeConstructor(typeArguments, name, arguments,
            nameToken, nameLastToken, constness),
        prefixGenerator.prefix,
        offsetForToken(suffixGenerator.token));
  }

  @override
  Generator buildIndexedAccess(Expression index, Token token,
      {bool isNullAware}) {
    assert(isNullAware != null);
    return new IndexedAccessGenerator(_helper, token, buildSimpleRead(), index,
        isNullAware: isNullAware);
  }

  @override
  void printOn(StringSink sink) {
    sink.write(", prefixGenerator: ");
    sink.write(prefixGenerator);
    sink.write(", suffixGenerator: ");
    sink.write(suffixGenerator);
  }
}

/// [TypeUseGenerator] represents the subexpression whose prefix is the name of
/// a class, enum, type variable, typedef, mixin declaration, extension
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
class TypeUseGenerator extends ReadOnlyAccessGenerator {
  final TypeDeclarationBuilder declaration;

  TypeUseGenerator(ExpressionGeneratorHelper helper, Token token,
      this.declaration, String targetName)
      : super(
            helper,
            token,
            null,
            targetName,
            // TODO(johnniwinther): InvalidTypeDeclarationBuilder is currently
            // misused for import conflict.
            declaration is InvalidTypeDeclarationBuilder
                ? ReadOnlyAccessKind.InvalidDeclaration
                : ReadOnlyAccessKind.TypeLiteral);

  @override
  String get _debugName => "TypeUseGenerator";

  @override
  TypeBuilder buildTypeWithResolvedArguments(
      NullabilityBuilder nullabilityBuilder, List<UnresolvedType> arguments) {
    if (declaration.isExtension) {
      // Extension declarations cannot be used as types.
      return super
          .buildTypeWithResolvedArguments(nullabilityBuilder, arguments);
    }
    if (arguments != null) {
      int expected = declaration.typeVariablesCount;
      if (arguments.length != expected) {
        // Build the type arguments to report any errors they may have.
        _helper.buildDartTypeArguments(arguments);
        _helper.warnTypeArgumentsMismatch(
            declaration.name, expected, fileOffset);
        // We ignore the provided arguments, which will in turn return the
        // raw type below.
        // TODO(sigmund): change to use an InvalidType and include the raw type
        // as a recovery node once the IR can represent it (Issue #29840).
        arguments = null;
      }
    } else if (declaration.typeVariablesCount != 0) {
      _helper.addProblem(
          templateMissingExplicitTypeArguments
              .withArguments(declaration.typeVariablesCount),
          fileOffset,
          lengthForToken(token));
    }

    List<TypeBuilder> argumentBuilders;
    if (arguments != null) {
      argumentBuilders = new List<TypeBuilder>.filled(arguments.length, null);
      for (int i = 0; i < argumentBuilders.length; i++) {
        argumentBuilders[i] = _helper
            .validateTypeUse(arguments[i],
                nonInstanceAccessIsError: false,
                allowPotentiallyConstantType:
                    _helper.libraryBuilder.isNonNullableByDefault &&
                        _helper.inIsOrAsOperatorType)
            .builder;
      }
    }
    return new NamedTypeBuilder(
        targetName, nullabilityBuilder, argumentBuilders, _uri, fileOffset)
      ..bind(declaration);
  }

  @override
  Expression invokeConstructor(
      List<UnresolvedType> typeArguments,
      String name,
      Arguments arguments,
      Token nameToken,
      Token nameLastToken,
      Constness constness) {
    return _helper.buildConstructorInvocation(
        declaration,
        nameToken,
        nameLastToken,
        arguments,
        name,
        typeArguments,
        offsetForToken(nameToken ?? token),
        constness);
  }

  @override
  void printOn(StringSink sink) {
    sink.write(", declaration: ");
    sink.write(declaration);
    sink.write(", plainNameForRead: ");
    sink.write(_plainNameForRead);
  }

  @override
  Expression get expression {
    if (super.expression == null) {
      if (declaration is InvalidTypeDeclarationBuilder) {
        InvalidTypeDeclarationBuilder declaration = this.declaration;
        super.expression = _helper.buildProblemErrorIfConst(
            declaration.message.messageObject, fileOffset, token.length);
      } else {
        super.expression = _forest.createTypeLiteral(
            offsetForToken(token),
            _helper.buildDartType(
                new UnresolvedType(
                    buildTypeWithResolvedArguments(
                        _helper.libraryBuilder.nonNullableBuilder, null),
                    fileOffset,
                    _uri),
                nonInstanceAccessIsError: true));
      }
    }
    return super.expression;
  }

  @override
  buildPropertyAccess(
      IncompleteSendGenerator send, int operatorOffset, bool isNullAware) {
    Name name = send.name;
    Arguments arguments = send.arguments;

    TypeDeclarationBuilder declarationBuilder = declaration;
    if (declarationBuilder is TypeAliasBuilder) {
      TypeAliasBuilder aliasBuilder = declarationBuilder;
      declarationBuilder = aliasBuilder.unaliasDeclaration(null,
          isInvocation: true,
          invocationCharOffset: this.fileOffset,
          invocationFileUri: _uri);
    }
    if (declarationBuilder is DeclarationBuilder) {
      DeclarationBuilder declaration = declarationBuilder;
      Builder member = declaration.findStaticBuilder(
          name.text, offsetForToken(send.token), _uri, _helper.libraryBuilder);

      Generator generator;
      if (member == null) {
        // If we find a setter, [member] is an [AccessErrorBuilder], not null.
        if (send is IncompletePropertyAccessGenerator) {
          generator = new UnresolvedNameGenerator(_helper, send.token, name);
        } else {
          return _helper.buildConstructorInvocation(
              declaration,
              send.token,
              send.token,
              arguments,
              name.text,
              send.typeArguments,
              token.charOffset,
              Constness.implicit,
              isTypeArgumentsInForest: send.isTypeArgumentsInForest);
        }
      } else if (member is AmbiguousBuilder) {
        return _helper.buildProblem(
            member.message, member.charOffset, name.text.length);
      } else {
        Builder setter;
        if (member.isSetter) {
          setter = member;
          member = null;
        } else if (member.isGetter) {
          setter = declaration.findStaticBuilder(
              name.text, fileOffset, _uri, _helper.libraryBuilder,
              isSetter: true);
        } else if (member.isField) {
          MemberBuilder fieldBuilder = member;
          if (!fieldBuilder.isAssignable) {
            setter = declaration.findStaticBuilder(
                name.text, fileOffset, _uri, _helper.libraryBuilder,
                isSetter: true);
          } else {
            setter = member;
          }
        }
        generator = new StaticAccessGenerator.fromBuilder(
            _helper,
            name.text,
            send.token,
            member is MemberBuilder ? member : null,
            setter is MemberBuilder ? setter : null,
            typeOffset: fileOffset,
            isNullAware: isNullAware);
      }

      return arguments == null
          ? generator
          : generator.doInvocation(
              offsetForToken(send.token), send.typeArguments, arguments,
              isTypeArgumentsInForest: send.isTypeArgumentsInForest);
    } else {
      // `SomeType?.toString` is the same as `SomeType.toString`, not
      // `(SomeType).toString`.
      return super.buildPropertyAccess(send, operatorOffset, isNullAware);
    }
  }

  @override
  doInvocation(
      int offset, List<UnresolvedType> typeArguments, Arguments arguments,
      {bool isTypeArgumentsInForest = false}) {
    if (declaration.isExtension) {
      ExtensionBuilder extensionBuilder = declaration;
      if (arguments.positional.length != 1 || arguments.named.isNotEmpty) {
        return _helper.buildProblem(messageExplicitExtensionArgumentMismatch,
            fileOffset, lengthForToken(token));
      }
      List<DartType> explicitTypeArguments =
          getExplicitTypeArguments(arguments);
      if (explicitTypeArguments != null) {
        int typeParameterCount = extensionBuilder.typeParameters?.length ?? 0;
        if (explicitTypeArguments.length != typeParameterCount) {
          return _helper.buildProblem(
              templateExplicitExtensionTypeArgumentMismatch.withArguments(
                  extensionBuilder.name, typeParameterCount),
              fileOffset,
              lengthForToken(token));
        }
      }
      // TODO(johnniwinther): Check argument and type argument count.
      return new ExplicitExtensionAccessGenerator(_helper, token, declaration,
          arguments.positional.single, explicitTypeArguments);
    } else {
      return _helper.buildConstructorInvocation(declaration, token, token,
          arguments, "", typeArguments, token.charOffset, Constness.implicit,
          isTypeArgumentsInForest: isTypeArgumentsInForest);
    }
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
class ReadOnlyAccessGenerator extends Generator {
  final String targetName;

  Expression expression;

  final ReadOnlyAccessKind kind;

  ReadOnlyAccessGenerator(ExpressionGeneratorHelper helper, Token token,
      this.expression, this.targetName, this.kind)
      : super(helper, token);

  @override
  String get _debugName => "ReadOnlyAccessGenerator";

  @override
  String get _plainNameForRead => targetName;

  @override
  Expression buildSimpleRead() => _createRead();

  Expression _createRead() => expression;

  Expression _makeInvalidWrite(Expression value) {
    switch (kind) {
      case ReadOnlyAccessKind.ConstVariable:
        assert(targetName != null);
        return _helper.buildProblem(
            templateCannotAssignToConstVariable.withArguments(targetName),
            fileOffset,
            lengthForToken(token));
      case ReadOnlyAccessKind.FinalVariable:
        assert(targetName != null);
        return _helper.buildProblem(
            templateCannotAssignToFinalVariable.withArguments(targetName),
            fileOffset,
            lengthForToken(token));
      case ReadOnlyAccessKind.ExtensionThis:
        return _helper.buildProblem(messageCannotAssignToExtensionThis,
            fileOffset, lengthForToken(token));
      case ReadOnlyAccessKind.TypeLiteral:
        return _helper.buildProblem(messageCannotAssignToTypeLiteral,
            fileOffset, lengthForToken(token));
      case ReadOnlyAccessKind.ParenthesizedExpression:
        return _helper.buildProblem(
            messageCannotAssignToParenthesizedExpression,
            fileOffset,
            lengthForToken(token));
      case ReadOnlyAccessKind.LetVariable:
      case ReadOnlyAccessKind.InvalidDeclaration:
        break;
    }
    return super._makeInvalidWrite(value);
  }

  @override
  Expression buildAssignment(Expression value, {bool voidContext: false}) {
    return _makeInvalidWrite(value);
  }

  @override
  Expression buildIfNullAssignment(Expression value, DartType type, int offset,
      {bool voidContext: false}) {
    Expression read = _createRead();
    Expression write = _makeInvalidWrite(value);
    return new IfNullSet(read, write, forEffect: voidContext)
      ..fileOffset = offset;
  }

  @override
  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      bool isPreIncDec: false,
      bool isPostIncDec: false}) {
    Expression binary = _helper.forest
        .createBinary(offset, _createRead(), binaryOperator, value);
    return _makeInvalidWrite(binary);
  }

  @override
  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset = TreeNode.noOffset, bool voidContext = false}) {
    Expression value = _forest.createIntLiteral(offset, 1);
    return buildCompoundAssignment(binaryOperator, value,
        offset: offset, voidContext: voidContext, isPostIncDec: true);
  }

  @override
  doInvocation(
      int offset, List<UnresolvedType> typeArguments, Arguments arguments,
      {bool isTypeArgumentsInForest = false}) {
    return _helper.forest.createExpressionInvocation(
        adjustForImplicitCall(targetName, offset), _createRead(), arguments);
  }

  @override
  Generator buildIndexedAccess(Expression index, Token token,
      {bool isNullAware}) {
    assert(isNullAware != null);
    // TODO(johnniwinther): The read-only quality of the variable should be
    // passed on to the generator.
    return new IndexedAccessGenerator(_helper, token, _createRead(), index,
        isNullAware: isNullAware);
  }

  @override
  void printOn(StringSink sink) {
    NameSystem syntheticNames = new NameSystem();
    sink.write(", expression: ");
    printNodeOn(expression, sink, syntheticNames: syntheticNames);
    sink.write(", plainNameForRead: ");
    sink.write(targetName);
    sink.write(", kind: ");
    sink.write(kind);
  }
}

abstract class ErroneousExpressionGenerator extends Generator {
  ErroneousExpressionGenerator(ExpressionGeneratorHelper helper, Token token)
      : super(helper, token);

  /// Pass [arguments] that must be evaluated before throwing an error.  At
  /// most one of [isGetter] and [isSetter] should be true and they're passed
  /// to [ExpressionGeneratorHelper.throwNoSuchMethodError] if it is used.
  Expression buildError(Arguments arguments,
      {bool isGetter: false, bool isSetter: false, int offset});

  Name get name => unsupported("name", fileOffset, _uri);

  @override
  String get _plainNameForRead => name.text;

  withReceiver(Object receiver, int operatorOffset, {bool isNullAware}) => this;

  @override
  List<Initializer> buildFieldInitializer(Map<String, int> initializedFields) {
    return <Initializer>[
      _helper.buildInvalidInitializer(
          buildError(_forest.createArgumentsEmpty(fileOffset), isSetter: true))
    ];
  }

  @override
  doInvocation(
      int offset, List<UnresolvedType> typeArguments, Arguments arguments,
      {bool isTypeArgumentsInForest = false}) {
    return buildError(arguments, offset: offset);
  }

  @override
  buildPropertyAccess(
      IncompleteSendGenerator send, int operatorOffset, bool isNullAware) {
    return send.withReceiver(buildSimpleRead(), operatorOffset,
        isNullAware: isNullAware);
  }

  @override
  Expression buildAssignment(Expression value, {bool voidContext: false}) {
    return buildError(_forest.createArguments(fileOffset, <Expression>[value]),
        isSetter: true);
  }

  @override
  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset: -1,
      bool voidContext: false,
      bool isPreIncDec: false,
      bool isPostIncDec: false}) {
    return buildError(_forest.createArguments(fileOffset, <Expression>[value]),
        isGetter: true);
  }

  @override
  Expression buildPrefixIncrement(Name binaryOperator,
      {int offset: -1, bool voidContext: false}) {
    return buildError(
        _forest.createArguments(
            fileOffset, <Expression>[_forest.createIntLiteral(offset, 1)]),
        isGetter: true)
      ..fileOffset = offset;
  }

  @override
  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset: -1, bool voidContext: false}) {
    return buildError(
        _forest.createArguments(
            fileOffset, <Expression>[_forest.createIntLiteral(offset, 1)]),
        isGetter: true)
      ..fileOffset = offset;
  }

  @override
  Expression buildIfNullAssignment(Expression value, DartType type, int offset,
      {bool voidContext: false}) {
    return buildError(_forest.createArguments(fileOffset, <Expression>[value]),
        isSetter: true);
  }

  @override
  Expression buildSimpleRead() {
    return buildError(_forest.createArgumentsEmpty(fileOffset), isGetter: true);
  }

  @override
  Expression _makeInvalidRead() {
    return buildError(_forest.createArgumentsEmpty(fileOffset), isGetter: true);
  }

  @override
  Expression _makeInvalidWrite(Expression value) {
    return buildError(_forest.createArguments(fileOffset, <Expression>[value]),
        isSetter: true);
  }

  @override
  Expression invokeConstructor(
      List<UnresolvedType> typeArguments,
      String name,
      Arguments arguments,
      Token nameToken,
      Token nameLastToken,
      Constness constness) {
    if (typeArguments != null) {
      assert(_forest.argumentsTypeArguments(arguments).isEmpty);
      _forest.argumentsSetTypeArguments(
          arguments, _helper.buildDartTypeArguments(typeArguments));
    }
    return buildError(arguments);
  }

  @override
  Generator buildIndexedAccess(Expression index, Token token,
      {bool isNullAware}) {
    assert(isNullAware != null);
    return new IndexedAccessGenerator(_helper, token, buildSimpleRead(), index,
        isNullAware: isNullAware);
  }
}

class UnresolvedNameGenerator extends ErroneousExpressionGenerator {
  @override
  final Name name;

  factory UnresolvedNameGenerator(
      ExpressionGeneratorHelper helper, Token token, Name name) {
    if (name.text.isEmpty) {
      unhandled("empty", "name", offsetForToken(token), helper.uri);
    }
    return new UnresolvedNameGenerator.internal(helper, token, name);
  }

  UnresolvedNameGenerator.internal(
      ExpressionGeneratorHelper helper, Token token, this.name)
      : super(helper, token);

  @override
  String get _debugName => "UnresolvedNameGenerator";

  @override
  Expression doInvocation(
      int charOffset, List<UnresolvedType> typeArguments, Arguments arguments,
      {bool isTypeArgumentsInForest = false}) {
    return buildError(arguments, offset: charOffset);
  }

  @override
  Expression buildError(Arguments arguments,
      {bool isGetter: false, bool isSetter: false, int offset}) {
    offset ??= fileOffset;
    return _helper.throwNoSuchMethodError(
        _forest.createNullLiteral(offset), _plainNameForRead, arguments, offset,
        isGetter: isGetter, isSetter: isSetter);
  }

  @override
  /* Expression | Generator */ Object qualifiedLookup(Token name) {
    return new UnexpectedQualifiedUseGenerator(_helper, name, this, true);
  }

  @override
  Expression buildAssignment(Expression value, {bool voidContext: false}) {
    return _buildUnresolvedVariableAssignment(false, value);
  }

  @override
  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      bool isPreIncDec: false,
      bool isPostIncDec: false}) {
    return _buildUnresolvedVariableAssignment(true, value);
  }

  @override
  Expression buildSimpleRead() {
    return buildError(_forest.createArgumentsEmpty(fileOffset), isGetter: true)
      ..fileOffset = fileOffset;
  }

  @override
  void printOn(StringSink sink) {
    sink.write(", name: ");
    sink.write(name.text);
  }

  Expression _buildUnresolvedVariableAssignment(
      bool isCompound, Expression value) {
    return buildError(_forest.createArguments(fileOffset, <Expression>[value]),
        isSetter: true);
  }

  @override
  Generator buildIndexedAccess(Expression index, Token token,
      {bool isNullAware}) {
    assert(isNullAware != null);
    return new IndexedAccessGenerator(_helper, token, buildSimpleRead(), index,
        isNullAware: isNullAware);
  }
}

abstract class ContextAwareGenerator extends Generator {
  final Generator generator;

  ContextAwareGenerator(
      ExpressionGeneratorHelper helper, Token token, this.generator)
      : super(helper, token);

  @override
  String get _plainNameForRead {
    return unsupported("plainNameForRead", token.charOffset, _helper.uri);
  }

  @override
  Expression doInvocation(
      int charOffset, List<UnresolvedType> typeArguments, Arguments arguments,
      {bool isTypeArgumentsInForest = false}) {
    return unhandled("${runtimeType}", "doInvocation", charOffset, _uri);
  }

  @override
  Expression buildAssignment(Expression value, {bool voidContext: false}) {
    return _makeInvalidWrite(value);
  }

  @override
  Expression buildIfNullAssignment(Expression value, DartType type, int offset,
      {bool voidContext: false}) {
    return _makeInvalidWrite(value);
  }

  @override
  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset: -1,
      bool voidContext: false,
      bool isPreIncDec: false,
      bool isPostIncDec: false}) {
    return _makeInvalidWrite(value);
  }

  @override
  Expression buildPrefixIncrement(Name binaryOperator,
      {int offset: -1, bool voidContext: false}) {
    return _makeInvalidWrite(null);
  }

  @override
  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset: -1, bool voidContext: false}) {
    return _makeInvalidWrite(null);
  }

  @override
  _makeInvalidRead() {
    return unsupported("makeInvalidRead", token.charOffset, _helper.uri);
  }

  @override
  Expression _makeInvalidWrite(Expression value) {
    return _helper.buildProblem(messageIllegalAssignmentToNonAssignable,
        fileOffset, lengthForToken(token));
  }

  @override
  Generator buildIndexedAccess(Expression index, Token token,
      {bool isNullAware}) {
    assert(isNullAware != null);
    return new IndexedAccessGenerator(_helper, token, buildSimpleRead(), index,
        isNullAware: isNullAware);
  }
}

class DelayedAssignment extends ContextAwareGenerator {
  final Expression value;

  String assignmentOperator;

  DelayedAssignment(ExpressionGeneratorHelper helper, Token token,
      Generator generator, this.value, this.assignmentOperator)
      : super(helper, token, generator);

  @override
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
          messageNotAConstantExpression, fileOffset, token.length);
    }
    if (identical("=", assignmentOperator)) {
      return generator.buildAssignment(value, voidContext: voidContext);
    } else if (identical("+=", assignmentOperator)) {
      return generator.buildCompoundAssignment(plusName, value,
          offset: fileOffset, voidContext: voidContext);
    } else if (identical("-=", assignmentOperator)) {
      return generator.buildCompoundAssignment(minusName, value,
          offset: fileOffset, voidContext: voidContext);
    } else if (identical("*=", assignmentOperator)) {
      return generator.buildCompoundAssignment(multiplyName, value,
          offset: fileOffset, voidContext: voidContext);
    } else if (identical("%=", assignmentOperator)) {
      return generator.buildCompoundAssignment(percentName, value,
          offset: fileOffset, voidContext: voidContext);
    } else if (identical("&=", assignmentOperator)) {
      return generator.buildCompoundAssignment(ampersandName, value,
          offset: fileOffset, voidContext: voidContext);
    } else if (identical("/=", assignmentOperator)) {
      return generator.buildCompoundAssignment(divisionName, value,
          offset: fileOffset, voidContext: voidContext);
    } else if (identical("<<=", assignmentOperator)) {
      return generator.buildCompoundAssignment(leftShiftName, value,
          offset: fileOffset, voidContext: voidContext);
    } else if (identical(">>=", assignmentOperator)) {
      return generator.buildCompoundAssignment(rightShiftName, value,
          offset: fileOffset, voidContext: voidContext);
    } else if (identical(">>>=", assignmentOperator)) {
      return generator.buildCompoundAssignment(tripleShiftName, value,
          offset: fileOffset, voidContext: voidContext);
    } else if (identical("??=", assignmentOperator)) {
      return generator.buildIfNullAssignment(
          value, const DynamicType(), fileOffset,
          voidContext: voidContext);
    } else if (identical("^=", assignmentOperator)) {
      return generator.buildCompoundAssignment(caretName, value,
          offset: fileOffset, voidContext: voidContext);
    } else if (identical("|=", assignmentOperator)) {
      return generator.buildCompoundAssignment(barName, value,
          offset: fileOffset, voidContext: voidContext);
    } else if (identical("~/=", assignmentOperator)) {
      return generator.buildCompoundAssignment(mustacheName, value,
          offset: fileOffset, voidContext: voidContext);
    } else {
      return unhandled(assignmentOperator, "handleAssignment", token.charOffset,
          _helper.uri);
    }
  }

  @override
  List<Initializer> buildFieldInitializer(Map<String, int> initializedFields) {
    if (!identical("=", assignmentOperator) ||
        generator is! ThisPropertyAccessGenerator) {
      return generator.buildFieldInitializer(initializedFields);
    }
    return _helper.buildFieldInitializer(generator._plainNameForRead,
        offsetForToken(generator.token), fileOffset, value);
  }

  @override
  void printOn(StringSink sink) {
    sink.write(", value: ");
    printNodeOn(value, sink);
    sink.write(", assignmentOperator: ");
    sink.write(assignmentOperator);
  }
}

class DelayedPostfixIncrement extends ContextAwareGenerator {
  final Name binaryOperator;

  DelayedPostfixIncrement(ExpressionGeneratorHelper helper, Token token,
      Generator generator, this.binaryOperator)
      : super(helper, token, generator);

  @override
  String get _debugName => "DelayedPostfixIncrement";

  @override
  Expression buildSimpleRead() {
    return generator.buildPostfixIncrement(binaryOperator,
        offset: fileOffset, voidContext: false);
  }

  @override
  Expression buildForEffect() {
    return generator.buildPostfixIncrement(binaryOperator,
        offset: fileOffset, voidContext: true);
  }

  @override
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
  String get _debugName => "PrefixUseGenerator";

  @override
  Expression buildSimpleRead() => _makeInvalidRead();

  @override
  Expression buildAssignment(Expression value, {bool voidContext: false}) {
    return _makeInvalidWrite(value);
  }

  @override
  Expression buildIfNullAssignment(Expression value, DartType type, int offset,
      {bool voidContext: false}) {
    return _makeInvalidRead();
  }

  @override
  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      bool isPreIncDec: false,
      bool isPostIncDec: false}) {
    return _makeInvalidRead();
  }

  @override
  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset: TreeNode.noOffset, bool voidContext: false}) {
    return _makeInvalidRead();
  }

  @override
  /* Expression | Generator */ Object qualifiedLookup(Token name) {
    if (_helper.constantContext != ConstantContext.none && prefix.deferred) {
      _helper.addProblem(
          templateCantUseDeferredPrefixAsConstant.withArguments(token),
          fileOffset,
          lengthForToken(token));
    }
    Object result = _helper.scopeLookup(prefix.exportScope, name.lexeme, name,
        isQualified: true, prefix: prefix);
    if (prefix.deferred) {
      if (result is Generator) {
        if (result is! LoadLibraryGenerator) {
          result = new DeferredAccessGenerator(_helper, name, this, result);
        }
      } else {
        _helper.wrapInDeferredCheck(result, prefix, fileOffset);
      }
    }
    return result;
  }

  @override
  /* Expression | Generator | Initializer */ doInvocation(
      int offset, List<UnresolvedType> typeArguments, Arguments arguments,
      {bool isTypeArgumentsInForest = false}) {
    return _helper.wrapInLocatedProblem(
        _helper.evaluateArgumentsBefore(
            arguments, _forest.createNullLiteral(fileOffset)),
        messageCantUsePrefixAsExpression.withLocation(
            _helper.uri, fileOffset, lengthForToken(token)));
  }

  @override
  /* Expression | Generator */ buildPropertyAccess(
      IncompleteSendGenerator send, int operatorOffset, bool isNullAware) {
    if (send is IncompleteSendGenerator) {
      assert(send.name.text == send.token.lexeme,
          "'${send.name.text}' != ${send.token.lexeme}");
      Object result = qualifiedLookup(send.token);
      if (send is SendAccessGenerator) {
        result = _helper.finishSend(
            result, send.typeArguments, send.arguments, fileOffset,
            isTypeArgumentsInForest: send.isTypeArgumentsInForest);
      }
      if (isNullAware) {
        result = _helper.wrapInLocatedProblem(
            _helper.toValue(result),
            messageCantUsePrefixWithNullAware.withLocation(
                _helper.uri, fileOffset, lengthForToken(token)));
      }
      return result;
    } else {
      return buildSimpleRead();
    }
  }

  @override
  Expression _makeInvalidRead() {
    return _helper.buildProblem(
        messageCantUsePrefixAsExpression, fileOffset, lengthForToken(token));
  }

  @override
  Expression _makeInvalidWrite(Expression value) => _makeInvalidRead();

  @override
  Generator buildIndexedAccess(Expression index, Token token,
      {bool isNullAware}) {
    assert(isNullAware != null);
    return new IndexedAccessGenerator(_helper, token, buildSimpleRead(), index,
        isNullAware: isNullAware);
  }

  @override
  void printOn(StringSink sink) {
    sink.write(", prefix: ");
    sink.write(prefix.name);
    sink.write(", deferred: ");
    sink.write(prefix.deferred);
  }
}

class UnexpectedQualifiedUseGenerator extends Generator {
  final Generator prefixGenerator;

  final bool isUnresolved;

  UnexpectedQualifiedUseGenerator(ExpressionGeneratorHelper helper, Token token,
      this.prefixGenerator, this.isUnresolved)
      : super(helper, token);

  @override
  String get _plainNameForRead =>
      "${prefixGenerator._plainNameForRead}.${token.lexeme}";

  @override
  String get _debugName => "UnexpectedQualifiedUseGenerator";

  @override
  Expression buildSimpleRead() => _makeInvalidRead();

  @override
  Expression buildAssignment(Expression value, {bool voidContext: false}) {
    return _makeInvalidWrite(value);
  }

  @override
  Expression buildIfNullAssignment(Expression value, DartType type, int offset,
      {bool voidContext: false}) {
    return _makeInvalidRead();
  }

  @override
  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      bool isPreIncDec: false,
      bool isPostIncDec: false}) {
    return _makeInvalidRead();
  }

  @override
  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset = TreeNode.noOffset, bool voidContext = false}) {
    return _makeInvalidRead();
  }

  @override
  Expression doInvocation(
      int offset, List<UnresolvedType> typeArguments, Arguments arguments,
      {bool isTypeArgumentsInForest = false}) {
    return _helper.throwNoSuchMethodError(_forest.createNullLiteral(offset),
        _plainNameForRead, arguments, fileOffset);
  }

  @override
  TypeBuilder buildTypeWithResolvedArguments(
      NullabilityBuilder nullabilityBuilder, List<UnresolvedType> arguments) {
    Template<Message Function(String, String)> template = isUnresolved
        ? templateUnresolvedPrefixInTypeAnnotation
        : templateNotAPrefixInTypeAnnotation;
    // TODO(johnniwinther): Could we use a FixedTypeBuilder(InvalidType()) here?
    NamedTypeBuilder result = new NamedTypeBuilder(
        _plainNameForRead,
        nullabilityBuilder,
        /* arguments = */ null,
        /* fileUri = */ null,
        /* charOffset = */ null);
    Message message =
        template.withArguments(prefixGenerator.token.lexeme, token.lexeme);
    _helper.libraryBuilder.addProblem(
        message,
        offsetForToken(prefixGenerator.token),
        lengthOfSpan(prefixGenerator.token, token),
        _uri);
    result.bind(result.buildInvalidTypeDeclarationBuilder(message.withLocation(
        _uri,
        offsetForToken(prefixGenerator.token),
        lengthOfSpan(prefixGenerator.token, token))));
    return result;
  }

  @override
  Generator buildIndexedAccess(Expression index, Token token,
      {bool isNullAware}) {
    assert(isNullAware != null);
    return new IndexedAccessGenerator(_helper, token, buildSimpleRead(), index,
        isNullAware: isNullAware);
  }

  @override
  void printOn(StringSink sink) {
    sink.write(", prefixGenerator: ");
    prefixGenerator.printOn(sink);
  }
}

class ParserErrorGenerator extends Generator {
  final Message message;

  ParserErrorGenerator(
      ExpressionGeneratorHelper helper, Token token, this.message)
      : super(helper, token);

  @override
  String get _plainNameForRead => "#parser-error";

  @override
  String get _debugName => "ParserErrorGenerator";

  @override
  void printOn(StringSink sink) {}

  Expression buildProblem() {
    return _helper.buildProblem(message, fileOffset, noLength,
        suppressMessage: true);
  }

  Expression buildSimpleRead() => buildProblem();

  Expression buildAssignment(Expression value, {bool voidContext: false}) {
    return buildProblem();
  }

  Expression buildIfNullAssignment(Expression value, DartType type, int offset,
      {bool voidContext: false}) {
    return buildProblem();
  }

  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      bool isPreIncDec: false,
      bool isPostIncDec: false}) {
    return buildProblem();
  }

  Expression buildPrefixIncrement(Name binaryOperator,
      {int offset: TreeNode.noOffset, bool voidContext: false}) {
    return buildProblem();
  }

  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset: TreeNode.noOffset, bool voidContext: false}) {
    return buildProblem();
  }

  Expression _makeInvalidRead() => buildProblem();

  Expression _makeInvalidWrite(Expression value) => buildProblem();

  List<Initializer> buildFieldInitializer(Map<String, int> initializedFields) {
    return <Initializer>[_helper.buildInvalidInitializer(buildProblem())];
  }

  Expression doInvocation(
      int offset, List<UnresolvedType> typeArguments, Arguments arguments,
      {bool isTypeArgumentsInForest = false}) {
    return buildProblem();
  }

  Expression buildPropertyAccess(
      IncompleteSendGenerator send, int operatorOffset, bool isNullAware) {
    return buildProblem();
  }

  TypeBuilder buildTypeWithResolvedArguments(
      NullabilityBuilder nullabilityBuilder, List<UnresolvedType> arguments) {
    // TODO(johnniwinther): Could we use a FixedTypeBuilder(InvalidType()) here?
    NamedTypeBuilder result = new NamedTypeBuilder(
        token.lexeme,
        nullabilityBuilder,
        /* arguments = */ null,
        /* fileUri = */ null,
        /* charOffset = */ null);
    _helper.libraryBuilder.addProblem(message, fileOffset, noLength, _uri);
    result.bind(result.buildInvalidTypeDeclarationBuilder(
        message.withLocation(_uri, fileOffset, noLength)));
    return result;
  }

  Expression qualifiedLookup(Token name) {
    return buildProblem();
  }

  Expression invokeConstructor(
      List<UnresolvedType> typeArguments,
      String name,
      Arguments arguments,
      Token nameToken,
      Token nameLastToken,
      Constness constness) {
    return buildProblem();
  }

  @override
  Generator buildIndexedAccess(Expression index, Token token,
      {bool isNullAware}) {
    assert(isNullAware != null);
    return new IndexedAccessGenerator(_helper, token, buildSimpleRead(), index,
        isNullAware: isNullAware);
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

  ThisAccessGenerator(ExpressionGeneratorHelper helper, Token token,
      this.isInitializer, this.inFieldInitializer, this.inLateFieldInitializer,
      {this.isSuper: false})
      : super(helper, token);

  String get _plainNameForRead {
    return unsupported(
        "${isSuper ? 'super' : 'this'}.plainNameForRead", fileOffset, _uri);
  }

  String get _debugName => "ThisAccessGenerator";

  Expression buildSimpleRead() {
    if (!isSuper) {
      if (inFieldInitializer && !inLateFieldInitializer) {
        return buildFieldInitializerError(null);
      } else {
        return _forest.createThisExpression(fileOffset);
      }
    } else {
      return _helper.buildProblem(
          messageSuperAsExpression, fileOffset, lengthForToken(token));
    }
  }

  Expression buildFieldInitializerError(Map<String, int> initializedFields) {
    String keyword = isSuper ? "super" : "this";
    return _helper.buildProblem(
        templateThisOrSuperAccessInFieldInitializer.withArguments(keyword),
        fileOffset,
        keyword.length);
  }

  @override
  List<Initializer> buildFieldInitializer(Map<String, int> initializedFields) {
    Expression error = buildFieldInitializerError(initializedFields);
    return <Initializer>[
      _helper.buildInvalidInitializer(error, error.fileOffset)
    ];
  }

  void _reportNonNullableInNullAwareWarningIfNeeded() {
    if (_helper.libraryBuilder.isNonNullableByDefault) {
      _helper.libraryBuilder.addProblem(
          messageThisInNullAwareReceiver, fileOffset, 4, _helper.uri);
    }
  }

  buildPropertyAccess(
      IncompleteSendGenerator send, int operatorOffset, bool isNullAware) {
    Name name = send.name;
    Arguments arguments = send.arguments;
    int offset = offsetForToken(send.token);
    if (isInitializer && send is SendAccessGenerator) {
      if (isNullAware) {
        _helper.addProblem(
            messageInvalidUseOfNullAwareAccess, operatorOffset, 2);
      }
      return buildConstructorInitializer(offset, name, arguments);
    }
    if (inFieldInitializer && !inLateFieldInitializer && !isInitializer) {
      return buildFieldInitializerError(null);
    }
    if (send is SendAccessGenerator) {
      // Notice that 'this' or 'super' can't be null. So we can ignore the
      // value of [isNullAware].
      if (isNullAware) {
        _reportNonNullableInNullAwareWarningIfNeeded();
      }
      return _helper.buildMethodInvocation(
          _forest.createThisExpression(fileOffset),
          name,
          send.arguments,
          offsetForToken(send.token),
          isSuper: isSuper);
    } else {
      if (isSuper) {
        Member getter = _helper.lookupInstanceMember(name, isSuper: isSuper);
        Member setter = _helper.lookupInstanceMember(name,
            isSuper: isSuper, isSetter: true);
        return new SuperPropertyAccessGenerator(
            _helper,
            // TODO(ahe): This is not the 'super' token.
            send.token,
            name,
            getter,
            setter);
      } else {
        return new ThisPropertyAccessGenerator(
            _helper,
            // TODO(ahe): This is not the 'this' token.
            send.token,
            name,
            thisOffset: fileOffset,
            isNullAware: isNullAware);
      }
    }
  }

  doInvocation(
      int offset, List<UnresolvedType> typeArguments, Arguments arguments,
      {bool isTypeArgumentsInForest = false}) {
    if (isInitializer) {
      return buildConstructorInitializer(offset, new Name(""), arguments);
    } else if (isSuper) {
      return _helper.buildProblem(messageSuperAsExpression, offset, noLength);
    } else {
      return _helper.forest.createExpressionInvocation(
          offset, _forest.createThisExpression(fileOffset), arguments);
    }
  }

  @override
  buildEqualsOperation(Token token, Expression right, {bool isNot}) {
    assert(isNot != null);
    if (isSuper) {
      int offset = offsetForToken(token);
      Expression result = _helper.buildMethodInvocation(
          _forest.createThisExpression(fileOffset),
          equalsName,
          _forest.createArguments(offset, <Expression>[right]),
          offset,
          isSuper: true);
      if (isNot) {
        result = _forest.createNot(offset, result);
      }
      return result;
    }
    return super.buildEqualsOperation(token, right, isNot: isNot);
  }

  @override
  buildBinaryOperation(Token token, Name binaryName, Expression right) {
    if (isSuper) {
      int offset = offsetForToken(token);
      return _helper.buildMethodInvocation(
          _forest.createThisExpression(fileOffset),
          binaryName,
          _forest.createArguments(offset, <Expression>[right]),
          offset,
          isSuper: true);
    }
    return super.buildBinaryOperation(token, binaryName, right);
  }

  @override
  buildUnaryOperation(Token token, Name unaryName) {
    if (isSuper) {
      int offset = offsetForToken(token);
      return _helper.buildMethodInvocation(
          _forest.createThisExpression(fileOffset),
          unaryName,
          _forest.createArgumentsEmpty(offset),
          offset,
          isSuper: true);
    }
    return super.buildUnaryOperation(token, unaryName);
  }

  Initializer buildConstructorInitializer(
      int offset, Name name, Arguments arguments) {
    Constructor constructor = _helper.lookupConstructor(name, isSuper: isSuper);
    LocatedMessage message;
    if (constructor != null) {
      message = _helper.checkArgumentsForFunction(
          constructor.function, arguments, offset, <TypeParameter>[]);
    } else {
      String fullName =
          _helper.constructorNameForDiagnostics(name.text, isSuper: isSuper);
      message = (isSuper
              ? templateSuperclassHasNoConstructor
              : templateConstructorNotFound)
          .withArguments(fullName)
          .withLocation(_uri, fileOffset, lengthForToken(token));
    }
    if (message != null) {
      return _helper.buildInvalidInitializer(
          _helper.throwNoSuchMethodError(
              _forest.createNullLiteral(offset),
              _helper.constructorNameForDiagnostics(name.text,
                  isSuper: isSuper),
              arguments,
              offset,
              isSuper: isSuper,
              message: message),
          offset);
    } else if (isSuper) {
      return _helper.buildSuperInitializer(
          false, constructor, arguments, offset);
    } else {
      return _helper.buildRedirectingInitializer(
          constructor, arguments, offset);
    }
  }

  Expression buildAssignment(Expression value, {bool voidContext: false}) {
    return buildAssignmentError();
  }

  Expression buildIfNullAssignment(Expression value, DartType type, int offset,
      {bool voidContext: false}) {
    return buildAssignmentError();
  }

  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      bool isPreIncDec: false,
      bool isPostIncDec: false}) {
    return buildAssignmentError();
  }

  Expression buildPrefixIncrement(Name binaryOperator,
      {int offset: TreeNode.noOffset, bool voidContext: false}) {
    return buildAssignmentError();
  }

  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset: TreeNode.noOffset, bool voidContext: false}) {
    return buildAssignmentError();
  }

  @override
  Generator buildIndexedAccess(Expression index, Token token,
      {bool isNullAware}) {
    assert(isNullAware != null);
    if (isSuper) {
      return new SuperIndexedAccessGenerator(
          _helper,
          token,
          index,
          _helper.lookupInstanceMember(indexGetName, isSuper: true),
          _helper.lookupInstanceMember(indexSetName, isSuper: true));
    } else {
      return new ThisIndexedAccessGenerator(_helper, token, index,
          thisOffset: fileOffset, isNullAware: isNullAware);
    }
  }

  Expression buildAssignmentError() {
    return _helper.buildProblem(
        isSuper ? messageCannotAssignToSuper : messageNotAnLvalue,
        fileOffset,
        token.length);
  }

  @override
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

abstract class IncompleteSendGenerator implements Generator {
  Name get name;

  withReceiver(Object receiver, int operatorOffset, {bool isNullAware});

  List<UnresolvedType> get typeArguments => null;

  bool get isTypeArgumentsInForest => true;

  Arguments get arguments => null;
}

class IncompleteErrorGenerator extends ErroneousExpressionGenerator
    with IncompleteSendGenerator {
  final Message message;

  IncompleteErrorGenerator(
      ExpressionGeneratorHelper helper, Token token, this.message)
      : super(helper, token);

  Name get name => null;

  String get _plainNameForRead => token.lexeme;

  String get _debugName => "IncompleteErrorGenerator";

  @override
  Expression buildError(Arguments arguments,
      {bool isGetter: false, bool isSetter: false, int offset}) {
    int length = noLength;
    if (offset == null) {
      offset = fileOffset;
      length = lengthForToken(token);
    }
    return _helper.buildProblem(message, offset, length);
  }

  @override
  doInvocation(
          int offset, List<UnresolvedType> typeArguments, Arguments arguments,
          {bool isTypeArgumentsInForest = false}) =>
      this;

  @override
  Expression buildSimpleRead() {
    return buildError(_forest.createArgumentsEmpty(fileOffset), isGetter: true)
      ..fileOffset = fileOffset;
  }

  @override
  void printOn(StringSink sink) {
    sink.write(", message: ");
    sink.write(message.code.name);
  }
}

// TODO(ahe): Rename to SendGenerator.
class SendAccessGenerator extends Generator with IncompleteSendGenerator {
  @override
  final Name name;

  @override
  final List<UnresolvedType> typeArguments;

  @override
  final bool isTypeArgumentsInForest;

  @override
  final Arguments arguments;

  final bool isPotentiallyConstant;

  SendAccessGenerator(ExpressionGeneratorHelper helper, Token token, this.name,
      this.typeArguments, this.arguments,
      {this.isPotentiallyConstant = false, this.isTypeArgumentsInForest = true})
      : super(helper, token) {
    assert(arguments != null);
  }

  String get _plainNameForRead => name.text;

  String get _debugName => "SendAccessGenerator";

  Expression buildSimpleRead() {
    return unsupported("buildSimpleRead", fileOffset, _uri);
  }

  Expression buildAssignment(Expression value, {bool voidContext: false}) {
    return unsupported("buildAssignment", fileOffset, _uri);
  }

  withReceiver(Object receiver, int operatorOffset, {bool isNullAware: false}) {
    if (receiver is Generator) {
      return receiver.buildPropertyAccess(this, operatorOffset, isNullAware);
    }
    return _helper.buildMethodInvocation(
        _helper.toValue(receiver), name, arguments, fileOffset,
        isNullAware: isNullAware);
  }

  Expression buildIfNullAssignment(Expression value, DartType type, int offset,
      {bool voidContext: false}) {
    return unsupported("buildNullAwareAssignment", offset, _uri);
  }

  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      bool isPreIncDec: false,
      bool isPostIncDec: false}) {
    return unsupported("buildCompoundAssignment", offset ?? fileOffset, _uri);
  }

  Expression buildPrefixIncrement(Name binaryOperator,
      {int offset: TreeNode.noOffset, bool voidContext: false}) {
    return unsupported("buildPrefixIncrement", offset ?? fileOffset, _uri);
  }

  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset: TreeNode.noOffset, bool voidContext: false}) {
    return unsupported("buildPostfixIncrement", offset ?? fileOffset, _uri);
  }

  Expression doInvocation(
      int offset, List<UnresolvedType> typeArguments, Arguments arguments,
      {bool isTypeArgumentsInForest = false}) {
    return unsupported("doInvocation", offset, _uri);
  }

  @override
  Generator buildIndexedAccess(Expression index, Token token,
      {bool isNullAware}) {
    assert(isNullAware != null);
    return unsupported("buildIndexedAccess", offsetForToken(token), _uri);
  }

  @override
  void printOn(StringSink sink) {
    sink.write(", name: ");
    sink.write(name.text);
    sink.write(", arguments: ");
    Arguments node = arguments;
    if (node is Node) {
      printNodeOn(node, sink);
    } else {
      sink.write(node);
    }
  }
}

class IncompletePropertyAccessGenerator extends Generator
    with IncompleteSendGenerator {
  final Name name;

  IncompletePropertyAccessGenerator(
      ExpressionGeneratorHelper helper, Token token, this.name)
      : super(helper, token);

  String get _plainNameForRead => name.text;

  String get _debugName => "IncompletePropertyAccessGenerator";

  Expression buildSimpleRead() {
    return unsupported("buildSimpleRead", fileOffset, _uri);
  }

  Expression buildAssignment(Expression value, {bool voidContext: false}) {
    return unsupported("buildAssignment", fileOffset, _uri);
  }

  withReceiver(Object receiver, int operatorOffset, {bool isNullAware: false}) {
    if (receiver is Generator) {
      return receiver.buildPropertyAccess(this, operatorOffset, isNullAware);
    }
    return PropertyAccessGenerator.make(
        _helper, token, _helper.toValue(receiver), name, isNullAware);
  }

  Expression buildIfNullAssignment(Expression value, DartType type, int offset,
      {bool voidContext: false}) {
    return unsupported("buildNullAwareAssignment", offset, _uri);
  }

  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      bool isPreIncDec: false,
      bool isPostIncDec: false}) {
    return unsupported("buildCompoundAssignment", offset ?? fileOffset, _uri);
  }

  Expression buildPrefixIncrement(Name binaryOperator,
      {int offset: TreeNode.noOffset, bool voidContext: false}) {
    return unsupported("buildPrefixIncrement", offset ?? fileOffset, _uri);
  }

  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset: TreeNode.noOffset, bool voidContext: false}) {
    return unsupported("buildPostfixIncrement", offset ?? fileOffset, _uri);
  }

  Expression doInvocation(
      int offset, List<UnresolvedType> typeArguments, Arguments arguments,
      {bool isTypeArgumentsInForest = false}) {
    return unsupported("doInvocation", offset, _uri);
  }

  @override
  Generator buildIndexedAccess(Expression index, Token token,
      {bool isNullAware}) {
    assert(isNullAware != null);
    return unsupported("buildIndexedAccess", offsetForToken(token), _uri);
  }

  @override
  void printOn(StringSink sink) {
    sink.write(", name: ");
    sink.write(name.text);
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
class ParenthesizedExpressionGenerator extends ReadOnlyAccessGenerator {
  ParenthesizedExpressionGenerator(
      ExpressionGeneratorHelper helper, Token token, Expression expression)
      : super(helper, token, expression, null,
            ReadOnlyAccessKind.ParenthesizedExpression);

  @override
  Expression buildSimpleRead() => expression;

  @override
  Expression _createRead() =>
      _helper.forest.createParenthesized(fileOffset, expression);

  String get _debugName => "ParenthesizedExpressionGenerator";

  /* Expression | Generator */ buildPropertyAccess(
      IncompleteSendGenerator send, int operatorOffset, bool isNullAware) {
    if (send is SendAccessGenerator) {
      return _helper.buildMethodInvocation(
          _createRead(), send.name, send.arguments, offsetForToken(send.token),
          isNullAware: isNullAware,
          isConstantExpression: send.isPotentiallyConstant);
    } else {
      if (_helper.constantContext != ConstantContext.none &&
          send.name != lengthName) {
        _helper.addProblem(
            messageNotAConstantExpression, fileOffset, token.length);
      }
      return PropertyAccessGenerator.make(
          _helper, send.token, _createRead(), send.name, isNullAware);
    }
  }
}

int adjustForImplicitCall(String name, int offset) {
  // Normally the offset is at the start of the token, but in this case,
  // because we insert a '.call', we want it at the end instead.
  return offset + (name?.length ?? 0);
}

bool isFieldOrGetter(Member member) {
  return member is Field || (member is Procedure && member.isGetter);
}
