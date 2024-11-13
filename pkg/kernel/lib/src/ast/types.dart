// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../../ast.dart';

// ------------------------------------------------------------------------
//                             TYPES
// ------------------------------------------------------------------------

/// Represents nullability of a type.
enum Nullability {
  /// Non-legacy types not known to be nullable or non-nullable statically.
  ///
  /// An example of such type is type T in the example below.  Note that both
  /// int and int? can be passed in for T, so an attempt to assign null to x is
  /// a compile-time error as well as assigning x to y.
  ///
  ///   class A<T extends Object?> {
  ///     foo(T x) {
  ///       x = null;      // Compile-time error.
  ///       Object y = x;  // Compile-time error.
  ///     }
  ///   }
  undetermined,

  /// Nullable types are marked with the '?' modifier.
  ///
  /// Null, dynamic, and void are nullable by default.
  nullable,

  /// Non-nullable types are types that aren't marked with the '?' modifier.
  ///
  /// Note that Null, dynamic, and void that are nullable by default.  Note also
  /// that some types denoted by a type parameter without the '?' modifier can
  /// be something else rather than non-nullable.
  nonNullable,

  /// Types in opt-out libraries are 'legacy' types.
  ///
  /// They are both subtypes and supertypes of the nullable and non-nullable
  /// versions of the type.
  legacy
}

/// Declaration of a type variable.
///
/// Type parameters declared in a [Class] or [FunctionNode] are part of the AST,
/// have a parent pointer to its declaring class or function, and will be seen
/// by tree visitors.
///
/// Type parameters declared by a [FunctionType] are orphans and have a `null`
/// parent pointer.  [TypeParameter] objects should not be shared between
/// different [FunctionType] objects.
class TypeParameter extends TreeNode implements Annotatable {
  int flags = 0;

  /// List of metadata annotations on the type parameter.
  ///
  /// This defaults to an immutable empty list. Use [addAnnotation] to add
  /// annotations if needed.
  @override
  List<Expression> annotations = const <Expression>[];

  String? name; // Cosmetic name.

  /// Sentinel value used for the [bound] that has not yet been computed. This
  /// is needed to make the [bound] field non-nullable while supporting
  /// recursive bounds.
  static final DartType unsetBoundSentinel = new InvalidType();

  /// The bound on the type variable.
  ///
  /// This is set to [unsetBoundSentinel] temporarily during IR construction.
  /// This is set to the `Object?` for type parameters without an explicit
  /// bound.
  DartType bound;

  /// Sentinel value used for the [defaultType] that has not yet been computed.
  /// This is needed to make the [defaultType] field non-nullable while
  /// supporting recursive bounds for which the default type need to be set
  /// late.
  static final DartType unsetDefaultTypeSentinel = new InvalidType();

  /// The default value of the type variable. It is used to provide the
  /// corresponding missing type argument in type annotations and as the
  /// fall-back type value in type inference at compile time. At run time,
  /// [defaultType] is used by the backends in place of the missing type
  /// argument of a dynamic invocation of a generic function.
  DartType defaultType;

  /// Describes variance of the type parameter w.r.t. declaration on which it is
  /// defined. For classes, if variance is not explicitly set, the type
  /// parameter has legacy covariance defined by [isLegacyCovariant] which
  /// on the lattice is equivalent to [Variance.covariant]. For typedefs, it's
  /// the variance of the type parameters in the type term on the r.h.s. of the
  /// typedef.
  Variance? _variance;

  Variance get variance => _variance ?? Variance.covariant;

  void set variance(Variance? newVariance) => _variance = newVariance;

  bool get isLegacyCovariant => _variance == null;

  static const int legacyCovariantSerializationMarker = 4;

  TypeParameter([this.name, DartType? bound, DartType? defaultType])
      : bound = bound ?? unsetBoundSentinel,
        defaultType = defaultType ?? unsetDefaultTypeSentinel;

  // Must match serialized bit positions.
  static const int FlagCovariantByClass = 1 << 0;

  @Deprecated("Used TypeParameter.declaration instead.")
  @override
  TreeNode? get parent;

  @Deprecated("Used TypeParameter.declaration instead.")
  @override
  void set parent(TreeNode? value);

  // TODO(johnniwinther): Make this non-nullable.
  GenericDeclaration? get declaration {
    // TODO(johnniwinther): Store the declaration directly when [parent] is
    // removed.
    TreeNode? parent = super.parent;
    if (parent is GenericDeclaration) {
      return parent;
    } else if (parent is FunctionNode) {
      return parent.parent as GenericDeclaration;
    }
    assert(
        parent == null,
        "Unexpected type parameter parent node "
        "${parent} (${parent.runtimeType}).");
    return null;
  }

  void set declaration(GenericDeclaration? value) {
    switch (value) {
      case Typedef():
      case Class():
      case Extension():
      case ExtensionTypeDeclaration():
        super.parent = value;
      case Procedure():
        super.parent = value.function;
      case LocalFunction():
        super.parent = value.function;
      case null:
        super.parent = null;
    }
  }

  /// If this [TypeParameter] is a type parameter of a generic method, indicates
  /// whether the method implementation needs to contain a runtime type check to
  /// deal with generic covariance.
  ///
  /// When `true`, runtime checks may need to be performed.
  bool get isCovariantByClass => flags & FlagCovariantByClass != 0;

  void set isCovariantByClass(bool value) {
    flags = value
        ? (flags | FlagCovariantByClass)
        : (flags & ~FlagCovariantByClass);
  }

  @override
  void addAnnotation(Expression annotation) {
    if (annotations.isEmpty) {
      annotations = <Expression>[];
    }
    annotations.add(annotation..parent = this);
  }

  @override
  R accept<R>(TreeVisitor<R> v) => v.visitTypeParameter(this);

  @override
  R accept1<R, A>(TreeVisitor1<R, A> v, A arg) =>
      v.visitTypeParameter(this, arg);

  @override
  void visitChildren(Visitor v) {
    visitList(annotations, v);
    bound.accept(v);
    defaultType.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    v.transformList(annotations, this);
    bound = v.visitDartType(bound);
    defaultType = v.visitDartType(defaultType);
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    v.transformExpressionList(annotations, this);
    bound = v.visitDartType(bound, cannotRemoveSentinel);
    defaultType = v.visitDartType(defaultType, cannotRemoveSentinel);
  }

  /// Returns a possibly synthesized name for this type parameter, consistent
  /// with the names used across all [toString] calls.
  @override
  String toString() {
    return "TypeParameter(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeTypeParameterName(this);
  }
}

/// Declaration of a type variable by a [FunctionType]
///
/// [StructuralParameter] objects should not be shared between different
/// [FunctionType] objects.
class StructuralParameter extends Node
    implements SharedTypeParameterStructure<DartType> {
  int flags = 0;

  String? name; // Cosmetic name.

  static const int noOffset = -1;

  /// Offset in the source file it comes from.
  ///
  /// Valid values are from 0 and up, or -1 ([noOffset]) if the file offset is
  /// not available (this is the default if none is specifically set).
  int fileOffset = noOffset;

  Uri? uri;

  /// Sentinel value used for the [bound] that has not yet been computed.
  ///
  /// This is needed to make the [bound] field non-nullable while supporting
  /// recursive bounds.
  static final DartType unsetBoundSentinel = new InvalidType();

  /// The bound on the type variable.
  ///
  /// This is set to [unsetBoundSentinel] temporarily during IR construction.
  /// This is set to the `Object?` for type parameters without an explicit
  /// bound.
  @override
  DartType bound;

  /// Sentinel value used for the [defaultType] that has not yet been computed.
  ///
  /// This is needed to make the [defaultType] field non-nullable while
  /// supporting recursive bounds for which the default type need to be set
  /// late.
  static final DartType unsetDefaultTypeSentinel = new InvalidType();

  /// The default value of the type variable.
  ///
  /// It is used to provide the corresponding missing type argument in type
  /// annotations and as the fall-back type value in type inference at compile
  /// time. At run time, [defaultType] is used by the backends in place of the
  /// missing type argument of a dynamic invocation of a generic function.
  DartType defaultType;

  /// Variance of type parameter w.r.t. declaration on which it is defined.
  Variance? _variance;

  @override
  String get displayName => name ?? '<unknown>';

  Variance get variance => _variance ?? Variance.covariant;

  void set variance(Variance? newVariance) => _variance = newVariance;

  bool get isLegacyCovariant => _variance == null;

  static const int legacyCovariantSerializationMarker = 4;

  StructuralParameter([this.name, DartType? bound, DartType? defaultType])
      : bound = bound ?? unsetBoundSentinel,
        defaultType = defaultType ?? unsetDefaultTypeSentinel;

  @override
  R accept<R>(Visitor<R> v) => v.visitStructuralParameter(this);

  @override
  R accept1<R, A>(Visitor1<R, A> v, A arg) =>
      v.visitStructuralParameter(this, arg);

  @override
  void visitChildren(Visitor v) {
    bound.accept(v);
    defaultType.accept(v);
  }

  /// Returns a possibly synthesized name for this type parameter
  ///
  /// Consistent with the names used across all [toString] calls.
  @override
  String toString() {
    return "StructuralParameter(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeStructuralParameterName(this);
  }
}

