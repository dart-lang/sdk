// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:dartdev/src/core.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  group('PackageConfig', _packageConfig);
  group('Project', _project);
}

void _packageConfig() {
  test('packages', () {
    PackageConfig packageConfig = PackageConfig(jsonDecode(_packageData));
    expect(packageConfig.packages, isNotEmpty);
  });

  test('hasDependency', () {
    PackageConfig packageConfig = PackageConfig(jsonDecode(_packageData));
    expect(packageConfig.hasDependency('test'), isFalse);
    expect(packageConfig.hasDependency('pedantic'), isTrue);
  });
}

void _project() {
  TestProject p;

  tearDown(() => p?.dispose());

  test('hasPackageConfigFile negative', () {
    p = project();
    Project coreProj = Project.fromDirectory(p.dir);
    expect(coreProj.hasPackageConfigFile, isFalse);
  });

  test('hasPackageConfigFile positive', () {
    p = project();
    p.file('.dart_tool/package_config.json', _packageData);
    Project coreProj = Project.fromDirectory(p.dir);
    expect(coreProj.hasPackageConfigFile, isTrue);
    expect(coreProj.packageConfig, isNotNull);
    expect(coreProj.packageConfig.packages, isNotEmpty);
  });
}

const String _packageData = '''{
  "configVersion": 2,
  "packages": [
    {
      "name": "pedantic",
      "rootUri": "file:///Users/.../.pub-cache/hosted/pub.dartlang.org/pedantic-1.9.0",
      "packageUri": "lib/",
      "languageVersion": "2.1"
    },
    {
      "name": "args",
      "rootUri": "../",
      "packageUri": "lib/",
      "languageVersion": "2.3"
    }
  ],
  "generated": "2020-03-01T03:38:14.906205Z",
  "generator": "pub",
  "generatorVersion": "2.8.0-dev.10.0"
}
''';
