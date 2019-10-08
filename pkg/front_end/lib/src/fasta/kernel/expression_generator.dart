// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A library to help generate expression.
library fasta.expression_generator;

import 'dart:core' hide MapEntry;

import 'package:kernel/ast.dart';

import '../../scanner/token.dart' show Token;

import '../constant_context.dart' show ConstantContext;

import '../builder/builder.dart'
    show NullabilityBuilder, PrefixBuilder, TypeDeclarationBuilder;
import '../builder/declaration_builder.dart';
import '../builder/extension_builder.dart';
import '../builder/member_builder.dart';

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

import '../parser.dart' show lengthForToken, lengthOfSpan, offsetForToken;

import '../problems.dart';

import '../scope.dart';

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

import 'kernel_builder.dart'
    show
        AccessErrorBuilder,
        Builder,
        InvalidTypeBuilder,
        LoadLibraryBuilder,
        NamedTypeBuilder,
        TypeBuilder,
        UnlinkedDeclaration,
        UnresolvedType;

import 'kernel_shadow_ast.dart';

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
      Procedure interfaceTarget,
      bool isPreIncDec: false,
      bool isPostIncDec: false});

  /// Returns a [Expression] representing a pre-increment or pre-decrement of
  /// the generator.
  Expression buildPrefixIncrement(Name binaryOperator,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      Procedure interfaceTarget}) {
    return buildCompoundAssignment(
        binaryOperator, _forest.createIntLiteral(offset, 1),
        offset: offset,
        // TODO(johnniwinther): We are missing some void contexts here. For
        // instance `++a?.b;` is not providing a void context making it default
        // `true`.
        voidContext: voidContext,
        interfaceTarget: interfaceTarget,
        isPreIncDec: true);
  }

  /// Returns a [Expression] representing a post-increment or post-decrement of
  /// the generator.
  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      Procedure interfaceTarget});

  /// Returns a [Generator] or [Expression] representing an index access
  /// (e.g. `a[b]`) with the generator on the receiver and [index] as the
  /// index expression.
  Generator buildIndexedAccess(Expression index, Token token);

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

  Initializer buildFieldInitializer(Map<String, int> initializedFields) {
    return _helper.buildInvalidInitializer(
        _helper.buildProblem(
            messageInvalidInitializer, fileOffset, lengthForToken(token)),
        fileOffset);
  }

  /// Returns an expression, generator or initializer for an invocation of this
  /// subexpression with [arguments] at [offset].
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
      int offset, Arguments arguments);

  /* Expression | Generator */ buildPropertyAccess(
      IncompleteSendGenerator send, int operatorOffset, bool isNullAware) {
    if (send is SendAccessGenerator) {
      return _helper.buildMethodInvocation(buildSimpleRead(), send.name,
          send.arguments, offsetForToken(send.token),
          isNullAware: isNullAware);
    } else {
      if (_helper.constantContext != ConstantContext.none &&
          send.name != lengthName) {
        _helper.addProblem(
            messageNotAConstantExpression, fileOffset, token.length);
      }
      return PropertyAccessGenerator.make(_helper, send.token,
          buildSimpleRead(), send.name, null, null, isNullAware);
    }
  }

  /// Returns a [TypeBuilder] for this subexpression instantiated with the
  /// type [arguments]. If no type arguments are provided [arguments] is `null`.
  ///
  /// The type arguments have not been resolved and should be resolved to
  /// create a [TypeBuilder] for a valid type.
  TypeBuilder buildTypeWithResolvedArguments(
      NullabilityBuilder nullabilityBuilder, List<UnresolvedType> arguments) {
    NamedTypeBuilder result =
        new NamedTypeBuilder(token.lexeme, nullabilityBuilder, null);
    Message message = templateNotAType.withArguments(token.lexeme);
    _helper.libraryBuilder
        .addProblem(message, fileOffset, lengthForToken(token), _uri);
    result.bind(result.buildInvalidType(
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
      : super(helper, token);

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
    _helper.typePromoter
        ?.mutateVariable(variable, _helper.functionNestingLevel);
    Expression write;
    if (variable.isFinal || variable.isConst) {
      write = _makeInvalidWrite(value);
    } else {
      write = new VariableSet(variable, value)..fileOffset = offset;
    }
    return write;
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
      Procedure interfaceTarget,
      bool isPreIncDec: false,
      bool isPostIncDec: false}) {
    MethodInvocation binary = _helper.forest.createMethodInvocation(
        offset,
        _createRead(),
        binaryOperator,
        _helper.forest.createArguments(offset, <Expression>[value]),
        interfaceTarget: interfaceTarget);
    return _createWrite(fileOffset, binary);
  }

  @override
  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset = TreeNode.noOffset,
      bool voidContext = false,
      Procedure interfaceTarget}) {
    Expression value = _forest.createIntLiteral(offset, 1);
    if (voidContext) {
      return buildCompoundAssignment(binaryOperator, value,
          offset: offset,
          voidContext: voidContext,
          interfaceTarget: interfaceTarget,
          isPostIncDec: true);
    }
    VariableDeclaration read =
        _helper.forest.createVariableDeclarationForValue(_createRead());
    MethodInvocation binary = _helper.forest.createMethodInvocation(
        offset,
        _helper.createVariableGet(read, fileOffset),
        binaryOperator,
        _helper.forest.createArguments(offset, <Expression>[value]),
        interfaceTarget: interfaceTarget);
    VariableDeclaration write = _helper.forest
        .createVariableDeclarationForValue(_createWrite(offset, binary));
    return new LocalPostIncDec(read, write)..fileOffset = offset;
  }

  @override
  Expression doInvocation(int offset, Arguments arguments) {
    return _helper.buildMethodInvocation(buildSimpleRead(), callName, arguments,
        adjustForImplicitCall(_plainNameForRead, offset),
        isImplicitCall: true);
  }

  @override
  Generator buildIndexedAccess(Expression index, Token token) {
    return new IndexedAccessGenerator(
        _helper, token, buildSimpleRead(), index, null, null);
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

  // TODO(johnniwinther): Remove [getter] and [setter]? These are never
  // passed.
  final Member getter;

  final Member setter;

  PropertyAccessGenerator(ExpressionGeneratorHelper helper, Token token,
      this.receiver, this.name, this.getter, this.setter)
      : super(helper, token);

  @override
  String get _debugName => "PropertyAccessGenerator";

  @override
  String get _plainNameForRead => name.name;

  @override
  Expression doInvocation(int offset, Arguments arguments) {
    return _helper.buildMethodInvocation(receiver, name, arguments, offset);
  }

  @override
  void printOn(StringSink sink) {
    NameSystem syntheticNames = new NameSystem();
    sink.write(", receiver: ");
    printNodeOn(receiver, sink, syntheticNames: syntheticNames);
    sink.write(", name: ");
    sink.write(name.name);
    sink.write(", getter: ");
    printQualifiedNameOn(getter, sink, syntheticNames: syntheticNames);
    sink.write(", setter: ");
    printQualifiedNameOn(setter, sink, syntheticNames: syntheticNames);
  }

  @override
  Expression buildSimpleRead() {
    return new PropertyGet(receiver, name, getter)..fileOffset = fileOffset;
  }

  @override
  Expression buildAssignment(Expression value, {bool voidContext: false}) {
    return _helper.forest.createPropertySet(fileOffset, receiver, name, value,
        interfaceTarget: setter, forEffect: voidContext);
  }

  @override
  Expression buildIfNullAssignment(Expression value, DartType type, int offset,
      {bool voidContext = false}) {
    VariableDeclaration variable =
        _helper.forest.createVariableDeclarationForValue(receiver);
    PropertyGet read = new PropertyGet(
        _helper.createVariableGet(variable, receiver.fileOffset), name)
      ..fileOffset = fileOffset;
    PropertySet write = _helper.forest.createPropertySet(fileOffset,
        _helper.createVariableGet(variable, receiver.fileOffset), name, value,
        forEffect: voidContext);
    return new IfNullPropertySet(variable, read, write, forEffect: voidContext)
      ..fileOffset = offset;
  }

  @override
  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      Procedure interfaceTarget,
      bool isPreIncDec: false,
      bool isPostIncDec: false}) {
    VariableDeclaration variable =
        _helper.forest.createVariableDeclarationForValue(receiver);
    MethodInvocation binary = _helper.forest.createMethodInvocation(
        offset,
        new PropertyGet(
            _helper.createVariableGet(variable, receiver.fileOffset), name)
          ..fileOffset = fileOffset,
        binaryOperator,
        _helper.forest.createArguments(offset, <Expression>[value]),
        interfaceTarget: interfaceTarget);
    PropertySet write = _helper.forest.createPropertySet(fileOffset,
        _helper.createVariableGet(variable, receiver.fileOffset), name, binary,
        forEffect: voidContext);
    return new CompoundPropertySet(variable, write)..fileOffset = offset;
  }

  @override
  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset = TreeNode.noOffset,
      bool voidContext = false,
      Procedure interfaceTarget}) {
    Expression value = _forest.createIntLiteral(offset, 1);
    if (voidContext) {
      return buildCompoundAssignment(binaryOperator, value,
          offset: offset,
          voidContext: voidContext,
          interfaceTarget: interfaceTarget,
          isPostIncDec: true);
    }
    VariableDeclaration variable =
        _helper.forest.createVariableDeclarationForValue(receiver);
    VariableDeclaration read = _helper.forest.createVariableDeclarationForValue(
        new PropertyGet(
            _helper.createVariableGet(variable, receiver.fileOffset), name)
          ..fileOffset = fileOffset);
    MethodInvocation binary = _helper.forest.createMethodInvocation(
        offset,
        _helper.createVariableGet(read, fileOffset),
        binaryOperator,
        _helper.forest.createArguments(offset, <Expression>[value]),
        interfaceTarget: interfaceTarget);
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
  Generator buildIndexedAccess(Expression index, Token token) {
    return new IndexedAccessGenerator(
        _helper, token, buildSimpleRead(), index, null, null);
  }

  /// Creates a [Generator] for the access of property [name] on [receiver].
  static Generator make(
      ExpressionGeneratorHelper helper,
      Token token,
      Expression receiver,
      Name name,
      // TODO(johnniwinther): Remove [getter] and [setter]? These are never
      // passed.
      Member getter,
      Member setter,
      bool isNullAware) {
    if (helper.forest.isThisExpression(receiver)) {
      getter ??= helper.lookupInstanceMember(name);
      setter ??= helper.lookupInstanceMember(name, isSetter: true);
      return new ThisPropertyAccessGenerator(
          helper, token, name, getter, setter);
    } else {
      return isNullAware
          ? new NullAwarePropertyAccessGenerator(
              helper, token, receiver, name, getter, setter, null)
          : new PropertyAccessGenerator(
              helper, token, receiver, name, getter, setter);
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

  /// The member accessed if this subexpression has a read.
  ///
  /// This is `null` if the `this` class does not have a readable property named
  /// [name].
  final Member getter;

  /// The member accessed if this subexpression has a write.
  ///
  /// This is `null` if the `this` class does not have a writable property named
  /// [name].
  final Member setter;

  ThisPropertyAccessGenerator(ExpressionGeneratorHelper helper, Token token,
      this.name, this.getter, this.setter)
      : super(helper, token);

  @override
  String get _debugName => "ThisPropertyAccessGenerator";

  @override
  String get _plainNameForRead => name.name;

  @override
  Expression buildSimpleRead() {
    return _createRead();
  }

  Expression _createRead() {
    return new PropertyGet(
        _forest.createThisExpression(fileOffset), name, getter)
      ..fileOffset = fileOffset;
  }

  @override
  Expression buildAssignment(Expression value, {bool voidContext: false}) {
    return _createWrite(fileOffset, value, forEffect: voidContext);
  }

  Expression _createWrite(int offset, Expression value, {bool forEffect}) {
    return _helper.forest.createPropertySet(
        fileOffset, _forest.createThisExpression(fileOffset), name, value,
        interfaceTarget: setter, forEffect: forEffect);
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
      Procedure interfaceTarget,
      bool isPreIncDec: false,
      bool isPostIncDec: false}) {
    MethodInvocation binary = _helper.forest.createMethodInvocation(
        offset,
        new PropertyGet(_forest.createThisExpression(fileOffset), name)
          ..fileOffset = fileOffset,
        binaryOperator,
        _helper.forest.createArguments(offset, <Expression>[value]),
        interfaceTarget: interfaceTarget);
    return _createWrite(fileOffset, binary, forEffect: voidContext);
  }

  @override
  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset = TreeNode.noOffset,
      bool voidContext = false,
      Procedure interfaceTarget}) {
    Expression value = _forest.createIntLiteral(offset, 1);
    if (voidContext) {
      return buildCompoundAssignment(binaryOperator, value,
          offset: offset,
          voidContext: voidContext,
          interfaceTarget: interfaceTarget,
          isPostIncDec: true);
    }
    VariableDeclaration read = _helper.forest.createVariableDeclarationForValue(
        new PropertyGet(_forest.createThisExpression(fileOffset), name)
          ..fileOffset = fileOffset);
    MethodInvocation binary = _helper.forest.createMethodInvocation(
        offset,
        _helper.createVariableGet(read, fileOffset),
        binaryOperator,
        _helper.forest.createArguments(offset, <Expression>[value]),
        interfaceTarget: interfaceTarget);
    VariableDeclaration write = _helper.forest
        .createVariableDeclarationForValue(
            _createWrite(fileOffset, binary, forEffect: true));
    return new PropertyPostIncDec.onReadOnly(read, write)..fileOffset = offset;
  }

  @override
  Expression doInvocation(int offset, Arguments arguments) {
    Member interfaceTarget = getter;
    if (interfaceTarget is Field) {
      // TODO(ahe): In strong mode we should probably rewrite this to
      // `this.name.call(arguments)`.
      interfaceTarget = null;
    }
    return _helper.buildMethodInvocation(
        _forest.createThisExpression(fileOffset), name, arguments, offset,
        interfaceTarget: interfaceTarget);
  }

  @override
  Generator buildIndexedAccess(Expression index, Token token) {
    return new IndexedAccessGenerator(
        _helper, token, buildSimpleRead(), index, null, null);
  }

  @override
  void printOn(StringSink sink) {
    NameSystem syntheticNames = new NameSystem();
    sink.write(", name: ");
    sink.write(name.name);
    sink.write(", getter: ");
    printQualifiedNameOn(getter, sink, syntheticNames: syntheticNames);
    sink.write(", setter: ");
    printQualifiedNameOn(setter, sink, syntheticNames: syntheticNames);
  }
}