class Supertype extends Node {
  Reference className;
  final List<DartType> typeArguments;

  Supertype(Class classNode, List<DartType> typeArguments)
      : this.byReference(classNode.reference, typeArguments);

  Supertype.byReference(this.className, this.typeArguments);

  Class get classNode => className.asClass;

  @override
  R accept<R>(Visitor<R> v) => v.visitSupertype(this);

  @override
  R accept1<R, A>(Visitor1<R, A> v, A arg) => v.visitSupertype(this, arg);

  @override
  void visitChildren(Visitor v) {
    classNode.acceptReference(v);
    visitList(typeArguments, v);
  }

  InterfaceType get asInterfaceType {
    return new InterfaceType(
        classNode, classNode.enclosingLibrary.nonNullable, typeArguments);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is Supertype) {
      if (className != other.className) return false;
      if (typeArguments.length != other.typeArguments.length) return false;
      for (int i = 0; i < typeArguments.length; ++i) {
        if (typeArguments[i] != other.typeArguments[i]) return false;
      }
      return true;
    } else {
      return false;
    }
  }

  @override
  int get hashCode {
    int hash = 0x3fffffff & className.hashCode;
    for (int i = 0; i < typeArguments.length; ++i) {
      hash = 0x3fffffff & (hash * 31 + (hash ^ typeArguments[i].hashCode));
    }
    return hash;
  }

  @override
  String toString() {
    return "Supertype(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeClassName(className, forType: true);
    printer.writeTypeArguments(typeArguments);
  }
}

/// A syntax-independent notion of a type.
///
/// [DartType]s are not AST nodes and may be shared between different parents.
///
/// [DartType] objects should be treated as unmodifiable objects, although
/// immutability is not enforced for List fields, and [TypeParameter]s are
/// cyclic structures that are constructed by mutation.
///
/// The `==` operator on [DartType]s compare based on type equality, not
/// object identity.
sealed class DartType extends Node implements SharedTypeStructure<DartType> {
  const DartType();

  @override
  R accept<R>(DartTypeVisitor<R> v);

  @override
  R accept1<R, A>(DartTypeVisitor1<R, A> v, A arg);

  @override
  bool operator ==(Object other) => equals(other, null);

  /// The nullability declared on the type.
  ///
  /// For example, the declared nullability of `FutureOr<int?>` is
  /// [Nullability.nonNullable], the declared nullability of `dynamic` is
  /// [Nullability.nullable], the declared nullability of `int*` is
  /// [Nullability.legacy], the declared nullability of the promoted type `X &
  /// int` where `X extends Object?`
  /// is [Nullability.undetermined].
  Nullability get declaredNullability;

  /// The nullability of the type as the property to contain null.
  ///
  /// For example, nullability-as-property of FutureOr<int?> is
  /// [Nullability.nullable], nullability-as-property of dynamic is
  /// [Nullability.nullable], nullability-as-property of int* is
  /// [Nullability.legacy], nullability-as-property of the promoted type `X &
  /// int` where `X extends Object?`
  /// is [Nullability.nonNullable].
  Nullability get nullability;

  @override
  NullabilitySuffix get nullabilitySuffix {
    if (isTypeWithoutNullabilityMarker(this)) {
      return NullabilitySuffix.none;
    } else if (isNullableTypeConstructorApplication(this)) {
      return NullabilitySuffix.question;
    } else {
      assert(isLegacyTypeConstructorApplication(this));
      return NullabilitySuffix.star;
    }
  }

  /// If this is a typedef type, repeatedly unfolds its type definition until
  /// the root term is not a typedef type, otherwise returns the type itself.
  ///
  /// Will never return a typedef type.
  DartType get unalias => this;

  /// Creates a copy of the type with the given [declaredNullability].
  ///
  /// Some types have fixed nullabilities, such as `dynamic`, `invalid-type`,
  /// `void`, or `bottom`.
  DartType withDeclaredNullability(Nullability declaredNullability);

  /// Creates the type corresponding to this type without null, if possible.
  ///
  /// Note that not all types, for instance `dynamic`, have a corresponding
  /// non-nullable type. For these, the type itself is returned.
  ///
  /// This corresponds to the `NonNull` function of the nnbd specification.
  DartType toNonNull() => computeNonNull(this);

  /// Checks if the type is potentially nullable.
  ///
  /// A type is potentially nullable if it's nullable or if its nullability is
  /// undetermined at compile time.
  bool get isPotentiallyNullable {
    return nullability == Nullability.nullable ||
        nullability == Nullability.undetermined;
  }

  /// Checks if the type is potentially non-nullable.
  ///
  /// A type is potentially non-nullable if it's non-nullable or if its
  /// nullability is undetermined at compile time.
  bool get isPotentiallyNonNullable {
    return nullability == Nullability.nonNullable ||
        nullability == Nullability.undetermined;
  }

  /// Returns the non-type parameter bound of this type, taking nullability
  /// into account.
  ///
  /// For instance in
  ///
  ///     method<T, S extends Class, U extends S?>()
  ///
  /// the non-type parameter bound of `T` is `Object?`, for `S` it is `Class`,
  /// and for `U` it is `Class?`.
  DartType get nonTypeParameterBound;

  /// Returns `true` if members *not* declared on `Object` can be accessed on
  /// a receiver of this type.
  bool get hasNonObjectMemberAccess;

  /// Returns the type with all occurrences of [ExtensionType] replaced by their
  /// representations, transitively. This is the type used at runtime to
  /// represent this type.
  ///
  /// For instance, for these declarations
  ///
  ///    extension type ET1(int id) {}
  ///    extension type ET2(ET1 id) {}
  ///    extension type ET3<T>(T id) {}
  ///
  /// the extension type erasures for `ET1`, `ET2`, `ET3<ET2>` and `List<ET2>`
  /// are `int`, `int`, `int`, `List<int>`, respectively.
  DartType get extensionTypeErasure => computeExtensionTypeErasure(this);

  /// Internal implementation of equality using [assumptions] to handle equality
  /// of type parameters on function types coinductively.
  bool equals(Object other, Assumptions? assumptions);

  @override
  String getDisplayString() => toText(const AstTextStrategy());

  @override
  bool isStructurallyEqualTo(SharedTypeStructure other) {
    // TODO(cstefantsova): Use the actual algorithm for structural equality.
    return this == other;
  }

  /// Returns a textual representation of the this type.
  ///
  /// If [verbose] is `true`, qualified names will include the library name/uri.
  @override
  String toText(AstTextStrategy strategy) {
    AstPrinter printer = new AstPrinter(strategy);
    printer.writeType(this);
    return printer.getText();
  }

  @override
  void toTextInternal(AstPrinter printer);
}

/// A type which is an instantiation of a [TypeDeclaration].
sealed class TypeDeclarationType extends DartType {
  /// The [Reference] to the [TypeDeclaration] on which this
  /// [TypeDeclarationType] is built.
  Reference get typeDeclarationReference;

  /// The type arguments used to instantiate this [TypeDeclarationType].
  List<DartType> get typeArguments;

  /// The [TypeDeclaration] on which this [TypeDeclarationType] is built.
  TypeDeclaration get typeDeclaration =>
      typeDeclarationReference.asTypeDeclaration;
}

abstract class AuxiliaryType extends DartType {
  const AuxiliaryType();

  @override
  R accept<R>(DartTypeVisitor<R> v) => v.visitAuxiliaryType(this);

  @override
  R accept1<R, A>(DartTypeVisitor1<R, A> v, A arg) =>
      v.visitAuxiliaryType(this, arg);
}

/// The type arising from invalid type annotations.
///
/// Can usually be treated as 'dynamic', but should occasionally be handled
/// differently, e.g. `x is ERROR` should evaluate to false.
class InvalidType extends DartType
    implements SharedInvalidTypeStructure<DartType> {
  @override
  final int hashCode = 12345;

  const InvalidType();

  @override
  R accept<R>(DartTypeVisitor<R> v) => v.visitInvalidType(this);

  @override
  R accept1<R, A>(DartTypeVisitor1<R, A> v, A arg) =>
      v.visitInvalidType(this, arg);

  @override
  void visitChildren(Visitor v) {}

  @override
  DartType get nonTypeParameterBound => this;

  @override
  bool get hasNonObjectMemberAccess => true;

  @override
  bool equals(Object other, Assumptions? assumptions) => other is InvalidType;

  @override
  Nullability get declaredNullability {
    // TODO(johnniwinther,cstefantsova): Consider implementing
    // invalidNullability.
    return Nullability.nullable;
  }

  @override
  Nullability get nullability {
    // TODO(johnniwinther,cstefantsova): Consider implementing
    // invalidNullability.
    return Nullability.nullable;
  }

  @override
  InvalidType withDeclaredNullability(Nullability declaredNullability) => this;

  @override
  String toString() {
    return "InvalidType(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write("<invalid>");
  }
}

