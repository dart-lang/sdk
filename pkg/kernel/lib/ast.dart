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

import 'dart:core';
import 'dart:core' as core show MapEntry;
import 'dart:collection' show ListBase;
import 'dart:convert' show utf8;

import 'visitor.dart';
export 'visitor.dart';

import 'canonical_name.dart' show CanonicalName;
export 'canonical_name.dart' show CanonicalName;

import 'default_language_version.dart' show defaultLanguageVersion;
export 'default_language_version.dart' show defaultLanguageVersion;

import 'transformations/flags.dart';
import 'text/ast_to_text.dart' as astToText;
import 'core_types.dart';
import 'type_algebra.dart';
import 'type_environment.dart';
import 'src/assumptions.dart';
import 'src/printer.dart';
import 'src/text_util.dart';

/// Any type of node in the IR.
abstract class Node {
  const Node();

  R accept<R>(Visitor<R> v);
  void visitChildren(Visitor v);

  /// Returns the textual representation of this node for use in debugging.
  ///
  /// [toString] should only be used for debugging, but should not leak.
  ///
  /// The data is generally bare-bones, but can easily be updated for your
  /// specific debugging needs.
  String toString();

  /// Returns the textual representation of this node for use in debugging.
  ///
  /// [toStringInternal] should only be used for debugging, but should not leak.
  ///
  /// The data is generally bare-bones, but can easily be updated for your
  /// specific debugging needs.
  ///
  /// This method is called internally by toString methods to create conciser
  /// textual representations.
  String toStringInternal() => toText(defaultAstTextStrategy);

  /// Returns the textual representation of this node for use in debugging.
  ///
  /// Note that this adds some nodes to a static map to ensure consistent
  /// naming, but that it thus also leaks memory. [leakingDebugToString] should
  /// thus only be used for debugging and short-running test tools.
  ///
  /// Synthetic names are cached globally to retain consistency across different
  /// [leakingDebugToString] calls (hence the memory leak).
  String leakingDebugToString() => astToText.debugNodeToString(this);

  String toText(AstTextStrategy strategy) {
    AstPrinter printer = new AstPrinter(strategy);
    toTextInternal(printer);
    return printer.getText();
  }

  void toTextInternal(AstPrinter printer);
}

/// A mutable AST node with a parent pointer.
///
/// This is anything other than [Name] and [DartType] nodes.
abstract class TreeNode extends Node {
  static int _hashCounter = 0;
  final int hashCode = _hashCounter = (_hashCounter + 1) & 0x3fffffff;
  static const int noOffset = -1;

  TreeNode? parent;

  /// Offset in the source file it comes from.
  ///
  /// Valid values are from 0 and up, or -1 ([noOffset]) if the file offset is
  /// not available (this is the default if none is specifically set).
  int fileOffset = noOffset;

  R accept<R>(TreeVisitor<R> v);
  R accept1<R, A>(TreeVisitor1<R, A> v, A arg);
  void visitChildren(Visitor v);
  void transformChildren(Transformer v);
  void transformOrRemoveChildren(RemovingTransformer v);

  /// Replaces [child] with [replacement].
  ///
  /// The caller is responsible for ensuring that the AST remains a tree.  In
  /// particular, [replacement] should be an orphan or be part of an orphaned
  /// subtree.
  ///
  /// Has no effect if [child] is not actually a child of this node.
  ///
  /// [replacement] must be non-null.
  void replaceChild(TreeNode child, TreeNode replacement) {
    // ignore: unnecessary_null_comparison
    assert(replacement != null);
    transformChildren(new _ChildReplacer(child, replacement));
  }

  /// Inserts another node in place of this one.
  ///
  /// The caller is responsible for ensuring that the AST remains a tree.  In
  /// particular, [replacement] should be an orphan or be part of an orphaned
  /// subtree.
  ///
  /// [replacement] must be non-null.
  void replaceWith(TreeNode replacement) {
    // ignore: unnecessary_null_comparison
    assert(replacement != null);
    parent!.replaceChild(this, replacement);
    parent = null;
  }

  // TODO(johnniwinther): Make this non-nullable.
  Component? get enclosingComponent => parent?.enclosingComponent;

  /// Returns the best known source location of the given AST node, or `null` if
  /// the node is orphaned.
  ///
  /// This getter is intended for diagnostics and debugging, and should be
  /// avoided in production code.
  Location? get location {
    if (fileOffset == noOffset) return parent?.location;
    return _getLocationInEnclosingFile(fileOffset);
  }

  Location? _getLocationInEnclosingFile(int offset) {
    return parent?._getLocationInEnclosingFile(offset);
  }
}

/// An AST node that can be referenced by other nodes.
///
/// There is a single [reference] belonging to this node, providing a level of
/// indirection that is needed during serialization.
abstract class NamedNode extends TreeNode {
  final Reference reference;

  NamedNode(Reference? reference)
      : this.reference = reference ?? new Reference() {
    if (this is Field) {
      (this as Field).getterReference.node = this;
    } else {
      this.reference.node = this;
    }
  }

  CanonicalName? get canonicalName => reference.canonicalName;

  /// This is an advanced feature.
  ///
  /// See [Component.relink] for a comprehensive description.
  ///
  /// Makes sure the reference in this named node points to itself.
  void _relinkNode() {
    this.reference.node = this;
  }
}

abstract class FileUriNode extends TreeNode {
  /// The URI of the source file this node was loaded from.
  // TODO(johnniwinther): Make this non-nullable.
  Uri? get fileUri;
}

abstract class Annotatable extends TreeNode {
  List<Expression> get annotations;
  void addAnnotation(Expression node);
}

/// Indirection between a reference and its definition.
///
/// There is only one reference object per [NamedNode].
class Reference {
  CanonicalName? canonicalName;

  NamedNode? _node;

