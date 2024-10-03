// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../../ast.dart';

// ------------------------------------------------------------------------
//                            MEMBERS
// ------------------------------------------------------------------------

sealed class Member extends NamedNode implements Annotatable, FileUriNode {
  /// End offset in the source file it comes from.
  ///
  /// Valid values are from 0 and up, or -1 ([TreeNode.noOffset]) if the file
  /// end offset is not available (this is the default if none is specifically
  /// set).
  int fileEndOffset = TreeNode.noOffset;

  @override
  List<int>? get fileOffsetsIfMultiple => [fileOffset, fileEndOffset];

  /// List of metadata annotations on the member.
  ///
  /// This defaults to an immutable empty list. Use [addAnnotation] to add
  /// annotations if needed.
  @override
  List<Expression> annotations = const <Expression>[];

  Name name;

  /// The URI of the source file this member was loaded from.
  @override
  Uri fileUri;

  /// Flags summarizing the kinds of AST nodes contained in this member, for
  /// speeding up transformations that only affect certain types of nodes.
  ///
  /// See [TransformerFlag] for the meaning of each bit.
  ///
  /// These should not be used for any purpose other than skipping certain
  /// members if it can be determined that no work is needed in there.
  ///
  /// It is valid for these flags to be false positives in rare cases, so
  /// transformers must tolerate the case where a flag is spuriously set.
  ///
  /// This value is not serialized; it is populated by the frontend and the
  /// deserializer.
  //
  // TODO(asgerf): It might be worthwhile to put this on classes as well.
  int transformerFlags = 0;

  Member(this.name, this.fileUri, Reference? reference) : super(reference);

  /// The enclosing [TypeDeclaration] if this member a class member or an
  /// abstract extension type member.
  TypeDeclaration? get enclosingTypeDeclaration =>
      parent is TypeDeclaration ? parent as TypeDeclaration : null;

  /// The enclosing [Class] if this member a class member.
  ///
  /// This includes both declared and inherited members, and both static and
  /// instance members.
  Class? get enclosingClass => parent is Class ? parent as Class : null;

  /// The enclosing [ExtensionTypeDeclaration] if this member an abstract
  /// extension type member.
  ///
  /// This includes abstract getters for representation fields and combined
  /// member signatures from inherited non-extension type members.
  ExtensionTypeDeclaration? get enclosingExtensionTypeDeclaration =>
      parent is ExtensionTypeDeclaration
          ? parent as ExtensionTypeDeclaration
          : null;

  Library get enclosingLibrary {
    TreeNode? parent = this.parent;
    if (parent is Class) {
      return parent.enclosingLibrary;
    } else if (parent is ExtensionTypeDeclaration) {
      return parent.enclosingLibrary;
    }
    return parent as Library;
  }

  @override
  R accept<R>(MemberVisitor<R> v);

  @override
  R accept1<R, A>(MemberVisitor1<R, A> v, A arg);

  R acceptReference<R>(MemberReferenceVisitor<R> v);

  /// Returns true if this is an abstract procedure.
  bool get isAbstract => false;

  /// Returns true if the member has the 'const' modifier.
  bool get isConst;

  /// True if this is a field or non-setter procedure.
  ///
  /// Note that operators and factories return `true`, even though there are
  /// normally no calls to their getter.
  bool get hasGetter;

  /// True if this is a setter or a mutable field.
  bool get hasSetter;

  /// True if this is a non-static field or procedure.
  bool get isInstanceMember;

  /// True if the member has the `external` modifier, implying that the
  /// implementation is provided by the backend, and is not necessarily written
  /// in Dart.
  ///
  /// Members can have this modifier independently of whether the enclosing
  /// library is external.
  bool get isExternal;

  /// If `true` this member is compiled from a member declared in an extension
  /// declaration.
  ///
  /// For instance `field`, `method1` and `method2` in:
  ///
  ///     extension A on B {
  ///       static var field;
  ///       B method1() => this;
  ///       static B method2() => new B();
  ///     }
  ///
  bool get isExtensionMember;

  /// If `true` this member is compiled from a member declared in an extension
  /// type declaration.
  ///
  /// For instance `field`, `method1` and `method2` in:
  ///
  ///     extension type A(B it) {
  ///       static var field;
  ///       B method1() => this;
  ///       static B method2() => new B();
  ///     }
  ///
  bool get isExtensionTypeMember;

  /// If `true` this procedure is not part of the interface but only part of the
  /// class members.
  ///
  /// This is `true` for instance for augmented procedures and synthesized
  /// fields added for the late lowering.
  bool get isInternalImplementation => false;

  /// The function signature and body of the procedure or constructor, or `null`
  /// if this is a field.
  FunctionNode? get function => null;