class NullAwarePropertyAccessGenerator extends Generator {
  final VariableDeclaration receiver;

  final Expression receiverExpression;

  final Name name;

  final Member getter;

  final Member setter;

  final DartType type;

  NullAwarePropertyAccessGenerator(
      ExpressionGeneratorHelper helper,
      Token token,
      this.receiverExpression,
      this.name,
      this.getter,
      this.setter,
      this.type)
      : this.receiver = makeOrReuseVariable(receiverExpression),
        super(helper, token);

  @override
  String get _debugName => "NullAwarePropertyAccessGenerator";

  Expression receiverAccess() => new VariableGet(receiver);

  @override
  String get _plainNameForRead => name.name;

  @override
  Expression buildSimpleRead() {
    VariableDeclaration variable =
        _helper.forest.createVariableDeclarationForValue(receiverExpression);
    PropertyGet read = new PropertyGet(
        _helper.createVariableGet(variable, receiverExpression.fileOffset),
        name)
      ..fileOffset = fileOffset;
    return new NullAwarePropertyGet(variable, read)
      ..fileOffset = receiverExpression.fileOffset;
  }

  @override
  Expression buildAssignment(Expression value, {bool voidContext = false}) {
    VariableDeclaration variable =
        _helper.forest.createVariableDeclarationForValue(receiverExpression);
    PropertySet read = _helper.forest.createPropertySet(
        fileOffset,
        _helper.createVariableGet(variable, receiverExpression.fileOffset),
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
      Procedure interfaceTarget,
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
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      Procedure interfaceTarget}) {
    return buildCompoundAssignment(
        binaryOperator, _forest.createIntLiteral(offset, 1),
        offset: offset,
        voidContext: voidContext,
        interfaceTarget: interfaceTarget,
        isPostIncDec: true);
  }

  @override
  Expression doInvocation(int offset, Arguments arguments) {
    return unsupported("doInvocation", offset, _uri);
  }

  @override
  Generator buildIndexedAccess(Expression index, Token token) {
    return new IndexedAccessGenerator(
        _helper, token, buildSimpleRead(), index, null, null);
  }

  @override
  void printOn(StringSink sink) {
    NameSystem syntheticNames = new NameSystem();
    sink.write(", receiver: ");
    printNodeOn(receiver, sink, syntheticNames: syntheticNames);
    sink.write(", receiverExpression: ");
    printNodeOn(receiverExpression, sink, syntheticNames: syntheticNames);
    sink.write(", name: ");
    sink.write(name.name);
    sink.write(", getter: ");
    printQualifiedNameOn(getter, sink, syntheticNames: syntheticNames);
    sink.write(", setter: ");
    printQualifiedNameOn(setter, sink, syntheticNames: syntheticNames);
    sink.write(", type: ");
    printNodeOn(type, sink, syntheticNames: syntheticNames);
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
  String get _plainNameForRead => name.name;

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
      Procedure interfaceTarget,
      bool isPreIncDec = false,
      bool isPostIncDec = false}) {
    MethodInvocation binary = _helper.forest.createMethodInvocation(
        offset,
        _createRead(),
        binaryOperator,
        _helper.forest.createArguments(offset, <Expression>[value]),
        interfaceTarget: interfaceTarget);
    return _createWrite(fileOffset, binary);
  }

  @override
  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset = TreeNode.noOffset,
      bool voidContext = false,
      Procedure interfaceTarget}) {
    Expression value = _forest.createIntLiteral(offset, 1);
    if (voidContext) {
      return buildCompoundAssignment(binaryOperator, value,
          offset: offset,
          voidContext: voidContext,
          interfaceTarget: interfaceTarget,
          isPostIncDec: true);
    }
    VariableDeclaration read =
        _helper.forest.createVariableDeclarationForValue(_createRead());
    MethodInvocation binary = _helper.forest.createMethodInvocation(
        offset,
        _helper.createVariableGet(read, fileOffset),
        binaryOperator,
        _helper.forest.createArguments(offset, <Expression>[value]),
        interfaceTarget: interfaceTarget);
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
  Expression doInvocation(int offset, Arguments arguments) {
    if (_helper.constantContext != ConstantContext.none) {
      // TODO(brianwilkerson) Fix the length
      _helper.addProblem(messageNotAConstantExpression, offset, 1);
    }
    if (getter == null || isFieldOrGetter(getter)) {
      return _helper.buildMethodInvocation(
          buildSimpleRead(), callName, arguments, offset,
          // This isn't a constant expression, but we have checked if a
          // constant expression error should be emitted already.
          isConstantExpression: true,
          isImplicitCall: true);
    } else {
      // TODO(ahe): This could be something like "super.property(...)" where
      // property is a setter.
      return unhandled("${getter.runtimeType}", "doInvocation", offset, _uri);
    }
  }

  @override
  Generator buildIndexedAccess(Expression index, Token token) {
    return new IndexedAccessGenerator(
        _helper, token, buildSimpleRead(), index, null, null);
  }

  @override
  void printOn(StringSink sink) {
    NameSystem syntheticNames = new NameSystem();
    sink.write(", name: ");
    sink.write(name.name);
    sink.write(", getter: ");
    printQualifiedNameOn(getter, sink, syntheticNames: syntheticNames);
    sink.write(", setter: ");
    printQualifiedNameOn(setter, sink, syntheticNames: syntheticNames);
  }
}

