// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:_fe_analyzer_shared/src/messages/severity.dart';
import 'package:front_end/src/api_prototype/compiler_options.dart' as api;
import 'package:front_end/src/api_prototype/incremental_kernel_generator.dart'
    show IncrementalCompilerResult;
import 'package:front_end/src/base/compiler_context.dart';
import 'package:front_end/src/base/incremental_compiler.dart';
import 'package:front_end/src/base/processed_options.dart';
import 'package:front_end/src/compute_platform_binaries_location.dart'
    show computePlatformBinariesLocation;
import 'package:kernel/kernel.dart';
import 'package:kernel/target/targets.dart';

import '../tool/unreachable_if_finder.dart';
import 'testing_utils.dart' show getGitFiles;
import "utils/io_utils.dart";

final Uri repoDir = computeRepoDirUri();

Set<Uri> libUris = {};

Future<void> main(List<String> args) async {
  api.CompilerOptions compilerOptions = getOptions();

  Uri packageConfigUri = repoDir.resolve(".dart_tool/package_config.json");
  if (!new File.fromUri(packageConfigUri).existsSync()) {
    throw "Couldn't find .dart_tool/package_config.json";
  }
  compilerOptions.packagesFileUri = packageConfigUri;

  ProcessedOptions options = new ProcessedOptions(options: compilerOptions);

  libUris.add(repoDir.resolve("pkg/front_end/lib/"));
  libUris.add(repoDir.resolve("pkg/front_end/test/fasta/"));
  libUris.add(repoDir.resolve("pkg/front_end/tool/"));

  for (Uri uri in libUris) {
    Set<Uri> gitFiles = await getGitFiles(uri);
    List<FileSystemEntity> entities =
        new Directory.fromUri(uri).listSync(recursive: true);
    for (FileSystemEntity entity in entities) {
      if (entity is File &&
          entity.path.endsWith(".dart") &&
          gitFiles.contains(entity.uri)) {
        options.inputs.add(entity.uri);
      }
    }
  }

  Stopwatch stopwatch = new Stopwatch()..start();

  IncrementalCompiler compiler =
      new IncrementalCompiler(new CompilerContext(options));
  IncrementalCompilerResult compilerResult = await compiler.computeDelta();
  Component component = compilerResult.component;
  List<Warning> warnings = UnreachableIfFinder.find(component);

  print("Done in ${stopwatch.elapsedMilliseconds} ms. "
      "Found ${warnings.length} warnings.");
  if (warnings.length > 0) {
    for (Warning warning in warnings) {
      print(warning);
      print("");
    }
    throw "Found ${warnings.length} warnings.";
  }
}

api.CompilerOptions getOptions() {
  Uri sdkRoot = computePlatformBinariesLocation(forceBuildDir: true);
  api.CompilerOptions options = new api.CompilerOptions()
    ..sdkRoot = sdkRoot
    ..compileSdk = false
    ..target = new NoneTarget(new TargetFlags())
    ..librariesSpecificationUri = repoDir.resolve("sdk/lib/libraries.json")
    ..omitPlatform = true
    ..onDiagnostic = (api.DiagnosticMessage message) {
      if (message.severity == Severity.error) {
        print(message.plainTextFormatted.join('\n'));
        exitCode = 1;
      }
    }
    ..environmentDefines = const {};
  return options;
}