  /// Returns a possibly synthesized name for this member, consistent with
  /// the names used across all [toString] calls.
  @override
  String toString() => toStringInternal();

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeMemberName(reference);
  }

  @override
  void addAnnotation(Expression node) {
    if (annotations.isEmpty) {
      annotations = <Expression>[];
    }
    annotations.add(node);
    node.parent = this;
  }

  /// Returns the type of this member when accessed as a getter.
  ///
  /// For a field, this is the field type. For a getter, this is the return
  /// type. For a method or constructor, this is the tear off type.
  ///
  /// For a setter, this is undefined. Currently, non-nullable `Never` is
  /// returned.
  // TODO(johnniwinther): Should we use `InvalidType` for the undefined cases?
  DartType get getterType;

  /// Returns the type of this member when access as a getter on a super class.
  ///
  /// This is in most cases the same as for [getterType].
  ///
  /// An exception is for forwarding semi stubs:
  ///
  ///    class Super {
  ///      void method(num a) {}
  ///    }
  ///    class Class extends Super {
  ///      void method(covariant int a);
  ///    }
  ///    class Subclass extends Class {
  ///      void method(int a) {
  ///        super.method; // Type `void Function(num)`.
  ///        Class().method; // Type `void Function(int)`.
  ///      }
  ///    }
  ///
  /// Here, `Class.method` is turned into a forwarding semi stub
  ///
  ///     void method(covariant num a) => super.method(a);
  ///
  /// with [signatureType] `void Function(int)`. When `Class.method` is used
  /// as the target of a super get, it has getter type `void Function(num)` and
  /// as the target of an instance get, it has getter type `void Function(int)`.
  DartType get superGetterType => getterType;

  /// Returns the type of this member when accessed as a setter.
  ///
  /// For an assignable field, this is the field type. For a setter this is the
  /// parameter type.
  ///
  /// For other members, including unassignable fields, this is undefined.
  /// Currently, non-nullable `Never` is returned.
  // TODO(johnniwinther): Should we use `InvalidType` for the undefined cases?
  DartType get setterType;

  /// Returns the type of this member when access as a setter on a super class.
  ///
  /// This is in most cases the same as for [setterType].
  ///
  /// An exception is for forwarding semi stubs:
  ///
  ///    class Super {
  ///      void set setter(num a) {}
  ///    }
  ///    class Class extends Super {
  ///      void set setter(covariant int a);
  ///    }
  ///    class Subclass extends Class {
  ///      void set setter(int a) {
  ///        super.setter = 0.5; // Valid.
  ///        Class().setter = 0.5; // Invalid.
  ///      }
  ///    }
  ///
  /// Here, `Class.setter` is turned into a forwarding semi stub
  ///
  ///     void set setter(covariant num a) => super.setter = a;
  ///
  /// with [signatureType] `void Function(int)`. When `Class.setter` is used
  /// as the target of a super set, it has setter type `num` and as the target
  /// of an instance set, it has setter type `int`.
  DartType get superSetterType => setterType;

  bool get containsSuperCalls {
    return transformerFlags & TransformerFlag.superCalls != 0;
  }

  /// If this member is a member signature, [memberSignatureOrigin] is one of
  /// the non-member signature members from which it was created.
  Member? get memberSignatureOrigin => null;
}

/// A field declaration.
///
/// The implied getter and setter for the field are not represented explicitly,
/// but can be made explicit if needed.
class Field extends Member {
  DartType type; // Not null. Defaults to DynamicType.
  int flags = 0;
  Expression? initializer; // May be null.

  /// Reference used for reading from this field.
  ///
  /// This should be used as the target in [StaticGet], [InstanceGet], and
  /// [SuperPropertyGet].
  final Reference getterReference;

  /// Reference used for writing to this field.
  ///
  /// This should be used as the target in [StaticSet], [InstanceSet], and
  /// [SuperPropertySet].
  final Reference? setterReference;

  @override
  @Deprecated("Use the specific getterReference/setterReference instead")
  Reference get reference => super.reference;

  /// Reference used for initializing this field.
  ///
  /// This should be used as the target in [FieldInitializer] and as the key
  /// in the field values of [InstanceConstant].
  Reference get fieldReference => super.reference;

  Field.mutable(Name name,
      {this.type = const DynamicType(),
      this.initializer,
      bool isCovariantByDeclaration = false,
      bool isFinal = false,
      bool isStatic = false,
      bool isLate = false,
      int transformerFlags = 0,
      required Uri fileUri,
      Reference? fieldReference,
      Reference? getterReference,
      Reference? setterReference})
      : this.getterReference = getterReference ?? new Reference(),
        this.setterReference = setterReference ?? new Reference(),
        super(name, fileUri, fieldReference) {
    this.getterReference.node = this;
    this.setterReference!.node = this;
    initializer?.parent = this;
    this.isCovariantByDeclaration = isCovariantByDeclaration;
    this.isFinal = isFinal;
    this.isStatic = isStatic;
    this.isLate = isLate;
    this.transformerFlags = transformerFlags;
  }

  Field.immutable(Name name,
      {this.type = const DynamicType(),
      this.initializer,
      bool isCovariantByDeclaration = false,
      bool isFinal = false,
      bool isConst = false,
      bool isStatic = false,
      bool isLate = false,
      int transformerFlags = 0,
      required Uri fileUri,
      Reference? fieldReference,
      Reference? getterReference,
      bool isEnumElement = false})
      : this.getterReference = getterReference ?? new Reference(),
        this.setterReference = null,
        super(name, fileUri, fieldReference) {
    this.getterReference.node = this;
    initializer?.parent = this;
    this.isCovariantByDeclaration = isCovariantByDeclaration;
    this.isFinal = isFinal;
    this.isConst = isConst;
    this.isStatic = isStatic;
    this.isLate = isLate;
    this.isEnumElement = isEnumElement;
    this.transformerFlags = transformerFlags;
  }

