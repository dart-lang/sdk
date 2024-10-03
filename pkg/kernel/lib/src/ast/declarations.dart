// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../../ast.dart';

// ------------------------------------------------------------------------
//          DECLARATIONS: CLASSES, EXTENSIONS, and EXTENSION TYPES
// ------------------------------------------------------------------------

/// Common interface for [Class] and [ExtensionTypeDeclaration].
sealed class TypeDeclaration
    implements Annotatable, FileUriNode, GenericDeclaration {
  /// The name of the declaration.
  ///
  /// This must be unique within the library.
  String get name;
}

/// Declaration of a regular class or a mixin application.
///
/// Mixin applications may not contain fields or procedures, as they implicitly
/// use those from its mixed-in type.  However, the IR does not enforce this
/// rule directly, as doing so can obstruct transformations.  It is possible to
/// transform a mixin application to become a regular class, and vice versa.
class Class extends NamedNode implements TypeDeclaration {
  /// Start offset of the class in the source file it comes from.
  ///
  /// Note that this includes annotations if any.
  ///
  /// Valid values are from 0 and up, or -1 ([TreeNode.noOffset]) if the file
  /// start offset is not available (this is the default if none is specifically
  /// set).
  int startFileOffset = TreeNode.noOffset;

  /// End offset in the source file it comes from. Valid values are from 0 and
  /// up, or -1 ([TreeNode.noOffset]) if the file end offset is not available
  /// (this is the default if none is specifically set).
  int fileEndOffset = TreeNode.noOffset;

  @override
  List<int>? get fileOffsetsIfMultiple =>
      [fileOffset, startFileOffset, fileEndOffset];

  /// List of metadata annotations on the class.
  ///
  /// This defaults to an immutable empty list. Use [addAnnotation] to add
  /// annotations if needed.
  @override
  List<Expression> annotations = const <Expression>[];

  /// Name of the class.
  ///
  /// Must be non-null and must be unique within the library.
  ///
  /// The name may contain characters that are not valid in a Dart identifier,
  /// in particular, the symbol '&' is used in class names generated for mixin
  /// applications.
  @override
  String name;

  // Must match serialized bit positions.
  static const int FlagAbstract = 1 << 0;
  static const int FlagEnum = 1 << 1;
  static const int FlagAnonymousMixin = 1 << 2;
  static const int FlagEliminatedMixin = 1 << 3;
  static const int FlagMixinDeclaration = 1 << 4;
  static const int FlagHasConstConstructor = 1 << 5;
  static const int FlagMacro = 1 << 6;
  static const int FlagSealed = 1 << 7;
  static const int FlagMixinClass = 1 << 8;
  static const int FlagBase = 1 << 9;
  static const int FlagInterface = 1 << 10;
  static const int FlagFinal = 1 << 11;

  int flags = 0;

  bool get isAbstract => flags & FlagAbstract != 0;

  void set isAbstract(bool value) {
    flags = value ? (flags | FlagAbstract) : (flags & ~FlagAbstract);
  }

  /// Whether this class is an enum.
  bool get isEnum => flags & FlagEnum != 0;

  void set isEnum(bool value) {
    flags = value ? (flags | FlagEnum) : (flags & ~FlagEnum);
  }

  /// Whether this class is a macro class.
  bool get isMacro => flags & FlagMacro != 0;

  void set isMacro(bool value) {
    flags = value ? (flags | FlagMacro) : (flags & ~FlagMacro);
  }

  /// Whether this class is a sealed class.
  bool get isSealed => flags & FlagSealed != 0;

  void set isSealed(bool value) {
    flags = value ? (flags | FlagSealed) : (flags & ~FlagSealed);
  }

  /// Whether this class is a base class.
  bool get isBase => flags & FlagBase != 0;

  void set isBase(bool value) {
    flags = value ? (flags | FlagBase) : (flags & ~FlagBase);
  }

  /// Whether this class is an interface class.
  bool get isInterface => flags & FlagInterface != 0;

  void set isInterface(bool value) {
    flags = value ? (flags | FlagInterface) : (flags & ~FlagInterface);
  }

