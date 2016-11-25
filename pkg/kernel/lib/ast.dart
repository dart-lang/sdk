// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// -----------------------------------------------------------------------
///                           ERROR HANDLING
/// -----------------------------------------------------------------------
///
/// As a rule of thumb, errors that can be detected statically are handled by
/// the frontend, typically by translating the erroneous code into a 'throw' or
/// a call to 'noSuchMethod'.
///
/// For example, there are no arity mismatches in static invocations, and
/// there are no direct invocations of a constructor on a abstract class.
///
/// -----------------------------------------------------------------------
///                           STATIC vs TOP-LEVEL
/// -----------------------------------------------------------------------
///
/// The term `static` includes both static class members and top-level members.
///
/// "Static class member" is the preferred term for non-top level statics.
///
/// Static class members are not lifted to the library level because mirrors
/// and stack traces can observe that they are class members.
///
/// -----------------------------------------------------------------------
///                                 PROCEDURES
/// -----------------------------------------------------------------------
///
/// "Procedure" is an umbrella term for method, getter, setter, index-getter,
/// index-setter, operator overloader, and factory constructor.
///
/// Generative constructors, field initializers, local functions are NOT
/// procedures.
///
/// -----------------------------------------------------------------------
///                               TRANSFORMATIONS
/// -----------------------------------------------------------------------
///
/// AST transformations can be performed using [TreeNode.replaceWith] or the
/// [Transformer] visitor class.
///
/// Use [Transformer] for bulk transformations that are likely to transform lots
/// of nodes, and [TreeNode.replaceWith] for sparse transformations that mutate
/// relatively few nodes.  Or use whichever is more convenient.
///
/// The AST can also be mutated by direct field manipulation, but the user then
/// has to update parent pointers manually.
///
library kernel.ast;

import 'visitor.dart';
export 'visitor.dart';

import 'type_propagation/type_propagation.dart';
export 'type_propagation/type_propagation.dart';

import 'transformations/flags.dart';
import 'text/ast_to_text.dart';
import 'type_algebra.dart';
import 'type_environment.dart';

/// Any type of node in the IR.
abstract class Node {
  const Node();

  accept(Visitor v);
  visitChildren(Visitor v);

  /// Returns the textual representation of this node for use in debugging.
  ///
  /// [toString] should only be used for debugging and short-running test tools
  /// as it can cause serious memory leaks.
  ///
  /// Synthetic names are cached globally to retain consistency across different
  /// [toString] calls (hence the memory leak).
  ///
  /// Nodes that are named, such as [Class] and [Member], return their
  /// (possibly synthesized) name, whereas other AST nodes return the complete
  /// textual representation of their subtree.
  String toString() => debugNodeToString(this);
}

/// A mutable AST node with a parent pointer.
///
/// This is anything other than [Name] and [DartType] nodes.
abstract class TreeNode extends Node {
  static int _hashCounter = 0;
  final int hashCode = _hashCounter = (_hashCounter + 1) & 0x3fffffff;
  static const int noOffset = -1;

  TreeNode parent;

  /// Offset in the source file it comes from. Valid values are from 0 and up,
  /// or -1 ([noOffset]) if the file offset is not available
  /// (this is the default if none is specifically set).
  int fileOffset = noOffset;

  accept(TreeVisitor v);
  visitChildren(Visitor v);
  transformChildren(Transformer v);

  /// Replaces [child] with [replacement].
  ///
  /// The caller is responsible for ensuring that the AST remains a tree.  In
  /// particular, [replacement] should be an orphan or be part of an orphaned
  /// subtree.
  ///
  /// Has no effect if [child] is not actually a child of this node.
  ///
  /// If [replacement] is `null`, this will [remove] the [child] node.
  void replaceChild(TreeNode child, TreeNode replacement) {
    transformChildren(new _ChildReplacer(child, replacement));
  }

  /// Inserts another node in place of this one.
  ///
  /// The caller is responsible for ensuring that the AST remains a tree.  In
  /// particular, [replacement] should be an orphan or be part of an orphaned
  /// subtree.
  ///
  /// If [replacement] is `null`, this will [remove] the node.
  void replaceWith(TreeNode replacement) {
    parent.replaceChild(this, replacement);
    parent = null;
  }

  /// Removes this node from the [List] it is currently stored in, or assigns
  /// `null` to the field on the parent currently pointing to the node.
  ///
  /// Has no effect if the node is orphaned or if the parent pointer is stale.
  void remove() {
    parent?.replaceChild(this, null);
    parent = null;
  }

  Program get enclosingProgram => parent?.enclosingProgram;

  /// Returns the best known source location of the given AST node, or `null` if
  /// the node is orphaned.
  ///
  /// This getter is intended for diagnostics and debugging, and should be
  /// avoided in production code.
  Location get location {
    if (fileOffset == noOffset) return parent?.location;
    return _getLocationInEnclosingFile(fileOffset);
  }

  Location _getLocationInEnclosingFile(int offset) {
    return parent?._getLocationInEnclosingFile(offset);
  }
}

// ------------------------------------------------------------------------
//                      LIBRARIES and CLASSES
// ------------------------------------------------------------------------

class Library extends TreeNode implements Comparable<Library> {
  /// An absolute import path to this library.
  ///
  /// The [Uri] should have the `dart`, `package`, or `file` scheme.
  Uri importUri;

  /// The uri of the source file this library was loaded from.
  String fileUri;

  /// If true, the library is part of another build unit and its contents
  /// are only partially loaded.
  ///
  /// Classes of an external library are loaded at one of the [ClassLevel]s
  /// other than [ClassLevel.Body].  Members in an external library have no
  /// body, but have their typed interface present.
  ///
  /// If the libary is non-external, then its classes are at [ClassLevel.Body]
  /// and all members are loaded.
  bool isExternal;

  String name;
  final List<Class> classes;
  final List<Procedure> procedures;
  final List<Field> fields;

  Library(this.importUri,
      {this.name,
      this.isExternal: false,
      List<Class> classes,
      List<Procedure> procedures,
      List<Field> fields})
      : this.classes = classes ?? <Class>[],
        this.procedures = procedures ?? <Procedure>[],
        this.fields = fields ?? <Field>[] {
    setParents(this.classes, this);
    setParents(this.procedures, this);
    setParents(this.fields, this);
  }

  /// Returns the top-level fields and procedures defined in this library.
  ///
  /// This getter is for convenience, not efficiency.  Consider manually
  /// iterating the members to speed up code in production.
  Iterable<Member> get members =>
      <Iterable<Member>>[fields, procedures].expand((x) => x);

  void addMember(Member member) {
    member.parent = this;
    if (member is Procedure) {
      procedures.add(member);
    } else if (member is Field) {
      fields.add(member);
    } else {
      throw new ArgumentError(member);
    }
  }

  void addClass(Class class_) {
    class_.parent = this;
    classes.add(class_);
  }

  accept(TreeVisitor v) => v.visitLibrary(this);

  visitChildren(Visitor v) {
    visitList(classes, v);
    visitList(procedures, v);
    visitList(fields, v);
  }

  transformChildren(Transformer v) {
    transformList(classes, v, this);
    transformList(procedures, v, this);
    transformList(fields, v, this);
  }

  static int _libraryIdCounter = 0;
  int _libraryId = ++_libraryIdCounter;

  int compareTo(Library other) => _libraryId - other._libraryId;

  /// Returns a possibly synthesized name for this library, consistent with
  /// the names across all [toString] calls.
  String toString() => debugLibraryName(this);

  Location _getLocationInEnclosingFile(int offset) {
    return enclosingProgram.getLocation(fileUri, offset);
  }
}

/// The degree to which the contents of a class have been loaded into memory.
///
/// Each level imply the requirements of the previous ones.
enum ClassLevel {
  /// Temporary loading level for internal use by IR producers.  Consumers of
  /// kernel code should not expect to see classes at this level.
  Temporary,

  /// The class may be used as a type, and it may contain members that are
  /// referenced from this build unit.
  ///
  /// The type parameters and their bounds are present.
  ///
  /// There is no guarantee that all members are present.
  ///
  /// All supertypes of this class are at [Type] level or higher.
  Type,

  /// All instance members of the class are present.
  ///
  /// All supertypes of this class are at [Hierarchy] level or higher.
  ///
  /// This level exists so supertypes of a fully loaded class contain all the
  /// members needed to detect override constraints.
  Hierarchy,

  /// All members of the class are fully loaded and are in the correct order.
  ///
  /// Annotations are present on classes and members.
  ///
  /// All supertypes of this class are at [Hierarchy] level or higher,
  /// not necessarily at [Body] level.
  Body,
}

/// Declaration of a regular class or a mixin application.
///
/// Mixin applications may not contain fields or procedures, as they implicitly
/// use those from its mixed-in type.  However, the IR does not enforce this
/// rule directly, as doing so can obstruct transformations.  It is possible to
/// transform a mixin application to become a regular class, and vice versa.
class Class extends TreeNode {
  /// The degree to which the contents of the class have been loaded.
  ClassLevel level = ClassLevel.Body;

  /// List of metadata annotations on the class.
  ///
  /// This defaults to an immutable empty list. Use [addAnnotation] to add
  /// annotations if needed.
  List<Expression> annotations = const <Expression>[];

  /// Name of the class.
  ///
  /// Must be non-null and must be unique within the library.
  ///
  /// The name may contain characters that are not valid in a Dart identifier,
  /// in particular, the symbol '&' is used in class names generated for mixin
  /// applications.
  String name;
  bool isAbstract;

  /// The uri of the source file this class was loaded from.
  String fileUri;

  final List<TypeParameter> typeParameters;

  /// The immediate super type, or `null` if this is the root class.
  Supertype supertype;

  /// The mixed-in type if this is a mixin application, otherwise `null`.
  Supertype mixedInType;

  /// The types from the `implements` clause.
  final List<Supertype> implementedTypes;

  /// Fields declared in the class.
  ///
  /// For mixin applications this should be empty.
  final List<Field> fields;

  /// Constructors declared in the class.
  final List<Constructor> constructors;

  /// Procedures declared in the class.
  ///
  /// For mixin applications this should be empty.
  final List<Procedure> procedures;

  Class(
      {this.name,
      this.isAbstract: false,
      this.supertype,
      this.mixedInType,
      List<TypeParameter> typeParameters,
      List<InterfaceType> implementedTypes,
      List<Constructor> constructors,
      List<Procedure> procedures,
      List<Field> fields,
      this.fileUri})
      : this.typeParameters = typeParameters ?? <TypeParameter>[],
        this.implementedTypes = implementedTypes ?? <Supertype>[],
        this.fields = fields ?? <Field>[],
        this.constructors = constructors ?? <Constructor>[],
        this.procedures = procedures ?? <Procedure>[] {
    setParents(this.typeParameters, this);
    setParents(this.constructors, this);
    setParents(this.procedures, this);
    setParents(this.fields, this);
  }

  /// The immediate super class, or `null` if this is the root class.
  Class get superclass => supertype?.classNode;

  /// The mixed-in class if this is a mixin application, otherwise `null`.
  ///
  /// Note that this may itself be a mixin application.  Use [mixin] to get the
  /// class that has the fields and procedures.
  Class get mixedInClass => mixedInType?.classNode;

  /// The class that declares the field and procedures of this class.
  Class get mixin => mixedInClass?.mixin ?? this;

  bool get isMixinApplication => mixedInType != null;

  /// Members declared in this class.
  ///
  /// This getter is for convenience, not efficiency.  Consider manually
  /// iterating the members to speed up code in production.
  Iterable<Member> get members =>
      <Iterable<Member>>[fields, constructors, procedures].expand((x) => x);

  /// The immediately extended, mixed-in, and implemented types.
  ///
  /// This getter is for convenience, not efficiency.  Consider manually
  /// iterating the super types to speed up code in production.
  Iterable<Supertype> get supers => <Iterable<Supertype>>[
        supertype == null ? const [] : [supertype],
        mixedInType == null ? const [] : [mixedInType],
        implementedTypes
      ].expand((x) => x);