  @override
  void bindCanonicalNames(CanonicalName parent) {
    parent.getChildFromField(this).bindTo(fieldReference);
    parent.getChildFromFieldGetter(this).bindTo(getterReference);
    if (hasSetter) {
      parent.getChildFromFieldSetter(this).bindTo(setterReference!);
    }
  }

  @override
  void _relinkNode() {
    this.fieldReference.node = this;
    this.getterReference.node = this;
    if (hasSetter) {
      this.setterReference!.node = this;
    }
  }

  static const int FlagFinal = 1 << 0; // Must match serialized bit positions.
  static const int FlagConst = 1 << 1;
  static const int FlagStatic = 1 << 2;
  static const int FlagCovariant = 1 << 3;
  static const int FlagCovariantByClass = 1 << 4;
  static const int FlagLate = 1 << 5;
  static const int FlagExtensionMember = 1 << 6;
  static const int FlagInternalImplementation = 1 << 7;
  static const int FlagEnumElement = 1 << 8;
  static const int FlagExtensionTypeMember = 1 << 9;

  /// Whether the field is declared with the `covariant` keyword.
  bool get isCovariantByDeclaration => flags & FlagCovariant != 0;

  bool get isFinal => flags & FlagFinal != 0;

  @override
  bool get isConst => flags & FlagConst != 0;

  bool get isStatic => flags & FlagStatic != 0;

  @override
  bool get isExtensionMember => flags & FlagExtensionMember != 0;

  @override
  bool get isExtensionTypeMember => flags & FlagExtensionTypeMember != 0;

  /// Indicates whether the implicit setter associated with this field needs to
  /// contain a runtime type check to deal with generic covariance.
  ///
  /// When `true`, runtime checks may need to be performed.
  bool get isCovariantByClass => flags & FlagCovariantByClass != 0;

  /// Whether the field is declared with the `late` keyword.
  bool get isLate => flags & FlagLate != 0;

  /// If `true` this field is not part of the interface but only part of the
  /// class members.
  ///
  /// This is `true` for instance for synthesized fields added for the late
  /// lowering.
  @override
  bool get isInternalImplementation => flags & FlagInternalImplementation != 0;

  /// If `true` this field is an enum element.
  ///
  /// For instance
  ///
  ///    enum A {
  ///      a, b;
  ///      static const A c = A.a;
  ///    }
  ///
  /// the fields `a` and `b` are enum elements whereas `c` is a regular field.
  bool get isEnumElement => flags & FlagEnumElement != 0;

  void set isCovariantByDeclaration(bool value) {
    flags = value ? (flags | FlagCovariant) : (flags & ~FlagCovariant);
  }

  void set isFinal(bool value) {
    flags = value ? (flags | FlagFinal) : (flags & ~FlagFinal);
  }

  void set isConst(bool value) {
    flags = value ? (flags | FlagConst) : (flags & ~FlagConst);
  }

  void set isStatic(bool value) {
    flags = value ? (flags | FlagStatic) : (flags & ~FlagStatic);
  }

  void set isExtensionMember(bool value) {
    flags =
        value ? (flags | FlagExtensionMember) : (flags & ~FlagExtensionMember);
  }

  void set isCovariantByClass(bool value) {
    flags = value
        ? (flags | FlagCovariantByClass)
        : (flags & ~FlagCovariantByClass);
  }

  void set isLate(bool value) {
    flags = value ? (flags | FlagLate) : (flags & ~FlagLate);
  }

  void set isInternalImplementation(bool value) {
    flags = value
        ? (flags | FlagInternalImplementation)
        : (flags & ~FlagInternalImplementation);
  }

  void set isEnumElement(bool value) {
    flags = value ? (flags | FlagEnumElement) : (flags & ~FlagEnumElement);
  }

  void set isExtensionTypeMember(bool value) {
    flags = value
        ? (flags | FlagExtensionTypeMember)
        : (flags & ~FlagExtensionTypeMember);
  }

  @override
  bool get isInstanceMember => !isStatic;

  @override
  bool get hasGetter => true;

  @override
  bool get hasSetter => setterReference != null;

  @override
  bool get isExternal => false;

  @override
  R accept<R>(MemberVisitor<R> v) => v.visitField(this);

  @override
  R accept1<R, A>(MemberVisitor1<R, A> v, A arg) => v.visitField(this, arg);

  @override
  R acceptReference<R>(MemberReferenceVisitor<R> v) =>
      v.visitFieldReference(this);

