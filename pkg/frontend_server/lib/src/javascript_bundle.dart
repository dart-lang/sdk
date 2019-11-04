// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:dev_compiler/dev_compiler.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';

import 'strong_components.dart';

/// Produce a special bundle format for compiled JavaScript.
///
/// The bundle format consists of two files: One containing all produced
/// JavaScript modules concatenated together, and a second containing the byte
/// offsets by module name for each JavaScript module in JSON format.
///
/// Ths format is analgous to the dill and .incremental.dill in that during
/// an incremental build, a different file is written for each which contains
/// only the updated libraries.
class JavaScriptBundler {
  JavaScriptBundler(this._originalComponent, this._strongComponents) {
    _summaries = <Component>[];
    _summaryUris = <Uri>[];
    _moduleImportForSummary = <Uri, String>{};
    _uriToComponent = <Uri, Component>{};
    for (Uri uri in _strongComponents.modules.keys) {
      final List<Library> libraries = _strongComponents.modules[uri].toList();
      final Component summaryComponent = Component(
        libraries: libraries,
        nameRoot: _originalComponent.root,
        uriToSource: _originalComponent.uriToSource,
      );
      _summaries.add(summaryComponent);
      _summaryUris.add(uri);
      _moduleImportForSummary[uri] = '${uri.path}.js';
      _uriToComponent[uri] = summaryComponent;
    }
  }

  final StrongComponents _strongComponents;
  final Component _originalComponent;

  List<Component> _summaries;
  List<Uri> _summaryUris;
  Map<Uri, String> _moduleImportForSummary;
  Map<Uri, Component> _uriToComponent;

  /// Compile each component into a single JavaScript module.
  void compile(ClassHierarchy classHierarchy, CoreTypes coreTypes,
      IOSink codeSink, IOSink manifestSink, IOSink sourceMapsSink) {
    var codeOffset = 0;
    var sourceMapOffset = 0;
    final manifest = <String, Map<String, List<int>>>{};
    final Set<Uri> visited = <Uri>{};
    for (Library library in _originalComponent.libraries) {
      // ignore: DEPRECATED_MEMBER_USE
      if (library.isExternal || library.importUri.scheme == 'dart') {
        continue;
      }
      final Uri moduleUri = _strongComponents.moduleAssignment[library.fileUri];
      if (visited.contains(moduleUri)) {
        continue;
      }
      visited.add(moduleUri);

      final summaryComponent = _uriToComponent[moduleUri];
      final compiler = ProgramCompiler(
        _originalComponent,
        classHierarchy,
        SharedCompilerOptions(sourceMap: true, summarizeApi: false),
        coreTypes: coreTypes,
      );
      final jsModule = compiler.emitModule(
          summaryComponent, _summaries, _summaryUris, _moduleImportForSummary);
      final moduleUrl = moduleUri.toString();
      final code = jsProgramToCode(jsModule, ModuleFormat.amd,
          inlineSourceMap: true,
          buildSourceMap: true,
          jsUrl: '$moduleUrl',
          mapUrl: '$moduleUrl.js.map');
      final codeBytes = utf8.encode(code.code);
      final sourceMapBytes = utf8.encode(json.encode(code.sourceMap));
      codeSink.add(codeBytes);
      sourceMapsSink.add(sourceMapBytes);

      final String moduleKey = _moduleImportForSummary[moduleUri];
      manifest[moduleKey] = {
        'code': <int>[codeOffset, codeOffset += codeBytes.length],
        'sourcemap': <int>[
          sourceMapOffset,
          sourceMapOffset += sourceMapBytes.length
        ],
      };
    }
    manifestSink.add(utf8.encode(json.encode(manifest)));
  }
}
