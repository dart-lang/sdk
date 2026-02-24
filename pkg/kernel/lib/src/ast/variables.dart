// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../../ast.dart';

/// Generalized notion of a variable.
sealed class Variable extends TreeNode implements Annotatable {
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
abstract interface class IExpressionVariable implements TreeNode {
  abstract DartType type;
  abstract String? cosmeticName;
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
  bool get hasIsFinal;
  bool get hasIsConst;
  bool get hasIsLate;
  bool get hasIsInitializingFormal;
  bool get hasIsSynthesized;
  bool get hasIsHoisted;
  bool get hasHasDeclaredInitializer;
  bool get hasIsCovariantByClass;
  bool get hasIsRequired;
  bool get hasIsCovariantByDeclaration;
  bool get hasIsLowered;
  bool get hasIsWildcard;
  bool get hasIsSuperInitializingFormal;
  bool get hasIsErroneouslyInitialized;
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
  abstract List<Expression> annotations;

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
  bool get hasIsFinal;
  @override
  bool get hasIsConst;
  @override
  bool get hasIsLate;
  @override
  bool get hasIsInitializingFormal;
  @override
  bool get hasIsSynthesized;
  @override
  bool get hasIsHoisted;
  @override
  bool get hasHasDeclaredInitializer;
  @override
  bool get hasIsCovariantByClass;
  @override
  bool get hasIsRequired;
  @override
  bool get hasIsCovariantByDeclaration;
  @override
  bool get hasIsLowered;
  @override
  bool get hasIsWildcard;
  @override
  bool get hasIsSuperInitializingFormal;
  @override
  bool get hasIsErroneouslyInitialized;

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

  @override
  List<Expression> annotations = const <Expression>[];

  LocalVariable({
    this.cosmeticName,
    required DartType? type,
    bool isFinal = false,
    bool isConst = false,
    bool isLate = false,
    bool isWildcard = false,
  }) : type = type ?? const DynamicType() {
    this.isFinal = isFinal;
    this.isConst = isConst;
    this.isLate = isLate;
    this.isWildcard = isWildcard;
  }

  @override
  void addAnnotation(Expression annotation) {
    if (annotations.isEmpty) {
      annotations = <Expression>[];
    }
    annotations.add(annotation..parent = this);
  }

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
  void toTextInternal(AstPrinter printer) {
    printer.writeExpressionVariable(this);
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

  @override
  bool get hasIsFinal => true;

  @override
  bool get hasIsConst => true;

  @override
  bool get hasIsLate => true;

  @override
  bool get hasIsInitializingFormal => false;

  @override
  bool get hasIsSynthesized => false;

  @override
  bool get hasIsHoisted => true;

  @override
  bool get hasHasDeclaredInitializer => false;

  @override
  bool get hasIsCovariantByClass => false;

  @override
  bool get hasIsRequired => false;

  @override
  bool get hasIsCovariantByDeclaration => false;

  @override
  bool get hasIsLowered => true;

  @override
  bool get hasIsWildcard => true;

  @override
  bool get hasIsSuperInitializingFormal => false;

  @override
  bool get hasIsErroneouslyInitialized => false;
}

/// Since the `catch` block isn't invoked by the user code, but is redirected to
/// by the runtime, its parameters, the exception and the stack trace,
/// represented by `e` and `s` in the example below, are filled in by the
/// runtime too. The semantics of populating the variables makes them distinct
/// from function parameters, and they have a separate representation from them.
///
///     try {
///       foo();
///     } catch (e, s) {
///       bar();
///     }
class CatchVariable extends ExpressionVariable {
  String catchVariableName;

  @override
  DartType type;

  @override
  List<Expression> annotations = const <Expression>[];

  CatchVariable({
    required String name,
    required DartType? type,
    bool isWildcard = false,
  })  : catchVariableName = name,
        type = type ?? const DynamicType() {
    this.isWildcard = isWildcard;
  }