  @override
  void visitChildren(Visitor v) {
    visitList(annotations, v);
    type.accept(v);
    name.accept(v);
    initializer?.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    type = v.visitDartType(type);
    v.transformList(annotations, this);
    if (initializer != null) {
      initializer = v.transform(initializer!);
      initializer?.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    type = v.visitDartType(type, null);
    v.transformExpressionList(annotations, this);
    if (initializer != null) {
      initializer = v.transformOrRemoveExpression(initializer!);
      initializer?.parent = this;
    }
  }

  @override
  DartType get getterType => type;

  @override
  DartType get setterType => hasSetter ? type : const NeverType.nonNullable();

  @override
  Location? _getLocationInEnclosingFile(int offset) {
    return _getLocationInComponent(enclosingComponent, fileUri, offset,
        viaForErrorMessage: "Field '$name'");
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeMemberName(fieldReference);
  }
}

/// A generative constructor, possibly redirecting.
///
/// Note that factory constructors are treated as [Procedure]s.
///
/// Constructors do not take type parameters.  Type arguments from a constructor
/// invocation should be matched with the type parameters declared in the class.
///
/// For unnamed constructors, the name is an empty string (in a [Name]).
class Constructor extends Member {
  /// Start offset of the constructor in the source file it comes from.
  ///
  /// Note that this includes annotations if any.
  ///
  /// Valid values are from 0 and up, or -1 ([TreeNode.noOffset]) if the file
  /// start offset is not available (this is the default if none is specifically
  /// set).
  int startFileOffset = TreeNode.noOffset;

  @override
  List<int>? get fileOffsetsIfMultiple =>
      [fileOffset, startFileOffset, fileEndOffset];

  int flags = 0;

  @override
  FunctionNode function;

  List<Initializer> initializers;

  Constructor(this.function,
      {required Name name,
      bool isConst = false,
      bool isExternal = false,
      bool isSynthetic = false,
      List<Initializer>? initializers,
      int transformerFlags = 0,
      required Uri fileUri,
      Reference? reference})
      : this.initializers = initializers ?? <Initializer>[],
        super(name, fileUri, reference) {
    function.parent = this;
    setParents(this.initializers, this);
    this.isConst = isConst;
    this.isExternal = isExternal;
    this.isSynthetic = isSynthetic;
    this.transformerFlags = transformerFlags;
  }

  @override
  void bindCanonicalNames(CanonicalName parent) {
    parent.getChildFromConstructor(this).bindTo(reference);
  }

  @override
  Class get enclosingClass => parent as Class;

  static const int FlagConst = 1 << 0; // Must match serialized bit positions.
  static const int FlagExternal = 1 << 1;
  static const int FlagSynthetic = 1 << 2;

  @override
  bool get isConst => flags & FlagConst != 0;

  @override
  bool get isExternal => flags & FlagExternal != 0;

  /// True if this is a synthetic constructor inserted in a class that
  /// does not otherwise declare any constructors.
  bool get isSynthetic => flags & FlagSynthetic != 0;

  void set isConst(bool value) {
    flags = value ? (flags | FlagConst) : (flags & ~FlagConst);
  }

  void set isExternal(bool value) {
    flags = value ? (flags | FlagExternal) : (flags & ~FlagExternal);
  }

  void set isSynthetic(bool value) {
    flags = value ? (flags | FlagSynthetic) : (flags & ~FlagSynthetic);
  }

  @override
  bool get isInstanceMember => false;

  @override
  bool get hasGetter => false;

  @override
  bool get hasSetter => false;

  @override
  bool get isExtensionMember => false;

  @override
  bool get isExtensionTypeMember => false;

  @override
  R accept<R>(MemberVisitor<R> v) => v.visitConstructor(this);

  @override
  R accept1<R, A>(MemberVisitor1<R, A> v, A arg) =>
      v.visitConstructor(this, arg);

  @override
  R acceptReference<R>(MemberReferenceVisitor<R> v) =>
      v.visitConstructorReference(this);

  @override
  void visitChildren(Visitor v) {
    visitList(annotations, v);
    name.accept(v);
    visitList(initializers, v);
    function.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    v.transformList(annotations, this);
    v.transformList(initializers, this);
    function = v.transform(function);
    function.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    v.transformExpressionList(annotations, this);
    v.transformInitializerList(initializers, this);
    function = v.transform(function);
    function.parent = this;
  }

  // TODO(johnniwinther): Provide the tear off type here.
  @override
  DartType get getterType => const NeverType.nonNullable();

  @override
  DartType get setterType => const NeverType.nonNullable();

  @override
  Location? _getLocationInEnclosingFile(int offset) {
    return _getLocationInComponent(enclosingComponent, fileUri, offset,
        viaForErrorMessage: "Constructor '$name'");
  }
}

/// Enum for the semantics of the `Procedure.stubTarget` property.
enum ProcedureStubKind {
  /// A regular procedure declared in source code.
  ///
  /// The stub target is `null`.
  Regular,

  /// An abstract procedure inserted to add `isCovariantByDeclaration` and
  /// `isCovariantByClass` to parameters for a set of overridden members.
  ///
  /// The stub is inserted when not all of the overridden members agree on
  /// the covariance flags. For instance:
  ///
  ///     class A<T> {
  ///        void method1(num o) {}
  ///        void method2(T o) {}
  ///     }
  ///     class B {
  ///        void method1(covariant int o) {}
  ///        void method2(int o) {}
  ///     }
  ///     class C implements A<int>, B {
  ///        // Abstract forwarding stub needed because the parameter is
  ///        // covariant in `B.method1` but not in `A.method1`.
  ///        void method1(covariant num o);
  ///        // Abstract forwarding stub needed because the parameter is a
  ///        // generic covariant impl in `A.method2` but not in `B.method2`.
  ///        void method2(/*generic-covariant-impl*/ int o);
  ///     }
  ///
  /// The stub target is one of the overridden members.
  AbstractForwardingStub,

