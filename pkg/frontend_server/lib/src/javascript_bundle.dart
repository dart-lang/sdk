// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: implementation_imports

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:args/args.dart';
import 'package:dev_compiler/dev_compiler.dart';
import 'package:dev_compiler/src/command/command.dart';
import 'package:dev_compiler/src/kernel/hot_reload_delta_inspector.dart';
import 'package:dev_compiler/src/js_ast/nodes.dart';
import 'package:front_end/src/api_unstable/vm.dart' show FileSystem;
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as p;

import 'strong_components.dart';

/// Produce a special bundle format for compiled JavaScript.
///
/// The bundle format consists of two files: One containing all produced
/// JavaScript library bundles concatenated together, and a second containing
/// the byte offsets by the synthesized library bundle name for each JavaScript
/// library bundle in JSON format. The library bundle name is based off of a
/// library URI from the associated component.
///
/// The format is analogous to the dill and .incremental.dill in that during
/// an incremental build, a different file is written for each which contains
/// only the updated libraries.
class IncrementalJavaScriptBundler {
  IncrementalJavaScriptBundler(
    this._fileSystem,
    this._loadedLibraries,
    this._fileSystemScheme, {
    this.useDebuggerModuleNames = false,
    this.emitDebugMetadata = false,
    this.emitDebugSymbols = false,
    this.useStronglyConnectedComponents = true,
    this.canaryFeatures = false,
    String? moduleFormat,
    this.extraDdcOptions = const [],
  }) : _moduleFormat = parseModuleFormat(moduleFormat ?? 'amd');

  final bool useDebuggerModuleNames;
  final bool emitDebugMetadata;
  final bool emitDebugSymbols;
  final bool useStronglyConnectedComponents;
  final ModuleFormat _moduleFormat;
  final List<String> extraDdcOptions;
  final bool canaryFeatures;
  final FileSystem? _fileSystem;
  final Set<Library> _loadedLibraries;
  final Map<Uri, Component> _uriToComponent = <Uri, Component>{};
  final _libraryToSummary = new Map<Library, Component>.identity();
  final _summaryToLibraryBundleName = new Map<Component, String>.identity();
  final Map<Uri, String> _summaryToLibraryBundleJSPath = <Uri, String>{};
  final String _fileSystemScheme;
  final HotReloadDeltaInspector _deltaInspector = new HotReloadDeltaInspector();

  late HotReloadLibraryMetadataRepository _libraryMetadataRepository;
  late Component _lastFullComponent;
  late Component _currentComponent;
  late StrongComponents _strongComponents;

  /// Initialize the incremental bundler from a full component.
  Future<void> initialize(
      Component fullComponent, Uri mainUri, PackageConfig packageConfig) async {
    _lastFullComponent = fullComponent;
    _currentComponent = fullComponent;
    // Initialize fresh hot reload metadata for this compile and throw out all
    // information collected from any previous series of hot reloads compiles.
    _libraryMetadataRepository = new HotReloadLibraryMetadataRepository();
    Iterable<Uri> initialLibraryUris;
    if (useStronglyConnectedComponents) {
      _strongComponents = new StrongComponents(
        fullComponent,
        _loadedLibraries,
        mainUri,
        _fileSystem,
      );
      await _strongComponents.computeLibraryBundles();
      initialLibraryUris =
          _strongComponents.libraryBundleImportToLibraries.keys;
    } else {
      initialLibraryUris =
          fullComponent.libraries.map((library) => library.importUri);
    }
    _updateSummaries(initialLibraryUris, packageConfig);
  }