  /// The library containing this class.
  Library get enclosingLibrary => parent;

  /// Adds a member to this class.
  ///
  /// Throws an error if attempting to add a field or procedure to a mixin
  /// application.
  void addMember(Member member) {
    member.parent = this;
    if (member is Constructor) {
      constructors.add(member);
    } else if (member is Procedure) {
      procedures.add(member);
    } else if (member is Field) {
      fields.add(member);
    } else {
      throw new ArgumentError(member);
    }
  }

  void addAnnotation(Expression node) {
    if (annotations.isEmpty) {
      annotations = <Expression>[];
    }
    annotations.add(node);
    node.parent = this;
  }

  accept(TreeVisitor v) => v.visitClass(this);
  acceptReference(Visitor v) => v.visitClassReference(this);

  /// If true, the class is part of an external library, that is, it is defined
  /// in another build unit.  Only a subset of its members are present.
  ///
  /// These classes should be loaded at either [ClassLevel.Type] or
  /// [ClassLevel.Hierarchy] level.
  bool get isInExternalLibrary => enclosingLibrary.isExternal;

  Supertype get asRawSupertype {
    return new Supertype(this,
        new List<DartType>.filled(typeParameters.length, const DynamicType()));
  }

  Supertype get asThisSupertype {
    return new Supertype(this, _getAsTypeArguments(typeParameters));
  }

  InterfaceType _rawType;
  InterfaceType get rawType => _rawType ??= new InterfaceType(this);

  InterfaceType _thisType;
  InterfaceType get thisType {
    return _thisType ??=
        new InterfaceType(this, _getAsTypeArguments(typeParameters));
  }

  InterfaceType _bottomType;
  InterfaceType get bottomType {
    return _bottomType ??= new InterfaceType(this,
        new List<DartType>.filled(typeParameters.length, const BottomType()));
  }

  /// Returns a possibly synthesized name for this class, consistent with
  /// the names used across all [toString] calls.
  String toString() => debugQualifiedClassName(this);

  visitChildren(Visitor v) {
    visitList(annotations, v);
    visitList(typeParameters, v);
    supertype?.accept(v);
    mixedInType?.accept(v);
    visitList(implementedTypes, v);
    visitList(constructors, v);
    visitList(procedures, v);
    visitList(fields, v);
  }

  transformChildren(Transformer v) {
    transformList(annotations, v, this);
    transformList(typeParameters, v, this);
    if (supertype != null) {
      supertype = v.visitSupertype(supertype);
    }
    if (mixedInType != null) {
      mixedInType = v.visitSupertype(mixedInType);
    }
    transformSupertypeList(implementedTypes, v);
    transformList(constructors, v, this);
    transformList(procedures, v, this);
    transformList(fields, v, this);
  }

  Location _getLocationInEnclosingFile(int offset) {
    return enclosingProgram.getLocation(fileUri, offset);
  }
}

// ------------------------------------------------------------------------
//                            MEMBERS
// ------------------------------------------------------------------------

/// A indirect reference to a member, which can be updated to point at another
/// member at a later time.
class _MemberAccessor {
  Member target;
  _MemberAccessor(this.target);
}

abstract class Member extends TreeNode {
  /// List of metadata annotations on the member.
  ///
  /// This defaults to an immutable empty list. Use [addAnnotation] to add
  /// annotations if needed.
  List<Expression> annotations = const <Expression>[];
  Name name;

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

  Member(this.name);

  Class get enclosingClass => parent is Class ? parent : null;
  Library get enclosingLibrary => parent is Class ? parent.parent : parent;

  accept(MemberVisitor v);
  acceptReference(MemberReferenceVisitor v);

  /// If true, the member is part of an external library, that is, it is defined
  /// in another build unit.  Such members have no body or initializer present
  /// in the IR.
  bool get isInExternalLibrary => enclosingLibrary.isExternal;

  /// Returns true if this is an abstract procedure.
  bool get isAbstract => false;

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
  void set isExternal(bool value);

  /// The body of the procedure or constructor, or `null` if this is a field.
  FunctionNode get function => null;

  /// Returns a possibly synthesized name for this member, consistent with
  /// the names used across all [toString] calls.
  String toString() => debugQualifiedMemberName(this);

  void addAnnotation(Expression node) {
    if (annotations.isEmpty) {
      annotations = <Expression>[];
    }
    annotations.add(node);
    node.parent = this;
  }

  DartType get getterType;
  DartType get setterType;

  bool get containsSuperCalls {
    return transformerFlags & TransformerFlag.superCalls != 0;
  }

  _MemberAccessor get _getterInterface;
  _MemberAccessor get _setterInterface;
}

/// A field declaration.
///
/// The implied getter and setter for the field are not represented explicitly,
/// but can be made explicit if needed.
class Field extends Member {
  _MemberAccessor _getterInterface, _setterInterface;

  DartType type; // Not null. Defaults to DynamicType.
  InferredValue inferredValue; // May be null.
  int flags = 0;
  Expression initializer; // May be null.

  /// The uri of the source file this field was loaded from.
  String fileUri;

  Field(Name name,
      {this.type: const DynamicType(),
      this.inferredValue,
      this.initializer,
      bool isFinal: false,
      bool isConst: false,
      bool isStatic: false,
      bool hasImplicitGetter,
      bool hasImplicitSetter,
      int transformerFlags: 0,
      this.fileUri})
      : super(name) {
    _getterInterface = new _MemberAccessor(this);
    _setterInterface = new _MemberAccessor(this);
    assert(type != null);
    initializer?.parent = this;
    this.isFinal = isFinal;
    this.isConst = isConst;
    this.isStatic = isStatic;
    this.hasImplicitGetter = hasImplicitGetter ?? !isStatic;
    this.hasImplicitSetter = hasImplicitSetter ?? (!isStatic && !isFinal);
    this.transformerFlags = transformerFlags;
  }

  static const int FlagFinal = 1 << 0; // Must match serialized bit positions.
  static const int FlagConst = 1 << 1;
  static const int FlagStatic = 1 << 2;
  static const int FlagHasImplicitGetter = 1 << 3;
  static const int FlagHasImplicitSetter = 1 << 4;

  bool get isFinal => flags & FlagFinal != 0;
  bool get isConst => flags & FlagConst != 0;
  bool get isStatic => flags & FlagStatic != 0;

  /// If true, a getter should be generated for this field.
  ///
  /// If false, there may or may not exist an explicit getter in the same class
  /// with the same name as the field.
  ///
  /// By default, all non-static fields have implicit getters.
  bool get hasImplicitGetter => flags & FlagHasImplicitGetter != 0;

  /// If true, a setter should be generated for this field.
  ///
  /// If false, there may or may not exist an explicit setter in the same class
  /// with the same name as the field.
  ///
  /// Final fields never have implicit setters, but a field without an implicit
  /// setter is not necessarily final, as it may be mutated by direct field
  /// access.
  ///
  /// By default, all non-static, non-final fields have implicit getters.
  bool get hasImplicitSetter => flags & FlagHasImplicitSetter != 0;

  void set isFinal(bool value) {
    flags = value ? (flags | FlagFinal) : (flags & ~FlagFinal);
  }

  void set isConst(bool value) {
    flags = value ? (flags | FlagConst) : (flags & ~FlagConst);
  }

  void set isStatic(bool value) {
    flags = value ? (flags | FlagStatic) : (flags & ~FlagStatic);
  }

  void set hasImplicitGetter(bool value) {
    flags = value
        ? (flags | FlagHasImplicitGetter)
        : (flags & ~FlagHasImplicitGetter);
  }

  void set hasImplicitSetter(bool value) {
    flags = value
        ? (flags | FlagHasImplicitSetter)
        : (flags & ~FlagHasImplicitSetter);
  }

  /// True if the field is neither final nor const.
  bool get isMutable => flags & (FlagFinal | FlagConst) == 0;
  bool get isInstanceMember => !isStatic;
  bool get hasGetter => true;
  bool get hasSetter => isMutable;

  bool get isExternal => false;
  void set isExternal(bool value) {
    if (value) throw 'Fields cannot be external';
  }

  accept(MemberVisitor v) => v.visitField(this);

  acceptReference(MemberReferenceVisitor v) => v.visitFieldReference(this);

  visitChildren(Visitor v) {
    visitList(annotations, v);
    type?.accept(v);
    inferredValue?.accept(v);
    name?.accept(v);
    initializer?.accept(v);
  }

  transformChildren(Transformer v) {
    type = v.visitDartType(type);
    transformList(annotations, v, this);
    if (initializer != null) {
      initializer = initializer.accept(v);
      initializer?.parent = this;
    }
  }

  DartType get getterType => type;
  DartType get setterType => isMutable ? type : const BottomType();

  /// Makes all [PropertyGet]s that have this field as its interface target
  /// use [getter] as its interface target instead.
  ///
  /// That can be used to introduce an explicit getter for a field instead of
  /// its implicit getter.
  ///
  /// This method only updates the stored interface target -- the caller must
  /// ensure that [getter] actually becomes the target for dispatches that
  /// would previously hit the implicit field getter.
  ///
  /// [DirectPropertyGet]s are not affected, and will continue to access the
  /// field directly. [PropertyGet] nodes created after the call will not be
  /// affected until the method is called again.
  ///
  /// Existing [ClassHierarchy] instances are not affected by this call.
  void replaceGetterInterfaceWith(Procedure getter) {
    _getterInterface.target = getter;
    _getterInterface = new _MemberAccessor(this);
  }

  /// Makes all [PropertySet]s that have this field as its interface target
  /// use [setter] as its interface target instead.
  ///
  /// That can be used to introduce an explicit setter for a field instead of
  /// its implicit setter.
  ///
  /// This method only updates the stored interface target -- the caller must
  /// ensure that [setter] actually becomes the target for dispatches that
  /// would previously hit the implicit field setter.
  ///
  /// [DirectPropertySet] and [FieldInitializer]s are not affected, and will
  /// continue to access the field directly.  [PropertySet] nodes created after
  /// the call will not be affected until the method is called again.
  ///
  /// Existing [ClassHierarchy] instances are not affected by this call.
  void replaceSetterInterfaceWith(Procedure setter) {
    _setterInterface.target = setter;
    _setterInterface = new _MemberAccessor(this);
  }