  /// A concrete procedure inserted to add `isCovariantByDeclaration` and
  /// `isCovariantByClass` checks to parameters before calling the
  /// overridden member in the superclass.
  ///
  /// The stub is inserted when not all of the overridden members agree on
  /// the covariance flags and the overridden super class member does not
  /// have the same covariance flags. For instance:
  ///
  ///     class A<T> {
  ///        void method1(num o) {}
  ///        void method2(T o) {}
  ///     }
  ///     class B {
  ///        void method1(covariant int o) {}
  ///        void method2(int o) {}
  ///     }
  ///     class C extends A<int> implements B {
  ///        // Concrete forwarding stub needed because the parameter is
  ///        // covariant in `B.method1` but not in `A.method1`.
  ///        void method1(covariant num o) => super.method1(o);
  ///        // No need for a concrete forwarding stub for `A.method2` because
  ///        // it has the right covariance flags already.
  ///     }
  ///
  /// The stub target is the called superclass member.
  ConcreteForwardingStub,

  /// A concrete procedure inserted to forward calls to `noSuchMethod` for
  /// an inherited member that it does not implement.
  ///
  /// The stub is inserted when a class implements private members of another
  /// library or declares/inherits a user-defined `noSuchMethod` method. For
  /// instance:
  ///
  ///     // lib1:
  ///     class A {
  ///       void _privateMethod() {}
  ///     }
  ///     // lib2:
  ///     class B implements A {
  ///       // Forwarding stub inserted to forward calls to `A._privateMethod`.
  ///       void _privateMethod() => noSuchMethod(#_privateMethod, ...);
  ///     }
  ///     class C {
  ///       void method() {}
  ///     }
  ///     class D implements C {
  ///       noSuchMethod(o) { ... }
  ///       // Forwarding stub inserted to forward calls to `C.method`.
  ///       void method() => noSuchMethod(#method, ...);
  ///     }
  ///
  ///
  /// The stub target is `null` if the procedure preexisted as an abstract
  /// procedure. Otherwise the stub target is one of the inherited members.
  NoSuchMethodForwarder,

  /// An abstract procedure inserted to show the combined member signature type
  /// of set of overridden members.
  ///
  /// The stub is inserted when an opt-in member is inherited into an opt-out
  /// library or when NNBD_TOP_MERGE was used to compute the type of a merge
  /// point in an opt-in library. For instance:
  ///
  ///     // lib1: opt-in
  ///     class A {
  ///       int? method1() => null;
  ///       void method2(Object? o) {}
  ///     }
  ///     class B {
  ///       dynamic method2(dynamic o);
  ///     }
  ///     class C implements A, B {
  ///       // Member signature inserted for the NNBD_TOP_MERGE type of
  ///       // `A.method2` and `B.method2`.
  ///       Object? method2(Object? o);
  ///     }
  ///     // lib2: opt-out
  ///     class D extends A {
  ///       // Member signature inserted for the LEGACY_ERASURE type of
  ///       // `A.method1` and `A.method2` with types `int* Function()`
  ///       // and `void Function(Object*)`, respectively.
  ///       int method1();
  ///       void method2(Object o);
  ///     }
  ///
  /// The stub target is one of the overridden members.
  MemberSignature,

  /// An abstract procedure inserted for the application of an abstract mixin
  /// member.
  ///
  /// The stub is inserted when an abstract member is mixed into a mixin
  /// application. For instance:
  ///
  ///     class Super {}
  ///     abstract class Mixin {
  ///        void method();
  ///     }
  ///     class Class = Super with Mixin
  ///       // An abstract mixin stub for `A.method` is added to `Class`
  ///       void method();
  ///     ;
  ///
  /// This is added to ensure that interface targets are resolved consistently
  /// in face of cloning. For instance, without the abstract mixin stub, this
  /// call:
  ///
  ///     method(Class c) => c.method();
  ///
  /// would use `Mixin.method` as its target, but after loading from a VM .dill
  /// (which clones all mixin members) the call would resolve to `Class.method`
  /// instead. By adding the mixin stub to `Class`, all accesses both before
  /// and after .dill will point to `Class.method`.
  ///
  /// The stub target is the mixin member.
  AbstractMixinStub,

  /// A concrete procedure inserted for the application of a concrete mixin
  /// member. The implementation calls the mixin member via a super-call.
  ///
  /// The stub is inserted when a concrete member is mixed into a mixin
  /// application. For instance:
  ///
  ///     class Super {}
  ///     abstract class Mixin {
  ///        void method() {}
  ///     }
  ///     class Class = Super with Mixin
  ///       // A concrete mixin stub for `A.method` is added to `Class` which
  ///       // calls `A.method`.
  ///       void method() => super.method();
  ///     ;
  ///
  /// This is added to ensure that super accesses are resolved correctly, even
  /// in face of cloning. For instance, without the concrete mixin stub, this
  /// super call:
  ///
  ///     class Subclass extends Class {
  ///       method(Class c) => super.method();
  ///     }
  ///
  /// would use `Mixin.method` as its target, which would need to be updated to
  /// match the clone of the mixin member performed for instance by the VM. By
  /// adding the concrete mixin stub to `Class`, all accesses both before and
  /// after cloning will point to `Class.method`.
  ///
  /// The stub target is the called mixin member.
  ConcreteMixinStub,

