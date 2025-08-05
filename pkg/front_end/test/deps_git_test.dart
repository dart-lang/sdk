// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:_fe_analyzer_shared/src/messages/severity.dart';
import 'package:expect/expect.dart' show Expect;
import 'package:front_end/src/api_prototype/compiler_options.dart';
import 'package:front_end/src/api_prototype/standard_file_system.dart';
import 'package:front_end/src/base/compiler_context.dart';
import 'package:front_end/src/base/file_system_dependency_tracker.dart';
import 'package:front_end/src/base/import_chains.dart';
import 'package:front_end/src/base/processed_options.dart';
import 'package:front_end/src/base/ticker.dart';
import 'package:front_end/src/base/uri_translator.dart';
import 'package:front_end/src/builder/compilation_unit.dart';
import 'package:front_end/src/compute_platform_binaries_location.dart'
    show computePlatformBinariesLocation;
import 'package:front_end/src/dill/dill_target.dart';
import 'package:front_end/src/kernel/kernel_target.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/target/targets.dart';
import 'package:package_config/src/package_config.dart';
import 'package:vm/modular/target/vm.dart' show VmTarget;

import 'utils/io_utils.dart' show computeRepoDirUri;

final Uri repoDir = computeRepoDirUri();

Set<String> allowlistedExternalDartFiles = {
  // TODO(CFE-team): These files should not be included.
  // The package isn't even in pubspec.yaml.
  // They're included via at least
  // _fe_analyzer_shared/lib/src/flow_analysis/flow_analysis.dart
  "pkg/meta/lib/meta.dart",
  "pkg/meta/lib/meta_meta.dart",
};

Set<String> allowedPackages = {
  "front_end",
  "kernel",
  "_fe_analyzer_shared",
  "package_config",
  "macros",
  "_macros",
  // package:front_end imports package:yaml for the 'dynamic modules'
  // experiment.
  "yaml",
  // package:yaml uses package:source_span, package:string_scanner and
  // package:collection.
  "source_span",
  "string_scanner",
  "collection",
  // package:source_span imports package:path.
  "path",
  // package:source_span imports package:term_glyph.
  "term_glyph",
};

List<String> allowedRelativePaths = [
  // For VmTarget for macros.
  "pkg/vm/lib/modular/",
  // Platform.
  "sdk/lib/",
];