  Location _getLocationInEnclosingFile(int offset) {
    return enclosingProgram.getLocation(fileUri, offset);
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
  int flags = 0;
  FunctionNode function;
  List<Initializer> initializers;

  Constructor(this.function,
      {Name name,
      bool isConst: false,
      bool isExternal: false,
      List<Initializer> initializers,
      int transformerFlags: 0})
      : this.initializers = initializers ?? <Initializer>[],
        super(name) {
    function?.parent = this;
    setParents(this.initializers, this);
    this.isConst = isConst;
    this.isExternal = isExternal;
    this.transformerFlags = transformerFlags;
  }

  static const int FlagConst = 1 << 0; // Must match serialized bit positions.
  static const int FlagExternal = 1 << 1;

  bool get isConst => flags & FlagConst != 0;
  bool get isExternal => flags & FlagExternal != 0;

  void set isConst(bool value) {
    flags = value ? (flags | FlagConst) : (flags & ~FlagConst);
  }

  void set isExternal(bool value) {
    flags = value ? (flags | FlagExternal) : (flags & ~FlagExternal);
  }

  bool get isInstanceMember => false;
  bool get hasGetter => false;
  bool get hasSetter => false;

  accept(MemberVisitor v) => v.visitConstructor(this);

  acceptReference(MemberReferenceVisitor v) =>
      v.visitConstructorReference(this);

  visitChildren(Visitor v) {
    visitList(annotations, v);
    name?.accept(v);
    function?.accept(v);
    visitList(initializers, v);
  }

  transformChildren(Transformer v) {
    transformList(annotations, v, this);
    if (function != null) {
      function = function.accept(v);
      function?.parent = this;
    }
    transformList(initializers, v, this);
  }

  DartType get getterType => const BottomType();
  DartType get setterType => const BottomType();

  _MemberAccessor get _getterInterface {
    throw 'Constructors cannot be used as getters';
  }

  _MemberAccessor get _setterInterface {
    throw 'Constructors cannot be used as setters';
  }
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
class Procedure extends Member {
  _MemberAccessor _reference;
  ProcedureKind kind;
  int flags = 0;
  FunctionNode function; // Body is null if and only if abstract or external.

  /// The uri of the source file this procedure was loaded from.
  String fileUri;

  Procedure(Name name, this.kind, this.function,
      {bool isAbstract: false,
      bool isStatic: false,
      bool isExternal: false,
      bool isConst: false,
      int transformerFlags: 0,
      this.fileUri})
      : super(name) {
    _reference = new _MemberAccessor(this);
    function?.parent = this;
    this.isAbstract = isAbstract;
    this.isStatic = isStatic;
    this.isExternal = isExternal;
    this.isConst = isConst;
    this.transformerFlags = transformerFlags;
  }

  static const int FlagStatic = 1 << 0; // Must match serialized bit positions.
  static const int FlagAbstract = 1 << 1;
  static const int FlagExternal = 1 << 2;
  static const int FlagConst = 1 << 3; // Only for external const factories.

  bool get isStatic => flags & FlagStatic != 0;
  bool get isAbstract => flags & FlagAbstract != 0;
  bool get isExternal => flags & FlagExternal != 0;

  /// True if this has the `const` modifier.  This is only possible for external
  /// constant factories, such as `String.fromEnvironment`.
  bool get isConst => flags & FlagConst != 0;

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

  bool get isInstanceMember => !isStatic;
  bool get isGetter => kind == ProcedureKind.Getter;
  bool get isSetter => kind == ProcedureKind.Setter;
  bool get isAccessor => isGetter || isSetter;
  bool get hasGetter => kind != ProcedureKind.Setter;
  bool get hasSetter => kind == ProcedureKind.Setter;

  accept(MemberVisitor v) => v.visitProcedure(this);

  acceptReference(MemberReferenceVisitor v) => v.visitProcedureReference(this);

  visitChildren(Visitor v) {
    visitList(annotations, v);
    name?.accept(v);
    function?.accept(v);
  }

  transformChildren(Transformer v) {
    transformList(annotations, v, this);
    if (function != null) {
      function = function.accept(v);
      function?.parent = this;
    }
  }

  DartType get getterType {
    return isGetter ? function.returnType : function.functionType;
  }

  DartType get setterType {
    return isSetter
        ? function.positionalParameters[0].type
        : const BottomType();
  }

  _MemberAccessor get _getterInterface => _reference;
  _MemberAccessor get _setterInterface => _reference;
}

enum ProcedureKind {
  Method,
  Getter,
  Setter,
  Operator,
  Factory,
}

// ------------------------------------------------------------------------
//                     CONSTRUCTOR INITIALIZERS
// ------------------------------------------------------------------------

/// Part of an initializer list in a constructor.
abstract class Initializer extends TreeNode {
  accept(InitializerVisitor v);
}

/// An initializer with a compile-time error.
///
/// Should throw an exception at runtime.
//
// DESIGN TODO: The frontend should use this in a lot more cases to catch
// invalid cases.
class InvalidInitializer extends Initializer {
  accept(InitializerVisitor v) => v.visitInvalidInitializer(this);

  visitChildren(Visitor v) {}
  transformChildren(Transformer v) {}
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
  Field field;
  Expression value;

  FieldInitializer(this.field, this.value) {
    value?.parent = this;
  }

  accept(InitializerVisitor v) => v.visitFieldInitializer(this);

  visitChildren(Visitor v) {
    field?.acceptReference(v);
    value?.accept(v);
  }

  transformChildren(Transformer v) {
    if (value != null) {
      value = value.accept(v);
      value?.parent = this;
    }
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
  Constructor target;
  Arguments arguments;

  SuperInitializer(this.target, this.arguments) {
    arguments?.parent = this;
  }

  accept(InitializerVisitor v) => v.visitSuperInitializer(this);

  visitChildren(Visitor v) {
    target?.acceptReference(v);
    arguments?.accept(v);
  }

  transformChildren(Transformer v) {
    if (arguments != null) {
      arguments = arguments.accept(v);
      arguments?.parent = this;
    }
  }
}

/// A redirecting call `this(x,y)` occurring in the initializer list of
/// a constructor.
//
// TODO: The frontend should check that this is the only initializer and if the
// constructor has a body or if there is a cycle in the initializer calls.
class RedirectingInitializer extends Initializer {
  /// Reference to the constructor being invoked in the same class. Not null.
  Constructor target;
  Arguments arguments;

  RedirectingInitializer(this.target, this.arguments) {
    arguments?.parent = this;
  }

  accept(InitializerVisitor v) => v.visitRedirectingInitializer(this);

  visitChildren(Visitor v) {
    target?.acceptReference(v);
    arguments?.accept(v);
  }

  transformChildren(Transformer v) {
    if (arguments != null) {
      arguments = arguments.accept(v);
      arguments?.parent = this;
    }
  }
}

/// Binding of a temporary variable in the initializer list of a constructor.
///
/// The variable is in scope for the remainder of the initializer list, but is
/// not in scope in the constructor body.
class LocalInitializer extends Initializer {
  VariableDeclaration variable;

  LocalInitializer(this.variable) {
    variable?.parent = this;
  }

  accept(InitializerVisitor v) => v.visitLocalInitializer(this);

  visitChildren(Visitor v) {
    variable?.accept(v);
  }

  transformChildren(Transformer v) {
    if (variable != null) {
      variable = variable.accept(v);
      variable?.parent = this;
    }
  }
}

// ------------------------------------------------------------------------
//                            FUNCTIONS
// ------------------------------------------------------------------------

/// A function declares parameters and has a body.
///
/// This may occur in a procedure, constructor, function expression, or local
/// function declaration.
class FunctionNode extends TreeNode {
  AsyncMarker asyncMarker;
  List<TypeParameter> typeParameters;
  int requiredParameterCount;
  List<VariableDeclaration> positionalParameters;
  List<VariableDeclaration> namedParameters; // Must be sorted.
  InferredValue inferredReturnValue; // May be null.
  DartType returnType; // Not null.
  Statement body;

  FunctionNode(this.body,
      {List<TypeParameter> typeParameters,
      List<VariableDeclaration> positionalParameters,
      List<VariableDeclaration> namedParameters,
      int requiredParameterCount,
      this.returnType: const DynamicType(),
      this.inferredReturnValue,
      this.asyncMarker: AsyncMarker.Sync})
      : this.positionalParameters =
            positionalParameters ?? <VariableDeclaration>[],
        this.requiredParameterCount =
            requiredParameterCount ?? positionalParameters?.length ?? 0,
        this.namedParameters = namedParameters ?? <VariableDeclaration>[],
        this.typeParameters = typeParameters ?? <TypeParameter>[] {
    assert(returnType != null);
    setParents(this.typeParameters, this);
    setParents(this.positionalParameters, this);
    setParents(this.namedParameters, this);
    body?.parent = this;
  }

  static DartType _getTypeOfVariable(VariableDeclaration node) => node.type;

  static NamedType _getNamedTypeOfVariable(VariableDeclaration node) {
    return new NamedType(node.name, node.type);
  }

  FunctionType get functionType {
    Map<String, DartType> named = const <String, DartType>{};
    if (namedParameters.isNotEmpty) {
      named = <String, DartType>{};
      for (var node in namedParameters) {
        named[node.name] = node.type;
      }
    }
    TreeNode parent = this.parent;
    return new FunctionType(
        positionalParameters.map(_getTypeOfVariable).toList(), returnType,
        namedParameters: namedParameters.map(_getNamedTypeOfVariable).toList(),
        typeParameters: parent is Constructor
            ? parent.enclosingClass.typeParameters
            : typeParameters,
        requiredParameterCount: requiredParameterCount);
  }

  accept(TreeVisitor v) => v.visitFunctionNode(this);

  visitChildren(Visitor v) {
    visitList(typeParameters, v);
    visitList(positionalParameters, v);
    visitList(namedParameters, v);
    returnType?.accept(v);
    inferredReturnValue?.accept(v);
    body?.accept(v);
  }

  transformChildren(Transformer v) {
    transformList(typeParameters, v, this);
    transformList(positionalParameters, v, this);
    transformList(namedParameters, v, this);
    returnType = v.visitDartType(returnType);
    if (body != null) {
      body = body.accept(v);
      body?.parent = this;
    }
  }
}

enum AsyncMarker {
  // Do not change the order of these, the frontends depend on it.
  Sync,
  SyncStar,
  Async,
  AsyncStar,

  // `SyncYielding` is a marker that tells Dart VM that this function is an
  // artificial closure introduced by an async transformer which desugared all
  // async syntax into a combination of native yields and helper method calls.
  //
  // Native yields (formatted as `[yield]`) are semantically close to
  // `yield x` statement: they denote a yield/resume point within a function
  // but are completely decoupled from the notion of iterators. When
  // execution of the closure reaches `[yield] x` it stops and return the
  // value of `x` to the caller. If closure is called again it continues
  // to the next statement after this yield as if it was suspended and resumed.
  //
  // Consider this example:
  //
  //   g() {
  //     var :await_jump_var = 0;
  //     var :await_ctx_var;
  //
  //     f(x) yielding {
  //       [yield] '${x}:0';
  //       [yield] '${x}:1';
  //       [yield] '${x}:2';
  //     }
  //
  //     return f;
  //   }
  //
  //   print(f('a'));  /* prints 'a:0', :await_jump_var = 1  */
  //   print(f('b'));  /* prints 'b:1', :await_jump_var = 2  */
  //   print(f('c'));  /* prints 'c:2', :await_jump_var = 3  */
  //
  // Note: currently Dart VM implicitly relies on async transformer to
  // inject certain artificial variables into g (like `:await_jump_var`).
  // As such SyncYielding and native yield are not intended to be used on their
  // own, but are rather an implementation artifact of the async transformer
  // itself.
  SyncYielding,
}

// ------------------------------------------------------------------------
//                                EXPRESSIONS
// ------------------------------------------------------------------------

abstract class Expression extends TreeNode {
  /// Returns the static type of the expression.
  ///
  /// Should only be used on code compiled in strong mode, as this method
  /// assumes the IR is strongly typed.
  DartType getStaticType(TypeEnvironment types);

  /// Returns the static type of the expression as an instantiation of
  /// [superclass].
  ///
  /// Should only be used on code compiled in strong mode, as this method
  /// assumes the IR is strongly typed.
  ///
  /// This method futhermore assumes that the type of the expression actually
  /// is a subtype of (some instantiation of) the given [superclass].
  /// If this is not the case, either an exception is thrown or the raw type of
  /// [superclass] is returned.
  InterfaceType getStaticTypeAsInstanceOf(
      Class superclass, TypeEnvironment types) {
    // This method assumes the program is correctly typed, so if the superclass
    // is not generic, we can just return its raw type without computing the
    // type of this expression.  It also ensures that all types are considered
    // subtypes of Object (not just interface types), and function types are
    // considered subtypes of Function.
    if (superclass.typeParameters.isEmpty) {
      return superclass.rawType;
    }
    var type = getStaticType(types);
    while (type is TypeParameterType) {
      type = (type as TypeParameterType).parameter.bound;
    }
    if (type is InterfaceType) {
      var upcastType = types.hierarchy.getTypeAsInstanceOf(type, superclass);
      if (upcastType != null) return upcastType;
    } else if (type is BottomType) {
      return superclass.bottomType;
    }
    types.typeError(this, '$type is not a subtype of $superclass');
    return superclass.rawType;
  }

  accept(ExpressionVisitor v);
}

/// An expression containing compile-time errors.
///
/// Should throw a runtime error when evaluated.
class InvalidExpression extends Expression {
  DartType getStaticType(TypeEnvironment types) => const BottomType();

  accept(ExpressionVisitor v) => v.visitInvalidExpression(this);

  visitChildren(Visitor v) {}
  transformChildren(Transformer v) {}
}

/// Read a local variable, a local function, or a function parameter.
class VariableGet extends Expression {
  VariableDeclaration variable;
  DartType promotedType; // Null if not promoted.

  VariableGet(this.variable, [this.promotedType]);

  DartType getStaticType(TypeEnvironment types) {
    return promotedType ?? variable.type;
  }

  accept(ExpressionVisitor v) => v.visitVariableGet(this);

  visitChildren(Visitor v) {
    promotedType?.accept(v);
  }

  transformChildren(Transformer v) {
    if (promotedType != null) {
      promotedType = v.visitDartType(promotedType);
    }
  }
}

/// Assign a local variable or function parameter.
class VariableSet extends Expression {
  VariableDeclaration variable;
  Expression value;

  VariableSet(this.variable, this.value) {
    value?.parent = this;
  }

  DartType getStaticType(TypeEnvironment types) => value.getStaticType(types);

  accept(ExpressionVisitor v) => v.visitVariableSet(this);

  visitChildren(Visitor v) {
    value?.accept(v);
  }

  transformChildren(Transformer v) {
    if (value != null) {
      value = value.accept(v);
      value?.parent = this;
    }
  }
}

/// Expression of form `x.field`.
///
/// This may invoke a getter, read a field, or tear off a method.
class PropertyGet extends Expression {
  Expression receiver;
  Name name;

  _MemberAccessor _interfaceTargetReference;

  PropertyGet(this.receiver, this.name, [Member interfaceTarget]) {
    receiver?.parent = this;
    this.interfaceTarget = interfaceTarget;
  }

  Member get interfaceTarget => _interfaceTargetReference?.target;

  void set interfaceTarget(Member newTarget) {
    _interfaceTargetReference = newTarget?._getterInterface;
  }

  DartType getStaticType(TypeEnvironment types) {
    var interfaceTarget = this.interfaceTarget;
    if (interfaceTarget != null) {
      Class superclass = interfaceTarget.enclosingClass;
      var receiverType = receiver.getStaticTypeAsInstanceOf(superclass, types);
      return Substitution
          .fromInterfaceType(receiverType)
          .substituteType(interfaceTarget.getterType);
    }
    // Treat the properties of Object specially.
    String nameString = name.name;
    if (nameString == 'hashCode') {
      return types.intType;
    } else if (nameString == 'runtimeType') {
      return types.typeType;
    }
    return const DynamicType();
  }

  accept(ExpressionVisitor v) => v.visitPropertyGet(this);

  visitChildren(Visitor v) {
    receiver?.accept(v);
    name?.accept(v);
  }

  transformChildren(Transformer v) {
    if (receiver != null) {
      receiver = receiver.accept(v);
      receiver?.parent = this;
    }
  }
}

/// Expression of form `x.field = value`.
///
/// This may invoke a setter or assign a field.
class PropertySet extends Expression {
  Expression receiver;
  Name name;
  Expression value;

  _MemberAccessor _interfaceTargetReference;

  PropertySet(this.receiver, this.name, this.value, [Member interfaceTarget]) {
    receiver?.parent = this;
    value?.parent = this;
    this.interfaceTarget = interfaceTarget;
  }

  Member get interfaceTarget => _interfaceTargetReference?.target;

  void set interfaceTarget(Member newTarget) {
    _interfaceTargetReference = newTarget?._setterInterface;
  }

  DartType getStaticType(TypeEnvironment types) => value.getStaticType(types);

  accept(ExpressionVisitor v) => v.visitPropertySet(this);

  visitChildren(Visitor v) {
    receiver?.accept(v);
    name?.accept(v);
    value?.accept(v);
  }

  transformChildren(Transformer v) {
    if (receiver != null) {
      receiver = receiver.accept(v);
      receiver?.parent = this;
    }
    if (value != null) {
      value = value.accept(v);
      value?.parent = this;
    }
  }
}

/// Directly read a field, call a getter, or tear off a method.
class DirectPropertyGet extends Expression {
  Expression receiver;
  Member target;

  DirectPropertyGet(this.receiver, this.target) {
    receiver?.parent = this;
  }

  visitChildren(Visitor v) {
    receiver?.accept(v);
    target?.acceptReference(v);
  }

  transformChildren(Transformer v) {
    if (receiver != null) {
      receiver = receiver.accept(v);
      receiver?.parent = this;
    }
  }

  accept(ExpressionVisitor v) => v.visitDirectPropertyGet(this);

  DartType getStaticType(TypeEnvironment types) {
    Class superclass = target.enclosingClass;
    var receiverType = receiver.getStaticTypeAsInstanceOf(superclass, types);
    return Substitution
        .fromInterfaceType(receiverType)
        .substituteType(target.getterType);
  }
}

/// Directly assign a field, or call a setter.
class DirectPropertySet extends Expression {
  Expression receiver;
  Member target;
  Expression value;

  DirectPropertySet(this.receiver, this.target, this.value) {
    receiver?.parent = this;
    value?.parent = this;
  }

  visitChildren(Visitor v) {
    receiver?.accept(v);
    target?.acceptReference(v);
    value?.accept(v);
  }

  transformChildren(Transformer v) {
    if (receiver != null) {
      receiver = receiver.accept(v);
      receiver?.parent = this;
    }
    if (value != null) {
      value = value.accept(v);
      value?.parent = this;
    }
  }

  accept(ExpressionVisitor v) => v.visitDirectPropertySet(this);

  DartType getStaticType(TypeEnvironment types) => value.getStaticType(types);
}

/// Directly call an instance method, bypassing ordinary dispatch.
class DirectMethodInvocation extends Expression {
  Expression receiver;
  Procedure target;
  Arguments arguments;

  DirectMethodInvocation(this.receiver, this.target, this.arguments) {
    receiver?.parent = this;
    arguments?.parent = this;
  }

  visitChildren(Visitor v) {
    receiver?.accept(v);
    target?.acceptReference(v);
    arguments?.accept(v);
  }

  transformChildren(Transformer v) {
    if (receiver != null) {
      receiver = receiver.accept(v);
      receiver?.parent = this;
    }
    if (arguments != null) {
      arguments = arguments.accept(v);
      arguments?.parent = this;
    }
  }

  accept(ExpressionVisitor v) => v.visitDirectMethodInvocation(this);

  DartType getStaticType(TypeEnvironment types) {
    if (types.isOverloadedArithmeticOperator(target)) {
      return types.getTypeOfOverloadedArithmetic(receiver.getStaticType(types),
          arguments.positional[0].getStaticType(types));
    }
    Class superclass = target.enclosingClass;
    var receiverType = receiver.getStaticTypeAsInstanceOf(superclass, types);
    var returnType = Substitution
        .fromInterfaceType(receiverType)
        .substituteType(target.function.returnType);
    return Substitution
        .fromPairs(target.function.typeParameters, arguments.types)
        .substituteType(returnType);
  }
}

/// Expression of form `super.field`.
///
/// This may invoke a getter, read a field, or tear off a method.
class SuperPropertyGet extends Expression {
  Name name;
  _MemberAccessor _interfaceTargetReference;

  SuperPropertyGet(this.name, [Member interfaceTarget]) {
    _interfaceTargetReference = interfaceTarget?._getterInterface;
  }

  Member get interfaceTarget => _interfaceTargetReference?.target;

  void set interfaceTarget(Member newTarget) {
    _interfaceTargetReference = newTarget?._getterInterface;
  }

  DartType getStaticType(TypeEnvironment types) {
    Class declaringClass = interfaceTarget.enclosingClass;
    if (declaringClass.typeParameters.isEmpty) {
      return interfaceTarget.getterType;
    }
    var receiver =
        types.hierarchy.getTypeAsInstanceOf(types.thisType, declaringClass);
    return Substitution
        .fromInterfaceType(receiver)
        .substituteType(interfaceTarget.getterType);
  }

  accept(ExpressionVisitor v) => v.visitSuperPropertyGet(this);

  visitChildren(Visitor v) {
    name?.accept(v);
  }

  transformChildren(Transformer v) {}
}

/// Expression of form `super.field = value`.
///
/// This may invoke a setter or assign a field.
class SuperPropertySet extends Expression {
  Name name;
  Expression value;
  _MemberAccessor _interfaceTargetReference;

  SuperPropertySet(this.name, this.value, [Member interfaceTarget]) {
    value?.parent = this;
    _interfaceTargetReference = interfaceTarget?._setterInterface;
  }

  Member get interfaceTarget => _interfaceTargetReference?.target;

  void set interfaceTarget(Member newTarget) {
    _interfaceTargetReference = newTarget?._setterInterface;
  }

  DartType getStaticType(TypeEnvironment types) => value.getStaticType(types);

  accept(ExpressionVisitor v) => v.visitSuperPropertySet(this);

  visitChildren(Visitor v) {
    name?.accept(v);
    value?.accept(v);
  }

  transformChildren(Transformer v) {
    if (value != null) {
      value = value.accept(v);
      value?.parent = this;
    }
  }
}

/// Read a static field, call a static getter, or tear off a static method.
class StaticGet extends Expression {
  /// A static field, getter, or method (for tear-off).
  Member target;

  StaticGet(this.target);

  DartType getStaticType(TypeEnvironment types) => target.getterType;

  accept(ExpressionVisitor v) => v.visitStaticGet(this);

  visitChildren(Visitor v) {
    target?.acceptReference(v);
  }

  transformChildren(Transformer v) {}
}

/// Assign a static field or call a static setter.
class StaticSet extends Expression {
  /// A mutable static field or a static setter.
  Member target;
  Expression value;

  StaticSet(this.target, this.value) {
    value?.parent = this;
  }

  DartType getStaticType(TypeEnvironment types) => value.getStaticType(types);

  accept(ExpressionVisitor v) => v.visitStaticSet(this);

  visitChildren(Visitor v) {
    target?.acceptReference(v);
    value?.accept(v);
  }

  transformChildren(Transformer v) {
    if (value != null) {
      value = value.accept(v);
      value?.parent = this;
    }
  }
}

/// The arguments to a function call, divided into type arguments,
/// positional arguments, and named arguments.
class Arguments extends TreeNode {
  final List<DartType> types;
  final List<Expression> positional;
  final List<NamedExpression> named;

  Arguments(this.positional,
      {List<DartType> types, List<NamedExpression> named})
      : this.types = types ?? <DartType>[],
        this.named = named ?? <NamedExpression>[] {
    setParents(this.positional, this);
    setParents(this.named, this);
  }

  Arguments.empty()
      : types = <DartType>[],
        positional = <Expression>[],
        named = <NamedExpression>[];

  accept(TreeVisitor v) => v.visitArguments(this);

  visitChildren(Visitor v) {
    visitList(types, v);
    visitList(positional, v);
    visitList(named, v);
  }

  transformChildren(Transformer v) {
    transformTypeList(types, v);
    transformList(positional, v, this);
    transformList(named, v, this);
  }
}

/// A named argument, `name: value`.
class NamedExpression extends TreeNode {
  String name;
  Expression value;

  NamedExpression(this.name, this.value) {
    value?.parent = this;
  }

  accept(TreeVisitor v) => v.visitNamedExpression(this);

  visitChildren(Visitor v) {
    value?.accept(v);
  }

  transformChildren(Transformer v) {
    if (value != null) {
      value = value.accept(v);
      value?.parent = this;
    }
  }
}

/// Common super class for [MethodInvocation], [SuperMethodInvocation],
/// [StaticInvocation], and [ConstructorInvocation].
abstract class InvocationExpression extends Expression {
  Arguments get arguments;
  set arguments(Arguments value);

  /// Name of the invoked method.
  ///
  /// May be `null` if the target is a synthetic static member without a name.
  Name get name;
}

/// Expression of form `x.foo(y)`.
class MethodInvocation extends InvocationExpression {
  Expression receiver;
  Name name;
  Arguments arguments;

  Procedure interfaceTarget;

  MethodInvocation(this.receiver, this.name, this.arguments,
      [this.interfaceTarget]) {
    receiver?.parent = this;
    arguments?.parent = this;
  }

  DartType getStaticType(TypeEnvironment types) {
    if (interfaceTarget != null) {
      if (types.isOverloadedArithmeticOperator(interfaceTarget)) {
        return types.getTypeOfOverloadedArithmetic(
            receiver.getStaticType(types),
            arguments.positional[0].getStaticType(types));
      }
      Class superclass = interfaceTarget.enclosingClass;
      var receiverType = receiver.getStaticTypeAsInstanceOf(superclass, types);
      var returnType = Substitution
          .fromInterfaceType(receiverType)
          .substituteType(interfaceTarget.function.returnType);
      return Substitution
          .fromPairs(interfaceTarget.function.typeParameters, arguments.types)
          .substituteType(returnType);
    }
    if (name.name == 'call') {
      var receiverType = receiver.getStaticType(types);
      if (receiverType is FunctionType) {
        if (receiverType.typeParameters.length != arguments.types.length) {
          return const BottomType();
        }
        return Substitution
            .fromPairs(receiverType.typeParameters, arguments.types)
            .substituteType(receiverType.returnType);
      }
    }
    if (name.name == '==') {
      // We use this special case to simplify generation of '==' checks.
      return types.boolType;
    }
    return const DynamicType();
  }

  accept(ExpressionVisitor v) => v.visitMethodInvocation(this);

  visitChildren(Visitor v) {
    receiver?.accept(v);
    name?.accept(v);
    arguments?.accept(v);
  }

  transformChildren(Transformer v) {
    if (receiver != null) {
      receiver = receiver.accept(v);
      receiver?.parent = this;
    }
    if (arguments != null) {
      arguments = arguments.accept(v);
      arguments?.parent = this;
    }
  }
}

/// Expression of form `super.foo(x)`.
///
/// The provided arguments might not match the parameters of the target.
class SuperMethodInvocation extends InvocationExpression {
  Name name;
  Arguments arguments;

  Member interfaceTarget;

  SuperMethodInvocation(this.name, this.arguments, this.interfaceTarget) {
    arguments?.parent = this;
  }

  DartType getStaticType(TypeEnvironment types) {
    if (interfaceTarget == null) return const DynamicType();
    Class superclass = interfaceTarget.enclosingClass;
    var receiverType =
        types.hierarchy.getTypeAsInstanceOf(types.thisType, superclass);
    var returnType = Substitution
        .fromInterfaceType(receiverType)
        .substituteType(interfaceTarget.function.returnType);
    return Substitution
        .fromPairs(interfaceTarget.function.typeParameters, arguments.types)
        .substituteType(returnType);
  }

  accept(ExpressionVisitor v) => v.visitSuperMethodInvocation(this);

  visitChildren(Visitor v) {
    name?.accept(v);
    arguments?.accept(v);
  }

  transformChildren(Transformer v) {
    if (arguments != null) {
      arguments = arguments.accept(v);
      arguments?.parent = this;
    }
  }
}

/// Expression of form `foo(x)`, or `const foo(x)` if the target is an
/// external constant factory.
///
/// The provided arguments might not match the parameters of the target.
class StaticInvocation extends InvocationExpression {
  Procedure target;
  Arguments arguments;

  /// True if this is a constant call to an external constant factory.
  bool isConst;

  Name get name => target?.name;

  StaticInvocation(this.target, this.arguments, {this.isConst: false}) {
    arguments?.parent = this;
  }

  DartType getStaticType(TypeEnvironment types) {
    return Substitution
        .fromPairs(target.function.typeParameters, arguments.types)
        .substituteType(target.function.returnType);
  }

  accept(ExpressionVisitor v) => v.visitStaticInvocation(this);

  visitChildren(Visitor v) {
    target?.acceptReference(v);
    arguments?.accept(v);
  }

  transformChildren(Transformer v) {
    if (arguments != null) {
      arguments = arguments.accept(v);
      arguments?.parent = this;
    }
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
  Constructor target;
  Arguments arguments;
  bool isConst;

  Name get name => target?.name;

  ConstructorInvocation(this.target, this.arguments, {this.isConst: false}) {
    arguments?.parent = this;
  }

  DartType getStaticType(TypeEnvironment types) {
    return arguments.types.isEmpty
        ? target.enclosingClass.rawType
        : new InterfaceType(target.enclosingClass, arguments.types);
  }

  accept(ExpressionVisitor v) => v.visitConstructorInvocation(this);

  visitChildren(Visitor v) {
    target?.acceptReference(v);
    arguments?.accept(v);
  }

  transformChildren(Transformer v) {
    if (arguments != null) {
      arguments = arguments.accept(v);
      arguments?.parent = this;
    }
  }

  InterfaceType get constructedType {
    return arguments.types.isEmpty
        ? target.enclosingClass.rawType
        : new InterfaceType(target.enclosingClass, arguments.types);
  }
}

/// Expression of form `!x`.
///
/// The `is!` and `!=` operators are desugared into [Not] nodes with `is` and
/// `==` expressions inside, respectively.
class Not extends Expression {
  Expression operand;

  Not(this.operand) {
    operand?.parent = this;
  }

  DartType getStaticType(TypeEnvironment types) => types.boolType;

  accept(ExpressionVisitor v) => v.visitNot(this);

  visitChildren(Visitor v) {
    operand?.accept(v);
  }

  transformChildren(Transformer v) {
    if (operand != null) {
      operand = operand.accept(v);
      operand?.parent = this;
    }
  }
}

/// Expression of form `x && y` or `x || y`
class LogicalExpression extends Expression {
  Expression left;
  String operator; // && or || or ??
  Expression right;

  LogicalExpression(this.left, this.operator, this.right) {
    left?.parent = this;
    right?.parent = this;
  }

  DartType getStaticType(TypeEnvironment types) => types.boolType;

  accept(ExpressionVisitor v) => v.visitLogicalExpression(this);

  visitChildren(Visitor v) {
    left?.accept(v);
    right?.accept(v);
  }

  transformChildren(Transformer v) {
    if (left != null) {
      left = left.accept(v);
      left?.parent = this;
    }
    if (right != null) {
      right = right.accept(v);
      right?.parent = this;
    }
  }
}

/// Expression of form `x ? y : z`.
class ConditionalExpression extends Expression {
  Expression condition;
  Expression then;
  Expression otherwise;

  /// The static type of the expression. Should not be `null`.
  DartType staticType;

  ConditionalExpression(
      this.condition, this.then, this.otherwise, this.staticType) {
    condition?.parent = this;
    then?.parent = this;
    otherwise?.parent = this;
  }

  DartType getStaticType(TypeEnvironment types) => staticType;

  accept(ExpressionVisitor v) => v.visitConditionalExpression(this);

  visitChildren(Visitor v) {
    condition?.accept(v);
    then?.accept(v);
    otherwise?.accept(v);
    staticType?.accept(v);
  }

  transformChildren(Transformer v) {
    if (condition != null) {
      condition = condition.accept(v);
      condition?.parent = this;
    }
    if (then != null) {
      then = then.accept(v);
      then?.parent = this;
    }
    if (otherwise != null) {
      otherwise = otherwise.accept(v);
      otherwise?.parent = this;
    }
    if (staticType != null) {
      staticType = v.visitDartType(staticType);
    }
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

  DartType getStaticType(TypeEnvironment types) => types.stringType;

  accept(ExpressionVisitor v) => v.visitStringConcatenation(this);

  visitChildren(Visitor v) {
    visitList(expressions, v);
  }

  transformChildren(Transformer v) {
    transformList(expressions, v, this);
  }
}

/// Expression of form `x is T`.
class IsExpression extends Expression {
  Expression operand;
  DartType type;

  IsExpression(this.operand, this.type) {
    operand?.parent = this;
  }

  DartType getStaticType(TypeEnvironment types) => types.boolType;

  accept(ExpressionVisitor v) => v.visitIsExpression(this);

  visitChildren(Visitor v) {
    operand?.accept(v);
    type?.accept(v);
  }

  transformChildren(Transformer v) {
    if (operand != null) {
      operand = operand.accept(v);
      operand?.parent = this;
    }
    type = v.visitDartType(type);
  }
}

/// Expression of form `x as T`.
class AsExpression extends Expression {
  Expression operand;
  DartType type;

  AsExpression(this.operand, this.type) {
    operand?.parent = this;
  }

  DartType getStaticType(TypeEnvironment types) => type;

  accept(ExpressionVisitor v) => v.visitAsExpression(this);

  visitChildren(Visitor v) {
    operand?.accept(v);
    type?.accept(v);
  }

  transformChildren(Transformer v) {
    if (operand != null) {
      operand = operand.accept(v);
      operand?.parent = this;
    }
    type = v.visitDartType(type);
  }
}

/// An integer, double, boolean, string, or null constant.
abstract class BasicLiteral extends Expression {
  Object get value;

  visitChildren(Visitor v) {}
  transformChildren(Transformer v) {}
}

class StringLiteral extends BasicLiteral {
  String value;

  StringLiteral(this.value);

  DartType getStaticType(TypeEnvironment types) => types.stringType;

  accept(ExpressionVisitor v) => v.visitStringLiteral(this);
}

class IntLiteral extends BasicLiteral {
  int value;

  IntLiteral(this.value);

  DartType getStaticType(TypeEnvironment types) => types.intType;

  accept(ExpressionVisitor v) => v.visitIntLiteral(this);
}

class DoubleLiteral extends BasicLiteral {
  double value;

  DoubleLiteral(this.value);

  DartType getStaticType(TypeEnvironment types) => types.doubleType;

  accept(ExpressionVisitor v) => v.visitDoubleLiteral(this);
}

class BoolLiteral extends BasicLiteral {
  bool value;

  BoolLiteral(this.value);

  DartType getStaticType(TypeEnvironment types) => types.boolType;

  accept(ExpressionVisitor v) => v.visitBoolLiteral(this);
}

class NullLiteral extends BasicLiteral {
  Object get value => null;

  DartType getStaticType(TypeEnvironment types) => const BottomType();

  accept(ExpressionVisitor v) => v.visitNullLiteral(this);
}

class SymbolLiteral extends Expression {
  String value; // Everything strictly after the '#'.

  SymbolLiteral(this.value);

  DartType getStaticType(TypeEnvironment types) => types.symbolType;

  accept(ExpressionVisitor v) => v.visitSymbolLiteral(this);

  visitChildren(Visitor v) {}
  transformChildren(Transformer v) {}
}

class TypeLiteral extends Expression {
  DartType type;

  TypeLiteral(this.type);

  DartType getStaticType(TypeEnvironment types) => types.typeType;

  accept(ExpressionVisitor v) => v.visitTypeLiteral(this);

  visitChildren(Visitor v) {
    type?.accept(v);
  }

  transformChildren(Transformer v) {
    type = v.visitDartType(type);
  }
}

class ThisExpression extends Expression {
  DartType getStaticType(TypeEnvironment types) => types.thisType;

  accept(ExpressionVisitor v) => v.visitThisExpression(this);

  visitChildren(Visitor v) {}
  transformChildren(Transformer v) {}
}

class Rethrow extends Expression {
  DartType getStaticType(TypeEnvironment types) => const BottomType();

  accept(ExpressionVisitor v) => v.visitRethrow(this);

  visitChildren(Visitor v) {}
  transformChildren(Transformer v) {}
}

class Throw extends Expression {
  Expression expression;

  Throw(this.expression) {
    expression?.parent = this;
  }

  DartType getStaticType(TypeEnvironment types) => const BottomType();

  accept(ExpressionVisitor v) => v.visitThrow(this);

  visitChildren(Visitor v) {
    expression?.accept(v);
  }

  transformChildren(Transformer v) {
    if (expression != null) {
      expression = expression.accept(v);
      expression?.parent = this;
    }
  }
}

class ListLiteral extends Expression {
  bool isConst;
  DartType typeArgument; // Not null, defaults to DynamicType.
  final List<Expression> expressions;

  ListLiteral(this.expressions,
      {this.typeArgument: const DynamicType(), this.isConst: false}) {
    assert(typeArgument != null);
    setParents(expressions, this);
  }

  DartType getStaticType(TypeEnvironment types) {
    return types.literalListType(typeArgument);
  }

  accept(ExpressionVisitor v) => v.visitListLiteral(this);

  visitChildren(Visitor v) {
    typeArgument?.accept(v);
    visitList(expressions, v);
  }

  transformChildren(Transformer v) {
    typeArgument = v.visitDartType(typeArgument);
    transformList(expressions, v, this);
  }
}

class MapLiteral extends Expression {
  bool isConst;
  DartType keyType; // Not null, defaults to DynamicType.
  DartType valueType; // Not null, defaults to DynamicType.
  final List<MapEntry> entries;

  MapLiteral(this.entries,
      {this.keyType: const DynamicType(),
      this.valueType: const DynamicType(),
      this.isConst: false}) {
    assert(keyType != null);
    assert(valueType != null);
    setParents(entries, this);
  }

  DartType getStaticType(TypeEnvironment types) {
    return types.literalMapType(keyType, valueType);
  }

  accept(ExpressionVisitor v) => v.visitMapLiteral(this);

  visitChildren(Visitor v) {
    keyType?.accept(v);
    valueType?.accept(v);
    visitList(entries, v);
  }

  transformChildren(Transformer v) {
    keyType = v.visitDartType(keyType);
    valueType = v.visitDartType(valueType);
    transformList(entries, v, this);
  }
}

class MapEntry extends TreeNode {
  Expression key;
  Expression value;

  MapEntry(this.key, this.value) {
    key?.parent = this;
    value?.parent = this;
  }

  accept(TreeVisitor v) => v.visitMapEntry(this);

  visitChildren(Visitor v) {
    key?.accept(v);
    value?.accept(v);
  }

  transformChildren(Transformer v) {
    if (key != null) {
      key = key.accept(v);
      key?.parent = this;
    }
    if (value != null) {
      value = value.accept(v);
      value?.parent = this;
    }
  }
}

/// Expression of form `await x`.
class AwaitExpression extends Expression {
  Expression operand;

  AwaitExpression(this.operand) {
    operand?.parent = this;
  }

  DartType getStaticType(TypeEnvironment types) {
    return types.unfutureType(operand.getStaticType(types));
  }

  accept(ExpressionVisitor v) => v.visitAwaitExpression(this);

  visitChildren(Visitor v) {
    operand?.accept(v);
  }

  transformChildren(Transformer v) {
    if (operand != null) {
      operand = operand.accept(v);
      operand?.parent = this;
    }
  }
}

/// Expression of form `(x,y) => ...` or `(x,y) { ... }`
///
/// The arrow-body form `=> e` is desugared into `return e;`.
class FunctionExpression extends Expression {
  FunctionNode function;

  FunctionExpression(this.function) {
    function?.parent = this;
  }

  DartType getStaticType(TypeEnvironment types) => function.functionType;

  accept(ExpressionVisitor v) => v.visitFunctionExpression(this);

  visitChildren(Visitor v) {
    function?.accept(v);
  }

  transformChildren(Transformer v) {
    if (function != null) {
      function = function.accept(v);
      function?.parent = this;
    }
  }
}

/// Synthetic expression of form `let v = x in y`
class Let extends Expression {
  VariableDeclaration variable; // Must have an initializer.
  Expression body;

  Let(this.variable, this.body) {
    variable?.parent = this;
    body?.parent = this;
  }

  DartType getStaticType(TypeEnvironment types) => body.getStaticType(types);

  accept(ExpressionVisitor v) => v.visitLet(this);

  visitChildren(Visitor v) {
    variable?.accept(v);
    body?.accept(v);
  }

  transformChildren(Transformer v) {
    if (variable != null) {
      variable = variable.accept(v);
      variable?.parent = this;
    }
    if (body != null) {
      body = body.accept(v);
      body?.parent = this;
    }
  }
}

// ------------------------------------------------------------------------
//                              STATEMENTS
// ------------------------------------------------------------------------

abstract class Statement extends TreeNode {
  accept(StatementVisitor v);
}

/// A statement with a compile-time error.
///
/// Should throw an exception at runtime.
class InvalidStatement extends Statement {
  accept(StatementVisitor v) => v.visitInvalidStatement(this);

  visitChildren(Visitor v) {}
  transformChildren(Transformer v) {}
}

class ExpressionStatement extends Statement {
  Expression expression;

  ExpressionStatement(this.expression) {
    expression?.parent = this;
  }

  accept(StatementVisitor v) => v.visitExpressionStatement(this);

  visitChildren(Visitor v) {
    expression?.accept(v);
  }

  transformChildren(Transformer v) {
    if (expression != null) {
      expression = expression.accept(v);
      expression?.parent = this;
    }
  }
}

class Block extends Statement {
  final List<Statement> statements;

  Block(this.statements) {
    setParents(statements, this);
  }

  accept(StatementVisitor v) => v.visitBlock(this);

  visitChildren(Visitor v) {
    visitList(statements, v);
  }

  transformChildren(Transformer v) {
    transformList(statements, v, this);
  }

  void addStatement(Statement node) {
    statements.add(node);
    node.parent = this;
  }
}

class EmptyStatement extends Statement {
  accept(StatementVisitor v) => v.visitEmptyStatement(this);

  visitChildren(Visitor v) {}
  transformChildren(Transformer v) {}
}

class AssertStatement extends Statement {
  Expression condition;
  Expression message; // May be null.

  AssertStatement(this.condition, [this.message]) {
    condition?.parent = this;
    message?.parent = this;
  }

  accept(StatementVisitor v) => v.visitAssertStatement(this);

  visitChildren(Visitor v) {
    condition?.accept(v);
    message?.accept(v);
  }

  transformChildren(Transformer v) {
    if (condition != null) {
      condition = condition.accept(v);
      condition?.parent = this;
    }
    if (message != null) {
      message = message.accept(v);
      message?.parent = this;
    }
  }
}

/// A target of a [Break] statement.
///
/// The label itself has no name; breaks reference the statement directly.
///
/// The frontend does not generate labeled statements without uses.
class LabeledStatement extends Statement {
  Statement body;

  LabeledStatement(this.body) {
    body?.parent = this;
  }

  accept(StatementVisitor v) => v.visitLabeledStatement(this);

  visitChildren(Visitor v) {
    body?.accept(v);
  }

  transformChildren(Transformer v) {
    if (body != null) {
      body = body.accept(v);
      body?.parent = this;
    }
  }
}

/// Breaks out of an enclosing [LabeledStatement].
///
/// Both `break` and loop `continue` statements are translated into this node.
///
/// For example, the following loop with a `continue` will be desugared:
///
///     while(x) {
///       if (y) continue;
///       BODY'
///     }
///
///     ==>
///
///     while(x) {
///       L: {
///         if (y) break L;
///         BODY'
///       }
///     }
//
class BreakStatement extends Statement {
  LabeledStatement target;

  BreakStatement(this.target);

  accept(StatementVisitor v) => v.visitBreakStatement(this);

  visitChildren(Visitor v) {}
  transformChildren(Transformer v) {}
}

class WhileStatement extends Statement {
  Expression condition;
  Statement body;

  WhileStatement(this.condition, this.body) {
    condition?.parent = this;
    body?.parent = this;
  }

  accept(StatementVisitor v) => v.visitWhileStatement(this);

  visitChildren(Visitor v) {
    condition?.accept(v);
    body?.accept(v);
  }

  transformChildren(Transformer v) {
    if (condition != null) {
      condition = condition.accept(v);
      condition?.parent = this;
    }
    if (body != null) {
      body = body.accept(v);
      body?.parent = this;
    }
  }
}

class DoStatement extends Statement {
  Statement body;
  Expression condition;

  DoStatement(this.body, this.condition) {
    body?.parent = this;
    condition?.parent = this;
  }

  accept(StatementVisitor v) => v.visitDoStatement(this);

  visitChildren(Visitor v) {
    body?.accept(v);
    condition?.accept(v);
  }

  transformChildren(Transformer v) {
    if (body != null) {
      body = body.accept(v);
      body?.parent = this;
    }
    if (condition != null) {
      condition = condition.accept(v);
      condition?.parent = this;
    }
  }
}

class ForStatement extends Statement {
  final List<VariableDeclaration> variables; // May be empty, but not null.
  Expression condition; // May be null.
  final List<Expression> updates; // May be empty, but not null.
  Statement body;

  ForStatement(this.variables, this.condition, this.updates, this.body) {
    setParents(variables, this);
    condition?.parent = this;
    setParents(updates, this);
    body?.parent = this;
  }

  accept(StatementVisitor v) => v.visitForStatement(this);

  visitChildren(Visitor v) {
    visitList(variables, v);
    condition?.accept(v);
    visitList(updates, v);
    body?.accept(v);
  }

  transformChildren(Transformer v) {
    transformList(variables, v, this);
    if (condition != null) {
      condition = condition.accept(v);
      condition?.parent = this;
    }
    transformList(updates, v, this);
    if (body != null) {
      body = body.accept(v);
      body?.parent = this;
    }
  }
}

class ForInStatement extends Statement {
  VariableDeclaration variable; // Has no initializer.
  Expression iterable;
  Statement body;
  bool isAsync; // True if this is an 'await for' loop.

  ForInStatement(this.variable, this.iterable, this.body,
      {this.isAsync: false}) {
    variable?.parent = this;
    iterable?.parent = this;
    body?.parent = this;
  }

  accept(StatementVisitor v) => v.visitForInStatement(this);

  visitChildren(Visitor v) {
    variable?.accept(v);
    iterable?.accept(v);
    body?.accept(v);
  }

  transformChildren(Transformer v) {
    if (variable != null) {
      variable = variable.accept(v);
      variable?.parent = this;
    }
    if (iterable != null) {
      iterable = iterable.accept(v);
      iterable?.parent = this;
    }
    if (body != null) {
      body = body.accept(v);
      body?.parent = this;
    }
  }
}

/// Statement of form `switch (e) { case x: ... }`.
///
/// Adjacent case clauses have been merged into a single [SwitchCase]. A runtime
/// exception must be thrown if one [SwitchCase] falls through to another case.
class SwitchStatement extends Statement {
  Expression expression;
  final List<SwitchCase> cases;

  SwitchStatement(this.expression, this.cases) {
    expression?.parent = this;
    setParents(cases, this);
  }

  accept(StatementVisitor v) => v.visitSwitchStatement(this);

  visitChildren(Visitor v) {
    expression?.accept(v);
    visitList(cases, v);
  }

  transformChildren(Transformer v) {
    if (expression != null) {
      expression = expression.accept(v);
      expression?.parent = this;
    }
    transformList(cases, v, this);
  }
}

/// A group of `case` clauses and/or a `default` clause.
///
/// This is a potential target of [ContinueSwitchStatement].
class SwitchCase extends TreeNode {
  final List<Expression> expressions;
  Statement body;
  bool isDefault;

  SwitchCase(this.expressions, this.body, {this.isDefault: false}) {
    setParents(expressions, this);
    body?.parent = this;
  }

  SwitchCase.defaultCase(this.body)
      : isDefault = true,
        expressions = <Expression>[] {
    body?.parent = this;
  }

  SwitchCase.empty()
      : expressions = <Expression>[],
        body = null,
        isDefault = false;

  accept(TreeVisitor v) => v.visitSwitchCase(this);

  visitChildren(Visitor v) {
    visitList(expressions, v);
    body?.accept(v);
  }

  transformChildren(Transformer v) {
    transformList(expressions, v, this);
    if (body != null) {
      body = body.accept(v);
      body?.parent = this;
    }
  }
}

/// Jump to a case in an enclosing switch.
class ContinueSwitchStatement extends Statement {
  SwitchCase target;

  ContinueSwitchStatement(this.target);

  accept(StatementVisitor v) => v.visitContinueSwitchStatement(this);

  visitChildren(Visitor v) {}
  transformChildren(Transformer v) {}
}

class IfStatement extends Statement {
  Expression condition;
  Statement then;
  Statement otherwise;

  IfStatement(this.condition, this.then, this.otherwise) {
    condition?.parent = this;
    then?.parent = this;
    otherwise?.parent = this;
  }

  accept(StatementVisitor v) => v.visitIfStatement(this);

  visitChildren(Visitor v) {
    condition?.accept(v);
    then?.accept(v);
    otherwise?.accept(v);
  }

  transformChildren(Transformer v) {
    if (condition != null) {
      condition = condition.accept(v);
      condition?.parent = this;
    }
    if (then != null) {
      then = then.accept(v);
      then?.parent = this;
    }
    if (otherwise != null) {
      otherwise = otherwise.accept(v);
      otherwise?.parent = this;
    }
  }
}

class ReturnStatement extends Statement {
  Expression expression; // May be null.

  ReturnStatement([this.expression]) {
    expression?.parent = this;
  }

  accept(StatementVisitor v) => v.visitReturnStatement(this);

  visitChildren(Visitor v) {
    expression?.accept(v);
  }

  transformChildren(Transformer v) {
    if (expression != null) {
      expression = expression.accept(v);
      expression?.parent = this;
    }
  }
}

class TryCatch extends Statement {
  Statement body;
  List<Catch> catches;

  TryCatch(this.body, this.catches) {
    body?.parent = this;
    setParents(catches, this);
  }

  accept(StatementVisitor v) => v.visitTryCatch(this);

  visitChildren(Visitor v) {
    body?.accept(v);
    visitList(catches, v);
  }

  transformChildren(Transformer v) {
    if (body != null) {
      body = body.accept(v);
      body?.parent = this;
    }
    transformList(catches, v, this);
  }
}

class Catch extends TreeNode {
  DartType guard; // Not null, defaults to dynamic.
  VariableDeclaration exception; // May be null.
  VariableDeclaration stackTrace; // May be null.
  Statement body;

  Catch(this.exception, this.body,
      {this.guard: const DynamicType(), this.stackTrace}) {
    assert(guard != null);
    exception?.parent = this;
    stackTrace?.parent = this;
    body?.parent = this;
  }

  accept(TreeVisitor v) => v.visitCatch(this);

  visitChildren(Visitor v) {
    guard?.accept(v);
    exception?.accept(v);
    stackTrace?.accept(v);
    body?.accept(v);
  }

  transformChildren(Transformer v) {
    guard = v.visitDartType(guard);
    if (exception != null) {
      exception = exception.accept(v);
      exception?.parent = this;
    }
    if (stackTrace != null) {
      stackTrace = stackTrace.accept(v);
      stackTrace?.parent = this;
    }
    if (body != null) {
      body = body.accept(v);
      body?.parent = this;
    }
  }
}

class TryFinally extends Statement {
  Statement body;
  Statement finalizer;

  TryFinally(this.body, this.finalizer) {
    body?.parent = this;
    finalizer?.parent = this;
  }

  accept(StatementVisitor v) => v.visitTryFinally(this);

  visitChildren(Visitor v) {
    body?.accept(v);
    finalizer?.accept(v);
  }

  transformChildren(Transformer v) {
    if (body != null) {
      body = body.accept(v);
      body?.parent = this;
    }
    if (finalizer != null) {
      finalizer = finalizer.accept(v);
      finalizer?.parent = this;
    }
  }
}

/// Statement of form `yield x` or `yield* x`.
///
/// For native yield semantics see `AsyncMarker.SyncYielding`.
class YieldStatement extends Statement {
  Expression expression;
  int flags = 0;

  YieldStatement(this.expression,
      {bool isYieldStar: false, bool isNative: false}) {
    expression?.parent = this;
    this.isYieldStar = isYieldStar;
    this.isNative = isNative;
  }

  static const int FlagYieldStar = 1 << 0;
  static const int FlagNative = 1 << 1;

  bool get isYieldStar => flags & FlagYieldStar != 0;
  bool get isNative => flags & FlagNative != 0;

  void set isYieldStar(bool value) {
    flags = value ? (flags | FlagYieldStar) : (flags & ~FlagYieldStar);
  }

  void set isNative(bool value) {
    flags = value ? (flags | FlagNative) : (flags & ~FlagNative);
  }

  accept(StatementVisitor v) => v.visitYieldStatement(this);

  visitChildren(Visitor v) {
    expression?.accept(v);
  }

  transformChildren(Transformer v) {
    if (expression != null) {
      expression = expression.accept(v);
      expression?.parent = this;
    }
  }
}

/// Declaration of a local variable.
///
/// This may occur as a statement, but is also used in several non-statement
/// contexts, such as in [ForStatement], [Catch], and [FunctionNode].
///
/// When this occurs as a statement, it must be a direct child of a [Block].
//
// DESIGN TODO: Should we remove the 'final' modifier from variables?
class VariableDeclaration extends Statement
    implements Comparable<VariableDeclaration> {
  /// For named parameters, this is the name of the parameter. No two named
  /// parameters (in the same parameter list) can have the same name.
  ///
  /// In all other cases, the name is cosmetic, may be empty or null,
  /// and is not necessarily unique.
  String name;
  int flags = 0;
  DartType type; // Not null, defaults to dynamic.
  InferredValue inferredValue; // May be null.

  /// For locals, this is the initial value.
  /// For parameters, this is the default value.
  ///
  /// Should be null in other cases.
  Expression initializer; // May be null.

  VariableDeclaration(this.name,
      {this.initializer,
      this.type: const DynamicType(),
      this.inferredValue,
      bool isFinal: false,
      bool isConst: false}) {
    assert(type != null);
    initializer?.parent = this;
    this.isFinal = isFinal;
    this.isConst = isConst;
  }

  /// Creates a synthetic variable with the given expression as initializer.
  VariableDeclaration.forValue(this.initializer,
      {bool isFinal: true,
      bool isConst: false,
      this.type: const DynamicType()}) {
    assert(type != null);
    initializer?.parent = this;
    this.isFinal = isFinal;
    this.isConst = isConst;
  }

  static const int FlagFinal = 1 << 0; // Must match serialized bit positions.
  static const int FlagConst = 1 << 1;

  bool get isFinal => flags & FlagFinal != 0;
  bool get isConst => flags & FlagConst != 0;

  void set isFinal(bool value) {
    flags = value ? (flags | FlagFinal) : (flags & ~FlagFinal);
  }

  void set isConst(bool value) {
    flags = value ? (flags | FlagConst) : (flags & ~FlagConst);
  }

  accept(StatementVisitor v) => v.visitVariableDeclaration(this);

  visitChildren(Visitor v) {
    type?.accept(v);
    inferredValue?.accept(v);
    initializer?.accept(v);
  }

  transformChildren(Transformer v) {
    type = v.visitDartType(type);
    if (initializer != null) {
      initializer = initializer.accept(v);
      initializer?.parent = this;
    }
  }

  /// Returns a possibly synthesized name for this variable, consistent with
  /// the names used across all [toString] calls.
  String toString() => debugVariableDeclarationName(this);

  int compareTo(VariableDeclaration other) {
    return name.compareTo(other.name);
  }
}

/// Declaration a local function.
///
/// The body of the function may use [variable] as its self-reference.
class FunctionDeclaration extends Statement {
  VariableDeclaration variable; // Is final and has no initializer.
  FunctionNode function;

  FunctionDeclaration(this.variable, this.function) {
    variable?.parent = this;
    function?.parent = this;
  }

  accept(StatementVisitor v) => v.visitFunctionDeclaration(this);

  visitChildren(Visitor v) {
    variable?.accept(v);
    function?.accept(v);
  }

  transformChildren(Transformer v) {
    if (variable != null) {
      variable = variable.accept(v);
      variable?.parent = this;
    }
    if (function != null) {
      function = function.accept(v);
      function?.parent = this;
    }
  }
}

// ------------------------------------------------------------------------
//                                NAMES
// ------------------------------------------------------------------------

/// A public name, or a private name qualified by a library.
///
/// Names are only used for expressions with dynamic dispatch, as all
/// statically resolved references are represented in nameless form.
///
/// [Name]s are immutable and compare based on structural equality, and they
/// are not AST nodes.
///
/// The [toString] method returns a human-readable string that includes the
/// library name for private names; uniqueness is not guaranteed.
abstract class Name implements Node {
  final int hashCode;
  final String name;
  Library get library;
  bool get isPrivate;

  Name._internal(this.hashCode, this.name);

  factory Name(String name, [Library library]) {
    /// Use separate subclasses for the public and private case to save memory
    /// for public names.
    if (name.startsWith('_')) {
      assert(library != null);
      return new _PrivateName(name, library);
    } else {
      return new _PublicName(name);
    }
  }

  bool operator ==(other) {
    return other is Name && name == other.name && library == other.library;
  }

  accept(Visitor v) => v.visitName(this);

  visitChildren(Visitor v) {
    // DESIGN TODO: Should we visit the library as a library reference?
  }
}

class _PrivateName extends Name {
  final Library library;
  bool get isPrivate => true;

  _PrivateName(String name, Library library)
      : this.library = library,
        super._internal(_computeHashCode(name, library), name);

  String toString() => library != null ? '$library::$name' : name;

  static int _computeHashCode(String name, Library library) {
    return 131 * name.hashCode + 17 * library.hashCode;
  }
}

class _PublicName extends Name {
  Library get library => null;
  bool get isPrivate => false;

  _PublicName(String name) : super._internal(name.hashCode, name);

  String toString() => name;
}

// ------------------------------------------------------------------------
//                             TYPES
// ------------------------------------------------------------------------

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
abstract class DartType extends Node {
  const DartType();

  accept(DartTypeVisitor v);

  bool operator ==(Object other);
}

/// The type arising from invalid type annotations.
///
/// Can usually be treated as 'dynamic', but should occasionally be handled
/// differently, e.g. `x is ERROR` should evaluate to false.
class InvalidType extends DartType {
  final int hashCode = 12345;

  const InvalidType();

  accept(DartTypeVisitor v) => v.visitInvalidType(this);
  visitChildren(Visitor v) {}

  bool operator ==(Object other) => other is InvalidType;
}

class DynamicType extends DartType {
  final int hashCode = 54321;

  const DynamicType();

  accept(DartTypeVisitor v) => v.visitDynamicType(this);
  visitChildren(Visitor v) {}

  bool operator ==(Object other) => other is DynamicType;
}

class VoidType extends DartType {
  final int hashCode = 123121;

  const VoidType();

  accept(DartTypeVisitor v) => v.visitVoidType(this);
  visitChildren(Visitor v) {}

  bool operator ==(Object other) => other is VoidType;
}

class BottomType extends DartType {
  final int hashCode = 514213;

  const BottomType();

  accept(DartTypeVisitor v) => v.visitBottomType(this);
  visitChildren(Visitor v) {}

  bool operator ==(Object other) => other is BottomType;
}

class InterfaceType extends DartType {
  final Class classNode;
  final List<DartType> typeArguments;

  /// The [typeArguments] list must not be modified after this call. If the
  /// list is omitted, 'dynamic' type arguments are filled in.
  InterfaceType(Class classNode, [List<DartType> typeArguments])
      : this.classNode = classNode,
        this.typeArguments = typeArguments ?? _defaultTypeArguments(classNode);

  static List<DartType> _defaultTypeArguments(Class classNode) {
    if (classNode.typeParameters.length == 0) {
      // Avoid allocating a list in this very common case.
      return const <DartType>[];
    } else {
      return new List<DartType>.filled(
          classNode.typeParameters.length, const DynamicType());
    }
  }

  accept(DartTypeVisitor v) => v.visitInterfaceType(this);

  visitChildren(Visitor v) {
    classNode.acceptReference(v);
    visitList(typeArguments, v);
  }

  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is InterfaceType) {
      if (classNode != other.classNode) return false;
      if (typeArguments.length != other.typeArguments.length) return false;
      for (int i = 0; i < typeArguments.length; ++i) {
        if (typeArguments[i] != other.typeArguments[i]) return false;
      }
      return true;
    } else {
      return false;
    }
  }

  int get hashCode {
    int hash = 0x3fffffff & classNode.hashCode;
    for (int i = 0; i < typeArguments.length; ++i) {
      hash = 0x3fffffff & (hash * 31 + (hash ^ typeArguments[i].hashCode));
    }
    return hash;
  }
}

/// A possibly generic function type.
class FunctionType extends DartType {
  final List<TypeParameter> typeParameters;
  final int requiredParameterCount;
  final List<DartType> positionalParameters;
  final List<NamedType> namedParameters; // Must be sorted.
  final DartType returnType;
  int _hashCode;

  FunctionType(List<DartType> positionalParameters, this.returnType,
      {this.namedParameters: const <NamedType>[],
      this.typeParameters: const <TypeParameter>[],
      int requiredParameterCount})
      : this.positionalParameters = positionalParameters,
        this.requiredParameterCount =
            requiredParameterCount ?? positionalParameters.length;

  accept(DartTypeVisitor v) => v.visitFunctionType(this);

  visitChildren(Visitor v) {
    visitList(typeParameters, v);
    visitList(positionalParameters, v);
    visitList(namedParameters, v);
    returnType.accept(v);
  }

  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is FunctionType) {
      if (typeParameters.length != other.typeParameters.length ||
          requiredParameterCount != other.requiredParameterCount ||
          positionalParameters.length != other.positionalParameters.length ||
          namedParameters.length != other.namedParameters.length) {
        return false;
      }
      if (typeParameters.isEmpty) {
        for (int i = 0; i < positionalParameters.length; ++i) {
          if (positionalParameters[i] != other.positionalParameters[i]) {
            return false;
          }
        }
        for (int i = 0; i < namedParameters.length; ++i) {
          if (namedParameters[i] != other.namedParameters[i]) {
            return false;
          }
        }
        return returnType == other.returnType;
      } else {
        // Structural equality does not tell us if two generic function types
        // are the same type.  If they are unifiable without substituting any
        // type variables, they are equal.
        return unifyTypes(this, other, new Set<TypeParameter>()) != null;
      }
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
    return new FunctionType(positionalParameters, returnType,
        requiredParameterCount: requiredParameterCount,
        namedParameters: namedParameters);
  }

  int get hashCode => _hashCode ??= _computeHashCode();

  int _computeHashCode() {
    int hash = 1237;
    hash = 0x3fffffff & (hash * 31 + requiredParameterCount);
    for (int i = 0; i < typeParameters.length; ++i) {
      TypeParameter parameter = typeParameters[i];
      _temporaryHashCodeTable[parameter] = _temporaryHashCodeTable.length;
      hash = 0x3fffffff & (hash * 31 + parameter.bound.hashCode);
    }
    for (int i = 0; i < positionalParameters.length; ++i) {
      hash = 0x3fffffff & (hash * 31 + positionalParameters[i].hashCode);
    }
    for (int i = 0; i < namedParameters.length; ++i) {
      hash = 0x3fffffff & (hash * 31 + namedParameters[i].hashCode);
    }
    hash = 0x3fffffff & (hash * 31 + returnType.hashCode);
    for (int i = 0; i < typeParameters.length; ++i) {
      // Remove the type parameters from the scope again.
      _temporaryHashCodeTable.remove(typeParameters[i]);
    }
    return hash;
  }
}

/// A named parameter in [FunctionType].
class NamedType extends Node implements Comparable<NamedType> {
  final String name;
  final DartType type;

  NamedType(this.name, this.type);

  bool operator ==(Object other) {
    return other is NamedType && name == other.name && type == other.type;
  }

  int get hashCode {
    return name.hashCode * 31 + type.hashCode * 37;
  }

  int compareTo(NamedType other) => name.compareTo(other.name);

  accept(Visitor v) => v.visitNamedType(this);

  void visitChildren(Visitor v) {
    type.accept(v);
  }
}

/// Stores the hash code of function type parameters while computing the hash
/// code of a [FunctionType] object.
///
/// This ensures that distinct [FunctionType] objects get the same hash code
/// if they represent the same type, even though their type parameters are
/// represented by different objects.
final Map<TypeParameter, int> _temporaryHashCodeTable = <TypeParameter, int>{};

/// Reference to a type variable.
class TypeParameterType extends DartType {
  TypeParameter parameter;

  TypeParameterType(this.parameter);

  accept(DartTypeVisitor v) => v.visitTypeParameterType(this);

  visitChildren(Visitor v) {}

  bool operator ==(Object other) {
    return other is TypeParameterType && parameter == other.parameter;
  }

  int get hashCode => _temporaryHashCodeTable[parameter] ?? parameter.hashCode;
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
class TypeParameter extends TreeNode {
  String name; // Cosmetic name.

  /// The bound on the type variable.
  ///
  /// Should not be null except temporarily during IR construction.  Should
  /// be set to the root class for type parameters without an explicit bound.
  DartType bound;

  TypeParameter([this.name, this.bound]);

  accept(TreeVisitor v) => v.visitTypeParameter(this);

  visitChildren(Visitor v) {
    bound.accept(v);
  }

  transformChildren(Transformer v) {
    bound = v.visitDartType(bound);
  }

  /// Returns a possibly synthesized name for this type parameter, consistent
  /// with the names used across all [toString] calls.
  String toString() => debugQualifiedTypeParameterName(this);
}

class Supertype extends Node {
  final Class classNode;
  final List<DartType> typeArguments;

  Supertype(this.classNode, this.typeArguments);

  accept(Visitor v) => v.visitSupertype(this);

  visitChildren(Visitor v) {
    classNode.acceptReference(v);
    visitList(typeArguments, v);
  }

  InterfaceType get asInterfaceType {
    return new InterfaceType(classNode, typeArguments);
  }

  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is Supertype) {
      if (classNode != other.classNode) return false;
      if (typeArguments.length != other.typeArguments.length) return false;
      for (int i = 0; i < typeArguments.length; ++i) {
        if (typeArguments[i] != other.typeArguments[i]) return false;
      }
      return true;
    } else {
      return false;
    }
  }

  int get hashCode {
    int hash = 0x3fffffff & classNode.hashCode;
    for (int i = 0; i < typeArguments.length; ++i) {
      hash = 0x3fffffff & (hash * 31 + (hash ^ typeArguments[i].hashCode));
    }
    return hash;
  }
}

// ------------------------------------------------------------------------
//                                PROGRAM
// ------------------------------------------------------------------------

/// A way to bundle up all the libraries in a program.
class Program extends TreeNode {
  final List<Library> libraries;

