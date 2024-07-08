// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test the modular compilation pipeline of dart2js.
///
/// This is a shell that runs multiple tests, one per folder under `data/`.
import 'dart:io';
import 'dart:ffi';
import 'dart:async';

import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/kernel/dart2js_target.dart';
import 'package:front_end/src/api_unstable/dart2js.dart'
    show computePlatformBinariesLocation;
import 'package:modular_test/src/create_package_config.dart';
import 'package:modular_test/src/io_pipeline.dart';
import 'package:modular_test/src/pipeline.dart';
import 'package:modular_test/src/runner.dart';
import 'package:modular_test/src/suite.dart';
import 'package:modular_test/src/steps/macro_precompile_aot.dart';
import 'package:modular_test/src/steps/util.dart';

String packageConfigJsonPath = ".dart_tool/package_config.json";
Uri sdkRoot = Platform.script.resolve("../../../");
Uri packageConfigUri = sdkRoot.resolve(packageConfigJsonPath);
late Options _options;
late String _dart2jsScript;
late String _kernelWorkerScript;

const dillSummaryId = DataId("summary.dill");
const dillId = DataId("full.dill");
const fullDillId = DataId("concatenate.dill");
const closedWorldId = DataId("world");
const globalDataId = DataId("global.data");
const codeId = ShardsDataId("code", 2);
const codeId0 = ShardDataId(codeId, 0);
const codeId1 = ShardDataId(codeId, 1);
const jsId = DataId("js");
const dumpInfoDataId = DataId("dump.data");
const txtId = DataId("txt");
const dumpInfoId = DataId("js.info.json");
const fakeRoot = 'dev-dart-app:/';

String getRootScheme(Module module) {
  // We use non file-URI schemes for representing source locations in a
  // root-agnostic way. This allows us to refer to file across modules and
  // across steps without exposing the underlying temporary folders that are
  // created by the framework. In build systems like bazel this is especially
  // important because each step may be run on a different machine.
  //
  // Files in packages are defined in terms of `package:` URIs, while
  // non-package URIs are defined using the `dart-dev-app` scheme.
  return module.isSdk ? 'dart-dev-sdk' : 'dev-dart-app';
}

String sourceToImportUri(Module module, Uri relativeUri) {
  if (module.isPackage) {
    var basePath = module.packageBase!.path;
    var packageRelativePath = basePath == "./"
        ? relativeUri.path
        : relativeUri.path.substring(basePath.length);
    return 'package:${module.name}/$packageRelativePath';
  } else {
    return '${getRootScheme(module)}:/$relativeUri';
  }
}

List<String> getSources(Module module) {
  return module.sources.map((uri) => sourceToImportUri(module, uri)).toList();
}

abstract class CFEStep extends IOModularStep {
  final String stepName;

  CFEStep(this.stepName);

  @override
  bool get needsSources => true;

  @override
  bool get onlyOnMain => false;

  @override
  Future<void> execute(Module module, Uri root, ModuleDataToRelativeUri toUri,
      List<String> flags) async {
    if (_options.verbose) print("\nstep: $stepName on $module");

    Set<Module> transitiveDependencies = computeTransitiveDependencies(module);
    await writePackageConfig(module, transitiveDependencies, root);

    String rootScheme = getRootScheme(module);
    List<String> sources;
    List<String> extraArgs = [
      '--packages-file',
      '$rootScheme:/$packageConfigJsonPath'
    ];
    if (module.isSdk) {
      // When no flags are passed, we can skip compilation and reuse the
      // platform.dill created by build.py.
      if (flags.isEmpty) {
        var platform =
            computePlatformBinariesLocation().resolve("dart2js_platform.dill");
        var destination = root.resolveUri(toUri(module, outputData));
        if (_options.verbose) {
          print('command:\ncp $platform $destination');
        }
        await File.fromUri(platform).copy(destination.toFilePath());
        return;
      }
      sources = requiredLibraries['dart2js']! + ['dart:core'];
      extraArgs += [
        '--libraries-file',
        '$rootScheme:///sdk/lib/libraries.json'
      ];
      assert(transitiveDependencies.isEmpty);
    } else {
      sources = getSources(module);
    }

    List<String> args = [
      _kernelWorkerScript,
      '--sound-null-safety',
      ...stepArguments,
      '--exclude-non-sources',
      '--multi-root',
      '$root',
      '--multi-root-scheme',
      rootScheme,
      ...extraArgs,
      '--output',
      '${toUri(module, outputData)}',
      ...(transitiveDependencies
          .expand((m) => ['--input-summary', '${toUri(m, inputData)}'])),
      ...transitiveDependencies
          .where((m) => m.macroConstructors.isNotEmpty)
          .expand((m) =>
              ['--precompiled-macro', '${precompiledMacroArg(m, toUri)};']),
      ...(sources.expand((String uri) => ['--source', uri])),
      ...(flags.expand((String flag) => ['--enable-experiment', flag])),
    ];

    var result = await runProcess(
        Platform.resolvedExecutable, args, root.toFilePath(), _options.verbose);
    checkExitCode(result, this, module, _options.verbose);
  }

