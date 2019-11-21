// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test the modular compilation pipeline of ddc.
///
/// This is a shell that runs multiple tests, one per folder under `data/`.
import 'dart:io';

import 'package:modular_test/src/io_pipeline.dart';
import 'package:modular_test/src/pipeline.dart';
import 'package:modular_test/src/suite.dart';
import 'package:modular_test/src/runner.dart';

// TODO(vsm): Hack until we have either:
// (1) an NNBD version of the below
// (2) the ability to compile the primary version with NNBD
List<String> _nnbdOptOut = ['sdk'];
String _test_package = 'ddc_modular_test';

Uri sdkRoot = Platform.script.resolve("../../../");
Options _options;
String _dartdevcScript;
String _buildSdkScript;
String _patchSdkScript;
String _sdkDevRuntime;
String _sdkDevRuntimeNnbd;

main(List<String> args) async {
  _options = Options.parse(args);
  await _resolveScripts();
  await runSuite(
      sdkRoot.resolve('tests/modular/'),
      'tests/modular',
      _options,
      IOPipeline([
        DDCStep(),
        RunD8(),
      ], cacheSharedModules: true));

  // DDC only test suite.
  await runSuite(
      sdkRoot.resolve('tests/compiler/dartdevc/modular/'),
      'tests/compiler/dartdevc/modular',
      _options,
      IOPipeline([
        DDCStep(),
        RunD8(),
      ], cacheSharedModules: true));
}

const sumId = DataId("sum");
const jsId = DataId("js");
const txtId = DataId("txt");

class DDCStep implements IOModularStep {
  @override
  List<DataId> get resultData => const [sumId, jsId];

  @override
  bool get needsSources => true;

  @override
  List<DataId> get dependencyDataNeeded => const [sumId];

  @override
  List<DataId> get moduleDataNeeded => const [];

  @override
  bool get onlyOnMain => false;

  @override
  Future<void> execute(Module module, Uri root, ModuleDataToRelativeUri toUri,
      List<String> flags) async {
    if (_options.verbose) print("\nstep: ddc on $module");

    Set<Module> transitiveDependencies = computeTransitiveDependencies(module);
    await _createPackagesFile(module, root, transitiveDependencies);

    ProcessResult result;

    bool nnbd = flags.contains('non-nullable');
    bool allowErrors = nnbd && _nnbdOptOut.contains(module.name);

    if (module.isSdk) {
      assert(transitiveDependencies.isEmpty);

      // Apply patches.
      result = await _runProcess(
          Platform.resolvedExecutable,
          [
            _patchSdkScript,
            sdkRoot.toFilePath(),
            if (nnbd) _sdkDevRuntimeNnbd else _sdkDevRuntime,
            'patched_sdk',
            if (nnbd) 'sdk_nnbd'
          ],
          root.toFilePath());
      _checkExitCode(result, this, module);

      // Build the SDK.
      result = await _runProcess(
          Platform.resolvedExecutable,
          [
            _buildSdkScript,
            '--dart-sdk',
            'patched_sdk',
            '--dart-sdk-summary=build',
            '--summary-out',
            '${toUri(module, sumId)}',
            '--modules=es6',
            if (allowErrors) '--unsafe-force-compile',
            for (String flag in flags) '--enable-experiment=$flag',
            '-o',
            '${toUri(module, jsId)}',
          ],
          root.toFilePath());
      _checkExitCode(result, this, module);
    } else {
      Module sdkModule = module.dependencies.firstWhere((m) => m.isSdk);
      List<String> sources = module.sources
          .map((relativeUri) => _sourceToImportUri(module, relativeUri))
          .toList();
      Map<String, String> _urlMappings = {};
      if (!module.isPackage) {
        for (var source in module.sources) {
          var importUri = _sourceToImportUri(module, source);
          _urlMappings[importUri] = '$source';
        }
      }
      for (var dependency in transitiveDependencies) {
        if (!dependency.isPackage && !dependency.isSdk) {
          for (var source in dependency.sources) {
            var importUri = _sourceToImportUri(dependency, source);
            _urlMappings[importUri] = '$source';
          }
        }
      }
      var extraArgs = [
        '--dart-sdk-summary',
        '${toUri(sdkModule, sumId)}',
        '--packages',
        '.packages',
      ];

      Uri output = toUri(module, jsId);

      List<String> args = [
        '--packages=${sdkRoot.toFilePath()}.packages',
        _dartdevcScript,
        '--modules=es6',
        '--summarize',
        '--no-source-map',
        ...sources,
        if (_urlMappings.isNotEmpty)
          '--url-mapping=${_urlMappings.entries.map((entry) => '${entry.key},${entry.value}').join(',')}',
        ...extraArgs,
        for (String flag in flags) '--enable-experiment=$flag',
        ...(transitiveDependencies
            .where((m) => !m.isSdk)
            .expand((m) => ['-s', '${toUri(m, sumId)}'])),
        '-o',
        '$output',
      ];
      result = await _runProcess(
          Platform.resolvedExecutable, args, root.toFilePath());
      _checkExitCode(result, this, module);
    }
  }