  /// Map from a source file uri to a line-starts table.
  /// Given a source file uri and a offset in that file one can translate
  /// it to a line:column position in that file.
  final Map<String, List<int>> uriToLineStarts;

  /// Reference to the main method in one of the libraries.
  Procedure mainMethod;

  Program([List<Library> libraries, Map<String, List<int>> uriToLineStarts])
      : libraries = libraries ?? <Library>[],
        uriToLineStarts = uriToLineStarts ?? {} {
    setParents(libraries, this);
  }

  accept(TreeVisitor v) => v.visitProgram(this);

  visitChildren(Visitor v) {
    visitList(libraries, v);
    mainMethod?.acceptReference(v);
  }

  transformChildren(Transformer v) {
    transformList(libraries, v, this);
  }

  Program get enclosingProgram => this;

  /// Translates an offset to line and column numbers in the given file.
  Location getLocation(String file, int offset) {
    List<int> lines = uriToLineStarts[file];
    int low = 0, high = lines.length - 1;
    while (low < high) {
      int mid = high - ((high - low) >> 1); // Get middle, rounding up.
      int pivot = lines[mid];
      if (pivot <= offset) {
        low = mid;
      } else {
        high = mid - 1;
      }
    }
    int lineIndex = low;
    int lineStart = lines[lineIndex];
    int lineNumber = 1 + lineIndex;
    int columnNumber = offset - lineStart;
    return new Location(file, lineNumber, columnNumber);
  }
}

/// A tuple with file, line, and column number, for displaying human-readable
/// locations.
class Location {
  final String file;
  final int line; // 1-based.
  final int column; // 1-based.

