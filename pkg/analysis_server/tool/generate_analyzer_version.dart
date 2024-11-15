// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer_utilities/package_root.dart';
import 'package:analyzer_utilities/tools.dart';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

void main() async {
  await GeneratedContent.generateAll(
    normalize(join(packageRoot, 'analysis_server')),
    allTargets,
  );
}

List<GeneratedContent> get allTargets {
  return [
    GeneratedFile('lib/src/plugin2/analyzer_version.g.dart', (_) async {
      var buffer = StringBuffer('''
// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead, run 'dart pkg/analysis_server/tool/generate_analyzer_version.dart'
// to update this file.

''');
      var pubspecPath = normalize(
        join(packageRoot, 'analyzer', 'pubspec.yaml'),
      );
      var pubspec = loadYaml(File(pubspecPath).readAsStringSync());
      var version = (pubspec as YamlMap)['version'] as String;

      buffer.write('''
/// The version of the analyzer that matches the analyzer code used by the
/// analysis_server package.
var analyzerVersion = '$version';
''');
      return buffer.toString();
    }),
  ];
}