  @override
  String? get cosmeticName => catchVariableName;

  @override
  void set cosmeticName(String? value) {
    catchVariableName = value!;
  }

  @override
  VariableInitialization? get variableInitialization {
    throw new UnsupportedError("${this.runtimeType}.variableInitialization");
  }

  @override
  void set variableInitialization(VariableInitialization? value) {
    throw new UnsupportedError("${this.runtimeType}.variableInitialization=");
  }

  @override
  void addAnnotation(Expression annotation) {
    if (annotations.isEmpty) {
      annotations = <Expression>[];
    }
    annotations.add(annotation..parent = this);
  }

  static const int FlagWildcard = 1 << 0;

  @override
  bool get isFinal => true;

  @override
  void set isFinal(bool value) {
    throw new UnsupportedError("${this.runtimeType}.isFinal=");
  }

  @override
  bool get isWildcard => flags & FlagWildcard != 0;

  @override
  void set isWildcard(bool value) {
    flags = value ? (flags | FlagWildcard) : (flags & ~FlagWildcard);
  }

  @override
  bool get isConst {
    throw new UnsupportedError("${this.runtimeType}.isConst");
  }

  @override
  void set isConst(bool value) {
    throw new UnsupportedError("${this.runtimeType}.isConst=");
  }

  @override
  bool get isLate {
    throw new UnsupportedError("${this.runtimeType}.isLate");
  }

  @override
  void set isLate(bool value) {
    throw new UnsupportedError("${this.runtimeType}.isLate=");
  }

  @override
  bool get isLowered {
    throw new UnsupportedError("${this.runtimeType}.isLowered");
  }

  @override
  void set isLowered(bool value) {
    throw new UnsupportedError("${this.runtimeType}.isLowered=");
  }

  @override
  bool get isHoisted {
    throw new UnsupportedError("${this.runtimeType}.isHoisted");
  }

  @override
  void set isHoisted(bool value) {
    throw new UnsupportedError("${this.runtimeType}.isHoisted=");
  }

  @override
  bool get isCovariantByClass {
    throw new UnsupportedError("${this.runtimeType}.isCovariantByClass");
  }

  @override
  void set isCovariantByClass(bool value) {
    throw new UnsupportedError("${this.runtimeType}.isCovariantByClass=");
  }

  @override
  bool get isCovariantByDeclaration {
    throw new UnsupportedError("${this.runtimeType}.isCovariantByDeclaration");
  }

  @override
  void set isCovariantByDeclaration(bool value) {
    throw new UnsupportedError("${this.runtimeType}.isCovariantByDeclaration=");
  }

  @override
  bool get isErroneouslyInitialized {
    throw new UnsupportedError("${this.runtimeType}.isErroneouslyInitialized");
  }

  @override
  void set isErroneouslyInitialized(bool value) {
    throw new UnsupportedError("${this.runtimeType}.isErroneouslyInitialized=");
  }

  @override
  bool get hasDeclaredInitializer {
    throw new UnsupportedError("${this.runtimeType}.hasDeclaredInitializer");
  }

  @override
  void set hasDeclaredInitializer(bool value) {
    throw new UnsupportedError("${this.runtimeType}.hasDeclaredInitializer=");
  }

  @override
  bool get isInitializingFormal {
    throw new UnsupportedError("${this.runtimeType}.isInitializingFormal");
  }

  @override
  void set isInitializingFormal(bool value) {
    throw new UnsupportedError("${this.runtimeType}.isInitializingFormal=");
  }

  @override
  bool get isRequired {
    throw new UnsupportedError("${this.runtimeType}.isRequired");
  }

  @override
  void set isRequired(bool value) {
    throw new UnsupportedError("${this.runtimeType}.isRequired=");
  }

  @override
  bool get isSuperInitializingFormal {
    throw new UnsupportedError("${this.runtimeType}.isSuperInitializingFormal");
  }