  /// Whether this class is a final class.
  bool get isFinal => flags & FlagFinal != 0;

  void set isFinal(bool value) {
    flags = value ? (flags | FlagFinal) : (flags & ~FlagFinal);
  }

  /// Whether this class is a synthetic implementation created for each
  /// mixed-in class. For example the following code:
  /// class Z extends A with B, C, D {}
  /// class A {}
  /// class B {}
  /// class C {}
  /// class D {}
  /// ...creates:
  /// abstract class _Z&A&B extends A mixedIn B {}
  /// abstract class _Z&A&B&C extends A&B mixedIn C {}
  /// abstract class _Z&A&B&C&D extends A&B&C mixedIn D {}
  /// class Z extends _Z&A&B&C&D {}
  /// All X&Y classes are marked as synthetic.
  bool get isAnonymousMixin => flags & FlagAnonymousMixin != 0;

  void set isAnonymousMixin(bool value) {
    flags =
        value ? (flags | FlagAnonymousMixin) : (flags & ~FlagAnonymousMixin);
  }

  /// Whether this class was transformed from a mixin application.
  /// In such case, its mixed-in type was pulled into the end of implemented
  /// types list.
  bool get isEliminatedMixin => flags & FlagEliminatedMixin != 0;

  void set isEliminatedMixin(bool value) {
    flags =
        value ? (flags | FlagEliminatedMixin) : (flags & ~FlagEliminatedMixin);
  }

  /// Whether this class is a mixin class.
  ///
  /// The `mixin` modifier was added to the class declaration which allows the
  /// class to be used as a mixin. The class can be mixed in by other classes
  /// outside of its library. Otherwise, classes are not able to be used as a
  /// mixin outside of its library from version 3.0 and later.
  bool get isMixinClass => flags & FlagMixinClass != 0;

  void set isMixinClass(bool value) {
    flags = value ? (flags | FlagMixinClass) : (flags & ~FlagMixinClass);
  }

  /// True if this class was a mixin declaration in Dart.
  ///
  /// Mixins are declared in Dart with the `mixin` keyword.  They are compiled
  /// to Kernel classes.
  bool get isMixinDeclaration => flags & FlagMixinDeclaration != 0;

  void set isMixinDeclaration(bool value) {
    flags = value
        ? (flags | FlagMixinDeclaration)
        : (flags & ~FlagMixinDeclaration);
  }

  /// True if this class declares one or more constant constructors.
  bool get hasConstConstructor => flags & FlagHasConstConstructor != 0;

  void set hasConstConstructor(bool value) {
    flags = value
        ? (flags | FlagHasConstConstructor)
        : (flags & ~FlagHasConstConstructor);
  }

  /// If this class is a mixin declaration, this list contains the types from
  /// the `on` clause. Otherwise the list is empty.
  List<Supertype> get onClause => _onClause ??= _computeOnClause();

  List<Supertype> _computeOnClause() {
    List<Supertype> constraints = <Supertype>[];

    // Not a mixin declaration.
    if (!isMixinDeclaration) return constraints;

    // Otherwise we have a left-linear binary tree (subtrees are supertype and
    // mixedInType) of constraints, where all the interior nodes are anonymous
    // mixin applications.
    Supertype? current = supertype;
    while (current != null && current.classNode.isAnonymousMixin) {
      Class currentClass = current.classNode;
      assert(currentClass.implementedTypes.length == 2);
      Substitution substitution = Substitution.fromSupertype(current);
      constraints.add(
          substitution.substituteSupertype(currentClass.implementedTypes[1]));
      current =
          substitution.substituteSupertype(currentClass.implementedTypes[0]);
    }
    return constraints..add(current!);
  }

  /// The URI of the source file this class was loaded from.
  @override
  Uri fileUri;

  @override
  final List<TypeParameter> typeParameters;

  /// The immediate super type, or `null` if this is the root class.
  Supertype? supertype;

  /// The mixed-in type if this is a mixin application, otherwise `null`.
  Supertype? mixedInType;