class IndexedAccessGenerator extends Generator {
  final Expression receiver;

  final Expression index;

  final Procedure getter;

  final Procedure setter;

  IndexedAccessGenerator(ExpressionGeneratorHelper helper, Token token,
      this.receiver, this.index, this.getter, this.setter)
      : super(helper, token);

  @override
  String get _plainNameForRead => "[]";

  @override
  String get _debugName => "IndexedAccessGenerator";

  @override
  Expression buildSimpleRead() {
    return _helper.buildMethodInvocation(
        receiver,
        indexGetName,
        _helper.forest.createArguments(fileOffset, <Expression>[index]),
        fileOffset,
        interfaceTarget: getter);
  }

  @override
  Expression buildAssignment(Expression value, {bool voidContext: false}) {
    if (voidContext) {
      return _helper.buildMethodInvocation(
          receiver,
          indexSetName,
          _helper.forest
              .createArguments(fileOffset, <Expression>[index, value]),
          fileOffset,
          interfaceTarget: setter);
    } else {
      return new IndexSet(receiver, index, value)..fileOffset = fileOffset;
    }
  }

  @override
  Expression buildIfNullAssignment(Expression value, DartType type, int offset,
      {bool voidContext: false}) {
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
      Procedure interfaceTarget,
      bool isPreIncDec: false,
      bool isPostIncDec: false}) {
    return new CompoundIndexSet(receiver, index, binaryOperator, value,
        readOffset: fileOffset,
        binaryOffset: offset,
        writeOffset: fileOffset,
        forEffect: voidContext,
        forPostIncDec: isPostIncDec);
  }

  @override
  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset = TreeNode.noOffset,
      bool voidContext = false,
      Procedure interfaceTarget}) {
    Expression value = _forest.createIntLiteral(offset, 1);
    return buildCompoundAssignment(binaryOperator, value,
        offset: offset,
        voidContext: voidContext,
        interfaceTarget: interfaceTarget,
        isPostIncDec: true);
  }

  @override
  Expression doInvocation(int offset, Arguments arguments) {
    return _helper.buildMethodInvocation(
        buildSimpleRead(), callName, arguments, arguments.fileOffset,
        isImplicitCall: true);
  }

  @override
  Generator buildIndexedAccess(Expression index, Token token) {
    return new IndexedAccessGenerator(
        _helper, token, buildSimpleRead(), index, null, null);
  }

  @override
  void printOn(StringSink sink) {
    NameSystem syntheticNames = new NameSystem();
    sink.write(", receiver: ");
    printNodeOn(receiver, sink, syntheticNames: syntheticNames);
    sink.write(", index: ");
    printNodeOn(index, sink, syntheticNames: syntheticNames);
    sink.write(", getter: ");
    printQualifiedNameOn(getter, sink, syntheticNames: syntheticNames);
    sink.write(", setter: ");
    printQualifiedNameOn(setter, sink, syntheticNames: syntheticNames);
  }

  static Generator make(
      ExpressionGeneratorHelper helper,
      Token token,
      Expression receiver,
      Expression index,
      Procedure getter,
      Procedure setter) {
    if (helper.forest.isThisExpression(receiver)) {
      return new ThisIndexedAccessGenerator(
          helper, token, index, getter, setter);
    } else {
      return new IndexedAccessGenerator(
          helper, token, receiver, index, getter, setter);
    }
  }
}

/// Special case of [IndexedAccessGenerator] to avoid creating an indirect
/// access to 'this'.
class ThisIndexedAccessGenerator extends Generator {
  final Expression index;

  final Procedure getter;

  final Procedure setter;

  ThisIndexedAccessGenerator(ExpressionGeneratorHelper helper, Token token,
      this.index, this.getter, this.setter)
      : super(helper, token);

  @override
  String get _plainNameForRead => "[]";

  @override
  String get _debugName => "ThisIndexedAccessGenerator";

  @override
  Expression buildSimpleRead() {
    Expression receiver = _helper.forest.createThisExpression(fileOffset);
    return _helper.buildMethodInvocation(
        receiver,
        indexGetName,
        _helper.forest.createArguments(fileOffset, <Expression>[index]),
        fileOffset,
        interfaceTarget: getter);
  }

  @override
  Expression buildAssignment(Expression value, {bool voidContext: false}) {
    Expression receiver = _helper.forest.createThisExpression(fileOffset);
    if (voidContext) {
      return _helper.buildMethodInvocation(
          receiver,
          indexSetName,
          _helper.forest
              .createArguments(fileOffset, <Expression>[index, value]),
          fileOffset,
          interfaceTarget: setter);
    } else {
      return new IndexSet(receiver, index, value)..fileOffset = fileOffset;
    }
  }

