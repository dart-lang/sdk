// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:_fe_analyzer_shared/src/messages/severity.dart';
import 'package:front_end/src/api_prototype/compiler_options.dart' as api;
import 'package:front_end/src/api_prototype/incremental_kernel_generator.dart'
    show IncrementalCompilerResult;
import 'package:front_end/src/base/processed_options.dart';
import 'package:front_end/src/compute_platform_binaries_location.dart'
    show computePlatformBinariesLocation;
import 'package:front_end/src/base/compiler_context.dart';
import 'package:front_end/src/base/incremental_compiler.dart';
import 'package:kernel/target/targets.dart';
import 'package:vm/modular/target/vm.dart';

import '../test/utils/io_utils.dart' show computeRepoDirUri;

final Uri repoDir = computeRepoDirUri();

Future<void> main(List<String> argsOrg) async {
  bool silent = false;
  List<String> args = [];
  for (String arg in argsOrg) {
    if (arg == "--silent") {
      silent = true;
    } else if (arg.startsWith("--")) {
      // Ignore other non-path arguments for better compatibility with the
      // stable analysis tool (and thus comparison with the analyzer).
      continue;
    } else {
      args.add(arg);
    }
  }
  Stopwatch stopwatch = new Stopwatch()..start();
  await run(args, silent);
  if (!silent) {
    print("Finished in ${stopwatch.elapsed}");
  }
}

Future<void> run(List<String> args, bool silent) async {
  api.CompilerOptions compilerOptions = getOptions();

  ProcessedOptions options = new ProcessedOptions(options: compilerOptions);

  Set<Uri> libUris = {};
  Set<Uri> packageConfigUris = {};
  for (String arg in args) {
    if (!arg.endsWith("/")) {
      // Assume directory.
      arg = "$arg/";
    }
    Uri dir = Uri.base.resolveUri(new Uri.file(arg));
    libUris.add(dir);
    while (!File.fromUri(
      dir.resolve(".dart_tool/package_config.json"),
    ).existsSync()) {
      Uri newDir = dir.resolve("..");
      if (newDir != dir) {
        dir = newDir;
      } else {
        throw "Couldn't find package config for $arg";
      }
    }
    packageConfigUris.add(dir.resolve(".dart_tool/package_config.json"));
  }
  if (packageConfigUris.length != 1) throw "Didn't find unique package config.";

  Uri packageConfigUri = packageConfigUris.first;
  if (!new File.fromUri(packageConfigUri).existsSync()) {
    throw "Couldn't find .dart_tool/package_config.json";
  }
  compilerOptions.packagesFileUri = packageConfigUri;

  for (Uri uri in libUris) {
    List<FileSystemEntity> entities = new Directory.fromUri(
      uri,
    ).listSync(recursive: true);
    for (FileSystemEntity entity in entities) {
      if (entity is File && entity.path.endsWith(".dart")) {
        options.inputs.add(entity.uri);
      }
    }
  }

  IncrementalCompiler compiler = new IncrementalCompiler(
    new CompilerContext(options),
  );
  IncrementalCompilerResult result = await compiler.computeDelta();
  if (!silent) {
    print("Got ${result.component.libraries.length} libraries.");
  }
}

api.CompilerOptions getOptions() {
  Uri sdkRoot = computePlatformBinariesLocation(forceBuildDir: true);
  api.CompilerOptions options = new api.CompilerOptions()
    ..sdkRoot = sdkRoot
    ..compileSdk = false
    ..target = new VmTarget(new TargetFlags())
    ..librariesSpecificationUri = repoDir.resolve("sdk/lib/libraries.json")
    ..omitPlatform = true
    ..onDiagnostic = (api.CfeDiagnosticMessage message) {
      if (message.severity == CfeSeverity.error) {
        print(message.plainTextFormatted.join('\n'));
        exitCode = 1;
      }
    }
    ..environmentDefines = const {};
  return options;
}
