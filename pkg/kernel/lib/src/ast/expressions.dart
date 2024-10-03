// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../../ast.dart';

// ------------------------------------------------------------------------
//                                EXPRESSIONS
// ------------------------------------------------------------------------

sealed class Expression extends TreeNode {
  /// Returns the static type of the expression.
  ///
  /// This calls `StaticTypeContext.getExpressionType` which calls
  /// [getStaticTypeInternal] to compute the type of not already cached in
  /// [context].
  DartType getStaticType(StaticTypeContext context) {
    return context.getExpressionType(this);
  }

  /// Computes the static type of this expression.
  ///
  /// This is called by `StaticTypeContext.getExpressionType` if the static
  /// type of this expression is not already cached in [context].
  DartType getStaticTypeInternal(StaticTypeContext context);

  /// Returns the static type of the expression as an instantiation of
  /// [superclass].
  ///
  /// Shouldn't be used on code compiled in legacy mode, as this method assumes
  /// the IR is strongly typed.
  ///
  /// This method furthermore assumes that the type of the expression actually
  /// is a subtype of (some instantiation of) the given [superclass].
  /// If this is not the case, either an exception is thrown or the raw type of
  /// [superclass] is returned.
  InterfaceType getStaticTypeAsInstanceOf(
      Class superclass, StaticTypeContext context) {
    // This method assumes the program is correctly typed, so if the superclass
    // is not generic, we can just return its raw type without computing the
    // type of this expression.  It also ensures that all types are considered
    // subtypes of Object (not just interface types), and function types are
    // considered subtypes of Function.
    if (superclass.typeParameters.isEmpty) {
      return context.typeEnvironment.coreTypes
          .rawType(superclass, context.nonNullable);
    }
    DartType type = getStaticType(context).nonTypeVariableBound;
    if (type is NullType) {
      return context.typeEnvironment.coreTypes
          .bottomInterfaceType(superclass, context.nullable);
    } else if (type is NeverType) {
      return context.typeEnvironment.coreTypes
          .bottomInterfaceType(superclass, type.nullability);
    }
    if (type is TypeDeclarationType) {
      List<DartType>? upcastTypeArguments = context.typeEnvironment
          .getTypeArgumentsAsInstanceOf(type, superclass);
      if (upcastTypeArguments != null) {
        return new InterfaceType(
            superclass, type.nullability, upcastTypeArguments);
      }
    }

    // The static type of this expression is not a subtype of [superclass]. The
    // means that the static type of this expression is not the same as when
    // the parent [PropertyGet] or [MethodInvocation] was created.
    //
    // For instance when cloning generic mixin methods, the substitution can
    // render some of the code paths as dead code:
    //
    //     mixin M<T> {
    //       int method(T t) => t is String ? t.length : 0;
    //     }
    //     class C with M<int> {}
    //
    // The mixin transformation will clone the `M.method` method into the
    // unnamed mixin application for `Object&M<int>` as this:
    //
    //     int method(int t) => t is String ? t.length : 0;
    //
    // Now `t.length`, which was originally an access to `String.length` on a
    // receiver of type `T & String`, is an access to `String.length` on `int`.
    // When computing the static type of `t.length` we will try to compute the
    // type of `int` as an instance of `String`, and we do not find it to be
    // an instance of `String`.
    //
    // To resolve this case we compute the type of `t.length` to be the type
    // as if accessed on an unknown subtype `String`.
    return context.typeEnvironment.coreTypes
        .rawType(superclass, context.nonNullable);
  }

  @override
  R accept<R>(ExpressionVisitor<R> v);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg);

  int get precedence => astToText.Precedence.of(this);

  @override
  String toText(AstTextStrategy strategy) {
    AstPrinter printer = new AstPrinter(strategy);
    printer.writeExpression(this);
    return printer.getText();
  }
}

/// Abstract subclass of [Expression] that can be used to add [Expression]
/// subclasses from outside `package:kernel`.
abstract class AuxiliaryExpression extends Expression {
  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitAuxiliaryExpression(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitAuxiliaryExpression(this, arg);
}

/// An expression containing compile-time errors.
///
/// Should throw a runtime error when evaluated.
///
/// The [fileOffset] of an [InvalidExpression] indicates the location in the
/// tree where the expression occurs, rather than the location of the error.
class InvalidExpression extends Expression {
  // TODO(johnniwinther): Avoid using `null` as the empty string.
  String? message;

  /// The expression containing the error.
  Expression? expression;

  InvalidExpression(this.message, [this.expression]) {
    expression?.parent = this;
  }

  @override
  DartType getStaticType(StaticTypeContext context) =>
      getStaticTypeInternal(context);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) =>
      const NeverType.nonNullable();

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitInvalidExpression(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitInvalidExpression(this, arg);

  @override
  void visitChildren(Visitor v) {
    expression?.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    if (expression != null) {
      expression = v.transform(expression!);
      expression?.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    if (expression != null) {
      expression = v.transformOrRemoveExpression(expression!);
      expression?.parent = this;
    }
  }

  @override
  String toString() {
    return "InvalidExpression(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('<invalid:');
    printer.write(message ?? '');
    if (expression != null) {
      printer.write(', ');
      printer.writeExpression(expression!);
    }
    printer.write('>');
  }
}

/// Read a local variable, a local function, or a function parameter.
class VariableGet extends Expression {
  VariableDeclaration variable;
  DartType? promotedType; // Null if not promoted.

  VariableGet(this.variable, [this.promotedType]);

  @override
  DartType getStaticType(StaticTypeContext context) =>
      getStaticTypeInternal(context);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) {
    return promotedType ?? variable.type;
  }

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitVariableGet(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitVariableGet(this, arg);

  @override
  void visitChildren(Visitor v) {
    promotedType?.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    if (promotedType != null) {
      promotedType = v.visitDartType(promotedType!);
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    if (promotedType != null) {
      DartType newPromotedType = v.visitDartType(promotedType!, dummyDartType);
      if (identical(newPromotedType, dummyDartType)) {
        promotedType = null;
      } else {
        promotedType = newPromotedType;
      }
    }
  }

  @override
  String toString() {
    return "VariableGet(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write(printer.getVariableName(variable));
    if (promotedType != null) {
      printer.write('{');
      printer.writeType(promotedType!);
      printer.write('}');
    }
  }
}

/// Assign a local variable or function parameter.
///
/// Evaluates to the value of [value].
class VariableSet extends Expression {
  VariableDeclaration variable;
  Expression value;

  VariableSet(this.variable, this.value) {
    value.parent = this;
  }

  @override
  DartType getStaticType(StaticTypeContext context) =>
      getStaticTypeInternal(context);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) =>
      value.getStaticType(context);

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitVariableSet(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitVariableSet(this, arg);

  @override
  void visitChildren(Visitor v) {
    value.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    value = v.transform(value);
    value.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    value = v.transform(value);
    value.parent = this;
  }

  @override
  String toString() {
    return "VariableSet(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write(printer.getVariableName(variable));
    printer.write(' = ');
    printer.writeExpression(value);
  }
}

class RecordIndexGet extends Expression {
  Expression receiver;
  RecordType receiverType;
  final int index;

  RecordIndexGet(this.receiver, this.receiverType, this.index)
      : assert(0 <= index && index < receiverType.positional.length) {
    receiver.parent = this;
  }

  @override
  DartType getStaticType(StaticTypeContext context) =>
      getStaticTypeInternal(context);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) {
    assert(index < receiverType.positional.length);
    return receiverType.positional[index];
  }

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitRecordIndexGet(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitRecordIndexGet(this, arg);

  @override
  void visitChildren(Visitor v) {
    receiver.accept(v);
    receiverType.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    receiver = v.transform(receiver)..parent = this;
    receiverType = v.visitDartType(receiverType) as RecordType;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    receiver = v.transform(receiver)..parent = this;
    receiverType =
        v.visitDartType(receiverType, cannotRemoveSentinel) as RecordType;
  }

  @override
  String toString() {
    return "RecordIndexGet(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(receiver);
    printer.write(".\$${index + 1}");
  }
}

class RecordNameGet extends Expression {
  Expression receiver;
  RecordType receiverType;
  final String name;

  RecordNameGet(this.receiver, this.receiverType, this.name)
      : assert(receiverType.named
                .singleWhere((element) => element.name == name)
                .name ==
            name) {
    receiver.parent = this;
  }

  @override
  DartType getStaticType(StaticTypeContext context) =>
      getStaticTypeInternal(context);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) {
    DartType? result;
    for (NamedType namedType in receiverType.named) {
      if (namedType.name == name) {
        result = namedType.type;
        break;
      }
    }
    assert(result != null);

    return result!;
  }

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitRecordNameGet(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitRecordNameGet(this, arg);

  @override
  void visitChildren(Visitor v) {
    receiver.accept(v);
    receiverType.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    receiver = v.transform(receiver)..parent = this;
    receiverType = v.visitDartType(receiverType) as RecordType;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    receiver = v.transform(receiver)..parent = this;
    receiverType =
        v.visitDartType(receiverType, cannotRemoveSentinel) as RecordType;
  }

  @override
  String toString() {
    return "RecordNameGet(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(receiver);
    printer.write(".${name}");
  }
}

enum DynamicAccessKind {
  /// An access on a receiver of type dynamic.
  ///
  /// An access of this kind always results in a value of static type dynamic.
  ///
  /// Valid accesses to Object members on receivers of type dynamic are encoded
  /// as an [InstanceInvocation] of kind [InstanceAccessKind.Object].
  Dynamic,

  /// An access on a receiver of type Never.
  ///
  /// An access of this kind always results in a value of static type Never.
  ///
  /// Valid accesses to Object members on receivers of type Never are also
  /// encoded as [DynamicInvocation] of kind [DynamicAccessKind.Never] and _not_
  /// as an [InstanceInvocation] of kind [InstanceAccessKind.Object].
  Never,

  /// An access on a receiver of an invalid type.
  ///
  /// An access of this kind always results in a value of an invalid static
  /// type.
  Invalid,

  /// An access of an unresolved target.
  ///
  /// An access of this kind always results in a value of an invalid static
  /// type.
  Unresolved,
}

class DynamicGet extends Expression {
  final DynamicAccessKind kind;
  Expression receiver;
  Name name;

  DynamicGet(this.kind, this.receiver, this.name) {
    receiver.parent = this;
  }

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitDynamicGet(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitDynamicGet(this, arg);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) {
    switch (kind) {
      case DynamicAccessKind.Dynamic:
        return const DynamicType();
      case DynamicAccessKind.Never:
        return const NeverType.nonNullable();
      case DynamicAccessKind.Invalid:
      case DynamicAccessKind.Unresolved:
        return const InvalidType();
    }
  }

  @override
  void visitChildren(Visitor v) {
    receiver.accept(v);
    name.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    receiver = v.transform(receiver);
    receiver.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    receiver = v.transform(receiver);
    receiver.parent = this;
  }

  @override
  String toString() {
    return "DynamicGet($kind,${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(receiver,
        minimumPrecedence: astToText.Precedence.PRIMARY);
    printer.write('.');
    printer.writeName(name);
  }
}

/// A property read of an instance getter or field with a statically known
/// interface target.
class InstanceGet extends Expression {
  final InstanceAccessKind kind;
  Expression receiver;

  // TODO(johnniwinther): Can we pull this from the [interfaceTarget] instead?
  Name name;

  /// The static type of result of the property read.
  ///
  /// This includes substituted type parameters from the static receiver type.
  ///
  /// For instance
  ///
  ///    class A<T> {
  ///      T get t;
  ///    }
  ///    m(A<String> a) {
  ///      a.t; // The result type is `String`.
  ///    }
  ///
  DartType resultType;

  Reference interfaceTargetReference;

  InstanceGet(InstanceAccessKind kind, Expression receiver, Name name,
      {required Member interfaceTarget, required DartType resultType})
      : this.byReference(kind, receiver, name,
            interfaceTargetReference:
                getNonNullableMemberReferenceGetter(interfaceTarget),
            resultType: resultType);

  InstanceGet.byReference(this.kind, this.receiver, this.name,
      {required this.interfaceTargetReference, required this.resultType}) {
    receiver.parent = this;
  }

  Member get interfaceTarget => interfaceTargetReference.asMember;

  void set interfaceTarget(Member member) {
    interfaceTargetReference = getNonNullableMemberReferenceGetter(member);
  }

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) => resultType;

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitInstanceGet(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitInstanceGet(this, arg);

  @override
  void visitChildren(Visitor v) {
    receiver.accept(v);
    interfaceTarget.acceptReference(v);
    name.accept(v);
    resultType.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    receiver = v.transform(receiver);
    receiver.parent = this;
    resultType = v.visitDartType(resultType);
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    receiver = v.transform(receiver);
    receiver.parent = this;
    resultType = v.visitDartType(resultType, cannotRemoveSentinel);
  }

  @override
  String toString() {
    return "InstanceGet($kind,${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(receiver,
        minimumPrecedence: astToText.Precedence.PRIMARY);
    printer.write('.');
    printer.writeInterfaceMemberName(interfaceTargetReference, name);
  }
}

/// A tear-off of the 'call' method on an expression whose static type is
/// a function type or the type 'Function'.
class FunctionTearOff extends Expression {
  Expression receiver;