class DynamicType extends DartType
    implements SharedDynamicTypeStructure<DartType> {
  @override
  final int hashCode = 54321;

  const DynamicType();

  @override
  R accept<R>(DartTypeVisitor<R> v) => v.visitDynamicType(this);

  @override
  R accept1<R, A>(DartTypeVisitor1<R, A> v, A arg) =>
      v.visitDynamicType(this, arg);

  @override
  void visitChildren(Visitor v) {}

  @override
  DartType get nonTypeParameterBound => this;

  @override
  bool get hasNonObjectMemberAccess => false;

  @override
  bool equals(Object other, Assumptions? assumptions) => other is DynamicType;

  @override
  Nullability get declaredNullability => Nullability.nullable;

  @override
  Nullability get nullability => Nullability.nullable;

  @override
  DynamicType withDeclaredNullability(Nullability declaredNullability) => this;

  @override
  String toString() {
    return "DynamicType(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write("dynamic");
  }
}

class VoidType extends DartType implements SharedVoidTypeStructure<DartType> {
  @override
  final int hashCode = 123121;

  const VoidType();

  @override
  R accept<R>(DartTypeVisitor<R> v) => v.visitVoidType(this);

  @override
  R accept1<R, A>(DartTypeVisitor1<R, A> v, A arg) =>
      v.visitVoidType(this, arg);

  @override
  void visitChildren(Visitor v) {}

  @override
  DartType get nonTypeParameterBound => this;

  @override
  bool get hasNonObjectMemberAccess => false;

  @override
  bool equals(Object other, Assumptions? assumptions) => other is VoidType;

  @override
  Nullability get declaredNullability => Nullability.nullable;

  @override
  Nullability get nullability => Nullability.nullable;

  @override
  VoidType withDeclaredNullability(Nullability declaredNullability) => this;

  @override
  String toString() {
    return "VoidType(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write("void");
  }
}

class NeverType extends DartType {
  @override
  final Nullability declaredNullability;

  const NeverType.nullable() : this.internal(Nullability.nullable);

  const NeverType.nonNullable() : this.internal(Nullability.nonNullable);

  const NeverType.legacy() : this.internal(Nullability.legacy);

  const NeverType.internal(this.declaredNullability)
      : assert(declaredNullability != Nullability.undetermined);

  static NeverType fromNullability(Nullability nullability) {
    switch (nullability) {
      case Nullability.nullable:
        return const NeverType.nullable();
      case Nullability.nonNullable:
        return const NeverType.nonNullable();
      case Nullability.legacy:
        return const NeverType.legacy();
      case Nullability.undetermined:
        throw new StateError("Unsupported nullability for 'NeverType': "
            "'${nullability}'");
    }
  }

  @override
  Nullability get nullability => declaredNullability;

  @override
  DartType get nonTypeParameterBound => this;

  @override
  bool get hasNonObjectMemberAccess => switch (declaredNullability) {
        Nullability.undetermined => false,
        Nullability.nullable => false,
        Nullability.nonNullable => true,
        Nullability.legacy => true,
      };

  @override
  int get hashCode {
    return 485786 ^ ((0x33333333 >> nullability.index) ^ 0x33333333);
  }

  @override
  R accept<R>(DartTypeVisitor<R> v) => v.visitNeverType(this);

  @override
  R accept1<R, A>(DartTypeVisitor1<R, A> v, A arg) =>
      v.visitNeverType(this, arg);

  @override
  void visitChildren(Visitor v) {}

  @override
  bool equals(Object other, Assumptions? assumptions) =>
      other is NeverType && nullability == other.nullability;

  @override
  NeverType withDeclaredNullability(Nullability declaredNullability) {
    return this.declaredNullability == declaredNullability
        ? this
        : NeverType.fromNullability(declaredNullability);
  }

  @override
  String toString() {
    return "NeverType(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write("Never");
    printer.writeNullability(declaredNullability);
  }
}

class NullType extends DartType {
  @override
  final int hashCode = 415324;

  const NullType();

  @override
  R accept<R>(DartTypeVisitor<R> v) => v.visitNullType(this);

  @override
  R accept1<R, A>(DartTypeVisitor1<R, A> v, A arg) {
    return v.visitNullType(this, arg);
  }

  @override
  void visitChildren(Visitor v) {}

  @override
  DartType get nonTypeParameterBound => this;

  @override
  bool get hasNonObjectMemberAccess => false;

  @override
  bool equals(Object other, Assumptions? assumptions) => other is NullType;

  @override
  Nullability get declaredNullability => Nullability.nullable;

  @override
  Nullability get nullability => Nullability.nullable;

  @override
  DartType withDeclaredNullability(Nullability nullability) => this;

  @override
  String toString() {
    return "NullType(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write("Null");
  }
}

class InterfaceType extends TypeDeclarationType {
  final Reference classReference;

  @override
  final Nullability declaredNullability;

  @override
  final List<DartType> typeArguments;

  /// The [typeArguments] list must not be modified after this call. If the
  /// list is omitted, 'dynamic' type arguments are filled in.
  InterfaceType(Class classNode, Nullability declaredNullability,
      [List<DartType>? typeArguments])
      : this.byReference(classNode.reference, declaredNullability,
            typeArguments ?? _defaultTypeArguments(classNode));

  InterfaceType.byReference(
      this.classReference, this.declaredNullability, this.typeArguments);

  @override
  Reference get typeDeclarationReference => classReference;

  Class get classNode => classReference.asClass;

  @override
  Nullability get nullability => declaredNullability;

  @override
  bool get hasNonObjectMemberAccess => switch (declaredNullability) {
        Nullability.undetermined => false,
        Nullability.nullable => false,
        Nullability.nonNullable => true,
        Nullability.legacy => true,
      };

  @override
  DartType get nonTypeParameterBound => this;

  static List<DartType> _defaultTypeArguments(Class classNode) {
    if (classNode.typeParameters.length == 0) {
      // Avoid allocating a list in this very common case.
      return const <DartType>[];
    } else {
      return new List<DartType>.filled(
          classNode.typeParameters.length, const DynamicType());
    }
  }

  @override
  R accept<R>(DartTypeVisitor<R> v) => v.visitInterfaceType(this);

  @override
  R accept1<R, A>(DartTypeVisitor1<R, A> v, A arg) =>
      v.visitInterfaceType(this, arg);

  @override
  void visitChildren(Visitor v) {
    classNode.acceptReference(v);
    visitList(typeArguments, v);
  }

  @override
  bool equals(Object other, Assumptions? assumptions) {
    if (identical(this, other)) return true;
    if (other is InterfaceType) {
      if (nullability != other.nullability) return false;
      if (classReference != other.classReference) return false;
      if (typeArguments.length != other.typeArguments.length) return false;
      for (int i = 0; i < typeArguments.length; ++i) {
        if (!typeArguments[i].equals(other.typeArguments[i], assumptions)) {
          return false;
        }
      }
      return true;
    } else {
      return false;
    }
  }

  @override
  int get hashCode {
    int hash = 0x3fffffff & classReference.hashCode;
    for (int i = 0; i < typeArguments.length; ++i) {
      hash = 0x3fffffff & (hash * 31 + (hash ^ typeArguments[i].hashCode));
    }
    int nullabilityHash = (0x33333333 >> nullability.index) ^ 0x33333333;
    hash = 0x3fffffff & (hash * 31 + (hash ^ nullabilityHash));
    return hash;
  }

  @override
  InterfaceType withDeclaredNullability(Nullability declaredNullability) {
    return declaredNullability == this.declaredNullability
        ? this
        : new InterfaceType.byReference(
            classReference, declaredNullability, typeArguments);
  }

  @override
  String toString() {
    return "InterfaceType(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeClassName(classReference, forType: true);
    printer.writeTypeArguments(typeArguments);
    printer.writeNullability(declaredNullability);
  }
}