  /// Update the incremental bundler from a partial component and the last full
  /// component.
  Future<void> invalidate(Component partialComponent,
      Component lastFullComponent, Uri mainUri, PackageConfig packageConfig,
      {required bool recompileRestart}) async {
    if (canaryFeatures &&
        _moduleFormat == ModuleFormat.ddc &&
        !recompileRestart) {
      // Attach the global metadata to the last full component. The delta
      // inspector will add to it while comparing the two components.
      lastFullComponent.addMetadataRepository(_libraryMetadataRepository);
      // Find any potential hot reload rejections before updating the strongly
      // connected component graph.
      final List<String> errors = _deltaInspector.compareGenerations(
          lastFullComponent, partialComponent);
      if (errors.isNotEmpty) {
        throw new Exception(errors.join('/n') +
            '\nHot reload rejected due to unsupported changes. '
                'Try performing a hot restart instead.');
      }
    }
    _currentComponent = partialComponent;
    _updateFullComponent(lastFullComponent, partialComponent);
    Iterable<Uri> invalidatedLibraryUris;

    if (useStronglyConnectedComponents) {
      _strongComponents = new StrongComponents(
        _lastFullComponent,
        _loadedLibraries,
        mainUri,
        _fileSystem,
      );
      await _strongComponents.computeLibraryBundles(<Uri, Library>{
        for (Library library in partialComponent.libraries)
          library.importUri: library,
      });
      invalidatedLibraryUris = <Uri>{
        for (Library library in partialComponent.libraries)
          _strongComponents
              .libraryImportToLibraryBundleImport[library.importUri]!,
      };
    } else {
      invalidatedLibraryUris =
          partialComponent.libraries.map((library) => library.importUri);
    }
    _updateSummaries(invalidatedLibraryUris, packageConfig);
  }

  void _updateFullComponent(Component lastKnownGood, Component candidate) {
    Map<Uri, Library> combined = <Uri, Library>{};
    Map<Uri, Source> uriToSource = <Uri, Source>{};
    for (Library library in lastKnownGood.libraries) {
      combined[library.importUri] = library;
    }
    for (Library library in candidate.libraries) {
      combined[library.importUri] = library;
    }
    uriToSource.addAll(lastKnownGood.uriToSource);
    uriToSource.addAll(candidate.uriToSource);

    _lastFullComponent = new Component(
      libraries: combined.values.toList(),
      uriToSource: uriToSource,
    )..setMainMethodAndMode(candidate.mainMethod?.reference, true);
    for (final MetadataRepository repo in candidate.metadata.values) {
      _lastFullComponent.addMetadataRepository(repo);
    }
  }

  /// Update the summaries using the [libraryBundleImports].
  void _updateSummaries(
      Iterable<Uri> libraryBundleImports, PackageConfig packageConfig) {
    final Map<Uri, Library> libraryUriToLibrary = {
      for (Library library in _lastFullComponent.libraries)
        library.importUri: library,
    };
    for (Uri uri in libraryBundleImports) {
      final List<Library> libraries = useStronglyConnectedComponents
          ? _strongComponents.libraryBundleImportToLibraries[uri]!.toList()
          : [libraryUriToLibrary[uri]!];
      final Component summaryComponent = new Component(
        libraries: libraries,
        nameRoot: _lastFullComponent.root,
        uriToSource: _lastFullComponent.uriToSource,
      );
      summaryComponent.setMainMethodAndMode(null, false);

      String baseName = urlForComponentUri(uri, packageConfig);
      _summaryToLibraryBundleJSPath[uri] = '$baseName.lib.js';
      // Library bundle loaders loads bundles by bundle names, not paths
      String libraryBundleName = makeLibraryBundleName(baseName);

      _uriToComponent[uri] = summaryComponent;

      List<Component> oldSummaries = [];
      for (Component summary in _summaryToLibraryBundleName.keys) {
        if (_summaryToLibraryBundleName[summary] == libraryBundleName) {
          oldSummaries.add(summary);
        }
      }
      for (Component summary in oldSummaries) {
        _summaryToLibraryBundleName.remove(summary);
      }
      _libraryToSummary
          .removeWhere((key, value) => oldSummaries.contains(value));

      for (Library library in summaryComponent.libraries) {
        assert(!_libraryToSummary.containsKey(library));
        _libraryToSummary[library] = summaryComponent;
        _summaryToLibraryBundleName[summaryComponent] = libraryBundleName;
      }
    }
  }

  /// Reports if [option] in [extraDdcOptions] was overridden or extended
  /// to [newValue] before being passed to DDC.
  void _checkOverriddenExtraDdcOption(
      ArgResults extraDdcOptionsResults, String option, dynamic newValue) {
    if (extraDdcOptionsResults.wasParsed(option)) {
      if (newValue is List) {
        if (listEquals(extraDdcOptionsResults[option], newValue)) return;
      } else if (newValue == extraDdcOptionsResults[option]) {
        return;
      }
      print("Warning: DDC option '$option' was overridden to '$newValue'.");
    }
  }

