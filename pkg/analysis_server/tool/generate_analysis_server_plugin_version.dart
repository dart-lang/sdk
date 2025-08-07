// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer_testing/package_root.dart';
import 'package:analyzer_utilities/tools.dart';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

void main() async {
  await GeneratedContent.generateAll(packageRoot, allTargets);
}

List<GeneratedContent> get allTargets {
  return [
    GeneratedFile('analysis_server/lib/src/plugin2/analyzer_version.g.dart', (
      _,
    ) async {
      var buffer = StringBuffer('''
// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead, run
// 'dart pkg/analysis_server/tool/generate_analysis_server_plugin_version.dart'
// to update this file.

''');

      var analysisServerPluginVersion = versionFromPubspec(
        normalize(join(packageRoot, 'analysis_server_plugin', 'pubspec.yaml')),
      );
      buffer.write('''
/// The version of the analysis_server_plugin package that matches the protocol
/// used by the analysis_server package.
var analysisServerPluginVersion = '$analysisServerPluginVersion';

''');
      return buffer.toString();
    }),
  ];
}

String versionFromPubspec(String pubspecPath) {
  var pubspec = loadYaml(File(pubspecPath).readAsStringSync());
  return (pubspec as YamlMap)['version'] as String;
}
