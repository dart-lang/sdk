// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/string_source.dart';
import 'package:analyzer/src/summary/api_signature.dart';
import 'package:analyzer/src/summary/format.dart' as idl;
import 'package:analyzer/src/summary/idl.dart' as idl;
import 'package:analyzer/src/summary/link.dart' as graph
    show DependencyWalker, Node;
import 'package:convert/convert.dart';
import 'package:yaml/yaml.dart';

/// A top-level public declaration.
class Declaration {
  final String name;
  final DeclarationKind kind;

  Declaration(this.name, this.kind);

  @override
  String toString() {
    return '($name, $kind)';
  }
}

/// A kind of a top-level declaration.
enum DeclarationKind {
  CLASS,
  CLASS_TYPE_ALIAS,
  ENUM,
  FUNCTION,
  FUNCTION_TYPE_ALIAS,
  MIXIN,
  VARIABLE
}

/// The context in which completions happens, so declarations are collected.
class DeclarationsContext {
  final DeclarationsTracker _tracker;

  /// The analysis context for this context.  Declarations from all files in
  /// the root are included into completion, even in 'lib/src' folders.
  final AnalysisContext _analysisContext;

  /// Map of path prefixes to lists of files from dependencies (both libraries
  /// and parts, we don't know at the time when we fill this map) that
  /// libraries with files paths starting with these prefixes can access.
  ///
  /// The path prefix keys are sorted so that the longest keys are first.
  final Map<String, List<String>> _pathPrefixToDependencyFiles = {};

  DeclarationsContext(this._tracker, this._analysisContext);

  /// Return libraries that are available to the file with the given [path].
  ///
  /// With `Pub`, files below the `pubspec.yaml` file can access libraries
  /// of packages listed as `dependencies`, and files in the `test` directory
  /// can in addition access libraries of packages listed as `dev_dependencies`.
  ///
  /// With `Bazel` sets of accessible libraries are specified explicitly by
  /// the client using [setDependencies].
  List<int> getLibraries(String path) {
    // TODO(scheglov) include context libraries
    for (var pathPrefix in _pathPrefixToDependencyFiles.keys) {
      if (path.startsWith(pathPrefix)) {
        var pathList = _pathPrefixToDependencyFiles[pathPrefix];
        var idList = pathList
            .map((libPath) => _tracker._pathToFile[libPath])
            .where((file) => file != null && file.isLibrary)
            .map((file) => file.id)
            .toList();
        return idList;
      }
    }
    return <int>[];
  }

  /// Set dependencies for path prefixes in this context.
  ///
  /// The map [pathPrefixToPathList] specifies the list of paths of libraries
  /// and directories with libraries that are accessible to the files with
  /// paths that start with the path that is the key in the map.  The longest
  /// (so most specific) key will be used, each list of paths is complete, and
  /// is not combined with any enclosing locations.
  ///
  /// For `Pub` packages this method is invoked automatically, because their
  /// dependencies, described in `pubspec.yaml` files, and can be automatically
  /// included.  This method is useful for `Bazel` contexts, where dependencies
  /// are specified externally, in form of `BUILD` files.
  ///
  /// New dependencies will replace any previously set dependencies for this
  /// context.
  ///
  /// Every path in the list must be absolute and normalized.
  void setDependencies(Map<String, List<String>> pathPrefixToPathList) {
    var rootFolder = _analysisContext.contextRoot.root;
    _pathPrefixToDependencyFiles.removeWhere((pathPrefix, _) {
      return rootFolder.isOrContains(pathPrefix);
    });

    var sortedPrefixes = pathPrefixToPathList.keys.toList();
    sortedPrefixes.sort((a, b) {
      return b.compareTo(a);
    });

    for (var pathPrefix in sortedPrefixes) {
      var pathList = pathPrefixToPathList[pathPrefix];
      var files = <String>[];
      for (var path in pathList) {
        var resource = _tracker._resourceProvider.getResource(path);
        _scheduleDependencyResource(files, resource);
      }
      _pathPrefixToDependencyFiles[pathPrefix] = files;
    }
  }

  bool _isLibSrcPath(String path) {
    var parts = _tracker._resourceProvider.pathContext.split(path);
    for (var i = 0; i < parts.length - 1; ++i) {
      if (parts[i] == 'lib' && parts[i + 1] == 'src') return true;
    }
    return false;
  }

