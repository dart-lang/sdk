// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test the modular compilation pipeline of dart2js.
///
/// This is a shell that runs multiple tests, one per folder under `data/`.
import 'dart:io';
import 'dart:async';

import 'package:compiler/src/commandline_options.dart';
import 'package:front_end/src/compute_platform_binaries_location.dart'
    show computePlatformBinariesLocation;
import 'package:modular_test/src/io_pipeline.dart';
import 'package:modular_test/src/pipeline.dart';
import 'package:modular_test/src/suite.dart';
import 'package:modular_test/src/runner.dart';
import 'package:package_config/package_config.dart';

String packageConfigJsonPath = ".dart_tool/package_config.json";
Uri sdkRoot = Platform.script.resolve("../../../");
Uri packageConfigUri = sdkRoot.resolve(packageConfigJsonPath);
Options _options;
String _dart2jsScript;
String _kernelWorkerScript;

// TODO(joshualitt): Figure out a way to support package configs in
// tests/modular.
PackageConfig _packageConfig;
main(List<String> args) async {
  _options = Options.parse(args);
  _packageConfig = await loadPackageConfigUri(packageConfigUri);
  await _resolveScripts();
  await Future.wait([
    runSuite(
        sdkRoot.resolve('tests/modular/'),
        'tests/modular',
        _options,
        new IOPipeline([
          SourceToDillStep(),
          ComputeClosedWorldStep(),
          GlobalAnalysisStep(),
          Dart2jsCodegenStep(codeId0),
          Dart2jsCodegenStep(codeId1),
          Dart2jsEmissionStep(),
          RunD8(),
        ], cacheSharedModules: true)),
    // TODO(joshualitt) Delete this when we stop supporting this way of running
    // the compiler.
    runSuite(
        sdkRoot.resolve('tests/modular/'),
        'tests/modular',
        _options,
        new IOPipeline([
          SourceToDillStep(),
          ComputeClosedWorldStep(),
          GlobalAnalysisStep(),
          LegacyDart2jsCodegenStep(codeId0),
          LegacyDart2jsCodegenStep(codeId1),
          LegacyDart2jsEmissionStep(),
          RunD8(),
        ], cacheSharedModules: true)),
  ]);
}

const dillId = const DataId("dill");
const updatedDillId = const DataId("udill");
const closedWorldId = const DataId("world");
const globalDataId = const DataId("gdata");
const codeId = const ShardsDataId("code", 2);
const codeId0 = const ShardDataId(codeId, 0);
const codeId1 = const ShardDataId(codeId, 1);
const jsId = const DataId("js");
const txtId = const DataId("txt");

String _packageConfigEntry(String name, Uri root,
    {Uri packageRoot, LanguageVersion version}) {
  var fields = [
    '"name": "${name}"',
    '"rootUri": "$root"',
    if (packageRoot != null) '"packageUri": "$packageRoot"',
    if (version != null) '"languageVersion": "$version"'
  ];
  return '{${fields.join(',')}}';
}

// Step that compiles sources in a module to a .dill file.
class SourceToDillStep implements IOModularStep {
  @override
  List<DataId> get resultData => const [dillId];

  @override
  bool get needsSources => true;

  @override
  List<DataId> get dependencyDataNeeded => const [dillId];

  @override
  List<DataId> get moduleDataNeeded => const [];

  @override
  bool get onlyOnMain => false;

