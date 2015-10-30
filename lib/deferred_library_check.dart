// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This tool checks that the output from dart2js meets a given specification,
/// given in a YAML file. The format of the YAML file is:
///
///     main:
///       packages:
///         - some_package
///         - other_package
///
///     foo:
///       packages:
///         - foo
///         - bar
///
///     baz:
///       packages:
///         - baz
///         - quux
///
/// The YAML file consists of a list of declarations, one for each deferred
/// part expected in the output. At least one of these parts must be named
/// "main"; this is the main part that contains the program entrypoint. Each
/// top-level part contains a list of package names that are expected to be
/// contained in that part. Any package that is not explicitly listed is
/// expected to be in the main part. For instance, in the example YAML above
/// the part named "baz" is expected to contain the packages "baz" and "quux".
///
/// The names for parts given in the specification YAML file (besides "main")
/// are arbitrary and just used for reporting when the output does not meet the
/// specification.
library dart2js_info.deferred_library_check;

import 'info.dart';
import 'package:quiver/collection.dart';

List<ManifestComplianceFailure> checkDeferredLibraryManifest(
    AllInfo info, Map manifest) {
  // For each part in the manifest, record the expected "packages" for that
  // part.
  var packages = <String, String>{};
  for (var part in manifest.keys) {
    for (var package in manifest[part]['packages']) {
      if (packages.containsKey(package)) {
        throw new ArgumentError.value(
            manifest,
            'manifest',
            'You cannot specify that package "$package" maps to both parts '
            '"$part" and "${packages[package]}".');
      }
      packages[package] = part;
    }
  }

  var guessedPartMapping = new BiMap<String, String>();
  guessedPartMapping['main'] = 'main';

  var failures = <ManifestComplianceFailure>[];

  checkInfo(BasicInfo info) {
    var lib = _getLibraryOf(info);
    if (lib != null && _isPackageUri(lib.uri)) {
      var packageName = _getPackageName(lib.uri);
      var outputUnitName = info.outputUnit.name;
      var expectedPart;
      if (packages.containsKey(packageName)) {
        expectedPart = packages[packageName];
      } else {
        expectedPart = 'main';
      }
      var expectedOutputUnit = guessedPartMapping[expectedPart];
      if (expectedOutputUnit == null) {
        guessedPartMapping[expectedPart] = outputUnitName;
      } else {
        if (expectedOutputUnit != outputUnitName) {
          // TODO(het): add options for how to treat unspecified packages
          if (!packages.containsKey(packageName)) {
            failures.add(new ManifestComplianceFailure(info.name, packageName));
          } else {
            var actualPart = guessedPartMapping.inverse[outputUnitName];
            failures.add(new ManifestComplianceFailure(
                info.name, packageName, expectedPart, actualPart));
          }
        }
      }
    }
  }

  info.functions.forEach(checkInfo);
  info.fields.forEach(checkInfo);

  return failures;
}

LibraryInfo _getLibraryOf(Info info) {
  var current = info;
  while (current is! LibraryInfo) {
    if (current == null) {
      return null;
    }
    current = current.parent;
  }
  return current;
}

bool _isPackageUri(Uri uri) => uri.scheme == 'package';

String _getPackageName(Uri uri) {
  assert(_isPackageUri(uri));
  return uri.pathSegments.first;
}

class ManifestComplianceFailure {
  final String infoName;
  final String packageName;
  final String expectedPart;
  final String actualPart;

  const ManifestComplianceFailure(this.infoName, this.packageName,
      [this.expectedPart, this.actualPart]);

  String toString() {
    if (expectedPart == null && actualPart == null) {
      return '"$infoName" from package "$packageName" was not declared '
          'to be in an explicit part but was not in the main part';
    } else {
      return '"$infoName" from package "$packageName" was specified to '
          'be in part $expectedPart but is in part $actualPart';
    }
  }
}
