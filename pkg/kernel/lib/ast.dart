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

import 'dart:convert' show UTF8;

import 'visitor.dart';
export 'visitor.dart';

import 'canonical_name.dart' show CanonicalName;
export 'canonical_name.dart' show CanonicalName;

import 'transformations/flags.dart';
import 'text/ast_to_text.dart';
import 'type_algebra.dart';
import 'type_environment.dart';
import 'coq_annot.dart';

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

  /// Offset in the source file it comes from.
  ///
  /// Valid values are from 0 and up, or -1 ([noOffset]) if the file offset is
  /// not available (this is the default if none is specifically set).
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

/// An AST node that can be referenced by other nodes.
///
/// There is a single [reference] belonging to this node, providing a level of
/// indirection that is needed during serialization.
@coq
abstract class NamedNode extends TreeNode {
  @coqdef
  final Reference reference;

  NamedNode(Reference reference)
      : this.reference = reference ?? new Reference() {
    this.reference.node = this;
  }

  CanonicalName get canonicalName => reference?.canonicalName;
}

/// Indirection between a reference and its definition.
///
/// There is only one reference object per [NamedNode].
@coqref
class Reference {
  CanonicalName canonicalName;

  @nocoq
  NamedNode node;

  String toString() {
    if (canonicalName != null) {
      return 'Reference to $canonicalName';
    }
    if (node != null) {
      return 'Reference to $node';
    }
    return 'Unbound reference';
  }

  Library get asLibrary {
    if (node == null) {
      throw '$this is not bound to an AST node. A library was expected';
    }
    return node as Library;
  }

  Class get asClass {
    if (node == null) {
      throw '$this is not bound to an AST node. A class was expected';
    }
    return node as Class;
  }

  Member get asMember {
    if (node == null) {
      throw '$this is not bound to an AST node. A member was expected';
    }
    return node as Member;
  }

  Field get asField {
    if (node == null) {
      throw '$this is not bound to an AST node. A field was expected';
    }
    return node as Field;
  }

  Constructor get asConstructor {
    if (node == null) {
      throw '$this is not bound to an AST node. A constructor was expected';
    }
    return node as Constructor;
  }

  Procedure get asProcedure {
    if (node == null) {
      throw '$this is not bound to an AST node. A procedure was expected';
    }
    return node as Procedure;
  }

  Typedef get asTypedef {
    if (node == null) {
      throw '$this is not bound to an AST node. A typedef was expected';
    }
    return node as Typedef;
  }
}

// ------------------------------------------------------------------------
//                      LIBRARIES and CLASSES
// ------------------------------------------------------------------------

@coq
class Library extends NamedNode implements Comparable<Library> {
  /// Offset of the declaration, set and used when writing the binary.
  int binaryOffset = -1;

  /// An import path to this library.
  ///
  /// The [Uri] should have the `dart`, `package`, `app`, or `file` scheme.
  ///
  /// If the URI has the `app` scheme, it is relative to the application root.
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

  /// Documentation comment of the library, or `null`.
  @informative
  String documentationComment;

  String name;

  @nocoq
  final List<Expression> annotations;

  final List<LibraryDependency> dependencies;

  /// References to nodes exported by `export` declarations that:
  /// - aren't ambiguous, or
  /// - aren't hidden by local declarations.
  @nocoq
  final List<Reference> additionalExports = <Reference>[];

  @informative
  final List<LibraryPart> parts;

  final List<Typedef> typedefs;
  final List<Class> classes;
  final List<Procedure> procedures;
  final List<Field> fields;

