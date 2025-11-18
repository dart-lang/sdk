// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../../ast.dart';

/// Generalized notion of a variable.
sealed class Variable extends TreeNode {
  VariableContext get context => parent as VariableContext;

  /// The cosmetic name of the variable from the source code, if exists.
  String? get cosmeticName;

  void set cosmeticName(String? value);

  int flags = 0;

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write(printer.getVariableName(this));
  }
}

/// This is a helper class to enable mixing a mixin into concrete
/// implementations of the sealed class [ExpressionVariable]. It's not supposed
/// to be used as a type annotation, but purely for declaring the class
/// hierarchy.
abstract interface class IExpressionVariable {
  abstract DartType type;
  abstract VariableInitialization? variableInitialization;
  abstract Expression? initializer;
  abstract bool isFinal;
  abstract bool isConst;
  abstract bool isLate;
  abstract bool isInitializingFormal;
  abstract bool isSynthesized;
  abstract bool isHoisted;
  abstract bool hasDeclaredInitializer;
  abstract bool isCovariantByClass;
  abstract bool isRequired;
  abstract bool isCovariantByDeclaration;
  abstract bool isLowered;
  abstract bool isWildcard;
  abstract bool isSuperInitializingFormal;
  abstract bool isErroneouslyInitialized;
  bool get isAssignable;
  ExpressionVariable get asExpressionVariable;
}

/// The root of the sealed hierarchy of non-type variables.
sealed class ExpressionVariable extends Variable
    implements IExpressionVariable {
  /// Static type of the variable.
  @override
  abstract DartType type;

  /// Initialization node for the variable, if available.
  @override
  abstract VariableInitialization? variableInitialization;

  /// Derived from [variableInitialization], if available.
  @override
  abstract Expression? initializer;

  @override
  abstract bool isFinal;
  @override
  abstract bool isConst;
  @override
  abstract bool isLate;
  @override
  abstract bool isInitializingFormal;
  @override
  abstract bool isSynthesized;
  @override
  abstract bool isHoisted;
  @override
  abstract bool hasDeclaredInitializer;
  @override
  abstract bool isCovariantByClass;
  @override
  abstract bool isRequired;
  @override
  abstract bool isCovariantByDeclaration;
  @override
  abstract bool isLowered;
  @override
  abstract bool isWildcard;
  @override
  abstract bool isSuperInitializingFormal;
  @override
  abstract bool isErroneouslyInitialized;

  @override
  bool get isAssignable;

  @override
  ExpressionVariable get asExpressionVariable => this;
}

/// Local variables. They aren't Statements. A [LocalVariable] is "declared" in
/// the [VariableContext] it appears in. [VariableInitialization]
/// (which is a [Statement]) marks the spot of the original variable declaration
/// in the Dart program.
class LocalVariable extends ExpressionVariable {
  @override
  String? cosmeticName;

  @override
  DartType type;

  @override
  VariableInitialization? variableInitialization;

  LocalVariable({this.cosmeticName, required DartType? type})
      : type = type ?? const DynamicType();

  static const int FlagFinal = 1 << 0;
  static const int FlagWildcard = 1 << 1;
  static const int FlagConst = 1 << 2;
  static const int FlagLate = 1 << 3;
  static const int FlagLowered = 1 << 4;
  static const int FlagHoisted = 1 << 5;

  @override
  bool get isFinal => flags & FlagFinal != 0;

  @override
  void set isFinal(bool value) {
    flags = value ? (flags | FlagFinal) : (flags & ~FlagFinal);
  }

  @override
  bool get isWildcard => flags & FlagWildcard != 0;

  @override
  void set isWildcard(bool value) {
    flags = value ? (flags | FlagWildcard) : (flags & ~FlagWildcard);
  }

  @override
  bool get isConst => flags & FlagConst != 0;

  @override
  void set isConst(bool value) {
    flags = value ? (flags | FlagConst) : (flags & ~FlagConst);
  }