  /// The types from the `implements` clause.
  List<Supertype> implementedTypes;

  List<Supertype>? _onClause;

  /// Internal. Should *ONLY* be used from within kernel.
  ///
  /// If non-null, the function that will have to be called to fill-out the
  /// content of this class. Note that this should not be called directly
  /// though.
  void Function()? lazyBuilder;

  /// Makes sure the class is loaded, i.e. the fields, procedures etc have been
  /// loaded from the dill. Generally, one should not need to call this as it is
  /// done automatically when accessing the lists.
  void ensureLoaded() {
    void Function()? lazyBuilderLocal = lazyBuilder;
    if (lazyBuilderLocal != null) {
      lazyBuilder = null;
      lazyBuilderLocal();
    }
  }

  List<Field> _fieldsInternal;
  DirtifyingList<Field>? _fieldsView;

  /// Fields declared in the class.
  ///
  /// For mixin applications this should be empty.
  List<Field> get fields {
    ensureLoaded();
    // If already dirty the caller just might as well add stuff directly too.
    if (dirty) return _fieldsInternal;
    return _fieldsView ??= new DirtifyingList(this, _fieldsInternal);
  }

  /// Internal. Should *ONLY* be used from within kernel.
  ///
  /// Used for adding fields when reading the dill file.
  void set fieldsInternal(List<Field> fields) {
    _fieldsInternal = fields;
    _fieldsView = null;
  }

  List<Constructor> _constructorsInternal;
  DirtifyingList<Constructor>? _constructorsView;

  /// Constructors declared in the class.
  List<Constructor> get constructors {
    ensureLoaded();
    // If already dirty the caller just might as well add stuff directly too.
    if (dirty) return _constructorsInternal;
    return _constructorsView ??=
        new DirtifyingList(this, _constructorsInternal);
  }

  /// Internal. Should *ONLY* be used from within kernel.
  ///
  /// Used for adding constructors when reading the dill file.
  void set constructorsInternal(List<Constructor> constructors) {
    _constructorsInternal = constructors;
    _constructorsView = null;
  }

  List<Procedure> _proceduresInternal;
  DirtifyingList<Procedure>? _proceduresView;

  /// Procedures declared in the class.
  ///
  /// For mixin applications this should only contain forwarding stubs.
  List<Procedure> get procedures {
    ensureLoaded();
    // If already dirty the caller just might as well add stuff directly too.
    if (dirty) return _proceduresInternal;
    return _proceduresView ??= new DirtifyingList(this, _proceduresInternal);
  }

  /// Internal. Should *ONLY* be used from within kernel.
  ///
  /// Used for adding procedures when reading the dill file.
  void set proceduresInternal(List<Procedure> procedures) {
    _proceduresInternal = procedures;
    _proceduresView = null;
  }

  Class(
      {required this.name,
      bool isAbstract = false,
      bool isAnonymousMixin = false,
      this.supertype,
      this.mixedInType,
      List<TypeParameter>? typeParameters,
      List<Supertype>? implementedTypes,
      List<Constructor>? constructors,
      List<Procedure>? procedures,
      List<Field>? fields,
      required this.fileUri,
      Reference? reference})
      : this.typeParameters = typeParameters ?? <TypeParameter>[],
        this.implementedTypes = implementedTypes ?? <Supertype>[],
        this._fieldsInternal = fields ?? <Field>[],
        this._constructorsInternal = constructors ?? <Constructor>[],
        this._proceduresInternal = procedures ?? <Procedure>[],
        super(reference) {
    setParents(this.typeParameters, this);
    setParents(this._constructorsInternal, this);
    setParents(this._proceduresInternal, this);
    setParents(this._fieldsInternal, this);
    this.isAbstract = isAbstract;
    this.isAnonymousMixin = isAnonymousMixin;
  }

  @override
  CanonicalName bindCanonicalNames(CanonicalName parent) {
    return parent.getChild(name)..bindTo(reference);
  }

