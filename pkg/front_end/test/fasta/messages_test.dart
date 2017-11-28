// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:front_end/src/testing/package_root.dart' as package_root;
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart' show loadYaml;

main([List<String> arguments = const []]) async {
  File file = new File(
      path.join(package_root.packageRoot, 'front_end', 'messages.yaml'));
  if (!await file.exists()) {
    file = new File.fromUri(Uri.base.resolve('messages.yaml'));
  }
  Map yaml = loadYaml(await file.readAsString());

  int untestedExampleCount = 0;
  int missingExamplesCount = 0;
  int missingAnalyzerCode = 0;
  List<String> keysWithAnalyzerCodeButNoDart2JsCode = <String>[];
  List<String> keys = yaml.keys.toList()..sort();
  for (String name in keys) {
    var description = yaml[name];
    while (description is String) {
      description = yaml[description];
    }
    Map map = description;

    int localUntestedExampleCount = countExamples(map, name, 'bytes');
    localUntestedExampleCount += countExamples(map, name, 'declaration');
    localUntestedExampleCount += countExamples(map, name, 'expression');
    localUntestedExampleCount += countExamples(map, name, 'script');
    localUntestedExampleCount += countExamples(map, name, 'statement');
    if (localUntestedExampleCount == 0) ++missingExamplesCount;
    untestedExampleCount += localUntestedExampleCount;

    if (map['analyzerCode'] == null) {
      ++missingAnalyzerCode;
    } else {
      if (map['dart2jsCode'] == null) {
        keysWithAnalyzerCodeButNoDart2JsCode.add(name);
      }
    }
  }

  if (keysWithAnalyzerCodeButNoDart2JsCode.isNotEmpty) {
    print('${keysWithAnalyzerCodeButNoDart2JsCode.length}'
        ' error codes have an analyzerCode but no dart2jsCode:');
    for (String name in keysWithAnalyzerCodeButNoDart2JsCode) {
      print('  $name');
    }
    print('');
  }
  print('$untestedExampleCount examples not tested');
  print('$missingExamplesCount error codes missing examples');
  print('$missingAnalyzerCode error codes missing analyzer code');

  // TODO(danrubel): Update this to assert each count == 0 and stays zero.
  exit(keysWithAnalyzerCodeButNoDart2JsCode.isEmpty &&
          untestedExampleCount > 0 &&
          missingExamplesCount > 0 &&
          missingAnalyzerCode > 0
      ? 0
      : 1);
}

int countExamples(Map map, String name, String key) {
  var example = map[key];
  if (example == null) return 0;
  if (example is String) return 1;
  if (example is List) return example.length;
  if (example is Map) return example.length;

  throw 'Unknown value for $name $key --> ${example.runtimeType}\n  $example';
}
