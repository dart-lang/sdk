// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:analyzer/file_system/file_system.dart';
import 'package:package_config/package_config.dart';
import 'package:path/path.dart' show Context;

import '../shared.dart';
import 'frontend_server_client.dart';

/// Incremental DDC compiler for DartPad built on `pkg/frontend_server`.
///
/// Created for one entrypoint and kept alive as long as the pad is running:
/// [compile] is called again for every hot reload or hot restart, and only
/// recompiles what changed.
///
/// Calls to [compile] must not overlap, as the underlying
/// [FrontendServerClient] can only have one outstanding instruction.
final class FrontendServerCompiler {
  /// Sequence number handed out to [_compilerId].
  static int _nextCompilerId = 1;

  /// Scheme used with `--filesystem-scheme` / `--filesystem-root` for workspace
  /// files outside `lib/`, producing workspace-relative paths in stack traces.
  static const _scheme = 'workspace';

  /// Virtual file system from which files are read, and to which
  /// `frontend_server` writes its output.
  final ResourceProvider resourceProvider;

  /// The entrypoint within [resourceProvider] to be compiled.
  final String targetPath;

  /// The `.dart_tool/package_config.json` to be used for package resolution.
  ///
  /// This file must exist in [resourceProvider], and its grandparent folder is
  /// used as `--filesystem-root`, see [_root].
  final String packageConfig;

  /// _DartPad SDK_ configuration specifying paths within [resourceProvider].
  ///
  /// This compiler will pass [DartPadConfig.summaryModules] to
  /// `frontend_server` as `--import-dill`, see [_arguments].
  final DartPadConfig config;

  /// Distinguishes the output folder of this compiler from that of any other
  /// compiler writing into the same workspace.
  final int _compilerId = _nextCompilerId++;

  /// Source files `frontend_server` has reported as dependencies, mapped to
  /// their [File.modificationStamp] as of the last accepted compilation.
  ///
  /// A `null` stamp marks a source that has not been part of an accepted
  /// compilation yet, or that has been deleted; either way it always counts as
  /// invalidated, see [_invalidatedUris].
  final _trackedSources = <String, int?>{};

  FrontendServerClient? _client;

  /// Caller is responsible for resolving [packageConfig]. The compiler assumes
  /// `ddc_outline.dill` can be found relative to [DartPadConfig.dartSdkPath] as
  /// specified in [DartPadConfig].
  FrontendServerCompiler({
    required this.resourceProvider,
    required this.targetPath,
    required this.packageConfig,
    required this.config,
  });

  Context get _context => resourceProvider.pathContext;

  late final String _root = _context.dirname(_context.dirname(packageConfig));

  late final String _outputFolder = _context.join(
    _root,
    '.dart_tool',
    'dartpad',
    '$_compilerId',
  );

  late final String _outputDill = _context.join(_outputFolder, 'app.dill');

  /// Compile the entrypoint, returning the library bundles that changed since
  /// the previous call.
  ///
  /// The first call starts a `frontend_server` session that is kept alive for
  /// subsequent calls. Pass [restart] when the result will be applied with a
  /// hot restart rather than a hot reload, which relaxes the checks on what may
  /// change.
  ///
  /// Throws [CompilationFailedException] if compilation fails, and
  /// [HotReloadRejectedException] if the edit cannot be hot reloaded. Both
  /// leave the session intact, so the next call can still compile
  /// incrementally.
  Future<CompileResult> compile({bool restart = false}) async {
    try {
      return await _compile(restart: restart);
    } on CompilationFailedException {
      rethrow;
    } on HotReloadRejectedException {
      rethrow;
    } catch (_) {
      // Any other error means the session is in an unknown state, so throw it
      // away. Never let cleanup mask what actually went wrong.
      await close().onError((_, _) {});
      rethrow;
    }
  }

  /// Release any state held by this compiler.
  Future<void> close() async {
    if (_client case final client?) {
      _client = null;
      await client.quit();
    }
    _trackedSources.clear();
    final folder = resourceProvider.getFolder(_outputFolder);
    if (folder.exists) {
      folder.delete();
    }
  }