  FunctionTearOff(this.receiver) {
    receiver.parent = this;
  }

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) =>
      receiver.getStaticType(context);

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitFunctionTearOff(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitFunctionTearOff(this, arg);

  @override
  void visitChildren(Visitor v) {
    receiver.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    receiver = v.transform(receiver);
    receiver.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    receiver = v.transform(receiver);
    receiver.parent = this;
  }

  @override
  String toString() {
    return "FunctionTearOff(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(receiver,
        minimumPrecedence: astToText.Precedence.PRIMARY);
    printer.write('.');
    printer.writeName(Name.callName);
  }
}

/// A tear-off of an instance method with a statically known interface target.
class InstanceTearOff extends Expression {
  final InstanceAccessKind kind;
  Expression receiver;

  // TODO(johnniwinther): Can we pull this from the [interfaceTarget] instead?
  Name name;

  /// The static type of result of the tear-off.
  ///
  /// This includes substituted type parameters from the static receiver type.
  ///
  /// For instance
  ///
  ///    class A<T, S> {
  ///      T method<U>(S s, U u) { ... }
  ///    }
  ///    m(A<String, int> a) {
  ///      a.method; // The result type is `String Function<U>(int, U)`.
  ///    }
  ///
  DartType resultType;

  Reference interfaceTargetReference;

  InstanceTearOff(InstanceAccessKind kind, Expression receiver, Name name,
      {required Procedure interfaceTarget, required DartType resultType})
      : this.byReference(kind, receiver, name,
            interfaceTargetReference:
                getNonNullableMemberReferenceGetter(interfaceTarget),
            resultType: resultType);

  InstanceTearOff.byReference(this.kind, this.receiver, this.name,
      {required this.interfaceTargetReference, required this.resultType}) {
    receiver.parent = this;
  }

  Procedure get interfaceTarget => interfaceTargetReference.asProcedure;

  void set interfaceTarget(Procedure procedure) {
    interfaceTargetReference = getNonNullableMemberReferenceGetter(procedure);
  }

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) => resultType;

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitInstanceTearOff(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitInstanceTearOff(this, arg);

  @override
  void visitChildren(Visitor v) {
    receiver.accept(v);
    interfaceTarget.acceptReference(v);
    name.accept(v);
    resultType.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    receiver = v.transform(receiver);
    receiver.parent = this;
    resultType = v.visitDartType(resultType);
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    receiver = v.transform(receiver);
    receiver.parent = this;
    resultType = v.visitDartType(resultType, cannotRemoveSentinel);
  }

  @override
  String toString() {
    return "InstanceTearOff($kind, ${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(receiver,
        minimumPrecedence: astToText.Precedence.PRIMARY);
    printer.write('.');
    printer.writeInterfaceMemberName(interfaceTargetReference, name);
  }
}

class DynamicSet extends Expression {
  final DynamicAccessKind kind;
  Expression receiver;
  Name name;
  Expression value;

  DynamicSet(this.kind, this.receiver, this.name, this.value) {
    receiver.parent = this;
    value.parent = this;
  }

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) =>
      value.getStaticType(context);

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitDynamicSet(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitDynamicSet(this, arg);

  @override
  void visitChildren(Visitor v) {
    receiver.accept(v);
    name.accept(v);
    value.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    receiver = v.transform(receiver);
    receiver.parent = this;
    value = v.transform(value);
    value.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    receiver = v.transform(receiver);
    receiver.parent = this;
    value = v.transform(value);
    value.parent = this;
  }

  @override
  String toString() {
    return "DynamicSet($kind,${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(receiver,
        minimumPrecedence: astToText.Precedence.PRIMARY);
    printer.write('.');
    printer.writeName(name);
    printer.write(' = ');
    printer.writeExpression(value);
  }
}

/// An property write of an instance setter or field with a statically known
/// interface target.
class InstanceSet extends Expression {
  final InstanceAccessKind kind;
  Expression receiver;

  // TODO(johnniwinther): Can we pull this from the [interfaceTarget] instead?
  Name name;
  Expression value;

  Reference interfaceTargetReference;

  InstanceSet(
      InstanceAccessKind kind, Expression receiver, Name name, Expression value,
      {required Member interfaceTarget})
      : this.byReference(kind, receiver, name, value,
            interfaceTargetReference:
                getNonNullableMemberReferenceSetter(interfaceTarget));

  InstanceSet.byReference(this.kind, this.receiver, this.name, this.value,
      {required this.interfaceTargetReference}) {
    receiver.parent = this;
    value.parent = this;
  }

  Member get interfaceTarget => interfaceTargetReference.asMember;

  void set interfaceTarget(Member member) {
    interfaceTargetReference = getNonNullableMemberReferenceSetter(member);
  }

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) =>
      value.getStaticType(context);

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitInstanceSet(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitInstanceSet(this, arg);

  @override
  void visitChildren(Visitor v) {
    receiver.accept(v);
    interfaceTarget.acceptReference(v);
    name.accept(v);
    value.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    receiver = v.transform(receiver);
    receiver.parent = this;
    value = v.transform(value);
    value.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    receiver = v.transform(receiver);
    receiver.parent = this;
    value = v.transform(value);
    value.parent = this;
  }

  @override
  String toString() {
    return "InstanceSet(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(receiver,
        minimumPrecedence: astToText.Precedence.PRIMARY);
    printer.write('.');
    printer.writeInterfaceMemberName(interfaceTargetReference, name);
    printer.write(' = ');
    printer.writeExpression(value);
  }
}

/// Expression of form `super.foo` occurring in a mixin declaration.
///
/// In this setting, the target is looked up on the types in the mixin 'on'
/// clause and are therefore not necessary the runtime targets of the read. An
/// [AbstractSuperPropertyGet] must be converted into a [SuperPropertyGet] to
/// statically bind the target.
///
/// For instance
///
///    abstract class Interface {
///      get getter;
///    }
///    mixin Mixin on Interface {
///      get getter {
///        // This is an [AbstractSuperPropertyGet] with interface target
///        // `Interface.getter`.
///        return super.getter;
///      }
///    }
///    class Super implements Interface {
///      // This is the target when `Mixin` is applied to `Class`.
///      get getter => 42;
///    }
///    class Class extends Super with Mixin {}
///
/// This may invoke a getter, read a field, or tear off a method.
class AbstractSuperPropertyGet extends Expression {
  Name name;

  Reference interfaceTargetReference;

  AbstractSuperPropertyGet(Name name, Member interfaceTarget)
      : this.byReference(
            name, getNonNullableMemberReferenceGetter(interfaceTarget));

  AbstractSuperPropertyGet.byReference(
      this.name, this.interfaceTargetReference);

  Member get interfaceTarget => interfaceTargetReference.asMember;

  void set interfaceTarget(Member member) {
    interfaceTargetReference = getNonNullableMemberReferenceGetter(member);
  }

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) {
    Class declaringClass = interfaceTarget.enclosingClass!;
    if (declaringClass.typeParameters.isEmpty) {
      return interfaceTarget.getterType;
    }
    List<DartType>? receiverArguments = context.typeEnvironment
        .getTypeArgumentsAsInstanceOf(context.thisType!, declaringClass);
    return Substitution.fromPairs(
            declaringClass.typeParameters, receiverArguments!)
        .substituteType(interfaceTarget.getterType);
  }

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitAbstractSuperPropertyGet(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitAbstractSuperPropertyGet(this, arg);

  @override
  void visitChildren(Visitor v) {
    interfaceTarget.acceptReference(v);
    name.accept(v);
  }

  @override
  void transformChildren(Transformer v) {}

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {}

  @override
  String toString() {
    return "AbstractSuperPropertyGet(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('super.{abstract}');
    printer.writeInterfaceMemberName(interfaceTargetReference, name);
  }
}

/// Expression of form `super.field`.
///
/// This may invoke a getter, read a field, or tear off a method.
class SuperPropertyGet extends Expression {
  Name name;

  Reference interfaceTargetReference;

  SuperPropertyGet(Name name, Member interfaceTarget)
      : this.byReference(
            name, getNonNullableMemberReferenceGetter(interfaceTarget));

  SuperPropertyGet.byReference(this.name, this.interfaceTargetReference);

  Member get interfaceTarget => interfaceTargetReference.asMember;

  void set interfaceTarget(Member member) {
    interfaceTargetReference = getNonNullableMemberReferenceGetter(member);
  }

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) {
    Class declaringClass = interfaceTarget.enclosingClass!;
    if (declaringClass.typeParameters.isEmpty) {
      return interfaceTarget.getterType;
    }
    List<DartType>? receiverArguments = context.typeEnvironment
        .getTypeArgumentsAsInstanceOf(context.thisType!, declaringClass);
    return Substitution.fromPairs(
            declaringClass.typeParameters, receiverArguments!)
        .substituteType(interfaceTarget.getterType);
  }

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitSuperPropertyGet(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitSuperPropertyGet(this, arg);

  @override
  void visitChildren(Visitor v) {
    interfaceTarget.acceptReference(v);
    name.accept(v);
  }

  @override
  void transformChildren(Transformer v) {}

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {}

  @override
  String toString() {
    return "SuperPropertyGet(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('super.');
    printer.writeInterfaceMemberName(interfaceTargetReference, name);
  }
}

/// Expression of form `super.foo = x` occurring in a mixin declaration.
///
/// In this setting, the target is looked up on the types in the mixin 'on'
/// clause and are therefore not necessary the runtime targets of the
/// assignment. An [AbstractSuperPropertySet] must be converted into a
/// [SuperPropertySet] to statically bind the target.
///
/// For instance
///
///    abstract class Interface {
///      void set setter(value);
///    }
///    mixin Mixin on Interface {
///      void set setter(value) {
///        // This is an [AbstractSuperPropertySet] with interface target
///        // `Interface.setter`.
///        super.setter = value;
///      }
///    }
///    class Super implements Interface {
///      // This is the target when `Mixin` is applied to `Class`.
///      void set setter(value) {}
///    }
///    class Class extends Super with Mixin {}
///
/// This may invoke a setter or assign a field.
class AbstractSuperPropertySet extends Expression {
  Name name;
  Expression value;

  Reference interfaceTargetReference;

  AbstractSuperPropertySet(Name name, Expression value, Member interfaceTarget)
      : this.byReference(
            name, value, getNonNullableMemberReferenceSetter(interfaceTarget));

  AbstractSuperPropertySet.byReference(
      this.name, this.value, this.interfaceTargetReference) {
    value.parent = this;
  }

  Member get interfaceTarget => interfaceTargetReference.asMember;

  void set interfaceTarget(Member member) {
    interfaceTargetReference = getNonNullableMemberReferenceSetter(member);
  }

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) =>
      value.getStaticType(context);

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitAbstractSuperPropertySet(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitAbstractSuperPropertySet(this, arg);

  @override
  void visitChildren(Visitor v) {
    interfaceTarget.acceptReference(v);
    name.accept(v);
    value.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    value = v.transform(value);
    value.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    value = v.transform(value);
    value.parent = this;
  }

  @override
  String toString() {
    return "AbstractSuperPropertySet(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('super.{abstract}');
    printer.writeInterfaceMemberName(interfaceTargetReference, name);
    printer.write(' = ');
    printer.writeExpression(value);
  }
}

/// Expression of form `super.field = value`.
///
/// This may invoke a setter or assign a field.
///
/// Evaluates to the value of [value].
class SuperPropertySet extends Expression {
  Name name;
  Expression value;

  Reference interfaceTargetReference;

  SuperPropertySet(Name name, Expression value, Member interfaceTarget)
      : this.byReference(
            name, value, getNonNullableMemberReferenceSetter(interfaceTarget));

  SuperPropertySet.byReference(
      this.name, this.value, this.interfaceTargetReference) {
    value.parent = this;
  }

  Member get interfaceTarget => interfaceTargetReference.asMember;

  void set interfaceTarget(Member member) {
    interfaceTargetReference = getNonNullableMemberReferenceSetter(member);
  }

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) =>
      value.getStaticType(context);

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitSuperPropertySet(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitSuperPropertySet(this, arg);

  @override
  void visitChildren(Visitor v) {
    interfaceTarget.acceptReference(v);
    name.accept(v);
    value.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    value = v.transform(value);
    value.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    value = v.transform(value);
    value.parent = this;
  }

  @override
  String toString() {
    return "SuperPropertySet(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('super.');
    printer.writeInterfaceMemberName(interfaceTargetReference, name);
    printer.write(' = ');
    printer.writeExpression(value);
  }
}

/// Read a static field, call a static getter, or tear off a static method.
class StaticGet extends Expression {
  /// A static field, getter, or method (for tear-off).
  Reference targetReference;

  StaticGet(Member target)
      : assert(target is Field || (target is Procedure && target.isGetter)),
        this.targetReference = getNonNullableMemberReferenceGetter(target);

  StaticGet.byReference(this.targetReference);

  Member get target => targetReference.asMember;

