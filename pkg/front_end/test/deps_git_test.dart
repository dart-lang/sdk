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
import 'package:front_end/src/base/processed_options.dart';
import 'package:front_end/src/base/ticker.dart';
import 'package:front_end/src/base/uri_translator.dart';
import 'package:front_end/src/compute_platform_binaries_location.dart'
    show computePlatformBinariesLocation;
import 'package:front_end/src/dill/dill_target.dart';
import 'package:front_end/src/kernel/kernel_target.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/target/targets.dart';
import 'package:vm/modular/target/vm.dart' show VmTarget;

import 'utils/io_utils.dart' show computeRepoDirUri;

final Uri repoDir = computeRepoDirUri();

Set<String> allowlistedExternalDartFiles = {
  "third_party/pkg/package_config/lib/package_config.dart",
  "third_party/pkg/package_config/lib/package_config_types.dart",
  "third_party/pkg/package_config/lib/src/discovery.dart",
  "third_party/pkg/package_config/lib/src/errors.dart",
  "third_party/pkg/package_config/lib/src/package_config_impl.dart",
  "third_party/pkg/package_config/lib/src/package_config_io.dart",
  "third_party/pkg/package_config/lib/src/package_config_json.dart",
  "third_party/pkg/package_config/lib/src/package_config.dart",
  "third_party/pkg/package_config/lib/src/packages_file.dart",
  "third_party/pkg/package_config/lib/src/util.dart",

  // TODO(johnniwinther): Fix to allow dependency of package:package_config.
  "third_party/pkg/package_config/lib/src/util_io.dart",

  // TODO(CFE-team): These files should not be included.
  // The package isn't even in pubspec.yaml.
  "pkg/meta/lib/meta.dart",
  "pkg/meta/lib/meta_meta.dart",
};

Set<String> allowlistedThirdPartyPackages = {
  "yaml",
  // package:yaml dependencies
  "core/pkgs/collection",
  "core/pkgs/path",
  "source_span",
  "string_scanner",
  "term_glyph",
};

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

  List<Uri> result = await CompilerContext.runWithOptions<List<Uri>>(options,
      (CompilerContext c) async {
    UriTranslator uriTranslator = await c.options.getUriTranslator();
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
    return new List<Uri>.from(tracker.dependencies);
  });

  Set<Uri> otherDartUris = new Set<Uri>();
  Set<Uri> otherNonDartUris = new Set<Uri>();
  List<String> allowedRelativePaths = [
    // Front-end.
    "pkg/kernel/",
    "pkg/_fe_analyzer_shared/",
    // For VmTarget for macros.
    "pkg/vm/lib/modular/",
    // Platform.
    "sdk/lib/",
    "runtime/lib/",
    "runtime/bin/",
    // Macros.
    "pkg/macros",
    "pkg/_macros",
    for (String package in allowlistedThirdPartyPackages)
      "third_party/pkg/$package/",
  ];
  List<String> allowedUriPrefixes = [
    frontendLibUri.toString(),
    for (String relativePath in allowedRelativePaths)
      repoDir.resolve(relativePath).toString()
  ];
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
  otherNonDartUris.remove(repoDir.resolve(".dart_tool/package_config.json"));

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
    ..onDiagnostic = (DiagnosticMessage message) {
      if (message.severity == Severity.error) {
        Expect.fail(
            "Unexpected error: ${message.plainTextFormatted.join('\n')}");
      }
    }
    ..environmentDefines = const {};
  return options;
}
