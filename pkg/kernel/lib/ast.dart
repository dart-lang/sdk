// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// -----------------------------------------------------------------------
///                          WHEN CHANGING THIS FILE:
/// -----------------------------------------------------------------------
///
/// If you are adding/removing/modifying fields/classes of the AST, you must
/// also update the following files:
///
///   - binary/ast_to_binary.dart
///   - binary/ast_from_binary.dart
///   - text/ast_to_text.dart
///   - clone.dart
///   - binary.md
///   - type_checker.dart (if relevant)
///
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

import 'dart:collection' show ListBase;
import 'dart:convert' show utf8;

import 'visitor.dart';
export 'visitor.dart';

import 'canonical_name.dart' show CanonicalName;
export 'canonical_name.dart' show CanonicalName;

import 'transformations/flags.dart';
import 'text/ast_to_text.dart';
import 'type_algebra.dart';
import 'type_environment.dart';

/// Any type of node in the IR.
abstract class Node {
  const Node();

  R accept<R>(Visitor<R> v);
  void visitChildren(Visitor v);

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

  R accept<R>(TreeVisitor<R> v);
  void visitChildren(Visitor v);
  void transformChildren(Transformer v);

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

  Component get enclosingComponent => parent?.enclosingComponent;

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
abstract class NamedNode extends TreeNode {
  final Reference reference;

  NamedNode(Reference reference)
      : this.reference = reference ?? new Reference() {
    this.reference.node = this;
  }

  CanonicalName get canonicalName => reference?.canonicalName;
}

abstract class FileUriNode extends TreeNode {
  /// The URI of the source file this node was loaded from.
  Uri get fileUri;
}

abstract class Annotatable {
  List<Expression> get annotations;
  void addAnnotation(Expression node);
}

/// Indirection between a reference and its definition.
///
/// There is only one reference object per [NamedNode].
class Reference {
  CanonicalName canonicalName;

  NamedNode _node;

  NamedNode get node {
    if (_node == null) {
      // Either this is an unbound reference or it belongs to a lazy-loaded
      // (and not yet loaded) class. If it belongs to a lazy-loaded class,
      // load the class.

      CanonicalName canonicalNameParent = canonicalName?.parent;
      while (canonicalNameParent != null) {
        if (canonicalNameParent.name.startsWith("@")) {
          break;
        }
        canonicalNameParent = canonicalNameParent.parent;
      }
      if (canonicalNameParent != null) {
        NamedNode parentNamedNode =
            canonicalNameParent?.parent?.reference?._node;
        if (parentNamedNode is Class) {
          Class parentClass = parentNamedNode;
          if (parentClass.lazyBuilder != null) {
            parentClass.ensureLoaded();
          }
        }
      }
    }
    return _node;
  }