  void set target(Member target) {
    targetReference = getNonNullableMemberReferenceGetter(target);
  }

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) =>
      target.getterType;

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitStaticGet(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitStaticGet(this, arg);

  @override
  void visitChildren(Visitor v) {
    target.acceptReference(v);
  }

  @override
  void transformChildren(Transformer v) {}

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {}

  @override
  String toString() {
    return "StaticGet(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeMemberName(targetReference);
  }
}

/// Tear-off of a static method.
class StaticTearOff extends Expression {
  Reference targetReference;

  StaticTearOff(Procedure target)
      : assert(target.isStatic, "Unexpected static tear off target: $target"),
        assert(target.kind == ProcedureKind.Method,
            "Unexpected static tear off target: $target"),
        this.targetReference = getNonNullableMemberReferenceGetter(target);

  StaticTearOff.byReference(this.targetReference);

  Procedure get target => targetReference.asProcedure;

  void set target(Procedure target) {
    targetReference = getNonNullableMemberReferenceGetter(target);
  }

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) =>
      target.getterType;

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitStaticTearOff(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitStaticTearOff(this, arg);

  @override
  void visitChildren(Visitor v) {
    target.acceptReference(v);
  }

  @override
  void transformChildren(Transformer v) {}

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {}

  @override
  String toString() {
    return "StaticTearOff(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeMemberName(targetReference);
  }
}

/// Assign a static field or call a static setter.
///
/// Evaluates to the value of [value].
class StaticSet extends Expression {
  /// A mutable static field or a static setter.
  Reference targetReference;
  Expression value;

  StaticSet(Member target, Expression value)
      : this.byReference(getNonNullableMemberReferenceSetter(target), value);

  StaticSet.byReference(this.targetReference, this.value) {
    value.parent = this;
  }

  Member get target => targetReference.asMember;

  void set target(Member target) {
    targetReference = getNonNullableMemberReferenceSetter(target);
  }

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) =>
      value.getStaticType(context);

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitStaticSet(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitStaticSet(this, arg);

  @override
  void visitChildren(Visitor v) {
    target.acceptReference(v);
    value.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    value = v.transform(value);
    value.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    value = v.transform(value);
    value.parent = this;
  }

  @override
  String toString() {
    return "StaticSet(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeMemberName(targetReference);
    printer.write(' = ');
    printer.writeExpression(value);
  }
}

/// The arguments to a function call, divided into type arguments,
/// positional arguments, and named arguments.
class Arguments extends TreeNode {
  final List<DartType> types;
  final List<Expression> positional;
  List<NamedExpression> named;

  Arguments(this.positional,
      {List<DartType>? types, List<NamedExpression>? named})
      : this.types = types ?? <DartType>[],
        this.named = named ?? <NamedExpression>[] {
    setParents(this.positional, this);
    setParents(this.named, this);
  }

  Arguments.empty()
      : types = <DartType>[],
        positional = <Expression>[],
        named = <NamedExpression>[];

  factory Arguments.forwarded(FunctionNode function, Library library) {
    return new Arguments(
        function.positionalParameters
            .map<Expression>((p) => new VariableGet(p))
            .toList(),
        named: function.namedParameters
            .map((p) => new NamedExpression(p.name!, new VariableGet(p)))
            .toList(),
        types: function.typeParameters
            .map<DartType>((p) =>
                new TypeParameterType.withDefaultNullabilityForLibrary(
                    p, library))
            .toList());
  }

  @override
  R accept<R>(TreeVisitor<R> v) => v.visitArguments(this);

  @override
  R accept1<R, A>(TreeVisitor1<R, A> v, A arg) => v.visitArguments(this, arg);

  @override
  void visitChildren(Visitor v) {
    visitList(types, v);
    visitList(positional, v);
    visitList(named, v);
  }

  @override
  void transformChildren(Transformer v) {
    v.transformDartTypeList(types);
    v.transformList(positional, this);
    v.transformList(named, this);
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    v.transformDartTypeList(types);
    v.transformExpressionList(positional, this);
    v.transformNamedExpressionList(named, this);
  }

  @override
  String toString() {
    return "Arguments(${toStringInternal()})";
  }

  @override
  String toText(AstTextStrategy strategy) {
    AstPrinter printer = new AstPrinter(strategy);
    printer.writeArguments(this);
    return printer.getText();
  }

  @override
  void toTextInternal(AstPrinter printer, {bool includeTypeArguments = true}) {
    if (includeTypeArguments) {
      printer.writeTypeArguments(types);
    }
    printer.write('(');
    for (int index = 0; index < positional.length; index++) {
      if (index > 0) {
        printer.write(', ');
      }
      printer.writeExpression(positional[index]);
    }
    if (named.isNotEmpty) {
      if (positional.isNotEmpty) {
        printer.write(', ');
      }
      for (int index = 0; index < named.length; index++) {
        if (index > 0) {
          printer.write(', ');
        }
        printer.writeNamedExpression(named[index]);
      }
    }
    printer.write(')');
  }
}

/// A named argument, `name: value`.
class NamedExpression extends TreeNode {
  String name;
  Expression value;

  NamedExpression(this.name, this.value) {
    value.parent = this;
  }

  @override
  R accept<R>(TreeVisitor<R> v) => v.visitNamedExpression(this);

  @override
  R accept1<R, A>(TreeVisitor1<R, A> v, A arg) =>
      v.visitNamedExpression(this, arg);

  @override
  void visitChildren(Visitor v) {
    value.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    value = v.transform(value);
    value.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    value = v.transform(value);
    value.parent = this;
  }

  @override
  String toString() {
    return "NamedExpression(${toStringInternal()})";
  }

  @override
  String toText(AstTextStrategy strategy) {
    AstPrinter printer = new AstPrinter(strategy);
    toTextInternal(printer);
    return printer.getText();
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write(name);
    printer.write(': ');
    printer.writeExpression(value);
  }
}

/// Common super class for [DirectMethodInvocation], [MethodInvocation],
/// [SuperMethodInvocation], [StaticInvocation], and [ConstructorInvocation].
abstract class InvocationExpression extends Expression {
  Arguments get arguments;

  /// Name of the invoked method.
  Name get name;
}

abstract class InstanceInvocationExpression extends InvocationExpression {
  Expression get receiver;
}

class DynamicInvocation extends InstanceInvocationExpression {
  // Must match serialized bit positions.
  static const int FlagImplicitCall = 1 << 0;

  final DynamicAccessKind kind;

  @override
  Expression receiver;

  @override
  Name name;

  @override
  Arguments arguments;

  int flags = 0;

  DynamicInvocation(this.kind, this.receiver, this.name, this.arguments) {
    receiver.parent = this;
    arguments.parent = this;
  }

  /// If `true` this is an implicit call to 'call'. For instance
  ///
  ///    method(dynamic d) {
  ///      d(); // Implicit call.
  ///      d.call(); // Explicit call.
  ///
  bool get isImplicitCall => flags & FlagImplicitCall != 0;

  void set isImplicitCall(bool value) {
    flags = value ? (flags | FlagImplicitCall) : (flags & ~FlagImplicitCall);
  }

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) {
    switch (kind) {
      case DynamicAccessKind.Dynamic:
        return const DynamicType();
      case DynamicAccessKind.Never:
        return const NeverType.nonNullable();
      case DynamicAccessKind.Invalid:
      case DynamicAccessKind.Unresolved:
        return const InvalidType();
    }
  }

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitDynamicInvocation(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitDynamicInvocation(this, arg);

  @override
  void visitChildren(Visitor v) {
    receiver.accept(v);
    name.accept(v);
    arguments.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    receiver = v.transform(receiver);
    receiver.parent = this;
    arguments = v.transform(arguments);
    arguments.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    receiver = v.transform(receiver);
    receiver.parent = this;
    arguments = v.transform(arguments);
    arguments.parent = this;
  }

  @override
  String toString() {
    return "DynamicInvocation($kind,${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(receiver,
        minimumPrecedence: astToText.Precedence.PRIMARY);
    if (!isImplicitCall) {
      printer.write('.');
      printer.writeName(name);
    }
    printer.writeArguments(arguments);
  }
}

/// Access kind used by [InstanceInvocation], [InstanceGet], [InstanceSet],
/// and [InstanceTearOff].
enum InstanceAccessKind {
  /// An access to a member on a static receiver type which is an interface
  /// type.
  ///
  /// In null safe libraries the static receiver type is non-nullable.
  ///
  /// For instance:
  ///
  ///     class C { void method() {} }
  ///     main() => new C().method();
  ///
  Instance,

  /// An access to a member defined on Object on a static receiver type that
  /// is either a non-interface type or a nullable type.
  ///
  /// For instance:
  ///
  ///     test1(String? s) => s.toString();
  ///     test1(dynamic s) => s.hashCode;
  ///
  Object,

  /// An access to a method on a static receiver type which is an interface
  /// type which is inapplicable, that is, whose arguments don't match the
  /// required parameter structure.
  ///
  /// This is an error case which is only used on expression nested within
  /// [InvalidExpression]s.
  ///
  /// For instance:
  ///
  ///     class C { void method() {} }
  ///     main() => new C().method(0); // Too many arguments.
  ///
  Inapplicable,

  /// An access to a non-Object member on a static receiver type which is a
  /// nullable interface type.
  ///
  /// This is an error case which is only used on expression nested within
  /// [InvalidExpression]s.
  ///
  /// For instance:
  ///
  ///     class C { void method() {} }
  ///     test(C? c) => c.method(0); // 'c' is nullable.
  ///
  Nullable,
}

/// An invocation of an instance method with a statically known interface
/// target.
class InstanceInvocation extends InstanceInvocationExpression {
  // Must match serialized bit positions.
  static const int FlagInvariant = 1 << 0;
  static const int FlagBoundsSafe = 1 << 1;

  final InstanceAccessKind kind;

  @override
  Expression receiver;

  // TODO(johnniwinther): Can we pull this from the [interfaceTarget] instead?
  @override
  Name name;

  @override
  Arguments arguments;

  int flags = 0;

  /// The static type of the invocation.
  ///
  /// This includes substituted type parameters from the static receiver type
  /// and generic type arguments.
  ///
  /// For instance
  ///
  ///    class A<T> {
  ///      Map<T, S> map<S>(S s) { ... }
  ///    }
  ///    m(A<String> a) {
  ///      a.map(0); // The function type is `Map<String, int> Function(int)`.
  ///    }
  ///
  FunctionType functionType;

  Reference interfaceTargetReference;

  InstanceInvocation(InstanceAccessKind kind, Expression receiver, Name name,
      Arguments arguments,
      {required Procedure interfaceTarget, required FunctionType functionType})
      : this.byReference(kind, receiver, name, arguments,
            interfaceTargetReference:
                getNonNullableMemberReferenceGetter(interfaceTarget),
            functionType: functionType);

  InstanceInvocation.byReference(
      this.kind, this.receiver, this.name, this.arguments,
      {required this.interfaceTargetReference, required this.functionType})
      : assert(functionType.typeParameters.isEmpty) {
    receiver.parent = this;
    arguments.parent = this;
  }

  Procedure get interfaceTarget => interfaceTargetReference.asProcedure;

  void set interfaceTarget(Procedure target) {
    interfaceTargetReference = getNonNullableMemberReferenceGetter(target);
  }

  /// If `true`, this call is known to be safe wrt. parameter covariance checks.
  ///
  /// This is for instance the case in code patterns like this
  ///
  ///     List<int> list = <int>[];
  ///     list.add(0);
  ///
  /// where the `list` variable is known to hold a value of the same type as
  /// the static type. In contrast the would not be the case in code patterns
  /// like this
  ///
  ///     List<num> list = <double>[];
  ///     list.add(0); // Runtime error `int` is not a subtype of `double`.
  ///
  bool get isInvariant => flags & FlagInvariant != 0;

  void set isInvariant(bool value) {
    flags = value ? (flags | FlagInvariant) : (flags & ~FlagInvariant);
  }

  /// If `true`, this call is known to be safe wrt. parameter covariance checks.
  ///
  /// This is for instance the case in code patterns like this
  ///
  ///     List list = new List.filled(2, 0);
  ///     list[1] = 42;
  ///
  /// where the `list` is known to have a sufficient length for the update
  /// in `list[1] = 42`.
  bool get isBoundsSafe => flags & FlagBoundsSafe != 0;

  void set isBoundsSafe(bool value) {
    flags = value ? (flags | FlagBoundsSafe) : (flags & ~FlagBoundsSafe);
  }

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) =>
      functionType.returnType;

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitInstanceInvocation(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitInstanceInvocation(this, arg);

  @override
  void visitChildren(Visitor v) {
    receiver.accept(v);
    interfaceTarget.acceptReference(v);
    name.accept(v);
    arguments.accept(v);
    functionType.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    receiver = v.transform(receiver);
    receiver.parent = this;
    arguments = v.transform(arguments);
    arguments.parent = this;
    functionType = v.visitDartType(functionType) as FunctionType;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    receiver = v.transform(receiver);
    receiver.parent = this;
    arguments = v.transform(arguments);
    arguments.parent = this;
    functionType =
        v.visitDartType(functionType, cannotRemoveSentinel) as FunctionType;
  }

  @override
  String toString() {
    return "InstanceInvocation($kind, ${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(receiver,
        minimumPrecedence: astToText.Precedence.PRIMARY);
    printer.write('.');
    printer.writeInterfaceMemberName(interfaceTargetReference, name);
    printer.writeArguments(arguments);
  }
}