  List<String> _resolvePackageNamesToLibPaths(List<String> packageNames) {
    return packageNames
        .map(_resolvePackageNameToLibPath)
        .where((path) => path != null)
        .toList();
  }

  String _resolvePackageNameToLibPath(String packageName) {
    try {
      var uri = Uri.parse('package:$packageName/ref.dart');

      var path = _resolveUri(uri);
      if (path == null) return null;

      return _tracker._resourceProvider.pathContext.dirname(path);
    } on FormatException {
      return null;
    }
  }

  String _resolveUri(Uri uri) {
    var uriConverter = _analysisContext.currentSession.uriConverter;
    return uriConverter.uriToPath(uri);
  }

  Uri _restoreUri(String path) {
    var uriConverter = _analysisContext.currentSession.uriConverter;
    return uriConverter.pathToUri(path);
  }

  void _scheduleContextFiles() {
    var contextFiles = _analysisContext.contextRoot.analyzedFiles();
    for (var path in contextFiles) {
      _tracker._addFile(this, path);
    }
  }

  void _scheduleDependencyFolder(List<String> files, Folder folder) {
    if (_isLibSrcPath(folder.path)) return;
    try {
      for (var resource in folder.getChildren()) {
        _scheduleDependencyResource(files, resource);
      }
    } on FileSystemException catch (_) {}
  }

  void _scheduleDependencyResource(List<String> files, Resource resource) {
    if (resource is File) {
      files.add(resource.path);
      _tracker._addFile(this, resource.path);
    } else if (resource is Folder) {
      _scheduleDependencyFolder(files, resource);
    }
  }

  /// Traverse the folders of this context, and use `pubspec.yaml` files
  /// to set dependencies for containing folders.
  void _setPubspecDependencies() {
    var pathContext = _tracker._resourceProvider.pathContext;
    var locationToPathList = <String, List<String>>{};

    void visitFolder(Folder folder) {
      var pubspecFile = folder.getChildAssumingFile('pubspec.yaml');
      if (pubspecFile.exists) {
        var dependencies = _parsePubspecDependencies(pubspecFile);
        var libPaths = _resolvePackageNamesToLibPaths(dependencies.lib);
        var devPaths = _resolvePackageNamesToLibPaths(dependencies.dev);

        var packagePath = folder.path;
        locationToPathList[packagePath] = <String>[]
          ..addAll(libPaths)
          ..addAll(devPaths);

        var libPath = pathContext.join(packagePath, 'lib');
        locationToPathList[libPath] = libPaths;
      }

      try {
        for (var resource in folder.getChildren()) {
          if (resource is Folder) {
            visitFolder(resource);
          }
        }
      } on FileSystemException {}
    }

    visitFolder(_analysisContext.contextRoot.root);
    setDependencies(locationToPathList);
  }

  static _PubspecDependencies _parsePubspecDependencies(File pubspecFile) {
    var dependencies = <String>[];
    var devDependencies = <String>[];
    try {
      var fileContent = pubspecFile.readAsStringSync();
      var document = loadYamlDocument(fileContent);
      var contents = document.contents;
      if (contents is YamlMap) {
        var dependenciesNode = contents.nodes['dependencies'];
        if (dependenciesNode is YamlMap) {
          dependencies = dependenciesNode.keys.whereType<String>().toList();
        }

        var devDependenciesNode = contents.nodes['dev_dependencies'];
        if (devDependenciesNode is YamlMap) {
          devDependencies =
              devDependenciesNode.keys.whereType<String>().toList();
        }
      }
    } catch (e) {}
    return _PubspecDependencies(dependencies, devDependencies);
  }
}

/// Tracker for top-level declarations across multiple analysis contexts
/// and their dependencies.
class DeclarationsTracker {
  final ByteStore _byteStore;
  final ResourceProvider _resourceProvider;

  final Map<AnalysisContext, DeclarationsContext> _contexts = {};
  final Map<String, _File> _pathToFile = {};
  final Map<Uri, _File> _uriToFile = {};

  final _changesController = _StreamController<LibraryChange>();

  /// The list of files scheduled for processing.  It may include parts and
  /// libraries, but parts are ignored when we detect them.
  final List<_ScheduledFile> _scheduledFiles = [];

  DeclarationsTracker(this._byteStore, this._resourceProvider);

  /// The stream of changes to the set of libraries used by the added contexts.
  Stream<LibraryChange> get changes => _changesController.stream;

