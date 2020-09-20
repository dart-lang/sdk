// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show File, Platform;

import 'package:_fe_analyzer_shared/src/scanner/characters.dart'
    show $A, $MINUS, $a, $z;

import 'package:_fe_analyzer_shared/src/sdk/allowed_experiments.dart';

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
      .resolve("../../lib/src/api_prototype/experimental_flags_generated.dart");
}

Uri computeKernelGeneratedFile() {
  return Platform.script
      .resolve("../../../kernel/lib/default_language_version.dart");
}

Uri computeYamlFile() {
  return Platform.script
      .resolve("../../../../tools/experimental_features.yaml");
}

Uri computeAllowListFile() {
  return Platform.script
      .resolve("../../../../sdk/lib/_internal/allowed_experiments.json");
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
// 'dart pkg/front_end/tool/fasta.dart generate-experimental-flags' to update.

import "ast.dart";

Version defaultLanguageVersion = const Version($currentVersionMajor, $currentVersionMinor);
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
// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// NOTE: THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'tools/experimental_features.yaml' and run
// 'dart pkg/front_end/tool/fasta.dart generate-experimental-flags' to update.

part of 'experimental_flags.dart';
''');

  Map<String, dynamic> features = {};
  Map<dynamic, dynamic> yamlFeatures = yaml['features'];
  for (MapEntry<dynamic, dynamic> entry in yamlFeatures.entries) {
    String category = entry.value["category"] ?? "language";
    if (category != "language" && category != "CFE") {
      // Skip a feature with a category that's not language or CFE.
      // In the future we might want to generate different code for different
      // things.
      continue;
    }
    features[entry.key] = entry.value;
  }

  List<String> keys = features.keys.toList()..sort();

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
    sb.writeln('  const Version enable'
        '${keyToIdentifier(key, upperCaseFirst: true)}'
        'Version = const Version($major, $minor);');
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
  sb.write('''
};

const Map<ExperimentalFlag, Version> experimentEnabledVersion = {
''');
  for (String key in keys) {
    int major;
    int minor;
    String enabledIn =
        getAsVersionNumberString((features[key] as YamlMap)['enabledIn']);
    if (enabledIn != null) {
      List<String> split = enabledIn.split(".");
      major = int.parse(split[0]);
      minor = int.parse(split[1]);
    } else {
      major = currentVersionMajor;
      minor = currentVersionMinor;
    }
    sb.writeln('  ExperimentalFlag.${keyToIdentifier(key)}: '
        'const Version($major, $minor),');
  }
  sb.write('''
};

const Map<ExperimentalFlag, Version> experimentReleasedVersion = {
''');
  for (String key in keys) {
    int major;
    int minor;
    String enabledIn =
        getAsVersionNumberString((features[key] as YamlMap)['enabledIn']);
    String experimentalReleaseVersion = getAsVersionNumberString(
        (features[key] as YamlMap)['experimentalReleaseVersion']);
    if (experimentalReleaseVersion != null) {
      List<String> split = experimentalReleaseVersion.split(".");
      major = int.parse(split[0]);
      minor = int.parse(split[1]);
    } else if (enabledIn != null) {
      List<String> split = enabledIn.split(".");
      major = int.parse(split[0]);
      minor = int.parse(split[1]);
    } else {
      major = currentVersionMajor;
      minor = currentVersionMinor;
    }
    sb.writeln('  ExperimentalFlag.${keyToIdentifier(key)}: '
        'const Version($major, $minor),');
  }
  sb.write('''
};
  
''');

  Uri allowListFile = computeAllowListFile();
  AllowedExperiments allowedExperiments = parseAllowedExperiments(
      new File.fromUri(allowListFile).readAsStringSync());

  sb.write('''
const AllowedExperimentalFlags defaultAllowedExperimentalFlags =
    const AllowedExperimentalFlags(
''');
  sb.writeln('sdkDefaultExperiments: {');
  for (String sdkDefaultExperiment
      in allowedExperiments.sdkDefaultExperiments) {
    sb.writeln('ExperimentalFlag.${keyToIdentifier(sdkDefaultExperiment)},');
  }
  sb.writeln('},');
  sb.writeln('sdkLibraryExperiments: {');
  allowedExperiments.sdkLibraryExperiments
      .forEach((String library, List<String> experiments) {
    sb.writeln('"$library": {');
    for (String experiment in experiments) {
      sb.writeln('ExperimentalFlag.${keyToIdentifier(experiment)},');
    }
    sb.writeln('},');
  });
  sb.writeln('},');
  sb.writeln('packageExperiments: {');
  allowedExperiments.packageExperiments
      .forEach((String package, List<String> experiments) {
    sb.writeln('"$package": {');
    for (String experiment in experiments) {
      sb.writeln('ExperimentalFlag.${keyToIdentifier(experiment)},');
    }
    sb.writeln('},');
  });
  sb.writeln('});');

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
