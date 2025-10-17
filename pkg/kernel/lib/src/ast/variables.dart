// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../../ast.dart';

/// Generalized notion of a variable.
sealed class Variable extends TreeNode {
  VariableContext get context => parent as VariableContext;

  // CaptureKind get captureKind => context.captureKind;

  /// The cosmetic name of the variable from the source code, if exists.
  String? get cosmeticName;

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write(printer.getVariableName(this));
  }
}

/// The root of the sealed hierarchy of non-type variables.
sealed class ExpressionVariable extends Variable {}

/// Local variables. They aren't Statements. A [LocalVariable] is "declared" in
/// the [VariableContext] it appears in. [VariableInitialization]
/// (which is a [Statement]) marks the spot of the original variable declaration
/// in the Dart program.
class LocalVariable extends ExpressionVariable {
  @override
  String? cosmeticName;

  LocalVariable({this.cosmeticName});

  @override
  R accept<R>(TreeVisitor<R> v) {
    // TODO(cstefantsova): Implement accept.
    throw UnimplementedError();
  }

  @override
  R accept1<R, A>(TreeVisitor1<R, A> v, A arg) {
    // TODO(cstefantsova): Implement accept1.
    throw UnimplementedError();
  }

  @override
  void transformChildren(Transformer v) {
    // TODO(cstefantsova): Implement transformChildren.
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    // TODO(cstefantsova): Implement transformOrRemoveChildren.
  }

  @override
  void visitChildren(Visitor v) {
    // TODO(cstefantsova): Implement visitChildren.
  }

  @override
  String toString() {
    return "LocalVariable(${toStringInternal()})";
  }
}

/// Abstract parameter class, the parent for positional and named parameters.
sealed class FunctionParameter extends ExpressionVariable {}

/// Positional parameters. The [cosmeticName] field is optional and doesn't
/// affect the runtime semantics of the program.
class PositionalParameter extends FunctionParameter {
  @override
  final String? cosmeticName;

  PositionalParameter(this.cosmeticName);

  @override
  R accept<R>(TreeVisitor<R> v) {
    // TODO(cstefantsova): Implement accept.
    throw UnimplementedError();
  }

  @override
  R accept1<R, A>(TreeVisitor1<R, A> v, A arg) {
    // TODO(cstefantsova): Implement accept1.
    throw UnimplementedError();
  }

  @override
  void transformChildren(Transformer v) {
    // TODO(cstefantsova): Implement transformChildren.
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    // TODO(cstefantsova): Implement transformOrRemoveChildren.
  }

  @override
  void visitChildren(Visitor v) {
    // TODO(cstefantsova): Implement visitChildren.
  }

  @override
  String toString() {
    return "PositionalParameter(${toStringInternal()})";
  }
}

/// Named parameters. The [name] field is mandatory.
class NamedParameter extends FunctionParameter {
  final String name;

  @override
  String get cosmeticName => name;

  NamedParameter({required this.name});

  @override
  R accept<R>(TreeVisitor<R> v) {
    // TODO(cstefantsova): Implement accept.
    throw UnimplementedError();
  }

  @override
  R accept1<R, A>(TreeVisitor1<R, A> v, A arg) {
    // TODO(cstefantsova): Implement accept1.
    throw UnimplementedError();
  }

  @override
  void transformChildren(Transformer v) {
    // TODO(cstefantsova): Implement transformChildren.
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    // TODO(cstefantsova): Implement transformOrRemoveChildren.
  }

  @override
  void visitChildren(Visitor v) {
    // TODO(cstefantsova): Implement visitChildren.
  }

  @override
  String toString() {
    return "NamedParameter(${toStringInternal()})";
  }
}

/// The variable storage for `this`.
class ThisVariable extends ExpressionVariable {
  @override
  String get cosmeticName => "this";

  ThisVariable();

  @override
  R accept<R>(TreeVisitor<R> v) {
    // TODO(cstefantsova): Implement accept.
    throw UnimplementedError();
  }

  @override
  R accept1<R, A>(TreeVisitor1<R, A> v, A arg) {
    // TODO(cstefantsova): Implement accept1.
    throw UnimplementedError();
  }

  @override
  void transformChildren(Transformer v) {
    // TODO(cstefantsova): Implement transformChildren.
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    // TODO(cstefantsova): Implement transformOrRemoveChildren.
  }

