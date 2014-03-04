// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library code_transformer.src.resolver_impl;

import 'dart:async';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/sdk.dart' show DartSdk;
import 'package:analyzer/src/generated/sdk_io.dart' show DirectoryBasedDartSdk;
import 'package:analyzer/src/generated/source.dart';
import 'package:barback/barback.dart';
import 'package:path/path.dart' as native_path;
import 'package:source_maps/refactor.dart';
import 'package:source_maps/span.dart' show SourceFile, Span;

import 'resolver.dart';

// We should always be using url paths here since it's always Dart/pub code.
final path = native_path.url;

/// Resolves and updates an AST based on Barback-based assets.
///
/// This also provides a handful of useful APIs for traversing and working
/// with the resolved AST.
class ResolverImpl implements Resolver {
  /// Cache of all asset sources currently referenced.
  final Map<AssetId, _AssetBasedSource> sources =
      <AssetId, _AssetBasedSource>{};

  /// The Dart entry point file where parsing begins.
  final AssetId entryPoint;

  final AnalysisContext _context =
      AnalysisEngine.instance.createAnalysisContext();

  /// Transform for which this is currently updating, or null when not updating.
  Transform _currentTransform;

  /// The currently resolved library, or null if unresolved.
  LibraryElement _entryLibrary;

  /// Future indicating when this resolver is done in the current phase.
  Future _lastPhaseComplete = new Future.value();

  /// Completer for wrapping up the current phase.
  Completer _currentPhaseComplete;

  /// Handler for all Dart SDK (dart:) sources.
  DirectoryBasedDartSdk _dartSdk;

  /// Creates a resolver that will resolve the Dart code starting at
  /// [entryPoint].
  ///
  /// [sdkDir] is the root directory of the Dart SDK, for resolving dart:
  /// imports.
  ResolverImpl(this.entryPoint, String sdkDir, {AnalysisOptions options}) {
    if (options == null) {
      options = new AnalysisOptionsImpl()
        ..cacheSize = 256 // # of sources to cache ASTs for.
        ..preserveComments = false
        ..analyzeFunctionBodies = true;
    }
    _context.analysisOptions = options;

    _dartSdk = new _DirectoryBasedDartSdkProxy(new JavaFile(sdkDir));
    _dartSdk.context.analysisOptions = options;

    _context.sourceFactory = new SourceFactory([
        new DartUriResolverProxy(_dartSdk),
        new _AssetUriResolver(this)]);
  }

  LibraryElement get entryLibrary => _entryLibrary;

  Future<Resolver> resolve(Transform transform) {
    // Can only have one resolve in progress at a time, so chain the current
    // resolution to be after the last one.
    var phaseComplete = new Completer();
    var future = _lastPhaseComplete.then((_) {
      _currentPhaseComplete = phaseComplete;

      return _performResolve(transform);
    }).then((_) => this);
    // Advance the lastPhaseComplete to be done when this phase is all done.
    _lastPhaseComplete = phaseComplete.future;
    return future;
  }

  void release() {
    if (_currentPhaseComplete == null) {
      throw new StateError('Releasing without current lock.');
    }
    _currentPhaseComplete.complete(null);
    _currentPhaseComplete = null;

    // Clear out the entry lib since it should not be referenced after release.
    _entryLibrary = null;
  }

  Future _performResolve(Transform transform) {
    if (_currentTransform != null) {
      throw new StateError('Cannot be accessed by concurrent transforms');
    }
    _currentTransform = transform;

    // Basic approach is to start at the first file, update it's contents
    // and see if it changed, then walk all files accessed by it.
    var visited = new Set<AssetId>();
    var visiting = new FutureGroup();

    void processAsset(AssetId assetId) {
      visited.add(assetId);

      visiting.add(transform.readInputAsString(assetId).then((contents) {
        var source = sources[assetId];
        if (source == null) {
          source = new _AssetBasedSource(assetId, this);
          sources[assetId] = source;
        }
        source.updateContents(contents);

        source.dependentAssets
            .where((id) => !visited.contains(id))
            .forEach(processAsset);

      }, onError: (e) {
        _context.applyChanges(new ChangeSet()..removed(sources[assetId]));
        sources.remove(assetId);
      }));
    }
    processAsset(entryPoint);

    // Once we have all asset sources updated with the new contents then
    // resolve everything.
    return visiting.future.then((_) {
      var changeSet = new ChangeSet();
      var unreachableAssets = new Set.from(sources.keys).difference(visited);
      for (var unreachable in unreachableAssets) {
        changeSet.removed(sources[unreachable]);
        sources.remove(unreachable);
      }

      // Update the analyzer context with the latest sources
      _context.applyChanges(changeSet);
      // Resolve the AST
      _entryLibrary = _context.computeLibraryElement(sources[entryPoint]);
      _currentTransform = null;
    });
  }