/// An invocation of an instance getter or field with a statically known
/// interface target.
///
/// This is used only for web backend in order to support invocation of
/// native properties as functions. This node will be removed when this
/// invocation style is no longer supported.
class InstanceGetterInvocation extends InstanceInvocationExpression {
  // Must match serialized bit positions.
  static const int FlagInvariant = 1 << 0;
  static const int FlagBoundsSafe = 1 << 1;

  final InstanceAccessKind kind;

  @override
  Expression receiver;

  @override
  Name name;

  @override
  Arguments arguments;

  int flags = 0;

  /// The static type of the invocation, or `dynamic` is of the type is unknown.
  ///
  /// This includes substituted type parameters from the static receiver type
  /// and generic type arguments.
  ///
  /// For instance
  ///
  ///    class A<T> {
  ///      Map<T, S> Function<S>(S) get map => ...
  ///      dynamic get dyn => ...
  ///    }
  ///    m(A<String> a) {
  ///      a.map(0); // The function type is `Map<String, int> Function(int)`.
  ///      a.dyn(0); // The function type is `null`.
  ///    }
  ///
  FunctionType? functionType;

  Reference interfaceTargetReference;

  InstanceGetterInvocation(InstanceAccessKind kind, Expression receiver,
      Name name, Arguments arguments,
      {required Member interfaceTarget, required FunctionType? functionType})
      : this.byReference(kind, receiver, name, arguments,
            interfaceTargetReference:
                getNonNullableMemberReferenceGetter(interfaceTarget),
            functionType: functionType);

  InstanceGetterInvocation.byReference(
      this.kind, this.receiver, this.name, this.arguments,
      {required this.interfaceTargetReference, required this.functionType})
      : assert(functionType == null || functionType.typeParameters.isEmpty) {
    receiver.parent = this;
    arguments.parent = this;
  }

  Member get interfaceTarget => interfaceTargetReference.asMember;

  void set interfaceTarget(Member target) {
    interfaceTargetReference = getNonNullableMemberReferenceGetter(target);
  }

  /// If `true`, this call is known to be safe wrt. parameter covariance checks.
  ///
  /// This is for instance the case in code patterns like this
  ///
  ///     List<int> list = <int>[];
  ///     list.add(0);
  ///
  /// where the `list` variable is known to hold a value of the same type as
  /// the static type. In contrast the would not be the case in code patterns
  /// like this
  ///
  ///     List<num> list = <double>[];
  ///     list.add(0); // Runtime error `int` is not a subtype of `double`.
  ///
  bool get isInvariant => flags & FlagInvariant != 0;

  void set isInvariant(bool value) {
    flags = value ? (flags | FlagInvariant) : (flags & ~FlagInvariant);
  }

  /// If `true`, this call is known to be safe wrt. parameter covariance checks.
  ///
  /// This is for instance the case in code patterns like this
  ///
  ///     List list = new List.filled(2, 0);
  ///     list[1] = 42;
  ///
  /// where the `list` is known to have a sufficient length for the update
  /// in `list[1] = 42`.
  bool get isBoundsSafe => flags & FlagBoundsSafe != 0;

  void set isBoundsSafe(bool value) {
    flags = value ? (flags | FlagBoundsSafe) : (flags & ~FlagBoundsSafe);
  }

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) =>
      functionType?.returnType ?? const DynamicType();

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitInstanceGetterInvocation(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitInstanceGetterInvocation(this, arg);

  @override
  void visitChildren(Visitor v) {
    receiver.accept(v);
    interfaceTarget.acceptReference(v);
    name.accept(v);
    arguments.accept(v);
    functionType?.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    receiver = v.transform(receiver);
    receiver.parent = this;
    arguments = v.transform(arguments);
    arguments.parent = this;

    if (functionType != null) {
      functionType = v.visitDartType(functionType!) as FunctionType;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    receiver = v.transform(receiver);
    receiver.parent = this;
    arguments = v.transform(arguments);
    arguments.parent = this;
    if (functionType != null) {
      functionType =
          v.visitDartType(functionType!, cannotRemoveSentinel) as FunctionType;
    }
  }

  @override
  String toString() {
    return "InstanceGetterInvocation($kind, ${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(receiver,
        minimumPrecedence: astToText.Precedence.PRIMARY);
    printer.write('.');
    printer.writeInterfaceMemberName(interfaceTargetReference, name);
    printer.writeArguments(arguments);
  }
}

/// Access kind used by [FunctionInvocation] and [FunctionTearOff].
enum FunctionAccessKind {
  /// An access to the 'call' method on an expression of static type `Function`.
  ///
  /// For instance
  ///
  ///     method(Function f) => f();
  ///
  Function,

  /// An access to the 'call' method on an expression whose static type is a
  /// function type.
  ///
  /// For instance
  ///
  ///     method(void Function() f) => f();
  ///
  FunctionType,

  /// An access to the 'call' method on an expression whose static type is a
  /// function type which is inapplicable, that is, whose arguments don't match
  /// the required parameter structure.
  ///
  /// This is an error case which is only used on expression nested within
  /// [InvalidExpression]s.
  ///
  /// For instance:
  ///
  ///     test(void Function() f) => f(0); // Too many arguments.
  ///
  Inapplicable,

  /// An access to the 'call' method on an expression whose static type is a
  /// nullable function type or `Function?`.
  ///
  /// This is an error case which is only used on expression nested within
  /// [InvalidExpression]s.
  ///
  /// For instance:
  ///
  ///     test(void Function()? f) => f(); // 'f' is nullable.
  ///
  Nullable,
}

/// An invocation of the 'call' method on an expression whose static type is
/// a function type or the type 'Function'.
class FunctionInvocation extends InstanceInvocationExpression {
  final FunctionAccessKind kind;

  @override
  Expression receiver;

  @override
  Arguments arguments;

  /// The static type of the invocation.
  ///
  /// This is `null` if the static type of the receiver is not a function type
  /// or is not bounded by a function type.
  ///
  /// For instance
  ///
  ///    m<T extends Function, S extends int Function()>(T t, S s, Function f) {
  ///      X local<X>(X t) => t;
  ///      t(); // The function type is `null`.
  ///      s(); // The function type is `int Function()`.
  ///      f(); // The function type is `null`.
  ///      local(0); // The function type is `int Function(int)`.
  ///    }
  ///
  FunctionType? functionType;

  FunctionInvocation(this.kind, this.receiver, this.arguments,
      {required this.functionType}) {
    receiver.parent = this;
    arguments.parent = this;
  }

  @override
  Name get name => Name.callName;

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) =>
      functionType?.returnType ?? const DynamicType();

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitFunctionInvocation(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitFunctionInvocation(this, arg);

  @override
  void visitChildren(Visitor v) {
    receiver.accept(v);
    name.accept(v);
    arguments.accept(v);
    functionType?.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    receiver = v.transform(receiver);
    receiver.parent = this;
    arguments = v.transform(arguments);
    arguments.parent = this;
    FunctionType? type = functionType;
    if (type != null) {
      functionType = v.visitDartType(type) as FunctionType;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    receiver = v.transform(receiver);
    receiver.parent = this;
    arguments = v.transform(arguments);
    arguments.parent = this;
    FunctionType? type = functionType;
    if (type != null) {
      functionType =
          v.visitDartType(type, cannotRemoveSentinel) as FunctionType;
    }
  }

  @override
  String toString() {
    return "FunctionInvocation(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(receiver,
        minimumPrecedence: astToText.Precedence.PRIMARY);
    printer.writeArguments(arguments);
  }
}

/// An invocation of a local function declaration.
class LocalFunctionInvocation extends InvocationExpression {
  /// The variable declaration for the function declaration.
  VariableDeclaration variable;

  @override
  Arguments arguments;

  /// The static type of the invocation.
  ///
  /// This might differ from the static type of [variable] for generic
  /// functions.
  ///
  /// For instance
  ///
  ///    m() {
  ///      T local<T>(T t) => t;
  ///      local(0); // The static type is `int Function(int)`.
  ///    }
  ///
  FunctionType functionType;

  LocalFunctionInvocation(this.variable, this.arguments,
      {required this.functionType}) {
    arguments.parent = this;
  }

  /// The declaration for the invoked local function.
  FunctionDeclaration get localFunction =>
      variable.parent as FunctionDeclaration;

  @override
  Name get name => Name.callName;

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) =>
      functionType.returnType;

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitLocalFunctionInvocation(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitLocalFunctionInvocation(this, arg);

  @override
  void visitChildren(Visitor v) {
    arguments.accept(v);
    functionType.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    arguments = v.transform(arguments);
    arguments.parent = this;
    functionType = v.visitDartType(functionType) as FunctionType;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    arguments = v.transform(arguments);
    arguments.parent = this;
    functionType =
        v.visitDartType(functionType, cannotRemoveSentinel) as FunctionType;
  }

  @override
  String toString() {
    return "LocalFunctionInvocation(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write(printer.getVariableName(variable));
    printer.writeArguments(arguments);
  }
}

/// Nullness test of an expression, that is `e == null`.
///
/// This is generated for code like `e1 == e2` where `e1` or `e2` is `null`.
class EqualsNull extends Expression {
  /// The expression tested for nullness.
  Expression expression;

  EqualsNull(this.expression) {
    expression.parent = this;
  }

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) =>
      context.typeEnvironment.coreTypes.boolRawType(context.nonNullable);

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitEqualsNull(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitEqualsNull(this, arg);

  @override
  void visitChildren(Visitor v) {
    expression.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    expression = v.transform(expression);
    expression.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    expression = v.transform(expression);
    expression.parent = this;
  }

  @override
  String toString() {
    return "EqualsNull(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(expression, minimumPrecedence: precedence);
    printer.write(' == null');
  }
}

/// A test of equality, that is `e1 == e2`.
///
/// This is generated for code like `e1 == e2` where neither `e1` nor `e2` is
/// `null`.
class EqualsCall extends Expression {
  Expression left;
  Expression right;

  /// The static type of the invocation.
  ///
  /// This might differ from the static type of [Object.==] for covariant
  /// parameters.
  ///
  /// For instance
  ///
  ///    class C<T> {
  ///      bool operator(covariant C<T> other) { ... }
  ///    }
  ///    // The function type is `bool Function(C<num>)`.
  ///    method(C<num> a, C<int> b) => a == b;
  ///
  FunctionType functionType;

  Reference interfaceTargetReference;

  EqualsCall(Expression left, Expression right,
      {required FunctionType functionType, required Procedure interfaceTarget})
      : this.byReference(left, right,
            functionType: functionType,
            interfaceTargetReference:
                getNonNullableMemberReferenceGetter(interfaceTarget));

  EqualsCall.byReference(this.left, this.right,
      {required this.functionType, required this.interfaceTargetReference}) {
    left.parent = this;
    right.parent = this;
  }

  Procedure get interfaceTarget => interfaceTargetReference.asProcedure;

  void set interfaceTarget(Procedure target) {
    interfaceTargetReference = getNonNullableMemberReferenceGetter(target);
  }

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) {
    return functionType.returnType;
  }

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitEqualsCall(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitEqualsCall(this, arg);

  @override
  void visitChildren(Visitor v) {
    left.accept(v);
    interfaceTarget.acceptReference(v);
    right.accept(v);
    functionType.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    left = v.transform(left);
    left.parent = this;
    right = v.transform(right);
    right.parent = this;
    functionType = v.visitDartType(functionType) as FunctionType;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    left = v.transform(left);
    left.parent = this;
    right = v.transform(right);
    right.parent = this;
    functionType =
        v.visitDartType(functionType, cannotRemoveSentinel) as FunctionType;
  }

  @override
  String toString() {
    return "EqualsCall(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    int minimumPrecedence = precedence;
    printer.writeExpression(left, minimumPrecedence: minimumPrecedence);
    printer.write(' == ');
    printer.writeExpression(right, minimumPrecedence: minimumPrecedence + 1);
  }
}

/// Expression of form `super.foo(x)` occurring in a mixin declaration.
///
/// In this setting, the target is looked up on the types in the mixin 'on'
/// clause and are therefore not necessary the runtime targets of the
/// invocation. An [AbstractSuperMethodInvocation] must be converted into
/// a [SuperMethodInvocation] to statically bind the target.
///
/// For instance
///
///    abstract class Interface {
///      void method();
///    }
///    mixin Mixin on Interface {
///      void method() {
///        // This is an [AbstractSuperMethodInvocation] with interface target
///        // `Interface.method`.
///        super.method(); // This targets Super.method.
///      }
///    }
///    class Super implements Interface {
///      // This is the target when `Mixin` is applied to `Class`.
///      void method() {}
///    }
///    class Class extends Super with Mixin {}
///
class AbstractSuperMethodInvocation extends InvocationExpression {
  @override
  Name name;

  @override
  Arguments arguments;

  Reference interfaceTargetReference;

