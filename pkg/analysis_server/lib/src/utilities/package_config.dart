// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:pub_semver/pub_semver.dart';

/// Updates the language version for [packageName] in the given
/// [packageConfigJson] string.
///
/// Returns the updated JSON string with indentation, or `null` if
/// [packageConfigJson] is not valid JSON, does not conform to the package
/// config format, or does not contain [packageName].
String? updatePackageLanguageVersion(
  String packageConfigJson, {
  required String packageName,
  required Version languageVersion,
}) {
  try {
    var json = jsonDecode(packageConfigJson);
    if (json is! Map<String, Object?>) return null;
    var packages = json['packages'];
    if (packages is! List<Object?>) return null;
    for (var package in packages) {
      if (package is Map<String, Object?> && package['name'] == packageName) {
        package['languageVersion'] =
            '${languageVersion.major}.${languageVersion.minor}';
        return JsonEncoder.withIndent('  ').convert(json);
      }
    }
  } on FormatException {
    return null;
  }
  return null;
}
