// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:package_config/package_config.dart';

/// Helper to construct a [PackageConfig] for unit tests.
PackageConfig createPackageConfig({
  List<Map<String, String>> packages = const [
    {
      'name': 'pkg_a',
      'rootUri': '../../../../../../pkg_a/',
      'packageUri': 'lib/',
    },
    {
      'name': 'pkg_b',
      'rootUri': '../../../../../../pkg_b/',
      'packageUri': 'lib/',
    },
  ],
  String packagesPath = 'google3:///app/.dart_tool/package_config.json',
}) {
  return PackageConfig.parseString(
    jsonEncode({
      'configVersion': 2,
      'packages': [
        for (final pkg in packages)
          {
            'name': pkg['name'],
            'rootUri': pkg['rootUri'],
            'packageUri': pkg['packageUri'],
            'languageVersion': '3.4',
          },
      ],
    }),
    Uri.parse(packagesPath),
  );
}
