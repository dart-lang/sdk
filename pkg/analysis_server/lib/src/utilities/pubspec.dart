// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/hint/sdk_constraint_extractor.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:pub_semver/pub_semver.dart';

/// Checks if [targetVersion] is compatible with the SDK constraints of all
/// resolved [packages].
///
/// Returns a list of package names that are incompatible.
List<String> checkDependencyCompatibility({
  required Iterable<Package> packages,
  required Version targetVersion,
}) {
  var incompatible = <String>[];
  for (var package in packages) {
    var pubspecFile = package.rootFolder.getFile(file_paths.pubspecYaml);
    if (!pubspecFile.exists) continue;

    var extractor = SdkConstraintExtractor(pubspecFile);
    var constraint = extractor.constraint();
    if (constraint == null) continue;

    // Check if the dependency's SDK constraint allows the target version.
    if (!constraint.allows(targetVersion)) {
      incompatible.add(package.name);
    }
  }
  return incompatible;
}

/// Calculates the edit to update the SDK constraint in [pubspecFile] to the
/// given [minimumVersion].
///
/// Returns `null` if the constraint cannot be found or is not in a supported
/// format.
PubspecEdit? computeEdit(File pubspecFile, Version minimumVersion) {
  var extractor = SdkConstraintExtractor(pubspecFile);
  return _computeEdit(
    extractor.constraintText(),
    extractor.constraintOffset(),
    minimumVersion,
  );
}

/// Calculates the edit to bump the SDK constraint in [pubspecFile] by 1
/// minor version.
///
/// Returns `null` if the constraint cannot be found or is not in a supported
/// format.
PubspecEdit? computeVersionBumpEdit(File pubspecFile) {
  var extractor = SdkConstraintExtractor(pubspecFile);
  var text = extractor.constraintText();
  if (text == null) return null;

  Version? newVersion;
  try {
    var constraint = VersionConstraint.parse(text);
    if (constraint is VersionRange) {
      var min = constraint.min;
      if (min != null) {
        newVersion = Version(min.major, min.minor + 1, 0);
      }
    } else if (constraint is Version) {
      newVersion = Version(constraint.major, constraint.minor + 1, 0);
    }
    // TODO(kallentu): Support VersionUnion.
    // For example (e.g. '>=2.12.0 <3.0.0 || >=3.10.0').
  } catch (e) {
    // Can't parse the version constraint.
    return null;
  }

  if (newVersion == null) return null;

  return _computeEdit(text, extractor.constraintOffset(), newVersion);
}

PubspecEdit? _computeEdit(String? text, int offset, Version minimumVersion) {
  if (text == null || offset < 0) {
    return null;
  }

  var length = text.length;
  var spaceOffset = text.indexOf(' ');
  if (spaceOffset >= 0) {
    length = spaceOffset;
  }

  String newText;
  if (text == 'any') {
    newText = '^$minimumVersion';
  } else if (text.startsWith('^')) {
    newText = '^$minimumVersion';
  } else if (text.startsWith('>=')) {
    newText = '>=$minimumVersion';
  } else if (text.startsWith('>')) {
    newText = '>=$minimumVersion';
  } else {
    return null;
  }

  return PubspecEdit(
    offset: offset,
    length: length,
    replacement: newText,
    originalConstraint: text,
    targetVersion: minimumVersion,
  );
}

/// The result of computing an edit to a pubspec file's SDK constraint.
class PubspecEdit {
  /// The character offset in the document where the edit should be applied.
  final int offset;

  /// The length of the text to be replaced.
  final int length;

  /// The full new SDK constraint text after the edit is applied and the text to
  /// be inserted at [offset], replacing [length] characters.
  final String replacement;

  /// The full original SDK constraint text before the edit is applied.
  final String originalConstraint;

  /// The target version to migrate to.
  final Version targetVersion;

  new({
    required this.offset,
    required this.length,
    required this.replacement,
    required this.originalConstraint,
    required this.targetVersion,
  });
}
