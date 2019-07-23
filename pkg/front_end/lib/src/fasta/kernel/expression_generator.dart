// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A library to help generate expression.
library fasta.expression_generator;

import 'package:kernel/ast.dart'
    show
        Constructor,
        Field,
        InvalidExpression,
        Let,
        Node,
        PropertyGet,
        PropertySet,
        StaticSet,
        SuperMethodInvocation,
        SuperPropertySet,
        TreeNode,
        TypeParameter,
        VariableGet,
        VariableSet;

import '../../scanner/token.dart' show Token;

import '../constant_context.dart' show ConstantContext;

import '../fasta_codes.dart'
    show
        LocatedMessage,
        Message,
        Template,
        messageCannotAssignToSuper,
        messageCannotAssignToParenthesizedExpression,
        messageCantUsePrefixAsExpression,
        messageCantUsePrefixWithNullAware,
        messageIllegalAssignmentToNonAssignable,
        messageInvalidInitializer,
        messageInvalidUseOfNullAwareAccess,
        messageLoadLibraryTakesNoArguments,
        messageNotAConstantExpression,
        messageNotAnLvalue,
        messageSuperAsExpression,
        noLength,
        templateCantUseDeferredPrefixAsConstant,
        templateConstructorNotFound,
        templateDeferredTypeAnnotation,
        templateMissingExplicitTypeArguments,
        templateNotConstantExpression,
        templateNotAPrefixInTypeAnnotation,
        templateNotAType,
        templateSuperclassHasNoConstructor,
        templateThisOrSuperAccessInFieldInitializer,
        templateUnresolvedPrefixInTypeAnnotation;

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

import '../problems.dart' show unhandled, unsupported;

import '../scope.dart';

import 'body_builder.dart' show noLocation;

import 'constness.dart' show Constness;

import 'expression_generator_helper.dart' show ExpressionGeneratorHelper;

import 'forest.dart'
    show
        Forest,
        LoadLibraryBuilder,
        PrefixBuilder,
        TypeDeclarationBuilder,
        UnlinkedDeclaration;

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
        Declaration,
        KernelClassBuilder,
        KernelInvalidTypeBuilder,
        NamedTypeBuilder,
        TypeBuilder,
        UnresolvedType;