  NamedNode? get node {
    if (_node == null) {
      // Either this is an unbound reference or it belongs to a lazy-loaded
      // (and not yet loaded) class. If it belongs to a lazy-loaded class,
      // load the class.

      CanonicalName? canonicalNameParent = canonicalName?.parent;
      while (canonicalNameParent != null) {
        if (canonicalNameParent.name.startsWith("@")) {
          break;
        }
        canonicalNameParent = canonicalNameParent.parent;
      }
      if (canonicalNameParent != null) {
        NamedNode? parentNamedNode =
            canonicalNameParent.parent?.reference?._node;
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

  void set node(NamedNode? node) {
    _node = node;
  }

  String toString() {
    return "Reference to ${toStringInternal()}";
  }

  String toStringInternal() {
    if (canonicalName != null) {
      return '${canonicalName!.toStringInternal()}';
    }
    if (node != null) {
      return node!.toStringInternal();
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

  Extension get asExtension {
    if (node == null) {
      throw '$this is not bound to an AST node. An extension was expected';
    }
    return node as Extension;
  }

  bool get isConsistent {
    NamedNode? node = _node;
    if (node != null) {
      if (node.reference != this &&
          (node is! Field || node.setterReference != this)) {
        // The reference of a [NamedNode] must point to this reference, or
        // if the node is a [Field] the setter reference must point to this
        // reference.
        return false;
      }
    }
    if (canonicalName != null && canonicalName!.reference != this) {
      return false;
    }
    return true;
  }

  String getInconsistency() {
    StringBuffer sb = new StringBuffer();
    sb.write('Reference ${this} (${hashCode}):');
    NamedNode? node = _node;
    if (node != null) {
      if (node is Field) {
        if (node.getterReference != this && node.setterReference != this) {
          sb.write(' _node=${node} (${node.runtimeType}:${node.hashCode})');
          sb.write(' _node.getterReference='
              '${node.getterReference} (${node.getterReference.hashCode})');
          sb.write(' _node.setterReference='
              '${node.setterReference} (${node.setterReference.hashCode})');
        }
      } else {
        if (node.reference != this) {
          sb.write(' _node=${node} (${node.runtimeType}:${node.hashCode})');
          sb.write(' _node.reference='
              '${node.reference} (${node.reference.hashCode})');
        }
      }
    }
    if (canonicalName != null && canonicalName!.reference != this) {
      sb.write(' canonicalName=${canonicalName} (${canonicalName.hashCode})');
      sb.write(' canonicalName.reference='
          '${canonicalName!.reference} (${canonicalName!.reference.hashCode})');
    }
    return sb.toString();
  }
}

// ------------------------------------------------------------------------
//                      LIBRARIES and CLASSES
// ------------------------------------------------------------------------

enum NonNullableByDefaultCompiledMode { Weak, Strong, Agnostic, Invalid }

class Library extends NamedNode
    implements Annotatable, Comparable<Library>, FileUriNode {
  /// An import path to this library.
  ///
  /// The [Uri] should have the `dart`, `package`, `app`, or `file` scheme.
  ///
  /// If the URI has the `app` scheme, it is relative to the application root.
  Uri importUri;

  /// The URI of the source file this library was loaded from.
  @override
  Uri? fileUri;

  Version? _languageVersion;
  Version get languageVersion => _languageVersion ?? defaultLanguageVersion;

  void setLanguageVersion(Version languageVersion) {
    // ignore: unnecessary_null_comparison
    if (languageVersion == null) {
      throw new StateError("Trying to set language version 'null'");
    }
    _languageVersion = languageVersion;
  }

  static const int SyntheticFlag = 1 << 0;
  static const int NonNullableByDefaultFlag = 1 << 1;
  static const int NonNullableByDefaultModeBit1 = 1 << 2;
  static const int NonNullableByDefaultModeBit2 = 1 << 3;

  int flags = 0;

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

  NonNullableByDefaultCompiledMode get nonNullableByDefaultCompiledMode {
    bool bit1 = (flags & NonNullableByDefaultModeBit1) != 0;
    bool bit2 = (flags & NonNullableByDefaultModeBit2) != 0;
    if (!bit1 && !bit2) return NonNullableByDefaultCompiledMode.Weak;
    if (bit1 && !bit2) return NonNullableByDefaultCompiledMode.Strong;
    if (bit1 && bit2) return NonNullableByDefaultCompiledMode.Agnostic;
    if (!bit1 && bit2) return NonNullableByDefaultCompiledMode.Invalid;
    throw new StateError("Unused bit-pattern for compilation mode");
  }

  void set nonNullableByDefaultCompiledMode(
      NonNullableByDefaultCompiledMode mode) {
    switch (mode) {
      case NonNullableByDefaultCompiledMode.Weak:
        flags = (flags & ~NonNullableByDefaultModeBit1) &
            ~NonNullableByDefaultModeBit2;
        break;
      case NonNullableByDefaultCompiledMode.Strong:
        flags = (flags | NonNullableByDefaultModeBit1) &
            ~NonNullableByDefaultModeBit2;
        break;
      case NonNullableByDefaultCompiledMode.Agnostic:
        flags = (flags | NonNullableByDefaultModeBit1) |
            NonNullableByDefaultModeBit2;
        break;
      case NonNullableByDefaultCompiledMode.Invalid:
        flags = (flags & ~NonNullableByDefaultModeBit1) |
            NonNullableByDefaultModeBit2;
        break;
    }
  }

  String? name;

  /// Problems in this [Library] encoded as json objects.
  ///
  /// Note that this field can be null, and by convention should be null if the
  /// list is empty.
  List<String>? problemsAsJson;

  @override
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
      List<Expression>? annotations,
      List<LibraryDependency>? dependencies,
      List<LibraryPart>? parts,
      List<Typedef>? typedefs,
      List<Class>? classes,
      List<Extension>? extensions,
      List<Procedure>? procedures,
      List<Field>? fields,
      this.fileUri,
      Reference? reference})
      : this.annotations = annotations ?? <Expression>[],
        this.dependencies = dependencies ?? <LibraryDependency>[],
        this.parts = parts ?? <LibraryPart>[],
        this.typedefs = typedefs ?? <Typedef>[],
        this.classes = classes ?? <Class>[],
        this.extensions = extensions ?? <Extension>[],
        this.procedures = procedures ?? <Procedure>[],
        this.fields = fields ?? <Field>[],
        super(reference) {
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

  @override
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
    CanonicalName canonicalName = this.canonicalName!;
    for (int i = 0; i < typedefs.length; ++i) {
      Typedef typedef_ = typedefs[i];
      canonicalName.getChildFromTypedef(typedef_).bindTo(typedef_.reference);
    }
    for (int i = 0; i < fields.length; ++i) {
      Field field = fields[i];
      canonicalName.getChildFromField(field).bindTo(field.getterReference);
      if (field.hasSetter) {
        canonicalName
            .getChildFromFieldSetter(field)
            .bindTo(field.setterReference!);
      }
    }
    for (int i = 0; i < procedures.length; ++i) {
      Procedure member = procedures[i];
      canonicalName.getChildFromProcedure(member).bindTo(member.reference);
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

  /// This is an advanced feature. Use of this method should be coordinated
  /// with the kernel team.
  ///
  /// See [Component.relink] for a comprehensive description.
  ///
  /// Makes sure all references in named nodes in this library points to said
  /// named node.
  void relink() {
    _relinkNode();
    for (int i = 0; i < typedefs.length; ++i) {
      Typedef typedef_ = typedefs[i];
      typedef_._relinkNode();
    }
    for (int i = 0; i < fields.length; ++i) {
      Field field = fields[i];
      field._relinkNode();
    }
    for (int i = 0; i < procedures.length; ++i) {
      Procedure member = procedures[i];
      member._relinkNode();
    }
    for (int i = 0; i < classes.length; ++i) {
      Class class_ = classes[i];
      class_.relink();
    }
    for (int i = 0; i < extensions.length; ++i) {
      Extension extension = extensions[i];
      extension._relinkNode();
    }
  }

  void addDependency(LibraryDependency node) {
    dependencies.add(node..parent = this);
  }

  void addPart(LibraryPart node) {
    parts.add(node..parent = this);
  }

  @override
  R accept<R>(TreeVisitor<R> v) => v.visitLibrary(this);

  @override
  R accept1<R, A>(TreeVisitor1<R, A> v, A arg) => v.visitLibrary(this, arg);

  @override
  void visitChildren(Visitor v) {
    visitList(annotations, v);
    visitList(dependencies, v);
    visitList(parts, v);
    visitList(typedefs, v);
    visitList(classes, v);
    visitList(extensions, v);
    visitList(procedures, v);
    visitList(fields, v);
  }

  @override
  void transformChildren(Transformer v) {
    v.transformList(annotations, this);
    v.transformList(dependencies, this);
    v.transformList(parts, this);
    v.transformList(typedefs, this);
    v.transformList(classes, this);
    v.transformList(extensions, this);
    v.transformList(procedures, this);
    v.transformList(fields, this);
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    v.transformExpressionList(annotations, this);
    v.transformLibraryDependencyList(dependencies, this);
    v.transformLibraryPartList(parts, this);
    v.transformTypedefList(typedefs, this);
    v.transformClassList(classes, this);
    v.transformExtensionList(extensions, this);
    v.transformProcedureList(procedures, this);
    v.transformFieldList(fields, this);
  }

  static int _libraryIdCounter = 0;
  int _libraryId = ++_libraryIdCounter;

  @override
  int compareTo(Library other) => _libraryId - other._libraryId;

  /// Returns a possibly synthesized name for this library, consistent with
  /// the names across all [toString] calls.
  @override
  String toString() => libraryNameToString(this);

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write(libraryNameToString(this));
  }

  Location? _getLocationInEnclosingFile(int offset) {
    return _getLocationInComponent(enclosingComponent, fileUri, offset);
  }

  String leakingDebugToString() => astToText.debugLibraryToString(this);
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
  String? name;

  final List<Combinator> combinators;

  LibraryDependency(int flags, List<Expression> annotations,
      Library importedLibrary, String name, List<Combinator> combinators)
      : this.byReference(
            flags, annotations, importedLibrary.reference, name, combinators);

  LibraryDependency.deferredImport(Library importedLibrary, String name,
      {List<Combinator>? combinators, List<Expression>? annotations})
      : this.byReference(DeferredFlag, annotations ?? <Expression>[],
            importedLibrary.reference, name, combinators ?? <Combinator>[]);

  LibraryDependency.import(Library importedLibrary,
      {String? name,
      List<Combinator>? combinators,
      List<Expression>? annotations})
      : this.byReference(0, annotations ?? <Expression>[],
            importedLibrary.reference, name, combinators ?? <Combinator>[]);

  LibraryDependency.export(Library importedLibrary,
      {List<Combinator>? combinators, List<Expression>? annotations})
      : this.byReference(ExportFlag, annotations ?? <Expression>[],
            importedLibrary.reference, null, combinators ?? <Combinator>[]);

  LibraryDependency.byReference(this.flags, this.annotations,
      this.importedLibraryReference, this.name, this.combinators) {
    setParents(annotations, this);
    setParents(combinators, this);
  }

  Library get enclosingLibrary => parent as Library;
  Library get targetLibrary => importedLibraryReference.asLibrary;

  static const int ExportFlag = 1 << 0;
  static const int DeferredFlag = 1 << 1;

  bool get isExport => flags & ExportFlag != 0;
  bool get isImport => !isExport;
  bool get isDeferred => flags & DeferredFlag != 0;

  void addAnnotation(Expression annotation) {
    annotations.add(annotation..parent = this);
  }

  @override
  R accept<R>(TreeVisitor<R> v) => v.visitLibraryDependency(this);

  @override
  R accept1<R, A>(TreeVisitor1<R, A> v, A arg) =>
      v.visitLibraryDependency(this, arg);

  @override
  void visitChildren(Visitor v) {
    visitList(annotations, v);
    visitList(combinators, v);
  }

  @override
  void transformChildren(Transformer v) {
    v.transformList(annotations, this);
    v.transformList(combinators, this);
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    v.transformExpressionList(annotations, this);
    v.transformCombinatorList(combinators, this);
  }

  @override
  String toString() {
    return "LibraryDependency(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    // TODO(johnniwinther): Implement this.
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

  @override
  R accept<R>(TreeVisitor<R> v) => v.visitLibraryPart(this);

  @override
  R accept1<R, A>(TreeVisitor1<R, A> v, A arg) => v.visitLibraryPart(this, arg);

  @override
  void visitChildren(Visitor v) {
    visitList(annotations, v);
  }

  @override
  void transformChildren(Transformer v) {
    v.transformList(annotations, this);
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    v.transformExpressionList(annotations, this);
  }

  @override
  String toString() {
    return "LibraryPart(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    // TODO(johnniwinther): Implement this.
  }
}

/// A `show` or `hide` clause for an import or export.
class Combinator extends TreeNode {
  bool isShow;

  final List<String> names;

  LibraryDependency get dependency => parent as LibraryDependency;

  Combinator(this.isShow, this.names);
  Combinator.show(this.names) : isShow = true;
  Combinator.hide(this.names) : isShow = false;

  bool get isHide => !isShow;

  @override
  R accept<R>(TreeVisitor<R> v) => v.visitCombinator(this);

  @override
  R accept1<R, A>(TreeVisitor1<R, A> v, A arg) => v.visitCombinator(this, arg);

  @override
  void visitChildren(Visitor v) {}

  @override
  void transformChildren(Transformer v) {}

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {}

  @override
  String toString() {
    return "Combinator(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    // TODO(johnniwinther): Implement this.
  }
}

/// Declaration of a type alias.
class Typedef extends NamedNode implements FileUriNode {
  /// The URI of the source file that contains the declaration of this typedef.
  @override
  Uri? fileUri;

  List<Expression> annotations = const <Expression>[];
  String name;
  final List<TypeParameter> typeParameters;
  // TODO(johnniwinther): Make this non-nullable.
  DartType? type;

  // The following two fields describe parameters of the underlying type when
  // that is a function type.  They are needed to keep such attributes as names
  // and annotations. When the underlying type is not a function type, they are
  // empty.
  final List<TypeParameter> typeParametersOfFunctionType;
  final List<VariableDeclaration> positionalParameters;
  final List<VariableDeclaration> namedParameters;

  Typedef(this.name, this.type,
      {Reference? reference,
      this.fileUri,
      List<TypeParameter>? typeParameters,
      List<TypeParameter>? typeParametersOfFunctionType,
      List<VariableDeclaration>? positionalParameters,
      List<VariableDeclaration>? namedParameters})
      : this.typeParameters = typeParameters ?? <TypeParameter>[],
        this.typeParametersOfFunctionType =
            typeParametersOfFunctionType ?? <TypeParameter>[],
        this.positionalParameters =
            positionalParameters ?? <VariableDeclaration>[],
        this.namedParameters = namedParameters ?? <VariableDeclaration>[],
        super(reference) {
    setParents(this.typeParameters, this);
  }

  Library get enclosingLibrary => parent as Library;

  @override
  R accept<R>(TreeVisitor<R> v) => v.visitTypedef(this);

  @override
  R accept1<R, A>(TreeVisitor1<R, A> v, A arg) => v.visitTypedef(this, arg);

  @override
  void visitChildren(Visitor v) {
    visitList(annotations, v);
    visitList(typeParameters, v);
    type?.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    v.transformList(annotations, this);
    v.transformList(typeParameters, this);
    if (type != null) {
      type = v.visitDartType(type!);
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    v.transformExpressionList(annotations, this);
    v.transformTypeParameterList(typeParameters, this);
    if (type != null) {
      DartType newType = v.visitDartType(type!, dummyDartType);
      if (identical(newType, dummyDartType)) {
        type = null;
      } else {
        type = newType;
      }
    }
  }

  void addAnnotation(Expression node) {
    if (annotations.isEmpty) {
      annotations = <Expression>[];
    }
    annotations.add(node);
    node.parent = this;
  }

  @override
  Location? _getLocationInEnclosingFile(int offset) {
    return _getLocationInComponent(enclosingComponent, fileUri!, offset);
  }

  @override
  String toString() {
    return "Typedef(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeTypedefName(reference);
  }
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
  String name;

  // Must match serialized bit positions.
  static const int FlagAbstract = 1 << 0;
  static const int FlagEnum = 1 << 1;
  static const int FlagAnonymousMixin = 1 << 2;
  static const int FlagEliminatedMixin = 1 << 3;
  static const int FlagMixinDeclaration = 1 << 4;
  static const int FlagHasConstConstructor = 1 << 5;

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

  /// True if this class declares one or more constant constructors.
  bool get hasConstConstructor => flags & FlagHasConstConstructor != 0;

  void set hasConstConstructor(bool value) {
    flags = value
        ? (flags | FlagHasConstConstructor)
        : (flags & ~FlagHasConstConstructor);
  }

  List<Supertype> superclassConstraints() {
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
  Uri? fileUri;

  final List<TypeParameter> typeParameters;

  /// The immediate super type, or `null` if this is the root class.
  Supertype? supertype;

  /// The mixed-in type if this is a mixin application, otherwise `null`.
  Supertype? mixedInType;

  /// The types from the `implements` clause.
  final List<Supertype> implementedTypes;

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

  /// Internal. Should *ONLY* be used from within kernel.
  ///
  /// Used for adding fields when reading the dill file.
  final List<Field> fieldsInternal;
  DirtifyingList<Field>? _fieldsView;

  /// Fields declared in the class.
  ///
  /// For mixin applications this should be empty.
  List<Field> get fields {
    ensureLoaded();
    // If already dirty the caller just might as well add stuff directly too.
    if (dirty) return fieldsInternal;
    return _fieldsView ??= new DirtifyingList(this, fieldsInternal);
  }

  /// Internal. Should *ONLY* be used from within kernel.
  ///
  /// Used for adding constructors when reading the dill file.
  final List<Constructor> constructorsInternal;
  DirtifyingList<Constructor>? _constructorsView;

  /// Constructors declared in the class.
  List<Constructor> get constructors {
    ensureLoaded();
    // If already dirty the caller just might as well add stuff directly too.
    if (dirty) return constructorsInternal;
    return _constructorsView ??= new DirtifyingList(this, constructorsInternal);
  }

  /// Internal. Should *ONLY* be used from within kernel.
  ///
  /// Used for adding procedures when reading the dill file.
  final List<Procedure> proceduresInternal;
  DirtifyingList<Procedure>? _proceduresView;

  /// Procedures declared in the class.
  ///
  /// For mixin applications this should only contain forwarding stubs.
  List<Procedure> get procedures {
    ensureLoaded();
    // If already dirty the caller just might as well add stuff directly too.
    if (dirty) return proceduresInternal;
    return _proceduresView ??= new DirtifyingList(this, proceduresInternal);
  }

  /// Internal. Should *ONLY* be used from within kernel.
  ///
  /// Used for adding redirecting factory constructor when reading the dill
  /// file.
  final List<RedirectingFactoryConstructor>
      redirectingFactoryConstructorsInternal;
  DirtifyingList<RedirectingFactoryConstructor>?
      _redirectingFactoryConstructorsView;

  /// Redirecting factory constructors declared in the class.
  ///
  /// For mixin applications this should be empty.
  List<RedirectingFactoryConstructor> get redirectingFactoryConstructors {
    ensureLoaded();
    // If already dirty the caller just might as well add stuff directly too.
    if (dirty) return redirectingFactoryConstructorsInternal;
    return _redirectingFactoryConstructorsView ??=
        new DirtifyingList(this, redirectingFactoryConstructorsInternal);
  }

  Class(
      {required this.name,
      bool isAbstract: false,
      bool isAnonymousMixin: false,
      this.supertype,
      this.mixedInType,
      List<TypeParameter>? typeParameters,
      List<Supertype>? implementedTypes,
      List<Constructor>? constructors,
      List<Procedure>? procedures,
      List<Field>? fields,
      List<RedirectingFactoryConstructor>? redirectingFactoryConstructors,
      this.fileUri,
      Reference? reference})
      // ignore: unnecessary_null_comparison
      : assert(name != null),
        this.typeParameters = typeParameters ?? <TypeParameter>[],
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
    CanonicalName canonicalName = this.canonicalName!;
    if (!dirty) return;
    for (int i = 0; i < fields.length; ++i) {
      Field member = fields[i];
      canonicalName.getChildFromField(member).bindTo(member.getterReference);
      if (member.hasSetter) {
        canonicalName
            .getChildFromFieldSetter(member)
            .bindTo(member.setterReference!);
      }
    }
    for (int i = 0; i < procedures.length; ++i) {
      Procedure member = procedures[i];
      canonicalName.getChildFromProcedure(member).bindTo(member.reference);
    }
    for (int i = 0; i < constructors.length; ++i) {
      Constructor member = constructors[i];
      canonicalName.getChildFromConstructor(member).bindTo(member.reference);
    }
    for (int i = 0; i < redirectingFactoryConstructors.length; ++i) {
      RedirectingFactoryConstructor member = redirectingFactoryConstructors[i];
      canonicalName
          .getChildFromRedirectingFactoryConstructor(member)
          .bindTo(member.reference);
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
    for (int i = 0; i < redirectingFactoryConstructors.length; ++i) {
      RedirectingFactoryConstructor member = redirectingFactoryConstructors[i];
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
        redirectingFactoryConstructors
      ].expand((x) => x);

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
    constructorsInternal.add(constructor);
  }

  /// Adds a procedure to this class.
  void addProcedure(Procedure procedure) {
    dirty = true;
    procedure.parent = this;
    proceduresInternal.add(procedure);
  }

  /// Adds a field to this class.
  void addField(Field field) {
    dirty = true;
    field.parent = this;
    fieldsInternal.add(field);
  }

  /// Adds a field to this class.
  void addRedirectingFactoryConstructor(
      RedirectingFactoryConstructor redirectingFactoryConstructor) {
    dirty = true;
    redirectingFactoryConstructor.parent = this;
    redirectingFactoryConstructorsInternal.add(redirectingFactoryConstructor);
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
    visitList(redirectingFactoryConstructors, v);
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
    v.transformList(redirectingFactoryConstructors, this);
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
    v.transformRedirectingFactoryConstructorList(
        redirectingFactoryConstructors, this);
  }

  @override
  Location? _getLocationInEnclosingFile(int offset) {
    return _getLocationInComponent(enclosingComponent, fileUri!, offset);
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
  Uri? fileUri;

  /// Type parameters declared on the extension.
  final List<TypeParameter> typeParameters;

  /// The type in the 'on clause' of the extension declaration.
  ///
  /// For instance A in:
  ///
  ///   class A {}
  ///   extension B on A {}
  ///
  late DartType onType;

  /// The members declared by the extension.
  ///
  /// The members are converted into top-level members and only accessible
  /// by reference through [ExtensionMemberDescriptor].
  final List<ExtensionMemberDescriptor> members;

  Extension(
      {required this.name,
      List<TypeParameter>? typeParameters,
      DartType? onType,
      List<ExtensionMemberDescriptor>? members,
      this.fileUri,
      Reference? reference})
      // ignore: unnecessary_null_comparison
      : assert(name != null),
        this.typeParameters = typeParameters ?? <TypeParameter>[],
        this.members = members ?? <ExtensionMemberDescriptor>[],
        super(reference) {
    setParents(this.typeParameters, this);
    if (onType != null) {
      this.onType = onType;
    }
  }

  Library get enclosingLibrary => parent as Library;

  @override
  R accept<R>(TreeVisitor<R> v) => v.visitExtension(this);

  @override
  R accept1<R, A>(TreeVisitor1<R, A> v, A arg) => v.visitExtension(this, arg);

  @override
  void visitChildren(Visitor v) {
    visitList(typeParameters, v);
    onType.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    v.transformList(typeParameters, this);
    // ignore: unnecessary_null_comparison
    if (onType != null) {
      onType = v.visitDartType(onType);
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    v.transformTypeParameterList(typeParameters, this);
    // ignore: unnecessary_null_comparison
    if (onType != null) {
      onType = v.visitDartType(onType, cannotRemoveSentinel);
    }
  }

  @override
  Location? _getLocationInEnclosingFile(int offset) {
    return _getLocationInComponent(enclosingComponent, fileUri!, offset);
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
  final Reference member;

  ExtensionMemberDescriptor(
      {required this.name,
      required this.kind,
      bool isStatic: false,
      required this.member}) {
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
        '${member.toStringInternal()},isStatic=${isStatic})';
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
  @override
  List<Expression> annotations = const <Expression>[];

  // TODO(johnniwinther): Make this non-nullable.
  Name? name;

  /// The URI of the source file this member was loaded from.
  @override
  Uri? fileUri;

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

  Class? get enclosingClass => parent is Class ? parent as Class : null;
  Library get enclosingLibrary =>
      (parent is Class ? parent!.parent : parent) as Library;

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

  /// If `true` this member is defined in a library for which non-nullable by
  /// default is enabled.
  bool get isNonNullableByDefault;
  void set isNonNullableByDefault(bool value);

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

  DartType get getterType;
  DartType get setterType;

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
  final Reference? setterReference;

  @override
  @Deprecated("Use the specific getterReference/setterReference instead")
  Reference get reference => super.reference;

  Reference get getterReference => super.reference;

  @override
  @Deprecated(
      "Use the specific getterCanonicalName/setterCanonicalName instead")
  CanonicalName? get canonicalName => reference.canonicalName;

  CanonicalName? get getterCanonicalName => getterReference.canonicalName;
  CanonicalName? get setterCanonicalName => setterReference?.canonicalName;

  Field.mutable(Name? name,
      {this.type: const DynamicType(),
      this.initializer,
      bool isCovariant: false,
      bool isFinal: false,
      bool isStatic: false,
      bool isLate: false,
      int transformerFlags: 0,
      Uri? fileUri,
      Reference? getterReference,
      Reference? setterReference})
      : this.setterReference = setterReference ?? new Reference(),
        super(name, fileUri, getterReference) {
    this.setterReference!.node = this;
    // ignore: unnecessary_null_comparison
    assert(type != null);
    initializer?.parent = this;
    this.isCovariant = isCovariant;
    this.isFinal = isFinal;
    this.isStatic = isStatic;
    this.isLate = isLate;
    this.transformerFlags = transformerFlags;
  }

  Field.immutable(Name? name,
      {this.type: const DynamicType(),
      this.initializer,
      bool isCovariant: false,
      bool isFinal: false,
      bool isConst: false,
      bool isStatic: false,
      bool isLate: false,
      int transformerFlags: 0,
      Uri? fileUri,
      Reference? getterReference})
      : this.setterReference = null,
        super(name, fileUri, getterReference) {
    // ignore: unnecessary_null_comparison
    assert(type != null);
    initializer?.parent = this;
    this.isCovariant = isCovariant;
    this.isFinal = isFinal;
    this.isConst = isConst;
    this.isStatic = isStatic;
    this.isLate = isLate;
    this.transformerFlags = transformerFlags;
  }

  @override
  void _relinkNode() {
    super._relinkNode();
    if (hasSetter) {
      this.setterReference!.node = this;
    }
  }

  static const int FlagFinal = 1 << 0; // Must match serialized bit positions.
  static const int FlagConst = 1 << 1;
  static const int FlagStatic = 1 << 2;
  static const int FlagCovariant = 1 << 3;
  static const int FlagGenericCovariantImpl = 1 << 4;
  static const int FlagLate = 1 << 5;
  static const int FlagExtensionMember = 1 << 6;
  static const int FlagNonNullableByDefault = 1 << 7;
  static const int FlagInternalImplementation = 1 << 8;

  /// Whether the field is declared with the `covariant` keyword.
  bool get isCovariant => flags & FlagCovariant != 0;

  bool get isFinal => flags & FlagFinal != 0;

  @override
  bool get isConst => flags & FlagConst != 0;

  bool get isStatic => flags & FlagStatic != 0;

  @override
  bool get isExtensionMember => flags & FlagExtensionMember != 0;

  /// Indicates whether the implicit setter associated with this field needs to
  /// contain a runtime type check to deal with generic covariance.
  ///
  /// When `true`, runtime checks may need to be performed; see
  /// [DispatchCategory] for details.
  bool get isGenericCovariantImpl => flags & FlagGenericCovariantImpl != 0;

  /// Whether the field is declared with the `late` keyword.
  bool get isLate => flags & FlagLate != 0;

  // If `true` this field is not part of the interface but only part of the
  // class members.
  //
  // This is `true` for instance for synthesized fields added for the late
  // lowering.
  bool get isInternalImplementation => flags & FlagInternalImplementation != 0;

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

  void set isGenericCovariantImpl(bool value) {
    flags = value
        ? (flags | FlagGenericCovariantImpl)
        : (flags & ~FlagGenericCovariantImpl);
  }

  void set isLate(bool value) {
    flags = value ? (flags | FlagLate) : (flags & ~FlagLate);
  }

  void set isInternalImplementation(bool value) {
    flags = value
        ? (flags | FlagInternalImplementation)
        : (flags & ~FlagInternalImplementation);
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
  void set isExternal(bool value) {
    if (value) throw 'Fields cannot be external';
  }

  @override
  bool get isNonNullableByDefault => flags & FlagNonNullableByDefault != 0;

  @override
  void set isNonNullableByDefault(bool value) {
    flags = value
        ? (flags | FlagNonNullableByDefault)
        : (flags & ~FlagNonNullableByDefault);
  }

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
    name?.accept(v);
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
    return _getLocationInComponent(enclosingComponent, fileUri!, offset);
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeMemberName(getterReference);
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

  // TODO(johnniwinther): Make this non-nullable.
  @override
  FunctionNode? function;

  List<Initializer> initializers;

  Constructor(this.function,
      {Name? name,
      bool isConst: false,
      bool isExternal: false,
      bool isSynthetic: false,
      List<Initializer>? initializers,
      int transformerFlags: 0,
      Uri? fileUri,
      Reference? reference})
      : this.initializers = initializers ?? <Initializer>[],
        super(name, fileUri, reference) {
    function?.parent = this;
    setParents(this.initializers, this);
    this.isConst = isConst;
    this.isExternal = isExternal;
    this.isSynthetic = isSynthetic;
    this.transformerFlags = transformerFlags;
  }

  @override
  Class get enclosingClass => parent as Class;

  static const int FlagConst = 1 << 0; // Must match serialized bit positions.
  static const int FlagExternal = 1 << 1;
  static const int FlagSynthetic = 1 << 2;
  static const int FlagNonNullableByDefault = 1 << 3;

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

  @override
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
  bool get isNonNullableByDefault => flags & FlagNonNullableByDefault != 0;

  @override
  void set isNonNullableByDefault(bool value) {
    flags = value
        ? (flags | FlagNonNullableByDefault)
        : (flags & ~FlagNonNullableByDefault);
  }

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
    name?.accept(v);
    visitList(initializers, v);
    function?.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    v.transformList(annotations, this);
    v.transformList(initializers, this);
    if (function != null) {
      function = v.transform(function!);
      function?.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    v.transformExpressionList(annotations, this);
    v.transformInitializerList(initializers, this);
    if (function != null) {
      function = v.transformOrRemove(function!, dummyFunctionNode);
      function?.parent = this;
    }
  }

  @override
  DartType get getterType => const NeverType.nonNullable();

  @override
  DartType get setterType => const NeverType.nonNullable();

  @override
  Location? _getLocationInEnclosingFile(int offset) {
    return _getLocationInComponent(enclosingComponent, fileUri!, offset);
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
  // TODO(johnniwinther): Make this non-nullable.
  Reference? targetReference;

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
      {Name? name,
      bool isConst: false,
      bool isExternal: false,
      int transformerFlags: 0,
      List<DartType>? typeArguments,
      List<TypeParameter>? typeParameters,
      List<VariableDeclaration>? positionalParameters,
      List<VariableDeclaration>? namedParameters,
      int? requiredParameterCount,
      Uri? fileUri,
      Reference? reference})
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

  @override
  Class get enclosingClass => parent as Class;

  static const int FlagConst = 1 << 0; // Must match serialized bit positions.
  static const int FlagExternal = 1 << 1;
  static const int FlagNonNullableByDefault = 1 << 2;

  @override
  bool get isConst => flags & FlagConst != 0;

  @override
  bool get isExternal => flags & FlagExternal != 0;

  void set isConst(bool value) {
    flags = value ? (flags | FlagConst) : (flags & ~FlagConst);
  }

  @override
  void set isExternal(bool value) {
    flags = value ? (flags | FlagExternal) : (flags & ~FlagExternal);
  }

  @override
  bool get isInstanceMember => false;

  @override
  bool get hasGetter => false;

  @override
  bool get hasSetter => false;

  @override
  bool get isExtensionMember => false;

  bool get isUnresolved => targetReference == null;

  @override
  bool get isNonNullableByDefault => flags & FlagNonNullableByDefault != 0;

  @override
  void set isNonNullableByDefault(bool value) {
    flags = value
        ? (flags | FlagNonNullableByDefault)
        : (flags & ~FlagNonNullableByDefault);
  }

  Member? get target => targetReference?.asMember;

  void set target(Member? member) {
    assert(member is Constructor ||
        (member is Procedure && member.kind == ProcedureKind.Factory));
    targetReference = getMemberReferenceGetter(member);
  }

  @override
  R accept<R>(MemberVisitor<R> v) => v.visitRedirectingFactoryConstructor(this);

  @override
  R accept1<R, A>(MemberVisitor1<R, A> v, A arg) =>
      v.visitRedirectingFactoryConstructor(this, arg);

  @override
  R acceptReference<R>(MemberReferenceVisitor<R> v) =>
      v.visitRedirectingFactoryConstructorReference(this);

  @override
  void visitChildren(Visitor v) {
    visitList(annotations, v);
    target?.acceptReference(v);
    visitList(typeArguments, v);
    name?.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    v.transformList(annotations, this);
    v.transformDartTypeList(typeArguments);
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    v.transformExpressionList(annotations, this);
    v.transformDartTypeList(typeArguments);
  }

  @override
  DartType get getterType => const NeverType.nonNullable();

  @override
  DartType get setterType => const NeverType.nonNullable();

  @override
  Location? _getLocationInEnclosingFile(int offset) {
    return _getLocationInComponent(enclosingComponent, fileUri!, offset);
  }
}

/// Enum for the semantics of the `Procedure.stubTarget` property.
enum ProcedureStubKind {
  /// A regular procedure declared in source code.
  ///
  /// The stub target is `null`.
  Regular,

  /// An abstract procedure inserted to add `isCovariant` and
  /// `isGenericCovariantImpl` to parameters for a set of overridden members.
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

  /// A concrete procedure inserted to add `isCovariant` and
  /// `isGenericCovariantImpl` checks to parameters before calling the
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

  final ProcedureKind kind;
  int flags = 0;

  // TODO(johnniwinther): Make this non-nullable.
  @override
  FunctionNode? function;

  // The function node's body might be lazily loaded, meaning that this value
  // might not be set correctly yet. Make sure the body is loaded before
  // returning anything.
  @override
  int get transformerFlags {
    function?.body;
    return super.transformerFlags;
  }

  // The function node's body might be lazily loaded, meaning that this value
  // might get overwritten later (when the body is read). To avoid that read the
  // body now and only set the value afterwards.
  @override
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

  ProcedureStubKind stubKind;
  Reference? stubTargetReference;

  Procedure(Name? name, ProcedureKind kind, FunctionNode? function,
      {bool isAbstract: false,
      bool isStatic: false,
      bool isExternal: false,
      bool isConst: false,
      bool isExtensionMember: false,
      bool isSynthetic: false,
      int transformerFlags: 0,
      Uri? fileUri,
      Reference? reference,
      ProcedureStubKind stubKind: ProcedureStubKind.Regular,
      Member? stubTarget})
      : this._byReferenceRenamed(name, kind, function,
            isAbstract: isAbstract,
            isStatic: isStatic,
            isExternal: isExternal,
            isConst: isConst,
            isExtensionMember: isExtensionMember,
            isSynthetic: isSynthetic,
            transformerFlags: transformerFlags,
            fileUri: fileUri,
            reference: reference,
            stubKind: stubKind,
            stubTargetReference:
                getMemberReferenceBasedOnProcedureKind(stubTarget, kind));

  Procedure._byReferenceRenamed(Name? name, this.kind, this.function,
      {bool isAbstract: false,
      bool isStatic: false,
      bool isExternal: false,
      bool isConst: false,
      bool isExtensionMember: false,
      bool isSynthetic: false,
      int transformerFlags: 0,
      Uri? fileUri,
      Reference? reference,
      this.stubKind: ProcedureStubKind.Regular,
      this.stubTargetReference})
      // ignore: unnecessary_null_comparison
      : assert(kind != null),
        super(name, fileUri, reference) {
    function?.parent = this;
    this.isAbstract = isAbstract;
    this.isStatic = isStatic;
    this.isExternal = isExternal;
    this.isConst = isConst;
    this.isExtensionMember = isExtensionMember;
    this.isSynthetic = isSynthetic;
    this.transformerFlags = transformerFlags;
    assert(!(isMemberSignature && stubTargetReference == null),
        "No member signature origin for member signature $this.");
    assert(
        !(memberSignatureOrigin is Procedure &&
            (memberSignatureOrigin as Procedure).isMemberSignature),
        "Member signature origin cannot be a member signature "
        "$memberSignatureOrigin for $this.");
  }

  static const int FlagStatic = 1 << 0; // Must match serialized bit positions.
  static const int FlagAbstract = 1 << 1;
  static const int FlagExternal = 1 << 2;
  static const int FlagConst = 1 << 3; // Only for external const factories.
  // TODO(29841): Remove this flag after the issue is resolved.
  static const int FlagRedirectingFactoryConstructor = 1 << 4;
  static const int FlagExtensionMember = 1 << 5;
  static const int FlagNonNullableByDefault = 1 << 6;
  static const int FlagSynthetic = 1 << 7;

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
  bool get isRedirectingFactoryConstructor {
    return flags & FlagRedirectingFactoryConstructor != 0;
  }

  /// If set, this flag indicates that this function was not present in the
  /// source, and it exists solely for the purpose of type checking arguments
  /// and forwarding to [concreteForwardingStubTarget].
  bool get isSyntheticForwarder => isForwardingStub && !isForwardingSemiStub;
  bool get isSynthetic => flags & FlagSynthetic != 0;

  bool get isNoSuchMethodForwarder =>
      stubKind == ProcedureStubKind.NoSuchMethodForwarder;

  @override
  bool get isExtensionMember => flags & FlagExtensionMember != 0;

  void set isStatic(bool value) {
    flags = value ? (flags | FlagStatic) : (flags & ~FlagStatic);
  }

  void set isAbstract(bool value) {
    flags = value ? (flags | FlagAbstract) : (flags & ~FlagAbstract);
  }

  @override
  void set isExternal(bool value) {
    flags = value ? (flags | FlagExternal) : (flags & ~FlagExternal);
  }

  void set isConst(bool value) {
    flags = value ? (flags | FlagConst) : (flags & ~FlagConst);
  }

  void set isRedirectingFactoryConstructor(bool value) {
    flags = value
        ? (flags | FlagRedirectingFactoryConstructor)
        : (flags & ~FlagRedirectingFactoryConstructor);
  }

  void set isExtensionMember(bool value) {
    flags =
        value ? (flags | FlagExtensionMember) : (flags & ~FlagExtensionMember);
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

  @override
  bool get isNonNullableByDefault => flags & FlagNonNullableByDefault != 0;

  @override
  void set isNonNullableByDefault(bool value) {
    flags = value
        ? (flags | FlagNonNullableByDefault)
        : (flags & ~FlagNonNullableByDefault);
  }

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
    name?.accept(v);
    function?.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    v.transformList(annotations, this);
    if (function != null) {
      function = v.transform(function!);
      function?.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    v.transformExpressionList(annotations, this);
    if (function != null) {
      function = v.transformOrRemove(function!, dummyFunctionNode);
      function?.parent = this;
    }
  }

  @override
  DartType get getterType {
    return isGetter
        ? function!.returnType
        : function!.computeFunctionType(enclosingLibrary.nonNullable);
  }

  @override
  DartType get setterType {
    return isSetter
        ? function!.positionalParameters[0].type
        : const NeverType.nonNullable();
  }

  @override
  Location? _getLocationInEnclosingFile(int offset) {
    return _getLocationInComponent(enclosingComponent, fileUri!, offset);
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

  @override
  R accept<R>(InitializerVisitor<R> v);

  @override
  R accept1<R, A>(InitializerVisitor1<R, A> v, A arg);
}

/// An initializer with a compile-time error.
///
/// Should throw an exception at runtime.
//
// DESIGN TODO: The frontend should use this in a lot more cases to catch
// invalid cases.
class InvalidInitializer extends Initializer {
  @override
  R accept<R>(InitializerVisitor<R> v) => v.visitInvalidInitializer(this);

  @override
  R accept1<R, A>(InitializerVisitor1<R, A> v, A arg) =>
      v.visitInvalidInitializer(this, arg);

  @override
  void visitChildren(Visitor v) {}

  @override
  void transformChildren(Transformer v) {}

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {}

  @override
  String toString() {
    return "InvalidInitializer(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    // TODO(johnniwinther): Implement this.
  }
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
      : this.byReference(
            // getterReference is used since this refers to the field itself
            field.getterReference,
            value);

  FieldInitializer.byReference(this.fieldReference, this.value) {
    value.parent = this;
  }

  Field get field => fieldReference.asField;

  void set field(Field field) {
    fieldReference = field.getterReference;
  }

  @override
  R accept<R>(InitializerVisitor<R> v) => v.visitFieldInitializer(this);

  @override
  R accept1<R, A>(InitializerVisitor1<R, A> v, A arg) =>
      v.visitFieldInitializer(this, arg);

  @override
  void visitChildren(Visitor v) {
    field.acceptReference(v);
    value.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    // ignore: unnecessary_null_comparison
    if (value != null) {
      value = v.transform(value);
      value.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    // ignore: unnecessary_null_comparison
    if (value != null) {
      value = v.transform(value);
      value.parent = this;
    }
  }

  @override
  String toString() {
    return "FieldInitializer(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    // TODO(johnniwinther): Implement this.
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
      : this.byReference(
            // Getter vs setter doesn't matter for constructors.
            getNonNullableMemberReferenceGetter(target),
            arguments);

  SuperInitializer.byReference(this.targetReference, this.arguments) {
    arguments.parent = this;
  }

  Constructor get target => targetReference.asConstructor;

  void set target(Constructor target) {
    // Getter vs setter doesn't matter for constructors.
    targetReference = getNonNullableMemberReferenceGetter(target);
  }

  @override
  R accept<R>(InitializerVisitor<R> v) => v.visitSuperInitializer(this);

  @override
  R accept1<R, A>(InitializerVisitor1<R, A> v, A arg) =>
      v.visitSuperInitializer(this, arg);

  @override
  void visitChildren(Visitor v) {
    target.acceptReference(v);
    arguments.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    // ignore: unnecessary_null_comparison
    if (arguments != null) {
      arguments = v.transform(arguments);
      arguments.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    // ignore: unnecessary_null_comparison
    if (arguments != null) {
      arguments = v.transform(arguments);
      arguments.parent = this;
    }
  }

  @override
  String toString() {
    return "SuperInitializer(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    // TODO(johnniwinther): Implement this.
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
      : this.byReference(
            // Getter vs setter doesn't matter for constructors.
            getNonNullableMemberReferenceGetter(target),
            arguments);

  RedirectingInitializer.byReference(this.targetReference, this.arguments) {
    arguments.parent = this;
  }

  Constructor get target => targetReference.asConstructor;

  void set target(Constructor target) {
    // Getter vs setter doesn't matter for constructors.
    targetReference = getNonNullableMemberReferenceGetter(target);
  }

  @override
  R accept<R>(InitializerVisitor<R> v) => v.visitRedirectingInitializer(this);

  @override
  R accept1<R, A>(InitializerVisitor1<R, A> v, A arg) =>
      v.visitRedirectingInitializer(this, arg);

  @override
  void visitChildren(Visitor v) {
    target.acceptReference(v);
    arguments.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    // ignore: unnecessary_null_comparison
    if (arguments != null) {
      arguments = v.transform(arguments);
      arguments.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    // ignore: unnecessary_null_comparison
    if (arguments != null) {
      arguments = v.transform(arguments);
      arguments.parent = this;
    }
  }

  @override
  String toString() {
    return "RedirectingInitializer(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    // TODO(johnniwinther): Implement this.
  }
}

/// Binding of a temporary variable in the initializer list of a constructor.
///
/// The variable is in scope for the remainder of the initializer list, but is
/// not in scope in the constructor body.
class LocalInitializer extends Initializer {
  VariableDeclaration variable;

  LocalInitializer(this.variable) {
    variable.parent = this;
  }

  @override
  R accept<R>(InitializerVisitor<R> v) => v.visitLocalInitializer(this);

  @override
  R accept1<R, A>(InitializerVisitor1<R, A> v, A arg) =>
      v.visitLocalInitializer(this, arg);

  @override
  void visitChildren(Visitor v) {
    variable.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    // ignore: unnecessary_null_comparison
    if (variable != null) {
      variable = v.transform(variable);
      variable.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    // ignore: unnecessary_null_comparison
    if (variable != null) {
      variable = v.transform(variable);
      variable.parent = this;
    }
  }

  @override
  String toString() {
    return "LocalInitializer(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    // TODO(johnniwinther): Implement this.
  }
}

class AssertInitializer extends Initializer {
  AssertStatement statement;

  AssertInitializer(this.statement) {
    statement.parent = this;
  }

  @override
  R accept<R>(InitializerVisitor<R> v) => v.visitAssertInitializer(this);

  @override
  R accept1<R, A>(InitializerVisitor1<R, A> v, A arg) =>
      v.visitAssertInitializer(this, arg);

  @override
  void visitChildren(Visitor v) {
    statement.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    statement = v.transform(statement);
    statement.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    statement = v.transform(statement);
    statement.parent = this;
  }

  @override
  String toString() {
    return "AssertInitializer(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    // TODO(johnniwinther): Implement this.
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
  Statement? _body;

  /// The future value type of this is an async function, otherwise `null`.
  ///
  /// The future value type is the element type returned by an async function.
  /// For instance
  ///
  ///     Future<Foo> method1() async => new Foo();
  ///     FutureOr<Foo> method2() async => new Foo();
  ///
  /// here the return types are `Future<Foo>` and `FutureOr<Foo>` for `method1`
  /// and `method2`, respectively, but the future value type is in both cases
  /// `Foo`.
  DartType? futureValueType;

  void Function()? lazyBuilder;

  void _buildLazy() {
    void Function()? lazyBuilderLocal = lazyBuilder;
    if (lazyBuilderLocal != null) {
      lazyBuilder = null;
      lazyBuilderLocal();
    }
  }

  Statement? get body {
    _buildLazy();
    return _body;
  }

  void set body(Statement? body) {
    _buildLazy();
    _body = body;
  }

  FunctionNode(this._body,
      {List<TypeParameter>? typeParameters,
      List<VariableDeclaration>? positionalParameters,
      List<VariableDeclaration>? namedParameters,
      int? requiredParameterCount,
      this.returnType: const DynamicType(),
      this.asyncMarker: AsyncMarker.Sync,
      AsyncMarker? dartAsyncMarker,
      this.futureValueType})
      : this.positionalParameters =
            positionalParameters ?? <VariableDeclaration>[],
        this.requiredParameterCount =
            requiredParameterCount ?? positionalParameters?.length ?? 0,
        this.namedParameters = namedParameters ?? <VariableDeclaration>[],
        this.typeParameters = typeParameters ?? <TypeParameter>[],
        this.dartAsyncMarker = dartAsyncMarker ?? asyncMarker {
    // ignore: unnecessary_null_comparison
    assert(returnType != null);
    setParents(this.typeParameters, this);
    setParents(this.positionalParameters, this);
    setParents(this.namedParameters, this);
    _body?.parent = this;
  }

  static DartType _getTypeOfVariable(VariableDeclaration node) => node.type;

  static NamedType _getNamedTypeOfVariable(VariableDeclaration node) {
    return new NamedType(node.name!, node.type, isRequired: node.isRequired);
  }

  /// Returns the function type of the node reusing its type parameters.
  ///
  /// This getter works similarly to [functionType], but reuses type parameters
  /// of the function node (or the class enclosing it -- see the comment on
  /// [functionType] about constructors of generic classes) in the result.  It
  /// is useful in some contexts, especially when reasoning about the function
  /// type of the enclosing generic function and in combination with
  /// [FunctionType.withoutTypeParameters].
  FunctionType computeThisFunctionType(Nullability nullability) {
    TreeNode? parent = this.parent;
    List<NamedType> named =
        namedParameters.map(_getNamedTypeOfVariable).toList(growable: false);
    named.sort();
    // We need create a copy of the list of type parameters, otherwise
    // transformations like erasure don't work.
    List<TypeParameter> typeParametersCopy = new List<TypeParameter>.from(
        parent is Constructor
            ? parent.enclosingClass.typeParameters
            : typeParameters);
    return new FunctionType(
        positionalParameters.map(_getTypeOfVariable).toList(growable: false),
        returnType,
        nullability,
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
  FunctionType computeFunctionType(Nullability nullability) {
    return typeParameters.isEmpty
        ? computeThisFunctionType(nullability)
        : getFreshTypeParameters(typeParameters)
            .applyToFunctionType(computeThisFunctionType(nullability));
  }

  /// Return function type of node returning [typedefType] reuse type parameters
  ///
  /// When this getter is invoked, the parent must be a [Constructor].
  /// This getter works similarly to [computeThisFunctionType], but uses
  /// [typedef] to compute the return type of the returned function type. It
  /// is useful in some contexts, especially during inference of aliased
  /// constructor invocations.
  FunctionType computeAliasedConstructorFunctionType(
      Typedef typedef, Library library) {
    assert(parent is Constructor, "Only run this method on constructors");
    Constructor parentConstructor = parent as Constructor;
    // We need create a copy of the list of type parameters, otherwise
    // transformations like erasure don't work.
    List<TypeParameter> classTypeParametersCopy =
        List.from(parentConstructor.enclosingClass.typeParameters);
    List<TypeParameter> typedefTypeParametersCopy =
        List.from(typedef.typeParameters);
    List<DartType> asTypeArguments =
        getAsTypeArguments(typedefTypeParametersCopy, library);
    TypedefType typedefType =
        TypedefType(typedef, library.nonNullable, asTypeArguments);
    DartType unaliasedTypedef = typedefType.unalias;
    assert(unaliasedTypedef is InterfaceType,
        "[typedef] is assumed to resolve to an interface type");
    InterfaceType targetType = unaliasedTypedef as InterfaceType;
    Substitution substitution = Substitution.fromPairs(
        classTypeParametersCopy, targetType.typeArguments);
    List<DartType> positional = positionalParameters
        .map((VariableDeclaration decl) =>
            substitution.substituteType(decl.type))
        .toList(growable: false);
    List<NamedType> named = namedParameters
        .map((VariableDeclaration decl) => NamedType(
            decl.name!, substitution.substituteType(decl.type),
            isRequired: decl.isRequired))
        .toList(growable: false);
    named.sort();
    return FunctionType(positional, typedefType.unalias, library.nonNullable,
        namedParameters: named,
        typeParameters: typedefTypeParametersCopy,
        requiredParameterCount: requiredParameterCount);
  }

  /// Return function type of node returning [typedefType] reuse type parameters
  ///
  /// When this getter is invoked, the parent must be a [Procedure] which is a
  /// redirecting factory constructor. This getter works similarly to
  /// [computeThisFunctionType], but uses [typedef] to compute the return type
  /// of the returned function type. It is useful in some contexts, especially
  /// during inference of aliased factory invocations.
  FunctionType computeAliasedFactoryFunctionType(
      Typedef typedef, Library library) {
    assert(
        parent is Procedure &&
            (parent as Procedure).kind == ProcedureKind.Factory,
        "Only run this method on a factory");
    // We need create a copy of the list of type parameters, otherwise
    // transformations like erasure don't work.
    List<TypeParameter> classTypeParametersCopy = List.from(typeParameters);
    List<TypeParameter> typedefTypeParametersCopy =
        List.from(typedef.typeParameters);
    List<DartType> asTypeArguments =
        getAsTypeArguments(typedefTypeParametersCopy, library);
    TypedefType typedefType =
        TypedefType(typedef, library.nonNullable, asTypeArguments);
    DartType unaliasedTypedef = typedefType.unalias;
    assert(unaliasedTypedef is InterfaceType,
        "[typedef] is assumed to resolve to an interface type");
    InterfaceType targetType = unaliasedTypedef as InterfaceType;
    Substitution substitution = Substitution.fromPairs(
        classTypeParametersCopy, targetType.typeArguments);
    List<DartType> positional = positionalParameters
        .map((VariableDeclaration decl) =>
            substitution.substituteType(decl.type))
        .toList(growable: false);
    List<NamedType> named = namedParameters
        .map((VariableDeclaration decl) => NamedType(
            decl.name!, substitution.substituteType(decl.type),
            isRequired: decl.isRequired))
        .toList(growable: false);
    named.sort();
    return FunctionType(positional, typedefType.unalias, library.nonNullable,
        namedParameters: named,
        typeParameters: typedefTypeParametersCopy,
        requiredParameterCount: requiredParameterCount);
  }

  @override
  R accept<R>(TreeVisitor<R> v) => v.visitFunctionNode(this);

  @override
  R accept1<R, A>(TreeVisitor1<R, A> v, A arg) =>
      v.visitFunctionNode(this, arg);

  @override
  void visitChildren(Visitor v) {
    visitList(typeParameters, v);
    visitList(positionalParameters, v);
    visitList(namedParameters, v);
    returnType.accept(v);
    body?.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    v.transformList(typeParameters, this);
    v.transformList(positionalParameters, this);
    v.transformList(namedParameters, this);
    returnType = v.visitDartType(returnType);
    if (body != null) {
      body = v.transform(body!);
      body?.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    v.transformTypeParameterList(typeParameters, this);
    v.transformVariableDeclarationList(positionalParameters, this);
    v.transformVariableDeclarationList(namedParameters, this);
    returnType = v.visitDartType(returnType, cannotRemoveSentinel);
    if (body != null) {
      body = v.transformOrRemoveStatement(body!);
      body?.parent = this;
    }
  }

  @override
  String toString() {
    return "FunctionNode(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    // TODO(johnniwinther): Implement this.
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
  /// This calls `StaticTypeContext.getExpressionType` which calls
  /// [getStaticTypeInternal] to compute the type of not already cached in
  /// [context].
  DartType getStaticType(StaticTypeContext context) {
    return context.getExpressionType(this);
  }

  /// Computes the static type of this expression.
  ///
  /// This is called by `StaticTypeContext.getExpressionType` if the static
  /// type of this expression is not already cached in [context].
  DartType getStaticTypeInternal(StaticTypeContext context);

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
      Class superclass, StaticTypeContext context) {
    // This method assumes the program is correctly typed, so if the superclass
    // is not generic, we can just return its raw type without computing the
    // type of this expression.  It also ensures that all types are considered
    // subtypes of Object (not just interface types), and function types are
    // considered subtypes of Function.
    if (superclass.typeParameters.isEmpty) {
      return context.typeEnvironment.coreTypes
          .rawType(superclass, context.nonNullable);
    }
    DartType type = getStaticType(context);
    while (type is TypeParameterType) {
      TypeParameterType typeParameterType = type;
      type = typeParameterType.bound;
    }
    if (type is NullType) {
      return context.typeEnvironment.coreTypes
          .bottomInterfaceType(superclass, context.nullable);
    } else if (type is NeverType) {
      return context.typeEnvironment.coreTypes
          .bottomInterfaceType(superclass, type.nullability);
    }
    if (type is InterfaceType) {
      List<DartType>? upcastTypeArguments = context.typeEnvironment
          .getTypeArgumentsAsInstanceOf(type, superclass);
      if (upcastTypeArguments != null) {
        return new InterfaceType(
            superclass, type.nullability, upcastTypeArguments);
      }
    }

    // The static type of this expression is not a subtype of [superclass]. The
    // means that the static type of this expression is not the same as when
    // the parent [PropertyGet] or [MethodInvocation] was created.
    //
    // For instance when cloning generic mixin methods, the substitution can
    // render some of the code paths as dead code:
    //
    //     mixin M<T> {
    //       int method(T t) => t is String ? t.length : 0;
    //     }
    //     class C with M<int> {}
    //
    // The mixin transformation will clone the `M.method` method into the
    // unnamed mixin application for `Object&M<int>` as this:
    //
    //     int method(int t) => t is String ? t.length : 0;
    //
    // Now `t.length`, which was originally an access to `String.length` on a
    // receiver of type `T & String`, is an access to `String.length` on `int`.
    // When computing the static type of `t.length` we will try to compute the
    // type of `int` as an instance of `String`, and we do not find it to be
    // an instance of `String`.
    //
    // To resolve this case we compute the type of `t.length` to be the type
    // as if accessed on an unknown subtype `String`.
    return context.typeEnvironment.coreTypes
        .rawType(superclass, context.nonNullable);
  }

  @override
  R accept<R>(ExpressionVisitor<R> v);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg);

  int get precedence => astToText.Precedence.of(this);

  @override
  String toText(AstTextStrategy strategy) {
    AstPrinter printer = new AstPrinter(strategy);
    printer.writeExpression(this);
    return printer.getText();
  }
}

/// An expression containing compile-time errors.
///
/// Should throw a runtime error when evaluated.
///
/// The [fileOffset] of an [InvalidExpression] indicates the location in the
/// tree where the expression occurs, rather than the location of the error.
class InvalidExpression extends Expression {
  // TODO(johnniwinther): Avoid using `null` as the empty string.
  String? message;

  InvalidExpression(this.message);

  @override
  DartType getStaticType(StaticTypeContext context) =>
      getStaticTypeInternal(context);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) =>
      const NeverType.nonNullable();

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitInvalidExpression(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitInvalidExpression(this, arg);

  @override
  void visitChildren(Visitor v) {}

  @override
  void transformChildren(Transformer v) {}

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {}

  @override
  String toString() {
    return "InvalidExpression(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('<invalid:');
    printer.write(message ?? '');
    printer.write('>');
  }
}

/// Read a local variable, a local function, or a function parameter.
class VariableGet extends Expression {
  VariableDeclaration variable;
  DartType? promotedType; // Null if not promoted.

  VariableGet(this.variable, [this.promotedType])
      // ignore: unnecessary_null_comparison
      : assert(variable != null);

  @override
  DartType getStaticType(StaticTypeContext context) =>
      getStaticTypeInternal(context);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) {
    return promotedType ?? variable.type;
  }

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitVariableGet(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitVariableGet(this, arg);

  @override
  void visitChildren(Visitor v) {
    promotedType?.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    if (promotedType != null) {
      promotedType = v.visitDartType(promotedType!);
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    if (promotedType != null) {
      DartType newPromotedType = v.visitDartType(promotedType!, dummyDartType);
      if (identical(newPromotedType, dummyDartType)) {
        promotedType = null;
      } else {
        promotedType = newPromotedType;
      }
    }
  }

  @override
  String toString() {
    return "VariableGet(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write(printer.getVariableName(variable));
    if (promotedType != null) {
      printer.write('{');
      printer.writeType(promotedType!);
      printer.write('}');
    }
  }
}

/// Assign a local variable or function parameter.
///
/// Evaluates to the value of [value].
class VariableSet extends Expression {
  VariableDeclaration variable;
  Expression value;

  VariableSet(this.variable, this.value)
      // ignore: unnecessary_null_comparison
      : assert(variable != null) {
    value.parent = this;
  }

  @override
  DartType getStaticType(StaticTypeContext context) =>
      getStaticTypeInternal(context);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) =>
      value.getStaticType(context);

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitVariableSet(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitVariableSet(this, arg);

  @override
  void visitChildren(Visitor v) {
    value.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    // ignore: unnecessary_null_comparison
    if (value != null) {
      value = v.transform(value);
      value.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    // ignore: unnecessary_null_comparison
    if (value != null) {
      value = v.transform(value);
      value.parent = this;
    }
  }

  @override
  String toString() {
    return "VariableSet(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write(printer.getVariableName(variable));
    printer.write(' = ');
    printer.writeExpression(value);
  }
}

enum DynamicAccessKind {
  /// An access on a receiver of type dynamic.
  ///
  /// An access of this kind always results in a value of static type dynamic.
  ///
  /// Valid accesses to Object members on receivers of type dynamic are encoded
  /// as an [InstanceInvocation] of kind [InstanceAccessKind.Object].
  Dynamic,

  /// An access on a receiver of type Never.
  ///
  /// An access of this kind always results in a value of static type Never.
  ///
  /// Valid accesses to Object members on receivers of type Never are also
  /// encoded as [DynamicInvocation] of kind [DynamicAccessKind.Never] and _not_
  /// as an [InstanceInvocation] of kind [InstanceAccessKind.Object].
  Never,

  /// An access on a receiver of an invalid type.
  ///
  /// An access of this kind always results in a value of an invalid static
  /// type.
  Invalid,

  Unresolved,
}

class DynamicGet extends Expression {
  final DynamicAccessKind kind;
  Expression receiver;
  Name name;

  DynamicGet(this.kind, this.receiver, this.name) {
    receiver.parent = this;
  }

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitDynamicGet(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitDynamicGet(this, arg);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) {
    switch (kind) {
      case DynamicAccessKind.Dynamic:
        return const DynamicType();
      case DynamicAccessKind.Never:
        return const NeverType.nonNullable();
      case DynamicAccessKind.Invalid:
      case DynamicAccessKind.Unresolved:
        return const InvalidType();
    }
  }

  @override
  void visitChildren(Visitor v) {
    receiver.accept(v);
    name.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    // ignore: unnecessary_null_comparison
    if (receiver != null) {
      receiver = v.transform(receiver);
      receiver.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    // ignore: unnecessary_null_comparison
    if (receiver != null) {
      receiver = v.transform(receiver);
      receiver.parent = this;
    }
  }

  @override
  String toString() {
    return "DynamicGet($kind,${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(receiver,
        minimumPrecedence: astToText.Precedence.PRIMARY);
    printer.write('.');
    printer.writeName(name);
  }
}

/// An property read of an instance getter or field with a statically known
/// interface target.
class InstanceGet extends Expression {
  final InstanceAccessKind kind;
  Expression receiver;
  Name name;

  /// The static type of result of the property read.
  ///
  /// This includes substituted type parameters from the static receiver type.
  ///
  /// For instance
  ///
  ///    class A<T> {
  ///      T get t;
  ///    }
  ///    m(A<String> a) {
  ///      a.t; // The result type is `String`.
  ///    }
  ///
  DartType resultType;

  Reference interfaceTargetReference;

  InstanceGet(InstanceAccessKind kind, Expression receiver, Name name,
      {required Member interfaceTarget, required DartType resultType})
      : this.byReference(kind, receiver, name,
            interfaceTargetReference:
                getNonNullableMemberReferenceGetter(interfaceTarget),
            resultType: resultType);

  InstanceGet.byReference(this.kind, this.receiver, this.name,
      {required this.interfaceTargetReference, required this.resultType})
      // ignore: unnecessary_null_comparison
      : assert(interfaceTargetReference != null),
        // ignore: unnecessary_null_comparison
        assert(resultType != null) {
    receiver.parent = this;
  }

  Member get interfaceTarget => interfaceTargetReference.asMember;

  void set interfaceTarget(Member member) {
    interfaceTargetReference = getNonNullableMemberReferenceGetter(member);
  }

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) => resultType;

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitInstanceGet(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitInstanceGet(this, arg);

  @override
  void visitChildren(Visitor v) {
    receiver.accept(v);
    interfaceTarget.acceptReference(v);
    name.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    // ignore: unnecessary_null_comparison
    if (receiver != null) {
      receiver = v.transform(receiver);
      receiver.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    // ignore: unnecessary_null_comparison
    if (receiver != null) {
      receiver = v.transform(receiver);
      receiver.parent = this;
    }
  }

  @override
  String toString() {
    return "InstanceGet($kind,${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(receiver,
        minimumPrecedence: astToText.Precedence.PRIMARY);
    printer.write('.');
    printer.writeInterfaceMemberName(interfaceTargetReference, name);
  }
}

/// A tear-off of the 'call' method on an expression whose static type is
/// a function type or the type 'Function'.
class FunctionTearOff extends Expression {
  Expression receiver;

  FunctionTearOff(this.receiver) {
    receiver.parent = this;
  }

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) =>
      receiver.getStaticType(context);

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitFunctionTearOff(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitFunctionTearOff(this, arg);

  @override
  void visitChildren(Visitor v) {
    receiver.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    // ignore: unnecessary_null_comparison
    if (receiver != null) {
      receiver = v.transform(receiver);
      receiver.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    // ignore: unnecessary_null_comparison
    if (receiver != null) {
      receiver = v.transform(receiver);
      receiver.parent = this;
    }
  }

  @override
  String toString() {
    return "FunctionTearOff(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(receiver,
        minimumPrecedence: astToText.Precedence.PRIMARY);
    printer.write('.');
    printer.writeName(Name.callName);
  }
}

/// A tear-off of an instance method with a statically known interface target.
class InstanceTearOff extends Expression {
  final InstanceAccessKind kind;
  Expression receiver;
  Name name;

  /// The static type of result of the tear-off.
  ///
  /// This includes substituted type parameters from the static receiver type.
  ///
  /// For instance
  ///
  ///    class A<T, S> {
  ///      T method<U>(S s, U u) { ... }
  ///    }
  ///    m(A<String, int> a) {
  ///      a.method; // The result type is `String Function<U>(int, U)`.
  ///    }
  ///
  DartType resultType;

  Reference interfaceTargetReference;

  InstanceTearOff(InstanceAccessKind kind, Expression receiver, Name name,
      {required Procedure interfaceTarget, required DartType resultType})
      : this.byReference(kind, receiver, name,
            interfaceTargetReference:
                getNonNullableMemberReferenceGetter(interfaceTarget),
            resultType: resultType);

  InstanceTearOff.byReference(this.kind, this.receiver, this.name,
      {required this.interfaceTargetReference, required this.resultType}) {
    receiver.parent = this;
  }

  Procedure get interfaceTarget => interfaceTargetReference.asProcedure;

  void set interfaceTarget(Procedure procedure) {
    interfaceTargetReference = getNonNullableMemberReferenceGetter(procedure);
  }

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) => resultType;

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitInstanceTearOff(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitInstanceTearOff(this, arg);

  @override
  void visitChildren(Visitor v) {
    receiver.accept(v);
    interfaceTarget.acceptReference(v);
    name.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    // ignore: unnecessary_null_comparison
    if (receiver != null) {
      receiver = v.transform(receiver);
      receiver.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    // ignore: unnecessary_null_comparison
    if (receiver != null) {
      receiver = v.transform(receiver);
      receiver.parent = this;
    }
  }

  @override
  String toString() {
    return "InstanceTearOff($kind, ${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(receiver,
        minimumPrecedence: astToText.Precedence.PRIMARY);
    printer.write('.');
    printer.writeInterfaceMemberName(interfaceTargetReference, name);
  }
}

/// Expression of form `x.field`.
///
/// This may invoke a getter, read a field, or tear off a method.
class PropertyGet extends Expression {
  Expression receiver;
  Name name;

  Reference? interfaceTargetReference;

  PropertyGet(Expression receiver, Name name, [Member? interfaceTarget])
      : this.byReference(
            receiver, name, getMemberReferenceGetter(interfaceTarget));

  PropertyGet.byReference(
      this.receiver, this.name, this.interfaceTargetReference) {
    receiver.parent = this;
  }

  Member? get interfaceTarget => interfaceTargetReference?.asMember;

  void set interfaceTarget(Member? member) {
    interfaceTargetReference = getMemberReferenceGetter(member);
  }

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) {
    Member? interfaceTarget = this.interfaceTarget;
    if (interfaceTarget != null) {
      Class superclass = interfaceTarget.enclosingClass!;
      InterfaceType receiverType =
          receiver.getStaticTypeAsInstanceOf(superclass, context);
      return Substitution.fromInterfaceType(receiverType)
          .substituteType(interfaceTarget.getterType);
    }
    // Treat the properties of Object specially.
    String nameString = name.text;
    if (nameString == 'hashCode') {
      return context.typeEnvironment.coreTypes.intRawType(context.nonNullable);
    } else if (nameString == 'runtimeType') {
      return context.typeEnvironment.coreTypes.typeRawType(context.nonNullable);
    }
    return const DynamicType();
  }

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitPropertyGet(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitPropertyGet(this, arg);

  @override
  void visitChildren(Visitor v) {
    receiver.accept(v);
    interfaceTarget?.acceptReference(v);
    name.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    // ignore: unnecessary_null_comparison
    if (receiver != null) {
      receiver = v.transform(receiver);
      receiver.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    // ignore: unnecessary_null_comparison
    if (receiver != null) {
      receiver = v.transform(receiver);
      receiver.parent = this;
    }
  }

  @override
  String toString() {
    return "PropertyGet(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(receiver,
        minimumPrecedence: astToText.Precedence.PRIMARY);
    printer.write('.');
    printer.writeInterfaceMemberName(interfaceTargetReference, name);
  }
}

class DynamicSet extends Expression {
  final DynamicAccessKind kind;
  Expression receiver;
  Name name;
  Expression value;

  DynamicSet(this.kind, this.receiver, this.name, this.value) {
    receiver.parent = this;
    value.parent = this;
  }

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) =>
      value.getStaticType(context);

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitDynamicSet(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitDynamicSet(this, arg);

  @override
  void visitChildren(Visitor v) {
    receiver.accept(v);
    name.accept(v);
    value.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    // ignore: unnecessary_null_comparison
    if (receiver != null) {
      receiver = v.transform(receiver);
      receiver.parent = this;
    }
    // ignore: unnecessary_null_comparison
    if (value != null) {
      value = v.transform(value);
      value.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    // ignore: unnecessary_null_comparison
    if (receiver != null) {
      receiver = v.transform(receiver);
      receiver.parent = this;
    }
    // ignore: unnecessary_null_comparison
    if (value != null) {
      value = v.transform(value);
      value.parent = this;
    }
  }

  @override
  String toString() {
    return "DynamicSet($kind,${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(receiver,
        minimumPrecedence: astToText.Precedence.PRIMARY);
    printer.write('.');
    printer.writeName(name);
    printer.write(' = ');
    printer.writeExpression(value);
  }
}

/// An property write of an instance setter or field with a statically known
/// interface target.
class InstanceSet extends Expression {
  final InstanceAccessKind kind;
  Expression receiver;
  Name name;
  Expression value;

  Reference interfaceTargetReference;

  InstanceSet(
      InstanceAccessKind kind, Expression receiver, Name name, Expression value,
      {required Member interfaceTarget})
      : this.byReference(kind, receiver, name, value,
            interfaceTargetReference:
                getNonNullableMemberReferenceSetter(interfaceTarget));

  InstanceSet.byReference(this.kind, this.receiver, this.name, this.value,
      {required this.interfaceTargetReference})
      // ignore: unnecessary_null_comparison
      : assert(interfaceTargetReference != null) {
    receiver.parent = this;
    value.parent = this;
  }

  Member get interfaceTarget => interfaceTargetReference.asMember;

  void set interfaceTarget(Member member) {
    interfaceTargetReference = getNonNullableMemberReferenceSetter(member);
  }

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) =>
      value.getStaticType(context);

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitInstanceSet(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitInstanceSet(this, arg);

  @override
  void visitChildren(Visitor v) {
    receiver.accept(v);
    interfaceTarget.acceptReference(v);
    name.accept(v);
    value.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    // ignore: unnecessary_null_comparison
    if (receiver != null) {
      receiver = v.transform(receiver);
      receiver.parent = this;
    }
    // ignore: unnecessary_null_comparison
    if (value != null) {
      value = v.transform(value);
      value.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    // ignore: unnecessary_null_comparison
    if (receiver != null) {
      receiver = v.transform(receiver);
      receiver.parent = this;
    }
    // ignore: unnecessary_null_comparison
    if (value != null) {
      value = v.transform(value);
      value.parent = this;
    }
  }

  @override
  String toString() {
    return "InstanceSet(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(receiver,
        minimumPrecedence: astToText.Precedence.PRIMARY);
    printer.write('.');
    printer.writeInterfaceMemberName(interfaceTargetReference, name);
    printer.write(' = ');
    printer.writeExpression(value);
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

  Reference? interfaceTargetReference;

  PropertySet(Expression receiver, Name name, Expression value,
      [Member? interfaceTarget])
      : this.byReference(
            receiver, name, value, getMemberReferenceSetter(interfaceTarget));

  PropertySet.byReference(
      this.receiver, this.name, this.value, this.interfaceTargetReference) {
    receiver.parent = this;
    value.parent = this;
  }

  Member? get interfaceTarget => interfaceTargetReference?.asMember;

  void set interfaceTarget(Member? member) {
    interfaceTargetReference = getMemberReferenceSetter(member);
  }

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) =>
      value.getStaticType(context);

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitPropertySet(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitPropertySet(this, arg);

  @override
  void visitChildren(Visitor v) {
    receiver.accept(v);
    interfaceTarget?.acceptReference(v);
    name.accept(v);
    value.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    // ignore: unnecessary_null_comparison
    if (receiver != null) {
      receiver = v.transform(receiver);
      receiver.parent = this;
    }
    // ignore: unnecessary_null_comparison
    if (value != null) {
      value = v.transform(value);
      value.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    // ignore: unnecessary_null_comparison
    if (receiver != null) {
      receiver = v.transform(receiver);
      receiver.parent = this;
    }
    // ignore: unnecessary_null_comparison
    if (value != null) {
      value = v.transform(value);
      value.parent = this;
    }
  }

  @override
  String toString() {
    return "PropertySet(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(receiver,
        minimumPrecedence: astToText.Precedence.PRIMARY);
    printer.write('.');
    printer.writeInterfaceMemberName(interfaceTargetReference, name);
    printer.write(' = ');
    printer.writeExpression(value);
  }
}

/// Expression of form `super.field`.
///
/// This may invoke a getter, read a field, or tear off a method.
class SuperPropertyGet extends Expression {
  Name name;

  Reference? interfaceTargetReference;

  SuperPropertyGet(Name name, [Member? interfaceTarget])
      : this.byReference(name, getMemberReferenceGetter(interfaceTarget));

  SuperPropertyGet.byReference(this.name, this.interfaceTargetReference);

  Member? get interfaceTarget => interfaceTargetReference?.asMember;

  void set interfaceTarget(Member? member) {
    interfaceTargetReference = getMemberReferenceGetter(member);
  }

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) {
    Member? interfaceTarget = this.interfaceTarget;
    if (interfaceTarget == null) {
      // TODO(johnniwinther): SuperPropertyGet without a target should be
      // replaced by invalid expressions.
      return const DynamicType();
    }
    Class declaringClass = interfaceTarget.enclosingClass!;
    if (declaringClass.typeParameters.isEmpty) {
      return interfaceTarget.getterType;
    }
    List<DartType>? receiverArguments = context.typeEnvironment
        .getTypeArgumentsAsInstanceOf(context.thisType!, declaringClass);
    return Substitution.fromPairs(
            declaringClass.typeParameters, receiverArguments!)
        .substituteType(interfaceTarget.getterType);
  }

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitSuperPropertyGet(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitSuperPropertyGet(this, arg);

  @override
  void visitChildren(Visitor v) {
    interfaceTarget?.acceptReference(v);
    name.accept(v);
  }

  @override
  void transformChildren(Transformer v) {}

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {}

  @override
  String toString() {
    return "SuperPropertyGet(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('super.');
    printer.writeInterfaceMemberName(interfaceTargetReference, name);
  }
}

/// Expression of form `super.field = value`.
///
/// This may invoke a setter or assign a field.
///
/// Evaluates to the value of [value].
class SuperPropertySet extends Expression {
  Name name;
  Expression value;

  Reference? interfaceTargetReference;

  SuperPropertySet(Name name, Expression value, Member interfaceTarget)
      : this.byReference(
            name, value, getMemberReferenceSetter(interfaceTarget));

  SuperPropertySet.byReference(
      this.name, this.value, this.interfaceTargetReference) {
    value.parent = this;
  }

  Member? get interfaceTarget => interfaceTargetReference?.asMember;

  void set interfaceTarget(Member? member) {
    interfaceTargetReference = getMemberReferenceSetter(member);
  }

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) =>
      value.getStaticType(context);

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitSuperPropertySet(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitSuperPropertySet(this, arg);

  @override
  void visitChildren(Visitor v) {
    interfaceTarget?.acceptReference(v);
    name.accept(v);
    value.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    // ignore: unnecessary_null_comparison
    if (value != null) {
      value = v.transform(value);
      value.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    // ignore: unnecessary_null_comparison
    if (value != null) {
      value = v.transform(value);
      value.parent = this;
    }
  }

  @override
  String toString() {
    return "SuperPropertySet(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('super.');
    printer.writeInterfaceMemberName(interfaceTargetReference, name);
    printer.write(' = ');
    printer.writeExpression(value);
  }
}

/// Read a static field, call a static getter, or tear off a static method.
class StaticGet extends Expression {
  /// A static field, getter, or method (for tear-off).
  Reference targetReference;

  StaticGet(Member target)
      : this.byReference(getNonNullableMemberReferenceGetter(target));

  StaticGet.byReference(this.targetReference);

  Member get target => targetReference.asMember;

  void set target(Member target) {
    targetReference = getNonNullableMemberReferenceGetter(target);
  }

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) =>
      target.getterType;

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitStaticGet(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitStaticGet(this, arg);

  @override
  void visitChildren(Visitor v) {
    target.acceptReference(v);
  }

  @override
  void transformChildren(Transformer v) {}

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {}

  @override
  String toString() {
    return "StaticGet(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeMemberName(targetReference);
  }
}

/// Tear-off of a static method.
class StaticTearOff extends Expression {
  Reference targetReference;

  StaticTearOff(Procedure target)
      : this.byReference(getNonNullableMemberReferenceGetter(target));

  StaticTearOff.byReference(this.targetReference);

  Procedure get target => targetReference.asProcedure;

  void set target(Procedure target) {
    targetReference = getNonNullableMemberReferenceGetter(target);
  }

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) =>
      target.getterType;

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitStaticTearOff(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitStaticTearOff(this, arg);

  @override
  void visitChildren(Visitor v) {
    target.acceptReference(v);
  }

  @override
  void transformChildren(Transformer v) {}

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {}

  @override
  String toString() {
    return "StaticTearOff(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeMemberName(targetReference);
  }
}

/// Assign a static field or call a static setter.
///
/// Evaluates to the value of [value].
class StaticSet extends Expression {
  /// A mutable static field or a static setter.
  Reference targetReference;
  Expression value;

  StaticSet(Member target, Expression value)
      : this.byReference(getNonNullableMemberReferenceSetter(target), value);

  StaticSet.byReference(this.targetReference, this.value) {
    value.parent = this;
  }

  Member get target => targetReference.asMember;

  void set target(Member target) {
    targetReference = getNonNullableMemberReferenceSetter(target);
  }

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) =>
      value.getStaticType(context);

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitStaticSet(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitStaticSet(this, arg);

  @override
  void visitChildren(Visitor v) {
    target.acceptReference(v);
    value.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    // ignore: unnecessary_null_comparison
    if (value != null) {
      value = v.transform(value);
      value.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    // ignore: unnecessary_null_comparison
    if (value != null) {
      value = v.transform(value);
      value.parent = this;
    }
  }

  @override
  String toString() {
    return "StaticSet(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeMemberName(targetReference);
    printer.write(' = ');
    printer.writeExpression(value);
  }
}

/// The arguments to a function call, divided into type arguments,
/// positional arguments, and named arguments.
class Arguments extends TreeNode {
  final List<DartType> types;
  final List<Expression> positional;
  List<NamedExpression> named;

  Arguments(this.positional,
      {List<DartType>? types, List<NamedExpression>? named})
      : this.types = types ?? <DartType>[],
        this.named = named ?? <NamedExpression>[] {
    setParents(this.positional, this);
    setParents(this.named, this);
  }

  Arguments.empty()
      : types = <DartType>[],
        positional = <Expression>[],
        named = <NamedExpression>[];

  factory Arguments.forwarded(FunctionNode function, Library library) {
    return new Arguments(
        function.positionalParameters
            .map<Expression>((p) => new VariableGet(p))
            .toList(),
        named: function.namedParameters
            .map((p) => new NamedExpression(p.name!, new VariableGet(p)))
            .toList(),
        types: function.typeParameters
            .map<DartType>((p) =>
                new TypeParameterType.withDefaultNullabilityForLibrary(
                    p, library))
            .toList());
  }

  @override
  R accept<R>(TreeVisitor<R> v) => v.visitArguments(this);

  @override
  R accept1<R, A>(TreeVisitor1<R, A> v, A arg) => v.visitArguments(this, arg);

  @override
  void visitChildren(Visitor v) {
    visitList(types, v);
    visitList(positional, v);
    visitList(named, v);
  }

  @override
  void transformChildren(Transformer v) {
    v.transformDartTypeList(types);
    v.transformList(positional, this);
    v.transformList(named, this);
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    v.transformDartTypeList(types);
    v.transformExpressionList(positional, this);
    v.transformNamedExpressionList(named, this);
  }

  @override
  String toString() {
    return "Arguments(${toStringInternal()})";
  }

  @override
  String toText(AstTextStrategy strategy) {
    AstPrinter printer = new AstPrinter(strategy);
    printer.writeArguments(this);
    return printer.getText();
  }

  @override
  void toTextInternal(AstPrinter printer, {bool includeTypeArguments: true}) {
    if (includeTypeArguments) {
      printer.writeTypeArguments(types);
    }
    printer.write('(');
    for (int index = 0; index < positional.length; index++) {
      if (index > 0) {
        printer.write(', ');
      }
      printer.writeExpression(positional[index]);
    }
    if (named.isNotEmpty) {
      if (positional.isNotEmpty) {
        printer.write(', ');
      }
      for (int index = 0; index < named.length; index++) {
        if (index > 0) {
          printer.write(', ');
        }
        printer.writeNamedExpression(named[index]);
      }
    }
    printer.write(')');
  }
}

/// A named argument, `name: value`.
class NamedExpression extends TreeNode {
  String name;
  Expression value;

  NamedExpression(this.name, this.value) {
    value.parent = this;
  }

  @override
  R accept<R>(TreeVisitor<R> v) => v.visitNamedExpression(this);

  @override
  R accept1<R, A>(TreeVisitor1<R, A> v, A arg) =>
      v.visitNamedExpression(this, arg);

  @override
  void visitChildren(Visitor v) {
    value.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    // ignore: unnecessary_null_comparison
    if (value != null) {
      value = v.transform(value);
      value.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    // ignore: unnecessary_null_comparison
    if (value != null) {
      value = v.transform(value);
      value.parent = this;
    }
  }

  @override
  String toString() {
    return "NamedExpression(${toStringInternal()})";
  }

  @override
  String toText(AstTextStrategy strategy) {
    AstPrinter printer = new AstPrinter(strategy);
    toTextInternal(printer);
    return printer.getText();
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write(name);
    printer.write(': ');
    printer.writeExpression(value);
  }
}

/// Common super class for [DirectMethodInvocation], [MethodInvocation],
/// [SuperMethodInvocation], [StaticInvocation], and [ConstructorInvocation].
abstract class InvocationExpression extends Expression {
  Arguments get arguments;
  void set arguments(Arguments value);

  /// Name of the invoked method.
  Name get name;
}

class DynamicInvocation extends InvocationExpression {
  final DynamicAccessKind kind;
  Expression receiver;

  @override
  Name name;

  @override
  Arguments arguments;

  DynamicInvocation(this.kind, this.receiver, this.name, this.arguments) {
    receiver.parent = this;
    arguments.parent = this;
  }

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) {
    switch (kind) {
      case DynamicAccessKind.Dynamic:
        return const DynamicType();
      case DynamicAccessKind.Never:
        return const NeverType.nonNullable();
      case DynamicAccessKind.Invalid:
      case DynamicAccessKind.Unresolved:
        return const InvalidType();
    }
  }

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitDynamicInvocation(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitDynamicInvocation(this, arg);

  @override
  void visitChildren(Visitor v) {
    receiver.accept(v);
    name.accept(v);
    arguments.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    // ignore: unnecessary_null_comparison
    if (receiver != null) {
      receiver = v.transform(receiver);
      receiver.parent = this;
    }
    // ignore: unnecessary_null_comparison
    if (arguments != null) {
      arguments = v.transform(arguments);
      arguments.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    // ignore: unnecessary_null_comparison
    if (receiver != null) {
      receiver = v.transform(receiver);
      receiver.parent = this;
    }
    // ignore: unnecessary_null_comparison
    if (arguments != null) {
      arguments = v.transform(arguments);
      arguments.parent = this;
    }
  }

  @override
  String toString() {
    return "DynamicInvocation($kind,${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(receiver,
        minimumPrecedence: astToText.Precedence.PRIMARY);
    printer.write('.');
    printer.writeName(name);
    printer.writeArguments(arguments);
  }
}

/// Access kind used by [InstanceInvocation], [InstanceGet], [InstanceSet],
/// and [InstanceTearOff].
enum InstanceAccessKind {
  /// An access to a member on a static receiver type which is an interface
  /// type.
  ///
  /// In null safe libraries the static receiver type is non-nullable.
  ///
  /// For instance:
  ///
  ///     class C { void method() {} }
  ///     main() => new C().method();
  ///
  Instance,

  /// An access to a member defined on Object on a static receiver type that
  /// is either a non-interface type or a nullable type.
  ///
  /// For instance:
  ///
  ///     test1(String? s) => s.toString();
  ///     test1(dynamic s) => s.hashCode;
  ///
  Object,

  /// An access to a method on a static receiver type which is an interface
  /// type which is inapplicable, that is, whose arguments don't match the
  /// required parameter structure.
  ///
  /// This is an error case which is only used on expression nested within
  /// [InvalidExpression]s.
  ///
  /// For instance:
  ///
  ///     class C { void method() {} }
  ///     main() => new C().method(0); // Too many arguments.
  ///
  Inapplicable,

  /// An access to a non-Object member on a static receiver type which is a
  /// nullable interface type.
  ///
  /// This is an error case which is only used on expression nested within
  /// [InvalidExpression]s.
  ///
  /// For instance:
  ///
  ///     class C { void method() {} }
  ///     test(C? c) => c.method(0); // 'c' is nullable.
  ///
  Nullable,
}

/// An invocation of an instance method with a statically known interface
/// target.
class InstanceInvocation extends InvocationExpression {
  // Must match serialized bit positions.
  static const int FlagInvariant = 1 << 0;
  static const int FlagBoundsSafe = 1 << 1;

  final InstanceAccessKind kind;
  Expression receiver;

  @override
  Name name;

  @override
  Arguments arguments;

  int flags = 0;

  /// The static type of the invocation.
  ///
  /// This includes substituted type parameters from the static receiver type
  /// and generic type arguments.
  ///
  /// For instance
  ///
  ///    class A<T> {
  ///      Map<T, S> map<S>(S s) { ... }
  ///    }
  ///    m(A<String> a) {
  ///      a.map(0); // The function type is `Map<String, int> Function(int)`.
  ///    }
  ///
  FunctionType functionType;

  Reference interfaceTargetReference;

  InstanceInvocation(InstanceAccessKind kind, Expression receiver, Name name,
      Arguments arguments,
      {required Procedure interfaceTarget, required FunctionType functionType})
      : this.byReference(kind, receiver, name, arguments,
            interfaceTargetReference:
                getNonNullableMemberReferenceGetter(interfaceTarget),
            functionType: functionType);

  InstanceInvocation.byReference(
      this.kind, this.receiver, this.name, this.arguments,
      {required this.interfaceTargetReference, required this.functionType})
      // ignore: unnecessary_null_comparison
      : assert(interfaceTargetReference != null),
        // ignore: unnecessary_null_comparison
        assert(functionType != null),
        assert(functionType.typeParameters.isEmpty) {
    receiver.parent = this;
    arguments.parent = this;
  }

  Procedure get interfaceTarget => interfaceTargetReference.asProcedure;

  void set interfaceTarget(Procedure target) {
    interfaceTargetReference = getNonNullableMemberReferenceGetter(target);
  }

  /// If `true`, this call is known to be safe wrt. parameter covariance checks.
  ///
  /// This is for instance the case in code patterns like this
  ///
  ///     List<int> list = <int>[];
  ///     list.add(0);
  ///
  /// where the `list` variable is known to hold a value of the same type as
  /// the static type. In contrast the would not be the case in code patterns
  /// like this
  ///
  ///     List<num> list = <double>[];
  ///     list.add(0); // Runtime error `int` is not a subtype of `double`.
  ///
  bool get isInvariant => flags & FlagInvariant != 0;

  void set isInvariant(bool value) {
    flags = value ? (flags | FlagInvariant) : (flags & ~FlagInvariant);
  }

  /// If `true`, this call is known to be safe wrt. parameter covariance checks.
  ///
  /// This is for instance the case in code patterns like this
  ///
  ///     List list = new List.filled(2, 0);
  ///     list[1] = 42;
  ///
  /// where the `list` is known to have a sufficient length for the update
  /// in `list[1] = 42`.
  bool get isBoundsSafe => flags & FlagBoundsSafe != 0;

  void set isBoundsSafe(bool value) {
    flags = value ? (flags | FlagBoundsSafe) : (flags & ~FlagBoundsSafe);
  }

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) =>
      functionType.returnType;

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitInstanceInvocation(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitInstanceInvocation(this, arg);

  @override
  void visitChildren(Visitor v) {
    receiver.accept(v);
    interfaceTarget.acceptReference(v);
    name.accept(v);
    arguments.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    // ignore: unnecessary_null_comparison
    if (receiver != null) {
      receiver = v.transform(receiver);
      receiver.parent = this;
    }
    // ignore: unnecessary_null_comparison
    if (arguments != null) {
      arguments = v.transform(arguments);
      arguments.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    // ignore: unnecessary_null_comparison
    if (receiver != null) {
      receiver = v.transform(receiver);
      receiver.parent = this;
    }
    // ignore: unnecessary_null_comparison
    if (arguments != null) {
      arguments = v.transform(arguments);
      arguments.parent = this;
    }
  }

  @override
  String toString() {
    return "InstanceInvocation($kind, ${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(receiver,
        minimumPrecedence: astToText.Precedence.PRIMARY);
    printer.write('.');
    printer.writeInterfaceMemberName(interfaceTargetReference, name);
    printer.writeArguments(arguments);
  }
}

/// An invocation of an instance getter or field with a statically known
/// interface target.
///
/// This is used only for web backend in order to support invocation of
/// native properties as functions. This node will be removed when this
/// invocation style is no longer supported.
class InstanceGetterInvocation extends InvocationExpression {
  // Must match serialized bit positions.
  static const int FlagInvariant = 1 << 0;
  static const int FlagBoundsSafe = 1 << 1;

  final InstanceAccessKind kind;
  Expression receiver;

  @override
  Name name;

  @override
  Arguments arguments;

  int flags = 0;

  /// The static type of the invocation.
  ///
  /// This includes substituted type parameters from the static receiver type
  /// and generic type arguments.
  ///
  /// For instance
  ///
  ///    class A<T> {
  ///      Map<T, S> map<S>(S s) { ... }
  ///    }
  ///    m(A<String> a) {
  ///      a.map(0); // The function type is `Map<String, int> Function(int)`.
  ///    }
  ///
  FunctionType functionType;

  Reference interfaceTargetReference;

  InstanceGetterInvocation(InstanceAccessKind kind, Expression receiver,
      Name name, Arguments arguments,
      {required Procedure interfaceTarget, required FunctionType functionType})
      : this.byReference(kind, receiver, name, arguments,
            interfaceTargetReference:
                getNonNullableMemberReferenceGetter(interfaceTarget),
            functionType: functionType);

  InstanceGetterInvocation.byReference(
      this.kind, this.receiver, this.name, this.arguments,
      {required this.interfaceTargetReference, required this.functionType})
      // ignore: unnecessary_null_comparison
      : assert(interfaceTargetReference != null),
        // ignore: unnecessary_null_comparison
        assert(functionType != null),
        assert(functionType.typeParameters.isEmpty) {
    receiver.parent = this;
    arguments.parent = this;
  }

  Member get interfaceTarget => interfaceTargetReference.asProcedure;

  void set interfaceTarget(Member target) {
    interfaceTargetReference = getNonNullableMemberReferenceGetter(target);
  }

  /// If `true`, this call is known to be safe wrt. parameter covariance checks.
  ///
  /// This is for instance the case in code patterns like this
  ///
  ///     List<int> list = <int>[];
  ///     list.add(0);
  ///
  /// where the `list` variable is known to hold a value of the same type as
  /// the static type. In contrast the would not be the case in code patterns
  /// like this
  ///
  ///     List<num> list = <double>[];
  ///     list.add(0); // Runtime error `int` is not a subtype of `double`.
  ///
  bool get isInvariant => flags & FlagInvariant != 0;

  void set isInvariant(bool value) {
    flags = value ? (flags | FlagInvariant) : (flags & ~FlagInvariant);
  }

  /// If `true`, this call is known to be safe wrt. parameter covariance checks.
  ///
  /// This is for instance the case in code patterns like this
  ///
  ///     List list = new List.filled(2, 0);
  ///     list[1] = 42;
  ///
  /// where the `list` is known to have a sufficient length for the update
  /// in `list[1] = 42`.
  bool get isBoundsSafe => flags & FlagBoundsSafe != 0;

  void set isBoundsSafe(bool value) {
    flags = value ? (flags | FlagBoundsSafe) : (flags & ~FlagBoundsSafe);
  }

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) =>
      functionType.returnType;

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitInstanceGetterInvocation(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitInstanceGetterInvocation(this, arg);

  @override
  void visitChildren(Visitor v) {
    receiver.accept(v);
    interfaceTarget.acceptReference(v);
    name.accept(v);
    arguments.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    // ignore: unnecessary_null_comparison
    if (receiver != null) {
      receiver = v.transform(receiver);
      receiver.parent = this;
    }
    // ignore: unnecessary_null_comparison
    if (arguments != null) {
      arguments = v.transform(arguments);
      arguments.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    // ignore: unnecessary_null_comparison
    if (receiver != null) {
      receiver = v.transform(receiver);
      receiver.parent = this;
    }
    // ignore: unnecessary_null_comparison
    if (arguments != null) {
      arguments = v.transform(arguments);
      arguments.parent = this;
    }
  }

  @override
  String toString() {
    return "InstanceGetterInvocation($kind, ${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(receiver,
        minimumPrecedence: astToText.Precedence.PRIMARY);
    printer.write('.');
    printer.writeInterfaceMemberName(interfaceTargetReference, name);
    printer.writeArguments(arguments);
  }
}

/// Access kind used by [FunctionInvocation] and [FunctionTearOff].
enum FunctionAccessKind {
  /// An access to the 'call' method on an expression of static type `Function`.
  ///
  /// For instance
  ///
  ///     method(Function f) => f();
  ///
  Function,

  /// An access to the 'call' method on an expression whose static type is a
  /// function type.
  ///
  /// For instance
  ///
  ///     method(void Function() f) => f();
  ///
  FunctionType,

  /// An access to the 'call' method on an expression whose static type is a
  /// function type which is inapplicable, that is, whose arguments don't match
  /// the required parameter structure.
  ///
  /// This is an error case which is only used on expression nested within
  /// [InvalidExpression]s.
  ///
  /// For instance:
  ///
  ///     test(void Function() f) => f(0); // Too many arguments.
  ///
  Inapplicable,

  /// An access to the 'call' method on an expression whose static type is a
  /// nullable function type or `Function?`.
  ///
  /// This is an error case which is only used on expression nested within
  /// [InvalidExpression]s.
  ///
  /// For instance:
  ///
  ///     test(void Function()? f) => f(); // 'f' is nullable.
  ///
  Nullable,
}

/// An invocation of the 'call' method on an expression whose static type is
/// a function type or the type 'Function'.
class FunctionInvocation extends InvocationExpression {
  final FunctionAccessKind kind;

  Expression receiver;

  @override
  Arguments arguments;

  /// The static type of the invocation.
  ///
  /// This is `null` if the static type of the receiver is not a function type
  /// or is not bounded by a function type.
  ///
  /// For instance
  ///
  ///    m<T extends Function, S extends int Function()>(T t, S s, Function f) {
  ///      X local<X>(X t) => t;
  ///      t(); // The function type is `null`.
  ///      s(); // The function type is `int Function()`.
  ///      f(); // The function type is `null`.
  ///      local(0); // The function type is `int Function(int)`.
  ///    }
  ///
  FunctionType? functionType;

  FunctionInvocation(this.kind, this.receiver, this.arguments,
      {required this.functionType}) {
    receiver.parent = this;
    arguments.parent = this;
  }

  @override
  Name get name => Name.callName;

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) =>
      functionType?.returnType ?? const DynamicType();

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitFunctionInvocation(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitFunctionInvocation(this, arg);

  @override
  void visitChildren(Visitor v) {
    receiver.accept(v);
    name.accept(v);
    arguments.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    // ignore: unnecessary_null_comparison
    if (receiver != null) {
      receiver = v.transform(receiver);
      receiver.parent = this;
    }
    // ignore: unnecessary_null_comparison
    if (arguments != null) {
      arguments = v.transform(arguments);
      arguments.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    // ignore: unnecessary_null_comparison
    if (receiver != null) {
      receiver = v.transform(receiver);
      receiver.parent = this;
    }
    // ignore: unnecessary_null_comparison
    if (arguments != null) {
      arguments = v.transform(arguments);
      arguments.parent = this;
    }
  }

  @override
  String toString() {
    return "FunctionInvocation(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(receiver,
        minimumPrecedence: astToText.Precedence.PRIMARY);
    printer.writeArguments(arguments);
  }
}

/// An invocation of a local function declaration.
class LocalFunctionInvocation extends InvocationExpression {
  /// The variable declaration for the function declaration.
  VariableDeclaration variable;

  @override
  Arguments arguments;

  /// The static type of the invocation.
  ///
  /// This might differ from the static type of [variable] for generic
  /// functions.
  ///
  /// For instance
  ///
  ///    m() {
  ///      T local<T>(T t) => t;
  ///      local(0); // The static type is `int Function(int)`.
  ///    }
  ///
  FunctionType functionType;

  LocalFunctionInvocation(this.variable, this.arguments,
      {required this.functionType})
      // ignore: unnecessary_null_comparison
      : assert(functionType != null) {
    arguments.parent = this;
  }

  /// The declaration for the invoked local function.
  FunctionDeclaration get localFunction =>
      variable.parent as FunctionDeclaration;

  @override
  Name get name => Name.callName;

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) =>
      functionType.returnType;

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitLocalFunctionInvocation(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitLocalFunctionInvocation(this, arg);

  @override
  void visitChildren(Visitor v) {
    arguments.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    // ignore: unnecessary_null_comparison
    if (arguments != null) {
      arguments = v.transform(arguments);
      arguments.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    // ignore: unnecessary_null_comparison
    if (arguments != null) {
      arguments = v.transform(arguments);
      arguments.parent = this;
    }
  }

  @override
  String toString() {
    return "LocalFunctionInvocation(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write(printer.getVariableName(variable));
    printer.writeArguments(arguments);
  }
}

/// Nullness test of an expression, that is `e == null`.
///
/// This is generated for code like `e1 == e2` where `e1` or `e2` is `null`.
class EqualsNull extends Expression {
  /// The expression tested for nullness.
  Expression expression;

  EqualsNull(this.expression) {
    expression.parent = this;
  }

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) =>
      context.typeEnvironment.coreTypes.boolRawType(context.nonNullable);

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitEqualsNull(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitEqualsNull(this, arg);

  @override
  void visitChildren(Visitor v) {
    expression.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    // ignore: unnecessary_null_comparison
    if (expression != null) {
      expression = v.transform(expression);
      expression.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    // ignore: unnecessary_null_comparison
    if (expression != null) {
      expression = v.transform(expression);
      expression.parent = this;
    }
  }

  @override
  String toString() {
    return "EqualsNull(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(expression, minimumPrecedence: precedence);
    printer.write(' == null');
  }
}

/// A test of equality, that is `e1 == e2`.
///
/// This is generated for code like `e1 == e2` where neither `e1` nor `e2` is
/// `null`.
class EqualsCall extends Expression {
  Expression left;
  Expression right;

  /// The static type of the invocation.
  ///
  /// This might differ from the static type of [Object.==] for covariant
  /// parameters.
  ///
  /// For instance
  ///
  ///    class C<T> {
  ///      bool operator(covariant C<T> other) { ... }
  ///    }
  ///    // The function type is `bool Function(C<num>)`.
  ///    method(C<num> a, C<int> b) => a == b;
  ///
  FunctionType functionType;

  Reference interfaceTargetReference;

  EqualsCall(Expression left, Expression right,
      {required FunctionType functionType, required Procedure interfaceTarget})
      : this.byReference(left, right,
            functionType: functionType,
            interfaceTargetReference:
                getNonNullableMemberReferenceGetter(interfaceTarget));

  EqualsCall.byReference(this.left, this.right,
      {required this.functionType, required this.interfaceTargetReference}) {
    left.parent = this;
    right.parent = this;
  }

  Procedure get interfaceTarget => interfaceTargetReference.asProcedure;

  void set interfaceTarget(Procedure target) {
    interfaceTargetReference = getNonNullableMemberReferenceGetter(target);
  }

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) {
    return functionType.returnType;
  }

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitEqualsCall(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitEqualsCall(this, arg);

  @override
  void visitChildren(Visitor v) {
    left.accept(v);
    interfaceTarget.acceptReference(v);
    right.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    // ignore: unnecessary_null_comparison
    if (left != null) {
      left = v.transform(left);
      left.parent = this;
    }
    // ignore: unnecessary_null_comparison
    if (right != null) {
      right = v.transform(right);
      right.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    // ignore: unnecessary_null_comparison
    if (left != null) {
      left = v.transform(left);
      left.parent = this;
    }
    // ignore: unnecessary_null_comparison
    if (right != null) {
      right = v.transform(right);
      right.parent = this;
    }
  }

  @override
  String toString() {
    return "EqualsCall(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    int minimumPrecedence = precedence;
    printer.writeExpression(left, minimumPrecedence: minimumPrecedence);
    printer.write(' == ');
    printer.writeExpression(right, minimumPrecedence: minimumPrecedence + 1);
  }
}

/// Expression of form `x.foo(y)`.
class MethodInvocation extends InvocationExpression {
  // Must match serialized bit positions.
  static const int FlagInvariant = 1 << 0;
  static const int FlagBoundsSafe = 1 << 1;

  Expression receiver;

  @override
  Name name;

  @override
  Arguments arguments;

  int flags = 0;

  Reference? interfaceTargetReference;

  MethodInvocation(Expression receiver, Name name, Arguments arguments,
      [Member? interfaceTarget])
      : this.byReference(
            receiver,
            name,
            arguments,
            // An invocation doesn't refer to the setter.
            getMemberReferenceGetter(interfaceTarget));

  MethodInvocation.byReference(
      this.receiver, this.name, this.arguments, this.interfaceTargetReference) {
    receiver.parent = this;
    arguments.parent = this;
  }

  Member? get interfaceTarget => interfaceTargetReference?.asMember;

  void set interfaceTarget(Member? target) {
    // An invocation doesn't refer to the setter.
    interfaceTargetReference = getMemberReferenceGetter(target);
  }

  /// If `true`, this call is known to be safe wrt. parameter covariance checks.
  ///
  /// This is for instance the case in code patterns like this
  ///
  ///     List<int> list = <int>[];
  ///     list.add(0);
  ///
  /// where the `list` variable is known to hold a value of the same type as
  /// the static type. In contrast the would not be the case in code patterns
  /// like this
  ///
  ///     List<num> list = <double>[];
  ///     list.add(0); // Runtime error `int` is not a subtype of `double`.
  ///
  bool get isInvariant => flags & FlagInvariant != 0;

  void set isInvariant(bool value) {
    flags = value ? (flags | FlagInvariant) : (flags & ~FlagInvariant);
  }

  /// If `true`, this call is known to be safe wrt. parameter covariance checks.
  ///
  /// This is for instance the case in code patterns like this
  ///
  ///     List list = new List.filled(2, 0);
  ///     list[1] = 42;
  ///
  /// where the `list` is known to have a sufficient length for the update
  /// in `list[1] = 42`.
  bool get isBoundsSafe => flags & FlagBoundsSafe != 0;

  void set isBoundsSafe(bool value) {
    flags = value ? (flags | FlagBoundsSafe) : (flags & ~FlagBoundsSafe);
  }

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) {
    Member? interfaceTarget = this.interfaceTarget;
    if (interfaceTarget != null) {
      if (interfaceTarget is Procedure &&
          context.typeEnvironment
              .isSpecialCasedBinaryOperator(interfaceTarget)) {
        return context.typeEnvironment.getTypeOfSpecialCasedBinaryOperator(
            receiver.getStaticType(context),
            arguments.positional[0].getStaticType(context));
      }
      Class superclass = interfaceTarget.enclosingClass!;
      InterfaceType receiverType =
          receiver.getStaticTypeAsInstanceOf(superclass, context);
      DartType getterType = Substitution.fromInterfaceType(receiverType)
          .substituteType(interfaceTarget.getterType);
      if (getterType is FunctionType) {
        Substitution substitution;
        if (getterType.typeParameters.length == arguments.types.length) {
          substitution = Substitution.fromPairs(
              getterType.typeParameters, arguments.types);
        } else {
          // TODO(johnniwinther): The front end should normalize the type
          //  argument count or create an invalid expression in case of method
          //  invocations with invalid type argument count.
          substitution = Substitution.fromPairs(
              getterType.typeParameters,
              getterType.typeParameters
                  .map((TypeParameter typeParameter) =>
                      typeParameter.defaultType!)
                  .toList());
        }
        return substitution.substituteType(getterType.returnType);
      }
      // The front end currently do not replace a property call `o.foo()`, where
      // `foo` is a field or getter, with a function call on the property,
      // `o.foo.call()`, so we look up the call method explicitly here.
      // TODO(johnniwinther): Remove this when the front end performs the
      // correct replacement.
      if (getterType is InterfaceType) {
        Member? member = context.typeEnvironment
            .getInterfaceMember(getterType.classNode, new Name('call'));
        if (member != null) {
          DartType callType = member.getterType;
          if (callType is FunctionType) {
            return Substitution.fromInterfaceType(getterType)
                .substituteType(callType.returnType);
          }
        }
      }
      return const DynamicType();
    }
    if (name.text == 'call') {
      DartType receiverType = receiver.getStaticType(context);
      if (receiverType is FunctionType) {
        if (receiverType.typeParameters.length != arguments.types.length) {
          return const NeverType.nonNullable();
        }
        return Substitution.fromPairs(
                receiverType.typeParameters, arguments.types)
            .substituteType(receiverType.returnType);
      }
    }
    if (name.text == '==') {
      // We use this special case to simplify generation of '==' checks.
      return context.typeEnvironment.coreTypes.boolRawType(context.nonNullable);
    }
    return const DynamicType();
  }

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitMethodInvocation(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitMethodInvocation(this, arg);

  @override
  void visitChildren(Visitor v) {
    receiver.accept(v);
    interfaceTarget?.acceptReference(v);
    name.accept(v);
    arguments.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    // ignore: unnecessary_null_comparison
    if (receiver != null) {
      receiver = v.transform(receiver);
      receiver.parent = this;
    }
    // ignore: unnecessary_null_comparison
    if (arguments != null) {
      arguments = v.transform(arguments);
      arguments.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    // ignore: unnecessary_null_comparison
    if (receiver != null) {
      receiver = v.transform(receiver);
      receiver.parent = this;
    }
    // ignore: unnecessary_null_comparison
    if (arguments != null) {
      arguments = v.transform(arguments);
      arguments.parent = this;
    }
  }

  @override
  String toString() {
    return "MethodInvocation(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(receiver,
        minimumPrecedence: astToText.Precedence.PRIMARY);
    printer.write('.');
    printer.writeInterfaceMemberName(interfaceTargetReference, name);
    printer.writeArguments(arguments);
  }
}

/// Expression of form `super.foo(x)`.
///
/// The provided arguments might not match the parameters of the target.
class SuperMethodInvocation extends InvocationExpression {
  @override
  Name name;

  @override
  Arguments arguments;

  Reference? interfaceTargetReference;

  SuperMethodInvocation(Name name, Arguments arguments,
      [Procedure? interfaceTarget])
      : this.byReference(
            name,
            arguments,
            // An invocation doesn't refer to the setter.
            getMemberReferenceGetter(interfaceTarget));

  SuperMethodInvocation.byReference(
      this.name, this.arguments, this.interfaceTargetReference) {
    arguments.parent = this;
  }

  Procedure? get interfaceTarget => interfaceTargetReference?.asProcedure;

  void set interfaceTarget(Procedure? target) {
    // An invocation doesn't refer to the setter.
    interfaceTargetReference = getMemberReferenceGetter(target);
  }

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) {
    Procedure? interfaceTarget = this.interfaceTarget;
    if (interfaceTarget == null) return const DynamicType();
    Class superclass = interfaceTarget.enclosingClass!;
    List<DartType>? receiverTypeArguments = context.typeEnvironment
        .getTypeArgumentsAsInstanceOf(context.thisType!, superclass);
    DartType returnType = Substitution.fromPairs(
            superclass.typeParameters, receiverTypeArguments!)
        .substituteType(interfaceTarget.function!.returnType);
    return Substitution.fromPairs(
            interfaceTarget.function!.typeParameters, arguments.types)
        .substituteType(returnType);
  }

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitSuperMethodInvocation(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitSuperMethodInvocation(this, arg);

  @override
  void visitChildren(Visitor v) {
    interfaceTarget?.acceptReference(v);
    name.accept(v);
    arguments.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    // ignore: unnecessary_null_comparison
    if (arguments != null) {
      arguments = v.transform(arguments);
      arguments.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    // ignore: unnecessary_null_comparison
    if (arguments != null) {
      arguments = v.transform(arguments);
      arguments.parent = this;
    }
  }

  @override
  String toString() {
    return "SuperMethodInvocation(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('super.');
    printer.writeInterfaceMemberName(interfaceTargetReference, name);
    printer.writeArguments(arguments);
  }
}

/// Expression of form `foo(x)`, or `const foo(x)` if the target is an
/// external constant factory.
///
/// The provided arguments might not match the parameters of the target.
class StaticInvocation extends InvocationExpression {
  Reference targetReference;

  @override
  Arguments arguments;

  /// True if this is a constant call to an external constant factory.
  bool isConst;

  @override
  Name get name => target.name!;

  StaticInvocation(Procedure target, Arguments arguments, {bool isConst: false})
      : this.byReference(
            // An invocation doesn't refer to the setter.
            getNonNullableMemberReferenceGetter(target),
            arguments,
            isConst: isConst);

  StaticInvocation.byReference(this.targetReference, this.arguments,
      {this.isConst: false}) {
    arguments.parent = this;
  }

  Procedure get target => targetReference.asProcedure;

  void set target(Procedure target) {
    // An invocation doesn't refer to the setter.
    targetReference = getNonNullableMemberReferenceGetter(target);
  }

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) {
    return Substitution.fromPairs(
            target.function!.typeParameters, arguments.types)
        .substituteType(target.function!.returnType);
  }

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitStaticInvocation(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitStaticInvocation(this, arg);

  @override
  void visitChildren(Visitor v) {
    target.acceptReference(v);
    arguments.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    // ignore: unnecessary_null_comparison
    if (arguments != null) {
      arguments = v.transform(arguments);
      arguments.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    // ignore: unnecessary_null_comparison
    if (arguments != null) {
      arguments = v.transform(arguments);
      arguments.parent = this;
    }
  }

  @override
  String toString() {
    return "StaticInvocation(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeMemberName(targetReference);
    printer.writeArguments(arguments);
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

  @override
  Arguments arguments;

  bool isConst;

  @override
  Name get name => target.name!;

  ConstructorInvocation(Constructor target, Arguments arguments,
      {bool isConst: false})
      : this.byReference(
            // A constructor doesn't refer to the setter.
            getNonNullableMemberReferenceGetter(target),
            arguments,
            isConst: isConst);

  ConstructorInvocation.byReference(this.targetReference, this.arguments,
      {this.isConst: false}) {
    arguments.parent = this;
  }

  Constructor get target => targetReference.asConstructor;

  void set target(Constructor target) {
    // A constructor doesn't refer to the setter.
    targetReference = getNonNullableMemberReferenceGetter(target);
  }

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) {
    return arguments.types.isEmpty
        ? context.typeEnvironment.coreTypes
            .rawType(target.enclosingClass, context.nonNullable)
        : new InterfaceType(
            target.enclosingClass, context.nonNullable, arguments.types);
  }

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitConstructorInvocation(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitConstructorInvocation(this, arg);

  @override
  void visitChildren(Visitor v) {
    target.acceptReference(v);
    arguments.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    // ignore: unnecessary_null_comparison
    if (arguments != null) {
      arguments = v.transform(arguments);
      arguments.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    // ignore: unnecessary_null_comparison
    if (arguments != null) {
      arguments = v.transform(arguments);
      arguments.parent = this;
    }
  }

  // TODO(dmitryas): Change the getter into a method that accepts a CoreTypes.
  InterfaceType get constructedType {
    Class enclosingClass = target.enclosingClass;
    // TODO(dmitryas): Get raw type from a CoreTypes object if arguments is
    // empty.
    return arguments.types.isEmpty
        ? new InterfaceType(
            enclosingClass, Nullability.legacy, const <DartType>[])
        : new InterfaceType(
            enclosingClass, Nullability.legacy, arguments.types);
  }

  @override
  String toString() {
    return "ConstructorInvocation(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    if (isConst) {
      printer.write('const ');
    } else {
      printer.write('new ');
    }
    printer.writeClassName(target.enclosingClass.reference);
    printer.writeTypeArguments(arguments.types);
    if (target.name!.text.isNotEmpty) {
      printer.write('.');
      printer.write(target.name!.text);
    }
    printer.writeArguments(arguments, includeTypeArguments: false);
  }
}

/// An explicit type instantiation of a generic function.
class Instantiation extends Expression {
  Expression expression;
  final List<DartType> typeArguments;

  Instantiation(this.expression, this.typeArguments) {
    expression.parent = this;
  }

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) {
    FunctionType type = expression.getStaticType(context) as FunctionType;
    return Substitution.fromPairs(type.typeParameters, typeArguments)
        .substituteType(type.withoutTypeParameters);
  }

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitInstantiation(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitInstantiation(this, arg);

  @override
  void visitChildren(Visitor v) {
    expression.accept(v);
    visitList(typeArguments, v);
  }

  @override
  void transformChildren(Transformer v) {
    // ignore: unnecessary_null_comparison
    if (expression != null) {
      expression = v.transform(expression);
      expression.parent = this;
    }
    v.transformDartTypeList(typeArguments);
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    // ignore: unnecessary_null_comparison
    if (expression != null) {
      expression = v.transform(expression);
      expression.parent = this;
    }
    v.transformDartTypeList(typeArguments);
  }

  @override
  String toString() {
    return "Instantiation(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(expression);
    printer.writeTypeArguments(typeArguments);
  }
}

/// Expression of form `!x`.
///
/// The `is!` and `!=` operators are desugared into [Not] nodes with `is` and
/// `==` expressions inside, respectively.
class Not extends Expression {
  Expression operand;

  Not(this.operand) {
    operand.parent = this;
  }

  @override
  DartType getStaticType(StaticTypeContext context) =>
      getStaticTypeInternal(context);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) =>
      context.typeEnvironment.coreTypes.boolRawType(context.nonNullable);

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitNot(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) => v.visitNot(this, arg);

  @override
  void visitChildren(Visitor v) {
    operand.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    // ignore: unnecessary_null_comparison
    if (operand != null) {
      operand = v.transform(operand);
      operand.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    // ignore: unnecessary_null_comparison
    if (operand != null) {
      operand = v.transform(operand);
      operand.parent = this;
    }
  }

  @override
  String toString() {
    return "Not(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('!');
    printer.writeExpression(operand,
        minimumPrecedence: astToText.Precedence.PREFIX);
  }
}

enum LogicalExpressionOperator { AND, OR }

String logicalExpressionOperatorToString(LogicalExpressionOperator operator) {
  switch (operator) {
    case LogicalExpressionOperator.AND:
      return "&&";
    case LogicalExpressionOperator.OR:
      return "||";
  }
}

/// Expression of form `x && y` or `x || y`
class LogicalExpression extends Expression {
  Expression left;
  LogicalExpressionOperator operatorEnum; // AND (&&) or OR (||).
  Expression right;

  LogicalExpression(this.left, this.operatorEnum, this.right) {
    left.parent = this;
    right.parent = this;
  }

  @override
  DartType getStaticType(StaticTypeContext context) =>
      getStaticTypeInternal(context);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) =>
      context.typeEnvironment.coreTypes.boolRawType(context.nonNullable);

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitLogicalExpression(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitLogicalExpression(this, arg);

  @override
  void visitChildren(Visitor v) {
    left.accept(v);
    right.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    // ignore: unnecessary_null_comparison
    if (left != null) {
      left = v.transform(left);
      left.parent = this;
    }
    // ignore: unnecessary_null_comparison
    if (right != null) {
      right = v.transform(right);
      right.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    // ignore: unnecessary_null_comparison
    if (left != null) {
      left = v.transform(left);
      left.parent = this;
    }
    // ignore: unnecessary_null_comparison
    if (right != null) {
      right = v.transform(right);
      right.parent = this;
    }
  }

  @override
  String toString() {
    return "LogicalExpression(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    int minimumPrecedence = precedence;
    printer.writeExpression(left, minimumPrecedence: minimumPrecedence);
    printer.write(' ${logicalExpressionOperatorToString(operatorEnum)} ');
    printer.writeExpression(right, minimumPrecedence: minimumPrecedence + 1);
  }
}

/// Expression of form `x ? y : z`.
class ConditionalExpression extends Expression {
  Expression condition;
  Expression then;
  Expression otherwise;

  /// The static type of the expression.
  DartType staticType;

  ConditionalExpression(
      this.condition, this.then, this.otherwise, this.staticType) {
    condition.parent = this;
    then.parent = this;
    otherwise.parent = this;
  }

  @override
  DartType getStaticType(StaticTypeContext context) =>
      getStaticTypeInternal(context);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) => staticType;

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitConditionalExpression(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitConditionalExpression(this, arg);

  @override
  void visitChildren(Visitor v) {
    condition.accept(v);
    then.accept(v);
    otherwise.accept(v);
    staticType.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    // ignore: unnecessary_null_comparison
    if (condition != null) {
      condition = v.transform(condition);
      condition.parent = this;
    }
    // ignore: unnecessary_null_comparison
    if (then != null) {
      then = v.transform(then);
      then.parent = this;
    }
    // ignore: unnecessary_null_comparison
    if (otherwise != null) {
      otherwise = v.transform(otherwise);
      otherwise.parent = this;
    }
    // ignore: unnecessary_null_comparison
    if (staticType != null) {
      staticType = v.visitDartType(staticType);
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    // ignore: unnecessary_null_comparison
    if (condition != null) {
      condition = v.transform(condition);
      condition.parent = this;
    }
    // ignore: unnecessary_null_comparison
    if (then != null) {
      then = v.transform(then);
      then.parent = this;
    }
    // ignore: unnecessary_null_comparison
    if (otherwise != null) {
      otherwise = v.transform(otherwise);
      otherwise.parent = this;
    }
    // ignore: unnecessary_null_comparison
    if (staticType != null) {
      staticType = v.visitDartType(staticType, cannotRemoveSentinel);
    }
  }

  @override
  String toString() {
    return "ConditionalExpression(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(condition,
        minimumPrecedence: astToText.Precedence.LOGICAL_OR);
    printer.write(' ?');
    // ignore: unnecessary_null_comparison
    if (staticType != null) {
      printer.write('{');
      printer.writeType(staticType);
      printer.write('}');
    }
    printer.write(' ');
    printer.writeExpression(then);
    printer.write(' : ');
    printer.writeExpression(otherwise);
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

  @override
  DartType getStaticType(StaticTypeContext context) =>
      getStaticTypeInternal(context);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) =>
      context.typeEnvironment.coreTypes.stringRawType(context.nonNullable);

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitStringConcatenation(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitStringConcatenation(this, arg);

  @override
  void visitChildren(Visitor v) {
    visitList(expressions, v);
  }

  @override
  void transformChildren(Transformer v) {
    v.transformList(expressions, this);
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    v.transformExpressionList(expressions, this);
  }

  @override
  String toString() {
    return "StringConcatenation(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('"');
    for (Expression part in expressions) {
      if (part is StringLiteral) {
        printer.write(escapeString(part.value));
      } else {
        printer.write(r'${');
        printer.writeExpression(part);
        printer.write('}');
      }
    }
    printer.write('"');
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

  @override
  DartType getStaticType(StaticTypeContext context) =>
      getStaticTypeInternal(context);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) {
    return context.typeEnvironment.listType(typeArgument, context.nonNullable);
  }

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitListConcatenation(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitListConcatenation(this, arg);

  @override
  void visitChildren(Visitor v) {
    typeArgument.accept(v);
    visitList(lists, v);
  }

  @override
  void transformChildren(Transformer v) {
    typeArgument = v.visitDartType(typeArgument);
    v.transformList(lists, this);
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    typeArgument = v.visitDartType(typeArgument, cannotRemoveSentinel);
    v.transformExpressionList(lists, this);
  }

  @override
  String toString() {
    return "ListConcatenation(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    bool first = true;
    for (Expression part in lists) {
      if (!first) {
        printer.write(' + ');
      }
      printer.writeExpression(part);
      first = false;
    }
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

  @override
  DartType getStaticType(StaticTypeContext context) =>
      getStaticTypeInternal(context);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) {
    return context.typeEnvironment.setType(typeArgument, context.nonNullable);
  }

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitSetConcatenation(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitSetConcatenation(this, arg);

  @override
  void visitChildren(Visitor v) {
    typeArgument.accept(v);
    visitList(sets, v);
  }

  @override
  void transformChildren(Transformer v) {
    typeArgument = v.visitDartType(typeArgument);
    v.transformList(sets, this);
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    typeArgument = v.visitDartType(typeArgument, cannotRemoveSentinel);
    v.transformExpressionList(sets, this);
  }

  @override
  String toString() {
    return "SetConcatenation(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    bool first = true;
    for (Expression part in sets) {
      if (!first) {
        printer.write(' + ');
      }
      printer.writeExpression(part);
      first = false;
    }
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

  @override
  DartType getStaticType(StaticTypeContext context) =>
      getStaticTypeInternal(context);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) {
    return context.typeEnvironment
        .mapType(keyType, valueType, context.nonNullable);
  }

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitMapConcatenation(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitMapConcatenation(this, arg);

  @override
  void visitChildren(Visitor v) {
    keyType.accept(v);
    valueType.accept(v);
    visitList(maps, v);
  }

  @override
  void transformChildren(Transformer v) {
    keyType = v.visitDartType(keyType);
    valueType = v.visitDartType(valueType);
    v.transformList(maps, this);
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    keyType = v.visitDartType(keyType, cannotRemoveSentinel);
    valueType = v.visitDartType(valueType, cannotRemoveSentinel);
    v.transformExpressionList(maps, this);
  }

  @override
  String toString() {
    return "MapConcatenation(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    bool first = true;
    for (Expression part in maps) {
      if (!first) {
        printer.write(' + ');
      }
      printer.writeExpression(part);
      first = false;
    }
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
      this.asserts, this.unusedArguments) {
    setParents(fieldValues.values.toList(), this);
    setParents(asserts, this);
    setParents(unusedArguments, this);
  }

  Class get classNode => classReference.asClass;

  @override
  DartType getStaticType(StaticTypeContext context) =>
      getStaticTypeInternal(context);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) {
    return typeArguments.isEmpty
        ? context.typeEnvironment.coreTypes
            .rawType(classNode, context.nonNullable)
        : new InterfaceType(classNode, context.nonNullable, typeArguments);
  }

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitInstanceCreation(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitInstanceCreation(this, arg);

  @override
  void visitChildren(Visitor v) {
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

  @override
  void transformChildren(Transformer v) {
    fieldValues.forEach((Reference fieldRef, Expression value) {
      Expression transformed = v.transform(value);
      // ignore: unnecessary_null_comparison
      if (transformed != null && !identical(value, transformed)) {
        fieldValues[fieldRef] = transformed;
        transformed.parent = this;
      }
    });
    v.transformList(asserts, this);
    v.transformList(unusedArguments, this);
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    fieldValues.forEach((Reference fieldRef, Expression value) {
      Expression transformed = v.transform(value);
      if (!identical(value, transformed)) {
        fieldValues[fieldRef] = transformed;
        transformed.parent = this;
      }
    });
    v.transformList(asserts, this, dummyAssertStatement);
    v.transformExpressionList(unusedArguments, this);
  }

  @override
  String toString() {
    return "InstanceCreation(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeClassName(classReference);
    printer.writeTypeArguments(typeArguments);
    printer.write('{');
    bool first = true;
    fieldValues.forEach((Reference fieldRef, Expression value) {
      if (!first) {
        printer.write(', ');
      }
      printer.writeName(fieldRef.asField.name);
      printer.write(': ');
      printer.writeExpression(value);
      first = false;
    });
    for (AssertStatement assert_ in asserts) {
      if (!first) {
        printer.write(', ');
      }
      printer.write('assert(');
      printer.writeExpression(assert_.condition);
      if (assert_.message != null) {
        printer.write(', ');
        printer.writeExpression(assert_.message!);
      }
      printer.write(')');
      first = false;
    }
    for (Expression unusedArgument in unusedArguments) {
      if (!first) {
        printer.write(', ');
      }
      printer.writeExpression(unusedArgument);
      first = false;
    }
    printer.write('}');
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

  @override
  DartType getStaticType(StaticTypeContext context) =>
      getStaticTypeInternal(context);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) =>
      expression.getStaticType(context);

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitFileUriExpression(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitFileUriExpression(this, arg);

  @override
  void visitChildren(Visitor v) {
    expression.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    expression = v.transform(expression)..parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    expression = v.transform(expression)..parent = this;
  }

  @override
  Location? _getLocationInEnclosingFile(int offset) {
    return _getLocationInComponent(enclosingComponent, fileUri, offset);
  }

  @override
  String toString() {
    return "FileUriExpression(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    if (printer.includeAuxiliaryProperties) {
      printer.write('{');
      printer.write(fileUri.toString());
      printer.write('}');
    }
    printer.writeExpression(expression);
  }
}

/// Expression of form `x is T`.
class IsExpression extends Expression {
  int flags = 0;
  Expression operand;
  DartType type;

  IsExpression(this.operand, this.type) {
    operand.parent = this;
  }

  // Must match serialized bit positions.
  static const int FlagForNonNullableByDefault = 1 << 0;

  /// If `true`, this test take the nullability of [type] into account.
  ///
  /// This is the case for is-tests written in libraries that are opted in to
  /// the non nullable by default feature.
  bool get isForNonNullableByDefault =>
      flags & FlagForNonNullableByDefault != 0;

  void set isForNonNullableByDefault(bool value) {
    flags = value
        ? (flags | FlagForNonNullableByDefault)
        : (flags & ~FlagForNonNullableByDefault);
  }

  DartType getStaticType(StaticTypeContext context) =>
      getStaticTypeInternal(context);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) =>
      context.typeEnvironment.coreTypes.boolRawType(context.nonNullable);

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitIsExpression(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitIsExpression(this, arg);

  @override
  void visitChildren(Visitor v) {
    operand.accept(v);
    type.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    // ignore: unnecessary_null_comparison
    if (operand != null) {
      operand = v.transform(operand);
      operand.parent = this;
    }
    type = v.visitDartType(type);
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    // ignore: unnecessary_null_comparison
    if (operand != null) {
      operand = v.transform(operand);
      operand.parent = this;
    }
    type = v.visitDartType(type, cannotRemoveSentinel);
  }

  @override
  String toString() {
    return "IsExpression(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(operand,
        minimumPrecedence: astToText.Precedence.BITWISE_OR);
    printer.write(' is');
    if (printer.includeAuxiliaryProperties && isForNonNullableByDefault) {
      printer.write('{ForNonNullableByDefault}');
    }
    printer.write(' ');
    printer.writeType(type);
  }
}

/// Expression of form `x as T`.
class AsExpression extends Expression {
  int flags = 0;
  Expression operand;
  DartType type;

  AsExpression(this.operand, this.type) {
    operand.parent = this;
  }

  // Must match serialized bit positions.
  static const int FlagTypeError = 1 << 0;
  static const int FlagCovarianceCheck = 1 << 1;
  static const int FlagForDynamic = 1 << 2;
  static const int FlagForNonNullableByDefault = 1 << 3;

  /// If `true`, this test is an implicit down cast.
  ///
  /// If `true` a TypeError should be thrown. If `false` a CastError should be
  /// thrown.
  bool get isTypeError => flags & FlagTypeError != 0;

  void set isTypeError(bool value) {
    flags = value ? (flags | FlagTypeError) : (flags & ~FlagTypeError);
  }

  /// If `true`, this test is needed to ensure soundness of covariant type
  /// variables using in contravariant positions.
  ///
  /// For instance
  ///
  ///    class Class<T> {
  ///      void Function(T) field;
  ///      Class(this.field);
  ///    }
  ///    main() {
  ///      Class<num> c = new Class<int>((int i) {});
  ///      void Function<num> field = c.field; // Check needed on `c.field`
  ///      field(0.5);
  ///    }
  ///
  /// Here a covariant check `c.field as void Function(num)` is needed because
  /// the field could be (and indeed is) not a subtype of the static type of
  /// the expression.
  bool get isCovarianceCheck => flags & FlagCovarianceCheck != 0;

  void set isCovarianceCheck(bool value) {
    flags =
        value ? (flags | FlagCovarianceCheck) : (flags & ~FlagCovarianceCheck);
  }

  /// If `true`, this is an implicit down cast from an expression of type
  /// `dynamic`.
  bool get isForDynamic => flags & FlagForDynamic != 0;

  void set isForDynamic(bool value) {
    flags = value ? (flags | FlagForDynamic) : (flags & ~FlagForDynamic);
  }

  /// If `true`, this test take the nullability of [type] into account.
  ///
  /// This is the case for is-tests written in libraries that are opted in to
  /// the non nullable by default feature.
  bool get isForNonNullableByDefault =>
      flags & FlagForNonNullableByDefault != 0;

  void set isForNonNullableByDefault(bool value) {
    flags = value
        ? (flags | FlagForNonNullableByDefault)
        : (flags & ~FlagForNonNullableByDefault);
  }

  @override
  DartType getStaticType(StaticTypeContext context) =>
      getStaticTypeInternal(context);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) => type;

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitAsExpression(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitAsExpression(this, arg);

  @override
  void visitChildren(Visitor v) {
    operand.accept(v);
    type.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    // ignore: unnecessary_null_comparison
    if (operand != null) {
      operand = v.transform(operand);
      operand.parent = this;
    }
    type = v.visitDartType(type);
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    // ignore: unnecessary_null_comparison
    if (operand != null) {
      operand = v.transform(operand);
      operand.parent = this;
    }
    type = v.visitDartType(type, cannotRemoveSentinel);
  }

  @override
  String toString() {
    return "AsExpression(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(operand,
        minimumPrecedence: astToText.Precedence.BITWISE_OR);
    printer.write(' as');
    if (printer.includeAuxiliaryProperties) {
      List<String> flags = <String>[];
      if (isTypeError) {
        flags.add('TypeError');
      }
      if (isCovarianceCheck) {
        flags.add('CovarianceCheck');
      }
      if (isForDynamic) {
        flags.add('ForDynamic');
      }
      if (isForNonNullableByDefault) {
        flags.add('ForNonNullableByDefault');
      }
      if (flags.isNotEmpty) {
        printer.write('{${flags.join(',')}}');
      }
    }
    printer.write(' ');
    printer.writeType(type);
  }
}

/// Null check expression of form `x!`.
///
/// This expression was added as part of NNBD and is currently only created when
/// the 'non-nullable' experimental feature is enabled.
class NullCheck extends Expression {
  Expression operand;

  NullCheck(this.operand) {
    operand.parent = this;
  }

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) {
    DartType operandType = operand.getStaticType(context);
    return operandType is NullType
        ? const NeverType.nonNullable()
        : operandType.withDeclaredNullability(Nullability.nonNullable);
  }

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitNullCheck(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitNullCheck(this, arg);

  @override
  void visitChildren(Visitor v) {
    operand.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    // ignore: unnecessary_null_comparison
    if (operand != null) {
      operand = v.transform(operand);
      operand.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    // ignore: unnecessary_null_comparison
    if (operand != null) {
      operand = v.transform(operand);
      operand.parent = this;
    }
  }

  @override
  String toString() {
    return "NullCheck(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(operand,
        minimumPrecedence: astToText.Precedence.POSTFIX);
    printer.write('!');
  }
}

/// An integer, double, boolean, string, or null constant.
abstract class BasicLiteral extends Expression {
  Object? get value;

  @override
  void visitChildren(Visitor v) {}

  @override
  void transformChildren(Transformer v) {}

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {}
}

class StringLiteral extends BasicLiteral {
  @override
  String value;

  StringLiteral(this.value);

  @override
  DartType getStaticType(StaticTypeContext context) =>
      getStaticTypeInternal(context);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) =>
      context.typeEnvironment.coreTypes.stringRawType(context.nonNullable);

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitStringLiteral(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitStringLiteral(this, arg);

  @override
  String toString() {
    return "StringLiteral(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('"');
    printer.write(escapeString(value));
    printer.write('"');
  }
}

class IntLiteral extends BasicLiteral {
  /// Note that this value holds a uint64 value.
  /// E.g. "0x8000000000000000" will be saved as "-9223372036854775808" despite
  /// technically (on some platforms, particularly Javascript) being positive.
  /// If the number is meant to be negative it will be wrapped in a "unary-".
  @override
  int value;

  IntLiteral(this.value);

  @override
  DartType getStaticType(StaticTypeContext context) =>
      getStaticTypeInternal(context);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) =>
      context.typeEnvironment.coreTypes.intRawType(context.nonNullable);

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitIntLiteral(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitIntLiteral(this, arg);

  @override
  String toString() {
    return "IntLiteral(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('$value');
  }
}

class DoubleLiteral extends BasicLiteral {
  @override
  double value;

  DoubleLiteral(this.value);

  @override
  DartType getStaticType(StaticTypeContext context) =>
      getStaticTypeInternal(context);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) =>
      context.typeEnvironment.coreTypes.doubleRawType(context.nonNullable);

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitDoubleLiteral(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitDoubleLiteral(this, arg);

  @override
  String toString() {
    return "DoubleLiteral(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('$value');
  }
}

class BoolLiteral extends BasicLiteral {
  @override
  bool value;

  BoolLiteral(this.value);

  @override
  DartType getStaticType(StaticTypeContext context) =>
      getStaticTypeInternal(context);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) =>
      context.typeEnvironment.coreTypes.boolRawType(context.nonNullable);

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitBoolLiteral(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitBoolLiteral(this, arg);

  @override
  String toString() {
    return "BoolLiteral(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('$value');
  }
}

class NullLiteral extends BasicLiteral {
  @override
  Object? get value => null;

  DartType getStaticType(StaticTypeContext context) =>
      getStaticTypeInternal(context);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) => const NullType();

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitNullLiteral(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitNullLiteral(this, arg);

  @override
  String toString() {
    return "NullLiteral(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('null');
  }
}

class SymbolLiteral extends Expression {
  String value; // Everything strictly after the '#'.

  SymbolLiteral(this.value);

  @override
  DartType getStaticType(StaticTypeContext context) =>
      getStaticTypeInternal(context);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) =>
      context.typeEnvironment.coreTypes.symbolRawType(context.nonNullable);

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitSymbolLiteral(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitSymbolLiteral(this, arg);

  @override
  void visitChildren(Visitor v) {}

  @override
  void transformChildren(Transformer v) {}

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {}

  @override
  String toString() {
    return "SymbolLiteral(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('#');
    printer.write(value);
  }
}

class TypeLiteral extends Expression {
  DartType type;

  TypeLiteral(this.type);

  @override
  DartType getStaticType(StaticTypeContext context) =>
      getStaticTypeInternal(context);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) =>
      context.typeEnvironment.coreTypes.typeRawType(context.nonNullable);

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitTypeLiteral(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitTypeLiteral(this, arg);

  @override
  void visitChildren(Visitor v) {
    type.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    type = v.visitDartType(type);
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    type = v.visitDartType(type, cannotRemoveSentinel);
  }

  @override
  String toString() {
    return "TypeLiteral(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeType(type);
  }
}

class ThisExpression extends Expression {
  DartType getStaticType(StaticTypeContext context) =>
      getStaticTypeInternal(context);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) =>
      context.thisType!;

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitThisExpression(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitThisExpression(this, arg);

  @override
  void visitChildren(Visitor v) {}

  @override
  void transformChildren(Transformer v) {}

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {}

  @override
  String toString() {
    return "ThisExpression(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('this');
  }
}

class Rethrow extends Expression {
  @override
  DartType getStaticType(StaticTypeContext context) =>
      getStaticTypeInternal(context);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) =>
      context.isNonNullableByDefault
          ? const NeverType.nonNullable()
          : const NeverType.legacy();

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitRethrow(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitRethrow(this, arg);

  @override
  void visitChildren(Visitor v) {}

  @override
  void transformChildren(Transformer v) {}

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {}

  @override
  String toString() {
    return "Rethrow(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('rethrow');
  }
}

class Throw extends Expression {
  Expression expression;

  Throw(this.expression) {
    expression.parent = this;
  }

  @override
  DartType getStaticType(StaticTypeContext context) =>
      getStaticTypeInternal(context);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) =>
      context.isNonNullableByDefault
          ? const NeverType.nonNullable()
          : const NeverType.legacy();

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitThrow(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) => v.visitThrow(this, arg);

  @override
  void visitChildren(Visitor v) {
    expression.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    // ignore: unnecessary_null_comparison
    if (expression != null) {
      expression = v.transform(expression);
      expression.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    // ignore: unnecessary_null_comparison
    if (expression != null) {
      expression = v.transform(expression);
      expression.parent = this;
    }
  }

  @override
  String toString() {
    return "Throw(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('throw ');
    printer.writeExpression(expression);
  }
}

class ListLiteral extends Expression {
  bool isConst;
  DartType typeArgument; // Not null, defaults to DynamicType.
  final List<Expression> expressions;

  ListLiteral(this.expressions,
      {this.typeArgument: const DynamicType(), this.isConst: false}) {
    // ignore: unnecessary_null_comparison
    assert(typeArgument != null);
    setParents(expressions, this);
  }

  @override
  DartType getStaticType(StaticTypeContext context) =>
      getStaticTypeInternal(context);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) {
    return context.typeEnvironment.listType(typeArgument, context.nonNullable);
  }

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitListLiteral(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitListLiteral(this, arg);

  @override
  void visitChildren(Visitor v) {
    typeArgument.accept(v);
    visitList(expressions, v);
  }

  @override
  void transformChildren(Transformer v) {
    typeArgument = v.visitDartType(typeArgument);
    v.transformList(expressions, this);
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    typeArgument = v.visitDartType(typeArgument, cannotRemoveSentinel);
    v.transformExpressionList(expressions, this);
  }

  @override
  String toString() {
    return "ListLiteral(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    if (isConst) {
      printer.write('const ');
    }
    printer.write('<');
    printer.writeType(typeArgument);
    printer.write('>[');
    printer.writeExpressions(expressions);
    printer.write(']');
  }
}

class SetLiteral extends Expression {
  bool isConst;
  DartType typeArgument; // Not null, defaults to DynamicType.
  final List<Expression> expressions;

  SetLiteral(this.expressions,
      {this.typeArgument: const DynamicType(), this.isConst: false}) {
    // ignore: unnecessary_null_comparison
    assert(typeArgument != null);
    setParents(expressions, this);
  }

  @override
  DartType getStaticType(StaticTypeContext context) =>
      getStaticTypeInternal(context);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) {
    return context.typeEnvironment.setType(typeArgument, context.nonNullable);
  }

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitSetLiteral(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitSetLiteral(this, arg);

  @override
  void visitChildren(Visitor v) {
    typeArgument.accept(v);
    visitList(expressions, v);
  }

  @override
  void transformChildren(Transformer v) {
    typeArgument = v.visitDartType(typeArgument);
    v.transformList(expressions, this);
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    typeArgument = v.visitDartType(typeArgument, cannotRemoveSentinel);
    v.transformExpressionList(expressions, this);
  }

  @override
  String toString() {
    return "SetLiteral(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    if (isConst) {
      printer.write('const ');
    }
    printer.write('<');
    printer.writeType(typeArgument);
    printer.write('>{');
    printer.writeExpressions(expressions);
    printer.write('}');
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
    // ignore: unnecessary_null_comparison
    assert(keyType != null);
    // ignore: unnecessary_null_comparison
    assert(valueType != null);
    setParents(entries, this);
  }

  @override
  DartType getStaticType(StaticTypeContext context) =>
      getStaticTypeInternal(context);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) {
    return context.typeEnvironment
        .mapType(keyType, valueType, context.nonNullable);
  }

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitMapLiteral(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitMapLiteral(this, arg);

  @override
  void visitChildren(Visitor v) {
    keyType.accept(v);
    valueType.accept(v);
    visitList(entries, v);
  }

  @override
  void transformChildren(Transformer v) {
    keyType = v.visitDartType(keyType);
    valueType = v.visitDartType(valueType);
    v.transformList(entries, this);
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    keyType = v.visitDartType(keyType, cannotRemoveSentinel);
    valueType = v.visitDartType(valueType, cannotRemoveSentinel);
    v.transformMapEntryList(entries, this);
  }

  @override
  String toString() {
    return "MapLiteral(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    if (isConst) {
      printer.write('const ');
    }
    printer.write('<');
    printer.writeType(keyType);
    printer.write(', ');
    printer.writeType(valueType);
    printer.write('>{');
    for (int index = 0; index < entries.length; index++) {
      if (index > 0) {
        printer.write(', ');
      }
      printer.writeMapEntry(entries[index]);
    }
    printer.write('}');
  }
}

class MapEntry extends TreeNode {
  Expression key;
  Expression value;

  MapEntry(this.key, this.value) {
    key.parent = this;
    value.parent = this;
  }

  @override
  R accept<R>(TreeVisitor<R> v) => v.visitMapEntry(this);

  @override
  R accept1<R, A>(TreeVisitor1<R, A> v, A arg) => v.visitMapEntry(this, arg);

  @override
  void visitChildren(Visitor v) {
    key.accept(v);
    value.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    // ignore: unnecessary_null_comparison
    if (key != null) {
      key = v.transform(key);
      key.parent = this;
    }
    // ignore: unnecessary_null_comparison
    if (value != null) {
      value = v.transform(value);
      value.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    // ignore: unnecessary_null_comparison
    if (key != null) {
      key = v.transform(key);
      key.parent = this;
    }
    // ignore: unnecessary_null_comparison
    if (value != null) {
      value = v.transform(value);
      value.parent = this;
    }
  }

  @override
  String toString() {
    return "MapEntry(${toStringInternal()})";
  }

  String toText(AstTextStrategy strategy) {
    AstPrinter printer = new AstPrinter(strategy);
    toTextInternal(printer);
    return printer.getText();
  }

  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(key);
    printer.write(': ');
    printer.writeExpression(value);
  }
}

/// Expression of form `await x`.
class AwaitExpression extends Expression {
  Expression operand;

  AwaitExpression(this.operand) {
    operand.parent = this;
  }

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) {
    return context.typeEnvironment.flatten(operand.getStaticType(context));
  }

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitAwaitExpression(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitAwaitExpression(this, arg);

  @override
  void visitChildren(Visitor v) {
    operand.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    // ignore: unnecessary_null_comparison
    if (operand != null) {
      operand = v.transform(operand);
      operand.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    // ignore: unnecessary_null_comparison
    if (operand != null) {
      operand = v.transform(operand);
      operand.parent = this;
    }
  }

  @override
  String toString() {
    return "AwaitExpression(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('await ');
    printer.writeExpression(operand);
  }
}

/// Common super-interface for [FunctionExpression] and [FunctionDeclaration].
abstract class LocalFunction implements TreeNode {
  // TODO(johnniwinther): Make this non-nullable.
  FunctionNode? get function;
}

/// Expression of form `(x,y) => ...` or `(x,y) { ... }`
///
/// The arrow-body form `=> e` is desugared into `return e;`.
class FunctionExpression extends Expression implements LocalFunction {
  @override
  FunctionNode function;

  FunctionExpression(this.function) {
    function.parent = this;
  }

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) {
    return function.computeFunctionType(context.nonNullable);
  }

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitFunctionExpression(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitFunctionExpression(this, arg);

  @override
  void visitChildren(Visitor v) {
    function.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    // ignore: unnecessary_null_comparison
    if (function != null) {
      function = v.transform(function);
      function.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    // ignore: unnecessary_null_comparison
    if (function != null) {
      function = v.transform(function);
      function.parent = this;
    }
  }

  @override
  String toString() {
    return "FunctionExpression(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeFunctionNode(function, '');
  }
}

class ConstantExpression extends Expression {
  Constant constant;
  DartType type;

  ConstantExpression(this.constant, [this.type = const DynamicType()]) {
    // ignore: unnecessary_null_comparison
    assert(constant != null);
  }

  @override
  DartType getStaticType(StaticTypeContext context) =>
      getStaticTypeInternal(context);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) => type;

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitConstantExpression(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitConstantExpression(this, arg);

  @override
  void visitChildren(Visitor v) {
    constant.acceptReference(v);
    type.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    constant = v.visitConstant(constant);
    type = v.visitDartType(type);
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    constant = v.visitConstant(constant, cannotRemoveSentinel);
    type = v.visitDartType(type, cannotRemoveSentinel);
  }

  @override
  String toString() {
    return "ConstantExpression(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeConstant(constant);
  }
}

/// Synthetic expression of form `let v = x in y`
class Let extends Expression {
  VariableDeclaration variable; // Must have an initializer.
  Expression body;

  Let(this.variable, this.body) {
    variable.parent = this;
    body.parent = this;
  }

  @override
  DartType getStaticType(StaticTypeContext context) =>
      getStaticTypeInternal(context);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) =>
      body.getStaticType(context);

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitLet(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) => v.visitLet(this, arg);

  @override
  void visitChildren(Visitor v) {
    variable.accept(v);
    body.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    // ignore: unnecessary_null_comparison
    if (variable != null) {
      variable = v.transform(variable);
      variable.parent = this;
    }
    // ignore: unnecessary_null_comparison
    if (body != null) {
      body = v.transform(body);
      body.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    // ignore: unnecessary_null_comparison
    if (variable != null) {
      variable = v.transform(variable);
      variable.parent = this;
    }
    // ignore: unnecessary_null_comparison
    if (body != null) {
      body = v.transform(body);
      body.parent = this;
    }
  }

  @override
  String toString() {
    return "Let(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('let ');
    printer.writeVariableDeclaration(variable);
    printer.write(' in ');
    printer.writeExpression(body);
  }
}

class BlockExpression extends Expression {
  Block body;
  Expression value;

  BlockExpression(this.body, this.value) {
    body.parent = this;
    value.parent = this;
  }

  @override
  DartType getStaticType(StaticTypeContext context) =>
      getStaticTypeInternal(context);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) =>
      value.getStaticType(context);

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitBlockExpression(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitBlockExpression(this, arg);

  @override
  void visitChildren(Visitor v) {
    body.accept(v);
    value.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    // ignore: unnecessary_null_comparison
    if (body != null) {
      body = v.transform(body);
      body.parent = this;
    }
    // ignore: unnecessary_null_comparison
    if (value != null) {
      value = v.transform(value);
      value.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    // ignore: unnecessary_null_comparison
    if (body != null) {
      body = v.transform(body);
      body.parent = this;
    }
    // ignore: unnecessary_null_comparison
    if (value != null) {
      value = v.transform(value);
      value.parent = this;
    }
  }

  @override
  String toString() {
    return "BlockExpression(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('block ');
    printer.writeBlock(body.statements);
    printer.write(' => ');
    printer.writeExpression(value);
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

  @override
  DartType getStaticType(StaticTypeContext context) =>
      getStaticTypeInternal(context);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) {
    return context.typeEnvironment
        .futureType(const DynamicType(), context.nonNullable);
  }

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitLoadLibrary(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitLoadLibrary(this, arg);

  @override
  void visitChildren(Visitor v) {}

  @override
  void transformChildren(Transformer v) {}

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {}

  @override
  String toString() {
    return "LoadLibrary(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write(import.name!);
    printer.write('.loadLibrary()');
  }
}

/// Checks that the given deferred import has been marked as 'loaded'.
class CheckLibraryIsLoaded extends Expression {
  /// Reference to a deferred import in the enclosing library.
  LibraryDependency import;

  CheckLibraryIsLoaded(this.import);

  @override
  DartType getStaticType(StaticTypeContext context) =>
      getStaticTypeInternal(context);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) {
    return context.typeEnvironment.coreTypes.objectRawType(context.nonNullable);
  }

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitCheckLibraryIsLoaded(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitCheckLibraryIsLoaded(this, arg);

  @override
  void visitChildren(Visitor v) {}

  @override
  void transformChildren(Transformer v) {}

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {}

  @override
  String toString() {
    return "CheckLibraryIsLoaded(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write(import.name!);
    printer.write('.checkLibraryIsLoaded()');
  }
}

// ------------------------------------------------------------------------
//                              STATEMENTS
// ------------------------------------------------------------------------

abstract class Statement extends TreeNode {
  @override
  R accept<R>(StatementVisitor<R> v);

  @override
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg);

  @override
  String toText(AstTextStrategy strategy) {
    AstPrinter printer = new AstPrinter(strategy);
    printer.writeStatement(this);
    return printer.getText();
  }
}

class ExpressionStatement extends Statement {
  Expression expression;

  ExpressionStatement(this.expression) {
    expression.parent = this;
  }

  @override
  R accept<R>(StatementVisitor<R> v) => v.visitExpressionStatement(this);

  @override
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg) =>
      v.visitExpressionStatement(this, arg);

  @override
  void visitChildren(Visitor v) {
    expression.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    // ignore: unnecessary_null_comparison
    if (expression != null) {
      expression = v.transform(expression);
      expression.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    // ignore: unnecessary_null_comparison
    if (expression != null) {
      expression = v.transform(expression);
      expression.parent = this;
    }
  }

  @override
  String toString() {
    return "ExpressionStatement(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(expression);
    printer.write(';');
  }
}

class Block extends Statement {
  final List<Statement> statements;

  /// End offset in the source file it comes from. Valid values are from 0 and
  /// up, or -1 ([TreeNode.noOffset]) if the file end offset is not available
  /// (this is the default if none is specifically set).
  int fileEndOffset = TreeNode.noOffset;

  Block(this.statements) {
    // Ensure statements is mutable.
    assert(checkListIsMutable(statements, dummyStatement));
    setParents(statements, this);
  }

  @override
  R accept<R>(StatementVisitor<R> v) => v.visitBlock(this);

  @override
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg) => v.visitBlock(this, arg);

  @override
  void visitChildren(Visitor v) {
    visitList(statements, v);
  }

  @override
  void transformChildren(Transformer v) {
    v.transformList(statements, this);
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    v.transformStatementList(statements, this);
  }

  void addStatement(Statement node) {
    statements.add(node);
    node.parent = this;
  }

  @override
  String toString() {
    return "Block(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeBlock(statements);
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
    assert(checkListIsMutable(statements, dummyStatement));
    setParents(statements, this);
  }

  @override
  R accept<R>(StatementVisitor<R> v) => v.visitAssertBlock(this);

  @override
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg) =>
      v.visitAssertBlock(this, arg);

  @override
  void transformChildren(Transformer v) {
    v.transformList(statements, this);
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    v.transformStatementList(statements, this);
  }

  @override
  void visitChildren(Visitor v) {
    visitList(statements, v);
  }

  void addStatement(Statement node) {
    statements.add(node);
    node.parent = this;
  }

  @override
  String toString() {
    return "AssertBlock(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('assert ');
    printer.writeBlock(statements);
  }
}

class EmptyStatement extends Statement {
  @override
  R accept<R>(StatementVisitor<R> v) => v.visitEmptyStatement(this);

  @override
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg) =>
      v.visitEmptyStatement(this, arg);

  @override
  void visitChildren(Visitor v) {}

  @override
  void transformChildren(Transformer v) {}

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {}

  @override
  String toString() {
    return "EmptyStatement(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write(';');
  }
}

class AssertStatement extends Statement {
  Expression condition;
  Expression? message; // May be null.

  /// Character offset in the source where the assertion condition begins.
  ///
  /// Note: This is not the offset into the UTF8 encoded `List<int>` source.
  int conditionStartOffset;

  /// Character offset in the source where the assertion condition ends.
  ///
  /// Note: This is not the offset into the UTF8 encoded `List<int>` source.
  int conditionEndOffset;

  AssertStatement(this.condition,
      {this.message,
      required this.conditionStartOffset,
      required this.conditionEndOffset}) {
    condition.parent = this;
    message?.parent = this;
  }

  @override
  R accept<R>(StatementVisitor<R> v) => v.visitAssertStatement(this);

  @override
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg) =>
      v.visitAssertStatement(this, arg);

  @override
  void visitChildren(Visitor v) {
    condition.accept(v);
    message?.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    // ignore: unnecessary_null_comparison
    if (condition != null) {
      condition = v.transform(condition);
      condition.parent = this;
    }
    if (message != null) {
      message = v.transform(message!);
      message?.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    // ignore: unnecessary_null_comparison
    if (condition != null) {
      condition = v.transform(condition);
      condition.parent = this;
    }
    if (message != null) {
      message = v.transformOrRemoveExpression(message!);
      message?.parent = this;
    }
  }

  @override
  String toString() {
    return "AssertStatement(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('assert(');
    printer.writeExpression(condition);
    if (message != null) {
      printer.write(', ');
      printer.writeExpression(message!);
    }
    printer.write(');');
  }
}

/// A target of a [Break] statement.
///
/// The label itself has no name; breaks reference the statement directly.
///
/// The frontend does not generate labeled statements without uses.
class LabeledStatement extends Statement {
  late Statement body;

  LabeledStatement(Statement? body) {
    if (body != null) {
      this.body = body..parent = this;
    }
  }

  @override
  R accept<R>(StatementVisitor<R> v) => v.visitLabeledStatement(this);

  @override
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg) =>
      v.visitLabeledStatement(this, arg);

  @override
  void visitChildren(Visitor v) {
    body.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    // ignore: unnecessary_null_comparison
    if (body != null) {
      body = v.transform(body);
      body.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    // ignore: unnecessary_null_comparison
    if (body != null) {
      body = v.transform(body);
      body.parent = this;
    }
  }

  @override
  String toString() {
    return "LabeledStatement(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write(printer.getLabelName(this));
    printer.write(':');
    printer.newLine();
    printer.writeStatement(body);
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

  @override
  R accept<R>(StatementVisitor<R> v) => v.visitBreakStatement(this);

  @override
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg) =>
      v.visitBreakStatement(this, arg);

  @override
  void visitChildren(Visitor v) {}

  @override
  void transformChildren(Transformer v) {}

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {}

  @override
  String toString() {
    return "BreakStatement(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('break ');
    printer.write(printer.getLabelName(target));
    printer.write(';');
  }
}

class WhileStatement extends Statement {
  Expression condition;
  Statement body;

  WhileStatement(this.condition, this.body) {
    condition.parent = this;
    body.parent = this;
  }

  @override
  R accept<R>(StatementVisitor<R> v) => v.visitWhileStatement(this);

  @override
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg) =>
      v.visitWhileStatement(this, arg);

  @override
  void visitChildren(Visitor v) {
    condition.accept(v);
    body.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    // ignore: unnecessary_null_comparison
    if (condition != null) {
      condition = v.transform(condition);
      condition.parent = this;
    }
    // ignore: unnecessary_null_comparison
    if (body != null) {
      body = v.transform(body);
      body.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    // ignore: unnecessary_null_comparison
    if (condition != null) {
      condition = v.transform(condition);
      condition.parent = this;
    }
    // ignore: unnecessary_null_comparison
    if (body != null) {
      body = v.transform(body);
      body.parent = this;
    }
  }

  @override
  String toString() {
    return "WhileStatement(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('while (');
    printer.writeExpression(condition);
    printer.write(') ');
    printer.writeStatement(body);
  }
}

class DoStatement extends Statement {
  Statement body;
  Expression condition;

  DoStatement(this.body, this.condition) {
    body.parent = this;
    condition.parent = this;
  }

  @override
  R accept<R>(StatementVisitor<R> v) => v.visitDoStatement(this);

  @override
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg) =>
      v.visitDoStatement(this, arg);

  @override
  void visitChildren(Visitor v) {
    body.accept(v);
    condition.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    // ignore: unnecessary_null_comparison
    if (body != null) {
      body = v.transform(body);
      body.parent = this;
    }
    // ignore: unnecessary_null_comparison
    if (condition != null) {
      condition = v.transform(condition);
      condition.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    // ignore: unnecessary_null_comparison
    if (body != null) {
      body = v.transform(body);
      body.parent = this;
    }
    // ignore: unnecessary_null_comparison
    if (condition != null) {
      condition = v.transform(condition);
      condition.parent = this;
    }
  }

  @override
  String toString() {
    return "DoStatement(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('do ');
    printer.writeStatement(body);
    printer.write(' while (');
    printer.writeExpression(condition);
    printer.write(');');
  }
}

class ForStatement extends Statement {
  final List<VariableDeclaration> variables; // May be empty, but not null.
  Expression? condition; // May be null.
  final List<Expression> updates; // May be empty, but not null.
  Statement body;

  ForStatement(this.variables, this.condition, this.updates, this.body) {
    setParents(variables, this);
    condition?.parent = this;
    setParents(updates, this);
    body.parent = this;
  }

  @override
  R accept<R>(StatementVisitor<R> v) => v.visitForStatement(this);

  @override
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg) =>
      v.visitForStatement(this, arg);

  @override
  void visitChildren(Visitor v) {
    visitList(variables, v);
    condition?.accept(v);
    visitList(updates, v);
    body.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    v.transformList(variables, this);
    if (condition != null) {
      condition = v.transform(condition!);
      condition?.parent = this;
    }
    v.transformList(updates, this);
    // ignore: unnecessary_null_comparison
    if (body != null) {
      body = v.transform(body);
      body.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    v.transformVariableDeclarationList(variables, this);
    if (condition != null) {
      condition = v.transformOrRemoveExpression(condition!);
      condition?.parent = this;
    }
    v.transformExpressionList(updates, this);
    // ignore: unnecessary_null_comparison
    if (body != null) {
      body = v.transform(body);
      body.parent = this;
    }
  }

  @override
  String toString() {
    return "ForStatement(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('for (');
    for (int index = 0; index < variables.length; index++) {
      if (index > 0) {
        printer.write(', ');
      }
      printer.writeVariableDeclaration(variables[index],
          includeModifiersAndType: index == 0);
    }
    printer.write('; ');
    if (condition != null) {
      printer.writeExpression(condition!);
    }
    printer.write('; ');
    printer.writeExpressions(updates);
    printer.write(') ');
    printer.writeStatement(body);
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
    variable.parent = this;
    iterable.parent = this;
    body.parent = this;
  }

  @override
  R accept<R>(StatementVisitor<R> v) => v.visitForInStatement(this);

  @override
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg) =>
      v.visitForInStatement(this, arg);

  @override
  void visitChildren(Visitor v) {
    variable.accept(v);
    iterable.accept(v);
    body.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    // ignore: unnecessary_null_comparison
    if (variable != null) {
      variable = v.transform(variable);
      variable.parent = this;
    }
    // ignore: unnecessary_null_comparison
    if (iterable != null) {
      iterable = v.transform(iterable);
      iterable.parent = this;
    }
    // ignore: unnecessary_null_comparison
    if (body != null) {
      body = v.transform(body);
      body.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    // ignore: unnecessary_null_comparison
    if (variable != null) {
      variable = v.transform(variable);
      variable.parent = this;
    }
    // ignore: unnecessary_null_comparison
    if (iterable != null) {
      iterable = v.transform(iterable);
      iterable.parent = this;
    }
    // ignore: unnecessary_null_comparison
    if (body != null) {
      body = v.transform(body);
      body.parent = this;
    }
  }

  /// Returns the type of the iterator in this for-in statement.
  ///
  /// This calls `StaticTypeContext.getForInIteratorType` which calls
  /// [getStaticTypeInternal] to compute the type of not already cached in
  /// [context].
  DartType getIteratorType(StaticTypeContext context) =>
      context.getForInIteratorType(this);

  /// Computes the type of the iterator in this for-in statement.
  ///
  /// This is called by `StaticTypeContext.getForInIteratorType` if the iterator
  /// type of this for-in statement is not already cached in [context].
  DartType getIteratorTypeInternal(StaticTypeContext context) {
    DartType? iteratorType;
    if (isAsync) {
      InterfaceType? streamType = iterable.getStaticTypeAsInstanceOf(
          context.typeEnvironment.coreTypes.streamClass, context);
      // ignore: unnecessary_null_comparison
      if (streamType != null) {
        iteratorType = new InterfaceType(
            context.typeEnvironment.coreTypes.streamIteratorClass,
            context.nonNullable,
            streamType.typeArguments);
      }
    } else {
      InterfaceType iterableType = iterable.getStaticTypeAsInstanceOf(
          context.typeEnvironment.coreTypes.iterableClass, context);
      Member? member = context.typeEnvironment.hierarchy
          .getInterfaceMember(iterableType.classNode, new Name('iterator'));
      if (member != null) {
        iteratorType = Substitution.fromInterfaceType(iterableType)
            .substituteType(member.getterType);
      }
    }
    return iteratorType ?? const DynamicType();
  }

  /// Returns the type of the element in this for-in statement.
  ///
  /// This calls `StaticTypeContext.getForInElementType` which calls
  /// [getStaticTypeInternal] to compute the type of not already cached in
  /// [context].
  DartType getElementType(StaticTypeContext context) =>
      context.getForInElementType(this);

  /// Computes the type of the element in this for-in statement.
  ///
  /// This is called by `StaticTypeContext.getForInElementType` if the element
  /// type of this for-in statement is not already cached in [context].
  DartType getElementTypeInternal(StaticTypeContext context) {
    DartType iterableType = iterable.getStaticType(context);
    // TODO(johnniwinther): Update this to use the type of
    //  `iterable.iterator.current` if inference is updated accordingly.
    while (iterableType is TypeParameterType) {
      TypeParameterType typeParameterType = iterableType;
      iterableType = typeParameterType.bound;
    }
    if (iterableType is NeverType) {
      return iterableType;
    }
    if (iterableType is InvalidType) {
      return iterableType;
    }
    if (iterableType is! InterfaceType) {
      // TODO(johnniwinther): Change this to an assert once the CFE correctly
      // inserts casts for all invalid iterable types.
      return const InvalidType();
    }
    if (isAsync) {
      List<DartType> typeArguments = context.typeEnvironment
          .getTypeArgumentsAsInstanceOf(
              iterableType, context.typeEnvironment.coreTypes.streamClass)!;
      return typeArguments.single;
    } else {
      List<DartType> typeArguments = context.typeEnvironment
          .getTypeArgumentsAsInstanceOf(
              iterableType, context.typeEnvironment.coreTypes.iterableClass)!;
      return typeArguments.single;
    }
  }

  @override
  String toString() {
    return "ForInStatement(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('for (');
    printer.writeVariableDeclaration(variable);

    printer.write(' in ');
    printer.writeExpression(iterable);
    printer.write(') ');
    printer.writeStatement(body);
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
    expression.parent = this;
    setParents(cases, this);
  }

  @override
  R accept<R>(StatementVisitor<R> v) => v.visitSwitchStatement(this);

  @override
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg) =>
      v.visitSwitchStatement(this, arg);

  @override
  void visitChildren(Visitor v) {
    expression.accept(v);
    visitList(cases, v);
  }

  @override
  void transformChildren(Transformer v) {
    // ignore: unnecessary_null_comparison
    if (expression != null) {
      expression = v.transform(expression);
      expression.parent = this;
    }
    v.transformList(cases, this);
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    // ignore: unnecessary_null_comparison
    if (expression != null) {
      expression = v.transform(expression);
      expression.parent = this;
    }
    v.transformSwitchCaseList(cases, this);
  }

  @override
  String toString() {
    return "SwitchStatement(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('switch (');
    printer.writeExpression(expression);
    printer.write(') {');
    printer.incIndentation();
    for (SwitchCase switchCase in cases) {
      printer.newLine();
      printer.writeSwitchCase(switchCase);
    }
    printer.decIndentation();
    printer.newLine();
    printer.write('}');
  }
}

/// A group of `case` clauses and/or a `default` clause.
///
/// This is a potential target of [ContinueSwitchStatement].
class SwitchCase extends TreeNode {
  final List<Expression> expressions;
  final List<int> expressionOffsets;
  late Statement body;
  bool isDefault;

  SwitchCase(this.expressions, this.expressionOffsets, Statement? body,
      {this.isDefault: false}) {
    setParents(expressions, this);
    if (body != null) {
      this.body = body..parent = this;
    }
  }

  SwitchCase.defaultCase(Statement? body)
      : isDefault = true,
        expressions = <Expression>[],
        expressionOffsets = <int>[] {
    if (body != null) {
      this.body = body..parent = this;
    }
  }

  @override
  R accept<R>(TreeVisitor<R> v) => v.visitSwitchCase(this);

  @override
  R accept1<R, A>(TreeVisitor1<R, A> v, A arg) => v.visitSwitchCase(this, arg);

  @override
  void visitChildren(Visitor v) {
    visitList(expressions, v);
    body.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    v.transformList(expressions, this);
    // ignore: unnecessary_null_comparison
    if (body != null) {
      body = v.transform(body);
      body.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    v.transformExpressionList(expressions, this);
    // ignore: unnecessary_null_comparison
    if (body != null) {
      body = v.transform(body);
      body.parent = this;
    }
  }

  @override
  String toString() {
    return "SwitchCase(${toStringInternal()})";
  }

  @override
  String toText(AstTextStrategy strategy) {
    AstPrinter printer = new AstPrinter(strategy);
    toTextInternal(printer);
    return printer.getText();
  }

  @override
  void toTextInternal(AstPrinter printer) {
    for (int index = 0; index < expressions.length; index++) {
      if (index > 0) {
        printer.newLine();
      }
      printer.write('case ');
      printer.writeExpression(expressions[index]);
      printer.write(':');
    }
    if (isDefault) {
      if (expressions.isNotEmpty) {
        printer.newLine();
      }
      printer.write('default:');
    }
    printer.incIndentation();
    Statement? block = body;
    if (block is Block) {
      for (Statement statement in block.statements) {
        printer.newLine();
        printer.writeStatement(statement);
      }
    } else {
      printer.write(' ');
      printer.writeStatement(body);
    }
    printer.decIndentation();
  }
}

/// Jump to a case in an enclosing switch.
class ContinueSwitchStatement extends Statement {
  SwitchCase target;

  ContinueSwitchStatement(this.target);

  @override
  R accept<R>(StatementVisitor<R> v) => v.visitContinueSwitchStatement(this);

  @override
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg) =>
      v.visitContinueSwitchStatement(this, arg);

  @override
  void visitChildren(Visitor v) {}

  @override
  void transformChildren(Transformer v) {}

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {}

  @override
  String toString() {
    return "ContinueSwitchStatement(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('continue ');
    printer.write(printer.getSwitchCaseName(target));
    printer.write(';');
  }
}

class IfStatement extends Statement {
  Expression condition;
  Statement then;
  Statement? otherwise;

  IfStatement(this.condition, this.then, this.otherwise) {
    condition.parent = this;
    then.parent = this;
    otherwise?.parent = this;
  }

  @override
  R accept<R>(StatementVisitor<R> v) => v.visitIfStatement(this);

  @override
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg) =>
      v.visitIfStatement(this, arg);

  @override
  void visitChildren(Visitor v) {
    condition.accept(v);
    then.accept(v);
    otherwise?.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    // ignore: unnecessary_null_comparison
    if (condition != null) {
      condition = v.transform(condition);
      condition.parent = this;
    }
    // ignore: unnecessary_null_comparison
    if (then != null) {
      then = v.transform(then);
      then.parent = this;
    }
    if (otherwise != null) {
      otherwise = v.transform(otherwise!);
      otherwise?.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    // ignore: unnecessary_null_comparison
    if (condition != null) {
      condition = v.transform(condition);
      condition.parent = this;
    }
    // ignore: unnecessary_null_comparison
    if (then != null) {
      then = v.transform(then);
      then.parent = this;
    }
    if (otherwise != null) {
      otherwise = v.transformOrRemoveStatement(otherwise!);
      otherwise?.parent = this;
    }
  }

  @override
  String toString() {
    return "IfStatement(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('if (');
    printer.writeExpression(condition);
    printer.write(') ');
    printer.writeStatement(then);
    if (otherwise != null) {
      printer.write(' else ');
      printer.writeStatement(otherwise!);
    }
  }
}

class ReturnStatement extends Statement {
  Expression? expression; // May be null.

  ReturnStatement([this.expression]) {
    expression?.parent = this;
  }

  @override
  R accept<R>(StatementVisitor<R> v) => v.visitReturnStatement(this);

  @override
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg) =>
      v.visitReturnStatement(this, arg);

  @override
  void visitChildren(Visitor v) {
    expression?.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    if (expression != null) {
      expression = v.transform(expression!);
      expression?.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    if (expression != null) {
      expression = v.transformOrRemoveExpression(expression!);
      expression?.parent = this;
    }
  }

  @override
  String toString() {
    return "ReturnStatement(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('return');
    if (expression != null) {
      printer.write(' ');
      printer.writeExpression(expression!);
    }
    printer.write(';');
  }
}

class TryCatch extends Statement {
  Statement body;
  List<Catch> catches;
  bool isSynthetic;

  TryCatch(this.body, this.catches, {this.isSynthetic: false}) {
    body.parent = this;
    setParents(catches, this);
  }

  @override
  R accept<R>(StatementVisitor<R> v) => v.visitTryCatch(this);

  @override
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg) =>
      v.visitTryCatch(this, arg);

  @override
  void visitChildren(Visitor v) {
    body.accept(v);
    visitList(catches, v);
  }

  @override
  void transformChildren(Transformer v) {
    // ignore: unnecessary_null_comparison
    if (body != null) {
      body = v.transform(body);
      body.parent = this;
    }
    v.transformList(catches, this);
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    // ignore: unnecessary_null_comparison
    if (body != null) {
      body = v.transform(body);
      body.parent = this;
    }
    v.transformCatchList(catches, this);
  }

  @override
  String toString() {
    return "TryCatch(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('try ');
    printer.writeStatement(body);
    for (Catch catchClause in catches) {
      printer.write(' ');
      printer.writeCatch(catchClause);
    }
  }
}

class Catch extends TreeNode {
  DartType guard; // Not null, defaults to dynamic.
  VariableDeclaration? exception;
  VariableDeclaration? stackTrace;
  Statement body;

  Catch(this.exception, this.body,
      {this.guard: const DynamicType(), this.stackTrace}) {
    // ignore: unnecessary_null_comparison
    assert(guard != null);
    exception?.parent = this;
    stackTrace?.parent = this;
    body.parent = this;
  }

  @override
  R accept<R>(TreeVisitor<R> v) => v.visitCatch(this);

  @override
  R accept1<R, A>(TreeVisitor1<R, A> v, A arg) => v.visitCatch(this, arg);

  @override
  void visitChildren(Visitor v) {
    guard.accept(v);
    exception?.accept(v);
    stackTrace?.accept(v);
    body.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    guard = v.visitDartType(guard);
    if (exception != null) {
      exception = v.transform(exception!);
      exception?.parent = this;
    }
    if (stackTrace != null) {
      stackTrace = v.transform(stackTrace!);
      stackTrace?.parent = this;
    }
    // ignore: unnecessary_null_comparison
    if (body != null) {
      body = v.transform(body);
      body.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    guard = v.visitDartType(guard, cannotRemoveSentinel);
    if (exception != null) {
      exception = v.transformOrRemoveVariableDeclaration(exception!);
      exception?.parent = this;
    }
    if (stackTrace != null) {
      stackTrace = v.transformOrRemoveVariableDeclaration(stackTrace!);
      stackTrace?.parent = this;
    }
    // ignore: unnecessary_null_comparison
    if (body != null) {
      body = v.transform(body);
      body.parent = this;
    }
  }

  @override
  String toString() {
    return "Catch(${toStringInternal()})";
  }

  @override
  String toText(AstTextStrategy strategy) {
    AstPrinter printer = new AstPrinter(strategy);
    toTextInternal(printer);
    return printer.getText();
  }

  @override
  void toTextInternal(AstPrinter printer) {
    bool isImplicitType(DartType type) {
      if (type is DynamicType) {
        return true;
      }
      if (type is InterfaceType &&
          type.className.node != null &&
          type.classNode.name == 'Object') {
        Uri uri = type.classNode.enclosingLibrary.importUri;
        return uri.scheme == 'dart' &&
            uri.path == 'core' &&
            type.nullability == Nullability.nonNullable;
      }
      return false;
    }

    if (exception != null) {
      if (!isImplicitType(guard)) {
        printer.write('on ');
        printer.writeType(guard);
        printer.write(' ');
      }
      printer.write('catch (');
      printer.writeVariableDeclaration(exception!,
          includeModifiersAndType: false);
      if (stackTrace != null) {
        printer.write(', ');
        printer.writeVariableDeclaration(stackTrace!,
            includeModifiersAndType: false);
      }
      printer.write(') ');
    } else {
      printer.write('on ');
      printer.writeType(guard);
      printer.write(' ');
    }
    printer.writeStatement(body);
  }
}

class TryFinally extends Statement {
  Statement body;
  Statement finalizer;

  TryFinally(this.body, this.finalizer) {
    body.parent = this;
    finalizer.parent = this;
  }

  @override
  R accept<R>(StatementVisitor<R> v) => v.visitTryFinally(this);

  @override
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg) =>
      v.visitTryFinally(this, arg);

  @override
  void visitChildren(Visitor v) {
    body.accept(v);
    finalizer.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    // ignore: unnecessary_null_comparison
    if (body != null) {
      body = v.transform(body);
      body.parent = this;
    }
    // ignore: unnecessary_null_comparison
    if (finalizer != null) {
      finalizer = v.transform(finalizer);
      finalizer.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    // ignore: unnecessary_null_comparison
    if (body != null) {
      body = v.transform(body);
      body.parent = this;
    }
    // ignore: unnecessary_null_comparison
    if (finalizer != null) {
      finalizer = v.transform(finalizer);
      finalizer.parent = this;
    }
  }

  @override
  String toString() {
    return "TryFinally(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    if (body is! TryCatch) {
      // This is a `try {} catch (e) {} finally {}`. Avoid repeating `try`.
      printer.write('try ');
    }
    printer.writeStatement(body);
    printer.write(' finally ');
    printer.writeStatement(finalizer);
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
    expression.parent = this;
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

  @override
  R accept<R>(StatementVisitor<R> v) => v.visitYieldStatement(this);

  @override
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg) =>
      v.visitYieldStatement(this, arg);

  @override
  void visitChildren(Visitor v) {
    expression.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    // ignore: unnecessary_null_comparison
    if (expression != null) {
      expression = v.transform(expression);
      expression.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    // ignore: unnecessary_null_comparison
    if (expression != null) {
      expression = v.transform(expression);
      expression.parent = this;
    }
  }

  @override
  String toString() {
    return "YieldStatement(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('yield');
    if (isYieldStar) {
      printer.write('*');
    }
    printer.write(' ');
    printer.writeExpression(expression);
    printer.write(';');
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
  String? name;
  int flags = 0;
  DartType type; // Not null, defaults to dynamic.

  /// Offset of the declaration, set and used when writing the binary.
  int binaryOffsetNoTag = -1;

  /// For locals, this is the initial value.
  /// For parameters, this is the default value.
  ///
  /// Should be null in other cases.
  Expression? initializer; // May be null.

  VariableDeclaration(this.name,
      {this.initializer,
      this.type: const DynamicType(),
      int flags: -1,
      bool isFinal: false,
      bool isConst: false,
      bool isFieldFormal: false,
      bool isCovariant: false,
      bool isLate: false,
      bool isRequired: false,
      bool isLowered: false}) {
    // ignore: unnecessary_null_comparison
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
      this.isLowered = isLowered;
    }
  }

  /// Creates a synthetic variable with the given expression as initializer.
  VariableDeclaration.forValue(this.initializer,
      {bool isFinal: true,
      bool isConst: false,
      bool isFieldFormal: false,
      bool isLate: false,
      bool isRequired: false,
      bool isLowered: false,
      this.type: const DynamicType()}) {
    // ignore: unnecessary_null_comparison
    assert(type != null);
    initializer?.parent = this;
    this.isFinal = isFinal;
    this.isConst = isConst;
    this.isFieldFormal = isFieldFormal;
    this.isLate = isLate;
    this.isRequired = isRequired;
    this.isLowered = isLowered;
  }

  static const int FlagFinal = 1 << 0; // Must match serialized bit positions.
  static const int FlagConst = 1 << 1;
  static const int FlagFieldFormal = 1 << 2;
  static const int FlagCovariant = 1 << 3;
  static const int FlagGenericCovariantImpl = 1 << 4;
  static const int FlagLate = 1 << 5;
  static const int FlagRequired = 1 << 6;
  static const int FlagLowered = 1 << 7;

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

  /// Whether the variable is part of a lowering.
  ///
  /// If a variable is part of a lowering its name may be synthesized so that it
  /// doesn't reflect the name used in the source code and might not have a
  /// one-to-one correspondence with the variable in the source.
  ///
  /// Lowering is used for instance of encoding of 'this' in extension instance
  /// members and encoding of late locals.
  bool get isLowered => flags & FlagLowered != 0;

  /// Whether the variable is assignable.
  ///
  /// This is `true` if the variable is neither constant nor final, or if it
  /// is late final without an initializer.
  bool get isAssignable {
    if (isConst) return false;
    if (isFinal) {
      if (isLate) return initializer == null;
      return false;
    }
    return true;
  }

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

  void set isLowered(bool value) {
    flags = value ? (flags | FlagLowered) : (flags & ~FlagLowered);
  }

  void clearAnnotations() {
    annotations = const <Expression>[];
  }

  void addAnnotation(Expression annotation) {
    if (annotations.isEmpty) {
      annotations = <Expression>[];
    }
    annotations.add(annotation..parent = this);
  }

  @override
  R accept<R>(StatementVisitor<R> v) => v.visitVariableDeclaration(this);

  @override
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg) =>
      v.visitVariableDeclaration(this, arg);

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
    printer.writeVariableDeclaration(this, includeInitializer: false);
    return printer.getText();
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeVariableDeclaration(this);
    printer.write(';');
  }
}

/// Declaration a local function.
///
/// The body of the function may use [variable] as its self-reference.
class FunctionDeclaration extends Statement implements LocalFunction {
  VariableDeclaration variable; // Is final and has no initializer.

  @override
  FunctionNode? function;

  FunctionDeclaration(this.variable, this.function) {
    variable.parent = this;
    function?.parent = this;
  }

  @override
  R accept<R>(StatementVisitor<R> v) => v.visitFunctionDeclaration(this);

  @override
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg) =>
      v.visitFunctionDeclaration(this, arg);

  @override
  void visitChildren(Visitor v) {
    variable.accept(v);
    function?.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    // ignore: unnecessary_null_comparison
    if (variable != null) {
      variable = v.transform(variable);
      variable.parent = this;
    }
    if (function != null) {
      function = v.transform(function!);
      function?.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    // ignore: unnecessary_null_comparison
    if (variable != null) {
      variable = v.transform(variable);
      variable.parent = this;
    }
    if (function != null) {
      function = v.transformOrRemove(function!, dummyFunctionNode);
      function?.parent = this;
    }
  }

  @override
  String toString() {
    return "FunctionDeclaration(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    if (function != null) {
      printer.writeFunctionNode(function!, printer.getVariableName(variable));
      if (function!.body is ReturnStatement) {
        printer.write(';');
      }
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
abstract class Name extends Node {
  @override
  final int hashCode;

  final String text;
  Reference? get libraryName;
  Library? get library;
  bool get isPrivate;

  Name._internal(this.hashCode, this.text);

  factory Name(String text, [Library? library]) =>
      new Name.byReference(text, library?.reference);

  factory Name.byReference(String text, Reference? libraryName) {
    /// Use separate subclasses for the public and private case to save memory
    /// for public names.
    if (text.startsWith('_')) {
      assert(libraryName != null);
      return new _PrivateName(text, libraryName!);
    } else {
      return new _PublicName(text);
    }
  }

  // TODO(johnniwinther): Remove this when dependent code has been updated to
  // use [text].
  String get name => text;

  @override
  bool operator ==(other) {
    return other is Name && text == other.text && library == other.library;
  }

  @override
  R accept<R>(Visitor<R> v) => v.visitName(this);

  @override
  void visitChildren(Visitor v) {
    // DESIGN TODO: Should we visit the library as a library reference?
  }

  /// Returns the textual representation of this node for use in debugging.
  ///
  /// Note that this adds some nodes to a static map to ensure consistent
  /// naming, but that it thus also leaks memory.
  @override
  String leakingDebugToString() => astToText.debugNodeToString(this);

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeName(this);
  }

  /// The name of the `call` method on a function.
  static final Name callName = new _PublicName('call');

  /// The name of the `==` operator.
  static final Name equalsName = new _PublicName('==');
}

class _PrivateName extends Name {
  @override
  final Reference libraryName;

  @override
  bool get isPrivate => true;

  _PrivateName(String text, Reference libraryName)
      : this.libraryName = libraryName,
        super._internal(_computeHashCode(text, libraryName), text);

  @override
  String toString() => toStringInternal();

  @override
  String toStringInternal() =>
      // ignore: unnecessary_null_comparison
      library != null ? '$library::$text' : text;

  @override
  Library get library => libraryName.asLibrary;

  static int _computeHashCode(String name, Reference libraryName) {
    // TODO(dmitryas): Factor in [libraryName] in a non-deterministic way into
    // the result.  Note, the previous code here was the following:
    //     return 131 * name.hashCode + 17 * libraryName.asLibrary._libraryId;
    return name.hashCode;
  }
}

class _PublicName extends Name {
  @override
  Reference? get libraryName => null;

  @override
  Library? get library => null;

  @override
  bool get isPrivate => false;

  _PublicName(String text) : super._internal(text.hashCode, text);

  @override
  String toString() => toStringInternal();
}

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

  @override
  R accept<R>(DartTypeVisitor<R> v);

  R accept1<R, A>(DartTypeVisitor1<R, A> v, A arg);

  @override
  bool operator ==(Object other);

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

  /// If this is a typedef type, repeatedly unfolds its type definition until
  /// the root term is not a typedef type, otherwise returns the type itself.
  ///
  /// Will never return a typedef type.
  DartType get unalias => this;

  /// If this is a typedef type, unfolds its type definition once, otherwise
  /// returns the type itself.
  DartType get unaliasOnce => this;

  /// Creates a copy of the type with the given [declaredNullability].
  ///
  /// Some types have fixed nullabilities, such as `dynamic`, `invalid-type`,
  /// `void`, or `bottom`.
  DartType withDeclaredNullability(Nullability declaredNullability);

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

  bool equals(Object other, Assumptions? assumptions);

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

/// The type arising from invalid type annotations.
///
/// Can usually be treated as 'dynamic', but should occasionally be handled
/// differently, e.g. `x is ERROR` should evaluate to false.
class InvalidType extends DartType {
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
  bool operator ==(Object other) => equals(other, null);

  @override
  bool equals(Object other, Assumptions? assumptions) => other is InvalidType;

  @override
  Nullability get declaredNullability {
    // TODO(johnniwinther,dmitryas): Consider implementing invalidNullability.
    return Nullability.legacy;
  }

  @override
  Nullability get nullability {
    // TODO(johnniwinther,dmitryas): Consider implementing invalidNullability.
    return Nullability.legacy;
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

class DynamicType extends DartType {
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
  bool operator ==(Object other) => equals(other, null);

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

class VoidType extends DartType {
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
  bool operator ==(Object other) => equals(other, null);

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

  const NeverType.undetermined() : this.internal(Nullability.undetermined);

  const NeverType.internal(this.declaredNullability);

  static NeverType fromNullability(Nullability nullability) {
    switch (nullability) {
      case Nullability.nullable:
        return const NeverType.nullable();
      case Nullability.nonNullable:
        return const NeverType.nonNullable();
      case Nullability.legacy:
        return const NeverType.legacy();
      case Nullability.undetermined:
        return const NeverType.undetermined();
    }
  }

  @override
  Nullability get nullability => declaredNullability;

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
  bool operator ==(Object other) => equals(other, null);

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
    printer.write(nullabilityToString(declaredNullability));
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
  bool operator ==(Object other) => equals(other, null);

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

class InterfaceType extends DartType {
  final Reference className;

  @override
  final Nullability declaredNullability;

  final List<DartType> typeArguments;

  /// The [typeArguments] list must not be modified after this call. If the
  /// list is omitted, 'dynamic' type arguments are filled in.
  InterfaceType(Class classNode, Nullability declaredNullability,
      [List<DartType>? typeArguments])
      : this.byReference(
            getNonNullableClassReference(classNode),
            declaredNullability,
            typeArguments ?? _defaultTypeArguments(classNode));

  InterfaceType.byReference(
      this.className, this.declaredNullability, this.typeArguments)
      // ignore: unnecessary_null_comparison
      : assert(declaredNullability != null);

  Class get classNode => className.asClass;

  @override
  Nullability get nullability => declaredNullability;

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
  bool operator ==(Object other) => equals(other, null);

  @override
  bool equals(Object other, Assumptions? assumptions) {
    if (identical(this, other)) return true;
    if (other is InterfaceType) {
      if (nullability != other.nullability) return false;
      if (className != other.className) return false;
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
    int hash = 0x3fffffff & className.hashCode;
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
            className, declaredNullability, typeArguments);
  }

  @override
  String toString() {
    return "InterfaceType(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeClassName(className, forType: true);
    printer.writeTypeArguments(typeArguments);
    printer.write(nullabilityToString(declaredNullability));
  }
}

/// A possibly generic function type.
class FunctionType extends DartType {
  final List<TypeParameter> typeParameters;
  final int requiredParameterCount;
  final List<DartType> positionalParameters;
  final List<NamedType> namedParameters; // Must be sorted.

  @override
  final Nullability declaredNullability;

  /// The [Typedef] this function type is created for.
  final TypedefType? typedefType;

  final DartType returnType;

  @override
  late final int hashCode = _computeHashCode();

  FunctionType(List<DartType> positionalParameters, this.returnType,
      this.declaredNullability,
      {this.namedParameters: const <NamedType>[],
      this.typeParameters: const <TypeParameter>[],
      int? requiredParameterCount,
      this.typedefType})
      : this.positionalParameters = positionalParameters,
        this.requiredParameterCount =
            requiredParameterCount ?? positionalParameters.length;

  Reference? get typedefReference => typedefType?.typedefReference;

  Typedef? get typedef => typedefReference?.asTypedef;

  @override
  Nullability get nullability => declaredNullability;

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
    typedefType?.accept(v);
    returnType.accept(v);
  }

  @override
  bool operator ==(Object other) => equals(other, null);

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
          assumptions.assume(
              typeParameters[index], other.typeParameters[index]);
        }
        for (int index = 0; index < typeParameters.length; index++) {
          if (!typeParameters[index]
              .bound!
              .equals(other.typeParameters[index].bound!, assumptions)) {
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
          assumptions!
              .forget(typeParameters[index], other.typeParameters[index]);
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
        namedParameters: namedParameters,
        typedefType: null);
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
      TypeParameter parameter = typeParameters[i];
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
    FunctionType result = FunctionType(
        positionalParameters, returnType, declaredNullability,
        namedParameters: namedParameters,
        typeParameters: typeParameters,
        requiredParameterCount: requiredParameterCount,
        typedefType: typedefType?.withDeclaredNullability(declaredNullability));
    if (typeParameters.isEmpty) return result;
    return getFreshTypeParameters(typeParameters).applyToFunctionType(result);
  }

  @override
  String toString() {
    return "FunctionType(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeType(returnType);
    printer.write(" Function");
    printer.writeTypeParameters(typeParameters);
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
    printer.write(nullabilityToString(declaredNullability));
  }
}

/// A use of a [Typedef] as a type.
///
/// The underlying type can be extracted using [unalias].
class TypedefType extends DartType {
  final Nullability declaredNullability;
  final Reference typedefReference;
  final List<DartType> typeArguments;

  TypedefType(Typedef typedefNode, Nullability nullability,
      [List<DartType>? typeArguments])
      : this.byReference(typedefNode.reference, nullability,
            typeArguments ?? const <DartType>[]);

  TypedefType.byReference(
      this.typedefReference, this.declaredNullability, this.typeArguments);

  Typedef get typedefNode => typedefReference.asTypedef;

  // TODO(dmitryas): Replace with uniteNullabilities(declaredNullability,
  // typedefNode.type.nullability).
  @override
  Nullability get nullability => declaredNullability;

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

  @override
  DartType get unaliasOnce {
    DartType result =
        Substitution.fromTypedefType(this).substituteType(typedefNode.type!);
    return result.withDeclaredNullability(
        combineNullabilitiesForSubstitution(result.nullability, nullability));
  }

  @override
  DartType get unalias {
    return unaliasOnce.unalias;
  }

  @override
  bool operator ==(Object other) => equals(other, null);

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
    printer.write(nullabilityToString(declaredNullability));
  }
}

class FutureOrType extends DartType {
  final DartType typeArgument;

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
  bool operator ==(Object other) => equals(other, null);

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
    printer.write(nullabilityToString(declaredNullability));
  }
}

/// A named parameter in [FunctionType].
class NamedType extends Node implements Comparable<NamedType> {
  // Flag used for serialization if [isRequired].
  static const int FlagRequiredNamedType = 1 << 0;

  final String name;
  final DartType type;
  final bool isRequired;

  const NamedType(this.name, this.type, {this.isRequired: false});

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
  void visitChildren(Visitor v) {
    type.accept(v);
  }

  @override
  String toString() {
    return "NamedType(${toStringInternal()})";
  }

  String toText(AstTextStrategy strategy) {
    AstPrinter printer = new AstPrinter(strategy);
    printer.writeNamedType(this);
    return printer.getText();
  }

  void toTextInternal(AstPrinter printer) {
    if (isRequired) {
      printer.write("required ");
    }
    printer.write(name);
    printer.write(': ');
    printer.writeType(type);
  }
}

/// Reference to a type variable.
///
/// A type variable has an optional bound because type promotion can change the
/// bound.  A bound of `null` indicates that the bound has not been promoted and
/// is the same as the [TypeParameter]'s bound.  This allows one to detect
/// whether the bound has been promoted.  The case of promoted bound can be
/// viewed as representing an intersection type between the type-parameter type
/// and the promoted bound.
class TypeParameterType extends DartType {
  /// The declared nullability of a type-parameter type.
  ///
  /// When a [TypeParameterType] represents an intersection,
  /// [declaredNullability] is the nullability of the left-hand side.
  @override
  Nullability declaredNullability;

  TypeParameter parameter;

  /// An optional promoted bound on the type parameter.
  ///
  /// 'null' indicates that the type parameter's bound has not been promoted and
  /// is therefore the same as the bound of [parameter].
  DartType? promotedBound;

  TypeParameterType.internal(
      this.parameter, this.declaredNullability, DartType? promotedBound)
      : this.promotedBound = promotedBound {
    assert(
        promotedBound == null ||
            (declaredNullability == Nullability.nonNullable &&
                promotedBound.nullability == Nullability.nonNullable) ||
            (declaredNullability == Nullability.nonNullable &&
                promotedBound.nullability == Nullability.undetermined) ||
            (declaredNullability == Nullability.legacy &&
                promotedBound.nullability == Nullability.legacy) ||
            (declaredNullability == Nullability.undetermined &&
                promotedBound.nullability == Nullability.nonNullable) ||
            (declaredNullability == Nullability.undetermined &&
                promotedBound.nullability == Nullability.nullable) ||
            (declaredNullability == Nullability.undetermined &&
                promotedBound.nullability == Nullability.undetermined)
            // These are observed in real situations:
            ||
            // pkg/front_end/test/id_tests/type_promotion_test
            // replicated in nnbd_mixed/type_parameter_nullability
            (declaredNullability == Nullability.nullable &&
                promotedBound.nullability == Nullability.nonNullable) ||
            // pkg/front_end/test/fasta/types/kernel_type_parser_test
            // pkg/front_end/test/fasta/incremental_hello_test
            // pkg/front_end/test/fasta/types/fasta_types_test
            // pkg/front_end/test/explicit_creation_test
            // pkg/front_end/tool/fasta_perf_test
            // nnbd/issue42089
            // replicated in nnbd_mixed/type_parameter_nullability
            (declaredNullability == Nullability.nullable &&
                promotedBound.nullability == Nullability.nullable) ||
            // pkg/front_end/test/explicit_creation_test
            // pkg/front_end/test/dill_round_trip_test
            // pkg/front_end/test/compile_dart2js_with_no_sdk_test
            // pkg/front_end/test/fasta/types/large_app_benchmark_test
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
            (declaredNullability == Nullability.legacy &&
                promotedBound.nullability == Nullability.nonNullable) ||
            // pkg/front_end/test/fasta/incremental_hello_test
            // pkg/front_end/test/explicit_creation_test
            // pkg/front_end/tool/fasta_perf_test
            // replicated in nnbd_mixed/type_parameter_nullability
            (declaredNullability == Nullability.nullable &&
                promotedBound.nullability == Nullability.undetermined) ||
            // These are only observed in tests and might be artifacts of the
            // tests rather than real situations:
            //
            // pkg/front_end/test/fasta/types/kernel_type_parser_test
            // pkg/front_end/test/fasta/types/fasta_types_test
            (declaredNullability == Nullability.legacy &&
                promotedBound.nullability == Nullability.nullable) ||
            // pkg/front_end/test/fasta/types/kernel_type_parser_test
            // pkg/front_end/test/fasta/types/fasta_types_test
            (declaredNullability == Nullability.nonNullable &&
                promotedBound.nullability == Nullability.nullable) ||
            // pkg/front_end/test/fasta/types/kernel_type_parser_test
            // pkg/front_end/test/fasta/types/fasta_types_test
            (declaredNullability == Nullability.undetermined &&
                promotedBound.nullability == Nullability.legacy),
        "Unexpected nullabilities for $parameter & $promotedBound: "
        "declaredNullability = $declaredNullability, "
        "promoted bound nullability = ${promotedBound.nullability}.");
  }

  TypeParameterType(TypeParameter parameter, Nullability declaredNullability,
      [DartType? promotedBound])
      : this.internal(parameter, declaredNullability, promotedBound);

  /// Creates an intersection type between a type parameter and [promotedBound].
  TypeParameterType.intersection(TypeParameter parameter,
      Nullability declaredNullability, DartType promotedBound)
      : this.internal(parameter, declaredNullability, promotedBound);

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

  /// Creates a type-parameter type with default nullability for the library.
  ///
  /// The nullability is computed as if the programmer omitted the modifier. It
  /// means that in the opt-out libraries `Nullability.legacy` will be used, and
  /// in opt-in libraries either `Nullability.nonNullable` or
  /// `Nullability.undetermined` will be used, depending on the nullability of
  /// the bound of [parameter].
  TypeParameterType.withDefaultNullabilityForLibrary(
      this.parameter, Library library)
      : declaredNullability = library.isNonNullableByDefault
            ? computeNullabilityFromBound(parameter)
            : Nullability.legacy;

  @override
  R accept<R>(DartTypeVisitor<R> v) => v.visitTypeParameterType(this);

  @override
  R accept1<R, A>(DartTypeVisitor1<R, A> v, A arg) =>
      v.visitTypeParameterType(this, arg);

  @override
  void visitChildren(Visitor v) {}

  @override
  bool operator ==(Object other) => equals(other, null);

  @override
  bool equals(Object other, Assumptions? assumptions) {
    if (identical(this, other)) {
      return true;
    } else if (other is TypeParameterType) {
      if (nullability != other.nullability) return false;
      if (parameter != other.parameter) {
        if (parameter.parent == null) {
          // Function type parameters are also equal by assumption.
          if (assumptions == null) {
            return false;
          }
          if (!assumptions.isAssumed(parameter, other.parameter)) {
            return false;
          }
        } else {
          return false;
        }
      }
      if (promotedBound != null) {
        if (other.promotedBound == null) return false;
        if (!promotedBound!.equals(other.promotedBound!, assumptions)) {
          return false;
        }
      } else if (other.promotedBound != null) {
        return false;
      }
      return true;
    } else {
      return false;
    }
  }

  @override
  int get hashCode {
    // TODO(johnniwinther): Since we use a unification strategy for function
    //  type type parameter equality, we have to assume they can end up being
    //  equal. Maybe we should change the equality strategy.
    int hash = parameter.isFunctionTypeTypeParameter ? 0 : parameter.hashCode;
    int nullabilityHash = (0x33333333 >> nullability.index) ^ 0x33333333;
    hash = 0x3fffffff & (hash * 31 + (hash ^ nullabilityHash));
    hash = 0x3fffffff & (hash * 31 + (hash ^ promotedBound.hashCode));
    return hash;
  }

  /// Returns the bound of the type parameter, accounting for promotions.
  DartType get bound => (promotedBound ?? parameter.bound)!;

  /// Nullability of the type, calculated from its parts.
  ///
  /// [nullability] is calculated from [typeParameterTypeNullability] and the
  /// nullability of [promotedBound] if it's present.
  ///
  /// For example, in the following program [typeParameterTypeNullability] of
  /// both `x` and `y` is [Nullability.undetermined], because it's copied from
  /// that of `bar` and T has a nullable type as its bound.  However, despite
  /// [nullability] of `x` is [Nullability.undetermined], [nullability] of `y`
  /// is [Nullability.nonNullable] because of its [promotedBound].
  ///
  ///     class A<T extends Object?> {
  ///       foo(T bar) {
  ///         var x = bar;
  ///         if (bar is int) {
  ///           var y = bar;
  ///         }
  ///       }
  ///     }
  @override
  Nullability get nullability {
    return getNullability(declaredNullability, promotedBound);
  }

  /// Gets a new [TypeParameterType] with given [typeParameterTypeNullability].
  ///
  /// In contrast with other types, [TypeParameterType.withDeclaredNullability]
  /// doesn't set the overall nullability of the returned type but sets that of
  /// the left-hand side of the intersection type.  In case [promotedBound] is
  /// null, it is an equivalent of setting the overall nullability.
  @override
  TypeParameterType withDeclaredNullability(Nullability declaredNullability) {
    if (declaredNullability == this.declaredNullability) {
      return this;
    }
    // TODO(dmitryas): Consider removing the assert.
    assert(promotedBound == null,
        "Can't change the nullability attribute of an intersection type.");
    return new TypeParameterType(parameter, declaredNullability, promotedBound);
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
    DartType? bound = typeParameter.bound;
    if (bound == null) {
      throw new StateError("Can't compute nullability from an absent bound.");
    }

    // If a type parameter's nullability depends on itself, it is deemed
    // 'undetermined'. Currently, it's possible if the type parameter has a
    // possibly nested FutureOr containing that type parameter.  If there are
    // other ways for such a dependency to exist, they should be checked here.
    bool nullabilityDependsOnItself = false;
    {
      DartType? type = typeParameter.bound;
      while (type is FutureOrType) {
        type = type.typeArgument;
      }
      if (type is TypeParameterType && type.parameter == typeParameter) {
        // Intersection types can't appear in the bound.
        assert(type.promotedBound == null);

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

  /// Gets nullability of [TypeParameterType] from arguments to its constructor.
  ///
  /// The method combines [typeParameterTypeNullability] and the nullability of
  /// [promotedBound] to yield the nullability of the intersection type.  If the
  /// right-hand side of the intersection is absent (that is, if [promotedBound]
  /// is null), the nullability of the intersection type is simply
  /// [typeParameterTypeNullability].
  static Nullability getNullability(
      Nullability typeParameterTypeNullability, DartType? promotedBound) {
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
    // |     !     |  !  |  +  | N/A |  !  |
    // |     ?     | (!) | (?) | N/A | (%) |
    // |     *     | (*) |  +  |  *  | N/A |
    // |     %     |  !  |  %  |  +  |  %  |
    //
    // In the table, LHS corresponds to lhsNullability in the code below; RHS
    // corresponds to promotedBound.nullability; !, ?, *, and % correspond to
    // nonNullable, nullable, legacy, and undetermined values of the Nullability
    // enum.

    assert(
        (lhsNullability == Nullability.nonNullable &&
                promotedBound.nullability == Nullability.nonNullable) ||
            (lhsNullability == Nullability.nonNullable &&
                promotedBound.nullability == Nullability.undetermined) ||
            (lhsNullability == Nullability.legacy &&
                promotedBound.nullability == Nullability.legacy) ||
            (lhsNullability == Nullability.undetermined &&
                promotedBound.nullability == Nullability.nonNullable) ||
            (lhsNullability == Nullability.undetermined &&
                promotedBound.nullability == Nullability.nullable) ||
            (lhsNullability == Nullability.undetermined &&
                promotedBound.nullability == Nullability.undetermined)
            // Apparently these happens as well:
            ||
            // pkg/front_end/test/id_tests/type_promotion_test
            (lhsNullability == Nullability.nullable &&
                promotedBound.nullability == Nullability.nonNullable) ||
            // pkg/front_end/test/fasta/types/kernel_type_parser_test
            // pkg/front_end/test/fasta/incremental_hello_test
            // pkg/front_end/test/fasta/types/fasta_types_test
            // pkg/front_end/test/explicit_creation_test
            // pkg/front_end/tool/fasta_perf_test
            // nnbd/issue42089
            (lhsNullability == Nullability.nullable &&
                promotedBound.nullability == Nullability.nullable) ||
            // pkg/front_end/test/explicit_creation_test
            // pkg/front_end/test/dill_round_trip_test
            // pkg/front_end/test/compile_dart2js_with_no_sdk_test
            // pkg/front_end/test/fasta/types/large_app_benchmark_test
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
                promotedBound.nullability == Nullability.nonNullable) ||
            // pkg/front_end/test/fasta/incremental_hello_test
            // pkg/front_end/test/explicit_creation_test
            // pkg/front_end/tool/fasta_perf_test
            // pkg/front_end/test/fasta/incremental_hello_test
            (lhsNullability == Nullability.nullable &&
                promotedBound.nullability == Nullability.undetermined) ||

            // This is created but never observed.
            // (lhsNullability == Nullability.legacy &&
            //     promotedBound.nullability == Nullability.nullable) ||

            // pkg/front_end/test/fasta/types/kernel_type_parser_test
            // pkg/front_end/test/fasta/types/fasta_types_test
            (lhsNullability == Nullability.undetermined &&
                promotedBound.nullability == Nullability.legacy) ||
            // pkg/front_end/test/fasta/types/kernel_type_parser_test
            // pkg/front_end/test/fasta/types/fasta_types_test
            (lhsNullability == Nullability.nonNullable &&
                promotedBound.nullability == Nullability.nullable),
        "Unexpected nullabilities for: LHS nullability = $lhsNullability, "
        "RHS nullability = ${promotedBound.nullability}.");

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
    // |     ?     | (!) | (?) |  *  | (%) |
    // |     *     | (*) |  *  |  *  |  %  |
    // |     %     |  !  |  %  |  %  |  %  |

    if (lhsNullability == Nullability.nullable &&
        promotedBound.nullability == Nullability.nonNullable) {
      return Nullability.nonNullable;
    }

    if (lhsNullability == Nullability.nullable &&
        promotedBound.nullability == Nullability.nullable) {
      return Nullability.nullable;
    }

    if (lhsNullability == Nullability.legacy &&
        promotedBound.nullability == Nullability.nonNullable) {
      return Nullability.legacy;
    }

    if (lhsNullability == Nullability.nullable &&
        promotedBound.nullability == Nullability.undetermined) {
      return Nullability.undetermined;
    }

    // Intersection with a non-nullable type always yields a non-nullable type,
    // as it's the most restrictive kind of types.
    if (lhsNullability == Nullability.nonNullable ||
        promotedBound.nullability == Nullability.nonNullable) {
      return Nullability.nonNullable;
    }

    // If the nullability of LHS is 'undetermined', the nullability of the
    // intersection is also 'undetermined' if RHS is 'undetermined' or nullable.
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
        promotedBound.nullability == Nullability.undetermined) {
      return Nullability.undetermined;
    }

    return Nullability.legacy;
  }

  @override
  String toString() {
    return "TypeParameterType(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    if (promotedBound != null) {
      printer.write('(');
      printer.writeTypeParameterName(parameter);
      printer.write(nullabilityToString(declaredNullability));
      printer.write(" & ");
      printer.writeType(promotedBound!);
      printer.write(')');
      printer.write(nullabilityToString(nullability));
    } else {
      printer.writeTypeParameterName(parameter);
      printer.write(nullabilityToString(declaredNullability));
    }
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

  /// Returns true if [a] is greater than (above) [b] in the partial order
  /// induced by the variance lattice.
  static bool greaterThan(int a, int b) {
    return greaterThanOrEqual(a, b) && a != b;
  }

  /// Returns true if [a] is greater than (above) or equal to [b] in the
  /// partial order induced by the variance lattice.
  static bool greaterThanOrEqual(int a, int b) {
    return meet(a, b) == b;
  }

  /// Returns true if [a] is less than (below) [b] in the partial order
  /// induced by the variance lattice.
  static bool lessThan(int a, int b) {
    return lessThanOrEqual(a, b) && a != b;
  }

  /// Returns true if [a] is less than (below) or equal to [b] in the
  /// partial order induced by the variance lattice.
  static bool lessThanOrEqual(int a, int b) {
    return meet(a, b) == a;
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

  // Returns the keyword lexeme associated with the variance given.
  static String keywordString(int variance) {
    switch (variance) {
      case Variance.contravariant:
        return 'in';
      case Variance.invariant:
        return 'inout';
      case Variance.covariant:
      default:
        return 'out';
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

  String? name; // Cosmetic name.

  /// The bound on the type variable.
  ///
  /// Should not be null except temporarily during IR construction.  Should
  /// be set to the root class for type parameters without an explicit bound.
  // TODO(johnniwinther): Can we make this late non-nullable?
  DartType? bound;

  /// The default value of the type variable. It is used to provide the
  /// corresponding missing type argument in type annotations and as the
  /// fall-back type value in type inference at compile time. At run time,
  /// [defaultType] is used by the backends in place of the missing type
  /// argument of a dynamic invocation of a generic function.
  // TODO(johnniwinther): Can we make this late non-nullable?
  DartType? defaultType;

  /// Describes variance of the type parameter w.r.t. declaration on which it is
  /// defined. For classes, if variance is not explicitly set, the type
  /// parameter has legacy covariance defined by [isLegacyCovariant] which
  /// on the lattice is equivalent to [Variance.covariant]. For typedefs, it's
  /// the variance of the type parameters in the type term on the r.h.s. of the
  /// typedef.
  int? _variance;

  int get variance => _variance ?? Variance.covariant;

  void set variance(int? newVariance) => _variance = newVariance;

  bool get isLegacyCovariant => _variance == null;

  static const int legacyCovariantSerializationMarker = 4;

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

  @override
  R accept<R>(TreeVisitor<R> v) => v.visitTypeParameter(this);

  @override
  R accept1<R, A>(TreeVisitor1<R, A> v, A arg) =>
      v.visitTypeParameter(this, arg);

  @override
  void visitChildren(Visitor v) {
    visitList(annotations, v);
    bound?.accept(v);
    defaultType?.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    v.transformList(annotations, this);
    if (bound != null) {
      bound = v.visitDartType(bound!);
    }
    if (defaultType != null) {
      defaultType = v.visitDartType(defaultType!);
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    v.transformExpressionList(annotations, this);
    if (bound != null) {
      DartType newBound = v.visitDartType(bound!, dummyDartType);
      if (identical(newBound, dummyDartType)) {
        bound = null;
      } else {
        bound = newBound;
      }
    }
    if (defaultType != null) {
      DartType newDefaultType = v.visitDartType(defaultType!, dummyDartType);
      if (identical(newDefaultType, dummyDartType)) {
        defaultType = null;
      } else {
        defaultType = newDefaultType;
      }
    }
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

  bool get isFunctionTypeTypeParameter => parent == null;
}

class Supertype extends Node {
  Reference className;
  final List<DartType> typeArguments;

  Supertype(Class classNode, List<DartType> typeArguments)
      : this.byReference(
            getNonNullableClassReference(classNode), typeArguments);

  Supertype.byReference(this.className, this.typeArguments);

  Class get classNode => className.asClass;

  R accept<R>(Visitor<R> v) => v.visitSupertype(this);

  visitChildren(Visitor v) {
    classNode.acceptReference(v);
    visitList(typeArguments, v);
  }

  InterfaceType get asInterfaceType {
    return new InterfaceType(classNode, Nullability.legacy, typeArguments);
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

  String toString() => throw '$runtimeType';

  /// Returns a textual representation of the this constant.
  ///
  /// If [verbose] is `true`, qualified names will include the library name/uri.
  String toText(AstTextStrategy strategy) {
    AstPrinter printer = new AstPrinter(strategy);
    printer.writeConstant(this);
    return printer.getText();
  }

  void toTextInternal(AstPrinter printer);

  /// Gets the type of this constant.
  DartType getType(StaticTypeContext context);

  Expression asExpression() {
    return new ConstantExpression(this);
  }
}

abstract class PrimitiveConstant<T> extends Constant {
  final T value;

  PrimitiveConstant(this.value);

  int get hashCode => value.hashCode;

  bool operator ==(Object other) =>
      other is PrimitiveConstant<T> && other.value == value;

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('$value');
  }
}

class NullConstant extends PrimitiveConstant<Null> {
  NullConstant() : super(null);

  visitChildren(Visitor v) {}
  R accept<R>(ConstantVisitor<R> v) => v.visitNullConstant(this);
  R acceptReference<R>(Visitor<R> v) => v.visitNullConstantReference(this);

  DartType getType(StaticTypeContext context) => const NullType();

  @override
  String toString() => 'NullConstant(${toStringInternal()})';
}

class BoolConstant extends PrimitiveConstant<bool> {
  BoolConstant(bool value) : super(value);

  visitChildren(Visitor v) {}
  R accept<R>(ConstantVisitor<R> v) => v.visitBoolConstant(this);
  R acceptReference<R>(Visitor<R> v) => v.visitBoolConstantReference(this);

  DartType getType(StaticTypeContext context) =>
      context.typeEnvironment.coreTypes.boolRawType(context.nonNullable);

  @override
  String toString() => 'BoolConstant(${toStringInternal()})';
}

/// An integer constant on a non-JS target.
class IntConstant extends PrimitiveConstant<int> {
  IntConstant(int value) : super(value);

  visitChildren(Visitor v) {}
  R accept<R>(ConstantVisitor<R> v) => v.visitIntConstant(this);
  R acceptReference<R>(Visitor<R> v) => v.visitIntConstantReference(this);

  DartType getType(StaticTypeContext context) =>
      context.typeEnvironment.coreTypes.intRawType(context.nonNullable);

  @override
  String toString() => 'IntConstant(${toStringInternal()})';
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

  DartType getType(StaticTypeContext context) =>
      context.typeEnvironment.coreTypes.doubleRawType(context.nonNullable);

  @override
  String toString() => 'DoubleConstant(${toStringInternal()})';
}

class StringConstant extends PrimitiveConstant<String> {
  StringConstant(String value) : super(value) {
    // ignore: unnecessary_null_comparison
    assert(value != null);
  }

  visitChildren(Visitor v) {}
  R accept<R>(ConstantVisitor<R> v) => v.visitStringConstant(this);
  R acceptReference<R>(Visitor<R> v) => v.visitStringConstantReference(this);

  @override
  DartType getType(StaticTypeContext context) =>
      context.typeEnvironment.coreTypes.stringRawType(context.nonNullable);

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('"');
    printer.write(escapeString(value));
    printer.write('"');
  }

  String toString() => 'StringConstant(${toStringInternal()})';
}

class SymbolConstant extends Constant {
  final String name;
  final Reference? libraryReference;

  SymbolConstant(this.name, this.libraryReference);

  visitChildren(Visitor v) {}

  R accept<R>(ConstantVisitor<R> v) => v.visitSymbolConstant(this);
  R acceptReference<R>(Visitor<R> v) => v.visitSymbolConstantReference(this);

  @override
  String toString() => 'SymbolConstant(${toStringInternal()})';

  int get hashCode => _Hash.hash2(name, libraryReference);

  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SymbolConstant &&
          other.name == name &&
          other.libraryReference == libraryReference);

  DartType getType(StaticTypeContext context) =>
      context.typeEnvironment.coreTypes.symbolRawType(context.nonNullable);

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('#');
    if (printer.includeAuxiliaryProperties && libraryReference != null) {
      printer.write(libraryNameToString(libraryReference!.asLibrary));
      printer.write('::');
    }
    printer.write(name);
  }
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

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('const <');
    printer.writeType(keyType);
    printer.write(', ');
    printer.writeType(valueType);
    printer.write('>{');
    for (int i = 0; i < entries.length; i++) {
      if (i > 0) {
        printer.write(', ');
      }
      printer.writeConstantMapEntry(entries[i]);
    }
    printer.write('}');
  }

  @override
  String toString() => 'MapConstant(${toStringInternal()})';

  @override
  late final int hashCode = _Hash.combine2Finish(
      keyType.hashCode, valueType.hashCode, _Hash.combineListHash(entries));

  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MapConstant &&
          other.keyType == keyType &&
          other.valueType == valueType &&
          listEquals(other.entries, entries));

  DartType getType(StaticTypeContext context) =>
      context.typeEnvironment.mapType(keyType, valueType, context.nonNullable);
}

class ConstantMapEntry {
  final Constant key;
  final Constant value;
  ConstantMapEntry(this.key, this.value);

  @override
  String toString() => 'ConstantMapEntry(${toStringInternal()})';

  @override
  int get hashCode => _Hash.hash2(key, value);

  @override
  bool operator ==(Object other) =>
      other is ConstantMapEntry && other.key == key && other.value == value;

  String toStringInternal() => toText(defaultAstTextStrategy);

  String toText(AstTextStrategy strategy) {
    AstPrinter printer = new AstPrinter(strategy);
    printer.writeConstantMapEntry(this);
    return printer.getText();
  }

  void toTextInternal(AstPrinter printer) {
    printer.writeConstant(key);
    printer.write(': ');
    printer.writeConstant(value);
  }
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

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('const <');
    printer.writeType(typeArgument);
    printer.write('>[');
    for (int i = 0; i < entries.length; i++) {
      if (i > 0) {
        printer.write(', ');
      }
      printer.writeConstant(entries[i]);
    }
    printer.write(']');
  }

  @override
  String toString() => 'ListConstant(${toStringInternal()})';

  @override
  late final int hashCode = _Hash.combineFinish(
      typeArgument.hashCode, _Hash.combineListHash(entries));

  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ListConstant &&
          other.typeArgument == typeArgument &&
          listEquals(other.entries, entries));

  DartType getType(StaticTypeContext context) =>
      context.typeEnvironment.listType(typeArgument, context.nonNullable);
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

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('const <');
    printer.writeType(typeArgument);
    printer.write('>{');
    for (int i = 0; i < entries.length; i++) {
      if (i > 0) {
        printer.write(', ');
      }
      printer.writeConstant(entries[i]);
    }
    printer.write('}');
  }

  @override
  String toString() => 'SetConstant(${toStringInternal()})';

  @override
  late final int hashCode = _Hash.combineFinish(
      typeArgument.hashCode, _Hash.combineListHash(entries));

  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SetConstant &&
          other.typeArgument == typeArgument &&
          listEquals(other.entries, entries));

  DartType getType(StaticTypeContext context) =>
      context.typeEnvironment.setType(typeArgument, context.nonNullable);
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

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('const ');
    printer.writeClassName(classReference);
    printer.writeTypeArguments(typeArguments);
    printer.write('{');
    String comma = '';
    fieldValues.forEach((Reference fieldRef, Constant constant) {
      printer.write(comma);
      printer.writeMemberName(fieldRef);
      printer.write(': ');
      printer.writeConstant(constant);
      comma = ', ';
    });
    printer.write('}');
  }

  @override
  String toString() => 'InstanceConstant(${toStringInternal()})';

  @override
  late final int hashCode = _Hash.combine2Finish(classReference.hashCode,
      listHashCode(typeArguments), _Hash.combineMapHashUnordered(fieldValues));

  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is InstanceConstant &&
            other.classReference == classReference &&
            listEquals(other.typeArguments, typeArguments) &&
            mapEquals(other.fieldValues, fieldValues));
  }

  DartType getType(StaticTypeContext context) =>
      new InterfaceType(classNode, context.nonNullable, typeArguments);
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

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeConstant(tearOffConstant);
    printer.writeTypeArguments(types);
  }

  @override
  String toString() => 'PartialInstantiationConstant(${toStringInternal()})';

  int get hashCode => _Hash.combineFinish(
      tearOffConstant.hashCode, _Hash.combineListHash(types));

  bool operator ==(Object other) {
    return other is PartialInstantiationConstant &&
        other.tearOffConstant == tearOffConstant &&
        listEquals(other.types, types);
  }

  DartType getType(StaticTypeContext context) {
    final FunctionType type = tearOffConstant.getType(context);
    final Map<TypeParameter, DartType> mapping = <TypeParameter, DartType>{};
    for (final TypeParameter parameter in type.typeParameters) {
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

  Procedure get procedure => procedureReference.asProcedure;

  visitChildren(Visitor v) {
    procedureReference.asProcedure.acceptReference(v);
  }

  R accept<R>(ConstantVisitor<R> v) => v.visitTearOffConstant(this);
  R acceptReference<R>(Visitor<R> v) => v.visitTearOffConstantReference(this);

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeMemberName(procedureReference);
  }

  @override
  String toString() => 'TearOffConstant(${toStringInternal()})';

  int get hashCode => procedureReference.hashCode;

  bool operator ==(Object other) {
    return other is TearOffConstant &&
        other.procedureReference == procedureReference;
  }

  FunctionType getType(StaticTypeContext context) {
    return procedure.function!.computeFunctionType(context.nonNullable);
  }
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

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeType(type);
  }

  @override
  String toString() => 'TypeLiteralConstant(${toStringInternal()})';

  int get hashCode => type.hashCode;

  bool operator ==(Object other) {
    return other is TypeLiteralConstant && other.type == type;
  }

  DartType getType(StaticTypeContext context) =>
      context.typeEnvironment.coreTypes.typeRawType(context.nonNullable);
}

class UnevaluatedConstant extends Constant {
  final Expression expression;

  UnevaluatedConstant(this.expression) {
    expression.parent = null;
  }

  visitChildren(Visitor v) {
    expression.accept(v);
  }

  R accept<R>(ConstantVisitor<R> v) => v.visitUnevaluatedConstant(this);
  R acceptReference<R>(Visitor<R> v) =>
      v.visitUnevaluatedConstantReference(this);

  DartType getType(StaticTypeContext context) =>
      expression.getStaticType(context);

  @override
  Expression asExpression() => expression;

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('unevaluated{');
    printer.writeExpression(expression);
    printer.write('}');
  }

  @override
  String toString() {
    return "UnevaluatedConstant(${toStringInternal()})";
  }

  @override
  int get hashCode => expression.hashCode;

  @override
  bool operator ==(Object other) {
    return other is UnevaluatedConstant && other.expression == expression;
  }
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
  List<String>? problemsAsJson;

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
  Reference? _mainMethodName;
  Reference? get mainMethodName => _mainMethodName;
  NonNullableByDefaultCompiledMode? _mode;
  NonNullableByDefaultCompiledMode get mode {
    return _mode ?? NonNullableByDefaultCompiledMode.Weak;
  }

  NonNullableByDefaultCompiledMode? get modeRaw => _mode;

  Component(
      {CanonicalName? nameRoot,
      List<Library>? libraries,
      Map<Uri, Source>? uriToSource})
      : root = nameRoot ?? new CanonicalName.root(),
        libraries = libraries ?? <Library>[],
        uriToSource = uriToSource ?? <Uri, Source>{} {
    adoptChildren();
  }

  void adoptChildren() {
    // ignore: unnecessary_null_comparison
    if (libraries != null) {
      for (int i = 0; i < libraries.length; ++i) {
        // The libraries are owned by this component, and so are their canonical
        // names if they exist.
        Library library = libraries[i];
        library.parent = this;
        CanonicalName? name = library.reference.canonicalName;
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

  /// This is an advanced feature. Use of this method should be coordinated
  /// with the kernel team.
  ///
  /// Makes sure all references in named nodes in this component points to said
  /// named node.
  ///
  /// The use case is advanced incremental compilation, where we want to rebuild
  /// a single library and make all other libraries use the new library and the
  /// content therein *while* having the option to go back to pointing (be
  /// "linked") to the old library if the delta is rejected.
  ///
  /// Please note that calling this is a potentially dangerous thing to do,
  /// and that stuff *can* go wrong, and you could end up in a situation where
  /// you point to several versions of "the same" library. Examples:
  ///  * If you only relink part (e.g. a class) if your component you can wind
  ///    up in an unfortunate situation where if the library (say libA) contains
  ///    class 'B' and class 'C', you only replace 'B' (with one in library
  ///    'libAPrime'), everything pointing to 'B' via parent pointers talks
  ///    about 'libAPrime', whereas everything pointing to 'C' would still
  ///    ultimately point to 'libA'.
  ///  * If you relink to a library that doesn't have exactly the same members
  ///    as the one you're "linking from" you can wind up in an unfortunate
  ///    situation, e.g. if the thing you relink two is missing a static method,
  ///    any links to that static method will still point to the old static
  ///    method and thus (via parent pointers) to the old library.
  ///  * (probably more).
  void relink() {
    for (int i = 0; i < libraries.length; ++i) {
      libraries[i].relink();
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

  Procedure? get mainMethod => mainMethodName?.asProcedure;

  void setMainMethodAndMode(Reference? main, bool overwriteMainIfSet,
      NonNullableByDefaultCompiledMode mode) {
    if (_mainMethodName == null || overwriteMainIfSet) {
      _mainMethodName = main;
    }
    _mode = mode;
  }

  @override
  R accept<R>(TreeVisitor<R> v) => v.visitComponent(this);

  @override
  R accept1<R, A>(TreeVisitor1<R, A> v, A arg) => v.visitComponent(this, arg);

  @override
  void visitChildren(Visitor v) {
    visitList(libraries, v);
    mainMethod?.acceptReference(v);
  }

  @override
  void transformChildren(Transformer v) {
    v.transformList(libraries, this);
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    v.transformLibraryList(libraries, this);
  }

  @override
  Component get enclosingComponent => this;

  /// Translates an offset to line and column numbers in the given file.
  Location? getLocation(Uri? file, int offset) {
    return uriToSource[file]?.getLocation(file, offset);
  }

  /// Translates line and column numbers to an offset in the given file.
  ///
  /// Returns offset of the line and column in the file, or -1 if the
  /// source is not available or has no lines.
  /// Throws [RangeError] if line or calculated offset are out of range.
  int getOffset(Uri file, int line, int column) {
    return uriToSource[file]?.getOffset(line, column) ?? -1;
  }

  void addMetadataRepository(MetadataRepository repository) {
    metadata[repository.tag] = repository;
  }

  @override
  String toString() {
    return "Component(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    // TODO(johnniwinther): Implement this.
  }

  String leakingDebugToString() => astToText.debugComponentToString(this);
}

/// A tuple with file, line, and column number, for displaying human-readable
/// locations.
class Location {
  // TODO(johnniwinther): Make this non-nullable.
  final Uri? file;
  final int line; // 1-based.
  final int column; // 1-based.

  Location(this.file, this.line, this.column);

  String toString() => '$file:$line:$column';
}

abstract class MetadataRepository<T> {
  /// Unique string tag associated with this repository.
  String get tag;

  /// Mutable mapping between nodes and their metadata.
  Map<Node, T> get mapping;

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
  /// can't have metadata attached to them. Also, metadata is not saved on
  /// Block nodes inside BlockExpressions.
  static bool isSupported(Node node) {
    return !(node is MapEntry ||
        node is Catch ||
        (node is Block && node.parent is BlockExpression));
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
  void writeConstantReference(Constant constant);
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
  int readUInt30();
  int readUint32();

  /// Read List<Byte> from the source.
  List<int> readByteList();

  CanonicalName? readNullableCanonicalNameReference();
  String readStringReference();
  Name readName();
  DartType readDartType();
  Constant readConstantReference();
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
  for (Node node in nodes) {
    node.accept(visitor);
  }
}

class _ChildReplacer extends Transformer {
  final TreeNode child;
  final TreeNode replacement;

  _ChildReplacer(this.child, this.replacement);

  @override
  TreeNode defaultTreeNode(TreeNode node) {
    if (node == child) {
      return replacement;
    } else {
      return node;
    }
  }
}

class Source {
  final List<int>? lineStarts;

  /// A UTF8 encoding of the original source file.
  final List<int> source;

  final Uri? importUri;

  final Uri? fileUri;

  Set<Reference>? constantCoverageConstructors;

  String? cachedText;

  Source(this.lineStarts, this.source, this.importUri, this.fileUri);

  /// Return the text corresponding to [line] which is a 1-based line
  /// number. The returned line contains no line separators.
  String? getTextLine(int line) {
    List<int>? lineStarts = this.lineStarts;
    if (source.isEmpty || lineStarts == null || lineStarts.isEmpty) {
      return null;
    }
    RangeError.checkValueInInterval(line, 1, lineStarts.length, 'line');

    String cachedText =
        this.cachedText ??= utf8.decode(source, allowMalformed: true);
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

  /// Translates an offset to 1-based line and column numbers in the given file.
  Location getLocation(Uri? file, int offset) {
    List<int>? lineStarts = this.lineStarts;
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

  /// Translates 1-based line and column numbers to an offset in the given file
  ///
  /// Returns offset of the line and column in the file, or -1 if the source
  /// has no lines.
  /// Throws [RangeError] if line or calculated offset are out of range.
  int getOffset(int line, int column) {
    List<int>? lineStarts = this.lineStarts;
    if (lineStarts == null || lineStarts.isEmpty) {
      return -1;
    }
    RangeError.checkValueInInterval(line, 1, lineStarts.length, 'line');
    int offset = lineStarts[line - 1] + column - 1;
    RangeError.checkValueInInterval(offset, 0, lineStarts.last, 'offset');
    return offset;
  }
}

/// Returns the [Reference] object for the given member based on the
/// ProcedureKind.
///
/// Returns `null` if the member is `null`.
Reference? getMemberReferenceBasedOnProcedureKind(
    Member? member, ProcedureKind kind) {
  if (member == null) return null;
  if (member is Field) {
    if (kind == ProcedureKind.Setter) return member.setterReference!;
    return member.getterReference;
  }
  return member.reference;
}

/// Returns the (getter) [Reference] object for the given member.
///
/// Returns `null` if the member is `null`.
/// TODO(jensj): Should it be called NotSetter instead of Getter?
Reference? getMemberReferenceGetter(Member? member) {
  if (member == null) return null;
  return getNonNullableMemberReferenceGetter(member);
}

Reference getNonNullableMemberReferenceGetter(Member member) {
  if (member is Field) return member.getterReference;
  return member.reference;
}

/// Returns the setter [Reference] object for the given member.
///
/// Returns `null` if the member is `null`.
Reference? getMemberReferenceSetter(Member? member) {
  if (member == null) return null;
  return getNonNullableMemberReferenceSetter(member);
}

Reference getNonNullableMemberReferenceSetter(Member member) {
  if (member is Field) return member.setterReference!;
  return member.reference;
}

/// Returns the [Reference] object for the given class.
///
/// Returns `null` if the class is `null`.
Reference? getClassReference(Class? class_) {
  return class_?.reference;
}

/// Returns the [Reference] object for the given class.
Reference getNonNullableClassReference(Class class_) {
  return class_.reference;
}

/// Returns the canonical name of [member], or throws an exception if the
/// member has not been assigned a canonical name yet.
///
/// Returns `null` if the member is `null`.
CanonicalName? getCanonicalNameOfMemberGetter(Member? member) {
  if (member == null) return null;
  CanonicalName? canonicalName;
  if (member is Field) {
    canonicalName = member.getterCanonicalName;
  } else {
    canonicalName = member.canonicalName;
  }
  if (canonicalName == null) {
    throw '$member has no canonical name';
  }
  return canonicalName;
}

/// Returns the canonical name of [member], or throws an exception if the
/// member has not been assigned a canonical name yet.
///
/// Returns `null` if the member is `null`.
CanonicalName? getCanonicalNameOfMemberSetter(Member? member) {
  if (member == null) return null;
  CanonicalName? canonicalName;
  if (member is Field) {
    canonicalName = member.setterCanonicalName;
  } else {
    canonicalName = member.canonicalName;
  }
  if (canonicalName == null) {
    throw '$member has no canonical name';
  }
  return canonicalName;
}

/// Returns the canonical name of [class_], or throws an exception if the
/// class has not been assigned a canonical name yet.
///
/// Returns `null` if the class is `null`.
CanonicalName? getCanonicalNameOfClass(Class? class_) {
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
CanonicalName? getCanonicalNameOfExtension(Extension? extension) {
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
CanonicalName? getCanonicalNameOfLibrary(Library? library) {
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

  static int hash2(Object object1, Object? object2) {
    return combine2Finish(object2.hashCode, object2.hashCode, 0);
  }

  static int combineListHash(List<Object> list, [int hash = 1]) {
    for (Object item in list) {
      hash = _Hash.combine(item.hashCode, hash);
    }
    return hash;
  }

  static int combineList(List<int> hashes, int hash) {
    for (int item in hashes) {
      hash = combine(item, hash);
    }
    return hash;
  }

  static int combineMapHashUnordered(Map? map, [int hash = 2]) {
    if (map == null || map.isEmpty) return hash;
    List<int> entryHashes = List.filled(
        map.length,
        // `-1` is used as a dummy default value.
        -1);
    int i = 0;
    for (core.MapEntry entry in map.entries) {
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

int listHashCode(List<Object> list) {
  return _Hash.finish(_Hash.combineListHash(list));
}

int mapHashCode(Map map) {
  return mapHashCodeUnordered(map);
}

int mapHashCodeOrdered(Map map, [int hash = 2]) {
  for (final Object x in map.keys) {
    hash = _Hash.combine(x.hashCode, hash);
  }
  for (final Object x in map.values) {
    hash = _Hash.combine(x.hashCode, hash);
  }
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
CanonicalName? getCanonicalNameOfTypedef(Typedef? typedef_) {
  if (typedef_ == null) return null;
  if (typedef_.canonicalName == null) {
    throw '$typedef_ has no canonical name';
  }
  return typedef_.canonicalName;
}

/// Annotation describing information which is not part of Dart semantics; in
/// other words, if this information (or any information it refers to) changes,
/// static analysis and runtime behavior of the library are unaffected.
const Null informative = null;

Location? _getLocationInComponent(
    Component? component, Uri? fileUri, int offset) {
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

/// Computes a list of [typeParameters] taken as types.
List<DartType> getAsTypeArguments(
    List<TypeParameter> typeParameters, Library library) {
  if (typeParameters.isEmpty) return const <DartType>[];
  return new List<DartType>.generate(
      typeParameters.length,
      (int i) => new TypeParameterType.withDefaultNullabilityForLibrary(
          typeParameters[i], library),
      growable: false);
}

class Version extends Object {
  final int major;
  final int minor;

  const Version(this.major, this.minor)
      // ignore: unnecessary_null_comparison
      : assert(major != null),
        // ignore: unnecessary_null_comparison
        assert(minor != null);

  bool operator <(Version other) {
    if (major < other.major) return true;
    if (major > other.major) return false;

    // Major is the same.
    if (minor < other.minor) return true;
    return false;
  }

  bool operator <=(Version other) {
    if (major < other.major) return true;
    if (major > other.major) return false;

    // Major is the same.
    if (minor <= other.minor) return true;
    return false;
  }

  bool operator >(Version other) {
    if (major > other.major) return true;
    if (major < other.major) return false;

    // Major is the same.
    if (minor > other.minor) return true;
    return false;
  }

  bool operator >=(Version other) {
    if (major > other.major) return true;
    if (major < other.major) return false;

    // Major is the same.
    if (minor >= other.minor) return true;
    return false;
  }

  /// Returns this language version as a 'major.minor' text.
  String toText() => '${major}.${minor}';

  @override
  int get hashCode {
    return major.hashCode * 13 + minor.hashCode * 17;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Version && major == other.major && minor == other.minor;
  }

  @override
  String toString() {
    return "Version(major=$major, minor=$minor)";
  }
}

/// Almost const <NamedExpression>[], but not const in an attempt to avoid
/// polymorphism. See https://dart-review.googlesource.com/c/sdk/+/185828.
final List<NamedExpression> emptyListOfNamedExpression =
    List.filled(0, dummyNamedExpression, growable: false);

/// Almost const <VariableDeclaration>[], but not const in an attempt to avoid
/// polymorphism. See https://dart-review.googlesource.com/c/sdk/+/185828.
final List<VariableDeclaration> emptyListOfVariableDeclaration =
    List.filled(0, dummyVariableDeclaration, growable: false);

/// Almost const <Combinator>[], but not const in an attempt to avoid
/// polymorphism. See https://dart-review.googlesource.com/c/sdk/+/185828.
final List<Combinator> emptyListOfCombinator =
    List.filled(0, dummyCombinator, growable: false);

/// Almost const <Expression>[], but not const in an attempt to avoid
/// polymorphism. See https://dart-review.googlesource.com/c/sdk/+/185828.
final List<Expression> emptyListOfExpression =
    List.filled(0, dummyExpression, growable: false);

/// Almost const <AssertStatement>[], but not const in an attempt to avoid
/// polymorphism. See https://dart-review.googlesource.com/c/sdk/+/185828.
final List<AssertStatement> emptyListOfAssertStatement =
    List.filled(0, dummyAssertStatement, growable: false);

/// Almost const <Statement>[], but not const in an attempt to avoid
/// polymorphism. See https://dart-review.googlesource.com/c/sdk/+/185828.
final List<Statement> emptyListOfStatement =
    List.filled(0, dummyStatement, growable: false);

/// Almost const <SwitchCase>[], but not const in an attempt to avoid
/// polymorphism. See https://dart-review.googlesource.com/c/sdk/+/185828.
final List<SwitchCase> emptyListOfSwitchCase =
    List.filled(0, dummySwitchCase, growable: false);

/// Almost const <Catch>[], but not const in an attempt to avoid
/// polymorphism. See https://dart-review.googlesource.com/c/sdk/+/185828.
final List<Catch> emptyListOfCatch =
    List.filled(0, dummyCatch, growable: false);

/// Almost const <Supertype>[], but not const in an attempt to avoid
/// polymorphism. See https://dart-review.googlesource.com/c/sdk/+/185828.
final List<Supertype> emptyListOfSupertype =
    List.filled(0, dummySupertype, growable: false);

/// Almost const <DartType>[], but not const in an attempt to avoid
/// polymorphism. See https://dart-review.googlesource.com/c/sdk/+/185828.
final List<DartType> emptyListOfDartType =
    List.filled(0, dummyDartType, growable: false);

/// Almost const <NamedType>[], but not const in an attempt to avoid
/// polymorphism. See https://dart-review.googlesource.com/c/sdk/+/185828.
final List<NamedType> emptyListOfNamedType =
    List.filled(0, dummyNamedType, growable: false);

/// Almost const <TypeParameter>[], but not const in an attempt to avoid
/// polymorphism. See https://dart-review.googlesource.com/c/sdk/+/185828.
final List<TypeParameter> emptyListOfTypeParameter =
    List.filled(0, dummyTypeParameter, growable: false);

/// Non-nullable [DartType] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final DartType dummyDartType = new DynamicType();

/// Non-nullable [Supertype] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final Supertype dummySupertype = new Supertype(dummyClass, const []);

/// Non-nullable [NamedType] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final NamedType dummyNamedType =
    new NamedType('', dummyDartType, isRequired: false);

/// Non-nullable [Uri] dummy value.
final Uri dummyUri = new Uri(scheme: 'dummy');

/// Non-nullable [Name] dummy value.
final Name dummyName = new _PublicName('');

/// Non-nullable [Library] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final Library dummyLibrary = new Library(dummyUri);

/// Non-nullable [LibraryDependency] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final LibraryDependency dummyLibraryDependency =
    new LibraryDependency.import(dummyLibrary);

/// Non-nullable [Combinator] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final Combinator dummyCombinator = new Combinator(false, const []);

/// Non-nullable [LibraryPart] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final LibraryPart dummyLibraryPart = new LibraryPart(const [], '');

/// Non-nullable [Class] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final Class dummyClass = new Class(name: '');

/// Non-nullable [Constructor] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final Constructor dummyConstructor = new Constructor(dummyFunctionNode);

/// Non-nullable [Extension] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final Extension dummyExtension = new Extension(name: '');

/// Non-nullable [Member] dummy value.
///
/// This can be used for instance as a dummy initial value for the
/// `List.filled` constructor.
final Member dummyMember = new Field.mutable(new _PublicName(''));

/// Non-nullable [Procedure] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final Procedure dummyProcedure =
    new Procedure(dummyName, ProcedureKind.Method, dummyFunctionNode);

/// Non-nullable [Field] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final Field dummyField = new Field.mutable(dummyName);

/// Non-nullable [RedirectingFactoryConstructor] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final RedirectingFactoryConstructor dummyRedirectingFactoryConstructor =
    new RedirectingFactoryConstructor(null);

/// Non-nullable [Typedef] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final Typedef dummyTypedef = new Typedef('', null);

/// Non-nullable [Initializer] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final Initializer dummyInitializer = new InvalidInitializer();

/// Non-nullable [FunctionNode] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final FunctionNode dummyFunctionNode = new FunctionNode(null);

/// Non-nullable [Statement] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final Statement dummyStatement = new EmptyStatement();

/// Non-nullable [Expression] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final Expression dummyExpression = new NullLiteral();

/// Non-nullable [NamedExpression] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final NamedExpression dummyNamedExpression =
    new NamedExpression('', dummyExpression);

/// Non-nullable [VariableDeclaration] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final VariableDeclaration dummyVariableDeclaration =
    new VariableDeclaration(null);

/// Non-nullable [TypeParameter] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final TypeParameter dummyTypeParameter = new TypeParameter();

/// Non-nullable [MapEntry] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final MapEntry dummyMapEntry = new MapEntry(dummyExpression, dummyExpression);

/// Non-nullable [Arguments] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final Arguments dummyArguments = new Arguments(const []);

/// Non-nullable [AssertStatement] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final AssertStatement dummyAssertStatement = new AssertStatement(
    dummyExpression,
    conditionStartOffset: TreeNode.noOffset,
    conditionEndOffset: TreeNode.noOffset);

/// Non-nullable [SwitchCase] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final SwitchCase dummySwitchCase = new SwitchCase.defaultCase(dummyStatement);

/// Non-nullable [Catch] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final Catch dummyCatch = new Catch(null, dummyStatement);

/// Sentinel value used to signal that a node cannot be removed through the
/// [RemovingTransformer].
const Null cannotRemoveSentinel = null;

/// Helper that can be used in asserts to check that [list] is mutable by
/// adding and removing [dummyElement].
bool checkListIsMutable<E>(List<E> list, E dummyElement) {
  list
    ..add(dummyElement)
    ..removeLast();
  return true;
}
