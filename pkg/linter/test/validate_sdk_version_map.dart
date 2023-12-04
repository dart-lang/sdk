// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/src/lint/state.dart';
import 'package:analyzer_utilities/package_root.dart' as pkg_root;
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/rules.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('check to ensure all lints have versions in `sdk.yaml`', () {
    var linterPkgPath =
        path.normalize(path.join(pkg_root.packageRoot, 'linter'));
    var sinceFile = File(path.join(linterPkgPath, 'tool', 'since', 'sdk.yaml'))
        .readAsStringSync();
    var versionMap = loadYamlNode(sinceFile) as YamlMap;
    registerLintRules();
    var publicRules =
        Analyzer.facade.registeredRules.where((rule) => !rule.state.isInternal);
    for (var rule in publicRules.map((r) => r.name)) {
      test(rule, () async {
        expect(versionMap.keys, contains(rule),
            reason: "'$rule' should have and entry in `tool/since/sdk.yaml`.");
      });
    }
  });
}
