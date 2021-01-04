// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:dev_compiler/dev_compiler.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:path/path.dart' as p;
import 'package:package_config/package_config.dart';
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
class JavaScriptBundler {
  JavaScriptBundler(this._originalComponent, this._strongComponents,
      this._fileSystemScheme, this._packageConfig,
      {this.useDebuggerModuleNames = false,
      this.emitDebugMetadata = false,
      String moduleFormat})
      : compilers = <String, ProgramCompiler>{},
        _moduleFormat = parseModuleFormat(moduleFormat ?? 'amd') {
    _summaries = <Component>[];
    _summaryUris = <Uri>[];
    _moduleImportForSummary = <Uri, String>{};
    _moduleImportNameForSummary = <Uri, String>{};
    _uriToComponent = <Uri, Component>{};
    for (Uri uri in _strongComponents.modules.keys) {
      final List<Library> libraries = _strongComponents.modules[uri].toList();
      final Component summaryComponent = Component(
        libraries: libraries,
        nameRoot: _originalComponent.root,
        uriToSource: _originalComponent.uriToSource,
      );
      summaryComponent.setMainMethodAndMode(
          null, false, _originalComponent.mode);
      _summaries.add(summaryComponent);
      _summaryUris.add(uri);

      var baseName = urlForComponentUri(uri);
      _moduleImportForSummary[uri] = '$baseName.lib.js';
      if (useDebuggerModuleNames) {
        _moduleImportNameForSummary[uri] = makeDebuggerModuleName(baseName);
      }

      _uriToComponent[uri] = summaryComponent;
    }
  }

  final StrongComponents _strongComponents;
  final Component _originalComponent;
  final String _fileSystemScheme;
  final PackageConfig _packageConfig;
  final bool useDebuggerModuleNames;
  final bool emitDebugMetadata;
  final Map<String, ProgramCompiler> compilers;
  final ModuleFormat _moduleFormat;

  List<Component> _summaries;
  List<Uri> _summaryUris;
  Map<Uri, String> _moduleImportForSummary;
  Map<Uri, String> _moduleImportNameForSummary;
  Map<Uri, Component> _uriToComponent;

  /// Compile each component into a single JavaScript module.
  Future<void> compile(
      ClassHierarchy classHierarchy,
      CoreTypes coreTypes,
      Set<Library> loadedLibraries,
      IOSink codeSink,
      IOSink manifestSink,
      IOSink sourceMapsSink,
      IOSink metadataSink) async {
    var codeOffset = 0;
    var sourceMapOffset = 0;
    var metadataOffset = 0;
    final manifest = <String, Map<String, List<int>>>{};
    final Set<Uri> visited = <Uri>{};

    final importToSummary = Map<Library, Component>.identity();
    final summaryToModule = Map<Component, String>.identity();
    for (var i = 0; i < _summaries.length; i++) {
      var summary = _summaries[i];
      var moduleImport = useDebuggerModuleNames
          // debugger loads modules by modules names, not paths
          ? _moduleImportNameForSummary[_summaryUris[i]]
          : _moduleImportForSummary[_summaryUris[i]];
      for (var l in summary.libraries) {
        assert(!importToSummary.containsKey(l));
        importToSummary[l] = summary;
        summaryToModule[summary] = moduleImport;
      }
    }

    for (Library library in _originalComponent.libraries) {
      if (loadedLibraries.contains(library) ||
          library.importUri.scheme == 'dart') {
        continue;
      }
      final Uri moduleUri =
          _strongComponents.moduleAssignment[library.importUri];
      if (visited.contains(moduleUri)) {
        continue;
      }
      visited.add(moduleUri);

      final summaryComponent = _uriToComponent[moduleUri];

      // module name to use in trackLibraries
      // use full path for tracking if module uri is not a package uri.
      String moduleName = urlForComponentUri(moduleUri);
      if (useDebuggerModuleNames) {
        // Skip the leading '/' as module names are used to require
        // modules using module paths mape in RequireJS, which treats
        // names with leading '/' or '.js' extensions specially
        // and tries to load them without mapping.
        moduleName = makeDebuggerModuleName(moduleName);
      }

      var compiler = ProgramCompiler(
        _originalComponent,
        classHierarchy,
        SharedCompilerOptions(
          sourceMap: true,
          summarizeApi: false,
          emitDebugMetadata: emitDebugMetadata,
          moduleName: moduleName,
        ),
        importToSummary,
        summaryToModule,
        coreTypes: coreTypes,
      );

      final jsModule = compiler.emitModule(summaryComponent);

      // TODO:(annagrin): create symbol tables and pass to expression compiler
      // so it can map dart symbols to js symbols
      // [issue 40273](https://github.com/dart-lang/sdk/issues/40273)

      // program compiler is used by ExpressionCompiler to evaluate expressions
      // on demand
      compilers[moduleName] = compiler;

      final moduleUrl = urlForComponentUri(moduleUri);
      String sourceMapBase;
      if (moduleUri.scheme == 'package') {
        // Source locations come through as absolute file uris. In order to
        // make relative paths in the source map we get the absolute uri for
        // the module and make them relative to that.
        sourceMapBase =
            p.dirname((await _packageConfig.resolve(moduleUri)).path);
      }

      final code = jsProgramToCode(
        jsModule,
        _moduleFormat,
        inlineSourceMap: true,
        buildSourceMap: true,
        emitDebugMetadata: emitDebugMetadata,
        jsUrl: '$moduleUrl.lib.js',
        mapUrl: '$moduleUrl.lib.js.map',
        sourceMapBase: sourceMapBase,
        customScheme: _fileSystemScheme,
        component: summaryComponent,
      );
      final codeBytes = utf8.encode(code.code);
      final sourceMapBytes = utf8.encode(json.encode(code.sourceMap));
      final metadataBytes =
          emitDebugMetadata ? utf8.encode(json.encode(code.metadata)) : null;

      codeSink.add(codeBytes);
      sourceMapsSink.add(sourceMapBytes);
      if (emitDebugMetadata) {
        metadataSink.add(metadataBytes);
      }
      final String moduleKey = _moduleImportForSummary[moduleUri];
      manifest[moduleKey] = {
        'code': <int>[codeOffset, codeOffset += codeBytes.length],
        'sourcemap': <int>[
          sourceMapOffset,
          sourceMapOffset += sourceMapBytes.length
        ],
        if (emitDebugMetadata)
          'metadata': <int>[
            metadataOffset,
            metadataOffset += metadataBytes.length
          ],
      };
    }
    manifestSink.add(utf8.encode(json.encode(manifest)));
  }
}

String urlForComponentUri(Uri componentUri) => componentUri.scheme == 'package'
    ? '/packages/${componentUri.path}'
    : componentUri.path;

String makeDebuggerModuleName(String name) {
  return name.startsWith('/') ? name.substring(1) : name;
}
