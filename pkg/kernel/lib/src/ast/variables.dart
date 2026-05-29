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

/// This is a helper class to enable mixing a mixin into concrete
/// implementations of the sealed class [Variable]. It's not supposed
/// to be used as a type annotation, but purely for declaring the class
/// hierarchy.
abstract interface class IVariable implements TreeNode, Annotatable {
  abstract DartType type;
  abstract String? cosmeticName;
  abstract VariableDeclaration? variableDeclaration;
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

  // The following is due to [VariableDeclaration] implementing
  // [VariableInitialization].
  abstract int binaryOffsetNoTag;
  abstract List<VariableContext>? capturedContexts;
  abstract int fileEqualsOffset;
  abstract Variable variable;
  void clearAnnotations();

  VariableContext? get context;
  void set context(VariableContext value);

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
  Variable get asVariableDeclaration;
}

/// The root of the sealed hierarchy of non-type variables.
sealed class Variable extends VariableBase
    implements IVariable, ContextConsumer {
  /// Static type of the variable.
  @override
  abstract DartType type;

  /// Declaration node for the variable, if available.
  @override
  abstract VariableDeclaration? variableDeclaration;

  /// Derived from [variableDeclaration], if available.
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

  factory Variable(
    String? name, {
    Expression? initializer,
    DartType type,
    int flags,
    bool isFinal,
    bool isConst,
    bool isInitializingFormal,
    bool isSuperInitializingFormal,
    bool isCovariantByDeclaration,
    bool isLate,
    bool isRequired,
    bool isLowered,
    bool isSynthesized,
    bool isHoisted,
    bool hasDeclaredInitializer,
    bool isWildcard,
  }) = LegacyVariable;

  factory Variable.forValue(
    Expression? initializer, {
    bool isFinal,
    bool isConst,
    bool isInitializingFormal,
    bool isSuperInitializingFormal,
    bool isLate,
    bool isRequired,
    bool isLowered,
    DartType type,
  }) = LegacyVariable.forValue;

  Variable.empty();

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
  Variable get asVariableDeclaration => this;

  abstract String? name;

  @override
  R accept<R>(VariableVisitor<R> visitor);

  @override
  R accept1<R, A>(VariableVisitor1<R, A> visitor, A arg);
}

/// Declaration of a local variable.
///
/// This may occur as a statement, but is also used in several non-statement
/// contexts, such as in [ForStatement], [Catch], and [FunctionNode].
///
/// When this occurs as a statement, it must be a direct child of a [Block].
//
// DESIGN TODO: Should we remove the 'final' modifier from variables?
class LegacyVariable extends TreeNode implements Variable, Annotatable {
  /// Offset of the equals sign in the source file it comes from.
  ///
  /// Valid values are from 0 and up, or -1 ([TreeNode.noOffset])
  /// if the equals sign offset is not available (e.g. if not initialized)
  /// (this is the default if none is specifically set).
  @override
  int fileEqualsOffset = TreeNode.noOffset;

  @override
  List<int>? get fileOffsetsIfMultiple => [fileOffset, fileEqualsOffset];

  /// List of metadata annotations on the variable declaration.
  ///
  /// This defaults to an immutable empty list. Use [addAnnotation] to add
  /// annotations if needed.
  @override
  List<Expression> annotations = const <Expression>[];

  /// The name of the variable or parameter as provided in the source code.
  ///
  /// If this variable is synthesized, for instance the variable of a [Let]
  /// expression, the name can be `null`.
  String? _name;

  @override
  int flags = 0;

  /// The declared or inferred type of the variable.
  @override
  DartType type; // Not null, defaults to dynamic.

  /// Offset of the declaration, set and used when writing the binary.
  @override
  int binaryOffsetNoTag = -1;

  /// For locals, this is the initial value.
  /// For parameters, this is the default value.
  ///
  /// Should be null in other cases.
  @override
  Expression? initializer; // May be null.

