// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A library to help generate expression.
library fasta.expression_generator;

import 'package:_fe_analyzer_shared/src/parser/parser.dart'
    show lengthForToken, lengthOfSpan;
import 'package:_fe_analyzer_shared/src/scanner/token.dart' show Token;
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
import 'package:kernel/text/ast_to_text.dart';
import 'package:kernel/type_algebra.dart';

import '../builder/builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/library_builder.dart';
import '../builder/member_builder.dart';
import '../builder/named_type_builder.dart';
import '../builder/nullability_builder.dart';
import '../builder/omitted_type_builder.dart';
import '../builder/prefix_builder.dart';
import '../builder/type_builder.dart';
import '../codes/fasta_codes.dart';
import '../constant_context.dart' show ConstantContext;
import '../problems.dart';
import '../scope.dart';
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
  Uri get _uri => _helper.uri;

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
  Expression buildIfNullAssignment(Expression value, DartType type, int offset,
      {bool voidContext = false});

  /// Returns an [Expression] representing a compound assignment (e.g. `+=`)
  /// with the generator on the LHS and [value] on the RHS.
  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset = TreeNode.noOffset,
      bool voidContext = false,
      bool isPreIncDec = false,
      bool isPostIncDec = false});

  /// Returns an [Expression] representing a pre-increment or pre-decrement of
  /// the generator.
  Expression buildPrefixIncrement(Name binaryOperator,
      {int offset = TreeNode.noOffset, bool voidContext = false}) {
    return buildCompoundAssignment(
        binaryOperator, _forest.createIntLiteral(offset, 1),
        offset: offset,
        // TODO(johnniwinther): We are missing some void contexts here. For
        // instance `++a?.b;` is not providing a void context making it default
        // `true`.
        voidContext: voidContext,
        isPreIncDec: true);
  }

  /// Returns an [Expression] representing a post-increment or post-decrement of
  /// the generator.
  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset = TreeNode.noOffset, bool voidContext = false});

  /// Returns a [Generator] or [Expression] representing an index access
  /// (e.g. `a[b]`) with the generator on the receiver and [index] as the
  /// index expression.
  Generator buildIndexedAccess(Expression index, Token token,
      {required bool isNullAware});

  /// Returns an [Expression] representing a compile-time error.
  ///
  /// At runtime, an exception will be thrown.
  Expression _makeInvalidRead(UnresolvedKind unresolvedKind) {
    return _helper.buildUnresolvedError(_plainNameForRead, fileOffset,
        kind: unresolvedKind);
  }

  /// Returns an [Expression] representing a compile-time error wrapping
  /// [value].
  ///
  /// At runtime, [value] will be evaluated before throwing an exception.
  Expression _makeInvalidWrite(Expression value) {
    return _helper.buildUnresolvedError(_plainNameForRead, fileOffset,
        rhs: value, kind: UnresolvedKind.Setter);
  }

  Expression buildForEffect() => buildSimpleRead();

  List<Initializer> buildFieldInitializer(Map<String, int>? initializedFields) {
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
  Expression_Generator_Initializer doInvocation(
      int offset, List<TypeBuilder>? typeArguments, ArgumentsImpl arguments,
      {bool isTypeArgumentsInForest = false});

  Expression_Generator_Initializer buildSelectorAccess(
      Selector selector, int operatorOffset, bool isNullAware) {
    selector.reportNewAsSelector();
    if (selector is InvocationSelector) {
      return _helper.buildMethodInvocation(buildSimpleRead(), selector.name,
          selector.arguments, offsetForToken(selector.token),
          isNullAware: isNullAware,
          isConstantExpression: selector.isPotentiallyConstant);
    } else {
      if (_helper.constantContext != ConstantContext.none &&
          selector.name != lengthName) {
        _helper.addProblem(
            messageNotAConstantExpression, fileOffset, token.length);
      }
      return PropertyAccessGenerator.make(_helper, selector.token,
          buildSimpleRead(), selector.name, isNullAware);
    }
  }

  Expression_Generator buildEqualsOperation(Token token, Expression right,
      {required bool isNot}) {
    return _forest.createEquals(offsetForToken(token), buildSimpleRead(), right,
        isNot: isNot);
  }

  Expression_Generator buildBinaryOperation(
      Token token, Name binaryName, Expression right) {
    return _forest.createBinary(
        offsetForToken(token), buildSimpleRead(), binaryName, right);
  }

  Expression_Generator buildUnaryOperation(Token token, Name unaryName) {
    return _forest.createUnary(
        offsetForToken(token), unaryName, buildSimpleRead());
  }

  Expression_Generator applyTypeArguments(
      int fileOffset, List<TypeBuilder>? typeArguments) {
    return new Instantiation(
        buildSimpleRead(),
        _helper.buildDartTypeArguments(
            typeArguments, TypeUse.tearOffTypeArgument,
            allowPotentiallyConstantType: true))
      ..fileOffset = fileOffset;
  }

  /// Returns a [TypeBuilder] for this subexpression instantiated with the
  /// type [arguments]. If no type arguments are provided [arguments] is `null`.
  ///
  /// The type arguments have not been resolved and should be resolved to
  /// create a [TypeBuilder] for a valid type.
  TypeBuilder buildTypeWithResolvedArguments(
      NullabilityBuilder nullabilityBuilder, List<TypeBuilder>? arguments,
      {required bool allowPotentiallyConstantType,
      required bool performTypeCanonicalization}) {
    Message message = templateNotAType.withArguments(token.lexeme);
    _helper.libraryBuilder
        .addProblem(message, fileOffset, lengthForToken(token), _uri);
    return new NamedTypeBuilderImpl.forInvalidType(
        token.lexeme,
        nullabilityBuilder,
        message.withLocation(_uri, fileOffset, lengthForToken(token)));
  }

  Expression_Generator qualifiedLookup(Token name) {
    return new UnexpectedQualifiedUseGenerator(_helper, name, this, false);
  }

  Expression invokeConstructor(
      List<TypeBuilder>? typeArguments,
      String name,
      Arguments arguments,
      Token nameToken,
      Token nameLastToken,
      Constness constness,
      {required bool inImplicitCreationContext}) {
    return _helper.createInstantiationAndInvocation(() => buildSimpleRead(),
        typeArguments, _plainNameForRead, name, arguments,
        instantiationOffset: fileOffset,
        invocationOffset: nameLastToken.charOffset,
        inImplicitCreationContext: inImplicitCreationContext);
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
  final VariableDeclaration variable;

  VariableUseGenerator(
      ExpressionGeneratorHelper helper, Token token, this.variable)
      : assert(variable.isAssignable, 'Variable $variable is not assignable'),
        super(helper, token);

  @override
  String get _debugName => "VariableUseGenerator";

  @override
  String get _plainNameForRead => variable.name!;

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

  Expression _createWrite(int offset, Expression value) {
    if (_helper.isDeclaredInEnclosingCase(variable)) {
      _helper.addProblem(
          messagePatternVariableAssignmentInsideGuard, offset, noLength);
    }
    _helper.registerVariableAssignment(variable);
    return new VariableSet(variable, value)..fileOffset = offset;
  }

  @override
  Expression buildIfNullAssignment(Expression value, DartType type, int offset,
      {bool voidContext = false}) {
    Expression read = _createRead();
    Expression write = _createWrite(fileOffset, value);
    return new IfNullSet(read, write, forEffect: voidContext)
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
    VariableDeclarationImpl read =
        _helper.createVariableDeclarationForValue(_createRead());
    Expression binary = _helper.forest.createBinary(offset,
        _helper.createVariableGet(read, fileOffset), binaryOperator, value);
    VariableDeclarationImpl write =
        _helper.createVariableDeclarationForValue(_createWrite(offset, binary));
    return new LocalPostIncDec(read, write)..fileOffset = offset;
  }

  @override
  Expression doInvocation(
      int offset, List<TypeBuilder>? typeArguments, Arguments arguments,
      {bool isTypeArgumentsInForest = false}) {
    return _helper.forest.createExpressionInvocation(
        adjustForImplicitCall(_plainNameForRead, offset),
        buildSimpleRead(),
        arguments);
  }

  @override
  Generator buildIndexedAccess(Expression index, Token token,
      {required bool isNullAware}) {
    return new IndexedAccessGenerator(_helper, token, buildSimpleRead(), index,
        isNullAware: isNullAware);
  }

  @override
  void printOn(StringSink sink) {
    NameSystem syntheticNames = new NameSystem();
    sink.write(", variable: ");
    printNodeOn(variable, sink, syntheticNames: syntheticNames);
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
  ForInLateFinalVariableUseGenerator(ExpressionGeneratorHelper helper,
      Token token, VariableDeclaration variable)
      : super(helper, token, variable);

  @override
  String get _debugName => "ForInLateFinalVariableUseGenerator";

  @override
  Expression buildAssignment(Expression value, {bool voidContext = false}) {
    InvalidExpression error = _helper.buildProblem(
        templateCannotAssignToFinalVariable.withArguments(variable.name!),
        fileOffset,
        lengthForToken(token))
      ..parent = variable;
    Expression assignment =
        super.buildAssignment(value, voidContext: voidContext);
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
      ExpressionGeneratorHelper helper, Token token, this.receiver, this.name)
      : super(helper, token);

  @override
  String get _debugName => "PropertyAccessGenerator";

  @override
  String get _plainNameForRead => name.text;

  @override
  Expression doInvocation(
      int offset, List<TypeBuilder>? typeArguments, Arguments arguments,
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
  Expression buildAssignment(Expression value, {bool voidContext = false}) {
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
      {int offset = TreeNode.noOffset,
      bool voidContext = false,
      bool isPreIncDec = false,
      bool isPostIncDec = false}) {
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
    VariableDeclarationImpl variable =
        _helper.createVariableDeclarationForValue(receiver);
    VariableDeclarationImpl read = _helper.createVariableDeclarationForValue(
        _forest.createPropertyGet(fileOffset,
            _helper.createVariableGet(variable, receiver.fileOffset), name));
    Expression binary = _helper.forest.createBinary(offset,
        _helper.createVariableGet(read, fileOffset), binaryOperator, value);
    VariableDeclarationImpl write = _helper.createVariableDeclarationForValue(
        _helper.forest.createPropertySet(
            fileOffset,
            _helper.createVariableGet(variable, receiver.fileOffset),
            name,
            binary,
            forEffect: true));
    return new PropertyPostIncDec(variable, read, write)..fileOffset = offset;
  }

  @override
  Generator buildIndexedAccess(Expression index, Token token,
      {required bool isNullAware}) {
    return new IndexedAccessGenerator(_helper, token, buildSimpleRead(), index,
        isNullAware: isNullAware);
  }

  /// Creates a [Generator] for the access of property [name] on [receiver].
  static Generator make(ExpressionGeneratorHelper helper, Token token,
      Expression receiver, Name name, bool isNullAware) {
    if (helper.forest.isThisExpression(receiver)) {
      return new ThisPropertyAccessGenerator(helper, token, name,
          thisVariable: null,
          thisOffset: receiver.fileOffset,
          isNullAware: isNullAware);
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
      ExpressionGeneratorHelper helper, Token token, this.name,
      {this.thisVariable, this.thisOffset, this.isNullAware = false})
      : super(helper, token);

  @override
  String get _debugName => "ThisPropertyAccessGenerator";

  @override
  String get _plainNameForRead => name.text;

  Expression get _thisExpression => thisVariable != null
      ? _forest.createVariableGet(fileOffset, thisVariable!)
      : _forest.createThisExpression(fileOffset);

  @override
  Expression buildSimpleRead() {
    return _createRead();
  }

  Expression _createRead() {
    return _forest.createPropertyGet(fileOffset, _thisExpression, name);
  }

  @override
  Expression buildAssignment(Expression value, {bool voidContext = false}) {
    return _createWrite(fileOffset, value, forEffect: voidContext);
  }

  Expression _createWrite(int offset, Expression value,
      {required bool forEffect}) {
    return _helper.forest.createPropertySet(
        fileOffset, _thisExpression, name, value,
        forEffect: forEffect);
  }

  @override
  Expression buildIfNullAssignment(Expression value, DartType type, int offset,
      {bool voidContext = false}) {
    return new IfNullSet(
        _createRead(), _createWrite(offset, value, forEffect: voidContext),
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
    VariableDeclarationImpl read =
        _helper.createVariableDeclarationForValue(_createRead());
    Expression binary = _helper.forest.createBinary(offset,
        _helper.createVariableGet(read, fileOffset), binaryOperator, value);
    VariableDeclarationImpl write = _helper.createVariableDeclarationForValue(
        _createWrite(fileOffset, binary, forEffect: true));
    return new PropertyPostIncDec.onReadOnly(read, write)..fileOffset = offset;
  }

  @override
  Expression doInvocation(
      int offset, List<TypeBuilder>? typeArguments, Arguments arguments,
      {bool isTypeArgumentsInForest = false}) {
    return _helper.buildMethodInvocation(
        _thisExpression, name, arguments, offset);
  }

  @override
  Generator buildIndexedAccess(Expression index, Token token,
      {required bool isNullAware}) {
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
            helper.createVariableDeclarationForValue(receiverExpression),
        super(helper, token);

  @override
  String get _debugName => "NullAwarePropertyAccessGenerator";

  @override
  String get _plainNameForRead => name.text;

  @override
  Expression buildSimpleRead() {
    VariableDeclarationImpl variable =
        _helper.createVariableDeclarationForValue(receiverExpression);
    Expression read = _forest.createPropertyGet(
        fileOffset,
        _helper.createVariableGet(variable, receiverExpression.fileOffset,
            forNullGuardedAccess: true),
        name);
    return new NullAwarePropertyGet(variable, read)
      ..fileOffset = receiverExpression.fileOffset;
  }

  @override
  Expression buildAssignment(Expression value, {bool voidContext = false}) {
    VariableDeclarationImpl variable =
        _helper.createVariableDeclarationForValue(receiverExpression);
    Expression read = _helper.forest.createPropertySet(
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

  @override
  Expression buildIfNullAssignment(Expression value, DartType type, int offset,
      {bool voidContext = false}) {
    return new NullAwareIfNullSet(receiverExpression, name, value,
        forEffect: voidContext,
        readOffset: fileOffset,
        testOffset: offset,
        writeOffset: fileOffset)
      ..fileOffset = offset;
  }

  @override
  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset = TreeNode.noOffset,
      bool voidContext = false,
      bool isPreIncDec = false,
      bool isPostIncDec = false}) {
    return new NullAwareCompoundSet(
        receiverExpression, name, binaryOperator, value,
        readOffset: fileOffset,
        binaryOffset: offset,
        writeOffset: fileOffset,
        forEffect: voidContext,
        forPostIncDec: isPostIncDec);
  }

  @override
  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset = TreeNode.noOffset, bool voidContext = false}) {
    return buildCompoundAssignment(
        binaryOperator, _forest.createIntLiteral(offset, 1),
        offset: offset, voidContext: voidContext, isPostIncDec: true);
  }

  @override
  Expression doInvocation(
      int offset, List<TypeBuilder>? typeArguments, Arguments arguments,
      {bool isTypeArgumentsInForest = false}) {
    return unsupported("doInvocation", offset, _uri);
  }

  @override
  Generator buildIndexedAccess(Expression index, Token token,
      {required bool isNullAware}) {
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

  final Member? getter;

  final Member? setter;

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
    Member? getter = this.getter;
    if (getter == null) {
      return _helper.buildUnresolvedError(name.text, fileOffset,
          isSuper: true, kind: UnresolvedKind.Getter);
    } else {
      return new SuperPropertyGet(name, getter)..fileOffset = fileOffset;
    }
  }

  @override
  Expression buildAssignment(Expression value, {bool voidContext = false}) {
    return _createWrite(fileOffset, value);
  }

  Expression _createWrite(int offset, Expression value) {
    Member? setter = this.setter;
    if (setter == null) {
      return _helper.buildUnresolvedError(name.text, fileOffset,
          rhs: value, isSuper: true, kind: UnresolvedKind.Setter);
    } else {
      return new SuperPropertySet(name, value, setter)..fileOffset = offset;
    }
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
    VariableDeclarationImpl read =
        _helper.createVariableDeclarationForValue(_createRead());
    Expression binary = _helper.forest.createBinary(offset,
        _helper.createVariableGet(read, fileOffset), binaryOperator, value);
    VariableDeclarationImpl write = _helper
        .createVariableDeclarationForValue(_createWrite(fileOffset, binary));
    return new StaticPostIncDec(read, write)..fileOffset = offset;
  }

  @override
  Expression buildIfNullAssignment(Expression value, DartType type, int offset,
      {bool voidContext = false}) {
    return new IfNullSet(_createRead(), _createWrite(fileOffset, value),
        forEffect: voidContext)
      ..fileOffset = offset;
  }

  @override
  Expression doInvocation(
      int offset, List<TypeBuilder>? typeArguments, Arguments arguments,
      {bool isTypeArgumentsInForest = false}) {
    if (_helper.constantContext != ConstantContext.none) {
      // TODO(brianwilkerson) Fix the length
      _helper.addProblem(messageNotAConstantExpression, offset, 1);
    }
    if (getter == null) {
      return _helper.buildUnresolvedError(name.text, fileOffset,
          arguments: arguments, isSuper: true, kind: UnresolvedKind.Method);
    } else if (isFieldOrGetter(getter)) {
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
      {required bool isNullAware}) {
    return new IndexedAccessGenerator(_helper, token, buildSimpleRead(), index,
        isNullAware: isNullAware);
  }

  @override
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
      ExpressionGeneratorHelper helper, Token token, this.receiver, this.index,
      {required this.isNullAware})
      : super(helper, token);

  @override
  String get _plainNameForRead => "[]";

  @override
  String get _debugName => "IndexedAccessGenerator";

  @override
  Expression buildSimpleRead() {
    VariableDeclarationImpl? variable;
    Expression receiverValue;
    if (isNullAware) {
      variable = _helper.createVariableDeclarationForValue(receiver);
      receiverValue = _helper.createVariableGet(variable, fileOffset,
          forNullGuardedAccess: true);
    } else {
      receiverValue = receiver;
    }
    Expression result =
        _forest.createIndexGet(fileOffset, receiverValue, index);
    if (isNullAware) {
      result = new NullAwareMethodInvocation(variable!, result)
        ..fileOffset = fileOffset;
    }
    return result;
  }

  @override
  Expression buildAssignment(Expression value, {bool voidContext = false}) {
    VariableDeclarationImpl? variable;
    Expression receiverValue;
    if (isNullAware) {
      variable = _helper.createVariableDeclarationForValue(receiver);
      receiverValue = _helper.createVariableGet(variable, fileOffset,
          forNullGuardedAccess: true);
    } else {
      receiverValue = receiver;
    }
    Expression result = _forest.createIndexSet(
        fileOffset, receiverValue, index, value,
        forEffect: voidContext);
    if (isNullAware) {
      result = new NullAwareMethodInvocation(variable!, result)
        ..fileOffset = fileOffset;
    }
    return result;
  }

  @override
  Expression buildIfNullAssignment(Expression value, DartType type, int offset,
      {bool voidContext = false}) {
    VariableDeclarationImpl? variable;
    Expression receiverValue;
    if (isNullAware) {
      variable = _helper.createVariableDeclarationForValue(receiver);
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
      result = new NullAwareMethodInvocation(variable!, result)
        ..fileOffset = fileOffset;
    }
    return result;
  }

  @override
  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset = TreeNode.noOffset,
      bool voidContext = false,
      bool isPreIncDec = false,
      bool isPostIncDec = false}) {
    VariableDeclarationImpl? variable;
    Expression receiverValue;
    if (isNullAware) {
      variable = _helper.createVariableDeclarationForValue(receiver);
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
      result = new NullAwareMethodInvocation(variable!, result)
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
      int offset, List<TypeBuilder>? typeArguments, Arguments arguments,
      {bool isTypeArgumentsInForest = false}) {
    return _helper.forest.createExpressionInvocation(
        arguments.fileOffset, buildSimpleRead(), arguments);
  }

  @override
  Generator buildIndexedAccess(Expression index, Token token,
      {required bool isNullAware}) {
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
      {required bool isNullAware}) {
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

  final int? thisOffset;
  final bool isNullAware;

  ThisIndexedAccessGenerator(
      ExpressionGeneratorHelper helper, Token token, this.index,
      {this.thisOffset, this.isNullAware = false})
      : super(helper, token);

  @override
  String get _plainNameForRead => "[]";

  @override
  String get _debugName => "ThisIndexedAccessGenerator";

  @override
  Expression buildSimpleRead() {
    Expression receiver = _helper.forest.createThisExpression(fileOffset);
    return _forest.createIndexGet(fileOffset, receiver, index);
  }

  @override
  Expression buildAssignment(Expression value, {bool voidContext = false}) {
    Expression receiver = _helper.forest.createThisExpression(fileOffset);
    return _forest.createIndexSet(fileOffset, receiver, index, value,
        forEffect: voidContext);
  }

  @override
  Expression buildIfNullAssignment(Expression value, DartType type, int offset,
      {bool voidContext = false}) {
    Expression receiver = _helper.forest.createThisExpression(fileOffset);
    return new IfNullIndexSet(receiver, index, value,
        readOffset: fileOffset,
        testOffset: offset,
        writeOffset: fileOffset,
        forEffect: voidContext)
      ..fileOffset = offset;
  }

  @override
  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset = TreeNode.noOffset,
      bool voidContext = false,
      bool isPreIncDec = false,
      bool isPostIncDec = false}) {
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
      int offset, List<TypeBuilder>? typeArguments, Arguments arguments,
      {bool isTypeArgumentsInForest = false}) {
    return _helper.forest
        .createExpressionInvocation(offset, buildSimpleRead(), arguments);
  }

  @override
  Generator buildIndexedAccess(Expression index, Token token,
      {required bool isNullAware}) {
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

  final Procedure? getter;

  final Procedure? setter;

  SuperIndexedAccessGenerator(ExpressionGeneratorHelper helper, Token token,
      this.index, this.getter, this.setter)
      : super(helper, token);

  @override
  String get _plainNameForRead => "[]";

  @override
  String get _debugName => "SuperIndexedAccessGenerator";

  @override
  Expression buildSimpleRead() {
    Procedure? getter = this.getter;
    if (getter == null) {
      return _helper.buildUnresolvedError(indexGetName.text, fileOffset,
          isSuper: true,
          arguments:
              _helper.forest.createArguments(fileOffset, <Expression>[index]),
          kind: UnresolvedKind.Method,
          length: noLength);
    } else {
      return _helper.forest.createSuperMethodInvocation(
          fileOffset,
          indexGetName,
          getter,
          _helper.forest.createArguments(fileOffset, <Expression>[index]));
    }
  }

  @override
  Expression buildAssignment(Expression value, {bool voidContext = false}) {
    Procedure? setter = this.setter;
    if (setter == null) {
      return _helper.buildUnresolvedError(indexSetName.text, fileOffset,
          isSuper: true,
          arguments: _helper.forest
              .createArguments(fileOffset, <Expression>[index, value]),
          kind: UnresolvedKind.Method,
          length: noLength);
    } else {
      if (voidContext) {
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
  }

  @override
  Expression buildIfNullAssignment(Expression value, DartType type, int offset,
      {bool voidContext = false}) {
    return new IfNullSuperIndexSet(getter, setter, index, value,
        readOffset: fileOffset,
        testOffset: offset,
        writeOffset: fileOffset,
        forEffect: voidContext)
      ..fileOffset = offset;
  }

  @override
  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset = TreeNode.noOffset,
      bool voidContext = false,
      bool isPreIncDec = false,
      bool isPostIncDec = false}) {
    Procedure? getter = this.getter;
    Procedure? setter = this.setter;
    if (getter == null || setter == null) {
      return buildAssignment(
          buildBinaryOperation(token, binaryOperator, value));
    } else {
      return new CompoundSuperIndexSet(
          getter, setter, index, binaryOperator, value,
          readOffset: fileOffset,
          binaryOffset: offset,
          writeOffset: fileOffset,
          forEffect: voidContext,
          forPostIncDec: isPostIncDec);
    }
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
      int offset, List<TypeBuilder>? typeArguments, Arguments arguments,
      {bool isTypeArgumentsInForest = false}) {
    return _helper.forest
        .createExpressionInvocation(offset, buildSimpleRead(), arguments);
  }

  @override
  Generator buildIndexedAccess(Expression index, Token token,
      {required bool isNullAware}) {
    return new IndexedAccessGenerator(_helper, token, buildSimpleRead(), index,
        isNullAware: isNullAware);
  }

  @override
  void printOn(StringSink sink) {
    NameSystem syntheticNames = new NameSystem();
    sink.write(", index: ");
    printNodeOn(index, sink, syntheticNames: syntheticNames);
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
  final String targetName;

  /// The static [Member] used for performing a read or invocation on this
  /// subexpression.
  ///
  /// This can be `null` if the subexpression doesn't have a readable target.
  /// For instance if the subexpression is a setter without a corresponding
  /// getter.
  final Member? readTarget;

  /// The static [Member] used for performing a write on this subexpression.
  ///
  /// This can be `null` if the subexpression doesn't have a writable target.
  /// For instance if the subexpression is a final field, a method, or a getter
  /// without a corresponding setter.
  final Member? writeTarget;

  /// The offset of the type name if explicit. Otherwise `null`.
  final int? typeOffset;
  final bool isNullAware;

  /// The builder for the parent of [readTarget] and [writeTarget]. This is
  /// either the builder for the enclosing library,  class, or extension.
  final Builder? parentBuilder;

  StaticAccessGenerator(ExpressionGeneratorHelper helper, Token token,
      this.targetName, this.parentBuilder, this.readTarget, this.writeTarget,
      {this.typeOffset, this.isNullAware = false})
      : assert(readTarget != null || writeTarget != null),
        assert(parentBuilder is DeclarationBuilder ||
            parentBuilder is LibraryBuilder),
        super(helper, token);

  factory StaticAccessGenerator.fromBuilder(
      ExpressionGeneratorHelper helper,
      String targetName,
      Token token,
      MemberBuilder? getterBuilder,
      MemberBuilder? setterBuilder,
      {int? typeOffset,
      bool isNullAware = false}) {
    // If both [getterBuilder] and [setterBuilder] exist, they must both be
    // either top level (potentially from different libraries) or from the same
    // class/extension.
    assert(getterBuilder == null ||
        setterBuilder == null ||
        (getterBuilder.parent is LibraryBuilder &&
            setterBuilder.parent is LibraryBuilder) ||
        getterBuilder.parent == setterBuilder.parent);
    return new StaticAccessGenerator(
        helper,
        token,
        targetName,
        getterBuilder?.parent ?? setterBuilder?.parent,
        getterBuilder?.readTarget,
        setterBuilder?.writeTarget,
        typeOffset: typeOffset,
        isNullAware: isNullAware);
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
    Member? readTarget = this.readTarget;
    if (readTarget == null) {
      read = _makeInvalidRead(UnresolvedKind.Getter);
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
      write = _makeInvalidWrite(value);
    } else {
      write = new StaticSet(writeTarget!, value)..fileOffset = offset;
    }
    return write;
  }

  @override
  Expression buildIfNullAssignment(Expression value, DartType type, int offset,
      {bool voidContext = false}) {
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
    VariableDeclarationImpl read =
        _helper.createVariableDeclarationForValue(_createRead());
    Expression binary = _helper.forest.createBinary(offset,
        _helper.createVariableGet(read, fileOffset), binaryOperator, value);
    VariableDeclarationImpl write =
        _helper.createVariableDeclarationForValue(_createWrite(offset, binary));
    return new StaticPostIncDec(read, write)..fileOffset = offset;
  }

  @override
  Expression doInvocation(
      int offset, List<TypeBuilder>? typeArguments, Arguments arguments,
      {bool isTypeArgumentsInForest = false}) {
    if (_helper.constantContext != ConstantContext.none &&
        !_helper.isIdentical(readTarget) &&
        !_helper.libraryFeatures.constFunctions.isEnabled) {
      return _helper.buildProblem(
          templateNotConstantExpression.withArguments('Method invocation'),
          offset,
          readTarget?.name.text.length ?? 0);
    }
    if (readTarget == null || isFieldOrGetter(readTarget!)) {
      return _helper.forest.createExpressionInvocation(
          offset + (readTarget?.name.text.length ?? 0),
          buildSimpleRead(),
          arguments);
    } else {
      return _helper.buildStaticInvocation(readTarget as Procedure, arguments,
          charOffset: offset, isConstructorInvocation: false);
    }
  }

  @override
  Generator buildIndexedAccess(Expression index, Token token,
      {required bool isNullAware}) {
    return new IndexedAccessGenerator(_helper, token, buildSimpleRead(), index,
        isNullAware: isNullAware);
  }

  @override
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
  final String targetName;

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
      this.extensionTypeParameters)
      : assert(
            readTarget != null || invokeTarget != null || writeTarget != null),
        super(helper, token);

  factory ExtensionInstanceAccessGenerator.fromBuilder(
      ExpressionGeneratorHelper helper,
      Token token,
      Extension extension,
      String? targetName,
      VariableDeclaration extensionThis,
      List<TypeParameter>? extensionTypeParameters,
      MemberBuilder? getterBuilder,
      MemberBuilder? setterBuilder) {
    Procedure? readTarget;
    Procedure? invokeTarget;
    if (getterBuilder != null) {
      if (getterBuilder.isGetter) {
        assert(!getterBuilder.isStatic);
        readTarget = getterBuilder.readTarget as Procedure?;
      } else if (getterBuilder.isRegularMethod) {
        assert(!getterBuilder.isStatic);
        readTarget = getterBuilder.readTarget as Procedure?;
        invokeTarget = getterBuilder.invokeTarget as Procedure?;
      } else if (getterBuilder.isOperator) {
        assert(!getterBuilder.isStatic);
        invokeTarget = getterBuilder.invokeTarget as Procedure?;
      } else {
        return unhandled(
            "${getterBuilder.runtimeType}",
            "ExtensionInstanceAccessGenerator.fromBuilder",
            offsetForToken(token),
            helper.uri);
      }
    }
    Procedure? writeTarget;
    if (setterBuilder != null) {
      if (setterBuilder.isSetter) {
        assert(!setterBuilder.isStatic);
        writeTarget = setterBuilder.writeTarget as Procedure?;
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
        targetName!,
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
      for (TypeParameter typeParameter in extensionTypeParameters!) {
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
      read = _makeInvalidRead(UnresolvedKind.Getter);
    } else {
      read = _helper.buildExtensionMethodInvocation(
          fileOffset,
          readTarget!,
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
  Expression buildAssignment(Expression value, {bool voidContext = false}) {
    return _createWrite(fileOffset, value, forEffect: voidContext);
  }

  Expression _createWrite(int offset, Expression value,
      {required bool forEffect}) {
    Expression write;
    if (writeTarget == null) {
      write = _makeInvalidWrite(value);
    } else {
      write = new ExtensionSet(
          extension,
          _createExtensionTypeArguments(),
          _helper.createVariableGet(extensionThis, fileOffset),
          writeTarget!,
          value,
          forEffect: forEffect);
    }
    write.fileOffset = offset;
    return write;
  }

  @override
  Expression buildIfNullAssignment(Expression value, DartType type, int offset,
      {bool voidContext = false}) {
    return new IfNullSet(
        _createRead(), _createWrite(fileOffset, value, forEffect: voidContext),
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
    VariableDeclarationImpl read =
        _helper.createVariableDeclarationForValue(_createRead());
    Expression binary = _helper.forest.createBinary(offset,
        _helper.createVariableGet(read, fileOffset), binaryOperator, value);
    VariableDeclarationImpl write = _helper.createVariableDeclarationForValue(
        _createWrite(fileOffset, binary, forEffect: true));
    return new PropertyPostIncDec.onReadOnly(read, write)..fileOffset = offset;
  }

  @override
  Expression doInvocation(
      int offset, List<TypeBuilder>? typeArguments, ArgumentsImpl arguments,
      {bool isTypeArgumentsInForest = false}) {
    if (invokeTarget != null) {
      Expression thisAccess = _helper.createVariableGet(extensionThis, offset);
      return _helper.buildExtensionMethodInvocation(
          offset,
          invokeTarget!,
          _forest.createArgumentsForExtensionMethod(
              fileOffset,
              _extensionTypeParameterCount,
              invokeTarget!.function.typeParameters.length -
                  _extensionTypeParameterCount,
              thisAccess,
              extensionTypeArguments: _createExtensionTypeArguments(),
              typeArguments: arguments.types,
              positionalArguments: arguments.positional,
              namedArguments: arguments.named,
              argumentsOriginalOrder: arguments.argumentsOriginalOrder != null
                  ? [thisAccess, ...arguments.argumentsOriginalOrder!]
                  : null),
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
      {required bool isNullAware}) {
    return new IndexedAccessGenerator(_helper, token, buildSimpleRead(), index,
        isNullAware: isNullAware);
  }

  @override
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
  final List<DartType>? explicitTypeArguments;

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
      {required this.isNullAware})
      : assert(
            readTarget != null || invokeTarget != null || writeTarget != null),
        super(helper, token);

  factory ExplicitExtensionInstanceAccessGenerator.fromBuilder(
      ExpressionGeneratorHelper helper,
      Token token,
      int extensionTypeArgumentOffset,
      Extension extension,
      Name targetName,
      Builder? getterBuilder,
      Builder? setterBuilder,
      Expression receiver,
      List<DartType>? explicitTypeArguments,
      int extensionTypeParameterCount,
      {required bool isNullAware}) {
    assert(getterBuilder != null || setterBuilder != null);
    Procedure? readTarget;
    Procedure? invokeTarget;
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
        MemberBuilder memberBuilder = getterBuilder as MemberBuilder;
        readTarget = memberBuilder.readTarget as Procedure?;
      } else if (getterBuilder.isRegularMethod) {
        assert(!getterBuilder.isStatic);
        MemberBuilder procedureBuilder = getterBuilder as MemberBuilder;
        readTarget = procedureBuilder.readTarget as Procedure?;
        invokeTarget = procedureBuilder.invokeTarget as Procedure?;
      } else if (getterBuilder.isOperator) {
        assert(!getterBuilder.isStatic);
        MemberBuilder memberBuilder = getterBuilder as MemberBuilder;
        invokeTarget = memberBuilder.invokeTarget as Procedure?;
      } else if (getterBuilder.isField) {
        assert(!getterBuilder.isStatic);
        MemberBuilder memberBuilder = getterBuilder as MemberBuilder;
        readTarget = memberBuilder.invokeTarget as Procedure?;
      } else {
        return unhandled(
            "$getterBuilder (${getterBuilder.runtimeType})",
            "InstanceExtensionAccessGenerator.fromBuilder",
            offsetForToken(token),
            helper.uri);
      }
    }
    Procedure? writeTarget;
    if (setterBuilder != null) {
      assert(!setterBuilder.isStatic);
      if (setterBuilder is AccessErrorBuilder) {
        // No setter.
      } else if (setterBuilder.isSetter) {
        assert(!setterBuilder.isStatic);
        MemberBuilder memberBuilder = setterBuilder as MemberBuilder;
        writeTarget = memberBuilder.writeTarget as Procedure?;
      } else if (setterBuilder.isField) {
        assert(!setterBuilder.isStatic);
        MemberBuilder memberBuilder = setterBuilder as MemberBuilder;
        writeTarget = memberBuilder.writeTarget as Procedure?;
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
      VariableDeclarationImpl variable =
          _helper.createVariableDeclarationForValue(receiver);
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
      read = _makeInvalidRead(UnresolvedKind.Getter);
    } else {
      read = _helper.buildExtensionMethodInvocation(
          fileOffset,
          readTarget!,
          _helper.forest.createArgumentsForExtensionMethod(
              fileOffset, extensionTypeParameterCount, 0, receiver,
              extensionTypeArguments: _createExtensionTypeArguments(),
              extensionTypeArgumentOffset: extensionTypeArgumentOffset),
          isTearOff: isReadTearOff);
    }
    return read;
  }

  @override
  Expression buildAssignment(Expression value, {bool voidContext = false}) {
    if (isNullAware) {
      VariableDeclarationImpl variable =
          _helper.createVariableDeclarationForValue(receiver);
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
      {required bool forEffect}) {
    Expression write;
    if (writeTarget == null) {
      write = _makeInvalidWrite(value);
    } else {
      write = new ExtensionSet(
          extension, explicitTypeArguments, receiver, writeTarget!, value,
          forEffect: forEffect);
    }
    write.fileOffset = offset;
    return write;
  }

  @override
  Expression buildIfNullAssignment(Expression value, DartType type, int offset,
      {bool voidContext = false}) {
    if (isNullAware) {
      VariableDeclarationImpl variable =
          _helper.createVariableDeclarationForValue(receiver);
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
      {int offset = TreeNode.noOffset,
      bool voidContext = false,
      bool isPreIncDec = false,
      bool isPostIncDec = false}) {
    if (isNullAware) {
      VariableDeclarationImpl variable =
          _helper.createVariableDeclarationForValue(receiver);
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
      VariableDeclarationImpl variable =
          _helper.createVariableDeclarationForValue(receiver);
      VariableDeclarationImpl read = _helper.createVariableDeclarationForValue(
          _createRead(_helper.createVariableGet(variable, receiver.fileOffset,
              forNullGuardedAccess: true)));
      Expression binary = _helper.forest.createBinary(offset,
          _helper.createVariableGet(read, fileOffset), binaryOperator, value);
      VariableDeclarationImpl write = _helper.createVariableDeclarationForValue(
          _createWrite(
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
      VariableDeclarationImpl variable =
          _helper.createVariableDeclarationForValue(receiver);
      VariableDeclarationImpl read = _helper.createVariableDeclarationForValue(
          _createRead(
              _helper.createVariableGet(variable, receiver.fileOffset)));
      Expression binary = _helper.forest.createBinary(offset,
          _helper.createVariableGet(read, fileOffset), binaryOperator, value);
      VariableDeclarationImpl write = _helper.createVariableDeclarationForValue(
          _createWrite(fileOffset,
              _helper.createVariableGet(variable, receiver.fileOffset), binary,
              forEffect: voidContext)
            ..fileOffset = fileOffset);
      return new PropertyPostIncDec(variable, read, write)..fileOffset = offset;
    }
  }

  @override
  Expression doInvocation(
      int offset, List<TypeBuilder>? typeArguments, Arguments arguments,
      {bool isTypeArgumentsInForest = false}) {
    VariableDeclarationImpl? receiverVariable;
    Expression receiverExpression = receiver;
    if (isNullAware) {
      receiverVariable = _helper.createVariableDeclarationForValue(receiver);
      receiverExpression = _helper.createVariableGet(
          receiverVariable, receiverVariable.fileOffset,
          forNullGuardedAccess: true);
    }
    Expression invocation;
    if (invokeTarget != null) {
      invocation = _helper.buildExtensionMethodInvocation(
          fileOffset,
          invokeTarget!,
          _forest.createArgumentsForExtensionMethod(
              fileOffset,
              extensionTypeParameterCount,
              invokeTarget!.function.typeParameters.length -
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
      return new NullAwareExtension(receiverVariable!, invocation)
        ..fileOffset = fileOffset;
    } else {
      return invocation;
    }
  }

  @override
  Generator buildIndexedAccess(Expression index, Token token,
      {required bool isNullAware}) {
    return new IndexedAccessGenerator(_helper, token, buildSimpleRead(), index,
        isNullAware: isNullAware);
  }

  @override
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
  final int extensionTypeArgumentOffset;

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
  final List<DartType>? explicitTypeArguments;

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
      {required this.isNullAware})
      : assert(readTarget != null || writeTarget != null),
        super(helper, token);

  factory ExplicitExtensionIndexedAccessGenerator.fromBuilder(
      ExpressionGeneratorHelper helper,
      Token token,
      int extensionTypeArgumentOffset,
      Extension extension,
      Builder? getterBuilder,
      Builder? setterBuilder,
      Expression receiver,
      Expression index,
      List<DartType>? explicitTypeArguments,
      int extensionTypeParameterCount,
      {required bool isNullAware}) {
    Procedure? readTarget;
    if (getterBuilder != null) {
      if (getterBuilder is AccessErrorBuilder) {
        AccessErrorBuilder error = getterBuilder;
        getterBuilder = error.builder;
        // We should only see an access error here if we've looked up a setter
        // when not explicitly looking for a setter.
        assert(getterBuilder is MemberBuilder);
      } else if (getterBuilder is MemberBuilder) {
        MemberBuilder procedureBuilder = getterBuilder;
        readTarget = procedureBuilder.member as Procedure?;
      } else {
        return unhandled(
            "${getterBuilder.runtimeType}",
            "InstanceExtensionAccessGenerator.fromBuilder",
            offsetForToken(token),
            helper.uri);
      }
    }
    Procedure? writeTarget;
    if (setterBuilder is MemberBuilder) {
      MemberBuilder memberBuilder = setterBuilder;
      writeTarget = memberBuilder.member as Procedure?;
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

  @override
  String get _plainNameForRead => "[]";

  @override
  String get _debugName => "ExplicitExtensionIndexedAccessGenerator";

  @override
  Expression buildSimpleRead() {
    if (readTarget == null) {
      return _makeInvalidRead(UnresolvedKind.Method);
    }
    VariableDeclarationImpl? variable;
    Expression receiverValue;
    if (isNullAware) {
      variable = _helper.createVariableDeclarationForValue(receiver);
      receiverValue = _helper.createVariableGet(variable, fileOffset,
          forNullGuardedAccess: true);
    } else {
      receiverValue = receiver;
    }
    Expression result = _helper.buildExtensionMethodInvocation(
        fileOffset,
        readTarget!,
        _forest.createArgumentsForExtensionMethod(
            fileOffset, extensionTypeParameterCount, 0, receiverValue,
            extensionTypeArguments: _createExtensionTypeArguments(),
            extensionTypeArgumentOffset: extensionTypeArgumentOffset,
            positionalArguments: <Expression>[index]),
        isTearOff: false);
    if (isNullAware) {
      result = new NullAwareMethodInvocation(variable!, result)
        ..fileOffset = fileOffset;
    }
    return result;
  }

  @override
  Expression buildAssignment(Expression value, {bool voidContext = false}) {
    if (writeTarget == null) {
      return _makeInvalidWrite(value);
    }
    VariableDeclarationImpl? variable;
    Expression receiverValue;
    if (isNullAware) {
      variable = _helper.createVariableDeclarationForValue(receiver);
      receiverValue = _helper.createVariableGet(variable, fileOffset,
          forNullGuardedAccess: true);
    } else {
      receiverValue = receiver;
    }
    Expression result;
    if (voidContext) {
      result = _helper.buildExtensionMethodInvocation(
          fileOffset,
          writeTarget!,
          _forest.createArgumentsForExtensionMethod(
              fileOffset, extensionTypeParameterCount, 0, receiverValue,
              extensionTypeArguments: _createExtensionTypeArguments(),
              extensionTypeArgumentOffset: extensionTypeArgumentOffset,
              positionalArguments: <Expression>[index, value]),
          isTearOff: false);
    } else {
      result = new ExtensionIndexSet(extension, explicitTypeArguments,
          receiverValue, writeTarget!, index, value)
        ..fileOffset = fileOffset;
    }
    if (isNullAware) {
      result = new NullAwareMethodInvocation(variable!, result)
        ..fileOffset = fileOffset;
    }
    return result;
  }

  @override
  Expression buildIfNullAssignment(Expression value, DartType type, int offset,
      {bool voidContext = false}) {
    VariableDeclarationImpl? variable;
    Expression receiverValue;
    if (isNullAware) {
      variable = _helper.createVariableDeclarationForValue(receiver);
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
      result = new NullAwareMethodInvocation(variable!, result)
        ..fileOffset = fileOffset;
    }
    return result;
  }

  @override
  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset = TreeNode.noOffset,
      bool voidContext = false,
      bool isPreIncDec = false,
      bool isPostIncDec = false}) {
    VariableDeclarationImpl? variable;
    Expression receiverValue;
    if (isNullAware) {
      variable = _helper.createVariableDeclarationForValue(receiver);
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
      result = new NullAwareMethodInvocation(variable!, result)
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
      int offset, List<TypeBuilder>? typeArguments, Arguments arguments,
      {bool isTypeArgumentsInForest = false}) {
    return _helper.forest
        .createExpressionInvocation(offset, buildSimpleRead(), arguments);
  }

  @override
  Generator buildIndexedAccess(Expression index, Token token,
      {required bool isNullAware}) {
    return new IndexedAccessGenerator(_helper, token, buildSimpleRead(), index,
        isNullAware: isNullAware);
  }

  @override
  void printOn(StringSink sink) {
    NameSystem syntheticNames = new NameSystem();
    sink.write(", index: ");
    printNodeOn(index, sink, syntheticNames: syntheticNames);
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
  final List<DartType>? explicitTypeArguments;

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
  Expression buildAssignment(Expression value, {bool voidContext = false}) {
    return _makeInvalidWrite(value);
  }

  @override
  Expression buildIfNullAssignment(Expression value, DartType type, int offset,
      {bool voidContext = false}) {
    return _makeInvalidRead();
  }

  @override
  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset = TreeNode.noOffset,
      bool voidContext = false,
      bool isPreIncDec = false,
      bool isPostIncDec = false}) {
    return _makeInvalidRead();
  }

  @override
  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset = TreeNode.noOffset, bool voidContext = false}) {
    return _makeInvalidRead();
  }

  Generator _createInstanceAccess(Token token, Name name,
      {bool isNullAware = false}) {
    Builder? getter = extensionBuilder.lookupLocalMemberByName(name);
    if (getter != null && getter.isStatic) {
      getter = null;
    }
    Builder? setter =
        extensionBuilder.lookupLocalMemberByName(name, setter: true);
    if (setter != null && setter.isStatic) {
      setter = null;
    }
    if (getter == null && setter == null) {
      return new UnresolvedNameGenerator(_helper, token, name,
          unresolvedReadKind: UnresolvedKind.Member);
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

  @override
  Expression_Generator buildSelectorAccess(
      Selector selector, int operatorOffset, bool isNullAware) {
    selector.reportNewAsSelector();
    if (_helper.constantContext != ConstantContext.none) {
      _helper.addProblem(
          messageNotAConstantExpression, fileOffset, token.length);
    }
    Generator generator = _createInstanceAccess(selector.token, selector.name,
        isNullAware: isNullAware);
    if (selector.arguments != null) {
      return generator.doInvocation(offsetForToken(selector.token),
          selector.typeArguments, selector.arguments! as ArgumentsImpl,
          isTypeArgumentsInForest: selector.isTypeArgumentsInForest);
    } else {
      return generator;
    }
  }

  @override
  Expression_Generator buildBinaryOperation(
      Token token, Name binaryName, Expression right) {
    int fileOffset = offsetForToken(token);
    Generator generator = _createInstanceAccess(token, binaryName);
    return generator.doInvocation(fileOffset, null,
        _forest.createArguments(fileOffset, <Expression>[right]));
  }

  @override
  Expression_Generator buildUnaryOperation(Token token, Name unaryName) {
    int fileOffset = offsetForToken(token);
    Generator generator = _createInstanceAccess(token, unaryName);
    return generator.doInvocation(
        fileOffset, null, _forest.createArgumentsEmpty(fileOffset));
  }

  @override
  Expression_Generator_Initializer doInvocation(
      int offset, List<TypeBuilder>? typeArguments, ArgumentsImpl arguments,
      {bool isTypeArgumentsInForest = false}) {
    Generator generator = _createInstanceAccess(token, callName);
    return generator.doInvocation(offset, typeArguments, arguments,
        isTypeArgumentsInForest: isTypeArgumentsInForest);
  }

  @override
  Expression _makeInvalidRead([UnresolvedKind? unresolvedKind]) {
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
      {required bool isNullAware}) {
    Builder? getter = extensionBuilder.lookupLocalMemberByName(indexGetName);
    Builder? setter = extensionBuilder.lookupLocalMemberByName(indexSetName);
    if (getter == null && setter == null) {
      return new UnresolvedNameGenerator(_helper, token, indexGetName,
          unresolvedReadKind: UnresolvedKind.Method);
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
  Expression buildAssignment(Expression value, {bool voidContext = false}) {
    return _makeInvalidWrite(value);
  }

  @override
  Expression buildIfNullAssignment(Expression value, DartType type, int offset,
      {bool voidContext = false}) {
    Expression read = buildSimpleRead();
    Expression write = _makeInvalidWrite(value);
    return new IfNullSet(read, write, forEffect: voidContext)
      ..fileOffset = offset;
  }

  @override
  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset = TreeNode.noOffset,
      bool voidContext = false,
      bool isPreIncDec = false,
      bool isPostIncDec = false}) {
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
      int offset, List<TypeBuilder>? typeArguments, Arguments arguments,
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
      {required bool isNullAware}) {
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
  Expression buildAssignment(Expression value, {bool voidContext = false}) {
    return _helper.wrapInDeferredCheck(
        suffixGenerator.buildAssignment(value, voidContext: voidContext),
        prefixGenerator.prefix,
        token.charOffset);
  }

  @override
  Expression buildIfNullAssignment(Expression value, DartType type, int offset,
      {bool voidContext = false}) {
    return _helper.wrapInDeferredCheck(
        suffixGenerator.buildIfNullAssignment(value, type, offset,
            voidContext: voidContext),
        prefixGenerator.prefix,
        token.charOffset);
  }

  @override
  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset = TreeNode.noOffset,
      bool voidContext = false,
      bool isPreIncDec = false,
      bool isPostIncDec = false}) {
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
      {int offset = TreeNode.noOffset, bool voidContext = false}) {
    return _helper.wrapInDeferredCheck(
        suffixGenerator.buildPostfixIncrement(binaryOperator,
            offset: offset, voidContext: voidContext),
        prefixGenerator.prefix,
        token.charOffset);
  }

  @override
  Expression_Generator buildSelectorAccess(
      Selector selector, int operatorOffset, bool isNullAware) {
    selector.reportNewAsSelector();
    Object propertyAccess = suffixGenerator.buildSelectorAccess(
        selector, operatorOffset, isNullAware);
    if (propertyAccess is Generator) {
      return new DeferredAccessGenerator(
          _helper, token, prefixGenerator, propertyAccess);
    } else {
      Expression expression = propertyAccess as Expression;
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
      NullabilityBuilder nullabilityBuilder, List<TypeBuilder>? arguments,
      {required bool allowPotentiallyConstantType,
      required bool performTypeCanonicalization}) {
    String name = "${prefixGenerator._plainNameForRead}."
        "${suffixGenerator._plainNameForRead}";
    TypeBuilder type = suffixGenerator.buildTypeWithResolvedArguments(
        nullabilityBuilder, arguments,
        allowPotentiallyConstantType: allowPotentiallyConstantType,
        performTypeCanonicalization: performTypeCanonicalization);
    LocatedMessage message;
    if (type is NamedTypeBuilder &&
        type.declaration is InvalidTypeDeclarationBuilder) {
      InvalidTypeDeclarationBuilder declaration =
          type.declaration as InvalidTypeDeclarationBuilder;
      message = declaration.message;
    } else {
      int charOffset = offsetForToken(prefixGenerator.token);
      message = templateDeferredTypeAnnotation
          .withArguments(
              _helper.buildDartType(type, TypeUse.deferredTypeError,
                  allowPotentiallyConstantType: allowPotentiallyConstantType),
              prefixGenerator._plainNameForRead,
              _helper.libraryBuilder.isNonNullableByDefault)
          .withLocation(
              _uri, charOffset, lengthOfSpan(prefixGenerator.token, token));
    }
    _helper.libraryBuilder.addProblem(
        message.messageObject, message.charOffset, message.length, message.uri);
    return new NamedTypeBuilderImpl.forInvalidType(
        name, nullabilityBuilder, message);
  }

  @override
  Expression_Generator_Initializer doInvocation(
      int offset, List<TypeBuilder>? typeArguments, ArgumentsImpl arguments,
      {bool isTypeArgumentsInForest = false}) {
    Object suffix = suffixGenerator.doInvocation(
        offset, typeArguments, arguments,
        isTypeArgumentsInForest: isTypeArgumentsInForest);
    if (suffix is Expression) {
      return _helper.wrapInDeferredCheck(
          suffix, prefixGenerator.prefix, fileOffset);
    } else {
      return new DeferredAccessGenerator(
          _helper, token, prefixGenerator, suffix as Generator);
    }
  }

  @override
  Expression invokeConstructor(
      List<TypeBuilder>? typeArguments,
      String name,
      Arguments arguments,
      Token nameToken,
      Token nameLastToken,
      Constness constness,
      {required bool inImplicitCreationContext}) {
    return _helper.wrapInDeferredCheck(
        suffixGenerator.invokeConstructor(
            typeArguments, name, arguments, nameToken, nameLastToken, constness,
            inImplicitCreationContext: inImplicitCreationContext),
        prefixGenerator.prefix,
        offsetForToken(suffixGenerator.token));
  }

  @override
  Generator buildIndexedAccess(Expression index, Token token,
      {required bool isNullAware}) {
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
class TypeUseGenerator extends AbstractReadOnlyAccessGenerator {
  final TypeDeclarationBuilder declaration;
  List<TypeBuilder>? typeArguments;

  final TypeName typeName;

  Expression? _expression;

  TypeUseGenerator(ExpressionGeneratorHelper helper, Token token,
      this.declaration, this.typeName)
      : super(
            helper,
            token,
            // TODO(johnniwinther): InvalidTypeDeclarationBuilder is currently
            // misused for import conflict.
            declaration is InvalidTypeDeclarationBuilder
                ? ReadOnlyAccessKind.InvalidDeclaration
                : ReadOnlyAccessKind.TypeLiteral);

  @override
  String get targetName => typeName.name;

  @override
  String get _debugName => "TypeUseGenerator";

  @override
  TypeBuilder buildTypeWithResolvedArguments(
      NullabilityBuilder nullabilityBuilder, List<TypeBuilder>? arguments,
      {required bool allowPotentiallyConstantType,
      required bool performTypeCanonicalization}) {
    if (declaration is OmittedTypeDeclarationBuilder) {
      // TODO(johnniwinther): Report errors when this occurs in-body or with
      // type arguments.
      // TODO(johnniwinther): Handle nullability.
      return new DependentTypeBuilder(
          (declaration as OmittedTypeDeclarationBuilder).omittedTypeBuilder);
    }
    return new NamedTypeBuilderImpl(typeName, nullabilityBuilder,
        arguments: arguments,
        fileUri: _uri,
        charOffset: fileOffset,
        instanceTypeVariableAccess: _helper.instanceTypeVariableAccessState,
        performTypeCanonicalization: performTypeCanonicalization)
      ..bind(_helper.libraryBuilder, declaration);
  }

  @override
  Expression invokeConstructor(
      List<TypeBuilder>? typeArguments,
      String name,
      Arguments arguments,
      Token nameToken,
      Token nameLastToken,
      Constness constness,
      {required bool inImplicitCreationContext}) {
    return _helper.buildConstructorInvocation(
        declaration,
        nameToken,
        nameLastToken,
        arguments,
        name,
        typeArguments,
        offsetForToken(nameToken),
        constness,
        unresolvedKind: UnresolvedKind.Constructor);
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
    if (_expression == null) {
      if (declaration is InvalidTypeDeclarationBuilder) {
        InvalidTypeDeclarationBuilder declaration =
            this.declaration as InvalidTypeDeclarationBuilder;
        _expression = _helper.buildProblemErrorIfConst(
            declaration.message.messageObject, fileOffset, token.length);
      } else {
        _expression = _forest.createTypeLiteral(
            offsetForToken(token),
            _helper.buildDartType(
                buildTypeWithResolvedArguments(
                    _helper.libraryBuilder.nonNullableBuilder, typeArguments,
                    allowPotentiallyConstantType: true,
                    performTypeCanonicalization: true),
                TypeUse.typeLiteral,
                allowPotentiallyConstantType:
                    _helper.libraryFeatures.constructorTearoffs.isEnabled));
      }
    }
    return _expression!;
  }

  @override
  Expression_Generator buildSelectorAccess(
      Selector send, int operatorOffset, bool isNullAware) {
    int nameOffset = offsetForToken(send.token);
    Name name = send.name;
    ArgumentsImpl? arguments = send.arguments as ArgumentsImpl?;

    TypeDeclarationBuilder? declarationBuilder = declaration;
    TypeAliasBuilder? aliasBuilder;
    List<TypeBuilder>? unaliasedTypeArguments;
    bool isGenericTypedefTearOff = false;
    if (declarationBuilder is TypeAliasBuilder) {
      aliasBuilder = declarationBuilder;
      declarationBuilder = aliasBuilder.unaliasDeclaration(null,
          isUsedAsClass: true,
          usedAsClassCharOffset: this.fileOffset,
          usedAsClassFileUri: _uri);

      bool supportsConstructorTearOff =
          _helper.libraryFeatures.constructorTearoffs.isEnabled &&
              switch (declarationBuilder) {
                ClassBuilder() => true,
                ExtensionBuilder() => false,
                ExtensionTypeDeclarationBuilder() => true,
                TypeAliasBuilder() => false,
                NominalVariableBuilder() => false,
                StructuralVariableBuilder() => false,
                InvalidTypeDeclarationBuilder() => false,
                BuiltinTypeDeclarationBuilder() => false,
                // TODO(johnniwinther): How should we handle this case?
                OmittedTypeDeclarationBuilder() => false,
                null => false,
              };
      bool isConstructorTearOff =
          send is PropertySelector && supportsConstructorTearOff;
      List<TypeBuilder>? aliasedTypeArguments = typeArguments
          ?.map((unknownType) => _helper.validateTypeVariableUse(unknownType,
              allowPotentiallyConstantType: isConstructorTearOff))
          .toList();
      if (aliasedTypeArguments != null &&
          aliasedTypeArguments.length != aliasBuilder.typeVariablesCount) {
        _helper.libraryBuilder.addProblem(
            templateTypeArgumentMismatch
                .withArguments(aliasBuilder.typeVariablesCount),
            fileOffset,
            noLength,
            _uri);
      } else {
        if (declarationBuilder is DeclarationBuilder) {
          if (aliasedTypeArguments != null) {
            new NamedTypeBuilderImpl(
                typeName, const NullabilityBuilder.omitted(),
                arguments: aliasedTypeArguments,
                fileUri: _uri,
                charOffset: fileOffset,
                instanceTypeVariableAccess:
                    _helper.instanceTypeVariableAccessState)
              ..bind(_helper.libraryBuilder, aliasBuilder)
              ..build(_helper.libraryBuilder, TypeUse.instantiation);
          }

          // If the arguments weren't supplied, the tear off is treated as
          // generic, and the aliased type arguments match type parameters of
          // the type alias.
          if (aliasedTypeArguments == null &&
              aliasBuilder.typeVariablesCount != 0) {
            isGenericTypedefTearOff = true;
            aliasedTypeArguments = <TypeBuilder>[];
            for (NominalVariableBuilder typeVariable
                in aliasBuilder.typeVariables!) {
              aliasedTypeArguments.add(new NamedTypeBuilderImpl(
                  new SyntheticTypeName(typeVariable.name, fileOffset),
                  const NullabilityBuilder.omitted(),
                  fileUri: _uri,
                  charOffset: fileOffset,
                  instanceTypeVariableAccess:
                      _helper.instanceTypeVariableAccessState)
                ..bind(_helper.libraryBuilder, typeVariable));
            }
          }
          unaliasedTypeArguments =
              aliasBuilder.unaliasTypeArguments(aliasedTypeArguments);
        }
      }
    }
    if (declarationBuilder is DeclarationBuilder) {
      Builder? member = declarationBuilder.findStaticBuilder(
          name.text, nameOffset, _uri, _helper.libraryBuilder);
      Generator generator;
      bool supportsConstructorTearOff =
          _helper.libraryFeatures.constructorTearoffs.isEnabled &&
              switch (declarationBuilder) {
                ClassBuilder() => true,
                ExtensionBuilder() => false,
                ExtensionTypeDeclarationBuilder() => true,
              };
      if (member == null) {
        // If we find a setter, [member] is an [AccessErrorBuilder], not null.
        if (send is PropertySelector) {
          assert(
              send.typeArguments == null,
              "Unexpected non-null typeArguments of "
              "an IncompletePropertyAccessGenerator object: "
              "'${send.typeArguments.runtimeType}'.");
          if (supportsConstructorTearOff) {
            MemberBuilder? constructor =
                declarationBuilder.findConstructorOrFactory(
                    name.text, nameOffset, _uri, _helper.libraryBuilder);
            Member? tearOff = constructor?.readTarget;
            Expression? tearOffExpression;
            if (tearOff is Constructor) {
              if (declarationBuilder is ClassBuilder &&
                  declarationBuilder.isAbstract) {
                return _helper.buildProblem(
                    messageAbstractClassConstructorTearOff,
                    nameOffset,
                    name.text.length);
              } else if (declarationBuilder.isEnum) {
                return _helper.buildProblem(messageEnumConstructorTearoff,
                    nameOffset, name.text.length);
              }
              tearOffExpression = _helper.forest
                  .createConstructorTearOff(token.charOffset, tearOff);
            } else if (tearOff is Procedure) {
              if (tearOff.isRedirectingFactory) {
                tearOffExpression = _helper.forest
                    .createRedirectingFactoryTearOff(token.charOffset, tearOff);
              } else if (tearOff.isFactory) {
                tearOffExpression = _helper.forest
                    .createConstructorTearOff(token.charOffset, tearOff);
              } else {
                tearOffExpression = _helper.forest
                    .createStaticTearOff(token.charOffset, tearOff);
              }
            } else if (tearOff != null) {
              unhandled("${tearOff.runtimeType}", "buildPropertyAccess",
                  operatorOffset, _helper.uri);
            }
            if (tearOffExpression != null) {
              List<DartType>? builtTypeArguments;
              if (unaliasedTypeArguments != null) {
                if (unaliasedTypeArguments.length !=
                    declarationBuilder.typeVariablesCount) {
                  // The type arguments are either aren't provided or mismatch
                  // in number with the type variables of the RHS declaration.
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
                    case ExtensionTypeDeclarationBuilder():
                      for (TypeParameter typeParameter in declarationBuilder
                          .extensionTypeDeclaration.typeParameters) {
                        builtTypeArguments.add(typeParameter.defaultType);
                      }
                    case ExtensionBuilder():
                      throw new UnsupportedError(
                          "Unexpected declaration $declarationBuilder");
                  }
                } else {
                  builtTypeArguments = unaliasTypes(
                      declarationBuilder.buildAliasedTypeArguments(
                          _helper.libraryBuilder,
                          unaliasedTypeArguments,
                          /* hierarchy = */ null),
                      legacyEraseAliases:
                          !_helper.libraryBuilder.isNonNullableByDefault)!;
                }
              } else if (typeArguments != null) {
                builtTypeArguments = _helper.buildDartTypeArguments(
                    typeArguments, TypeUse.tearOffTypeArgument,
                    allowPotentiallyConstantType: true);
              }
              if (isGenericTypedefTearOff) {
                if (isProperRenameForTypeDeclaration(
                    _helper.typeEnvironment,
                    aliasBuilder!.typedef,
                    aliasBuilder.libraryBuilder.library)) {
                  return tearOffExpression;
                }
                Procedure? tearOffLowering =
                    aliasBuilder.findConstructorOrFactory(
                        name.text, nameOffset, _uri, _helper.libraryBuilder);
                if (tearOffLowering != null) {
                  if (tearOffLowering.isFactory) {
                    return _helper.forest.createConstructorTearOff(
                        token.charOffset, tearOffLowering);
                  } else {
                    return _helper.forest
                        .createStaticTearOff(token.charOffset, tearOffLowering);
                  }
                }
                FreshTypeParameters freshTypeParameters =
                    getFreshTypeParameters(aliasBuilder.typedef.typeParameters);
                List<DartType>? substitutedTypeArguments;
                if (builtTypeArguments != null) {
                  substitutedTypeArguments = <DartType>[];
                  for (DartType builtTypeArgument in builtTypeArguments) {
                    substitutedTypeArguments
                        .add(freshTypeParameters.substitute(builtTypeArgument));
                  }
                }
                substitutedTypeArguments = unaliasTypes(
                    substitutedTypeArguments,
                    legacyEraseAliases:
                        !_helper.libraryBuilder.isNonNullableByDefault);

                tearOffExpression = _helper.forest.createTypedefTearOff(
                    token.charOffset,
                    freshTypeParameters.freshTypeParameters,
                    tearOffExpression,
                    substitutedTypeArguments ?? const <DartType>[]);
              } else {
                if (builtTypeArguments != null &&
                    builtTypeArguments.isNotEmpty) {
                  builtTypeArguments = unaliasTypes(builtTypeArguments,
                      legacyEraseAliases:
                          !_helper.libraryBuilder.isNonNullableByDefault)!;

                  tearOffExpression = _helper.forest.createInstantiation(
                      token.charOffset, tearOffExpression, builtTypeArguments);
                }
              }
              return tearOffExpression;
            }
          }
          generator = new UnresolvedNameGenerator(_helper, send.token, name,
              unresolvedReadKind: UnresolvedKind.Member);
        } else {
          return _helper.buildConstructorInvocation(
              declarationBuilder,
              send.token,
              send.token,
              arguments!,
              name.text,
              send.typeArguments,
              token.charOffset,
              Constness.implicit,
              isTypeArgumentsInForest: send.isTypeArgumentsInForest,
              typeAliasBuilder: aliasBuilder,
              unresolvedKind:
                  isNullAware ? UnresolvedKind.Method : UnresolvedKind.Member);
        }
      } else if (member is AmbiguousBuilder) {
        return _helper.buildProblem(
            member.message, member.charOffset, name.text.length);
      } else if (member.isStatic &&
          !member.isFactory &&
          typeArguments != null) {
        return _helper.buildProblem(messageStaticTearOffFromInstantiatedClass,
            send.fileOffset, send.name.text.length);
      } else {
        Builder? setter;
        if (member.isSetter) {
          setter = member;
          member = null;
        } else if (member.isGetter) {
          setter = declarationBuilder.findStaticBuilder(
              name.text, fileOffset, _uri, _helper.libraryBuilder,
              isSetter: true);
        } else if (member.isField) {
          MemberBuilder fieldBuilder = member as MemberBuilder;
          if (!fieldBuilder.isAssignable) {
            setter = declarationBuilder.findStaticBuilder(
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
      return super.buildSelectorAccess(send, operatorOffset, isNullAware);
    }
  }

  @override
  Expression_Generator_Builder doInvocation(
      int offset, List<TypeBuilder>? typeArguments, Arguments arguments,
      {bool isTypeArgumentsInForest = false}) {
    if (declaration.isExtension) {
      ExtensionBuilder extensionBuilder = declaration as ExtensionBuilder;
      if (arguments.positional.length != 1 || arguments.named.isNotEmpty) {
        return _helper.buildProblem(messageExplicitExtensionArgumentMismatch,
            fileOffset, lengthForToken(token));
      }
      List<DartType>? explicitTypeArguments =
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
      return new ExplicitExtensionAccessGenerator(
          _helper,
          token,
          declaration as ExtensionBuilder,
          arguments.positional.single,
          explicitTypeArguments);
    } else {
      return _helper.buildConstructorInvocation(declaration, token, token,
          arguments, "", typeArguments, token.charOffset, Constness.implicit,
          isTypeArgumentsInForest: isTypeArgumentsInForest,
          unresolvedKind: UnresolvedKind.Constructor);
    }
  }

  @override
  Expression_Generator applyTypeArguments(
      int fileOffset, List<TypeBuilder>? typeArguments) {
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

  ReadOnlyAccessGenerator(ExpressionGeneratorHelper helper, Token token,
      this.expression, this.targetName, ReadOnlyAccessKind kind)
      : super(helper, token, kind);
}

abstract class AbstractReadOnlyAccessGenerator extends Generator {
  final ReadOnlyAccessKind kind;

  AbstractReadOnlyAccessGenerator(
      ExpressionGeneratorHelper helper, Token token, this.kind)
      : super(helper, token);

  String get targetName;

  Expression get expression;

  @override
  String get _debugName => "ReadOnlyAccessGenerator";

  @override
  String get _plainNameForRead => targetName;

  @override
  Expression buildSimpleRead() => _createRead();

  Expression _createRead() => expression;

  @override
  Expression _makeInvalidWrite(Expression value) {
    switch (kind) {
      case ReadOnlyAccessKind.ConstVariable:
        return _helper.buildProblem(
            templateCannotAssignToConstVariable.withArguments(targetName),
            fileOffset,
            lengthForToken(token));
      case ReadOnlyAccessKind.FinalVariable:
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
  Expression buildAssignment(Expression value, {bool voidContext = false}) {
    return _makeInvalidWrite(value);
  }

  @override
  Expression buildIfNullAssignment(Expression value, DartType type, int offset,
      {bool voidContext = false}) {
    Expression read = _createRead();
    Expression write = _makeInvalidWrite(value);
    return new IfNullSet(read, write, forEffect: voidContext)
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
  Expression_Generator_Initializer doInvocation(
      int offset, List<TypeBuilder>? typeArguments, Arguments arguments,
      {bool isTypeArgumentsInForest = false}) {
    return _helper.forest.createExpressionInvocation(
        adjustForImplicitCall(targetName, offset), _createRead(), arguments);
  }

  @override
  Generator buildIndexedAccess(Expression index, Token token,
      {required bool isNullAware}) {
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

  Expression buildError(
      {Arguments? arguments,
      Expression? rhs,
      required UnresolvedKind kind,
      int? charOffset});

  Name get name => unsupported("name", fileOffset, _uri);

  @override
  String get _plainNameForRead => name.text;

  @override
  List<Initializer> buildFieldInitializer(Map<String, int>? initializedFields) {
    return <Initializer>[
      _helper.buildInvalidInitializer(buildError(kind: UnresolvedKind.Setter))
    ];
  }

  @override
  Expression_Generator_Initializer doInvocation(
      int offset, List<TypeBuilder>? typeArguments, Arguments arguments,
      {bool isTypeArgumentsInForest = false}) {
    return buildError(
        arguments: arguments, charOffset: offset, kind: UnresolvedKind.Method);
  }

  @override
  Expression_Generator buildSelectorAccess(
      Selector send, int operatorOffset, bool isNullAware) {
    return send.withReceiver(buildSimpleRead(), operatorOffset,
        isNullAware: isNullAware);
  }

  @override
  Expression buildAssignment(Expression value, {bool voidContext = false}) {
    return buildError(rhs: value, kind: UnresolvedKind.Setter);
  }

  @override
  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset = -1,
      bool voidContext = false,
      bool isPreIncDec = false,
      bool isPostIncDec = false}) {
    return buildError(rhs: value, kind: UnresolvedKind.Getter);
  }

  @override
  Expression buildPrefixIncrement(Name binaryOperator,
      {int offset = -1, bool voidContext = false}) {
    return buildError(
        arguments: _forest.createArguments(
            fileOffset, <Expression>[_forest.createIntLiteral(offset, 1)]),
        kind: UnresolvedKind.Getter)
      ..fileOffset = offset;
  }

  @override
  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset = -1, bool voidContext = false}) {
    return buildError(
        arguments: _forest.createArguments(
            fileOffset, <Expression>[_forest.createIntLiteral(offset, 1)]),
        kind: UnresolvedKind.Getter)
      ..fileOffset = offset;
  }

  @override
  Expression buildIfNullAssignment(Expression value, DartType type, int offset,
      {bool voidContext = false}) {
    return buildError(rhs: value, kind: UnresolvedKind.Setter);
  }

  @override
  Expression buildSimpleRead() {
    return buildError(kind: UnresolvedKind.Member);
  }

  @override
  Expression _makeInvalidRead(UnresolvedKind unresolvedKind) {
    return buildError(kind: unresolvedKind);
  }

  @override
  Expression _makeInvalidWrite(Expression value) {
    return buildError(rhs: value, kind: UnresolvedKind.Setter);
  }

  @override
  Expression invokeConstructor(
      List<TypeBuilder>? typeArguments,
      String name,
      Arguments arguments,
      Token nameToken,
      Token nameLastToken,
      Constness constness,
      {required bool inImplicitCreationContext}) {
    if (typeArguments != null) {
      assert(_forest.argumentsTypeArguments(arguments).isEmpty);
      _forest.argumentsSetTypeArguments(
          arguments,
          _helper.buildDartTypeArguments(
              typeArguments, TypeUse.constructorTypeArgument,
              allowPotentiallyConstantType: false));
    }
    return buildError(arguments: arguments, kind: UnresolvedKind.Constructor);
  }

  @override
  Generator buildIndexedAccess(Expression index, Token token,
      {required bool isNullAware}) {
    return new IndexedAccessGenerator(_helper, token, buildSimpleRead(), index,
        isNullAware: isNullAware);
  }
}

class UnresolvedNameGenerator extends ErroneousExpressionGenerator {
  @override
  final Name name;

  final UnresolvedKind unresolvedReadKind;

  factory UnresolvedNameGenerator(
      ExpressionGeneratorHelper helper, Token token, Name name,
      {required UnresolvedKind unresolvedReadKind}) {
    if (name.text.isEmpty) {
      unhandled("empty", "name", offsetForToken(token), helper.uri);
    }
    return new UnresolvedNameGenerator.internal(
        helper, token, name, unresolvedReadKind);
  }

  UnresolvedNameGenerator.internal(ExpressionGeneratorHelper helper,
      Token token, this.name, this.unresolvedReadKind)
      : super(helper, token);

  @override
  String get _debugName => "UnresolvedNameGenerator";

  @override
  Expression doInvocation(
      int charOffset, List<TypeBuilder>? typeArguments, Arguments arguments,
      {bool isTypeArgumentsInForest = false}) {
    return buildError(
        arguments: arguments,
        charOffset: charOffset,
        kind: UnresolvedKind.Method);
  }

  @override
  Expression buildError(
      {Arguments? arguments,
      Expression? rhs,
      required UnresolvedKind kind,
      int? charOffset}) {
    charOffset ??= fileOffset;
    return _helper.buildUnresolvedError(_plainNameForRead, charOffset,
        arguments: arguments, rhs: rhs, kind: kind);
  }

  @override
  /* Expression | Generator */ Object qualifiedLookup(Token name) {
    return new UnexpectedQualifiedUseGenerator(_helper, name, this, true);
  }

  @override
  Expression buildAssignment(Expression value, {bool voidContext = false}) {
    return _buildUnresolvedVariableAssignment(false, value);
  }

  @override
  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset = TreeNode.noOffset,
      bool voidContext = false,
      bool isPreIncDec = false,
      bool isPostIncDec = false}) {
    return _buildUnresolvedVariableAssignment(true, value);
  }

  @override
  Expression buildSimpleRead() {
    return buildError(kind: unresolvedReadKind)..fileOffset = fileOffset;
  }

  @override
  void printOn(StringSink sink) {
    sink.write(", name: ");
    sink.write(name.text);
  }

  Expression _buildUnresolvedVariableAssignment(
      bool isCompound, Expression value) {
    return buildError(rhs: value, kind: UnresolvedKind.Setter);
  }

  @override
  Generator buildIndexedAccess(Expression index, Token token,
      {required bool isNullAware}) {
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
  Never doInvocation(
      int charOffset, List<TypeBuilder>? typeArguments, Arguments arguments,
      {bool isTypeArgumentsInForest = false}) {
    return unhandled("${runtimeType}", "doInvocation", charOffset, _uri);
  }

  @override
  Expression buildAssignment(Expression value, {bool voidContext = false}) {
    return _makeInvalidWrite(value);
  }

  @override
  Expression buildIfNullAssignment(Expression value, DartType type, int offset,
      {bool voidContext = false}) {
    return _makeInvalidWrite(value);
  }

  @override
  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset = -1,
      bool voidContext = false,
      bool isPreIncDec = false,
      bool isPostIncDec = false}) {
    return _makeInvalidWrite(value);
  }

  @override
  Expression buildPrefixIncrement(Name binaryOperator,
      {int offset = -1, bool voidContext = false}) {
    return _makeInvalidWrite(null);
  }

  @override
  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset = -1, bool voidContext = false}) {
    return _makeInvalidWrite(null);
  }

  @override
  Never _makeInvalidRead([UnresolvedKind? unresolvedKind]) {
    return unsupported("makeInvalidRead", token.charOffset, _helper.uri);
  }

  @override
  Expression _makeInvalidWrite(Expression? value) {
    return _helper.buildProblem(messageIllegalAssignmentToNonAssignable,
        fileOffset, lengthForToken(token));
  }

  @override
  Generator buildIndexedAccess(Expression index, Token token,
      {required bool isNullAware}) {
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
  List<Initializer> buildFieldInitializer(Map<String, int>? initializedFields) {
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
  Expression buildAssignment(Expression value, {bool voidContext = false}) {
    return _makeInvalidWrite(value);
  }

  @override
  Expression buildIfNullAssignment(Expression value, DartType type, int offset,
      {bool voidContext = false}) {
    return _makeInvalidRead();
  }

  @override
  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset = TreeNode.noOffset,
      bool voidContext = false,
      bool isPreIncDec = false,
      bool isPostIncDec = false}) {
    return _makeInvalidRead();
  }

  @override
  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset = TreeNode.noOffset, bool voidContext = false}) {
    return _makeInvalidRead();
  }

  @override
  /* Expression | Generator */ Object qualifiedLookup(Token nameToken) {
    if (_helper.constantContext != ConstantContext.none && prefix.deferred) {
      _helper.addProblem(
          templateCantUseDeferredPrefixAsConstant.withArguments(token),
          fileOffset,
          lengthForToken(token));
    }
    Object result = _helper.scopeLookup(prefix.exportScope, nameToken,
        prefix: prefix, prefixToken: token);
    if (prefix.deferred) {
      if (result is Generator) {
        if (result is! LoadLibraryGenerator) {
          result =
              new DeferredAccessGenerator(_helper, nameToken, this, result);
        }
      } else {
        _helper.wrapInDeferredCheck(result as Expression, prefix, fileOffset);
      }
    }
    return result;
  }

  @override
  Expression doInvocation(
      int offset, List<TypeBuilder>? typeArguments, Arguments arguments,
      {bool isTypeArgumentsInForest = false}) {
    return _helper.wrapInLocatedProblem(
        _helper.evaluateArgumentsBefore(
            arguments, _forest.createNullLiteral(fileOffset)),
        messageCantUsePrefixAsExpression.withLocation(
            _helper.uri, fileOffset, lengthForToken(token)));
  }

  @override
  Expression_Generator buildSelectorAccess(
      Selector selector, int operatorOffset, bool isNullAware) {
    assert(selector.name.text == selector.token.lexeme,
        "'${selector.name.text}' != ${selector.token.lexeme}");
    selector.reportNewAsSelector();
    Object result = qualifiedLookup(selector.token);
    if (selector is InvocationSelector) {
      result = _helper.finishSend(result, selector.typeArguments,
          selector.arguments as ArgumentsImpl, selector.fileOffset,
          isTypeArgumentsInForest: selector.isTypeArgumentsInForest);
    }
    if (isNullAware) {
      result = _helper.wrapInLocatedProblem(
          _helper.toValue(result),
          messageCantUsePrefixWithNullAware.withLocation(
              _helper.uri, fileOffset, lengthForToken(token)));
    }
    return result;
  }

  @override
  Expression _makeInvalidRead([UnresolvedKind? unresolvedKind]) {
    return _helper.buildProblem(
        messageCantUsePrefixAsExpression, fileOffset, lengthForToken(token));
  }

  @override
  Expression _makeInvalidWrite(Expression value) => _makeInvalidRead();

  @override
  Generator buildIndexedAccess(Expression index, Token token,
      {required bool isNullAware}) {
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
  Expression buildSimpleRead() => _makeInvalidRead(UnresolvedKind.Member);

  @override
  Expression buildAssignment(Expression value, {bool voidContext = false}) {
    return _makeInvalidWrite(value);
  }

  @override
  Expression buildIfNullAssignment(Expression value, DartType type, int offset,
      {bool voidContext = false}) {
    return _makeInvalidRead(UnresolvedKind.Member);
  }

  @override
  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset = TreeNode.noOffset,
      bool voidContext = false,
      bool isPreIncDec = false,
      bool isPostIncDec = false}) {
    return _makeInvalidRead(UnresolvedKind.Member);
  }

  @override
  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset = TreeNode.noOffset, bool voidContext = false}) {
    return _makeInvalidRead(UnresolvedKind.Member);
  }

  @override
  Expression doInvocation(
      int offset, List<TypeBuilder>? typeArguments, Arguments arguments,
      {bool isTypeArgumentsInForest = false}) {
    return _helper.buildUnresolvedError(_plainNameForRead, fileOffset,
        arguments: arguments, kind: UnresolvedKind.Method);
  }

  @override
  TypeBuilder buildTypeWithResolvedArguments(
      NullabilityBuilder nullabilityBuilder, List<TypeBuilder>? arguments,
      {required bool allowPotentiallyConstantType,
      required bool performTypeCanonicalization}) {
    Template<Message Function(String, String)> template = isUnresolved
        ? templateUnresolvedPrefixInTypeAnnotation
        : templateNotAPrefixInTypeAnnotation;
    // TODO(johnniwinther): Could we use a FixedTypeBuilder(InvalidType()) here?
    Message message =
        template.withArguments(prefixGenerator.token.lexeme, token.lexeme);
    _helper.libraryBuilder.addProblem(
        message,
        offsetForToken(prefixGenerator.token),
        lengthOfSpan(prefixGenerator.token, token),
        _uri);
    return new NamedTypeBuilderImpl.forInvalidType(
        _plainNameForRead,
        nullabilityBuilder,
        message.withLocation(_uri, offsetForToken(prefixGenerator.token),
            lengthOfSpan(prefixGenerator.token, token)));
  }

  @override
  Generator buildIndexedAccess(Expression index, Token token,
      {required bool isNullAware}) {
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

  @override
  Expression buildSimpleRead() => buildProblem();

  @override
  Expression buildAssignment(Expression value, {bool voidContext = false}) {
    return buildProblem();
  }

  @override
  Expression buildIfNullAssignment(Expression value, DartType type, int offset,
      {bool voidContext = false}) {
    return buildProblem();
  }

  @override
  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset = TreeNode.noOffset,
      bool voidContext = false,
      bool isPreIncDec = false,
      bool isPostIncDec = false}) {
    return buildProblem();
  }

  @override
  Expression buildPrefixIncrement(Name binaryOperator,
      {int offset = TreeNode.noOffset, bool voidContext = false}) {
    return buildProblem();
  }

  @override
  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset = TreeNode.noOffset, bool voidContext = false}) {
    return buildProblem();
  }

  @override
  Expression _makeInvalidRead([UnresolvedKind? unresolvedKind]) =>
      buildProblem();

  @override
  Expression _makeInvalidWrite(Expression value) => buildProblem();

  @override
  List<Initializer> buildFieldInitializer(Map<String, int>? initializedFields) {
    return <Initializer>[_helper.buildInvalidInitializer(buildProblem())];
  }

  @override
  Expression doInvocation(
      int offset, List<TypeBuilder>? typeArguments, Arguments arguments,
      {bool isTypeArgumentsInForest = false}) {
    return buildProblem();
  }

  @override
  Expression buildSelectorAccess(
      Selector send, int operatorOffset, bool isNullAware) {
    return buildProblem();
  }

  @override
  TypeBuilder buildTypeWithResolvedArguments(
      NullabilityBuilder nullabilityBuilder, List<TypeBuilder>? arguments,
      {required bool allowPotentiallyConstantType,
      required bool performTypeCanonicalization}) {
    _helper.libraryBuilder.addProblem(message, fileOffset, noLength, _uri);
    return new NamedTypeBuilderImpl.forInvalidType(token.lexeme,
        nullabilityBuilder, message.withLocation(_uri, fileOffset, noLength));
  }

  TypeBuilder buildTypeWithResolvedArgumentsDoNotAddProblem(
      NullabilityBuilder nullabilityBuilder) {
    return new NamedTypeBuilderImpl.forInvalidType(token.lexeme,
        nullabilityBuilder, message.withLocation(_uri, fileOffset, noLength));
  }

  @override
  Expression qualifiedLookup(Token name) {
    return buildProblem();
  }

  @override
  Expression invokeConstructor(
      List<TypeBuilder>? typeArguments,
      String name,
      Arguments arguments,
      Token nameToken,
      Token nameLastToken,
      Constness constness,
      {required bool inImplicitCreationContext}) {
    return buildProblem();
  }

  @override
  Generator buildIndexedAccess(Expression index, Token token,
      {required bool isNullAware}) {
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
      {this.isSuper = false})
      : super(helper, token);

  @override
  String get _plainNameForRead {
    return unsupported(
        "${isSuper ? 'super' : 'this'}.plainNameForRead", fileOffset, _uri);
  }

  @override
  String get _debugName => "ThisAccessGenerator";

  @override
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

  Expression buildFieldInitializerError(Map<String, int>? initializedFields) {
    String keyword = isSuper ? "super" : "this";
    return _helper.buildProblem(
        templateThisOrSuperAccessInFieldInitializer.withArguments(keyword),
        fileOffset,
        keyword.length);
  }

  @override
  List<Initializer> buildFieldInitializer(Map<String, int>? initializedFields) {
    Expression error = buildFieldInitializerError(initializedFields);
    return <Initializer>[
      _helper.buildInvalidInitializer(error, error.fileOffset)
    ];
  }

  @override
  Expression_Generator_Initializer buildSelectorAccess(
      Selector selector, int operatorOffset, bool isNullAware) {
    Name name = selector.name;
    Arguments? arguments = selector.arguments;
    int offset = offsetForToken(selector.token);
    if (isInitializer && selector is InvocationSelector) {
      if (isNullAware) {
        _helper.addProblem(
            messageInvalidUseOfNullAwareAccess, operatorOffset, 2);
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
        return _helper.buildSuperInvocation(
            name, selector.arguments, offsetForToken(selector.token));
      } else {
        return _helper.buildMethodInvocation(
            _forest.createThisExpression(fileOffset),
            name,
            selector.arguments,
            offsetForToken(selector.token));
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
            setter);
      } else {
        return new ThisPropertyAccessGenerator(
            _helper,
            // TODO(ahe): This is not the 'this' token.
            selector.token,
            name,
            thisVariable: null,
            thisOffset: fileOffset,
            isNullAware: isNullAware);
      }
    }
  }

  @override
  Expression_Generator_Initializer doInvocation(
      int offset, List<TypeBuilder>? typeArguments, Arguments arguments,
      {bool isTypeArgumentsInForest = false}) {
    if (isInitializer) {
      return buildConstructorInitializer(offset, new Name(""), arguments);
    } else if (isSuper) {
      return _helper.buildSuperInvocation(Name.callName, arguments, offset,
          isImplicitCall: true);
    } else {
      return _helper.forest.createExpressionInvocation(
          offset, _forest.createThisExpression(fileOffset), arguments);
    }
  }

  @override
  Expression_Generator buildEqualsOperation(Token token, Expression right,
      {required bool isNot}) {
    if (isSuper) {
      int offset = offsetForToken(token);
      Expression result = _helper.buildSuperInvocation(equalsName,
          _forest.createArguments(offset, <Expression>[right]), offset);
      if (isNot) {
        result = _forest.createNot(offset, result);
      }
      return result;
    }
    return super.buildEqualsOperation(token, right, isNot: isNot);
  }

  @override
  Expression_Generator buildBinaryOperation(
      Token token, Name binaryName, Expression right) {
    if (isSuper) {
      int offset = offsetForToken(token);
      return _helper.buildSuperInvocation(binaryName,
          _forest.createArguments(offset, <Expression>[right]), offset);
    }
    return super.buildBinaryOperation(token, binaryName, right);
  }

  @override
  Expression_Generator buildUnaryOperation(Token token, Name unaryName) {
    if (isSuper) {
      int offset = offsetForToken(token);
      return _helper.buildSuperInvocation(
          unaryName, _forest.createArgumentsEmpty(offset), offset);
    }
    return super.buildUnaryOperation(token, unaryName);
  }

  Expression_Initializer buildConstructorInitializer(
      int offset, Name name, Arguments arguments) {
    if (isSuper) {
      Constructor? constructor = _helper.lookupSuperConstructor(name);
      if (constructor == null) {
        String fullName = _helper.superConstructorNameForDiagnostics(name.text);
        LocatedMessage message = templateSuperclassHasNoConstructor
            .withArguments(fullName)
            .withLocation(_uri, fileOffset, lengthForToken(token));
        return _helper.buildInvalidInitializer(
            _helper.buildUnresolvedError(
                _helper.superConstructorNameForDiagnostics(name.text), offset,
                arguments: arguments,
                isSuper: true,
                message: message,
                kind: UnresolvedKind.Constructor),
            offset);
      } else {
        return _helper.buildSuperInitializer(
            false, constructor, arguments, offset);
      }
    } else {
      return _helper.buildRedirectingInitializer(name, arguments,
          fileOffset: offset);
    }
  }

  @override
  Expression buildAssignment(Expression value, {bool voidContext = false}) {
    return buildAssignmentError();
  }

  @override
  Expression buildIfNullAssignment(Expression value, DartType type, int offset,
      {bool voidContext = false}) {
    return buildAssignmentError();
  }

  @override
  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset = TreeNode.noOffset,
      bool voidContext = false,
      bool isPreIncDec = false,
      bool isPostIncDec = false}) {
    return buildAssignmentError();
  }

  @override
  Expression buildPrefixIncrement(Name binaryOperator,
      {int offset = TreeNode.noOffset, bool voidContext = false}) {
    return buildAssignmentError();
  }

  @override
  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset = TreeNode.noOffset, bool voidContext = false}) {
    return buildAssignmentError();
  }

  @override
  Generator buildIndexedAccess(Expression index, Token token,
      {required bool isNullAware}) {
    if (isSuper) {
      return new SuperIndexedAccessGenerator(
          _helper,
          token,
          index,
          _helper.lookupSuperMember(indexGetName) as Procedure?,
          _helper.lookupSuperMember(indexSetName) as Procedure?);
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

class IncompleteErrorGenerator extends ErroneousExpressionGenerator {
  final Message message;

  IncompleteErrorGenerator(
      ExpressionGeneratorHelper helper, Token token, this.message)
      : super(helper, token);

  @override
  String get _plainNameForRead => token.lexeme;

  @override
  String get _debugName => "IncompleteErrorGenerator";

  @override
  Expression buildError(
      {Arguments? arguments,
      Expression? rhs,
      required UnresolvedKind kind,
      String? name,
      int? charOffset,
      int? charLength}) {
    if (charOffset == null) {
      charOffset = fileOffset;
      charLength ??= lengthForToken(token);
    }
    charLength ??= noLength;
    return _helper.buildProblem(message, charOffset, charLength);
  }

  @override
  Generator doInvocation(
          int offset, List<TypeBuilder>? typeArguments, Arguments arguments,
          {bool isTypeArgumentsInForest = false}) =>
      this;

  @override
  Expression buildSimpleRead() {
    return buildError(kind: UnresolvedKind.Member)..fileOffset = fileOffset;
  }

  @override
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
      ExpressionGeneratorHelper helper, Token token, this.expression)
      : super(helper, token, ReadOnlyAccessKind.ParenthesizedExpression);

  @override
  String get targetName => '';

  @override
  Expression buildSimpleRead() => _createRead();

  @override
  Expression _createRead() =>
      _helper.forest.createParenthesized(expression.fileOffset, expression);

  @override
  String get _debugName => "ParenthesizedExpressionGenerator";

  @override
  Expression_Generator buildSelectorAccess(
      Selector selector, int operatorOffset, bool isNullAware) {
    selector.reportNewAsSelector();
    if (selector is InvocationSelector) {
      return _helper.buildMethodInvocation(_createRead(), selector.name,
          selector.arguments, offsetForToken(selector.token),
          isNullAware: isNullAware,
          isConstantExpression: selector.isPotentiallyConstant);
    } else {
      if (_helper.constantContext != ConstantContext.none &&
          selector.name != lengthName) {
        _helper.addProblem(
            messageNotAConstantExpression, fileOffset, token.length);
      }
      return PropertyAccessGenerator.make(
          _helper, selector.token, _createRead(), selector.name, isNullAware);
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
  Expression_Generator withReceiver(Object? receiver, int operatorOffset,
      {bool isNullAware = false});

  List<TypeBuilder>? get typeArguments => null;

  bool get isTypeArgumentsInForest => true;

  Arguments? get arguments => null;

  /// Internal name used for debugging.
  String get _debugName;

  void printOn(StringSink sink);

  /// Report an error if the selector name "new" when the constructor-tearoff
  /// feature is enabled.
  void reportNewAsSelector() {
    if (name.text == 'new' &&
        _helper.libraryFeatures.constructorTearoffs.isEnabled) {
      _helper.addProblem(messageNewAsSelector, fileOffset, name.text.length);
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
  final List<TypeBuilder>? typeArguments;

  @override
  final bool isTypeArgumentsInForest;

  @override
  final Arguments arguments;

  final bool isPotentiallyConstant;

  InvocationSelector(ExpressionGeneratorHelper helper, Token token, this.name,
      this.typeArguments, this.arguments,
      {this.isPotentiallyConstant = false, this.isTypeArgumentsInForest = true})
      : super(helper, token);

  @override
  String get _debugName => 'InvocationSelector';

  @override
  Expression_Generator withReceiver(Object? receiver, int operatorOffset,
      {bool isNullAware = false}) {
    if (receiver is Generator) {
      return receiver.buildSelectorAccess(this, operatorOffset, isNullAware);
    }
    reportNewAsSelector();
    return _helper.buildMethodInvocation(
        _helper.toValue(receiver), name, arguments, fileOffset,
        isNullAware: isNullAware);
  }

  @override
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
  String get _debugName => 'PropertySelector';

  @override
  Expression_Generator withReceiver(Object? receiver, int operatorOffset,
      {bool isNullAware = false}) {
    if (receiver is Generator) {
      return receiver.buildSelectorAccess(this, operatorOffset, isNullAware);
    }
    reportNewAsSelector();
    return PropertyAccessGenerator.make(
        _helper, token, _helper.toValue(receiver), name, isNullAware);
  }

  @override
  void printOn(StringSink sink) {
    sink.write(", name: ");
    sink.write(name.text);
  }
}

class AugmentSuperAccessGenerator extends Generator {
  final AugmentSuperTarget augmentSuperTarget;

  AugmentSuperAccessGenerator(
      ExpressionGeneratorHelper helper, Token token, this.augmentSuperTarget)
      : super(helper, token);

  @override
  String get _debugName => "AugmentSuperGenerator";

  @override
  String get _plainNameForRead {
    return unsupported("augment super.plainNameForRead", fileOffset, _uri);
  }

  Expression _createRead() {
    Member? readTarget = augmentSuperTarget.readTarget;
    if (readTarget != null) {
      return new AugmentSuperGet(readTarget, fileOffset: fileOffset);
    } else {
      return _helper.buildProblem(
          messageNoAugmentSuperReadTarget, fileOffset, noLength);
    }
  }

  @override
  Expression buildAssignment(Expression value, {bool voidContext = false}) {
    return _createWrite(fileOffset, value, forEffect: voidContext);
  }

  Expression _createWrite(int offset, Expression value,
      {required bool forEffect}) {
    Member? writeTarget = augmentSuperTarget.writeTarget;
    if (writeTarget != null) {
      return new AugmentSuperSet(writeTarget, value,
          forEffect: forEffect, fileOffset: fileOffset);
    } else {
      return _helper.buildProblem(
          messageNoAugmentSuperWriteTarget, offset, noLength);
    }
  }

  @override
  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset = TreeNode.noOffset,
      bool voidContext = false,
      bool isPreIncDec = false,
      bool isPostIncDec = false}) {
    // TODO(johnniwinther): Is this ever valid? Augment getters have no access
    // to the augmented setter, augmenting setters have no access to the
    // augmented getters, and augmenting fields only have read access to the
    // augmented field initializer expression.

    Expression binary = _helper.forest
        .createBinary(offset, _createRead(), binaryOperator, value);
    return _createWrite(fileOffset, binary, forEffect: voidContext);
  }

  @override
  Expression buildIfNullAssignment(Expression value, DartType type, int offset,
      {bool voidContext = false}) {
    // TODO(johnniwinther): Is this ever valid? Augment getters have no access
    // to the augmented setter, augmenting setters have no access to the
    // augmented getters, and augmenting fields only have read access to the
    // augmented field initializer expression.
    return new IfNullSet(
        _createRead(), _createWrite(offset, value, forEffect: voidContext),
        forEffect: voidContext)
      ..fileOffset = offset;
  }

  @override
  Generator buildIndexedAccess(Expression index, Token token,
      {required bool isNullAware}) {
    // TODO(johnniwinther): The semantics is unclear. Is this accessing the
    // invoke target, which must be an `operator []` or the read target with a
    // type that has an `operator []`.
    throw new UnimplementedError();
  }

  @override
  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset = TreeNode.noOffset, bool voidContext = false}) {
    // TODO(johnniwinther): Is this ever valid? Augment getters have no access
    // to the augmented setter, augmenting setters have no access to the
    // augmented getters, and augmenting fields only have read access to the
    // augmented field initializer expression.
    Expression value = _forest.createIntLiteral(offset, 1);
    if (voidContext) {
      return buildCompoundAssignment(binaryOperator, value,
          offset: offset, voidContext: voidContext, isPostIncDec: true);
    }
    VariableDeclarationImpl read =
        _helper.createVariableDeclarationForValue(_createRead());
    Expression binary = _helper.forest.createBinary(offset,
        _helper.createVariableGet(read, fileOffset), binaryOperator, value);
    VariableDeclarationImpl write = _helper.createVariableDeclarationForValue(
        _createWrite(fileOffset, binary, forEffect: true));
    return new PropertyPostIncDec.onReadOnly(read, write)..fileOffset = offset;
  }

  @override
  Expression buildSimpleRead() {
    return _createRead();
  }

  @override
  Expression_Generator_Initializer doInvocation(
      int offset, List<TypeBuilder>? typeArguments, ArgumentsImpl arguments,
      {bool isTypeArgumentsInForest = false}) {
    Member? invokeTarget = augmentSuperTarget.invokeTarget;
    if (invokeTarget != null) {
      return new AugmentSuperInvocation(invokeTarget, arguments,
          fileOffset: fileOffset);
    } else {
      return _helper.buildProblem(
          messageNoAugmentSuperInvokeTarget, offset, noLength);
    }
  }

  @override
  void printOn(StringSink sink) {
    sink.write(", augmentSuperTarget: ");
    sink.write(augmentSuperTarget);
  }
}