  Location(this.file, this.line, this.column);

  String toString() => '$file:$line:$column';
}

// ------------------------------------------------------------------------
//                             INTERNAL FUNCTIONS
// ------------------------------------------------------------------------

void setParents(List<TreeNode> nodes, TreeNode parent) {
  for (int i = 0; i < nodes.length; ++i) {
    nodes[i].parent = parent;
  }
}

void visitList(List<Node> nodes, Visitor visitor) {
  for (int i = 0; i < nodes.length; ++i) {
    nodes[i].accept(visitor);
  }
}

void visitIterable(Iterable<Node> nodes, Visitor visitor) {
  for (var node in nodes) {
    node.accept(visitor);
  }
}

void transformTypeList(List<DartType> nodes, Transformer visitor) {
  int storeIndex = 0;
  for (int i = 0; i < nodes.length; ++i) {
    var result = visitor.visitDartType(nodes[i]);
    if (result != null) {
      nodes[storeIndex] = result;
      ++storeIndex;
    }
  }
  if (storeIndex < nodes.length) {
    nodes.length = storeIndex;
  }
}

void transformSupertypeList(List<Supertype> nodes, Transformer visitor) {
  int storeIndex = 0;
  for (int i = 0; i < nodes.length; ++i) {
    var result = visitor.visitSupertype(nodes[i]);
    if (result != null) {
      nodes[storeIndex] = result;
      ++storeIndex;
    }
  }
  if (storeIndex < nodes.length) {
    nodes.length = storeIndex;
  }
}

void transformList(List<TreeNode> nodes, Transformer visitor, TreeNode parent) {
  int storeIndex = 0;
  for (int i = 0; i < nodes.length; ++i) {
    var result = nodes[i].accept(visitor);
    if (result != null) {
      nodes[storeIndex] = result;
      result.parent = parent;
      ++storeIndex;
    }
  }
  if (storeIndex < nodes.length) {
    nodes.length = storeIndex;
  }
}

List<DartType> _getAsTypeArguments(List<TypeParameter> typeParameters) {
  if (typeParameters.isEmpty) return const <DartType>[];
  return new List<DartType>.generate(
      typeParameters.length, (i) => new TypeParameterType(typeParameters[i]),
      growable: false);
}

class _ChildReplacer extends Transformer {
  final TreeNode child;
  final TreeNode replacement;

  _ChildReplacer(this.child, this.replacement);

  @override
  defaultTreeNode(TreeNode node) {
    if (node == child) {
      return replacement;
    } else {
      return node;
    }
  }
}