  LegacyVariable(
    this._name, {
    this.initializer,
    this.type = const DynamicType(),
    int flags = -1,
    bool isFinal = false,
    bool isConst = false,
    bool isInitializingFormal = false,
    bool isSuperInitializingFormal = false,
    bool isCovariantByDeclaration = false,
    bool isLate = false,
    bool isRequired = false,
    bool isLowered = false,
    bool isSynthesized = false,
    bool isHoisted = false,
    bool hasDeclaredInitializer = false,
    bool isWildcard = false,
  }) {
    initializer?.parent = this;
    if (flags != -1) {
      this.flags = flags;
    } else {
      this.isFinal = isFinal;
      this.isConst = isConst;
      this.isInitializingFormal = isInitializingFormal;
      this.isSuperInitializingFormal = isSuperInitializingFormal;
      this.isCovariantByDeclaration = isCovariantByDeclaration;
      this.isLate = isLate;
      this.isRequired = isRequired;
      this.isLowered = isLowered;
      this.hasDeclaredInitializer = hasDeclaredInitializer;
      this.isSynthesized = isSynthesized;
      this.isHoisted = isHoisted;
      this.isWildcard = isWildcard;
    }
    assert(
      _name != null || this.isSynthesized,
      "Only synthesized variables can have no name.",
    );
  }

  /// Creates a synthetic variable with the given expression as initializer.
  LegacyVariable.forValue(
    this.initializer, {
    bool isFinal = true,
    bool isConst = false,
    bool isInitializingFormal = false,
    bool isSuperInitializingFormal = false,
    bool isLate = false,
    bool isRequired = false,
    bool isLowered = false,
    this.type = const DynamicType(),
  }) {
    initializer?.parent = this;
    this.isFinal = isFinal;
    this.isConst = isConst;
    this.isInitializingFormal = isInitializingFormal;
    this.isSuperInitializingFormal = isSuperInitializingFormal;
    this.isLate = isLate;
    this.isRequired = isRequired;
    this.isLowered = isLowered;
    this.hasDeclaredInitializer = true;
    this.isSynthesized = true;
  }

  /// The name of the variable as provided in the source code.
  ///
  /// The name of a variable can only be omitted if the variable is synthesized.
  /// Otherwise, its name is as provided in the source code.
  @override
  String? get name => _name;

