// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show File, exit, stderr;

import 'dart:isolate' show RawReceivePort;

import 'dart:convert' show JsonEncoder;

import 'package:yaml/yaml.dart' show loadYaml;

main(List<String> rawArguments) {
  var port = new RawReceivePort();
  bool check = false;
  String? relative;
  List<String> arguments = [];
  for (String argument in rawArguments) {
    if (argument == '--check') {
      check = true;
    } else if (argument.startsWith('--relative=')) {
      relative = argument.substring('--relative='.length);
    } else {
      arguments.add(argument);
    }
  }
  if (arguments.length != 2) {
    stderr.writeln("Usage: yaml2json.dart input.yaml output.json [--check]");
    exit(1);
  }
  Uri input = new File(arguments[0]).absolute.uri;
  Uri output = new File(arguments[1]).absolute.uri;
  String inputString = arguments[0];
  String outputString = arguments[1];
  if (relative != null) {
    String relativeTo = new File(relative).absolute.uri.toString();
    if (input.toString().startsWith(relativeTo)) {
      inputString = input.toString().substring(relativeTo.length);
    }
    if (output.toString().startsWith(relativeTo)) {
      outputString = output.toString().substring(relativeTo.length);
    }
  }
  Map yaml = loadYaml(new File.fromUri(input).readAsStringSync());
  Map<String, dynamic> result = new Map<String, dynamic>();
  result["comment:0"] = "NOTE: THIS FILE IS GENERATED. DO NOT EDIT.";
  result["comment:1"] =
      "Instead modify '$inputString' and follow the instructions therein.";
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
The file $outputString is not up to date. Regenerate using

  dart tools/yaml2json.dart $inputString $outputString
''');
      exit(1);
    }
  } else {
    file.writeAsStringSync(text);
  }
  port.close();
}