  @override
  void notifyCached(Module module) {
    if (_options.verbose) print("\ncached step: ddc on $module");
  }
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
  Future<void> execute(Module module, Uri root, ModuleDataToRelativeUri toUri,
      List<String> flags) async {
    if (_options.verbose) print("\nstep: d8 on $module");

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
        root.resolveUri(toUri(module, jsId)).toFilePath() + ".wrapper.js";
    await File(wrapper).writeAsString(runjs);
    List<String> d8Args = ['--module', wrapper];
    var result = await _runProcess(
        sdkRoot.resolve(_d8executable).toFilePath(), d8Args, root.toFilePath());

    _checkExitCode(result, this, module);

    await File.fromUri(root.resolveUri(toUri(module, txtId)))
        .writeAsString(result.stdout as String);
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
  throw UnsupportedError('Unsupported platform.');
}

Future<void> _createPackagesFile(
    Module module, Uri root, Set<Module> transitiveDependencies) async {
  // We create a .packages file which defines the location of this module if
  // it is a package.  The CFE requires that if a `package:` URI of a
  // dependency is used in an import, then we need that package entry in the
  // .packages file. However, after it checks that the definition exists, the
  // CFE will not actually use the resolved URI if a library for the import
  // URI is already found in one of the provided .dill files of the
  // dependencies. For that reason, and to ensure that a step only has access
  // to the files provided in a module, we generate a .packages with invalid
  // folders for other packages.
  // TODO(sigmund): follow up with the CFE to see if we can remove the need
  // for the .packages entry altogether if they won't need to read the
  // sources.
  var packagesContents = StringBuffer();
  if (module.isPackage) {
    packagesContents.write('${module.name}:${module.packageBase}\n');
  }
  for (Module dependency in transitiveDependencies) {
    if (dependency.isPackage) {
      packagesContents.write('${dependency.name}:unused\n');
    }
  }

  await File.fromUri(root.resolve('.packages'))
      .writeAsString('$packagesContents');
}

String _sourceToImportUri(Module module, Uri relativeUri) {
  if (module.isPackage) {
    var basePath = module.packageBase.path;
    var packageRelativePath = basePath == "./"
        ? relativeUri.path
        : relativeUri.path.substring(basePath.length);
    return 'package:${module.name}/$packageRelativePath';
  } else {
    return 'package:${_test_package}/$relativeUri';
  }
}

Future<void> _resolveScripts() async {
  Future<String> resolve(String sdkSourcePath,
      [String relativeSnapshotPath]) async {
    String result = sdkRoot.resolve(sdkSourcePath).toFilePath();
    if (_options.useSdk && relativeSnapshotPath != null) {
      String snapshot = Uri.file(Platform.resolvedExecutable)
          .resolve(relativeSnapshotPath)
          .toFilePath();
      if (await File(snapshot).exists()) {
        return snapshot;
      }
    }
    return result;
  }

  _dartdevcScript = await resolve(
      'pkg/dev_compiler/bin/dartdevc.dart', 'snapshots/dartdevc.dart.snapshot');
  _buildSdkScript = await resolve('pkg/dev_compiler/tool/build_sdk.dart');
  _patchSdkScript = await resolve('pkg/dev_compiler/tool/patch_sdk.dart');
  _sdkDevRuntime = await resolve('sdk/lib/_internal/js_dev_runtime');
  _sdkDevRuntimeNnbd = await resolve('sdk_nnbd/lib/_internal/js_dev_runtime');
}
