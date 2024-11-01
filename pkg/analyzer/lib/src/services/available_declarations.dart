// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart' as ast;
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/dartdoc/dartdoc_directive_info.dart';
import 'package:analyzer/src/summary/api_signature.dart';
import 'package:analyzer/src/summary/format.dart' as idl;
import 'package:analyzer/src/summary/idl.dart' as idl;
import 'package:analyzer/src/util/comment.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer/src/utilities/uri_cache.dart';
import 'package:convert/convert.dart';
import 'package:yaml/yaml.dart';

/// The context in which completions happens, so declarations are collected.
class DeclarationsContext {
  final DeclarationsTracker _tracker;

  /// The analysis context for this context.  Declarations from all files in
  /// the root are included into completion, even in 'lib/src' folders.
  final AnalysisContext _analysisContext;

  /// Packages in the analysis context.
  ///
  /// Packages are sorted so that inner packages are before outer.
  final List<_Package> _packages = [];

  /// The set of paths of all files inside the context.
  final Set<String> _contextPathSet = {};

  /// The list of paths of all SDK libraries.
  final List<String> _sdkLibraryPathList = [];

  /// The combined information about all of the dartdoc directives in this
  /// context.
  final DartdocDirectiveInfo _dartdocDirectiveInfo = DartdocDirectiveInfo();

  /// Map of path prefixes to lists of paths of files from dependencies
  /// (both libraries and parts, we don't know at the time when we fill this
  /// map) that libraries with paths starting with these prefixes can access.
  ///
  /// The path prefix keys are sorted so that the longest keys are first.
  final Map<String, List<String>> _pathPrefixToDependencyPathList = {};

  /// The set of paths of already checked known files, some of which were
  /// added to [_knownPathList]. For example we skip non-API files.
  final Set<String> _knownPathSet = <String>{};

  /// The list of paths of files known to this context - from the context
  /// itself, from direct dependencies, from indirect dependencies.
  ///
  /// We include libraries from this list only when actual context dependencies
  /// are not known. Dependencies are always know for Pub packages, but are
  /// currently never known for Blaze packages.
  final List<String> _knownPathList = [];

  DeclarationsContext(this._tracker, this._analysisContext);

  /// Return the combined information about all of the dartdoc directives in
  /// this context.
  DartdocDirectiveInfo get dartdocDirectiveInfo => _dartdocDirectiveInfo;

  AnalysisDriver get _analysisDriver {
    var session = _analysisContext.currentSession as AnalysisSessionImpl;
    // ignore: deprecated_member_use_from_same_package
    return session.getDriver();
  }

  void _addContextFile(String path) {
    _contextPathSet.add(path);
  }

  /// The set of features that are enabled for this file.
  FeatureSet _getFeatureSet(File file) {
    return _analysisContext.getAnalysisOptionsForFile(file).contextFeatures;
  }

  bool _isLibSrcPath(String path) {
    var parts = _tracker._resourceProvider.pathContext.split(path);
    for (var i = 0; i < parts.length - 1; ++i) {
      if (parts[i] == 'lib' && parts[i + 1] == 'src') return true;
    }
    return false;
  }

  List<String> _resolvePackageNamesToLibPaths(List<String> packageNames) {
    return packageNames.map(_resolvePackageNameToLibPath).nonNulls.toList();
  }

  String? _resolvePackageNameToLibPath(String packageName) {
    try {
      var uri = Uri.parse('package:$packageName/ref.dart');

      var path = _resolveUri(uri);
      if (path == null) return null;

      return _tracker._resourceProvider.pathContext.dirname(path);
    } on FormatException {
      return null;
    }
  }

  String? _resolveUri(Uri uri) {
    var uriConverter = _analysisContext.currentSession.uriConverter;
    return uriConverter.uriToPath(uri);
  }

  Uri? _restoreUri(String path) {
    var uriConverter = _analysisContext.currentSession.uriConverter;
    return uriConverter.pathToUri(path);
  }