  @override
  void set name(String? value) {
    assert(
      value != null || isSynthesized,
      "Only synthesized variables can have no name.",
    );
    _name = value;
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

  /// Whether the variable is declared with the `final` keyword.
  @override
  bool get isFinal => flags & FlagFinal != 0;

  /// Whether the variable is declared with the `const` keyword.
  @override
  bool get isConst => flags & FlagConst != 0;

  /// Whether the parameter is declared with the `covariant` keyword.
  @override
  bool get isCovariantByDeclaration => flags & FlagCovariantByDeclaration != 0;

  /// Whether the variable is declared as an initializing formal parameter of
  /// a constructor.
  @informative
  @override
  bool get isInitializingFormal => flags & FlagInitializingFormal != 0;

  /// Whether the variable is declared as a super initializing formal parameter
  /// of a constructor.
  @informative
  @override
  bool get isSuperInitializingFormal =>
      flags & FlagSuperInitializingFormal != 0;

  @informative
  @override
  bool get isErroneouslyInitialized => flags & FlagErroneouslyInitialized != 0;

  /// If this [LegacyVariable] is a parameter of a method, indicates
  /// whether the method implementation needs to contain a runtime type check to
  /// deal with generic covariance.
  ///
  /// When `true`, runtime checks may need to be performed.
  @override
  bool get isCovariantByClass => flags & FlagCovariantByClass != 0;

  /// Whether the variable is declared with the `late` keyword.
  ///
  /// The `late` modifier is only supported on local variables and not on
  /// parameters.
  @override
  bool get isLate => flags & FlagLate != 0;

  /// Whether the parameter is declared with the `required` keyword.
  ///
  /// The `required` modifier is only supported on named parameters and not on
  /// positional parameters and local variables.
  @override
  bool get isRequired => flags & FlagRequired != 0;

  /// Whether the variable is part of a lowering.
  ///
  /// If a variable is part of a lowering its name may be synthesized so that it
  /// doesn't reflect the name used in the source code and might not have a
  /// one-to-one correspondence with the variable in the source.
  ///
  /// Lowering is used for instance of encoding of 'this' in extension instance
  /// members and encoding of late locals.
  @override
  bool get isLowered => flags & FlagLowered != 0;

  /// Whether this variable is synthesized, that is, it is _not_ declared in
  /// the source code.
  ///
  /// The name of a variable can only be omitted if the variable is synthesized.
  /// Otherwise, its name is as provided in the source code.
  @override
  bool get isSynthesized => flags & FlagSynthesized != 0;

  /// Whether the declaration of this variable is has been moved to an earlier
  /// source location.
  ///
  /// This is for instance the case for variables declared in a pattern, where
  /// the lowering requires the variable to be declared before the expression
  /// that performs that matching in which its initialization occurs.
  @override
  bool get isHoisted => flags & FlagHoisted != 0;

  /// Whether the variable has an initializer, either by declaration or copied
  /// from an original declaration.
  ///
  /// Note that the variable might have a synthesized initializer expression,
  /// so `hasDeclaredInitializer == false` doesn't imply `initializer == null`.
  /// For instance, for duplicate variable names, an invalid expression is set
  /// as the initializer of the second variable.
  @override
  bool get hasDeclaredInitializer => flags & FlagHasDeclaredInitializer != 0;

  @override
  bool get isWildcard => flags & FlagWildcard != 0;

  /// Whether the variable is assignable.
  ///
  /// This is `true` if the variable is neither constant nor final, or if it
  /// is late final without an initializer.
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
  void set isFinal(bool value) {
    flags = value ? (flags | FlagFinal) : (flags & ~FlagFinal);
  }

  @override
  void set isConst(bool value) {
    flags = value ? (flags | FlagConst) : (flags & ~FlagConst);
  }

  @override
  void set isCovariantByDeclaration(bool value) {
    flags = value
        ? (flags | FlagCovariantByDeclaration)
        : (flags & ~FlagCovariantByDeclaration);
  }

  @override
  void set isInitializingFormal(bool value) {
    flags = value
        ? (flags | FlagInitializingFormal)
        : (flags & ~FlagInitializingFormal);
  }

  @override
  void set isSuperInitializingFormal(bool value) {
    flags = value
        ? (flags | FlagSuperInitializingFormal)
        : (flags & ~FlagSuperInitializingFormal);
  }

  @override
  void set isErroneouslyInitialized(bool value) {
    flags = value
        ? (flags | FlagErroneouslyInitialized)
        : (flags & ~FlagErroneouslyInitialized);
  }

  @override
  void set isCovariantByClass(bool value) {
    flags = value
        ? (flags | FlagCovariantByClass)
        : (flags & ~FlagCovariantByClass);
  }

  @override
  void set isLate(bool value) {
    flags = value ? (flags | FlagLate) : (flags & ~FlagLate);
  }

  @override
  void set isRequired(bool value) {
    flags = value ? (flags | FlagRequired) : (flags & ~FlagRequired);
  }

  @override
  void set isLowered(bool value) {
    flags = value ? (flags | FlagLowered) : (flags & ~FlagLowered);
  }

  @override
  void set isSynthesized(bool value) {
    assert(
      value || _name != null,
      "Only synthesized variables can have no name.",
    );
    flags = value ? (flags | FlagSynthesized) : (flags & ~FlagSynthesized);
  }

  @override
  void set isHoisted(bool value) {
    flags = value ? (flags | FlagHoisted) : (flags & ~FlagHoisted);
  }

  @override
  void set hasDeclaredInitializer(bool value) {
    flags = value
        ? (flags | FlagHasDeclaredInitializer)
        : (flags & ~FlagHasDeclaredInitializer);
  }

  @override
  void set isWildcard(bool value) {
    // TODO(kallentu): Change the name to be unique with other wildcard
    // variables.
    flags = value ? (flags | FlagWildcard) : (flags & ~FlagWildcard);
  }

  @override
  void clearAnnotations() {
    annotations = const <Expression>[];
  }

  @override
  void addAnnotation(Expression annotation) {
    if (annotations.isEmpty) {
      annotations = <Expression>[];
    }
    annotations.add(annotation..parent = this);
  }

  @override
  R accept<R>(VariableVisitor<R> v) => v.visitLegacyVariable(this);

  @override
  R accept1<R, A>(VariableVisitor1<R, A> v, A arg) =>
      v.visitLegacyVariable(this, arg);

  @override
  void visitChildren(Visitor v) {
    visitList(annotations, v);
    type.accept(v);
    initializer?.accept(v);
  }

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

  /// Returns a possibly synthesized name for this variable, consistent with
  /// the names used across all [toString] calls.
  @override
  String toString() {
    return "VariableDeclaration(${toStringInternal()})";
  }

  @override
  String toStringInternal() {
    AstPrinter printer = new AstPrinter(defaultAstTextStrategy);
    printer.writeVariableInitialization(this, includeInitializer: false);
    return printer.getText();
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeVariableInitialization(this);
    printer.write(';');
  }

  @override
  String? get cosmeticName => name;

  @override
  void set cosmeticName(String? value) {
    name = value;
  }

  @override
  VariableDeclaration? get variableDeclaration {
    throw new UnsupportedError("${this.runtimeType}.variableDeclaration");
  }

  @override
  void set variableDeclaration(VariableDeclaration? value) {}

  @override
  // TODO(62620): Conforming to [Variable] interface. Remove this.
  VariableContext get context {
    throw new UnsupportedError("${this.runtimeType}.context");
  }

  @override
  // TODO(62620): Conforming to [Variable] interface. Remove this.
  void set context(VariableContext value) {
    throw new UnsupportedError("${this.runtimeType}.context=");
  }

  @override
  Variable get asVariableDeclaration => this;

  @override
  Variable get variable => this;

  @override
  void set variable(Variable value) {
    throw new UnsupportedError("${this.runtimeType}.variable=");
  }

  @override
  bool get hasHasDeclaredInitializer => true;

  @override
  bool get hasIsConst => true;

  @override
  bool get hasIsCovariantByClass => true;

  @override
  bool get hasIsCovariantByDeclaration => true;

  @override
  bool get hasIsErroneouslyInitialized => true;

  @override
  bool get hasIsFinal => true;

  @override
  bool get hasIsHoisted => true;

  @override
  bool get hasIsInitializingFormal => true;

  @override
  bool get hasIsLate => true;

  @override
  bool get hasIsLowered => true;

  @override
  bool get hasIsRequired => true;

  @override
  bool get hasIsSuperInitializingFormal => true;

  @override
  bool get hasIsSynthesized => true;

  @override
  bool get hasIsWildcard => true;
}

/// Local variables. They aren't Statements. A [LocalVariable] is "declared" in
/// the [VariableContext] it appears in. [VariableInitializationBase]
/// (which is a [Statement]) marks the spot of the original variable declaration
/// in the Dart program.
class LocalVariable extends Variable {
  @override
  String? cosmeticName;

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

