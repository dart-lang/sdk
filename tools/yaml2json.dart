// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show File, exit, stderr;

import 'dart:isolate' show RawReceivePort;

import 'dart:convert' show JsonEncoder;

import 'package:yaml/yaml.dart' show loadYaml;

main(List<String> arguments) async {
  var port = new RawReceivePort();
  if (arguments.length != 2) {
    stderr.writeln("Usage: yaml2json.dart input.yaml output.json");
    exit(1);
  }
  Uri input = Uri.base.resolve(arguments[0]);
  Uri output = Uri.base.resolve(arguments[1]);
  Map yaml = loadYaml(await new File.fromUri(input).readAsString());
  Map<String, dynamic> result = new Map<String, dynamic>();
  result["comment:0"] = "NOTE: THIS FILE IS GENERATED. DO NOT EDIT.";
  result["comment:1"] =
      "Instead modify '${arguments[0]}' and follow the instructions therein.";
  for (String key in yaml.keys) {
    result[key] = yaml[key];
  }
  File file = new File.fromUri(output);
  await file.writeAsString(const JsonEncoder.withIndent("  ").convert(result));
  port.close();
}
