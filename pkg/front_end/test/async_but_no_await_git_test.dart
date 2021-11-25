// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
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
import 'package:front_end/src/fasta/compiler_context.dart';
import 'package:front_end/src/fasta/incremental_compiler.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/reference_from_index.dart';
import 'package:kernel/target/changed_structure_notifier.dart';
import 'package:kernel/target/targets.dart';
import "package:vm/target/vm.dart" show VmTarget;

import 'testing_utils.dart' show getGitFiles;
import "utils/io_utils.dart";

final Uri repoDir = computeRepoDirUri();

Set<Uri> libUris = {};

Future<void> main(List<String> args) async {
  api.CompilerOptions compilerOptions = getOptions();

  Uri dotPackagesUri = repoDir.resolve(".packages");
  if (!new File.fromUri(dotPackagesUri).existsSync()) {
    throw "Couldn't find .packages";
  }
  compilerOptions.packagesFileUri = dotPackagesUri;

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
  component.accept(new AsyncNoAwaitVisitor());

  print("Done in ${stopwatch.elapsedMilliseconds} ms. "
      "Found $errorCount errors.");
  if (errorCount > 0) {
    throw "Found $errorCount errors.";
  }
}

class AsyncNoAwaitVisitor extends RecursiveVisitor {
  bool sawAwait = false;

  @override
  void visitProcedure(Procedure node) {
    if (node.function.asyncMarker != AsyncMarker.Async) return;
    sawAwait = false;
    defaultMember(node);
    if (!sawAwait) {
      Location? location = node.location;
      if (location?.file.path.contains("/pkg/front_end/") == true) {
        print("$node (${node.location}) is async "
            "but doesn't use 'await' anywhere.");
        errorCount++;
      }
    }
  }

  @override
  void visitAwaitExpression(AwaitExpression node) {
    sawAwait = true;
  }
}

int errorCount = 0;

api.CompilerOptions getOptions() {
  // Compile sdk because when this is run from a lint it uses the checked-in sdk
  // and we might not have a suitable compiled platform.dill file.
  Uri sdkRoot = computePlatformBinariesLocation(forceBuildDir: true);
  api.CompilerOptions options = new api.CompilerOptions()
    ..sdkRoot = sdkRoot
    ..compileSdk = true
    ..target = new TestVmTarget(new TargetFlags())
    ..librariesSpecificationUri = repoDir.resolve("sdk/lib/libraries.json")
    ..omitPlatform = true
    ..onDiagnostic = (api.DiagnosticMessage message) {
      if (message.severity == Severity.error) {
        print(message.plainTextFormatted.join('\n'));
        errorCount++;
        exitCode = 1;
      }
    }
    ..environmentDefines = const {};
  return options;
}

class TestVmTarget extends VmTarget with NoTransformationsMixin {
  TestVmTarget(TargetFlags flags) : super(flags);
}

mixin NoTransformationsMixin on Target {
  @override
  void performModularTransformationsOnLibraries(
      Component component,
      CoreTypes coreTypes,
      ClassHierarchy hierarchy,
      List<Library> libraries,
      Map<String, String>? environmentDefines,
      DiagnosticReporter diagnosticReporter,
      ReferenceFromIndex? referenceFromIndex,
      {void Function(String msg)? logger,
      ChangedStructureNotifier? changedStructureNotifier}) {
    // We don't want to do the transformations because we need to await
    // statements.
  }
}