  @override
  Expression buildIfNullAssignment(Expression value, DartType type, int offset,
      {bool voidContext: false}) {
    Expression receiver = _helper.forest.createThisExpression(fileOffset);
    return new IfNullIndexSet(receiver, index, value,
        readOffset: fileOffset,
        testOffset: offset,
        writeOffset: fileOffset,
        forEffect: voidContext,
        readOnlyReceiver: true)
      ..fileOffset = offset;
  }

  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      Procedure interfaceTarget,
      bool isPreIncDec: false,
      bool isPostIncDec: false}) {
    Expression receiver = _helper.forest.createThisExpression(fileOffset);
    return new CompoundIndexSet(receiver, index, binaryOperator, value,
        readOffset: fileOffset,
        binaryOffset: offset,
        writeOffset: fileOffset,
        forEffect: voidContext,
        forPostIncDec: isPostIncDec,
        readOnlyReceiver: true);
  }

  @override
  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset = TreeNode.noOffset,
      bool voidContext = false,
      Procedure interfaceTarget}) {
    Expression value = _forest.createIntLiteral(offset, 1);
    return buildCompoundAssignment(binaryOperator, value,
        offset: offset,
        voidContext: voidContext,
        interfaceTarget: interfaceTarget,
        isPostIncDec: true);
  }

  @override
  Expression doInvocation(int offset, Arguments arguments) {
    return _helper.buildMethodInvocation(
        buildSimpleRead(), callName, arguments, offset,
        isImplicitCall: true);
  }

  @override
  Generator buildIndexedAccess(Expression index, Token token) {
    return new IndexedAccessGenerator(
        _helper, token, buildSimpleRead(), index, null, null);
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
      Procedure interfaceTarget,
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
      {int offset = TreeNode.noOffset,
      bool voidContext = false,
      Procedure interfaceTarget}) {
    Expression value = _forest.createIntLiteral(offset, 1);
    return buildCompoundAssignment(binaryOperator, value,
        offset: offset,
        voidContext: voidContext,
        interfaceTarget: interfaceTarget,
        isPostIncDec: true);
  }

  @override
  Expression doInvocation(int offset, Arguments arguments) {
    return _helper.buildMethodInvocation(
        buildSimpleRead(), callName, arguments, offset,
        isImplicitCall: true);
  }

  @override
  Generator buildIndexedAccess(Expression index, Token token) {
    return new IndexedAccessGenerator(
        _helper, token, buildSimpleRead(), index, null, null);
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

  StaticAccessGenerator(ExpressionGeneratorHelper helper, Token token,
      this.targetName, this.readTarget, this.writeTarget)
      : assert(targetName != null),
        assert(readTarget != null || writeTarget != null),
        super(helper, token);

  factory StaticAccessGenerator.fromBuilder(
      ExpressionGeneratorHelper helper,
      String targetName,
      Builder declaration,
      Token token,
      Builder builderSetter) {
    if (declaration is AccessErrorBuilder) {
      AccessErrorBuilder error = declaration;
      declaration = error.builder;
      // We should only see an access error here if we've looked up a setter
      // when not explicitly looking for a setter.
      assert(declaration.isSetter);
    } else if (declaration.target == null) {
      return unhandled(
          "${declaration.runtimeType}",
          "StaticAccessGenerator.fromBuilder",
          offsetForToken(token),
          helper.uri);
    }
    Member getter = declaration.target.hasGetter ? declaration.target : null;
    Member setter = declaration.target.hasSetter ? declaration.target : null;
    if (setter == null) {
      if (builderSetter?.target?.hasSetter ?? false) {
        setter = builderSetter.target;
      }
    }
    return new StaticAccessGenerator(helper, token, targetName, getter, setter);
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
      read = _helper.makeStaticGet(readTarget, token);
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
      Procedure interfaceTarget,
      bool isPreIncDec = false,
      bool isPostIncDec = false}) {
    MethodInvocation binary = _helper.forest.createMethodInvocation(
        offset,
        _createRead(),
        binaryOperator,
        _helper.forest.createArguments(offset, <Expression>[value]),
        interfaceTarget: interfaceTarget);
    return _createWrite(fileOffset, binary);
  }

  @override
  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset = TreeNode.noOffset,
      bool voidContext = false,
      Procedure interfaceTarget}) {
    Expression value = _forest.createIntLiteral(offset, 1);
    if (voidContext) {
      return buildCompoundAssignment(binaryOperator, value,
          offset: offset,
          voidContext: voidContext,
          interfaceTarget: interfaceTarget,
          isPostIncDec: true);
    }
    VariableDeclaration read =
        _helper.forest.createVariableDeclarationForValue(_createRead());
    MethodInvocation binary = _helper.forest.createMethodInvocation(
        offset,
        _helper.createVariableGet(read, fileOffset),
        binaryOperator,
        _helper.forest.createArguments(offset, <Expression>[value]),
        interfaceTarget: interfaceTarget);
    VariableDeclaration write = _helper.forest
        .createVariableDeclarationForValue(_createWrite(offset, binary));
    return new StaticPostIncDec(read, write)..fileOffset = offset;
  }

  @override
  Expression doInvocation(int offset, Arguments arguments) {
    if (_helper.constantContext != ConstantContext.none &&
        !_helper.isIdentical(readTarget)) {
      return _helper.buildProblem(
          templateNotConstantExpression.withArguments('Method invocation'),
          offset,
          readTarget?.name?.name?.length ?? 0);
    }
    if (readTarget == null || isFieldOrGetter(readTarget)) {
      return _helper.buildMethodInvocation(buildSimpleRead(), callName,
          arguments, offset + (readTarget?.name?.name?.length ?? 0),
          // This isn't a constant expression, but we have checked if a
          // constant expression error should be emitted already.
          isConstantExpression: true,
          isImplicitCall: true);
    } else {
      return _helper.buildStaticInvocation(readTarget, arguments,
          charOffset: offset);
    }
  }

  @override
  Generator buildIndexedAccess(Expression index, Token token) {
    return new IndexedAccessGenerator(
        _helper, token, buildSimpleRead(), index, null, null);
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
        assert(readTarget != null || writeTarget != null),
        assert(extensionThis != null),
        super(helper, token);

  factory ExtensionInstanceAccessGenerator.fromBuilder(
      ExpressionGeneratorHelper helper,
      Extension extension,
      String targetName,
      VariableDeclaration extensionThis,
      List<TypeParameter> extensionTypeParameters,
      Builder declaration,
      Token token,
      Builder builderSetter) {
    if (declaration is AccessErrorBuilder) {
      AccessErrorBuilder error = declaration;
      declaration = error.builder;
      // We should only see an access error here if we've looked up a setter
      // when not explicitly looking for a setter.
      assert(declaration.isSetter);
    } else if (declaration.target == null) {
      return unhandled(
          "${declaration.runtimeType}",
          "InstanceExtensionAccessGenerator.fromBuilder",
          offsetForToken(token),
          helper.uri);
    }
    Procedure readTarget;
    Procedure invokeTarget;
    if (declaration.isGetter) {
      readTarget = declaration.target;
    } else if (declaration.isRegularMethod) {
      MemberBuilder procedureBuilder = declaration;
      readTarget = procedureBuilder.extensionTearOff;
      invokeTarget = procedureBuilder.procedure;
    }
    Procedure writeTarget;
    if (builderSetter != null && builderSetter.isSetter) {
      writeTarget = builderSetter.target;
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
        extensionTypeArguments
            .add(_forest.createTypeParameterType(typeParameter));
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
          forEffect: forEffect,
          readOnlyReceiver: true);
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
      Procedure interfaceTarget,
      bool isPreIncDec: false,
      bool isPostIncDec: false}) {
    MethodInvocation binary = _helper.forest.createMethodInvocation(
        offset,
        _createRead(),
        binaryOperator,
        _helper.forest.createArguments(offset, <Expression>[value]),
        interfaceTarget: interfaceTarget);
    return _createWrite(fileOffset, binary, forEffect: voidContext);
  }

  @override
  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset = TreeNode.noOffset,
      bool voidContext = false,
      Procedure interfaceTarget}) {
    Expression value = _forest.createIntLiteral(offset, 1);
    if (voidContext) {
      return buildCompoundAssignment(binaryOperator, value,
          offset: offset,
          voidContext: voidContext,
          interfaceTarget: interfaceTarget,
          isPostIncDec: true);
    }
    VariableDeclaration read =
        _helper.forest.createVariableDeclarationForValue(_createRead());
    MethodInvocation binary = _helper.forest.createMethodInvocation(
        offset,
        _helper.createVariableGet(read, fileOffset),
        binaryOperator,
        _helper.forest.createArguments(offset, <Expression>[value]),
        interfaceTarget: interfaceTarget);
    VariableDeclaration write = _helper.forest
        .createVariableDeclarationForValue(
            _createWrite(fileOffset, binary, forEffect: true));
    return new PropertyPostIncDec.onReadOnly(read, write)..fileOffset = offset;
  }

  @override
  Expression doInvocation(int offset, Arguments arguments) {
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
      return _helper.buildMethodInvocation(buildSimpleRead(), callName,
          arguments, adjustForImplicitCall(_plainNameForRead, offset),
          isImplicitCall: true);
    }
  }

  @override
  Generator buildIndexedAccess(Expression index, Token token) {
    return new IndexedAccessGenerator(
        _helper, token, buildSimpleRead(), index, null, null);
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
  final Extension extension;

  /// The name of the original target;
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
        assert(readTarget != null || writeTarget != null),
        assert(receiver != null),
        assert(isNullAware != null),
        super(helper, token);

  factory ExplicitExtensionInstanceAccessGenerator.fromBuilder(
      ExpressionGeneratorHelper helper,
      Token token,
      Extension extension,
      Builder getterBuilder,
      Builder setterBuilder,
      Expression receiver,
      List<DartType> explicitTypeArguments,
      int extensionTypeParameterCount,
      {bool isNullAware}) {
    assert(getterBuilder != null || setterBuilder != null);
    String targetName;
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
        MemberBuilder memberBuilder = getterBuilder;
        readTarget = memberBuilder.member;
        targetName = memberBuilder.name;
      } else if (getterBuilder.isRegularMethod) {
        MemberBuilder procedureBuilder = getterBuilder;
        readTarget = procedureBuilder.extensionTearOff;
        invokeTarget = procedureBuilder.procedure;
        targetName = procedureBuilder.name;
      } else {
        return unhandled(
            "${getterBuilder.runtimeType}",
            "InstanceExtensionAccessGenerator.fromBuilder",
            offsetForToken(token),
            helper.uri);
      }
    }
    Procedure writeTarget;
    if (setterBuilder != null) {
      assert(!setterBuilder.isStatic);
      if (setterBuilder is AccessErrorBuilder) {
        targetName ??= setterBuilder.name;
      } else if (setterBuilder.isSetter) {
        MemberBuilder memberBuilder = setterBuilder;
        writeTarget = memberBuilder.member;
        targetName ??= memberBuilder.name;
      } else {
        return unhandled(
            "${setterBuilder.runtimeType}",
            "InstanceExtensionAccessGenerator.fromBuilder",
            offsetForToken(token),
            helper.uri);
      }
    }
    return new ExplicitExtensionInstanceAccessGenerator(
        helper,
        token,
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
  String get _plainNameForRead => targetName;

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
      return new NullAwareExtension(variable,
          _createRead(_helper.createVariableGet(variable, variable.fileOffset)))
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
              extensionTypeArguments: _createExtensionTypeArguments()),
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
          _createWrite(fileOffset,
              _helper.createVariableGet(variable, variable.fileOffset), value,
              forEffect: voidContext, readOnlyReceiver: true))
        ..fileOffset = fileOffset;
    } else {
      return _createWrite(fileOffset, receiver, value,
          forEffect: voidContext, readOnlyReceiver: false);
    }
  }

  Expression _createWrite(int offset, Expression receiver, Expression value,
      {bool readOnlyReceiver, bool forEffect}) {
    Expression write;
    if (writeTarget == null) {
      write = _makeInvalidWrite(value);
    } else {
      write = new ExtensionSet(
          extension, explicitTypeArguments, receiver, writeTarget, value,
          readOnlyReceiver: readOnlyReceiver, forEffect: forEffect);
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
      Expression read =
          _createRead(_helper.createVariableGet(variable, receiver.fileOffset));
      Expression write = _createWrite(fileOffset,
          _helper.createVariableGet(variable, receiver.fileOffset), value,
          forEffect: voidContext, readOnlyReceiver: true);
      return new NullAwareExtension(
          variable,
          new IfNullSet(read, write, forEffect: voidContext)
            ..fileOffset = offset)
        ..fileOffset = fileOffset;
    } else {
      VariableDeclaration variable =
          _helper.forest.createVariableDeclarationForValue(receiver);
      Expression read =
          _createRead(_helper.createVariableGet(variable, receiver.fileOffset));
      Expression write = _createWrite(fileOffset,
          _helper.createVariableGet(variable, receiver.fileOffset), value,
          forEffect: voidContext, readOnlyReceiver: true);
      return new IfNullPropertySet(variable, read, write,
          forEffect: voidContext)
        ..fileOffset = offset;
    }
  }

  @override
  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      Procedure interfaceTarget,
      bool isPreIncDec: false,
      bool isPostIncDec: false}) {
    if (isNullAware) {
      VariableDeclaration variable =
          _helper.forest.createVariableDeclarationForValue(receiver);
      MethodInvocation binary = _helper.forest.createMethodInvocation(
          offset,
          _createRead(_helper.createVariableGet(variable, receiver.fileOffset)),
          binaryOperator,
          _helper.forest.createArguments(offset, <Expression>[value]),
          interfaceTarget: interfaceTarget);
      Expression write = _createWrite(fileOffset,
          _helper.createVariableGet(variable, receiver.fileOffset), binary,
          forEffect: voidContext, readOnlyReceiver: true);
      return new NullAwareExtension(variable, write)..fileOffset = offset;
    } else {
      VariableDeclaration variable =
          _helper.forest.createVariableDeclarationForValue(receiver);
      MethodInvocation binary = _helper.forest.createMethodInvocation(
          offset,
          _createRead(_helper.createVariableGet(variable, receiver.fileOffset)),
          binaryOperator,
          _helper.forest.createArguments(offset, <Expression>[value]),
          interfaceTarget: interfaceTarget);
      Expression write = _createWrite(fileOffset,
          _helper.createVariableGet(variable, receiver.fileOffset), binary,
          forEffect: voidContext, readOnlyReceiver: true);
      return new CompoundPropertySet(variable, write)..fileOffset = offset;
    }
  }

  @override
  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset = TreeNode.noOffset,
      bool voidContext = false,
      Procedure interfaceTarget}) {
    Expression value = _forest.createIntLiteral(offset, 1);
    if (voidContext) {
      return buildCompoundAssignment(binaryOperator, value,
          offset: offset,
          voidContext: voidContext,
          interfaceTarget: interfaceTarget,
          isPostIncDec: true);
    } else if (isNullAware) {
      VariableDeclaration variable =
          _helper.forest.createVariableDeclarationForValue(receiver);
      VariableDeclaration read = _helper.forest
          .createVariableDeclarationForValue(_createRead(
              _helper.createVariableGet(variable, receiver.fileOffset)));
      MethodInvocation binary = _helper.forest.createMethodInvocation(
          offset,
          _helper.createVariableGet(read, fileOffset),
          binaryOperator,
          _helper.forest.createArguments(offset, <Expression>[value]),
          interfaceTarget: interfaceTarget);
      VariableDeclaration write = _helper.forest
          .createVariableDeclarationForValue(_createWrite(fileOffset,
              _helper.createVariableGet(variable, receiver.fileOffset), binary,
              forEffect: voidContext, readOnlyReceiver: true)
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
      MethodInvocation binary = _helper.forest.createMethodInvocation(
          offset,
          _helper.createVariableGet(read, fileOffset),
          binaryOperator,
          _helper.forest.createArguments(offset, <Expression>[value]),
          interfaceTarget: interfaceTarget);
      VariableDeclaration write = _helper.forest
          .createVariableDeclarationForValue(_createWrite(fileOffset,
              _helper.createVariableGet(variable, receiver.fileOffset), binary,
              forEffect: voidContext, readOnlyReceiver: true)
            ..fileOffset = fileOffset);
      return new PropertyPostIncDec(variable, read, write)..fileOffset = offset;
    }
  }

  @override
  Expression doInvocation(int offset, Arguments arguments) {
    VariableDeclaration receiverVariable;
    Expression receiverExpression = receiver;
    if (isNullAware) {
      receiverVariable =
          _helper.forest.createVariableDeclarationForValue(receiver);
      receiverExpression = _helper.createVariableGet(
          receiverVariable, receiverVariable.fileOffset);
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
              typeArguments: arguments.types,
              positionalArguments: arguments.positional,
              namedArguments: arguments.named),
          isTearOff: false);
    } else {
      invocation = _helper.buildMethodInvocation(
          _createRead(receiverExpression),
          callName,
          arguments,
          adjustForImplicitCall(_plainNameForRead, offset),
          isImplicitCall: true);
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
  Generator buildIndexedAccess(Expression index, Token token) {
    return new IndexedAccessGenerator(
        _helper, token, buildSimpleRead(), index, null, null);
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

  ExplicitExtensionIndexedAccessGenerator(
      ExpressionGeneratorHelper helper,
      Token token,
      this.extension,
      this.readTarget,
      this.writeTarget,
      this.receiver,
      this.index,
      this.explicitTypeArguments,
      this.extensionTypeParameterCount)
      : assert(readTarget != null || writeTarget != null),
        assert(receiver != null),
        super(helper, token);

  factory ExplicitExtensionIndexedAccessGenerator.fromBuilder(
      ExpressionGeneratorHelper helper,
      Token token,
      Extension extension,
      Builder getterBuilder,
      Builder setterBuilder,
      Expression receiver,
      Expression index,
      List<DartType> explicitTypeArguments,
      int extensionTypeParameterCount) {
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
        extension,
        readTarget,
        writeTarget,
        receiver,
        index,
        explicitTypeArguments,
        extensionTypeParameterCount);
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
    return _helper.buildExtensionMethodInvocation(
        fileOffset,
        readTarget,
        _forest.createArgumentsForExtensionMethod(
            fileOffset, extensionTypeParameterCount, 0, receiver,
            extensionTypeArguments: _createExtensionTypeArguments(),
            positionalArguments: <Expression>[index]),
        isTearOff: false);
  }

  @override
  Expression buildAssignment(Expression value, {bool voidContext: false}) {
    if (writeTarget == null) {
      return _makeInvalidWrite(value);
    }
    if (voidContext) {
      return _helper.buildExtensionMethodInvocation(
          fileOffset,
          writeTarget,
          _forest.createArgumentsForExtensionMethod(
              fileOffset, extensionTypeParameterCount, 0, receiver,
              extensionTypeArguments: _createExtensionTypeArguments(),
              positionalArguments: <Expression>[index, value]),
          isTearOff: false);
    } else {
      return new ExtensionIndexSet(
          extension, explicitTypeArguments, receiver, writeTarget, index, value)
        ..fileOffset = fileOffset;
    }
  }

  @override
  Expression buildIfNullAssignment(Expression value, DartType type, int offset,
      {bool voidContext: false}) {
    return new IfNullExtensionIndexSet(extension, explicitTypeArguments,
        receiver, readTarget, writeTarget, index, value,
        readOffset: fileOffset,
        testOffset: offset,
        writeOffset: fileOffset,
        forEffect: voidContext)
      ..fileOffset = offset;
  }

  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      Procedure interfaceTarget,
      bool isPreIncDec: false,
      bool isPostIncDec: false}) {
    return new CompoundExtensionIndexSet(extension, explicitTypeArguments,
        receiver, readTarget, writeTarget, index, binaryOperator, value,
        readOffset: fileOffset,
        binaryOffset: offset,
        writeOffset: fileOffset,
        forEffect: voidContext,
        forPostIncDec: isPostIncDec);
  }

  @override
  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset = TreeNode.noOffset,
      bool voidContext = false,
      Procedure interfaceTarget}) {
    Expression value = _forest.createIntLiteral(offset, 1);
    return buildCompoundAssignment(binaryOperator, value,
        offset: offset,
        voidContext: voidContext,
        interfaceTarget: interfaceTarget,
        isPostIncDec: true);
  }

  @override
  Expression doInvocation(int offset, Arguments arguments) {
    return _helper.buildMethodInvocation(
        buildSimpleRead(), callName, arguments, offset,
        isImplicitCall: true);
  }

  @override
  Generator buildIndexedAccess(Expression index, Token token) {
    return new IndexedAccessGenerator(
        _helper, token, buildSimpleRead(), index, null, null);
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
      Procedure interfaceTarget,
      bool isPreIncDec: false,
      bool isPostIncDec: false}) {
    return _makeInvalidRead();
  }

  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      Procedure interfaceTarget}) {
    return _makeInvalidRead();
  }

  Generator _createInstanceAccess(Token token, Name name, {bool isNullAware}) {
    Builder getter = extensionBuilder.lookupLocalMember(name.name);
    if (getter != null && getter.isStatic) {
      getter = null;
    }
    Builder setter =
        extensionBuilder.lookupLocalMember(name.name, setter: true);
    if (setter != null && setter.isStatic) {
      setter = null;
    }
    if (getter == null && setter == null) {
      return new UnresolvedNameGenerator(_helper, token, name);
    }
    return new ExplicitExtensionInstanceAccessGenerator.fromBuilder(
        _helper,
        token,
        extensionBuilder.extension,
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
      return generator.doInvocation(offsetForToken(send.token), send.arguments);
    } else {
      return generator;
    }
  }

  @override
  doInvocation(int offset, Arguments arguments) {
    Generator generator =
        _createInstanceAccess(token, callName, isNullAware: false);
    return generator.doInvocation(offset, arguments);
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
  Generator buildIndexedAccess(Expression index, Token token) {
    Builder getter = extensionBuilder.lookupLocalMember(indexGetName.name);
    Builder setter = extensionBuilder.lookupLocalMember(indexSetName.name);
    if (getter == null && setter == null) {
      return new UnresolvedNameGenerator(_helper, token, indexGetName);
    }

    return new ExplicitExtensionIndexedAccessGenerator.fromBuilder(
        _helper,
        token,
        extensionBuilder.extension,
        getter,
        setter,
        receiver,
        index,
        explicitTypeArguments,
        extensionBuilder.typeParameters?.length ?? 0);
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
      Procedure interfaceTarget,
      bool isPreIncDec: false,
      bool isPostIncDec: false}) {
    MethodInvocation binary = _helper.forest.createMethodInvocation(
        offset,
        buildSimpleRead(),
        binaryOperator,
        _helper.forest.createArguments(offset, <Expression>[value]),
        interfaceTarget: interfaceTarget);
    return _makeInvalidWrite(binary);
  }

  @override
  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset = TreeNode.noOffset,
      bool voidContext = false,
      Procedure interfaceTarget}) {
    Expression value = _forest.createIntLiteral(offset, 1);
    return buildCompoundAssignment(binaryOperator, value,
        offset: offset,
        voidContext: voidContext,
        interfaceTarget: interfaceTarget,
        isPostIncDec: true);
  }

  @override
  Expression doInvocation(int offset, Arguments arguments) {
    if (_forest.argumentsPositional(arguments).length > 0 ||
        _forest.argumentsNamed(arguments).length > 0) {
      _helper.addProblemErrorIfConst(
          messageLoadLibraryTakesNoArguments, offset, 'loadLibrary'.length);
    }
    return builder.createLoadLibrary(offset, _forest, arguments);
  }

  @override
  Generator buildIndexedAccess(Expression index, Token token) {
    return new IndexedAccessGenerator(
        _helper, token, buildSimpleRead(), index, null, null);
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
      Procedure interfaceTarget,
      bool isPreIncDec: false,
      bool isPostIncDec: false}) {
    return _helper.wrapInDeferredCheck(
        suffixGenerator.buildCompoundAssignment(binaryOperator, value,
            offset: offset,
            voidContext: voidContext,
            interfaceTarget: interfaceTarget,
            isPreIncDec: isPreIncDec,
            isPostIncDec: isPostIncDec),
        prefixGenerator.prefix,
        token.charOffset);
  }

  @override
  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      Procedure interfaceTarget}) {
    return _helper.wrapInDeferredCheck(
        suffixGenerator.buildPostfixIncrement(binaryOperator,
            offset: offset,
            voidContext: voidContext,
            interfaceTarget: interfaceTarget),
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
    if (type is NamedTypeBuilder && type.declaration is InvalidTypeBuilder) {
      InvalidTypeBuilder declaration = type.declaration;
      message = declaration.message;
    } else {
      int charOffset = offsetForToken(prefixGenerator.token);
      message = templateDeferredTypeAnnotation
          .withArguments(
              _helper.buildDartType(new UnresolvedType(type, charOffset, _uri)),
              prefixGenerator._plainNameForRead)
          .withLocation(
              _uri, charOffset, lengthOfSpan(prefixGenerator.token, token));
    }
    NamedTypeBuilder result =
        new NamedTypeBuilder(name, nullabilityBuilder, null);
    _helper.libraryBuilder.addProblem(
        message.messageObject, message.charOffset, message.length, message.uri);
    result.bind(result.buildInvalidType(message));
    return result;
  }

  @override
  Expression doInvocation(int offset, Arguments arguments) {
    return _helper.wrapInDeferredCheck(
        suffixGenerator.doInvocation(offset, arguments),
        prefixGenerator.prefix,
        token.charOffset);
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
  Generator buildIndexedAccess(Expression index, Token token) {
    return new IndexedAccessGenerator(
        _helper, token, buildSimpleRead(), index, null, null);
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
      : super(helper, token, null, targetName);

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
      argumentBuilders = new List<TypeBuilder>(arguments.length);
      for (int i = 0; i < argumentBuilders.length; i++) {
        argumentBuilders[i] =
            _helper.validateTypeUse(arguments[i], false).builder;
      }
    }
    return new NamedTypeBuilder(
        targetName, nullabilityBuilder, argumentBuilders)
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
      if (declaration is InvalidTypeBuilder) {
        InvalidTypeBuilder declaration = this.declaration;
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
    // `SomeType?.toString` is the same as `SomeType.toString`, not
    // `(SomeType).toString`.
    isNullAware = false;

    Name name = send.name;
    Arguments arguments = send.arguments;

    if (declaration is DeclarationBuilder) {
      DeclarationBuilder declaration = this.declaration;
      Builder member = declaration.findStaticBuilder(
          name.name, offsetForToken(send.token), _uri, _helper.libraryBuilder);

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
              name.name,
              null,
              token.charOffset,
              Constness.implicit);
        }
      } else if (member is AmbiguousBuilder) {
        return _helper.buildProblem(
            member.message, member.charOffset, name.name.length);
      } else {
        Builder setter;
        if (member.isSetter) {
          setter = member;
        } else if (member.isGetter) {
          setter = declaration.findStaticBuilder(
              name.name, fileOffset, _uri, _helper.libraryBuilder,
              isSetter: true);
        } else if (member.isField) {
          if (member.isFinal || member.isConst) {
            setter = declaration.findStaticBuilder(
                name.name, fileOffset, _uri, _helper.libraryBuilder,
                isSetter: true);
          } else {
            setter = member;
          }
        }
        generator = new StaticAccessGenerator.fromBuilder(
            _helper, name.name, member, send.token, setter);
      }

      return arguments == null
          ? generator
          : generator.doInvocation(offsetForToken(send.token), arguments);
    } else {
      return super.buildPropertyAccess(send, operatorOffset, isNullAware);
    }
  }

  @override
  doInvocation(int offset, Arguments arguments) {
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
          arguments, "", null, token.charOffset, Constness.implicit);
    }
  }
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

  VariableDeclaration value;

  ReadOnlyAccessGenerator(ExpressionGeneratorHelper helper, Token token,
      this.expression, this.targetName)
      : super(helper, token);

  @override
  String get _debugName => "ReadOnlyAccessGenerator";

  @override
  String get _plainNameForRead => targetName;

  @override
  Expression buildSimpleRead() => expression;

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
      Procedure interfaceTarget,
      bool isPreIncDec: false,
      bool isPostIncDec: false}) {
    MethodInvocation binary = _helper.forest.createMethodInvocation(
        offset,
        buildSimpleRead(),
        binaryOperator,
        _helper.forest.createArguments(offset, <Expression>[value]),
        interfaceTarget: interfaceTarget);
    return _makeInvalidWrite(binary);
  }

  @override
  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset = TreeNode.noOffset,
      bool voidContext = false,
      Procedure interfaceTarget}) {
    Expression value = _forest.createIntLiteral(offset, 1);
    return buildCompoundAssignment(binaryOperator, value,
        offset: offset,
        voidContext: voidContext,
        interfaceTarget: interfaceTarget,
        isPostIncDec: true);
  }

  @override
  doInvocation(int offset, Arguments arguments) {
    return _helper.buildMethodInvocation(buildSimpleRead(), callName, arguments,
        adjustForImplicitCall(targetName, offset),
        isImplicitCall: true);
  }

  @override
  Generator buildIndexedAccess(Expression index, Token token) {
    // TODO(johnniwinther): The read-only quality of the variable should be
    // passed on to the generator.
    return new IndexedAccessGenerator(
        _helper, token, buildSimpleRead(), index, null, null);
  }

  @override
  void printOn(StringSink sink) {
    NameSystem syntheticNames = new NameSystem();
    sink.write(", expression: ");
    printNodeOn(expression, sink, syntheticNames: syntheticNames);
    sink.write(", plainNameForRead: ");
    sink.write(targetName);
    sink.write(", value: ");
    printNodeOn(value, sink, syntheticNames: syntheticNames);
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
  String get _plainNameForRead => name.name;

  withReceiver(Object receiver, int operatorOffset, {bool isNullAware}) => this;

  @override
  Initializer buildFieldInitializer(Map<String, int> initializedFields) {
    return _helper.buildInvalidInitializer(
        buildError(_forest.createArgumentsEmpty(fileOffset), isSetter: true));
  }

  @override
  doInvocation(int offset, Arguments arguments) {
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
      Procedure interfaceTarget,
      bool isPreIncDec: false,
      bool isPostIncDec: false}) {
    return buildError(_forest.createArguments(fileOffset, <Expression>[value]),
        isGetter: true);
  }

  @override
  Expression buildPrefixIncrement(Name binaryOperator,
      {int offset: -1, bool voidContext: false, Procedure interfaceTarget}) {
    return buildError(
        _forest.createArguments(
            fileOffset, <Expression>[_forest.createIntLiteral(offset, 1)]),
        isGetter: true)
      ..fileOffset = offset;
  }

  @override
  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset: -1, bool voidContext: false, Procedure interfaceTarget}) {
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
  Generator buildIndexedAccess(Expression index, Token token) {
    return new IndexedAccessGenerator(
        _helper, token, buildSimpleRead(), index, null, null);
  }
}