  Iterable<LibraryElement> get libraries => entryLibrary.visibleLibraries;

  LibraryElement getLibraryByName(String libraryName) =>
      libraries.firstWhere((l) => l.name == libraryName, orElse: () => null);

  LibraryElement getLibraryByUri(Uri uri) =>
      libraries.firstWhere((l) => getImportUri(l) == uri, orElse: () => null);

  ClassElement getType(String typeName) {
    var dotIndex = typeName.lastIndexOf('.');
    var libraryName = dotIndex == -1 ? '' : typeName.substring(0, dotIndex);

    var className = dotIndex == -1 ?
        typeName : typeName.substring(dotIndex + 1);

    for (var lib in libraries.where((l) => l.name == libraryName)) {
      var type = lib.getType(className);
      if (type != null) return type;
    }
    return null;
  }

  Element getLibraryVariable(String variableName) {
    var dotIndex = variableName.lastIndexOf('.');
    var libraryName = dotIndex == -1 ? '' : variableName.substring(0, dotIndex);

    var name = dotIndex == -1 ?
        variableName : variableName.substring(dotIndex + 1);

    return libraries.where((lib) => lib.name == libraryName)
        .expand((lib) => lib.units)
        .expand((unit) => unit.topLevelVariables)
        .firstWhere((variable) => variable.name == name,
            orElse: () => null);
  }

  Element getLibraryFunction(String fnName) {
    var dotIndex = fnName.lastIndexOf('.');
    var libraryName = dotIndex == -1 ? '' : fnName.substring(0, dotIndex);

    var name = dotIndex == -1 ?
        fnName : fnName.substring(dotIndex + 1);

    return libraries.where((lib) => lib.name == libraryName)
        .expand((lib) => lib.units)
        .expand((unit) => unit.functions)
        .firstWhere((fn) => fn.name == name,
            orElse: () => null);
  }

  Uri getImportUri(LibraryElement lib, {AssetId from}) =>
      _getSourceUri(lib, from: from);


  /// Similar to getImportUri but will get the part URI for parts rather than
  /// the library URI.
  Uri _getSourceUri(Element element, {AssetId from}) {
    var source = element.source;
    if (source is _AssetBasedSource) {
      return source.getSourceUri(from);
    } else if (source is _DartSourceProxy) {
      return source.uri;
    }
    // Should not be able to encounter any other source types.
    throw new StateError('Unable to resolve URI for ${source.runtimeType}');
  }

  AssetId getSourceAssetId(Element element) {
    var source = element.source;
    if (source is _AssetBasedSource) return source.assetId;
    return null;
  }

  Span getSourceSpan(Element element) {
    var sourceFile = _getSourceFile(element);
    if (sourceFile == null) return null;
    return sourceFile.span(element.node.offset, element.node.end);
  }

  TextEditTransaction createTextEditTransaction(Element element) {
    if (element.source is! _AssetBasedSource) return null;

    _AssetBasedSource source = element.source;
    // Cannot modify assets in other packages.
    if (source.assetId.package != entryPoint.package) return null;

    var sourceFile = _getSourceFile(element);
    if (sourceFile == null) return null;

    return new TextEditTransaction(source.rawContents, sourceFile);
  }

  /// Gets the SourceFile for the source of the element.
  SourceFile _getSourceFile(Element element) {
    var assetId = getSourceAssetId(element);
    if (assetId == null) return null;

    var importUri = _getSourceUri(element, from: entryPoint);
    var spanPath = importUri != null ? importUri.toString() : assetId.path;
    return new SourceFile.text(spanPath, sources[assetId].rawContents);
  }
}

/// Implementation of Analyzer's Source for Barback based assets.
class _AssetBasedSource extends Source {

  /// Asset ID where this source can be found.
  final AssetId assetId;

  /// The resolver this is being used in.
  final ResolverImpl _resolver;

  /// Cache of dependent asset IDs, to avoid re-parsing the AST.
  Iterable<AssetId> _dependentAssets;

  /// The current revision of the file, incremented only when file changes.
  int _revision = 0;

  /// The file contents.
  String _contents;

  _AssetBasedSource(this.assetId, this._resolver);

