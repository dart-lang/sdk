// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../../ast.dart';

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
    return _mode ?? NonNullableByDefaultCompiledMode.Strong;
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
  Location? getLocation(Uri file, int offset, {String? viaForErrorMessage}) {
    return uriToSource[file]
        ?.getLocation(file, offset, viaForErrorMessage: viaForErrorMessage);
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

class Source {
  static final Uint8List _emptySource = new Uint8List(0);
  final List<int>? lineStarts;

  /// A UTF8 encoding of the original source file.
  final Uint8List source;

  final Uri? importUri;

  final Uri? fileUri;

  Set<Reference>? constantCoverageConstructors;

  String? cachedText;

  Source(this.lineStarts, this.source, this.importUri, this.fileUri);

  Source.emptySource(this.lineStarts, this.importUri, this.fileUri)
      : source = _emptySource;

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
  Location getLocation(Uri file, int offset, {String? viaForErrorMessage}) {
    List<int>? lineStarts = this.lineStarts;
    if (lineStarts == null || lineStarts.isEmpty) {
      return new Location(file, TreeNode.noOffset, TreeNode.noOffset);
    }
    if (viaForErrorMessage != null) {
      RangeError.checkValueInInterval(
          offset,
          0,
          lineStarts.last,
          'offset',
          'Asked for out-of-bounds offset for uri "$file" '
              'via $viaForErrorMessage');
    } else {
      RangeError.checkValueInInterval(offset, 0, lineStarts.last, 'offset',
          'Asked for out-of-bounds offset for uri "$file"');
    }
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