  AbstractSuperMethodInvocation(
      Name name, Arguments arguments, Procedure interfaceTarget)
      : this.byReference(
            name,
            arguments,
            // An invocation doesn't refer to the setter.
            getNonNullableMemberReferenceGetter(interfaceTarget));

  AbstractSuperMethodInvocation.byReference(
      this.name, this.arguments, this.interfaceTargetReference) {
    arguments.parent = this;
  }

  Procedure get interfaceTarget => interfaceTargetReference.asProcedure;

  void set interfaceTarget(Procedure target) {
    // An invocation doesn't refer to the setter.
    interfaceTargetReference = getNonNullableMemberReferenceGetter(target);
  }

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) {
    Class superclass = interfaceTarget.enclosingClass!;
    List<DartType>? receiverTypeArguments = context.typeEnvironment
        .getTypeArgumentsAsInstanceOf(context.thisType!, superclass);
    DartType returnType = Substitution.fromPairs(
            superclass.typeParameters, receiverTypeArguments!)
        .substituteType(interfaceTarget.function.returnType);
    return Substitution.fromPairs(
            interfaceTarget.function.typeParameters, arguments.types)
        .substituteType(returnType);
  }

  @override
  R accept<R>(ExpressionVisitor<R> v) =>
      v.visitAbstractSuperMethodInvocation(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitAbstractSuperMethodInvocation(this, arg);

  @override
  void visitChildren(Visitor v) {
    interfaceTarget.acceptReference(v);
    name.accept(v);
    arguments.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    arguments = v.transform(arguments);
    arguments.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    arguments = v.transform(arguments);
    arguments.parent = this;
  }

  @override
  String toString() {
    return "AbstractSuperMethodInvocation(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('super.{abstract}');
    printer.writeInterfaceMemberName(interfaceTargetReference, name);
    printer.writeArguments(arguments);
  }
}

/// Expression of form `super.foo(x)`.
///
/// The provided arguments might not match the parameters of the target.
class SuperMethodInvocation extends InvocationExpression {
  @override
  Name name;

  @override
  Arguments arguments;

  Reference interfaceTargetReference;

  SuperMethodInvocation(
      Name name, Arguments arguments, Procedure interfaceTarget)
      : this.byReference(
            name,
            arguments,
            // An invocation doesn't refer to the setter.
            getNonNullableMemberReferenceGetter(interfaceTarget));

  SuperMethodInvocation.byReference(
      this.name, this.arguments, this.interfaceTargetReference) {
    arguments.parent = this;
  }

  Procedure get interfaceTarget => interfaceTargetReference.asProcedure;

  void set interfaceTarget(Procedure target) {
    // An invocation doesn't refer to the setter.
    interfaceTargetReference = getNonNullableMemberReferenceGetter(target);
  }

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) {
    Class superclass = interfaceTarget.enclosingClass!;
    List<DartType>? receiverTypeArguments = context.typeEnvironment
        .getTypeArgumentsAsInstanceOf(context.thisType!, superclass);
    DartType returnType = Substitution.fromPairs(
            superclass.typeParameters, receiverTypeArguments!)
        .substituteType(interfaceTarget.function.returnType);
    return Substitution.fromPairs(
            interfaceTarget.function.typeParameters, arguments.types)
        .substituteType(returnType);
  }

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitSuperMethodInvocation(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitSuperMethodInvocation(this, arg);

  @override
  void visitChildren(Visitor v) {
    interfaceTarget.acceptReference(v);
    name.accept(v);
    arguments.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    arguments = v.transform(arguments);
    arguments.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    arguments = v.transform(arguments);
    arguments.parent = this;
  }

  @override
  String toString() {
    return "SuperMethodInvocation(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('super.');
    printer.writeInterfaceMemberName(interfaceTargetReference, name);
    printer.writeArguments(arguments);
  }
}

/// Expression of form `foo(x)`, or `const foo(x)` if the target is an
/// external constant factory.
///
/// The provided arguments might not match the parameters of the target.
class StaticInvocation extends InvocationExpression {
  Reference targetReference;

  @override
  Arguments arguments;

  /// True if this is a constant call to an external constant factory.
  bool isConst;

  @override
  Name get name => target.name;

  StaticInvocation(Procedure target, Arguments arguments,
      {bool isConst = false})
      : this.byReference(
            // An invocation doesn't refer to the setter.
            getNonNullableMemberReferenceGetter(target),
            arguments,
            isConst: isConst);

  StaticInvocation.byReference(this.targetReference, this.arguments,
      {this.isConst = false}) {
    arguments.parent = this;
  }

  Procedure get target => targetReference.asProcedure;

  void set target(Procedure target) {
    // An invocation doesn't refer to the setter.
    targetReference = getNonNullableMemberReferenceGetter(target);
  }

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) {
    return Substitution.fromPairs(
            target.function.typeParameters, arguments.types)
        .substituteType(target.function.returnType);
  }

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitStaticInvocation(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitStaticInvocation(this, arg);

  @override
  void visitChildren(Visitor v) {
    target.acceptReference(v);
    arguments.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    arguments = v.transform(arguments);
    arguments.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    arguments = v.transform(arguments);
    arguments.parent = this;
  }

  @override
  String toString() {
    return "StaticInvocation(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeMemberName(targetReference);
    printer.writeArguments(arguments);
  }
}

/// Expression of form `new Foo(x)` or `const Foo(x)`.
///
/// The provided arguments might not match the parameters of the target.
//
// DESIGN TODO: Should we pass type arguments in a separate field
// `classTypeArguments`? They are quite different from type arguments to
// generic functions.
class ConstructorInvocation extends InvocationExpression {
  Reference targetReference;

  @override
  Arguments arguments;

  bool isConst;

  @override
  Name get name => target.name;

  ConstructorInvocation(Constructor target, Arguments arguments,
      {bool isConst = false})
      : this.byReference(
            // A constructor doesn't refer to the setter.
            getNonNullableMemberReferenceGetter(target),
            arguments,
            isConst: isConst);

  ConstructorInvocation.byReference(this.targetReference, this.arguments,
      {this.isConst = false}) {
    arguments.parent = this;
  }

  Constructor get target => targetReference.asConstructor;

  void set target(Constructor target) {
    // A constructor doesn't refer to the setter.
    targetReference = getNonNullableMemberReferenceGetter(target);
  }

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) {
    return arguments.types.isEmpty
        ? context.typeEnvironment.coreTypes
            .rawType(target.enclosingClass, context.nonNullable)
        : new InterfaceType(
            target.enclosingClass, context.nonNullable, arguments.types);
  }

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitConstructorInvocation(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitConstructorInvocation(this, arg);

  @override
  void visitChildren(Visitor v) {
    target.acceptReference(v);
    arguments.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    arguments = v.transform(arguments);
    arguments.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    arguments = v.transform(arguments);
    arguments.parent = this;
  }

  // TODO(cstefantsova): Change the getter into a method that accepts a
  // CoreTypes.
  InterfaceType get constructedType {
    Class enclosingClass = target.enclosingClass;
    // TODO(cstefantsova): Get raw type from a CoreTypes object if arguments is
    // empty.
    return arguments.types.isEmpty
        ? new InterfaceType(enclosingClass, target.enclosingLibrary.nonNullable,
            const <DartType>[])
        : new InterfaceType(enclosingClass, target.enclosingLibrary.nonNullable,
            arguments.types);
  }

  @override
  String toString() {
    return "ConstructorInvocation(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    if (isConst) {
      printer.write('const ');
    } else {
      printer.write('new ');
    }
    printer.writeClassName(target.enclosingClass.reference);
    printer.writeTypeArguments(arguments.types);
    if (target.name.text.isNotEmpty) {
      printer.write('.');
      printer.write(target.name.text);
    }
    printer.writeArguments(arguments, includeTypeArguments: false);
  }
}

/// An explicit type instantiation of a generic function.
class Instantiation extends Expression {
  Expression expression;
  final List<DartType> typeArguments;

  Instantiation(this.expression, this.typeArguments) {
    expression.parent = this;
  }

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) {
    DartType type = expression.getStaticType(context);
    if (type is FunctionType) {
      return FunctionTypeInstantiator.instantiate(type, typeArguments);
    }
    assert(type is InvalidType || type is NeverType,
        "Unexpected operand type $type for $expression");
    return type;
  }

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitInstantiation(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitInstantiation(this, arg);

  @override
  void visitChildren(Visitor v) {
    expression.accept(v);
    visitList(typeArguments, v);
  }

  @override
  void transformChildren(Transformer v) {
    expression = v.transform(expression);
    expression.parent = this;

    v.transformDartTypeList(typeArguments);
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    expression = v.transform(expression);
    expression.parent = this;

    v.transformDartTypeList(typeArguments);
  }

  @override
  String toString() {
    return "Instantiation(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(expression);
    printer.writeTypeArguments(typeArguments);
  }
}

/// Expression of form `!x`.
///
/// The `is!` and `!=` operators are desugared into [Not] nodes with `is` and
/// `==` expressions inside, respectively.
class Not extends Expression {
  Expression operand;

  Not(this.operand) {
    operand.parent = this;
  }

  @override
  DartType getStaticType(StaticTypeContext context) =>
      getStaticTypeInternal(context);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) =>
      context.typeEnvironment.coreTypes.boolRawType(context.nonNullable);

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitNot(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) => v.visitNot(this, arg);

  @override
  void visitChildren(Visitor v) {
    operand.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    operand = v.transform(operand);
    operand.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    operand = v.transform(operand);
    operand.parent = this;
  }

  @override
  String toString() {
    return "Not(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('!');
    printer.writeExpression(operand,
        minimumPrecedence: astToText.Precedence.PREFIX);
  }
}

enum LogicalExpressionOperator { AND, OR }

String logicalExpressionOperatorToString(LogicalExpressionOperator operator) {
  switch (operator) {
    case LogicalExpressionOperator.AND:
      return "&&";
    case LogicalExpressionOperator.OR:
      return "||";
  }
}

/// Expression of form `x && y` or `x || y`
class LogicalExpression extends Expression {
  Expression left;
  LogicalExpressionOperator operatorEnum; // AND (&&) or OR (||).
  Expression right;

  LogicalExpression(this.left, this.operatorEnum, this.right) {
    left.parent = this;
    right.parent = this;
  }

  @override
  DartType getStaticType(StaticTypeContext context) =>
      getStaticTypeInternal(context);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) =>
      context.typeEnvironment.coreTypes.boolRawType(context.nonNullable);

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitLogicalExpression(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitLogicalExpression(this, arg);

  @override
  void visitChildren(Visitor v) {
    left.accept(v);
    right.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    left = v.transform(left);
    left.parent = this;
    right = v.transform(right);
    right.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    left = v.transform(left);
    left.parent = this;
    right = v.transform(right);
    right.parent = this;
  }

  @override
  String toString() {
    return "LogicalExpression(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    int minimumPrecedence = precedence;
    printer.writeExpression(left, minimumPrecedence: minimumPrecedence);
    printer.write(' ${logicalExpressionOperatorToString(operatorEnum)} ');
    printer.writeExpression(right, minimumPrecedence: minimumPrecedence + 1);
  }
}

/// Expression of form `x ? y : z`.
class ConditionalExpression extends Expression {
  Expression condition;
  Expression then;
  Expression otherwise;

  /// The static type of the expression.
  DartType staticType;

  ConditionalExpression(
      this.condition, this.then, this.otherwise, this.staticType) {
    condition.parent = this;
    then.parent = this;
    otherwise.parent = this;
  }

  @override
  DartType getStaticType(StaticTypeContext context) =>
      getStaticTypeInternal(context);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) => staticType;

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitConditionalExpression(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitConditionalExpression(this, arg);

  @override
  void visitChildren(Visitor v) {
    condition.accept(v);
    then.accept(v);
    otherwise.accept(v);
    staticType.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    condition = v.transform(condition);
    condition.parent = this;
    then = v.transform(then);
    then.parent = this;
    otherwise = v.transform(otherwise);
    otherwise.parent = this;
    staticType = v.visitDartType(staticType);
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    condition = v.transform(condition);
    condition.parent = this;
    then = v.transform(then);
    then.parent = this;
    otherwise = v.transform(otherwise);
    otherwise.parent = this;
    staticType = v.visitDartType(staticType, cannotRemoveSentinel);
  }

  @override
  String toString() {
    return "ConditionalExpression(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(condition,
        minimumPrecedence: astToText.Precedence.LOGICAL_OR);
    printer.write(' ?');
    printer.write('{');
    printer.writeType(staticType);
    printer.write('}');
    printer.write(' ');
    printer.writeExpression(then);
    printer.write(' : ');
    printer.writeExpression(otherwise);
  }
}

/// Convert expressions to strings and concatenate them.  Semantically, calls
/// `toString` on every argument, checks that a string is returned, and returns
/// the concatenation of all the strings.
///
/// If [expressions] is empty then an empty string is returned.
///
/// These arise from string interpolations and adjacent string literals.
class StringConcatenation extends Expression {
  final List<Expression> expressions;

  StringConcatenation(this.expressions) {
    setParents(expressions, this);
  }

