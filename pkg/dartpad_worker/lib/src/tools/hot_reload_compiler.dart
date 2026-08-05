// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:args/args.dart';
import 'package:dev_compiler/dev_compiler.dart' as ddc;
// ignore: implementation_imports
import 'package:dev_compiler/src/kernel/hot_reload_delta_inspector.dart'
    show HotReloadDeltaInspector;
// ignore: implementation_imports
import 'package:front_end/src/api_unstable/ddc.dart' as fe;
import 'package:kernel/kernel.dart' as k;
import 'package:kernel/target/targets.dart' as k;

import '../resource_provider/resource_provider_file_system.dart';
import '../shared.dart';

/// A stateful dartdevc-like compiler for dartpad.
///
/// This compiler is initiated with a [targetPath] and every call to [compile]
/// will do a modular recompilation and return a DDC canary module.
/// Internally, this compiler will retain the latest compiled component to
/// validate that the next recompilation is eligible for hot-reloading.
final class HotReloadCompiler {
  /// Virtual file system from which files are read.
  final ResourceProvider resourceProvider;

  /// The entrypoint within [resourceProvider] to be compiled.
  final String targetPath;

  /// The `.dart_tool/package_config.json` to be used for package resolution.
  ///
  /// This file must exist in [resourceProvider].
  final String packageConfig;

  /// _DartPad SDK_ configuration specifying paths within [resourceProvider].
  ///
  /// This compiler will use [DartPadConfig.summaryModules] for modular
  /// compilation.
  final DartPadConfig config;

  k.Component? _lastComponent;

  /// Create a [HotReloadCompiler] for [targetPath] using [resourceProvider] as
  /// file system.
  ///
  /// Caller is responsible for resolving [packageConfig]. The compiler will use
  /// [DartPadConfig.summaryModules] for modular compilation, and assumes
  /// `ddc_outline.dill` and `libraries.json` can be found relative to
  /// [DartPadConfig.dartSdkPath] as specified in [DartPadConfig].
  HotReloadCompiler({
    required this.resourceProvider,
    required this.targetPath,
    required this.packageConfig,
    required this.config,
  });

  /// Compile [targetPath] to DDC canary module.
  ///
  /// After the first invocation, subsequent calls to [compile] will validate
  /// that the newly compiled DDC module can be hot-reloaded in-place of the
  /// previously returned module. If this validation fails, [compile] will
  /// throw [HotReloadRejectedException].
  ///
  /// Throws [CompilationException], if compilation fails.
  Future<CompileResult> compile() async {
    try {
      return await _compile();
    } catch (e) {
      _lastComponent = null;
      rethrow;
    }
  }

  Future<void> close() async {
    _lastComponent = null;
  }

  Future<CompileResult> _compile() async {
    final dartSdkPath = config.dartSdkPath;
    final librariesPath = '$dartSdkPath/lib/libraries.json';
    final additionalDills = config.summaryModules.keys.toList();
    final entrypoint = Uri.file(targetPath);

    final argParser = ArgParser(allowTrailingOptions: true);
    ddc.Options.addArguments(argParser);
    final options = ddc.Options(
      moduleName: 'main',
      moduleFormats: [ddc.ModuleFormat.ddc],
      canaryFeatures: true,
    );
    final compilerState = fe.initializeCompiler(
      null,
      false,
      Uri.directory(dartSdkPath),
      Uri.file('$dartSdkPath/lib/_internal/ddc_outline.dill'),
      Uri.file(packageConfig),
      Uri.file(librariesPath),
      additionalDills.map(Uri.file).toList(),
      ddc.DevCompilerTarget(
        k.TargetFlags(trackCreationLocations: config.trackCreationLocations),
      ),
      fileSystem: resourceProviderAsFileSystem(resourceProvider),
      environmentDefines: options.enableAsserts
          ? {'dart.web.assertions_enabled': 'true'}
          : null,
    );

    var success = true;
    final logLines = <String>[];
    final result = await fe.compile(compilerState, [entrypoint], (message) {
      if (message.severity == fe.CfeSeverity.error) {
        success = false;
      }
      logLines.addAll(message.plainTextFormatted);
    });
    compilerState.options.onDiagnostic = null; // See http://dartbug.com/36983
    final log = logLines.isEmpty ? '' : '${logLines.join('\n')}\n';

    if (result == null || !success) {
      throw CompilationFailedException(
        log,
        data: {'entrypoint': entrypoint.toString()},
      );
    }

    final compiledLibraries = result.compiledLibraries;

    // Check that the edit is valid for a hot reload.
    final lastComponent = _lastComponent;
    if (lastComponent != null) {
      final deltaInspector = HotReloadDeltaInspector(
        nonHotReloadablePackages: options.nonHotReloadablePackages,
      );
      final rejectionReasons = deltaInspector.compareGenerations(
        lastComponent,
        compiledLibraries,
      );

      if (rejectionReasons.isNotEmpty) {
        throw HotReloadRejectedException(
          'Hot reload rejected:\n${rejectionReasons.join('\n')}\n'
          '$log',
          data: {'entrypoint': entrypoint.toString()},
        );
      }
    }
    // Hold the compiled component for validation on the next edit.
    _lastComponent = compiledLibraries;

    final importToSummary = Map<k.Library, k.Component>.identity();
    final summaryToModule = Map<k.Component, String>.identity();
    for (var i = 0; i < result.additionalDillModules.length; i++) {
      var additionalDill = result.additionalDillModules[i];
      var moduleImport = config.summaryModules[additionalDills[i]]!;
      for (var l in additionalDill.libraries) {
        assert(!importToSummary.containsKey(l));
        importToSummary[l] = additionalDill;
        summaryToModule[additionalDill] = moduleImport;
      }
    }

    if (result.sdkSummary != null) {
      summaryToModule[result.sdkSummary!] = 'dart_sdk';
      for (var lib in result.sdkSummary!.libraries) {
        importToSummary[lib] = result.sdkSummary!;
      }
    }

    summaryToModule[compiledLibraries] = options.moduleName;
    for (var lib in compiledLibraries.libraries) {
      importToSummary[lib] = compiledLibraries;
    }

    final compiler = ddc.LibraryBundleCompiler(
      result.component,
      result.classHierarchy,
      options,
      importToSummary,
      summaryToModule,
    );

    final jsCode = ddc.jsProgramToCode(
      compiler.emitModule(compiledLibraries),
      ddc.ModuleFormat.ddcLibraryBundle,
      customScheme: options.multiRootScheme,
      compiler: compiler,
      component: compiledLibraries,
    );

    final compiledLibraryUris = compiledLibraries.libraries
        .map((l) => l.importUri.toString())
        .toList();

    return (
      code: jsCode.code,
      compiledLibraryUris: compiledLibraryUris,
      log: log,
    );
  }
}
