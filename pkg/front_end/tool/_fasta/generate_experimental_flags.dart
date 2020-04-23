// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show File, Platform;

import 'package:_fe_analyzer_shared/src/scanner/characters.dart'
    show $A, $MINUS, $a, $z;

import 'package:dart_style/dart_style.dart' show DartFormatter;

import 'package:yaml/yaml.dart' show YamlMap, loadYaml;

main(List<String> arguments) {
  new File.fromUri(computeCfeGeneratedFile())
      .writeAsStringSync(generateCfeFile(), flush: true);
  new File.fromUri(computeKernelGeneratedFile())
      .writeAsStringSync(generateKernelFile(), flush: true);
}

Uri computeCfeGeneratedFile() {
  return Platform.script
      .resolve("../../lib/src/api_prototype/experimental_flags.dart");
}

Uri computeKernelGeneratedFile() {
  return Platform.script
      .resolve("../../../kernel/lib/default_language_version.dart");
}

Uri computeYamlFile() {
  return Platform.script
      .resolve("../../../../tools/experimental_features.yaml");
}

String generateKernelFile() {
  Uri yamlFile = computeYamlFile();
  Map<dynamic, dynamic> yaml =
      loadYaml(new File.fromUri(yamlFile).readAsStringSync());

  int currentVersionMajor;
  int currentVersionMinor;
  {
    String currentVersion = getAsVersionNumberString(yaml['current-version']);
    List<String> split = currentVersion.split(".");
    currentVersionMajor = int.parse(split[0]);
    currentVersionMinor = int.parse(split[1]);
  }

  StringBuffer sb = new StringBuffer();

  sb.write('''
// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// NOTE: THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'tools/experimental_features.yaml' and run
// 'pkg/front_end/tool/fasta generate-experimental-flags' to update.

  int defaultLanguageVersionMajor = $currentVersionMajor;
  int defaultLanguageVersionMinor = $currentVersionMinor;
''');

  return new DartFormatter().format("$sb");
}

String generateCfeFile() {
  Uri yamlFile = computeYamlFile();
  Map<dynamic, dynamic> yaml =
      loadYaml(new File.fromUri(yamlFile).readAsStringSync());

  int currentVersionMajor;
  int currentVersionMinor;
  {
    String currentVersion = getAsVersionNumberString(yaml['current-version']);
    List<String> split = currentVersion.split(".");
    currentVersionMajor = int.parse(split[0]);
    currentVersionMinor = int.parse(split[1]);
  }

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
  for (String key in keys) {
    sb.writeln('  ${keyToIdentifier(key)},');
  }
  sb.write('''
}

''');

  for (String key in keys) {
    int major;
    int minor;
    String enabledIn =
        getAsVersionNumberString((features[key] as YamlMap)['enabledIn']);
    if (enabledIn == null) {
      major = currentVersionMajor;
      minor = currentVersionMinor;
    } else {
      List<String> split = enabledIn.split(".");
      major = int.parse(split[0]);
      minor = int.parse(split[1]);
    }
    sb.writeln('  const int enable'
        '${keyToIdentifier(key, upperCaseFirst: true)}'
        'MajorVersion = $major;');
    sb.writeln('  const int enable'
        '${keyToIdentifier(key, upperCaseFirst: true)}'
        'MinorVersion = $minor;');
  }

  sb.write('''

ExperimentalFlag parseExperimentalFlag(String flag) {
  switch (flag) {
''');
  for (String key in keys) {
    sb.writeln('    case "$key":');
    sb.writeln('     return ExperimentalFlag.${keyToIdentifier(key)};');
  }
  sb.write('''  }
  return null;
}

const Map<ExperimentalFlag, bool> defaultExperimentalFlags = {
''');
  for (String key in keys) {
    bool expired = (features[key] as YamlMap)['expired'];
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
  for (String key in keys) {
    bool expired = (features[key] as YamlMap)['expired'] == true;
    sb.writeln('  ExperimentalFlag.${keyToIdentifier(key)}: ${expired},');
  }
  sb.writeln('};');

  return new DartFormatter().format("$sb");
}

keyToIdentifier(String key, {bool upperCaseFirst = false}) {
  StringBuffer identifier = StringBuffer();
  bool first = true;
  for (int index = 0; index < key.length; ++index) {
    int code = key.codeUnitAt(index);
    if (code == $MINUS) {
      ++index;
      code = key.codeUnitAt(index);
      if ($a <= code && code <= $z) {
        code = code - $a + $A;
      }
    }
    if (first && upperCaseFirst && $a <= code && code <= $z) {
      code = code - $a + $A;
    }
    first = false;
    identifier.writeCharCode(code);
  }
  return identifier.toString();
}

String getAsVersionNumberString(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  if (value is double) return "$value";
  throw "Unexpected value: $value (${value.runtimeType})";
}
