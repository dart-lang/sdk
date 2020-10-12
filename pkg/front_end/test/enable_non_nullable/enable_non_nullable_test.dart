// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'dart:io';

import 'package:expect/expect.dart';
import 'package:front_end/src/api_prototype/compiler_options.dart';
import 'package:front_end/src/api_prototype/experimental_flags.dart';
import 'package:front_end/src/api_prototype/kernel_generator.dart';
import 'package:front_end/src/api_prototype/language_version.dart';
import 'package:front_end/src/compute_platform_binaries_location.dart';
import 'package:kernel/ast.dart';

/// The version used in this test as the experiment release version.
const Version experimentReleaseVersion = const Version(2, 9);

/// The version used in this test as the experiment enabled version.
const Version experimentEnabledVersion = const Version(2, 10);

main() async {
  print('--------------------------------------------------------------------');
  print('Test off-by-default with command-line flag');
  print('--------------------------------------------------------------------');
  await test(
      enableNonNullableByDefault: false,
      // When the flag is off by default, the experiment release version should
      // be used as the opt-in criterion for all libraries.
      versionImpliesOptIn: experimentReleaseVersion,
      versionOptsInAllowed: experimentReleaseVersion);

  print('--------------------------------------------------------------------');
  print('Test on-by-default');
  print('--------------------------------------------------------------------');
  await test(
      enableNonNullableByDefault: true,
      // When the flag is on by default, the experiment release version should
      // be used as the opt-in criterion only for libraries in allowed packages
      // and the experiment enabled version should be used as the opt-in
      // criterion for all other libraries.
      versionImpliesOptIn: experimentEnabledVersion,
      versionOptsInAllowed: experimentReleaseVersion);
}

test(
    {bool enableNonNullableByDefault,
    Version versionImpliesOptIn,
    Version versionOptsInAllowed}) async {
  CompilerOptions options = new CompilerOptions();
  if (enableNonNullableByDefault) {
    // Pretend non-nullable is on by default.
    options.defaultExperimentFlagsForTesting = {
      ExperimentalFlag.nonNullable: true
    };
  } else {
    // Pretend non-nullable is off by default but enabled on command-line.
    options
      ..defaultExperimentFlagsForTesting = {ExperimentalFlag.nonNullable: false}
      ..experimentalFlags = {ExperimentalFlag.nonNullable: true};
  }

  Uri sdkSummary = computePlatformBinariesLocation(forceBuildDir: true)
      .resolve('vm_platform_strong.dill');
  options
    ..sdkSummary = sdkSummary
    // Pretend current version is 2.11
    ..currentSdkVersion = '2.11'
    ..allowedExperimentalFlagsForTesting = new AllowedExperimentalFlags(
        sdkDefaultExperiments:
            defaultAllowedExperimentalFlags.sdkDefaultExperiments,
        sdkLibraryExperiments:
            defaultAllowedExperimentalFlags.sdkLibraryExperiments,
        packageExperiments: {
          ...defaultAllowedExperimentalFlags.packageExperiments,
          'allowed_package': {ExperimentalFlag.nonNullable}
        })
    ..experimentReleasedVersionForTesting = const {
      // Pretend non-nullable is released in version 2.9.
      ExperimentalFlag.nonNullable: experimentReleaseVersion
    }
    ..experimentEnabledVersionForTesting = const {
      // Pretend non-nullable is enabled in version 2.10.
      ExperimentalFlag.nonNullable: experimentEnabledVersion
    };

  Directory directory = new Directory.fromUri(
      Uri.base.resolve('pkg/front_end/test/enable_non_nullable/data/'));
  CompilerResult result = await kernelForProgramInternal(
      directory.uri.resolve('main.dart'), options,
      retainDataForTesting: true);
  for (Library library in result.component.libraries) {
    if (library.importUri.scheme != 'dart') {
      bool usesLegacy =
          await uriUsesLegacyLanguageVersion(library.fileUri, options);
      VersionAndPackageUri versionAndPackageUri =
          await languageVersionForUri(library.fileUri, options);
      bool isNonNullableByDefault = library.isNonNullableByDefault;
      print('${library.fileUri}:');
      print(' version=${versionAndPackageUri.version}');
      print(' (package) uri=${versionAndPackageUri.packageUri}');
      print(' isNonNullableByDefault=${isNonNullableByDefault}');
      print(' uriUsesLegacyLanguageVersion=${usesLegacy}');
      Expect.equals(library.languageVersion, versionAndPackageUri.version,
          "Language version mismatch for ${library.importUri}");
      Expect.equals(
          !usesLegacy,
          isNonNullableByDefault,
          "Unexpected null-safe state for ${library.importUri}:"
          " isNonNullableByDefault=$isNonNullableByDefault,"
          " uriUsesLegacyLanguageVersion=$usesLegacy. "
          "Computed version=${versionAndPackageUri.version},"
          " (package) uri=${versionAndPackageUri.packageUri}");
      Expect.isTrue(
          library.languageVersion < versionImpliesOptIn ||
              library.isNonNullableByDefault,
          "Expected library ${library.importUri} with version "
          "${library.languageVersion} to be opted in.");
      Expect.isTrue(
          versionAndPackageUri.packageUri.scheme != 'package' ||
              !versionAndPackageUri.packageUri.path
                  .startsWith('allowed_package') ||
              library.languageVersion < versionOptsInAllowed ||
              library.isNonNullableByDefault,
          "Expected allowed library ${library.importUri} with version "
          "${library.languageVersion} to be opted in.");
    }
  }
}
