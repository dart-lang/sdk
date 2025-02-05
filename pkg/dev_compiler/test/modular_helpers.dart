// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';
import 'dart:io';

import 'package:modular_test/src/create_package_config.dart';
import 'package:modular_test/src/io_pipeline.dart';
import 'package:modular_test/src/pipeline.dart';
import 'package:modular_test/src/runner.dart';
import 'package:modular_test/src/steps/macro_precompile_aot.dart';
import 'package:modular_test/src/steps/util.dart';
import 'package:modular_test/src/suite.dart';
import 'package:path/path.dart' as p;

String packageConfigJsonPath = '.dart_tool/package_config.json';
Uri sdkRoot = Platform.script.resolve('../../../');
Uri packageConfigUri = sdkRoot.resolve(packageConfigJsonPath);
late Options _options;
late String _dartdevcScript;
late String _kernelWorkerScript;
late String _dartExecutable;

const dillId = DataId('dill');
const jsId = DataId('js');
const txtId = DataId('txt');

class SourceToSummaryDillStep implements IOModularStep {
  bool soundNullSafety;

  SourceToSummaryDillStep({required this.soundNullSafety});

  @override
  List<DataId> get resultData => const [dillId];

  @override
  bool get needsSources => true;

  @override
  List<DataId> get dependencyDataNeeded => const [dillId, precompiledMacroId];

  @override
  List<DataId> get moduleDataNeeded => const [];

  @override
  bool get onlyOnMain => false;

  @override
  bool get onlyOnSdk => false;

  @override
  bool get notOnSdk => false;

  @override
  Future<void> execute(Module module, Uri root, ModuleDataToRelativeUri toUri,
      List<String> flags) async {
    if (_options.verbose) print('\nstep: source-to-dill on $module');

    // We use non file-URI schemes for representing source locations in a
    // root-agnostic way. This allows us to refer to file across modules and
    // across steps without exposing the underlying temporary folders that are
    // created by the framework. In build systems like bazel this is especially
    // important because each step may be run on a different machine.
    //
    // Files in packages are defined in terms of `package:` URIs, while
    // non-package URIs are defined using the `dart-dev-app` scheme.
    var rootScheme = module.isSdk ? 'dev-dart-sdk' : 'dev-dart-app';
    String sourceToImportUri(Uri relativeUri) =>
        _sourceToImportUri(module, rootScheme, relativeUri);

    var transitiveDependencies = computeTransitiveDependencies(module);
    await writePackageConfig(module, transitiveDependencies, root);

    List<String> sources;
    List<String> extraArgs;
    if (module.isSdk) {
      sources = ['dart:core'];
      extraArgs = [
        '--libraries-file',
        '$rootScheme:///sdk/lib/libraries.json',
      ];
      assert(transitiveDependencies.isEmpty);
    } else {
      sources = module.sources.map(sourceToImportUri).toList();
      extraArgs = [
        '--packages-file',
        '$rootScheme:/.dart_tool/package_config.json'
      ];
    }

    var sdkModule =
        module.isSdk ? module : module.dependencies.firstWhere((m) => m.isSdk);

    var args = [
      _kernelWorkerScript,
      '--summary-only',
      '--target',
      'ddc',
      '--multi-root',
      '$root',
      '--multi-root-scheme',
      rootScheme,
      ...extraArgs,
      if (soundNullSafety) '--sound-null-safety' else '--no-sound-null-safety',
      '--output',
      '${toUri(module, dillId)}',
      if (!module.isSdk) ...[
        '--dart-sdk-summary',
        '${toUri(sdkModule, dillId)}',
        '--exclude-non-sources',
      ],
      ...transitiveDependencies
          .where((m) => !m.isSdk)
          .expand((m) => ['--input-summary', '${toUri(m, dillId)}']),
      ...transitiveDependencies
          .where((m) => m.macroConstructors.isNotEmpty)
          .expand((m) =>
              ['--precompiled-macro', '${precompiledMacroArg(m, toUri)};']),
      ...sources.expand((String uri) => ['--source', uri]),
      ...flags.expand((String flag) => ['--enable-experiment', flag]),
    ];

    var result = await runProcess(
        _dartExecutable, args, root.toFilePath(), _options.verbose);
    checkExitCode(result, this, module, _options.verbose);
  }

  @override
  void notifyCached(Module module) {
    if (_options.verbose) print('\ncached step: source-to-dill on $module');
  }

  @override
  bool shouldExecute(Module module) => true;
}

class DDCStep implements IOModularStep {
  bool soundNullSafety;
  bool canaryFeatures;

  DDCStep({required this.soundNullSafety, required this.canaryFeatures});

  @override
  List<DataId> get resultData => const [jsId];

  @override
  bool get needsSources => true;

  @override
  List<DataId> get dependencyDataNeeded => const [dillId, precompiledMacroId];

  @override
  List<DataId> get moduleDataNeeded => const [dillId];

  @override
  bool get onlyOnMain => false;

  @override
  bool get onlyOnSdk => false;

  @override
  bool get notOnSdk => false;