  /// Return `true` if there is scheduled work to do, as a result of adding
  /// new contexts, or changes to files.
  bool get hasWork => _scheduledFiles.isNotEmpty;

  /// Add the [analysisContext], so that its libraries are reported via the
  /// [changes] stream, and return the [DeclarationsContext] that can be used
  /// to set additional dependencies and request libraries available to this
  /// context.
  DeclarationsContext addContext(AnalysisContext analysisContext) {
    if (_contexts.containsKey(analysisContext)) {
      throw StateError('The analysis context has already been added.');
    }

    var declarationsContext = DeclarationsContext(this, analysisContext);
    _contexts[analysisContext] = declarationsContext;

    declarationsContext._scheduleContextFiles();
    declarationsContext._setPubspecDependencies();
    return declarationsContext;
  }

  /// The file with the given [path] was changed - updated or added.
  ///
  /// The [path] must be absolute and normalized.
  ///
  /// Usually causes [hasWork] to return `true`, so that [doWork] should
  /// be invoked to send updates to [changes] that reflect changes to the
  /// library of the file, and other libraries that export it.
  void changeFile(String path) {
    // TODO(scheglov) implement
  }

  /// Do a single piece of work.
  ///
  /// The client should call this method until [hasWork] returns `false`.
  /// This would mean that all previous changes have been processed, and
  /// updates scheduled to be delivered via the [changes] stream.
  void doWork() {
    if (_scheduledFiles.isEmpty) return;

    var scheduledFile = _scheduledFiles.removeLast();
    var file = _getFileByPath(scheduledFile.context, scheduledFile.path);

    if (!file.isLibrary) return;

    if (file.exportedDeclarations == null) {
      new _LibraryWalker().walkLibrary(file);
      assert(file.exportedDeclarations != null);
    }

    var library = Library._(
      file.id,
      file.path,
      file.uri,
      file.exportedDeclarations,
    );
    _changesController.add(
      LibraryChange._([library], []),
    );
  }

  /// The [analysisContext] is being disposed, it does not need declarations.
  void removeContext(AnalysisContext analysisContext) {
    _contexts.remove(analysisContext);

    _scheduledFiles.removeWhere((f) {
      return f.context._analysisContext == analysisContext;
    });
  }

  /// The file with the given [path] was removed.
  ///
  /// The [path] must be absolute and normalized.
  ///
  /// Usually causes [hasWork] to return `true`, so that [doWork] should
  /// be invoked to send updates to [changes] that reflect removing of the
  /// file, its defining library, other libraries that export it.
  void removeFile(String path) {
    // TODO(scheglov) implement
  }

  void _addFile(DeclarationsContext context, String path) {
    if (path.endsWith('.dart')) {
      _scheduledFiles.add(_ScheduledFile(context, path));
    }
  }

  _File _getFileByPath(DeclarationsContext context, String path) {
    var file = _pathToFile[path];
    if (file == null) {
      var uri = context._restoreUri(path);
      if (uri != null) {
        file = _File(this, path, uri);
        _pathToFile[path] = file;
        _uriToFile[uri] = file;
        file.refresh(context);
      }
    }
    return file;
  }

  _File _getFileByUri(DeclarationsContext context, Uri uri) {
    var file = _uriToFile[uri];
    if (file == null) {
      var path = context._resolveUri(uri);
      if (path != null) {
        file = _File(this, path, uri);
        _pathToFile[path] = file;
        _uriToFile[uri] = file;
        file.refresh(context);
      }
    }
    return file;
  }
}

/// A library with declarations.
class Library {
  /// The unique identifier of a library with the given [path].
  final int id;

  /// The path to the file that defines this library.
  final String path;

  /// The URI of the library.
  final Uri uri;

  /// All public declaration that the library declares or (re)exports.
  final List<Declaration> declarations;

  Library._(this.id, this.path, this.uri, this.declarations);
}

/// A change to the set of libraries and their declarations.
class LibraryChange {
  /// The list of new or changed libraries.
  final List<Library> changed;

  /// The list of identifier of libraries that are removed, either because
  /// the corresponding files were removed, or because none of the contexts
  /// has these libraries as dependencies, so that they cannot be used anymore.
  final List<int> removed;

  LibraryChange._(this.changed, this.removed);
}

class _Export {
  final Uri uri;
  final List<_ExportCombinator> combinators;

  _File file;

  _Export(this.uri, this.combinators);

