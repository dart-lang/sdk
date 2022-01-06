// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show File, exit, stderr;

import 'dart:isolate' show RawReceivePort;

import 'dart:convert' show JsonEncoder;

import 'package:yaml/yaml.dart' show loadYaml;

main(List<String> arguments) {
  var port = new RawReceivePort();
  bool check = false;
  if (arguments.contains('--check')) {
    arguments = arguments.toList()..remove('--check');
    check = true;
  }
  if (arguments.length != 2) {
    stderr.writeln("Usage: yaml2json.dart input.yaml output.json [--check]");
    exit(1);
  }
  Uri input = Uri.base.resolve(arguments[0]);
  Uri output = Uri.base.resolve(arguments[1]);
  Map yaml = loadYaml(new File.fromUri(input).readAsStringSync());
  Map<String, dynamic> result = new Map<String, dynamic>();
  result["comment:0"] = "NOTE: THIS FILE IS GENERATED. DO NOT EDIT.";
  result["comment:1"] =
      "Instead modify '${arguments[0]}' and follow the instructions therein.";
  for (String key in yaml.keys) {
    result[key] = yaml[key];
  }
  File file = new File.fromUri(output);
  String text = const JsonEncoder.withIndent("  ").convert(result);
  if (check) {
    bool needsUpdate = true;
    if (file.existsSync()) {
      String existingText = file.readAsStringSync();
      needsUpdate = text != existingText;
    }
    if (needsUpdate) {
      stderr.write('''
The file ${arguments[1]} is not up to date. Regenerate using

  dart tools/yaml2json.dart ${arguments[0]} ${arguments[1]}
''');
      exit(1);
    }
  } else {
    file.writeAsStringSync(text);
  }
  port.close();
}