  /// Computes the canonical name for this class and all its members.
  void ensureCanonicalNames(CanonicalName parent) {
    CanonicalName canonicalName = bindCanonicalNames(parent);
    if (!dirty) return;
    for (int i = 0; i < fields.length; ++i) {
      fields[i].bindCanonicalNames(canonicalName);
    }
    for (int i = 0; i < procedures.length; ++i) {
      procedures[i].bindCanonicalNames(canonicalName);
    }
    for (int i = 0; i < constructors.length; ++i) {
      constructors[i].bindCanonicalNames(canonicalName);
    }
    dirty = false;
  }

  /// This is an advanced feature. Use of this method should be coordinated
  /// with the kernel team.
  ///
  /// See [Component.relink] for a comprehensive description.
  ///
  /// Makes sure all references in named nodes in this class points to said
  /// named node.
  void relink() {
    this.reference.node = this;
    for (int i = 0; i < fields.length; ++i) {
      Field member = fields[i];
      member._relinkNode();
    }
    for (int i = 0; i < procedures.length; ++i) {
      Procedure member = procedures[i];
      member._relinkNode();
    }
    for (int i = 0; i < constructors.length; ++i) {
      Constructor member = constructors[i];
      member._relinkNode();
    }
    dirty = false;
  }

  /// The immediate super class, or `null` if this is the root class.
  Class? get superclass => supertype?.classNode;

  /// The mixed-in class if this is a mixin application, otherwise `null`.
  ///
  /// Note that this may itself be a mixin application.  Use [mixin] to get the
  /// class that has the fields and procedures.
  Class? get mixedInClass => mixedInType?.classNode;

  /// The class that declares the field and procedures of this class.
  Class get mixin => mixedInClass?.mixin ?? this;

  bool get isMixinApplication => mixedInType != null;

  String get demangledName {
    if (isAnonymousMixin) return nameAsMixinApplication;
    assert(!name.contains('&'));
    return name;
  }

  String get nameAsMixinApplication {
    assert(isAnonymousMixin);
    return demangleMixinApplicationName(name);
  }

  String get nameAsMixinApplicationSubclass {
    assert(isAnonymousMixin);
    return demangleMixinApplicationSubclassName(name);
  }

  /// Members declared in this class.
  ///
  /// This getter is for convenience, not efficiency.  Consider manually
  /// iterating the members to speed up code in production.
  Iterable<Member> get members => <Iterable<Member>>[
        fields,
        constructors,
        procedures,
      ].expand((x) => x);

  void forEachMember(void action(Member element)) {
    fields.forEach(action);
    constructors.forEach(action);
    procedures.forEach(action);
  }

  /// The immediately extended, mixed-in, and implemented types.
  ///
  /// This getter is for convenience, not efficiency.  Consider manually
  /// iterating the super types to speed up code in production.
  Iterable<Supertype> get supers => <Iterable<Supertype>>[
        supertype == null ? const [] : [supertype!],
        mixedInType == null ? const [] : [mixedInType!],
        implementedTypes
      ].expand((x) => x);

  /// The library containing this class.
  Library get enclosingLibrary => parent as Library;

  /// Internal. Should *ONLY* be used from within kernel.
  ///
  /// If true we have to compute canonical names for all children of this class.
  /// if false we can skip it.
  bool dirty = true;

  /// Adds a constructor to this class.
  void addConstructor(Constructor constructor) {
    dirty = true;
    constructor.parent = this;
    _constructorsInternal.add(constructor);
  }

  /// Adds a procedure to this class.
  void addProcedure(Procedure procedure) {
    dirty = true;
    procedure.parent = this;
    _proceduresInternal.add(procedure);
  }

  /// Adds a field to this class.
  void addField(Field field) {
    dirty = true;
    field.parent = this;
    _fieldsInternal.add(field);
  }

  @override
  void addAnnotation(Expression node) {
    if (annotations.isEmpty) {
      annotations = <Expression>[];
    }
    annotations.add(node);
    node.parent = this;
  }

  @override
  R accept<R>(TreeVisitor<R> v) => v.visitClass(this);

  @override
  R accept1<R, A>(TreeVisitor1<R, A> v, A arg) => v.visitClass(this, arg);

