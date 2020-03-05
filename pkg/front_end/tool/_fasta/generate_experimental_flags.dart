// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'dart:io';

import 'dart:isolate';

import 'package:_fe_analyzer_shared/src/scanner/characters.dart'
    show $A, $MINUS, $a, $z;

import 'package:dart_style/dart_style.dart' show DartFormatter;

import 'package:yaml/yaml.dart' show YamlMap, loadYaml;

main(List<String> arguments) async {
  var port = new ReceivePort();
  await new File.fromUri(await computeGeneratedFile())
      .writeAsString(await generateMessagesFile(), flush: true);
  port.close();
}

Future<Uri> computeGeneratedFile() {
  return Isolate.resolvePackageUri(
      Uri.parse('package:front_end/src/api_prototype/experimental_flags.dart'));
}

Future<String> generateMessagesFile() async {
  Uri messagesFile =
      Platform.script.resolve("../../../../tools/experimental_features.yaml");
  Map<dynamic, dynamic> yaml =
      loadYaml(await new File.fromUri(messagesFile).readAsStringSync());
  StringBuffer sb = new StringBuffer();

  sb.write('''
// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// NOTE: THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'tools/experimental_features.yaml' and run
// 'pkg/front_end/tool/fasta generate-experimental-flags' to update.
''');

  Map<dynamic, dynamic> features = yaml['features'];

  List<String> keys = features.keys.cast<String>().toList()..sort();

  sb.write('''

enum ExperimentalFlag {
''');
  for (var key in keys) {
    sb.writeln('  ${keyToIdentifier(key)},');
  }
  sb.write('''
}

ExperimentalFlag parseExperimentalFlag(String flag) {
  switch (flag) {
''');
  for (var key in keys) {
    sb.writeln('    case "$key":');
    sb.writeln('     return ExperimentalFlag.${keyToIdentifier(key)};');
  }
  sb.write('''  }
  return null;
}

const Map<ExperimentalFlag, bool> defaultExperimentalFlags = {
''');
  for (var key in keys) {
    var expired = (features[key] as YamlMap)['expired'];
    bool shipped = (features[key] as YamlMap)['enabledIn'] != null;
    sb.writeln('  ExperimentalFlag.${keyToIdentifier(key)}: ${shipped},');
    if (shipped) {
      if (expired == false) {
        throw 'Cannot mark shipped feature as "expired: false"';
      }
    }
  }
  sb.write('''
};

const Map<ExperimentalFlag, bool> expiredExperimentalFlags = {
''');
  for (var key in keys) {
    bool expired = (features[key] as YamlMap)['expired'] == true;
    sb.writeln('  ExperimentalFlag.${keyToIdentifier(key)}: ${expired},');
  }
  sb.writeln('};');

  return new DartFormatter().format("$sb");
}

keyToIdentifier(String key) {
  var identifier = StringBuffer();
  for (int index = 0; index < key.length; ++index) {
    var code = key.codeUnitAt(index);
    if (code == $MINUS) {
      ++index;
      code = key.codeUnitAt(index);
      if ($a <= code && code <= $z) {
        code = code - $a + $A;
      }
    }
    identifier.writeCharCode(code);
  }
  return identifier.toString();
}