  @override
  Future<void> execute(Module module, Uri root, ModuleDataToRelativeUri toUri,
      List<String> flags) async {
    if (_options.verbose) print('\nstep: ddc on $module');

    var transitiveDependencies = computeTransitiveDependencies(module);
    await writePackageConfig(module, transitiveDependencies, root);

    var rootScheme = module.isSdk ? 'dev-dart-sdk' : 'dev-dart-app';
    List<String> sources;
    List<String> extraArgs;
    if (module.isSdk) {
      sources = ['dart:core'];
      extraArgs = [
        '--compile-sdk',
        '--libraries-file',
        '$rootScheme:///sdk/lib/libraries.json',
      ];
      assert(transitiveDependencies.isEmpty);
    } else {
      var sdkModule = module.dependencies.firstWhere((m) => m.isSdk);
      sources = module.sources
          .map((relativeUri) =>
              _sourceToImportUri(module, rootScheme, relativeUri))
          .toList();
      extraArgs = [
        '--dart-sdk-summary',
        '${toUri(sdkModule, dillId)}',
        '--packages',
        '.dart_tool/package_config.json',
      ];
    }

    var output = toUri(module, jsId);

    var args = [
      '--packages=${sdkRoot.toFilePath()}/.dart_tool/package_config.json',
      _dartdevcScript,
      '--modules=es6',
      '--no-summarize',
      '--no-source-map',
      '--multi-root-scheme',
      rootScheme,
      ...sources,
      ...extraArgs,
      if (soundNullSafety) '--sound-null-safety' else '--no-sound-null-safety',
      if (canaryFeatures) '--canary',
      for (String flag in flags) '--enable-experiment=$flag',
      ...transitiveDependencies
          .where((m) => !m.isSdk)
          .expand((m) => ['-s', '${toUri(m, dillId)}=${m.name}']),
      ...transitiveDependencies
          .where((m) => m.macroConstructors.isNotEmpty)
          .expand((m) =>
              ['--precompiled-macro', '${precompiledMacroArg(m, toUri)};']),
      '-o',
      '$output',
    ];
    var result = await runProcess(
        _dartExecutable, args, root.toFilePath(), _options.verbose);
    checkExitCode(result, this, module, _options.verbose);
  }

  @override
  void notifyCached(Module module) {
    if (_options.verbose) print('\ncached step: ddc on $module');
  }

  @override
  bool shouldExecute(Module module) => true;
}

class RunD8 implements IOModularStep {
  @override
  List<DataId> get resultData => const [txtId];

  @override
  bool get needsSources => false;

  @override
  List<DataId> get dependencyDataNeeded => const [jsId];

  @override
  List<DataId> get moduleDataNeeded => const [jsId];

  @override
  bool get onlyOnMain => true;

  @override
  bool get onlyOnSdk => false;

  @override
  bool get notOnSdk => false;

  @override
  Future<void> execute(Module module, Uri root, ModuleDataToRelativeUri toUri,
      List<String> flags) async {
    if (_options.verbose) print('\nstep: d8 on $module');

    // Rename sdk.js to dart_sdk.js (the alternative, but more hermetic solution
    // would be to rename the import on all other .js files, but seems
    // overkill/unnecessary.
    if (await File.fromUri(root.resolve('dart_sdk.js')).exists()) {
      throw 'error: dart_sdk.js already exists.';
    }

    await File.fromUri(root.resolve('sdk.js'))
        .copy(root.resolve('dart_sdk.js').toFilePath());
    var runjs = '''
    import { dart, _isolate_helper } from 'dart_sdk.js';
    import { main } from 'main.js';
    _isolate_helper.startRootIsolate(() => {}, []);
    main.main();
    ''';

    var wrapper =
        '${root.resolveUri(toUri(module, jsId)).toFilePath()}.wrapper.js';
    await File(wrapper).writeAsString(runjs);
    var d8Args = ['--module', wrapper];
    var result = await runProcess(sdkRoot.resolve(_d8executable).toFilePath(),
        d8Args, root.toFilePath(), _options.verbose);

    checkExitCode(result, this, module, _options.verbose);

    await File.fromUri(root.resolveUri(toUri(module, txtId)))
        .writeAsString(result.stdout as String);
  }

  @override
  void notifyCached(Module module) {
    if (_options.verbose) print('\ncached step: d8 on $module');
  }

  @override
  bool shouldExecute(Module module) => true;
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

String _sourceToImportUri(Module module, String rootScheme, Uri relativeUri) {
  if (module.isPackage) {
    var basePath = module.packageBase!.path;
    var packageRelativePath = basePath == './'
        ? relativeUri.path
        : relativeUri.path.substring(basePath.length);
    return 'package:${module.name}/$packageRelativePath';
  } else {
    return '$rootScheme:/$relativeUri';
  }
}

Future<void> resolveScripts(Options options) async {
  _options = options;
  Future<String> resolve(
      String sdkSourcePath, String relativeSnapshotPath) async {
    var result = sdkRoot.resolve(sdkSourcePath).toFilePath();
    if (_options.useSdk) {
      var snapshot = Uri.file(Platform.resolvedExecutable)
          .resolve(relativeSnapshotPath)
          .toFilePath();
      if (await File(snapshot).exists()) {
        return snapshot;
      }
    }
    return result;
  }

  _dartdevcScript = await resolve('pkg/dev_compiler/bin/dartdevc.dart',
      'snapshots/dartdevc_aot.dart.snapshot');
  if (File(_dartdevcScript).existsSync()) {
    _kernelWorkerScript = await resolve('utils/bazel/kernel_worker.dart',
        'snapshots/kernel_worker_aot.dart.snapshot');
    var sdkPath = p.dirname(p.dirname(Platform.resolvedExecutable));
    _dartExecutable = p.absolute(
      sdkPath,
      'bin',
      Platform.isWindows ? 'dartaotruntime.exe' : 'dartaotruntime',
    );
  } else {
    // This can be removed once we stop supporting ia32 architecture.
    _dartdevcScript = await resolve('pkg/dev_compiler/bin/dartdevc.dart',
        'snapshots/dartdevc.dart.snapshot');
    _kernelWorkerScript = await resolve('utils/bazel/kernel_worker.dart',
        'snapshots/kernel_worker.dart.snapshot');
    _dartExecutable = Platform.resolvedExecutable;
  }
}
