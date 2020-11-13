// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

/// Test the modular compilation pipeline of ddc.
///
/// This is a shell that runs multiple tests, one per folder under `data/`.
import 'dart:io';

import 'package:modular_test/src/io_pipeline.dart';
import 'package:modular_test/src/pipeline.dart';
import 'package:modular_test/src/suite.dart';
import 'package:modular_test/src/runner.dart';
import 'package:package_config/package_config.dart';

String packageConfigJsonPath = '.dart_tool/package_config.json';
Uri sdkRoot = Platform.script.resolve('../../../');
Uri packageConfigUri = sdkRoot.resolve(packageConfigJsonPath);
Options _options;
String _dartdevcScript;
String _kernelWorkerScript;

// TODO(joshualitt): Figure out a way to support package configs in
// tests/modular.
PackageConfig _packageConfig;

void main(List<String> args) async {
  _options = Options.parse(args);
  _packageConfig = await loadPackageConfigUri(packageConfigUri);
  await _resolveScripts();
  await runSuite(
      sdkRoot.resolve('tests/modular/'),
      'tests/modular',
      _options,
      IOPipeline([
        SourceToSummaryDillStep(),
        DDCStep(),
        RunD8(),
      ], cacheSharedModules: true));
}

const dillId = DataId('dill');
const jsId = DataId('js');
const txtId = DataId('txt');

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

class SourceToSummaryDillStep implements IOModularStep {
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
    await _createPackagesFile(module, root, transitiveDependencies);

    List<String> sources;
    List<String> extraArgs;
    if (module.isSdk) {
      sources = ['dart:core'];
      extraArgs = [
        '--libraries-file',
        '$rootScheme:///sdk/lib/libraries.json',
        '--enable-experiment',
        'non-nullable',
      ];
      assert(transitiveDependencies.isEmpty);
    } else {
      sources = module.sources.map(sourceToImportUri).toList();
      extraArgs = ['--packages-file', '$rootScheme:/.packages'];
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
      '--output',
      '${toUri(module, dillId)}',
      if (!module.isSdk) ...[
        '--dart-sdk-summary',
        '${toUri(sdkModule, dillId)}',
        '--exclude-non-sources',
      ],
      ...(transitiveDependencies
          .where((m) => !m.isSdk)
          .expand((m) => ['--input-summary', '${toUri(m, dillId)}'])),
      ...(sources.expand((String uri) => ['--source', uri])),
      ...(flags.expand((String flag) => ['--enable-experiment', flag])),
    ];

    var result =
        await _runProcess(Platform.resolvedExecutable, args, root.toFilePath());
    _checkExitCode(result, this, module);
  }

  @override
  void notifyCached(Module module) {
    if (_options.verbose) print('\ncached step: source-to-dill on $module');
  }
}

class DDCStep implements IOModularStep {
  @override
  List<DataId> get resultData => const [jsId];

  @override
  bool get needsSources => true;

  @override
  List<DataId> get dependencyDataNeeded => const [dillId];

  @override
  List<DataId> get moduleDataNeeded => const [dillId];

  @override
  bool get onlyOnMain => false;

  @override
  Future<void> execute(Module module, Uri root, ModuleDataToRelativeUri toUri,
      List<String> flags) async {
    if (_options.verbose) print('\nstep: ddc on $module');

    var transitiveDependencies = computeTransitiveDependencies(module);
    await _createPackagesFile(module, root, transitiveDependencies);

    var rootScheme = module.isSdk ? 'dev-dart-sdk' : 'dev-dart-app';
    List<String> sources;
    List<String> extraArgs;
    if (module.isSdk) {
      sources = ['dart:core'];
      extraArgs = [
        '--compile-sdk',
        '--libraries-file',
        '$rootScheme:///sdk/lib/libraries.json',
        '--enable-experiment',
        'non-nullable',
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
        '.packages',
      ];
    }

    var output = toUri(module, jsId);

    var args = [
      '--packages=${sdkRoot.toFilePath()}/.packages',
      _dartdevcScript,
      '--kernel',
      '--modules=es6',
      '--no-summarize',
      '--no-source-map',
      '--multi-root-scheme',
      rootScheme,
      ...sources,
      ...extraArgs,
      for (String flag in flags) '--enable-experiment=$flag',
      ...(transitiveDependencies
          .where((m) => !m.isSdk)
          .expand((m) => ['-s', '${toUri(m, dillId)}=${m.name}'])),
      '-o',
      '$output',
    ];
    var result =
        await _runProcess(Platform.resolvedExecutable, args, root.toFilePath());
    _checkExitCode(result, this, module);
  }

  @override
  void notifyCached(Module module) {
    if (_options.verbose) print('\ncached step: ddc on $module');
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
        root.resolveUri(toUri(module, jsId)).toFilePath() + '.wrapper.js';
    await File(wrapper).writeAsString(runjs);
    var d8Args = ['--module', wrapper];
    var result = await _runProcess(
        sdkRoot.resolve(_d8executable).toFilePath(), d8Args, root.toFilePath());

    _checkExitCode(result, this, module);

    await File.fromUri(root.resolveUri(toUri(module, txtId)))
        .writeAsString(result.stdout as String);
  }

  @override
  void notifyCached(Module module) {
    if (_options.verbose) print('\ncached step: d8 on $module');
  }
}

void _checkExitCode(ProcessResult result, IOModularStep step, Module module) {
  if (result.exitCode != 0 || _options.verbose) {
    stdout.write(result.stdout);
    stderr.write(result.stderr);
  }
  if (result.exitCode != 0) {
    throw '${step.runtimeType} failed on $module:\n\n'
        'stdout:\n${result.stdout}\n\n'
        'stderr:\n${result.stderr}';
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
  var packagesContents = StringBuffer();
  if (module.isPackage) {
    packagesContents.write('${module.name}:${module.packageBase}\n');
    packagesJson.add(_packageConfigEntry(
        module.name, Uri.parse('../${module.packageBase}')));
  }
  var unusedNum = 0;
  for (var dependency in transitiveDependencies) {
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
}

String _sourceToImportUri(Module module, String rootScheme, Uri relativeUri) {
  if (module.isPackage) {
    var basePath = module.packageBase.path;
    var packageRelativePath = basePath == './'
        ? relativeUri.path
        : relativeUri.path.substring(basePath.length);
    return 'package:${module.name}/$packageRelativePath';
  } else {
    return '$rootScheme:/$relativeUri';
  }
}

Future<void> _resolveScripts() async {
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

  _dartdevcScript = await resolve(
      'pkg/dev_compiler/bin/dartdevc.dart', 'snapshots/dartdevc.dart.snapshot');
  _kernelWorkerScript = await resolve('utils/bazel/kernel_worker.dart',
      'snapshots/kernel_worker.dart.snapshot');
}
