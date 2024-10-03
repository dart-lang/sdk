// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../../ast.dart';

// ------------------------------------------------------------------------
//                     CONSTRUCTOR INITIALIZERS
// ------------------------------------------------------------------------

/// Part of an initializer list in a constructor.
sealed class Initializer extends TreeNode {
  /// True if this is a synthetic constructor initializer.
  @informative
  bool isSynthetic = false;

  @override
  R accept<R>(InitializerVisitor<R> v);

  @override
  R accept1<R, A>(InitializerVisitor1<R, A> v, A arg);
}

abstract class AuxiliaryInitializer extends Initializer {
  @override
  R accept<R>(InitializerVisitor<R> v) => v.visitAuxiliaryInitializer(this);

  @override
  R accept1<R, A>(InitializerVisitor1<R, A> v, A arg) =>
      v.visitAuxiliaryInitializer(this, arg);
}

/// An initializer with a compile-time error.
///
/// Should throw an exception at runtime.
//
// DESIGN TODO: The frontend should use this in a lot more cases to catch
// invalid cases.
class InvalidInitializer extends Initializer {
  @override
  R accept<R>(InitializerVisitor<R> v) => v.visitInvalidInitializer(this);

  @override
  R accept1<R, A>(InitializerVisitor1<R, A> v, A arg) =>
      v.visitInvalidInitializer(this, arg);

  @override
  void visitChildren(Visitor v) {}

  @override
  void transformChildren(Transformer v) {}

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {}

  @override
  String toString() {
    return "InvalidInitializer(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    // TODO(johnniwinther): Implement this.
  }
}

/// A field assignment `field = value` occurring in the initializer list of
/// a constructor.
///
/// This node has nothing to do with declaration-site field initializers; those
/// are [Expression]s stored in [Field.initializer].
//
// TODO: The frontend should check that all final fields are initialized
//  exactly once, and that no fields are assigned twice in the initializer list.
class FieldInitializer extends Initializer {
  /// Reference to the field being initialized.  Not null.
  Reference fieldReference;
  Expression value;

  FieldInitializer(Field field, Expression value)
      : this.byReference(field.fieldReference, value);

  FieldInitializer.byReference(this.fieldReference, this.value) {
    value.parent = this;
  }

  Field get field => fieldReference.asField;

  void set field(Field field) {
    fieldReference = field.fieldReference;
  }

  @override
  R accept<R>(InitializerVisitor<R> v) => v.visitFieldInitializer(this);

  @override
  R accept1<R, A>(InitializerVisitor1<R, A> v, A arg) =>
      v.visitFieldInitializer(this, arg);

  @override
  void visitChildren(Visitor v) {
    field.acceptReference(v);
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
    return "FieldInitializer(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    // TODO(johnniwinther): Implement this.
  }
}

/// A super call `super(x,y)` occurring in the initializer list of a
/// constructor.
///
/// There are no type arguments on this call.
//
// TODO: The frontend should check that there is no more than one super call.
//
// DESIGN TODO: Consider if the frontend should insert type arguments derived
// from the extends clause.
class SuperInitializer extends Initializer {
  /// Reference to the constructor being invoked in the super class. Not null.
  Reference targetReference;
  Arguments arguments;

  SuperInitializer(Constructor target, Arguments arguments)
      : this.byReference(
            // Getter vs setter doesn't matter for constructors.
            getNonNullableMemberReferenceGetter(target),
            arguments);

  SuperInitializer.byReference(this.targetReference, this.arguments) {
    arguments.parent = this;
  }

  Constructor get target => targetReference.asConstructor;

  void set target(Constructor target) {
    // Getter vs setter doesn't matter for constructors.
    targetReference = getNonNullableMemberReferenceGetter(target);
  }

  @override
  R accept<R>(InitializerVisitor<R> v) => v.visitSuperInitializer(this);

  @override
  R accept1<R, A>(InitializerVisitor1<R, A> v, A arg) =>
      v.visitSuperInitializer(this, arg);

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
    return "SuperInitializer(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('super');
    if (target.name.text.isNotEmpty) {
      printer.write('.');
      printer.write(target.name.text);
    }
    printer.writeArguments(arguments, includeTypeArguments: false);
  }
}

/// A redirecting call `this(x,y)` occurring in the initializer list of
/// a constructor.
//
// TODO: The frontend should check that this is the only initializer and if the
// constructor has a body or if there is a cycle in the initializer calls.
class RedirectingInitializer extends Initializer {
  /// Reference to the constructor being invoked in the same class. Not null.
  Reference targetReference;
  Arguments arguments;

  RedirectingInitializer(Constructor target, Arguments arguments)
      : this.byReference(
            // Getter vs setter doesn't matter for constructors.
            getNonNullableMemberReferenceGetter(target),
            arguments);

  RedirectingInitializer.byReference(this.targetReference, this.arguments) {
    arguments.parent = this;
  }

  Constructor get target => targetReference.asConstructor;

  void set target(Constructor target) {
    // Getter vs setter doesn't matter for constructors.
    targetReference = getNonNullableMemberReferenceGetter(target);
  }

  @override
  R accept<R>(InitializerVisitor<R> v) => v.visitRedirectingInitializer(this);

  @override
  R accept1<R, A>(InitializerVisitor1<R, A> v, A arg) =>
      v.visitRedirectingInitializer(this, arg);

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
    return "RedirectingInitializer(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('this');
    if (target.name.text.isNotEmpty) {
      printer.write('.');
      printer.write(target.name.text);
    }
    printer.writeArguments(arguments, includeTypeArguments: false);
  }
}

/// Binding of a temporary variable in the initializer list of a constructor.
///
/// The variable is in scope for the remainder of the initializer list, but is
/// not in scope in the constructor body.
class LocalInitializer extends Initializer {
  VariableDeclaration variable;

  LocalInitializer(this.variable) {
    variable.parent = this;
  }

  @override
  R accept<R>(InitializerVisitor<R> v) => v.visitLocalInitializer(this);

  @override
  R accept1<R, A>(InitializerVisitor1<R, A> v, A arg) =>
      v.visitLocalInitializer(this, arg);

  @override
  void visitChildren(Visitor v) {
    variable.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    variable = v.transform(variable);
    variable.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    variable = v.transform(variable);
    variable.parent = this;
  }

  @override
  String toString() {
    return "LocalInitializer(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    // TODO(johnniwinther): Implement this.
  }
}

class AssertInitializer extends Initializer {
  AssertStatement statement;

  AssertInitializer(this.statement) {
    statement.parent = this;
  }

  @override
  R accept<R>(InitializerVisitor<R> v) => v.visitAssertInitializer(this);

  @override
  R accept1<R, A>(InitializerVisitor1<R, A> v, A arg) =>
      v.visitAssertInitializer(this, arg);

  @override
  void visitChildren(Visitor v) {
    statement.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    statement = v.transform(statement);
    statement.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    statement = v.transform(statement);
    statement.parent = this;
  }

  @override
  String toString() {
    return "AssertInitializer(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    statement.toTextInternal(printer);
  }
}