  R acceptReference<R>(Visitor<R> v) => v.visitClassReference(this);

  Supertype get asRawSupertype {
    return new Supertype(this,
        new List<DartType>.filled(typeParameters.length, const DynamicType()));
  }

  Supertype get asThisSupertype {
    return new Supertype(
        this, getAsTypeArguments(typeParameters, this.enclosingLibrary));
  }

  /// Returns the type of `this` for the class using [coreTypes] for caching.
  InterfaceType getThisType(CoreTypes coreTypes, Nullability nullability) {
    return coreTypes.thisInterfaceType(this, nullability);
  }

  @override
  String toString() => 'Class(${toStringInternal()})';

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeClassName(reference);
  }

  @override
  void visitChildren(Visitor v) {
    visitList(annotations, v);
    visitList(typeParameters, v);
    supertype?.accept(v);
    mixedInType?.accept(v);
    visitList(implementedTypes, v);
    visitList(constructors, v);
    visitList(procedures, v);
    visitList(fields, v);
  }

  @override
  void transformChildren(Transformer v) {
    v.transformList(annotations, this);
    v.transformList(typeParameters, this);
    if (supertype != null) {
      supertype = v.visitSupertype(supertype!);
    }
    if (mixedInType != null) {
      mixedInType = v.visitSupertype(mixedInType!);
    }
    v.transformSupertypeList(implementedTypes);
    v.transformList(constructors, this);
    v.transformList(procedures, this);
    v.transformList(fields, this);
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    v.transformExpressionList(annotations, this);
    v.transformTypeParameterList(typeParameters, this);
    if (supertype != null) {
      Supertype newSupertype = v.visitSupertype(supertype!, dummySupertype);
      if (identical(newSupertype, dummySupertype)) {
        supertype = null;
      } else {
        supertype = newSupertype;
      }
    }
    if (mixedInType != null) {
      Supertype newMixedInType = v.visitSupertype(mixedInType!, dummySupertype);
      if (identical(newMixedInType, dummySupertype)) {
        mixedInType = null;
      } else {
        mixedInType = newMixedInType;
      }
    }
    v.transformSupertypeList(implementedTypes);
    v.transformConstructorList(constructors, this);
    v.transformProcedureList(procedures, this);
    v.transformFieldList(fields, this);
  }

  @override
  Location? _getLocationInEnclosingFile(int offset) {
    return _getLocationInComponent(enclosingComponent, fileUri, offset,
        viaForErrorMessage: "Class '$name'");
  }
}

