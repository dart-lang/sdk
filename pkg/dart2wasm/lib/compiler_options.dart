// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:front_end/src/api_unstable/vm.dart' as fe;
import 'package:path/path.dart' as path;

import 'dynamic_modules.dart' show DynamicModuleType;
import 'translator.dart';

/// Represents a discrete phase of dart2wasm's compilation process.
///
/// cfe: Runs the common frontend and applies any modular transforms as part of
/// that process.
///
/// tfa: Runs global transforms on kernel including, but not limited to, TFA.
///
/// codegen: Runs the main dart2wasm translation process converting the kernel
/// into WASM modules.
enum CompilerPhase {
  cfe,
  tfa,
  codegen,
  opt;

  static CompilerPhase parse(String name) {
    for (final phase in values) {
      if (phase.name == name) return phase;
    }
    throw ArgumentError('Invalid compiler phase name: $name');
  }
}

class WasmCompilerOptions {
  static const int mainModuleId = 0;
  final TranslatorOptions translatorOptions = TranslatorOptions();

  Uri? platformPath;
  Uri? librariesSpecPath;
  Uri? packagesPath;
  Uri mainUri;
  String outputFile;
  String? depFile;
  DynamicModuleType? dynamicModuleType;
  Uri? dynamicMainModuleUri;
  Uri? dynamicInterfaceUri;
  Uri? dynamicModuleMetadataFile;
  Uri? loadsIdsUri;
  Uri? programSplitConstraintsUri;
  bool validateDynamicModules = true;
  Map<String, String> environment = {};
  Map<fe.ExperimentalFlag, bool> feExperimentalFlags = const {};
  String? multiRootScheme;
  List<Uri> multiRoots = const [];
  List<String> deleteToStringPackageUri = const [];
  String? dumpKernelAfterCfe;
  String? dumpKernelBeforeTfa;
  String? dumpKernelAfterTfa;
  bool dryRun = false;
  Uri? wasmOptPath;
  int maxActiveWasmOptProcesses = _defaultMaxActiveWasmOptProcesses();
  bool saveUnopt = false;
  Set<int> moduleIdsToOptimize = const {};
  bool stripWasm = true;
  Uri? recordedUsesFile;
  List<CompilerPhase> phases = const [
    CompilerPhase.cfe,
    CompilerPhase.tfa,
    CompilerPhase.codegen
  ];

  factory WasmCompilerOptions.defaultOptions() =>
      WasmCompilerOptions(mainUri: Uri(), outputFile: '');

  WasmCompilerOptions({required this.mainUri, required this.outputFile});

  bool get enableDynamicModules => dynamicModuleType != null;

  bool get useMultiModuleOpt =>
      translatorOptions.enableDeferredLoading ||
      translatorOptions.enableMultiModuleStressTestMode ||
      enableDynamicModules;

  String moduleNameForId(String filePath, int id, {bool emitAsMain = false}) =>
      emitAsMain || id == mainModuleId
          ? path.basename(filePath)
          : path.basename(path.setExtension(filePath, '_module$id.wasm'));

  int? idForModuleName(String mainWasmFilename, String moduleFilename) {
    assert(mainWasmFilename.endsWith('.wasm') &&
        !mainWasmFilename.contains(path.separator));

    if (mainWasmFilename == moduleFilename) return mainModuleId;

    final prefix = '${path.basenameWithoutExtension(mainWasmFilename)}_module';
    if (!moduleFilename.startsWith(prefix) ||
        !moduleFilename.endsWith('.wasm')) {
      return null;
    }
    return int.tryParse(moduleFilename.substring(
        prefix.length, moduleFilename.length - '.wasm'.length));
  }

  static int _defaultMaxActiveWasmOptProcesses() {
    try {
      return Platform.numberOfProcessors;
    } catch (e) {
      // Fallback to 8 if numberOfProcessors is not available (e.g. if this is
      // running in a web context).
      return 8;
    }
  }

  bool get emitCfe => phases.last == CompilerPhase.cfe;
  bool get emitTfa => phases.last == CompilerPhase.tfa;
  bool get emitCodegen => phases.last == CompilerPhase.tfa;
  bool get readCodegen => phases.first == CompilerPhase.codegen;

  void validate() {
    if (translatorOptions.importSharedMemory &&
        translatorOptions.sharedMemoryMaxPages == null) {
      throw ArgumentError("--shared-memory-max-pages must be specified if "
          "--import-shared-memory is used.");
    }

    if (!translatorOptions.enableDeferredLoading) {
      if (loadsIdsUri != null) {
        throw ArgumentError("--load-ids can only be used with "
            "--enable-deferred-loading");
      }
    }

    if (enableDynamicModules) {
      if (dynamicMainModuleUri == null) {
        throw ArgumentError("--dynamic-module-main must be specified if "
            "compiling dynamic modules.");
      }

      if (dynamicInterfaceUri == null) {
        throw ArgumentError("--dynamic-module-interface must be specified if "
            "compiling dynamic modules.");
      }
    }

    _validatePhases();
  }

  void _validatePhases() {
    if (phases.isEmpty) {
      throw ArgumentError('--phases must contain at least one phase.');
    }

    CompilerPhase? previousPhase;
    for (final phase in phases) {
      // Ensure phases are consecutive
      if (previousPhase != null && previousPhase.index != phase.index - 1) {
        throw ArgumentError('--phases must contain consecutive phases.');
      }
      previousPhase = phase;
    }

    // Ensure correct input file type
    final inputExtension = path.extension(mainUri.path);
    switch (phases.first) {
      case CompilerPhase.cfe:
        if (inputExtension != '.dart') {
          throw ArgumentError('Input to cfe phase must be a .dart file.');
        }
      case CompilerPhase.tfa:
        if (inputExtension != '.dill') {
          throw ArgumentError('Input to tfa phase must be a .dill file.');
        }
      case CompilerPhase.codegen:
        if (inputExtension != '.dill') {
          throw ArgumentError('Input to codegen phase must be a .dill file.');
        }
      case CompilerPhase.opt:
        if (inputExtension != '.wasm') {
          throw ArgumentError('Input to opt phase must be a .wasm file.');
        }
    }

    // Ensure correct output file type
    final outputExtension = path.extension(outputFile);
    switch (phases.last) {
      case CompilerPhase.cfe:
        if (outputExtension != '.dill') {
          throw ArgumentError('Output from cfe phase must be a .dill file.');
        }
      case CompilerPhase.tfa:
        if (outputExtension != '.dill') {
          throw ArgumentError('Output from tfa phase must be a .dill file.');
        }
      case CompilerPhase.codegen:
        if (outputExtension != '.wasm') {
          throw ArgumentError(
              'Output from codegen phase must be a .wasm file.');
        }
      case CompilerPhase.opt:
        if (outputExtension != '.wasm') {
          throw ArgumentError('Output from opt phase must be a .wasm file.');
        }
    }

    if (phases.contains(CompilerPhase.opt) &&
        translatorOptions.optimizationLevel == 0) {
      throw ArgumentError(
          'Cannot specify "opt" phase with optimization level 0');
    }
  }
}
