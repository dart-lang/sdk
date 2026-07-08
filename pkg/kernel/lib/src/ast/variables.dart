// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../../ast.dart';

/// Generalized notion of a variable.
sealed class VariableBase extends TreeNode implements Annotatable {
  abstract VariableContext context;

  /// The cosmetic name of the variable from the source code, if exists.
  String? get cosmeticName;

  void set cosmeticName(String? value);

  int flags = 0;

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write(printer.getVariableName(this));
  }
}

/// The root of the sealed hierarchy of non-type variables.
sealed class Variable extends VariableBase implements ContextConsumer {
  // These flags are shared between all [Variable]s since they must all be
  // serialized uniformly.
  static const int FlagFinal = 1 << 0; // Must match serialized bit positions.
  static const int FlagConst = 1 << 1;
  static const int FlagHasDeclaredInitializer = 1 << 2;
  static const int FlagInitializingFormal = 1 << 3;
  static const int FlagCovariantByClass = 1 << 4;
  static const int FlagLate = 1 << 5;
  static const int FlagRequired = 1 << 6;
  static const int FlagCovariantByDeclaration = 1 << 7;
  static const int FlagLowered = 1 << 8;
  static const int FlagSynthesized = 1 << 9;
  static const int FlagHoisted = 1 << 10;
  static const int FlagWildcard = 1 << 11;
  static const int FlagSuperInitializingFormal = 1 << 12;
  static const int FlagErroneouslyInitialized = 1 << 13;
  static const int FlagRenamedPrivateNamedParameter = 1 << 14;

  /// The static type of the variable, either declared or inferred type during
  /// type inference.
  abstract DartType type;

  /// For locals, this is the initial value.
  /// For parameters, this is the default value.
  ///
  /// Should be null in other cases.
  abstract Expression? initializer;

  /// List of metadata annotations on the variable declaration.
  ///
  /// This defaults to an immutable empty list. Use [addAnnotation] to add
  /// annotations if needed.
  @override
  abstract List<Expression> annotations;

  /// Whether the variable is declared with the `final` keyword.
  abstract bool isFinal;

  /// Whether the variable is declared with the `const` keyword.
  abstract bool isConst;

  /// Whether the variable is declared with the `late` keyword.
  ///
  /// The `late` modifier is only supported on local variables and not on
  /// parameters.
  abstract bool isLate;

  /// Whether the variable is declared as an initializing formal parameter of
  /// a constructor.
  abstract bool isInitializingFormal;

  /// Whether this variable is synthesized, that is, it is _not_ declared in
  /// the source code.
  ///
  /// The name of a variable can only be omitted if the variable is synthesized.
  /// Otherwise, its name is as provided in the source code.
  abstract bool isSynthesized;

  /// Whether the declaration of this variable is has been moved to an earlier
  /// source location.
  ///
  /// This is for instance the case for variables declared in a pattern, where
  /// the lowering requires the variable to be declared before the expression
  /// that performs that matching in which its initialization occurs.
  abstract bool isHoisted;

  /// Whether the variable has an initializer, either by declaration or copied
  /// from an original declaration.
  ///
  /// Note that the variable might have a synthesized initializer expression,
  /// so `hasDeclaredInitializer == false` doesn't imply `initializer == null`.
  /// For instance, for duplicate variable names, an invalid expression is set
  /// as the initializer of the second variable.
  abstract bool hasDeclaredInitializer;

  /// If this [Variable] is a parameter of a method, indicates
  /// whether the method implementation needs to contain a runtime type check to
  /// deal with generic covariance.
  ///
  /// When `true`, runtime checks may need to be performed.
  abstract bool isCovariantByClass;

  /// Whether the parameter is declared with the `required` keyword.
  ///
  /// The `required` modifier is only supported on named parameters and not on
  /// positional parameters and local variables.
  abstract bool isRequired;

  /// Whether the parameter is declared with the `covariant` keyword.
  abstract bool isCovariantByDeclaration;

  /// Whether the variable is part of a lowering.
  ///
  /// If a variable is part of a lowering its name may be synthesized so that it
  /// doesn't reflect the name used in the source code and might not have a
  /// one-to-one correspondence with the variable in the source.
  ///
  /// Lowering is used for instance of encoding of 'this' in extension instance
  /// members and encoding of late locals.
  abstract bool isLowered;

  /// Whether the variable is a wildcard variable, that is, it was named '_' in
  /// the source code with the wildcard feature enabled..
  abstract bool isWildcard;

  /// Whether the variable is declared as a super initializing formal parameter
  /// of a constructor.
  abstract bool isSuperInitializingFormal;
  abstract bool isErroneouslyInitialized;

  /// Offset of the declaration, set and used when writing the binary.
  abstract int binaryOffsetNoTag;

  /// Offset of the equals sign in the source file it comes from.
  ///
  /// Valid values are from 0 and up, or -1 ([TreeNode.noOffset])
  /// if the equals sign offset is not available (e.g. if not initialized)
  /// (this is the default if none is specifically set).
  abstract int fileEqualsOffset;

  void clearAnnotations();

  @override
  List<int>? get fileOffsetsIfMultiple => [fileOffset, fileEqualsOffset];

  /// Whether the variable is assignable.
  ///
  /// This is `true` if the variable is neither constant nor final, or if it
  /// is late final without an initializer.
  bool get isAssignable;

  @override
  R accept<R>(VariableVisitor<R> visitor);

  @override
  R accept1<R, A>(VariableVisitor1<R, A> visitor, A arg);

  @override
  void toTextInternal(AstPrinter printer) {
    // TODO(johnniwinther): Update this.
    printer.writeVariableInitialization(this);
    printer.write(';');
  }
}

/// A variable declared within the body of a member.
///
/// This excludes [FunctionParameter], [ThisVariable] and [CatchVariable] which
/// are all declared by the enclosing node.
sealed class DeclaredVariable extends Variable {
  /// Declaration node for the variable, if available.
  abstract VariableDeclaration? variableDeclaration;
}

/// Local variables. They aren't Statements. A [LocalVariable] is "declared" in
/// the [VariableContext] it appears in. [VariableInitializationBase]
/// (which is a [Statement]) marks the spot of the original variable declaration
/// in the Dart program.
class LocalVariable extends DeclaredVariable {
  /// The name of the variable as provided in the source code.
  String name;

  @override
  DartType type;

  @override
  VariableDeclaration? variableDeclaration;

  @override
  List<Expression> annotations = const <Expression>[];

  @override
  late VariableContext context;

  @override
  // TODO(johnniwinther): Remove this.
  Expression? initializer;