  @override
  Future<void> execute(Module module, Uri root, ModuleDataToRelativeUri toUri,
      List<String> flags) async {
    if (_options.verbose) print("\nstep: source-to-dill on $module");

    // We use non file-URI schemes for representeing source locations in a
    // root-agnostic way. This allows us to refer to file across modules and
    // across steps without exposing the underlying temporary folders that are
    // created by the framework. In build systems like bazel this is especially
    // important because each step may be run on a different machine.
    //
    // Files in packages are defined in terms of `package:` URIs, while
    // non-package URIs are defined using the `dart-dev-app` scheme.
    String rootScheme = module.isSdk ? 'dart-dev-sdk' : 'dev-dart-app';
    String sourceToImportUri(Uri relativeUri) {
      if (module.isPackage) {
        var basePath = module.packageBase.path;
        var packageRelativePath = basePath == "./"
            ? relativeUri.path
            : relativeUri.path.substring(basePath.length);
        return 'package:${module.name}/$packageRelativePath';
      } else {
        return '$rootScheme:/$relativeUri';
      }
    }

    // We create both a .packages and package_config.json file which defines
    // the location of this module if it is a package.  The CFE requires that
    // if a `package:` URI of a dependency is used in an import, then we need
    // that package entry in the associated file. However, after it checks that
    // the definition exists, the CFE will not actually use the resolved URI if
    // a library for the import URI is already found in one of the provide
    // .dill files of the dependencies. For that reason, and to ensure that
    // a step only has access to the files provided in a module, we generate a
    // config file with invalid folders for other packages.
    // TODO(sigmund): follow up with the CFE to see if we can remove the need
    // for these dummy entries..
    // TODO(joshualitt): Generate just the json file.
    var packagesJson = [];
    var packagesContents = new StringBuffer();
    if (module.isPackage) {
      packagesContents.write('${module.name}:${module.packageBase}\n');
      packagesJson.add(_packageConfigEntry(
          module.name, Uri.parse('../${module.packageBase}')));
    }

    Set<Module> transitiveDependencies = computeTransitiveDependencies(module);
    int unusedNum = 0;
    for (Module dependency in transitiveDependencies) {
      if (dependency.isPackage) {
        // rootUri should be ignored for dependent modules, so we pass in a
        // bogus value.
        var rootUri = Uri.parse('unused$unusedNum');
        unusedNum++;

        var dependentPackage = _packageConfig[dependency.name];
        var packageJson = dependentPackage == null
            ? _packageConfigEntry(dependency.name, rootUri)
            : _packageConfigEntry(dependentPackage.name, rootUri,
                version: dependentPackage.languageVersion);
        packagesJson.add(packageJson);
        packagesContents.write('${dependency.name}:$rootUri\n');
      }
    }

    if (module.isPackage) {
      await File.fromUri(root.resolve(packageConfigJsonPath))
          .create(recursive: true);
      await File.fromUri(root.resolve(packageConfigJsonPath)).writeAsString('{'
          '  "configVersion": ${_packageConfig.version},'
          '  "packages": [ ${packagesJson.join(',')} ]'
          '}');
    }

    await File.fromUri(root.resolve('.packages'))
        .writeAsString('$packagesContents');

    List<String> sources;
    List<String> extraArgs;
    if (module.isSdk) {
      // When no flags are passed, we can skip compilation and reuse the
      // platform.dill created by build.py.
      if (flags.isEmpty) {
        var platform =
            computePlatformBinariesLocation().resolve("dart2js_platform.dill");
        var destination = root.resolveUri(toUri(module, dillId));
        if (_options.verbose) {
          print('command:\ncp $platform $destination');
        }
        await File.fromUri(platform).copy(destination.toFilePath());
        return;
      }
      sources = ['dart:core'];
      extraArgs = ['--libraries-file', '$rootScheme:///sdk/lib/libraries.json'];
      assert(transitiveDependencies.isEmpty);
    } else {
      sources = module.sources.map(sourceToImportUri).toList();
      extraArgs = ['--packages-file', '$rootScheme:/.packages'];
    }

    // TODO(joshualitt): Ensure the kernel worker has some way to specify
    // --no-sound-null-safety
    List<String> args = [
      _kernelWorkerScript,
      '--no-summary-only',
      '--target',
      'dart2js',
      '--multi-root',
      '$root',
      '--multi-root-scheme',
      rootScheme,
      ...extraArgs,
      '--output',
      '${toUri(module, dillId)}',
      ...(transitiveDependencies
          .expand((m) => ['--input-linked', '${toUri(m, dillId)}'])),
      ...(sources.expand((String uri) => ['--source', uri])),
      ...(flags.expand((String flag) => ['--enable-experiment', flag])),
      '--enable-experiment=non-nullable',
    ];

    var result =
        await _runProcess(Platform.resolvedExecutable, args, root.toFilePath());
    _checkExitCode(result, this, module);
  }