/// A possibly generic function type.
class FunctionType extends DartType
    implements
        SharedFunctionTypeStructure<DartType, StructuralParameter, NamedType> {
  final List<StructuralParameter> typeParameters;
  final int requiredParameterCount;
  final List<DartType> positionalParameters;
  final List<NamedType> namedParameters; // Must be sorted.

  @override
  final Nullability declaredNullability;

  @override
  final DartType returnType;

  @override
  late final int hashCode = _computeHashCode();

  FunctionType(List<DartType> positionalParameters, this.returnType,
      this.declaredNullability,
      {this.namedParameters = const <NamedType>[],
      this.typeParameters = const <StructuralParameter>[],
      int? requiredParameterCount})
      : this.positionalParameters = positionalParameters,
        this.requiredParameterCount =
            requiredParameterCount ?? positionalParameters.length;

  @override
  Nullability get nullability => declaredNullability;

  @override
  DartType get nonTypeParameterBound => this;

  @override
  bool get hasNonObjectMemberAccess => switch (declaredNullability) {
        Nullability.undetermined => false,
        Nullability.nullable => false,
        Nullability.nonNullable => true,
        Nullability.legacy => true,
      };

  @override
  List<DartType> get positionalParameterTypes => positionalParameters;

  @override
  int get requiredPositionalParameterCount => requiredParameterCount;

  @override
  List<NamedType> get sortedNamedParameters => namedParameters;

  @override
  List<StructuralParameter> get typeFormals => typeParameters;

  @override
  R accept<R>(DartTypeVisitor<R> v) => v.visitFunctionType(this);

  @override
  R accept1<R, A>(DartTypeVisitor1<R, A> v, A arg) =>
      v.visitFunctionType(this, arg);

  @override
  void visitChildren(Visitor v) {
    visitList(typeParameters, v);
    visitList(positionalParameters, v);
    visitList(namedParameters, v);
    returnType.accept(v);
  }

  @override
  bool equals(Object other, Assumptions? assumptions) {
    if (identical(this, other)) {
      return true;
    } else if (other is FunctionType) {
      if (nullability != other.nullability) return false;
      if (typeParameters.length != other.typeParameters.length ||
          requiredParameterCount != other.requiredParameterCount ||
          positionalParameters.length != other.positionalParameters.length ||
          namedParameters.length != other.namedParameters.length) {
        return false;
      }
      if (typeParameters.isNotEmpty) {
        assumptions ??= new Assumptions();
        for (int index = 0; index < typeParameters.length; index++) {
          assumptions.assumeStructuralParameter(
              typeParameters[index], other.typeParameters[index]);
        }
        for (int index = 0; index < typeParameters.length; index++) {
          if (!typeParameters[index]
              .bound
              .equals(other.typeParameters[index].bound, assumptions)) {
            return false;
          }
        }
      }
      if (!returnType.equals(other.returnType, assumptions)) {
        return false;
      }

      for (int index = 0; index < positionalParameters.length; index++) {
        if (!positionalParameters[index]
            .equals(other.positionalParameters[index], assumptions)) {
          return false;
        }
      }
      for (int index = 0; index < namedParameters.length; index++) {
        if (!namedParameters[index]
            .equals(other.namedParameters[index], assumptions)) {
          return false;
        }
      }
      if (typeParameters.isNotEmpty) {
        for (int index = 0; index < typeParameters.length; index++) {
          assumptions!.forgetStructuralParameter(
              typeParameters[index], other.typeParameters[index]);
        }
      }
      return true;
    } else {
      return false;
    }
  }

  /// Returns a variant of this function type that does not declare any type
  /// parameters.
  ///
  /// Any uses of its type parameters become free variables in the returned
  /// type.
  FunctionType get withoutTypeParameters {
    if (typeParameters.isEmpty) return this;
    return new FunctionType(positionalParameters, returnType, nullability,
        requiredParameterCount: requiredParameterCount,
        namedParameters: namedParameters);
  }

  /// Looks up the type of the named parameter with the given name.
  ///
  /// Returns `null` if there is no named parameter with the given name.
  DartType? getNamedParameter(String name) {
    int lower = 0;
    int upper = namedParameters.length - 1;
    while (lower <= upper) {
      int pivot = (lower + upper) ~/ 2;
      NamedType namedParameter = namedParameters[pivot];
      int comparison = name.compareTo(namedParameter.name);
      if (comparison == 0) {
        return namedParameter.type;
      } else if (comparison < 0) {
        upper = pivot - 1;
      } else {
        lower = pivot + 1;
      }
    }
    return null;
  }

  int _computeHashCode() {
    int hash = 1237;
    hash = 0x3fffffff & (hash * 31 + requiredParameterCount);
    for (int i = 0; i < typeParameters.length; ++i) {
      StructuralParameter parameter = typeParameters[i];
      hash = 0x3fffffff & (hash * 31 + parameter.bound.hashCode);
    }
    for (int i = 0; i < positionalParameters.length; ++i) {
      hash = 0x3fffffff & (hash * 31 + positionalParameters[i].hashCode);
    }
    for (int i = 0; i < namedParameters.length; ++i) {
      hash = 0x3fffffff & (hash * 31 + namedParameters[i].hashCode);
    }
    hash = 0x3fffffff & (hash * 31 + returnType.hashCode);
    hash = 0x3fffffff & (hash * 31 + nullability.index);
    return hash;
  }

  @override
  FunctionType withDeclaredNullability(Nullability declaredNullability) {
    if (declaredNullability == this.declaredNullability) return this;
    return new FunctionType(
        positionalParameters, returnType, declaredNullability,
        namedParameters: namedParameters,
        typeParameters: typeParameters,
        requiredParameterCount: requiredParameterCount);
  }

  @override
  String toString() {
    return "FunctionType(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeType(returnType);
    printer.write(" Function");
    printer.writeStructuralParameters(typeParameters);
    printer.write("(");
    for (int i = 0; i < positionalParameters.length; i++) {
      if (i > 0) {
        printer.write(", ");
      }
      if (i == requiredParameterCount) {
        printer.write("[");
      }
      printer.writeType(positionalParameters[i]);
    }
    if (requiredParameterCount < positionalParameters.length) {
      printer.write("]");
    }

    if (namedParameters.isNotEmpty) {
      if (positionalParameters.isNotEmpty) {
        printer.write(", ");
      }
      printer.write("{");
      for (int i = 0; i < namedParameters.length; i++) {
        if (i > 0) {
          printer.write(", ");
        }
        printer.writeNamedType(namedParameters[i]);
      }
      printer.write("}");
    }
    printer.write(")");
    printer.writeNullability(declaredNullability);
  }
}

/// A use of a [Typedef] as a type.
///
/// The underlying type can be extracted using [unalias].
class TypedefType extends DartType {
  @override
  final Nullability declaredNullability;
  final Reference typedefReference;
  final List<DartType> typeArguments;

  TypedefType(Typedef typedef, Nullability nullability,
      [List<DartType>? typeArguments])
      : this.byReference(typedef.reference, nullability,
            typeArguments ?? const <DartType>[]);

  TypedefType.byReference(
      this.typedefReference, this.declaredNullability, this.typeArguments);

  Typedef get typedefNode => typedefReference.asTypedef;

  // TODO(cstefantsova): Replace with uniteNullabilities(declaredNullability,
  // typedefNode.type.nullability).
  @override
  Nullability get nullability => declaredNullability;

  @override
  DartType get nonTypeParameterBound => unalias.nonTypeParameterBound;

  @override
  bool get hasNonObjectMemberAccess => unalias.hasNonObjectMemberAccess;

  @override
  R accept<R>(DartTypeVisitor<R> v) => v.visitTypedefType(this);

  @override
  R accept1<R, A>(DartTypeVisitor1<R, A> v, A arg) =>
      v.visitTypedefType(this, arg);

  @override
  void visitChildren(Visitor v) {
    visitList(typeArguments, v);
    v.visitTypedefReference(typedefNode);
  }

  DartType get unaliasOnce {
    DartType result =
        Substitution.fromTypedefType(this).substituteType(typedefNode.type!);
    return result.withDeclaredNullability(combineNullabilitiesForSubstitution(
        inner: result.declaredNullability, outer: nullability));
  }

  @override
  DartType get unalias {
    return unaliasOnce.unalias;
  }

  @override
  bool equals(Object other, Assumptions? assumptions) {
    if (identical(this, other)) {
      return true;
    } else if (other is TypedefType) {
      if (nullability != other.nullability) return false;
      if (typedefReference != other.typedefReference ||
          typeArguments.length != other.typeArguments.length) {
        return false;
      }
      for (int i = 0; i < typeArguments.length; ++i) {
        if (!typeArguments[i].equals(other.typeArguments[i], assumptions)) {
          return false;
        }
      }
      return true;
    } else {
      return false;
    }
  }

  @override
  int get hashCode {
    int hash = 0x3fffffff & typedefNode.hashCode;
    for (int i = 0; i < typeArguments.length; ++i) {
      hash = 0x3fffffff & (hash * 31 + (hash ^ typeArguments[i].hashCode));
    }
    int nullabilityHash = (0x33333333 >> nullability.index) ^ 0x33333333;
    hash = 0x3fffffff & (hash * 31 + (hash ^ nullabilityHash));
    return hash;
  }

  @override
  TypedefType withDeclaredNullability(Nullability declaredNullability) {
    return declaredNullability == this.declaredNullability
        ? this
        : new TypedefType.byReference(
            typedefReference, declaredNullability, typeArguments);
  }

  @override
  String toString() {
    return "TypedefType(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeTypedefName(typedefReference);
    printer.writeTypeArguments(typeArguments);
    printer.writeNullability(declaredNullability);
  }
}

class FutureOrType extends DartType {
  final DartType typeArgument;

  @override
  final Nullability declaredNullability;