  List<String> get stepArguments;

  DataId get inputData;

  DataId get outputData;

  @override
  void notifyCached(Module module) {
    if (_options.verbose) print("\ncached step: $stepName on $module");
  }
}

// Step that compiles sources in a module to a summary .dill file.
class OutlineDillCompilationStep extends CFEStep {
  @override
  List<DataId> get resultData => const [dillSummaryId];

  @override
  bool get needsSources => true;

  @override
  List<DataId> get dependencyDataNeeded =>
      const [dillSummaryId, precompiledMacroId];

  @override
  List<DataId> get moduleDataNeeded => const [];

  @override
  List<String> get stepArguments =>
      ['--target', 'dart2js_summary', '--summary-only'];

  @override
  DataId get inputData => dillSummaryId;

  @override
  DataId get outputData => dillSummaryId;

  OutlineDillCompilationStep() : super('outline-dill-compilation');
}

// Step that compiles sources in a module to a .dill file.
class FullDillCompilationStep extends CFEStep {
  @override
  List<DataId> get resultData => const [dillId];

  @override
  bool get needsSources => true;

  @override
  List<DataId> get dependencyDataNeeded =>
      const [dillSummaryId, precompiledMacroId];

  @override
  List<DataId> get moduleDataNeeded => const [];

  @override
  List<String> get stepArguments =>
      ['--target', 'dart2js', '--no-summary', '--no-summary-only'];

  @override
  DataId get inputData => dillSummaryId;

  @override
  DataId get outputData => dillId;

  FullDillCompilationStep() : super('full-dill-compilation');
}

class ConcatenateDillsStep extends IOModularStep {
  List<DataId> get dependencies => [dillId];

  @override
  List<DataId> get resultData => [fullDillId];

  @override
  bool get needsSources => false;

  @override
  List<DataId> get dependencyDataNeeded => dependencies;

  @override
  List<DataId> get moduleDataNeeded => dependencies;

  @override
  bool get onlyOnMain => true;

  ConcatenateDillsStep();

  @override
  Future<void> execute(Module module, Uri root, ModuleDataToRelativeUri toUri,
      List<String> flags) async {
    if (_options.verbose) print("\nstep: dart2js concatenate dills on $module");
    Set<Module> transitiveDependencies = computeTransitiveDependencies(module);
    Iterable<String> dillDependencies =
        transitiveDependencies.map((m) => '${toUri(m, dillId)}');
    List<String> args = [
      '--packages=${sdkRoot.toFilePath()}/$packageConfigJsonPath',
      _dart2jsScript,
      // TODO(sigmund): remove this dependency on libraries.json
      if (_options.useSdk) '--libraries-spec=$_librarySpecForSnapshot',
      if (_options.useSdk) '--invoker=modular_test',
      '${Flags.entryUri}=$fakeRoot${module.mainSource}',
      '${Flags.inputDill}=${toUri(module, dillId)}',
      for (String flag in flags) '--enable-experiment=$flag',
      '${Flags.dillDependencies}=${dillDependencies.join(',')}',
      '${Flags.stage}=cfe',
      '--out=${toUri(module, fullDillId)}',
    ];
    var result = await runProcess(
        Platform.resolvedExecutable, args, root.toFilePath(), _options.verbose);

    checkExitCode(result, this, module, _options.verbose);
  }

  @override
  void notifyCached(Module module) {
    if (_options.verbose)
      print("\ncached step: dart2js concatenate dills on $module");
  }
}

// Step that invokes the dart2js closed world computation.
class ComputeClosedWorldStep extends IOModularStep {
  ComputeClosedWorldStep();