  /// Update the contents of this file with [contents].
  ///
  /// Returns true if the contents of this asset have changed.
  bool updateContents(String contents) {
    if (contents == _contents) return false;
    var added = _contents == null;
    _contents = contents;
    ++_revision;
    // Invalidate the imports so we only parse the AST when needed.
    _dependentAssets = null;

    if (added) {
      _resolver._context.applyChanges(new ChangeSet()..added(this));
    } else {
      _resolver._context.applyChanges(new ChangeSet()..changed(this));
    }

    var compilationUnit = _resolver._context.parseCompilationUnit(this);
    _dependentAssets = compilationUnit.directives
        .where((d) => (d is ImportDirective || d is PartDirective ||
            d is ExportDirective))
        .map((d) => _resolve(assetId, d.uri.stringValue,
            _logger, _getSpan(d)))
        .where((id) => id != null).toSet();
    return true;
  }

  /// Contents of the file.
  TimestampedData<String> get contents =>
      new TimestampedData<String>(modificationStamp, _contents);

  /// Contents of the file.
  String get rawContents => _contents;

  /// Logger for the current transform.
  ///
  /// Only valid while the resolver is updating assets.
  TransformLogger get _logger => _resolver._currentTransform.logger;

  /// Gets all imports/parts/exports which resolve to assets (non-Dart files).
  Iterable<AssetId> get dependentAssets => _dependentAssets;

  bool exists() => true;

  bool operator ==(Object other) =>
      other is _AssetBasedSource && assetId == other.assetId;

  int get hashCode => assetId.hashCode;

  void getContentsToReceiver(Source_ContentReceiver receiver) {
    receiver.accept(rawContents, modificationStamp);
  }

  String get encoding =>
      "${uriKind.encoding}${assetId.package}/${assetId.path}";

  String get fullName => assetId.toString();

  int get modificationStamp => _revision;

  String get shortName => path.basename(assetId.path);

  UriKind get uriKind {
    if (assetId.path.startsWith('lib/')) return UriKind.PACKAGE_URI;
    return UriKind.FILE_URI;
  }

  bool get isInSystemLibrary => false;

  Source resolveRelative(Uri relativeUri) {
    var id = _resolve(assetId, relativeUri.toString(), _logger, null);
    if (id == null) return null;

    // The entire AST should have been parsed and loaded at this point.
    var source = _resolver.sources[id];
    if (source == null) {
      _logger.error('Could not load asset $id');
    }
    return source;
  }

  /// For logging errors.
  Span _getSpan(AstNode node) => _sourceFile.span(node.offset, node.end);
  /// For logging errors.
  SourceFile get _sourceFile {
    var uri = getSourceUri(_resolver.entryPoint);
    var path = uri != null ? uri.toString() : assetId.path;

    return new SourceFile.text(path, rawContents);
  }

  /// Gets a URI which would be appropriate for importing this file.
  ///
  /// Note that this file may represent a non-importable file such as a part.
  Uri getSourceUri([AssetId from]) {
    if (!assetId.path.startsWith('lib/')) {
      // Cannot do absolute imports of non lib-based assets.
      if (from == null) return null;

      if (assetId.package != from.package) return null;
      return new Uri(
          path: path.relative(assetId.path, from: path.dirname(from.path)));
    }

    return Uri.parse('package:${assetId.package}/${assetId.path.substring(4)}');
  }
}

/// Implementation of Analyzer's UriResolver for Barback based assets.
class _AssetUriResolver implements UriResolver {
  final ResolverImpl _resolver;
  _AssetUriResolver(this._resolver);

  Source resolveAbsolute(Uri uri) {
    var assetId = _resolve(null, uri.toString(), logger, null);
    var source = _resolver.sources[assetId];
    /// All resolved assets should be available by this point.
    if (source == null) {
      logger.error('Unable to find asset for "$uri"');
    }
    return source;
  }

  Source fromEncoding(UriKind kind, Uri uri) =>
      throw new UnsupportedError('fromEncoding is not supported');

  Uri restoreAbsolute(Source source) =>
      throw new UnsupportedError('restoreAbsolute is not supported');

  TransformLogger get logger => _resolver._currentTransform.logger;
}


/// Dart SDK which wraps all Dart sources to ensure they are tracked with Uris.
///
/// Just a simple wrapper to make it easy to make sure that all sources we
/// encounter are either _AssetBasedSource or _DartSourceProxy.
class _DirectoryBasedDartSdkProxy extends DirectoryBasedDartSdk {
  _DirectoryBasedDartSdkProxy(JavaFile sdkDirectory) : super(sdkDirectory);

  Source mapDartUri(String dartUri) =>
      _DartSourceProxy.wrap(super.mapDartUri(dartUri), Uri.parse(dartUri));
}


/// Dart SDK resolver which wraps all Dart sources to ensure they are tracked
/// with URIs.
class DartUriResolverProxy implements DartUriResolver {
  final DartUriResolver _proxy;
  DartUriResolverProxy(DirectoryBasedDartSdk sdk) :
      _proxy = new DartUriResolver(sdk);