  FutureOrType(this.typeArgument, this.declaredNullability);

  @override
  Nullability get nullability {
    return uniteNullabilities(typeArgument.nullability, declaredNullability);
  }

  @override
  R accept<R>(DartTypeVisitor<R> v) => v.visitFutureOrType(this);

  @override
  R accept1<R, A>(DartTypeVisitor1<R, A> v, A arg) {
    return v.visitFutureOrType(this, arg);
  }

  @override
  void visitChildren(Visitor v) {
    typeArgument.accept(v);
  }

  @override
  DartType get nonTypeParameterBound => this;

  @override
  bool get hasNonObjectMemberAccess => false;

  @override
  bool equals(Object other, Assumptions? assumptions) {
    if (identical(this, other)) return true;
    if (other is FutureOrType) {
      if (declaredNullability != other.declaredNullability) return false;
      if (!typeArgument.equals(other.typeArgument, assumptions)) {
        return false;
      }
      return true;
    } else {
      return false;
    }
  }

  @override
  int get hashCode {
    int hash = 0x12345678;
    hash = 0x3fffffff & (hash * 31 + (hash ^ typeArgument.hashCode));
    int nullabilityHash =
        (0x33333333 >> declaredNullability.index) ^ 0x33333333;
    hash = 0x3fffffff & (hash * 31 + (hash ^ nullabilityHash));
    return hash;
  }

  @override
  FutureOrType withDeclaredNullability(Nullability declaredNullability) {
    return declaredNullability == this.declaredNullability
        ? this
        : new FutureOrType(typeArgument, declaredNullability);
  }

  @override
  String toString() {
    return "FutureOrType(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write("FutureOr<");
    printer.writeType(typeArgument);
    printer.write(">");
    printer.writeNullability(declaredNullability);
  }
}

class ExtensionType extends TypeDeclarationType {
  final Reference extensionTypeDeclarationReference;

  @override
  final Nullability declaredNullability;

  @override
  final List<DartType> typeArguments;

  ExtensionType(ExtensionTypeDeclaration extensionTypeDeclaration,
      Nullability declaredNullability, [List<DartType>? typeArguments])
      : this.byReference(
            extensionTypeDeclaration.reference,
            declaredNullability,
            typeArguments ?? _defaultTypeArguments(extensionTypeDeclaration));

  ExtensionType.byReference(this.extensionTypeDeclarationReference,
      this.declaredNullability, this.typeArguments);

  ExtensionTypeDeclaration get extensionTypeDeclaration =>
      extensionTypeDeclarationReference.asExtensionTypeDeclaration;

  @override
  Reference get typeDeclarationReference => extensionTypeDeclarationReference;

  /// Returns the type erasure of this extension type.
  ///
  /// This is the type used at runtime for this type, for instance in is-tests
  /// and as-checks.
  ///
  /// The type erasure is the recursive replacement of extension types by their
  /// type erasures in the declared representation type of
  /// [extensionTypeDeclaration] instantiation with [typeArguments].
  ///
  /// For instance
  ///
  ///     extension type E1(int it) {}
  ///     extension type E2<X>(X it) {}
  ///     extension type E3<T>(E2<List<T>> it) {}
  ///
  /// the type erasure of `E1` is `int`, type erasure of `E2<num>` is `num` and
  /// the type erasure of `E3<String>` is `List<String>`.
  @override
  DartType get extensionTypeErasure => _computeTypeErasure(
      extensionTypeDeclarationReference, typeArguments, declaredNullability);

  @override
  Nullability get nullability {
    return combineNullabilitiesForSubstitution(
        inner: extensionTypeDeclaration.inherentNullability,
        outer: declaredNullability);
  }

  @override
  DartType get nonTypeParameterBound => this;

  @override
  bool get hasNonObjectMemberAccess => switch (declaredNullability) {
        // Undetermined means that the extension type does not implement
        // `Object` but is not explicitly marked as nullable.
        Nullability.undetermined => true,
        Nullability.nullable => false,
        Nullability.nonNullable => true,
        Nullability.legacy => true,
      };

  static List<DartType> _defaultTypeArguments(
      ExtensionTypeDeclaration extensionTypeDeclaration) {
    if (extensionTypeDeclaration.typeParameters.length == 0) {
      // Avoid allocating a list in this very common case.
      return const <DartType>[];
    } else {
      return new List<DartType>.filled(
          extensionTypeDeclaration.typeParameters.length, const DynamicType());
    }
  }

  static DartType _computeTypeErasure(
      Reference extensionTypeDeclarationReference,
      List<DartType> typeArguments,
      Nullability declaredNullability) {
    ExtensionTypeDeclaration extensionTypeDeclaration =
        extensionTypeDeclarationReference.asExtensionTypeDeclaration;
    DartType result = Substitution.fromPairs(
            extensionTypeDeclaration.typeParameters, typeArguments)
        .substituteType(extensionTypeDeclaration.declaredRepresentationType);
    result = result.extensionTypeErasure;

    // The nullability of the extension type affects the nullability of the type
    // erasure only if it was [Nullability.nullable]. In all other cases, that
    // is, [Nullability.nonNullable] or [Nullability.undetermined], it is
    // unrelated to the nullability of the representation type and should be
    // ignored.
    Nullability erasureNullability;
    if (declaredNullability == Nullability.nullable) {
      erasureNullability = combineNullabilitiesForSubstitution(
          inner: result.nullability, outer: declaredNullability);
    } else {
      erasureNullability = result.nullability;
    }
    result = result.withDeclaredNullability(erasureNullability);

    return result;
  }

  @override
  R accept<R>(DartTypeVisitor<R> v) {
    return v.visitExtensionType(this);
  }

  @override
  R accept1<R, A>(DartTypeVisitor1<R, A> v, A arg) {
    return v.visitExtensionType(this, arg);
  }

  @override
  void visitChildren(Visitor v) {
    extensionTypeDeclaration.acceptReference(v);
    visitList(typeArguments, v);
  }

  @override
  bool equals(Object other, Assumptions? assumptions) {
    if (identical(this, other)) return true;
    if (other is ExtensionType) {
      if (nullability != other.nullability) return false;
      if (extensionTypeDeclarationReference !=
          other.extensionTypeDeclarationReference) {
        return false;
      }
      if (typeArguments.length != other.typeArguments.length) return false;
      for (int i = 0; i < typeArguments.length; ++i) {
        if (!typeArguments[i].equals(other.typeArguments[i], assumptions)) {
          return false;
        }
      }
      return true;
    } else {
      return false;
    }
  }

  @override
  int get hashCode {
    int hash = 0x3fffffff & extensionTypeDeclarationReference.hashCode;
    for (int i = 0; i < typeArguments.length; ++i) {
      hash = 0x3fffffff & (hash * 31 + (hash ^ typeArguments[i].hashCode));
    }
    int nullabilityHash = (0x33333333 >> nullability.index) ^ 0x33333333;
    hash = 0x3fffffff & (hash * 31 + (hash ^ nullabilityHash));
    return hash;
  }

  @override
  ExtensionType withDeclaredNullability(Nullability declaredNullability) {
    return declaredNullability == this.declaredNullability
        ? this
        : new ExtensionType.byReference(extensionTypeDeclarationReference,
            declaredNullability, typeArguments);
  }

  @override
  String toString() {
    return "ExtensionType(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer
        .writeExtensionTypeDeclarationName(extensionTypeDeclarationReference);
    printer.writeTypeArguments(typeArguments);
    printer.writeNullability(declaredNullability);
  }
}

/// A named parameter in [FunctionType].
class NamedType extends Node
    implements
        Comparable<NamedType>,
        SharedNamedTypeStructure<DartType>,
        SharedNamedFunctionParameterStructure<DartType> {
  // Flag used for serialization if [isRequired].
  static const int FlagRequiredNamedType = 1 << 0;

  @override
  final String name;
  @override
  final DartType type;
  @override
  final bool isRequired;

  const NamedType(this.name, this.type, {this.isRequired = false});

  @override
  bool operator ==(Object other) => equals(other, null);

  bool equals(Object other, Assumptions? assumptions) {
    return other is NamedType &&
        name == other.name &&
        isRequired == other.isRequired &&
        type.equals(other.type, assumptions);
  }

  @override
  int get hashCode {
    return name.hashCode * 31 + type.hashCode * 37 + isRequired.hashCode * 41;
  }

  @override
  int compareTo(NamedType other) => name.compareTo(other.name);

  @override
  R accept<R>(Visitor<R> v) => v.visitNamedType(this);

  @override
  R accept1<R, A>(Visitor1<R, A> v, A arg) => v.visitNamedType(this, arg);

  @override
  void visitChildren(Visitor v) {
    type.accept(v);
  }

  @override
  String toString() {
    return "NamedType(${toStringInternal()})";
  }

  @override
  String toText(AstTextStrategy strategy) {
    AstPrinter printer = new AstPrinter(strategy);
    printer.writeNamedType(this);
    return printer.getText();
  }

  @override
  void toTextInternal(AstPrinter printer) {
    if (isRequired) {
      printer.write("required ");
    }
    printer.write(name);
    printer.write(': ');
    printer.writeType(type);
  }
}