  @override
  DartType getStaticType(StaticTypeContext context) =>
      getStaticTypeInternal(context);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) =>
      context.typeEnvironment.coreTypes.stringRawType(context.nonNullable);

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitStringConcatenation(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitStringConcatenation(this, arg);

  @override
  void visitChildren(Visitor v) {
    visitList(expressions, v);
  }

  @override
  void transformChildren(Transformer v) {
    v.transformList(expressions, this);
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    v.transformExpressionList(expressions, this);
  }

  @override
  String toString() {
    return "StringConcatenation(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('"');
    for (Expression part in expressions) {
      if (part is StringLiteral) {
        printer.write(escapeString(part.value));
      } else {
        printer.write(r'${');
        printer.writeExpression(part);
        printer.write('}');
      }
    }
    printer.write('"');
  }
}

/// Concatenate lists into a single list.
///
/// If [lists] is empty then an empty list is returned.
///
/// These arise from spread and control-flow elements in const list literals.
/// They are only present before constant evaluation, or within unevaluated
/// constants in constant expressions.
class ListConcatenation extends Expression {
  DartType typeArgument;
  final List<Expression> lists;

  ListConcatenation(this.lists, {this.typeArgument = const DynamicType()}) {
    setParents(lists, this);
  }

  @override
  DartType getStaticType(StaticTypeContext context) =>
      getStaticTypeInternal(context);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) {
    return context.typeEnvironment.listType(typeArgument, context.nonNullable);
  }

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitListConcatenation(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitListConcatenation(this, arg);

  @override
  void visitChildren(Visitor v) {
    typeArgument.accept(v);
    visitList(lists, v);
  }

  @override
  void transformChildren(Transformer v) {
    typeArgument = v.visitDartType(typeArgument);
    v.transformList(lists, this);
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    typeArgument = v.visitDartType(typeArgument, cannotRemoveSentinel);
    v.transformExpressionList(lists, this);
  }

  @override
  String toString() {
    return "ListConcatenation(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    bool first = true;
    for (Expression part in lists) {
      if (!first) {
        printer.write(' + ');
      }
      printer.writeExpression(part);
      first = false;
    }
  }
}

/// Concatenate sets into a single set.
///
/// If [sets] is empty then an empty set is returned.
///
/// These arise from spread and control-flow elements in const set literals.
/// They are only present before constant evaluation, or within unevaluated
/// constants in constant expressions.
///
/// Duplicated values in or across the sets will result in a compile-time error
/// during constant evaluation.
class SetConcatenation extends Expression {
  DartType typeArgument;
  final List<Expression> sets;

  SetConcatenation(this.sets, {this.typeArgument = const DynamicType()}) {
    setParents(sets, this);
  }

  @override
  DartType getStaticType(StaticTypeContext context) =>
      getStaticTypeInternal(context);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) {
    return context.typeEnvironment.setType(typeArgument, context.nonNullable);
  }

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitSetConcatenation(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitSetConcatenation(this, arg);

  @override
  void visitChildren(Visitor v) {
    typeArgument.accept(v);
    visitList(sets, v);
  }

  @override
  void transformChildren(Transformer v) {
    typeArgument = v.visitDartType(typeArgument);
    v.transformList(sets, this);
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    typeArgument = v.visitDartType(typeArgument, cannotRemoveSentinel);
    v.transformExpressionList(sets, this);
  }

  @override
  String toString() {
    return "SetConcatenation(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    bool first = true;
    for (Expression part in sets) {
      if (!first) {
        printer.write(' + ');
      }
      printer.writeExpression(part);
      first = false;
    }
  }
}

/// Concatenate maps into a single map.
///
/// If [maps] is empty then an empty map is returned.
///
/// These arise from spread and control-flow elements in const map literals.
/// They are only present before constant evaluation, or within unevaluated
/// constants in constant expressions.
///
/// Duplicated keys in or across the maps will result in a compile-time error
/// during constant evaluation.
class MapConcatenation extends Expression {
  DartType keyType;
  DartType valueType;
  final List<Expression> maps;

  MapConcatenation(this.maps,
      {this.keyType = const DynamicType(),
      this.valueType = const DynamicType()}) {
    setParents(maps, this);
  }

  @override
  DartType getStaticType(StaticTypeContext context) =>
      getStaticTypeInternal(context);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) {
    return context.typeEnvironment
        .mapType(keyType, valueType, context.nonNullable);
  }

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitMapConcatenation(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitMapConcatenation(this, arg);

  @override
  void visitChildren(Visitor v) {
    keyType.accept(v);
    valueType.accept(v);
    visitList(maps, v);
  }

  @override
  void transformChildren(Transformer v) {
    keyType = v.visitDartType(keyType);
    valueType = v.visitDartType(valueType);
    v.transformList(maps, this);
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    keyType = v.visitDartType(keyType, cannotRemoveSentinel);
    valueType = v.visitDartType(valueType, cannotRemoveSentinel);
    v.transformExpressionList(maps, this);
  }

  @override
  String toString() {
    return "MapConcatenation(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    bool first = true;
    for (Expression part in maps) {
      if (!first) {
        printer.write(' + ');
      }
      printer.writeExpression(part);
      first = false;
    }
  }
}

/// Create an instance directly from the field values.
///
/// These expressions arise from const constructor calls when one or more field
/// initializing expressions, field initializers, assert initializers or unused
/// arguments contain unevaluated expressions. They only ever occur within
/// unevaluated constants in constant expressions.
class InstanceCreation extends Expression {
  final Reference classReference;
  final List<DartType> typeArguments;
  final Map<Reference, Expression> fieldValues;
  final List<AssertStatement> asserts;
  final List<Expression> unusedArguments;

  InstanceCreation(this.classReference, this.typeArguments, this.fieldValues,
      this.asserts, this.unusedArguments) {
    setParents(fieldValues.values.toList(), this);
    setParents(asserts, this);
    setParents(unusedArguments, this);
  }

  Class get classNode => classReference.asClass;

  @override
  DartType getStaticType(StaticTypeContext context) =>
      getStaticTypeInternal(context);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) {
    return typeArguments.isEmpty
        ? context.typeEnvironment.coreTypes
            .rawType(classNode, context.nonNullable)
        : new InterfaceType(classNode, context.nonNullable, typeArguments);
  }

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitInstanceCreation(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitInstanceCreation(this, arg);

  @override
  void visitChildren(Visitor v) {
    classReference.asClass.acceptReference(v);
    visitList(typeArguments, v);
    for (final Reference reference in fieldValues.keys) {
      reference.asField.acceptReference(v);
    }
    for (final Expression value in fieldValues.values) {
      value.accept(v);
    }
    visitList(asserts, v);
    visitList(unusedArguments, v);
  }

  @override
  void transformChildren(Transformer v) {
    fieldValues.forEach((Reference fieldRef, Expression value) {
      Expression transformed = v.transform(value);
      if (!identical(value, transformed)) {
        fieldValues[fieldRef] = transformed;
        transformed.parent = this;
      }
    });
    v.transformList(asserts, this);
    v.transformList(unusedArguments, this);
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    fieldValues.forEach((Reference fieldRef, Expression value) {
      Expression transformed = v.transform(value);
      if (!identical(value, transformed)) {
        fieldValues[fieldRef] = transformed;
        transformed.parent = this;
      }
    });
    v.transformList(asserts, this, dummyAssertStatement);
    v.transformExpressionList(unusedArguments, this);
  }

  @override
  String toString() {
    return "InstanceCreation(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeClassName(classReference);
    printer.writeTypeArguments(typeArguments);
    printer.write('{');
    bool first = true;
    fieldValues.forEach((Reference fieldRef, Expression value) {
      if (!first) {
        printer.write(', ');
      }
      printer.writeName(fieldRef.asField.name);
      printer.write(': ');
      printer.writeExpression(value);
      first = false;
    });
    for (AssertStatement assert_ in asserts) {
      if (!first) {
        printer.write(', ');
      }
      printer.write('assert(');
      printer.writeExpression(assert_.condition);
      if (assert_.message != null) {
        printer.write(', ');
        printer.writeExpression(assert_.message!);
      }
      printer.write(')');
      first = false;
    }
    for (Expression unusedArgument in unusedArguments) {
      if (!first) {
        printer.write(', ');
      }
      printer.writeExpression(unusedArgument);
      first = false;
    }
    printer.write('}');
  }
}

/// A marker indicating that a subexpression originates in a different source
/// file than the surrounding context.
///
/// These expressions arise from inlining of const variables during constant
/// evaluation. They only ever occur within unevaluated constants in constant
/// expressions.
class FileUriExpression extends Expression implements FileUriNode {
  /// The URI of the source file in which the subexpression is located.
  /// Can be different from the file containing the [FileUriExpression].
  @override
  Uri fileUri;

  Expression expression;

  FileUriExpression(this.expression, this.fileUri) {
    expression.parent = this;
  }

  @override
  DartType getStaticType(StaticTypeContext context) =>
      getStaticTypeInternal(context);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) =>
      expression.getStaticType(context);

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitFileUriExpression(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitFileUriExpression(this, arg);

  @override
  void visitChildren(Visitor v) {
    expression.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    expression = v.transform(expression)..parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    expression = v.transform(expression)..parent = this;
  }

  @override
  Location? _getLocationInEnclosingFile(int offset) {
    return _getLocationInComponent(enclosingComponent, fileUri, offset,
        viaForErrorMessage: "File uri expression");
  }

  @override
  String toString() {
    return "FileUriExpression(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    if (printer.includeAuxiliaryProperties) {
      printer.write('{');
      printer.write(fileUri.toString());
      printer.write('}');
    }
    printer.writeExpression(expression);
  }
}

/// Expression of form `x is T`.
class IsExpression extends Expression {
  Expression operand;
  DartType type;

  IsExpression(this.operand, this.type) {
    operand.parent = this;
  }

  @override
  DartType getStaticType(StaticTypeContext context) =>
      getStaticTypeInternal(context);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) =>
      context.typeEnvironment.coreTypes.boolRawType(context.nonNullable);

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitIsExpression(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitIsExpression(this, arg);

  @override
  void visitChildren(Visitor v) {
    operand.accept(v);
    type.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    operand = v.transform(operand);
    operand.parent = this;
    type = v.visitDartType(type);
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    operand = v.transform(operand);
    operand.parent = this;
    type = v.visitDartType(type, cannotRemoveSentinel);
  }

  @override
  String toString() {
    return "IsExpression(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(operand,
        minimumPrecedence: astToText.Precedence.BITWISE_OR);
    printer.write(' is ');
    printer.writeType(type);
  }
}

/// Expression of form `x as T`.
class AsExpression extends Expression {
  int flags = 0;
  Expression operand;
  DartType type;

  AsExpression(this.operand, this.type) {
    operand.parent = this;
  }

  // Must match serialized bit positions.
  static const int FlagTypeError = 1 << 0;
  static const int FlagCovarianceCheck = 1 << 1;
  static const int FlagForDynamic = 1 << 2;
  static const int FlagUnchecked = 1 << 3;

  /// If `true`, this test is an implicit down cast.
  ///
  /// If `true` a TypeError should be thrown. If `false` a CastError should be
  /// thrown.
  bool get isTypeError => flags & FlagTypeError != 0;

  void set isTypeError(bool value) {
    flags = value ? (flags | FlagTypeError) : (flags & ~FlagTypeError);
  }

  /// If `true`, this test is needed to ensure soundness of covariant type
  /// variables using in contravariant positions.
  ///
  /// For instance
  ///
  ///    class Class<T> {
  ///      void Function(T) field;
  ///      Class(this.field);
  ///    }
  ///    main() {
  ///      Class<num> c = new Class<int>((int i) {});
  ///      void Function<num> field = c.field; // Check needed on `c.field`
  ///      field(0.5);
  ///    }
  ///
  /// Here a covariant check `c.field as void Function(num)` is needed because
  /// the field could be (and indeed is) not a subtype of the static type of
  /// the expression.
  bool get isCovarianceCheck => flags & FlagCovarianceCheck != 0;

  void set isCovarianceCheck(bool value) {
    flags =
        value ? (flags | FlagCovarianceCheck) : (flags & ~FlagCovarianceCheck);
  }

  /// If `true`, this is an implicit down cast from an expression of type
  /// `dynamic`.
  bool get isForDynamic => flags & FlagForDynamic != 0;

  void set isForDynamic(bool value) {
    flags = value ? (flags | FlagForDynamic) : (flags & ~FlagForDynamic);
  }

  /// If `true`, this test is added to show the known static type of the
  /// expression and should not be performed at runtime.
  ///
  /// This is the case for instance for access to extension type representation
  /// fields on an extension type, where this node shows that the static type
  /// changes from the extension type of the declared representation type.
  ///
  /// This is also the case when a field access undergoes type promotion.
  bool get isUnchecked => flags & FlagUnchecked != 0;

  void set isUnchecked(bool value) {
    flags = value ? (flags | FlagUnchecked) : (flags & ~FlagUnchecked);
  }