  /// Compile each component into a single JavaScript library bundle.
  Future<Map<String, Compiler>> compile(
    ClassHierarchy classHierarchy,
    CoreTypes coreTypes,
    PackageConfig packageConfig,
    IOSink codeSink,
    IOSink manifestSink,
    IOSink sourceMapsSink,
    IOSink? metadataSink,
    IOSink? symbolsSink,
  ) async {
    int codeOffset = 0;
    int sourceMapOffset = 0;
    int metadataOffset = 0;
    int symbolsOffset = 0;
    final Map<String, Map<String, List<int>>> manifest = {};
    final Map<Uri, Compiler> visited = {};
    final Map<String, Compiler> kernel2JsCompilers = {};

    for (Library library in _currentComponent.libraries) {
      if (_loadedLibraries.contains(library) ||
          library.importUri.isScheme('dart')) {
        continue;
      }

      final Uri libraryOrLibraryBundleImportUri = useStronglyConnectedComponents
          ? _strongComponents
              .libraryImportToLibraryBundleImport[library.importUri]!
          : library.importUri;
      if (visited.containsKey(libraryOrLibraryBundleImportUri)) {
        kernel2JsCompilers[library.importUri.toString()] =
            visited[libraryOrLibraryBundleImportUri]!;
        continue;
      }

      final Component summaryComponent =
          _uriToComponent[libraryOrLibraryBundleImportUri]!;

      final String componentUrl =
          urlForComponentUri(libraryOrLibraryBundleImportUri, packageConfig);
      // Library bundle name to use in trackLibraries. Use the full path for
      // tracking if library bundle uri is not a package uri.
      final String libraryBundleName = makeLibraryBundleName(componentUrl);
      // Issue a warning when provided [extraDdcOptions] were overridden.
      final ArgResults extraDdcOptionsResults =
          Options.nonSdkArgParser().parse(extraDdcOptions);
      _checkOverriddenExtraDdcOption(
          extraDdcOptionsResults, 'source-map', true);
      _checkOverriddenExtraDdcOption(
          extraDdcOptionsResults, 'summarize', false);
      _checkOverriddenExtraDdcOption(extraDdcOptionsResults,
          'experimental-emit-debug-metadata', emitDebugMetadata);
      _checkOverriddenExtraDdcOption(
          extraDdcOptionsResults, 'emit-debug-symbols', emitDebugSymbols);
      _checkOverriddenExtraDdcOption(
          extraDdcOptionsResults, 'canary', canaryFeatures);
      _checkOverriddenExtraDdcOption(
          extraDdcOptionsResults, 'module-name', libraryBundleName);
      _checkOverriddenExtraDdcOption(
          extraDdcOptionsResults, 'modules', [libraryBundleName]);
      // Apply existing Frontend Server flags over options selected in
      // [extraDdcOptions].
      final List<String> ddcArgs = [
        ...extraDdcOptions,
        '--source-map',
        '--no-summarize',
        emitDebugMetadata
            ? '--experimental-emit-debug-metadata'
            : '--no-experimental-emit-debug-metadata',
        emitDebugSymbols ? '--emit-debug-symbols' : '--no-emit-debug-symbols',
        canaryFeatures ? '--canary' : '--no-canary',
        '--module-name=$libraryBundleName',
        '--modules=${_moduleFormat.flagName}',
      ];
      final Options ddcOptions =
          new Options.fromArguments(Options.nonSdkArgParser().parse(ddcArgs));
      Compiler compiler;
      if (ddcOptions.emitLibraryBundle) {
        compiler = new LibraryBundleCompiler(
          _currentComponent,
          classHierarchy,
          ddcOptions,
          _libraryToSummary,
          _summaryToLibraryBundleName,
          coreTypes: coreTypes,
        );
        // Attach all the hot reload metadata collected so far to the component
        // that is about to be compiled.
        summaryComponent.addMetadataRepository(_libraryMetadataRepository);
      } else {
        compiler = new ProgramCompiler(
          _currentComponent,
          classHierarchy,
          ddcOptions,
          _libraryToSummary,
          _summaryToLibraryBundleName,
          coreTypes: coreTypes,
        );
      }
      final Program jsBundle = compiler.emitModule(summaryComponent);

      // Save program compiler to reuse for expression evaluation.
      kernel2JsCompilers[library.importUri.toString()] = compiler;
      visited[libraryOrLibraryBundleImportUri] = compiler;

      String? sourceMapBase;
      if (libraryOrLibraryBundleImportUri.isScheme('package')) {
        // Source locations come through as absolute file uris. In order to
        // make relative paths in the source map we get the absolute uri for
        // the library bundle and make them relative to that.
        sourceMapBase = p.dirname(
            (packageConfig.resolve(libraryOrLibraryBundleImportUri))!.path);
      }

      final JSCode code = jsProgramToCode(
        jsBundle,
        ddcOptions.emitLibraryBundle
            ? ModuleFormat.ddcLibraryBundle
            : _moduleFormat,
        inlineSourceMap: true,
        buildSourceMap: true,
        emitDebugMetadata: emitDebugMetadata,
        emitDebugSymbols: emitDebugSymbols,
        jsUrl: '$componentUrl.lib.js',
        mapUrl: '$componentUrl.lib.js.map',
        sourceMapBase: sourceMapBase,
        customScheme: _fileSystemScheme,
        compiler: compiler,
        component: summaryComponent,
        packageConfig: packageConfig,
      );
      final Uint8List codeBytes = utf8.encode(code.code);
      final Uint8List sourceMapBytes = utf8.encode(json.encode(code.sourceMap));
      final Uint8List? metadataBytes =
          emitDebugMetadata ? utf8.encode(json.encode(code.metadata)) : null;
      final Uint8List? symbolsBytes =
          emitDebugSymbols ? utf8.encode(json.encode(code.symbols)) : null;

      codeSink.add(codeBytes);
      sourceMapsSink.add(sourceMapBytes);
      if (emitDebugMetadata) {
        metadataSink!.add(metadataBytes!);
      }
      if (emitDebugSymbols) {
        symbolsSink!.add(symbolsBytes!);
      }
      final String libraryBundleJSPath =
          _summaryToLibraryBundleJSPath[libraryOrLibraryBundleImportUri]!;
      manifest[libraryBundleJSPath] = {
        'code': <int>[codeOffset, codeOffset += codeBytes.length],
        'sourcemap': <int>[
          sourceMapOffset,
          sourceMapOffset += sourceMapBytes.length
        ],
        if (emitDebugMetadata)
          'metadata': <int>[
            metadataOffset,
            metadataOffset += metadataBytes!.length
          ],
        if (emitDebugSymbols)
          'symbols': <int>[
            symbolsOffset,
            symbolsOffset += symbolsBytes!.length,
          ],
      };
    }
    manifestSink.add(utf8.encode(json.encode(manifest)));

    return kernel2JsCompilers;
  }