  Iterable<Declaration> filter(List<Declaration> declarations) {
    return declarations.where((d) {
      for (var combinator in combinators) {
        if (combinator.shows.isNotEmpty) {
          if (!combinator.shows.contains(d.name)) return false;
        }
        if (combinator.hides.isNotEmpty) {
          if (combinator.hides.contains(d.name)) return false;
        }
      }
      return true;
    });
  }
}

class _ExportCombinator {
  final List<String> shows;
  final List<String> hides;

  _ExportCombinator(this.shows, this.hides);
}

class _File {
  /// The version of data format, should be incremented on every format change.
  static const int DATA_VERSION = 1;

  /// The next value for [id].
  static int _nextId = 0;

  final DeclarationsTracker tracker;

  final int id = _nextId++;
  final String path;
  final Uri uri;

  bool isLibrary = false;
  List<_Export> exports = [];
  List<_Part> parts = [];

  List<Declaration> fileDeclarations = [];
  List<Declaration> libraryDeclarations = [];
  List<Declaration> exportedDeclarations;

  _File(this.tracker, this.path, this.uri);

  void refresh(DeclarationsContext context) {
    var resource = tracker._resourceProvider.getFile(path);

    int modificationStamp;
    try {
      modificationStamp = resource.modificationStamp;
    } catch (e) {
      modificationStamp = -1;
    }

    // When a file changes, its modification stamp changes.
    String pathKey;
    {
      var pathKeyBuilder = ApiSignature();
      pathKeyBuilder.addInt(DATA_VERSION);
      pathKeyBuilder.addString(path);
      pathKeyBuilder.addInt(modificationStamp);
      pathKey = pathKeyBuilder.toHex() + '.declarations_content';
    }

    // With Bazel multiple workspaces might be copies of the same workspace,
    // and have files with the same content, but with different paths.
    // So, we use the content hash to reuse their declarations without parsing.
    String content;
    String contentKey;
    {
      var contentHashBytes = tracker._byteStore.get(pathKey);
      if (contentHashBytes == null) {
        content = _readContent(resource);

        var contentHashBuilder = ApiSignature();
        contentHashBuilder.addInt(DATA_VERSION);
        contentHashBuilder.addString(content);
        contentHashBytes = contentHashBuilder.toByteList();

        tracker._byteStore.put(pathKey, contentHashBytes);
      }

      contentKey = hex.encode(contentHashBytes) + '.declarations';
    }

    var bytes = tracker._byteStore.get(contentKey);
    if (bytes == null) {
      content ??= _readContent(resource);

      CompilationUnit unit = _parse(content);
      _buildFileDeclarations(unit);
      _putFileDeclarationsToByteStore(contentKey);
    } else {
      _readFileDeclarationsFromBytes(bytes);
    }

    // Resolve exports and parts.
    for (var export in exports) {
      export.file = _fileForRelativeUri(context, export.uri);
    }
    for (var part in parts) {
      part.file = _fileForRelativeUri(context, part.uri);
    }
    exports.removeWhere((e) => e.file == null);
    parts.removeWhere((e) => e.file == null);

    // Compute library declarations.
    if (isLibrary) {
      libraryDeclarations = <Declaration>[];
      libraryDeclarations.addAll(fileDeclarations);
      for (var part in parts) {
        libraryDeclarations.addAll(part.file.fileDeclarations);
      }
    }
  }