/// Declaration of an extension.
///
/// The members are converted into top-level procedures and only accessible
/// by reference in the [Extension] node.
class Extension extends NamedNode
    implements Annotatable, FileUriNode, GenericDeclaration {
  /// Name of the extension.
  ///
  /// If unnamed, the extension will be given a synthesized name by the
  /// front end.
  String name;

  /// The URI of the source file this class was loaded from.
  @override
  Uri fileUri;

  /// Type parameters declared on the extension.
  @override
  final List<TypeParameter> typeParameters;

  /// The type in the 'on clause' of the extension declaration.
  ///
  /// For instance A in:
  ///
  ///   class A {}
  ///   extension B on A {}
  ///
  /// The 'on clause' appears also in the experimental feature 'extension
  /// types' as a part of an extension type declaration, for example:
  ///
  ///   class A {}
  ///   extension type B on A {}
  late DartType onType;

  /// The members declared by the extension.
  ///
  /// The members are converted into top-level members and only accessible
  /// by reference through [ExtensionMemberDescriptor].
  List<ExtensionMemberDescriptor> memberDescriptors;

  @override
  List<Expression> annotations = const <Expression>[];

  // Must match serialized bit positions.
  static const int FlagUnnamedExtension = 1 << 0;

  int flags = 0;

  @override
  void addAnnotation(Expression node) {
    if (annotations.isEmpty) {
      annotations = <Expression>[];
    }
    annotations.add(node);
    node.parent = this;
  }

  Extension(
      {required this.name,
      List<TypeParameter>? typeParameters,
      DartType? onType,
      List<ExtensionMemberDescriptor>? memberDescriptors,
      required this.fileUri,
      Reference? reference})
      : this.typeParameters = typeParameters ?? <TypeParameter>[],
        this.memberDescriptors =
            memberDescriptors ?? <ExtensionMemberDescriptor>[],
        super(reference) {
    setParents(this.typeParameters, this);
    if (onType != null) {
      this.onType = onType;
    }
  }

  @override
  void bindCanonicalNames(CanonicalName parent) {
    parent.getChild(name).bindTo(reference);
  }

  Library get enclosingLibrary => parent as Library;

  bool get isUnnamedExtension {
    return flags & FlagUnnamedExtension != 0;
  }

  void set isUnnamedExtension(bool value) {
    flags = value
        ? (flags | FlagUnnamedExtension)
        : (flags & ~FlagUnnamedExtension);
  }

  @override
  R accept<R>(TreeVisitor<R> v) => v.visitExtension(this);

  @override
  R accept1<R, A>(TreeVisitor1<R, A> v, A arg) => v.visitExtension(this, arg);

  @override
  void visitChildren(Visitor v) {
    visitList(annotations, v);
    visitList(typeParameters, v);
    onType.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    v.transformList(annotations, this);
    v.transformList(typeParameters, this);
    onType = v.visitDartType(onType);
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    v.transformExpressionList(annotations, this);
    v.transformTypeParameterList(typeParameters, this);
    onType = v.visitDartType(onType, cannotRemoveSentinel);
  }

  @override
  Location? _getLocationInEnclosingFile(int offset) {
    return _getLocationInComponent(enclosingComponent, fileUri, offset,
        viaForErrorMessage: "Extension '$name'");
  }

  @override
  String toString() {
    return "Extension(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeExtensionName(reference);
  }
}

enum ExtensionMemberKind {
  Field,
  Method,
  Getter,
  Setter,
  Operator,
}

/// Information about an member declaration in an extension.
class ExtensionMemberDescriptor {
  static const int FlagStatic = 1 << 0; // Must match serialized bit positions.

  /// The name of the extension member.
  ///
  /// The name of the generated top-level member is mangled to ensure
  /// uniqueness. This name is used to lookup an extension method in the
  /// extension itself.
  Name name;

  /// [ExtensionMemberKind] kind of the original member.
  ///
  /// An extension method is converted into a regular top-level method. For
  /// instance:
  ///
  ///     class A {
  ///       var foo;
  ///     }
  ///     extension B on A {
  ///       get bar => this.foo;
  ///     }
  ///
  /// will be converted into
  ///
  ///     class A {}
  ///     B|get#bar(A #this) => #this.foo;
  ///
  /// where `B|get#bar` is the synthesized name of the top-level method and
  /// `#this` is the synthesized parameter that holds represents `this`.
  ///
  ExtensionMemberKind kind;

  int flags = 0;

  /// Reference to the top-level member created for the extension method.
  final Reference memberReference;

  /// Reference to the top-level member created for the extension member tear
  /// off, if any.
  final Reference? tearOffReference;

  ExtensionMemberDescriptor(
      {required this.name,
      required this.kind,
      bool isStatic = false,
      required this.memberReference,
      required this.tearOffReference}) {
    this.isStatic = isStatic;
  }

  /// Return `true` if the extension method was declared as `static`.
  bool get isStatic => flags & FlagStatic != 0;

  void set isStatic(bool value) {
    flags = value ? (flags | FlagStatic) : (flags & ~FlagStatic);
  }

  @override
  String toString() {
    return 'ExtensionMemberDescriptor($name,$kind,'
        '${memberReference.toStringInternal()},isStatic=${isStatic})';
  }
}

/// Declaration of an extension type.
///
/// The members are converted into top-level procedures and only accessible
/// by reference in the [ExtensionTypeDeclaration] node.
class ExtensionTypeDeclaration extends NamedNode implements TypeDeclaration {
  /// Name of the extension type declaration.
  @override
  String name;

