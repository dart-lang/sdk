// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

// ignore: implementation_imports
import 'package:macros/src/bootstrap.dart';
// ignore: implementation_imports
import 'package:macros/src/executor/serialization.dart';

import 'util.dart';
import '../create_package_config.dart';
import '../io_pipeline.dart';
import '../pipeline.dart';
import '../suite.dart';

const precompiledMacroId = DataId('macro.exe');

/// Bootstraps a macro program and compiles it to an AOT executable.
class PrecompileMacroAotStep implements IOModularStep {
  final bool verbose;

  PrecompileMacroAotStep({required this.verbose});

  @override
  List<DataId> get resultData => const [precompiledMacroId];

  @override
  bool get needsSources => true;

  @override
  List<DataId> get dependencyDataNeeded => const [];

  @override
  List<DataId> get moduleDataNeeded => const [];

  @override
  bool get onlyOnMain => false;

  @override
  bool get onlyOnSdk => false;

  @override
  bool get notOnSdk => true;

  @override
  Future<void> execute(Module module, Uri root, ModuleDataToRelativeUri toUri,
      List<String> flags) async {
    if (verbose) {
      print('\nstep: precompile-macro-aot on $module');
    }

    var transitiveDependencies = computeTransitiveDependencies(module);
    var packageConfigUri = await writePackageConfig(
        module, transitiveDependencies, root,
        useRealPaths: true);

    var bootstrapContent = bootstrapMacroIsolate(
            module.macroConstructors, SerializationMode.byteData)
        // TODO: Don't do this https://github.com/dart-lang/sdk/issues/55388
        .replaceFirst('dev-dart-app:/', '');
    var bootstrapFile = File.fromUri(
        root.replace(path: '${root.path}/${module.name}.macro.bootstrap.dart'));
    await bootstrapFile.create(recursive: true);
    await bootstrapFile.writeAsString(bootstrapContent);

    var args = [
      'compile',
      'exe',
      '--packages',
      packageConfigUri.toFilePath(),
      '--output',
      '${toUri(module, precompiledMacroId)}',
      ...flags.expand((String flag) => ['--enable-experiment', flag]),
      bootstrapFile.path,
    ];

    var result = await runProcess(
        Platform.resolvedExecutable, args, root.toFilePath(), verbose);
    checkExitCode(result, this, module, verbose);
  }

  @override
  void notifyCached(Module module) {
    if (verbose) {
      print('\ncached step: precompile-macro-aot on $module');
    }
  }

  @override
  bool shouldExecute(Module module) => module.macroConstructors.isNotEmpty;
}

// The value of the --precompiled-macro argument for macros coming from
// `module`.
String precompiledMacroArg(Module module, ModuleDataToRelativeUri toUri) {
  var executableUri = toUri(module, precompiledMacroId);
  return '$executableUri;${module.macroConstructors.keys.join(';')}';
}