  @override
  void visitChildren(Visitor v) {
    // TODO(cstefantsova): Implement visitChildren.
  }

  @override
  String toString() {
    return "ThisVariable(${toStringInternal()})";
  }
}

/// A variable introduced during desugaring. Such variables don't correspond to
/// any variable declared by the programmer.
class SyntheticVariable extends ExpressionVariable {
  @override
  String? cosmeticName;

  SyntheticVariable({this.cosmeticName});

  @override
  R accept<R>(TreeVisitor<R> v) {
    // TODO(cstefantsova): Implement accept.
    throw UnimplementedError();
  }

  @override
  R accept1<R, A>(TreeVisitor1<R, A> v, A arg) {
    // TODO(cstefantsova): Implement accept1.
    throw UnimplementedError();
  }

  @override
  void transformChildren(Transformer v) {
    // TODO(cstefantsova): Implement transformChildren.
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    // TODO(cstefantsova): Implement transformOrRemoveChildren.
  }

  @override
  void visitChildren(Visitor v) {
    // TODO(cstefantsova): Implement visitChildren.
  }

  @override
  String toString() {
    return "SyntheticVariable(${toStringInternal()})";
  }
}

/// The enum reflecting the kind of a variable context. A context is
/// [assertCaptured] if it contains the variables captured in a closure within
/// an `assert` and not captured anywhere outside of `assert`s.
enum CaptureKind {
  notCaptured,
  captured,
  assertCaptured;
}

/// The box storing some of the variables in the scope it's associated with. It
/// serves as the "declaration" of the variables it contains for the runtime
/// environments.
class VariableContext extends TreeNode {
  final CaptureKind captureKind;
  final List<Variable> variables;

  VariableContext({required this.captureKind, required this.variables});

  @override
  R accept<R>(TreeVisitor<R> v) {
    // TODO(cstefantsova): Implement accept.
    throw UnimplementedError();
  }

  @override
  R accept1<R, A>(TreeVisitor1<R, A> v, A arg) {
    // TODO(cstefantsova): Implement accept1.
    throw UnimplementedError();
  }

  @override
  void transformChildren(Transformer v) {
    // TODO(cstefantsova): Implement transformChildren.
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    // TODO(cstefantsova): Implement transformOrRemoveChildren.
  }

  @override
  void visitChildren(Visitor v) {
    // TODO(cstefantsova): Implement visitChildren.
  }

  @override
  String toString() {
    return "VariableContext(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('[');
    for (int index = 0; index < variables.length; index++) {
      if (index > 0) {
        printer.write(', ');
      }
      variables[index].toTextInternal(printer);
    }
    printer.write(']');
  }
}

/// The collection of the contexts pertaining to a scope-inducing node. The
/// [Scopes] are supposed to be treated as the points of declaration of the
/// variables they contain. They aren't [Statement]s, but a runtime may choose
/// to interpret the [Scope] in an executable way before any [Statement]s or
/// [Expression]s of its node.
class Scope extends TreeNode {
  final List<VariableContext> contexts;

  Scope(this.contexts);

  @override
  R accept<R>(TreeVisitor<R> v) {
    // TODO(cstefantsova): Implement accept.
    throw UnimplementedError();
  }

  @override
  R accept1<R, A>(TreeVisitor1<R, A> v, A arg) {
    // TODO(cstefantsova): Implement accept1.
    throw UnimplementedError();
  }

  @override
  void transformChildren(Transformer v) {
    // TODO(cstefantsova): Implement transformChildren.
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    // TODO(cstefantsova): Implement transformOrRemoveChildren.
  }

  @override
  void visitChildren(Visitor v) {
    // TODO(cstefantsova): Implement visitChildren.
  }

  @override
  String toString() {
    return "Scope(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('[');
    for (int index = 0; index < contexts.length; index++) {
      if (index > 0) {
        printer.write(', ');
      }
      contexts[index].toTextInternal(printer);
    }
    printer.write(']');
  }
}

/// The root of the sealed hierarchy of the nodes that provide a scope, such as
/// loops, functions, and blocks.
sealed class ScopeProvider {
  /// The scope of the [ScopeProvider].
  ///
  /// It's represented as nullable due to the experimental status of the
  /// feature. When the feature isn't enabled, [scope] should return null.
  Scope? get scope;
}