  /// The URI of the source file this class was loaded from.
  @override
  Uri fileUri;

  /// Type parameters declared on the extension.
  @override
  final List<TypeParameter> typeParameters;

  /// The type in the underlying representation of the extension type
  /// declaration.
  ///
  /// For instance A in the extension type declaration B:
  ///
  ///   class A {}
  ///   extension type B(A it) {}
  ///
  late DartType declaredRepresentationType;

  /// The name of the representation field.
  ///
  /// For instance 'it' in the extension type declaration B:
  ///
  ///   class A {}
  ///   extension type B(A it) {}
  ///
  /// This name is used for accessing underlying representation from an
  /// extension type. If the name starts with '_' is private wrt. the enclosing
  /// library of the extension type declaration.
  late String representationName;

  /// Abstract procedures that are part of the extension type declaration
  /// interface.
  ///
  /// This includes a getter for the representation field and member signatures
  /// computed as the combined member signature of inherited non-extension type
  /// members.
  List<Procedure> _procedures;

  /// The members declared by the extension type declaration.
  ///
  /// The members are converted into top-level members and only accessible
  /// by reference through [ExtensionTypeMemberDescriptor].
  List<ExtensionTypeMemberDescriptor> memberDescriptors;

  @override
  List<Expression> annotations = const <Expression>[];

  List<TypeDeclarationType> implements;

  int flags = 0;

  @override
  void addAnnotation(Expression node) {
    if (annotations.isEmpty) {
      annotations = <Expression>[];
    }
    annotations.add(node);
    node.parent = this;
  }

  ExtensionTypeDeclaration(
      {required this.name,
      List<TypeParameter>? typeParameters,
      DartType? declaredRepresentationType,
      List<ExtensionTypeMemberDescriptor>? memberDescriptors,
      List<TypeDeclarationType>? implements,
      List<Procedure>? procedures,
      required this.fileUri,
      Reference? reference})
      : this.typeParameters = typeParameters ?? <TypeParameter>[],
        this.memberDescriptors =
            memberDescriptors ?? <ExtensionTypeMemberDescriptor>[],
        this.implements = implements ?? <TypeDeclarationType>[],
        this._procedures = procedures ?? <Procedure>[],
        super(reference) {
    setParents(this.typeParameters, this);
    setParents(this._procedures, this);
    if (declaredRepresentationType != null) {
      this.declaredRepresentationType = declaredRepresentationType;
    }
  }

  @override
  CanonicalName bindCanonicalNames(CanonicalName parent) {
    return parent.getChild(name)..bindTo(reference);
  }

  /// Computes the canonical name for this extension type declarations and all
  /// its members.
  void ensureCanonicalNames(CanonicalName parent) {
    CanonicalName canonicalName = bindCanonicalNames(parent);
    for (int i = 0; i < procedures.length; ++i) {
      procedures[i].bindCanonicalNames(canonicalName);
    }
  }

  Library get enclosingLibrary => parent as Library;

  void addProcedure(Procedure procedure) {
    procedure.parent = this;
    procedures.add(procedure);
  }

  List<Procedure> get procedures => _procedures;

  /// Internal. Should *ONLY* be used from within kernel.
  ///
  /// Used for adding procedures when reading the dill file.
  void set proceduresInternal(List<Procedure> procedures) {
    _procedures = procedures;
  }

  /// This is an advanced feature. Use of this method should be coordinated
  /// with the kernel team.
  ///
  /// See [Component.relink] for a comprehensive description.
  ///
  /// Makes sure all references in named nodes in this extension type
  /// declaration points to said named node.
  void relink() {
    this.reference.node = this;
    for (int i = 0; i < procedures.length; ++i) {
      Procedure member = procedures[i];
      member._relinkNode();
    }
  }

  @override
  R accept<R>(TreeVisitor<R> v) => v.visitExtensionTypeDeclaration(this);

  @override
  R accept1<R, A>(TreeVisitor1<R, A> v, A arg) =>
      v.visitExtensionTypeDeclaration(this, arg);