class UnresolvedNameGenerator extends ErroneousExpressionGenerator {
  @override
  final Name name;

  factory UnresolvedNameGenerator(
      ExpressionGeneratorHelper helper, Token token, Name name) {
    if (name.name.isEmpty) {
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
  Expression doInvocation(int charOffset, Arguments arguments) {
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
      Procedure interfaceTarget,
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
    sink.write(name.name);
  }

  Expression _buildUnresolvedVariableAssignment(
      bool isCompound, Expression value) {
    return buildError(_forest.createArguments(fileOffset, <Expression>[value]),
        isSetter: true);
  }

  @override
  Generator buildIndexedAccess(Expression index, Token token) {
    return new IndexedAccessGenerator(
        _helper, token, buildSimpleRead(), index, null, null);
  }
}

class UnlinkedGenerator extends Generator {
  final UnlinkedDeclaration declaration;

  final Expression receiver;

  final Name name;

  UnlinkedGenerator(
      ExpressionGeneratorHelper helper, Token token, this.declaration)
      : name = new Name(declaration.name, helper.libraryBuilder.library),
        receiver = new InvalidExpression(declaration.name)
          ..fileOffset = offsetForToken(token),
        super(helper, token);

  @override
  String get _plainNameForRead => declaration.name;

  @override
  String get _debugName => "UnlinkedGenerator";

  @override
  void printOn(StringSink sink) {
    sink.write(", name: ");
    sink.write(declaration.name);
  }

  @override
  Expression buildAssignment(Expression value, {bool voidContext: false}) {
    return _helper.forest.createPropertySet(fileOffset, receiver, name, value,
        forEffect: voidContext);
  }

  @override
  Expression buildSimpleRead() {
    return new PropertyGet(receiver, name)..fileOffset = fileOffset;
  }

  @override
  Expression buildIfNullAssignment(Expression value, DartType type, int offset,
      {bool voidContext: false}) {
    VariableDeclaration variable =
        _helper.forest.createVariableDeclarationForValue(receiver);
    PropertyGet read = new PropertyGet(
        _helper.createVariableGet(variable, receiver.fileOffset), name)
      ..fileOffset = fileOffset;
    PropertySet write = _helper.forest.createPropertySet(fileOffset,
        _helper.createVariableGet(variable, receiver.fileOffset), name, value,
        forEffect: voidContext);
    return new IfNullPropertySet(variable, read, write, forEffect: voidContext)
      ..fileOffset = offset;
  }

  @override
  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      Procedure interfaceTarget,
      bool isPreIncDec: false,
      bool isPostIncDec: false}) {
    VariableDeclaration variable =
        _helper.forest.createVariableDeclarationForValue(receiver);
    MethodInvocation binary = _helper.forest.createMethodInvocation(
        offset,
        new PropertyGet(
            _helper.createVariableGet(variable, receiver.fileOffset), name)
          ..fileOffset = fileOffset,
        binaryOperator,
        _helper.forest.createArguments(offset, <Expression>[value]),
        interfaceTarget: interfaceTarget);
    PropertySet write = _helper.forest.createPropertySet(fileOffset,
        _helper.createVariableGet(variable, receiver.fileOffset), name, binary,
        forEffect: voidContext);
    return new CompoundPropertySet(variable, write)..fileOffset = offset;
  }