class IntersectionType extends DartType {
  final TypeParameterType left;
  final DartType right;

  IntersectionType(this.left, this.right) {
    // TODO(cstefantsova): Also assert that [rhs] is a subtype of [lhs.bound].

    Nullability leftNullability = left.nullability;
    Nullability rightNullability = right.nullability;
    assert(
        (leftNullability == Nullability.nonNullable &&
                rightNullability == Nullability.nonNullable) ||
            (leftNullability == Nullability.nonNullable &&
                rightNullability == Nullability.undetermined) ||
            (leftNullability == Nullability.legacy &&
                rightNullability == Nullability.legacy) ||
            (leftNullability == Nullability.undetermined &&
                rightNullability == Nullability.nonNullable) ||
            (leftNullability == Nullability.undetermined &&
                rightNullability == Nullability.nullable) ||
            (leftNullability == Nullability.undetermined &&
                rightNullability == Nullability.undetermined)
            // These are observed in real situations:
            ||
            // pkg/front_end/test/id_tests/type_promotion_test
            // replicated in nnbd_mixed/type_parameter_nullability
            (leftNullability == Nullability.nullable &&
                rightNullability == Nullability.nonNullable) ||
            // pkg/front_end/test/types/kernel_type_parser_test
            // pkg/front_end/test/fasta/incremental_hello_test
            // pkg/front_end/test/types/fasta_types_test
            // pkg/front_end/tool/fasta_perf_test
            // nnbd/issue42089
            // replicated in nnbd_mixed/type_parameter_nullability
            (leftNullability == Nullability.nullable &&
                rightNullability == Nullability.nullable) ||
            // pkg/front_end/test/dill_round_trip_test
            // pkg/front_end/test/compile_dart2js_with_no_sdk_test
            // pkg/front_end/test/types/large_app_benchmark_test
            // pkg/front_end/test/incremental_dart2js_test
            // pkg/front_end/test/read_dill_from_binary_md_test
            // pkg/front_end/test/static_types/static_type_test
            // pkg/front_end/test/split_dill_test
            // pkg/front_end/tool/incremental_perf_test
            // pkg/vm/test/kernel_front_end_test
            // general/promoted_null_aware_access
            // inference/constructors_infer_from_arguments_factory
            // inference/infer_types_on_loop_indices_for_each_loop
            // inference/infer_types_on_loop_indices_for_each_loop_async
            // replicated in nnbd_mixed/type_parameter_nullability
            (leftNullability == Nullability.legacy &&
                rightNullability == Nullability.nonNullable) ||
            // pkg/front_end/test/fasta/incremental_hello_test
            // pkg/front_end/tool/fasta_perf_test
            // replicated in nnbd_mixed/type_parameter_nullability
            (leftNullability == Nullability.nullable &&
                rightNullability == Nullability.undetermined) ||
            // These are only observed in tests and might be artifacts of the
            // tests rather than real situations:
            //
            // pkg/front_end/test/types/kernel_type_parser_test
            // pkg/front_end/test/types/fasta_types_test
            (leftNullability == Nullability.legacy &&
                rightNullability == Nullability.nullable) ||
            // pkg/front_end/test/types/kernel_type_parser_test
            // pkg/front_end/test/types/fasta_types_test
            (leftNullability == Nullability.nonNullable &&
                rightNullability == Nullability.nullable) ||
            // pkg/front_end/test/types/kernel_type_parser_test
            // pkg/front_end/test/types/fasta_types_test
            (leftNullability == Nullability.undetermined &&
                rightNullability == Nullability.legacy) ||
            // pkg/kernel/test/clone_test
            // The legacy nullability is due to RHS being InvalidType.
            (leftNullability == Nullability.nonNullable &&
                rightNullability == Nullability.legacy),
        "Unexpected nullabilities for ${left} & ${right}: "
        "leftNullability = ${leftNullability}, "
        "rightNullability = ${rightNullability}.");
  }

  @override
  DartType get nonTypeParameterBound {
    DartType resolvedTypeParameterType = right.nonTypeParameterBound;
    return resolvedTypeParameterType.withDeclaredNullability(
        combineNullabilitiesForSubstitution(
            inner: resolvedTypeParameterType.declaredNullability,
            outer: declaredNullability));
  }

  @override
  bool get hasNonObjectMemberAccess =>
      nonTypeParameterBound.hasNonObjectMemberAccess;

  @override
  R accept<R>(DartTypeVisitor<R> v) => v.visitIntersectionType(this);

  @override
  R accept1<R, A>(DartTypeVisitor1<R, A> v, A arg) =>
      v.visitIntersectionType(this, arg);

  @override
  void visitChildren(Visitor v) {
    left.accept(v);
    right.accept(v);
  }

  @override
  bool equals(Object other, Assumptions? assumptions) {
    if (identical(this, other)) {
      return true;
    } else if (other is IntersectionType) {
      return left.equals(other.left, assumptions) &&
          right.equals(other.right, assumptions);
    } else {
      return false;
    }
  }

  @override
  int get hashCode {
    int nullabilityHash = (0x33333333 >> nullability.index) ^ 0x33333333;
    int hash = nullabilityHash;
    hash = 0x3fffffff & (hash * 31 + (hash ^ left.hashCode));
    hash = 0x3fffffff & (hash * 31 + (hash ^ right.hashCode));
    return hash;
  }