  void set node(NamedNode node) {
    _node = node;
  }

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

class Library extends NamedNode
    implements Annotatable, Comparable<Library>, FileUriNode {
  /// An import path to this library.
  ///
  /// The [Uri] should have the `dart`, `package`, `app`, or `file` scheme.
  ///
  /// If the URI has the `app` scheme, it is relative to the application root.
  Uri importUri;

  /// The URI of the source file this library was loaded from.
  Uri fileUri;

  // TODO(jensj): Do we have a better option than this?
  static int defaultLanguageVersionMajor = 2;
  static int defaultLanguageVersionMinor = 6;

  int _languageVersionMajor;
  int _languageVersionMinor;
  int get languageVersionMajor =>
      _languageVersionMajor ?? defaultLanguageVersionMajor;
  int get languageVersionMinor =>
      _languageVersionMinor ?? defaultLanguageVersionMinor;
  void setLanguageVersion(int languageVersionMajor, int languageVersionMinor) {
    if (languageVersionMajor == null || languageVersionMinor == null) {
      throw new StateError("Trying to set langauge version 'null'");
    }
    _languageVersionMajor = languageVersionMajor;
    _languageVersionMinor = languageVersionMinor;
  }

  static const int ExternalFlag = 1 << 0;
  static const int SyntheticFlag = 1 << 1;
  static const int NonNullableByDefaultFlag = 1 << 2;

  int flags = 0;

  /// If true, the library is part of another build unit and its contents
  /// are only partially loaded.
  ///
  /// Classes of an external library are loaded at one of the [ClassLevel]s
  /// other than [ClassLevel.Body].  Members in an external library have no
  /// body, but have their typed interface present.
  ///
  /// If the library is non-external, then its classes are at [ClassLevel.Body]
  /// and all members are loaded.
  bool get isExternal => (flags & ExternalFlag) != 0;
  void set isExternal(bool value) {
    flags = value ? (flags | ExternalFlag) : (flags & ~ExternalFlag);
  }

  /// If true, the library is synthetic, for instance library that doesn't
  /// represents an actual file and is created as the result of error recovery.
  bool get isSynthetic => flags & SyntheticFlag != 0;
  void set isSynthetic(bool value) {
    flags = value ? (flags | SyntheticFlag) : (flags & ~SyntheticFlag);
  }

  bool get isNonNullableByDefault => (flags & NonNullableByDefaultFlag) != 0;
  void set isNonNullableByDefault(bool value) {
    flags = value
        ? (flags | NonNullableByDefaultFlag)
        : (flags & ~NonNullableByDefaultFlag);
  }

  String name;

  /// Problems in this [Library] encoded as json objects.
  ///
  /// Note that this field can be null, and by convention should be null if the
  /// list is empty.
  List<String> problemsAsJson;

  final List<Expression> annotations;

  final List<LibraryDependency> dependencies;

  /// References to nodes exported by `export` declarations that:
  /// - aren't ambiguous, or
  /// - aren't hidden by local declarations.
  final List<Reference> additionalExports = <Reference>[];

  @informative
  final List<LibraryPart> parts;

  final List<Typedef> typedefs;
  final List<Class> classes;
  final List<Extension> extensions;
  final List<Procedure> procedures;
  final List<Field> fields;

  Library(this.importUri,
      {this.name,
      bool isExternal: false,
      List<Expression> annotations,
      List<LibraryDependency> dependencies,
      List<LibraryPart> parts,
      List<Typedef> typedefs,
      List<Class> classes,
      List<Extension> extensions,
      List<Procedure> procedures,
      List<Field> fields,
      this.fileUri,
      Reference reference})
      : this.annotations = annotations ?? <Expression>[],
        this.dependencies = dependencies ?? <LibraryDependency>[],
        this.parts = parts ?? <LibraryPart>[],
        this.typedefs = typedefs ?? <Typedef>[],
        this.classes = classes ?? <Class>[],
        this.extensions = extensions ?? <Extension>[],
        this.procedures = procedures ?? <Procedure>[],
        this.fields = fields ?? <Field>[],
        super(reference) {
    this.isExternal = isExternal;
    setParents(this.dependencies, this);
    setParents(this.parts, this);
    setParents(this.typedefs, this);
    setParents(this.classes, this);
    setParents(this.extensions, this);
    setParents(this.procedures, this);
    setParents(this.fields, this);
  }

  Nullability get nullable {
    return isNonNullableByDefault ? Nullability.nullable : Nullability.legacy;
  }

  Nullability get nonNullable {
    return isNonNullableByDefault
        ? Nullability.nonNullable
        : Nullability.legacy;
  }

  Nullability nullableIfTrue(bool isNullable) {
    if (isNonNullableByDefault) {
      return isNullable ? Nullability.nullable : Nullability.nonNullable;
    }
    return Nullability.legacy;
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

  void addAnnotation(Expression node) {
    node.parent = this;
    annotations.add(node);
  }

  void addClass(Class class_) {
    class_.parent = this;
    classes.add(class_);
  }

  void addExtension(Extension extension) {
    extension.parent = this;
    extensions.add(extension);
  }

  void addField(Field field) {
    field.parent = this;
    fields.add(field);
  }

  void addProcedure(Procedure procedure) {
    procedure.parent = this;
    procedures.add(procedure);
  }

  void addTypedef(Typedef typedef_) {
    typedef_.parent = this;
    typedefs.add(typedef_);
  }

  void computeCanonicalNames() {
    assert(canonicalName != null);
    for (int i = 0; i < typedefs.length; ++i) {
      Typedef typedef_ = typedefs[i];
      canonicalName.getChildFromTypedef(typedef_).bindTo(typedef_.reference);
    }
    for (int i = 0; i < fields.length; ++i) {
      Field field = fields[i];
      canonicalName.getChildFromMember(field).bindTo(field.reference);
    }
    for (int i = 0; i < procedures.length; ++i) {
      Procedure member = procedures[i];
      canonicalName.getChildFromMember(member).bindTo(member.reference);
    }
    for (int i = 0; i < classes.length; ++i) {
      Class class_ = classes[i];
      canonicalName.getChild(class_.name).bindTo(class_.reference);
      class_.computeCanonicalNames();
    }
    for (int i = 0; i < extensions.length; ++i) {
      Extension extension = extensions[i];
      canonicalName.getChild(extension.name).bindTo(extension.reference);
    }
  }

  void addDependency(LibraryDependency node) {
    dependencies.add(node..parent = this);
  }

  void addPart(LibraryPart node) {
    parts.add(node..parent = this);
  }

  R accept<R>(TreeVisitor<R> v) => v.visitLibrary(this);

  visitChildren(Visitor v) {
    visitList(annotations, v);
    visitList(dependencies, v);
    visitList(parts, v);
    visitList(typedefs, v);
    visitList(classes, v);
    visitList(extensions, v);
    visitList(procedures, v);
    visitList(fields, v);
  }

  transformChildren(Transformer v) {
    transformList(annotations, v, this);
    transformList(dependencies, v, this);
    transformList(parts, v, this);
    transformList(typedefs, v, this);
    transformList(classes, v, this);
    transformList(extensions, v, this);
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
    return _getLocationInComponent(enclosingComponent, fileUri, offset);
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

  R accept<R>(TreeVisitor<R> v) => v.visitLibraryDependency(this);

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
  final String partUri;

  LibraryPart(this.annotations, this.partUri) {
    setParents(annotations, this);
  }

  void addAnnotation(Expression annotation) {
    annotations.add(annotation..parent = this);
  }

  R accept<R>(TreeVisitor<R> v) => v.visitLibraryPart(this);

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
  R accept<R>(TreeVisitor<R> v) => v.visitCombinator(this);

  @override
  visitChildren(Visitor v) {}

  @override
  transformChildren(Transformer v) {}
}

/// Declaration of a type alias.
class Typedef extends NamedNode implements FileUriNode {
  /// The URI of the source file that contains the declaration of this typedef.
  Uri fileUri;
  List<Expression> annotations = const <Expression>[];
  String name;
  final List<TypeParameter> typeParameters;
  DartType type;

  // The following two fields describe parameters of the underlying function
  // type.  They are needed to keep such attributes as names and annotations.
  final List<TypeParameter> typeParametersOfFunctionType;
  final List<VariableDeclaration> positionalParameters;
  final List<VariableDeclaration> namedParameters;

  Typedef(this.name, this.type,
      {Reference reference,
      this.fileUri,
      List<TypeParameter> typeParameters,
      List<TypeParameter> typeParametersOfFunctionType,
      List<VariableDeclaration> positionalParameters,
      List<VariableDeclaration> namedParameters})
      : this.typeParameters = typeParameters ?? <TypeParameter>[],
        this.typeParametersOfFunctionType =
            typeParametersOfFunctionType ?? <TypeParameter>[],
        this.positionalParameters =
            positionalParameters ?? <VariableDeclaration>[],
        this.namedParameters = namedParameters ?? <VariableDeclaration>[],
        super(reference) {
    setParents(this.typeParameters, this);
  }

  Library get enclosingLibrary => parent;

  TypedefType get thisType {
    return new TypedefType(this, _getAsTypeArguments(typeParameters));
  }

  R accept<R>(TreeVisitor<R> v) {
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

  Location _getLocationInEnclosingFile(int offset) {
    return _getLocationInComponent(enclosingComponent, fileUri, offset);
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

/// List-wrapper that marks the parent-class as dirty if the list is modified.
///
/// The idea being, that for non-dirty classes (classes just loaded from dill)
/// the canonical names has already been calculated, and recalculating them is
/// not needed. If, however, we change anything, recalculation of the canonical
/// names can be needed.
class DirtifyingList<E> extends ListBase<E> {
  final Class dirtifyClass;
  final List<E> wrapped;

  DirtifyingList(this.dirtifyClass, this.wrapped);

  @override
  int get length {
    return wrapped.length;
  }

  @override
  void set length(int length) {
    dirtifyClass.dirty = true;
    wrapped.length = length;
  }

  @override
  E operator [](int index) {
    return wrapped[index];
  }

  @override
  void operator []=(int index, E value) {
    dirtifyClass.dirty = true;
    wrapped[index] = value;
  }
}

/// Declaration of a regular class or a mixin application.
///
/// Mixin applications may not contain fields or procedures, as they implicitly
/// use those from its mixed-in type.  However, the IR does not enforce this
/// rule directly, as doing so can obstruct transformations.  It is possible to
/// transform a mixin application to become a regular class, and vice versa.
class Class extends NamedNode implements Annotatable, FileUriNode {
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

  // Must match serialized bit positions.
  static const int LevelMask = 0x3; // Bits 0 and 1.
  static const int FlagAbstract = 1 << 2;
  static const int FlagEnum = 1 << 3;
  static const int FlagAnonymousMixin = 1 << 4;
  static const int FlagEliminatedMixin = 1 << 5;
  static const int FlagMixinDeclaration = 1 << 6;

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

  List<Supertype> superclassConstraints() {
    var constraints = <Supertype>[];

    // Not a mixin declaration.
    if (!isMixinDeclaration) return constraints;

    // Otherwise we have a left-linear binary tree (subtrees are supertype and
    // mixedInType) of constraints, where all the interior nodes are anonymous
    // mixin applications.
    Supertype current = supertype;
    while (current != null && current.classNode.isAnonymousMixin) {
      Class currentClass = current.classNode;
      assert(currentClass.implementedTypes.length == 2);
      Substitution substitution = Substitution.fromSupertype(current);
      constraints.add(
          substitution.substituteSupertype(currentClass.implementedTypes[1]));
      current =
          substitution.substituteSupertype(currentClass.implementedTypes[0]);
    }
    return constraints..add(current);
  }

  /// The URI of the source file this class was loaded from.
  Uri fileUri;

  final List<TypeParameter> typeParameters;

  /// The immediate super type, or `null` if this is the root class.
  Supertype supertype;

  /// The mixed-in type if this is a mixin application, otherwise `null`.
  Supertype mixedInType;

  /// The types from the `implements` clause.
  final List<Supertype> implementedTypes;

  /// Internal. Should *ONLY* be used from within kernel.
  ///
  /// If non-null, the function that will have to be called to fill-out the
  /// content of this class. Note that this should not be called directly though.
  void Function() lazyBuilder;

  /// Makes sure the class is loaded, i.e. the fields, procedures etc have been
  /// loaded from the dill. Generally, one should not need to call this as it is
  /// done automatically when accessing the lists.
  void ensureLoaded() {
    if (lazyBuilder != null) {
      var lazyBuilderLocal = lazyBuilder;
      lazyBuilder = null;
      lazyBuilderLocal();
    }
  }

  /// Internal. Should *ONLY* be used from within kernel.
  ///
  /// Used for adding fields when reading the dill file.
  final List<Field> fieldsInternal;
  DirtifyingList<Field> _fieldsView;

  /// Fields declared in the class.
  ///
  /// For mixin applications this should be empty.
  List<Field> get fields {
    ensureLoaded();
    // If already dirty the caller just might as well add stuff directly too.
    if (dirty) return fieldsInternal;
    _fieldsView ??= new DirtifyingList(this, fieldsInternal);
    return _fieldsView;
  }

  /// Internal. Should *ONLY* be used from within kernel.
  ///
  /// Used for adding constructors when reading the dill file.
  final List<Constructor> constructorsInternal;
  DirtifyingList<Constructor> _constructorsView;

  /// Constructors declared in the class.
  List<Constructor> get constructors {
    ensureLoaded();
    // If already dirty the caller just might as well add stuff directly too.
    if (dirty) return constructorsInternal;
    _constructorsView ??= new DirtifyingList(this, constructorsInternal);
    return _constructorsView;
  }

  /// Internal. Should *ONLY* be used from within kernel.
  ///
  /// Used for adding procedures when reading the dill file.
  final List<Procedure> proceduresInternal;
  DirtifyingList<Procedure> _proceduresView;

  /// Procedures declared in the class.
  ///
  /// For mixin applications this should only contain forwarding stubs.
  List<Procedure> get procedures {
    ensureLoaded();
    // If already dirty the caller just might as well add stuff directly too.
    if (dirty) return proceduresInternal;
    _proceduresView ??= new DirtifyingList(this, proceduresInternal);
    return _proceduresView;
  }

  /// Internal. Should *ONLY* be used from within kernel.
  ///
  /// Used for adding redirecting factory constructor when reading the dill
  /// file.
  final List<RedirectingFactoryConstructor>
      redirectingFactoryConstructorsInternal;
  DirtifyingList<RedirectingFactoryConstructor>
      _redirectingFactoryConstructorsView;

  /// Redirecting factory constructors declared in the class.
  ///
  /// For mixin applications this should be empty.
  List<RedirectingFactoryConstructor> get redirectingFactoryConstructors {
    ensureLoaded();
    // If already dirty the caller just might as well add stuff directly too.
    if (dirty) return redirectingFactoryConstructorsInternal;
    _redirectingFactoryConstructorsView ??=
        new DirtifyingList(this, redirectingFactoryConstructorsInternal);
    return _redirectingFactoryConstructorsView;
  }

  Class(
      {this.name,
      bool isAbstract: false,
      bool isAnonymousMixin: false,
      this.supertype,
      this.mixedInType,
      List<TypeParameter> typeParameters,
      List<Supertype> implementedTypes,
      List<Constructor> constructors,
      List<Procedure> procedures,
      List<Field> fields,
      List<RedirectingFactoryConstructor> redirectingFactoryConstructors,
      this.fileUri,
      Reference reference})
      : this.typeParameters = typeParameters ?? <TypeParameter>[],
        this.implementedTypes = implementedTypes ?? <Supertype>[],
        this.fieldsInternal = fields ?? <Field>[],
        this.constructorsInternal = constructors ?? <Constructor>[],
        this.proceduresInternal = procedures ?? <Procedure>[],
        this.redirectingFactoryConstructorsInternal =
            redirectingFactoryConstructors ?? <RedirectingFactoryConstructor>[],
        super(reference) {
    setParents(this.typeParameters, this);
    setParents(this.constructorsInternal, this);
    setParents(this.proceduresInternal, this);
    setParents(this.fieldsInternal, this);
    setParents(this.redirectingFactoryConstructorsInternal, this);
    this.isAbstract = isAbstract;
    this.isAnonymousMixin = isAnonymousMixin;
  }

  void computeCanonicalNames() {
    assert(canonicalName != null);
    if (!dirty) return;
    for (int i = 0; i < fields.length; ++i) {
      Field member = fields[i];
      canonicalName.getChildFromMember(member).bindTo(member.reference);
    }
    for (int i = 0; i < procedures.length; ++i) {
      Procedure member = procedures[i];
      canonicalName.getChildFromMember(member).bindTo(member.reference);
    }
    for (int i = 0; i < constructors.length; ++i) {
      Constructor member = constructors[i];
      canonicalName.getChildFromMember(member).bindTo(member.reference);
    }
    for (int i = 0; i < redirectingFactoryConstructors.length; ++i) {
      RedirectingFactoryConstructor member = redirectingFactoryConstructors[i];
      canonicalName.getChildFromMember(member).bindTo(member.reference);
    }
    dirty = false;
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
        redirectingFactoryConstructors
      ].expand((x) => x);

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

  /// Internal. Should *ONLY* be used from within kernel.
  ///
  /// If true we have to compute canonical names for all children of this class.
  /// if false we can skip it.
  bool dirty = true;

  /// Adds a member to this class.
  ///
  /// Throws an error if attempting to add a field or procedure to a mixin
  /// application.
  void addMember(Member member) {
    dirty = true;
    member.parent = this;
    if (member is Constructor) {
      constructorsInternal.add(member);
    } else if (member is Procedure) {
      proceduresInternal.add(member);
    } else if (member is Field) {
      fieldsInternal.add(member);
    } else if (member is RedirectingFactoryConstructor) {
      redirectingFactoryConstructorsInternal.add(member);
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

  R accept<R>(TreeVisitor<R> v) => v.visitClass(this);
  R acceptReference<R>(Visitor<R> v) => v.visitClassReference(this);

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
    visitList(redirectingFactoryConstructors, v);
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
    transformList(redirectingFactoryConstructors, v, this);
  }

  Location _getLocationInEnclosingFile(int offset) {
    return _getLocationInComponent(enclosingComponent, fileUri, offset);
  }
}

/// Declaration of an extension.
///
/// The members are converted into top-level procedures and only accessible
/// by reference in the [Extension] node.
class Extension extends NamedNode implements FileUriNode {
  /// Name of the extension.
  ///
  /// If unnamed, the extension will be given a synthesized name by the
  /// front end.
  String name;

  /// The URI of the source file this class was loaded from.
  Uri fileUri;

  /// Type parameters declared on the extension.
  final List<TypeParameter> typeParameters;

  /// The type in the 'on clause' of the extension declaration.
  ///
  /// For instance A in:
  ///
  ///   class A {}
  ///   extension B on A {}
  ///
  DartType onType;

  /// The members declared by the extension.
  ///
  /// The members are converted into top-level members and only accessible
  /// by reference through [ExtensionMemberDescriptor].
  final List<ExtensionMemberDescriptor> members;

  Extension(
      {this.name,
      List<TypeParameter> typeParameters,
      this.onType,
      List<Reference> members,
      this.fileUri,
      Reference reference})
      : this.typeParameters = typeParameters ?? <TypeParameter>[],
        this.members = members ?? <ExtensionMemberDescriptor>[],
        super(reference) {
    setParents(this.typeParameters, this);
  }

  Library get enclosingLibrary => parent;

  @override
  R accept<R>(TreeVisitor<R> v) => v.visitExtension(this);

  @override
  visitChildren(Visitor v) {
    visitList(typeParameters, v);
    onType?.accept(v);
  }

  @override
  transformChildren(Transformer v) {
    transformList(typeParameters, v, this);
    if (onType != null) {
      onType = v.visitDartType(onType);
    }
  }
}

enum ExtensionMemberKind {
  Field,
  Method,
  Getter,
  Setter,
  Operator,
  TearOff,
}

/// Information about an member declaration in an extension.
class ExtensionMemberDescriptor {
  static const int FlagStatic = 1 << 0; // Must match serialized bit positions.

  /// The name of the extension member.
  ///
  /// The name of the generated top-level member is mangled to ensure
  /// uniqueness. This name is used to lookup an extension method the
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
  Reference member;

  ExtensionMemberDescriptor(
      {this.name, this.kind, bool isStatic: false, this.member}) {
    this.isStatic = isStatic;
  }

  /// Return `true` if the extension method was declared as `static`.
  bool get isStatic => flags & FlagStatic != 0;

  void set isStatic(bool value) {
    flags = value ? (flags | FlagStatic) : (flags & ~FlagStatic);
  }
}

// ------------------------------------------------------------------------
//                            MEMBERS
// ------------------------------------------------------------------------

abstract class Member extends NamedNode implements Annotatable, FileUriNode {
  /// End offset in the source file it comes from.
  ///
  /// Valid values are from 0 and up, or -1 ([TreeNode.noOffset]) if the file
  /// end offset is not available (this is the default if none is specifically
  /// set).
  int fileEndOffset = TreeNode.noOffset;

  /// List of metadata annotations on the member.
  ///
  /// This defaults to an immutable empty list. Use [addAnnotation] to add
  /// annotations if needed.
  List<Expression> annotations = const <Expression>[];

  Name name;

  /// The URI of the source file this member was loaded from.
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

  Member(this.name, this.fileUri, Reference reference) : super(reference);

  Class get enclosingClass => parent is Class ? parent : null;
  Library get enclosingLibrary => parent is Class ? parent.parent : parent;

  R accept<R>(MemberVisitor<R> v);
  acceptReference(MemberReferenceVisitor v);

  /// If true, the member is part of an external library, that is, it is defined
  /// in another build unit.  Such members have no body or initializer present
  /// in the IR.
  bool get isInExternalLibrary => enclosingLibrary.isExternal;

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
  void set isExternal(bool value);

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

  Field(Name name,
      {this.type: const DynamicType(),
      this.initializer,
      bool isCovariant: false,
      bool isFinal: false,
      bool isConst: false,
      bool isStatic: false,
      bool hasImplicitGetter,
      bool hasImplicitSetter,
      bool isLate: false,
      int transformerFlags: 0,
      Uri fileUri,
      Reference reference})
      : super(name, fileUri, reference) {
    assert(type != null);
    initializer?.parent = this;
    this.isCovariant = isCovariant;
    this.isFinal = isFinal;
    this.isConst = isConst;
    this.isStatic = isStatic;
    this.isLate = isLate;
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
  static const int FlagLate = 1 << 7;
  static const int FlagExtensionMember = 1 << 8;

  /// Whether the field is declared with the `covariant` keyword.
  bool get isCovariant => flags & FlagCovariant != 0;

  bool get isFinal => flags & FlagFinal != 0;
  bool get isConst => flags & FlagConst != 0;
  bool get isStatic => flags & FlagStatic != 0;

  @override
  bool get isExtensionMember => flags & FlagExtensionMember != 0;

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

  /// Whether the field is declared with the `late` keyword.
  bool get isLate => flags & FlagLate != 0;

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

  void set isExtensionMember(bool value) {
    flags =
        value ? (flags | FlagExtensionMember) : (flags & ~FlagExtensionMember);
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

  void set isLate(bool value) {
    flags = value ? (flags | FlagLate) : (flags & ~FlagLate);
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

  R accept<R>(MemberVisitor<R> v) => v.visitField(this);

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
      initializer = initializer.accept<TreeNode>(v);
      initializer?.parent = this;
    }
  }

  DartType get getterType => type;
  DartType get setterType => isMutable ? type : const BottomType();

  Location _getLocationInEnclosingFile(int offset) {
    return _getLocationInComponent(enclosingComponent, fileUri, offset);
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

  int flags = 0;
  FunctionNode function;
  List<Initializer> initializers;

  Constructor(this.function,
      {Name name,
      bool isConst: false,
      bool isExternal: false,
      bool isSynthetic: false,
      List<Initializer> initializers,
      int transformerFlags: 0,
      Uri fileUri,
      Reference reference})
      : this.initializers = initializers ?? <Initializer>[],
        super(name, fileUri, reference) {
    function?.parent = this;
    setParents(this.initializers, this);
    this.isConst = isConst;
    this.isExternal = isExternal;
    this.isSynthetic = isSynthetic;
    this.transformerFlags = transformerFlags;
  }

  static const int FlagConst = 1 << 0; // Must match serialized bit positions.
  static const int FlagExternal = 1 << 1;
  static const int FlagSynthetic = 1 << 2;

  bool get isConst => flags & FlagConst != 0;
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

  bool get isInstanceMember => false;
  bool get hasGetter => false;
  bool get hasSetter => false;

  @override
  bool get isExtensionMember => false;

  R accept<R>(MemberVisitor<R> v) => v.visitConstructor(this);

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
      function = function.accept<TreeNode>(v);
      function?.parent = this;
    }
  }

  DartType get getterType => const BottomType();
  DartType get setterType => const BottomType();

  Location _getLocationInEnclosingFile(int offset) {
    return _getLocationInComponent(enclosingComponent, fileUri, offset);
  }
}

/// Residue of a redirecting factory constructor for the linking phase.
///
/// In the following example, `bar` is a redirecting factory constructor.
///
///     class A {
///       A.foo();
///       factory A.bar() = A.foo;
///     }
///
/// An invocation of `new A.bar()` has the same effect as an invocation of
/// `new A.foo()`.  In Kernel, the invocations of `bar` are replaced with
/// invocations of `foo`, and after it is done, the redirecting constructor can
/// be removed from the class.  However, it is needed during the linking phase,
/// because other modules can refer to that constructor.
///
/// [RedirectingFactoryConstructor]s contain the necessary information for
/// linking and are treated as non-runnable members of classes that merely serve
/// as containers for that information.
///
/// Redirecting factory constructors can be unnamed.  In this case, the name is
/// an empty string (in a [Name]).
class RedirectingFactoryConstructor extends Member {
  int flags = 0;

  /// [RedirectingFactoryConstructor]s may redirect to constructors or factories
  /// of instantiated generic types, that is, generic types with supplied type
  /// arguments.  The supplied type arguments are stored in this field.
  final List<DartType> typeArguments;

  /// Reference to the constructor or the factory that this
  /// [RedirectingFactoryConstructor] redirects to.
  Reference targetReference;

  /// [typeParameters] are duplicates of the type parameters of the enclosing
  /// class.  Because [RedirectingFactoryConstructor]s aren't instance members,
  /// references to the type parameters of the enclosing class in the
  /// redirection target description are encoded with references to the elements
  /// of [typeParameters].
  List<TypeParameter> typeParameters;

  /// Positional parameters of [RedirectingFactoryConstructor]s should be
  /// compatible with that of the target constructor.
  List<VariableDeclaration> positionalParameters;
  int requiredParameterCount;

  /// Named parameters of [RedirectingFactoryConstructor]s should be compatible
  /// with that of the target constructor.
  List<VariableDeclaration> namedParameters;

  RedirectingFactoryConstructor(this.targetReference,
      {Name name,
      bool isConst: false,
      bool isExternal: false,
      int transformerFlags: 0,
      List<DartType> typeArguments,
      List<TypeParameter> typeParameters,
      List<VariableDeclaration> positionalParameters,
      List<VariableDeclaration> namedParameters,
      int requiredParameterCount,
      Uri fileUri,
      Reference reference})
      : this.typeArguments = typeArguments ?? <DartType>[],
        this.typeParameters = typeParameters ?? <TypeParameter>[],
        this.positionalParameters =
            positionalParameters ?? <VariableDeclaration>[],
        this.namedParameters = namedParameters ?? <VariableDeclaration>[],
        this.requiredParameterCount =
            requiredParameterCount ?? positionalParameters?.length ?? 0,
        super(name, fileUri, reference) {
    setParents(this.typeParameters, this);
    setParents(this.positionalParameters, this);
    setParents(this.namedParameters, this);
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

  @override
  bool get isExtensionMember => false;

  bool get isUnresolved => targetReference == null;

  Member get target => targetReference?.asMember;

  void set target(Member member) {
    assert(member is Constructor ||
        (member is Procedure && member.kind == ProcedureKind.Factory));
    targetReference = getMemberReference(member);
  }

  R accept<R>(MemberVisitor<R> v) => v.visitRedirectingFactoryConstructor(this);

  acceptReference(MemberReferenceVisitor v) =>
      v.visitRedirectingFactoryConstructorReference(this);

  visitChildren(Visitor v) {
    visitList(annotations, v);
    target?.acceptReference(v);
    visitList(typeArguments, v);
    name?.accept(v);
  }

  transformChildren(Transformer v) {
    transformList(annotations, v, this);
    transformTypeList(typeArguments, v);
  }

  DartType get getterType => const BottomType();
  DartType get setterType => const BottomType();

  Location _getLocationInEnclosingFile(int offset) {
    return _getLocationInComponent(enclosingComponent, fileUri, offset);
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
  /// Start offset of the function in the source file it comes from.
  ///
  /// Note that this includes annotations if any.
  ///
  /// Valid values are from 0 and up, or -1 ([TreeNode.noOffset]) if the file
  /// start offset is not available (this is the default if none is specifically
  /// set).
  int startFileOffset = TreeNode.noOffset;

  ProcedureKind kind;
  int flags = 0;
  // function is null if and only if abstract, external.
  FunctionNode function;

  // The function node's body might be lazily loaded, meaning that this value
  // might not be set correctly yet. Make sure the body is loaded before
  // returning anything.
  int get transformerFlags {
    function?.body;
    return super.transformerFlags;
  }

  // The function node's body might be lazily loaded, meaning that this value
  // might get overwritten later (when the body is read). To avoid that read the
  // body now and only set the value afterwards.
  void set transformerFlags(int newValue) {
    function?.body;
    super.transformerFlags = newValue;
  }

  // This function will set the transformer flags without loading the body.
  // Used when reading the binary. For other cases one should probably use
  // `transformerFlags = value;`.
  void setTransformerFlagsWithoutLazyLoading(int newValue) {
    super.transformerFlags = newValue;
  }

  Reference forwardingStubSuperTargetReference;
  Reference forwardingStubInterfaceTargetReference;

  Procedure(Name name, ProcedureKind kind, FunctionNode function,
      {bool isAbstract: false,
      bool isStatic: false,
      bool isExternal: false,
      bool isConst: false,
      bool isForwardingStub: false,
      bool isForwardingSemiStub: false,
      bool isExtensionMember: false,
      int transformerFlags: 0,
      Uri fileUri,
      Reference reference,
      Member forwardingStubSuperTarget,
      Member forwardingStubInterfaceTarget})
      : this.byReference(name, kind, function,
            isAbstract: isAbstract,
            isStatic: isStatic,
            isExternal: isExternal,
            isConst: isConst,
            isForwardingStub: isForwardingStub,
            isForwardingSemiStub: isForwardingSemiStub,
            isExtensionMember: isExtensionMember,
            transformerFlags: transformerFlags,
            fileUri: fileUri,
            reference: reference,
            forwardingStubSuperTargetReference:
                getMemberReference(forwardingStubSuperTarget),
            forwardingStubInterfaceTargetReference:
                getMemberReference(forwardingStubInterfaceTarget));

  Procedure.byReference(Name name, this.kind, this.function,
      {bool isAbstract: false,
      bool isStatic: false,
      bool isExternal: false,
      bool isConst: false,
      bool isForwardingStub: false,
      bool isForwardingSemiStub: false,
      bool isExtensionMember: false,
      int transformerFlags: 0,
      Uri fileUri,
      Reference reference,
      this.forwardingStubSuperTargetReference,
      this.forwardingStubInterfaceTargetReference})
      : super(name, fileUri, reference) {
    function?.parent = this;
    this.isAbstract = isAbstract;
    this.isStatic = isStatic;
    this.isExternal = isExternal;
    this.isConst = isConst;
    this.isForwardingStub = isForwardingStub;
    this.isForwardingSemiStub = isForwardingSemiStub;
    this.isExtensionMember = isExtensionMember;
    this.transformerFlags = transformerFlags;
  }

  static const int FlagStatic = 1 << 0; // Must match serialized bit positions.
  static const int FlagAbstract = 1 << 1;
  static const int FlagExternal = 1 << 2;
  static const int FlagConst = 1 << 3; // Only for external const factories.
  static const int FlagForwardingStub = 1 << 4;
  static const int FlagForwardingSemiStub = 1 << 5;
  // TODO(29841): Remove this flag after the issue is resolved.
  static const int FlagRedirectingFactoryConstructor = 1 << 6;
  static const int FlagNoSuchMethodForwarder = 1 << 7;
  static const int FlagExtensionMember = 1 << 8;

  bool get isStatic => flags & FlagStatic != 0;
  bool get isAbstract => flags & FlagAbstract != 0;
  bool get isExternal => flags & FlagExternal != 0;

  /// True if this has the `const` modifier.  This is only possible for external
  /// constant factories, such as `String.fromEnvironment`.
  bool get isConst => flags & FlagConst != 0;

  /// If set, this flag indicates that this function's implementation exists
  /// solely for the purpose of type checking arguments and forwarding to
  /// [forwardingStubSuperTarget].
  ///
  /// Note that just because this bit is set doesn't mean that the function was
  /// not declared in the source; it's possible that this is a forwarding
  /// semi-stub (see isForwardingSemiStub).  To determine whether this function
  /// was present in the source, consult [isSyntheticForwarder].
  bool get isForwardingStub => flags & FlagForwardingStub != 0;

  /// If set, this flag indicates that although this function is a forwarding
  /// stub, it was present in the original source as an abstract method.
  bool get isForwardingSemiStub => flags & FlagForwardingSemiStub != 0;

  // Indicates if this [Procedure] represents a redirecting factory constructor
  // and doesn't have a runnable body.
  bool get isRedirectingFactoryConstructor {
    return flags & FlagRedirectingFactoryConstructor != 0;
  }

  /// If set, this flag indicates that this function was not present in the
  /// source, and it exists solely for the purpose of type checking arguments
  /// and forwarding to [forwardingStubSuperTarget].
  bool get isSyntheticForwarder => isForwardingStub && !isForwardingSemiStub;

  bool get isNoSuchMethodForwarder => flags & FlagNoSuchMethodForwarder != 0;

  @override
  bool get isExtensionMember => flags & FlagExtensionMember != 0;

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

  void set isForwardingStub(bool value) {
    flags =
        value ? (flags | FlagForwardingStub) : (flags & ~FlagForwardingStub);
  }

  void set isForwardingSemiStub(bool value) {
    flags = value
        ? (flags | FlagForwardingSemiStub)
        : (flags & ~FlagForwardingSemiStub);
  }

  void set isRedirectingFactoryConstructor(bool value) {
    flags = value
        ? (flags | FlagRedirectingFactoryConstructor)
        : (flags & ~FlagRedirectingFactoryConstructor);
  }

  void set isNoSuchMethodForwarder(bool value) {
    flags = value
        ? (flags | FlagNoSuchMethodForwarder)
        : (flags & ~FlagNoSuchMethodForwarder);
  }

  void set isExtensionMember(bool value) {
    flags =
        value ? (flags | FlagExtensionMember) : (flags & ~FlagExtensionMember);
  }

  bool get isInstanceMember => !isStatic;
  bool get isGetter => kind == ProcedureKind.Getter;
  bool get isSetter => kind == ProcedureKind.Setter;
  bool get isAccessor => isGetter || isSetter;
  bool get hasGetter => kind != ProcedureKind.Setter;
  bool get hasSetter => kind == ProcedureKind.Setter;
  bool get isFactory => kind == ProcedureKind.Factory;

  Member get forwardingStubSuperTarget =>
      forwardingStubSuperTargetReference?.asMember;

  void set forwardingStubSuperTarget(Member target) {
    forwardingStubSuperTargetReference = getMemberReference(target);
  }

  Member get forwardingStubInterfaceTarget =>
      forwardingStubInterfaceTargetReference?.asMember;

  void set forwardingStubInterfaceTarget(Member target) {
    forwardingStubInterfaceTargetReference = getMemberReference(target);
  }

  R accept<R>(MemberVisitor<R> v) => v.visitProcedure(this);

  acceptReference(MemberReferenceVisitor v) => v.visitProcedureReference(this);

  visitChildren(Visitor v) {
    visitList(annotations, v);
    name?.accept(v);
    function?.accept(v);
  }

  transformChildren(Transformer v) {
    transformList(annotations, v, this);
    if (function != null) {
      function = function.accept<TreeNode>(v);
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
    return _getLocationInComponent(enclosingComponent, fileUri, offset);
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

  R accept<R>(InitializerVisitor<R> v);
}

/// An initializer with a compile-time error.
///
/// Should throw an exception at runtime.
//
// DESIGN TODO: The frontend should use this in a lot more cases to catch
// invalid cases.
class InvalidInitializer extends Initializer {
  R accept<R>(InitializerVisitor<R> v) => v.visitInvalidInitializer(this);

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

  R accept<R>(InitializerVisitor<R> v) => v.visitFieldInitializer(this);

  visitChildren(Visitor v) {
    field?.acceptReference(v);
    value?.accept(v);
  }

  transformChildren(Transformer v) {
    if (value != null) {
      value = value.accept<TreeNode>(v);
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

  R accept<R>(InitializerVisitor<R> v) => v.visitSuperInitializer(this);

  visitChildren(Visitor v) {
    target?.acceptReference(v);
    arguments?.accept(v);
  }

  transformChildren(Transformer v) {
    if (arguments != null) {
      arguments = arguments.accept<TreeNode>(v);
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

  R accept<R>(InitializerVisitor<R> v) => v.visitRedirectingInitializer(this);

  visitChildren(Visitor v) {
    target?.acceptReference(v);
    arguments?.accept(v);
  }

  transformChildren(Transformer v) {
    if (arguments != null) {
      arguments = arguments.accept<TreeNode>(v);
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

  R accept<R>(InitializerVisitor<R> v) => v.visitLocalInitializer(this);

  visitChildren(Visitor v) {
    variable?.accept(v);
  }

  transformChildren(Transformer v) {
    if (variable != null) {
      variable = variable.accept<TreeNode>(v);
      variable?.parent = this;
    }
  }
}

class AssertInitializer extends Initializer {
  AssertStatement statement;

  AssertInitializer(this.statement) {
    statement.parent = this;
  }

  R accept<R>(InitializerVisitor<R> v) => v.visitAssertInitializer(this);

  visitChildren(Visitor v) {
    statement.accept(v);
  }

  transformChildren(Transformer v) {
    statement = statement.accept<TreeNode>(v);
    statement.parent = this;
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
  List<VariableDeclaration> positionalParameters;
  List<VariableDeclaration> namedParameters;
  DartType returnType; // Not null.
  Statement _body;

  void Function() lazyBuilder;

  void _buildLazy() {
    if (lazyBuilder != null) {
      var lazyBuilderLocal = lazyBuilder;
      lazyBuilder = null;
      lazyBuilderLocal();
    }
  }

  Statement get body {
    _buildLazy();
    return _body;
  }

  void set body(Statement body) {
    _buildLazy();
    _body = body;
  }

  FunctionNode(this._body,
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
    _body?.parent = this;
    dartAsyncMarker ??= asyncMarker;
  }

  static DartType _getTypeOfVariable(VariableDeclaration node) => node.type;

  static NamedType _getNamedTypeOfVariable(VariableDeclaration node) {
    return new NamedType(node.name, node.type, isRequired: node.isRequired);
  }

  /// Returns the function type of the node reusing its type parameters.
  ///
  /// This getter works similarly to [functionType], but reuses type parameters
  /// of the function node (or the class enclosing it -- see the comment on
  /// [functionType] about constructors of generic classes) in the result.  It
  /// is useful in some contexts, especially when reasoning about the function
  /// type of the enclosing generic function and in combination with
  /// [FunctionType.withoutTypeParameters].
  FunctionType get thisFunctionType {
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

  /// Returns the function type of the function node.
  ///
  /// If the function node describes a generic function, the resulting function
  /// type will be generic.  If the function node describes a constructor of a
  /// generic class, the resulting function type will be generic with its type
  /// parameters constructed after those of the class.  In both cases, if the
  /// resulting function type is generic, a fresh set of type parameters is used
  /// in it.
  FunctionType get functionType {
    return typeParameters.isEmpty
        ? thisFunctionType
        : getFreshTypeParameters(typeParameters)
            .applyToFunctionType(thisFunctionType);
  }

  R accept<R>(TreeVisitor<R> v) => v.visitFunctionNode(this);

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
      body = body.accept<TreeNode>(v);
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
  /// Shouldn't be used on code compiled in legacy mode, as this method assumes
  /// the IR is strongly typed.
  DartType getStaticType(TypeEnvironment types);

  /// Returns the static type of the expression as an instantiation of
  /// [superclass].
  ///
  /// Shouldn't be used on code compiled in legacy mode, as this method assumes
  /// the IR is strongly typed.
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
      return types.coreTypes.legacyRawType(superclass);
    }
    var type = getStaticType(types);
    while (type is TypeParameterType) {
      type = (type as TypeParameterType).parameter.bound;
    }
    if (type == types.nullType) {
      return superclass.bottomType;
    }
    if (type is InterfaceType) {
      var upcastType = types.getTypeAsInstanceOf(type, superclass);
      if (upcastType != null) return upcastType;
    } else if (type is BottomType) {
      return superclass.bottomType;
    }
    types.typeError(this, '$type is not a subtype of $superclass');
    return types.coreTypes.legacyRawType(superclass);
  }

  R accept<R>(ExpressionVisitor<R> v);
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg);
}

/// An expression containing compile-time errors.
///
/// Should throw a runtime error when evaluated.
///
/// The [fileOffset] of an [InvalidExpression] indicates the location in the
/// tree where the expression occurs, rather than the location of the error.
class InvalidExpression extends Expression {
  String message;

  InvalidExpression(this.message);

  DartType getStaticType(TypeEnvironment types) => const BottomType();

  R accept<R>(ExpressionVisitor<R> v) => v.visitInvalidExpression(this);
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitInvalidExpression(this, arg);

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

  R accept<R>(ExpressionVisitor<R> v) => v.visitVariableGet(this);
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitVariableGet(this, arg);

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

  R accept<R>(ExpressionVisitor<R> v) => v.visitVariableSet(this);
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitVariableSet(this, arg);

  visitChildren(Visitor v) {
    value?.accept(v);
  }

  transformChildren(Transformer v) {
    if (value != null) {
      value = value.accept<TreeNode>(v);
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

  Reference interfaceTargetReference;

  PropertyGet(Expression receiver, Name name, [Member interfaceTarget])
      : this.byReference(receiver, name, getMemberReference(interfaceTarget));

  PropertyGet.byReference(
      this.receiver, this.name, this.interfaceTargetReference) {
    receiver?.parent = this;
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
      return Substitution.fromInterfaceType(receiverType)
          .substituteType(interfaceTarget.getterType);
    }
    // Treat the properties of Object specially.
    String nameString = name.name;
    if (nameString == 'hashCode') {
      return types.coreTypes.intLegacyRawType;
    } else if (nameString == 'runtimeType') {
      return types.coreTypes.typeLegacyRawType;
    }
    return const DynamicType();
  }

  R accept<R>(ExpressionVisitor<R> v) => v.visitPropertyGet(this);
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitPropertyGet(this, arg);

  visitChildren(Visitor v) {
    receiver?.accept(v);
    name?.accept(v);
  }

  transformChildren(Transformer v) {
    if (receiver != null) {
      receiver = receiver.accept<TreeNode>(v);
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

  R accept<R>(ExpressionVisitor<R> v) => v.visitPropertySet(this);
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitPropertySet(this, arg);

  visitChildren(Visitor v) {
    receiver?.accept(v);
    name?.accept(v);
    value?.accept(v);
  }

  transformChildren(Transformer v) {
    if (receiver != null) {
      receiver = receiver.accept<TreeNode>(v);
      receiver?.parent = this;
    }
    if (value != null) {
      value = value.accept<TreeNode>(v);
      value?.parent = this;
    }
  }
}

/// Directly read a field, call a getter, or tear off a method.
class DirectPropertyGet extends Expression {
  Expression receiver;
  Reference targetReference;

  DirectPropertyGet(Expression receiver, Member target)
      : this.byReference(receiver, getMemberReference(target));

  DirectPropertyGet.byReference(this.receiver, this.targetReference) {
    receiver?.parent = this;
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
      receiver = receiver.accept<TreeNode>(v);
      receiver?.parent = this;
    }
  }

  R accept<R>(ExpressionVisitor<R> v) => v.visitDirectPropertyGet(this);
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitDirectPropertyGet(this, arg);

  DartType getStaticType(TypeEnvironment types) {
    Class superclass = target.enclosingClass;
    var receiverType = receiver.getStaticTypeAsInstanceOf(superclass, types);
    return Substitution.fromInterfaceType(receiverType)
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
      receiver = receiver.accept<TreeNode>(v);
      receiver?.parent = this;
    }
    if (value != null) {
      value = value.accept<TreeNode>(v);
      value?.parent = this;
    }
  }

  R accept<R>(ExpressionVisitor<R> v) => v.visitDirectPropertySet(this);
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitDirectPropertySet(this, arg);

  DartType getStaticType(TypeEnvironment types) => value.getStaticType(types);
}

/// Directly call an instance method, bypassing ordinary dispatch.
class DirectMethodInvocation extends InvocationExpression {
  Expression receiver;
  Reference targetReference;
  Arguments arguments;

  DirectMethodInvocation(
      Expression receiver, Procedure target, Arguments arguments)
      : this.byReference(receiver, getMemberReference(target), arguments);

  DirectMethodInvocation.byReference(
      this.receiver, this.targetReference, this.arguments) {
    receiver?.parent = this;
    arguments?.parent = this;
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
      receiver = receiver.accept<TreeNode>(v);
      receiver?.parent = this;
    }
    if (arguments != null) {
      arguments = arguments.accept<TreeNode>(v);
      arguments?.parent = this;
    }
  }

  R accept<R>(ExpressionVisitor<R> v) => v.visitDirectMethodInvocation(this);
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitDirectMethodInvocation(this, arg);

  DartType getStaticType(TypeEnvironment types) {
    if (types.isOverloadedArithmeticOperator(target)) {
      return types.getTypeOfOverloadedArithmetic(receiver.getStaticType(types),
          arguments.positional[0].getStaticType(types));
    }
    Class superclass = target.enclosingClass;
    var receiverType = receiver.getStaticTypeAsInstanceOf(superclass, types);
    var returnType = Substitution.fromInterfaceType(receiverType)
        .substituteType(target.function.returnType);
    return Substitution.fromPairs(
            target.function.typeParameters, arguments.types)
        .substituteType(returnType);
  }
}

/// Expression of form `super.field`.
///
/// This may invoke a getter, read a field, or tear off a method.
class SuperPropertyGet extends Expression {
  Name name;

  Reference interfaceTargetReference;

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
    var receiver = types.getTypeAsInstanceOf(types.thisType, declaringClass);
    return Substitution.fromInterfaceType(receiver)
        .substituteType(interfaceTarget.getterType);
  }

  R accept<R>(ExpressionVisitor<R> v) => v.visitSuperPropertyGet(this);
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitSuperPropertyGet(this, arg);

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

  R accept<R>(ExpressionVisitor<R> v) => v.visitSuperPropertySet(this);
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitSuperPropertySet(this, arg);

  visitChildren(Visitor v) {
    name?.accept(v);
    value?.accept(v);
  }

  transformChildren(Transformer v) {
    if (value != null) {
      value = value.accept<TreeNode>(v);
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

  R accept<R>(ExpressionVisitor<R> v) => v.visitStaticGet(this);
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitStaticGet(this, arg);

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

  R accept<R>(ExpressionVisitor<R> v) => v.visitStaticSet(this);
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitStaticSet(this, arg);

  visitChildren(Visitor v) {
    target?.acceptReference(v);
    value?.accept(v);
  }

  transformChildren(Transformer v) {
    if (value != null) {
      value = value.accept<TreeNode>(v);
      value?.parent = this;
    }
  }
}

/// The arguments to a function call, divided into type arguments,
/// positional arguments, and named arguments.
class Arguments extends TreeNode {
  final List<DartType> types;
  final List<Expression> positional;
  List<NamedExpression> named;

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

  factory Arguments.forwarded(FunctionNode function) {
    return new Arguments(
        function.positionalParameters.map((p) => new VariableGet(p)).toList(),
        named: function.namedParameters
            .map((p) => new NamedExpression(p.name, new VariableGet(p)))
            .toList(),
        types: function.typeParameters
            .map((p) => new TypeParameterType(p))
            .toList());
  }

  R accept<R>(TreeVisitor<R> v) => v.visitArguments(this);

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

  R accept<R>(TreeVisitor<R> v) => v.visitNamedExpression(this);

  visitChildren(Visitor v) {
    value?.accept(v);
  }

  transformChildren(Transformer v) {
    if (value != null) {
      value = value.accept<TreeNode>(v);
      value?.parent = this;
    }
  }
}

/// Common super class for [DirectMethodInvocation], [MethodInvocation],
/// [SuperMethodInvocation], [StaticInvocation], and [ConstructorInvocation].
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

  Reference interfaceTargetReference;

  MethodInvocation(Expression receiver, Name name, Arguments arguments,
      [Member interfaceTarget])
      : this.byReference(
            receiver, name, arguments, getMemberReference(interfaceTarget));

  MethodInvocation.byReference(
      this.receiver, this.name, this.arguments, this.interfaceTargetReference) {
    receiver?.parent = this;
    arguments?.parent = this;
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
      var getterType = Substitution.fromInterfaceType(receiverType)
          .substituteType(interfaceTarget.getterType);
      if (getterType is FunctionType) {
        return Substitution.fromPairs(
                getterType.typeParameters, arguments.types)
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
        return Substitution.fromPairs(
                receiverType.typeParameters, arguments.types)
            .substituteType(receiverType.returnType);
      }
    }
    if (name.name == '==') {
      // We use this special case to simplify generation of '==' checks.
      return types.coreTypes.boolLegacyRawType;
    }
    return const DynamicType();
  }

  R accept<R>(ExpressionVisitor<R> v) => v.visitMethodInvocation(this);
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitMethodInvocation(this, arg);

  visitChildren(Visitor v) {
    receiver?.accept(v);
    name?.accept(v);
    arguments?.accept(v);
  }

  transformChildren(Transformer v) {
    if (receiver != null) {
      receiver = receiver.accept<TreeNode>(v);
      receiver?.parent = this;
    }
    if (arguments != null) {
      arguments = arguments.accept<TreeNode>(v);
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
    var receiverType = types.getTypeAsInstanceOf(types.thisType, superclass);
    var returnType = Substitution.fromInterfaceType(receiverType)
        .substituteType(interfaceTarget.function.returnType);
    return Substitution.fromPairs(
            interfaceTarget.function.typeParameters, arguments.types)
        .substituteType(returnType);
  }

  R accept<R>(ExpressionVisitor<R> v) => v.visitSuperMethodInvocation(this);
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitSuperMethodInvocation(this, arg);

  visitChildren(Visitor v) {
    name?.accept(v);
    arguments?.accept(v);
  }

  transformChildren(Transformer v) {
    if (arguments != null) {
      arguments = arguments.accept<TreeNode>(v);
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
    return Substitution.fromPairs(
            target.function.typeParameters, arguments.types)
        .substituteType(target.function.returnType);
  }

  R accept<R>(ExpressionVisitor<R> v) => v.visitStaticInvocation(this);
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitStaticInvocation(this, arg);

  visitChildren(Visitor v) {
    target?.acceptReference(v);
    arguments?.accept(v);
  }

  transformChildren(Transformer v) {
    if (arguments != null) {
      arguments = arguments.accept<TreeNode>(v);
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
  Reference targetReference;
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
        ? types.coreTypes.legacyRawType(target.enclosingClass)
        : new InterfaceType(
            target.enclosingClass, arguments.types, Nullability.legacy);
  }

  R accept<R>(ExpressionVisitor<R> v) => v.visitConstructorInvocation(this);
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitConstructorInvocation(this, arg);

  visitChildren(Visitor v) {
    target?.acceptReference(v);
    arguments?.accept(v);
  }

  transformChildren(Transformer v) {
    if (arguments != null) {
      arguments = arguments.accept<TreeNode>(v);
      arguments?.parent = this;
    }
  }

  // TODO(dmitryas): Change the getter into a method that accepts a CoreTypes.
  InterfaceType get constructedType {
    Class enclosingClass = target.enclosingClass;
    // TODO(dmitryas): Get raw type from a CoreTypes object if arguments is
    // empty.
    return arguments.types.isEmpty
        ? new InterfaceType(
            enclosingClass, const <DartType>[], Nullability.legacy)
        : new InterfaceType(
            enclosingClass, arguments.types, Nullability.legacy);
  }
}

/// An explicit type instantiation of a generic function.
class Instantiation extends Expression {
  Expression expression;
  final List<DartType> typeArguments;

  Instantiation(this.expression, this.typeArguments) {
    expression?.parent = this;
  }

  DartType getStaticType(TypeEnvironment types) {
    FunctionType type = expression.getStaticType(types);
    return Substitution.fromPairs(type.typeParameters, typeArguments)
        .substituteType(type.withoutTypeParameters);
  }

  R accept<R>(ExpressionVisitor<R> v) => v.visitInstantiation(this);
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitInstantiation(this, arg);

  visitChildren(Visitor v) {
    expression?.accept(v);
    visitList(typeArguments, v);
  }

  transformChildren(Transformer v) {
    if (expression != null) {
      expression = expression.accept<TreeNode>(v);
      expression?.parent = this;
    }
    transformTypeList(typeArguments, v);
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

  DartType getStaticType(TypeEnvironment types) =>
      types.coreTypes.boolLegacyRawType;

  R accept<R>(ExpressionVisitor<R> v) => v.visitNot(this);
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) => v.visitNot(this, arg);

  visitChildren(Visitor v) {
    operand?.accept(v);
  }

  transformChildren(Transformer v) {
    if (operand != null) {
      operand = operand.accept<TreeNode>(v);
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

  DartType getStaticType(TypeEnvironment types) =>
      types.coreTypes.boolLegacyRawType;

  R accept<R>(ExpressionVisitor<R> v) => v.visitLogicalExpression(this);
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitLogicalExpression(this, arg);

  visitChildren(Visitor v) {
    left?.accept(v);
    right?.accept(v);
  }

  transformChildren(Transformer v) {
    if (left != null) {
      left = left.accept<TreeNode>(v);
      left?.parent = this;
    }
    if (right != null) {
      right = right.accept<TreeNode>(v);
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

  R accept<R>(ExpressionVisitor<R> v) => v.visitConditionalExpression(this);
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitConditionalExpression(this, arg);

  visitChildren(Visitor v) {
    condition?.accept(v);
    then?.accept(v);
    otherwise?.accept(v);
    staticType?.accept(v);
  }

  transformChildren(Transformer v) {
    if (condition != null) {
      condition = condition.accept<TreeNode>(v);
      condition?.parent = this;
    }
    if (then != null) {
      then = then.accept<TreeNode>(v);
      then?.parent = this;
    }
    if (otherwise != null) {
      otherwise = otherwise.accept<TreeNode>(v);
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

  DartType getStaticType(TypeEnvironment types) =>
      types.coreTypes.stringLegacyRawType;

  R accept<R>(ExpressionVisitor<R> v) => v.visitStringConcatenation(this);
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitStringConcatenation(this, arg);

  visitChildren(Visitor v) {
    visitList(expressions, v);
  }

  transformChildren(Transformer v) {
    transformList(expressions, v, this);
  }
}

/// Concatenate lists into a single list.
///
/// If [lists] is empty then an empty list is returned.
///
/// These arise from spread and control-flow elements in const list literals.
/// They are only present before constant evaluation, or within unevaluated
/// constants in constant expressions.
class ListConcatenation extends Expression {
  DartType typeArgument;
  final List<Expression> lists;

  ListConcatenation(this.lists, {this.typeArgument: const DynamicType()}) {
    setParents(lists, this);
  }

  DartType getStaticType(TypeEnvironment types) {
    return types.literalListType(typeArgument);
  }

  R accept<R>(ExpressionVisitor<R> v) => v.visitListConcatenation(this);
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitListConcatenation(this, arg);

  visitChildren(Visitor v) {
    typeArgument?.accept(v);
    visitList(lists, v);
  }

  transformChildren(Transformer v) {
    typeArgument = v.visitDartType(typeArgument);
    transformList(lists, v, this);
  }
}

/// Concatenate sets into a single set.
///
/// If [sets] is empty then an empty set is returned.
///
/// These arise from spread and control-flow elements in const set literals.
/// They are only present before constant evaluation, or within unevaluated
/// constants in constant expressions.
///
/// Duplicated values in or across the sets will result in a compile-time error
/// during constant evaluation.
class SetConcatenation extends Expression {
  DartType typeArgument;
  final List<Expression> sets;

  SetConcatenation(this.sets, {this.typeArgument: const DynamicType()}) {
    setParents(sets, this);
  }

  DartType getStaticType(TypeEnvironment types) {
    return types.literalSetType(typeArgument);
  }

  R accept<R>(ExpressionVisitor<R> v) => v.visitSetConcatenation(this);
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitSetConcatenation(this, arg);

  visitChildren(Visitor v) {
    typeArgument?.accept(v);
    visitList(sets, v);
  }

  transformChildren(Transformer v) {
    typeArgument = v.visitDartType(typeArgument);
    transformList(sets, v, this);
  }
}

/// Concatenate maps into a single map.
///
/// If [maps] is empty then an empty map is returned.
///
/// These arise from spread and control-flow elements in const map literals.
/// They are only present before constant evaluation, or within unevaluated
/// constants in constant expressions.
///
/// Duplicated keys in or across the maps will result in a compile-time error
/// during constant evaluation.
class MapConcatenation extends Expression {
  DartType keyType;
  DartType valueType;
  final List<Expression> maps;

  MapConcatenation(this.maps,
      {this.keyType: const DynamicType(),
      this.valueType: const DynamicType()}) {
    setParents(maps, this);
  }

  DartType getStaticType(TypeEnvironment types) {
    return types.literalMapType(keyType, valueType);
  }

  R accept<R>(ExpressionVisitor<R> v) => v.visitMapConcatenation(this);
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitMapConcatenation(this, arg);

  visitChildren(Visitor v) {
    keyType?.accept(v);
    valueType?.accept(v);
    visitList(maps, v);
  }

  transformChildren(Transformer v) {
    keyType = v.visitDartType(keyType);
    valueType = v.visitDartType(valueType);
    transformList(maps, v, this);
  }
}

/// Create an instance directly from the field values.
///
/// These expressions arise from const constructor calls when one or more field
/// initializing expressions, field initializers, assert initializers or unused
/// arguments contain unevaluated expressions. They only ever occur within
/// unevaluated constants in constant expressions.
class InstanceCreation extends Expression {
  final Reference classReference;
  final List<DartType> typeArguments;
  final Map<Reference, Expression> fieldValues;
  final List<AssertStatement> asserts;
  final List<Expression> unusedArguments;

  InstanceCreation(this.classReference, this.typeArguments, this.fieldValues,
      this.asserts, this.unusedArguments);

  Class get classNode => classReference.asClass;

  DartType getStaticType(TypeEnvironment types) {
    return typeArguments.isEmpty
        ? types.coreTypes.legacyRawType(classNode)
        : new InterfaceType(classNode, typeArguments);
  }

  R accept<R>(ExpressionVisitor<R> v) => v.visitInstanceCreation(this);
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitInstanceCreation(this, arg);

  visitChildren(Visitor v) {
    classReference.asClass.acceptReference(v);
    visitList(typeArguments, v);
    for (final Reference reference in fieldValues.keys) {
      reference.asField.acceptReference(v);
    }
    for (final Expression value in fieldValues.values) {
      value.accept(v);
    }
    visitList(asserts, v);
    visitList(unusedArguments, v);
  }

  transformChildren(Transformer v) {
    fieldValues.forEach((Reference fieldRef, Expression value) {
      Expression transformed = value.accept<TreeNode>(v);
      if (transformed != null && !identical(value, transformed)) {
        fieldValues[fieldRef] = transformed;
        transformed.parent = this;
      }
    });
    transformList(asserts, v, this);
    transformList(unusedArguments, v, this);
  }
}

/// A marker indicating that a subexpression originates in a different source
/// file than the surrounding context.
///
/// These expressions arise from inlining of const variables during constant
/// evaluation. They only ever occur within unevaluated constants in constant
/// expressions.
class FileUriExpression extends Expression implements FileUriNode {
  /// The URI of the source file in which the subexpression is located.
  /// Can be different from the file containing the [FileUriExpression].
  Uri fileUri;

  Expression expression;

  FileUriExpression(this.expression, this.fileUri) {
    expression.parent = this;
  }

  DartType getStaticType(TypeEnvironment types) =>
      expression.getStaticType(types);

  R accept<R>(ExpressionVisitor<R> v) => v.visitFileUriExpression(this);
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitFileUriExpression(this, arg);

  visitChildren(Visitor v) {
    expression.accept(v);
  }

  transformChildren(Transformer v) {
    expression = expression.accept<TreeNode>(v)..parent = this;
  }

  Location _getLocationInEnclosingFile(int offset) {
    return _getLocationInComponent(enclosingComponent, fileUri, offset);
  }
}

/// Expression of form `x is T`.
class IsExpression extends Expression {
  Expression operand;
  DartType type;

  IsExpression(this.operand, this.type) {
    operand?.parent = this;
  }

  DartType getStaticType(TypeEnvironment types) =>
      types.coreTypes.boolLegacyRawType;

  R accept<R>(ExpressionVisitor<R> v) => v.visitIsExpression(this);
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitIsExpression(this, arg);

  visitChildren(Visitor v) {
    operand?.accept(v);
    type?.accept(v);
  }

  transformChildren(Transformer v) {
    if (operand != null) {
      operand = operand.accept<TreeNode>(v);
      operand?.parent = this;
    }
    type = v.visitDartType(type);
  }
}

/// Expression of form `x as T`.
class AsExpression extends Expression {
  int flags = 0;
  Expression operand;
  DartType type;

  AsExpression(this.operand, this.type) {
    operand?.parent = this;
  }

  // Must match serialized bit positions.
  static const int FlagTypeError = 1 << 0;

  /// Indicates the type of error that should be thrown if the check fails.
  ///
  /// `true` means that a TypeError should be thrown.  `false` means that a
  /// CastError should be thrown.
  bool get isTypeError => flags & FlagTypeError != 0;

  void set isTypeError(bool value) {
    flags = value ? (flags | FlagTypeError) : (flags & ~FlagTypeError);
  }

  DartType getStaticType(TypeEnvironment types) => type;

  R accept<R>(ExpressionVisitor<R> v) => v.visitAsExpression(this);
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitAsExpression(this, arg);

  visitChildren(Visitor v) {
    operand?.accept(v);
    type?.accept(v);
  }

  transformChildren(Transformer v) {
    if (operand != null) {
      operand = operand.accept<TreeNode>(v);
      operand?.parent = this;
    }
    type = v.visitDartType(type);
  }
}

/// Null check expression of form `x!`.
///
/// This expression was added as part of NNBD and is currently only created when
/// the 'non-nullable' experimental feature is enabled.
class NullCheck extends Expression {
  Expression operand;

  NullCheck(this.operand) {
    operand?.parent = this;
  }

  DartType getStaticType(TypeEnvironment types) =>
      // TODO(johnniwinther): Return `NonNull(operand.getStaticType(types))`.
      operand.getStaticType(types);

  R accept<R>(ExpressionVisitor<R> v) => v.visitNullCheck(this);
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitNullCheck(this, arg);

  visitChildren(Visitor v) {
    operand?.accept(v);
  }

  transformChildren(Transformer v) {
    if (operand != null) {
      operand = operand.accept<TreeNode>(v);
      operand?.parent = this;
    }
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

  DartType getStaticType(TypeEnvironment types) =>
      types.coreTypes.stringLegacyRawType;

  R accept<R>(ExpressionVisitor<R> v) => v.visitStringLiteral(this);
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitStringLiteral(this, arg);
}

class IntLiteral extends BasicLiteral {
  /// Note that this value holds a uint64 value.
  /// E.g. "0x8000000000000000" will be saved as "-9223372036854775808" despite
  /// technically (on some platforms, particularly Javascript) being positive.
  /// If the number is meant to be negative it will be wrapped in a "unary-".
  int value;

  IntLiteral(this.value);

  DartType getStaticType(TypeEnvironment types) =>
      types.coreTypes.intLegacyRawType;

  R accept<R>(ExpressionVisitor<R> v) => v.visitIntLiteral(this);
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitIntLiteral(this, arg);
}

class DoubleLiteral extends BasicLiteral {
  double value;

  DoubleLiteral(this.value);

  DartType getStaticType(TypeEnvironment types) =>
      types.coreTypes.doubleLegacyRawType;

  R accept<R>(ExpressionVisitor<R> v) => v.visitDoubleLiteral(this);
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitDoubleLiteral(this, arg);
}

class BoolLiteral extends BasicLiteral {
  bool value;

  BoolLiteral(this.value);

  DartType getStaticType(TypeEnvironment types) =>
      types.coreTypes.boolLegacyRawType;

  R accept<R>(ExpressionVisitor<R> v) => v.visitBoolLiteral(this);
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitBoolLiteral(this, arg);
}

class NullLiteral extends BasicLiteral {
  Object get value => null;

  DartType getStaticType(TypeEnvironment types) => types.nullType;

  R accept<R>(ExpressionVisitor<R> v) => v.visitNullLiteral(this);
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitNullLiteral(this, arg);
}

class SymbolLiteral extends Expression {
  String value; // Everything strictly after the '#'.

  SymbolLiteral(this.value);

  DartType getStaticType(TypeEnvironment types) =>
      types.coreTypes.symbolLegacyRawType;

  R accept<R>(ExpressionVisitor<R> v) => v.visitSymbolLiteral(this);
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitSymbolLiteral(this, arg);

  visitChildren(Visitor v) {}
  transformChildren(Transformer v) {}
}

class TypeLiteral extends Expression {
  DartType type;

  TypeLiteral(this.type);

  DartType getStaticType(TypeEnvironment types) =>
      types.coreTypes.typeLegacyRawType;

  R accept<R>(ExpressionVisitor<R> v) => v.visitTypeLiteral(this);
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitTypeLiteral(this, arg);

  visitChildren(Visitor v) {
    type?.accept(v);
  }

  transformChildren(Transformer v) {
    type = v.visitDartType(type);
  }
}

class ThisExpression extends Expression {
  DartType getStaticType(TypeEnvironment types) => types.thisType;

  R accept<R>(ExpressionVisitor<R> v) => v.visitThisExpression(this);
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitThisExpression(this, arg);

  visitChildren(Visitor v) {}
  transformChildren(Transformer v) {}
}

class Rethrow extends Expression {
  DartType getStaticType(TypeEnvironment types) => const BottomType();

  R accept<R>(ExpressionVisitor<R> v) => v.visitRethrow(this);
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitRethrow(this, arg);

  visitChildren(Visitor v) {}
  transformChildren(Transformer v) {}
}

class Throw extends Expression {
  Expression expression;

  Throw(this.expression) {
    expression?.parent = this;
  }

  DartType getStaticType(TypeEnvironment types) => const BottomType();

  R accept<R>(ExpressionVisitor<R> v) => v.visitThrow(this);
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) => v.visitThrow(this, arg);

  visitChildren(Visitor v) {
    expression?.accept(v);
  }

  transformChildren(Transformer v) {
    if (expression != null) {
      expression = expression.accept<TreeNode>(v);
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

  R accept<R>(ExpressionVisitor<R> v) => v.visitListLiteral(this);
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitListLiteral(this, arg);

  visitChildren(Visitor v) {
    typeArgument?.accept(v);
    visitList(expressions, v);
  }

  transformChildren(Transformer v) {
    typeArgument = v.visitDartType(typeArgument);
    transformList(expressions, v, this);
  }
}

class SetLiteral extends Expression {
  bool isConst;
  DartType typeArgument; // Not null, defaults to DynamicType.
  final List<Expression> expressions;

  SetLiteral(this.expressions,
      {this.typeArgument: const DynamicType(), this.isConst: false}) {
    assert(typeArgument != null);
    setParents(expressions, this);
  }

  DartType getStaticType(TypeEnvironment types) {
    return types.literalSetType(typeArgument);
  }

  R accept<R>(ExpressionVisitor<R> v) => v.visitSetLiteral(this);
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitSetLiteral(this, arg);

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

  R accept<R>(ExpressionVisitor<R> v) => v.visitMapLiteral(this);
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitMapLiteral(this, arg);

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

  R accept<R>(TreeVisitor<R> v) => v.visitMapEntry(this);

  visitChildren(Visitor v) {
    key?.accept(v);
    value?.accept(v);
  }

  transformChildren(Transformer v) {
    if (key != null) {
      key = key.accept<TreeNode>(v);
      key?.parent = this;
    }
    if (value != null) {
      value = value.accept<TreeNode>(v);
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

  R accept<R>(ExpressionVisitor<R> v) => v.visitAwaitExpression(this);
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitAwaitExpression(this, arg);

  visitChildren(Visitor v) {
    operand?.accept(v);
  }

  transformChildren(Transformer v) {
    if (operand != null) {
      operand = operand.accept<TreeNode>(v);
      operand?.parent = this;
    }
  }
}

/// Common super-interface for [FunctionExpression] and [FunctionDeclaration].
abstract class LocalFunction implements TreeNode {
  FunctionNode get function;
}

/// Expression of form `(x,y) => ...` or `(x,y) { ... }`
///
/// The arrow-body form `=> e` is desugared into `return e;`.
class FunctionExpression extends Expression implements LocalFunction {
  FunctionNode function;

  FunctionExpression(this.function) {
    function?.parent = this;
  }

  DartType getStaticType(TypeEnvironment types) => function.functionType;

  R accept<R>(ExpressionVisitor<R> v) => v.visitFunctionExpression(this);
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitFunctionExpression(this, arg);

  visitChildren(Visitor v) {
    function?.accept(v);
  }

  transformChildren(Transformer v) {
    if (function != null) {
      function = function.accept<TreeNode>(v);
      function?.parent = this;
    }
  }
}

class ConstantExpression extends Expression {
  Constant constant;
  DartType type;

  ConstantExpression(this.constant, [this.type = const DynamicType()]) {
    assert(constant != null);
  }

  DartType getStaticType(TypeEnvironment types) => type;

  R accept<R>(ExpressionVisitor<R> v) => v.visitConstantExpression(this);
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitConstantExpression(this, arg);

  visitChildren(Visitor v) {
    constant?.acceptReference(v);
    type?.accept(v);
  }

  transformChildren(Transformer v) {
    constant = v.visitConstant(constant);
    type = v.visitDartType(type);
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

  R accept<R>(ExpressionVisitor<R> v) => v.visitLet(this);
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) => v.visitLet(this, arg);

  visitChildren(Visitor v) {
    variable?.accept(v);
    body?.accept(v);
  }

  transformChildren(Transformer v) {
    if (variable != null) {
      variable = variable.accept<TreeNode>(v);
      variable?.parent = this;
    }
    if (body != null) {
      body = body.accept<TreeNode>(v);
      body?.parent = this;
    }
  }
}

class BlockExpression extends Expression {
  Block body;
  Expression value;

  BlockExpression(this.body, this.value) {
    body?.parent = this;
    value?.parent = this;
  }

  DartType getStaticType(TypeEnvironment types) => value.getStaticType(types);

  R accept<R>(ExpressionVisitor<R> v) => v.visitBlockExpression(this);
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitBlockExpression(this, arg);

  visitChildren(Visitor v) {
    body?.accept(v);
    value?.accept(v);
  }

  transformChildren(Transformer v) {
    if (body != null) {
      body = body.accept<TreeNode>(v);
      body?.parent = this;
    }
    if (value != null) {
      value = value.accept<TreeNode>(v);
      value?.parent = this;
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

  R accept<R>(ExpressionVisitor<R> v) => v.visitLoadLibrary(this);
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitLoadLibrary(this, arg);

  visitChildren(Visitor v) {}
  transformChildren(Transformer v) {}
}

/// Checks that the given deferred import has been marked as 'loaded'.
class CheckLibraryIsLoaded extends Expression {
  /// Reference to a deferred import in the enclosing library.
  LibraryDependency import;

  CheckLibraryIsLoaded(this.import);

  DartType getStaticType(TypeEnvironment types) {
    return types.coreTypes.objectLegacyRawType;
  }

  R accept<R>(ExpressionVisitor<R> v) => v.visitCheckLibraryIsLoaded(this);
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitCheckLibraryIsLoaded(this, arg);

  visitChildren(Visitor v) {}
  transformChildren(Transformer v) {}
}

// ------------------------------------------------------------------------
//                              STATEMENTS
// ------------------------------------------------------------------------

abstract class Statement extends TreeNode {
  R accept<R>(StatementVisitor<R> v);
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg);
}

class ExpressionStatement extends Statement {
  Expression expression;

  ExpressionStatement(this.expression) {
    expression?.parent = this;
  }

  R accept<R>(StatementVisitor<R> v) => v.visitExpressionStatement(this);
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg) =>
      v.visitExpressionStatement(this, arg);

  visitChildren(Visitor v) {
    expression?.accept(v);
  }

  transformChildren(Transformer v) {
    if (expression != null) {
      expression = expression.accept<TreeNode>(v);
      expression?.parent = this;
    }
  }
}

class Block extends Statement {
  final List<Statement> statements;

  Block(this.statements) {
    // Ensure statements is mutable.
    assert((statements
          ..add(null)
          ..removeLast()) !=
        null);
    setParents(statements, this);
  }

  R accept<R>(StatementVisitor<R> v) => v.visitBlock(this);
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg) => v.visitBlock(this, arg);

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

/// A block that is only executed when asserts are enabled.
///
/// Sometimes arbitrary statements must be guarded by whether asserts are
/// enabled.  For example, when a subexpression of an assert in async code is
/// linearized and named, it can produce such a block of statements.
class AssertBlock extends Statement {
  final List<Statement> statements;

  AssertBlock(this.statements) {
    // Ensure statements is mutable.
    assert((statements
          ..add(null)
          ..removeLast()) !=
        null);
    setParents(statements, this);
  }

  R accept<R>(StatementVisitor<R> v) => v.visitAssertBlock(this);
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg) =>
      v.visitAssertBlock(this, arg);

  transformChildren(Transformer v) {
    transformList(statements, v, this);
  }

  visitChildren(Visitor v) {
    visitList(statements, v);
  }

  void addStatement(Statement node) {
    statements.add(node);
    node.parent = this;
  }
}

class EmptyStatement extends Statement {
  R accept<R>(StatementVisitor<R> v) => v.visitEmptyStatement(this);
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg) =>
      v.visitEmptyStatement(this, arg);

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

  R accept<R>(StatementVisitor<R> v) => v.visitAssertStatement(this);
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg) =>
      v.visitAssertStatement(this, arg);

  visitChildren(Visitor v) {
    condition?.accept(v);
    message?.accept(v);
  }

  transformChildren(Transformer v) {
    if (condition != null) {
      condition = condition.accept<TreeNode>(v);
      condition?.parent = this;
    }
    if (message != null) {
      message = message.accept<TreeNode>(v);
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

  R accept<R>(StatementVisitor<R> v) => v.visitLabeledStatement(this);
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg) =>
      v.visitLabeledStatement(this, arg);

  visitChildren(Visitor v) {
    body?.accept(v);
  }

  transformChildren(Transformer v) {
    if (body != null) {
      body = body.accept<TreeNode>(v);
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

  R accept<R>(StatementVisitor<R> v) => v.visitBreakStatement(this);
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg) =>
      v.visitBreakStatement(this, arg);

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

  R accept<R>(StatementVisitor<R> v) => v.visitWhileStatement(this);
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg) =>
      v.visitWhileStatement(this, arg);

  visitChildren(Visitor v) {
    condition?.accept(v);
    body?.accept(v);
  }

  transformChildren(Transformer v) {
    if (condition != null) {
      condition = condition.accept<TreeNode>(v);
      condition?.parent = this;
    }
    if (body != null) {
      body = body.accept<TreeNode>(v);
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

  R accept<R>(StatementVisitor<R> v) => v.visitDoStatement(this);
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg) =>
      v.visitDoStatement(this, arg);

  visitChildren(Visitor v) {
    body?.accept(v);
    condition?.accept(v);
  }

  transformChildren(Transformer v) {
    if (body != null) {
      body = body.accept<TreeNode>(v);
      body?.parent = this;
    }
    if (condition != null) {
      condition = condition.accept<TreeNode>(v);
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

  R accept<R>(StatementVisitor<R> v) => v.visitForStatement(this);
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg) =>
      v.visitForStatement(this, arg);

  visitChildren(Visitor v) {
    visitList(variables, v);
    condition?.accept(v);
    visitList(updates, v);
    body?.accept(v);
  }

  transformChildren(Transformer v) {
    transformList(variables, v, this);
    if (condition != null) {
      condition = condition.accept<TreeNode>(v);
      condition?.parent = this;
    }
    transformList(updates, v, this);
    if (body != null) {
      body = body.accept<TreeNode>(v);
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

  R accept<R>(StatementVisitor<R> v) => v.visitForInStatement(this);
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg) =>
      v.visitForInStatement(this, arg);

  void visitChildren(Visitor v) {
    variable?.accept(v);
    iterable?.accept(v);
    body?.accept(v);
  }

  void transformChildren(Transformer v) {
    if (variable != null) {
      variable = variable.accept<TreeNode>(v);
      variable?.parent = this;
    }
    if (iterable != null) {
      iterable = iterable.accept<TreeNode>(v);
      iterable?.parent = this;
    }
    if (body != null) {
      body = body.accept<TreeNode>(v);
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

  R accept<R>(StatementVisitor<R> v) => v.visitSwitchStatement(this);
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg) =>
      v.visitSwitchStatement(this, arg);

  visitChildren(Visitor v) {
    expression?.accept(v);
    visitList(cases, v);
  }

  transformChildren(Transformer v) {
    if (expression != null) {
      expression = expression.accept<TreeNode>(v);
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

  R accept<R>(TreeVisitor<R> v) => v.visitSwitchCase(this);

  visitChildren(Visitor v) {
    visitList(expressions, v);
    body?.accept(v);
  }

  transformChildren(Transformer v) {
    transformList(expressions, v, this);
    if (body != null) {
      body = body.accept<TreeNode>(v);
      body?.parent = this;
    }
  }
}

/// Jump to a case in an enclosing switch.
class ContinueSwitchStatement extends Statement {
  SwitchCase target;

  ContinueSwitchStatement(this.target);

  R accept<R>(StatementVisitor<R> v) => v.visitContinueSwitchStatement(this);
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg) =>
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

  R accept<R>(StatementVisitor<R> v) => v.visitIfStatement(this);
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg) =>
      v.visitIfStatement(this, arg);

  visitChildren(Visitor v) {
    condition?.accept(v);
    then?.accept(v);
    otherwise?.accept(v);
  }

  transformChildren(Transformer v) {
    if (condition != null) {
      condition = condition.accept<TreeNode>(v);
      condition?.parent = this;
    }
    if (then != null) {
      then = then.accept<TreeNode>(v);
      then?.parent = this;
    }
    if (otherwise != null) {
      otherwise = otherwise.accept<TreeNode>(v);
      otherwise?.parent = this;
    }
  }
}

class ReturnStatement extends Statement {
  Expression expression; // May be null.

  ReturnStatement([this.expression]) {
    expression?.parent = this;
  }

  R accept<R>(StatementVisitor<R> v) => v.visitReturnStatement(this);
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg) =>
      v.visitReturnStatement(this, arg);

  visitChildren(Visitor v) {
    expression?.accept(v);
  }

  transformChildren(Transformer v) {
    if (expression != null) {
      expression = expression.accept<TreeNode>(v);
      expression?.parent = this;
    }
  }
}

class TryCatch extends Statement {
  Statement body;
  List<Catch> catches;
  bool isSynthetic;

  TryCatch(this.body, this.catches, {this.isSynthetic: false}) {
    body?.parent = this;
    setParents(catches, this);
  }

  R accept<R>(StatementVisitor<R> v) => v.visitTryCatch(this);
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg) =>
      v.visitTryCatch(this, arg);

  visitChildren(Visitor v) {
    body?.accept(v);
    visitList(catches, v);
  }

  transformChildren(Transformer v) {
    if (body != null) {
      body = body.accept<TreeNode>(v);
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

  R accept<R>(TreeVisitor<R> v) => v.visitCatch(this);

  visitChildren(Visitor v) {
    guard?.accept(v);
    exception?.accept(v);
    stackTrace?.accept(v);
    body?.accept(v);
  }

  transformChildren(Transformer v) {
    guard = v.visitDartType(guard);
    if (exception != null) {
      exception = exception.accept<TreeNode>(v);
      exception?.parent = this;
    }
    if (stackTrace != null) {
      stackTrace = stackTrace.accept<TreeNode>(v);
      stackTrace?.parent = this;
    }
    if (body != null) {
      body = body.accept<TreeNode>(v);
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

  R accept<R>(StatementVisitor<R> v) => v.visitTryFinally(this);
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg) =>
      v.visitTryFinally(this, arg);

  visitChildren(Visitor v) {
    body?.accept(v);
    finalizer?.accept(v);
  }

  transformChildren(Transformer v) {
    if (body != null) {
      body = body.accept<TreeNode>(v);
      body?.parent = this;
    }
    if (finalizer != null) {
      finalizer = finalizer.accept<TreeNode>(v);
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

  R accept<R>(StatementVisitor<R> v) => v.visitYieldStatement(this);
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg) =>
      v.visitYieldStatement(this, arg);

  visitChildren(Visitor v) {
    expression?.accept(v);
  }

  transformChildren(Transformer v) {
    if (expression != null) {
      expression = expression.accept<TreeNode>(v);
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
class VariableDeclaration extends Statement {
  /// Offset of the equals sign in the source file it comes from.
  ///
  /// Valid values are from 0 and up, or -1 ([TreeNode.noOffset])
  /// if the equals sign offset is not available (e.g. if not initialized)
  /// (this is the default if none is specifically set).
  int fileEqualsOffset = TreeNode.noOffset;

  /// List of metadata annotations on the variable declaration.
  ///
  /// This defaults to an immutable empty list. Use [addAnnotation] to add
  /// annotations if needed.
  List<Expression> annotations = const <Expression>[];

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
  Expression initializer; // May be null.

  VariableDeclaration(this.name,
      {this.initializer,
      this.type: const DynamicType(),
      int flags: -1,
      bool isFinal: false,
      bool isConst: false,
      bool isFieldFormal: false,
      bool isCovariant: false,
      bool isLate: false,
      bool isRequired: false}) {
    assert(type != null);
    initializer?.parent = this;
    if (flags != -1) {
      this.flags = flags;
    } else {
      this.isFinal = isFinal;
      this.isConst = isConst;
      this.isFieldFormal = isFieldFormal;
      this.isCovariant = isCovariant;
      this.isLate = isLate;
      this.isRequired = isRequired;
    }
  }

  /// Creates a synthetic variable with the given expression as initializer.
  VariableDeclaration.forValue(this.initializer,
      {bool isFinal: true,
      bool isConst: false,
      bool isFieldFormal: false,
      bool isLate: false,
      bool isRequired: false,
      this.type: const DynamicType()}) {
    assert(type != null);
    initializer?.parent = this;
    this.isFinal = isFinal;
    this.isConst = isConst;
    this.isFieldFormal = isFieldFormal;
    this.isLate = isLate;
    this.isRequired = isRequired;
  }

  static const int FlagFinal = 1 << 0; // Must match serialized bit positions.
  static const int FlagConst = 1 << 1;
  static const int FlagFieldFormal = 1 << 2;
  static const int FlagCovariant = 1 << 3;
  static const int FlagInScope = 1 << 4; // Temporary flag used by verifier.
  static const int FlagGenericCovariantImpl = 1 << 5;
  static const int FlagLate = 1 << 6;
  static const int FlagRequired = 1 << 7;

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

  /// Whether the variable is declared with the `late` keyword.
  ///
  /// The `late` modifier is only supported on local variables and not on
  /// parameters.
  bool get isLate => flags & FlagLate != 0;

  /// Whether the parameter is declared with the `required` keyword.
  ///
  /// The `required` modifier is only supported on named parameters and not on
  /// positional parameters and local variables.
  bool get isRequired => flags & FlagRequired != 0;

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

  void set isLate(bool value) {
    flags = value ? (flags | FlagLate) : (flags & ~FlagLate);
  }

  void set isRequired(bool value) {
    flags = value ? (flags | FlagRequired) : (flags & ~FlagRequired);
  }

  void addAnnotation(Expression annotation) {
    if (annotations.isEmpty) {
      annotations = <Expression>[];
    }
    annotations.add(annotation..parent = this);
  }

  R accept<R>(StatementVisitor<R> v) => v.visitVariableDeclaration(this);
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg) =>
      v.visitVariableDeclaration(this, arg);

  visitChildren(Visitor v) {
    visitList(annotations, v);
    type?.accept(v);
    initializer?.accept(v);
  }

  transformChildren(Transformer v) {
    transformList(annotations, v, this);
    type = v.visitDartType(type);
    if (initializer != null) {
      initializer = initializer.accept<TreeNode>(v);
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
class FunctionDeclaration extends Statement implements LocalFunction {
  VariableDeclaration variable; // Is final and has no initializer.
  FunctionNode function;

  FunctionDeclaration(this.variable, this.function) {
    variable?.parent = this;
    function?.parent = this;
  }

  R accept<R>(StatementVisitor<R> v) => v.visitFunctionDeclaration(this);
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg) =>
      v.visitFunctionDeclaration(this, arg);

  visitChildren(Visitor v) {
    variable?.accept(v);
    function?.accept(v);
  }

  transformChildren(Transformer v) {
    if (variable != null) {
      variable = variable.accept<TreeNode>(v);
      variable?.parent = this;
    }
    if (function != null) {
      function = function.accept<TreeNode>(v);
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
  Reference get libraryName;
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

  R accept<R>(Visitor<R> v) => v.visitName(this);

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
    // TODO(dmitryas): Factor in [libraryName] in a non-deterministic way into
    // the result.  Note, the previous code here was the following:
    //     return 131 * name.hashCode + 17 * libraryName.asLibrary._libraryId;
    return name.hashCode;
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

/// Represents nullability of a type.
enum Nullability {
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

  /// Non-legacy types that are neither nullable, nor non-nullable.
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
  neither,

  /// Types in opt-out libraries are 'legacy' types.
  ///
  /// They are both subtypes and supertypes of the nullable and non-nullable
  /// versions of the type.
  legacy
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
abstract class DartType extends Node {
  const DartType();

  R accept<R>(DartTypeVisitor<R> v);
  R accept1<R, A>(DartTypeVisitor1<R, A> v, A arg);

  bool operator ==(Object other);

  Nullability get nullability;

  /// If this is a typedef type, repeatedly unfolds its type definition until
  /// the root term is not a typedef type, otherwise returns the type itself.
  ///
  /// Will never return a typedef type.
  DartType get unalias => this;

  /// If this is a typedef type, unfolds its type definition once, otherwise
  /// returns the type itself.
  DartType get unaliasOnce => this;

  /// Creates a copy of the type with the given [nullability] if possible.
  ///
  /// Some types have fixed nullabilities, such as `dynamic`, `invalid-type`,
  /// `void`, or `bottom`.
  DartType withNullability(Nullability nullability);
}

/// The type arising from invalid type annotations.
///
/// Can usually be treated as 'dynamic', but should occasionally be handled
/// differently, e.g. `x is ERROR` should evaluate to false.
class InvalidType extends DartType {
  final int hashCode = 12345;

  const InvalidType();

  R accept<R>(DartTypeVisitor<R> v) => v.visitInvalidType(this);
  R accept1<R, A>(DartTypeVisitor1<R, A> v, A arg) =>
      v.visitInvalidType(this, arg);
  visitChildren(Visitor v) {}

  bool operator ==(Object other) => other is InvalidType;

  Nullability get nullability => throw "InvalidType doesn't have nullability";

  InvalidType withNullability(Nullability nullability) => this;
}

class DynamicType extends DartType {
  final int hashCode = 54321;

  const DynamicType();

  R accept<R>(DartTypeVisitor<R> v) => v.visitDynamicType(this);
  R accept1<R, A>(DartTypeVisitor1<R, A> v, A arg) =>
      v.visitDynamicType(this, arg);
  visitChildren(Visitor v) {}

  bool operator ==(Object other) => other is DynamicType;

  Nullability get nullability => Nullability.nullable;

  DynamicType withNullability(Nullability nullability) => this;
}

class VoidType extends DartType {
  final int hashCode = 123121;

  const VoidType();

  R accept<R>(DartTypeVisitor<R> v) => v.visitVoidType(this);
  R accept1<R, A>(DartTypeVisitor1<R, A> v, A arg) =>
      v.visitVoidType(this, arg);
  visitChildren(Visitor v) {}

  bool operator ==(Object other) => other is VoidType;

  Nullability get nullability => Nullability.nullable;

  VoidType withNullability(Nullability nullability) => this;
}

class BottomType extends DartType {
  final int hashCode = 514213;

  const BottomType();

  R accept<R>(DartTypeVisitor<R> v) => v.visitBottomType(this);
  R accept1<R, A>(DartTypeVisitor1<R, A> v, A arg) =>
      v.visitBottomType(this, arg);
  visitChildren(Visitor v) {}

  bool operator ==(Object other) => other is BottomType;

  Nullability get nullability => Nullability.nonNullable;

  BottomType withNullability(Nullability nullability) => this;
}

class InterfaceType extends DartType {
  Reference className;

  final Nullability nullability;

  final List<DartType> typeArguments;

  /// The [typeArguments] list must not be modified after this call. If the
  /// list is omitted, 'dynamic' type arguments are filled in.
  InterfaceType(Class classNode,
      [List<DartType> typeArguments,
      Nullability nullability = Nullability.legacy])
      : this.byReference(getClassReference(classNode),
            typeArguments ?? _defaultTypeArguments(classNode), nullability);

  InterfaceType.byReference(this.className, this.typeArguments,
      [this.nullability = Nullability.legacy]);

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

  R accept<R>(DartTypeVisitor<R> v) => v.visitInterfaceType(this);
  R accept1<R, A>(DartTypeVisitor1<R, A> v, A arg) =>
      v.visitInterfaceType(this, arg);

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

  InterfaceType withNullability(Nullability nullability) {
    return nullability == this.nullability
        ? this
        : new InterfaceType.byReference(className, typeArguments, nullability);
  }
}

/// A possibly generic function type.
class FunctionType extends DartType {
  final List<TypeParameter> typeParameters;
  final int requiredParameterCount;
  final List<DartType> positionalParameters;
  final List<NamedType> namedParameters; // Must be sorted.
  final Nullability nullability;

  /// The [Typedef] this function type is created for.
  final TypedefType typedefType;

  final DartType returnType;
  int _hashCode;

  FunctionType(List<DartType> positionalParameters, this.returnType,
      {this.namedParameters: const <NamedType>[],
      this.typeParameters: const <TypeParameter>[],
      this.nullability: Nullability.legacy,
      int requiredParameterCount,
      this.typedefType})
      : this.positionalParameters = positionalParameters,
        this.requiredParameterCount =
            requiredParameterCount ?? positionalParameters.length;

  Reference get typedefReference => typedefType?.typedefReference;

  Typedef get typedef => typedefReference?.asTypedef;

  R accept<R>(DartTypeVisitor<R> v) => v.visitFunctionType(this);
  R accept1<R, A>(DartTypeVisitor1<R, A> v, A arg) =>
      v.visitFunctionType(this, arg);

  visitChildren(Visitor v) {
    visitList(typeParameters, v);
    visitList(positionalParameters, v);
    visitList(namedParameters, v);
    typedefType?.accept(v);
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
        namedParameters: namedParameters,
        typedefType: null);
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

  FunctionType withNullability(Nullability nullability) {
    if (nullability == this.nullability) return this;
    FunctionType result = FunctionType(positionalParameters, returnType,
        namedParameters: namedParameters,
        typeParameters: typeParameters,
        nullability: nullability,
        requiredParameterCount: requiredParameterCount,
        typedefType: typedefType?.withNullability(nullability));
    if (typeParameters.isEmpty) return result;
    return getFreshTypeParameters(typeParameters).applyToFunctionType(result);
  }
}

/// A use of a [Typedef] as a type.
///
/// The underlying type can be extracted using [unalias].
class TypedefType extends DartType {
  final Nullability nullability;
  final Reference typedefReference;
  final List<DartType> typeArguments;

  TypedefType(Typedef typedefNode,
      [List<DartType> typeArguments,
      Nullability nullability = Nullability.legacy])
      : this.byReference(typedefNode.reference,
            typeArguments ?? const <DartType>[], nullability);

  TypedefType.byReference(this.typedefReference, this.typeArguments,
      [this.nullability = Nullability.legacy]);

  Typedef get typedefNode => typedefReference.asTypedef;

  R accept<R>(DartTypeVisitor<R> v) => v.visitTypedefType(this);
  R accept1<R, A>(DartTypeVisitor1<R, A> v, A arg) =>
      v.visitTypedefType(this, arg);

  visitChildren(Visitor v) {
    visitList(typeArguments, v);
    v.visitTypedefReference(typedefNode);
  }

  DartType get unaliasOnce {
    return Substitution.fromTypedefType(this)
        .substituteType(typedefNode.type)
        .withNullability(nullability);
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

  TypedefType withNullability(Nullability nullability) {
    return nullability == this.nullability
        ? this
        : new TypedefType.byReference(
            typedefReference, typeArguments, nullability);
  }
}

/// A named parameter in [FunctionType].
class NamedType extends Node implements Comparable<NamedType> {
  // Flag used for serialization if [isRequired].
  static const int FlagRequiredNamedType = 1 << 0;

  final String name;
  final DartType type;
  final bool isRequired;

  NamedType(this.name, this.type, {this.isRequired: false});

  bool operator ==(Object other) {
    return other is NamedType &&
        name == other.name &&
        type == other.type &&
        isRequired == other.isRequired;
  }

  int get hashCode {
    return name.hashCode * 31 + type.hashCode * 37 + isRequired.hashCode * 41;
  }

  int compareTo(NamedType other) => name.compareTo(other.name);

  R accept<R>(Visitor<R> v) => v.visitNamedType(this);

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
/// whether the bound has been promoted.  The case of promoted bound can be
/// viewed as representing an intersection type between the type-parameter type
/// and the promoted bound.
class TypeParameterType extends DartType {
  /// Nullability of the type-parameter type or of its part of the intersection.
  ///
  /// Declarations of type-parameter types can set the nullability of a
  /// type-parameter type to [Nullability.nullable] (if the `?` marker is used)
  /// or [Nullability.legacy] (if the type comes from a library opted out from
  /// NNBD).  Otherwise, it's defined indirectly via the nullability of the
  /// bound of [parameter].  In cases when the [TypeParameterType] represents an
  /// intersection between a type-parameter type and [promotedBound],
  /// [typeParameterTypeNullability] represents the nullability of the left-hand
  /// side of the intersection.
  Nullability typeParameterTypeNullability;

  TypeParameter parameter;

  /// An optional promoted bound on the type parameter.
  ///
  /// 'null' indicates that the type parameter's bound has not been promoted and
  /// is therefore the same as the bound of [parameter].
  DartType promotedBound;

  TypeParameterType(this.parameter,
      [this.promotedBound,
      this.typeParameterTypeNullability = Nullability.legacy]);

  R accept<R>(DartTypeVisitor<R> v) => v.visitTypeParameterType(this);
  R accept1<R, A>(DartTypeVisitor1<R, A> v, A arg) =>
      v.visitTypeParameterType(this, arg);

  visitChildren(Visitor v) {}

  bool operator ==(Object other) {
    return other is TypeParameterType && parameter == other.parameter;
  }

  int get hashCode => _temporaryHashCodeTable[parameter] ?? parameter.hashCode;

  /// Returns the bound of the type parameter, accounting for promotions.
  DartType get bound => promotedBound ?? parameter.bound;

  /// Nullability of the type, calculated from its parts.
  ///
  /// [nullability] is calculated from [typeParameterTypeNullability] and the
  /// nullability of [promotedBound] if it's present.
  ///
  /// For example, in the following program [typeParameterTypeNullability] of
  /// both `x` and `y` is [Nullability.neither], because it's copied from that
  /// of `bar` and T has a nullable type as its bound.  However, despite
  /// [nullability] of `x` is [Nullability.neither], [nullability] of `y` is
  /// [Nullability.nonNullable] because of its [promotedBound].
  ///
  ///     class A<T extends Object?> {
  ///       foo(T bar) {
  ///         var x = bar;
  ///         if (bar is int) {
  ///           var y = bar;
  ///         }
  ///       }
  ///     }
  Nullability get nullability {
    return getNullability(
        typeParameterTypeNullability ?? computeNullabilityFromBound(parameter),
        promotedBound);
  }

  /// Gets a new [TypeParameterType] with given [typeParameterTypeNullability].
  ///
  /// In contrast with other types, [TypeParameterType.withNullability] doesn't
  /// set the overall nullability of the returned type but sets that of the
  /// left-hand side of the intersection type.  In case [promotedBound] is null,
  /// it is an equivalent of setting the overall nullability.
  TypeParameterType withNullability(Nullability typeParameterTypeNullability) {
    return typeParameterTypeNullability == this.typeParameterTypeNullability
        ? this
        : new TypeParameterType(
            parameter, promotedBound, typeParameterTypeNullability);
  }

  /// Gets the nullability of a type-parameter type based on the bound.
  ///
  /// This is a helper function to be used when the bound of the type parameter
  /// is changing or is being set for the first time, and the update on some
  /// type-parameter types is required.
  static Nullability computeNullabilityFromBound(TypeParameter typeParameter) {
    // If the bound is nullable or 'neither', both nullable and non-nullable
    // types can be passed in for the type parameter, making the corresponding
    // type parameter types 'neither.'  Otherwise, the nullability matches that
    // of the bound.
    DartType bound = typeParameter.bound;
    if (bound == null) {
      throw new StateError("Can't compute nullability from an absent bound.");
    }
    Nullability boundNullability =
        bound is InvalidType ? Nullability.neither : bound.nullability;
    return boundNullability == Nullability.nullable ||
            boundNullability == Nullability.neither
        ? Nullability.neither
        : boundNullability;
  }

  /// Gets nullability of [TypeParameterType] from arguments to its constructor.
  ///
  /// The method combines [typeParameterTypeNullability] and the nullability of
  /// [promotedBound] to yield the nullability of the intersection type.  If the
  /// right-hand side of the intersection is absent (that is, if [promotedBound]
  /// is null), the nullability of the intersection type is simply
  /// [typeParameterTypeNullability].
  static Nullability getNullability(
      Nullability typeParameterTypeNullability, DartType promotedBound) {
    // If promotedBound is null, getNullability simply returns the nullability
    // of the type parameter type.
    Nullability lhsNullability = typeParameterTypeNullability;
    if (promotedBound == null) {
      return lhsNullability;
    }

    // If promotedBound isn't null, getNullability returns the nullability of an
    // intersection of the left-hand side (referred to as LHS below) and the
    // right-hand side (referred to as RHS below).  Note that RHS is always a
    // subtype of the bound of the type parameter.

    // The code below implements the rule for the nullability of an intersection
    // type as per the following table:
    //
    // | LHS \ RHS |  !  |  ?  |  *  |  %  |
    // |-----------|-----|-----|-----|-----|
    // |     !     |  !  | N/A | N/A |  !  |
    // |     ?     | N/A | N/A | N/A | N/A |
    // |     *     | N/A | N/A |  *  | N/A |
    // |     %     |  !  |  %  | N/A |  %  |
    //
    // In the table, LHS corresponds to lhsNullability in the code below; RHS
    // corresponds to promotedBound.nullability; !, ?, *, and % correspond to
    // nonNullable, nullable, legacy, and neither values of the Nullability
    // enum.
    //
    // Whenever there's N/A in the table, it means that the corresponding
    // combination of the LHS and RHS nullability is not possible when compiling
    // from Dart source files, so we can define it to be whatever is faster and
    // more convenient to implement.  The verifier should check that the cases
    // marked as N/A never occur in the output of the CFE.
    //
    // The code below uses the following extension of the table function:
    //
    // | LHS \ RHS |  !  |  ?  |  *  |  %  |
    // |-----------|-----|-----|-----|-----|
    // |     !     |  !  |  !  |  !  |  !  |
    // |     ?     |  !  |  *  |  *  |  %  |
    // |     *     |  !  |  *  |  *  |  %  |
    // |     %     |  !  |  %  |  %  |  %  |

    // Intersection with a non-nullable type always yields a non-nullable type,
    // as it's the most restrictive kind of types.
    if (lhsNullability == Nullability.nonNullable ||
        promotedBound.nullability == Nullability.nonNullable) {
      return Nullability.nonNullable;
    }

    // If the nullability of LHS is 'neither,' the nullability of the
    // intersection is also 'neither' if RHS is 'neither' or nullable.
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
    if (lhsNullability == Nullability.neither ||
        promotedBound.nullability == Nullability.neither) {
      return Nullability.neither;
    }

    return Nullability.legacy;
  }
}

/// Value set for variance of a type parameter X in a type term T.
class Variance {
  /// Used when X does not occur free in T.
  static const int unrelated = 0;

  /// Used when X occurs free in T, and U <: V implies [U/X]T <: [V/X]T.
  static const int covariant = 1;

  /// Used when X occurs free in T, and U <: V implies [V/X]T <: [U/X]T.
  static const int contravariant = 2;

  /// Used when there exists a pair U and V such that U <: V, but [U/X]T and
  /// [V/X]T are incomparable.
  static const int invariant = 3;

  /// Variance values form a lattice where [unrelated] is the top, [invariant]
  /// is the bottom, and [covariant] and [contravariant] are incomparable.
  /// [meet] calculates the meet of two elements of such lattice.  It can be
  /// used, for example, to calculate the variance of a typedef type parameter
  /// if it's encountered on the r.h.s. of the typedef multiple times.
  static int meet(int a, int b) => a | b;

  /// Combines variances of X in T and Y in S into variance of X in [Y/T]S.
  ///
  /// Consider the following examples:
  ///
  /// * variance of X in Function(X) is [contravariant], variance of Y in
  /// List<Y> is [covariant], so variance of X in List<Function(X)> is
  /// [contravariant];
  ///
  /// * variance of X in List<X> is [covariant], variance of Y in Function(Y) is
  /// [contravariant], so variance of X in Function(List<X>) is [contravariant];
  ///
  /// * variance of X in Function(X) is [contravariant], variance of Y in
  /// Function(Y) is [contravariant], so variance of X in Function(Function(X))
  /// is [covariant];
  ///
  /// * let the following be declared:
  ///
  ///     typedef F<Z> = Function();
  ///
  /// then variance of X in F<X> is [unrelated], variance of Y in List<Y> is
  /// [covariant], so variance of X in List<F<X>> is [unrelated];
  ///
  /// * let the following be declared:
  ///
  ///     typedef G<Z> = Z Function(Z);
  ///
  /// then variance of X in List<X> is [covariant], variance of Y in G<Y> is
  /// [invariant], so variance of `X` in `G<List<X>>` is [invariant].
  static int combine(int a, int b) {
    if (a == unrelated || b == unrelated) return unrelated;
    if (a == invariant || b == invariant) return invariant;
    return a == b ? covariant : contravariant;
  }

  static int fromString(String variance) {
    if (variance == "in") {
      return contravariant;
    } else if (variance == "inout") {
      return invariant;
    } else if (variance == "out") {
      return covariant;
    } else {
      return unrelated;
    }
  }
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

  /// List of metadata annotations on the type parameter.
  ///
  /// This defaults to an immutable empty list. Use [addAnnotation] to add
  /// annotations if needed.
  List<Expression> annotations = const <Expression>[];

  String name; // Cosmetic name.

  /// The bound on the type variable.
  ///
  /// Should not be null except temporarily during IR construction.  Should
  /// be set to the root class for type parameters without an explicit bound.
  DartType bound;

  /// The default value of the type variable. It is used to provide the
  /// corresponding missing type argument in type annotations and as the
  /// fall-back type value in type inference at compile time. At run time,
  /// [defaultType] is used by the backends in place of the missing type
  /// argument of a dynamic invocation of a generic function.
  DartType defaultType;

  /// Describes variance of the type parameter w.r.t. declaration on which it is
  /// defined.  It's always [Variance.covariant] for classes, and for typedefs
  /// it's the variance of the type parameters in the type term on the r.h.s. of
  /// the typedef.
  int variance = Variance.covariant;

  TypeParameter([this.name, this.bound, this.defaultType]);

  // Must match serialized bit positions.
  static const int FlagGenericCovariantImpl = 1 << 0;

  /// If this [TypeParameter] is a type parameter of a generic method, indicates
  /// whether the method implementation needs to contain a runtime type check to
  /// deal with generic covariance.
  ///
  /// When `true`, runtime checks may need to be performed; see
  /// [DispatchCategory] for details.
  bool get isGenericCovariantImpl => flags & FlagGenericCovariantImpl != 0;

  void set isGenericCovariantImpl(bool value) {
    flags = value
        ? (flags | FlagGenericCovariantImpl)
        : (flags & ~FlagGenericCovariantImpl);
  }

  void addAnnotation(Expression annotation) {
    if (annotations.isEmpty) {
      annotations = <Expression>[];
    }
    annotations.add(annotation..parent = this);
  }

  R accept<R>(TreeVisitor<R> v) => v.visitTypeParameter(this);

  visitChildren(Visitor v) {
    visitList(annotations, v);
    bound.accept(v);
    defaultType?.accept(v);
  }

  transformChildren(Transformer v) {
    transformList(annotations, v, this);
    bound = v.visitDartType(bound);
    if (defaultType != null) {
      defaultType = v.visitDartType(defaultType);
    }
  }

  /// Returns a possibly synthesized name for this type parameter, consistent
  /// with the names used across all [toString] calls.
  String toString() => debugQualifiedTypeParameterName(this);

  bool get isFunctionTypeTypeParameter => parent == null;
}

class Supertype extends Node {
  Reference className;
  final List<DartType> typeArguments;

  Supertype(Class classNode, List<DartType> typeArguments)
      : this.byReference(getClassReference(classNode), typeArguments);

  Supertype.byReference(this.className, this.typeArguments);

  Class get classNode => className.asClass;

  R accept<R>(Visitor<R> v) => v.visitSupertype(this);

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
//                             CONSTANTS
// ------------------------------------------------------------------------

abstract class Constant extends Node {
  /// Calls the `visit*ConstantReference()` method on visitor [v] for all
  /// constants referenced in this constant.
  ///
  /// (Note that a constant can be seen as a DAG (directed acyclic graph) and
  ///  not a tree!)
  visitChildren(Visitor v);

  /// Calls the `visit*Constant()` method on the visitor [v].
  R accept<R>(ConstantVisitor<R> v);

  /// Calls the `visit*ConstantReference()` method on the visitor [v].
  R acceptReference<R>(Visitor<R> v);

  /// The Kernel AST will reference [Constant]s via [ConstantExpression]s.  The
  /// constants are not required to be canonicalized, but they have to be deeply
  /// comparable via hashCode/==!
  int get hashCode;
  bool operator ==(Object other);

  /// Gets the type of this constant.
  DartType getType(TypeEnvironment types);

  Expression asExpression() {
    return new ConstantExpression(this);
  }
}

abstract class PrimitiveConstant<T> extends Constant {
  final T value;

  PrimitiveConstant(this.value);

  String toString() => '$value';

  int get hashCode => value.hashCode;

  bool operator ==(Object other) =>
      other is PrimitiveConstant<T> && other.value == value;
}

class NullConstant extends PrimitiveConstant<Null> {
  NullConstant() : super(null);

  visitChildren(Visitor v) {}
  R accept<R>(ConstantVisitor<R> v) => v.visitNullConstant(this);
  R acceptReference<R>(Visitor<R> v) => v.visitNullConstantReference(this);

  DartType getType(TypeEnvironment types) => types.nullType;
}

class BoolConstant extends PrimitiveConstant<bool> {
  BoolConstant(bool value) : super(value);

  visitChildren(Visitor v) {}
  R accept<R>(ConstantVisitor<R> v) => v.visitBoolConstant(this);
  R acceptReference<R>(Visitor<R> v) => v.visitBoolConstantReference(this);

  DartType getType(TypeEnvironment types) => types.coreTypes.boolLegacyRawType;
}

/// An integer constant on a non-JS target.
class IntConstant extends PrimitiveConstant<int> {
  IntConstant(int value) : super(value);

  visitChildren(Visitor v) {}
  R accept<R>(ConstantVisitor<R> v) => v.visitIntConstant(this);
  R acceptReference<R>(Visitor<R> v) => v.visitIntConstantReference(this);

  DartType getType(TypeEnvironment types) => types.coreTypes.intLegacyRawType;
}

/// A double constant on a non-JS target or any numeric constant on a JS target.
class DoubleConstant extends PrimitiveConstant<double> {
  DoubleConstant(double value) : super(value);

  visitChildren(Visitor v) {}
  R accept<R>(ConstantVisitor<R> v) => v.visitDoubleConstant(this);
  R acceptReference<R>(Visitor<R> v) => v.visitDoubleConstantReference(this);

  int get hashCode => value.isNaN ? 199 : super.hashCode;
  bool operator ==(Object other) =>
      other is DoubleConstant && identical(value, other.value);

  DartType getType(TypeEnvironment types) =>
      types.coreTypes.doubleLegacyRawType;
}

class StringConstant extends PrimitiveConstant<String> {
  StringConstant(String value) : super(value) {
    assert(value != null);
  }

  visitChildren(Visitor v) {}
  R accept<R>(ConstantVisitor<R> v) => v.visitStringConstant(this);
  R acceptReference<R>(Visitor<R> v) => v.visitStringConstantReference(this);

  DartType getType(TypeEnvironment types) =>
      types.coreTypes.stringLegacyRawType;
}

class SymbolConstant extends Constant {
  final String name;
  final Reference libraryReference;

  SymbolConstant(this.name, this.libraryReference);

  visitChildren(Visitor v) {}

  R accept<R>(ConstantVisitor<R> v) => v.visitSymbolConstant(this);
  R acceptReference<R>(Visitor<R> v) => v.visitSymbolConstantReference(this);

  String toString() {
    return libraryReference != null
        ? '#${libraryReference.asLibrary.importUri}::$name'
        : '#$name';
  }

  int get hashCode => _Hash.hash2(name, libraryReference);

  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SymbolConstant &&
          other.name == name &&
          other.libraryReference == libraryReference);

  DartType getType(TypeEnvironment types) =>
      types.coreTypes.symbolLegacyRawType;
}

class MapConstant extends Constant {
  final DartType keyType;
  final DartType valueType;
  final List<ConstantMapEntry> entries;

  MapConstant(this.keyType, this.valueType, this.entries);

  visitChildren(Visitor v) {
    keyType.accept(v);
    valueType.accept(v);
    for (final ConstantMapEntry entry in entries) {
      entry.key.acceptReference(v);
      entry.value.acceptReference(v);
    }
  }

  R accept<R>(ConstantVisitor<R> v) => v.visitMapConstant(this);
  R acceptReference<R>(Visitor<R> v) => v.visitMapConstantReference(this);

  String toString() => '${this.runtimeType}<$keyType, $valueType>($entries)';

  int _cachedHashCode;
  int get hashCode {
    return _cachedHashCode ??= _Hash.combine2Finish(
        keyType.hashCode, valueType.hashCode, _Hash.combineListHash(entries));
  }

  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MapConstant &&
          other.keyType == keyType &&
          other.valueType == valueType &&
          listEquals(other.entries, entries));

  DartType getType(TypeEnvironment types) =>
      types.literalMapType(keyType, valueType);
}

class ConstantMapEntry {
  final Constant key;
  final Constant value;
  ConstantMapEntry(this.key, this.value);

  String toString() => '$key: $value';

  int get hashCode => _Hash.hash2(key, value);

  bool operator ==(Object other) =>
      other is ConstantMapEntry && other.key == key && other.value == value;
}

class ListConstant extends Constant {
  final DartType typeArgument;
  final List<Constant> entries;

  ListConstant(this.typeArgument, this.entries);

  visitChildren(Visitor v) {
    typeArgument.accept(v);
    for (final Constant constant in entries) {
      constant.acceptReference(v);
    }
  }

  R accept<R>(ConstantVisitor<R> v) => v.visitListConstant(this);
  R acceptReference<R>(Visitor<R> v) => v.visitListConstantReference(this);

  String toString() => '${this.runtimeType}<$typeArgument>($entries)';

  int _cachedHashCode;
  int get hashCode {
    return _cachedHashCode ??= _Hash.combineFinish(
        typeArgument.hashCode, _Hash.combineListHash(entries));
  }

  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ListConstant &&
          other.typeArgument == typeArgument &&
          listEquals(other.entries, entries));

  DartType getType(TypeEnvironment types) =>
      types.literalListType(typeArgument);
}

class SetConstant extends Constant {
  final DartType typeArgument;
  final List<Constant> entries;

  SetConstant(this.typeArgument, this.entries);

  visitChildren(Visitor v) {
    typeArgument.accept(v);
    for (final Constant constant in entries) {
      constant.acceptReference(v);
    }
  }

  R accept<R>(ConstantVisitor<R> v) => v.visitSetConstant(this);
  R acceptReference<R>(Visitor<R> v) => v.visitSetConstantReference(this);

  String toString() => '${this.runtimeType}<$typeArgument>($entries)';

  int _cachedHashCode;
  int get hashCode {
    return _cachedHashCode ??= _Hash.combineFinish(
        typeArgument.hashCode, _Hash.combineListHash(entries));
  }

  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SetConstant &&
          other.typeArgument == typeArgument &&
          listEquals(other.entries, entries));

  DartType getType(TypeEnvironment types) => types.literalSetType(typeArgument);
}

class InstanceConstant extends Constant {
  final Reference classReference;
  final List<DartType> typeArguments;
  final Map<Reference, Constant> fieldValues;

  InstanceConstant(this.classReference, this.typeArguments, this.fieldValues);

  Class get classNode => classReference.asClass;

  visitChildren(Visitor v) {
    classReference.asClass.acceptReference(v);
    visitList(typeArguments, v);
    for (final Reference reference in fieldValues.keys) {
      reference.asField.acceptReference(v);
    }
    for (final Constant constant in fieldValues.values) {
      constant.acceptReference(v);
    }
  }

  R accept<R>(ConstantVisitor<R> v) => v.visitInstanceConstant(this);
  R acceptReference<R>(Visitor<R> v) => v.visitInstanceConstantReference(this);

  String toString() {
    final sb = new StringBuffer();
    sb.write('${classReference.asClass}');
    if (!classReference.asClass.typeParameters.isEmpty) {
      sb.write('<');
      sb.write(typeArguments.map((type) => type.toString()).join(', '));
      sb.write('>');
    }
    sb.write(' {');
    fieldValues.forEach((Reference fieldRef, Constant constant) {
      sb.write('${fieldRef.asField.name}: $constant, ');
    });
    sb.write('}');
    return sb.toString();
  }

  int _cachedHashCode;
  int get hashCode {
    return _cachedHashCode ??= _Hash.combine2Finish(
        classReference.hashCode,
        listHashCode(typeArguments),
        _Hash.combineMapHashUnordered(fieldValues));
  }

  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is InstanceConstant &&
            other.classReference == classReference &&
            listEquals(other.typeArguments, typeArguments) &&
            mapEquals(other.fieldValues, fieldValues));
  }

  DartType getType(TypeEnvironment types) =>
      new InterfaceType(classNode, typeArguments);
}

class PartialInstantiationConstant extends Constant {
  final TearOffConstant tearOffConstant;
  final List<DartType> types;

  PartialInstantiationConstant(this.tearOffConstant, this.types);

  visitChildren(Visitor v) {
    tearOffConstant.acceptReference(v);
    visitList(types, v);
  }

  R accept<R>(ConstantVisitor<R> v) =>
      v.visitPartialInstantiationConstant(this);
  R acceptReference<R>(Visitor<R> v) =>
      v.visitPartialInstantiationConstantReference(this);

  String toString() {
    return '${runtimeType}(${tearOffConstant.procedure}<${types.join(', ')}>)';
  }

  int get hashCode => _Hash.combineFinish(
      tearOffConstant.hashCode, _Hash.combineListHash(types));

  bool operator ==(Object other) {
    return other is PartialInstantiationConstant &&
        other.tearOffConstant == tearOffConstant &&
        listEquals(other.types, types);
  }

  DartType getType(TypeEnvironment typeEnvironment) {
    final FunctionType type = tearOffConstant.getType(typeEnvironment);
    final mapping = <TypeParameter, DartType>{};
    for (final parameter in type.typeParameters) {
      mapping[parameter] = types[mapping.length];
    }
    return substitute(type.withoutTypeParameters, mapping);
  }
}

class TearOffConstant extends Constant {
  final Reference procedureReference;

  TearOffConstant(Procedure procedure)
      : procedureReference = procedure.reference {
    assert(procedure.isStatic);
  }

  TearOffConstant.byReference(this.procedureReference);

  Procedure get procedure => procedureReference?.asProcedure;

  visitChildren(Visitor v) {
    procedureReference.asProcedure.acceptReference(v);
  }

  R accept<R>(ConstantVisitor<R> v) => v.visitTearOffConstant(this);
  R acceptReference<R>(Visitor<R> v) => v.visitTearOffConstantReference(this);

  String toString() {
    return '${runtimeType}(${procedure})';
  }

  int get hashCode => procedureReference.hashCode;

  bool operator ==(Object other) {
    return other is TearOffConstant &&
        other.procedureReference == procedureReference;
  }

  FunctionType getType(TypeEnvironment types) =>
      procedure.function.functionType;
}

class TypeLiteralConstant extends Constant {
  final DartType type;

  TypeLiteralConstant(this.type);

  visitChildren(Visitor v) {
    type.accept(v);
  }

  R accept<R>(ConstantVisitor<R> v) => v.visitTypeLiteralConstant(this);
  R acceptReference<R>(Visitor<R> v) =>
      v.visitTypeLiteralConstantReference(this);

  String toString() => '${runtimeType}(${type})';

  int get hashCode => type.hashCode;

  bool operator ==(Object other) {
    return other is TypeLiteralConstant && other.type == type;
  }

  DartType getType(TypeEnvironment types) => types.coreTypes.typeLegacyRawType;
}

class UnevaluatedConstant extends Constant {
  final Expression expression;

  UnevaluatedConstant(this.expression) {
    expression?.parent = null;
  }

  visitChildren(Visitor v) {
    expression.accept(v);
  }

  R accept<R>(ConstantVisitor<R> v) => v.visitUnevaluatedConstant(this);
  R acceptReference<R>(Visitor<R> v) =>
      v.visitUnevaluatedConstantReference(this);

  DartType getType(TypeEnvironment types) => expression.getStaticType(types);

  @override
  Expression asExpression() => expression;
}

// ------------------------------------------------------------------------
//                                COMPONENT
// ------------------------------------------------------------------------

/// A way to bundle up libraries in a component.
class Component extends TreeNode {
  final CanonicalName root;

  /// Problems in this [Component] encoded as json objects.
  ///
  /// Note that this field can be null, and by convention should be null if the
  /// list is empty.
  List<String> problemsAsJson;

  final List<Library> libraries;

  /// Map from a source file URI to a line-starts table and source code.
  /// Given a source file URI and a offset in that file one can translate
  /// it to a line:column position in that file.
  final Map<Uri, Source> uriToSource;

  /// Mapping between string tags and [MetadataRepository] corresponding to
  /// those tags.
  final Map<String, MetadataRepository<dynamic>> metadata =
      <String, MetadataRepository<dynamic>>{};

  /// Reference to the main method in one of the libraries.
  Reference mainMethodName;

  Component(
      {CanonicalName nameRoot,
      List<Library> libraries,
      Map<Uri, Source> uriToSource})
      : root = nameRoot ?? new CanonicalName.root(),
        libraries = libraries ?? <Library>[],
        uriToSource = uriToSource ?? <Uri, Source>{} {
    adoptChildren();
  }

  void adoptChildren() {
    if (libraries != null) {
      for (int i = 0; i < libraries.length; ++i) {
        // The libraries are owned by this component, and so are their canonical
        // names if they exist.
        Library library = libraries[i];
        library.parent = this;
        CanonicalName name = library.reference.canonicalName;
        if (name != null && name.parent != root) {
          root.adoptChild(name);
        }
      }
    }
  }

  void computeCanonicalNames() {
    for (int i = 0; i < libraries.length; ++i) {
      computeCanonicalNamesForLibrary(libraries[i]);
    }
  }

  void computeCanonicalNamesForLibrary(Library library) {
    root.getChildFromUri(library.importUri).bindTo(library.reference);
    library.computeCanonicalNames();
  }

  void unbindCanonicalNames() {
    // TODO(jensj): Get rid of this.
    for (int i = 0; i < libraries.length; i++) {
      Library lib = libraries[i];
      for (int j = 0; j < lib.classes.length; j++) {
        Class c = lib.classes[j];
        c.dirty = true;
      }
    }
    root.unbindAll();
  }

  Procedure get mainMethod => mainMethodName?.asProcedure;

  void set mainMethod(Procedure main) {
    mainMethodName = getMemberReference(main);
  }

  R accept<R>(TreeVisitor<R> v) => v.visitComponent(this);

  visitChildren(Visitor v) {
    visitList(libraries, v);
    mainMethod?.acceptReference(v);
  }

  transformChildren(Transformer v) {
    transformList(libraries, v, this);
  }

  Component get enclosingComponent => this;

  /// Translates an offset to line and column numbers in the given file.
  Location getLocation(Uri file, int offset) {
    return uriToSource[file]?.getLocation(file, offset);
  }

  void addMetadataRepository(MetadataRepository repository) {
    metadata[repository.tag] = repository;
  }
}

/// A tuple with file, line, and column number, for displaying human-readable
/// locations.
class Location {
  final Uri file;
  final int line; // 1-based.
  final int column; // 1-based.

  Location(this.file, this.line, this.column);

  String toString() => '$file:$line:$column';
}

abstract class MetadataRepository<T> {
  /// Unique string tag associated with this repository.
  String get tag;

  /// Mutable mapping between nodes and their metadata.
  Map<TreeNode, T> get mapping;

  /// Write [metadata] object corresponding to the given [Node] into
  /// the given [BinarySink].
  ///
  /// Metadata is serialized immediately before serializing [node],
  /// so implementation of this method can use serialization context of
  /// [node]'s parents (such as declared type parameters and variables).
  /// In order to use scope declared by the [node] itself, implementation of
  /// this method can use [BinarySink.enterScope] and [BinarySink.leaveScope]
  /// methods.
  ///
  /// [metadata] must be an object owned by this repository.
  void writeToBinary(T metadata, Node node, BinarySink sink);

  /// Construct a metadata object from its binary payload read from the
  /// given [BinarySource].
  ///
  /// Metadata is deserialized immediately after deserializing [node],
  /// so it can use deserialization context of [node]'s parents.
  /// In order to use scope declared by the [node] itself, implementation of
  /// this method can use [BinarySource.enterScope] and
  /// [BinarySource.leaveScope] methods.
  T readFromBinary(Node node, BinarySource source);

  /// Method to check whether a node can have metadata attached to it
  /// or referenced from the metadata payload.
  ///
  /// Currently due to binary format specifics Catch and MapEntry nodes
  /// can't have metadata attached to them.
  static bool isSupported(TreeNode node) {
    return !(node is MapEntry || node is Catch);
  }
}

abstract class BinarySink {
  int getBufferOffset();

  void writeByte(int byte);
  void writeBytes(List<int> bytes);
  void writeUInt32(int value);
  void writeUInt30(int value);

  /// Write List<Byte> into the sink.
  void writeByteList(List<int> bytes);

  void writeNullAllowedCanonicalNameReference(CanonicalName name);
  void writeStringReference(String str);
  void writeName(Name node);
  void writeDartType(DartType type);
  void writeNode(Node node);

  void enterScope(
      {List<TypeParameter> typeParameters,
      bool memberScope: false,
      bool variableScope: false});
  void leaveScope(
      {List<TypeParameter> typeParameters,
      bool memberScope: false,
      bool variableScope: false});
}

abstract class BinarySource {
  int get currentOffset;
  List<int> get bytes;

  int readByte();
  List<int> readBytes(int length);
  int readUInt();
  int readUint32();

  /// Read List<Byte> from the source.
  List<int> readByteList();

  CanonicalName readCanonicalNameReference();
  String readStringReference();
  Name readName();
  DartType readDartType();
  FunctionNode readFunctionNode();

  void enterScope({List<TypeParameter> typeParameters});
  void leaveScope({List<TypeParameter> typeParameters});
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

  final Uri importUri;

  final Uri fileUri;

  String cachedText;

  Source(this.lineStarts, this.source, this.importUri, this.fileUri);

  /// Return the text corresponding to [line] which is a 1-based line
  /// number. The returned line contains no line separators.
  String getTextLine(int line) {
    if (source == null ||
        source.isEmpty ||
        lineStarts == null ||
        lineStarts.isEmpty) return null;
    RangeError.checkValueInInterval(line, 1, lineStarts.length, 'line');

    cachedText ??= utf8.decode(source, allowMalformed: true);
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
  Location getLocation(Uri file, int offset) {
    if (lineStarts == null || lineStarts.isEmpty) {
      return new Location(file, TreeNode.noOffset, TreeNode.noOffset);
    }
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

/// Returns the canonical name of [extension], or throws an exception if the
/// class has not been assigned a canonical name yet.
///
/// Returns `null` if the extension is `null`.
CanonicalName getCanonicalNameOfExtension(Extension extension) {
  if (extension == null) return null;
  if (extension.canonicalName == null) {
    throw '$extension has no canonical name';
  }
  return extension.canonicalName;
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

/// Murmur-inspired hashing, with a fall-back to Jenkins-inspired hashing when
/// compiled to JavaScript.
///
/// A hash function should be constructed of several [combine] calls followed by
/// a [finish] call.
class _Hash {
  static const int M = 0x9ddfea08eb382000 + 0xd69;
  static const bool intIs64Bit = (1 << 63) != 0;

  /// Primitive hash combining step.
  static int combine(int value, int hash) {
    if (intIs64Bit) {
      value *= M;
      value ^= _shru(value, 47);
      value *= M;
      hash ^= value;
      hash *= M;
    } else {
      // Fall back to Jenkins-inspired hashing on JavaScript platforms.
      hash = 0x1fffffff & (hash + value);
      hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
      hash = hash ^ (hash >> 6);
    }
    return hash;
  }

  /// Primitive hash finalization step.
  static int finish(int hash) {
    if (intIs64Bit) {
      hash ^= _shru(hash, 44);
      hash *= M;
      hash ^= _shru(hash, 41);
    } else {
      // Fall back to Jenkins-inspired hashing on JavaScript platforms.
      hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
      hash = hash ^ (hash >> 11);
      hash = 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
    }
    return hash;
  }

  static int combineFinish(int value, int hash) {
    return finish(combine(value, hash));
  }

  static int combine2(int value1, int value2, int hash) {
    return combine(value2, combine(value1, hash));
  }

  static int combine2Finish(int value1, int value2, int hash) {
    return finish(combine2(value1, value2, hash));
  }

  static int hash2(Object object1, Object object2) {
    return combine2Finish(object2.hashCode, object2.hashCode, 0);
  }

  static int combineListHash(List list, [int hash = 1]) {
    for (var item in list) {
      hash = _Hash.combine(item.hashCode, hash);
    }
    return hash;
  }

  static int combineList(List<int> hashes, int hash) {
    for (var item in hashes) {
      hash = combine(item, hash);
    }
    return hash;
  }

  static int combineMapHashUnordered(Map map, [int hash = 2]) {
    if (map == null || map.isEmpty) return hash;
    List<int> entryHashes = List(map.length);
    int i = 0;
    for (var entry in map.entries) {
      entryHashes[i++] = combine(entry.key.hashCode, entry.value.hashCode);
    }
    entryHashes.sort();
    return combineList(entryHashes, hash);
  }

  // TODO(sra): Replace with '>>>'.
  static int _shru(int v, int n) {
    assert(n >= 1);
    assert(intIs64Bit);
    return ((v >> 1) & (0x7fffFFFFffffF000 + 0xFFF)) >> (n - 1);
  }
}

int listHashCode(List list) {
  return _Hash.finish(_Hash.combineListHash(list));
}

int mapHashCode(Map map) {
  return mapHashCodeUnordered(map);
}

int mapHashCodeOrdered(Map map, [int hash = 2]) {
  for (final Object x in map.keys) hash = _Hash.combine(x.hashCode, hash);
  for (final Object x in map.values) hash = _Hash.combine(x.hashCode, hash);
  return _Hash.finish(hash);
}

int mapHashCodeUnordered(Map map) {
  return _Hash.finish(_Hash.combineMapHashUnordered(map));
}

bool listEquals(List a, List b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool mapEquals(Map a, Map b) {
  if (a.length != b.length) return false;
  for (final Object key in a.keys) {
    if (!b.containsKey(key) || a[key] != b[key]) return false;
  }
  return true;
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

Location _getLocationInComponent(Component component, Uri fileUri, int offset) {
  if (component != null) {
    return component.getLocation(fileUri, offset);
  } else {
    return new Location(fileUri, TreeNode.noOffset, TreeNode.noOffset);
  }
}

/// Convert the synthetic name of an implicit mixin application class
/// into a name suitable for user-faced strings.
///
/// For example, when compiling "class A extends S with M1, M2", the
/// two synthetic classes will be named "_A&S&M1" and "_A&S&M1&M2".
/// This function will return "S with M1" and "S with M1, M2", respectively.
String demangleMixinApplicationName(String name) {
  List<String> nameParts = name.split('&');
  if (nameParts.length < 2 || name == "&") return name;
  String demangledName = nameParts[1];
  for (int i = 2; i < nameParts.length; i++) {
    demangledName += (i == 2 ? " with " : ", ") + nameParts[i];
  }
  return demangledName;
}

/// Extract from the synthetic name of an implicit mixin application class
/// the name of the final subclass of the mixin application.
///
/// For example, when compiling "class A extends S with M1, M2", the
/// two synthetic classes will be named "_A&S&M1" and "_A&S&M1&M2".
/// This function will return "A" for both classes.
String demangleMixinApplicationSubclassName(String name) {
  List<String> nameParts = name.split('&');
  if (nameParts.length < 2) return name;
  assert(nameParts[0].startsWith('_'));
  return nameParts[0].substring(1);
}
