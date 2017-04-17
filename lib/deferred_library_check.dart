// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This tool checks that the output from dart2js meets a given specification,
/// given in a YAML file. The format of the YAML file is:
///
///     main:
///       include:
///         - some_package
///         - other_package
///
///     foo:
///       include:
///         - foo
///         - bar
///
///     baz:
///       include:
///         - baz
///         - quux
///       exclude:
///         - zardoz
///
/// The YAML file consists of a list of declarations, one for each deferred
/// part expected in the output. At least one of these parts must be named
/// "main"; this is the main part that contains the program entrypoint. Each
/// top-level part contains a list of package names that are expected to be
/// contained in that part, a list of package names that are expected to be in
/// another part, or both. For instance, in the example YAML above the part
/// named "baz" is expected to contain the packages "baz" and "quux" and not to
/// contain the package "zardoz".
///
/// The names for parts given in the specification YAML file (besides "main")
/// are the same as the name given to the deferred import in the dart file. For
/// instance, if you have `import 'package:foo/bar.dart' deferred as baz;` in
/// your dart file, then the corresponding name in the specification file is
/// 'baz'.
library dart2js_info.deferred_library_check;

import 'package:quiver/collection.dart';

import 'info.dart';

List<ManifestComplianceFailure> checkDeferredLibraryManifest(
    AllInfo info, Map manifest) {
  var includedPackages = new Multimap<String, String>();
  var excludedPackages = new Multimap<String, String>();
  for (var part in manifest.keys) {
    for (var package in manifest[part]['include'] ?? []) {
      includedPackages.add(part, package);
    }
    for (var package in manifest[part]['exclude'] ?? []) {
      excludedPackages.add(part, package);
    }
  }

  // There are 2 types of parts that are valid to mention in the specification
  // file. These are the main part and directly imported deferred parts. The
  // main part is always named 'main'; the directly imported deferred parts are
  // the outputUnits whose list of 'imports' contains a single import. If the
  // part is shared, it will have more than one import since it will include the
  // imports of all the top-level deferred parts that will load the shared part.
  List<String> validParts = ['main']..addAll(info.outputUnits
      .where((unit) => unit.imports.length == 1)
      .map((unit) => unit.imports.single));
  List<String> mentionedParts = []
    ..addAll(includedPackages.keys)
    ..addAll(excludedPackages.keys);
  var partNameFailures = <_InvalidPartName>[];
  for (var part in mentionedParts) {
    if (!validParts.contains(part)) {
      partNameFailures.add(new _InvalidPartName(part, validParts));
    }
  }
  if (partNameFailures.isNotEmpty) {
    return partNameFailures;
  }

  var mentionedPackages = new Set()
    ..addAll(includedPackages.values)
    ..addAll(excludedPackages.values);
  var actualIncludedPackages = new Multimap<String, String>();

  var failures = <ManifestComplianceFailure>[];

  checkInfo(BasicInfo info) {
    if (info.size == 0) return;
    var lib = _getLibraryOf(info);
    if (lib != null && _isPackageUri(lib.uri)) {
      var packageName = _getPackageName(lib.uri);
      if (!mentionedPackages.contains(packageName)) return;
      var containingParts = <String>[];
      if (info.outputUnit.name == 'main') {
        containingParts.add('main');
      } else {
        containingParts.addAll(info.outputUnit.imports);
      }
      for (var part in containingParts) {
        actualIncludedPackages.add(part, packageName);
        if (excludedPackages[part].contains(packageName)) {
          failures
              .add(new _PartContainedExcludedPackage(part, packageName, info));
        }
      }
    }
  }

  info.functions.forEach(checkInfo);
  info.fields.forEach(checkInfo);

  includedPackages.forEach((part, package) {
    if (!actualIncludedPackages.containsKey(part) ||
        !actualIncludedPackages[part].contains(package)) {
      failures.add(new _PartDidNotContainPackage(part, package));
    }
  });
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
  const ManifestComplianceFailure();
}

class _InvalidPartName extends ManifestComplianceFailure {
  final String part;
  final List<String> validPartNames;
  const _InvalidPartName(this.part, this.validPartNames);

  String toString() {
    return 'Manifest file declares invalid part "$part". '
        'Valid part names are: $validPartNames';
  }
}

class _PartContainedExcludedPackage extends ManifestComplianceFailure {
  final String part;
  final String package;
  final BasicInfo info;
  const _PartContainedExcludedPackage(this.part, this.package, this.info);

  String toString() {
    return 'Part "$part" was specified to exclude package "$package" but it '
        'actually contains ${kindToString(info.kind)} "${info.name}" which '
        'is from package "$package"';
  }
}

class _PartDidNotContainPackage extends ManifestComplianceFailure {
  final String part;
  final String package;
  const _PartDidNotContainPackage(this.part, this.package);

  String toString() {
    return 'Part "$part" was specified to include package "$package" but it '
        'does not contain any elements from that package.';
  }
}