  R acceptReference<R>(Visitor<R> v) =>
      v.visitExtensionTypeDeclarationReference(this);

  @override
  void visitChildren(Visitor v) {
    visitList(annotations, v);
    visitList(typeParameters, v);
    declaredRepresentationType.accept(v);
    visitList(procedures, v);
  }

  @override
  void transformChildren(Transformer v) {
    v.transformList(annotations, this);
    v.transformList(typeParameters, this);
    declaredRepresentationType = v.visitDartType(declaredRepresentationType);
    v.transformList(procedures, this);
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    v.transformExpressionList(annotations, this);
    v.transformTypeParameterList(typeParameters, this);
    declaredRepresentationType =
        v.visitDartType(declaredRepresentationType, cannotRemoveSentinel);
    v.transformProcedureList(procedures, this);
  }

  @override
  Location? _getLocationInEnclosingFile(int offset) {
    return _getLocationInComponent(enclosingComponent, fileUri, offset,
        viaForErrorMessage: "Extension type '$name'");
  }

  @override
  String toString() {
    return "ExtensionTypeDeclaration(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeExtensionTypeDeclarationName(reference);
  }

  /// Returns the inherent nullability of this extension type declaration.
  ///
  /// An extension type declaration is inherently non-nullable if it implements
  /// a non-extension type or a non-nullable extension type declaration.
  Nullability get inherentNullability {
    for (DartType supertype in implements) {
      if (supertype is! ExtensionType) {
        // A supertype that is not an extension type has to be non-nullable and
        // implement `Object` directly or indirectly.
        return Nullability.nonNullable;
      } else if (supertype.extensionTypeDeclaration.inherentNullability !=
          Nullability.undetermined) {
        // If an extension type is non-nullable, it implements `Object` directly
        // or indirectly.
        return Nullability.nonNullable;
      }
    }
    // Direct or indirect implementation of `Objects` isn't found.
    return Nullability.undetermined;
  }
}

enum ExtensionTypeMemberKind {
  Constructor,
  Factory,
  Field,
  Method,
  Getter,
  Setter,
  Operator,
  RedirectingFactory,
}

/// Information about an member declaration in an extension type declaration.
class ExtensionTypeMemberDescriptor {
  static const int FlagStatic = 1 << 0; // Must match serialized bit positions.

  /// The name of the extension type declaration member.
  ///
  /// The name of the generated top-level member is mangled to ensure
  /// uniqueness. This name is used to lookup a member in the extension type
  /// declaration itself.
  Name name;

  /// [ExtensionTypeMemberKind] kind of the original member.
  ///
  /// An extension type declaration member is converted into a regular top-level
  /// method. For instance:
  ///
  ///     class A {
  ///       var foo;
  ///     }
  ///     extension type B(A it) {
  ///       get bar => this.foo;
  ///     }
  ///
  /// will be converted into
  ///
  ///     class A {}
  ///     B|get#bar(A #this) => #this.foo;
  ///
  /// where `B|get#bar` is the synthesized name of the top-level method and
  /// `#this` is the synthesized parameter that holds represents `this`.
  ///
  ExtensionTypeMemberKind kind;

  int flags = 0;

  /// Reference to the top-level member created for the extension type
  /// declaration member.
  final Reference memberReference;

  /// Reference to the top-level member created for the extension type
  /// declaration member tear off, if any.
  final Reference? tearOffReference;

  ExtensionTypeMemberDescriptor(
      {required this.name,
      required this.kind,
      bool isStatic = false,
      required this.memberReference,
      required this.tearOffReference}) {
    this.isStatic = isStatic;
  }

  /// Return `true` if the extension type declaration member was declared as
  /// `static`.
  bool get isStatic => flags & FlagStatic != 0;

  void set isStatic(bool value) {
    flags = value ? (flags | FlagStatic) : (flags & ~FlagStatic);
  }

  @override
  String toString() {
    return 'ExtensionTypeMemberDescriptor($name,$kind,'
        '${memberReference.toStringInternal()},isStatic=${isStatic},'
        '${tearOffReference?.toStringInternal()})';
  }
}