  @override
  bool get isLate => flags & FlagLate != 0;

  @override
  void set isLate(bool value) {
    flags = value ? (flags | FlagLate) : (flags & ~FlagLate);
  }

  @override
  bool get isLowered => flags & FlagLowered != 0;

  @override
  void set isLowered(bool value) {
    flags = value ? (flags | FlagLowered) : (flags & ~FlagLowered);
  }

  @override
  bool get isHoisted => flags & FlagHoisted != 0;

  @override
  void set isHoisted(bool value) {
    flags = value ? (flags | FlagHoisted) : (flags & ~FlagHoisted);
  }

  @override
  bool get isCovariantByClass {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  void set isCovariantByClass(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isCovariantByDeclaration {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  void set isCovariantByDeclaration(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isErroneouslyInitialized {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  void set isErroneouslyInitialized(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get hasDeclaredInitializer {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  void set hasDeclaredInitializer(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isInitializingFormal {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  void set isInitializingFormal(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isRequired {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  void set isRequired(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isSuperInitializingFormal {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  void set isSuperInitializingFormal(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isSynthesized {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  void set isSynthesized(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isAssignable {
    if (isConst) return false;
    if (isFinal) {
      if (isLate) return variableInitialization?.initializer == null;
      return false;
    }
    return true;
  }

  @override
  R accept<R>(TreeVisitor<R> v) => v.visitLocalVariable(this);

  @override
  R accept1<R, A>(TreeVisitor1<R, A> v, A arg) =>
      v.visitLocalVariable(this, arg);

  @override
  void transformChildren(Transformer v) {}

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {}

  @override
  void visitChildren(Visitor v) {}

  @override
  String toString() {
    return "LocalVariable(${toStringInternal()})";
  }

  @override
  Expression? get initializer => variableInitialization?.initializer;

  @override
  void set initializer(Expression? value) {
    if (value != null && variableInitialization == null) {
      throw new StateError("Attempt to assign initializer to variable "
          "without an initialization node.");
    }
    variableInitialization!.initializer = value;
  }

  String? get name => cosmeticName;
}

/// Abstract parameter class, the parent for positional and named parameters.
sealed class FunctionParameter extends ExpressionVariable {
  /// Function parameters can't be `const` or `late`, so they are assignable if
  /// they aren't final.
  @override
  bool get isAssignable => !isFinal;

  /// Function parameters don't have initializers, only default values.
  @override
  VariableInitialization? get variableInitialization => null;

  @override
  void set variableInitialization(VariableInitialization? value) {}

  static const int FlagFinal = 1 << 0;
  static const int FlagWildcard = 1 << 1;
  static const int FlagCovariantByClass = 1 << 2;
  static const int FlagCovariantByDeclaration = 1 << 3;
  static const int FlagInitializingFormal = 1 << 4;
  static const int FlagSuperInitializingFormal = 1 << 5;
  static const int FlagRequired = 1 << 6;

  @override
  bool get isFinal => flags & FlagFinal != 0;

  @override
  void set isFinal(bool value) {
    flags = value ? (flags | FlagFinal) : (flags & ~FlagFinal);
  }

  @override
  bool get isWildcard => flags & FlagWildcard != 0;

  @override
  void set isWildcard(bool value) {
    flags = value ? (flags | FlagWildcard) : (flags & ~FlagWildcard);
  }

  @override
  bool get isCovariantByClass => flags & FlagCovariantByClass != 0;

  @override
  void set isCovariantByClass(bool value) {
    flags = value
        ? (flags | FlagCovariantByClass)
        : (flags & ~FlagCovariantByClass);
  }

  @override
  bool get isCovariantByDeclaration => flags & FlagCovariantByDeclaration != 0;

  @override
  void set isCovariantByDeclaration(bool value) {
    flags = value
        ? (flags | FlagCovariantByDeclaration)
        : (flags & ~FlagCovariantByDeclaration);
  }

  @override
  bool get isInitializingFormal => flags & FlagInitializingFormal != 0;

  @override
  void set isInitializingFormal(bool value) {
    flags = value
        ? (flags | FlagInitializingFormal)
        : (flags & ~FlagInitializingFormal);
  }

  @override
  bool get isSuperInitializingFormal =>
      flags & FlagSuperInitializingFormal != 0;

  @override
  void set isSuperInitializingFormal(bool value) {
    flags = value
        ? (flags | FlagSuperInitializingFormal)
        : (flags & ~FlagSuperInitializingFormal);
  }

  @override
  bool get isRequired => flags & FlagRequired != 0;

  @override
  void set isRequired(bool value) {
    flags = value ? (flags | FlagRequired) : (flags & ~FlagRequired);
  }

  @override
  bool get isErroneouslyInitialized {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  void set isErroneouslyInitialized(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get hasDeclaredInitializer {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  void set hasDeclaredInitializer(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isSynthesized {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  void set isSynthesized(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isConst {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  void set isConst(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isLate {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  void set isLate(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isHoisted {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  void set isHoisted(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isLowered {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  void set isLowered(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }
}

/// Positional parameters. The [cosmeticName] field is optional and doesn't
/// affect the runtime semantics of the program.
class PositionalParameter extends FunctionParameter {
  @override
  String? cosmeticName;

  @override
  DartType type;

  PositionalParameter({this.cosmeticName, required this.type});

  @override
  bool get isRequired {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  void set isRequired(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  R accept<R>(TreeVisitor<R> v) => v.visitPositionalParameter(this);

  @override
  R accept1<R, A>(TreeVisitor1<R, A> v, A arg) =>
      v.visitPositionalParameter(this, arg);

  @override
  void transformChildren(Transformer v) {}

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {}

  @override
  void visitChildren(Visitor v) {}

  @override
  String toString() {
    return "PositionalParameter(${toStringInternal()})";
  }

  @override
  Expression? get initializer {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  void set initializer(Expression? value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  String? get name => cosmeticName;
}

/// Named parameters. The [name] field is mandatory.
class NamedParameter extends FunctionParameter {
  String name;

  @override
  String get cosmeticName => name;

  @override
  void set cosmeticName(String? value) {
    name = value!;
  }

  @override
  DartType type;

  NamedParameter({required this.name, required this.type});

  @override
  R accept<R>(TreeVisitor<R> v) => v.visitNamedParameter(this);

  @override
  R accept1<R, A>(TreeVisitor1<R, A> v, A arg) =>
      v.visitNamedParameter(this, arg);

  @override
  void transformChildren(Transformer v) {}

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {}

  @override
  void visitChildren(Visitor v) {}

  @override
  String toString() {
    return "NamedParameter(${toStringInternal()})";
  }

  @override
  Expression? get initializer {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  void set initializer(Expression? value) {
    throw new UnsupportedError("${this.runtimeType}");
  }
}

/// The variable storage for `this`.
class ThisVariable extends ExpressionVariable {
  @override
  String get cosmeticName => "this";

  @override
  void set cosmeticName(String? value) {}

  @override
  VariableInitialization? get variableInitialization => null;

  @override
  void set variableInitialization(VariableInitialization? value) {}

  @override
  DartType type;

  ThisVariable({required this.type});

  @override
  bool get isFinal {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  void set isFinal(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isWildcard {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  void set isWildcard(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isCovariantByClass {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  void set isCovariantByClass(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isCovariantByDeclaration {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  void set isCovariantByDeclaration(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isInitializingFormal {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  void set isInitializingFormal(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isSuperInitializingFormal {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  void set isSuperInitializingFormal(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isErroneouslyInitialized {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  void set isErroneouslyInitialized(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get hasDeclaredInitializer {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  void set hasDeclaredInitializer(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isRequired {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  void set isRequired(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isSynthesized {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  void set isSynthesized(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isConst {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  void set isConst(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isLate {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  void set isLate(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isHoisted {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  void set isHoisted(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isLowered {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  void set isLowered(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  R accept<R>(TreeVisitor<R> v) => v.visitThisVariable(this);

  @override
  R accept1<R, A>(TreeVisitor1<R, A> v, A arg) =>
      v.visitThisVariable(this, arg);

  @override
  void transformChildren(Transformer v) {}

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {}

  @override
  void visitChildren(Visitor v) {}

  @override
  String toString() {
    return "ThisVariable(${toStringInternal()})";
  }

  @override
  bool get isAssignable => false;

  @override
  Expression? get initializer {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  void set initializer(Expression? value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  String? get name => cosmeticName;
}

/// A variable introduced during desugaring. Such variables don't correspond to
/// any variable declared by the programmer.
class SyntheticVariable extends ExpressionVariable {
  @override
  String? cosmeticName;

  @override
  DartType type;

  @override
  VariableInitialization? variableInitialization;

  SyntheticVariable({this.cosmeticName, required this.type});

  static const int FlagFinal = 1 << 0;
  static const int FlagLowered = 1 << 1;
  static const int FlagHoisted = 1 << 2;

  @override
  bool get isFinal => flags & FlagFinal != 0;

  @override
  void set isFinal(bool value) {
    flags = value ? (flags | FlagFinal) : (flags & ~FlagFinal);
  }

  @override
  bool get isLowered => flags & FlagLowered != 0;

  @override
  void set isLowered(bool value) {
    flags = value ? (flags | FlagLowered) : (flags & ~FlagLowered);
  }

  @override
  bool get isHoisted => flags & FlagHoisted != 0;

  @override
  void set isHoisted(bool value) {
    flags = value ? (flags | FlagHoisted) : (flags & ~FlagHoisted);
  }

  @override
  bool get isCovariantByClass {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  void set isCovariantByClass(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isCovariantByDeclaration {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  void set isCovariantByDeclaration(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isErroneouslyInitialized {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  void set isErroneouslyInitialized(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get hasDeclaredInitializer {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  void set hasDeclaredInitializer(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isInitializingFormal {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  void set isInitializingFormal(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isRequired {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  void set isRequired(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isSuperInitializingFormal {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  void set isSuperInitializingFormal(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isSynthesized {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  void set isSynthesized(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isConst {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  void set isConst(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isLate {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  void set isLate(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isWildcard {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  void set isWildcard(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  R accept<R>(TreeVisitor<R> v) => v.visitSyntheticVariable(this);

  @override
  R accept1<R, A>(TreeVisitor1<R, A> v, A arg) =>
      v.visitSyntheticVariable(this, arg);

  @override
  void transformChildren(Transformer v) {}

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {}

  @override
  void visitChildren(Visitor v) {}

  @override
  String toString() {
    return "SyntheticVariable(${toStringInternal()})";
  }

  @override
  bool get isAssignable => !isConst && !isFinal;

  @override
  Expression? get initializer => variableInitialization?.initializer;

  @override
  void set initializer(Expression? value) {
    if (value != null && variableInitialization == null) {
      throw new StateError("Attempt to assign initializer to variable "
          "without an initialization node.");
    }
    variableInitialization!.initializer = value;
  }

  String? get name => cosmeticName;
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
    throw new UnimplementedError();
  }

  @override
  R accept1<R, A>(TreeVisitor1<R, A> v, A arg) {
    // TODO(cstefantsova): Implement accept1.
    throw new UnimplementedError();
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

  Scope({required this.contexts});

  @override
  R accept<R>(TreeVisitor<R> v) {
    // TODO(cstefantsova): Implement accept.
    throw new UnimplementedError();
  }

  @override
  R accept1<R, A>(TreeVisitor1<R, A> v, A arg) {
    // TODO(cstefantsova): Implement accept1.
    throw new UnimplementedError();
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