  List<DataId> get dependencies => [fullDillId];

  @override
  List<DataId> get resultData => const [closedWorldId];

  @override
  bool get needsSources => false;

  @override
  List<DataId> get dependencyDataNeeded => dependencies;

  @override
  List<DataId> get moduleDataNeeded => dependencies;

  @override
  bool get onlyOnMain => true;

  @override
  Future<void> execute(Module module, Uri root, ModuleDataToRelativeUri toUri,
      List<String> flags) async {
    if (_options.verbose)
      print("\nstep: dart2js compute closed world on $module");
    List<String> args = [
      '--packages=${sdkRoot.toFilePath()}/$packageConfigJsonPath',
      _dart2jsScript,
      // TODO(sigmund): remove this dependency on libraries.json
      if (_options.useSdk) '--libraries-spec=$_librarySpecForSnapshot',
      if (_options.useSdk) '--invoker=modular_test',
      Flags.soundNullSafety,
      '${Flags.entryUri}=$fakeRoot${module.mainSource}',
      '${Flags.inputDill}=${toUri(module, fullDillId)}',
      for (String flag in flags) '--enable-experiment=$flag',
      '${Flags.closedWorldUri}=${toUri(module, closedWorldId)}',
      '${Flags.stage}=closed-world',
    ];
    var result = await runProcess(
        Platform.resolvedExecutable, args, root.toFilePath(), _options.verbose);

    checkExitCode(result, this, module, _options.verbose);
  }

  @override
  void notifyCached(Module module) {
    if (_options.verbose)
      print("\ncached step: dart2js compute closed world on $module");
  }
}

// Step that runs the dart2js modular analysis.
class GlobalAnalysisStep extends IOModularStep {
  @override
  List<DataId> get resultData => const [globalDataId];

  @override
  bool get needsSources => false;

  @override
  List<DataId> get dependencyDataNeeded => const [fullDillId];

  @override
  List<DataId> get moduleDataNeeded => const [closedWorldId, fullDillId];

  @override
  bool get onlyOnMain => true;

  @override
  Future<void> execute(Module module, Uri root, ModuleDataToRelativeUri toUri,
      List<String> flags) async {
    if (_options.verbose) print("\nstep: dart2js global analysis on $module");
    List<String> args = [
      '--packages=${sdkRoot.toFilePath()}/$packageConfigJsonPath',
      _dart2jsScript,
      // TODO(sigmund): remove this dependency on libraries.json
      if (_options.useSdk) '--libraries-spec=$_librarySpecForSnapshot',
      if (_options.useSdk) '--invoker=modular_test',
      Flags.soundNullSafety,
      '${Flags.entryUri}=$fakeRoot${module.mainSource}',
      '${Flags.inputDill}=${toUri(module, fullDillId)}',
      for (String flag in flags) '--enable-experiment=$flag',
      '${Flags.closedWorldUri}=${toUri(module, closedWorldId)}',
      '${Flags.globalInferenceUri}=${toUri(module, globalDataId)}',
      '${Flags.stage}=global-inference',
    ];
    var result = await runProcess(
        Platform.resolvedExecutable, args, root.toFilePath(), _options.verbose);

    checkExitCode(result, this, module, _options.verbose);
  }

  @override
  void notifyCached(Module module) {
    if (_options.verbose)
      print("\ncached step: dart2js global analysis on $module");
  }
}

// Step that invokes the dart2js code generation on the main module given the
// results of the global analysis step and produces one shard of the codegen
// output.
class Dart2jsCodegenStep extends IOModularStep {
  final ShardDataId codeId;

  Dart2jsCodegenStep(this.codeId);

  @override
  List<DataId> get resultData => [codeId];

  @override
  bool get needsSources => false;

  @override
  List<DataId> get dependencyDataNeeded => const [];

  @override
  List<DataId> get moduleDataNeeded =>
      const [fullDillId, closedWorldId, globalDataId];

  @override
  bool get onlyOnMain => true;