  @override
  void notifyCached(Module module) {
    if (_options.verbose) print("\ncached step: source-to-dill on $module");
  }
}

// Step that invokes the dart2js closed world computation.
class ComputeClosedWorldStep implements IOModularStep {
  @override
  List<DataId> get resultData => const [closedWorldId, updatedDillId];

  @override
  bool get needsSources => false;

  @override
  List<DataId> get dependencyDataNeeded => const [dillId];

  @override
  List<DataId> get moduleDataNeeded => const [dillId];

  @override
  bool get onlyOnMain => true;

  @override
  Future<void> execute(Module module, Uri root, ModuleDataToRelativeUri toUri,
      List<String> flags) async {
    if (_options.verbose)
      print("\nstep: dart2js compute closed world on $module");
    Set<Module> transitiveDependencies = computeTransitiveDependencies(module);
    Iterable<String> dillDependencies =
        transitiveDependencies.map((m) => '${toUri(m, dillId)}');
    List<String> args = [
      '--packages=${sdkRoot.toFilePath()}/.packages',
      _dart2jsScript,
      // TODO(sigmund): remove this dependency on libraries.json
      if (_options.useSdk) '--libraries-spec=$_librarySpecForSnapshot',
      '${toUri(module, dillId)}',
      for (String flag in flags) '--enable-experiment=$flag',
      '${Flags.dillDependencies}=${dillDependencies.join(',')}',
      '${Flags.writeClosedWorld}=${toUri(module, closedWorldId)}',
      '--out=${toUri(module, updatedDillId)}',
    ];
    var result =
        await _runProcess(Platform.resolvedExecutable, args, root.toFilePath());

    _checkExitCode(result, this, module);
  }

  @override
  void notifyCached(Module module) {
    if (_options.verbose)
      print("\ncached step: dart2js compute closed world on $module");
  }
}

// Step that invokes the dart2js global analysis on the main module by providing
// the .dill files of all transitive modules as inputs.
class GlobalAnalysisStep implements IOModularStep {
  @override
  List<DataId> get resultData => const [globalDataId];

  @override
  bool get needsSources => false;

  @override
  List<DataId> get dependencyDataNeeded => const [updatedDillId];

  @override
  List<DataId> get moduleDataNeeded => const [closedWorldId, updatedDillId];

  @override
  bool get onlyOnMain => true;

