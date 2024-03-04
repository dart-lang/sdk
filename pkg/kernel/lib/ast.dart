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

import 'src/extension_type_erasure.dart';
import 'visitor.dart';
export 'visitor.dart';

import 'canonical_name.dart' show CanonicalName, Reference;
export 'canonical_name.dart' show CanonicalName, Reference;

import 'default_language_version.dart' show defaultLanguageVersion;
export 'default_language_version.dart' show defaultLanguageVersion;

import 'transformations/flags.dart';
import 'text/ast_to_text.dart' as astToText;
import 'core_types.dart';
import 'type_algebra.dart';
import 'type_environment.dart';
import 'src/assumptions.dart';
import 'src/non_null.dart';
import 'src/printer.dart';
import 'src/text_util.dart';

part 'src/ast/patterns.dart';

/// Any type of node in the IR.
abstract class Node {
  const Node();

  R accept<R>(Visitor<R> v);
  R accept1<R, A>(Visitor1<R, A> v, A arg);
  void visitChildren(Visitor v);

  /// Returns the textual representation of this node for use in debugging.
  ///
  /// [toString] should only be used for debugging, but should not leak.
  ///
  /// The data is generally bare-bones, but can easily be updated for your
  /// specific debugging needs.
  @override
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
  @override
  final int hashCode = _hashCounter = (_hashCounter + 1) & 0x3fffffff;
  static const int noOffset = -1;

  TreeNode? parent;

  /// Offset in the source file it comes from.
  ///
  /// Valid values are from 0 and up, or -1 ([noOffset]) if the file offset is
  /// not available (this is the default if none is specifically set).
  int fileOffset = noOffset;

  /// Returns List<int> if this node has more offsets than [fileOffset].
  List<int>? get fileOffsetsIfMultiple => null;

  @override
  R accept<R>(TreeVisitor<R> v);
  @override
  R accept1<R, A>(TreeVisitor1<R, A> v, A arg);
  @override
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
    this.reference.node = this;
  }

  /// This is an advanced feature.
  ///
  /// See [Component.relink] for a comprehensive description.
  ///
  /// Makes sure the reference in this named node points to itself.
  void _relinkNode() {
    this.reference.node = this;
  }

  /// Computes the canonical names for this node using the [parent] as the
  /// canonical name of the parent node.
  void bindCanonicalNames(CanonicalName parent);
}

abstract class FileUriNode extends TreeNode {
  /// The URI of the source file this node was loaded from.
  Uri get fileUri;

  void set fileUri(Uri value);
}

abstract class Annotatable extends TreeNode {
  List<Expression> get annotations;
  void addAnnotation(Expression node);
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
  Uri fileUri;

  Version? _languageVersion;
  Version get languageVersion => _languageVersion ?? defaultLanguageVersion;

  void setLanguageVersion(Version languageVersion) {
    _languageVersion = languageVersion;
  }

  static const int SyntheticFlag = 1 << 0;
  static const int NonNullableByDefaultFlag = 1 << 1;
  static const int NonNullableByDefaultModeBit1 = 1 << 2;
  static const int NonNullableByDefaultModeBit2 = 1 << 3;
  static const int IsUnsupportedFlag = 1 << 4;

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

  /// If true, the library is not supported through the 'dart.library.*' value
  /// used in conditional imports and `bool.fromEnvironment` constants.
  bool get isUnsupported => flags & IsUnsupportedFlag != 0;
  void set isUnsupported(bool value) {
    flags = value ? (flags | IsUnsupportedFlag) : (flags & ~IsUnsupportedFlag);
  }

  String? name;

  /// Problems in this [Library] encoded as json objects.
  ///
  /// Note that this field can be null, and by convention should be null if the
  /// list is empty.
  List<String>? problemsAsJson;

  @override
  List<Expression> annotations;

  List<LibraryDependency> dependencies;

  /// References to nodes exported by `export` declarations that:
  /// - aren't ambiguous, or
  /// - aren't hidden by local declarations.
  final List<Reference> additionalExports = <Reference>[];

  @informative
  List<LibraryPart> parts;

  List<Typedef> _typedefs;
  List<Class> _classes;
  List<Extension> _extensions;
  List<ExtensionTypeDeclaration> _extensionTypeDeclarations;
  List<Procedure> _procedures;
  List<Field> _fields;

  Library(this.importUri,
      {this.name,
      List<Expression>? annotations,
      List<LibraryDependency>? dependencies,
      List<LibraryPart>? parts,
      List<Typedef>? typedefs,
      List<Class>? classes,
      List<Extension>? extensions,
      List<ExtensionTypeDeclaration>? extensionTypeDeclarations,
      List<Procedure>? procedures,
      List<Field>? fields,
      required this.fileUri,
      Reference? reference})
      : this.annotations = annotations ?? <Expression>[],
        this.dependencies = dependencies ?? <LibraryDependency>[],
        this.parts = parts ?? <LibraryPart>[],
        this._typedefs = typedefs ?? <Typedef>[],
        this._classes = classes ?? <Class>[],
        this._extensions = extensions ?? <Extension>[],
        this._extensionTypeDeclarations =
            extensionTypeDeclarations ?? <ExtensionTypeDeclaration>[],
        this._procedures = procedures ?? <Procedure>[],
        this._fields = fields ?? <Field>[],
        super(reference) {
    setParents(this.dependencies, this);
    setParents(this.parts, this);
    setParents(this._typedefs, this);
    setParents(this._classes, this);
    setParents(this._extensions, this);
    setParents(this._procedures, this);
    setParents(this._fields, this);
  }

  List<Typedef> get typedefs => _typedefs;

  /// Internal. Should *ONLY* be used from within kernel.
  ///
  /// Used for adding typedefs when reading the dill file.
  void set typedefsInternal(List<Typedef> typedefs) {
    _typedefs = typedefs;
  }

  List<Class> get classes => _classes;

  /// Internal. Should *ONLY* be used from within kernel.
  ///
  /// Used for adding classes when reading the dill file.
  void set classesInternal(List<Class> classes) {
    _classes = classes;
  }

  List<Extension> get extensions => _extensions;

  /// Internal. Should *ONLY* be used from within kernel.
  ///
  /// Used for adding extensions when reading the dill file.
  void set extensionsInternal(List<Extension> extensions) {
    _extensions = extensions;
  }

  List<ExtensionTypeDeclaration> get extensionTypeDeclarations =>
      _extensionTypeDeclarations;

  /// Internal. Should *ONLY* be used from within kernel.
  ///
  /// Used for adding extension type declarations when reading the dill file.
  void set extensionTypeDeclarationsInternal(
      List<ExtensionTypeDeclaration> extensionTypeDeclarations) {
    _extensionTypeDeclarations = extensionTypeDeclarations;
  }

  List<Procedure> get procedures => _procedures;

  /// Internal. Should *ONLY* be used from within kernel.
  ///
  /// Used for adding procedures when reading the dill file.
  void set proceduresInternal(List<Procedure> procedures) {
    _procedures = procedures;
  }

  List<Field> get fields => _fields;

  /// Internal. Should *ONLY* be used from within kernel.
  ///
  /// Used for adding fields when reading the dill file.
  void set fieldsInternal(List<Field> fields) {
    _fields = fields;
  }

  Nullability get nullable {
    return isNonNullableByDefault ? Nullability.nullable : Nullability.legacy;
  }

  Nullability get nonNullable {
    return isNonNullableByDefault
        ? Nullability.nonNullable
        : Nullability.legacy;
  }

  /// Returns the top-level fields and procedures defined in this library.
  ///
  /// This getter is for convenience, not efficiency.  Consider manually
  /// iterating the members to speed up code in production.
  Iterable<Member> get members =>
      <Iterable<Member>>[fields, procedures].expand((x) => x);

  void forEachMember(void action(Member element)) {
    fields.forEach(action);
    procedures.forEach(action);
  }

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