  Future<CompileResult> _compile({required bool restart}) async {
    final entrypoint = _entrypointUri();
    final data = {'entrypoint': targetPath};

    var client = _client;
    final firstCompile = client == null;
    final FrontendServerOutput output;
    if (client == null) {
      client = _client = FrontendServerClient.start(
        resourceProvider,
        _arguments,
      );
      output = await client.compile(entrypoint);
    } else {
      output = await client.recompile(
        entrypoint,
        _invalidatedUris(),
        restart: restart,
      );
    }

    _updateTrackedSources(output.addedSources, output.removedSources);

    if (output.errorCount > 0) {
      if (firstCompile) {
        // Nothing has been accepted yet, so there is no delta to reject and no
        // incremental state worth keeping.
        await close();
        throw CompilationFailedException(output.diagnostics, data: data);
      }
      // A rejected hot reload is reported as a single error holding the
      // exception thrown by the delta inspector, see
      // `pkg/frontend_server/lib/src/javascript_bundle.dart`. Matching the full
      // sentence avoids misreporting a compilation error that merely quotes
      // user code containing the same words.
      final rejected =
          output.errorCount == 1 &&
          output.diagnostics.contains(
            'Hot reload rejected due to unsupported changes.',
          );
      await client.reject();
      throw rejected
          ? HotReloadRejectedException(output.diagnostics, data: data)
          : CompilationFailedException(output.diagnostics, data: data);
    }

    client.accept();
    _updateSourceStamps();

    return (
      modules: _readModules(output.dillPath),
      entrypointLibraryUri: entrypoint,
      log: output.diagnostics,
    );
  }

  /// URIs of the tracked sources that changed since the last accepted
  /// compilation.
  List<String> _invalidatedUris() => [
    for (final MapEntry(key: path, value: stamp) in _trackedSources.entries)
      if (resourceProvider.getFile(path) case final file
          when !file.exists || file.modificationStamp != stamp)
        ..._urisFor(path),
  ];

  /// Applies the dependency delta `frontend_server` reported.
  ///
  /// This mirrors the dependencies `frontend_server` has _reported_, which is
  /// not the set of sources in the last accepted generation: a rejected delta
  /// rolls back the generation, but not the reported dependencies. Both ways
  /// the two can disagree are benign: invalidating a URI the compiler no longer
  /// knows is a no-op, and a source dropped by a rejected delta is reported as
  /// added again by the next compilation, staying invalidated until then.
  void _updateTrackedSources(List<Uri> addedSources, List<Uri> removedSources) {
    for (final uri in addedSources) {
      // Sources outside the pad that don't exist are the build machine paths
      // recorded in the dills passed with `--import-dill` (~1500 of them for
      // `flutter_web`). Tracking those would invalidate all of Flutter on every
      // compilation. A file in the pad may legitimately not exist yet, though:
      // a failed compilation reports the missing target of an `import` as a
      // dependency, and it is only ever reported once.
      if (_pathFor(uri) case final path?
          when _context.isWithin(_root, path) ||
              resourceProvider.getFile(path).exists) {
        _trackedSources.putIfAbsent(path, () => null);
      }
    }
    for (final uri in removedSources) {
      if (_pathFor(uri) case final path?) _trackedSources.remove(path);
    }
  }

  /// The path [uri] refers to, or `null` if it is not a file we can track.
  String? _pathFor(Uri uri) {
    // A file that `frontend_server` looked for and didn't find is reported
    // with the scheme it was looked up by.
    if (uri.isScheme(_scheme)) {
      return _context.joinAll([_root, ...uri.pathSegments]);
    }
    // Everything else is reported through `asFileUri`, which unwraps the
    // multi-root file system. Skipping an exotic URI is still better than
    // failing the compilation over it.
    assert(uri.isScheme('file'), 'Unexpected dependency URI: $uri');
    return uri.isScheme('file') ? _context.fromUri(uri) : null;
  }

  /// Records the state that `frontend_server` has just accepted, so that
  /// [_invalidatedUris] can report what changed after this point.
  void _updateSourceStamps() {
    // The package config is not reported as a dependency, but invalidating it
    // is how `frontend_server` is told to reload it, e.g. after a `pub get`.
    for (final path in [..._trackedSources.keys, packageConfig]) {
      final file = resourceProvider.getFile(path);
      // A tracked source that no longer exists stays invalidated until
      // `frontend_server` reports that it stopped depending on it.
      _trackedSources[path] = file.exists ? file.modificationStamp : null;
    }
  }