  /// The representation field of an extension type declaration, encoded as
  /// an abstract getter.
  ///
  /// The stub target is `null`.
  RepresentationField,
}

/// A method, getter, setter, index-getter, index-setter, operator overloader,
/// or factory.
///
/// Procedures can have the static, abstract, and/or external modifier, although
/// only the static and external modifiers may be used together.
///
/// For non-static procedures the name is required for dynamic dispatch.
/// For external procedures the name is required for identifying the external
/// implementation.
///
/// For methods, getters, and setters the name is just as it was declared.
/// For setters this does not include a trailing `=`.
/// For index-getters/setters, this is `[]` and `[]=`.
/// For operators, this is the token for the operator, e.g. `+` or `==`,
/// except for the unary minus operator, whose name is `unary-`.
class Procedure extends Member implements GenericFunction {
  /// Start offset of the function in the source file it comes from.
  ///
  /// Note that this includes annotations if any.
  ///
  /// Valid values are from 0 and up, or -1 ([TreeNode.noOffset]) if the file
  /// start offset is not available (this is the default if none is specifically
  /// set).
  int fileStartOffset = TreeNode.noOffset;

  @override
  List<int>? get fileOffsetsIfMultiple =>
      [fileOffset, fileStartOffset, fileEndOffset];

  final ProcedureKind kind;
  int flags = 0;

  @override
  FunctionNode function;

  ProcedureStubKind stubKind;
  Reference? stubTargetReference;

  /// The interface member signature type of this procedure.
  ///
  /// Normally this is derived from the parameter types and return type of
  /// [function]. In rare cases, the interface member signature type is
  /// different from the class member type, in which case the interface member
  /// signature type is stored here.
  ///
  /// For instance
  ///
  ///   class Super {
  ///     void method(num a) {}
  ///   }
  ///   class Class extends Super {
  ///     void method(covariant int a);
  ///   }
  ///
  /// Here the member `Class.method` is turned into a forwarding semi stub to
  /// ensure that arguments passed to `Super.method` are checked as covariant.
  /// Since `Super.method` allows `num` as argument, the inserted covariant
  /// check must be against `num` and not `int`, and the parameter type of the
  /// forwarding semi stub must be changed to `num`. Still, the interface of
  /// `Class` requires that `Class.method` is `void Function(int)`, so for
  /// this, it is stored explicitly as the [signatureType] on the procedure.
  ///
  /// When [signatureType] is null, you can compute the function type with
  /// `function.computeFunctionType(Nullability.nonNullable)`. Alternatively,
  /// you can use [computeSignatureOrFunctionType] that computes the interface
  /// member signature type accounting for the possibility of [signatureType]
  /// being null.
  FunctionType? signatureType;

  Procedure(Name name, ProcedureKind kind, FunctionNode function,
      {bool isAbstract = false,
      bool isStatic = false,
      bool isExternal = false,
      bool isConst = false,
      bool isExtensionMember = false,
      bool isExtensionTypeMember = false,
      bool isSynthetic = false,
      int transformerFlags = 0,
      required Uri fileUri,
      Reference? reference,
      ProcedureStubKind stubKind = ProcedureStubKind.Regular,
      Member? stubTarget})
      : this._byReferenceRenamed(name, kind, function,
            isAbstract: isAbstract,
            isStatic: isStatic,
            isExternal: isExternal,
            isConst: isConst,
            isExtensionMember: isExtensionMember,
            isExtensionTypeMember: isExtensionTypeMember,
            isSynthetic: isSynthetic,
            transformerFlags: transformerFlags,
            fileUri: fileUri,
            reference: reference,
            stubKind: stubKind,
            stubTargetReference:
                getMemberReferenceBasedOnProcedureKind(stubTarget, kind));

  Procedure._byReferenceRenamed(Name name, this.kind, this.function,
      {bool isAbstract = false,
      bool isStatic = false,
      bool isExternal = false,
      bool isConst = false,
      bool isExtensionMember = false,
      bool isExtensionTypeMember = false,
      bool isSynthetic = false,
      int transformerFlags = 0,
      required Uri fileUri,
      Reference? reference,
      this.stubKind = ProcedureStubKind.Regular,
      this.stubTargetReference})
      : super(name, fileUri, reference) {
    function.parent = this;
    this.isAbstract = isAbstract;
    this.isStatic = isStatic;
    this.isExternal = isExternal;
    this.isConst = isConst;
    this.isExtensionMember = isExtensionMember;
    this.isExtensionTypeMember = isExtensionTypeMember;
    this.isSynthetic = isSynthetic;
    setTransformerFlagsWithoutLazyLoading(transformerFlags);
    assert(!(isMemberSignature && stubTargetReference == null),
        "No member signature origin for member signature $this.");
    assert(
        !(memberSignatureOrigin is Procedure &&
            (memberSignatureOrigin as Procedure).isMemberSignature),
        "Member signature origin cannot be a member signature "
        "$memberSignatureOrigin for $this.");
  }