  new({
    required this.name,
    DartType? type,
    bool isFinal = false,
    bool isWildcard = false,
    bool hasDeclaredInitializer = false,
    this.initializer,
  }) : type = type ?? const DynamicType() {
    this.isFinal = isFinal;
    this.isWildcard = isWildcard;
    this.hasDeclaredInitializer = hasDeclaredInitializer;
    this.initializer?.parent = this;
  }

  @override
  void addAnnotation(Expression annotation) {
    if (annotations.isEmpty) {
      annotations = <Expression>[];
    }
    annotations.add(annotation..parent = this);
  }

  @override
  bool get isFinal => flags & Variable.FlagFinal != 0;

  @override
  void set isFinal(bool value) {
    flags = value
        ? (flags | Variable.FlagFinal)
        : (flags & ~Variable.FlagFinal);
  }

  @override
  bool get isWildcard => flags & Variable.FlagWildcard != 0;

  @override
  void set isWildcard(bool value) {
    flags = value
        ? (flags | Variable.FlagWildcard)
        : (flags & ~Variable.FlagWildcard);
  }

  @override
  bool get isConst => flags & Variable.FlagConst != 0;

  @override
  void set isConst(bool value) {
    flags = value
        ? (flags | Variable.FlagConst)
        : (flags & ~Variable.FlagConst);
  }

  @override
  bool get isLate => flags & Variable.FlagLate != 0;

  @override
  void set isLate(bool value) {
    flags = value ? (flags | Variable.FlagLate) : (flags & ~Variable.FlagLate);
  }

  @override
  bool get isLowered => flags & Variable.FlagLowered != 0;

  @override
  void set isLowered(bool value) {
    flags = value
        ? (flags | Variable.FlagLowered)
        : (flags & ~Variable.FlagLowered);
  }

  @override
  bool get isHoisted => flags & Variable.FlagHoisted != 0;

  @override
  void set isHoisted(bool value) {
    flags = value
        ? (flags | Variable.FlagHoisted)
        : (flags & ~Variable.FlagHoisted);
  }

  @override
  bool get isCovariantByClass => false;

