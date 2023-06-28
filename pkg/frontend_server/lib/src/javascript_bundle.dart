// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: implementation_imports

import 'dart:convert';
import 'dart:io';

import 'package:dev_compiler/dev_compiler.dart';
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
/// JavaScript modules concatenated together, and a second containing the byte
/// offsets by module name for each JavaScript module in JSON format.
///
/// Ths format is analogous to the dill and .incremental.dill in that during
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
    this.soundNullSafety = false,
    this.canaryFeatures = false,
    String? moduleFormat,
  }) : _moduleFormat = parseModuleFormat(moduleFormat ?? 'amd');

  final bool useDebuggerModuleNames;
  final bool emitDebugMetadata;
  final bool emitDebugSymbols;
  final ModuleFormat _moduleFormat;
  final bool soundNullSafety;
  final bool canaryFeatures;
  final FileSystem? _fileSystem;
  final Set<Library> _loadedLibraries;
  final Map<Uri, Component> _uriToComponent = <Uri, Component>{};
  final _importToSummary = Map<Library, Component>.identity();
  final _summaryToModule = Map<Component, String>.identity();
  final Map<Uri, String> _moduleImportForSummary = <Uri, String>{};
  final Map<Uri, String> _moduleImportNameForSummary = <Uri, String>{};
  final String _fileSystemScheme;

  late Component _lastFullComponent;
  late Component _currentComponent;
  late StrongComponents _strongComponents;

  /// Initialize the incremental bundler from a full component.
  Future<void> initialize(
      Component fullComponent, Uri mainUri, PackageConfig packageConfig) async {
    _lastFullComponent = fullComponent;
    _currentComponent = fullComponent;
    _strongComponents = StrongComponents(
      fullComponent,
      _loadedLibraries,
      mainUri,
      _fileSystem,
    );
    await _strongComponents.computeModules();
    _updateSummaries(_strongComponents.modules.keys, packageConfig);
  }

  /// Update the incremental bundler from a partial component and the last full
  /// component.
  Future<void> invalidate(
      Component partialComponent,
      Component lastFullComponent,
      Uri mainUri,
      PackageConfig packageConfig) async {
    _currentComponent = partialComponent;
    _updateFullComponent(lastFullComponent, partialComponent);
    _strongComponents = StrongComponents(
      _lastFullComponent,
      _loadedLibraries,
      mainUri,
      _fileSystem,
    );

    await _strongComponents.computeModules(<Uri, Library>{
      for (Library library in partialComponent.libraries)
        library.importUri: library,
    });
    var invalidated = <Uri>{
      for (Library library in partialComponent.libraries)
        _strongComponents.moduleAssignment[library.importUri]!,
    };
    _updateSummaries(invalidated, packageConfig);
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

    _lastFullComponent = Component(
      libraries: combined.values.toList(),
      uriToSource: uriToSource,
    )..setMainMethodAndMode(
        candidate.mainMethod?.reference, true, candidate.mode);
    for (final repo in candidate.metadata.values) {
      _lastFullComponent.addMetadataRepository(repo);
    }
  }

  /// Update the summaries [moduleKeys].
  void _updateSummaries(Iterable<Uri> moduleKeys, PackageConfig packageConfig) {
    for (Uri uri in moduleKeys) {
      final List<Library> libraries = _strongComponents.modules[uri]!.toList();
      final Component summaryComponent = Component(
        libraries: libraries,
        nameRoot: _lastFullComponent.root,
        uriToSource: _lastFullComponent.uriToSource,
      );
      summaryComponent.setMainMethodAndMode(
          null, false, _currentComponent.mode);

      var baseName = urlForComponentUri(uri, packageConfig);
      _moduleImportForSummary[uri] = '$baseName.lib.js';
      _moduleImportNameForSummary[uri] = makeModuleName(baseName);

      _uriToComponent[uri] = summaryComponent;
      // module loaders loads modules by modules names, not paths
      var moduleImport = _moduleImportNameForSummary[uri]!;

      var oldSummaries = <Component>[];
      for (Component summary in _summaryToModule.keys) {
        if (_summaryToModule[summary] == moduleImport) {
          oldSummaries.add(summary);
        }
      }
      for (Component summary in oldSummaries) {
        _summaryToModule.remove(summary);
      }
      _importToSummary
          .removeWhere((key, value) => oldSummaries.contains(value));

      for (Library library in summaryComponent.libraries) {
        assert(!_importToSummary.containsKey(library));
        _importToSummary[library] = summaryComponent;
        _summaryToModule[summaryComponent] = moduleImport;
      }
    }
  }

  /// Compile each component into a single JavaScript module.
  Future<Map<String, ProgramCompiler>> compile(
    ClassHierarchy classHierarchy,
    CoreTypes coreTypes,
    PackageConfig packageConfig,
    IOSink codeSink,
    IOSink manifestSink,
    IOSink sourceMapsSink,
    IOSink? metadataSink,
    IOSink? symbolsSink,
  ) async {
    var codeOffset = 0;
    var sourceMapOffset = 0;
    var metadataOffset = 0;
    var symbolsOffset = 0;
    final manifest = <String, Map<String, List<int>>>{};
    final Set<Uri> visited = <Uri>{};
    final Map<String, ProgramCompiler> kernel2JsCompilers = {};

    for (Library library in _currentComponent.libraries) {
      if (_loadedLibraries.contains(library) ||
          library.importUri.isScheme('dart')) {
        continue;
      }
      final Uri moduleUri =
          _strongComponents.moduleAssignment[library.importUri]!;
      if (visited.contains(moduleUri)) {
        continue;
      }
      visited.add(moduleUri);

      final summaryComponent = _uriToComponent[moduleUri]!;

      // module name to use in trackLibraries
      // use full path for tracking if module uri is not a package uri.
      final moduleUrl = urlForComponentUri(moduleUri, packageConfig);
      final moduleName = makeModuleName(moduleUrl);

      var compiler = ProgramCompiler(
        _currentComponent,
        classHierarchy,
        SharedCompilerOptions(
          sourceMap: true,
          summarizeApi: false,
          emitDebugMetadata: emitDebugMetadata,
          emitDebugSymbols: emitDebugSymbols,
          moduleName: moduleName,
          soundNullSafety: soundNullSafety,
          canaryFeatures: canaryFeatures,
        ),
        _importToSummary,
        _summaryToModule,
        coreTypes: coreTypes,
      );

      final jsModule = compiler.emitModule(summaryComponent);

      // Save program compiler to reuse for expression evaluation.
      kernel2JsCompilers[moduleName] = compiler;

      String? sourceMapBase;
      if (moduleUri.isScheme('package')) {
        // Source locations come through as absolute file uris. In order to
        // make relative paths in the source map we get the absolute uri for
        // the module and make them relative to that.
        sourceMapBase = p.dirname((packageConfig.resolve(moduleUri))!.path);
      }

      final code = jsProgramToCode(
        jsModule,
        _moduleFormat,
        inlineSourceMap: true,
        buildSourceMap: true,
        emitDebugMetadata: emitDebugMetadata,
        emitDebugSymbols: emitDebugSymbols,
        jsUrl: '$moduleUrl.lib.js',
        mapUrl: '$moduleUrl.lib.js.map',
        sourceMapBase: sourceMapBase,
        customScheme: _fileSystemScheme,
        compiler: compiler,
        component: summaryComponent,
      );
      final codeBytes = utf8.encode(code.code);
      final sourceMapBytes = utf8.encode(json.encode(code.sourceMap));
      final metadataBytes =
          emitDebugMetadata ? utf8.encode(json.encode(code.metadata)) : null;
      final symbolsBytes =
          emitDebugSymbols ? utf8.encode(json.encode(code.symbols)) : null;

      codeSink.add(codeBytes);
      sourceMapsSink.add(sourceMapBytes);
      if (emitDebugMetadata) {
        metadataSink!.add(metadataBytes!);
      }
      if (emitDebugSymbols) {
        symbolsSink!.add(symbolsBytes!);
      }
      final String moduleKey = _moduleImportForSummary[moduleUri]!;
      manifest[moduleKey] = {
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

  /// Module name used in the browser to load modules.
  ///
  /// Module names are used to load modules using module
  /// paths maps in RequireJS, which treats names with
  /// leading '/' or '.js' extensions specially, and tries
  /// to load them without mapping.
  /// Skip the leading '/' to always load modules via module
  /// path maps.
  String makeModuleName(String name) {
    return name.startsWith('/') ? name.substring(1) : name;
  }

  /// Create component url.
  ///
  /// Used as a server path in the browser for the module created
  /// from the component.
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
    final resolvedUri = packageConfig.resolve(componentUri)!;
    final package = packageConfig.packageOf(resolvedUri)!;
    final root = package.root;
    final relativeRoot =
        root.pathSegments.lastWhere((segment) => segment.isNotEmpty);
    final relativeUrl = resolvedUri.toString().replaceFirst('$root', '');

    // Relative component url (used as server path in the browser):
    // `packages/<package directory>/<path to file.dart>`
    return 'packages/$relativeRoot/$relativeUrl';
  }
}