  void addExtensionTypeDeclaration(
      ExtensionTypeDeclaration extensionTypeDeclaration) {
    extensionTypeDeclaration.parent = this;
    extensionTypeDeclarations.add(extensionTypeDeclaration);
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

  @override
  CanonicalName bindCanonicalNames(CanonicalName parent) {
    return parent.getChildFromUri(importUri)..bindTo(reference);
  }

  /// Computes the canonical name for this library and all its members.
  void ensureCanonicalNames(CanonicalName parent) {
    CanonicalName canonicalName = bindCanonicalNames(parent);
    for (int i = 0; i < typedefs.length; ++i) {
      typedefs[i].bindCanonicalNames(canonicalName);
    }
    for (int i = 0; i < fields.length; ++i) {
      fields[i].bindCanonicalNames(canonicalName);
    }
    for (int i = 0; i < procedures.length; ++i) {
      procedures[i].bindCanonicalNames(canonicalName);
    }
    for (int i = 0; i < classes.length; ++i) {
      classes[i].ensureCanonicalNames(canonicalName);
    }
    for (int i = 0; i < extensions.length; ++i) {
      extensions[i].bindCanonicalNames(canonicalName);
    }
    for (int i = 0; i < extensionTypeDeclarations.length; ++i) {
      extensionTypeDeclarations[i].ensureCanonicalNames(canonicalName);
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
    for (int i = 0; i < extensionTypeDeclarations.length; ++i) {
      ExtensionTypeDeclaration extensionTypeDeclaration =
          extensionTypeDeclarations[i];
      extensionTypeDeclaration.relink();
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
    visitList(extensionTypeDeclarations, v);
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
    v.transformList(extensionTypeDeclarations, this);
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
    v.transformExtensionTypeDeclarationList(extensionTypeDeclarations, this);
    v.transformProcedureList(procedures, this);
    v.transformFieldList(fields, this);
  }

  static int _libraryIdCounter = 0;
  int _libraryId = ++_libraryIdCounter;
  int get libraryIdForTesting => _libraryId;

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

  @override
  Location? _getLocationInEnclosingFile(int offset) {
    return _getLocationInComponent(enclosingComponent, fileUri, offset);
  }

  @override
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
class LibraryDependency extends TreeNode implements Annotatable {
  int flags;

  @override
  final List<Expression> annotations;

  Reference importedLibraryReference;

  /// The name of the import prefix, if any, or `null` if this is not an import
  /// with a prefix.
  ///
  /// Must be non-null for deferred imports, and must be null for exports.
  String? name;

  final List<Combinator> combinators;

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

  @override
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
    if (isExport) {
      printer.write('export ');
    } else {
      printer.write('import ');
    }
    if (isDeferred) {
      printer.write('deferred ');
    }
    printer.writeLibraryReference(importedLibraryReference);
    printer.write(';');
  }
}

/// A part declaration in a library.
///
///     part <url>;
///
/// optionally with metadata.
class LibraryPart extends TreeNode implements Annotatable {
  @override
  final List<Expression> annotations;

  final String partUri;

  LibraryPart(this.annotations, this.partUri) {
    setParents(annotations, this);
  }

  @override
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
class Typedef extends NamedNode
    implements FileUriNode, Annotatable, GenericDeclaration {
  /// The URI of the source file that contains the declaration of this typedef.
  @override
  Uri fileUri;

  @override
  List<Expression> annotations = const <Expression>[];

  String name;

  @override
  final List<TypeParameter> typeParameters;

  // TODO(johnniwinther): Make this non-nullable.
  DartType? type;

  Typedef(this.name, this.type,
      {Reference? reference,
      required this.fileUri,
      List<TypeParameter>? typeParameters,
      List<TypeParameter>? typeParametersOfFunctionType,
      List<VariableDeclaration>? positionalParameters,
      List<VariableDeclaration>? namedParameters})
      : this.typeParameters = typeParameters ?? <TypeParameter>[],
        super(reference) {
    setParents(this.typeParameters, this);
  }

  @override
  void bindCanonicalNames(CanonicalName parent) {
    parent.getChildFromTypedef(this).bindTo(reference);
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

  @override
  void addAnnotation(Expression node) {
    if (annotations.isEmpty) {
      annotations = <Expression>[];
    }
    annotations.add(node);
    node.parent = this;
  }

  @override
  Location? _getLocationInEnclosingFile(int offset) {
    return _getLocationInComponent(enclosingComponent, fileUri, offset);
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

/// Declaration that can introduce [TypeParameter]s.
sealed class GenericDeclaration implements TreeNode {
  /// The type parameters introduced by this declaration.
  List<TypeParameter> get typeParameters;
}

/// Functions that can introduce [TypeParameter]s.
sealed class GenericFunction implements GenericDeclaration {
  /// The [FunctionNode] that holds the introduced [typeParameters].
  FunctionNode get function;
}

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
    return _getLocationInComponent(enclosingComponent, fileUri, offset);
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
  static const int FlagExtensionTypeDeclaration = 1 << 0;
  static const int FlagUnnamedExtension = 1 << 1;

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

  bool get isExtensionTypeDeclaration {
    return flags & FlagExtensionTypeDeclaration != 0;
  }

  void set isExtensionTypeDeclaration(bool value) {
    flags = value
        ? (flags | FlagExtensionTypeDeclaration)
        : (flags & ~FlagExtensionTypeDeclaration);
  }

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
    return _getLocationInComponent(enclosingComponent, fileUri, offset);
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
    return _getLocationInComponent(enclosingComponent, fileUri, offset);
  }

  @override
  String toString() {
    return "ExtensionTypeDeclaration(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeExtensionTypeDeclarationName(reference);
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

  /// If `true` this member is defined in a library for which non-nullable by
  /// default is enabled.
  bool get isNonNullableByDefault;

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
  static const int FlagNonNullableByDefault = 1 << 7;
  static const int FlagInternalImplementation = 1 << 8;
  static const int FlagEnumElement = 1 << 9;
  static const int FlagExtensionTypeMember = 1 << 10;

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
  bool get isNonNullableByDefault => flags & FlagNonNullableByDefault != 0;

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
    return _getLocationInComponent(enclosingComponent, fileUri, offset);
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
  bool get isNonNullableByDefault => flags & FlagNonNullableByDefault != 0;

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
    return _getLocationInComponent(enclosingComponent, fileUri, offset);
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
  /// `function.computeFunctionType(Nullability.nonNullable)`.
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
  static const int FlagNonNullableByDefault = 1 << 5;
  static const int FlagSynthetic = 1 << 6;
  static const int FlagInternalImplementation = 1 << 7;
  static const int FlagExtensionTypeMember = 1 << 8;
  static const int FlagHasWeakTearoffReferencePragma = 1 << 9;

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

  @override
  bool get isNonNullableByDefault => flags & FlagNonNullableByDefault != 0;

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

  bool get hasWeakTearoffReferencePragma =>
      flags & FlagHasWeakTearoffReferencePragma != 0;

  void set hasWeakTearoffReferencePragma(bool value) {
    flags = value
        ? (flags | FlagHasWeakTearoffReferencePragma)
        : (flags & ~FlagHasWeakTearoffReferencePragma);
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
sealed class Initializer extends TreeNode {
  /// True if this is a synthetic constructor initializer.
  @informative
  bool isSynthetic = false;

  @override
  R accept<R>(InitializerVisitor<R> v);

  @override
  R accept1<R, A>(InitializerVisitor1<R, A> v, A arg);
}

abstract class AuxiliaryInitializer extends Initializer {
  @override
  R accept<R>(InitializerVisitor<R> v) => v.visitAuxiliaryInitializer(this);

  @override
  R accept1<R, A>(InitializerVisitor1<R, A> v, A arg) =>
      v.visitAuxiliaryInitializer(this, arg);
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
      : this.byReference(field.fieldReference, value);

  FieldInitializer.byReference(this.fieldReference, this.value) {
    value.parent = this;
  }

  Field get field => fieldReference.asField;

  void set field(Field field) {
    fieldReference = field.fieldReference;
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
    value = v.transform(value);
    value.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    value = v.transform(value);
    value.parent = this;
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
    arguments = v.transform(arguments);
    arguments.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    arguments = v.transform(arguments);
    arguments.parent = this;
  }

  @override
  String toString() {
    return "SuperInitializer(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('super');
    if (target.name.text.isNotEmpty) {
      printer.write('.');
      printer.write(target.name.text);
    }
    printer.writeArguments(arguments, includeTypeArguments: false);
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
    arguments = v.transform(arguments);
    arguments.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    arguments = v.transform(arguments);
    arguments.parent = this;
  }

  @override
  String toString() {
    return "RedirectingInitializer(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('this');
    if (target.name.text.isNotEmpty) {
      printer.write('.');
      printer.write(target.name.text);
    }
    printer.writeArguments(arguments, includeTypeArguments: false);
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
    variable = v.transform(variable);
    variable.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    variable = v.transform(variable);
    variable.parent = this;
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
    statement.toTextInternal(printer);
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

  @override
  List<int>? get fileOffsetsIfMultiple => [fileOffset, fileEndOffset];

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

  /// The emitted value of non-sync functions
  ///
  /// For `async` functions [emittedValueType] is the future value type, that
  /// is, the returned element type. For instance
  ///
  ///     Future<Foo> method1() async => new Foo();
  ///     FutureOr<Foo> method2() async => new Foo();
  ///
  /// here the return types are `Future<Foo>` and `FutureOr<Foo>` for `method1`
  /// and `method2`, respectively, but the future value type is in both cases
  /// `Foo`.
  ///
  /// For pre-nnbd libraries, this is set to `flatten(T)` of the return type
  /// `T`, which can be seen as the pre-nnbd equivalent of the future value
  /// type.
  ///
  /// For `sync*` functions [emittedValueType] is the type of the element of the
  /// iterable returned by the function.
  ///
  /// For `async*` functions [emittedValueType] is the type of the element of
  /// the stream return ed by the function.
  ///
  /// For sync functions (those not marked with one of `async`, `sync*`, or
  /// `async*`) the value of [emittedValueType] is null.
  DartType? emittedValueType;

  /// If the function is a redirecting factory constructor, this holds
  /// the target and type arguments of the redirection.
  RedirectingFactoryTarget? redirectingFactoryTarget;

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
      this.returnType = const DynamicType(),
      this.asyncMarker = AsyncMarker.Sync,
      AsyncMarker? dartAsyncMarker,
      this.emittedValueType})
      : this.positionalParameters =
            positionalParameters ?? <VariableDeclaration>[],
        this.requiredParameterCount =
            requiredParameterCount ?? positionalParameters?.length ?? 0,
        this.namedParameters = namedParameters ?? <VariableDeclaration>[],
        this.typeParameters = typeParameters ?? <TypeParameter>[],
        this.dartAsyncMarker = dartAsyncMarker ?? asyncMarker {
    setParents(this.typeParameters, this);
    setParents(this.positionalParameters, this);
    setParents(this.namedParameters, this);
    _body?.parent = this;
  }

  static DartType _getTypeOfVariable(VariableDeclaration node) => node.type;

  static NamedType _getNamedTypeOfVariable(VariableDeclaration node,
      [Substitution? substitution]) {
    return new NamedType(
        node.name!,
        substitution != null
            ? substitution.substituteType(node.type)
            : node.type,
        isRequired: node.isRequired);
  }

  /// Returns the function type of the node reusing its type parameters.
  ///
  /// This getter works similarly to [functionType], but reuses type parameters
  /// of the function node (or the class enclosing it -- see the comment on
  /// [functionType] about constructors of generic classes) in the result.  It
  /// is useful in some contexts, especially when reasoning about the function
  /// type of the enclosing generic function and in combination with
  /// [FunctionType.withoutTypeParameters].
  FunctionType computeThisFunctionType(Nullability nullability,
      {bool reuseTypeParameters = false}) {
    TreeNode? parent = this.parent;

    List<StructuralParameter> structuralParameters;
    List<TypeParameter> typeParametersToCopy = parent is Constructor
        ? parent.enclosingClass.typeParameters
        : typeParameters;
    DartType returnType;
    List<DartType> positionalParameters;
    List<NamedType> namedParameters;
    if (typeParametersToCopy.isEmpty || reuseTypeParameters) {
      structuralParameters = const <StructuralParameter>[];
      returnType = this.returnType;
      List<VariableDeclaration> thisPositionals = this.positionalParameters;
      positionalParameters = List.generate(thisPositionals.length,
          (index) => _getTypeOfVariable(thisPositionals[index]),
          growable: false);

      List<VariableDeclaration> thisNamed = this.namedParameters;
      if (thisNamed.isEmpty) {
        namedParameters = const <NamedType>[];
      } else {
        namedParameters = List.generate(thisNamed.length,
            (index) => _getNamedTypeOfVariable(thisNamed[index]),
            growable: false);
        namedParameters.sort();
      }
    } else {
      // We need create a copy of the list of type parameters, otherwise
      // transformations like erasure don't work.
      FreshStructuralParametersFromTypeParameters freshStructuralParameters =
          getFreshStructuralParametersFromTypeParameters(typeParametersToCopy);
      structuralParameters = freshStructuralParameters.freshTypeParameters;
      Substitution substitution = freshStructuralParameters.substitution;
      returnType = substitution.substituteType(this.returnType);

      List<VariableDeclaration> thisPositionals = this.positionalParameters;
      positionalParameters = List.generate(
          thisPositionals.length,
          (index) => substitution
              .substituteType(_getTypeOfVariable(thisPositionals[index])),
          growable: false);
      List<VariableDeclaration> thisNamed = this.namedParameters;
      if (thisNamed.isEmpty) {
        namedParameters = const <NamedType>[];
      } else {
        namedParameters = List.generate(thisNamed.length,
            (index) => _getNamedTypeOfVariable(thisNamed[index], substitution),
            growable: false);
        namedParameters.sort();
      }
    }
    // TODO(johnniwinther,cstefantsova): Cache the function type here and use
    // [DartType.withDeclaredNullability] to handle the variants.
    return new FunctionType(positionalParameters, returnType, nullability,
        namedParameters: namedParameters,
        typeParameters: structuralParameters,
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
  // TODO(johnniwinther,cstefantsova): Merge it with [computeThisFunctionType].
  FunctionType computeFunctionType(Nullability nullability) {
    return computeThisFunctionType(nullability);
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
    emittedValueType?.accept(v);
    redirectingFactoryTarget?.target?.acceptReference(v);
    if (redirectingFactoryTarget?.typeArguments != null) {
      visitList(redirectingFactoryTarget!.typeArguments!, v);
    }
    body?.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    v.transformList(typeParameters, this);
    v.transformList(positionalParameters, this);
    v.transformList(namedParameters, this);
    returnType = v.visitDartType(returnType);
    if (emittedValueType != null) {
      emittedValueType = v.visitDartType(emittedValueType!);
    }
    if (redirectingFactoryTarget?.typeArguments != null) {
      v.transformDartTypeList(redirectingFactoryTarget!.typeArguments!);
    }
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
    if (emittedValueType != null) {
      emittedValueType =
          v.visitDartType(emittedValueType!, cannotRemoveSentinel);
    }
    if (redirectingFactoryTarget?.typeArguments != null) {
      v.transformDartTypeList(redirectingFactoryTarget!.typeArguments!);
    }
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

// ------------------------------------------------------------------------
//                                EXPRESSIONS
// ------------------------------------------------------------------------

sealed class Expression extends TreeNode {
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
    DartType type = getStaticType(context).nonTypeVariableBound;
    if (type is NullType) {
      return context.typeEnvironment.coreTypes
          .bottomInterfaceType(superclass, context.nullable);
    } else if (type is NeverType) {
      return context.typeEnvironment.coreTypes
          .bottomInterfaceType(superclass, type.nullability);
    }
    if (type is TypeDeclarationType) {
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

/// Abstract subclass of [Expression] that can be used to add [Expression]
/// subclasses from outside `package:kernel`.
abstract class AuxiliaryExpression extends Expression {
  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitAuxiliaryExpression(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitAuxiliaryExpression(this, arg);
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

  /// The expression containing the error.
  Expression? expression;

  InvalidExpression(this.message, [this.expression]) {
    expression?.parent = this;
  }

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
    return "InvalidExpression(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('<invalid:');
    printer.write(message ?? '');
    if (expression != null) {
      printer.write(', ');
      printer.writeExpression(expression!);
    }
    printer.write('>');
  }
}

/// Read a local variable, a local function, or a function parameter.
class VariableGet extends Expression {
  VariableDeclaration variable;
  DartType? promotedType; // Null if not promoted.

  VariableGet(this.variable, [this.promotedType]);

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

  VariableSet(this.variable, this.value) {
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
    value = v.transform(value);
    value.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    value = v.transform(value);
    value.parent = this;
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

class RecordIndexGet extends Expression {
  Expression receiver;
  RecordType receiverType;
  final int index;

  RecordIndexGet(this.receiver, this.receiverType, this.index)
      : assert(0 <= index && index < receiverType.positional.length) {
    receiver.parent = this;
  }

  @override
  DartType getStaticType(StaticTypeContext context) =>
      getStaticTypeInternal(context);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) {
    assert(index < receiverType.positional.length);
    return receiverType.positional[index];
  }

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitRecordIndexGet(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitRecordIndexGet(this, arg);

  @override
  void visitChildren(Visitor v) {
    receiver.accept(v);
    receiverType.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    receiver = v.transform(receiver)..parent = this;
    receiverType = v.visitDartType(receiverType) as RecordType;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    receiver = v.transform(receiver)..parent = this;
    receiverType =
        v.visitDartType(receiverType, cannotRemoveSentinel) as RecordType;
  }

  @override
  String toString() {
    return "RecordIndexGet(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(receiver);
    printer.write(".\$${index + 1}");
  }
}

class RecordNameGet extends Expression {
  Expression receiver;
  RecordType receiverType;
  final String name;

  RecordNameGet(this.receiver, this.receiverType, this.name)
      : assert(receiverType.named
                .singleWhere((element) => element.name == name)
                .name ==
            name) {
    receiver.parent = this;
  }

  @override
  DartType getStaticType(StaticTypeContext context) =>
      getStaticTypeInternal(context);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) {
    DartType? result;
    for (NamedType namedType in receiverType.named) {
      if (namedType.name == name) {
        result = namedType.type;
        break;
      }
    }
    assert(result != null);

    return result!;
  }

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitRecordNameGet(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitRecordNameGet(this, arg);

  @override
  void visitChildren(Visitor v) {
    receiver.accept(v);
    receiverType.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    receiver = v.transform(receiver)..parent = this;
    receiverType = v.visitDartType(receiverType) as RecordType;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    receiver = v.transform(receiver)..parent = this;
    receiverType =
        v.visitDartType(receiverType, cannotRemoveSentinel) as RecordType;
  }

  @override
  String toString() {
    return "RecordNameGet(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(receiver);
    printer.write(".${name}");
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

  /// An access of an unresolved target.
  ///
  /// An access of this kind always results in a value of an invalid static
  /// type.
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
    receiver = v.transform(receiver);
    receiver.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    receiver = v.transform(receiver);
    receiver.parent = this;
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

/// A property read of an instance getter or field with a statically known
/// interface target.
class InstanceGet extends Expression {
  final InstanceAccessKind kind;
  Expression receiver;

  // TODO(johnniwinther): Can we pull this from the [interfaceTarget] instead?
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
      {required this.interfaceTargetReference, required this.resultType}) {
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
    resultType.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    receiver = v.transform(receiver);
    receiver.parent = this;
    resultType = v.visitDartType(resultType);
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    receiver = v.transform(receiver);
    receiver.parent = this;
    resultType = v.visitDartType(resultType, cannotRemoveSentinel);
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
    receiver = v.transform(receiver);
    receiver.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    receiver = v.transform(receiver);
    receiver.parent = this;
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

  // TODO(johnniwinther): Can we pull this from the [interfaceTarget] instead?
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
    resultType.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    receiver = v.transform(receiver);
    receiver.parent = this;
    resultType = v.visitDartType(resultType);
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    receiver = v.transform(receiver);
    receiver.parent = this;
    resultType = v.visitDartType(resultType, cannotRemoveSentinel);
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
    receiver = v.transform(receiver);
    receiver.parent = this;
    value = v.transform(value);
    value.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    receiver = v.transform(receiver);
    receiver.parent = this;
    value = v.transform(value);
    value.parent = this;
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

  // TODO(johnniwinther): Can we pull this from the [interfaceTarget] instead?
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
      {required this.interfaceTargetReference}) {
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
    receiver = v.transform(receiver);
    receiver.parent = this;
    value = v.transform(value);
    value.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    receiver = v.transform(receiver);
    receiver.parent = this;
    value = v.transform(value);
    value.parent = this;
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

/// Expression of form `super.foo` occurring in a mixin declaration.
///
/// In this setting, the target is looked up on the types in the mixin 'on'
/// clause and are therefore not necessary the runtime targets of the read. An
/// [AbstractSuperPropertyGet] must be converted into a [SuperPropertyGet] to
/// statically bind the target.
///
/// For instance
///
///    abstract class Interface {
///      get getter;
///    }
///    mixin Mixin on Interface {
///      get getter {
///        // This is an [AbstractSuperPropertyGet] with interface target
///        // `Interface.getter`.
///        return super.getter;
///      }
///    }
///    class Super implements Interface {
///      // This is the target when `Mixin` is applied to `Class`.
///      get getter => 42;
///    }
///    class Class extends Super with Mixin {}
///
/// This may invoke a getter, read a field, or tear off a method.
class AbstractSuperPropertyGet extends Expression {
  Name name;

  Reference interfaceTargetReference;

  AbstractSuperPropertyGet(Name name, Member interfaceTarget)
      : this.byReference(
            name, getNonNullableMemberReferenceGetter(interfaceTarget));

  AbstractSuperPropertyGet.byReference(
      this.name, this.interfaceTargetReference);

  Member get interfaceTarget => interfaceTargetReference.asMember;

  void set interfaceTarget(Member member) {
    interfaceTargetReference = getNonNullableMemberReferenceGetter(member);
  }

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) {
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
  R accept<R>(ExpressionVisitor<R> v) => v.visitAbstractSuperPropertyGet(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitAbstractSuperPropertyGet(this, arg);

  @override
  void visitChildren(Visitor v) {
    interfaceTarget.acceptReference(v);
    name.accept(v);
  }

  @override
  void transformChildren(Transformer v) {}

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {}

  @override
  String toString() {
    return "AbstractSuperPropertyGet(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('super.{abstract}');
    printer.writeInterfaceMemberName(interfaceTargetReference, name);
  }
}

/// Expression of form `super.field`.
///
/// This may invoke a getter, read a field, or tear off a method.
class SuperPropertyGet extends Expression {
  Name name;

  Reference interfaceTargetReference;

  SuperPropertyGet(Name name, Member interfaceTarget)
      : this.byReference(
            name, getNonNullableMemberReferenceGetter(interfaceTarget));

  SuperPropertyGet.byReference(this.name, this.interfaceTargetReference);

  Member get interfaceTarget => interfaceTargetReference.asMember;

  void set interfaceTarget(Member member) {
    interfaceTargetReference = getNonNullableMemberReferenceGetter(member);
  }

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) {
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
    interfaceTarget.acceptReference(v);
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

/// Expression of form `super.foo = x` occurring in a mixin declaration.
///
/// In this setting, the target is looked up on the types in the mixin 'on'
/// clause and are therefore not necessary the runtime targets of the
/// assignment. An [AbstractSuperPropertySet] must be converted into a
/// [SuperPropertySet] to statically bind the target.
///
/// For instance
///
///    abstract class Interface {
///      void set setter(value);
///    }
///    mixin Mixin on Interface {
///      void set setter(value) {
///        // This is an [AbstractSuperPropertySet] with interface target
///        // `Interface.setter`.
///        super.setter = value;
///      }
///    }
///    class Super implements Interface {
///      // This is the target when `Mixin` is applied to `Class`.
///      void set setter(value) {}
///    }
///    class Class extends Super with Mixin {}
///
/// This may invoke a setter or assign a field.
class AbstractSuperPropertySet extends Expression {
  Name name;
  Expression value;

  Reference interfaceTargetReference;

  AbstractSuperPropertySet(Name name, Expression value, Member interfaceTarget)
      : this.byReference(
            name, value, getNonNullableMemberReferenceSetter(interfaceTarget));

  AbstractSuperPropertySet.byReference(
      this.name, this.value, this.interfaceTargetReference) {
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
  R accept<R>(ExpressionVisitor<R> v) => v.visitAbstractSuperPropertySet(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitAbstractSuperPropertySet(this, arg);

  @override
  void visitChildren(Visitor v) {
    interfaceTarget.acceptReference(v);
    name.accept(v);
    value.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    value = v.transform(value);
    value.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    value = v.transform(value);
    value.parent = this;
  }

  @override
  String toString() {
    return "AbstractSuperPropertySet(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('super.{abstract}');
    printer.writeInterfaceMemberName(interfaceTargetReference, name);
    printer.write(' = ');
    printer.writeExpression(value);
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

  Reference interfaceTargetReference;

  SuperPropertySet(Name name, Expression value, Member interfaceTarget)
      : this.byReference(
            name, value, getNonNullableMemberReferenceSetter(interfaceTarget));

  SuperPropertySet.byReference(
      this.name, this.value, this.interfaceTargetReference) {
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
  R accept<R>(ExpressionVisitor<R> v) => v.visitSuperPropertySet(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitSuperPropertySet(this, arg);

  @override
  void visitChildren(Visitor v) {
    interfaceTarget.acceptReference(v);
    name.accept(v);
    value.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    value = v.transform(value);
    value.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    value = v.transform(value);
    value.parent = this;
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
      : assert(target is Field || (target is Procedure && target.isGetter)),
        this.targetReference = getNonNullableMemberReferenceGetter(target);

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
      : assert(target.isStatic, "Unexpected static tear off target: $target"),
        assert(target.kind == ProcedureKind.Method,
            "Unexpected static tear off target: $target"),
        this.targetReference = getNonNullableMemberReferenceGetter(target);

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
    value = v.transform(value);
    value.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    value = v.transform(value);
    value.parent = this;
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
  void toTextInternal(AstPrinter printer, {bool includeTypeArguments = true}) {
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
    value = v.transform(value);
    value.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    value = v.transform(value);
    value.parent = this;
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

  /// Name of the invoked method.
  Name get name;
}

abstract class InstanceInvocationExpression extends InvocationExpression {
  Expression get receiver;
}

class DynamicInvocation extends InstanceInvocationExpression {
  // Must match serialized bit positions.
  static const int FlagImplicitCall = 1 << 0;

  final DynamicAccessKind kind;

  @override
  Expression receiver;

  @override
  Name name;

  @override
  Arguments arguments;

  int flags = 0;

  DynamicInvocation(this.kind, this.receiver, this.name, this.arguments) {
    receiver.parent = this;
    arguments.parent = this;
  }

  /// If `true` this is an implicit call to 'call'. For instance
  ///
  ///    method(dynamic d) {
  ///      d(); // Implicit call.
  ///      d.call(); // Explicit call.
  ///
  bool get isImplicitCall => flags & FlagImplicitCall != 0;

  void set isImplicitCall(bool value) {
    flags = value ? (flags | FlagImplicitCall) : (flags & ~FlagImplicitCall);
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
    receiver = v.transform(receiver);
    receiver.parent = this;
    arguments = v.transform(arguments);
    arguments.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    receiver = v.transform(receiver);
    receiver.parent = this;
    arguments = v.transform(arguments);
    arguments.parent = this;
  }

  @override
  String toString() {
    return "DynamicInvocation($kind,${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(receiver,
        minimumPrecedence: astToText.Precedence.PRIMARY);
    if (!isImplicitCall) {
      printer.write('.');
      printer.writeName(name);
    }
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
class InstanceInvocation extends InstanceInvocationExpression {
  // Must match serialized bit positions.
  static const int FlagInvariant = 1 << 0;
  static const int FlagBoundsSafe = 1 << 1;

  final InstanceAccessKind kind;

  @override
  Expression receiver;

  // TODO(johnniwinther): Can we pull this from the [interfaceTarget] instead?
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
      : assert(functionType.typeParameters.isEmpty) {
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
    functionType.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    receiver = v.transform(receiver);
    receiver.parent = this;
    arguments = v.transform(arguments);
    arguments.parent = this;
    functionType = v.visitDartType(functionType) as FunctionType;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    receiver = v.transform(receiver);
    receiver.parent = this;
    arguments = v.transform(arguments);
    arguments.parent = this;
    functionType =
        v.visitDartType(functionType, cannotRemoveSentinel) as FunctionType;
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
class InstanceGetterInvocation extends InstanceInvocationExpression {
  // Must match serialized bit positions.
  static const int FlagInvariant = 1 << 0;
  static const int FlagBoundsSafe = 1 << 1;

  final InstanceAccessKind kind;

  @override
  Expression receiver;

  @override
  Name name;

  @override
  Arguments arguments;

  int flags = 0;

  /// The static type of the invocation, or `dynamic` is of the type is unknown.
  ///
  /// This includes substituted type parameters from the static receiver type
  /// and generic type arguments.
  ///
  /// For instance
  ///
  ///    class A<T> {
  ///      Map<T, S> Function<S>(S) get map => ...
  ///      dynamic get dyn => ...
  ///    }
  ///    m(A<String> a) {
  ///      a.map(0); // The function type is `Map<String, int> Function(int)`.
  ///      a.dyn(0); // The function type is `null`.
  ///    }
  ///
  FunctionType? functionType;

  Reference interfaceTargetReference;

  InstanceGetterInvocation(InstanceAccessKind kind, Expression receiver,
      Name name, Arguments arguments,
      {required Member interfaceTarget, required FunctionType? functionType})
      : this.byReference(kind, receiver, name, arguments,
            interfaceTargetReference:
                getNonNullableMemberReferenceGetter(interfaceTarget),
            functionType: functionType);

  InstanceGetterInvocation.byReference(
      this.kind, this.receiver, this.name, this.arguments,
      {required this.interfaceTargetReference, required this.functionType})
      : assert(functionType == null || functionType.typeParameters.isEmpty) {
    receiver.parent = this;
    arguments.parent = this;
  }

  Member get interfaceTarget => interfaceTargetReference.asMember;

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
      functionType?.returnType ?? const DynamicType();

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
    functionType?.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    receiver = v.transform(receiver);
    receiver.parent = this;
    arguments = v.transform(arguments);
    arguments.parent = this;

    if (functionType != null) {
      functionType = v.visitDartType(functionType!) as FunctionType;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    receiver = v.transform(receiver);
    receiver.parent = this;
    arguments = v.transform(arguments);
    arguments.parent = this;
    if (functionType != null) {
      functionType =
          v.visitDartType(functionType!, cannotRemoveSentinel) as FunctionType;
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
class FunctionInvocation extends InstanceInvocationExpression {
  final FunctionAccessKind kind;

  @override
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
    functionType?.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    receiver = v.transform(receiver);
    receiver.parent = this;
    arguments = v.transform(arguments);
    arguments.parent = this;
    FunctionType? type = functionType;
    if (type != null) {
      functionType = v.visitDartType(type) as FunctionType;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    receiver = v.transform(receiver);
    receiver.parent = this;
    arguments = v.transform(arguments);
    arguments.parent = this;
    FunctionType? type = functionType;
    if (type != null) {
      functionType =
          v.visitDartType(type, cannotRemoveSentinel) as FunctionType;
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
      {required this.functionType}) {
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
    functionType.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    arguments = v.transform(arguments);
    arguments.parent = this;
    functionType = v.visitDartType(functionType) as FunctionType;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    arguments = v.transform(arguments);
    arguments.parent = this;
    functionType =
        v.visitDartType(functionType, cannotRemoveSentinel) as FunctionType;
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
    expression = v.transform(expression);
    expression.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    expression = v.transform(expression);
    expression.parent = this;
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
    functionType.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    left = v.transform(left);
    left.parent = this;
    right = v.transform(right);
    right.parent = this;
    functionType = v.visitDartType(functionType) as FunctionType;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    left = v.transform(left);
    left.parent = this;
    right = v.transform(right);
    right.parent = this;
    functionType =
        v.visitDartType(functionType, cannotRemoveSentinel) as FunctionType;
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

/// Expression of form `super.foo(x)` occurring in a mixin declaration.
///
/// In this setting, the target is looked up on the types in the mixin 'on'
/// clause and are therefore not necessary the runtime targets of the
/// invocation. An [AbstractSuperMethodInvocation] must be converted into
/// a [SuperMethodInvocation] to statically bind the target.
///
/// For instance
///
///    abstract class Interface {
///      void method();
///    }
///    mixin Mixin on Interface {
///      void method() {
///        // This is an [AbstractSuperMethodInvocation] with interface target
///        // `Interface.method`.
///        super.method(); // This targets Super.method.
///      }
///    }
///    class Super implements Interface {
///      // This is the target when `Mixin` is applied to `Class`.
///      void method() {}
///    }
///    class Class extends Super with Mixin {}
///
class AbstractSuperMethodInvocation extends InvocationExpression {
  @override
  Name name;

  @override
  Arguments arguments;

  Reference interfaceTargetReference;

  AbstractSuperMethodInvocation(
      Name name, Arguments arguments, Procedure interfaceTarget)
      : this.byReference(
            name,
            arguments,
            // An invocation doesn't refer to the setter.
            getNonNullableMemberReferenceGetter(interfaceTarget));

  AbstractSuperMethodInvocation.byReference(
      this.name, this.arguments, this.interfaceTargetReference) {
    arguments.parent = this;
  }

  Procedure get interfaceTarget => interfaceTargetReference.asProcedure;

  void set interfaceTarget(Procedure target) {
    // An invocation doesn't refer to the setter.
    interfaceTargetReference = getNonNullableMemberReferenceGetter(target);
  }

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) {
    Class superclass = interfaceTarget.enclosingClass!;
    List<DartType>? receiverTypeArguments = context.typeEnvironment
        .getTypeArgumentsAsInstanceOf(context.thisType!, superclass);
    DartType returnType = Substitution.fromPairs(
            superclass.typeParameters, receiverTypeArguments!)
        .substituteType(interfaceTarget.function.returnType);
    return Substitution.fromPairs(
            interfaceTarget.function.typeParameters, arguments.types)
        .substituteType(returnType);
  }

  @override
  R accept<R>(ExpressionVisitor<R> v) =>
      v.visitAbstractSuperMethodInvocation(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitAbstractSuperMethodInvocation(this, arg);

  @override
  void visitChildren(Visitor v) {
    interfaceTarget.acceptReference(v);
    name.accept(v);
    arguments.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    arguments = v.transform(arguments);
    arguments.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    arguments = v.transform(arguments);
    arguments.parent = this;
  }

  @override
  String toString() {
    return "AbstractSuperMethodInvocation(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('super.{abstract}');
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

  Reference interfaceTargetReference;

  SuperMethodInvocation(
      Name name, Arguments arguments, Procedure interfaceTarget)
      : this.byReference(
            name,
            arguments,
            // An invocation doesn't refer to the setter.
            getNonNullableMemberReferenceGetter(interfaceTarget));

  SuperMethodInvocation.byReference(
      this.name, this.arguments, this.interfaceTargetReference) {
    arguments.parent = this;
  }

  Procedure get interfaceTarget => interfaceTargetReference.asProcedure;

  void set interfaceTarget(Procedure target) {
    // An invocation doesn't refer to the setter.
    interfaceTargetReference = getNonNullableMemberReferenceGetter(target);
  }

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) {
    Class superclass = interfaceTarget.enclosingClass!;
    List<DartType>? receiverTypeArguments = context.typeEnvironment
        .getTypeArgumentsAsInstanceOf(context.thisType!, superclass);
    DartType returnType = Substitution.fromPairs(
            superclass.typeParameters, receiverTypeArguments!)
        .substituteType(interfaceTarget.function.returnType);
    return Substitution.fromPairs(
            interfaceTarget.function.typeParameters, arguments.types)
        .substituteType(returnType);
  }

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitSuperMethodInvocation(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitSuperMethodInvocation(this, arg);

  @override
  void visitChildren(Visitor v) {
    interfaceTarget.acceptReference(v);
    name.accept(v);
    arguments.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    arguments = v.transform(arguments);
    arguments.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    arguments = v.transform(arguments);
    arguments.parent = this;
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
  Name get name => target.name;

  StaticInvocation(Procedure target, Arguments arguments,
      {bool isConst = false})
      : this.byReference(
            // An invocation doesn't refer to the setter.
            getNonNullableMemberReferenceGetter(target),
            arguments,
            isConst: isConst);

  StaticInvocation.byReference(this.targetReference, this.arguments,
      {this.isConst = false}) {
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
            target.function.typeParameters, arguments.types)
        .substituteType(target.function.returnType);
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
    arguments = v.transform(arguments);
    arguments.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    arguments = v.transform(arguments);
    arguments.parent = this;
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
  Name get name => target.name;

  ConstructorInvocation(Constructor target, Arguments arguments,
      {bool isConst = false})
      : this.byReference(
            // A constructor doesn't refer to the setter.
            getNonNullableMemberReferenceGetter(target),
            arguments,
            isConst: isConst);

  ConstructorInvocation.byReference(this.targetReference, this.arguments,
      {this.isConst = false}) {
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
    arguments = v.transform(arguments);
    arguments.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    arguments = v.transform(arguments);
    arguments.parent = this;
  }

  // TODO(cstefantsova): Change the getter into a method that accepts a
  // CoreTypes.
  InterfaceType get constructedType {
    Class enclosingClass = target.enclosingClass;
    // TODO(cstefantsova): Get raw type from a CoreTypes object if arguments is
    // empty.
    return arguments.types.isEmpty
        ? new InterfaceType(enclosingClass, target.enclosingLibrary.nonNullable,
            const <DartType>[])
        : new InterfaceType(enclosingClass, target.enclosingLibrary.nonNullable,
            arguments.types);
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
    if (target.name.text.isNotEmpty) {
      printer.write('.');
      printer.write(target.name.text);
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
    DartType type = expression.getStaticType(context);
    if (type is FunctionType) {
      return FunctionTypeInstantiator.instantiate(type, typeArguments);
    }
    assert(type is InvalidType || type is NeverType,
        "Unexpected operand type $type for $expression");
    return type;
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
    expression = v.transform(expression);
    expression.parent = this;

    v.transformDartTypeList(typeArguments);
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    expression = v.transform(expression);
    expression.parent = this;

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
    operand = v.transform(operand);
    operand.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    operand = v.transform(operand);
    operand.parent = this;
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
    left = v.transform(left);
    left.parent = this;
    right = v.transform(right);
    right.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    left = v.transform(left);
    left.parent = this;
    right = v.transform(right);
    right.parent = this;
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
    condition = v.transform(condition);
    condition.parent = this;
    then = v.transform(then);
    then.parent = this;
    otherwise = v.transform(otherwise);
    otherwise.parent = this;
    staticType = v.visitDartType(staticType);
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    condition = v.transform(condition);
    condition.parent = this;
    then = v.transform(then);
    then.parent = this;
    otherwise = v.transform(otherwise);
    otherwise.parent = this;
    staticType = v.visitDartType(staticType, cannotRemoveSentinel);
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
    printer.write('{');
    printer.writeType(staticType);
    printer.write('}');
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

  ListConcatenation(this.lists, {this.typeArgument = const DynamicType()}) {
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

  SetConcatenation(this.sets, {this.typeArgument = const DynamicType()}) {
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
      {this.keyType = const DynamicType(),
      this.valueType = const DynamicType()}) {
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
      if (!identical(value, transformed)) {
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
  @override
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

  @override
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
    operand = v.transform(operand);
    operand.parent = this;
    type = v.visitDartType(type);
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    operand = v.transform(operand);
    operand.parent = this;
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
  static const int FlagUnchecked = 1 << 4;

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

  /// If `true`, this test is added to show the known static type of the
  /// expression and should not be performed at runtime.
  ///
  /// This is the case for instance for access to extension type representation
  /// fields on an extension type, where this node shows that the static type
  /// changes from the extension type of the declared representation type.
  ///
  /// This is also the case when a field access undergoes type promotion.
  bool get isUnchecked => flags & FlagUnchecked != 0;

  void set isUnchecked(bool value) {
    flags = value ? (flags | FlagUnchecked) : (flags & ~FlagUnchecked);
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
    operand = v.transform(operand);
    operand.parent = this;
    type = v.visitDartType(type);
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    operand = v.transform(operand);
    operand.parent = this;
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
    operand = v.transform(operand);
    operand.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    operand = v.transform(operand);
    operand.parent = this;
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
  /// technically (on some platforms, particularly JavaScript) being positive.
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

  @override
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
  @override
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
  int flags = 0;

  Throw(this.expression) {
    expression.parent = this;
  }

  // Must match serialized bit positions.
  static const int FlagForErrorHandling = 1 << 0;

  /// If `true`, this `throw` is *not* present in the source code but added
  /// to ensure correctness and/or soundness of the generated code.
  ///
  /// This is used for instance in the lowering for handling duplicate writes
  /// to a late final field or for pattern assignments that don't match.
  bool get forErrorHandling => flags & FlagForErrorHandling != 0;

  void set forErrorHandling(bool value) {
    flags = value
        ? (flags | FlagForErrorHandling)
        : (flags & ~FlagForErrorHandling);
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
    expression = v.transform(expression);
    expression.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    expression = v.transform(expression);
    expression.parent = this;
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
      {this.typeArgument = const DynamicType(), this.isConst = false}) {
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
      {this.typeArgument = const DynamicType(), this.isConst = false}) {
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
  final List<MapLiteralEntry> entries;

  MapLiteral(this.entries,
      {this.keyType = const DynamicType(),
      this.valueType = const DynamicType(),
      this.isConst = false}) {
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

class MapLiteralEntry extends TreeNode {
  Expression key;
  Expression value;

  MapLiteralEntry(this.key, this.value) {
    key.parent = this;
    value.parent = this;
  }

  @override
  R accept<R>(TreeVisitor<R> v) => v.visitMapLiteralEntry(this);

  @override
  R accept1<R, A>(TreeVisitor1<R, A> v, A arg) =>
      v.visitMapLiteralEntry(this, arg);

  @override
  void visitChildren(Visitor v) {
    key.accept(v);
    value.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    key = v.transform(key);
    key.parent = this;
    value = v.transform(value);
    value.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    key = v.transform(key);
    key.parent = this;
    value = v.transform(value);
    value.parent = this;
  }

  @override
  String toString() {
    return "MapEntry(${toStringInternal()})";
  }

  @override
  String toText(AstTextStrategy strategy) {
    AstPrinter printer = new AstPrinter(strategy);
    toTextInternal(printer);
    return printer.getText();
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(key);
    printer.write(': ');
    printer.writeExpression(value);
  }
}

class RecordLiteral extends Expression {
  bool isConst;
  final List<Expression> positional;
  final List<NamedExpression> named;
  RecordType recordType;

  RecordLiteral(this.positional, this.named, this.recordType,
      {this.isConst = false})
      : assert(positional.length == recordType.positional.length &&
            named.length == recordType.named.length &&
            recordType.named
                .map((f) => f.name)
                .toSet()
                .containsAll(named.map((f) => f.name))),
        assert(() {
          // Assert that the named fields are sorted.
          for (int i = 1; i < named.length; i++) {
            if (named[i].name.compareTo(named[i - 1].name) < 0) {
              return false;
            }
          }
          return true;
        }(),
            "Named fields of a RecordLiterals aren't sorted lexicographically: "
            "${named.map((f) => f.name).join(", ")}") {
    setParents(positional, this);
    setParents(named, this);
  }

  @override
  DartType getStaticType(StaticTypeContext context) =>
      getStaticTypeInternal(context);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) {
    return recordType;
  }

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitRecordLiteral(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitRecordLiteral(this, arg);

  @override
  void visitChildren(Visitor v) {
    visitList(positional, v);
    visitList(named, v);
    recordType.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    v.transformList(positional, this);
    v.transformList(named, this);
    recordType = v.visitDartType(recordType) as RecordType;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    v.transformExpressionList(positional, this);
    v.transformNamedExpressionList(named, this);
    recordType =
        v.visitDartType(recordType, cannotRemoveSentinel) as RecordType;
  }

  @override
  String toString() {
    return "RecordType(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    if (isConst) {
      printer.write("const ");
    }
    printer.write("(");
    for (int index = 0; index < positional.length; index++) {
      if (index > 0) {
        printer.write(", ");
      }
      printer.writeExpression(positional[index]);
    }
    if (named.isNotEmpty) {
      if (positional.isNotEmpty) {
        printer.write(", ");
      }
      for (int index = 0; index < named.length; index++) {
        if (index > 0) {
          printer.write(", ");
        }
        printer.writeNamedExpression(named[index]);
      }
    }
    printer.write(")");
  }
}

/// Expression of form `await x`.
class AwaitExpression extends Expression {
  Expression operand;

  /// If non-null, the runtime should check whether the value of [operand] is a
  /// subtype of [runtimeCheckType], and if _not_ so, wrap the value in a call
  /// to the `Future.value()` constructor.
  ///
  /// For instance
  ///
  ///     FutureOr<Object> future1 = Future<Object?>.value();
  ///     var x = await future1; // Check against `Future<Object>`.
  ///
  ///     Object object = Future<Object?>.value();
  ///     var y = await object; // Check against `Future<Object>`.
  ///
  ///     Future<Object?> future2 = Future<Object?>.value();
  ///     var z = await future2; // No check.
  ///
  /// This runtime checks is necessary to ensure that we don't evaluate the
  /// await expression to `null` when the static type of the expression is
  /// non-nullable.
  ///
  /// The [runtimeCheckType] is computed as `Future<T>` where `T = flatten(S)`
  /// and `S` is the static type of [operand]. To avoid unnecessary runtime
  /// checks, the [runtimeCheckType] is not set if the static type of the
  /// [operand] is a subtype of `Future<T>`.
  ///
  /// See https://github.com/dart-lang/sdk/issues/49396 for further discussion
  /// of which the check is needed.
  DartType? runtimeCheckType;

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
    operand = v.transform(operand);
    operand.parent = this;
    if (runtimeCheckType != null) {
      runtimeCheckType = v.visitDartType(runtimeCheckType!);
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    operand = v.transform(operand);
    operand.parent = this;
    if (runtimeCheckType != null) {
      runtimeCheckType = v.visitDartType(runtimeCheckType!, null);
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
abstract class LocalFunction implements GenericFunction {
  @override
  FunctionNode get function;
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
  List<TypeParameter> get typeParameters => function.typeParameters;

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
    function = v.transform(function);
    function.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    function = v.transform(function);
    function.parent = this;
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

  ConstantExpression(this.constant, [this.type = const DynamicType()]);

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

class FileUriConstantExpression extends ConstantExpression
    implements FileUriNode {
  @override
  Uri fileUri;

  FileUriConstantExpression(Constant constant,
      {DartType type = const DynamicType(), required this.fileUri})
      : super(constant, type);

  @override
  Location? _getLocationInEnclosingFile(int offset) {
    return _getLocationInComponent(enclosingComponent, fileUri, offset);
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
    variable = v.transform(variable);
    variable.parent = this;
    body = v.transform(body);
    body.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    variable = v.transform(variable);
    variable.parent = this;
    body = v.transform(body);
    body.parent = this;
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
    body = v.transform(body);
    body.parent = this;
    value = v.transform(value);
    value.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    body = v.transform(body);
    body.parent = this;
    value = v.transform(value);
    value.parent = this;
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

/// Tearing off a constructor of a class.
class ConstructorTearOff extends Expression {
  /// The reference to the constructor being torn off.
  Reference targetReference;

  ConstructorTearOff(Member target)
      : assert(
            target is Constructor || (target is Procedure && target.isFactory),
            "Unexpected constructor tear off target: $target"),
        this.targetReference = getNonNullableMemberReferenceGetter(target);

  ConstructorTearOff.byReference(this.targetReference);

  Member get target => targetReference.asMember;

  FunctionNode get function => target.function!;

  void set target(Member member) {
    assert(member is Constructor ||
        (member is Procedure && member.kind == ProcedureKind.Factory));
    targetReference = getNonNullableMemberReferenceGetter(member);
  }

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) {
    return target.function!.computeFunctionType(Nullability.nonNullable);
  }

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitConstructorTearOff(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitConstructorTearOff(this, arg);

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
    return "ConstructorTearOff(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeMemberName(targetReference);
  }
}

/// Tearing off a redirecting factory constructor of a class.
class RedirectingFactoryTearOff extends Expression {
  /// The reference to the redirecting factory constructor being torn off.
  Reference targetReference;

  RedirectingFactoryTearOff(Procedure target)
      : assert(target.isRedirectingFactory),
        this.targetReference = getNonNullableMemberReferenceGetter(target);

  RedirectingFactoryTearOff.byReference(this.targetReference);

  Procedure get target => targetReference.asProcedure;

  void set target(Procedure target) {
    targetReference = getNonNullableMemberReferenceGetter(target);
  }

  FunctionNode get function => target.function;

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) {
    return target.function.computeFunctionType(Nullability.nonNullable);
  }

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitRedirectingFactoryTearOff(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitRedirectingFactoryTearOff(this, arg);

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
    return "RedirectingFactoryTearOff(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeMemberName(targetReference);
  }
}

class TypedefTearOff extends Expression {
  final List<TypeParameter> typeParameters;
  Expression expression;
  final List<DartType> typeArguments;

  TypedefTearOff(this.typeParameters, this.expression, this.typeArguments) {
    expression.parent = this;
    setParents(typeParameters, this);
  }

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) {
    FreshStructuralParametersFromTypeParameters freshTypeParameters =
        getFreshStructuralParametersFromTypeParameters(typeParameters);
    FunctionType type = expression.getStaticType(context) as FunctionType;
    type = freshTypeParameters.substitute(
            FunctionTypeInstantiator.instantiate(type, typeArguments))
        as FunctionType;
    return new FunctionType(
        type.positionalParameters, type.returnType, type.declaredNullability,
        namedParameters: type.namedParameters,
        typeParameters: freshTypeParameters.freshTypeParameters,
        requiredParameterCount: type.requiredParameterCount);
  }

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.visitTypedefTearOff(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitTypedefTearOff(this, arg);

  @override
  void visitChildren(Visitor v) {
    expression.accept(v);
    visitList(typeParameters, v);
    visitList(typeArguments, v);
  }

  @override
  void transformChildren(Transformer v) {
    expression = v.transform(expression);
    expression.parent = this;
    v.transformList(typeParameters, this);
    v.transformDartTypeList(typeArguments);
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    expression = v.transform(expression);
    expression.parent = this;
    v.transformList(typeParameters, this, dummyTypeParameter);
    v.transformDartTypeList(typeArguments);
  }

  @override
  String toString() {
    return "TypedefTearOff(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeTypeParameters(typeParameters);
    printer.write(".(");
    printer.writeExpression(expression);
    printer.writeTypeArguments(typeArguments);
    printer.write(")");
  }
}

// ------------------------------------------------------------------------
//                              STATEMENTS
// ------------------------------------------------------------------------

sealed class Statement extends TreeNode {
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

abstract class AuxiliaryStatement extends Statement {
  @override
  R accept<R>(StatementVisitor<R> v) => v.visitAuxiliaryStatement(this);

  @override
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg) =>
      v.visitAuxiliaryStatement(this, arg);
}

class ExpressionStatement extends Statement {
  Expression expression;

  // TODO(johnniwinther): Fix this so set value is not lost. We include this
  //   getter so offset is consistent before and after serialization.
  //   ExpressionStatements are common so serializing the offset could
  //   increase serialized size.
  @override
  int get fileOffset => expression.fileOffset;

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
    expression = v.transform(expression);
    expression.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    expression = v.transform(expression);
    expression.parent = this;
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

  @override
  List<int>? get fileOffsetsIfMultiple => [fileOffset, fileEndOffset];

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

  @override
  List<int>? get fileOffsetsIfMultiple =>
      [fileOffset, conditionStartOffset, conditionEndOffset];

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
    condition = v.transform(condition);
    condition.parent = this;
    if (message != null) {
      message = v.transform(message!);
      message?.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    condition = v.transform(condition);
    condition.parent = this;
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
    body = v.transform(body);
    body.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    body = v.transform(body);
    body.parent = this;
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
/// Both `break` and `continue` statements are translated into this node.
///
/// Example `break` desugaring:
///
///     while (x) {
///       if (y) break;
///       BODY
///     }
///
///     ==>
///
///     L: while (x) {
///       if (y) break L;
///       BODY
///     }
///
/// Example `continue` desugaring:
///
///     while (x) {
///       if (y) continue;
///       BODY
///     }
///
///     ==>
///
///     while (x) {
///       L: {
///         if (y) break L;
///         BODY
///       }
///     }
///
/// Note: Compiler-generated [LabeledStatement]s for [WhileStatement]s and
/// [ForStatement]s are only generated when needed. If there isn't a `break` or
/// `continue` in a loop, the kernel for the loop won't have a generated
/// [LabeledStatement].
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
    condition = v.transform(condition);
    condition.parent = this;
    body = v.transform(body);
    body.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    condition = v.transform(condition);
    condition.parent = this;
    body = v.transform(body);
    body.parent = this;
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
    body = v.transform(body);
    body.parent = this;
    condition = v.transform(condition);
    condition.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    body = v.transform(body);
    body.parent = this;
    condition = v.transform(condition);
    condition.parent = this;
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
    body = v.transform(body);
    body.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    v.transformVariableDeclarationList(variables, this);
    if (condition != null) {
      condition = v.transformOrRemoveExpression(condition!);
      condition?.parent = this;
    }
    v.transformExpressionList(updates, this);
    body = v.transform(body);
    body.parent = this;
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

  @override
  List<int>? get fileOffsetsIfMultiple => [fileOffset, bodyOffset];

  VariableDeclaration variable; // Has no initializer.
  Expression iterable;
  Statement body;
  bool isAsync; // True if this is an 'await for' loop.

  ForInStatement(this.variable, this.iterable, this.body,
      {this.isAsync = false}) {
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
    variable = v.transform(variable);
    variable.parent = this;
    iterable = v.transform(iterable);
    iterable.parent = this;
    body = v.transform(body);
    body.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    variable = v.transform(variable);
    variable.parent = this;
    iterable = v.transform(iterable);
    iterable.parent = this;
    body = v.transform(body);
    body.parent = this;
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
      InterfaceType streamType = iterable.getStaticTypeAsInstanceOf(
          context.typeEnvironment.coreTypes.streamClass, context);
      iteratorType = new InterfaceType(
          context.typeEnvironment.coreTypes.streamIteratorClass,
          context.nonNullable,
          streamType.typeArguments);
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
    DartType iterableType =
        iterable.getStaticType(context).nonTypeVariableBound;
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
    if (iterableType is! TypeDeclarationType) {
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

  /// For switches without a default clause, whether all possible values are
  /// covered by a switch case.  For switches with a default clause, always
  /// `false`.
  /// Initialized during type inference.
  bool isExplicitlyExhaustive;

  /// The static type of the [expression]
  ///
  /// This is set during inference.
  DartType? expressionTypeInternal;

  SwitchStatement(this.expression, this.cases,
      {this.isExplicitlyExhaustive = false}) {
    expression.parent = this;
    setParents(cases, this);
  }

  /// The static type of the [expression]
  ///
  /// This is set during inference.
  DartType get expressionType {
    assert(expressionTypeInternal != null,
        "Expression type hasn't been computed for $this.");
    return expressionTypeInternal!;
  }

  void set expressionType(DartType value) {
    expressionTypeInternal = value;
  }

  /// Whether the switch has a `default` case.
  bool get hasDefault {
    assert(cases.every((c) => c == cases.last || !c.isDefault));
    return cases.isNotEmpty && cases.last.isDefault;
  }

  /// Whether the switch is guaranteed to hit one of the cases (including the
  /// default case, if present).
  bool get isExhaustive => isExplicitlyExhaustive || hasDefault;

  @override
  R accept<R>(StatementVisitor<R> v) => v.visitSwitchStatement(this);

  @override
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg) =>
      v.visitSwitchStatement(this, arg);

  @override
  void visitChildren(Visitor v) {
    expression.accept(v);
    visitList(cases, v);
    expressionTypeInternal?.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    expression = v.transform(expression);
    expression.parent = this;
    v.transformList(cases, this);
    if (expressionTypeInternal != null) {
      expressionTypeInternal = v.visitDartType(expressionTypeInternal!);
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    expression = v.transform(expression);
    expression.parent = this;
    v.transformSwitchCaseList(cases, this);
    if (expressionTypeInternal != null) {
      expressionTypeInternal =
          v.visitDartType(expressionTypeInternal!, cannotRemoveSentinel);
    }
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
      {this.isDefault = false}) {
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
  List<int>? get fileOffsetsIfMultiple => [fileOffset, ...expressionOffsets];

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
    body = v.transform(body);
    body.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    v.transformExpressionList(expressions, this);
    body = v.transform(body);
    body.parent = this;
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
    condition = v.transform(condition);
    condition.parent = this;
    then = v.transform(then);
    then.parent = this;
    if (otherwise != null) {
      otherwise = v.transform(otherwise!);
      otherwise?.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    condition = v.transform(condition);
    condition.parent = this;
    then = v.transform(then);
    then.parent = this;
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

  TryCatch(this.body, this.catches, {this.isSynthetic = false}) {
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
    body = v.transform(body);
    body.parent = this;
    v.transformList(catches, this);
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    body = v.transform(body);
    body.parent = this;
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
      {this.guard = const DynamicType(), this.stackTrace}) {
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
    body = v.transform(body);
    body.parent = this;
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
    body = v.transform(body);
    body.parent = this;
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
          type.classReference.node != null &&
          type.classNode.name == 'Object') {
        Uri uri = type.classNode.enclosingLibrary.importUri;
        return uri.isScheme('dart') &&
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
    body = v.transform(body);
    body.parent = this;
    finalizer = v.transform(finalizer);
    finalizer.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    body = v.transform(body);
    body.parent = this;
    finalizer = v.transform(finalizer);
    finalizer.parent = this;
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
class YieldStatement extends Statement {
  Expression expression;
  int flags = 0;

  YieldStatement(this.expression, {bool isYieldStar = false}) {
    expression.parent = this;
    this.isYieldStar = isYieldStar;
  }

  static const int FlagYieldStar = 1 << 0;

  bool get isYieldStar => flags & FlagYieldStar != 0;

  void set isYieldStar(bool value) {
    flags = value ? (flags | FlagYieldStar) : (flags & ~FlagYieldStar);
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
    expression = v.transform(expression);
    expression.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    expression = v.transform(expression);
    expression.parent = this;
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
class VariableDeclaration extends Statement implements Annotatable {
  /// Offset of the equals sign in the source file it comes from.
  ///
  /// Valid values are from 0 and up, or -1 ([TreeNode.noOffset])
  /// if the equals sign offset is not available (e.g. if not initialized)
  /// (this is the default if none is specifically set).
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
  int flags = 0;
  DartType type; // Not null, defaults to dynamic.

  /// Offset of the declaration, set and used when writing the binary.
  int binaryOffsetNoTag = -1;

  /// For locals, this is the initial value.
  /// For parameters, this is the default value.
  ///
  /// Should be null in other cases.
  Expression? initializer; // May be null.

  VariableDeclaration(this._name,
      {this.initializer,
      this.type = const DynamicType(),
      int flags = -1,
      bool isFinal = false,
      bool isConst = false,
      bool isInitializingFormal = false,
      bool isCovariantByDeclaration = false,
      bool isLate = false,
      bool isRequired = false,
      bool isLowered = false,
      bool isSynthesized = false,
      bool isHoisted = false,
      bool hasDeclaredInitializer = false}) {
    initializer?.parent = this;
    if (flags != -1) {
      this.flags = flags;
    } else {
      this.isFinal = isFinal;
      this.isConst = isConst;
      this.isInitializingFormal = isInitializingFormal;
      this.isCovariantByDeclaration = isCovariantByDeclaration;
      this.isLate = isLate;
      this.isRequired = isRequired;
      this.isLowered = isLowered;
      this.hasDeclaredInitializer = hasDeclaredInitializer;
      this.isSynthesized = isSynthesized;
      this.isHoisted = isHoisted;
    }
    assert(_name != null || this.isSynthesized,
        "Only synthesized variables can have no name.");
  }

  /// Creates a synthetic variable with the given expression as initializer.
  VariableDeclaration.forValue(this.initializer,
      {bool isFinal = true,
      bool isConst = false,
      bool isInitializingFormal = false,
      bool isLate = false,
      bool isRequired = false,
      bool isLowered = false,
      this.type = const DynamicType()}) {
    initializer?.parent = this;
    this.isFinal = isFinal;
    this.isConst = isConst;
    this.isInitializingFormal = isInitializingFormal;
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
  String? get name => _name;

  void set name(String? value) {
    assert(value != null || isSynthesized,
        "Only synthesized variables can have no name.");
    _name = value;
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

  bool get isFinal => flags & FlagFinal != 0;
  bool get isConst => flags & FlagConst != 0;

  /// Whether the parameter is declared with the `covariant` keyword.
  bool get isCovariantByDeclaration => flags & FlagCovariantByDeclaration != 0;

  /// Whether the variable is declared as an initializing formal parameter of
  /// a constructor.
  @informative
  bool get isInitializingFormal => flags & FlagInitializingFormal != 0;

  /// If this [VariableDeclaration] is a parameter of a method, indicates
  /// whether the method implementation needs to contain a runtime type check to
  /// deal with generic covariance.
  ///
  /// When `true`, runtime checks may need to be performed.
  bool get isCovariantByClass => flags & FlagCovariantByClass != 0;

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

  /// Whether this variable is synthesized, that is, it is _not_ declared in
  /// the source code.
  ///
  /// The name of a variable can only be omitted if the variable is synthesized.
  /// Otherwise, its name is as provided in the source code.
  bool get isSynthesized => flags & FlagSynthesized != 0;

  /// Whether the declaration of this variable is has been moved to an earlier
  /// source location.
  ///
  /// This is for instance the case for variables declared in a pattern, where
  /// the lowering requires the variable to be declared before the expression
  /// that performs that matching in which its initialization occurs.
  bool get isHoisted => flags & FlagHoisted != 0;

  /// Whether the variable has an initializer, either by declaration or copied
  /// from an original declaration.
  ///
  /// Note that the variable might have a synthesized initializer expression,
  /// so `hasDeclaredInitializer == false` doesn't imply `initializer == null`.
  /// For instance, for duplicate variable names, an invalid expression is set
  /// as the initializer of the second variable.
  bool get hasDeclaredInitializer => flags & FlagHasDeclaredInitializer != 0;

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

  void set isCovariantByDeclaration(bool value) {
    flags = value
        ? (flags | FlagCovariantByDeclaration)
        : (flags & ~FlagCovariantByDeclaration);
  }

  @informative
  void set isInitializingFormal(bool value) {
    flags = value
        ? (flags | FlagInitializingFormal)
        : (flags & ~FlagInitializingFormal);
  }

  void set isCovariantByClass(bool value) {
    flags = value
        ? (flags | FlagCovariantByClass)
        : (flags & ~FlagCovariantByClass);
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

  void set isSynthesized(bool value) {
    assert(
        value || _name != null, "Only synthesized variables can have no name.");
    flags = value ? (flags | FlagSynthesized) : (flags & ~FlagSynthesized);
  }

  void set isHoisted(bool value) {
    flags = value ? (flags | FlagHoisted) : (flags & ~FlagHoisted);
  }

  void set hasDeclaredInitializer(bool value) {
    flags = value
        ? (flags | FlagHasDeclaredInitializer)
        : (flags & ~FlagHasDeclaredInitializer);
  }

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
  FunctionNode function;

  FunctionDeclaration(this.variable, this.function) {
    variable.parent = this;
    function.parent = this;
  }

  @override
  List<TypeParameter> get typeParameters => function.typeParameters;

  @override
  R accept<R>(StatementVisitor<R> v) => v.visitFunctionDeclaration(this);

  @override
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg) =>
      v.visitFunctionDeclaration(this, arg);

  @override
  void visitChildren(Visitor v) {
    variable.accept(v);
    function.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    variable = v.transform(variable);
    variable.parent = this;
    function = v.transform(function);
    function.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    variable = v.transform(variable);
    variable.parent = this;
    function = v.transform(function);
    function.parent = this;
  }

  @override
  String toString() {
    return "FunctionDeclaration(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeFunctionNode(function, printer.getVariableName(variable));
    if (function.body is ReturnStatement) {
      printer.write(';');
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
  Reference? get libraryReference;
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

  @override
  bool operator ==(other) {
    return other is Name && text == other.text && library == other.library;
  }

  @override
  R accept<R>(Visitor<R> v) => v.visitName(this);

  @override
  R accept1<R, A>(Visitor1<R, A> v, A arg) => v.visitName(this, arg);

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
  final Reference libraryReference;

  @override
  bool get isPrivate => true;

  _PrivateName(String text, Reference libraryReference)
      : this.libraryReference = libraryReference,
        super._internal(_computeHashCode(text, libraryReference), text);

  @override
  String toString() => toStringInternal();

  @override
  String toStringInternal() => '$library::$text';

  @override
  Library get library => libraryReference.asLibrary;

  static int _computeHashCode(String name, Reference libraryReference) {
    // TODO(cstefantsova): Factor in [libraryReference] in a non-deterministic
    // way into the result.  Note, the previous code here was the following:
    //     return 131 * name.hashCode + 17 *
    //         libraryReference.asLibrary._libraryId;
    return name.hashCode;
  }
}

class _PublicName extends Name {
  @override
  Reference? get libraryReference => null;

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
sealed class DartType extends Node {
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

  /// Returns the non-type variable bound of this type, taking nullability
  /// into account.
  ///
  /// For instance in
  ///
  ///     method<T, S extends Class, U extends S?>()
  ///
  /// the non-type variable bound of `T` is `Object?`, for `S` it is `Class`,
  /// and for `U` it is `Class?`.
  DartType get nonTypeVariableBound;

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
  DartType get nonTypeVariableBound => this;

  @override
  bool get hasNonObjectMemberAccess => true;

  @override
  bool equals(Object other, Assumptions? assumptions) => other is InvalidType;

  @override
  Nullability get declaredNullability {
    // TODO(johnniwinther,cstefantsova): Consider implementing
    // invalidNullability.
    return Nullability.legacy;
  }

  @override
  Nullability get nullability {
    // TODO(johnniwinther,cstefantsova): Consider implementing
    // invalidNullability.
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
  DartType get nonTypeVariableBound => this;

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
  DartType get nonTypeVariableBound => this;

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
  DartType get nonTypeVariableBound => this;

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
  DartType get nonTypeVariableBound => this;

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
  DartType get nonTypeVariableBound => this;

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
class FunctionType extends DartType {
  final List<StructuralParameter> typeParameters;
  final int requiredParameterCount;
  final List<DartType> positionalParameters;
  final List<NamedType> namedParameters; // Must be sorted.

  @override
  final Nullability declaredNullability;

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
  DartType get nonTypeVariableBound => this;

  @override
  bool get hasNonObjectMemberAccess => switch (declaredNullability) {
        Nullability.undetermined => false,
        Nullability.nullable => false,
        Nullability.nonNullable => true,
        Nullability.legacy => true,
      };

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
  DartType get nonTypeVariableBound => unalias.nonTypeVariableBound;

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
        result.declaredNullability, nullability));
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
  DartType get nonTypeVariableBound => this;

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

  Nullability get _nullabilityDerivedFromSupertypes {
    for (DartType supertype in extensionTypeDeclaration.implements) {
      if (supertype is! ExtensionType) {
        // A supertype that is not an extension type has to be non-nullable and
        // implement `Object` directly or indirectly.
        return Nullability.nonNullable;
      } else if (supertype._nullabilityDerivedFromSupertypes !=
          Nullability.undetermined) {
        // If an extension type is non-nullable, it implements `Object` directly
        // or indirectly.
        return Nullability.nonNullable;
      }
    }
    // Direct or indirect implementation of `Objects` isn't found.
    return Nullability.undetermined;
  }

  @override
  Nullability get nullability {
    return combineNullabilitiesForSubstitution(
        _nullabilityDerivedFromSupertypes, declaredNullability);
  }

  @override
  DartType get nonTypeVariableBound => this;

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
          result.nullability, declaredNullability);
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
class NamedType extends Node implements Comparable<NamedType> {
  // Flag used for serialization if [isRequired].
  static const int FlagRequiredNamedType = 1 << 0;

  final String name;
  final DartType type;
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
            // pkg/front_end/test/fasta/types/kernel_type_parser_test
            // pkg/front_end/test/fasta/incremental_hello_test
            // pkg/front_end/test/fasta/types/fasta_types_test
            // pkg/front_end/test/explicit_creation_test
            // pkg/front_end/tool/fasta_perf_test
            // nnbd/issue42089
            // replicated in nnbd_mixed/type_parameter_nullability
            (leftNullability == Nullability.nullable &&
                rightNullability == Nullability.nullable) ||
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
            (leftNullability == Nullability.legacy &&
                rightNullability == Nullability.nonNullable) ||
            // pkg/front_end/test/fasta/incremental_hello_test
            // pkg/front_end/test/explicit_creation_test
            // pkg/front_end/tool/fasta_perf_test
            // replicated in nnbd_mixed/type_parameter_nullability
            (leftNullability == Nullability.nullable &&
                rightNullability == Nullability.undetermined) ||
            // These are only observed in tests and might be artifacts of the
            // tests rather than real situations:
            //
            // pkg/front_end/test/fasta/types/kernel_type_parser_test
            // pkg/front_end/test/fasta/types/fasta_types_test
            (leftNullability == Nullability.legacy &&
                rightNullability == Nullability.nullable) ||
            // pkg/front_end/test/fasta/types/kernel_type_parser_test
            // pkg/front_end/test/fasta/types/fasta_types_test
            (leftNullability == Nullability.nonNullable &&
                rightNullability == Nullability.nullable) ||
            // pkg/front_end/test/fasta/types/kernel_type_parser_test
            // pkg/front_end/test/fasta/types/fasta_types_test
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
  DartType get nonTypeVariableBound {
    DartType resolvedTypeParameterType = right.nonTypeVariableBound;
    return resolvedTypeParameterType.withDeclaredNullability(
        combineNullabilitiesForSubstitution(
            resolvedTypeParameterType.declaredNullability,
            declaredNullability));
  }

  @override
  bool get hasNonObjectMemberAccess =>
      nonTypeVariableBound.hasNonObjectMemberAccess;

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
            // pkg/front_end/test/fasta/types/kernel_type_parser_test
            // pkg/front_end/test/fasta/incremental_hello_test
            // pkg/front_end/test/fasta/types/fasta_types_test
            // pkg/front_end/test/explicit_creation_test
            // pkg/front_end/tool/fasta_perf_test
            // nnbd/issue42089
            (lhsNullability == Nullability.nullable &&
                rhsNullability == Nullability.nullable) ||
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
                rhsNullability == Nullability.nonNullable) ||
            // pkg/front_end/test/fasta/incremental_hello_test
            // pkg/front_end/test/explicit_creation_test
            // pkg/front_end/tool/fasta_perf_test
            // pkg/front_end/test/fasta/incremental_hello_test
            (lhsNullability == Nullability.nullable &&
                rhsNullability == Nullability.undetermined) ||

            // This is created but never observed.
            // (lhsNullability == Nullability.legacy &&
            //     rhsNullability == Nullability.nullable) ||

            // pkg/front_end/test/fasta/types/kernel_type_parser_test
            // pkg/front_end/test/fasta/types/fasta_types_test
            (lhsNullability == Nullability.undetermined &&
                rhsNullability == Nullability.legacy) ||
            // pkg/front_end/test/fasta/types/kernel_type_parser_test
            // pkg/front_end/test/fasta/types/fasta_types_test
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

  TypeParameter parameter;

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
      : declaredNullability = library.isNonNullableByDefault
            ? computeNullabilityFromBound(parameter)
            : Nullability.legacy;

  @override
  DartType get nonTypeVariableBound {
    DartType resolvedTypeParameterType = bound.nonTypeVariableBound;
    return resolvedTypeParameterType.withDeclaredNullability(
        combineNullabilitiesForSubstitution(
            resolvedTypeParameterType.declaredNullability,
            declaredNullability));
  }

  @override
  bool get hasNonObjectMemberAccess =>
      nonTypeVariableBound.hasNonObjectMemberAccess;

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
      if (parameter != other.parameter) {
        if (parameter.isStructuralParameter) {
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
      return true;
    } else {
      return false;
    }
  }

  @override
  int get hashCode {
    // TODO(johnniwinther): Since we use a unification strategy for function
    //  type parameter equality, we have to assume they can end up being
    //  equal. Maybe we should change the equality strategy.
    int hash = parameter.isStructuralParameter ? 0 : parameter.hashCode;
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
  DartType get nonTypeVariableBound {
    DartType resolvedTypeParameterType = bound.nonTypeVariableBound;
    return resolvedTypeParameterType.withDeclaredNullability(
        combineNullabilitiesForSubstitution(
            resolvedTypeParameterType.nullability, declaredNullability));
  }

  @override
  bool get hasNonObjectMemberAccess =>
      nonTypeVariableBound.hasNonObjectMemberAccess;

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
    // TODO(johnniwinther): Since we use a unification strategy for function
    //  type parameter equality, we have to assume they can end up being
    //  equal. Maybe we should change the equality strategy.
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

class RecordType extends DartType {
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

  @override
  Nullability get nullability => declaredNullability;

  @override
  DartType get nonTypeVariableBound => this;

  @override
  bool get hasNonObjectMemberAccess => switch (declaredNullability) {
        Nullability.undetermined => false,
        Nullability.nullable => false,
        Nullability.nonNullable => true,
        Nullability.legacy => true,
      };

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
  int? _variance;

  int get variance => _variance ?? Variance.covariant;

  void set variance(int? newVariance) => _variance = newVariance;

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

  bool get isStructuralParameter => declaration == null;
}

/// Declaration of a type variable by a [FunctionType]
///
/// [StructuralParameter] objects should not be shared between different
/// [FunctionType] objects.
class StructuralParameter extends Node {
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
  int? _variance;

  int get variance => _variance ?? Variance.covariant;

  void set variance(int? newVariance) => _variance = newVariance;

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

// ------------------------------------------------------------------------
//                             CONSTANTS
// ------------------------------------------------------------------------

sealed class Constant extends Node {
  /// Calls the `visit*ConstantReference()` method on visitor [v] for all
  /// constants referenced in this constant.
  ///
  /// (Note that a constant can be seen as a DAG (directed acyclic graph) and
  ///  not a tree!)
  @override
  void visitChildren(Visitor v);

  /// Calls the `visit*Constant()` method on the visitor [v].
  @override
  R accept<R>(ConstantVisitor<R> v);

  /// Calls the `visit*Constant()` method on the visitor [v].
  @override
  R accept1<R, A>(ConstantVisitor1<R, A> v, A arg);

  /// Calls the `visit*ConstantReference()` method on the visitor [v].
  R acceptReference<R>(ConstantReferenceVisitor<R> v);

  /// Calls the `visit*ConstantReference()` method on the visitor [v].
  R acceptReference1<R, A>(ConstantReferenceVisitor1<R, A> v, A arg);

  /// The Kernel AST will reference [Constant]s via [ConstantExpression]s.  The
  /// constants are not required to be canonicalized, but they have to be deeply
  /// comparable via hashCode/==!
  @override
  int get hashCode;

  @override
  bool operator ==(Object other);

  @override
  String toString() => throw '$runtimeType';

  /// Returns a textual representation of the this constant.
  ///
  /// If [verbose] is `true`, qualified names will include the library name/uri.
  @override
  String toText(AstTextStrategy strategy) {
    AstPrinter printer = new AstPrinter(strategy);
    printer.writeConstant(this);
    return printer.getText();
  }

  @override
  void toTextInternal(AstPrinter printer);

  /// Gets the type of this constant.
  DartType getType(StaticTypeContext context);
}

abstract class AuxiliaryConstant extends Constant {
  @override
  R accept<R>(ConstantVisitor<R> v) => v.visitAuxiliaryConstant(this);

  @override
  R accept1<R, A>(ConstantVisitor1<R, A> v, A arg) =>
      v.visitAuxiliaryConstant(this, arg);

  @override
  R acceptReference<R>(ConstantReferenceVisitor<R> v) =>
      v.visitAuxiliaryConstantReference(this);

  @override
  R acceptReference1<R, A>(ConstantReferenceVisitor1<R, A> v, A arg) =>
      v.visitAuxiliaryConstantReference(this, arg);
}

sealed class PrimitiveConstant<T> extends Constant {
  final T value;

  PrimitiveConstant(this.value);

  @override
  int get hashCode => value.hashCode;

  @override
  bool operator ==(Object other) =>
      other is PrimitiveConstant<T> && other.value == value;

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('$value');
  }
}

class NullConstant extends PrimitiveConstant<Null> {
  NullConstant() : super(null);

  @override
  void visitChildren(Visitor v) {}

  @override
  R accept<R>(ConstantVisitor<R> v) => v.visitNullConstant(this);

  @override
  R accept1<R, A>(ConstantVisitor1<R, A> v, A arg) =>
      v.visitNullConstant(this, arg);

  @override
  R acceptReference<R>(ConstantReferenceVisitor<R> v) =>
      v.visitNullConstantReference(this);

  @override
  R acceptReference1<R, A>(ConstantReferenceVisitor1<R, A> v, A arg) =>
      v.visitNullConstantReference(this, arg);

  @override
  DartType getType(StaticTypeContext context) => const NullType();

  @override
  String toString() => 'NullConstant(${toStringInternal()})';
}

class BoolConstant extends PrimitiveConstant<bool> {
  BoolConstant(bool value) : super(value);

  @override
  void visitChildren(Visitor v) {}

  @override
  R accept<R>(ConstantVisitor<R> v) => v.visitBoolConstant(this);

  @override
  R accept1<R, A>(ConstantVisitor1<R, A> v, A arg) =>
      v.visitBoolConstant(this, arg);

  @override
  R acceptReference<R>(ConstantReferenceVisitor<R> v) =>
      v.visitBoolConstantReference(this);

  @override
  R acceptReference1<R, A>(ConstantReferenceVisitor1<R, A> v, A arg) =>
      v.visitBoolConstantReference(this, arg);

  @override
  DartType getType(StaticTypeContext context) =>
      context.typeEnvironment.coreTypes.boolRawType(context.nonNullable);

  @override
  String toString() => 'BoolConstant(${toStringInternal()})';
}

/// An integer constant on a non-JS target.
class IntConstant extends PrimitiveConstant<int> {
  IntConstant(int value) : super(value);

  @override
  void visitChildren(Visitor v) {}

  @override
  R accept<R>(ConstantVisitor<R> v) => v.visitIntConstant(this);

  @override
  R accept1<R, A>(ConstantVisitor1<R, A> v, A arg) =>
      v.visitIntConstant(this, arg);

  @override
  R acceptReference<R>(ConstantReferenceVisitor<R> v) =>
      v.visitIntConstantReference(this);

  @override
  R acceptReference1<R, A>(ConstantReferenceVisitor1<R, A> v, A arg) =>
      v.visitIntConstantReference(this, arg);

  @override
  DartType getType(StaticTypeContext context) =>
      context.typeEnvironment.coreTypes.intRawType(context.nonNullable);

  @override
  String toString() => 'IntConstant(${toStringInternal()})';
}

/// A double constant on a non-JS target or any numeric constant on a JS target.
class DoubleConstant extends PrimitiveConstant<double> {
  DoubleConstant(double value) : super(value);

  @override
  void visitChildren(Visitor v) {}

  @override
  R accept<R>(ConstantVisitor<R> v) => v.visitDoubleConstant(this);

  @override
  R accept1<R, A>(ConstantVisitor1<R, A> v, A arg) =>
      v.visitDoubleConstant(this, arg);

  @override
  R acceptReference<R>(ConstantReferenceVisitor<R> v) =>
      v.visitDoubleConstantReference(this);

  @override
  R acceptReference1<R, A>(ConstantReferenceVisitor1<R, A> v, A arg) =>
      v.visitDoubleConstantReference(this, arg);

  @override
  int get hashCode => value.isNaN ? 199 : super.hashCode;

  @override
  bool operator ==(Object other) =>
      other is DoubleConstant && identical(value, other.value);

  @override
  DartType getType(StaticTypeContext context) =>
      context.typeEnvironment.coreTypes.doubleRawType(context.nonNullable);

  @override
  String toString() => 'DoubleConstant(${toStringInternal()})';
}

class StringConstant extends PrimitiveConstant<String> {
  StringConstant(String value) : super(value);

  @override
  void visitChildren(Visitor v) {}

  @override
  R accept<R>(ConstantVisitor<R> v) => v.visitStringConstant(this);

  @override
  R accept1<R, A>(ConstantVisitor1<R, A> v, A arg) =>
      v.visitStringConstant(this, arg);

  @override
  R acceptReference<R>(ConstantReferenceVisitor<R> v) =>
      v.visitStringConstantReference(this);

  @override
  R acceptReference1<R, A>(ConstantReferenceVisitor1<R, A> v, A arg) =>
      v.visitStringConstantReference(this, arg);

  @override
  DartType getType(StaticTypeContext context) =>
      context.typeEnvironment.coreTypes.stringRawType(context.nonNullable);

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('"');
    printer.write(escapeString(value));
    printer.write('"');
  }

  @override
  String toString() => 'StringConstant(${toStringInternal()})';
}

class SymbolConstant extends Constant {
  final String name;
  final Reference? libraryReference;

  SymbolConstant(this.name, this.libraryReference);

  @override
  void visitChildren(Visitor v) {}

  @override
  R accept<R>(ConstantVisitor<R> v) => v.visitSymbolConstant(this);

  @override
  R accept1<R, A>(ConstantVisitor1<R, A> v, A arg) =>
      v.visitSymbolConstant(this, arg);

  @override
  R acceptReference<R>(ConstantReferenceVisitor<R> v) =>
      v.visitSymbolConstantReference(this);

  @override
  R acceptReference1<R, A>(ConstantReferenceVisitor1<R, A> v, A arg) =>
      v.visitSymbolConstantReference(this, arg);

  @override
  String toString() => 'SymbolConstant(${toStringInternal()})';

  @override
  int get hashCode => _Hash.hash2(name, libraryReference);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SymbolConstant &&
          other.name == name &&
          other.libraryReference == libraryReference);

  @override
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

  @override
  void visitChildren(Visitor v) {
    keyType.accept(v);
    valueType.accept(v);
    for (final ConstantMapEntry entry in entries) {
      entry.key.acceptReference(v);
      entry.value.acceptReference(v);
    }
  }

  @override
  R accept<R>(ConstantVisitor<R> v) => v.visitMapConstant(this);

  @override
  R accept1<R, A>(ConstantVisitor1<R, A> v, A arg) =>
      v.visitMapConstant(this, arg);

  @override
  R acceptReference<R>(ConstantReferenceVisitor<R> v) =>
      v.visitMapConstantReference(this);

  @override
  R acceptReference1<R, A>(ConstantReferenceVisitor1<R, A> v, A arg) =>
      v.visitMapConstantReference(this, arg);

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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MapConstant &&
          other.keyType == keyType &&
          other.valueType == valueType &&
          listEquals(other.entries, entries));

  @override
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

  @override
  void visitChildren(Visitor v) {
    typeArgument.accept(v);
    for (final Constant constant in entries) {
      constant.acceptReference(v);
    }
  }

  @override
  R accept<R>(ConstantVisitor<R> v) => v.visitListConstant(this);

  @override
  R accept1<R, A>(ConstantVisitor1<R, A> v, A arg) =>
      v.visitListConstant(this, arg);

  @override
  R acceptReference<R>(ConstantReferenceVisitor<R> v) =>
      v.visitListConstantReference(this);

  @override
  R acceptReference1<R, A>(ConstantReferenceVisitor1<R, A> v, A arg) =>
      v.visitListConstantReference(this, arg);

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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ListConstant &&
          other.typeArgument == typeArgument &&
          listEquals(other.entries, entries));

  @override
  DartType getType(StaticTypeContext context) =>
      context.typeEnvironment.listType(typeArgument, context.nonNullable);
}

class SetConstant extends Constant {
  final DartType typeArgument;
  final List<Constant> entries;

  SetConstant(this.typeArgument, this.entries);

  @override
  void visitChildren(Visitor v) {
    typeArgument.accept(v);
    for (final Constant constant in entries) {
      constant.acceptReference(v);
    }
  }

  @override
  R accept<R>(ConstantVisitor<R> v) => v.visitSetConstant(this);

  @override
  R accept1<R, A>(ConstantVisitor1<R, A> v, A arg) =>
      v.visitSetConstant(this, arg);

  @override
  R acceptReference<R>(ConstantReferenceVisitor<R> v) =>
      v.visitSetConstantReference(this);

  @override
  R acceptReference1<R, A>(ConstantReferenceVisitor1<R, A> v, A arg) =>
      v.visitSetConstantReference(this, arg);

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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SetConstant &&
          other.typeArgument == typeArgument &&
          listEquals(other.entries, entries));

  @override
  DartType getType(StaticTypeContext context) =>
      context.typeEnvironment.setType(typeArgument, context.nonNullable);
}

class RecordConstant extends Constant {
  /// Positional field values.
  final List<Constant> positional;

  /// Named field values, sorted by name.
  final Map<String, Constant> named;

  /// The runtime type of the constant.
  ///
  /// [recordType] is computed from the individual types of the record fields
  /// and reflects runtime type of the record constant, as opposed to the
  /// static type of the expression that defined the constant.
  ///
  /// The following program shows the distinction between the static and the
  /// runtime types of the constant. The static type of the first record in the
  /// invocation of `identical` is `(E, String)`, the static type of the second
  /// — `(int, String)`. The runtime type of both constants is `(int, String)`,
  /// and the assertion condition should be satisfied.
  ///
  ///   extension type const E(Object? it) {}
  ///
  ///   main() {
  ///     const bool check = identical(const (E(1), "foo"), const (1, "foo"));
  ///     assert(check);
  ///   }
  final RecordType recordType;

  RecordConstant(this.positional, this.named, this.recordType)
      : assert(positional.length == recordType.positional.length &&
            named.length == recordType.named.length &&
            recordType.named
                .map((f) => f.name)
                .toSet()
                .containsAll(named.keys)),
        assert(() {
          // Assert that the named fields are sorted.
          String? previous;
          for (String name in named.keys) {
            if (previous != null && name.compareTo(previous) < 0) {
              return false;
            }
            previous = name;
          }
          return true;
        }(),
            "Named fields of a RecordConstant aren't sorted lexicographically: "
            "${named.keys.join(", ")}");

  RecordConstant.fromTypeContext(
      this.positional, this.named, StaticTypeContext staticTypeContext)
      : recordType = new RecordType([
          for (Constant constant in positional)
            constant.getType(staticTypeContext)
        ], [
          for (var MapEntry(key: name, value: constant) in named.entries)
            new NamedType(name, constant.getType(staticTypeContext))
        ], staticTypeContext.nonNullable);

  @override
  void visitChildren(Visitor v) {
    recordType.accept(v);
    for (final Constant entry in positional) {
      entry.acceptReference(v);
    }
    for (final Constant entry in named.values) {
      entry.acceptReference(v);
    }
  }

  @override
  R accept<R>(ConstantVisitor<R> v) => v.visitRecordConstant(this);

  @override
  R accept1<R, A>(ConstantVisitor1<R, A> v, A arg) =>
      v.visitRecordConstant(this, arg);

  @override
  R acceptReference<R>(ConstantReferenceVisitor<R> v) =>
      v.visitRecordConstantReference(this);

  @override
  R acceptReference1<R, A>(ConstantReferenceVisitor1<R, A> v, A arg) =>
      v.visitRecordConstantReference(this, arg);

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write("const (");
    String comma = '';
    for (Constant entry in positional) {
      printer.write(comma);
      printer.writeConstant(entry);
      comma = ', ';
    }
    if (named.isNotEmpty) {
      printer.write(comma);
      comma = '';
      printer.write("{");
      for (MapEntry<String, Constant> entry in named.entries) {
        printer.write(comma);
        printer.write(entry.key);
        printer.write(": ");
        printer.writeConstant(entry.value);
        comma = ', ';
      }
      printer.write("}");
    }
    printer.write(")");
  }

  @override
  String toString() => "RecordConstant(${toStringInternal()})";

  @override
  late final int hashCode =
      _Hash.combineMapHashUnordered(named, _Hash.combineListHash(positional));

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecordConstant &&
          listEquals(other.positional, positional) &&
          mapEquals(other.named, named));

  @override
  DartType getType(StaticTypeContext context) => recordType;
}

class InstanceConstant extends Constant {
  final Reference classReference;
  final List<DartType> typeArguments;
  final Map<Reference, Constant> fieldValues;

  InstanceConstant(this.classReference, this.typeArguments, this.fieldValues);

  Class get classNode => classReference.asClass;

  @override
  void visitChildren(Visitor v) {
    classReference.asClass.acceptReference(v);
    visitList(typeArguments, v);
    for (final Reference reference in fieldValues.keys) {
      reference.asField.acceptReference(v);
    }
    for (final Constant constant in fieldValues.values) {
      constant.acceptReference(v);
    }
  }

  @override
  R accept<R>(ConstantVisitor<R> v) => v.visitInstanceConstant(this);

  @override
  R accept1<R, A>(ConstantVisitor1<R, A> v, A arg) =>
      v.visitInstanceConstant(this, arg);

  @override
  R acceptReference<R>(ConstantReferenceVisitor<R> v) =>
      v.visitInstanceConstantReference(this);

  @override
  R acceptReference1<R, A>(ConstantReferenceVisitor1<R, A> v, A arg) =>
      v.visitInstanceConstantReference(this, arg);

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

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is InstanceConstant &&
            other.classReference == classReference &&
            listEquals(other.typeArguments, typeArguments) &&
            mapEquals(other.fieldValues, fieldValues));
  }

  @override
  DartType getType(StaticTypeContext context) =>
      new InterfaceType(classNode, context.nonNullable, typeArguments);
}

class InstantiationConstant extends Constant {
  final Constant tearOffConstant;
  final List<DartType> types;

  InstantiationConstant(this.tearOffConstant, this.types);

  @override
  void visitChildren(Visitor v) {
    tearOffConstant.acceptReference(v);
    visitList(types, v);
  }

  @override
  R accept<R>(ConstantVisitor<R> v) => v.visitInstantiationConstant(this);

  @override
  R accept1<R, A>(ConstantVisitor1<R, A> v, A arg) =>
      v.visitInstantiationConstant(this, arg);

  @override
  R acceptReference<R>(ConstantReferenceVisitor<R> v) =>
      v.visitInstantiationConstantReference(this);

  @override
  R acceptReference1<R, A>(ConstantReferenceVisitor1<R, A> v, A arg) =>
      v.visitInstantiationConstantReference(this, arg);

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeConstant(tearOffConstant);
    printer.writeTypeArguments(types);
  }

  @override
  String toString() => 'InstantiationConstant(${toStringInternal()})';

  @override
  int get hashCode => _Hash.combineFinish(
      tearOffConstant.hashCode, _Hash.combineListHash(types));

  @override
  bool operator ==(Object other) {
    return other is InstantiationConstant &&
        other.tearOffConstant == tearOffConstant &&
        listEquals(other.types, types);
  }

  @override
  DartType getType(StaticTypeContext context) {
    final FunctionType type = tearOffConstant.getType(context) as FunctionType;
    return FunctionTypeInstantiator.instantiate(type, types);
  }
}

abstract class TearOffConstant implements Constant {
  Reference get targetReference;
  Member get target;
  FunctionNode get function;
}

class StaticTearOffConstant extends Constant implements TearOffConstant {
  @override
  final Reference targetReference;

  StaticTearOffConstant(Procedure target)
      : assert(target.isStatic),
        assert(target.kind == ProcedureKind.Method,
            "Unexpected static tear off target: $target"),
        targetReference = target.reference;

  StaticTearOffConstant.byReference(this.targetReference);

  @override
  Procedure get target => targetReference.asProcedure;

  @override
  FunctionNode get function => target.function;

  @override
  void visitChildren(Visitor v) {
    target.acceptReference(v);
  }

  @override
  R accept<R>(ConstantVisitor<R> v) => v.visitStaticTearOffConstant(this);

  @override
  R accept1<R, A>(ConstantVisitor1<R, A> v, A arg) =>
      v.visitStaticTearOffConstant(this, arg);

  @override
  R acceptReference<R>(ConstantReferenceVisitor<R> v) =>
      v.visitStaticTearOffConstantReference(this);

  @override
  R acceptReference1<R, A>(ConstantReferenceVisitor1<R, A> v, A arg) =>
      v.visitStaticTearOffConstantReference(this, arg);

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeMemberName(targetReference);
  }

  @override
  String toString() => 'StaticTearOffConstant(${toStringInternal()})';

  @override
  int get hashCode => targetReference.hashCode;

  @override
  bool operator ==(Object other) {
    return other is StaticTearOffConstant &&
        other.targetReference == targetReference;
  }

  @override
  FunctionType getType(StaticTypeContext context) {
    return target.function.computeFunctionType(context.nonNullable);
  }
}

class ConstructorTearOffConstant extends Constant implements TearOffConstant {
  @override
  final Reference targetReference;

  ConstructorTearOffConstant(Member target)
      : assert(
            target is Constructor || (target is Procedure && target.isFactory),
            "Unexpected constructor tear off target: $target"),
        this.targetReference = getNonNullableMemberReferenceGetter(target);

  ConstructorTearOffConstant.byReference(this.targetReference);

  @override
  Member get target => targetReference.asMember;

  @override
  FunctionNode get function => target.function!;

  @override
  void visitChildren(Visitor v) {
    target.acceptReference(v);
  }

  @override
  R accept<R>(ConstantVisitor<R> v) => v.visitConstructorTearOffConstant(this);

  @override
  R accept1<R, A>(ConstantVisitor1<R, A> v, A arg) =>
      v.visitConstructorTearOffConstant(this, arg);

  @override
  R acceptReference<R>(ConstantReferenceVisitor<R> v) =>
      v.visitConstructorTearOffConstantReference(this);

  @override
  R acceptReference1<R, A>(ConstantReferenceVisitor1<R, A> v, A arg) =>
      v.visitConstructorTearOffConstantReference(this, arg);

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeMemberName(targetReference);
  }

  @override
  String toString() => 'ConstructorTearOffConstant(${toStringInternal()})';

  @override
  int get hashCode => targetReference.hashCode;

  @override
  bool operator ==(Object other) {
    return other is ConstructorTearOffConstant &&
        other.targetReference == targetReference;
  }

  @override
  FunctionType getType(StaticTypeContext context) {
    return function.computeFunctionType(context.nonNullable);
  }
}

class RedirectingFactoryTearOffConstant extends Constant
    implements TearOffConstant {
  @override
  final Reference targetReference;

  RedirectingFactoryTearOffConstant(Procedure target)
      : assert(target.isRedirectingFactory),
        this.targetReference = getNonNullableMemberReferenceGetter(target);

  RedirectingFactoryTearOffConstant.byReference(this.targetReference);

  @override
  Procedure get target => targetReference.asProcedure;

  @override
  FunctionNode get function => target.function;

  @override
  void visitChildren(Visitor v) {
    target.acceptReference(v);
  }

  @override
  R accept<R>(ConstantVisitor<R> v) =>
      v.visitRedirectingFactoryTearOffConstant(this);

  @override
  R accept1<R, A>(ConstantVisitor1<R, A> v, A arg) =>
      v.visitRedirectingFactoryTearOffConstant(this, arg);

  @override
  R acceptReference<R>(ConstantReferenceVisitor<R> v) =>
      v.visitRedirectingFactoryTearOffConstantReference(this);

  @override
  R acceptReference1<R, A>(ConstantReferenceVisitor1<R, A> v, A arg) =>
      v.visitRedirectingFactoryTearOffConstantReference(this, arg);

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeMemberName(targetReference);
  }

  @override
  String toString() =>
      'RedirectingFactoryTearOffConstant(${toStringInternal()})';

  @override
  int get hashCode => targetReference.hashCode;

  @override
  bool operator ==(Object other) {
    return other is RedirectingFactoryTearOffConstant &&
        other.targetReference == targetReference;
  }

  @override
  FunctionType getType(StaticTypeContext context) {
    return function.computeFunctionType(context.nonNullable);
  }
}

class TypedefTearOffConstant extends Constant {
  // TODO(johnniwinther): Change this to use [StructuralParameter].
  final List<TypeParameter> parameters;
  final TearOffConstant tearOffConstant;
  final List<DartType> types;

  @override
  late final int hashCode = _computeHashCode();

  TypedefTearOffConstant(this.parameters, this.tearOffConstant, this.types);

  @override
  void visitChildren(Visitor v) {
    visitList(parameters, v);
    tearOffConstant.acceptReference(v);
    visitList(types, v);
  }

  @override
  R accept<R>(ConstantVisitor<R> v) => v.visitTypedefTearOffConstant(this);

  @override
  R accept1<R, A>(ConstantVisitor1<R, A> v, A arg) =>
      v.visitTypedefTearOffConstant(this, arg);

  @override
  R acceptReference<R>(ConstantReferenceVisitor<R> v) =>
      v.visitTypedefTearOffConstantReference(this);

  @override
  R acceptReference1<R, A>(ConstantReferenceVisitor1<R, A> v, A arg) =>
      v.visitTypedefTearOffConstantReference(this, arg);

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeTypeParameters(parameters);
    printer.writeConstant(tearOffConstant);
    printer.writeTypeArguments(types);
  }

  @override
  String toString() => 'TypedefTearOffConstant(${toStringInternal()})';

  @override
  bool operator ==(Object other) {
    if (other is! TypedefTearOffConstant) return false;
    if (other.tearOffConstant != tearOffConstant) return false;
    if (other.parameters.length != parameters.length) return false;
    if (parameters.isNotEmpty) {
      Assumptions assumptions = new Assumptions();
      for (int index = 0; index < parameters.length; index++) {
        assumptions.assume(parameters[index], other.parameters[index]);
      }
      for (int index = 0; index < parameters.length; index++) {
        if (!parameters[index]
            .bound
            .equals(other.parameters[index].bound, assumptions)) {
          return false;
        }
      }
      for (int i = 0; i < types.length; ++i) {
        if (!types[i].equals(other.types[i], assumptions)) {
          return false;
        }
      }
    }
    return true;
  }

  int _computeHashCode() {
    int hash = 1237;
    for (int i = 0; i < parameters.length; ++i) {
      TypeParameter parameter = parameters[i];
      hash = 0x3fffffff & (hash * 31 + parameter.bound.hashCode);
    }
    for (int i = 0; i < types.length; ++i) {
      hash = 0x3fffffff & (hash * 31 + types[i].hashCode);
    }
    hash = 0x3fffffff & (hash * 31 + tearOffConstant.hashCode);
    return hash;
  }

  @override
  DartType getType(StaticTypeContext context) {
    FunctionType type = tearOffConstant.getType(context) as FunctionType;
    FreshStructuralParametersFromTypeParameters freshStructuralParameters =
        getFreshStructuralParametersFromTypeParameters(parameters);
    type = freshStructuralParameters.substitute(
        FunctionTypeInstantiator.instantiate(type, types)) as FunctionType;
    return new FunctionType(
        type.positionalParameters, type.returnType, type.declaredNullability,
        namedParameters: type.namedParameters,
        typeParameters: freshStructuralParameters.freshTypeParameters,
        requiredParameterCount: type.requiredParameterCount);
  }
}

class TypeLiteralConstant extends Constant {
  final DartType type;

  TypeLiteralConstant(this.type);

  @override
  void visitChildren(Visitor v) {
    type.accept(v);
  }

  @override
  R accept<R>(ConstantVisitor<R> v) => v.visitTypeLiteralConstant(this);

  @override
  R accept1<R, A>(ConstantVisitor1<R, A> v, A arg) =>
      v.visitTypeLiteralConstant(this, arg);

  @override
  R acceptReference<R>(ConstantReferenceVisitor<R> v) =>
      v.visitTypeLiteralConstantReference(this);

  @override
  R acceptReference1<R, A>(ConstantReferenceVisitor1<R, A> v, A arg) =>
      v.visitTypeLiteralConstantReference(this, arg);

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeType(type);
  }

  @override
  String toString() => 'TypeLiteralConstant(${toStringInternal()})';

  @override
  int get hashCode => type.hashCode;

  @override
  bool operator ==(Object other) {
    return other is TypeLiteralConstant && other.type == type;
  }

  @override
  DartType getType(StaticTypeContext context) =>
      context.typeEnvironment.coreTypes.typeRawType(context.nonNullable);
}

class UnevaluatedConstant extends Constant {
  final Expression expression;

  UnevaluatedConstant(this.expression) {
    expression.parent = null;
  }

  @override
  void visitChildren(Visitor v) {
    expression.accept(v);
  }

  @override
  R accept<R>(ConstantVisitor<R> v) => v.visitUnevaluatedConstant(this);

  @override
  R accept1<R, A>(ConstantVisitor1<R, A> v, A arg) =>
      v.visitUnevaluatedConstant(this, arg);

  @override
  R acceptReference<R>(ConstantReferenceVisitor<R> v) =>
      v.visitUnevaluatedConstantReference(this);

  @override
  R acceptReference1<R, A>(ConstantReferenceVisitor1<R, A> v, A arg) =>
      v.visitUnevaluatedConstantReference(this, arg);

  @override
  DartType getType(StaticTypeContext context) =>
      expression.getStaticType(context);

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
      Map<Uri, Source>? uriToSource,
      NonNullableByDefaultCompiledMode? mode})
      : root = nameRoot ?? new CanonicalName.root(),
        libraries = libraries ?? <Library>[],
        uriToSource = uriToSource ?? <Uri, Source>{},
        _mode = mode {
    adoptChildren();
  }

  void adoptChildren() {
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
    library.ensureCanonicalNames(root);
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
  Location? getLocation(Uri file, int offset) {
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

  @override
  String leakingDebugToString() => astToText.debugComponentToString(this);
}

/// A tuple with file, line, and column number, for displaying human-readable
/// locations.
class Location {
  final Uri file;
  final int line; // 1-based.
  final int column; // 1-based.

  Location(this.file, this.line, this.column);

  @override
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
    return !(node is MapLiteralEntry ||
        node is Catch ||
        (node is Block && node.parent is BlockExpression));
  }
}

abstract class BinarySink {
  void writeByte(int byte);
  void writeUInt32(int value);
  void writeUInt30(int value);

  /// Write List<Byte> into the sink.
  void writeByteList(List<int> bytes);

  void writeNullAllowedCanonicalNameReference(Reference? reference);
  void writeStringReference(String str);
  void writeDartType(DartType type);
  void writeConstantReference(Constant constant);
}

abstract class BinarySource {
  int readByte();
  int readUInt30();
  int readUint32();

  /// Read List<Byte> from the source.
  List<int> readByteList();

  CanonicalName? readNullableCanonicalNameReference();
  String readStringReference();
  DartType readDartType();
  Constant readConstantReference();
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

    String cachedText = text;
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

  String get text => cachedText ??= utf8.decode(source, allowMalformed: true);

  /// Translates an offset to 1-based line and column numbers in the given file.
  Location getLocation(Uri file, int offset) {
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

Reference getNonNullableMemberReferenceSetter(Member member) {
  if (member is Field) return member.setterReference!;
  return member.reference;
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
    for (MapEntry entry in map.entries) {
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

/// Annotation describing information which is not part of Dart semantics; in
/// other words, if this information (or any information it refers to) changes,
/// static analysis and runtime behavior of the library are unaffected.
const Null informative = null;

Location? _getLocationInComponent(
    Component? component, Uri fileUri, int offset) {
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

  const Version(this.major, this.minor);

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

/// Almost const <SwitchCase>[], but not const in an attempt to avoid
/// polymorphism. See https://dart-review.googlesource.com/c/sdk/+/185828.
final List<SwitchCase> emptyListOfSwitchCase =
    List.filled(0, dummySwitchCase, growable: false);

/// Almost const <SwitchExpressionCase>[], but not const in an attempt to avoid
/// polymorphism. See https://dart-review.googlesource.com/c/sdk/+/185828.
final List<SwitchExpressionCase> emptyListOfSwitchExpressionCase =
    List.filled(0, dummySwitchExpressionCase, growable: false);

/// Almost const <PatternSwitchCase>[], but not const in an attempt to avoid
/// polymorphism. See https://dart-review.googlesource.com/c/sdk/+/185828.
final List<PatternSwitchCase> emptyListOfPatternSwitchCase =
    List.filled(0, dummyPatternSwitchCase, growable: false);

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

/// Almost const <StructuralParameter>[], but not const in an attempt to
/// avoid polymorphism. See https://dart-review.googlesource.com/c/sdk/+/185828.
final List<StructuralParameter> emptyListOfStructuralParameter =
    List.filled(0, dummyStructuralParameter, growable: false);

/// Almost const <Constant>[], but not const in an attempt to avoid
/// polymorphism. See https://dart-review.googlesource.com/c/sdk/+/185828.
final List<Constant> emptyListOfConstant =
    List.filled(0, dummyConstant, growable: false);

/// Almost const <String>[], but not const in an attempt to avoid
/// polymorphism. See https://dart-review.googlesource.com/c/sdk/+/185828.
final List<String> emptyListOfString = List.filled(0, '', growable: false);

/// Almost const <Typedef>[], but not const in an attempt to avoid
/// polymorphism. See https://dart-review.googlesource.com/c/sdk/+/185828.
final List<Typedef> emptyListOfTypedef =
    List.filled(0, dummyTypedef, growable: false);

/// Almost const <Extension>[], but not const in an attempt to avoid
/// polymorphism. See https://dart-review.googlesource.com/c/sdk/+/185828.
final List<Extension> emptyListOfExtension =
    List.filled(0, dummyExtension, growable: false);

/// Almost const <ExtensionTypeDeclaration>[], but not const in an attempt to
/// avoid polymorphism. See https://dart-review.googlesource.com/c/sdk/+/185828.
final List<ExtensionTypeDeclaration> emptyListOfExtensionTypeDeclaration =
    List.filled(0, dummyExtensionTypeDeclaration, growable: false);

/// Almost const <Field>[], but not const in an attempt to avoid
/// polymorphism. See https://dart-review.googlesource.com/c/sdk/+/185828.
final List<Field> emptyListOfField =
    List.filled(0, dummyField, growable: false);

/// Almost const <LibraryPart>[], but not const in an attempt to avoid
/// polymorphism. See https://dart-review.googlesource.com/c/sdk/+/185828.
final List<LibraryPart> emptyListOfLibraryPart =
    List.filled(0, dummyLibraryPart, growable: false);

/// Almost const <LibraryDependency>[], but not const in an attempt to avoid
/// polymorphism. See https://dart-review.googlesource.com/c/sdk/+/185828.
final List<LibraryDependency> emptyListOfLibraryDependency =
    List.filled(0, dummyLibraryDependency, growable: false);

/// Almost const <Procedure>[], but not const in an attempt to avoid
/// polymorphism. See https://dart-review.googlesource.com/c/sdk/+/185828.
final List<Procedure> emptyListOfProcedure =
    List.filled(0, dummyProcedure, growable: false);

/// Almost const <MapLiteralEntry>[], but not const in an attempt to avoid
/// polymorphism. See https://dart-review.googlesource.com/c/sdk/+/185828.
final List<MapLiteralEntry> emptyListOfMapLiteralEntry =
    List.filled(0, dummyMapLiteralEntry, growable: false);

/// Almost const <Class>[], but not const in an attempt to avoid
/// polymorphism. See https://dart-review.googlesource.com/c/sdk/+/185828.
final List<Class> emptyListOfClass =
    List.filled(0, dummyClass, growable: false);

/// Almost const <ExtensionMemberDescriptor>[], but not const in an attempt to
/// avoid polymorphism. See https://dart-review.googlesource.com/c/sdk/+/185828.
final List<ExtensionMemberDescriptor> emptyListOfExtensionMemberDescriptor =
    List.filled(0, dummyExtensionMemberDescriptor, growable: false);

/// Almost const <ExtensionTypeMemberDescriptor>[], but not const in an attempt
/// to avoid polymorphism. See
/// https://dart-review.googlesource.com/c/sdk/+/185828.
final List<ExtensionTypeMemberDescriptor>
    emptyListOfExtensionTypeMemberDescriptor =
    List.filled(0, dummyExtensionTypeMemberDescriptor, growable: false);

/// Almost const <TypeDeclarationType>[], but not const in an attempt to avoid
/// polymorphism. See https://dart-review.googlesource.com/c/sdk/+/185828.
final List<TypeDeclarationType> emptyListOfTypeDeclarationType =
    List.filled(0, dummyExtensionType, growable: false);

/// Almost const <Constructor>[], but not const in an attempt to avoid
/// polymorphism. See https://dart-review.googlesource.com/c/sdk/+/185828.
final List<Constructor> emptyListOfConstructor =
    List.filled(0, dummyConstructor, growable: false);

/// Almost const <Initializer>[], but not const in an attempt to avoid
/// polymorphism. See https://dart-review.googlesource.com/c/sdk/+/185828.
final List<Initializer> emptyListOfInitializer =
    List.filled(0, dummyInitializer, growable: false);

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

/// Non-nullable [Reference] dummy value.
final Reference dummyReference = new Reference();

/// Non-nullable [Component] dummy value.
///
/// This can be used for instance as a dummy initial value for the `List.filled`
/// constructor.
final Component dummyComponent = new Component();

/// Non-nullable [Library] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final Library dummyLibrary = new Library(dummyUri, fileUri: dummyUri);

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
final Class dummyClass = new Class(name: '', fileUri: dummyUri);

/// Non-nullable [Constructor] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final Constructor dummyConstructor =
    new Constructor(dummyFunctionNode, name: dummyName, fileUri: dummyUri);

/// Non-nullable [Extension] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final Extension dummyExtension = new Extension(name: '', fileUri: dummyUri);

/// Non-nullable [ExtensionMemberDescriptor] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final ExtensionMemberDescriptor dummyExtensionMemberDescriptor =
    new ExtensionMemberDescriptor(
        name: dummyName,
        kind: ExtensionMemberKind.Getter,
        memberReference: dummyReference,
        tearOffReference: null);

/// Non-nullable [ExtensionTypeDeclaration] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final ExtensionTypeDeclaration dummyExtensionTypeDeclaration =
    new ExtensionTypeDeclaration(name: '', fileUri: dummyUri);

/// Non-nullable [ExtensionTypeMemberDescriptor] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final ExtensionTypeMemberDescriptor dummyExtensionTypeMemberDescriptor =
    new ExtensionTypeMemberDescriptor(
        name: dummyName,
        kind: ExtensionTypeMemberKind.Getter,
        memberReference: dummyReference,
        tearOffReference: null);

/// Non-nullable [ExtensionType] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final ExtensionType dummyExtensionType =
    new ExtensionType(dummyExtensionTypeDeclaration, Nullability.nonNullable);

/// Non-nullable [Member] dummy value.
///
/// This can be used for instance as a dummy initial value for the
/// `List.filled` constructor.
final Member dummyMember = new Field.mutable(dummyName, fileUri: dummyUri);

/// Non-nullable [Procedure] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final Procedure dummyProcedure = new Procedure(
    dummyName, ProcedureKind.Method, dummyFunctionNode,
    fileUri: dummyUri);

/// Non-nullable [Field] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final Field dummyField = new Field.mutable(dummyName, fileUri: dummyUri);

/// Non-nullable [Typedef] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final Typedef dummyTypedef = new Typedef('', null, fileUri: dummyUri);

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

/// Almost const <Pattern>[], but not const in an attempt to avoid
/// polymorphism. See
/// https://dart-review.googlesource.com/c/sdk/+/185828.
final List<Pattern> emptyListOfPattern =
    List.filled(0, dummyPattern, growable: false);

/// Almost const <NamedPattern>[], but not const in an attempt to avoid
/// polymorphism. See
/// https://dart-review.googlesource.com/c/sdk/+/185828.
final List<NamedPattern> emptyListOfNamedPattern =
    List.filled(0, dummyNamedPattern, growable: false);

/// Almost const <MapPatternEntry>[], but not const in an attempt to avoid
/// polymorphism. See
/// https://dart-review.googlesource.com/c/sdk/+/185828.
final List<MapPatternEntry> emptyListOfMapPatternEntry =
    List.filled(0, dummyMapPatternEntry, growable: false);

/// Non-nullable [VariableDeclaration] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final VariableDeclaration dummyVariableDeclaration =
    new VariableDeclaration(null, isSynthesized: true);

/// Non-nullable [TypeParameter] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final TypeParameter dummyTypeParameter = new TypeParameter();

/// Non-nullable [StructuralParameter] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final StructuralParameter dummyStructuralParameter = new StructuralParameter();

/// Non-nullable [MapLiteralEntry] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final MapLiteralEntry dummyMapLiteralEntry =
    new MapLiteralEntry(dummyExpression, dummyExpression);

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

/// Non-nullable [Constant] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final Constant dummyConstant = new NullConstant();

/// Non-nullable [LabeledStatement] dummy value.
///
/// This is used as the removal sentinel in [RemovingTransformer] and can be
/// used for instance as a dummy initial value for the `List.filled`
/// constructor.
final LabeledStatement dummyLabeledStatement = new LabeledStatement(null);

/// Of the dummy nodes, some are tree nodes. `TreeNode`s has a parent pointer
/// and that can be set when the dummy is used. This means that we can leak
/// through them. This list will (at least as a stopgap) allow us to null-out
/// the parent pointer when/if needed.
///
/// This should manually be kept up to date.
final List<TreeNode> dummyTreeNodes = [
  dummyComponent,
  dummyLibrary,
  dummyLibraryDependency,
  dummyCombinator,
  dummyLibraryPart,
  dummyClass,
  dummyConstructor,
  dummyExtension,
  dummyMember,
  dummyProcedure,
  dummyField,
  dummyTypedef,
  dummyInitializer,
  dummyFunctionNode,
  dummyStatement,
  dummyExpression,
  dummyNamedExpression,
  dummyVariableDeclaration,
  dummyTypeParameter,
  dummyMapLiteralEntry,
  dummyArguments,
  dummyAssertStatement,
  dummySwitchCase,
  dummyCatch,
  dummyLabeledStatement,
];

void clearDummyTreeNodesParentPointer() {
  for (TreeNode treeNode in dummyTreeNodes) {
    treeNode.parent = null;
  }
}

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