/// Returns true on no errors and false if errors was found.
Future<bool> main() async {
  Ticker ticker = new Ticker(isVerbose: false);
  CompilerOptions compilerOptions = getOptions();

  Uri packageConfigUri = repoDir.resolve(".dart_tool/package_config.json");
  if (!new File.fromUri(packageConfigUri).existsSync()) {
    throw "Couldn't find .dart_tool/package_config.json";
  }
  compilerOptions.packagesFileUri = packageConfigUri;
  FileSystemDependencyTracker tracker = new FileSystemDependencyTracker();
  compilerOptions.fileSystem = StandardFileSystem.instanceWithTracking(tracker);

  ProcessedOptions options = new ProcessedOptions(options: compilerOptions);

  Uri frontendLibUri = repoDir.resolve("pkg/front_end/lib/");
  List<FileSystemEntity> entities =
      new Directory.fromUri(frontendLibUri).listSync(recursive: true);
  for (FileSystemEntity entity in entities) {
    if (entity is File && entity.path.endsWith(".dart")) {
      options.inputs.add(entity.uri);
    }
  }

  LoadedLibraries? loadedLibraries;
  Map<Uri, Uri> fileUriToImportUri = {};
  List<String> allowedUriPrefixes = [
    for (String relativePath in allowedRelativePaths)
      repoDir.resolve(relativePath).toString()
  ];

  List<Uri> result = await CompilerContext.runWithOptions<List<Uri>>(options,
      (CompilerContext c) async {
    UriTranslator uriTranslator = await c.options.getUriTranslator();
    for (Package package in uriTranslator.packages.packages) {
      if (allowedPackages.contains(package.name)) {
        allowedUriPrefixes.add(package.packageUriRoot.toString());
      }
    }
    DillTarget dillTarget =
        new DillTarget(c, ticker, uriTranslator, c.options.target);
    KernelTarget kernelTarget =
        new KernelTarget(c, c.fileSystem, false, dillTarget, uriTranslator);
    Uri? platform = c.options.sdkSummary;
    if (platform != null) {
      var bytes = new File.fromUri(platform).readAsBytesSync();
      var platformComponent = loadComponentFromBytes(bytes);
      dillTarget.loader
          .appendLibraries(platformComponent, byteCount: bytes.length);
    }

    kernelTarget.setEntryPoints(c.options.inputs);
    dillTarget.buildOutlines();
    await kernelTarget.loader.buildOutlines();

    {
      List<CompilationUnit> compilationUnits =
          kernelTarget.loader.compilationUnits.toList(growable: false);
      List<CompilationUnit> rootCompilationUnits = [];
      Set<Uri> inputs = new Set.of(options.inputs);
      for (CompilationUnit unit in compilationUnits) {
        fileUriToImportUri[unit.fileUri] = unit.importUri;
        if (inputs.contains(unit.fileUri) || inputs.contains(unit.importUri)) {
          rootCompilationUnits.add(unit);
        }
      }
      loadedLibraries =
          new LoadedLibrariesImpl(rootCompilationUnits, compilationUnits);
    }

    return new List<Uri>.from(tracker.dependencies);
  });

  Set<Uri> otherDartUris = new Set<Uri>();
  Set<Uri> otherNonDartUris = new Set<Uri>();
  for (Uri uri in result) {
    final String uriAsString = uri.toString();
    bool allowed = false;
    for (String prefix in allowedUriPrefixes) {
      if (uriAsString.startsWith(prefix)) {
        allowed = true;
        break;
      }
    }
    if (!allowed) {
      if (uri.toString().endsWith(".dart")) {
        otherDartUris.add(uri);
      } else {
        otherNonDartUris.add(uri);
      }
    }
  }

  // Remove allow-listed non-dart files.
  otherNonDartUris.remove(packageConfigUri);
  otherNonDartUris.remove(repoDir.resolve("sdk/lib/libraries.json"));

  // Remove allow-listed dart files.
  for (String s in allowlistedExternalDartFiles) {
    otherDartUris.remove(repoDir.resolve(s));
  }

  // Everything else is an error.
  if (otherNonDartUris.isNotEmpty || otherDartUris.isNotEmpty) {
    print("The following files was imported without being allowlisted:");
    for (Uri uri in otherNonDartUris) {
      print(" - $uri");
    }
    for (Uri uri in otherDartUris) {
      print(" - $uri");
      if (loadedLibraries != null) {
        Uri? importUri = fileUriToImportUri[uri];
        if (importUri != null) {
          Set<String> importChains = (computeImportChainsFor(
              Uri.parse("<entry>"), loadedLibraries!, importUri,
              verbose: false));
          for (String s in importChains) {
            print(" => $s");
          }
        }
      }
    }
    exitCode = 1;
    return false;
  }
  return true;
}

CompilerOptions getOptions() {
  // Compile sdk because when this is run from a lint it uses the checked-in sdk
  // and we might not have a suitable compiled platform.dill file.
  Uri sdkRoot = computePlatformBinariesLocation(forceBuildDir: true);
  CompilerOptions options = new CompilerOptions()
    ..sdkRoot = sdkRoot
    ..compileSdk = true
    ..target = new VmTarget(new TargetFlags())
    ..librariesSpecificationUri = repoDir.resolve("sdk/lib/libraries.json")
    ..omitPlatform = true
    ..onDiagnostic = (CfeDiagnosticMessage message) {
      if (message.severity == CfeSeverity.error) {
        Expect.fail(
            "Unexpected error: ${message.plainTextFormatted.join('\n')}");
      }
    }
    ..environmentDefines = const {};
  return options;
}
