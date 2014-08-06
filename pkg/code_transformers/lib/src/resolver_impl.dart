// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library code_transformer.src.resolver_impl;

import 'dart:async';
import 'package:analyzer/analyzer.dart' show parseDirectives;
import 'package:analyzer/src/generated/ast.dart' hide ConstantEvaluator;
import 'package:analyzer/src/generated/constant.dart' show ConstantEvaluator,
       EvaluationResult;
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart' show DartSdk;
import 'package:analyzer/src/generated/source.dart';
import 'package:barback/barback.dart';
import 'package:code_transformers/assets.dart';
import 'package:path/path.dart' as native_path;
import 'package:source_maps/refactor.dart';
import 'package:source_span/source_span.dart';

import 'resolver.dart';
import 'dart_sdk.dart' show UriAnnotatedSource;

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

  final InternalAnalysisContext _context =
      AnalysisEngine.instance.createAnalysisContext();

  /// Transform for which this is currently updating, or null when not updating.
  Transform _currentTransform;

  /// The currently resolved entry libraries, or null if nothing is resolved.
  List<LibraryElement> _entryLibraries;
  Set<LibraryElement> _libraries;

  /// Future indicating when this resolver is done in the current phase.
  Future _lastPhaseComplete = new Future.value();

  /// Completer for wrapping up the current phase.
  Completer _currentPhaseComplete;

  /// Creates a resolver with a given [sdk] implementation for resolving
  /// `dart:*` imports.
  ResolverImpl(DartSdk sdk, DartUriResolver dartUriResolver,
      {AnalysisOptions options}) {
    if (options == null) {
      options = new AnalysisOptionsImpl()
        ..cacheSize = 256 // # of sources to cache ASTs for.
        ..preserveComments = false
        ..analyzeFunctionBodies = true;
    }
    _context.analysisOptions = options;
    sdk.context.analysisOptions = options;
    _context.sourceFactory = new SourceFactory([dartUriResolver,
        new _AssetUriResolver(this)]);
  }

  LibraryElement getLibrary(AssetId assetId) {
    var source = sources[assetId];
    return source == null ? null : _context.computeLibraryElement(source);
  }

  Future<Resolver> resolve(Transform transform, [List<AssetId> entryPoints]) {
    // Can only have one resolve in progress at a time, so chain the current
    // resolution to be after the last one.
    var phaseComplete = new Completer();
    var future = _lastPhaseComplete.whenComplete(() {
      _currentPhaseComplete = phaseComplete;
      return _performResolve(transform,
        entryPoints == null ? [transform.primaryInput.id] : entryPoints);
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

    // Clear out libraries since they should not be referenced after release.
    _entryLibraries = null;
    _libraries = null;
    _currentTransform = null;
  }

  Future _performResolve(Transform transform, List<AssetId> entryPoints) {
    if (_currentTransform != null) {
      throw new StateError('Cannot be accessed by concurrent transforms');
    }
    _currentTransform = transform;

    // Basic approach is to start at the first file, update it's contents
    // and see if it changed, then walk all files accessed by it.
    var visited = new Set<AssetId>();
    var visiting = new FutureGroup();
    var toUpdate = [];

    void processAsset(AssetId assetId) {
      visited.add(assetId);

      visiting.add(transform.readInputAsString(assetId).then((contents) {
        var source = sources[assetId];
        if (source == null) {
          source = new _AssetBasedSource(assetId, this);
          sources[assetId] = source;
        }
        source.updateDependencies(contents);
        toUpdate.add(new _PendingUpdate(source, contents));
        source.dependentAssets.where((id) => !visited.contains(id))
            .forEach(processAsset);
      }, onError: (e) {
        var source = sources[assetId];
        if (source != null && source.exists()) {
          _context.applyChanges(
              new ChangeSet()..removedSource(source));
          sources[assetId].updateContents(null);
        }
      }));
    }
    entryPoints.forEach(processAsset);

    // Once we have all asset sources updated with the new contents then
    // resolve everything.
    return visiting.future.then((_) {
      var changeSet = new ChangeSet();
      toUpdate.forEach((pending) => pending.apply(changeSet));
      var unreachableAssets = sources.keys.toSet()
          .difference(visited)
          .map((id) => sources[id]);
      for (var unreachable in unreachableAssets) {
        changeSet.removedSource(unreachable);
        unreachable.updateContents(null);
        sources.remove(unreachable.assetId);
      }

      // Update the analyzer context with the latest sources
      _context.applyChanges(changeSet);
      // Force resolve each entry point (the getter will ensure the library is
      // computed first).
      _entryLibraries = entryPoints.map((id) {
        var source = sources[id];
        if (source == null) return null;
        return _context.computeLibraryElement(source);
      }).toList();
    });
  }

  Iterable<LibraryElement> get libraries {
    if (_libraries == null) {
      // Note: we don't use `lib.visibleLibraries` because that excludes the
      // exports seen in the entry libraries.
      _libraries = new Set<LibraryElement>();
      _entryLibraries.forEach(_collectLibraries);
    }
    return _libraries;
  }

  void _collectLibraries(LibraryElement lib) {
    if (lib == null || _libraries.contains(lib)) return;
    _libraries.add(lib);
    lib.importedLibraries.forEach(_collectLibraries);
    lib.exportedLibraries.forEach(_collectLibraries);
  }

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

  EvaluationResult evaluateConstant(
      LibraryElement library, Expression expression) {
    return new ConstantEvaluator(library.source, _context.typeProvider)
        .evaluate(expression);
  }

  Uri getImportUri(LibraryElement lib, {AssetId from}) =>
      _getSourceUri(lib, from: from);


  /// Similar to getImportUri but will get the part URI for parts rather than
  /// the library URI.
  Uri _getSourceUri(Element element, {AssetId from}) {
    var source = element.source;
    if (source is _AssetBasedSource) {
      return source.getSourceUri(from);
    } else if (source is UriAnnotatedSource) {
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

  SourceSpan getSourceSpan(Element element) {
    var sourceFile = getSourceFile(element);
    if (sourceFile == null) return null;
    return sourceFile.span(element.node.offset, element.node.end);
  }

  TextEditTransaction createTextEditTransaction(Element element) {
    if (element.source is! _AssetBasedSource) return null;

    // Cannot edit unless there is an active transformer.
    if (_currentTransform == null) return null;

    _AssetBasedSource source = element.source;
    // Cannot modify assets in other packages.
    if (source.assetId.package != _currentTransform.primaryInput.id.package) {
      return null;
    }

    var sourceFile = getSourceFile(element);
    if (sourceFile == null) return null;

    return new TextEditTransaction(source.rawContents, sourceFile);
  }

  /// Gets the SourceFile for the source of the element.
  SourceFile getSourceFile(Element element) {
    var assetId = getSourceAssetId(element);
    if (assetId == null) return null;

    var importUri = _getSourceUri(element);
    var spanPath = importUri != null ? importUri.toString() : assetId.path;
    return new SourceFile(sources[assetId].rawContents, url: spanPath);
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

  /// Update the dependencies of this source. This parses [contents] but avoids
  /// any analyzer resolution.
  void updateDependencies(String contents) {
    if (contents == _contents) return;
    var unit = parseDirectives(contents, suppressErrors: true);
    _dependentAssets = unit.directives
        .where((d) => (d is ImportDirective || d is PartDirective ||
            d is ExportDirective))
        .map((d) => _resolve(assetId, d.uri.stringValue, _logger,
              _getSpan(d, contents)))
        .where((id) => id != null).toSet();
  }

  /// Update the contents of this file with [contents].
  ///
  /// Returns true if the contents of this asset have changed.
  bool updateContents(String contents) {
    if (contents == _contents) return false;
    _contents = contents;
    ++_revision;
    return true;
  }

  /// Contents of the file.
  TimestampedData<String> get contents {
    if (!exists()) throw new StateError('$assetId does not exist');

    return new TimestampedData<String>(modificationStamp, _contents);
  }

  /// Contents of the file.
  String get rawContents => _contents;

  Uri get uri => Uri.parse('asset:${assetId.package}/${assetId.path}');

  /// Logger for the current transform.
  ///
  /// Only valid while the resolver is updating assets.
  TransformLogger get _logger => _resolver._currentTransform.logger;

  /// Gets all imports/parts/exports which resolve to assets (non-Dart files).
  Iterable<AssetId> get dependentAssets => _dependentAssets;

  bool exists() => _contents != null;

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

  Uri resolveRelativeUri(Uri relativeUri) {
    var id = _resolve(assetId, relativeUri.toString(), _logger, null);
    if (id == null) return uri.resolveUri(relativeUri);

    // The entire AST should have been parsed and loaded at this point.
    var source = _resolver.sources[id];
    if (source == null) {
      _logger.error('Could not load asset $id');
    }
    return source.uri;
  }

  /// For logging errors.
  SourceSpan _getSpan(AstNode node, [String contents]) =>
      _getSourceFile(contents).span(node.offset, node.end);
  /// For logging errors.
  SourceFile _getSourceFile([String contents]) {
    var uri = getSourceUri();
    var path = uri != null ? uri.toString() : assetId.path;
    return new SourceFile(contents != null ? contents : rawContents, url: path);
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
    assert(uri.scheme != 'dart');
    var assetId;
    if (uri.scheme == 'asset') {
      var parts = path.split(uri.path);
      assetId = new AssetId(parts[0], path.joinAll(parts.skip(1)));
    } else {
      assetId = _resolve(null, uri.toString(), logger, null);
      if (assetId == null) {
        logger.error('Unable to resolve asset ID for "$uri"');
        return null;
      }
    }
    var source = _resolver.sources[assetId];
    // Analyzer expects that sources which are referenced but do not exist yet
    // still exist, so just make an empty source.
    if (source == null) {
      source = new _AssetBasedSource(assetId, _resolver);
      _resolver.sources[assetId] = source;
    }
    return source;
  }

  Source fromEncoding(UriKind kind, Uri uri) =>
      throw new UnsupportedError('fromEncoding is not supported');

  Uri restoreAbsolute(Source source) =>
      throw new UnsupportedError('restoreAbsolute is not supported');

  TransformLogger get logger => _resolver._currentTransform.logger;
}

/// Get an asset ID for a URL relative to another source asset.
AssetId _resolve(AssetId source, String url, TransformLogger logger,
    SourceSpan span) {
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

  return uriToAssetId(source, url, logger, span);
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
   * A Future that completes with a List of the values from all the added
   * tasks, when they have all completed.
   *
   * If any task fails, this Future will receive the error. Only the first
   * error will be sent to the Future.
   */
  Future<List<E>> get future => _completer.future;
}

/// A pending update to notify the resolver that a [Source] has been added or
/// changed. This is used by the `_performResolve` algorithm above to apply all
/// changes after it first discovers the transitive closure of files that are
/// reachable from the sources.
class _PendingUpdate {
  _AssetBasedSource source;
  String content;

  _PendingUpdate(this.source, this.content);

  void apply(ChangeSet changeSet) {
    if (!source.updateContents(content)) return;
    if (source._revision == 1 && source._contents != null) {
      changeSet.addedSource(source);
    } else {
      changeSet.changedSource(source);
    }
  }
}
