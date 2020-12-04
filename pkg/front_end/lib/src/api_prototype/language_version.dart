// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data' show Uint8List;

import 'package:_fe_analyzer_shared/src/scanner/scanner.dart'
    show LanguageVersionToken, Scanner, ScannerConfiguration, scan;

import 'package:kernel/ast.dart' show Version;
export 'package:kernel/ast.dart' show Version;

import 'package:package_config/package_config.dart'
    show InvalidLanguageVersion, Package;

import '../base/processed_options.dart' show ProcessedOptions;

import '../fasta/compiler_context.dart' show CompilerContext;

import '../fasta/source/source_library_builder.dart' show SourceLibraryBuilder;

import '../fasta/uri_translator.dart' show UriTranslator;

import 'compiler_options.dart' show CompilerOptions;

import 'experimental_flags.dart' show ExperimentalFlag;
import 'file_system.dart' show FileSystem, FileSystemException;

/// Gets the language version for a specific URI.
///
/// Note that this returning some language version, doesn't mean there aren't
/// errors associated with the language version specified (e.g. that the file
/// specifies a language version that's too high).
///
/// The language version returned is valid though.
Future<VersionAndPackageUri> languageVersionForUri(
    Uri uri, CompilerOptions options) async {
  return await CompilerContext.runWithOptions(
      new ProcessedOptions(options: options, inputs: [uri]), (context) async {
    // Get largest valid version / default version.
    String currentSdkVersion = context.options.currentSdkVersion;
    bool good = false;
    int currentSdkVersionMajor;
    int currentSdkVersionMinor;
    if (currentSdkVersion != null) {
      List<String> dotSeparatedParts = currentSdkVersion.split(".");
      if (dotSeparatedParts.length >= 2) {
        currentSdkVersionMajor = int.tryParse(dotSeparatedParts[0]);
        currentSdkVersionMinor = int.tryParse(dotSeparatedParts[1]);
        good = true;
      }
    }
    if (!good) {
      throw new StateError("Unparsable sdk version given: $currentSdkVersion");
    }

    // Get file uri.
    UriTranslator uriTranslator = await context.options.getUriTranslator();
    Uri fileUri;
    Package package;
    if (uri.scheme == "package") {
      fileUri = uriTranslator.translate(uri);
      package = uriTranslator.getPackage(uri);
    } else {
      fileUri = uri;
      package = uriTranslator.packages.packageOf(uri);
    }
    Uri packageUri = uri;
    if (packageUri.scheme != 'dart' &&
        packageUri.scheme != 'package' &&
        package != null &&
        package.name != null) {
      packageUri = new Uri(scheme: 'package', path: package.name);
    }

    // Check file content for @dart annotation.
    int major;
    int minor;
    if (fileUri != null) {
      List<int> rawBytes;
      try {
        FileSystem fileSystem = context.options.fileSystem;
        rawBytes = await fileSystem.entityForUri(fileUri).readAsBytes();
      } on FileSystemException catch (_) {
        rawBytes = null;
      }
      if (rawBytes != null) {
        Uint8List zeroTerminatedBytes = new Uint8List(rawBytes.length + 1);
        zeroTerminatedBytes.setRange(0, rawBytes.length, rawBytes);

        scan(zeroTerminatedBytes,
            includeComments: false,
            configuration: new ScannerConfiguration(), languageVersionChanged:
                (Scanner scanner, LanguageVersionToken version) {
          if (major != null || minor != null) return;
          major = version.major;
          minor = version.minor;
        });
      }
    }

    if (major != null && minor != null) {
      // Verify OK.
      if (major > currentSdkVersionMajor ||
          (major == currentSdkVersionMajor && minor > currentSdkVersionMinor)) {
        major = null;
        minor = null;
      }
    }
    if (major != null && minor != null) {
      // The file decided. Return result.
      return new VersionAndPackageUri(new Version(major, minor), packageUri);
    }

    // Check package.
    if (package != null &&
        package.languageVersion != null &&
        package.languageVersion is! InvalidLanguageVersion) {
      major = package.languageVersion.major;
      minor = package.languageVersion.minor;
      if (major > currentSdkVersionMajor ||
          (major == currentSdkVersionMajor && minor > currentSdkVersionMinor)) {
        major = null;
        minor = null;
      }
    }
    if (major != null && minor != null) {
      // The package decided. Return result.
      return new VersionAndPackageUri(new Version(major, minor), packageUri);
    }

    // Return default.
    return new VersionAndPackageUri(
        new Version(currentSdkVersionMajor, currentSdkVersionMinor),
        packageUri);
  });
}

/// Returns `true` if the language version of [uri] does not support null
/// safety.
Future<bool> uriUsesLegacyLanguageVersion(
    Uri uri, CompilerOptions options) async {
  // This method is here in order to use the opt out hack here for test
  // sources.
  if (SourceLibraryBuilder.isOptOutTest(uri)) return true;
  VersionAndPackageUri versionAndLibraryUri =
      await languageVersionForUri(uri, options);
  return (versionAndLibraryUri.version <
      options.getExperimentEnabledVersionInLibrary(
          ExperimentalFlag.nonNullable, versionAndLibraryUri.packageUri));
}

class VersionAndPackageUri {
  final Version version;
  final Uri packageUri;

  VersionAndPackageUri(this.version, this.packageUri);
}