  @override
  Future<void> execute(Module module, Uri root, ModuleDataToRelativeUri toUri,
      List<String> flags) async {
    if (_options.verbose) print("\nstep: dart2js global analysis on $module");
    List<String> args = [
      '--packages=${sdkRoot.toFilePath()}/.packages',
      _dart2jsScript,
      // TODO(sigmund): remove this dependency on libraries.json
      if (_options.useSdk) '--libraries-spec=$_librarySpecForSnapshot',
      '${toUri(module, updatedDillId)}',
      for (String flag in flags) '--enable-experiment=$flag',
      '${Flags.readClosedWorld}=${toUri(module, closedWorldId)}',
      '${Flags.writeData}=${toUri(module, globalDataId)}',
    ];
    var result =
        await _runProcess(Platform.resolvedExecutable, args, root.toFilePath());

    _checkExitCode(result, this, module);
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
class Dart2jsCodegenStep implements IOModularStep {
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
      const [updatedDillId, closedWorldId, globalDataId];

  @override
  bool get onlyOnMain => true;

  @override
  Future<void> execute(Module module, Uri root, ModuleDataToRelativeUri toUri,
      List<String> flags) async {
    if (_options.verbose) print("\nstep: dart2js backend on $module");
    List<String> args = [
      '--packages=${sdkRoot.toFilePath()}/.packages',
      _dart2jsScript,
      if (_options.useSdk) '--libraries-spec=$_librarySpecForSnapshot',
      '${toUri(module, updatedDillId)}',
      for (String flag in flags) '--enable-experiment=$flag',
      '${Flags.readClosedWorld}=${toUri(module, closedWorldId)}',
      '${Flags.readData}=${toUri(module, globalDataId)}',
      '${Flags.writeCodegen}=${toUri(module, codeId.dataId)}',
      '${Flags.codegenShard}=${codeId.shard}',
      '${Flags.codegenShards}=${codeId.dataId.shards}',
    ];
    var result =
        await _runProcess(Platform.resolvedExecutable, args, root.toFilePath());

    _checkExitCode(result, this, module);
  }

  @override
  void notifyCached(Module module) {
    if (_options.verbose) print("cached step: dart2js backend on $module");
  }
}

// Step that invokes the dart2js codegen enqueuer and emitter on the main module
// given the results of the global analysis step and codegen shards.
class Dart2jsEmissionStep implements IOModularStep {
  @override
  List<DataId> get resultData => const [jsId];

  @override
  bool get needsSources => false;

  @override
  List<DataId> get dependencyDataNeeded => const [];

  @override
  List<DataId> get moduleDataNeeded =>
      const [updatedDillId, closedWorldId, globalDataId, codeId0, codeId1];

  @override
  bool get onlyOnMain => true;

  @override
  Future<void> execute(Module module, Uri root, ModuleDataToRelativeUri toUri,
      List<String> flags) async {
    if (_options.verbose) print("step: dart2js backend on $module");
    List<String> args = [
      '--packages=${sdkRoot.toFilePath()}/.packages',
      _dart2jsScript,
      if (_options.useSdk) '--libraries-spec=$_librarySpecForSnapshot',
      '${toUri(module, updatedDillId)}',
      for (String flag in flags) '${Flags.enableLanguageExperiments}=$flag',
      '${Flags.readClosedWorld}=${toUri(module, closedWorldId)}',
      '${Flags.readData}=${toUri(module, globalDataId)}',
      '${Flags.readCodegen}=${toUri(module, codeId)}',
      '${Flags.codegenShards}=${codeId.shards}',
      '--out=${toUri(module, jsId)}',
    ];
    var result =
        await _runProcess(Platform.resolvedExecutable, args, root.toFilePath());

    _checkExitCode(result, this, module);
  }

  @override
  void notifyCached(Module module) {
    if (_options.verbose) print("\ncached step: dart2js backend on $module");
  }
}

// Step that invokes the dart2js code generation on the main module given the
// results of the global analysis step and produces one shard of the codegen
// output.
// Note: Legacy.
class LegacyDart2jsCodegenStep implements IOModularStep {
  final ShardDataId codeId;

  LegacyDart2jsCodegenStep(this.codeId);

  @override
  List<DataId> get resultData => [codeId];

  @override
  bool get needsSources => false;

  @override
  List<DataId> get dependencyDataNeeded => const [];

  @override
  List<DataId> get moduleDataNeeded => const [updatedDillId, globalDataId];

  @override
  bool get onlyOnMain => true;

  @override
  Future<void> execute(Module module, Uri root, ModuleDataToRelativeUri toUri,
      List<String> flags) async {
    if (_options.verbose) print("\nstep: dart2js backend on $module");
    List<String> args = [
      '--packages=${sdkRoot.toFilePath()}/.packages',
      _dart2jsScript,
      if (_options.useSdk) '--libraries-spec=$_librarySpecForSnapshot',
      '${toUri(module, updatedDillId)}',
      for (String flag in flags) '--enable-experiment=$flag',
      '${Flags.readData}=${toUri(module, globalDataId)}',
      '${Flags.writeCodegen}=${toUri(module, codeId.dataId)}',
      '${Flags.codegenShard}=${codeId.shard}',
      '${Flags.codegenShards}=${codeId.dataId.shards}',
    ];
    var result =
        await _runProcess(Platform.resolvedExecutable, args, root.toFilePath());

    _checkExitCode(result, this, module);
  }

  @override
  void notifyCached(Module module) {
    if (_options.verbose) print("cached step: dart2js backend on $module");
  }
}

// Step that invokes the dart2js codegen enqueuer and emitter on the main module
// given the results of the global analysis step and codegen shards.
// Note: Legacy.
class LegacyDart2jsEmissionStep implements IOModularStep {
  @override
  List<DataId> get resultData => const [jsId];

  @override
  bool get needsSources => false;

  @override
  List<DataId> get dependencyDataNeeded => const [];

  @override
  List<DataId> get moduleDataNeeded =>
      const [updatedDillId, globalDataId, codeId0, codeId1];

  @override
  bool get onlyOnMain => true;

  @override
  Future<void> execute(Module module, Uri root, ModuleDataToRelativeUri toUri,
      List<String> flags) async {
    if (_options.verbose) print("step: dart2js backend on $module");
    List<String> args = [
      '--packages=${sdkRoot.toFilePath()}/.packages',
      _dart2jsScript,
      if (_options.useSdk) '--libraries-spec=$_librarySpecForSnapshot',
      '${toUri(module, updatedDillId)}',
      for (String flag in flags) '${Flags.enableLanguageExperiments}=$flag',
      '${Flags.readData}=${toUri(module, globalDataId)}',
      '${Flags.readCodegen}=${toUri(module, codeId)}',
      '${Flags.codegenShards}=${codeId.shards}',
      '--out=${toUri(module, jsId)}',
    ];
    var result =
        await _runProcess(Platform.resolvedExecutable, args, root.toFilePath());

    _checkExitCode(result, this, module);
  }

  @override
  void notifyCached(Module module) {
    if (_options.verbose) print("\ncached step: dart2js backend on $module");
  }
}

/// Step that runs the output of dart2js in d8 and saves the output.
class RunD8 implements IOModularStep {
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
    var result = await _runProcess(
        sdkRoot.resolve(_d8executable).toFilePath(), d8Args, root.toFilePath());

    _checkExitCode(result, this, module);

    await File.fromUri(root.resolveUri(toUri(module, txtId)))
        .writeAsString(result.stdout);
  }

  @override
  void notifyCached(Module module) {
    if (_options.verbose) print("\ncached step: d8 on $module");
  }
}

void _checkExitCode(ProcessResult result, IOModularStep step, Module module) {
  if (result.exitCode != 0 || _options.verbose) {
    stdout.write(result.stdout);
    stderr.write(result.stderr);
  }
  if (result.exitCode != 0) {
    throw "${step.runtimeType} failed on $module:\n\n"
        "stdout:\n${result.stdout}\n\n"
        "stderr:\n${result.stderr}";
  }
}

Future<ProcessResult> _runProcess(
    String command, List<String> arguments, String workingDirectory) {
  if (_options.verbose) {
    print('command:\n$command ${arguments.join(' ')} from $workingDirectory');
  }
  return Process.run(command, arguments, workingDirectory: workingDirectory);
}

String get _d8executable {
  if (Platform.isWindows) {
    return 'third_party/d8/windows/d8.exe';
  } else if (Platform.isLinux) {
    return 'third_party/d8/linux/d8';
  } else if (Platform.isMacOS) {
    return 'third_party/d8/macos/d8';
  }
  throw new UnsupportedError('Unsupported platform.');
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

Future<void> _resolveScripts() async {
  Future<String> resolve(
      String sourceUriOrPath, String relativeSnapshotPath) async {
    Uri sourceUri = sdkRoot.resolve(sourceUriOrPath);
    String result =
        sourceUri.scheme == 'file' ? sourceUri.toFilePath() : sourceUriOrPath;
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

  _dart2jsScript = await resolve(
      'package:compiler/src/dart2js.dart', 'snapshots/dart2js.dart.snapshot');
  _kernelWorkerScript = await resolve('utils/bazel/kernel_worker.dart',
      'snapshots/kernel_worker.dart.snapshot');
}

String _librarySpecForSnapshot = Uri.file(Platform.resolvedExecutable)
    .resolve('../lib/libraries.json')
    .toFilePath();