  /// Computes the nullability of [IntersectionType] from its parts.
  ///
  /// [nullability] is calculated from [left.nullability] and
  /// [right.nullability].
  ///
  /// In the following program the nullability of `x` is
  /// [Nullability.undetermined] because it's copied from that of `bar`. The
  /// nullability of `y` is [Nullability.nonNullable] because its type is an
  /// intersection type where the LHS is `T` and the RHS is the promoted type
  /// `int`. The nullability of the type of `y` is computed from the
  /// nullabilities of those two types.
  ///
  ///     class A<T extends Object?> {
  ///       foo(T bar) {
  ///         var x = bar;
  ///         if (bar is int) {
  ///           var y = bar;
  ///         }
  ///       }
  ///     }
  ///
  /// The method combines the nullabilities of [left] and [right] to yield the
  /// nullability of the intersection type.
  @override
  Nullability get nullability {
    // Note that RHS is always a subtype of the bound of the type parameter.

    // The code below implements the rule for the nullability of an
    // intersection type as per the following table:
    //
    // | LHS \ RHS |  !  |  ?  |  *  |  %  |
    // |-----------|-----|-----|-----|-----|
    // |     !     |  !  |  +  | N/A |  !  |
    // |     ?     | (!) | (?) | N/A | (%) |
    // |     *     | (*) |  +  |  *  | N/A |
    // |     %     |  !  |  %  |  +  |  %  |
    //
    // In the table, LHS corresponds to [lhsNullability] in the code below; RHS
    // corresponds to [rhsNullability]; !, ?, *, and % correspond to
    // nonNullable, nullable, legacy, and undetermined values of the
    // Nullability enum.

    Nullability lhsNullability = left.nullability;
    Nullability rhsNullability = right.nullability;
    assert(
        (lhsNullability == Nullability.nonNullable &&
                rhsNullability == Nullability.nonNullable) ||
            (lhsNullability == Nullability.nonNullable &&
                rhsNullability == Nullability.undetermined) ||
            (lhsNullability == Nullability.legacy &&
                rhsNullability == Nullability.legacy) ||
            (lhsNullability == Nullability.undetermined &&
                rhsNullability == Nullability.nonNullable) ||
            (lhsNullability == Nullability.undetermined &&
                rhsNullability == Nullability.nullable) ||
            (lhsNullability == Nullability.undetermined &&
                rhsNullability == Nullability.undetermined)
            // Apparently these happens as well:
            ||
            // pkg/front_end/test/id_tests/type_promotion_test
            (lhsNullability == Nullability.nullable &&
                rhsNullability == Nullability.nonNullable) ||
            // pkg/front_end/test/types/kernel_type_parser_test
            // pkg/front_end/test/fasta/incremental_hello_test
            // pkg/front_end/test/types/fasta_types_test
            // pkg/front_end/tool/fasta_perf_test
            // nnbd/issue42089
            (lhsNullability == Nullability.nullable &&
                rhsNullability == Nullability.nullable) ||
            // pkg/front_end/test/dill_round_trip_test
            // pkg/front_end/test/compile_dart2js_with_no_sdk_test
            // pkg/front_end/test/types/large_app_benchmark_test
            // pkg/front_end/test/incremental_dart2js_test
            // pkg/front_end/test/read_dill_from_binary_md_test
            // pkg/front_end/test/static_types/static_type_test
            // pkg/front_end/test/split_dill_test
            // pkg/front_end/tool/incremental_perf_test
            // pkg/vm/test/kernel_front_end_test
            // general/promoted_null_aware_access
            // inference/constructors_infer_from_arguments_factory
            // inference/infer_types_on_loop_indices_for_each_loop
            // inference/infer_types_on_loop_indices_for_each_loop_async
            (lhsNullability == Nullability.legacy &&
                rhsNullability == Nullability.nonNullable) ||
            // pkg/front_end/test/fasta/incremental_hello_test
            // pkg/front_end/tool/fasta_perf_test
            // pkg/front_end/test/fasta/incremental_hello_test
            (lhsNullability == Nullability.nullable &&
                rhsNullability == Nullability.undetermined) ||

            // This is created but never observed.
            // (lhsNullability == Nullability.legacy &&
            //     rhsNullability == Nullability.nullable) ||

            // pkg/front_end/test/types/kernel_type_parser_test
            // pkg/front_end/test/types/fasta_types_test
            (lhsNullability == Nullability.undetermined &&
                rhsNullability == Nullability.legacy) ||
            // pkg/front_end/test/types/kernel_type_parser_test
            // pkg/front_end/test/types/fasta_types_test
            (lhsNullability == Nullability.nonNullable &&
                rhsNullability == Nullability.nullable),
        "Unexpected nullabilities for: LHS nullability = $lhsNullability, "
        "RHS nullability = ${rhsNullability}.");

    // Whenever there's N/A in the table, it means that the corresponding
    // combination of the LHS and RHS nullability is not possible when
    // compiling from Dart source files, so we can define it to be whatever is
    // faster and more convenient to implement.  The verifier should check that
    // the cases marked as N/A never occur in the output of the CFE.
    //
    // The code below uses the following extension of the table function:
    //
    // | LHS \ RHS |  !  |  ?  |  *  |  %  |
    // |-----------|-----|-----|-----|-----|
    // |     !     |  !  |  !  |  !  |  !  |
    // |     ?     | (!) | (?) |  *  | (%) |
    // |     *     | (*) |  *  |  *  |  %  |
    // |     %     |  !  |  %  |  %  |  %  |

    if (lhsNullability == Nullability.nullable &&
        rhsNullability == Nullability.nonNullable) {
      return Nullability.nonNullable;
    }

    if (lhsNullability == Nullability.nullable &&
        rhsNullability == Nullability.nullable) {
      return Nullability.nullable;
    }

    if (lhsNullability == Nullability.legacy &&
        rhsNullability == Nullability.nonNullable) {
      return Nullability.legacy;
    }

    if (lhsNullability == Nullability.nullable &&
        rhsNullability == Nullability.undetermined) {
      return Nullability.undetermined;
    }

    // Intersection with a non-nullable type always yields a non-nullable type,
    // as it's the most restrictive kind of types.
    if (lhsNullability == Nullability.nonNullable ||
        rhsNullability == Nullability.nonNullable) {
      return Nullability.nonNullable;
    }

    // If the nullability of LHS is 'undetermined', the nullability of the
    // intersection is also 'undetermined' if RHS is 'undetermined' or
    // nullable.
    //
    // Consider the following example:
    //
    //     class A<X extends Object?, Y extends X> {
    //       foo(X x) {
    //         if (x is Y) {
    //           x = null;     // Compile-time error.  Consider X = Y = int.
    //           Object a = x; // Compile-time error.  Consider X = Y = int?.
    //         }
    //         if (x is int?) {
    //           x = null;     // Compile-time error.  Consider X = int.
    //           Object b = x; // Compile-time error.  Consider X = int?.
    //         }
    //       }
    //     }
    if (lhsNullability == Nullability.undetermined ||
        rhsNullability == Nullability.undetermined) {
      return Nullability.undetermined;
    }

    return Nullability.legacy;
  }

  @override
  Nullability get declaredNullability => nullability;

  @override
  IntersectionType withDeclaredNullability(Nullability declaredNullability) {
    if (left.declaredNullability == declaredNullability) {
      return this;
    }
    TypeParameterType newLeft =
        left.withDeclaredNullability(declaredNullability);
    if (identical(newLeft, left)) {
      return this;
    }
    return new IntersectionType(newLeft, right);
  }

  @override
  String toString() {
    return "IntersectionType(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('(');
    printer.writeType(left);
    printer.write(" & ");
    printer.writeType(right);
    printer.write(')');
    printer.writeNullability(nullability);
  }
}

/// Reference to a type variable.
class TypeParameterType extends DartType {
  /// The declared nullability of a type-parameter type.
  @override
  Nullability declaredNullability;

  final TypeParameter parameter;

  TypeParameterType(this.parameter, this.declaredNullability);

  /// Creates a type-parameter type to be used in alpha-renaming.
  ///
  /// The constructed type object is supposed to be used as a value in a
  /// substitution map created to perform an alpha-renaming from parameter
  /// [from] to parameter [to] on a generic type.  The resulting type-parameter
  /// type is an occurrence of [to] as a type, but the nullability property is
  /// derived from the bound of [from].  It allows to assign the bound to [to]
  /// after the desired alpha-renaming is performed, which is often the case.
  TypeParameterType.forAlphaRenaming(TypeParameter from, TypeParameter to)
      : this(to, computeNullabilityFromBound(from));

  TypeParameterType.forAlphaRenamingFromStructuralParameters(
      StructuralParameter from, TypeParameter to)
      : this(to, StructuralParameterType.computeNullabilityFromBound(from));

  /// Creates a type-parameter type with default nullability for the library.
  ///
  /// The nullability is computed as if the programmer omitted the modifier. It
  /// means that in the opt-out libraries `Nullability.legacy` will be used, and
  /// in opt-in libraries either `Nullability.nonNullable` or
  /// `Nullability.undetermined` will be used, depending on the nullability of
  /// the bound of [parameter].
  TypeParameterType.withDefaultNullabilityForLibrary(
      this.parameter, Library library)
      : declaredNullability = computeNullabilityFromBound(parameter);

  @override
  DartType get nonTypeParameterBound {
    DartType resolvedTypeParameterType = bound.nonTypeParameterBound;
    return resolvedTypeParameterType.withDeclaredNullability(
        combineNullabilitiesForSubstitution(
            inner: resolvedTypeParameterType.declaredNullability,
            outer: declaredNullability));
  }

  @override
  bool get hasNonObjectMemberAccess =>
      nonTypeParameterBound.hasNonObjectMemberAccess;

  @override
  R accept<R>(DartTypeVisitor<R> v) => v.visitTypeParameterType(this);

  @override
  R accept1<R, A>(DartTypeVisitor1<R, A> v, A arg) =>
      v.visitTypeParameterType(this, arg);

  @override
  void visitChildren(Visitor v) {}

  @override
  bool equals(Object other, Assumptions? assumptions) {
    if (identical(this, other)) {
      return true;
    } else if (other is TypeParameterType) {
      if (nullability != other.nullability) return false;
      return parameter == other.parameter;
    } else {
      return false;
    }
  }

  @override
  int get hashCode {
    int hash = parameter.hashCode;
    int nullabilityHash = (0x33333333 >> nullability.index) ^ 0x33333333;
    hash = 0x3fffffff & (hash * 31 + (hash ^ nullabilityHash));
    return hash;
  }

  /// A quick access to the bound of the parameter.
  DartType get bound => parameter.bound;

  @override
  Nullability get nullability => declaredNullability;

  /// Gets a new [TypeParameterType] with given [declaredNullability].
  @override
  TypeParameterType withDeclaredNullability(Nullability declaredNullability) {
    if (declaredNullability == this.declaredNullability) {
      return this;
    }
    return new TypeParameterType(parameter, declaredNullability);
  }

  /// Gets the nullability of a type-parameter type based on the bound.
  ///
  /// This is a helper function to be used when the bound of the type parameter
  /// is changing or is being set for the first time, and the update on some
  /// type-parameter types is required.
  static Nullability computeNullabilityFromBound(TypeParameter typeParameter) {
    // If the bound is nullable or 'undetermined', both nullable and
    // non-nullable types can be passed in for the type parameter, making the
    // corresponding type parameter types 'undetermined.'  Otherwise, the
    // nullability matches that of the bound.
    DartType bound = typeParameter.bound;
    if (identical(bound, TypeParameter.unsetBoundSentinel)) {
      throw new StateError("Can't compute nullability from an absent bound.");
    }

    // If a type parameter's nullability depends on itself, it is deemed
    // 'undetermined'. Currently, it's possible if the type parameter has a
    // possibly nested FutureOr containing that type parameter.  If there are
    // other ways for such a dependency to exist, they should be checked here.
    bool nullabilityDependsOnItself = false;
    {
      DartType type = typeParameter.bound;
      while (type is FutureOrType) {
        type = type.typeArgument;
      }
      if (type is TypeParameterType && type.parameter == typeParameter) {
        nullabilityDependsOnItself = true;
      }
    }
    if (nullabilityDependsOnItself) {
      return Nullability.undetermined;
    }

    Nullability boundNullability =
        bound is InvalidType ? Nullability.undetermined : bound.nullability;
    return boundNullability == Nullability.nullable ||
            boundNullability == Nullability.undetermined
        ? Nullability.undetermined
        : boundNullability;
  }