  Library(this.importUri,
      {this.name,
      this.isExternal: false,
      List<Expression> annotations,
      List<LibraryDependency> dependencies,
      List<LibraryPart> parts,
      List<Typedef> typedefs,
      List<Class> classes,
      List<Procedure> procedures,
      List<Field> fields,
      this.fileUri,
      Reference reference})
      : this.annotations = annotations ?? <Expression>[],
        this.dependencies = dependencies ?? <LibraryDependency>[],
        this.parts = parts ?? <LibraryPart>[],
        this.typedefs = typedefs ?? <Typedef>[],
        this.classes = classes ?? <Class>[],
        this.procedures = procedures ?? <Procedure>[],
        this.fields = fields ?? <Field>[],
        super(reference) {
    setParents(this.dependencies, this);
    setParents(this.parts, this);
    setParents(this.typedefs, this);
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

  void addTypedef(Typedef typedef_) {
    typedef_.parent = this;
    typedefs.add(typedef_);
  }

  void addAnnotation(Expression node) {
    node.parent = this;
    annotations.add(node);
  }

  void computeCanonicalNames() {
    assert(canonicalName != null);
    for (var typedef_ in typedefs) {
      canonicalName.getChildFromTypedef(typedef_).bindTo(typedef_.reference);
    }
    for (var field in fields) {
      canonicalName.getChildFromMember(field).bindTo(field.reference);
    }
    for (var member in procedures) {
      canonicalName.getChildFromMember(member).bindTo(member.reference);
    }
    for (var class_ in classes) {
      canonicalName.getChild(class_.name).bindTo(class_.reference);
      class_.computeCanonicalNames();
    }
  }

  void addDependency(LibraryDependency node) {
    dependencies.add(node..parent = this);
  }

  void addPart(LibraryPart node) {
    parts.add(node..parent = this);
  }

  accept(TreeVisitor v) => v.visitLibrary(this);

  visitChildren(Visitor v) {
    visitList(dependencies, v);
    visitList(parts, v);
    visitList(typedefs, v);
    visitList(classes, v);
    visitList(procedures, v);
    visitList(fields, v);
  }

  transformChildren(Transformer v) {
    transformList(dependencies, v, this);
    transformList(parts, v, this);
    transformList(typedefs, v, this);
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

/// An import or export declaration in a library.
///
/// It can represent any of the following forms,
///
///     import <url>;
///     import <url> as <name>;
///     import <url> deferred as <name>;
///     export <url>;
///
/// optionally with metadata and [Combinators].
class LibraryDependency extends TreeNode {
  int flags;

  final List<Expression> annotations;

  Reference importedLibraryReference;

  /// The name of the import prefix, if any, or `null` if this is not an import
  /// with a prefix.
  ///
  /// Must be non-null for deferred imports, and must be null for exports.
  String name;

  final List<Combinator> combinators;

  LibraryDependency(int flags, List<Expression> annotations,
      Library importedLibrary, String name, List<Combinator> combinators)
      : this.byReference(
            flags, annotations, importedLibrary.reference, name, combinators);

  LibraryDependency.deferredImport(Library importedLibrary, String name,
      {List<Combinator> combinators, List<Expression> annotations})
      : this.byReference(DeferredFlag, annotations ?? <Expression>[],
            importedLibrary.reference, name, combinators ?? <Combinator>[]);

  LibraryDependency.import(Library importedLibrary,
      {String name, List<Combinator> combinators, List<Expression> annotations})
      : this.byReference(0, annotations ?? <Expression>[],
            importedLibrary.reference, name, combinators ?? <Combinator>[]);

  LibraryDependency.export(Library importedLibrary,
      {List<Combinator> combinators, List<Expression> annotations})
      : this.byReference(ExportFlag, annotations ?? <Expression>[],
            importedLibrary.reference, null, combinators ?? <Combinator>[]);

  LibraryDependency.byReference(this.flags, this.annotations,
      this.importedLibraryReference, this.name, this.combinators) {
    setParents(annotations, this);
    setParents(combinators, this);
  }

  Library get enclosingLibrary => parent;
  Library get targetLibrary => importedLibraryReference.asLibrary;

  static const int ExportFlag = 1 << 0;
  static const int DeferredFlag = 1 << 1;

  bool get isExport => flags & ExportFlag != 0;
  bool get isImport => !isExport;
  bool get isDeferred => flags & DeferredFlag != 0;

  void addAnnotation(Expression annotation) {
    annotations.add(annotation..parent = this);
  }

  accept(TreeVisitor v) => v.visitLibraryDependency(this);

  visitChildren(Visitor v) {
    visitList(annotations, v);
    visitList(combinators, v);
  }

  transformChildren(Transformer v) {
    transformList(annotations, v, this);
    transformList(combinators, v, this);
  }
}

/// A part declaration in a library.
///
///     part <url>;
///
/// optionally with metadata.
class LibraryPart extends TreeNode {
  final List<Expression> annotations;
  final String fileUri;

  LibraryPart(List<Expression> annotations, String fileUri)
      : this.byReference(annotations, fileUri);

  LibraryPart.byReference(this.annotations, this.fileUri) {
    setParents(annotations, this);
  }

  void addAnnotation(Expression annotation) {
    annotations.add(annotation..parent = this);
  }

  accept(TreeVisitor v) => v.visitLibraryPart(this);

  visitChildren(Visitor v) {
    visitList(annotations, v);
  }

  transformChildren(Transformer v) {
    transformList(annotations, v, this);
  }
}

/// A `show` or `hide` clause for an import or export.
class Combinator extends TreeNode {
  bool isShow;

  final List<String> names;

  LibraryDependency get dependency => parent;

  Combinator(this.isShow, this.names);
  Combinator.show(this.names) : isShow = true;
  Combinator.hide(this.names) : isShow = false;

  bool get isHide => !isShow;

  @override
  accept(TreeVisitor v) => v.visitCombinator(this);

  @override
  visitChildren(Visitor v) {}

  @override
  transformChildren(Transformer v) {}
}

/// Declaration of a type alias.
class Typedef extends NamedNode {
  /// The uri of the source file that contains the declaration of this typedef.
  String fileUri;
  List<Expression> annotations = const <Expression>[];
  String name;
  final List<TypeParameter> typeParameters;
  DartType type;

  Typedef(this.name, this.type,
      {Reference reference, this.fileUri, List<TypeParameter> typeParameters})
      : this.typeParameters = typeParameters ?? <TypeParameter>[],
        super(reference) {
    setParents(this.typeParameters, this);
  }

  Library get enclosingLibrary => parent;

  accept(TreeVisitor v) {
    return v.visitTypedef(this);
  }

  transformChildren(Transformer v) {
    transformList(annotations, v, this);
    transformList(typeParameters, v, this);
    if (type != null) {
      type = v.visitDartType(type);
    }
  }

  visitChildren(Visitor v) {
    visitList(annotations, v);
    visitList(typeParameters, v);
    type?.accept(v);
  }

  void addAnnotation(Expression node) {
    if (annotations.isEmpty) {
      annotations = <Expression>[];
    }
    annotations.add(node);
    node.parent = this;
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

  /// All instance members of the class have their body loaded, and their
  /// annotations are present.
  ///
  /// All supertypes of this class are at [Hierarchy] level or higher.
  ///
  /// If this class is a mixin application, then its mixin is loaded at [Mixin]
  /// level or higher.
  ///
  /// This level exists so the contents of a mixin can be cloned into a
  /// mixin application.
  Mixin,

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
@coq
class Class extends NamedNode {
  /// End offset in the source file it comes from. Valid values are from 0 and
  /// up, or -1 ([TreeNode.noOffset]) if the file end offset is not available
  /// (this is the default if none is specifically set).
  int fileEndOffset = TreeNode.noOffset;

  /// The degree to which the contents of the class have been loaded.
  ClassLevel level = ClassLevel.Body;

  /// Documentation comment of the class, or `null`.
  @informative
  String documentationComment;

  /// List of metadata annotations on the class.
  ///
  /// This defaults to an immutable empty list. Use [addAnnotation] to add
  /// annotations if needed.
  @nocoq
  List<Expression> annotations = const <Expression>[];

  /// Name of the class.
  ///
  /// Must be non-null and must be unique within the library.
  ///
  /// The name may contain characters that are not valid in a Dart identifier,
  /// in particular, the symbol '&' is used in class names generated for mixin
  /// applications.
  @coq
  String name;
  bool isAbstract;

  /// Whether this class is an enum.
  @informative
  bool isEnum = false;

  /// Whether this class is a synthetic implementation created for each
  /// mixed-in class. For example the following code:
  /// class Z extends A with B, C, D {}
  /// class A {}
  /// class B {}
  /// class C {}
  /// class D {}
  /// ...creates:
  /// abstract class A&B extends A mixedIn B {}
  /// abstract class A&B&C extends A&B mixedIn C {}
  /// abstract class A&B&C&D extends A&B&C mixedIn D {}
  /// class Z extends A&B&C&D {}
  /// All X&Y classes are marked as synthetic.
  bool isSyntheticMixinImplementation;

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
      this.isSyntheticMixinImplementation: false,
      this.supertype,
      this.mixedInType,
      List<TypeParameter> typeParameters,
      List<Supertype> implementedTypes,
      List<Constructor> constructors,
      List<Procedure> procedures,
      List<Field> fields,
      this.fileUri,
      Reference reference})
      : this.typeParameters = typeParameters ?? <TypeParameter>[],
        this.implementedTypes = implementedTypes ?? <Supertype>[],
        this.fields = fields ?? <Field>[],
        this.constructors = constructors ?? <Constructor>[],
        this.procedures = procedures ?? <Procedure>[],
        super(reference) {
    setParents(this.typeParameters, this);
    setParents(this.constructors, this);
    setParents(this.procedures, this);
    setParents(this.fields, this);
  }

  void computeCanonicalNames() {
    assert(canonicalName != null);
    for (var member in fields) {
      canonicalName.getChildFromMember(member).bindTo(member.reference);
    }
    for (var member in procedures) {
      canonicalName.getChildFromMember(member).bindTo(member.reference);
    }
    for (var member in constructors) {
      canonicalName.getChildFromMember(member).bindTo(member.reference);
    }
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

  @nocoq
  InterfaceType _rawType;
  InterfaceType get rawType => _rawType ??= new InterfaceType(this);

  @nocoq
  InterfaceType _thisType;
  InterfaceType get thisType {
    return _thisType ??=
        new InterfaceType(this, _getAsTypeArguments(typeParameters));
  }

  @nocoq
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

@coq
abstract class Member extends NamedNode {
  /// End offset in the source file it comes from. Valid values are from 0 and
  /// up, or -1 ([TreeNode.noOffset]) if the file end offset is not available
  /// (this is the default if none is specifically set).
  int fileEndOffset = TreeNode.noOffset;

  /// Documentation comment of the member, or `null`.
  @informative
  String documentationComment;

  /// List of metadata annotations on the member.
  ///
  /// This defaults to an immutable empty list. Use [addAnnotation] to add
  /// annotations if needed.
  @nocoq
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

  Member(this.name, Reference reference) : super(reference);

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
}

/// A field declaration.
///
/// The implied getter and setter for the field are not represented explicitly,
/// but can be made explicit if needed.
class Field extends Member {
  DartType type; // Not null. Defaults to DynamicType.
  int flags = 0;
  Expression initializer; // May be null.

  /// The uri of the source file this field was loaded from.
  String fileUri;

  Field(Name name,
      {this.type: const DynamicType(),
      this.initializer,
      bool isCovariant: false,
      bool isFinal: false,
      bool isConst: false,
      bool isStatic: false,
      bool hasImplicitGetter,
      bool hasImplicitSetter,
      int transformerFlags: 0,
      this.fileUri,
      Reference reference})
      : super(name, reference) {
    assert(type != null);
    initializer?.parent = this;
    this.isCovariant = isCovariant;
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
  static const int FlagCovariant = 1 << 5;
  static const int FlagGenericCovariantImpl = 1 << 6;
  static const int FlagGenericCovariantInterface = 1 << 7;

  /// Whether the field is declared with the `covariant` keyword.
  bool get isCovariant => flags & FlagCovariant != 0;

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
  /// By default, all non-static, non-final fields have implicit setters.
  bool get hasImplicitSetter => flags & FlagHasImplicitSetter != 0;

  /// Indicates whether the implicit setter associated with this field needs to
  /// contain a runtime type check to deal with generic covariance.
  ///
  /// When `true`, runtime checks may need to be performed; see
  /// [DispatchCategory] for details.
  bool get isGenericCovariantImpl => flags & FlagGenericCovariantImpl != 0;

  /// Indicates whether setter invocations using this interface target may need
  /// to perform a runtime type check to deal with generic covariance.
  ///
  /// When `true`, runtime checks may need to be performed; see
  /// [DispatchCategory] for details.
  bool get isGenericCovariantInterface =>
      flags & FlagGenericCovariantInterface != 0;

  void set isCovariant(bool value) {
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

  void set isGenericCovariantImpl(bool value) {
    flags = value
        ? (flags | FlagGenericCovariantImpl)
        : (flags & ~FlagGenericCovariantImpl);
  }

  void set isGenericCovariantInterface(bool value) {
    flags = value
        ? (flags | FlagGenericCovariantInterface)
        : (flags & ~FlagGenericCovariantInterface);
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
  /// Offset of the name in the source file it comes from.
  ///
  /// Valid values are from `-1` and up, where `-1` means that the node does
  /// not have an explicit name (i.e. unnamed constructor).
  int nameOffset = TreeNode.noOffset;

  int flags = 0;
  FunctionNode function;
  List<Initializer> initializers;

  Constructor(this.function,
      {Name name,
      bool isConst: false,
      bool isExternal: false,
      bool isSyntheticDefault: false,
      List<Initializer> initializers,
      int transformerFlags: 0,
      Reference reference})
      : this.initializers = initializers ?? <Initializer>[],
        super(name, reference) {
    function?.parent = this;
    setParents(this.initializers, this);
    this.isConst = isConst;
    this.isExternal = isExternal;
    this.isSyntheticDefault = isSyntheticDefault;
    this.transformerFlags = transformerFlags;
  }

  static const int FlagConst = 1 << 0; // Must match serialized bit positions.
  static const int FlagExternal = 1 << 1;
  static const int FlagSyntheticDefault = 1 << 2;

  bool get isConst => flags & FlagConst != 0;
  bool get isExternal => flags & FlagExternal != 0;

  /// True if this is a synthetic default constructor inserted in a class that
  /// does not otherwise declare any constructors.
  bool get isSyntheticDefault => flags & FlagSyntheticDefault != 0;

  void set isConst(bool value) {
    flags = value ? (flags | FlagConst) : (flags & ~FlagConst);
  }

  void set isExternal(bool value) {
    flags = value ? (flags | FlagExternal) : (flags & ~FlagExternal);
  }

  void set isSyntheticDefault(bool value) {
    flags = value
        ? (flags | FlagSyntheticDefault)
        : (flags & ~FlagSyntheticDefault);
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
    visitList(initializers, v);
    function?.accept(v);
  }

  transformChildren(Transformer v) {
    transformList(annotations, v, this);
    transformList(initializers, v, this);
    if (function != null) {
      function = function.accept(v);
      function?.parent = this;
    }
  }

  DartType get getterType => const BottomType();
  DartType get setterType => const BottomType();
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
@coq
class Procedure extends Member {
  ProcedureKind kind;

  /// Offset of the name in the source file it comes from.
  ///
  /// Valid values are from `-1` and up, where `-1` means that the node does
  /// not have an explicit name (i.e. unnamed constructor).
  int nameOffset = TreeNode.noOffset;

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
      this.fileUri,
      Reference reference})
      : super(name, reference) {
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
  bool get isFactory => kind == ProcedureKind.Factory;

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

  Location _getLocationInEnclosingFile(int offset) {
    return enclosingProgram.getLocation(fileUri, offset);
  }
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
  /// True if this is a synthetic constructor initializer.
  @informative
  bool isSynthetic = false;

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
  Reference fieldReference;
  Expression value;

  FieldInitializer(Field field, Expression value)
      : this.byReference(field?.reference, value);

  FieldInitializer.byReference(this.fieldReference, this.value) {
    value?.parent = this;
  }

  Field get field => fieldReference?.node;

  void set field(Field field) {
    fieldReference = field?.reference;
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
  Reference targetReference;
  Arguments arguments;

  SuperInitializer(Constructor target, Arguments arguments)
      : this.byReference(getMemberReference(target), arguments);

  SuperInitializer.byReference(this.targetReference, this.arguments) {
    arguments?.parent = this;
  }

  Constructor get target => targetReference?.asConstructor;

  void set target(Constructor target) {
    targetReference = getMemberReference(target);
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
  Reference targetReference;
  Arguments arguments;

  RedirectingInitializer(Constructor target, Arguments arguments)
      : this.byReference(getMemberReference(target), arguments);

  RedirectingInitializer.byReference(this.targetReference, this.arguments) {
    arguments?.parent = this;
  }

  Constructor get target => targetReference?.asConstructor;

  void set target(Constructor target) {
    targetReference = getMemberReference(target);
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
@coq
class FunctionNode extends TreeNode {
  /// End offset in the source file it comes from. Valid values are from 0 and
  /// up, or -1 ([TreeNode.noOffset]) if the file end offset is not available
  /// (this is the default if none is specifically set).
  int fileEndOffset = TreeNode.noOffset;

  /// Kernel async marker for the function.
  ///
  /// See also [dartAsyncMarker].
  AsyncMarker asyncMarker;

  /// Dart async marker for the function.
  ///
  /// See also [asyncMarker].
  ///
  /// A Kernel function can represent a Dart function with a different async
  /// marker.
  ///
  /// For example, when async/await is translated away,
  /// a Dart async function might be represented by a Kernel sync function.
  AsyncMarker dartAsyncMarker;

  List<TypeParameter> typeParameters;
  int requiredParameterCount;
  @coqsingledef
  List<VariableDeclaration> positionalParameters;
  @nocoq
  List<VariableDeclaration> namedParameters;
  DartType returnType; // Not null.
  Statement body;

  FunctionNode(this.body,
      {List<TypeParameter> typeParameters,
      List<VariableDeclaration> positionalParameters,
      List<VariableDeclaration> namedParameters,
      int requiredParameterCount,
      this.returnType: const DynamicType(),
      this.asyncMarker: AsyncMarker.Sync,
      this.dartAsyncMarker})
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
    dartAsyncMarker ??= asyncMarker;
  }

  static DartType _getTypeOfVariable(VariableDeclaration node) => node.type;

  static NamedType _getNamedTypeOfVariable(VariableDeclaration node) {
    return new NamedType(node.name, node.type);
  }

  FunctionType get functionType {
    TreeNode parent = this.parent;
    List<NamedType> named =
        namedParameters.map(_getNamedTypeOfVariable).toList(growable: false);
    named.sort();
    // We need create a copy of the list of type parameters, otherwise
    // transformations like erasure don't work.
    var typeParametersCopy = new List<TypeParameter>.from(parent is Constructor
        ? parent.enclosingClass.typeParameters
        : typeParameters);
    return new FunctionType(
        positionalParameters.map(_getTypeOfVariable).toList(growable: false),
        returnType,
        namedParameters: named,
        typeParameters: typeParametersCopy,
        requiredParameterCount: requiredParameterCount);
  }

  accept(TreeVisitor v) => v.visitFunctionNode(this);

  visitChildren(Visitor v) {
    visitList(typeParameters, v);
    visitList(positionalParameters, v);
    visitList(namedParameters, v);
    returnType?.accept(v);
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

@coq
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
  /// This method furthermore assumes that the type of the expression actually
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
  accept1(ExpressionVisitor1 v, arg);
}

/// An expression containing compile-time errors.
///
/// Should throw a runtime error when evaluated.
class InvalidExpression extends Expression {
  DartType getStaticType(TypeEnvironment types) => const BottomType();

  accept(ExpressionVisitor v) => v.visitInvalidExpression(this);
  accept1(ExpressionVisitor1 v, arg) => v.visitInvalidExpression(this, arg);

  visitChildren(Visitor v) {}
  transformChildren(Transformer v) {}
}

/// Read a local variable, a local function, or a function parameter.
@coq
class VariableGet extends Expression {
  VariableDeclaration variable;
  @nocoq
  DartType promotedType; // Null if not promoted.

  VariableGet(this.variable, [this.promotedType]);

  DartType getStaticType(TypeEnvironment types) {
    return promotedType ?? variable.type;
  }

  accept(ExpressionVisitor v) => v.visitVariableGet(this);
  accept1(ExpressionVisitor1 v, arg) => v.visitVariableGet(this, arg);

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
///
/// Evaluates to the value of [value].
class VariableSet extends Expression {
  VariableDeclaration variable;
  Expression value;

  VariableSet(this.variable, this.value) {
    value?.parent = this;
  }

  DartType getStaticType(TypeEnvironment types) => value.getStaticType(types);

  accept(ExpressionVisitor v) => v.visitVariableSet(this);
  accept1(ExpressionVisitor1 v, arg) => v.visitVariableSet(this, arg);

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
@coq
class PropertyGet extends Expression {
  Expression receiver;
  @coq
  Name name;
  int flags = 0;

  @nocoq
  Reference interfaceTargetReference;

  PropertyGet(Expression receiver, Name name, [Member interfaceTarget])
      : this.byReference(receiver, name, getMemberReference(interfaceTarget));

  PropertyGet.byReference(
      this.receiver, this.name, this.interfaceTargetReference) {
    receiver?.parent = this;
    this.dispatchCategory = DispatchCategory.dynamicDispatch;
  }

  // Must match serialized bit positions
  static const int ShiftDispatchCategory = 0;
  static const int FlagDispatchCategory = 3 << ShiftDispatchCategory;

  DispatchCategory get dispatchCategory => DispatchCategory
      .values[(flags & FlagDispatchCategory) >> ShiftDispatchCategory];

  void set dispatchCategory(DispatchCategory value) {
    flags = (flags & ~FlagDispatchCategory) |
        (value.index << ShiftDispatchCategory);
  }

  Member get interfaceTarget => interfaceTargetReference?.asMember;

  void set interfaceTarget(Member member) {
    interfaceTargetReference = getMemberReference(member);
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
  accept1(ExpressionVisitor1 v, arg) => v.visitPropertyGet(this, arg);

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
///
/// Evaluates to the value of [value].
class PropertySet extends Expression {
  Expression receiver;
  Name name;
  Expression value;

  Reference interfaceTargetReference;

  PropertySet(Expression receiver, Name name, Expression value,
      [Member interfaceTarget])
      : this.byReference(
            receiver, name, value, getMemberReference(interfaceTarget));

  PropertySet.byReference(
      this.receiver, this.name, this.value, this.interfaceTargetReference) {
    receiver?.parent = this;
    value?.parent = this;
  }

  Member get interfaceTarget => interfaceTargetReference?.asMember;

  void set interfaceTarget(Member member) {
    interfaceTargetReference = getMemberReference(member);
  }

  DartType getStaticType(TypeEnvironment types) => value.getStaticType(types);

  accept(ExpressionVisitor v) => v.visitPropertySet(this);
  accept1(ExpressionVisitor1 v, arg) => v.visitPropertySet(this, arg);

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
  Reference targetReference;
  int flags = 0;

  DirectPropertyGet(Expression receiver, Member target)
      : this.byReference(receiver, getMemberReference(target));

  DirectPropertyGet.byReference(this.receiver, this.targetReference) {
    receiver?.parent = this;
    this.dispatchCategory = DispatchCategory.dynamicDispatch;
  }

  // Must match serialized bit positions
  static const int ShiftDispatchCategory = 0;
  static const int FlagDispatchCategory = 3 << ShiftDispatchCategory;

  DispatchCategory get dispatchCategory => DispatchCategory
      .values[(flags & FlagDispatchCategory) >> ShiftDispatchCategory];

  void set dispatchCategory(DispatchCategory value) {
    flags = (flags & ~FlagDispatchCategory) |
        (value.index << ShiftDispatchCategory);
  }

  Member get target => targetReference?.asMember;

  void set target(Member target) {
    targetReference = getMemberReference(target);
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
  accept1(ExpressionVisitor1 v, arg) => v.visitDirectPropertyGet(this, arg);

  DartType getStaticType(TypeEnvironment types) {
    Class superclass = target.enclosingClass;
    var receiverType = receiver.getStaticTypeAsInstanceOf(superclass, types);
    return Substitution
        .fromInterfaceType(receiverType)
        .substituteType(target.getterType);
  }
}

/// Directly assign a field, or call a setter.
///
/// Evaluates to the value of [value].
class DirectPropertySet extends Expression {
  Expression receiver;
  Reference targetReference;
  Expression value;

  DirectPropertySet(Expression receiver, Member target, Expression value)
      : this.byReference(receiver, getMemberReference(target), value);

  DirectPropertySet.byReference(
      this.receiver, this.targetReference, this.value) {
    receiver?.parent = this;
    value?.parent = this;
  }

  Member get target => targetReference?.asMember;

  void set target(Member target) {
    targetReference = getMemberReference(target);
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
  accept1(ExpressionVisitor1 v, arg) => v.visitDirectPropertySet(this, arg);

  DartType getStaticType(TypeEnvironment types) => value.getStaticType(types);
}

/// Directly call an instance method, bypassing ordinary dispatch.
class DirectMethodInvocation extends InvocationExpression {
  Expression receiver;
  Reference targetReference;
  Arguments arguments;
  int flags = 0;

  DirectMethodInvocation(
      Expression receiver, Procedure target, Arguments arguments)
      : this.byReference(receiver, getMemberReference(target), arguments);

  DirectMethodInvocation.byReference(
      this.receiver, this.targetReference, this.arguments) {
    receiver?.parent = this;
    arguments?.parent = this;
    this.dispatchCategory = DispatchCategory.dynamicDispatch;
  }

  // Must match serialized bit positions
  static const int ShiftDispatchCategory = 0;
  static const int FlagDispatchCategory = 3 << ShiftDispatchCategory;

  DispatchCategory get dispatchCategory => DispatchCategory
      .values[(flags & FlagDispatchCategory) >> ShiftDispatchCategory];

  void set dispatchCategory(DispatchCategory value) {
    flags = (flags & ~FlagDispatchCategory) |
        (value.index << ShiftDispatchCategory);
  }

  Procedure get target => targetReference?.asProcedure;

  void set target(Procedure target) {
    targetReference = getMemberReference(target);
  }

  Name get name => target?.name;

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
  accept1(ExpressionVisitor1 v, arg) =>
      v.visitDirectMethodInvocation(this, arg);

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

  Reference interfaceTargetReference;

  DispatchCategory get dispatchCategory => DispatchCategory.viaThis;

  SuperPropertyGet(Name name, [Member interfaceTarget])
      : this.byReference(name, getMemberReference(interfaceTarget));

  SuperPropertyGet.byReference(this.name, this.interfaceTargetReference);

  Member get interfaceTarget => interfaceTargetReference?.asMember;

  void set interfaceTarget(Member member) {
    interfaceTargetReference = getMemberReference(member);
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
  accept1(ExpressionVisitor1 v, arg) => v.visitSuperPropertyGet(this, arg);

  visitChildren(Visitor v) {
    name?.accept(v);
  }

  transformChildren(Transformer v) {}
}

/// Expression of form `super.field = value`.
///
/// This may invoke a setter or assign a field.
///
/// Evaluates to the value of [value].
class SuperPropertySet extends Expression {
  Name name;
  Expression value;

  Reference interfaceTargetReference;

  SuperPropertySet(Name name, Expression value, Member interfaceTarget)
      : this.byReference(name, value, getMemberReference(interfaceTarget));

  SuperPropertySet.byReference(
      this.name, this.value, this.interfaceTargetReference) {
    value?.parent = this;
  }

  Member get interfaceTarget => interfaceTargetReference?.asMember;

  void set interfaceTarget(Member member) {
    interfaceTargetReference = getMemberReference(member);
  }

  DartType getStaticType(TypeEnvironment types) => value.getStaticType(types);

  accept(ExpressionVisitor v) => v.visitSuperPropertySet(this);
  accept1(ExpressionVisitor1 v, arg) => v.visitSuperPropertySet(this, arg);

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
  Reference targetReference;

  StaticGet(Member target) : this.byReference(getMemberReference(target));

  StaticGet.byReference(this.targetReference);

  Member get target => targetReference?.asMember;

  void set target(Member target) {
    targetReference = getMemberReference(target);
  }

  DartType getStaticType(TypeEnvironment types) => target.getterType;

  accept(ExpressionVisitor v) => v.visitStaticGet(this);
  accept1(ExpressionVisitor1 v, arg) => v.visitStaticGet(this, arg);

  visitChildren(Visitor v) {
    target?.acceptReference(v);
  }

  transformChildren(Transformer v) {}
}

/// Assign a static field or call a static setter.
///
/// Evaluates to the value of [value].
class StaticSet extends Expression {
  /// A mutable static field or a static setter.
  Reference targetReference;
  Expression value;

  StaticSet(Member target, Expression value)
      : this.byReference(getMemberReference(target), value);

  StaticSet.byReference(this.targetReference, this.value) {
    value?.parent = this;
  }

  Member get target => targetReference?.asMember;

  void set target(Member target) {
    targetReference = getMemberReference(target);
  }

  DartType getStaticType(TypeEnvironment types) => value.getStaticType(types);

  accept(ExpressionVisitor v) => v.visitStaticSet(this);
  accept1(ExpressionVisitor1 v, arg) => v.visitStaticSet(this, arg);

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
@coq
class Arguments extends TreeNode {
  @nocoq
  final List<DartType> types;
  @coqsingle
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

/// Common super class for [DirectMethodInvocation], [MethodInvocation],
/// [SuperMethodInvocation], [StaticInvocation], and [ConstructorInvocation].
@coq
abstract class InvocationExpression extends Expression {
  Arguments get arguments;
  set arguments(Arguments value);

  /// Name of the invoked method.
  ///
  /// May be `null` if the target is a synthetic static member without a name.
  Name get name;
}

/// Expression of form `x.foo(y)`.
@coq
class MethodInvocation extends InvocationExpression {
  Expression receiver;
  Name name;
  Arguments arguments;
  int flags = 0;

  Reference interfaceTargetReference;

  MethodInvocation(Expression receiver, Name name, Arguments arguments,
      [Member interfaceTarget])
      : this.byReference(
            receiver, name, arguments, getMemberReference(interfaceTarget));

  MethodInvocation.byReference(
      this.receiver, this.name, this.arguments, this.interfaceTargetReference) {
    receiver?.parent = this;
    arguments?.parent = this;
    this.dispatchCategory = DispatchCategory.dynamicDispatch;
  }

  // Must match serialized bit positions
  static const int ShiftDispatchCategory = 0;
  static const int FlagDispatchCategory = 3 << ShiftDispatchCategory;

  DispatchCategory get dispatchCategory => DispatchCategory
      .values[(flags & FlagDispatchCategory) >> ShiftDispatchCategory];

  void set dispatchCategory(DispatchCategory value) {
    flags = (flags & ~FlagDispatchCategory) |
        (value.index << ShiftDispatchCategory);
  }

  Member get interfaceTarget => interfaceTargetReference?.asMember;

  void set interfaceTarget(Member target) {
    interfaceTargetReference = getMemberReference(target);
  }

  DartType getStaticType(TypeEnvironment types) {
    var interfaceTarget = this.interfaceTarget;
    if (interfaceTarget != null) {
      if (interfaceTarget is Procedure &&
          types.isOverloadedArithmeticOperator(interfaceTarget)) {
        return types.getTypeOfOverloadedArithmetic(
            receiver.getStaticType(types),
            arguments.positional[0].getStaticType(types));
      }
      Class superclass = interfaceTarget.enclosingClass;
      var receiverType = receiver.getStaticTypeAsInstanceOf(superclass, types);
      var getterType = Substitution
          .fromInterfaceType(receiverType)
          .substituteType(interfaceTarget.getterType);
      if (getterType is FunctionType) {
        return Substitution
            .fromPairs(getterType.typeParameters, arguments.types)
            .substituteType(getterType.returnType);
      } else {
        return const DynamicType();
      }
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
  accept1(ExpressionVisitor1 v, arg) => v.visitMethodInvocation(this, arg);

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
  DispatchCategory get dispatchCategory => DispatchCategory.viaThis;

  Reference interfaceTargetReference;

  SuperMethodInvocation(Name name, Arguments arguments,
      [Procedure interfaceTarget])
      : this.byReference(name, arguments, getMemberReference(interfaceTarget));

  SuperMethodInvocation.byReference(
      this.name, this.arguments, this.interfaceTargetReference) {
    arguments?.parent = this;
  }

  Procedure get interfaceTarget => interfaceTargetReference?.asProcedure;

  void set interfaceTarget(Procedure target) {
    interfaceTargetReference = getMemberReference(target);
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
  accept1(ExpressionVisitor1 v, arg) => v.visitSuperMethodInvocation(this, arg);

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
  Reference targetReference;
  Arguments arguments;

  /// True if this is a constant call to an external constant factory.
  bool isConst;

  Name get name => target?.name;

  StaticInvocation(Procedure target, Arguments arguments, {bool isConst: false})
      : this.byReference(getMemberReference(target), arguments,
            isConst: isConst);

  StaticInvocation.byReference(this.targetReference, this.arguments,
      {this.isConst: false}) {
    arguments?.parent = this;
  }

  Procedure get target => targetReference?.asProcedure;

  void set target(Procedure target) {
    targetReference = getMemberReference(target);
  }

  DartType getStaticType(TypeEnvironment types) {
    return Substitution
        .fromPairs(target.function.typeParameters, arguments.types)
        .substituteType(target.function.returnType);
  }

  accept(ExpressionVisitor v) => v.visitStaticInvocation(this);
  accept1(ExpressionVisitor1 v, arg) => v.visitStaticInvocation(this, arg);

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
@coq
class ConstructorInvocation extends InvocationExpression {
  Reference targetReference;
  @nocoq
  Arguments arguments;
  bool isConst;

  Name get name => target?.name;

  ConstructorInvocation(Constructor target, Arguments arguments,
      {bool isConst: false})
      : this.byReference(getMemberReference(target), arguments,
            isConst: isConst);

  ConstructorInvocation.byReference(this.targetReference, this.arguments,
      {this.isConst: false}) {
    arguments?.parent = this;
  }

  Constructor get target => targetReference?.asConstructor;

  void set target(Constructor target) {
    targetReference = getMemberReference(target);
  }

  DartType getStaticType(TypeEnvironment types) {
    return arguments.types.isEmpty
        ? target.enclosingClass.rawType
        : new InterfaceType(target.enclosingClass, arguments.types);
  }

  accept(ExpressionVisitor v) => v.visitConstructorInvocation(this);
  accept1(ExpressionVisitor1 v, arg) => v.visitConstructorInvocation(this, arg);

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
  accept1(ExpressionVisitor1 v, arg) => v.visitNot(this, arg);

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
  accept1(ExpressionVisitor1 v, arg) => v.visitLogicalExpression(this, arg);

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
  accept1(ExpressionVisitor1 v, arg) => v.visitConditionalExpression(this, arg);

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
  accept1(ExpressionVisitor1 v, arg) => v.visitStringConcatenation(this, arg);

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
  accept1(ExpressionVisitor1 v, arg) => v.visitIsExpression(this, arg);

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
  accept1(ExpressionVisitor1 v, arg) => v.visitAsExpression(this, arg);

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
  accept1(ExpressionVisitor1 v, arg) => v.visitStringLiteral(this, arg);
}

class IntLiteral extends BasicLiteral {
  int value;

  IntLiteral(this.value);

  DartType getStaticType(TypeEnvironment types) => types.intType;

  accept(ExpressionVisitor v) => v.visitIntLiteral(this);
  accept1(ExpressionVisitor1 v, arg) => v.visitIntLiteral(this, arg);
}

class DoubleLiteral extends BasicLiteral {
  double value;

  DoubleLiteral(this.value);

  DartType getStaticType(TypeEnvironment types) => types.doubleType;

  accept(ExpressionVisitor v) => v.visitDoubleLiteral(this);
  accept1(ExpressionVisitor1 v, arg) => v.visitDoubleLiteral(this, arg);
}

class BoolLiteral extends BasicLiteral {
  bool value;

  BoolLiteral(this.value);

  DartType getStaticType(TypeEnvironment types) => types.boolType;

  accept(ExpressionVisitor v) => v.visitBoolLiteral(this);
  accept1(ExpressionVisitor1 v, arg) => v.visitBoolLiteral(this, arg);
}

class NullLiteral extends BasicLiteral {
  Object get value => null;

  DartType getStaticType(TypeEnvironment types) => const BottomType();

  accept(ExpressionVisitor v) => v.visitNullLiteral(this);
  accept1(ExpressionVisitor1 v, arg) => v.visitNullLiteral(this, arg);
}

class SymbolLiteral extends Expression {
  String value; // Everything strictly after the '#'.

  SymbolLiteral(this.value);

  DartType getStaticType(TypeEnvironment types) => types.symbolType;

  accept(ExpressionVisitor v) => v.visitSymbolLiteral(this);
  accept1(ExpressionVisitor1 v, arg) => v.visitSymbolLiteral(this, arg);

  visitChildren(Visitor v) {}
  transformChildren(Transformer v) {}
}

class TypeLiteral extends Expression {
  DartType type;

  TypeLiteral(this.type);

  DartType getStaticType(TypeEnvironment types) => types.typeType;

  accept(ExpressionVisitor v) => v.visitTypeLiteral(this);
  accept1(ExpressionVisitor1 v, arg) => v.visitTypeLiteral(this, arg);

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
  accept1(ExpressionVisitor1 v, arg) => v.visitThisExpression(this, arg);

  visitChildren(Visitor v) {}
  transformChildren(Transformer v) {}
}

class Rethrow extends Expression {
  DartType getStaticType(TypeEnvironment types) => const BottomType();

  accept(ExpressionVisitor v) => v.visitRethrow(this);
  accept1(ExpressionVisitor1 v, arg) => v.visitRethrow(this, arg);

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
  accept1(ExpressionVisitor1 v, arg) => v.visitThrow(this, arg);

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
  accept1(ExpressionVisitor1 v, arg) => v.visitListLiteral(this, arg);

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
  accept1(ExpressionVisitor1 v, arg) => v.visitMapLiteral(this, arg);

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
  accept1(ExpressionVisitor1 v, arg) => v.visitAwaitExpression(this, arg);

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
  accept1(ExpressionVisitor1 v, arg) => v.visitFunctionExpression(this, arg);

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
  accept1(ExpressionVisitor1 v, arg) => v.visitLet(this, arg);

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

/// Attempt to load the library referred to by a deferred import.
///
/// This instruction is concerned with:
/// - keeping track whether the deferred import is marked as 'loaded'
/// - keeping track of whether the library code has already been downloaded
/// - actually downloading and linking the library
///
/// Should return a future.  The value in this future will be the same value
/// seen by callers of `loadLibrary` functions.
///
/// On backends that link the entire program eagerly, this instruction needs
/// to mark the deferred import as 'loaded' and return a future.
class LoadLibrary extends Expression {
  /// Reference to a deferred import in the enclosing library.
  LibraryDependency import;

  LoadLibrary(this.import);

  DartType getStaticType(TypeEnvironment types) {
    return types.futureType(const DynamicType());
  }

  accept(ExpressionVisitor v) => v.visitLoadLibrary(this);
  accept1(ExpressionVisitor1 v, arg) => v.visitLoadLibrary(this, arg);

  visitChildren(Visitor v) {}
  transformChildren(Transformer v) {}
}

/// Checks that the given deferred import has been marked as 'loaded'.
class CheckLibraryIsLoaded extends Expression {
  /// Reference to a deferred import in the enclosing library.
  LibraryDependency import;

  CheckLibraryIsLoaded(this.import);

  DartType getStaticType(TypeEnvironment types) {
    return types.objectType;
  }

  accept(ExpressionVisitor v) => v.visitCheckLibraryIsLoaded(this);
  accept1(ExpressionVisitor1 v, arg) => v.visitCheckLibraryIsLoaded(this, arg);

  visitChildren(Visitor v) {}
  transformChildren(Transformer v) {}
}

/// Expression of the form `MakeVector(N)` where `N` is an integer representing
/// the length of the vector.
///
/// For detailed comment about Vectors see [VectorType].
class VectorCreation extends Expression {
  int length;

  VectorCreation(this.length);

  accept(ExpressionVisitor v) => v.visitVectorCreation(this);
  accept1(ExpressionVisitor1 v, arg) => v.visitVectorCreation(this, arg);

  visitChildren(Visitor v) {}

  transformChildren(Transformer v) {}

  DartType getStaticType(TypeEnvironment types) {
    return const VectorType();
  }
}

/// Expression of the form `v[i]` where `v` is a vector expression, and `i` is
/// an integer index.
class VectorGet extends Expression {
  Expression vectorExpression;
  int index;

  VectorGet(this.vectorExpression, this.index) {
    vectorExpression?.parent = this;
  }

  accept(ExpressionVisitor v) => v.visitVectorGet(this);
  accept1(ExpressionVisitor1 v, arg) => v.visitVectorGet(this, arg);

  visitChildren(Visitor v) {
    vectorExpression.accept(v);
  }

  transformChildren(Transformer v) {
    if (vectorExpression != null) {
      vectorExpression = vectorExpression.accept(v);
      vectorExpression?.parent = this;
    }
  }

  DartType getStaticType(TypeEnvironment types) {
    return const DynamicType();
  }
}

/// Expression of the form `v[i] = x` where `v` is a vector expression, `i` is
/// an integer index, and `x` is an arbitrary expression.
class VectorSet extends Expression {
  Expression vectorExpression;
  int index;
  Expression value;

  VectorSet(this.vectorExpression, this.index, this.value) {
    vectorExpression?.parent = this;
    value?.parent = this;
  }

  accept(ExpressionVisitor v) => v.visitVectorSet(this);
  accept1(ExpressionVisitor1 v, arg) => v.visitVectorSet(this, arg);

  visitChildren(Visitor v) {
    vectorExpression.accept(v);
    value.accept(v);
  }

  transformChildren(Transformer v) {
    if (vectorExpression != null) {
      vectorExpression = vectorExpression.accept(v);
      vectorExpression?.parent = this;
    }
    if (value != null) {
      value = value.accept(v);
      value?.parent = this;
    }
  }

  DartType getStaticType(TypeEnvironment types) {
    return value.getStaticType(types);
  }
}

/// Expression of the form `CopyVector(v)` where `v` is a vector expression.
class VectorCopy extends Expression {
  Expression vectorExpression;

  VectorCopy(this.vectorExpression) {
    vectorExpression?.parent = this;
  }

  accept(ExpressionVisitor v) => v.visitVectorCopy(this);
  accept1(ExpressionVisitor1 v, arg) => v.visitVectorCopy(this, arg);

  visitChildren(Visitor v) {
    vectorExpression.accept(v);
  }

  transformChildren(Transformer v) {
    if (vectorExpression != null) {
      vectorExpression = vectorExpression.accept(v);
      vectorExpression?.parent = this;
    }
  }

  DartType getStaticType(TypeEnvironment types) {
    return const VectorType();
  }
}

/// Expression of the form `MakeClosure(f, c, t)` where `f` is a name of a
/// closed top-level function, `c` is a Vector representing closure context, and
/// `t` is the type of the resulting closure.
class ClosureCreation extends Expression {
  Reference topLevelFunctionReference;
  Expression contextVector;
  FunctionType functionType;
  List<DartType> typeArguments;

  ClosureCreation(Member topLevelFunction, Expression contextVector,
      FunctionType functionType, List<DartType> typeArguments)
      : this.byReference(getMemberReference(topLevelFunction), contextVector,
            functionType, typeArguments);

  ClosureCreation.byReference(this.topLevelFunctionReference,
      this.contextVector, this.functionType, this.typeArguments) {
    contextVector?.parent = this;
  }

  Procedure get topLevelFunction => topLevelFunctionReference?.asProcedure;

  void set topLevelFunction(Member topLevelFunction) {
    topLevelFunctionReference = getMemberReference(topLevelFunction);
  }

  accept(ExpressionVisitor v) => v.visitClosureCreation(this);
  accept1(ExpressionVisitor1 v, arg) => v.visitClosureCreation(this, arg);

  visitChildren(Visitor v) {
    contextVector?.accept(v);
    functionType.accept(v);
    visitList(typeArguments, v);
  }

  transformChildren(Transformer v) {
    if (contextVector != null) {
      contextVector = contextVector.accept(v);
      contextVector?.parent = this;
    }
    functionType = v.visitDartType(functionType);
    transformTypeList(typeArguments, v);
  }

  DartType getStaticType(TypeEnvironment types) {
    return functionType;
  }
}

// ------------------------------------------------------------------------
//                              STATEMENTS
// ------------------------------------------------------------------------

@coq
abstract class Statement extends TreeNode {
  accept(StatementVisitor v);
  accept1(StatementVisitor1 v, arg);
}

/// A statement with a compile-time error.
///
/// Should throw an exception at runtime.
class InvalidStatement extends Statement {
  accept(StatementVisitor v) => v.visitInvalidStatement(this);
  accept1(StatementVisitor1 v, arg) => v.visitInvalidStatement(this, arg);

  visitChildren(Visitor v) {}
  transformChildren(Transformer v) {}
}

@coq
class ExpressionStatement extends Statement {
  Expression expression;

  ExpressionStatement(this.expression) {
    expression?.parent = this;
  }

  accept(StatementVisitor v) => v.visitExpressionStatement(this);
  accept1(StatementVisitor1 v, arg) => v.visitExpressionStatement(this, arg);

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

@coq
class Block extends Statement {
  final List<Statement> statements;

  Block(this.statements) {
    setParents(statements, this);
  }

  accept(StatementVisitor v) => v.visitBlock(this);
  accept1(StatementVisitor1 v, arg) => v.visitBlock(this, arg);

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
  accept1(StatementVisitor1 v, arg) => v.visitEmptyStatement(this, arg);

  visitChildren(Visitor v) {}
  transformChildren(Transformer v) {}
}

class AssertStatement extends Statement {
  Expression condition;
  Expression message; // May be null.
  int conditionStartOffset;
  int conditionEndOffset;

  AssertStatement(this.condition,
      {this.message, this.conditionStartOffset, this.conditionEndOffset}) {
    condition?.parent = this;
    message?.parent = this;
  }

  accept(StatementVisitor v) => v.visitAssertStatement(this);
  accept1(StatementVisitor1 v, arg) => v.visitAssertStatement(this, arg);

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
  accept1(StatementVisitor1 v, arg) => v.visitLabeledStatement(this, arg);

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
  accept1(StatementVisitor1 v, arg) => v.visitBreakStatement(this, arg);

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
  accept1(StatementVisitor1 v, arg) => v.visitWhileStatement(this, arg);

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
  accept1(StatementVisitor1 v, arg) => v.visitDoStatement(this, arg);

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
  accept1(StatementVisitor1 v, arg) => v.visitForStatement(this, arg);

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
  /// Offset in the source file it comes from.
  ///
  /// Valid values are from 0 and up, or -1 ([TreeNode.noOffset]) if the file
  /// offset is not available (this is the default if none is specifically set).
  int bodyOffset = TreeNode.noOffset;

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
  accept1(StatementVisitor1 v, arg) => v.visitForInStatement(this, arg);

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
  accept1(StatementVisitor1 v, arg) => v.visitSwitchStatement(this, arg);

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
  final List<int> expressionOffsets;
  Statement body;
  bool isDefault;

  SwitchCase(this.expressions, this.expressionOffsets, this.body,
      {this.isDefault: false}) {
    setParents(expressions, this);
    body?.parent = this;
  }

  SwitchCase.defaultCase(this.body)
      : isDefault = true,
        expressions = <Expression>[],
        expressionOffsets = <int>[] {
    body?.parent = this;
  }

  SwitchCase.empty()
      : expressions = <Expression>[],
        expressionOffsets = <int>[],
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
  accept1(StatementVisitor1 v, arg) =>
      v.visitContinueSwitchStatement(this, arg);

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
  accept1(StatementVisitor1 v, arg) => v.visitIfStatement(this, arg);

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

@coq
class ReturnStatement extends Statement {
  Expression expression; // May be null.

  ReturnStatement([this.expression]) {
    expression?.parent = this;
  }

  accept(StatementVisitor v) => v.visitReturnStatement(this);
  accept1(StatementVisitor1 v, arg) => v.visitReturnStatement(this, arg);

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
  accept1(StatementVisitor1 v, arg) => v.visitTryCatch(this, arg);

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
  accept1(StatementVisitor1 v, arg) => v.visitTryFinally(this, arg);

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
  accept1(StatementVisitor1 v, arg) => v.visitYieldStatement(this, arg);

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

/// Categorization of a call site indicating its effect on type guarantees.
enum DispatchCategory {
  /// This call site binds to its callee through a specific interface.
  ///
  /// The front end guarantees that the target of the call exists, has the
  /// correct arity, and accepts all of the supplied named parameters.  Further,
  /// it guarantees that the number of type parameters supplied matches the
  /// number of type parameters expected by the target of the call.
  ///
  /// Due to parameter covariance, it is not necessarily guaranteed that the
  /// actual values of parameters will match the declared types of those
  /// parameters in the method actually being called.  A runtime type check is
  /// required for any parameter meeting one of the following conditions:
  ///
  /// - The parameter in the interface target is tagged with
  ///   `isGenericCovariantInterface`, and the corresponding parameter in the
  ///   method actually being called is tagged with `isGenericCovariantImpl`.
  ///
  /// - The parameter in the method actually being called is tagged with
  ///   `isCovariant`.
  ///
  /// Note: type parameters of generic methods require similar checks; the
  /// flags `isGenericCovariantInterface` and `isGenericCovariantImpl` are found
  /// in [TypeParameter], and the implementation must check that the actual
  /// type is a subtype of the type parameter bound declared in the actual
  /// method being called.  For type parameter checks, there is no `isCovariant`
  /// tag.
  ///
  /// Note: if the interface target or the method actually being called is a
  /// field, then the tags `isGenericCovariantInterface`,
  /// `isGenericCovariantImpl`, and `isCovariant` are found in [Field].
  interface,

  /// This call site binds to its callee via a call on `this`.
  ///
  /// Similar to [interface], however the target of the call is a method on
  /// `this` or `super`, therefore all of the class's type parameters are known
  /// to match exactly.
  ///
  /// Due to parameter covariance, it is not necessarily guaranteed that the
  /// actual values of parameters will match the declared types of those
  /// parameters in the method actually being called.  A runtime type check is
  /// required for any parameter meeting one of the following condition:
  ///
  /// - The parameter in the method actually being called is tagged with
  ///   `isCovariant`.
  ///
  /// Note: type parameters of generic methods do not require a check when the
  /// call is via `this`.
  ///
  /// Note: if the interface target or the method actually being called is a
  /// field, then the tag `isCovariant` is found in [Field].
  viaThis,

  /// This call site is an invocation of a function object (formed either by a
  /// tear off or a function literal).
  ///
  /// Similar to [interface], however the interface target of the call is not
  /// known.
  ///
  /// Due to parameter covariance, it is not necessarily guaranteed that the
  /// actual values of parameters will match the declared types of those
  /// parameters in the method actually being called.  A runtime type check is
  /// required for any parameter meeting one of the following conditions:
  ///
  /// - The parameter in the method actually being called is tagged with
  ///   `isGenericCovariantImpl`.
  ///
  /// - The parameter in the method actually being called is tagged with
  ///   `isCovariant`.
  ///
  /// Note: type parameters of generic methods require similar checks; the
  /// flag `isGenericCovariantImpl` is found in [TypeParameter], and the
  /// implementation must check that the actual type is a subtype of the type
  /// parameter bound declared in the actual method being called.  For type
  /// parameter checks, there is no `isCovariant` tag.
  ///
  /// Note: if the interface target or the method actually being called is a
  /// field, then the tags `isGenericCovariantImpl` and `isCovariant` are found
  /// in [Field].
  closure,

  /// The call site is dynamic.
  ///
  /// The front end makes no guarantees that the target of the call will accept
  /// the actual runtime types of the parameters, nor that the target of the
  /// call even exists.  Everything must be checked at runtime.
  dynamicDispatch,
}

/// Declaration of a local variable.
///
/// This may occur as a statement, but is also used in several non-statement
/// contexts, such as in [ForStatement], [Catch], and [FunctionNode].
///
/// When this occurs as a statement, it must be a direct child of a [Block].
//
// DESIGN TODO: Should we remove the 'final' modifier from variables?
@coqref
class VariableDeclaration extends Statement {
  /// Offset of the equals sign in the source file it comes from.
  ///
  /// Valid values are from 0 and up, or -1 ([TreeNode.noOffset])
  /// if the equals sign offset is not available (e.g. if not initialized)
  /// (this is the default if none is specifically set).
  int fileEqualsOffset = TreeNode.noOffset;

  /// For named parameters, this is the name of the parameter. No two named
  /// parameters (in the same parameter list) can have the same name.
  ///
  /// In all other cases, the name is cosmetic, may be empty or null,
  /// and is not necessarily unique.
  String name;
  int flags = 0;
  DartType type; // Not null, defaults to dynamic.

  /// Offset of the declaration, set and used when writing the binary.
  int binaryOffsetNoTag = -1;

  /// For locals, this is the initial value.
  /// For parameters, this is the default value.
  ///
  /// Should be null in other cases.
  @coqopt
  Expression initializer; // May be null.

  VariableDeclaration(this.name,
      {this.initializer,
      this.type: const DynamicType(),
      int flags: -1,
      bool isFinal: false,
      bool isConst: false,
      bool isFieldFormal: false,
      bool isCovariant: false}) {
    assert(type != null);
    initializer?.parent = this;
    if (flags != -1) {
      this.flags = flags;
    } else {
      this.isFinal = isFinal;
      this.isConst = isConst;
      this.isFieldFormal = isFieldFormal;
      this.isCovariant = isCovariant;
    }
  }

  /// Creates a synthetic variable with the given expression as initializer.
  VariableDeclaration.forValue(this.initializer,
      {bool isFinal: true,
      bool isConst: false,
      bool isFieldFormal: false,
      this.type: const DynamicType()}) {
    assert(type != null);
    initializer?.parent = this;
    this.isFinal = isFinal;
    this.isConst = isConst;
    this.isFieldFormal = isFieldFormal;
  }

  static const int FlagFinal = 1 << 0; // Must match serialized bit positions.
  static const int FlagConst = 1 << 1;
  static const int FlagFieldFormal = 1 << 2;
  static const int FlagCovariant = 1 << 3;
  static const int FlagInScope = 1 << 4; // Temporary flag used by verifier.
  static const int FlagGenericCovariantImpl = 1 << 5;
  static const int FlagGenericCovariantInterface = 1 << 6;

  bool get isFinal => flags & FlagFinal != 0;
  bool get isConst => flags & FlagConst != 0;

  /// Whether the parameter is declared with the `covariant` keyword.
  bool get isCovariant => flags & FlagCovariant != 0;

  /// Whether the variable is declared as a field formal parameter of
  /// a constructor.
  @informative
  bool get isFieldFormal => flags & FlagFieldFormal != 0;

  /// If this [VariableDeclaration] is a parameter of a method, indicates
  /// whether the method implementation needs to contain a runtime type check to
  /// deal with generic covariance.
  ///
  /// When `true`, runtime checks may need to be performed; see
  /// [DispatchCategory] for details.
  bool get isGenericCovariantImpl => flags & FlagGenericCovariantImpl != 0;

  /// If this [VariableDeclaration] is a parameter of a method, indicates
  /// whether invocations using the method as an interface target may need to
  /// perform a runtime type check to deal with generic covariance.
  ///
  /// When `true`, runtime checks may need to be performed; see
  /// [DispatchCategory] for details.
  bool get isGenericCovariantInterface =>
      flags & FlagGenericCovariantInterface != 0;

  void set isFinal(bool value) {
    flags = value ? (flags | FlagFinal) : (flags & ~FlagFinal);
  }

  void set isConst(bool value) {
    flags = value ? (flags | FlagConst) : (flags & ~FlagConst);
  }

  void set isCovariant(bool value) {
    flags = value ? (flags | FlagCovariant) : (flags & ~FlagCovariant);
  }

  @informative
  void set isFieldFormal(bool value) {
    flags = value ? (flags | FlagFieldFormal) : (flags & ~FlagFieldFormal);
  }

  void set isGenericCovariantImpl(bool value) {
    flags = value
        ? (flags | FlagGenericCovariantImpl)
        : (flags & ~FlagGenericCovariantImpl);
  }

  void set isGenericCovariantInterface(bool value) {
    flags = value
        ? (flags | FlagGenericCovariantInterface)
        : (flags & ~FlagGenericCovariantInterface);
  }

  accept(StatementVisitor v) => v.visitVariableDeclaration(this);
  accept1(StatementVisitor1 v, arg) => v.visitVariableDeclaration(this, arg);

  visitChildren(Visitor v) {
    type?.accept(v);
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
  accept1(StatementVisitor1 v, arg) => v.visitFunctionDeclaration(this, arg);

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
@coq
abstract class Name implements Node {
  final int hashCode;
  @coq
  final String name;
  @nocoq
  Reference get libraryName;
  @nocoq
  Library get library;
  bool get isPrivate;

  Name._internal(this.hashCode, this.name);

  factory Name(String name, [Library library]) =>
      new Name.byReference(name, library?.reference);

  factory Name.byReference(String name, Reference libraryName) {
    /// Use separate subclasses for the public and private case to save memory
    /// for public names.
    if (name.startsWith('_')) {
      assert(libraryName != null);
      return new _PrivateName(name, libraryName);
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
  final Reference libraryName;
  bool get isPrivate => true;

  _PrivateName(String name, Reference libraryName)
      : this.libraryName = libraryName,
        super._internal(_computeHashCode(name, libraryName), name);

  String toString() => library != null ? '$library::$name' : name;

  Library get library => libraryName.asLibrary;

  static int _computeHashCode(String name, Reference libraryName) {
    return 131 * name.hashCode + 17 * libraryName.hashCode;
  }
}

class _PublicName extends Name {
  Reference get libraryName => null;
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
@coq
abstract class DartType extends Node {
  const DartType();

  accept(DartTypeVisitor v);

  bool operator ==(Object other);

  /// If this is a typedef type, repeatedly unfolds its type definition until
  /// the root term is not a typedef type, otherwise returns the type itself.
  ///
  /// Will never return a typedef type.
  DartType get unalias => this;

  /// If this is a typedef type, unfolds its type definition once, otherwise
  /// returns the type itself.
  DartType get unaliasOnce => this;
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

@coq
class InterfaceType extends DartType {
  final Reference className;
  @nocoq
  final List<DartType> typeArguments;

  /// The [typeArguments] list must not be modified after this call. If the
  /// list is omitted, 'dynamic' type arguments are filled in.
  InterfaceType(Class classNode, [List<DartType> typeArguments])
      : this.byReference(getClassReference(classNode),
            typeArguments ?? _defaultTypeArguments(classNode));

  InterfaceType.byReference(this.className, this.typeArguments);

  Class get classNode => className.asClass;

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

  int get hashCode {
    int hash = 0x3fffffff & className.hashCode;
    for (int i = 0; i < typeArguments.length; ++i) {
      hash = 0x3fffffff & (hash * 31 + (hash ^ typeArguments[i].hashCode));
    }
    return hash;
  }
}

/// [VectorType] represents Vectors, a special kind of data that is not
/// available for use by Dart programmers directly. It is used by Kernel
/// transformations as efficient index-based storage.
///
/// * Vectors aren't user-visible. For example, they are not supposed to be
/// exposed to Dart programs through variables or be visible in stack traces.
///
/// * Vectors have fixed length at runtime. The length is known at compile
/// time, and [VectorCreation] AST node stores it in a field.
///
/// * Indexes for accessing and assigning Vector items are known at compile
/// time. The corresponding [VectorGet] and [VectorSet] AST nodes store the
/// index in a field.
///
/// * For efficiency considerations, bounds checks aren't performed for Vectors.
/// If necessary, a transformer or verifier can do this checks at compile-time,
/// after adding length field to [VectorType], to make sure that previous
/// transformations didn't introduce any access errors.
///
/// * Access to Vectors is untyped.
///
/// * Vectors can be used by various transformations of Kernel programs.
/// Currently they are used by Closure Conversion to represent closure contexts.
class VectorType extends DartType {
  const VectorType();

  accept(DartTypeVisitor v) => v.visitVectorType(this);
  visitChildren(Visitor v) {}
}

/// A possibly generic function type.
@coq
class FunctionType extends DartType {
  final List<TypeParameter> typeParameters;
  final int requiredParameterCount;
  @coqsingle
  final List<DartType> positionalParameters;
  final List<NamedType> namedParameters; // Must be sorted.

  /// The optional names of [positionalParameters], not `null`, but might be
  /// empty if information is not available.
  @informative
  final List<String> positionalParameterNames;

  /// The [Typedef] this function type is created for.
  @nocoq
  Reference typedefReference;

  final DartType returnType;
  int _hashCode;

  FunctionType(List<DartType> positionalParameters, this.returnType,
      {this.namedParameters: const <NamedType>[],
      this.typeParameters: const <TypeParameter>[],
      int requiredParameterCount,
      this.positionalParameterNames: const <String>[],
      this.typedefReference})
      : this.positionalParameters = positionalParameters,
        this.requiredParameterCount =
            requiredParameterCount ?? positionalParameters.length;

  /// The [Typedef] this function type is created for.
  Typedef get typedef => typedefReference?.asTypedef;

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

  /// Looks up the type of the named parameter with the given name.
  ///
  /// Returns `null` if there is no named parameter with the given name.
  DartType getNamedParameter(String name) {
    int lower = 0;
    int upper = namedParameters.length - 1;
    while (lower <= upper) {
      int pivot = (lower + upper) ~/ 2;
      var namedParameter = namedParameters[pivot];
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

/// A use of a [Typedef] as a type.
///
/// The underlying type can be extracted using [unalias].
class TypedefType extends DartType {
  final Reference typedefReference;
  final List<DartType> typeArguments;

  TypedefType(Typedef typedefNode, [List<DartType> typeArguments])
      : this.byReference(
            typedefNode.reference, typeArguments ?? const <DartType>[]);

  TypedefType.byReference(this.typedefReference, this.typeArguments);

  Typedef get typedefNode => typedefReference.asTypedef;

  accept(DartTypeVisitor v) => v.visitTypedefType(this);

  visitChildren(Visitor v) {
    visitList(typeArguments, v);
    v.visitTypedefReference(typedefNode);
  }

  DartType get unaliasOnce {
    return Substitution.fromTypedefType(this).substituteType(typedefNode.type);
  }

  DartType get unalias {
    return unaliasOnce.unalias;
  }

  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is TypedefType) {
      if (typedefReference != other.typedefReference ||
          typeArguments.length != other.typeArguments.length) {
        return false;
      }
      for (int i = 0; i < typeArguments.length; ++i) {
        if (typeArguments[i] != other.typeArguments[i]) return false;
      }
      return true;
    }
    return false;
  }

  int get hashCode {
    int hash = 0x3fffffff & typedefNode.hashCode;
    for (int i = 0; i < typeArguments.length; ++i) {
      hash = 0x3fffffff & (hash * 31 + (hash ^ typeArguments[i].hashCode));
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
///
/// A type variable has an optional bound because type promotion can change the
/// bound.  A bound of `null` indicates that the bound has not been promoted and
/// is the same as the [TypeParameter]'s bound.  This allows one to detect
/// whether the bound has been promoted.
class TypeParameterType extends DartType {
  TypeParameter parameter;

  /// An optional promoted bound on the type parameter.
  ///
  /// 'null' indicates that the type parameter's bound has not been promoted and
  /// is therefore the same as the bound of [parameter].
  DartType promotedBound;

  TypeParameterType(this.parameter, [this.promotedBound]);

  accept(DartTypeVisitor v) => v.visitTypeParameterType(this);

  visitChildren(Visitor v) {}

  bool operator ==(Object other) {
    return other is TypeParameterType && parameter == other.parameter;
  }

  int get hashCode => _temporaryHashCodeTable[parameter] ?? parameter.hashCode;

  /// Returns the bound of the type parameter, accounting for promotions.
  DartType get bound => promotedBound ?? parameter.bound;
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
  int flags = 0;

  String name; // Cosmetic name.

  /// The bound on the type variable.
  ///
  /// Should not be null except temporarily during IR construction.  Should
  /// be set to the root class for type parameters without an explicit bound.
  DartType bound;

  TypeParameter([this.name, this.bound]);

  // Must match serialized bit positions.
  static const int FlagGenericCovariantImpl = 1 << 0;
  static const int FlagGenericCovariantInterface = 1 << 1;

  /// If this [TypeParameter] is a type parameter of a generic method, indicates
  /// whether the method implementation needs to contain a runtime type check to
  /// deal with generic covariance.
  ///
  /// When `true`, runtime checks may need to be performed; see
  /// [DispatchCategory] for details.
  bool get isGenericCovariantImpl => flags & FlagGenericCovariantImpl != 0;

  /// If this [TypeParameter] is a type parameter of a generic method, indicates
  /// whether invocations using the method as an interface target may need to
  /// perform a runtime type check to deal with generic covariance.
  ///
  /// When `true`, runtime checks may need to be performed; see
  /// [DispatchCategory] for details.
  bool get isGenericCovariantInterface =>
      flags & FlagGenericCovariantInterface != 0;

  void set isGenericCovariantImpl(bool value) {
    flags = value
        ? (flags | FlagGenericCovariantImpl)
        : (flags & ~FlagGenericCovariantImpl);
  }

  void set isGenericCovariantInterface(bool value) {
    flags = value
        ? (flags | FlagGenericCovariantInterface)
        : (flags & ~FlagGenericCovariantInterface);
  }

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
  final Reference className;
  final List<DartType> typeArguments;

  Supertype(Class classNode, List<DartType> typeArguments)
      : this.byReference(getClassReference(classNode), typeArguments);

  Supertype.byReference(this.className, this.typeArguments);

  Class get classNode => className.asClass;

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

  int get hashCode {
    int hash = 0x3fffffff & className.hashCode;
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
  final CanonicalName root;

  final List<Library> libraries;

  /// Map from a source file uri to a line-starts table and source code.
  /// Given a source file uri and a offset in that file one can translate
  /// it to a line:column position in that file.
  final Map<String, Source> uriToSource;

  /// Reference to the main method in one of the libraries.
  Reference mainMethodName;

  Program(
      {CanonicalName nameRoot,
      List<Library> libraries,
      Map<String, Source> uriToSource})
      : root = nameRoot ?? new CanonicalName.root(),
        libraries = libraries ?? <Library>[],
        uriToSource = uriToSource ?? <String, Source>{} {
    setParents(this.libraries, this);
  }

  void computeCanonicalNames() {
    for (var library in libraries) {
      root.getChildFromUri(library.importUri).bindTo(library.reference);
      library.computeCanonicalNames();
    }
  }

  void unbindCanonicalNames() {
    root.unbindAll();
  }

  Procedure get mainMethod => mainMethodName?.asProcedure;

  void set mainMethod(Procedure main) {
    mainMethodName = getMemberReference(main);
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
    return uriToSource[file]?.getLocation(file, offset);
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

class Source {
  final List<int> lineStarts;

  final List<int> source;

  String cachedText;

  Source(this.lineStarts, this.source);

  /// Return the text corresponding to [line] which is a 1-based line
  /// number. The returned line contains no line separators.
  String getTextLine(int line) {
    RangeError.checkValueInInterval(line, 1, lineStarts.length, 'line');
    if (source == null) return null;

    cachedText ??= UTF8.decode(source, allowMalformed: true);
    // -1 as line numbers start at 1.
    int index = line - 1;
    if (index + 1 == lineStarts.length) {
      // Last line.
      return cachedText.substring(lineStarts[index]);
    } else if (index < lineStarts.length) {
      // We subtract 1 from the next line for two reasons:
      // 1. If the file isn't terminated by a newline, that index is invalid.
      // 2. To remove the newline at the end of the line.
      int endOfLine = lineStarts[index + 1] - 1;
      if (endOfLine > index && cachedText[endOfLine - 1] == "\r") {
        --endOfLine; // Windows line endings.
      }
      return cachedText.substring(lineStarts[index], endOfLine);
    }
    // This shouldn't happen: should have been caught by the range check above.
    throw "Internal error";
  }

  /// Translates an offset to line and column numbers in the given file.
  Location getLocation(String file, int offset) {
    RangeError.checkValueInInterval(offset, 0, lineStarts.last, 'offset');
    int low = 0, high = lineStarts.length - 1;
    while (low < high) {
      int mid = high - ((high - low) >> 1); // Get middle, rounding up.
      int pivot = lineStarts[mid];
      if (pivot <= offset) {
        low = mid;
      } else {
        high = mid - 1;
      }
    }
    int lineIndex = low;
    int lineStart = lineStarts[lineIndex];
    int lineNumber = 1 + lineIndex;
    int columnNumber = 1 + offset - lineStart;
    return new Location(file, lineNumber, columnNumber);
  }
}

/// Returns the [Reference] object for the given member.
///
/// Returns `null` if the member is `null`.
Reference getMemberReference(Member member) {
  return member?.reference;
}

/// Returns the [Reference] object for the given class.
///
/// Returns `null` if the class is `null`.
Reference getClassReference(Class class_) {
  return class_?.reference;
}

/// Returns the canonical name of [member], or throws an exception if the
/// member has not been assigned a canonical name yet.
///
/// Returns `null` if the member is `null`.
CanonicalName getCanonicalNameOfMember(Member member) {
  if (member == null) return null;
  if (member.canonicalName == null) {
    throw '$member has no canonical name';
  }
  return member.canonicalName;
}

/// Returns the canonical name of [class_], or throws an exception if the
/// class has not been assigned a canonical name yet.
///
/// Returns `null` if the class is `null`.
CanonicalName getCanonicalNameOfClass(Class class_) {
  if (class_ == null) return null;
  if (class_.canonicalName == null) {
    throw '$class_ has no canonical name';
  }
  return class_.canonicalName;
}

/// Returns the canonical name of [library], or throws an exception if the
/// library has not been assigned a canonical name yet.
///
/// Returns `null` if the library is `null`.
CanonicalName getCanonicalNameOfLibrary(Library library) {
  if (library == null) return null;
  if (library.canonicalName == null) {
    throw '$library has no canonical name';
  }
  return library.canonicalName;
}

/// Returns the canonical name of [typedef_], or throws an exception if the
/// typedef has not been assigned a canonical name yet.
///
/// Returns `null` if the typedef is `null`.
CanonicalName getCanonicalNameOfTypedef(Typedef typedef_) {
  if (typedef_ == null) return null;
  if (typedef_.canonicalName == null) {
    throw '$typedef_ has no canonical name';
  }
  return typedef_.canonicalName;
}

/// Annotation describing information which is not part of Dart semantics; in
/// other words, if this information (or any information it refers to) changes,
/// static analysis and runtime behavior of the library are unaffected.
const informative = null;