  @override
  List<TypeParameter> get typeParameters => function.typeParameters;

  // The function node's body might be lazily loaded, meaning that this value
  // might not be set correctly yet. Make sure the body is loaded before
  // returning anything.
  @override
  int get transformerFlags {
    function.body;
    return super.transformerFlags;
  }

  // The function node's body might be lazily loaded, meaning that this value
  // might get overwritten later (when the body is read). To avoid that read the
  // body now and only set the value afterwards.
  @override
  void set transformerFlags(int newValue) {
    function.body;
    super.transformerFlags = newValue;
  }

  // This function will set the transformer flags without loading the body.
  // Used when reading the binary. For other cases one should probably use
  // `transformerFlags = value;`.
  void setTransformerFlagsWithoutLazyLoading(int newValue) {
    super.transformerFlags = newValue;
  }

  @override
  void bindCanonicalNames(CanonicalName parent) {
    parent.getChildFromProcedure(this).bindTo(reference);
  }

  static const int FlagStatic = 1 << 0; // Must match serialized bit positions.
  static const int FlagAbstract = 1 << 1;
  static const int FlagExternal = 1 << 2;
  static const int FlagConst = 1 << 3; // Only for external const factories.
  static const int FlagExtensionMember = 1 << 4;
  static const int FlagSynthetic = 1 << 5;
  static const int FlagInternalImplementation = 1 << 6;
  static const int FlagExtensionTypeMember = 1 << 7;
  static const int FlagHasWeakTearoffReferencePragma = 1 << 8;

  bool get isStatic => flags & FlagStatic != 0;

  @override
  bool get isAbstract => flags & FlagAbstract != 0;

  @override
  bool get isExternal => flags & FlagExternal != 0;

  /// True if this has the `const` modifier.  This is only possible for external
  /// constant factories, such as `String.fromEnvironment`.
  @override
  bool get isConst => flags & FlagConst != 0;

  /// If set, this flag indicates that this function's implementation exists
  /// solely for the purpose of type checking arguments and forwarding to
  /// [concreteForwardingStubTarget].
  ///
  /// Note that just because this bit is set doesn't mean that the function was
  /// not declared in the source; it's possible that this is a forwarding
  /// semi-stub (see isForwardingSemiStub).  To determine whether this function
  /// was present in the source, consult [isSyntheticForwarder].
  bool get isForwardingStub =>
      stubKind == ProcedureStubKind.AbstractForwardingStub ||
      stubKind == ProcedureStubKind.ConcreteForwardingStub;

  /// If set, this flag indicates that although this function is a forwarding
  /// stub, it was present in the original source as an abstract method.
  bool get isForwardingSemiStub => !isSynthetic && isForwardingStub;

  /// If set, this method is a class member added to show the type of an
  /// inherited member.
  ///
  /// This is used when the type of the inherited member cannot be computed
  /// directly from the member(s) in the supertypes. For instance in case of
  /// an nnbd opt-out class inheriting from an nnbd opt-in class; here all nnbd-
  /// aware types are replaced with legacy types in the inherited signature.
  bool get isMemberSignature => stubKind == ProcedureStubKind.MemberSignature;

  // Indicates if this [Procedure] represents a redirecting factory constructor
  // and doesn't have a runnable body.
  bool get isRedirectingFactory {
    return function.redirectingFactoryTarget != null;
  }

  /// If set, this flag indicates that this function was not present in the
  /// source, and it exists solely for the purpose of type checking arguments
  /// and forwarding to [concreteForwardingStubTarget].
  bool get isSyntheticForwarder => isForwardingStub && !isForwardingSemiStub;
  bool get isSynthetic => flags & FlagSynthetic != 0;

  bool get isNoSuchMethodForwarder =>
      stubKind == ProcedureStubKind.NoSuchMethodForwarder;

  /// If `true` this procedure is not part of the interface but only part of the
  /// class members.
  ///
  /// This is `true` for instance for augmented procedures.
  @override
  bool get isInternalImplementation => flags & FlagInternalImplementation != 0;

  void set isInternalImplementation(bool value) {
    flags = value
        ? (flags | FlagInternalImplementation)
        : (flags & ~FlagInternalImplementation);
  }

  @override
  bool get isExtensionMember => flags & FlagExtensionMember != 0;

  @override
  bool get isExtensionTypeMember => flags & FlagExtensionTypeMember != 0;

  void set isStatic(bool value) {
    flags = value ? (flags | FlagStatic) : (flags & ~FlagStatic);
  }

  void set isAbstract(bool value) {
    flags = value ? (flags | FlagAbstract) : (flags & ~FlagAbstract);
  }

  void set isExternal(bool value) {
    flags = value ? (flags | FlagExternal) : (flags & ~FlagExternal);
  }

  void set isConst(bool value) {
    flags = value ? (flags | FlagConst) : (flags & ~FlagConst);
  }

  void set isExtensionMember(bool value) {
    flags =
        value ? (flags | FlagExtensionMember) : (flags & ~FlagExtensionMember);
  }

  void set isExtensionTypeMember(bool value) {
    flags = value
        ? (flags | FlagExtensionTypeMember)
        : (flags & ~FlagExtensionTypeMember);
  }

