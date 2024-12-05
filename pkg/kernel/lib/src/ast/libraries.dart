// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../../ast.dart';

// ------------------------------------------------------------------------
//                      LIBRARIES and CLASSES
// ------------------------------------------------------------------------

enum NonNullableByDefaultCompiledMode { Strong, Weak, Invalid }

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

  static const int NonNullableByDefaultModeBit1 = 1 << 1;
  static const int NonNullableByDefaultModeBit2 = 1 << 2;
  static const int IsUnsupportedFlag = 1 << 3;

  int flags = 0;

  /// If true, the library is synthetic, for instance library that doesn't
  /// represents an actual file and is created as the result of error recovery.
  bool get isSynthetic => flags & SyntheticFlag != 0;
  void set isSynthetic(bool value) {
    flags = value ? (flags | SyntheticFlag) : (flags & ~SyntheticFlag);
  }

  NonNullableByDefaultCompiledMode get nonNullableByDefaultCompiledMode {
    bool bit1 = (flags & NonNullableByDefaultModeBit1) != 0;
    bool bit2 = (flags & NonNullableByDefaultModeBit2) != 0;
    if (!bit1 && !bit2) return NonNullableByDefaultCompiledMode.Strong;
    if (bit1 && !bit2) return NonNullableByDefaultCompiledMode.Weak;
    if (!bit1 && bit2) return NonNullableByDefaultCompiledMode.Invalid;
    throw new StateError("Unused bit-pattern for compilation mode");
  }

  void set nonNullableByDefaultCompiledMode(
      NonNullableByDefaultCompiledMode mode) {
    switch (mode) {
      case NonNullableByDefaultCompiledMode.Strong:
        flags = (flags & ~NonNullableByDefaultModeBit1) &
            ~NonNullableByDefaultModeBit2;
        break;
      case NonNullableByDefaultCompiledMode.Weak:
        flags = (flags | NonNullableByDefaultModeBit1) &
            ~NonNullableByDefaultModeBit2;
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

  Nullability get nullable => Nullability.nullable;

  Nullability get nonNullable => Nullability.nonNullable;

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
    return _getLocationInComponent(enclosingComponent, fileUri, offset,
        viaForErrorMessage: "Library");
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