  LocalVariable({
    this.cosmeticName,
    required DartType? type,
    bool isFinal = false,
    bool isConst = false,
    bool isWildcard = false,
    bool hasDeclaredInitializer = false,
    this.initializer,
  }) : type = type ?? const DynamicType(),
       super.empty() {
    this.isFinal = isFinal;
    this.isConst = isConst;
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

  static const int FlagFinal = 1 << 0;
  static const int FlagWildcard = 1 << 1;
  static const int FlagConst = 1 << 2;
  static const int FlagLate = 1 << 3;
  static const int FlagLowered = 1 << 4;
  static const int FlagHoisted = 1 << 5;
  static const int FlagHasDeclaredInitializer = 1 << 6;
  static const int FlagErroneouslyInitialized = 1 << 7;

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
  bool get isErroneouslyInitialized => flags & FlagErroneouslyInitialized != 0;

  @override
  void set isErroneouslyInitialized(bool value) {
    flags = value
        ? (flags | FlagErroneouslyInitialized)
        : (flags & ~FlagErroneouslyInitialized);
  }

  @override
  bool get hasDeclaredInitializer => flags & FlagHasDeclaredInitializer != 0;

  @override
  void set hasDeclaredInitializer(bool value) {
    flags = value
        ? (flags | FlagHasDeclaredInitializer)
        : (flags & ~FlagHasDeclaredInitializer);
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
    if (initializer != null) {
      initializer = v.transform(initializer!);
      initializer?.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    v.transformExpressionList(annotations, this);
    if (initializer != null) {
      initializer = v.transformOrRemoveExpression(initializer!);
      initializer?.parent = this;
    }
  }

  @override
  void visitChildren(Visitor v) {
    visitList(annotations, v);
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
  bool get hasIsSynthesized => true;

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
  Variable get variable => this;

  @override
  void set variable(Variable variable) {
    throw new UnsupportedError("${this.runtimeType}.variable=");
  }

  @override
  void clearAnnotations() {
    annotations.clear();
  }

  @override
  set name(String? value) {
    cosmeticName = value;
  }
}

/// A late local variable.
class LateVariable extends Variable {
  @override
  String? cosmeticName;

  @override
  DartType type;

  @override
  VariableDeclaration? variableDeclaration;

  @override
  List<Expression> annotations = const <Expression>[];

  @override
  late VariableContext context;

  @override
  // TODO(johnniwinther): Rename to [initialValue].
  Expression? initializer;

  LateVariable({
    this.cosmeticName,
    required DartType? type,
    bool isFinal = false,
    bool isConst = false,
    bool isWildcard = false,
    bool hasDeclaredInitializer = false,
    this.initializer,
  }) : type = type ?? const DynamicType(),
       super.empty() {
    this.isFinal = isFinal;
    this.isConst = isConst;
    this.isLate = true;
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

  static const int FlagFinal = 1 << 0;
  static const int FlagWildcard = 1 << 1;
  static const int FlagConst = 1 << 2;
  static const int FlagLate = 1 << 3;
  static const int FlagLowered = 1 << 4;
  static const int FlagHoisted = 1 << 5;
  static const int FlagHasDeclaredInitializer = 1 << 6;
  static const int FlagErroneouslyInitialized = 1 << 7;

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
  bool get isErroneouslyInitialized => flags & FlagErroneouslyInitialized != 0;

  @override
  void set isErroneouslyInitialized(bool value) {
    flags = value
        ? (flags | FlagErroneouslyInitialized)
        : (flags & ~FlagErroneouslyInitialized);
  }

  @override
  bool get hasDeclaredInitializer => flags & FlagHasDeclaredInitializer != 0;

  @override
  void set hasDeclaredInitializer(bool value) {
    flags = value
        ? (flags | FlagHasDeclaredInitializer)
        : (flags & ~FlagHasDeclaredInitializer);
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
  R accept<R>(VariableVisitor<R> v) => v.visitLateVariable(this);

  @override
  R accept1<R, A>(VariableVisitor1<R, A> v, A arg) =>
      v.visitLateVariable(this, arg);

  @override
  void transformChildren(Transformer v) {
    v.transformList(annotations, this);
    if (initializer != null) {
      initializer = v.transform(initializer!);
      initializer?.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    v.transformExpressionList(annotations, this);
    if (initializer != null) {
      initializer = v.transformOrRemoveExpression(initializer!);
      initializer?.parent = this;
    }
  }

  @override
  void visitChildren(Visitor v) {
    visitList(annotations, v);
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
  bool get hasIsSynthesized => true;

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
  Variable get variable => this;

  @override
  void set variable(Variable variable) {
    throw new UnsupportedError("${this.runtimeType}.variable=");
  }

  @override
  void clearAnnotations() {
    annotations.clear();
  }

  @override
  set name(String? value) {
    cosmeticName = value;
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

  CatchVariable({
    required String name,
    required DartType? type,
    bool isWildcard = false,
  }) : catchVariableName = name,
       type = type ?? const DynamicType(),
       super.empty() {
    this.isWildcard = isWildcard;
  }

  @override
  String? get cosmeticName => catchVariableName;

  @override
  void set cosmeticName(String? value) {
    throw new UnsupportedError("${this.runtimeType}.cosmeticName=");
  }

  @override
  VariableDeclaration? get variableDeclaration {
    throw new UnsupportedError("${this.runtimeType}.variableInitialization");
  }

  @override
  void set variableDeclaration(VariableDeclaration? value) {
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
      "${this.runtimeType}.isSuperInitializingFormal=",
    );
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
  R accept<R>(VariableVisitor<R> v) => v.visitCatchVariable(this);

  @override
  R accept1<R, A>(VariableVisitor1<R, A> v, A arg) =>
      v.visitCatchVariable(this, arg);

  @override
  void transformChildren(Transformer v) {
    v.transformList(annotations, this);
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    v.transformExpressionList(annotations, this);
  }

  @override
  void visitChildren(Visitor v) {
    visitList(annotations, v);
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
  bool get hasIsFinal => false;

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
  bool get hasIsLowered => true;

  @override
  bool get hasIsWildcard => false;

  @override
  bool get hasIsSuperInitializingFormal => false;

  @override
  bool get hasIsErroneouslyInitialized => false;

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
  Variable get variable => this;

  @override
  void set variable(Variable variable) {
    throw new UnsupportedError("${this.runtimeType}.variable=");
  }

  @override
  void clearAnnotations() {
    annotations.clear();
  }

  @override
  String? get name => cosmeticName;

  @override
  set name(String? value) {
    cosmeticName = value;
  }
}

/// Abstract parameter class, the parent for positional and named parameters.
sealed class FunctionParameter extends Variable {
  Expression? defaultValue;

  FunctionParameter({
    required Expression? defaultValue,
    required bool isCovariantByDeclaration,
    required bool isRequired,
    required bool isInitializingFormal,
    required bool isSuperInitializingFormal,
    required bool isFinal,
    required bool hasDeclaredDefaultType,
    required bool isLowered,
    required bool isSynthesized,
    required bool isWildcard,
  }) : super.empty() {
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
  VariableDeclaration? get variableDeclaration => null;

  @override
  void set variableDeclaration(VariableDeclaration? value) {}

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
  static const int FlagErroneouslyInitialized = 1 << 10;

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
  bool get isErroneouslyInitialized => flags & FlagErroneouslyInitialized != 0;

  @override
  void set isErroneouslyInitialized(bool value) {
    flags = value
        ? (flags | FlagErroneouslyInitialized)
        : (flags & ~FlagErroneouslyInitialized);
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

  @override
  late VariableContext context;

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
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    v.transformExpressionList(annotations, this);
  }

  @override
  void visitChildren(Visitor v) {
    visitList(annotations, v);
  }

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
  bool get hasIsErroneouslyInitialized => true;

  @override
  int binaryOffsetNoTag = -1;

  @override
  int fileEqualsOffset = TreeNode.noOffset;

  @override
  Variable get variable => this;

  @override
  void set variable(Variable value) {
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

  @override
  late VariableContext context;

  NamedParameter({
    required this.parameterName,
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
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    v.transformExpressionList(annotations, this);
  }

  @override
  void visitChildren(Visitor v) {
    visitList(annotations, v);
  }

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
  bool get hasIsErroneouslyInitialized => true;

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
  Variable get variable => this;

  @override
  void set variable(Variable value) {
    throw new UnsupportedError("${this.runtimeType}");
  }
}

/// The variable storage for `this`.
class ThisVariable extends Variable {
  @override
  String get cosmeticName => "this-variable";

  @override
  void set cosmeticName(String? value) {}

  @override
  VariableDeclaration? get variableDeclaration => null;

  @override
  void set variableDeclaration(VariableDeclaration? value) {}

  @override
  DartType type;

  // TODO(cstefantsova): Consider a throwing implementation instead.
  @override
  List<Expression> annotations = const <Expression>[];

  @override
  late VariableContext context;

  ThisVariable({required this.type}) : super.empty();

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
  R accept<R>(VariableVisitor<R> v) => v.visitThisVariable(this);

  @override
  R accept1<R, A>(VariableVisitor1<R, A> v, A arg) =>
      v.visitThisVariable(this, arg);

  @override
  void transformChildren(Transformer v) {
    v.transformList(annotations, this);
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    v.transformExpressionList(annotations, this);
  }

  @override
  void visitChildren(Visitor v) {
    visitList(annotations, v);
  }

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

  @override
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
  Variable get variable => this;

  @override
  void set variable(Variable variable) {
    throw new UnsupportedError("${this.runtimeType}.variable=");
  }

  @override
  void clearAnnotations() {
    annotations.clear();
  }

  @override
  set name(String? value) {
    cosmeticName = value;
  }
}

/// A variable introduced during desugaring. Such variables don't correspond to
/// any variable declared by the programmer.
class SyntheticVariable extends Variable {
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

  SyntheticVariable({this.cosmeticName, required this.type, this.initializer})
    : super.empty() {
    this.initializer?.parent = this;
  }

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
  bool get isSynthesized => true;

  @override
  void set isSynthesized(bool value) {
    throw new UnsupportedError("${this.runtimeType}");
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
  bool get isWildcard {
    throw new UnsupportedError("${this.runtimeType}");
  }

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
    if (initializer != null) {
      initializer = v.transform(initializer!);
      initializer?.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    v.transformExpressionList(annotations, this);
    if (initializer != null) {
      initializer = v.transformOrRemoveExpression(initializer!);
      initializer?.parent = this;
    }
  }

  @override
  void visitChildren(Visitor v) {
    visitList(annotations, v);
    initializer?.accept(v);
  }

  @override
  String toString() {
    return "SyntheticVariable(${toStringInternal()})";
  }

  @override
  bool get isAssignable => !isConst && !isFinal;

  @override
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
  bool get hasIsSynthesized => true;

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
  Variable get variable => this;

  @override
  void set variable(Variable variable) {
    throw new UnsupportedError("${this.runtimeType}.variable=");
  }

  @override
  void clearAnnotations() {
    annotations.clear();
  }

  @override
  set name(String? value) {
    cosmeticName = value;
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
  final CaptureKind captureKind;
  final List<VariableBase> variables;

  VariableContext({required this.captureKind, required this.variables});

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

  Scope({required this.contexts});

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
  Variable variable;

  /// Contexts of the variables captured by the late variable initializer.
  ///
  /// If [variable] isn't `late`, [capturedContexts] should be `null`.
  @override
  List<VariableContext>? capturedContexts;

  VariableDeclaration(this.variable) {
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
  String toString() => 'VariableDeclaration(${toStringInternal()}';
}