  @override
  void set isSuperInitializingFormal(bool value) {
    throw new UnsupportedError(
        "${this.runtimeType}.isSuperInitializingFormal=");
  }

  @override
  bool get isSynthesized {
    throw new UnsupportedError("${this.runtimeType}.isSynthesized");
  }

  @override
  void set isSynthesized(bool value) {
    throw new UnsupportedError("${this.runtimeType}.isSynthesized=");
  }

  @override
  bool get isAssignable => false;

  @override
  R accept<R>(TreeVisitor<R> v) => v.visitCatchVariable(this);

  @override
  R accept1<R, A>(TreeVisitor1<R, A> v, A arg) =>
      v.visitCatchVariable(this, arg);

  @override
  void transformChildren(Transformer v) {}

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {}

  @override
  void visitChildren(Visitor v) {}

  @override
  String toString() {
    return "CatchVariable(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeExpressionVariable(this);
  }

  @override
  Expression? get initializer {
    throw new UnsupportedError("${this.runtimeType}.initializer");
  }

  @override
  void set initializer(Expression? value) {
    throw new UnsupportedError("${this.runtimeType}.initializer=");
  }

  @override
  bool get hasIsFinal => false;

  @override
  bool get hasIsConst => false;

  @override
  bool get hasIsLate => false;

  @override
  bool get hasIsInitializingFormal => false;

  @override
  bool get hasIsSynthesized => false;

  @override
  bool get hasIsHoisted => false;

  @override
  bool get hasHasDeclaredInitializer => false;

  @override
  bool get hasIsCovariantByClass => false;

  @override
  bool get hasIsRequired => false;

  @override
  bool get hasIsCovariantByDeclaration => false;

  @override
  bool get hasIsLowered => false;

  @override
  bool get hasIsWildcard => false;

  @override
  bool get hasIsSuperInitializingFormal => false;