  @override
  String toString() {
    return "TypeParameterType(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeTypeParameterName(parameter);
    printer.writeNullability(declaredNullability);
  }
}

/// Reference to a structural type variable declared by a [FunctionType]
class StructuralParameterType extends DartType {
  /// The declared nullability of the structural parameter type.
  @override
  Nullability declaredNullability;

  final StructuralParameter parameter;

  StructuralParameterType(this.parameter, this.declaredNullability);

  /// Creates a structural parameter type to be used in alpha-renaming.
  ///
  /// The constructed type object is supposed to be used as a value in a
  /// substitution map created to perform an alpha-renaming from the parameter
  /// [from] to the parameter [to] on a generic type. The resulting structural
  /// parameter type is an occurrence of [to] as a type, but the nullability
  /// property is derived from the bound of [from].
  ///
  /// A typical use of this constructor is to create a [StructuralParameterType]
  /// referring to [StructuralParameter] [from] that is not fully formed yet and
  /// may miss a bound. In case of alpha renaming it is assumed that nothing but
  /// the identity of the variables change, and the bound of the parameter being
  /// replaced can be used to compute the nullability of the replacement.
  StructuralParameterType.forAlphaRenaming(
      StructuralParameter from, StructuralParameter to)
      : this(to, computeNullabilityFromBound(from));

  StructuralParameterType.forAlphaRenamingFromTypeParameters(
      TypeParameter from, StructuralParameter to)
      : this(to, TypeParameterType.computeNullabilityFromBound(from));

  @override
  DartType get nonTypeParameterBound {
    DartType resolvedTypeParameterType = bound.nonTypeParameterBound;
    return resolvedTypeParameterType.withDeclaredNullability(
        combineNullabilitiesForSubstitution(
            inner: resolvedTypeParameterType.nullability,
            outer: declaredNullability));
  }

  @override
  bool get hasNonObjectMemberAccess =>
      nonTypeParameterBound.hasNonObjectMemberAccess;

  @override
  R accept<R>(DartTypeVisitor<R> v) => v.visitStructuralParameterType(this);

  @override
  R accept1<R, A>(DartTypeVisitor1<R, A> v, A arg) =>
      v.visitStructuralParameterType(this, arg);

  @override
  void visitChildren(Visitor v) {}

  @override
  bool operator ==(Object other) => equals(other, null);

  @override
  bool equals(Object other, Assumptions? assumptions) {
    if (identical(this, other)) {
      return true;
    } else if (other is StructuralParameterType) {
      if (nullability != other.nullability) return false;
      if (parameter != other.parameter) {
        // Function type parameters are also equal by assumption.
        if (assumptions == null) {
          return false;
        }
        if (!assumptions.isAssumedStructuralParameter(
            parameter, other.parameter)) {
          return false;
        }
      }
      return true;
    } else {
      return false;
    }
  }

  @override
  int get hashCode {
    int hash = 0;
    int nullabilityHash = (0x33333333 >> nullability.index) ^ 0x33333333;
    hash = 0x3fffffff & (hash * 31 + (hash ^ nullabilityHash));
    return hash;
  }

  /// A quick access to the bound of the parameter.
  DartType get bound => parameter.bound;

  @override
  Nullability get nullability => declaredNullability;

  /// Gets a new [StructuralParameterType] with given [declaredNullability].
  @override
  StructuralParameterType withDeclaredNullability(
      Nullability declaredNullability) {
    if (declaredNullability == this.declaredNullability) {
      return this;
    }
    return new StructuralParameterType(parameter, declaredNullability);
  }

  /// Gets the nullability of a structural parameter type based on the bound.
  ///
  /// This is a helper function to be used when the bound of the structural
  /// parameter is changing or is being set for the first time, and the update
  /// on some structural parameter types is required.
  static Nullability computeNullabilityFromBound(
      StructuralParameter structuralParameter) {
    // If the bound is nullable or 'undetermined', both nullable and
    // non-nullable types can be passed in for the type parameter, making the
    // corresponding type parameter types 'undetermined.'  Otherwise, the
    // nullability matches that of the bound.
    DartType bound = structuralParameter.bound;
    if (identical(bound, StructuralParameter.unsetBoundSentinel)) {
      throw new StateError("Can't compute nullability from an absent bound.");
    }

    // If a type parameter's nullability depends on itself, it is deemed
    // 'undetermined'. Currently, it's possible if the type parameter has a
    // possibly nested FutureOr containing that type parameter.  If there are
    // other ways for such a dependency to exist, they should be checked here.
    bool nullabilityDependsOnItself = false;
    {
      DartType type = structuralParameter.bound;
      while (type is FutureOrType) {
        type = type.typeArgument;
      }
      if (type is StructuralParameterType &&
          type.parameter == structuralParameter) {
        nullabilityDependsOnItself = true;
      }
    }
    if (nullabilityDependsOnItself) {
      return Nullability.undetermined;
    }

    Nullability boundNullability =
        bound is InvalidType ? Nullability.undetermined : bound.nullability;
    return boundNullability == Nullability.nullable ||
            boundNullability == Nullability.undetermined
        ? Nullability.undetermined
        : boundNullability;
  }

  @override
  String toString() {
    return "StructuralParameterType(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeStructuralParameterName(parameter);
    printer.writeNullability(declaredNullability);
  }
}

class RecordType extends DartType
    implements SharedRecordTypeStructure<DartType> {
  final List<DartType> positional;
  final List<NamedType> named;

  @override
  final Nullability declaredNullability;

  RecordType(this.positional, this.named, this.declaredNullability)
      : /*TODO(johnniwinther): Enabled this assert:
        assert(named.length == named.map((p) => p.name).toSet().length,
            "Named field types must have unique names in a RecordType: "
            "${named}"),*/
        assert(() {
          // Assert that the named field types are sorted.
          for (int i = 1; i < named.length; i++) {
            if (named[i].name.compareTo(named[i - 1].name) < 0) {
              return false;
            }
          }
          return true;
        }(),
            "Named field types aren't sorted lexicographically "
            "in a RecordType: ${named}");

  List<SharedNamedTypeStructure<DartType>> get namedTypes => named;

  @override
  List<SharedNamedTypeStructure<DartType>> get sortedNamedTypes {
    return namedTypes;
  }

  @override
  Nullability get nullability => declaredNullability;

  @override
  DartType get nonTypeParameterBound => this;

  @override
  bool get hasNonObjectMemberAccess => switch (declaredNullability) {
        Nullability.undetermined => false,
        Nullability.nullable => false,
        Nullability.nonNullable => true,
        Nullability.legacy => true,
      };

  @override
  List<DartType> get positionalTypes => positional;

  @override
  R accept<R>(DartTypeVisitor<R> v) {
    return v.visitRecordType(this);
  }

  @override
  R accept1<R, A>(DartTypeVisitor1<R, A> v, A arg) {
    return v.visitRecordType(this, arg);
  }

  @override
  void visitChildren(Visitor v) {
    visitList(positional, v);
    visitList(named, v);
  }

  @override
  bool equals(Object other, Assumptions? assumptions) {
    if (identical(this, other)) {
      return true;
    } else if (other is RecordType) {
      if (nullability != other.nullability) return false;
      if (positional.length != other.positional.length) return false;
      if (named.length != other.named.length) return false;
      for (int index = 0; index < positional.length; index++) {
        if (!positional[index].equals(other.positional[index], assumptions)) {
          return false;
        }
      }
      for (int index = 0; index < named.length; index++) {
        if (!named[index].equals(other.named[index], assumptions)) {
          return false;
        }
      }
      return true;
    } else {
      return false;
    }
  }

  @override
  int get hashCode {
    int hash = 1237;
    for (int i = 0; i < positional.length; ++i) {
      hash = 0x3fffffff & (hash * 31 + positional[i].hashCode);
    }
    for (int i = 0; i < named.length; ++i) {
      hash = 0x3fffffff & (hash * 31 + named[i].hashCode);
    }
    hash = 0x3fffffff & (hash * 31 + nullability.index);
    return hash;
  }

  @override
  RecordType withDeclaredNullability(Nullability declaredNullability) {
    return declaredNullability == this.declaredNullability
        ? this
        : new RecordType(this.positional, this.named, declaredNullability);
  }

  @override
  String toString() {
    return "RecordType(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write("(");
    printer.writeTypes(positional);
    if (named.isNotEmpty) {
      if (positional.isNotEmpty) {
        printer.write(", ");
      }
      printer.write("{");
      for (int i = 0; i < named.length; i++) {
        if (i > 0) {
          printer.write(", ");
        }
        printer.writeType(named[i].type);
        printer.write(' ');
        printer.write(named[i].name);
      }
      printer.write("}");
    }
    printer.write(")");
  }
}