import 'kernel_shadow_ast.dart'
    show
        ComplexAssignmentJudgment,
        LoadLibraryTearOffJudgment,
        MethodInvocationJudgment,
        NullAwarePropertyGetJudgment,
        PropertyAssignmentJudgment,
        SuperMethodInvocationJudgment,
        SuperPropertyGetJudgment,
        SyntheticWrapper,
        VariableDeclarationJudgment,
        VariableGetJudgment;

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

  Generator(this._helper, this.token);

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
  /// The read of the this subexpression does _not_ need to support a
  /// simultaneous write of the same subexpression.
  Expression buildSimpleRead() {
    return _finish(_makeSimpleRead(), null);
  }

  /// Internal implementation for [buildSimpleRead].
  ///
  /// The read of the this subexpression does _not_ need to support a
  /// simultaneous write of the same subexpression.
  ///
  /// This is in contrast to [_makeRead] which is used for instance in compound
  /// assignments like `a.b = c` where both a read and a write of the
  /// subexpression `a.b` occurs.
  ///
  /// Subclasses that can benefit from this distinction should override this
  /// method.
  Expression _makeSimpleRead() => _makeRead(null);

  /// Builds a [Expression] representing an assignment with the generator on
  /// the LHS and [value] on the RHS.
  ///
  /// The returned expression evaluates to the assigned value, unless
  /// [voidContext] is true, in which case it may evaluate to anything.
  Expression buildAssignment(Expression value, {bool voidContext: false}) {
    var complexAssignment = startComplexAssignment(value);
    return _finish(_makeSimpleWrite(value, voidContext, complexAssignment),
        complexAssignment);
  }

  /// Internal implementation for [buildAssignment].
  Expression _makeSimpleWrite(Expression value, bool voidContext,
      ComplexAssignmentJudgment complexAssignment) {
    return _makeWrite(value, voidContext, complexAssignment);
  }

  /// Returns a [Expression] representing a null-aware assignment (`??=`) with
  /// the generator on the LHS and [value] on the RHS.
  ///
  /// The returned expression evaluates to the assigned value, unless
  /// [voidContext] is true, in which case it may evaluate to anything.
  ///
  /// [type] is the static type of the RHS.
  Expression buildNullAwareAssignment(
      Expression value, DartType type, int offset,
      {bool voidContext: false}) {
    var complexAssignment = startComplexAssignment(value);
    if (voidContext) {
      var nullAwareCombiner = _forest.conditionalExpression(
          buildIsNull(_makeRead(complexAssignment), offset, _helper),
          null,
          _makeWrite(value, false, complexAssignment),
          null,
          _forest.literalNull(null)..fileOffset = offset)
        ..fileOffset = offset;
      complexAssignment?.nullAwareCombiner = nullAwareCombiner;
      return _finish(nullAwareCombiner, complexAssignment);
    }
    var tmp = new VariableDeclaration.forValue(_makeRead(complexAssignment));
    var nullAwareCombiner = _forest.conditionalExpression(
        buildIsNull(new VariableGet(tmp), offset, _helper),
        null,
        _makeWrite(value, false, complexAssignment),
        null,
        new VariableGet(tmp))
      ..fileOffset = offset;
    complexAssignment?.nullAwareCombiner = nullAwareCombiner;
    return _finish(makeLet(tmp, nullAwareCombiner), complexAssignment);
  }

  /// Returns a [Expression] representing a compound assignment (e.g. `+=`)
  /// with the generator on the LHS and [value] on the RHS.
  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      Procedure interfaceTarget,
      bool isPreIncDec: false,
      bool isPostIncDec: false}) {
    var complexAssignment = startComplexAssignment(value);
    complexAssignment?.isPreIncDec = isPreIncDec;
    complexAssignment?.isPostIncDec = isPostIncDec;
    var combiner = makeBinary(_makeRead(complexAssignment), binaryOperator,
        interfaceTarget, value, _helper,
        offset: offset);
    complexAssignment?.combiner = combiner;
    return _finish(_makeWrite(combiner, voidContext, complexAssignment),
        complexAssignment);
  }

  /// Returns a [Expression] representing a pre-increment or pre-decrement of
  /// the generator.
  Expression buildPrefixIncrement(Name binaryOperator,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      Procedure interfaceTarget}) {
    return buildCompoundAssignment(
        binaryOperator, _forest.literalInt(1, null)..fileOffset = offset,
        offset: offset,
        voidContext: voidContext,
        interfaceTarget: interfaceTarget,
        isPreIncDec: true);
  }

  /// Returns a [Expression] representing a post-increment or post-decrement of
  /// the generator.
  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      Procedure interfaceTarget}) {
    if (voidContext) {
      return buildCompoundAssignment(
          binaryOperator, _forest.literalInt(1, null)..fileOffset = offset,
          offset: offset,
          voidContext: voidContext,
          interfaceTarget: interfaceTarget,
          isPostIncDec: true);
    }
    var rhs = _forest.literalInt(1, null)..fileOffset = offset;
    var complexAssignment = startComplexAssignment(rhs);
    var value = new VariableDeclaration.forValue(_makeRead(complexAssignment));
    valueAccess() => new VariableGet(value);
    var combiner = makeBinary(
        valueAccess(), binaryOperator, interfaceTarget, rhs, _helper,
        offset: offset);
    complexAssignment?.combiner = combiner;
    complexAssignment?.isPostIncDec = true;
    var dummy = new VariableDeclarationJudgment.forValue(
        _makeWrite(combiner, true, complexAssignment),
        _helper.functionNestingLevel);
    return _finish(
        makeLet(value, makeLet(dummy, valueAccess())), complexAssignment);
  }

  /// Returns a [Expression] representing a compile-time error.
  ///
  /// At runtime, an exception will be thrown.
  Expression _makeInvalidRead() {
    return _helper.wrapSyntheticExpression(
        _helper.throwNoSuchMethodError(
            _forest.literalNull(token),
            _plainNameForRead,
            _forest.argumentsEmpty(noLocation),
            offsetForToken(token),
            isGetter: true),
        offsetForToken(token));
  }

  /// Returns a [Expression] representing a compile-time error wrapping
  /// [value].
  ///
  /// At runtime, [value] will be evaluated before throwing an exception.
  Expression _makeInvalidWrite(Expression value) {
    return _helper.wrapSyntheticExpression(
        _helper.throwNoSuchMethodError(
            _forest.literalNull(token),
            _plainNameForRead,
            _forest.arguments(<Expression>[value], noLocation),
            offsetForToken(token),
            isSetter: true),
        offsetForToken(token));
  }

  /// Returns an [Expression] the reads this subexpression.
  ///
  /// The created read expression must support a simultaneous write of the same
  /// expression with valid semantics.
  ///
  /// For instance in `a.b += c`, both a read and a write of the subexpression
  /// `a.b` is created, but `a` must _not_ be evaluated twice. For this reason
  /// [PropertyAccessGenerator] creates a synthetic local variable for `a` and
  /// uses this for the both the [PropertyGet] and [PropertySet] of property
  /// `b`.
  ///
  /// If [complexAssignment] is provided, the created expression is registered
  /// as the `read` of the complex assignment.
  ///
  /// The default implementation creates the expression through
  /// [_makeInvalidRead]. Subclasses with valid read operations must override
  /// this method with a valid implementation.
  Expression _makeRead(ComplexAssignmentJudgment complexAssignment) {
    Expression read = _makeInvalidRead();
    if (complexAssignment != null) {
      read = _helper.desugarSyntheticExpression(read);
      complexAssignment.read = read;
    }
    return read;
  }

  /// Returns an [Expression] the write [value] to this subexpression.
  ///
  /// The created read expression must support a simultaneous read of the same
  /// expression with valid semantics.
  ///
  /// For instance in `a.b += c`, both a read and a write of the subexpression
  /// `a.b` is created, but `a` must _not_ be evaluated twice. For this reason
  /// [PropertyAccessGenerator] creates a synthetic local variable for `a` and
  /// uses this for the both the [PropertyGet] and [PropertySet] of property
  /// `b`.
  ///
  /// If [complexAssignment] is provided, the created expression is registered
  /// as the `write` of the complex assignment.
  ///
  /// The default implementation creates the expression through
  /// [_makeInvalidWrite]. Subclasses with valid write operations must override
  /// this method with a valid implementation.
  Expression _makeWrite(Expression value, bool voidContext,
      ComplexAssignmentJudgment complexAssignment) {
    Expression write = _makeInvalidWrite(value);
    if (complexAssignment != null) {
      write = _helper.desugarSyntheticExpression(write);
      complexAssignment.write = write;
    }
    return write;
  }

  Expression _finish(
      Expression body, ComplexAssignmentJudgment complexAssignment) {
    if (!_helper.legacyMode && complexAssignment != null) {
      complexAssignment.desugared = body;
      return complexAssignment;
    } else {
      return body;
    }
  }

  /// Creates a data structure for tracking the desugaring of a complex
  /// assignment expression whose right hand side is [rhs].
  ComplexAssignmentJudgment startComplexAssignment(Expression rhs) =>
      SyntheticWrapper.wrapIllegalAssignment(rhs);

  Expression buildForEffect() => buildSimpleRead();

  Initializer buildFieldInitializer(Map<String, int> initializedFields) {
    int offset = offsetForToken(token);
    return _helper.buildInvalidInitializer(
        _helper.desugarSyntheticExpression(_helper.buildProblem(
            messageInvalidInitializer, offset, lengthForToken(token))),
        offset);
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
            messageNotAConstantExpression, offsetForToken(token), token.length);
      }
      return PropertyAccessGenerator.make(_helper, send.token,
          buildSimpleRead(), send.name, null, null, isNullAware);
    }
  }

  TypeBuilder buildTypeWithResolvedArguments(
      List<UnresolvedType<TypeBuilder>> arguments) {
    NamedTypeBuilder result = new NamedTypeBuilder(token.lexeme, null);
    Message message = templateNotAType.withArguments(token.lexeme);
    _helper.library.addProblem(
        message, offsetForToken(token), lengthForToken(token), _uri);
    result.bind(result.buildInvalidType(message.withLocation(
        _uri, offsetForToken(token), lengthForToken(token))));
    return result;
  }

  /* Expression | Generator */ Object qualifiedLookup(Token name) {
    return new UnexpectedQualifiedUseGenerator(_helper, name, this, false);
  }

  Expression invokeConstructor(
      List<UnresolvedType<TypeBuilder>> typeArguments,
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
    return _helper.wrapInvalidConstructorInvocation(
        _helper.throwNoSuchMethodError(
            _forest.literalNull(token),
            _helper.constructorNameForDiagnostics(name,
                className: _plainNameForRead),
            arguments,
            nameToken.charOffset),
        null,
        arguments,
        offsetForToken(token));
  }

  void printOn(StringSink sink);

  String toString() {
    StringBuffer buffer = new StringBuffer();
    buffer.write(_debugName);
    buffer.write("(offset: ");
    buffer.write("${offsetForToken(token)}");
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
  Expression _makeRead(ComplexAssignmentJudgment complexAssignment) {
    var fact = _helper.typePromoter
        ?.getFactForAccess(variable, _helper.functionNestingLevel);
    var scope = _helper.typePromoter?.currentScope;
    var read = new VariableGetJudgment(variable, fact, scope)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.read = read;
    return read;
  }

  @override
  Expression _makeWrite(Expression value, bool voidContext,
      ComplexAssignmentJudgment complexAssignment) {
    _helper.typePromoter
        ?.mutateVariable(variable, _helper.functionNestingLevel);
    Expression write;
    if (variable.isFinal || variable.isConst) {
      write = _makeInvalidWrite(value);
      if (complexAssignment != null) {
        write = _helper.desugarSyntheticExpression(write);
        complexAssignment.write = write;
      }
    } else {
      write = new VariableSet(variable, value)
        ..fileOffset = offsetForToken(token);
      complexAssignment?.write = write;
    }
    return write;
  }

  @override
  Expression doInvocation(int offset, Arguments arguments) {
    return _helper.buildMethodInvocation(buildSimpleRead(), callName, arguments,
        adjustForImplicitCall(_plainNameForRead, offset),
        isImplicitCall: true);
  }

  @override
  ComplexAssignmentJudgment startComplexAssignment(Expression rhs) {
    return SyntheticWrapper.wrapVariableAssignment(rhs)
      ..fileOffset = offsetForToken(token);
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

  /// Synthetic variable created for [receiver] if need.
  VariableDeclaration _receiverVariable;

  PropertyAccessGenerator(ExpressionGeneratorHelper helper, Token token,
      this.receiver, this.name, this.getter, this.setter)
      : super(helper, token);

  @override
  String get _debugName => "PropertyAccessGenerator";

  @override
  String get _plainNameForRead => name.name;

  receiverAccess() {
    _receiverVariable ??= new VariableDeclaration.forValue(receiver);
    return new VariableGet(_receiverVariable)
      ..fileOffset = offsetForToken(token);
  }

  @override
  Expression doInvocation(int offset, Arguments arguments) {
    return _helper.buildMethodInvocation(receiver, name, arguments, offset);
  }

  @override
  ComplexAssignmentJudgment startComplexAssignment(Expression rhs) =>
      SyntheticWrapper.wrapPropertyAssignment(receiver, rhs);

  @override
  void printOn(StringSink sink) {
    NameSystem syntheticNames = new NameSystem();
    sink.write(", _receiverVariable: ");
    printNodeOn(_receiverVariable, sink, syntheticNames: syntheticNames);
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
  Expression _makeSimpleRead() {
    return new PropertyGet(receiver, name, getter)
      ..fileOffset = offsetForToken(token);
  }

  @override
  Expression _makeSimpleWrite(Expression value, bool voidContext,
      ComplexAssignmentJudgment complexAssignment) {
    var write = new PropertySet(receiver, name, value, setter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.write = write;
    return write;
  }

  @override
  Expression _makeRead(ComplexAssignmentJudgment complexAssignment) {
    var read = new PropertyGet(receiverAccess(), name, getter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.read = read;
    return read;
  }

  @override
  Expression _makeWrite(Expression value, bool voidContext,
      ComplexAssignmentJudgment complexAssignment) {
    var write = new PropertySet(receiverAccess(), name, value, setter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.write = write;
    return write;
  }

  @override
  Expression _finish(
      Expression body, ComplexAssignmentJudgment complexAssignment) {
    return super._finish(makeLet(_receiverVariable, body), complexAssignment);
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
  Expression _makeRead(ComplexAssignmentJudgment complexAssignment) {
    if (getter == null) {
      _helper.warnUnresolvedGet(name, offsetForToken(token));
    }
    var read = new PropertyGet(_forest.thisExpression(token), name, getter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.read = read;
    return read;
  }

  @override
  Expression _makeWrite(Expression value, bool voidContext,
      ComplexAssignmentJudgment complexAssignment) {
    if (setter == null) {
      _helper.warnUnresolvedSet(name, offsetForToken(token));
    }
    var write =
        new PropertySet(_forest.thisExpression(token), name, value, setter)
          ..fileOffset = offsetForToken(token);
    complexAssignment?.write = write;
    return write;
  }

  @override
  Expression doInvocation(int offset, Arguments arguments) {
    Member interfaceTarget = getter;
    if (interfaceTarget == null) {
      _helper.warnUnresolvedMethod(name, offset);
    }
    if (interfaceTarget is Field) {
      // TODO(ahe): In strong mode we should probably rewrite this to
      // `this.name.call(arguments)`.
      interfaceTarget = null;
    }
    return _helper.buildMethodInvocation(
        _forest.thisExpression(null), name, arguments, offset,
        interfaceTarget: interfaceTarget);
  }

  @override
  ComplexAssignmentJudgment startComplexAssignment(Expression rhs) =>
      SyntheticWrapper.wrapPropertyAssignment(null, rhs);

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
  Expression _makeRead(ComplexAssignmentJudgment complexAssignment) {
    var read = new PropertyGet(receiverAccess(), name, getter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.read = read;
    return read;
  }

  @override
  Expression _makeWrite(Expression value, bool voidContext,
      ComplexAssignmentJudgment complexAssignment) {
    var write = new PropertySet(receiverAccess(), name, value, setter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.write = write;
    return write;
  }

  @override
  Expression _finish(
      Expression body, ComplexAssignmentJudgment complexAssignment) {
    var offset = offsetForToken(token);
    var nullAwareGuard = _forest.conditionalExpression(
        buildIsNull(receiverAccess(), offset, _helper),
        null,
        _forest.literalNull(null)..fileOffset = offset,
        null,
        body)
      ..fileOffset = offset;
    if (complexAssignment != null) {
      body = makeLet(receiver, nullAwareGuard);
      if (_helper.legacyMode) return body;
      PropertyAssignmentJudgment kernelPropertyAssign = complexAssignment;
      kernelPropertyAssign.nullAwareGuard = nullAwareGuard;
      kernelPropertyAssign.desugared = body;
      return kernelPropertyAssign;
    } else {
      return new NullAwarePropertyGetJudgment(receiver, nullAwareGuard)
        ..fileOffset = offset;
    }
  }

  @override
  Expression doInvocation(int offset, Arguments arguments) {
    return unsupported("doInvocation", offset, _uri);
  }

  @override
  ComplexAssignmentJudgment startComplexAssignment(Expression rhs) =>
      SyntheticWrapper.wrapPropertyAssignment(receiverExpression, rhs);

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
  Expression _makeRead(ComplexAssignmentJudgment complexAssignment) {
    if (getter == null) {
      _helper.warnUnresolvedGet(name, offsetForToken(token), isSuper: true);
    }
    // TODO(ahe): Use [DirectPropertyGet] when possible.
    var read = new SuperPropertyGetJudgment(name, interfaceTarget: getter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.read = read;
    return read;
  }

  @override
  Expression _makeWrite(Expression value, bool voidContext,
      ComplexAssignmentJudgment complexAssignment) {
    if (setter == null) {
      _helper.warnUnresolvedSet(name, offsetForToken(token), isSuper: true);
    }
    // TODO(ahe): Use [DirectPropertySet] when possible.
    var write = new SuperPropertySet(name, value, setter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.write = write;
    return write;
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
  ComplexAssignmentJudgment startComplexAssignment(Expression rhs) =>
      SyntheticWrapper.wrapPropertyAssignment(null, rhs, isSuper: true);

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

  VariableDeclaration receiverVariable;

  VariableDeclaration indexVariable;

  IndexedAccessGenerator(ExpressionGeneratorHelper helper, Token token,
      this.receiver, this.index, this.getter, this.setter)
      : super(helper, token);

  @override
  String get _plainNameForRead => "[]";

  @override
  String get _debugName => "IndexedAccessGenerator";

  Expression indexAccess() {
    indexVariable ??= new VariableDeclaration.forValue(index);
    return new VariableGet(indexVariable)..fileOffset = offsetForToken(token);
  }

  Expression receiverAccess() {
    // We cannot reuse the receiver if it is a variable since it might be
    // reassigned in the index expression.
    receiverVariable ??= new VariableDeclaration.forValue(receiver);
    return new VariableGet(receiverVariable)
      ..fileOffset = offsetForToken(token);
  }

  @override
  Expression _makeSimpleRead() {
    var read = new MethodInvocationJudgment(receiver, indexGetName,
        _forest.castArguments(_forest.arguments(<Expression>[index], token)),
        interfaceTarget: getter)
      ..fileOffset = offsetForToken(token);
    return read;
  }

  @override
  Expression _makeSimpleWrite(Expression value, bool voidContext,
      ComplexAssignmentJudgment complexAssignment) {
    if (!voidContext) return _makeWriteAndReturn(value, complexAssignment);
    var write = new MethodInvocationJudgment(
        receiver,
        indexSetName,
        _forest.castArguments(
            _forest.arguments(<Expression>[index, value], token)),
        interfaceTarget: setter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.write = write;
    return write;
  }

  @override
  Expression _makeRead(ComplexAssignmentJudgment complexAssignment) {
    var read = new MethodInvocationJudgment(
        receiverAccess(),
        indexGetName,
        _forest.castArguments(
            _forest.arguments(<Expression>[indexAccess()], token)),
        interfaceTarget: getter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.read = read;
    return read;
  }

  @override
  Expression _makeWrite(Expression value, bool voidContext,
      ComplexAssignmentJudgment complexAssignment) {
    if (!voidContext) return _makeWriteAndReturn(value, complexAssignment);
    var write = new MethodInvocationJudgment(
        receiverAccess(),
        indexSetName,
        _forest.castArguments(
            _forest.arguments(<Expression>[indexAccess(), value], token)),
        interfaceTarget: setter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.write = write;
    return write;
  }

  // TODO(dmitryas): remove this method after the "[]=" operator of the Context
  // class is made to return a value.
  Expression _makeWriteAndReturn(
      Expression value, ComplexAssignmentJudgment complexAssignment) {
    // The call to []= does not return the value like direct-style assignments
    // do.  We need to bind the value in a let.
    var valueVariable = new VariableDeclaration.forValue(value);
    var write = new MethodInvocationJudgment(
        receiverAccess(),
        indexSetName,
        _forest.castArguments(_forest.arguments(
            <Expression>[indexAccess(), new VariableGet(valueVariable)],
            token)),
        interfaceTarget: setter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.write = write;
    var dummy = new VariableDeclarationJudgment.forValue(
        write, _helper.functionNestingLevel);
    return makeLet(
        valueVariable, makeLet(dummy, new VariableGet(valueVariable)));
  }

  @override
  Expression _finish(
      Expression body, ComplexAssignmentJudgment complexAssignment) {
    int offset = offsetForToken(token);
    return super._finish(
        makeLet(
            receiverVariable, makeLet(indexVariable, body)..fileOffset = offset)
          ..fileOffset = offset,
        complexAssignment);
  }

  @override
  Expression doInvocation(int offset, Arguments arguments) {
    return _helper.buildMethodInvocation(
        buildSimpleRead(), callName, arguments, _forest.readOffset(arguments),
        isImplicitCall: true);
  }

  @override
  ComplexAssignmentJudgment startComplexAssignment(Expression rhs) =>
      SyntheticWrapper.wrapIndexAssignment(receiver, index, rhs);

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
    sink.write(", receiverVariable: ");
    printNodeOn(receiverVariable, sink, syntheticNames: syntheticNames);
    sink.write(", indexVariable: ");
    printNodeOn(indexVariable, sink, syntheticNames: syntheticNames);
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

  VariableDeclaration indexVariable;

  ThisIndexedAccessGenerator(ExpressionGeneratorHelper helper, Token token,
      this.index, this.getter, this.setter)
      : super(helper, token);

  @override
  String get _plainNameForRead => "[]";

  @override
  String get _debugName => "ThisIndexedAccessGenerator";

  Expression indexAccess() {
    indexVariable ??= new VariableDeclaration.forValue(index);
    return new VariableGet(indexVariable);
  }

  Expression _makeWriteAndReturn(
      Expression value, ComplexAssignmentJudgment complexAssignment) {
    var valueVariable = new VariableDeclaration.forValue(value);
    var write = new MethodInvocationJudgment(
        _forest.thisExpression(token),
        indexSetName,
        _forest.castArguments(_forest.arguments(
            <Expression>[indexAccess(), new VariableGet(valueVariable)],
            token)),
        interfaceTarget: setter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.write = write;
    var dummy = new VariableDeclaration.forValue(write);
    return makeLet(
        valueVariable, makeLet(dummy, new VariableGet(valueVariable)));
  }

  @override
  Expression _makeSimpleRead() {
    return new MethodInvocationJudgment(
        _forest.thisExpression(token),
        indexGetName,
        _forest.castArguments(_forest.arguments(<Expression>[index], token)),
        interfaceTarget: getter)
      ..fileOffset = offsetForToken(token);
  }

  @override
  Expression _makeSimpleWrite(Expression value, bool voidContext,
      ComplexAssignmentJudgment complexAssignment) {
    if (!voidContext) return _makeWriteAndReturn(value, complexAssignment);
    var write = new MethodInvocationJudgment(
        _forest.thisExpression(token),
        indexSetName,
        _forest.castArguments(
            _forest.arguments(<Expression>[index, value], token)),
        interfaceTarget: setter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.write = write;
    return write;
  }

  @override
  Expression _makeRead(ComplexAssignmentJudgment complexAssignment) {
    var read = new MethodInvocationJudgment(
        _forest.thisExpression(token),
        indexGetName,
        _forest.castArguments(
            _forest.arguments(<Expression>[indexAccess()], token)),
        interfaceTarget: getter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.read = read;
    return read;
  }

  @override
  Expression _makeWrite(Expression value, bool voidContext,
      ComplexAssignmentJudgment complexAssignment) {
    if (!voidContext) return _makeWriteAndReturn(value, complexAssignment);
    var write = new MethodInvocationJudgment(
        _forest.thisExpression(token),
        indexSetName,
        _forest.castArguments(
            _forest.arguments(<Expression>[indexAccess(), value], token)),
        interfaceTarget: setter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.write = write;
    return write;
  }

  @override
  Expression _finish(
      Expression body, ComplexAssignmentJudgment complexAssignment) {
    return super._finish(makeLet(indexVariable, body), complexAssignment);
  }

  @override
  Expression doInvocation(int offset, Arguments arguments) {
    return _helper.buildMethodInvocation(
        buildSimpleRead(), callName, arguments, offset,
        isImplicitCall: true);
  }

  @override
  ComplexAssignmentJudgment startComplexAssignment(Expression rhs) =>
      SyntheticWrapper.wrapIndexAssignment(null, index, rhs);

  @override
  void printOn(StringSink sink) {
    NameSystem syntheticNames = new NameSystem();
    sink.write(", index: ");
    printNodeOn(index, sink, syntheticNames: syntheticNames);
    sink.write(", getter: ");
    printQualifiedNameOn(getter, sink, syntheticNames: syntheticNames);
    sink.write(", setter: ");
    printQualifiedNameOn(setter, sink, syntheticNames: syntheticNames);
    sink.write(", indexVariable: ");
    printNodeOn(indexVariable, sink, syntheticNames: syntheticNames);
  }
}

class SuperIndexedAccessGenerator extends Generator {
  final Expression index;

  final Member getter;

  final Member setter;

  VariableDeclaration indexVariable;

  SuperIndexedAccessGenerator(ExpressionGeneratorHelper helper, Token token,
      this.index, this.getter, this.setter)
      : super(helper, token);

  String get _plainNameForRead => "[]";

  String get _debugName => "SuperIndexedAccessGenerator";

  Expression indexAccess() {
    indexVariable ??= new VariableDeclaration.forValue(index);
    return new VariableGet(indexVariable);
  }

  Expression _makeWriteAndReturn(
      Expression value, ComplexAssignmentJudgment complexAssignment) {
    var valueVariable = new VariableDeclaration.forValue(value);
    if (setter == null) {
      _helper.warnUnresolvedMethod(indexSetName, offsetForToken(token),
          isSuper: true);
    }
    var write = new SuperMethodInvocation(
        indexSetName,
        _forest.castArguments(_forest.arguments(
            <Expression>[indexAccess(), new VariableGet(valueVariable)],
            token)),
        setter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.write = write;
    var dummy = new VariableDeclaration.forValue(write);
    return makeLet(
        valueVariable, makeLet(dummy, new VariableGet(valueVariable)));
  }

  @override
  Expression _makeSimpleRead() {
    if (getter == null) {
      _helper.warnUnresolvedMethod(indexGetName, offsetForToken(token),
          isSuper: true);
    }
    // TODO(ahe): Use [DirectMethodInvocation] when possible.
    return new SuperMethodInvocationJudgment(indexGetName,
        _forest.castArguments(_forest.arguments(<Expression>[index], token)),
        interfaceTarget: getter)
      ..fileOffset = offsetForToken(token);
  }

  @override
  Expression _makeSimpleWrite(Expression value, bool voidContext,
      ComplexAssignmentJudgment complexAssignment) {
    if (!voidContext) return _makeWriteAndReturn(value, complexAssignment);
    if (setter == null) {
      _helper.warnUnresolvedMethod(indexSetName, offsetForToken(token),
          isSuper: true);
    }
    var write = new SuperMethodInvocation(
        indexSetName,
        _forest.castArguments(
            _forest.arguments(<Expression>[index, value], token)),
        setter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.write = write;
    return write;
  }

  @override
  Expression _makeRead(ComplexAssignmentJudgment complexAssignment) {
    if (getter == null) {
      _helper.warnUnresolvedMethod(indexGetName, offsetForToken(token),
          isSuper: true);
    }
    var read = new SuperMethodInvocation(
        indexGetName,
        _forest.castArguments(
            _forest.arguments(<Expression>[indexAccess()], token)),
        getter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.read = read;
    return read;
  }

  @override
  Expression _makeWrite(Expression value, bool voidContext,
      ComplexAssignmentJudgment complexAssignment) {
    if (!voidContext) return _makeWriteAndReturn(value, complexAssignment);
    if (setter == null) {
      _helper.warnUnresolvedMethod(indexSetName, offsetForToken(token),
          isSuper: true);
    }
    var write = new SuperMethodInvocation(
        indexSetName,
        _forest.castArguments(
            _forest.arguments(<Expression>[indexAccess(), value], token)),
        setter)
      ..fileOffset = offsetForToken(token);
    complexAssignment?.write = write;
    return write;
  }

  @override
  Expression _finish(
      Expression body, ComplexAssignmentJudgment complexAssignment) {
    return super._finish(
        makeLet(indexVariable, body)..fileOffset = offsetForToken(token),
        complexAssignment);
  }

  @override
  Expression doInvocation(int offset, Arguments arguments) {
    return _helper.buildMethodInvocation(
        buildSimpleRead(), callName, arguments, offset,
        isImplicitCall: true);
  }

  @override
  ComplexAssignmentJudgment startComplexAssignment(Expression rhs) =>
      SyntheticWrapper.wrapIndexAssignment(null, index, rhs, isSuper: true);

  @override
  void printOn(StringSink sink) {
    NameSystem syntheticNames = new NameSystem();
    sink.write(", index: ");
    printNodeOn(index, sink, syntheticNames: syntheticNames);
    sink.write(", getter: ");
    printQualifiedNameOn(getter, sink, syntheticNames: syntheticNames);
    sink.write(", setter: ");
    printQualifiedNameOn(setter, sink, syntheticNames: syntheticNames);
    sink.write(", indexVariable: ");
    printNodeOn(indexVariable, sink, syntheticNames: syntheticNames);
  }
}

class StaticAccessGenerator extends Generator {
  final Member readTarget;

  final Member writeTarget;

  StaticAccessGenerator(ExpressionGeneratorHelper helper, Token token,
      this.readTarget, this.writeTarget)
      : assert(readTarget != null || writeTarget != null),
        super(helper, token);

  factory StaticAccessGenerator.fromBuilder(ExpressionGeneratorHelper helper,
      Declaration declaration, Token token, Declaration builderSetter) {
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
    return new StaticAccessGenerator(helper, token, getter, setter);
  }

  @override
  String get _debugName => "StaticAccessGenerator";

  @override
  String get _plainNameForRead => (readTarget ?? writeTarget).name.name;

  @override
  Expression _makeRead(ComplexAssignmentJudgment complexAssignment) {
    Expression read;
    if (readTarget == null) {
      read = _makeInvalidRead();
      if (complexAssignment != null) {
        read = _helper.desugarSyntheticExpression(read);
      }
    } else {
      read = _helper.makeStaticGet(readTarget, token);
    }
    complexAssignment?.read = read;
    return read;
  }

  @override
  Expression _makeWrite(Expression value, bool voidContext,
      ComplexAssignmentJudgment complexAssignment) {
    Expression write;
    if (writeTarget == null) {
      write = _makeInvalidWrite(value);
      if (complexAssignment != null) {
        write = _helper.desugarSyntheticExpression(write);
      }
    } else {
      write = new StaticSet(writeTarget, value);
    }
    complexAssignment?.write = write;
    write.fileOffset = offsetForToken(token);
    return write;
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
  ComplexAssignmentJudgment startComplexAssignment(Expression rhs) =>
      SyntheticWrapper.wrapStaticAssignment(rhs);

  @override
  void printOn(StringSink sink) {
    NameSystem syntheticNames = new NameSystem();
    sink.write(", readTarget: ");
    printQualifiedNameOn(readTarget, sink, syntheticNames: syntheticNames);
    sink.write(", writeTarget: ");
    printQualifiedNameOn(writeTarget, sink, syntheticNames: syntheticNames);
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
  Expression _makeRead(ComplexAssignmentJudgment complexAssignment) {
    builder.importDependency.targetLibrary;
    var read = new LoadLibraryTearOffJudgment(
        builder.importDependency, builder.createTearoffMethod(_helper.forest))
      ..fileOffset = offsetForToken(token);
    complexAssignment?.read = read;
    return read;
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
  Expression _makeSimpleRead() {
    return _helper.wrapInDeferredCheck(suffixGenerator._makeSimpleRead(),
        prefixGenerator.prefix, token.charOffset);
  }

  @override
  Expression _makeRead(ComplexAssignmentJudgment complexAssignment) {
    return _helper.wrapInDeferredCheck(
        suffixGenerator._makeRead(complexAssignment),
        prefixGenerator.prefix,
        token.charOffset);
  }

  @override
  Expression _makeWrite(Expression value, bool voidContext,
      ComplexAssignmentJudgment complexAssignment) {
    return _helper.wrapInDeferredCheck(
        suffixGenerator._makeWrite(value, voidContext, complexAssignment),
        prefixGenerator.prefix,
        token.charOffset);
  }

  @override
  ComplexAssignmentJudgment startComplexAssignment(Expression rhs) =>
      SyntheticWrapper.wrapStaticAssignment(rhs);

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
    return unsupported(
        "deferredAccessor.plainNameForRead", offsetForToken(token), _uri);
  }

  @override
  String get _debugName => "DeferredAccessGenerator";

  @override
  TypeBuilder buildTypeWithResolvedArguments(
      List<UnresolvedType<TypeBuilder>> arguments) {
    String name =
        "${prefixGenerator._plainNameForRead}.${suffixGenerator._plainNameForRead}";
    TypeBuilder type =
        suffixGenerator.buildTypeWithResolvedArguments(arguments);
    LocatedMessage message;
    if (type is NamedTypeBuilder &&
        type.declaration is KernelInvalidTypeBuilder) {
      KernelInvalidTypeBuilder declaration = type.declaration;
      message = declaration.message;
    } else {
      int charOffset = offsetForToken(prefixGenerator.token);
      message = templateDeferredTypeAnnotation
          .withArguments(
              _helper.buildDartType(
                  new UnresolvedType<TypeBuilder>(type, charOffset, _uri)),
              prefixGenerator._plainNameForRead)
          .withLocation(
              _uri, charOffset, lengthOfSpan(prefixGenerator.token, token));
    }
    NamedTypeBuilder result = new NamedTypeBuilder(name, null);
    _helper.library.addProblem(
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
      List<UnresolvedType<TypeBuilder>> typeArguments,
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
  void printOn(StringSink sink) {
    sink.write(", prefixGenerator: ");
    sink.write(prefixGenerator);
    sink.write(", suffixGenerator: ");
    sink.write(suffixGenerator);
  }
}

class TypeUseGenerator extends ReadOnlyAccessGenerator {
  final TypeDeclarationBuilder declaration;

  TypeUseGenerator(ExpressionGeneratorHelper helper, Token token,
      this.declaration, String plainNameForRead)
      : super(helper, token, null, plainNameForRead);

  @override
  String get _debugName => "TypeUseGenerator";

  @override
  TypeBuilder buildTypeWithResolvedArguments(
      List<UnresolvedType<TypeBuilder>> arguments) {
    if (arguments != null) {
      int expected = declaration.typeVariablesCount;
      if (arguments.length != expected) {
        // Build the type arguments to report any errors they may have.
        _helper.buildDartTypeArguments(arguments);
        _helper.warnTypeArgumentsMismatch(
            declaration.name, expected, offsetForToken(token));
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
          offsetForToken(token),
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
    return new NamedTypeBuilder(_plainNameForRead, argumentBuilders)
      ..bind(declaration);
  }

  @override
  Expression invokeConstructor(
      List<UnresolvedType<TypeBuilder>> typeArguments,
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
      int offset = offsetForToken(token);
      if (declaration is KernelInvalidTypeBuilder) {
        KernelInvalidTypeBuilder declaration = this.declaration;
        _helper.addProblemErrorIfConst(
            declaration.message.messageObject, offset, token.length);
        super.expression = _helper.wrapSyntheticExpression(
            _forest.throwExpression(
                null, _forest.literalString(declaration.message.message, token))
              ..fileOffset = offset,
            offset);
      } else {
        super.expression = _forest.literalType(
            _helper.buildDartType(
                new UnresolvedType<TypeBuilder>(
                    buildTypeWithResolvedArguments(null), offset, _uri),
                nonInstanceAccessIsError: true),
            token);
      }
    }
    return super.expression;
  }

  @override
  Expression _makeInvalidWrite(Expression value) {
    return _helper.wrapSyntheticExpression(
        _helper.throwNoSuchMethodError(
            _forest.literalNull(token),
            _plainNameForRead,
            _forest.arguments(<Expression>[value], null)
              ..fileOffset = value.fileOffset,
            offsetForToken(token),
            isSetter: true),
        offsetForToken(token));
  }

  @override
  buildPropertyAccess(
      IncompleteSendGenerator send, int operatorOffset, bool isNullAware) {
    // `SomeType?.toString` is the same as `SomeType.toString`, not
    // `(SomeType).toString`.
    isNullAware = false;

    Name name = send.name;
    Arguments arguments = send.arguments;

    if (declaration is KernelClassBuilder) {
      KernelClassBuilder declaration = this.declaration;
      Declaration member = declaration.findStaticBuilder(
          name.name, offsetForToken(send.token), _uri, _helper.library);

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
        Declaration setter;
        if (member.isSetter) {
          setter = member;
        } else if (member.isGetter) {
          setter = declaration.findStaticBuilder(
              name.name, offsetForToken(token), _uri, _helper.library,
              isSetter: true);
        } else if (member.isField) {
          if (member.isFinal || member.isConst) {
            setter = declaration.findStaticBuilder(
                name.name, offsetForToken(token), _uri, _helper.library,
                isSetter: true);
          } else {
            setter = member;
          }
        }
        generator = new StaticAccessGenerator.fromBuilder(
            _helper, member, send.token, setter);
      }

      return arguments == null
          ? generator
          : generator.doInvocation(offsetForToken(send.token), arguments);
    } else {
      return super.buildPropertyAccess(send, operatorOffset, isNullAware);
    }
  }

  @override
  Expression doInvocation(int offset, Arguments arguments) {
    return _helper.buildConstructorInvocation(declaration, token, token,
        arguments, "", null, token.charOffset, Constness.implicit);
  }
}

class ReadOnlyAccessGenerator extends Generator {
  @override
  final String _plainNameForRead;

  Expression expression;

  VariableDeclaration value;

  ReadOnlyAccessGenerator(ExpressionGeneratorHelper helper, Token token,
      this.expression, this._plainNameForRead)
      : super(helper, token);

  @override
  String get _debugName => "ReadOnlyAccessGenerator";

  @override
  Expression _makeSimpleRead() => expression;

  @override
  Expression _makeRead(ComplexAssignmentJudgment complexAssignment) {
    value ??= new VariableDeclaration.forValue(expression);
    return new VariableGet(value);
  }

  @override
  Expression _finish(
          Expression body, ComplexAssignmentJudgment complexAssignment) =>
      super._finish(makeLet(value, body), complexAssignment);

  @override
  Expression doInvocation(int offset, Arguments arguments) {
    return _helper.buildMethodInvocation(buildSimpleRead(), callName, arguments,
        adjustForImplicitCall(_plainNameForRead, offset),
        isImplicitCall: true);
  }

  @override
  void printOn(StringSink sink) {
    NameSystem syntheticNames = new NameSystem();
    sink.write(", expression: ");
    printNodeOn(expression, sink, syntheticNames: syntheticNames);
    sink.write(", plainNameForRead: ");
    sink.write(_plainNameForRead);
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

  Name get name => unsupported("name", offsetForToken(token), _uri);

  @override
  String get _plainNameForRead => name.name;

  withReceiver(Object receiver, int operatorOffset, {bool isNullAware}) => this;

  @override
  Initializer buildFieldInitializer(Map<String, int> initializedFields) {
    return _helper.buildInvalidInitializer(_helper.desugarSyntheticExpression(
        buildError(_forest.argumentsEmpty(token), isSetter: true)));
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
    return buildError(_forest.arguments(<Expression>[value], token),
        isSetter: true);
  }

  @override
  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset: -1,
      bool voidContext: false,
      Procedure interfaceTarget,
      bool isPreIncDec: false,
      bool isPostIncDec: false}) {
    return buildError(_forest.arguments(<Expression>[value], token),
        isGetter: true);
  }

  @override
  Expression buildPrefixIncrement(Name binaryOperator,
      {int offset: -1, bool voidContext: false, Procedure interfaceTarget}) {
    return buildError(
        _forest.arguments(
            <Expression>[_forest.literalInt(1, null)..fileOffset = offset],
            token),
        isGetter: true)
      ..fileOffset = offset;
  }

  @override
  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset: -1, bool voidContext: false, Procedure interfaceTarget}) {
    return buildError(
        _forest.arguments(
            <Expression>[_forest.literalInt(1, null)..fileOffset = offset],
            token),
        isGetter: true)
      ..fileOffset = offset;
  }

  @override
  Expression buildNullAwareAssignment(
      Expression value, DartType type, int offset,
      {bool voidContext: false}) {
    return buildError(_forest.arguments(<Expression>[value], token),
        isSetter: true);
  }

  @override
  Expression buildSimpleRead() {
    return buildError(_forest.argumentsEmpty(token), isGetter: true);
  }

  @override
  Expression _makeInvalidRead() {
    return buildError(_forest.argumentsEmpty(token), isGetter: true);
  }

  @override
  Expression _makeInvalidWrite(Expression value) {
    return buildError(_forest.arguments(<Expression>[value], token),
        isSetter: true);
  }

  @override
  Expression invokeConstructor(
      List<UnresolvedType<TypeBuilder>> typeArguments,
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
    return _helper.wrapInvalidConstructorInvocation(
        _helper.desugarSyntheticExpression(buildError(arguments)),
        null,
        arguments,
        offsetForToken(token));
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
    return _helper.wrapUnresolvedTargetInvocation(
        _helper.desugarSyntheticExpression(
            buildError(arguments, offset: charOffset)),
        arguments,
        arguments.fileOffset);
  }

  @override
  Expression buildError(Arguments arguments,
      {bool isGetter: false, bool isSetter: false, int offset}) {
    offset ??= offsetForToken(this.token);
    return _helper.wrapSyntheticExpression(
        _helper.throwNoSuchMethodError(
            _forest.literalNull(null)..fileOffset = offset,
            _plainNameForRead,
            arguments,
            offset,
            isGetter: isGetter,
            isSetter: isSetter),
        offset);
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
    return buildError(_forest.argumentsEmpty(token), isGetter: true)
      ..fileOffset = token.charOffset;
  }

  @override
  void printOn(StringSink sink) {
    sink.write(", name: ");
    sink.write(name.name);
  }

  Expression _buildUnresolvedVariableAssignment(
      bool isCompound, Expression value) {
    return _helper.wrapUnresolvedVariableAssignment(
        _helper.desugarSyntheticExpression(buildError(
            _forest.arguments(<Expression>[value], token),
            isSetter: true)),
        isCompound,
        value,
        token.charOffset);
  }
}

class UnlinkedGenerator extends Generator {
  final UnlinkedDeclaration declaration;

  final Expression receiver;

  final Name name;

  UnlinkedGenerator(
      ExpressionGeneratorHelper helper, Token token, this.declaration)
      : name = new Name(declaration.name, helper.library.target),
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
    return new PropertySet(receiver, name, value)
      ..fileOffset = offsetForToken(token);
  }

  @override
  Expression buildSimpleRead() {
    return new PropertyGet(receiver, name)..fileOffset = offsetForToken(token);
  }

  @override
  Expression doInvocation(int offset, Arguments arguments) {
    return unsupported("doInvocation", offset, _uri);
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
  Expression buildNullAwareAssignment(
      Expression value, DartType type, int offset,
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
        offsetForToken(token), lengthForToken(token));
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
          messageNotAConstantExpression, offsetForToken(token), token.length);
    }
    if (identical("=", assignmentOperator)) {
      return generator.buildAssignment(value, voidContext: voidContext);
    } else if (identical("+=", assignmentOperator)) {
      return generator.buildCompoundAssignment(plusName, value,
          offset: offsetForToken(token), voidContext: voidContext);
    } else if (identical("-=", assignmentOperator)) {
      return generator.buildCompoundAssignment(minusName, value,
          offset: offsetForToken(token), voidContext: voidContext);
    } else if (identical("*=", assignmentOperator)) {
      return generator.buildCompoundAssignment(multiplyName, value,
          offset: offsetForToken(token), voidContext: voidContext);
    } else if (identical("%=", assignmentOperator)) {
      return generator.buildCompoundAssignment(percentName, value,
          offset: offsetForToken(token), voidContext: voidContext);
    } else if (identical("&=", assignmentOperator)) {
      return generator.buildCompoundAssignment(ampersandName, value,
          offset: offsetForToken(token), voidContext: voidContext);
    } else if (identical("/=", assignmentOperator)) {
      return generator.buildCompoundAssignment(divisionName, value,
          offset: offsetForToken(token), voidContext: voidContext);
    } else if (identical("<<=", assignmentOperator)) {
      return generator.buildCompoundAssignment(leftShiftName, value,
          offset: offsetForToken(token), voidContext: voidContext);
    } else if (identical(">>=", assignmentOperator)) {
      return generator.buildCompoundAssignment(rightShiftName, value,
          offset: offsetForToken(token), voidContext: voidContext);
    } else if (identical(">>>=", assignmentOperator)) {
      return generator.buildCompoundAssignment(tripleShiftName, value,
          offset: offsetForToken(token), voidContext: voidContext);
    } else if (identical("??=", assignmentOperator)) {
      return generator.buildNullAwareAssignment(
          value, const DynamicType(), offsetForToken(token),
          voidContext: voidContext);
    } else if (identical("^=", assignmentOperator)) {
      return generator.buildCompoundAssignment(caretName, value,
          offset: offsetForToken(token), voidContext: voidContext);
    } else if (identical("|=", assignmentOperator)) {
      return generator.buildCompoundAssignment(barName, value,
          offset: offsetForToken(token), voidContext: voidContext);
    } else if (identical("~/=", assignmentOperator)) {
      return generator.buildCompoundAssignment(mustacheName, value,
          offset: offsetForToken(token), voidContext: voidContext);
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
        offsetForToken(generator.token), offsetForToken(token), value);
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
        offset: offsetForToken(token),
        voidContext: false,
        interfaceTarget: interfaceTarget);
  }

  @override
  Expression buildForEffect() {
    return generator.buildPostfixIncrement(binaryOperator,
        offset: offsetForToken(token),
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
  /* Expression | Generator */ Object qualifiedLookup(Token name) {
    if (_helper.constantContext != ConstantContext.none && prefix.deferred) {
      _helper.addProblem(
          templateCantUseDeferredPrefixAsConstant.withArguments(token),
          offsetForToken(token),
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
        _helper.wrapInDeferredCheck(result, prefix, offsetForToken(token));
      }
    }
    return result;
  }

  @override
  /* Expression | Generator | Initializer */ doInvocation(
      int offset, Arguments arguments) {
    return _helper.wrapInLocatedProblem(
        _helper.evaluateArgumentsBefore(arguments, _forest.literalNull(token)),
        messageCantUsePrefixAsExpression.withLocation(
            _helper.uri, offsetForToken(token), lengthForToken(token)));
  }

  @override
  /* Expression | Generator */ buildPropertyAccess(
      IncompleteSendGenerator send, int operatorOffset, bool isNullAware) {
    if (send is IncompleteSendGenerator) {
      assert(send.name.name == send.token.lexeme,
          "'${send.name.name}' != ${send.token.lexeme}");
      Object result = qualifiedLookup(send.token);
      if (send is SendAccessGenerator) {
        result = _helper.finishSend(
            result,
            send.arguments as dynamic /* TODO(ahe): Remove this cast. */,
            offsetForToken(token));
      }
      if (isNullAware) {
        result = _helper.wrapInLocatedProblem(
            _helper.toValue(result),
            messageCantUsePrefixWithNullAware.withLocation(
                _helper.uri, offsetForToken(token), lengthForToken(token)));
      }
      return result;
    } else {
      return buildSimpleRead();
    }
  }

  @override
  Expression _makeInvalidRead() {
    return _helper.buildProblem(messageCantUsePrefixAsExpression,
        offsetForToken(token), lengthForToken(token));
  }

  @override
  Expression _makeInvalidWrite(Expression value) => _makeInvalidRead();

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
  String get _plainNameForRead {
    return "${prefixGenerator._plainNameForRead}.${token.lexeme}";
  }

  @override
  String get _debugName => "UnexpectedQualifiedUseGenerator";

  @override
  Expression buildSimpleRead() => _makeInvalidRead();

  @override
  Expression doInvocation(int offset, Arguments arguments) {
    return _helper.wrapSyntheticExpression(
        _helper.throwNoSuchMethodError(
            _forest.literalNull(null)..fileOffset = offset,
            _plainNameForRead,
            arguments,
            offsetForToken(token)),
        offsetForToken(token));
  }

  @override
  TypeBuilder buildTypeWithResolvedArguments(
      List<UnresolvedType<TypeBuilder>> arguments) {
    Template<Message Function(String, String)> template = isUnresolved
        ? templateUnresolvedPrefixInTypeAnnotation
        : templateNotAPrefixInTypeAnnotation;
    NamedTypeBuilder result = new NamedTypeBuilder(_plainNameForRead, null);
    Message message =
        template.withArguments(prefixGenerator.token.lexeme, token.lexeme);
    _helper.library.addProblem(message, offsetForToken(prefixGenerator.token),
        lengthOfSpan(prefixGenerator.token, token), _uri);
    result.bind(result.buildInvalidType(message.withLocation(
        _uri,
        offsetForToken(prefixGenerator.token),
        lengthOfSpan(prefixGenerator.token, token))));
    return result;
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
    return _helper.buildProblem(message, offsetForToken(token), noLength,
        suppressMessage: true);
  }

  Expression buildSimpleRead() => buildProblem();

  Expression buildAssignment(Expression value, {bool voidContext: false}) {
    return buildProblem();
  }

  Expression buildNullAwareAssignment(
      Expression value, DartType type, int offset,
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
    return _helper.buildInvalidInitializer(
        _helper.desugarSyntheticExpression(buildProblem()));
  }

  Expression doInvocation(int offset, Arguments arguments) {
    return buildProblem();
  }

  Expression buildPropertyAccess(
      IncompleteSendGenerator send, int operatorOffset, bool isNullAware) {
    return buildProblem();
  }

  TypeBuilder buildTypeWithResolvedArguments(
      List<UnresolvedType<TypeBuilder>> arguments) {
    NamedTypeBuilder result = new NamedTypeBuilder(token.lexeme, null);
    _helper.library.addProblem(message, offsetForToken(token), noLength, _uri);
    result.bind(result.buildInvalidType(
        message.withLocation(_uri, offsetForToken(token), noLength)));
    return result;
  }

  Expression qualifiedLookup(Token name) {
    return buildProblem();
  }

  Expression invokeConstructor(
      List<UnresolvedType<TypeBuilder>> typeArguments,
      String name,
      Arguments arguments,
      Token nameToken,
      Token nameLastToken,
      Constness constness) {
    return buildProblem();
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

  // `true` if this subexpression represents a `super` prefix.
  final bool isSuper;

  ThisAccessGenerator(ExpressionGeneratorHelper helper, Token token,
      this.isInitializer, this.inFieldInitializer,
      {this.isSuper: false})
      : super(helper, token);

  String get _plainNameForRead {
    return unsupported("${isSuper ? 'super' : 'this'}.plainNameForRead",
        offsetForToken(token), _uri);
  }

  String get _debugName => "ThisAccessGenerator";

  Expression buildSimpleRead() {
    if (!isSuper) {
      if (inFieldInitializer) {
        return buildFieldInitializerError(null);
      } else {
        return _forest.thisExpression(token);
      }
    } else {
      return _helper.buildProblem(messageSuperAsExpression,
          offsetForToken(token), lengthForToken(token));
    }
  }

  Expression buildFieldInitializerError(Map<String, int> initializedFields) {
    String keyword = isSuper ? "super" : "this";
    return _helper.buildProblem(
        templateThisOrSuperAccessInFieldInitializer.withArguments(keyword),
        offsetForToken(token),
        keyword.length);
  }

  @override
  Initializer buildFieldInitializer(Map<String, int> initializedFields) {
    Expression error = _helper.desugarSyntheticExpression(
        buildFieldInitializerError(initializedFields));
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
      return _helper.buildMethodInvocation(_forest.thisExpression(null), name,
          send.arguments, offsetForToken(send.token),
          isSuper: isSuper, interfaceTarget: getter);
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
          _forest.thisExpression(null), callName, arguments, offset,
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
          .withLocation(_uri, offsetForToken(token), lengthForToken(token));
    }
    if (message != null) {
      return _helper.buildInvalidInitializer(_helper.wrapSyntheticExpression(
          _helper.throwNoSuchMethodError(
              _forest.literalNull(null)..fileOffset = offset,
              _helper.constructorNameForDiagnostics(name.name,
                  isSuper: isSuper),
              arguments,
              offset,
              isSuper: isSuper,
              message: message),
          offset));
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

  Expression buildNullAwareAssignment(
      Expression value, DartType type, int offset,
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

  Expression buildAssignmentError() {
    return _helper.desugarSyntheticExpression(_helper.buildProblem(
        isSuper ? messageCannotAssignToSuper : messageNotAnLvalue,
        offsetForToken(token),
        token.length));
  }

  @override
  void printOn(StringSink sink) {
    sink.write(", isInitializer: ");
    sink.write(isInitializer);
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
      offset = offsetForToken(token);
      length = lengthForToken(token);
    }
    return _helper.buildProblem(message, offset, length);
  }

  @override
  doInvocation(int offset, Arguments arguments) => this;

  @override
  Expression buildSimpleRead() {
    return buildError(_forest.argumentsEmpty(token), isGetter: true)
      ..fileOffset = offsetForToken(token);
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
    return unsupported("buildSimpleRead", offsetForToken(token), _uri);
  }

  Expression buildAssignment(Expression value, {bool voidContext: false}) {
    return unsupported("buildAssignment", offsetForToken(token), _uri);
  }

  withReceiver(Object receiver, int operatorOffset, {bool isNullAware: false}) {
    if (receiver is Generator) {
      return receiver.buildPropertyAccess(this, operatorOffset, isNullAware);
    }
    return _helper.buildMethodInvocation(
        _helper.toValue(receiver), name, arguments, offsetForToken(token),
        isNullAware: isNullAware);
  }

  Expression buildNullAwareAssignment(
      Expression value, DartType type, int offset,
      {bool voidContext: false}) {
    return unsupported("buildNullAwareAssignment", offset, _uri);
  }

  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      Procedure interfaceTarget,
      bool isPreIncDec: false,
      bool isPostIncDec: false}) {
    return unsupported(
        "buildCompoundAssignment", offset ?? offsetForToken(token), _uri);
  }

  Expression buildPrefixIncrement(Name binaryOperator,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      Procedure interfaceTarget}) {
    return unsupported(
        "buildPrefixIncrement", offset ?? offsetForToken(token), _uri);
  }

  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      Procedure interfaceTarget}) {
    return unsupported(
        "buildPostfixIncrement", offset ?? offsetForToken(token), _uri);
  }

  Expression doInvocation(int offset, Arguments arguments) {
    return unsupported("doInvocation", offset, _uri);
  }

  @override
  void printOn(StringSink sink) {
    sink.write(", name: ");
    sink.write(name.name);
    sink.write(", arguments: ");
    var node = arguments;
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
    return unsupported("buildSimpleRead", offsetForToken(token), _uri);
  }

  Expression buildAssignment(Expression value, {bool voidContext: false}) {
    return unsupported("buildAssignment", offsetForToken(token), _uri);
  }

  withReceiver(Object receiver, int operatorOffset, {bool isNullAware: false}) {
    if (receiver is Generator) {
      return receiver.buildPropertyAccess(this, operatorOffset, isNullAware);
    }
    return PropertyAccessGenerator.make(_helper, token,
        _helper.toValue(receiver), name, null, null, isNullAware);
  }

  Expression buildNullAwareAssignment(
      Expression value, DartType type, int offset,
      {bool voidContext: false}) {
    return unsupported("buildNullAwareAssignment", offset, _uri);
  }

  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      Procedure interfaceTarget,
      bool isPreIncDec: false,
      bool isPostIncDec: false}) {
    return unsupported(
        "buildCompoundAssignment", offset ?? offsetForToken(token), _uri);
  }

  Expression buildPrefixIncrement(Name binaryOperator,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      Procedure interfaceTarget}) {
    return unsupported(
        "buildPrefixIncrement", offset ?? offsetForToken(token), _uri);
  }

  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      Procedure interfaceTarget}) {
    return unsupported(
        "buildPostfixIncrement", offset ?? offsetForToken(token), _uri);
  }

  Expression doInvocation(int offset, Arguments arguments) {
    return unsupported("doInvocation", offset, _uri);
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

  @override
  ComplexAssignmentJudgment startComplexAssignment(Expression rhs) {
    return SyntheticWrapper.wrapIllegalAssignment(rhs,
        assignmentOffset: offsetForToken(token));
  }

  Expression _makeInvalidWrite(Expression value) {
    return _helper.wrapInvalidWrite(
        _helper.desugarSyntheticExpression(_helper.buildProblem(
            messageCannotAssignToParenthesizedExpression,
            offsetForToken(token),
            lengthForToken(token))),
        expression,
        offsetForToken(token));
  }
}

Expression makeLet(VariableDeclaration variable, Expression body) {
  if (variable == null) return body;
  return new Let(variable, body);
}

Expression makeBinary(Expression left, Name operator, Procedure interfaceTarget,
    Expression right, ExpressionGeneratorHelper helper,
    {int offset: TreeNode.noOffset}) {
  return new MethodInvocationJudgment(
      left,
      operator,
      helper.forest
          .castArguments(helper.forest.arguments(<Expression>[right], null))
            ..fileOffset = offset,
      interfaceTarget: interfaceTarget)
    ..fileOffset = offset;
}

Expression buildIsNull(
    Expression value, int offset, ExpressionGeneratorHelper helper) {
  return makeBinary(value, equalsName, null,
      helper.forest.literalNull(null)..fileOffset = offset, helper,
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