  void set isSynthetic(bool value) {
    flags = value ? (flags | FlagSynthetic) : (flags & ~FlagSynthetic);
  }

  @override
  bool get isInstanceMember => !isStatic;

  bool get isGetter => kind == ProcedureKind.Getter;
  bool get isSetter => kind == ProcedureKind.Setter;
  bool get isAccessor => isGetter || isSetter;

  @override
  bool get hasGetter => kind != ProcedureKind.Setter;

  @override
  bool get hasSetter => kind == ProcedureKind.Setter;

  bool get isFactory => kind == ProcedureKind.Factory;

  Member? get concreteForwardingStubTarget =>
      stubKind == ProcedureStubKind.ConcreteForwardingStub
          ? stubTargetReference?.asMember
          : null;

  Member? get abstractForwardingStubTarget =>
      stubKind == ProcedureStubKind.AbstractForwardingStub
          ? stubTargetReference?.asMember
          : null;

  Member? get stubTarget => stubTargetReference?.asMember;

  void set stubTarget(Member? target) {
    stubTargetReference = getMemberReferenceBasedOnProcedureKind(target, kind);
  }

  @override
  Member? get memberSignatureOrigin =>
      stubKind == ProcedureStubKind.MemberSignature
          ? stubTargetReference?.asMember
          : null;

  bool get hasWeakTearoffReferencePragma =>
      flags & FlagHasWeakTearoffReferencePragma != 0;

  void set hasWeakTearoffReferencePragma(bool value) {
    flags = value
        ? (flags | FlagHasWeakTearoffReferencePragma)
        : (flags & ~FlagHasWeakTearoffReferencePragma);
  }

  /// Computes the interface member signature type of the procedure.
  ///
  /// In case [signatureType] is set, returns [signatureType]. Otherwise,
  /// computes the function type of the function node.
  FunctionType computeSignatureOrFunctionType() {
    return signatureType ??
        function.computeFunctionType(Nullability.nonNullable);
  }

  @override
  R accept<R>(MemberVisitor<R> v) => v.visitProcedure(this);

  @override
  R accept1<R, A>(MemberVisitor1<R, A> v, A arg) => v.visitProcedure(this, arg);

  @override
  R acceptReference<R>(MemberReferenceVisitor<R> v) =>
      v.visitProcedureReference(this);

  @override
  void visitChildren(Visitor v) {
    visitList(annotations, v);
    name.accept(v);
    function.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    v.transformList(annotations, this);
    function = v.transform(function);
    function.parent = this;
    if (signatureType != null) {
      signatureType = v.visitDartType(signatureType!) as FunctionType;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    v.transformExpressionList(annotations, this);
    function = v.transform(function);
    function.parent = this;
    if (signatureType != null) {
      DartType newSignatureType =
          v.visitDartType(signatureType!, dummyDartType);
      if (identical(newSignatureType, dummyDartType)) {
        signatureType = null;
      } else {
        signatureType = newSignatureType as FunctionType;
      }
    }
  }

  @override
  DartType get getterType {
    return isGetter
        ? (signatureType?.returnType ?? function.returnType)
        : (signatureType ??
            function.computeFunctionType(enclosingLibrary.nonNullable));
  }

  @override
  DartType get superGetterType {
    return isGetter
        ? function.returnType
        : function.computeFunctionType(enclosingLibrary.nonNullable);
  }

  @override
  DartType get setterType {
    return isSetter
        ? (signatureType?.positionalParameters[0] ??
            function.positionalParameters[0].type)
        : const NeverType.nonNullable();
  }

  @override
  DartType get superSetterType {
    return isSetter
        ? function.positionalParameters[0].type
        : const NeverType.nonNullable();
  }

  @override
  Location? _getLocationInEnclosingFile(int offset) {
    return _getLocationInComponent(enclosingComponent, fileUri, offset,
        viaForErrorMessage: "Procedure '$name'");
  }
}

enum ProcedureKind {
  Method,
  Getter,
  Setter,
  Operator,
  Factory,
}

/// The target constructor and passed type arguments of a redirecting factory,
/// or if erroneous, the message for the error.
class RedirectingFactoryTarget {
  /// The reference to the target constructor if this is a valid redirecting
  /// factory. `null` otherwise.
  final Reference? targetReference;

  /// The type arguments passed to the target constructor if this is a valid
  /// redirecting factory. `null` otherwise.
  final List<DartType>? typeArguments;

  /// The message for the error, if this is an erroneous redirection. `null`
  /// otherwise.
  final String? errorMessage;

  RedirectingFactoryTarget(Member target, List<DartType> typeArguments)
      : this.byReference(target.reference, typeArguments);

  RedirectingFactoryTarget.byReference(
      Reference this.targetReference, List<DartType> this.typeArguments)
      : errorMessage = null;

  RedirectingFactoryTarget.error(String this.errorMessage)
      : targetReference = null,
        typeArguments = null;

  /// The target constructor if this is a valid redirecting factory. `null`
  /// otherwise.
  Member? get target => targetReference?.asMember;

  /// If `true`, this is an erroneous redirection.
  bool get isError => errorMessage != null;

  @override
  String toString() => 'RedirectingFactoryTarget('
      '${isError ? '$errorMessage' : '$target,$typeArguments'})';
}