  @override
  DartType getStaticType(StaticTypeContext context) =>
      getStaticTypeInternal(context);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) => type;

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitAsExpression(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitAsExpression(this, arg);

  @override
  void visitChildren(Visitor v) {
    operand.accept(v);
    type.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    operand = v.transform(operand);
    operand.parent = this;
    type = v.visitDartType(type);
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    operand = v.transform(operand);
    operand.parent = this;
    type = v.visitDartType(type, cannotRemoveSentinel);
  }

  @override
  String toString() {
    return "AsExpression(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(operand,
        minimumPrecedence: astToText.Precedence.BITWISE_OR);
    printer.write(' as');
    if (printer.includeAuxiliaryProperties) {
      List<String> flags = <String>[];
      if (isTypeError) {
        flags.add('TypeError');
      }
      if (isCovarianceCheck) {
        flags.add('CovarianceCheck');
      }
      if (isForDynamic) {
        flags.add('ForDynamic');
      }
      if (flags.isNotEmpty) {
        printer.write('{${flags.join(',')}}');
      }
    }
    printer.write(' ');
    printer.writeType(type);
  }
}

/// Null check expression of form `x!`.
///
/// This expression was added as part of NNBD and is currently only created when
/// the 'non-nullable' experimental feature is enabled.
class NullCheck extends Expression {
  Expression operand;

  NullCheck(this.operand) {
    operand.parent = this;
  }

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) {
    DartType operandType = operand.getStaticType(context);
    return operandType is NullType
        ? const NeverType.nonNullable()
        : operandType.withDeclaredNullability(Nullability.nonNullable);
  }

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitNullCheck(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitNullCheck(this, arg);

  @override
  void visitChildren(Visitor v) {
    operand.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    operand = v.transform(operand);
    operand.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    operand = v.transform(operand);
    operand.parent = this;
  }

  @override
  String toString() {
    return "NullCheck(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(operand,
        minimumPrecedence: astToText.Precedence.POSTFIX);
    printer.write('!');
  }
}

/// An integer, double, boolean, string, or null constant.
abstract class BasicLiteral extends Expression {
  Object? get value;

  @override
  void visitChildren(Visitor v) {}

  @override
  void transformChildren(Transformer v) {}

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {}
}

class StringLiteral extends BasicLiteral {
  @override
  String value;

  StringLiteral(this.value);

  @override
  DartType getStaticType(StaticTypeContext context) =>
      getStaticTypeInternal(context);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) =>
      context.typeEnvironment.coreTypes.stringRawType(context.nonNullable);

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitStringLiteral(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitStringLiteral(this, arg);

  @override
  String toString() {
    return "StringLiteral(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('"');
    printer.write(escapeString(value));
    printer.write('"');
  }
}

class IntLiteral extends BasicLiteral {
  /// Note that this value holds a uint64 value.
  /// E.g. "0x8000000000000000" will be saved as "-9223372036854775808" despite
  /// technically (on some platforms, particularly JavaScript) being positive.
  /// If the number is meant to be negative it will be wrapped in a "unary-".
  @override
  int value;

  IntLiteral(this.value);

  @override
  DartType getStaticType(StaticTypeContext context) =>
      getStaticTypeInternal(context);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) =>
      context.typeEnvironment.coreTypes.intRawType(context.nonNullable);

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitIntLiteral(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitIntLiteral(this, arg);

  @override
  String toString() {
    return "IntLiteral(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('$value');
  }
}

class DoubleLiteral extends BasicLiteral {
  @override
  double value;

  DoubleLiteral(this.value);

  @override
  DartType getStaticType(StaticTypeContext context) =>
      getStaticTypeInternal(context);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) =>
      context.typeEnvironment.coreTypes.doubleRawType(context.nonNullable);

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitDoubleLiteral(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitDoubleLiteral(this, arg);

  @override
  String toString() {
    return "DoubleLiteral(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('$value');
  }
}

class BoolLiteral extends BasicLiteral {
  @override
  bool value;

  BoolLiteral(this.value);

  @override
  DartType getStaticType(StaticTypeContext context) =>
      getStaticTypeInternal(context);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) =>
      context.typeEnvironment.coreTypes.boolRawType(context.nonNullable);

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitBoolLiteral(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitBoolLiteral(this, arg);

  @override
  String toString() {
    return "BoolLiteral(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('$value');
  }
}

class NullLiteral extends BasicLiteral {
  @override
  Object? get value => null;

  @override
  DartType getStaticType(StaticTypeContext context) =>
      getStaticTypeInternal(context);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) => const NullType();

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitNullLiteral(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitNullLiteral(this, arg);

  @override
  String toString() {
    return "NullLiteral(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('null');
  }
}

class SymbolLiteral extends Expression {
  String value; // Everything strictly after the '#'.

  SymbolLiteral(this.value);

  @override
  DartType getStaticType(StaticTypeContext context) =>
      getStaticTypeInternal(context);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) =>
      context.typeEnvironment.coreTypes.symbolRawType(context.nonNullable);

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitSymbolLiteral(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitSymbolLiteral(this, arg);

  @override
  void visitChildren(Visitor v) {}

  @override
  void transformChildren(Transformer v) {}

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {}

  @override
  String toString() {
    return "SymbolLiteral(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('#');
    printer.write(value);
  }
}

class TypeLiteral extends Expression {
  DartType type;

  TypeLiteral(this.type);

  @override
  DartType getStaticType(StaticTypeContext context) =>
      getStaticTypeInternal(context);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) =>
      context.typeEnvironment.coreTypes.typeRawType(context.nonNullable);

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitTypeLiteral(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitTypeLiteral(this, arg);

  @override
  void visitChildren(Visitor v) {
    type.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    type = v.visitDartType(type);
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    type = v.visitDartType(type, cannotRemoveSentinel);
  }

  @override
  String toString() {
    return "TypeLiteral(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeType(type);
  }
}

class ThisExpression extends Expression {
  @override
  DartType getStaticType(StaticTypeContext context) =>
      getStaticTypeInternal(context);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) =>
      context.thisType!;

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitThisExpression(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitThisExpression(this, arg);

  @override
  void visitChildren(Visitor v) {}

  @override
  void transformChildren(Transformer v) {}

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {}

  @override
  String toString() {
    return "ThisExpression(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('this');
  }
}

class Rethrow extends Expression {
  @override
  DartType getStaticType(StaticTypeContext context) =>
      getStaticTypeInternal(context);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) =>
      const NeverType.nonNullable();

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitRethrow(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitRethrow(this, arg);

  @override
  void visitChildren(Visitor v) {}

  @override
  void transformChildren(Transformer v) {}

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {}

  @override
  String toString() {
    return "Rethrow(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('rethrow');
  }
}

class Throw extends Expression {
  Expression expression;
  int flags = 0;

  Throw(this.expression) {
    expression.parent = this;
  }

  // Must match serialized bit positions.
  static const int FlagForErrorHandling = 1 << 0;

  /// If `true`, this `throw` is *not* present in the source code but added
  /// to ensure correctness and/or soundness of the generated code.
  ///
  /// This is used for instance in the lowering for handling duplicate writes
  /// to a late final field or for pattern assignments that don't match.
  bool get forErrorHandling => flags & FlagForErrorHandling != 0;

  void set forErrorHandling(bool value) {
    flags = value
        ? (flags | FlagForErrorHandling)
        : (flags & ~FlagForErrorHandling);
  }

  @override
  DartType getStaticType(StaticTypeContext context) =>
      getStaticTypeInternal(context);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) =>
      const NeverType.nonNullable();

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitThrow(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) => v.visitThrow(this, arg);

  @override
  void visitChildren(Visitor v) {
    expression.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    expression = v.transform(expression);
    expression.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    expression = v.transform(expression);
    expression.parent = this;
  }

  @override
  String toString() {
    return "Throw(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('throw ');
    printer.writeExpression(expression);
  }
}

class ListLiteral extends Expression {
  bool isConst;
  DartType typeArgument; // Not null, defaults to DynamicType.
  final List<Expression> expressions;

  ListLiteral(this.expressions,
      {this.typeArgument = const DynamicType(), this.isConst = false}) {
    setParents(expressions, this);
  }

  @override
  DartType getStaticType(StaticTypeContext context) =>
      getStaticTypeInternal(context);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) {
    return context.typeEnvironment.listType(typeArgument, context.nonNullable);
  }

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitListLiteral(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitListLiteral(this, arg);

  @override
  void visitChildren(Visitor v) {
    typeArgument.accept(v);
    visitList(expressions, v);
  }

  @override
  void transformChildren(Transformer v) {
    typeArgument = v.visitDartType(typeArgument);
    v.transformList(expressions, this);
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    typeArgument = v.visitDartType(typeArgument, cannotRemoveSentinel);
    v.transformExpressionList(expressions, this);
  }

  @override
  String toString() {
    return "ListLiteral(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    if (isConst) {
      printer.write('const ');
    }
    printer.write('<');
    printer.writeType(typeArgument);
    printer.write('>[');
    printer.writeExpressions(expressions);
    printer.write(']');
  }
}

class SetLiteral extends Expression {
  bool isConst;
  DartType typeArgument; // Not null, defaults to DynamicType.
  final List<Expression> expressions;

  SetLiteral(this.expressions,
      {this.typeArgument = const DynamicType(), this.isConst = false}) {
    setParents(expressions, this);
  }

  @override
  DartType getStaticType(StaticTypeContext context) =>
      getStaticTypeInternal(context);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) {
    return context.typeEnvironment.setType(typeArgument, context.nonNullable);
  }

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitSetLiteral(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitSetLiteral(this, arg);

  @override
  void visitChildren(Visitor v) {
    typeArgument.accept(v);
    visitList(expressions, v);
  }

  @override
  void transformChildren(Transformer v) {
    typeArgument = v.visitDartType(typeArgument);
    v.transformList(expressions, this);
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    typeArgument = v.visitDartType(typeArgument, cannotRemoveSentinel);
    v.transformExpressionList(expressions, this);
  }

  @override
  String toString() {
    return "SetLiteral(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    if (isConst) {
      printer.write('const ');
    }
    printer.write('<');
    printer.writeType(typeArgument);
    printer.write('>{');
    printer.writeExpressions(expressions);
    printer.write('}');
  }
}

class MapLiteral extends Expression {
  bool isConst;
  DartType keyType; // Not null, defaults to DynamicType.
  DartType valueType; // Not null, defaults to DynamicType.
  final List<MapLiteralEntry> entries;

  MapLiteral(this.entries,
      {this.keyType = const DynamicType(),
      this.valueType = const DynamicType(),
      this.isConst = false}) {
    setParents(entries, this);
  }

  @override
  DartType getStaticType(StaticTypeContext context) =>
      getStaticTypeInternal(context);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) {
    return context.typeEnvironment
        .mapType(keyType, valueType, context.nonNullable);
  }

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitMapLiteral(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitMapLiteral(this, arg);

  @override
  void visitChildren(Visitor v) {
    keyType.accept(v);
    valueType.accept(v);
    visitList(entries, v);
  }

  @override
  void transformChildren(Transformer v) {
    keyType = v.visitDartType(keyType);
    valueType = v.visitDartType(valueType);
    v.transformList(entries, this);
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    keyType = v.visitDartType(keyType, cannotRemoveSentinel);
    valueType = v.visitDartType(valueType, cannotRemoveSentinel);
    v.transformMapEntryList(entries, this);
  }

  @override
  String toString() {
    return "MapLiteral(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    if (isConst) {
      printer.write('const ');
    }
    printer.write('<');
    printer.writeType(keyType);
    printer.write(', ');
    printer.writeType(valueType);
    printer.write('>{');
    for (int index = 0; index < entries.length; index++) {
      if (index > 0) {
        printer.write(', ');
      }
      printer.writeMapEntry(entries[index]);
    }
    printer.write('}');
  }
}

class MapLiteralEntry extends TreeNode {
  Expression key;
  Expression value;

  MapLiteralEntry(this.key, this.value) {
    key.parent = this;
    value.parent = this;
  }

  @override
  R accept<R>(TreeVisitor<R> v) => v.visitMapLiteralEntry(this);

  @override
  R accept1<R, A>(TreeVisitor1<R, A> v, A arg) =>
      v.visitMapLiteralEntry(this, arg);

  @override
  void visitChildren(Visitor v) {
    key.accept(v);
    value.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    key = v.transform(key);
    key.parent = this;
    value = v.transform(value);
    value.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    key = v.transform(key);
    key.parent = this;
    value = v.transform(value);
    value.parent = this;
  }

  @override
  String toString() {
    return "MapEntry(${toStringInternal()})";
  }

  @override
  String toText(AstTextStrategy strategy) {
    AstPrinter printer = new AstPrinter(strategy);
    toTextInternal(printer);
    return printer.getText();
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(key);
    printer.write(': ');
    printer.writeExpression(value);
  }
}

class RecordLiteral extends Expression {
  bool isConst;
  final List<Expression> positional;
  final List<NamedExpression> named;
  RecordType recordType;