  @override
  Future<void> execute(Module module, Uri root, ModuleDataToRelativeUri toUri,
      List<String> flags) async {
    if (_options.verbose) print("\nstep: dart2js backend on $module");
    List<String> args = [
      '--packages=${sdkRoot.toFilePath()}/$packageConfigJsonPath',
      _dart2jsScript,
      if (_options.useSdk) '--libraries-spec=$_librarySpecForSnapshot',
      if (_options.useSdk) '--invoker=modular_test',
      Flags.soundNullSafety,
      '${Flags.entryUri}=$fakeRoot${module.mainSource}',
      '${Flags.inputDill}=${toUri(module, fullDillId)}',
      for (String flag in flags) '--enable-experiment=$flag',
      '${Flags.closedWorldUri}=${toUri(module, closedWorldId)}',
      '${Flags.globalInferenceUri}=${toUri(module, globalDataId)}',
      '${Flags.codegenUri}=${toUri(module, codeId.dataId)}',
      '${Flags.codegenShard}=${codeId.shard}',
      '${Flags.codegenShards}=${codeId.dataId.shards}',
      '${Flags.stage}=codegen',
    ];
    var result = await runProcess(
        Platform.resolvedExecutable, args, root.toFilePath(), _options.verbose);

    checkExitCode(result, this, module, _options.verbose);
  }

  @override
  void notifyCached(Module module) {
    if (_options.verbose) print("cached step: dart2js backend on $module");
  }
}

// Step that invokes the dart2js codegen enqueuer and emitter on the main module
// given the results of the global analysis step and codegen shards.
class Dart2jsEmissionStep extends IOModularStep {
  @override
  List<DataId> get resultData => const [jsId, dumpInfoDataId];

  @override
  bool get needsSources => false;

  @override
  List<DataId> get dependencyDataNeeded => const [];

  @override
  List<DataId> get moduleDataNeeded =>
      const [fullDillId, closedWorldId, globalDataId, codeId0, codeId1];

  @override
  bool get onlyOnMain => true;

  @override
  Future<void> execute(Module module, Uri root, ModuleDataToRelativeUri toUri,
      List<String> flags) async {
    if (_options.verbose) print("step: dart2js backend on $module");
    List<String> args = [
      '--packages=${sdkRoot.toFilePath()}/$packageConfigJsonPath',
      _dart2jsScript,
      if (_options.useSdk) '--libraries-spec=$_librarySpecForSnapshot',
      if (_options.useSdk) '--invoker=modular_test',
      Flags.soundNullSafety,
      '${Flags.entryUri}=$fakeRoot${module.mainSource}',
      '${Flags.inputDill}=${toUri(module, fullDillId)}',
      for (String flag in flags) '${Flags.enableLanguageExperiments}=$flag',
      '${Flags.closedWorldUri}=${toUri(module, closedWorldId)}',
      '${Flags.globalInferenceUri}=${toUri(module, globalDataId)}',
      '${Flags.codegenUri}=${toUri(module, codeId)}',
      '${Flags.codegenShards}=${codeId.shards}',
      '${Flags.dumpInfoDataUri}=${toUri(module, dumpInfoDataId)}',
      '${Flags.stage}=emit-js',
      '--out=${toUri(module, jsId)}',
    ];
    var result = await runProcess(
        Platform.resolvedExecutable, args, root.toFilePath(), _options.verbose);

    checkExitCode(result, this, module, _options.verbose);
  }

  @override
  void notifyCached(Module module) {
    if (_options.verbose) print("\ncached step: dart2js backend on $module");
  }
}

// Step that invokes the dart2js dump info task on the main module given the
// results of the emitted JS and serialized dump info data.
class Dart2jsDumpInfoStep extends IOModularStep {
  @override
  List<DataId> get resultData => const [dumpInfoId];

  @override
  bool get needsSources => false;

  @override
  List<DataId> get dependencyDataNeeded => const [];

  @override
  List<DataId> get moduleDataNeeded => const [
        fullDillId,
        closedWorldId,
        globalDataId,
        codeId0,
        codeId1,
        dumpInfoDataId,
      ];

  @override
  bool get onlyOnMain => true;