  @override
  void set isCovariantByClass(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isCovariantByDeclaration => false;

  @override
  void set isCovariantByDeclaration(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isErroneouslyInitialized =>
      flags & Variable.FlagErroneouslyInitialized != 0;

  @override
  void set isErroneouslyInitialized(bool value) {
    flags = value
        ? (flags | Variable.FlagErroneouslyInitialized)
        : (flags & ~Variable.FlagErroneouslyInitialized);
  }

  @override
  bool get hasDeclaredInitializer =>
      flags & Variable.FlagHasDeclaredInitializer != 0;

  @override
  void set hasDeclaredInitializer(bool value) {
    flags = value
        ? (flags | Variable.FlagHasDeclaredInitializer)
        : (flags & ~Variable.FlagHasDeclaredInitializer);
  }

  @override
  bool get isInitializingFormal => false;

  @override
  void set isInitializingFormal(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isRequired => false;

  @override
  void set isRequired(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isSuperInitializingFormal => false;

  @override
  void set isSuperInitializingFormal(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isSynthesized => false;

  @override
  void set isSynthesized(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isAssignable {
    if (isConst) return false;
    if (isFinal) {
      if (isLate) return initializer == null;
      return false;
    }
    return true;
  }

  @override
  R accept<R>(VariableVisitor<R> v) => v.visitLocalVariable(this);

  @override
  R accept1<R, A>(VariableVisitor1<R, A> v, A arg) =>
      v.visitLocalVariable(this, arg);

  @override
  void transformChildren(Transformer v) {
    v.transformList(annotations, this);
    type = v.visitDartType(type);
    if (initializer != null) {
      initializer = v.transform(initializer!);
      initializer?.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    v.transformExpressionList(annotations, this);
    type = v.visitDartType(type, cannotRemoveSentinel);
    if (initializer != null) {
      initializer = v.transformOrRemoveExpression(initializer!);
      initializer?.parent = this;
    }
  }

  @override
  void visitChildren(Visitor v) {
    visitList(annotations, v);
    type.accept(v);
    initializer?.accept(v);
  }

  @override
  String toString() {
    return "LocalVariable(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeExpressionVariable(this);
  }

  @override
  int binaryOffsetNoTag = -1;

  @override
  List<VariableContext>? get capturedContexts {
    throw new UnsupportedError("${this.runtimeType}.capturedContexts");
  }

  @override
  void set capturedContexts(List<VariableContext>? value) {
    throw new UnsupportedError("${this.runtimeType}.capturedContexts=");
  }

  @override
  int fileEqualsOffset = TreeNode.noOffset;

  @override
  void clearAnnotations() {
    annotations.clear();
  }

  @override
  String? get cosmeticName => name;

  @override
  void set cosmeticName(String? value) {
    name = value!;
  }
}

/// Variable for a local function declaration.
///
/// Local functions, declared using [FunctionDeclaration], have a
/// [LocalFunctionVariable] which hold their name and is used to identify the
/// function in [LocalFunctionInvocation]s and tear-offs through [VariableGet].
class LocalFunctionVariable extends DeclaredVariable {
  /// The name of the variable as provided in the source code.
  String name;

  @override
  DartType type;

  @override
  VariableDeclaration? variableDeclaration;

  @override
  List<Expression> annotations = const <Expression>[];

  @override
  late VariableContext context;

  @override
  // TODO(johnniwinther): Remove this.
  Expression? initializer;

  new({
    required this.name,
    DartType? type,
    bool isWildcard = false,
    bool isLowered = false,
    bool isSynthesized = false,
  }) : type = type ?? const DynamicType() {
    this.isFinal = true;
    this.isWildcard = isWildcard;
    this.isLowered = isLowered;
    this.isSynthesized = isSynthesized;
  }

  @override
  void addAnnotation(Expression annotation) {
    if (annotations.isEmpty) {
      annotations = <Expression>[];
    }
    annotations.add(annotation..parent = this);
  }

  @override
  bool get isFinal => flags & Variable.FlagFinal != 0;

  @override
  void set isFinal(bool value) {
    flags = value
        ? (flags | Variable.FlagFinal)
        : (flags & ~Variable.FlagFinal);
  }

  @override
  bool get isWildcard => flags & Variable.FlagWildcard != 0;

  @override
  void set isWildcard(bool value) {
    flags = value
        ? (flags | Variable.FlagWildcard)
        : (flags & ~Variable.FlagWildcard);
  }

  @override
  bool get isConst => flags & Variable.FlagConst != 0;

  @override
  void set isConst(bool value) {
    flags = value
        ? (flags | Variable.FlagConst)
        : (flags & ~Variable.FlagConst);
  }

  @override
  bool get isLate => flags & Variable.FlagLate != 0;

  @override
  void set isLate(bool value) {
    flags = value ? (flags | Variable.FlagLate) : (flags & ~Variable.FlagLate);
  }

  @override
  bool get isLowered => flags & Variable.FlagLowered != 0;

  @override
  void set isLowered(bool value) {
    flags = value
        ? (flags | Variable.FlagLowered)
        : (flags & ~Variable.FlagLowered);
  }

  @override
  bool get isHoisted => flags & Variable.FlagHoisted != 0;

  @override
  void set isHoisted(bool value) {
    flags = value
        ? (flags | Variable.FlagHoisted)
        : (flags & ~Variable.FlagHoisted);
  }

  @override
  bool get isCovariantByClass => false;

  @override
  void set isCovariantByClass(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isCovariantByDeclaration => false;

  @override
  void set isCovariantByDeclaration(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isErroneouslyInitialized =>
      flags & Variable.FlagErroneouslyInitialized != 0;

  @override
  void set isErroneouslyInitialized(bool value) {
    flags = value
        ? (flags | Variable.FlagErroneouslyInitialized)
        : (flags & ~Variable.FlagErroneouslyInitialized);
  }

  @override
  bool get hasDeclaredInitializer =>
      flags & Variable.FlagHasDeclaredInitializer != 0;

  @override
  void set hasDeclaredInitializer(bool value) {
    flags = value
        ? (flags | Variable.FlagHasDeclaredInitializer)
        : (flags & ~Variable.FlagHasDeclaredInitializer);
  }

  @override
  bool get isInitializingFormal => false;

  @override
  void set isInitializingFormal(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isRequired => false;

  @override
  void set isRequired(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isSuperInitializingFormal => false;

  @override
  void set isSuperInitializingFormal(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isSynthesized => flags & Variable.FlagSynthesized != 0;

  @override
  void set isSynthesized(bool value) {
    flags = value
        ? (flags | Variable.FlagSynthesized)
        : (flags & ~Variable.FlagSynthesized);
  }

  @override
  bool get isAssignable {
    if (isConst) return false;
    if (isFinal) {
      if (isLate) return initializer == null;
      return false;
    }
    return true;
  }

  @override
  R accept<R>(VariableVisitor<R> v) => v.visitLocalFunctionVariable(this);

  @override
  R accept1<R, A>(VariableVisitor1<R, A> v, A arg) =>
      v.visitLocalFunctionVariable(this, arg);

  @override
  void transformChildren(Transformer v) {
    v.transformList(annotations, this);
    type = v.visitDartType(type);
    if (initializer != null) {
      initializer = v.transform(initializer!);
      initializer?.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    v.transformExpressionList(annotations, this);
    type = v.visitDartType(type, cannotRemoveSentinel);
    if (initializer != null) {
      initializer = v.transformOrRemoveExpression(initializer!);
      initializer?.parent = this;
    }
  }

  @override
  void visitChildren(Visitor v) {
    visitList(annotations, v);
    type.accept(v);
    initializer?.accept(v);
  }

  @override
  String toString() {
    return "LocalVariable(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeExpressionVariable(this);
  }

  @override
  int binaryOffsetNoTag = -1;

  @override
  List<VariableContext>? get capturedContexts {
    throw new UnsupportedError("${this.runtimeType}.capturedContexts");
  }

  @override
  void set capturedContexts(List<VariableContext>? value) {
    throw new UnsupportedError("${this.runtimeType}.capturedContexts=");
  }

  @override
  int fileEqualsOffset = TreeNode.noOffset;

  @override
  void clearAnnotations() {
    annotations.clear();
  }

  @override
  String? get cosmeticName => name;

  @override
  void set cosmeticName(String? value) {
    name = value!;
  }
}

/// A late local variable.
class LateVariable extends DeclaredVariable {
  String name;

  @override
  DartType type;

  @override
  VariableDeclaration? variableDeclaration;

  @override
  List<Expression> annotations = const <Expression>[];

  @override
  late VariableContext context;

  Expression? initialValue;

  new({
    required String this.name,
    DartType? type,
    bool isFinal = false,
    bool isWildcard = false,
    bool hasDeclaredInitializer = false,
    this.initialValue,
  }) : type = type ?? const DynamicType() {
    this.isFinal = isFinal;
    this.isLate = true;
    this.isWildcard = isWildcard;
    this.hasDeclaredInitializer = hasDeclaredInitializer;
    this.initialValue?.parent = this;
  }

  @Deprecated('Use LateVariable.initialValue instead.')
  @override
  Expression? get initializer => initialValue;

  @Deprecated('Use LateVariable.initialValue instead.')
  @override
  void set initializer(Expression? value) {
    initialValue = value;
  }

  @override
  void addAnnotation(Expression annotation) {
    if (annotations.isEmpty) {
      annotations = <Expression>[];
    }
    annotations.add(annotation..parent = this);
  }

  @override
  bool get isFinal => flags & Variable.FlagFinal != 0;

  @override
  void set isFinal(bool value) {
    flags = value
        ? (flags | Variable.FlagFinal)
        : (flags & ~Variable.FlagFinal);
  }

  @override
  bool get isWildcard => flags & Variable.FlagWildcard != 0;

  @override
  void set isWildcard(bool value) {
    flags = value
        ? (flags | Variable.FlagWildcard)
        : (flags & ~Variable.FlagWildcard);
  }

  @override
  bool get isConst => flags & Variable.FlagConst != 0;

  @override
  void set isConst(bool value) {
    flags = value
        ? (flags | Variable.FlagConst)
        : (flags & ~Variable.FlagConst);
  }

  @override
  bool get isLate => flags & Variable.FlagLate != 0;

  @override
  void set isLate(bool value) {
    flags = value ? (flags | Variable.FlagLate) : (flags & ~Variable.FlagLate);
  }

  @override
  bool get isLowered => flags & Variable.FlagLowered != 0;

  @override
  void set isLowered(bool value) {
    flags = value
        ? (flags | Variable.FlagLowered)
        : (flags & ~Variable.FlagLowered);
  }

  @override
  bool get isHoisted => flags & Variable.FlagHoisted != 0;

  @override
  void set isHoisted(bool value) {
    flags = value
        ? (flags | Variable.FlagHoisted)
        : (flags & ~Variable.FlagHoisted);
  }

  @override
  bool get isCovariantByClass => false;
  @override
  void set isCovariantByClass(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isCovariantByDeclaration => false;

  @override
  void set isCovariantByDeclaration(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isErroneouslyInitialized =>
      flags & Variable.FlagErroneouslyInitialized != 0;

  @override
  void set isErroneouslyInitialized(bool value) {
    flags = value
        ? (flags | Variable.FlagErroneouslyInitialized)
        : (flags & ~Variable.FlagErroneouslyInitialized);
  }

  @override
  bool get hasDeclaredInitializer =>
      flags & Variable.FlagHasDeclaredInitializer != 0;

  @override
  void set hasDeclaredInitializer(bool value) {
    flags = value
        ? (flags | Variable.FlagHasDeclaredInitializer)
        : (flags & ~Variable.FlagHasDeclaredInitializer);
  }

  @override
  bool get isInitializingFormal => false;

  @override
  void set isInitializingFormal(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isRequired => false;

  @override
  void set isRequired(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isSuperInitializingFormal => false;

  @override
  void set isSuperInitializingFormal(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isSynthesized => false;

  @override
  void set isSynthesized(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isAssignable {
    if (isConst) return false;
    if (isFinal) {
      if (isLate) return initialValue == null;
      return false;
    }
    return true;
  }

  @override
  R accept<R>(VariableVisitor<R> v) => v.visitLateVariable(this);

  @override
  R accept1<R, A>(VariableVisitor1<R, A> v, A arg) =>
      v.visitLateVariable(this, arg);

  @override
  void transformChildren(Transformer v) {
    v.transformList(annotations, this);
    type = v.visitDartType(type);
    if (initialValue != null) {
      initialValue = v.transform(initialValue!);
      initialValue?.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    v.transformExpressionList(annotations, this);
    type = v.visitDartType(type, cannotRemoveSentinel);
    if (initialValue != null) {
      initialValue = v.transformOrRemoveExpression(initialValue!);
      initialValue?.parent = this;
    }
  }

  @override
  void visitChildren(Visitor v) {
    visitList(annotations, v);
    type.accept(v);
    initialValue?.accept(v);
  }

  @override
  String toString() {
    return "LateVariable(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeExpressionVariable(this);
  }

  @override
  int binaryOffsetNoTag = -1;

  @override
  List<VariableContext>? get capturedContexts {
    throw new UnsupportedError("${this.runtimeType}.capturedContexts");
  }

  @override
  void set capturedContexts(List<VariableContext>? value) {
    throw new UnsupportedError("${this.runtimeType}.capturedContexts=");
  }

  @override
  int fileEqualsOffset = TreeNode.noOffset;

  @override
  void clearAnnotations() {
    annotations.clear();
  }

  @override
  String? get cosmeticName => name;

  @override
  void set cosmeticName(String? value) {
    name = value!;
  }
}

/// A constant local variable.
class ConstVariable extends DeclaredVariable {
  String name;

  @override
  DartType type;

  @override
  VariableDeclaration? variableDeclaration;

  @override
  List<Expression> annotations = const <Expression>[];

  @override
  late VariableContext context;

  Expression? value;

  new({
    required String this.name,
    DartType? type,
    bool isFinal = false,
    bool isWildcard = false,
    bool hasDeclaredInitializer = false,
    this.value,
  }) : type = type ?? const DynamicType() {
    this.isFinal = isFinal;
    this.isConst = true;
    this.isLate = false;
    this.isWildcard = isWildcard;
    this.hasDeclaredInitializer = hasDeclaredInitializer;
    this.value?.parent = this;
  }

  @Deprecated('Use ConstVariable.value instead.')
  @override
  Expression? get initializer => value;

  @Deprecated('Use ConstVariable.initialValue instead.')
  @override
  void set initializer(Expression? value) {
    this.value = value;
  }

  @override
  void addAnnotation(Expression annotation) {
    if (annotations.isEmpty) {
      annotations = <Expression>[];
    }
    annotations.add(annotation..parent = this);
  }

  @override
  bool get isFinal => flags & Variable.FlagFinal != 0;

  @override
  void set isFinal(bool value) {
    flags = value
        ? (flags | Variable.FlagFinal)
        : (flags & ~Variable.FlagFinal);
  }

  @override
  bool get isWildcard => flags & Variable.FlagWildcard != 0;

  @override
  void set isWildcard(bool value) {
    flags = value
        ? (flags | Variable.FlagWildcard)
        : (flags & ~Variable.FlagWildcard);
  }

  @override
  bool get isConst => flags & Variable.FlagConst != 0;

  @override
  void set isConst(bool value) {
    flags = value
        ? (flags | Variable.FlagConst)
        : (flags & ~Variable.FlagConst);
  }

  @override
  bool get isLate => flags & Variable.FlagLate != 0;

  @override
  void set isLate(bool value) {
    flags = value ? (flags | Variable.FlagLate) : (flags & ~Variable.FlagLate);
  }

  @override
  bool get isLowered => flags & Variable.FlagLowered != 0;

  @override
  void set isLowered(bool value) {
    flags = value
        ? (flags | Variable.FlagLowered)
        : (flags & ~Variable.FlagLowered);
  }

  @override
  bool get isHoisted => flags & Variable.FlagHoisted != 0;

  @override
  void set isHoisted(bool value) {
    flags = value
        ? (flags | Variable.FlagHoisted)
        : (flags & ~Variable.FlagHoisted);
  }

  @override
  bool get isCovariantByClass => false;
  @override
  void set isCovariantByClass(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isCovariantByDeclaration => false;

  @override
  void set isCovariantByDeclaration(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isErroneouslyInitialized =>
      flags & Variable.FlagErroneouslyInitialized != 0;

  @override
  void set isErroneouslyInitialized(bool value) {
    flags = value
        ? (flags | Variable.FlagErroneouslyInitialized)
        : (flags & ~Variable.FlagErroneouslyInitialized);
  }

  @override
  bool get hasDeclaredInitializer =>
      flags & Variable.FlagHasDeclaredInitializer != 0;

  @override
  void set hasDeclaredInitializer(bool value) {
    flags = value
        ? (flags | Variable.FlagHasDeclaredInitializer)
        : (flags & ~Variable.FlagHasDeclaredInitializer);
  }

  @override
  bool get isInitializingFormal => false;

  @override
  void set isInitializingFormal(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isRequired => false;

  @override
  void set isRequired(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isSuperInitializingFormal => false;

  @override
  void set isSuperInitializingFormal(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isSynthesized => false;

  @override
  void set isSynthesized(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isAssignable {
    if (isConst) return false;
    if (isFinal) {
      if (isLate) return value == null;
      return false;
    }
    return true;
  }

  @override
  R accept<R>(VariableVisitor<R> v) => v.visitConstVariable(this);

  @override
  R accept1<R, A>(VariableVisitor1<R, A> v, A arg) =>
      v.visitConstVariable(this, arg);

  @override
  void transformChildren(Transformer v) {
    v.transformList(annotations, this);
    type = v.visitDartType(type);
    if (value != null) {
      value = v.transform(value!);
      value?.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    v.transformExpressionList(annotations, this);
    type = v.visitDartType(type, cannotRemoveSentinel);
    if (value != null) {
      value = v.transformOrRemoveExpression(value!);
      value?.parent = this;
    }
  }

  @override
  void visitChildren(Visitor v) {
    visitList(annotations, v);
    type.accept(v);
    value?.accept(v);
  }

  @override
  String toString() {
    return "ConstVariable(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeExpressionVariable(this);
  }

  @override
  int binaryOffsetNoTag = -1;

  @override
  List<VariableContext>? get capturedContexts {
    throw new UnsupportedError("${this.runtimeType}.capturedContexts");
  }

  @override
  void set capturedContexts(List<VariableContext>? value) {
    throw new UnsupportedError("${this.runtimeType}.capturedContexts=");
  }

  @override
  int fileEqualsOffset = TreeNode.noOffset;

  @override
  void clearAnnotations() {
    annotations.clear();
  }

  @override
  String? get cosmeticName => name;

  @override
  void set cosmeticName(String? value) {
    name = value!;
  }
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
class CatchVariable extends Variable {
  final String catchVariableName;

  @override
  DartType type;

  @override
  List<Expression> annotations = const <Expression>[];

  @override
  late VariableContext context;

  new({
    required String name,
    DartType? type,
    bool isWildcard = false,
    bool isFinal = false,
    bool isSynthesized = false,
  }) : catchVariableName = name,
       type = type ?? const DynamicType() {
    this.isWildcard = isWildcard;
    this.isFinal = isFinal;
    this.isSynthesized = isSynthesized;
  }

  @override
  String? get cosmeticName => catchVariableName;

  @override
  void set cosmeticName(String? value) {
    throw new UnsupportedError("${this.runtimeType}.cosmeticName=");
  }

  @override
  void addAnnotation(Expression annotation) {
    if (annotations.isEmpty) {
      annotations = <Expression>[];
    }
    annotations.add(annotation..parent = this);
  }

  @override
  bool get isFinal => flags & Variable.FlagFinal != 0;

  @override
  void set isFinal(bool value) {
    flags = value
        ? (flags | Variable.FlagFinal)
        : (flags & ~Variable.FlagFinal);
  }

  @override
  bool get isWildcard => flags & Variable.FlagWildcard != 0;

  @override
  void set isWildcard(bool value) {
    flags = value
        ? (flags | Variable.FlagWildcard)
        : (flags & ~Variable.FlagWildcard);
  }

  @override
  bool get isConst => false;

  @override
  void set isConst(bool value) {
    throw new UnsupportedError("${this.runtimeType}.isConst=");
  }

  @override
  bool get isLate => false;

  @override
  void set isLate(bool value) {
    throw new UnsupportedError("${this.runtimeType}.isLate=");
  }

  @override
  bool get isLowered => false;

  @override
  void set isLowered(bool value) {
    throw new UnsupportedError("${this.runtimeType}.isLowered=");
  }

  @override
  bool get isHoisted => false;

  @override
  void set isHoisted(bool value) {
    throw new UnsupportedError("${this.runtimeType}.isHoisted=");
  }

  @override
  bool get isCovariantByClass => false;

  @override
  void set isCovariantByClass(bool value) {
    throw new UnsupportedError("${this.runtimeType}.isCovariantByClass=");
  }

  @override
  bool get isCovariantByDeclaration => false;

  @override
  void set isCovariantByDeclaration(bool value) {
    throw new UnsupportedError("${this.runtimeType}.isCovariantByDeclaration=");
  }

  @override
  bool get isErroneouslyInitialized => false;

  @override
  void set isErroneouslyInitialized(bool value) {
    throw new UnsupportedError("${this.runtimeType}.isErroneouslyInitialized=");
  }

  @override
  bool get hasDeclaredInitializer => false;

  @override
  void set hasDeclaredInitializer(bool value) {
    throw new UnsupportedError("${this.runtimeType}.hasDeclaredInitializer=");
  }

  @override
  bool get isInitializingFormal => false;

  @override
  void set isInitializingFormal(bool value) {
    throw new UnsupportedError("${this.runtimeType}.isInitializingFormal=");
  }

  @override
  bool get isRequired => false;

  @override
  void set isRequired(bool value) {
    throw new UnsupportedError("${this.runtimeType}.isRequired=");
  }

  @override
  bool get isSuperInitializingFormal => false;

  @override
  void set isSuperInitializingFormal(bool value) {
    throw new UnsupportedError(
      "${this.runtimeType}.isSuperInitializingFormal=",
    );
  }

  @override
  bool get isSynthesized => flags & Variable.FlagSynthesized != 0;

  @override
  void set isSynthesized(bool value) {
    flags = value
        ? (flags | Variable.FlagSynthesized)
        : (flags & ~Variable.FlagSynthesized);
  }

  @override
  bool get isAssignable => false;

  @override
  R accept<R>(VariableVisitor<R> v) => v.visitCatchVariable(this);

  @override
  R accept1<R, A>(VariableVisitor1<R, A> v, A arg) =>
      v.visitCatchVariable(this, arg);

  @override
  void transformChildren(Transformer v) {
    v.transformList(annotations, this);
    type = v.visitDartType(type);
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    v.transformExpressionList(annotations, this);
    type = v.visitDartType(type, cannotRemoveSentinel);
  }

  @override
  void visitChildren(Visitor v) {
    visitList(annotations, v);
    type.accept(v);
  }

  @override
  String toString() {
    return "CatchVariable(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeExpressionVariable(this);
  }

  @override
  Expression? get initializer => null;

  @override
  void set initializer(Expression? value) {
    throw new UnsupportedError("${this.runtimeType}.initializer=");
  }

  @override
  int binaryOffsetNoTag = -1;

  @override
  List<VariableContext>? get capturedContexts {
    throw new UnsupportedError("${this.runtimeType}.capturedContexts");
  }

  @override
  void set capturedContexts(List<VariableContext>? value) {
    throw new UnsupportedError("${this.runtimeType}.capturedContexts=");
  }

  @override
  int fileEqualsOffset = TreeNode.noOffset;

  @override
  void clearAnnotations() {
    annotations.clear();
  }
}

/// Abstract parameter class, the parent for positional and named parameters.
sealed class FunctionParameter extends Variable {
  Expression? defaultValue;

  new({
    required this.defaultValue,
    required bool isCovariantByDeclaration,
    required bool isCovariantByClass,
    required bool isRequired,
    required bool isInitializingFormal,
    required bool isSuperInitializingFormal,
    required bool isFinal,
    required bool hasDeclaredDefaultValue,
    required bool isLowered,
    required bool isSynthesized,
    required bool isWildcard,
  }) {
    this.defaultValue?.parent = this;
    this.isCovariantByDeclaration = isCovariantByDeclaration;
    this.isCovariantByClass = isCovariantByClass;
    this.isRequired = isRequired;
    this.isInitializingFormal = isInitializingFormal;
    this.isSuperInitializingFormal = isSuperInitializingFormal;
    this.isFinal = isFinal;
    this.hasDeclaredDefaultValue = hasDeclaredDefaultValue;
    this.isLowered = isLowered;
    this.isSynthesized = isSynthesized;
    this.isWildcard = isWildcard;
  }

  /// Function parameters can't be `const` or `late`, so they are assignable if
  /// they aren't final.
  @override
  bool get isAssignable => !isFinal;

  @Deprecated('Use FunctionParameter.defaultValue instead.')
  @override
  Expression? get initializer => defaultValue;

  @Deprecated('Use FunctionParameter.defaultValue instead.')
  @override
  void set initializer(Expression? value) {
    defaultValue = value;
  }

  @override
  bool get isFinal => flags & Variable.FlagFinal != 0;

  @override
  void set isFinal(bool value) {
    flags = value
        ? (flags | Variable.FlagFinal)
        : (flags & ~Variable.FlagFinal);
  }

  @override
  bool get isWildcard => flags & Variable.FlagWildcard != 0;

  @override
  void set isWildcard(bool value) {
    flags = value
        ? (flags | Variable.FlagWildcard)
        : (flags & ~Variable.FlagWildcard);
  }

  @override
  bool get isCovariantByClass => flags & Variable.FlagCovariantByClass != 0;

  @override
  void set isCovariantByClass(bool value) {
    flags = value
        ? (flags | Variable.FlagCovariantByClass)
        : (flags & ~Variable.FlagCovariantByClass);
  }

  @override
  bool get isCovariantByDeclaration =>
      flags & Variable.FlagCovariantByDeclaration != 0;

  @override
  void set isCovariantByDeclaration(bool value) {
    flags = value
        ? (flags | Variable.FlagCovariantByDeclaration)
        : (flags & ~Variable.FlagCovariantByDeclaration);
  }

  @override
  bool get isInitializingFormal => flags & Variable.FlagInitializingFormal != 0;

  @override
  void set isInitializingFormal(bool value) {
    flags = value
        ? (flags | Variable.FlagInitializingFormal)
        : (flags & ~Variable.FlagInitializingFormal);
  }

  @override
  bool get isSuperInitializingFormal =>
      flags & Variable.FlagSuperInitializingFormal != 0;

  @override
  void set isSuperInitializingFormal(bool value) {
    flags = value
        ? (flags | Variable.FlagSuperInitializingFormal)
        : (flags & ~Variable.FlagSuperInitializingFormal);
  }

  @override
  bool get isRequired => flags & Variable.FlagRequired != 0;

  @override
  void set isRequired(bool value) {
    flags = value
        ? (flags | Variable.FlagRequired)
        : (flags & ~Variable.FlagRequired);
  }

  @override
  bool get isLowered => flags & Variable.FlagLowered != 0;

  @override
  void set isLowered(bool value) {
    flags = value
        ? (flags | Variable.FlagLowered)
        : (flags & ~Variable.FlagLowered);
  }

  bool get hasDeclaredDefaultValue =>
      flags & Variable.FlagHasDeclaredInitializer != 0;

  void set hasDeclaredDefaultValue(bool value) {
    flags = value
        ? (flags | Variable.FlagHasDeclaredInitializer)
        : (flags & ~Variable.FlagHasDeclaredInitializer);
  }

  @Deprecated('Use FunctionParameter.hasDeclaredDefaultValue instead.')
  @override
  bool get hasDeclaredInitializer => hasDeclaredDefaultValue;

  @Deprecated('Use FunctionParameter.hasDeclaredDefaultValue instead.')
  @override
  void set hasDeclaredInitializer(bool value) {
    hasDeclaredDefaultValue = value;
  }

  @override
  bool get isSynthesized => flags & Variable.FlagSynthesized != 0;

  @override
  void set isSynthesized(bool value) {
    flags = value
        ? (flags | Variable.FlagSynthesized)
        : (flags & ~Variable.FlagSynthesized);
  }

  bool get hasErroneousDefaultValue =>
      flags & Variable.FlagErroneouslyInitialized != 0;

  void set hasErroneousDefaultValue(bool value) {
    flags = value
        ? (flags | Variable.FlagErroneouslyInitialized)
        : (flags & ~Variable.FlagErroneouslyInitialized);
  }

  @Deprecated('Use FunctionParameter.hasErroneousDefaultValue instead.')
  @override
  bool get isErroneouslyInitialized =>
      flags & Variable.FlagErroneouslyInitialized != 0;

  @Deprecated('Use FunctionParameter.hasErroneousDefaultValue instead.')
  @override
  void set isErroneouslyInitialized(bool value) {
    flags = value
        ? (flags | Variable.FlagErroneouslyInitialized)
        : (flags & ~Variable.FlagErroneouslyInitialized);
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
  bool get isHoisted => false;

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

  @override
  late VariableContext context;

  new({
    this.cosmeticName,
    DartType? type,
    super.defaultValue,
    super.isCovariantByDeclaration = false,
    super.isCovariantByClass = false,
    super.isRequired = false,
    super.isInitializingFormal = false,
    super.isSuperInitializingFormal = false,
    super.isFinal = false,
    super.hasDeclaredDefaultValue = false,
    super.isLowered = false,
    super.isSynthesized = false,
    super.isWildcard = false,
  }) : type = type ?? const DynamicType();

  @override
  // TODO(62620): Conforming to [VariableDeclaration] interface. Remove this.
  List<VariableContext>? get capturedContexts {
    throw new UnsupportedError("${this.runtimeType}.capturedContexts");
  }

  @override
  // TODO(62620): Conforming to [VariableDeclaration] interface. Remove this.
  void set capturedContexts(List<VariableContext>? value) {
    throw new UnsupportedError("${this.runtimeType}.capturedContexts=");
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
  R accept<R>(VariableVisitor<R> v) => v.visitPositionalParameter(this);

  @override
  R accept1<R, A>(VariableVisitor1<R, A> v, A arg) =>
      v.visitPositionalParameter(this, arg);

  @override
  void transformChildren(Transformer v) {
    v.transformList(annotations, this);
    type = v.visitDartType(type);
    if (defaultValue != null) {
      defaultValue = v.transform(defaultValue!);
      defaultValue?.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    v.transformExpressionList(annotations, this);
    type = v.visitDartType(type, cannotRemoveSentinel);
    if (defaultValue != null) {
      defaultValue = v.transformOrRemoveExpression(defaultValue!);
      defaultValue?.parent = this;
    }
  }

  @override
  void visitChildren(Visitor v) {
    visitList(annotations, v);
    type.accept(v);
    defaultValue?.accept(v);
  }

  @override
  String toString() {
    return "PositionalParameter(${toStringInternal()})";
  }

  @override
  int binaryOffsetNoTag = -1;

  @override
  int fileEqualsOffset = TreeNode.noOffset;
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

  @override
  late VariableContext context;

  new({
    required this.parameterName,
    DartType? type,
    super.defaultValue,
    super.isCovariantByDeclaration = false,
    super.isCovariantByClass = false,
    super.isRequired = false,
    super.isInitializingFormal = false,
    super.isSuperInitializingFormal = false,
    super.isFinal = false,
    super.hasDeclaredDefaultValue = false,
    super.isLowered = false,
    super.isSynthesized = false,
    super.isWildcard = false,
    bool isRenamedPrivateNamedParameter = false,
  }) : type = type ?? const DynamicType() {
    this.isRenamedPrivateNamedParameter = isRenamedPrivateNamedParameter;
  }

  bool get isRenamedPrivateNamedParameter =>
      flags & Variable.FlagRenamedPrivateNamedParameter != 0;

  void set isRenamedPrivateNamedParameter(bool value) {
    flags = value
        ? (flags | Variable.FlagRenamedPrivateNamedParameter)
        : (flags & ~Variable.FlagRenamedPrivateNamedParameter);
  }

  @override
  // TODO(62620): Conforming to [VariableDeclaration] interface. Remove this.
  List<VariableContext>? get capturedContexts {
    throw new UnsupportedError("${this.runtimeType}.capturedContexts");
  }

  @override
  // TODO(62620): Conforming to [VariableDeclaration] interface. Remove this.
  void set capturedContexts(List<VariableContext>? value) {
    throw new UnsupportedError("${this.runtimeType}.capturedContexts=");
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
  R accept<R>(VariableVisitor<R> v) => v.visitNamedParameter(this);

  @override
  R accept1<R, A>(VariableVisitor1<R, A> v, A arg) =>
      v.visitNamedParameter(this, arg);

  @override
  void transformChildren(Transformer v) {
    v.transformList(annotations, this);
    type = v.visitDartType(type);
    if (defaultValue != null) {
      defaultValue = v.transform(defaultValue!);
      defaultValue?.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    v.transformExpressionList(annotations, this);
    type = v.visitDartType(type, cannotRemoveSentinel);
    if (defaultValue != null) {
      defaultValue = v.transformOrRemoveExpression(defaultValue!);
      defaultValue?.parent = this;
    }
  }

  @override
  void visitChildren(Visitor v) {
    visitList(annotations, v);
    type.accept(v);
    defaultValue?.accept(v);
  }

  @override
  String toString() {
    return "NamedParameter(${toStringInternal()})";
  }

  @override
  int binaryOffsetNoTag = -1;

  @override
  int fileEqualsOffset = TreeNode.noOffset;
}

/// The variable storage for `this`.
class ThisVariable extends Variable {
  @override
  String get cosmeticName => "";

  @override
  void set cosmeticName(String? value) {}

  @override
  DartType type;

  // TODO(cstefantsova): Consider a throwing implementation instead.
  @override
  List<Expression> annotations = const <Expression>[];

  @override
  late VariableContext context;

  new({required this.type}) {
    // All [Variable]s must be serialized uniformly.
    flags |= Variable.FlagFinal;
  }

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
  bool get isFinal => true;

  @override
  void set isFinal(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isWildcard => false;

  @override
  void set isWildcard(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isCovariantByClass => false;

  @override
  void set isCovariantByClass(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isCovariantByDeclaration => false;

  @override
  void set isCovariantByDeclaration(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isInitializingFormal => false;

  @override
  void set isInitializingFormal(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isSuperInitializingFormal => false;

  @override
  void set isSuperInitializingFormal(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isErroneouslyInitialized => false;

  @override
  void set isErroneouslyInitialized(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get hasDeclaredInitializer => false;

  @override
  void set hasDeclaredInitializer(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isRequired => false;

  @override
  void set isRequired(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isSynthesized => false;

  @override
  void set isSynthesized(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isHoisted => false;

  @override
  void set isHoisted(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isLowered => false;

  @override
  void set isLowered(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  R accept<R>(VariableVisitor<R> v) => v.visitThisVariable(this);

  @override
  R accept1<R, A>(VariableVisitor1<R, A> v, A arg) =>
      v.visitThisVariable(this, arg);

  @override
  void transformChildren(Transformer v) {
    v.transformList(annotations, this);
    type = v.visitDartType(type);
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    v.transformExpressionList(annotations, this);
    type = v.visitDartType(type, cannotRemoveSentinel);
  }

  @override
  void visitChildren(Visitor v) {
    visitList(annotations, v);
    type.accept(v);
  }

  @override
  String toString() {
    return "ThisVariable(${toStringInternal()})";
  }

  @override
  bool get isAssignable => false;

  @override
  Expression? get initializer => null;

  @override
  void set initializer(Expression? value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  int binaryOffsetNoTag = -1;

  @override
  List<VariableContext>? get capturedContexts {
    throw new UnsupportedError("${this.runtimeType}.capturedContexts");
  }

  @override
  void set capturedContexts(List<VariableContext>? value) {
    throw new UnsupportedError("${this.runtimeType}.capturedContexts=");
  }

  @override
  int fileEqualsOffset = TreeNode.noOffset;

  @override
  void clearAnnotations() {
    annotations.clear();
  }
}

/// A variable introduced during desugaring. Such variables don't correspond to
/// any variable declared by the programmer.
class SyntheticVariable extends DeclaredVariable {
  @override
  String? cosmeticName;

  @override
  DartType type;

  @override
  VariableDeclaration? variableDeclaration;

  // TODO(cstefantsova): Consider a throwing implementation instead.
  @override
  List<Expression> annotations = const <Expression>[];

  @override
  late VariableContext context;

  @override
  // TODO(johnniwinther): Remove this.
  Expression? initializer;

  new({
    this.cosmeticName,
    DartType? type,
    this.initializer,
    bool isFinal = false,
    bool isLowered = false,
    // TODO(johnniwinther): Remove the ability for [SyntheticVariable]s to not
    // be synthesized.
    bool isSynthesized = true,
    bool hasDeclaredInitializer = false,
    bool isWildcard = false,
  }) : type = type ?? const DynamicType() {
    this.initializer?.parent = this;
    this.isFinal = isFinal;
    this.isLowered = isLowered;
    this.isSynthesized = isSynthesized;
    this.hasDeclaredInitializer = hasDeclaredInitializer;
  }

  // TODO(cstefantsova): Consider a throwing implementation instead.
  @override
  void addAnnotation(Expression annotation) {
    if (annotations.isEmpty) {
      annotations = <Expression>[];
    }
    annotations.add(annotation..parent = this);
  }

  @override
  bool get isFinal => flags & Variable.FlagFinal != 0;

  @override
  void set isFinal(bool value) {
    flags = value
        ? (flags | Variable.FlagFinal)
        : (flags & ~Variable.FlagFinal);
  }

  @override
  bool get isLowered => flags & Variable.FlagLowered != 0;

  @override
  void set isLowered(bool value) {
    flags = value
        ? (flags | Variable.FlagLowered)
        : (flags & ~Variable.FlagLowered);
  }

  @override
  bool get isHoisted => flags & Variable.FlagHoisted != 0;

  @override
  void set isHoisted(bool value) {
    flags = value
        ? (flags | Variable.FlagHoisted)
        : (flags & ~Variable.FlagHoisted);
  }

  @override
  bool get isCovariantByClass => false;

  @override
  void set isCovariantByClass(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isCovariantByDeclaration => false;

  @override
  void set isCovariantByDeclaration(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isErroneouslyInitialized => false;

  @override
  void set isErroneouslyInitialized(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get hasDeclaredInitializer =>
      flags & Variable.FlagHasDeclaredInitializer != 0;

  // TODO(johnniwinther): Remove this.
  @override
  void set hasDeclaredInitializer(bool value) {
    flags = value
        ? (flags | Variable.FlagHasDeclaredInitializer)
        : (flags & ~Variable.FlagHasDeclaredInitializer);
  }

  @override
  bool get isInitializingFormal => false;

  @override
  void set isInitializingFormal(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isRequired => false;

  @override
  void set isRequired(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isSuperInitializingFormal => false;

  @override
  void set isSuperInitializingFormal(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  bool get isSynthesized => flags & Variable.FlagSynthesized != 0;

  @override
  void set isSynthesized(bool value) {
    flags = value
        ? (flags | Variable.FlagSynthesized)
        : (flags & ~Variable.FlagSynthesized);
  }

  @override
  bool get isConst => flags & Variable.FlagConst != 0;

  @override
  void set isConst(bool value) {
    flags = value
        ? (flags | Variable.FlagConst)
        : (flags & ~Variable.FlagConst);
  }

  // TODO(johnniwinther): Should [SyntheticVariable]s be able to be late?
  @override
  bool get isLate => flags & Variable.FlagLate != 0;

  @override
  void set isLate(bool value) {
    flags = value ? (flags | Variable.FlagLate) : (flags & ~Variable.FlagLate);
  }

  @override
  bool get isWildcard => false;

  @override
  void set isWildcard(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  R accept<R>(VariableVisitor<R> v) => v.visitSyntheticVariable(this);

  @override
  R accept1<R, A>(VariableVisitor1<R, A> v, A arg) =>
      v.visitSyntheticVariable(this, arg);

  @override
  void transformChildren(Transformer v) {
    v.transformList(annotations, this);
    type = v.visitDartType(type);
    if (initializer != null) {
      initializer = v.transform(initializer!);
      initializer?.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    v.transformExpressionList(annotations, this);
    type = v.visitDartType(type, cannotRemoveSentinel);
    if (initializer != null) {
      initializer = v.transformOrRemoveExpression(initializer!);
      initializer?.parent = this;
    }
  }

  @override
  void visitChildren(Visitor v) {
    visitList(annotations, v);
    type.accept(v);
    initializer?.accept(v);
  }

  @override
  String toString() {
    return "SyntheticVariable(${toStringInternal()})";
  }

  @override
  bool get isAssignable => !isConst && !isFinal;

  @override
  int binaryOffsetNoTag = -1;

  @override
  List<VariableContext>? get capturedContexts {
    throw new UnsupportedError("${this.runtimeType}.capturedContexts");
  }

  @override
  void set capturedContexts(List<VariableContext>? value) {
    throw new UnsupportedError("${this.runtimeType}.capturedContexts=");
  }

  @override
  int fileEqualsOffset = TreeNode.noOffset;

  @override
  void clearAnnotations() {
    annotations.clear();
  }
}

/// The enum reflecting the kind of a variable context. A context is
/// [assertCaptured] if it contains the variables captured in a closure within
/// an `assert` and not captured anywhere outside of `assert`s.
enum CaptureKind { notCaptured, directCaptured, assertCaptured }

/// The box storing some of the variables in the scope it's associated with. It
/// serves as the "declaration" of the variables it contains for the runtime
/// environments.
class VariableContext {
  CaptureKind captureKind;
  List<VariableBase> variables;

  new({required this.captureKind, required this.variables}) {
    for (VariableBase variable in variables) {
      variable.context = this;
    }
  }

  void addVariable(VariableBase variable) {
    variable.context = this;
    variables.add(variable);
  }

  @override
  String toString() {
    AstPrinter printer = new AstPrinter(defaultAstTextStrategy);
    toTextInternal(printer);
    return "VariableContext(${printer.getText()})";
  }

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
class Scope {
  final List<VariableContext> contexts;

  new({required this.contexts});

  void addContext(VariableContext context) {
    contexts.add(context);
  }

  @override
  String toString() {
    AstPrinter printer = new AstPrinter(defaultAstTextStrategy);
    toTextInternal(printer);
    return "Scope(${printer.getText()})";
  }

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
  abstract List<VariableContext>? capturedContexts;
}

/// Declaration of a variable with an initial value.
class VariableDeclaration extends TreeNode implements ContextConsumer {
  /// The declared variable.
  DeclaredVariable variable;

  /// Contexts of the variables captured by the late variable initializer.
  ///
  /// If [variable] isn't `late`, [capturedContexts] should be `null`.
  @override
  List<VariableContext>? capturedContexts;

  new(this.variable) {
    variable.parent = this;
    variable.variableDeclaration = this;
  }

  /// The declared initializer, if any.
  // TODO(johnniwinther): VariableDeclaration should own the initializer.
  Expression? get initializer => variable.initializer;

  @override
  R accept<R>(TreeVisitor<R> v) => v.visitVariableDeclaration(this);

  @override
  R accept1<R, A>(TreeVisitor1<R, A> v, A arg) =>
      v.visitVariableDeclaration(this, arg);

  @override
  void toTextInternal(AstPrinter printer) {
    variable.toTextInternal(printer);
  }

  @override
  void transformChildren(Transformer v) {
    variable = v.transform(variable)..parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    variable = v.transform(variable)..parent = this;
  }

  @override
  void visitChildren(Visitor<dynamic> v) {
    variable.accept(v);
  }

  @override
  String toString() => 'VariableDeclaration(${toStringInternal()})';
}