  @override
  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset = TreeNode.noOffset,
      bool voidContext = false,
      Procedure interfaceTarget}) {
    Expression value = _forest.createIntLiteral(offset, 1);
    if (voidContext) {
      return buildCompoundAssignment(binaryOperator, value,
          offset: offset,
          voidContext: voidContext,
          interfaceTarget: interfaceTarget,
          isPostIncDec: true);
    }
    VariableDeclaration variable =
        _helper.forest.createVariableDeclarationForValue(receiver);
    VariableDeclaration read = _helper.forest.createVariableDeclarationForValue(
        new PropertyGet(
            _helper.createVariableGet(variable, receiver.fileOffset), name)
          ..fileOffset = fileOffset);
    MethodInvocation binary = _helper.forest.createMethodInvocation(
        offset,
        _helper.createVariableGet(read, fileOffset),
        binaryOperator,
        _helper.forest.createArguments(offset, <Expression>[value]),
        interfaceTarget: interfaceTarget);
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
  Expression doInvocation(int offset, Arguments arguments) {
    return unsupported("doInvocation", offset, _uri);
  }

  @override
  Generator buildIndexedAccess(Expression index, Token token) {
    return new IndexedAccessGenerator(
        _helper, token, buildSimpleRead(), index, null, null);
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
  Expression doInvocation(int charOffset, Arguments arguments) {
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
      Procedure interfaceTarget,
      bool isPreIncDec: false,
      bool isPostIncDec: false}) {
    return _makeInvalidWrite(value);
  }

  @override
  Expression buildPrefixIncrement(Name binaryOperator,
      {int offset: -1, bool voidContext: false, Procedure interfaceTarget}) {
    return _makeInvalidWrite(null);
  }

  @override
  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset: -1, bool voidContext: false, Procedure interfaceTarget}) {
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
  Generator buildIndexedAccess(Expression index, Token token) {
    return new IndexedAccessGenerator(
        _helper, token, buildSimpleRead(), index, null, null);
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
  Initializer buildFieldInitializer(Map<String, int> initializedFields) {
    if (!identical("=", assignmentOperator) ||
        generator is! ThisPropertyAccessGenerator) {
      return generator.buildFieldInitializer(initializedFields);
    }
    return _helper.buildFieldInitializer(false, generator._plainNameForRead,
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

  final Procedure interfaceTarget;

  DelayedPostfixIncrement(ExpressionGeneratorHelper helper, Token token,
      Generator generator, this.binaryOperator, this.interfaceTarget)
      : super(helper, token, generator);

  @override
  String get _debugName => "DelayedPostfixIncrement";

  @override
  Expression buildSimpleRead() {
    return generator.buildPostfixIncrement(binaryOperator,
        offset: fileOffset,
        voidContext: false,
        interfaceTarget: interfaceTarget);
  }

  @override
  Expression buildForEffect() {
    return generator.buildPostfixIncrement(binaryOperator,
        offset: fileOffset,
        voidContext: true,
        interfaceTarget: interfaceTarget);
  }

  @override
  void printOn(StringSink sink) {
    sink.write(", binaryOperator: ");
    sink.write(binaryOperator.name);
    sink.write(", interfaceTarget: ");
    printQualifiedNameOn(interfaceTarget, sink);
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
      Procedure interfaceTarget,
      bool isPreIncDec: false,
      bool isPostIncDec: false}) {
    return _makeInvalidRead();
  }

  @override
  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      Procedure interfaceTarget}) {
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
      int offset, Arguments arguments) {
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
      assert(send.name.name == send.token.lexeme,
          "'${send.name.name}' != ${send.token.lexeme}");
      Object result = qualifiedLookup(send.token);
      if (send is SendAccessGenerator) {
        result = _helper.finishSend(result, send.arguments, fileOffset);
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
  Generator buildIndexedAccess(Expression index, Token token) {
    return new IndexedAccessGenerator(
        _helper, token, buildSimpleRead(), index, null, null);
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
      Procedure interfaceTarget,
      bool isPreIncDec: false,
      bool isPostIncDec: false}) {
    return _makeInvalidRead();
  }

  @override
  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset = TreeNode.noOffset,
      bool voidContext = false,
      Procedure interfaceTarget}) {
    return _makeInvalidRead();
  }

  @override
  Expression doInvocation(int offset, Arguments arguments) {
    return _helper.throwNoSuchMethodError(_forest.createNullLiteral(offset),
        _plainNameForRead, arguments, fileOffset);
  }

  @override
  TypeBuilder buildTypeWithResolvedArguments(
      NullabilityBuilder nullabilityBuilder, List<UnresolvedType> arguments) {
    Template<Message Function(String, String)> template = isUnresolved
        ? templateUnresolvedPrefixInTypeAnnotation
        : templateNotAPrefixInTypeAnnotation;
    NamedTypeBuilder result =
        new NamedTypeBuilder(_plainNameForRead, nullabilityBuilder, null);
    Message message =
        template.withArguments(prefixGenerator.token.lexeme, token.lexeme);
    _helper.libraryBuilder.addProblem(
        message,
        offsetForToken(prefixGenerator.token),
        lengthOfSpan(prefixGenerator.token, token),
        _uri);
    result.bind(result.buildInvalidType(message.withLocation(
        _uri,
        offsetForToken(prefixGenerator.token),
        lengthOfSpan(prefixGenerator.token, token))));
    return result;
  }

  @override
  Generator buildIndexedAccess(Expression index, Token token) {
    return new IndexedAccessGenerator(
        _helper, token, buildSimpleRead(), index, null, null);
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
      Procedure interfaceTarget,
      bool isPreIncDec: false,
      bool isPostIncDec: false}) {
    return buildProblem();
  }

  Expression buildPrefixIncrement(Name binaryOperator,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      Procedure interfaceTarget}) {
    return buildProblem();
  }

  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      Procedure interfaceTarget}) {
    return buildProblem();
  }

  Expression _makeInvalidRead() => buildProblem();

  Expression _makeInvalidWrite(Expression value) => buildProblem();

  Initializer buildFieldInitializer(Map<String, int> initializedFields) {
    return _helper.buildInvalidInitializer(buildProblem());
  }

  Expression doInvocation(int offset, Arguments arguments) {
    return buildProblem();
  }

  Expression buildPropertyAccess(
      IncompleteSendGenerator send, int operatorOffset, bool isNullAware) {
    return buildProblem();
  }

  TypeBuilder buildTypeWithResolvedArguments(
      NullabilityBuilder nullabilityBuilder, List<UnresolvedType> arguments) {
    NamedTypeBuilder result =
        new NamedTypeBuilder(token.lexeme, nullabilityBuilder, null);
    _helper.libraryBuilder.addProblem(message, fileOffset, noLength, _uri);
    result.bind(result
        .buildInvalidType(message.withLocation(_uri, fileOffset, noLength)));
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
  Generator buildIndexedAccess(Expression index, Token token) {
    return new IndexedAccessGenerator(
        _helper, token, buildSimpleRead(), index, null, null);
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

  /// `true` if this subexpression represents a `super` prefix.
  final bool isSuper;

  ThisAccessGenerator(ExpressionGeneratorHelper helper, Token token,
      this.isInitializer, this.inFieldInitializer,
      {this.isSuper: false})
      : super(helper, token);

  String get _plainNameForRead {
    return unsupported(
        "${isSuper ? 'super' : 'this'}.plainNameForRead", fileOffset, _uri);
  }

  String get _debugName => "ThisAccessGenerator";

  Expression buildSimpleRead() {
    if (!isSuper) {
      if (inFieldInitializer) {
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
  Initializer buildFieldInitializer(Map<String, int> initializedFields) {
    Expression error = buildFieldInitializerError(initializedFields);
    return _helper.buildInvalidInitializer(error, error.fileOffset);
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
    if (inFieldInitializer && !isInitializer) {
      return buildFieldInitializerError(null);
    }
    Member getter = _helper.lookupInstanceMember(name, isSuper: isSuper);
    if (send is SendAccessGenerator) {
      // Notice that 'this' or 'super' can't be null. So we can ignore the
      // value of [isNullAware].
      if (getter == null) {
        _helper.warnUnresolvedMethod(name, offsetForToken(send.token),
            isSuper: isSuper);
      }
      return _helper.buildMethodInvocation(
          _forest.createThisExpression(fileOffset),
          name,
          send.arguments,
          offsetForToken(send.token),
          isSuper: isSuper,
          interfaceTarget: getter);
    } else {
      Member setter =
          _helper.lookupInstanceMember(name, isSuper: isSuper, isSetter: true);
      if (isSuper) {
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
            getter,
            setter);
      }
    }
  }

  doInvocation(int offset, Arguments arguments) {
    if (isInitializer) {
      return buildConstructorInitializer(offset, new Name(""), arguments);
    } else if (isSuper) {
      return _helper.buildProblem(messageSuperAsExpression, offset, noLength);
    } else {
      return _helper.buildMethodInvocation(
          _forest.createThisExpression(fileOffset), callName, arguments, offset,
          isImplicitCall: true);
    }
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
          _helper.constructorNameForDiagnostics(name.name, isSuper: isSuper);
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
              _helper.constructorNameForDiagnostics(name.name,
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
      Procedure interfaceTarget,
      bool isPreIncDec: false,
      bool isPostIncDec: false}) {
    return buildAssignmentError();
  }

  Expression buildPrefixIncrement(Name binaryOperator,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      Procedure interfaceTarget}) {
    return buildAssignmentError();
  }

  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      Procedure interfaceTarget}) {
    return buildAssignmentError();
  }

  @override
  Generator buildIndexedAccess(Expression index, Token token) {
    if (isSuper) {
      return new SuperIndexedAccessGenerator(
          _helper,
          token,
          index,
          _helper.lookupInstanceMember(indexGetName, isSuper: true),
          _helper.lookupInstanceMember(indexSetName, isSuper: true));
    } else {
      return new ThisIndexedAccessGenerator(_helper, token, index, null, null);
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
    sink.write(", isSuper: ");
    sink.write(isSuper);
  }
}

abstract class IncompleteSendGenerator implements Generator {
  Name get name;

  withReceiver(Object receiver, int operatorOffset, {bool isNullAware});

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
  doInvocation(int offset, Arguments arguments) => this;

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
  final Arguments arguments;

  SendAccessGenerator(
      ExpressionGeneratorHelper helper, Token token, this.name, this.arguments)
      : super(helper, token) {
    assert(arguments != null);
  }

  String get _plainNameForRead => name.name;

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
      Procedure interfaceTarget,
      bool isPreIncDec: false,
      bool isPostIncDec: false}) {
    return unsupported("buildCompoundAssignment", offset ?? fileOffset, _uri);
  }

  Expression buildPrefixIncrement(Name binaryOperator,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      Procedure interfaceTarget}) {
    return unsupported("buildPrefixIncrement", offset ?? fileOffset, _uri);
  }

  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      Procedure interfaceTarget}) {
    return unsupported("buildPostfixIncrement", offset ?? fileOffset, _uri);
  }

  Expression doInvocation(int offset, Arguments arguments) {
    return unsupported("doInvocation", offset, _uri);
  }

  @override
  Generator buildIndexedAccess(Expression index, Token token) {
    return unsupported("buildIndexedAccess", offsetForToken(token), _uri);
  }

  @override
  void printOn(StringSink sink) {
    sink.write(", name: ");
    sink.write(name.name);
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

  String get _plainNameForRead => name.name;

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
    return PropertyAccessGenerator.make(_helper, token,
        _helper.toValue(receiver), name, null, null, isNullAware);
  }

  Expression buildIfNullAssignment(Expression value, DartType type, int offset,
      {bool voidContext: false}) {
    return unsupported("buildNullAwareAssignment", offset, _uri);
  }

  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      Procedure interfaceTarget,
      bool isPreIncDec: false,
      bool isPostIncDec: false}) {
    return unsupported("buildCompoundAssignment", offset ?? fileOffset, _uri);
  }

  Expression buildPrefixIncrement(Name binaryOperator,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      Procedure interfaceTarget}) {
    return unsupported("buildPrefixIncrement", offset ?? fileOffset, _uri);
  }

  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      Procedure interfaceTarget}) {
    return unsupported("buildPostfixIncrement", offset ?? fileOffset, _uri);
  }

  Expression doInvocation(int offset, Arguments arguments) {
    return unsupported("doInvocation", offset, _uri);
  }

  @override
  Generator buildIndexedAccess(Expression index, Token token) {
    return unsupported("buildIndexedAccess", offsetForToken(token), _uri);
  }

  @override
  void printOn(StringSink sink) {
    sink.write(", name: ");
    sink.write(name.name);
  }
}