  @override
  Future<void> execute(Module module, Uri root, ModuleDataToRelativeUri toUri,
      List<String> flags) async {
    if (_options.verbose) print("step: dart2js dump info on $module");
    List<String> args = [
      '--packages=${sdkRoot.toFilePath()}/$packageConfigJsonPath',
      _dart2jsScript,
      if (_options.useSdk) '--libraries-spec=$_librarySpecForSnapshot',
      if (_options.useSdk) '--invoker=modular_test',
      Flags.soundNullSafety,
      '${Flags.entryUri}=$fakeRoot${module.mainSource}',
      '${Flags.inputDill}=${toUri(module, fullDillId)}',
      for (String flag in flags) '${Flags.enableLanguageExperiments}=$flag',
      '${Flags.closedWorldUri}=${toUri(module, closedWorldId)}',
      '${Flags.globalInferenceUri}=${toUri(module, globalDataId)}',
      '${Flags.codegenUri}=${toUri(module, codeId)}',
      '${Flags.codegenShards}=${codeId.shards}',
      '${Flags.dumpInfoDataUri}=${toUri(module, dumpInfoDataId)}',
      '${Flags.stage}=dump-info',
      '--out=${toUri(module, jsId)}',
    ];
    var result = await runProcess(
        Platform.resolvedExecutable, args, root.toFilePath(), _options.verbose);

    checkExitCode(result, this, module, _options.verbose);
  }

  @override
  void notifyCached(Module module) {
    if (_options.verbose) print("\ncached step: dart2js dump info on $module");
  }
}

/// Step that runs the output of dart2js in d8 and saves the output.
class RunD8 extends IOModularStep {
  @override
  List<DataId> get resultData => const [txtId];

  @override
  bool get needsSources => false;

  @override
  List<DataId> get dependencyDataNeeded => const [];

  @override
  List<DataId> get moduleDataNeeded => const [jsId];

  @override
  bool get onlyOnMain => true;

  @override
  Future<void> execute(Module module, Uri root, ModuleDataToRelativeUri toUri,
      List<String> flags) async {
    if (_options.verbose) print("\nstep: d8 on $module");
    List<String> d8Args = [
      sdkRoot
          .resolve('sdk/lib/_internal/js_runtime/lib/preambles/d8.js')
          .toFilePath(),
      root.resolveUri(toUri(module, jsId)).toFilePath(),
    ];
    var result = await runProcess(sdkRoot.resolve(_d8executable).toFilePath(),
        d8Args, root.toFilePath(), _options.verbose);

    checkExitCode(result, this, module, _options.verbose);

    await File.fromUri(root.resolveUri(toUri(module, txtId)))
        .writeAsString(result.stdout);
  }

  @override
  void notifyCached(Module module) {
    if (_options.verbose) print("\ncached step: d8 on $module");
  }
}

String get _d8executable {
  final arch = Abi.current().toString().split('_')[1];
  if (Platform.isWindows) {
    return 'third_party/d8/windows/$arch/d8.exe';
  } else if (Platform.isLinux) {
    return 'third_party/d8/linux/$arch/d8';
  } else if (Platform.isMacOS) {
    return 'third_party/d8/macos/$arch/d8';
  }
  throw UnsupportedError('Unsupported platform.');
}

class ShardsDataId implements DataId {
  @override
  final String name;
  final int shards;

  const ShardsDataId(this.name, this.shards);

  @override
  String toString() => name;
}

class ShardDataId implements DataId {
  final ShardsDataId dataId;
  final int _shard;

  const ShardDataId(this.dataId, this._shard);

  int get shard {
    assert(0 <= _shard && _shard < dataId.shards);
    return _shard;
  }

  @override
  String get name => '${dataId.name}${shard}';

  @override
  String toString() => name;
}

Future<void> resolveScripts(Options options) async {
  Future<String> resolve(
      String sourceUriOrPath, String relativeSnapshotPath) async {
    Uri sourceUri = sdkRoot.resolve(sourceUriOrPath);
    String result =
        sourceUri.isScheme('file') ? sourceUri.toFilePath() : sourceUriOrPath;
    if (_options.useSdk) {
      String snapshot = Uri.file(Platform.resolvedExecutable)
          .resolve(relativeSnapshotPath)
          .toFilePath();
      if (await File(snapshot).exists()) {
        return snapshot;
      }
    }
    return result;
  }

  _options = options;
  _dart2jsScript = await resolve(
      'package:compiler/src/dart2js.dart', 'snapshots/dart2js.dart.snapshot');
  _kernelWorkerScript = await resolve('utils/bazel/kernel_worker.dart',
      'snapshots/kernel_worker.dart.snapshot');
}

String _librarySpecForSnapshot = Uri.file(Platform.resolvedExecutable)
    .resolve('../lib/libraries.json')
    .toFilePath();
