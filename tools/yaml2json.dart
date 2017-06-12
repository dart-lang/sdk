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
  var yaml = loadYaml(await new File.fromUri(input).readAsString());
  await new File.fromUri(output)
      .writeAsString(const JsonEncoder.withIndent("  ").convert(yaml));
  port.close();
}