  /// Command-line arguments for `frontend_server`.
  ///
  /// Note that these are flags only: a positional entrypoint argument makes
  /// `starter()` do a single batch compilation instead of listening for
  /// instructions.
  late final List<String> _arguments = [
    // The trailing slash is required, `--platform` is resolved relative to it.
    '--sdk-root=${config.dartSdkPath}/',
    '--platform=lib/_internal/ddc_outline.dill',
    for (final MapEntry(key: dill, value: moduleName)
        in config.summaryModules.entries)
      '--import-dill=$dill:module-name=$moduleName',
    '--filesystem-scheme=$_scheme',
    '--filesystem-root=$_root',
    '--packages=$packageConfig',
    '--output-dill=$_outputDill',
    '--target=dartdevc',
    '--dartdevc-module-format=ddc',
    '--dartdevc-canary',
    '--experimental-emit-debug-metadata',
    '--incremental',
    if (config.trackCreationLocations) '--track-creation-locations',
    '-Ddart.web.assertions_enabled=true',
  ];

  /// How `frontend_server` and DDC address [targetPath] (`package:...` for
  /// files under `lib/`, `workspace:///...` for other files in the pad).
  String _entrypointUri() {
    // Reloaded on every compilation because `pub get` can change it.
    final packages = PackageConfig.parseString(
      resourceProvider.getFile(packageConfig).readAsStringSync(),
      _context.toUri(packageConfig),
    );
    final fileUri = _context.toUri(targetPath);
    final uri =
        packages.toPackageUri(fileUri) ??
        (_context.isWithin(_root, targetPath)
            ? _workspaceUri(targetPath)
            : fileUri);
    return uri.toString();
  }

  Uri _workspaceUri(String path) => Uri(
    scheme: _scheme,
    host: '',
    pathSegments: _context.split(_context.relative(path, from: _root)),
  );

  /// Returns the URI forms CFE may record for [path] (`file:///...` and, for
  /// files inside [_root], `workspace:///...`).
  ///
  /// Both are sent unconditionally: which one the CFE knows a file by depends
  /// on whether it was reached through the package config or the multi-root
  /// file system, and invalidating a URI it doesn't know is a no-op.
  List<String> _urisFor(String path) => [
    _context.toUri(path).toString(),
    if (_context.isWithin(_root, path)) _workspaceUri(path).toString(),
  ];

  /// Splits the concatenated DDC bundles in
  /// `<dillPath>.{json,sources,metadata}`.
  ///
  /// Returns an empty list if the compilation produced no bundles at all, as
  /// happens for a hot reload of sources that didn't change.
  List<CompiledModule> _readModules(String dillPath) {
    final manifestFile = resourceProvider.getFile('$dillPath.json');
    // `frontend_server` writes a manifest next to every output dill, even when
    // it holds no bundles; loading no modules beats failing the compilation.
    assert(manifestFile.exists, 'Missing bundle manifest: $dillPath.json');
    if (!manifestFile.exists) return const [];

    final manifest =
        jsonDecode(manifestFile.readAsStringSync()) as Map<String, Object?>;
    if (manifest.isEmpty) return const [];

    final sources = resourceProvider
        .getFile('$dillPath.sources')
        .readAsBytesSync();
    final metadataBytes = resourceProvider
        .getFile('$dillPath.metadata')
        .readAsBytesSync();

    final modules = [
      for (final entry in manifest.values)
        if (entry case {
          'code': [final int codeStart, final int codeEnd],
          'metadata': [final int metaStart, final int metaEnd],
        })
          if (jsonDecode(
                utf8.decoder.convert(metadataBytes, metaStart, metaEnd),
              )
              case {
                'name': final String moduleName,
                'libraries': final List<Object?> libraries,
              })
            (
              moduleName: moduleName,
              code: utf8.decoder.convert(sources, codeStart, codeEnd),
              libraries: [
                for (final lib in libraries)
                  if (lib case {'importUri': final String uri}) uri,
              ],
            ),
    ];
    // Entries are skipped if the manifest, or the metadata emitted because of
    // `--experimental-emit-debug-metadata`, isn't shaped as expected here;
    // dropping a bundle beats failing the compilation.
    assert(
      modules.length == manifest.length,
      'Read ${modules.length} of ${manifest.length} bundles from $dillPath',
    );
    // Nothing reads any of this back, and `frontend_server` writes a fresh set
    // for every compilation. `writeJavaScriptBundle` recreates the folder.
    final folder = resourceProvider.getFolder(_outputFolder);
    if (folder.exists) {
      folder.delete();
    }
    return modules;
  }
}