class ParenthesizedExpressionGenerator extends ReadOnlyAccessGenerator {
  ParenthesizedExpressionGenerator(
      ExpressionGeneratorHelper helper, Token token, Expression expression)
      : super(helper, token, expression, null);

  String get _debugName => "ParenthesizedExpressionGenerator";

  Expression _makeInvalidWrite(Expression value) {
    return _helper.buildProblem(messageCannotAssignToParenthesizedExpression,
        fileOffset, lengthForToken(token));
  }
}

Expression makeLet(VariableDeclaration variable, Expression body) {
  if (variable == null) return body;
  return new Let(variable, body);
}

Expression makeBinary(Expression left, Name operator, Procedure interfaceTarget,
    Expression right, ExpressionGeneratorHelper helper,
    {int offset: TreeNode.noOffset}) {
  return new MethodInvocationImpl(left, operator,
      helper.forest.createArguments(offset, <Expression>[right]),
      interfaceTarget: interfaceTarget)
    ..fileOffset = offset;
}

Expression buildIsNull(
    Expression value, int offset, ExpressionGeneratorHelper helper) {
  return makeBinary(
      value, equalsName, null, helper.forest.createNullLiteral(offset), helper,
      offset: offset);
}

VariableDeclaration makeOrReuseVariable(Expression value) {
  // TODO: Devise a way to remember if a variable declaration was reused
  // or is fresh (hence needs a let binding).
  return new VariableDeclaration.forValue(value);
}

int adjustForImplicitCall(String name, int offset) {
  // Normally the offset is at the start of the token, but in this case,
  // because we insert a '.call', we want it at the end instead.
  return offset + (name?.length ?? 0);
}

bool isFieldOrGetter(Member member) {
  return member is Field || (member is Procedure && member.isGetter);
}