  /// Library bundle name used in the browser to load library bundles.
  ///
  /// Library bundle names are used to load library bundles using library bundle
  /// path maps in RequireJS, which treats names with leading '/' or '.js'
  /// extensions specially, and tries to load them without mapping. Skip the
  /// leading '/' to always load library bundles via library bundle path maps.
  String makeLibraryBundleName(String name) {
    return name.startsWith('/') ? name.substring(1) : name;
  }

  /// Create component url.
  ///
  /// Used as a server path in the browser for the library bundle created from
  /// the component.
  String urlForComponentUri(Uri componentUri, PackageConfig packageConfig) {
    if (!componentUri.isScheme('package')) {
      return componentUri.path;
    }
    if (!useDebuggerModuleNames) {
      return '/packages/${componentUri.path}';
    }
    // Match relative directory structure of server paths to the
    // actual directory structure, so the sourcemaps relative paths
    // can be resolved by the browser.
    final Uri resolvedUri = packageConfig.resolve(componentUri)!;
    final Package package = packageConfig.packageOf(resolvedUri)!;
    final Uri root = package.root;
    final String relativeRoot =
        root.pathSegments.lastWhere((segment) => segment.isNotEmpty);
    final String relativeUrl = resolvedUri.toString().replaceFirst('$root', '');

    // Relative component url (used as server path in the browser):
    // `packages/<package directory>/<path to file.dart>`
    return 'packages/$relativeRoot/$relativeUrl';
  }
}