  Source resolveAbsolute(Uri uri) =>
    _DartSourceProxy.wrap(_proxy.resolveAbsolute(uri), uri);

  DartSdk get dartSdk => _proxy.dartSdk;

  Source fromEncoding(UriKind kind, Uri uri) =>
      throw new UnsupportedError('fromEncoding is not supported');

  Uri restoreAbsolute(Source source) =>
      throw new UnsupportedError('restoreAbsolute is not supported');
}

/// Source file for dart: sources which track the sources with dart: URIs.
///
/// This is primarily to support [Resolver.getImportUri] for Dart SDK (dart:)
/// based libraries.
class _DartSourceProxy implements Source {

  /// Absolute URI which this source can be imported from
  final Uri uri;

  /// Underlying source object.
  final Source _proxy;

  _DartSourceProxy(this._proxy, this.uri);

  /// Ensures that [source] is a _DartSourceProxy.
  static _DartSourceProxy wrap(Source source, Uri uri) {
    if (source == null || source is _DartSourceProxy) return source;
    return new _DartSourceProxy(source, uri);
  }

  Source resolveRelative(Uri relativeUri) {
    // Assume that the type can be accessed via this URI, since these
    // should only be parts for dart core files.
    return wrap(_proxy.resolveRelative(relativeUri), uri);
  }

  bool exists() => _proxy.exists();

  bool operator ==(Object other) =>
    (other is _DartSourceProxy && _proxy == other._proxy);

  int get hashCode => _proxy.hashCode;

  void getContentsToReceiver(Source_ContentReceiver receiver) {
    _proxy.getContentsToReceiver(receiver);
  }

  TimestampedData<String> get contents => _proxy.contents;

  String get encoding => _proxy.encoding;

  String get fullName => _proxy.fullName;

  int get modificationStamp => _proxy.modificationStamp;

  String get shortName => _proxy.shortName;

  UriKind get uriKind => _proxy.uriKind;

  bool get isInSystemLibrary => _proxy.isInSystemLibrary;
}

/// Get an asset ID for a URL relative to another source asset.
AssetId _resolve(AssetId source, String url, TransformLogger logger,
    Span span) {
  if (url == null || url == '') return null;
  var uri = Uri.parse(url);

  // Workaround for dartbug.com/17156- pub transforms package: imports from
  // files of the transformers package to have absolute /packages/ URIs.
  if (uri.scheme == '' && path.isAbsolute(url)
      && uri.pathSegments[0] == 'packages') {
    uri = Uri.parse('package:${uri.pathSegments.skip(1).join(path.separator)}');
  }

  if (uri.scheme == 'package') {
    var segments = new List.from(uri.pathSegments);
    var package = segments[0];
    segments[0] = 'lib';
    return new AssetId(package, segments.join(path.separator));
  }
  // Dart SDK libraries do not have assets.
  if (uri.scheme == 'dart') return null;

  if (uri.host != '' || uri.scheme != '' || path.isAbsolute(url)) {
    logger.error('absolute paths not allowed: "$url"', span: span);
    return null;
  }

  var targetPath = path.normalize(
      path.join(path.dirname(source.path), url));
  return new AssetId(source.package, targetPath);
}


/// A completer that waits until all added [Future]s complete.
// TODO(blois): Copied from quiver. Remove from here when it gets
// added to dart:core. (See #6626.)
class FutureGroup<E> {
  static const _FINISHED = -1;

  int _pending = 0;
  Future _failedTask;
  final Completer<List> _completer = new Completer<List>();
  final List results = [];

  /** Gets the task that failed, if any. */
  Future get failedTask => _failedTask;

  /**
   * Wait for [task] to complete.
   *
   * If this group has already been marked as completed, a [StateError] will be
   * thrown.
   *
   * If this group has a [failedTask], new tasks will be ignored, because the
   * error has already been signaled.
   */
  void add(Future task) {
    if (_failedTask != null) return;
    if (_pending == _FINISHED) throw new StateError("Future already completed");

    _pending++;
    var i = results.length;
    results.add(null);
    task.then((res) {
      results[i] = res;
      if (_failedTask != null) return;
      _pending--;
      if (_pending == 0) {
        _pending = _FINISHED;
        _completer.complete(results);
      }
    }, onError: (e, s) {
      if (_failedTask != null) return;
      _failedTask = task;
      _completer.completeError(e, s);
    });
  }

  /**
   * A Future that complets with a List of the values from all the added
   * tasks, when they have all completed.
   *
   * If any task fails, this Future will receive the error. Only the first
   * error will be sent to the Future.
   */
  Future<List<E>> get future => _completer.future;
}