  void _buildFileDeclarations(CompilationUnit unit) {
    isLibrary = true;
    exports = [];
    fileDeclarations = [];
    libraryDeclarations = null;
    exportedDeclarations = null;

    void addDeclaration(Identifier name, DeclarationKind kind) {
      if (!Identifier.isPrivateName(name.name)) {
        fileDeclarations.add(Declaration(name.name, kind));
      }
    }

    for (var astDirective in unit.directives) {
      if (astDirective is PartOfDirective) {
        isLibrary = false;
      } else if (astDirective is ExportDirective) {
        var uri = _uriFromAst(astDirective.uri);
        if (uri == null) continue;

        var combinators = <_ExportCombinator>[];
        for (var astCombinator in astDirective.combinators) {
          if (astCombinator is ShowCombinator) {
            combinators.add(_ExportCombinator(
              astCombinator.shownNames.map((id) => id.name).toList(),
              const [],
            ));
          } else if (astCombinator is HideCombinator) {
            combinators.add(_ExportCombinator(
              const [],
              astCombinator.hiddenNames.map((id) => id.name).toList(),
            ));
          }
        }

        exports.add(_Export(uri, combinators));
      } else if (astDirective is PartDirective) {
        var uri = _uriFromAst(astDirective.uri);
        if (uri == null) continue;

        parts.add(_Part(uri));
      }
    }

    for (var node in unit.declarations) {
      if (node is ClassDeclaration) {
        addDeclaration(node.name, DeclarationKind.CLASS);
      } else if (node is ClassTypeAlias) {
        addDeclaration(node.name, DeclarationKind.CLASS_TYPE_ALIAS);
      } else if (node is EnumDeclaration) {
        addDeclaration(node.name, DeclarationKind.ENUM);
      } else if (node is FunctionDeclaration) {
        addDeclaration(node.name, DeclarationKind.FUNCTION);
      } else if (node is GenericTypeAlias) {
        addDeclaration(node.name, DeclarationKind.FUNCTION_TYPE_ALIAS);
      } else if (node is MixinDeclaration) {
        addDeclaration(node.name, DeclarationKind.MIXIN);
      } else if (node is TopLevelVariableDeclaration) {
        for (var variable in node.variables.variables) {
          addDeclaration(variable.name, DeclarationKind.VARIABLE);
        }
      }
    }
  }

  /// Return the [_File] for the given [relative] URI, maybe `null`.
  _File _fileForRelativeUri(DeclarationsContext context, Uri relative) {
    var absoluteUri = uri.resolveUri(relative);
    return tracker._getFileByUri(context, absoluteUri);
  }

  void _putFileDeclarationsToByteStore(String contentKey) {
    var builder = idl.AvailableFileBuilder(
      isLibrary: isLibrary,
      exports: exports.map((e) {
        return idl.AvailableFileExportBuilder(
          uri: e.uri.toString(),
          combinators: e.combinators.map((c) {
            return idl.AvailableFileExportCombinatorBuilder(
                shows: c.shows, hides: c.hides);
          }).toList(),
        );
      }).toList(),
      parts: parts.map((p) => p.uri.toString()).toList(),
      declarations: fileDeclarations.map((d) {
        var idlKind = _kindToIdl(d.kind);
        return idl.AvailableDeclarationBuilder(kind: idlKind, name: d.name);
      }).toList(),
    );
    var bytes = builder.toBuffer();
    tracker._byteStore.put(contentKey, bytes);
  }

  void _readFileDeclarationsFromBytes(List<int> bytes) {
    var idlFile = idl.AvailableFile.fromBuffer(bytes);

    isLibrary = idlFile.isLibrary;

    exports = idlFile.exports.map((e) {
      return _Export(
        Uri.parse(e.uri),
        e.combinators.map((c) {
          return _ExportCombinator(c.shows.toList(), c.hides.toList());
        }).toList(),
      );
    }).toList();

    parts = idlFile.parts.map((e) {
      var uri = Uri.parse(e);
      return _Part(uri);
    }).toList();

    fileDeclarations = idlFile.declarations.map((e) {
      var kind = _kindFromIdl(e.kind);
      return Declaration(e.name, kind);
    }).toList();
  }

  static DeclarationKind _kindFromIdl(idl.AvailableDeclarationKind kind) {
    switch (kind) {
      case idl.AvailableDeclarationKind.CLASS:
        return DeclarationKind.CLASS;
      case idl.AvailableDeclarationKind.CLASS_TYPE_ALIAS:
        return DeclarationKind.CLASS_TYPE_ALIAS;
      case idl.AvailableDeclarationKind.ENUM:
        return DeclarationKind.ENUM;
      case idl.AvailableDeclarationKind.FUNCTION:
        return DeclarationKind.FUNCTION;
      case idl.AvailableDeclarationKind.FUNCTION_TYPE_ALIAS:
        return DeclarationKind.FUNCTION_TYPE_ALIAS;
      case idl.AvailableDeclarationKind.MIXIN:
        return DeclarationKind.MIXIN;
      case idl.AvailableDeclarationKind.VARIABLE:
        return DeclarationKind.VARIABLE;
      default:
        throw StateError('Unknown kind: $kind');
    }
  }