  RecordLiteral(this.positional, this.named, this.recordType,
      {this.isConst = false})
      : assert(positional.length == recordType.positional.length &&
            named.length == recordType.named.length &&
            recordType.named
                .map((f) => f.name)
                .toSet()
                .containsAll(named.map((f) => f.name))),
        assert(() {
          // Assert that the named fields are sorted.
          for (int i = 1; i < named.length; i++) {
            if (named[i].name.compareTo(named[i - 1].name) < 0) {
              return false;
            }
          }
          return true;
        }(),
            "Named fields of a RecordLiterals aren't sorted lexicographically: "
            "${named.map((f) => f.name).join(", ")}") {
    setParents(positional, this);
    setParents(named, this);
  }

  @override
  DartType getStaticType(StaticTypeContext context) =>
      getStaticTypeInternal(context);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) {
    return recordType;
  }

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitRecordLiteral(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitRecordLiteral(this, arg);

  @override
  void visitChildren(Visitor v) {
    visitList(positional, v);
    visitList(named, v);
    recordType.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    v.transformList(positional, this);
    v.transformList(named, this);
    recordType = v.visitDartType(recordType) as RecordType;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    v.transformExpressionList(positional, this);
    v.transformNamedExpressionList(named, this);
    recordType =
        v.visitDartType(recordType, cannotRemoveSentinel) as RecordType;
  }

  @override
  String toString() {
    return "RecordType(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    if (isConst) {
      printer.write("const ");
    }
    printer.write("(");
    for (int index = 0; index < positional.length; index++) {
      if (index > 0) {
        printer.write(", ");
      }
      printer.writeExpression(positional[index]);
    }
    if (named.isNotEmpty) {
      if (positional.isNotEmpty) {
        printer.write(", ");
      }
      for (int index = 0; index < named.length; index++) {
        if (index > 0) {
          printer.write(", ");
        }
        printer.writeNamedExpression(named[index]);
      }
    }
    printer.write(")");
  }
}

/// Expression of form `await x`.
class AwaitExpression extends Expression {
  Expression operand;

  /// If non-null, the runtime should check whether the value of [operand] is a
  /// subtype of [runtimeCheckType], and if _not_ so, wrap the value in a call
  /// to the `Future.value()` constructor.
  ///
  /// For instance
  ///
  ///     FutureOr<Object> future1 = Future<Object?>.value();
  ///     var x = await future1; // Check against `Future<Object>`.
  ///
  ///     Object object = Future<Object?>.value();
  ///     var y = await object; // Check against `Future<Object>`.
  ///
  ///     Future<Object?> future2 = Future<Object?>.value();
  ///     var z = await future2; // No check.
  ///
  /// This runtime checks is necessary to ensure that we don't evaluate the
  /// await expression to `null` when the static type of the expression is
  /// non-nullable.
  ///
  /// The [runtimeCheckType] is computed as `Future<T>` where `T = flatten(S)`
  /// and `S` is the static type of [operand]. To avoid unnecessary runtime
  /// checks, the [runtimeCheckType] is not set if the static type of the
  /// [operand] is a subtype of `Future<T>`.
  ///
  /// See https://github.com/dart-lang/sdk/issues/49396 for further discussion
  /// of which the check is needed.
  DartType? runtimeCheckType;

  AwaitExpression(this.operand) {
    operand.parent = this;
  }

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) {
    return context.typeEnvironment.flatten(operand.getStaticType(context));
  }

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitAwaitExpression(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitAwaitExpression(this, arg);

  @override
  void visitChildren(Visitor v) {
    operand.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    operand = v.transform(operand);
    operand.parent = this;
    if (runtimeCheckType != null) {
      runtimeCheckType = v.visitDartType(runtimeCheckType!);
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    operand = v.transform(operand);
    operand.parent = this;
    if (runtimeCheckType != null) {
      runtimeCheckType = v.visitDartType(runtimeCheckType!, null);
    }
  }

  @override
  String toString() {
    return "AwaitExpression(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('await ');
    printer.writeExpression(operand);
  }
}

/// Common super-interface for [FunctionExpression] and [FunctionDeclaration].
abstract class LocalFunction implements GenericFunction {
  @override
  FunctionNode get function;
}

/// Expression of form `(x,y) => ...` or `(x,y) { ... }`
///
/// The arrow-body form `=> e` is desugared into `return e;`.
class FunctionExpression extends Expression implements LocalFunction {
  @override
  FunctionNode function;

  FunctionExpression(this.function) {
    function.parent = this;
  }

  @override
  List<TypeParameter> get typeParameters => function.typeParameters;

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) {
    return function.computeFunctionType(context.nonNullable);
  }

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitFunctionExpression(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitFunctionExpression(this, arg);

  @override
  void visitChildren(Visitor v) {
    function.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    function = v.transform(function);
    function.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    function = v.transform(function);
    function.parent = this;
  }

  @override
  String toString() {
    return "FunctionExpression(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeFunctionNode(function, '');
  }
}

class ConstantExpression extends Expression {
  Constant constant;
  DartType type;

  ConstantExpression(this.constant, [this.type = const DynamicType()]);

  @override
  DartType getStaticType(StaticTypeContext context) =>
      getStaticTypeInternal(context);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) => type;

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitConstantExpression(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitConstantExpression(this, arg);

  @override
  void visitChildren(Visitor v) {
    constant.acceptReference(v);
    type.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    constant = v.visitConstant(constant);
    type = v.visitDartType(type);
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    constant = v.visitConstant(constant, cannotRemoveSentinel);
    type = v.visitDartType(type, cannotRemoveSentinel);
  }

  @override
  String toString() {
    return "ConstantExpression(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeConstant(constant);
  }
}

class FileUriConstantExpression extends ConstantExpression
    implements FileUriNode {
  @override
  Uri fileUri;

  FileUriConstantExpression(Constant constant,
      {DartType type = const DynamicType(), required this.fileUri})
      : super(constant, type);

  @override
  Location? _getLocationInEnclosingFile(int offset) {
    return _getLocationInComponent(enclosingComponent, fileUri, offset,
        viaForErrorMessage: "File uri constant expression");
  }
}

/// Synthetic expression of form `let v = x in y`
class Let extends Expression {
  VariableDeclaration variable; // Must have an initializer.
  Expression body;

  Let(this.variable, this.body) {
    variable.parent = this;
    body.parent = this;
  }

  @override
  DartType getStaticType(StaticTypeContext context) =>
      getStaticTypeInternal(context);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) =>
      body.getStaticType(context);

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitLet(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) => v.visitLet(this, arg);

  @override
  void visitChildren(Visitor v) {
    variable.accept(v);
    body.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    variable = v.transform(variable);
    variable.parent = this;
    body = v.transform(body);
    body.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    variable = v.transform(variable);
    variable.parent = this;
    body = v.transform(body);
    body.parent = this;
  }

  @override
  String toString() {
    return "Let(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('let ');
    printer.writeVariableDeclaration(variable);
    printer.write(' in ');
    printer.writeExpression(body);
  }
}

class BlockExpression extends Expression {
  Block body;
  Expression value;

  BlockExpression(this.body, this.value) {
    body.parent = this;
    value.parent = this;
  }

  @override
  DartType getStaticType(StaticTypeContext context) =>
      getStaticTypeInternal(context);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) =>
      value.getStaticType(context);

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitBlockExpression(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitBlockExpression(this, arg);

  @override
  void visitChildren(Visitor v) {
    body.accept(v);
    value.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    body = v.transform(body);
    body.parent = this;
    value = v.transform(value);
    value.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    body = v.transform(body);
    body.parent = this;
    value = v.transform(value);
    value.parent = this;
  }

  @override
  String toString() {
    return "BlockExpression(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('block ');
    printer.writeBlock(body.statements);
    printer.write(' => ');
    printer.writeExpression(value);
  }
}

/// Attempt to load the library referred to by a deferred import.
///
/// This instruction is concerned with:
/// - keeping track whether the deferred import is marked as 'loaded'
/// - keeping track of whether the library code has already been downloaded
/// - actually downloading and linking the library
///
/// Should return a future.  The value in this future will be the same value
/// seen by callers of `loadLibrary` functions.
///
/// On backends that link the entire program eagerly, this instruction needs
/// to mark the deferred import as 'loaded' and return a future.
class LoadLibrary extends Expression {
  /// Reference to a deferred import in the enclosing library.
  LibraryDependency import;

  LoadLibrary(this.import);

  @override
  DartType getStaticType(StaticTypeContext context) =>
      getStaticTypeInternal(context);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) {
    return context.typeEnvironment
        .futureType(const DynamicType(), context.nonNullable);
  }

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitLoadLibrary(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitLoadLibrary(this, arg);

  @override
  void visitChildren(Visitor v) {}

  @override
  void transformChildren(Transformer v) {}

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {}

  @override
  String toString() {
    return "LoadLibrary(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write(import.name!);
    printer.write('.loadLibrary()');
  }
}

/// Checks that the given deferred import has been marked as 'loaded'.
class CheckLibraryIsLoaded extends Expression {
  /// Reference to a deferred import in the enclosing library.
  LibraryDependency import;

  CheckLibraryIsLoaded(this.import);

  @override
  DartType getStaticType(StaticTypeContext context) =>
      getStaticTypeInternal(context);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) {
    return context.typeEnvironment.coreTypes.objectRawType(context.nonNullable);
  }

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitCheckLibraryIsLoaded(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitCheckLibraryIsLoaded(this, arg);

  @override
  void visitChildren(Visitor v) {}

  @override
  void transformChildren(Transformer v) {}

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {}

  @override
  String toString() {
    return "CheckLibraryIsLoaded(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write(import.name!);
    printer.write('.checkLibraryIsLoaded()');
  }
}

/// Tearing off a constructor of a class.
class ConstructorTearOff extends Expression {
  /// The reference to the constructor being torn off.
  Reference targetReference;

  ConstructorTearOff(Member target)
      : assert(
            target is Constructor || (target is Procedure && target.isFactory),
            "Unexpected constructor tear off target: $target"),
        this.targetReference = getNonNullableMemberReferenceGetter(target);

  ConstructorTearOff.byReference(this.targetReference);

  Member get target => targetReference.asMember;

  FunctionNode get function => target.function!;

  void set target(Member member) {
    assert(member is Constructor ||
        (member is Procedure && member.kind == ProcedureKind.Factory));
    targetReference = getNonNullableMemberReferenceGetter(member);
  }

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) {
    return target.function!.computeFunctionType(Nullability.nonNullable);
  }

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitConstructorTearOff(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitConstructorTearOff(this, arg);

  @override
  void visitChildren(Visitor v) {
    target.acceptReference(v);
  }

  @override
  void transformChildren(Transformer v) {}

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {}

  @override
  String toString() {
    return "ConstructorTearOff(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeMemberName(targetReference);
  }
}

/// Tearing off a redirecting factory constructor of a class.
class RedirectingFactoryTearOff extends Expression {
  /// The reference to the redirecting factory constructor being torn off.
  Reference targetReference;

  RedirectingFactoryTearOff(Procedure target)
      : assert(target.isRedirectingFactory),
        this.targetReference = getNonNullableMemberReferenceGetter(target);

  RedirectingFactoryTearOff.byReference(this.targetReference);

  Procedure get target => targetReference.asProcedure;

  void set target(Procedure target) {
    targetReference = getNonNullableMemberReferenceGetter(target);
  }

  FunctionNode get function => target.function;

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) {
    return target.function.computeFunctionType(Nullability.nonNullable);
  }

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitRedirectingFactoryTearOff(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitRedirectingFactoryTearOff(this, arg);

  @override
  void visitChildren(Visitor v) {
    target.acceptReference(v);
  }

  @override
  void transformChildren(Transformer v) {}

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {}

  @override
  String toString() {
    return "RedirectingFactoryTearOff(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeMemberName(targetReference);
  }
}

class TypedefTearOff extends Expression {
  final List<StructuralParameter> structuralParameters;
  Expression expression;
  final List<DartType> typeArguments;

  TypedefTearOff(
      this.structuralParameters, this.expression, this.typeArguments) {
    expression.parent = this;
  }

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) {
    FreshStructuralParameters freshTypeParameters =
        getFreshStructuralParameters(structuralParameters);
    FunctionType type = expression.getStaticType(context) as FunctionType;
    type = freshTypeParameters.substitute(
            FunctionTypeInstantiator.instantiate(type, typeArguments))
        as FunctionType;
    return new FunctionType(
        type.positionalParameters, type.returnType, type.declaredNullability,
        namedParameters: type.namedParameters,
        typeParameters: freshTypeParameters.freshTypeParameters,
        requiredParameterCount: type.requiredParameterCount);
  }

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitTypedefTearOff(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitTypedefTearOff(this, arg);

  @override
  void visitChildren(Visitor v) {
    expression.accept(v);
    visitList(structuralParameters, v);
    visitList(typeArguments, v);
  }

  @override
  void transformChildren(Transformer v) {
    expression = v.transform(expression);
    expression.parent = this;
    v.transformDartTypeList(typeArguments);
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    expression = v.transform(expression);
    expression.parent = this;
    v.transformDartTypeList(typeArguments);
  }

  @override
  String toString() {
    return "TypedefTearOff(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeStructuralParameters(structuralParameters);
    printer.write(".(");
    printer.writeExpression(expression);
    printer.writeTypeArguments(typeArguments);
    printer.write(")");
  }
}
