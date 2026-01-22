// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show File, Directory, Process, ProcessResult;
import 'dart:typed_data';

import 'package:build_integration/file_system/multi_root.dart'
    show MultiRootFileSystemEntity, MultiRootFileSystem;
import 'package:front_end/src/api_prototype/file_system.dart' show FileSystem;
import 'package:kernel/ast.dart' show Component;
import 'package:kernel/binary/ast_from_binary.dart'
    show BinaryBuilderWithMetadata;
import 'package:kernel/kernel.dart'
    show writeComponentToBinary, writeComponentToText;
import 'package:path/path.dart' as path;

import 'compiler_options.dart';

class CompilerPhaseInputOutputManager {
  final FileSystem fileSystem;
  final WasmCompilerOptions options;

  CompilerPhaseInputOutputManager(FileSystem fileSystem, this.options)
      : fileSystem = options.multiRootScheme != null
            ? MultiRootFileSystem(
                options.multiRootScheme!,
                options.multiRoots.isEmpty ? [Uri.base] : options.multiRoots,
                fileSystem)
            : fileSystem;

  String _moduleNameToWasmFile(String prefix, String moduleName) {
    return path.join(path.dirname(prefix), moduleName);
  }

  String _moduleNameToSourceMapFile(String prefix, String moduleName) {
    return '${_moduleNameToWasmFile(prefix, moduleName)}.map';
  }

  Uri _moduleNameToRelativeSourceMapUri(String moduleName) {
    return Uri.file(path
        .basename(_moduleNameToSourceMapFile(options.outputFile, moduleName)));
  }

  Uri Function(String)? get sourceMapUrlGenerator =>
      options.translatorOptions.generateSourceMaps
          ? _moduleNameToRelativeSourceMapUri
          : null;

  Future<String> readString(Uri uri) async {
    return await File.fromUri((await resolveUri(uri))!).readAsString();
  }

  Future<List<int>> readBytes(Uri uri) async {
    return await File.fromUri((await resolveUri(uri))!).readAsBytes();
  }

  Future<void> readComponent(Uri componentUri, Component component) async {
    BinaryBuilderWithMetadata(
            await File.fromUri((await resolveUri(componentUri))!).readAsBytes())
        .readComponent(component);
  }

  Future<void> writeComponent(Component component, String path,
      {bool includeSource = true}) {
    return writeComponentToBinary(component, path,
        includeSource: includeSource);
  }

  void writeComponentAsText(Component component, String path) {
    writeComponentToText(component, path: path, showMetadata: true);
  }

  Future<void> writeWasmModule(Uint8List wasmModule, String moduleName) {
    final wasmFileName = _moduleNameToWasmFile(options.outputFile, moduleName);
    final Directory dir = Directory(path.dirname(wasmFileName));
    // Do this synchronously to make sure it happens before subsequent async
    // operations.
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    return File(wasmFileName).writeAsBytes(wasmModule);
  }

  Future<void> writeWasmSourceMap(String sourceMap, String moduleName) {
    return File(_moduleNameToSourceMapFile(options.outputFile, moduleName))
        .writeAsString(sourceMap);
  }

  Future<void> writeJsRuntime(String jsRuntime) {
    return File(path.setExtension(options.outputFile, '.mjs'))
        .writeAsString(jsRuntime);
  }

  Future<void> writeSupportJs(String supportJs) {
    return File(path.setExtension(options.outputFile, '.support.js'))
        .writeAsString(supportJs);
  }

  Future<void> runWasmOpt(
      String mainWasmModule, int moduleId, List<String> flags) async {
    final inputModuleName = options.moduleNameForId(mainWasmModule, moduleId);

    final outputModuleName =
        options.moduleNameForId(options.outputFile, moduleId);
    final wasmOutName =
        _moduleNameToWasmFile(options.outputFile, outputModuleName);
    final wasmInName = _moduleNameToWasmFile(mainWasmModule, inputModuleName);
    final args = [
      ...flags,
      wasmInName,
      '-o',
      wasmOutName,
      if (options.translatorOptions.generateSourceMaps) ...[
        '-ism',
        _moduleNameToSourceMapFile(mainWasmModule, inputModuleName),
        '-osm',
        _moduleNameToSourceMapFile(options.outputFile, outputModuleName),
        '-osu',
        _moduleNameToRelativeSourceMapUri(outputModuleName).toString(),
      ],
      if (!options.stripWasm) '-g',
    ];

    if (options.translatorOptions.verbose) {
      print('Running wasm-opt $args');
    }

    if (options.saveUnopt) {
      await File(wasmInName)
          .copy(path.setExtension(wasmOutName, '.unopt.wasm'));
    }
    final wasmOptPath = options.wasmOptPath?.toFilePath() ?? 'wasm-opt';
    final result = await _runProcess(wasmOptPath, args);
    if (result.exitCode != 0) {
      throw Exception(
          'wasm-opt failed on module $inputModuleName with exit code ${result.exitCode}:'
          '\n${result.stdout}\n${result.stderr}');
    }
  }

  Future<ProcessResult> _runProcess(
      String executable, List<String> args) async {
    return await Process.run(executable, args);
  }

  Future<Set<int>> getModuleIds(String mainWasmFilePath) async {
    final files =
        (await Directory(path.dirname(mainWasmFilePath)).list().toList());
    final mainWasmFilename = path.basename(mainWasmFilePath);
    final moduleIds = <int>{};
    for (final file in files) {
      if (file is! File) continue;
      final moduleId =
          options.idForModuleName(mainWasmFilename, path.basename(file.path));
      if (moduleId != null) {
        moduleIds.add(moduleId);
      }
    }
    return moduleIds;
  }

  Future<Uint8List> readMainDynModuleMetadataBytes() async {
    final filename = options.dynamicModuleMetadataFile ??
        Uri.parse(path.setExtension(
            options.dynamicMainModuleUri!.toFilePath(), '.dyndata'));
    return await File.fromUri(filename).readAsBytes();
  }

  Future<void> writeMainDynModuleMetadataBytes(Uint8List bytes) async {
    final filename = options.dynamicModuleMetadataFile ??
        Uri.parse(path.setExtension(
            options.dynamicMainModuleUri!.toFilePath(), '.dyndata'));
    await File.fromUri(filename).writeAsBytes(bytes);
  }

  Future<Uri?> resolveUri(Uri? uri) async {
    if (uri == null) return null;
    var fileSystemEntity = fileSystem.entityForUri(uri);
    if (fileSystemEntity is MultiRootFileSystemEntity) {
      fileSystemEntity = await fileSystemEntity.delegate;
    }
    return fileSystemEntity.uri;
  }
}