  static idl.AvailableDeclarationKind _kindToIdl(DeclarationKind kind) {
    switch (kind) {
      case DeclarationKind.CLASS:
        return idl.AvailableDeclarationKind.CLASS;
      case DeclarationKind.CLASS_TYPE_ALIAS:
        return idl.AvailableDeclarationKind.CLASS_TYPE_ALIAS;
      case DeclarationKind.ENUM:
        return idl.AvailableDeclarationKind.ENUM;
      case DeclarationKind.FUNCTION:
        return idl.AvailableDeclarationKind.FUNCTION;
      case DeclarationKind.FUNCTION_TYPE_ALIAS:
        return idl.AvailableDeclarationKind.FUNCTION_TYPE_ALIAS;
      case DeclarationKind.MIXIN:
        return idl.AvailableDeclarationKind.MIXIN;
      case DeclarationKind.VARIABLE:
        return idl.AvailableDeclarationKind.VARIABLE;
      default:
        throw StateError('Unknown kind: $kind');
    }
  }

  static CompilationUnit _parse(String content) {
    var errorListener = AnalysisErrorListener.NULL_LISTENER;
    var source = StringSource(content, '');

    var reader = new CharSequenceReader(content);
    var scanner = new Scanner(null, reader, errorListener);
    var token = scanner.tokenize();

    var parser = new Parser(source, errorListener, useFasta: true);
    return parser.parseCompilationUnit(token);
  }

  static String _readContent(File resource) {
    try {
      return resource.readAsStringSync();
    } catch (e) {
      return '';
    }
  }

  static Uri _uriFromAst(StringLiteral astUri) {
    if (astUri is SimpleStringLiteral) {
      var uriStr = astUri.value;
      try {
        return Uri.parse(uriStr);
      } catch (_) {}
    }
    return null;
  }
}

class _LibraryNode extends graph.Node<_LibraryNode> {
  final _LibraryWalker walker;
  final _File file;

  _LibraryNode(this.walker, this.file);

  @override
  bool get isEvaluated => file.exportedDeclarations != null;

  @override
  List<_LibraryNode> computeDependencies() {
    return file.exports.map((e) => e.file).map(walker.getNode).toList();
  }
}

class _LibraryWalker extends graph.DependencyWalker<_LibraryNode> {
  final Map<_File, _LibraryNode> nodesOfFiles = {};

  @override
  void evaluate(_LibraryNode node) {
    var file = node.file;
    var resultSet = _newDeclarationSet();
    resultSet.addAll(file.libraryDeclarations);

    for (var export in file.exports) {
      var exportedDeclarations = export.file.exportedDeclarations;
      resultSet.addAll(export.filter(exportedDeclarations));
    }

    file.exportedDeclarations = resultSet.toList();
  }

  @override
  void evaluateScc(List<_LibraryNode> scc) {
    for (var node in scc) {
      var visitedFiles = Set<_File>();

      List<Declaration> computeExported(_File file) {
        if (file.exportedDeclarations != null) {
          return file.exportedDeclarations;
        }

        if (!visitedFiles.add(file)) {
          return const [];
        }

        var resultSet = _newDeclarationSet();
        resultSet.addAll(file.libraryDeclarations);

        for (var export in file.exports) {
          var exportedDeclarations = computeExported(export.file);
          resultSet.addAll(export.filter(exportedDeclarations));
        }

        return resultSet.toList();
      }

      var file = node.file;
      file.exportedDeclarations = computeExported(file);
    }
  }

  _LibraryNode getNode(_File file) {
    return nodesOfFiles.putIfAbsent(file, () => new _LibraryNode(this, file));
  }

  void walkLibrary(_File file) {
    var node = getNode(file);
    walk(node);
  }

  static Set<Declaration> _newDeclarationSet() {
    return HashSet<Declaration>(
      hashCode: (e) => e.name.hashCode,
      equals: (a, b) => a.name == b.name,
    );
  }
}

class _Part {
  final Uri uri;

  _File file;

  _Part(this.uri);
}

/// Normal and dev dependencies specified in a `pubspec.yaml` file.
class _PubspecDependencies {
  final List<String> lib;
  final List<String> dev;

  _PubspecDependencies(this.lib, this.dev);
}

class _ScheduledFile {
  final DeclarationsContext context;
  final String path;

  _ScheduledFile(this.context, this.path);
}

/// Wrapper for a [StreamController] and its unique [Stream] instance.
class _StreamController<T> {
  final StreamController<T> controller = StreamController<T>();
  Stream<T> stream;

  _StreamController() {
    stream = controller.stream;
  }

  void add(T event) {
    controller.add(event);
  }
}