  /// Schedule all analyzed files and fill [_packages] in a single iteration of
  /// `contextRoot.analyzedFiles`;  use `pubspec.yaml` files to set `Pub`
  /// dependencies.
  void _scheduleContextFilesAndFindPackages() {
    var pathContext = _tracker._resourceProvider.pathContext;
    var pubPathPrefixToPathList = <String, List<String>>{};

    for (var path in _analysisContext.contextRoot.analyzedFiles()) {
      _contextPathSet.add(path);
      _tracker._addFile(this, path);

      if (file_paths.isBlazeBuild(pathContext, path)) {
        var file = _tracker._resourceProvider.getFile(path);
        var packageFolder = file.parent;
        _packages.add(_Package(packageFolder));
      } else if (file_paths.isPubspecYaml(pathContext, path)) {
        var file = _tracker._resourceProvider.getFile(path);
        var dependencies = _parsePubspecDependencies(file);
        var libPaths = _resolvePackageNamesToLibPaths(dependencies.lib);
        var devPaths = _resolvePackageNamesToLibPaths(dependencies.dev);

        var packageFolder = file.parent;
        var packagePath = packageFolder.path;
        pubPathPrefixToPathList[packagePath] = [
          ...libPaths,
          ...devPaths,
        ];

        var libPath = pathContext.join(packagePath, 'lib');
        pubPathPrefixToPathList[libPath] = libPaths;

        _packages.add(_Package(packageFolder));
      }
    }

    _setDependencies(pubPathPrefixToPathList);

    _packages.sort((a, b) {
      var aRoot = a.root.path;
      var bRoot = b.root.path;
      return bRoot.compareTo(aRoot);
    });
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

  void _scheduleKnownFiles() {
    for (var file in _analysisDriver.knownFiles) {
      var path = file.path;
      if (_knownPathSet.add(path)) {
        if (!path.contains(r'/lib/src/') && !path.contains(r'\lib\src\')) {
          _knownPathList.add(path);
          _tracker._addFile(this, path);
        }
      }
    }
  }

  void _scheduleSdkLibraries() {
    var sdk = _analysisDriver.sourceFactory.dartSdk!;
    for (var uriStr in sdk.uris) {
      if (!uriStr.startsWith('dart:_')) {
        var uri = Uri.parse(uriStr);
        var path = _resolveUri(uri);
        if (path != null) {
          _sdkLibraryPathList.add(path);
          _tracker._addFile(this, path);
        }
      }
    }
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
  /// included.  This method is useful for `Blaze` contexts, where dependencies
  /// are specified externally, in form of `BUILD` files.
  ///
  /// New dependencies will replace any previously set dependencies for this
  /// context.
  ///
  /// Every path in the list must be absolute and normalized.
  void _setDependencies(Map<String, List<String>> pathPrefixToPathList) {
    var rootFolder = _analysisContext.contextRoot.root;
    _pathPrefixToDependencyPathList.removeWhere((pathPrefix, _) {
      return rootFolder.isOrContains(pathPrefix);
    });

    var sortedPrefixes = pathPrefixToPathList.keys.toList();
    sortedPrefixes.sort((a, b) {
      return b.compareTo(a);
    });

    for (var pathPrefix in sortedPrefixes) {
      var pathList = pathPrefixToPathList[pathPrefix];
      var files = <String>[];
      for (var path in pathList!) {
        var resource = _tracker._resourceProvider.getResource(path);
        _scheduleDependencyResource(files, resource);
      }
      _pathPrefixToDependencyPathList[pathPrefix] = files;
    }
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
    } catch (_) {}
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

  /// The list of changed file paths.
  final List<String> _changedPaths = [];

  /// The list of files scheduled for processing.  It may include parts and
  /// libraries, but parts are ignored when we detect them.
  final List<_ScheduledFile> _scheduledFiles = [];

  /// The time when known files were last pulled.
  DateTime _whenKnownFilesPulled = DateTime.fromMillisecondsSinceEpoch(0);

  DeclarationsTracker(this._byteStore, this._resourceProvider);

  /// Return `true` if there is scheduled work to do, as a result of adding
  /// new contexts, or changes to files.
  bool get hasWork {
    var now = DateTime.now();
    if (now.difference(_whenKnownFilesPulled).inSeconds > 1) {
      _whenKnownFilesPulled = now;
      _pullKnownFiles();
    }
    return _changedPaths.isNotEmpty || _scheduledFiles.isNotEmpty;
  }

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

    declarationsContext._scheduleContextFilesAndFindPackages();
    declarationsContext._scheduleSdkLibraries();
    return declarationsContext;
  }

  /// The file with the given [path] was changed - added, updated, or removed.
  ///
  /// The [path] must be absolute and normalized.
  ///
  /// Usually causes [hasWork] to return `true`, so that [doWork] should
  /// be invoked to send updates to [changes] that reflect changes to the
  /// library of the file, and other libraries that export it.
  void changeFile(String path) {
    if (!path.endsWith('.dart')) return;

    _changedPaths.add(path);
  }

  /// Discard all contexts and libraries, notify the [changes] stream that
  /// these libraries are removed.
  void discardContexts() {
    _contexts.clear();
    _pathToFile.clear();
    _uriToFile.clear();
    _changedPaths.clear();
    _scheduledFiles.clear();
  }

  /// Do a single piece of work.
  ///
  /// The client should call this method until [hasWork] returns `false`.
  /// This would mean that all previous changes have been processed, and
  /// updates scheduled to be delivered via the [changes] stream.
  void doWork() {
    if (_changedPaths.isNotEmpty) {
      var path = _changedPaths.removeLast();
      _performChangeFile(path);
      return;
    }

    if (_scheduledFiles.isNotEmpty) {
      var scheduledFile = _scheduledFiles.removeLast();
      _getFileByPath(scheduledFile.context, [], scheduledFile.path)!;
    }
  }

  /// Return the context associated with the given [analysisContext], or `null`
  /// if there is none.
  DeclarationsContext? getContext(AnalysisContext analysisContext) {
    return _contexts[analysisContext];
  }

  void _addFile(DeclarationsContext context, String path) {
    if (path.endsWith('.dart')) {
      _scheduledFiles.add(_ScheduledFile(context, path));
    }
  }

  // TODO(scheglov): Remove after fixing
  // https://github.com/dart-lang/sdk/issues/45233
  void _addPathOrUri(List<String> pathOrUriList, String path, Uri uri) {
    pathOrUriList.add('(uri: $uri, path: $path)');

    if (pathOrUriList.length > 200) {
      throw StateError('Suspected cycle. $pathOrUriList');
    }
  }

  DeclarationsContext? _findContextOfPath(String path) {
    // Prefer the context in which the path is analyzed.
    for (var context in _contexts.values) {
      if (context._analysisContext.contextRoot.isAnalyzed(path)) {
        context._addContextFile(path);
        return context;
      }
    }

    // The path must have the URI with one of the supported URI schemes.
    for (var context in _contexts.values) {
      var uri = context._restoreUri(path);
      if (uri != null) {
        if (uri.isScheme('dart') || uri.isScheme('package')) {
          return context;
        }
      }
    }

    return null;
  }

  _File? _getFileByPath(
      DeclarationsContext context, List<String> partOrUriList, String path) {
    var file = _pathToFile[path];
    if (file == null) {
      var uri = context._restoreUri(path);
      if (uri != null) {
        file = _File(this, path, uri);
        _pathToFile[path] = file;
        _uriToFile[uri] = file;
        _addPathOrUri(partOrUriList, path, uri);
        file.refresh(context, partOrUriList);
        partOrUriList.removeLast();
      }
    }
    return file;
  }

  _File? _getFileByUri(
      DeclarationsContext context, List<String> partOrUriList, Uri uri) {
    var file = _uriToFile[uri];
    if (file != null) {
      return file;
    }

    var path = context._resolveUri(uri);
    if (path == null) {
      return null;
    }

    try {
      path = _resolveLinks(path);
    } on FileSystemException {
      // Not existing file, or the link target.
    }

    file = _pathToFile[path];
    if (file != null) {
      return file;
    }

    file = _File(this, path!, uri);
    _pathToFile[path] = file;
    _uriToFile[uri] = file;

    _addPathOrUri(partOrUriList, path, uri);
    file.refresh(context, partOrUriList);
    partOrUriList.removeLast();
    return file;
  }

  void _performChangeFile(String path) {
    var containingContext = _findContextOfPath(path);
    if (containingContext == null) return;

    var file = _getFileByPath(containingContext, [], path);
    if (file == null) return;

    file.refresh(containingContext, []);
  }

  /// Pull known files into [DeclarationsContext]s.
  ///
  /// This is a temporary support for Blaze repositories, because IDEA
  /// does not yet give us dependencies for them.
  void _pullKnownFiles() {
    for (var context in _contexts.values) {
      context._scheduleKnownFiles();
    }
  }

  /// Return the [path] with resolved file system links.
  String _resolveLinks(String path) {
    var resource = _resourceProvider.getFile(path);
    resource = resource.resolveSymbolicLinksSync() as File;
    return resource.path;
  }
}

class _Export {
  final Uri uri;
  _File? file;

  _Export(this.uri);
}

class _File {
  /// The version of data format, should be incremented on every format change.
  static const int DATA_VERSION = 18;

  final DeclarationsTracker tracker;

  final String path;
  final Uri uri;

  List<_Export> exports = [];
  List<_Part> parts = [];

  List<String> templateNames = [];
  List<String> templateValues = [];

  _File(this.tracker, this.path, this.uri);

  void refresh(DeclarationsContext context, List<String> partOrUriList) {
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
      pathKey = '${pathKeyBuilder.toHex()}.declarations_content';
    }

    // With Blaze multiple workspaces might be copies of the same workspace,
    // and have files with the same content, but with different paths.
    // So, we use the content hash to reuse their declarations without parsing.
    String? content;
    String? contentKey;
    {
      var contentHashBytes = tracker._byteStore.get(pathKey);
      if (contentHashBytes == null) {
        content = _readContent(resource);

        var contentHashBuilder = ApiSignature();
        contentHashBuilder.addInt(DATA_VERSION);
        contentHashBuilder.addString(content);
        contentHashBytes = contentHashBuilder.toByteList();

        tracker._byteStore.putGet(pathKey, contentHashBytes);
      }

      contentKey = '${hex.encode(contentHashBytes)}.declarations';
    }

    var bytes = tracker._byteStore.get(contentKey);
    if (bytes == null) {
      content ??= _readContent(resource);

      ast.CompilationUnit unit =
          _parse(context._getFeatureSet(resource), content);
      _buildFileDeclarations(unit);
      _extractDartdocInfoFromUnit(unit);
      _putFileDeclarationsToByteStore(contentKey);
      context.dartdocDirectiveInfo
          .addTemplateNamesAndValues(templateNames, templateValues);
    } else {
      _readFileDeclarationsFromBytes(bytes);
      context.dartdocDirectiveInfo
          .addTemplateNamesAndValues(templateNames, templateValues);
    }

    // Resolve exports and parts.
    for (var export in exports) {
      export.file = _fileForRelativeUri(context, partOrUriList, export.uri);
    }
    for (var part in parts) {
      part.file = _fileForRelativeUri(context, partOrUriList, part.uri);
    }
    exports.removeWhere((e) => e.file == null);
    parts.removeWhere((e) => e.file == null);
  }

  void _buildFileDeclarations(ast.CompilationUnit unit) {
    exports = [];
    templateNames = [];
    templateValues = [];

    for (var astDirective in unit.directives) {
      if (astDirective is ast.ExportDirective) {
        var uri = _uriFromAst(astDirective.uri);
        if (uri == null) continue;

        exports.add(_Export(uri));
      } else if (astDirective is ast.PartDirective) {
        var uri = _uriFromAst(astDirective.uri);
        if (uri == null) continue;

        parts.add(_Part(uri));
      }
    }
  }

  void _extractDartdocInfoFromUnit(ast.CompilationUnit unit) {
    DartdocDirectiveInfo info = DartdocDirectiveInfo();
    for (ast.Directive directive in unit.directives) {
      var comment = directive.documentationComment;
      info.extractTemplate(getCommentNodeRawText(comment));
    }
    for (ast.CompilationUnitMember declaration in unit.declarations) {
      var comment = declaration.documentationComment;
      info.extractTemplate(getCommentNodeRawText(comment));

      var members = switch (declaration) {
        ast.ClassDeclaration() => declaration.members,
        ast.EnumDeclaration() => [
            ...declaration.members,
            ...declaration.constants
          ],
        ast.MixinDeclaration() => declaration.members,
        ast.ExtensionDeclaration() => declaration.members,
        ast.ExtensionTypeDeclaration() => declaration.members,
        _ => null,
      };

      if (members != null) {
        for (var member in members) {
          var comment = member.documentationComment;
          info.extractTemplate(getCommentNodeRawText(comment));
        }
      }
    }

    templateNames = [];
    templateValues = [];

    Map<String, String> templateMap = info.templateMap;
    for (var entry in templateMap.entries) {
      templateNames.add(entry.key);
      templateValues.add(entry.value);
    }
  }

  /// Return the [_File] for the given [relative] URI, maybe `null`.
  _File? _fileForRelativeUri(
    DeclarationsContext context,
    List<String> partOrUriList,
    Uri relative,
  ) {
    var absoluteUri = uriCache.resolveRelative(uri, relative);
    return tracker._getFileByUri(context, partOrUriList, absoluteUri);
  }

  void _putFileDeclarationsToByteStore(String contentKey) {
    var builder = idl.AvailableFileBuilder(
      exports: exports.map((p) => p.uri.toString()).toList(),
      parts: parts.map((p) => p.uri.toString()).toList(),
      directiveInfo: idl.DirectiveInfoBuilder(
          templateNames: templateNames, templateValues: templateValues),
    );
    var bytes = builder.toBuffer();
    tracker._byteStore.putGet(contentKey, bytes);
  }

  void _readFileDeclarationsFromBytes(List<int> bytes) {
    var idlFile = idl.AvailableFile.fromBuffer(bytes);

    exports = idlFile.parts.map((e) {
      var uri = Uri.parse(e);
      return _Export(uri);
    }).toList();

    parts = idlFile.parts.map((e) {
      var uri = Uri.parse(e);
      return _Part(uri);
    }).toList();

    templateNames = idlFile.directiveInfo!.templateNames.toList();
    templateValues = idlFile.directiveInfo!.templateValues.toList();
  }

  static ast.CompilationUnit _parse(FeatureSet featureSet, String content) {
    try {
      return parseString(
        content: content,
        featureSet: featureSet,
        throwIfDiagnostics: false,
      ).unit;
    } catch (e) {
      return parseString(
        content: '',
        featureSet: featureSet,
        throwIfDiagnostics: false,
      ).unit;
    }
  }

  static String _readContent(File resource) {
    try {
      return resource.readAsStringSync();
    } catch (e) {
      return '';
    }
  }

  static Uri? _uriFromAst(ast.StringLiteral astUri) {
    if (astUri is ast.SimpleStringLiteral) {
      var uriStr = astUri.value.trim();
      if (uriStr.isEmpty) return null;
      try {
        return Uri.parse(uriStr);
      } catch (_) {}
    }
    return null;
  }
}

/// Information about a package: `Pub` or `Blaze`.
class _Package {
  final Folder root;
  final Folder lib;

  _Package(this.root) : lib = root.getChildAssumingFolder('lib');

  /// Return `true` if the [path] is anywhere in the [root] of the package.
  ///
  /// Note, that this method does not check if the are nested packages, that
  /// might actually contain the [path].
  bool contains(String path) {
    return root.contains(path);
  }

  /// Return `true` if the [path] is in the `lib` folder of this package.
  bool containsInLib(String path) {
    return lib.contains(path);
  }

  /// Return the direct child folder of the root, that contains the [path].
  ///
  /// So, we can know if the [path] is in `lib/`, or `test/`, or `bin/`.
  Folder? folderInRootContaining(String path) {
    try {
      var children = root.getChildren();
      for (var folder in children) {
        if (folder is Folder && folder.contains(path)) {
          return folder;
        }
      }
    } on FileSystemException {
      // ignored
    }
    return null;
  }
}

class _Part {
  final Uri uri;

  _File? file;

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