  @override
  bool get hasIsErroneouslyInitialized => false;
}

/// Abstract parameter class, the parent for positional and named parameters.
sealed class FunctionParameter extends ExpressionVariable
    implements VariableDeclaration {
  Expression? defaultValue;

  FunctionParameter(
      {required Expression? defaultValue,
      required bool isCovariantByDeclaration,
      required bool isRequired,
      required bool isInitializingFormal,
      required bool isSuperInitializingFormal,
      required bool isFinal,
      required bool hasDeclaredDefaultType,
      required bool isLowered,
      required bool isSynthesized,
      required bool isWildcard}) {
    this.isCovariantByDeclaration = isCovariantByDeclaration;
    this.isRequired = isRequired;
    this.isInitializingFormal = isInitializingFormal;
    this.isSuperInitializingFormal = isSuperInitializingFormal;
    this.isFinal = isFinal;
    this.hasDeclaredDefaultType = hasDeclaredDefaultType;
    this.isLowered = isLowered;
    this.isSynthesized = isSynthesized;
    this.isWildcard = isWildcard;
  }

  /// Function parameters can't be `const` or `late`, so they are assignable if
  /// they aren't final.
  @override
  bool get isAssignable => !isFinal;

  /// Function parameters don't have initializers, only default values.
  @override
  VariableInitialization? get variableInitialization => null;

  @override
  void set variableInitialization(VariableInitialization? value) {}

  @override
  Expression? get initializer => defaultValue;

  @override
  void set initializer(Expression? value) {
    defaultValue = value;
  }

  static const int FlagFinal = 1 << 0;
  static const int FlagWildcard = 1 << 1;
  static const int FlagCovariantByClass = 1 << 2;
  static const int FlagCovariantByDeclaration = 1 << 3;
  static const int FlagInitializingFormal = 1 << 4;
  static const int FlagSuperInitializingFormal = 1 << 5;
  static const int FlagRequired = 1 << 6;
  static const int FlagLowered = 1 << 7;
  static const int FlagHasDeclaredDefaultType = 1 << 8;
  static const int FlagSynthesized = 1 << 9;

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
  bool get isLowered => flags & FlagLowered != 0;

  @override
  void set isLowered(bool value) {
    flags = value ? (flags | FlagLowered) : (flags & ~FlagLowered);
  }

  bool get hasDeclaredDefaultType => flags & FlagHasDeclaredDefaultType != 0;

  void set hasDeclaredDefaultType(bool value) {
    flags = value
        ? (flags | FlagHasDeclaredDefaultType)
        : (flags & ~FlagHasDeclaredDefaultType);
  }

  @override
  bool get hasDeclaredInitializer => hasDeclaredDefaultType;

  @override
  void set hasDeclaredInitializer(bool value) {
    hasDeclaredDefaultType = value;
  }

  @override
  bool get isSynthesized => flags & FlagSynthesized != 0;

  @override
  void set isSynthesized(bool value) {
    flags = value ? (flags | FlagSynthesized) : (flags & ~FlagSynthesized);
  }

  @override
  bool get isLate {
    // Function parameters can't be 'late'.
    return false;
  }

  @override
  void set isLate(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isConst {
    // Function parameters can't be 'const'.
    return false;
  }

  @override
  void set isConst(bool value) {
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
  bool get isHoisted {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  void set isHoisted(bool value) {
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

  @override
  List<Expression> annotations = const <Expression>[];

  PositionalParameter({
    this.cosmeticName,
    required this.type,
    super.defaultValue,
    super.isCovariantByDeclaration = false,
    super.isRequired = false,
    super.isInitializingFormal = false,
    super.isSuperInitializingFormal = false,
    super.isFinal = false,
    super.hasDeclaredDefaultType = false,
    super.isLowered = false,
    super.isSynthesized = false,
    super.isWildcard = false,
  });

  @override
  // TODO(62620): Conforming to [VariableDeclaration] interface. Remove this.
  List<VariableContext>? get contexts {
    throw new UnsupportedError("${this.runtimeType}.contexts");
  }

  @override
  // TODO(62620): Conforming to [VariableDeclaration] interface. Remove this.
  void set contexts(List<VariableContext>? value) {
    throw new UnsupportedError("${this.runtimeType}.contexts=");
  }

  @override
  // TODO(62620): Conforming to [VariableDeclaration] interface. Remove this.
  String get catchVariableName {
    throw new UnsupportedError("${this.runtimeType}.catchVariableName");
  }

  @override
  // TODO(62620): Conforming to [VariableDeclaration] interface. Remove this.
  void set catchVariableName(String value) {
    throw new UnsupportedError("${this.runtimeType}.catchVariableName=");
  }

  @override
  void addAnnotation(Expression annotation) {
    if (annotations.isEmpty) {
      annotations = <Expression>[];
    }
    annotations.add(annotation..parent = this);
  }

  @override
  void clearAnnotations() {
    annotations = const <Expression>[];
  }

  @override
  R accept<R>(StatementVisitor<R> v) => v.visitPositionalParameter(this);

  @override
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg) =>
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
  String? get name => cosmeticName;

  @override
  void set name(String? value) {
    cosmeticName = value;
  }

  @override
  bool get hasIsFinal => true;

  @override
  bool get hasIsConst => true;

  @override
  bool get hasIsLate => true;

  @override
  bool get hasIsInitializingFormal => true;

  @override
  bool get hasIsSynthesized => false;

  @override
  bool get hasIsHoisted => false;

  @override
  bool get hasHasDeclaredInitializer => true;

  @override
  bool get hasIsCovariantByClass => true;

  @override
  bool get hasIsRequired => true;

  @override
  bool get hasIsCovariantByDeclaration => true;

  @override
  bool get hasIsLowered => true;

  @override
  bool get hasIsWildcard => true;

  @override
  bool get hasIsSuperInitializingFormal => true;

  @override
  bool get hasIsErroneouslyInitialized => false;

  @override
  int binaryOffsetNoTag = -1;

  @override
  int fileEqualsOffset = TreeNode.noOffset;

  @override
  ExpressionVariable get variable => this;

  @override
  void set variable(ExpressionVariable value) {
    throw new UnsupportedError("${this.runtimeType}");
  }
}

/// Named parameters. The [name] field is mandatory.
class NamedParameter extends FunctionParameter {
  String parameterName;

  @override
  String? get cosmeticName => parameterName;

  @override
  void set cosmeticName(String? value) {
    parameterName = value!;
  }

  @override
  DartType type;

  @override
  List<Expression> annotations = const <Expression>[];

  NamedParameter(
      {required this.parameterName,
      required this.type,
      super.defaultValue,
      super.isCovariantByDeclaration = false,
      super.isRequired = false,
      super.isInitializingFormal = false,
      super.isSuperInitializingFormal = false,
      super.isFinal = false,
      super.hasDeclaredDefaultType = false,
      super.isLowered = false,
      super.isSynthesized = false,
      super.isWildcard = false});

  @override
  // TODO(62620): Conforming to [VariableDeclaration] interface. Remove this.
  List<VariableContext>? get contexts {
    throw new UnsupportedError("${this.runtimeType}.contexts");
  }

  @override
  // TODO(62620): Conforming to [VariableDeclaration] interface. Remove this.
  void set contexts(List<VariableContext>? value) {
    throw new UnsupportedError("${this.runtimeType}.contexts=");
  }

  @override
  // TODO(62620): Conforming to [VariableDeclaration] interface. Remove this.
  String get catchVariableName {
    throw new UnsupportedError("${this.runtimeType}.catchVariableName");
  }

  @override
  // TODO(62620): Conforming to [VariableDeclaration] interface. Remove this.
  void set catchVariableName(String value) {
    throw new UnsupportedError("${this.runtimeType}.catchVariableName=");
  }

  @override
  void addAnnotation(Expression annotation) {
    if (annotations.isEmpty) {
      annotations = <Expression>[];
    }
    annotations.add(annotation..parent = this);
  }

  @override
  void clearAnnotations() {
    annotations = const <Expression>[];
  }

  @override
  R accept<R>(StatementVisitor<R> v) => v.visitNamedParameter(this);

  @override
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg) =>
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
  bool get hasIsFinal => true;

  @override
  bool get hasIsConst => true;

  @override
  bool get hasIsLate => true;

  @override
  bool get hasIsInitializingFormal => true;

  @override
  bool get hasIsSynthesized => false;

  @override
  bool get hasIsHoisted => false;

  @override
  bool get hasHasDeclaredInitializer => true;

  @override
  bool get hasIsCovariantByClass => true;

  @override
  bool get hasIsRequired => true;

  @override
  bool get hasIsCovariantByDeclaration => true;

  @override
  bool get hasIsLowered => true;

  @override
  bool get hasIsWildcard => true;

  @override
  bool get hasIsSuperInitializingFormal => true;

  @override
  bool get hasIsErroneouslyInitialized => false;

  @override
  int binaryOffsetNoTag = -1;

  @override
  int fileEqualsOffset = TreeNode.noOffset;

  @override
  String? get name => parameterName;

  @override
  void set name(String? value) {
    parameterName = value!;
  }

  @override
  ExpressionVariable get variable => this;

  @override
  void set variable(ExpressionVariable value) {
    throw new UnsupportedError("${this.runtimeType}");
  }
}

/// The variable storage for `this`.
class ThisVariable extends ExpressionVariable {
  @override
  String get cosmeticName => "this-variable";

  @override
  void set cosmeticName(String? value) {}

  @override
  VariableInitialization? get variableInitialization => null;

  @override
  void set variableInitialization(VariableInitialization? value) {}

  @override
  DartType type;

  // TODO(cstefantsova): Consider a throwing implementation instead.
  @override
  List<Expression> annotations = const <Expression>[];

  ThisVariable({required this.type});

  // TODO(cstefantsova): Consider a throwing implementation instead.
  @override
  void addAnnotation(Expression annotation) {
    if (annotations.isEmpty) {
      annotations = <Expression>[];
    }
    annotations.add(annotation..parent = this);
  }

  @override
  bool get isConst => false;

  @override
  void set isConst(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isLate => false;

  @override
  void set isLate(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isFinal => false;

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

  @override
  bool get hasIsFinal => true;

  @override
  bool get hasIsConst => true;

  @override
  bool get hasIsLate => true;

  @override
  bool get hasIsInitializingFormal => false;

  @override
  bool get hasIsSynthesized => false;

  @override
  bool get hasIsHoisted => false;

  @override
  bool get hasHasDeclaredInitializer => false;

  @override
  bool get hasIsCovariantByClass => false;

  @override
  bool get hasIsRequired => false;

  @override
  bool get hasIsCovariantByDeclaration => false;

  @override
  bool get hasIsLowered => false;

  @override
  bool get hasIsWildcard => false;

  @override
  bool get hasIsSuperInitializingFormal => false;

  @override
  bool get hasIsErroneouslyInitialized => false;
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

  // TODO(cstefantsova): Consider a throwing implementation instead.
  @override
  List<Expression> annotations = const <Expression>[];

  SyntheticVariable({this.cosmeticName, required this.type});

  // TODO(cstefantsova): Consider a throwing implementation instead.
  @override
  void addAnnotation(Expression annotation) {
    if (annotations.isEmpty) {
      annotations = <Expression>[];
    }
    annotations.add(annotation..parent = this);
  }

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

  @override
  bool get hasIsFinal => true;

  @override
  bool get hasIsConst => false;

  @override
  bool get hasIsLate => false;

  @override
  bool get hasIsInitializingFormal => false;

  @override
  bool get hasIsSynthesized => false;

  @override
  bool get hasIsHoisted => true;

  @override
  bool get hasHasDeclaredInitializer => false;

  @override
  bool get hasIsCovariantByClass => false;

  @override
  bool get hasIsRequired => false;

  @override
  bool get hasIsCovariantByDeclaration => false;

  @override
  bool get hasIsLowered => true;

  @override
  bool get hasIsWildcard => false;

  @override
  bool get hasIsSuperInitializingFormal => false;

  @override
  bool get hasIsErroneouslyInitialized => false;
}

/// The enum reflecting the kind of a variable context. A context is
/// [assertCaptured] if it contains the variables captured in a closure within
/// an `assert` and not captured anywhere outside of `assert`s.
enum CaptureKind {
  notCaptured,
  directCaptured,
  assertCaptured;
}

/// The box storing some of the variables in the scope it's associated with. It
/// serves as the "declaration" of the variables it contains for the runtime
/// environments.
class VariableContext extends TreeNode {
  final CaptureKind captureKind;
  final List<Variable> variables;

  VariableContext({required this.captureKind, required this.variables});

  void addVariable(Variable variable) {
    variable.parent = this;
    variables.add(variable);
  }

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

  void addContext(VariableContext context) {
    context.parent = this;
    contexts.add(context);
  }

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
sealed class ScopeProvider implements TreeNode {
  /// Scope of the [ScopeProvider].
  ///
  /// It's represented as nullable due to the experimental status of the
  /// feature. When the feature isn't enabled, [scope] should return null.
  abstract Scope? scope;
}

/// The root of the sealed hierarchy of the nodes that consume variable
/// contexts, that is, they capture variables from those contexts, such as
/// functions or initialization nodes of late variables.
sealed class ContextConsumer implements TreeNode {
  /// Contexts the variables captured by [ContextConsumer] are from.
  abstract List<VariableContext>? contexts;
}
