/**
 * This file contains code to generate experimental flags
 * based on the information in tools/experimental_features.yaml.
 */
import 'dart:io';

import 'package:analysis_tool/tools.dart';
import 'package:front_end/src/fasta/scanner/characters.dart' show $MINUS, $_;
import 'package:path/path.dart';
import 'package:yaml/yaml.dart' show YamlMap, loadYaml;

import '../../test/utils/package_root.dart' as pkg_root;

main() async {
  await GeneratedContent.generateAll(
      normalize(join(pkg_root.packageRoot, 'analyzer')), allTargets);
}

List<GeneratedContent> get allTargets {
  Map<dynamic, dynamic> experimentsYaml = loadYaml(new File(join(
          normalize(join(pkg_root.packageRoot, '../tools')),
          'experimental_features.yaml'))
      .readAsStringSync());

  return <GeneratedContent>[
    new GeneratedFile('lib/src/dart/analysis/experiments.g.dart',
        (String pkgPath) async {
      var generator = new _ExperimentsGenerator(experimentsYaml);
      generator.generateFormatCode();
      return generator.out.toString();
    }),
  ];
}

String keyToIdentifier(String key) {
  var identifier = StringBuffer();
  for (int index = 0; index < key.length; ++index) {
    var code = key.codeUnitAt(index);
    if (code == $MINUS) {
      code = $_;
    }
    identifier.writeCharCode(code);
  }
  return identifier.toString();
}

class _ExperimentsGenerator {
  final Map experimentsYaml;

  List<String> keysSorted;

  final out = new StringBuffer('''
//
// THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'tools/experimental_features.yaml' and run
// 'dart pkg/analyzer/tool/experiments/generate.dart' to update.

part of 'experiments.dart';
''');

  _ExperimentsGenerator(this.experimentsYaml);

  void generateFormatCode() {
    keysSorted = experimentsYaml.keys.cast<String>().toList()..sort();
    generateSection_KnownFeatures();
    generateSection_BuildExperimentalFlagsArray();
    generateSection_EnableString();
    generateSection_ExperimentalFeature();
    generateSection_IsEnabledByDefault();
    generateSection_IsExpired();
    generateSection_CurrentState();
  }

  void generateSection_BuildExperimentalFlagsArray() {
    out.write('''

List<bool> _buildExperimentalFlagsArray() => <bool>[
''');
    for (var key in keysSorted) {
      var id = keyToIdentifier(key);
      var entry = experimentsYaml[key] as YamlMap;
      bool shipped = entry['enabledIn'] != null;
      bool expired = entry['expired'];
      if (shipped || expired == true) {
        out.writeln('true, // $key');
      } else {
        out.writeln('IsEnabledByDefault.$id,');
      }
    }
    // TODO(danrubel): Remove bogus entries
    out.write('''
      false, // bogus-disabled
      true, // bogus-enabled
    ];
''');
  }

  void generateSection_CurrentState() {
    // TODO(danrubel): Remove bogus entries
    out.write('''

mixin _CurrentState {
  /// Current state for the flag "bogus-disabled"
  @deprecated
  bool get bogus_disabled => isEnabled(ExperimentalFeatures.bogus_disabled);

  /// Current state for the flag "bogus-enabled"
  @deprecated
  bool get bogus_enabled => isEnabled(ExperimentalFeatures.bogus_enabled);
''');
    for (var key in keysSorted) {
      var id = keyToIdentifier(key);
      out.write('''
  /// Current state for the flag "$key"
  bool get $id => isEnabled(ExperimentalFeatures.$id);
    ''');
    }
    out.write('''

  bool isEnabled(covariant ExperimentalFeature feature);
}''');
  }

  void generateSection_EnableString() {
    out.write('''

/// Constant strings for enabling each of the currently known experimental
/// flags.
class EnableString {
''');
    for (var key in keysSorted) {
      out.write('''
      /// String to enable the experiment "$key"
      static const String ${keyToIdentifier(key)} = '$key';
    ''');
    }
    // TODO(danrubel): Remove bogus entries
    out.write('''

      /// String to enable the experiment "bogus-disabled"
      @deprecated
      static const String bogus_disabled = 'bogus-disabled';

      /// String to enable the experiment "bogus-enabled"
      @deprecated
      static const String bogus_enabled = 'bogus-enabled';
    }''');
  }

  void generateSection_ExperimentalFeature() {
    out.write('''

class ExperimentalFeatures {
''');
    int index = 0;
    for (var key in keysSorted) {
      var id = keyToIdentifier(key);
      var help = (experimentsYaml[key] as YamlMap)['help'] ?? '';
      var enabledIn = (experimentsYaml[key] as YamlMap)['enabledIn'];
      out.write('''

      static const $id = const ExperimentalFeature(
      $index,
      EnableString.$id,
      IsEnabledByDefault.$id,
      IsExpired.$id,
      '$help'
    ''');
      if (enabledIn != null) {
        if (enabledIn is double) {
          enabledIn = '$enabledIn.0';
        }
        out.write(",firstSupportedVersion: '$enabledIn'");
      }
      out.writeln(');');
      ++index;
    }
    // TODO(danrubel): Remove bogus entries
    out.write('''

      @deprecated
      static const bogus_disabled = const ExperimentalFeature(
        $index,
        // ignore: deprecated_member_use_from_same_package
        EnableString.bogus_disabled,
        IsEnabledByDefault.bogus_disabled,
        IsExpired.bogus_disabled,
        null);

      @deprecated
      static const bogus_enabled = const ExperimentalFeature(
        ${index + 1},
        // ignore: deprecated_member_use_from_same_package
        EnableString.bogus_enabled,
        IsEnabledByDefault.bogus_enabled,
        IsExpired.bogus_enabled,
        null,
        firstSupportedVersion: '1.0.0');
    }''');
  }

  void generateSection_IsEnabledByDefault() {
    out.write('''

/// Constant bools indicating whether each experimental flag is currently
/// enabled by default.
class IsEnabledByDefault {
''');
    for (var key in keysSorted) {
      var entry = experimentsYaml[key] as YamlMap;
      bool shipped = entry['enabledIn'] != null;
      out.write('''
      /// Default state of the experiment "$key"
      static const bool ${keyToIdentifier(key)} = $shipped;
    ''');
    }
    // TODO(danrubel): Remove bogus entries
    out.write('''

      /// Default state of the experiment "bogus-disabled"
      @deprecated
      static const bool bogus_disabled = false;

      /// Default state of the experiment "bogus-enabled"
      @deprecated
      static const bool bogus_enabled = true;
    }''');
  }

  void generateSection_IsExpired() {
    out.write('''

/// Constant bools indicating whether each experimental flag is currently
/// expired (meaning its enable/disable status can no longer be altered from the
/// value in [IsEnabledByDefault]).
class IsExpired {
''');
    for (var key in keysSorted) {
      var entry = experimentsYaml[key] as YamlMap;
      bool shipped = entry['enabledIn'] != null;
      bool expired = entry['expired'];
      out.write('''
      /// Expiration status of the experiment "$key"
      static const bool ${keyToIdentifier(key)} = ${expired == true};
    ''');
      if (shipped && expired == false) {
        throw 'Cannot mark shipped feature as "expired: false"';
      }
    }
    // TODO(danrubel): Remove bogus entries
    out.write('''

      /// Expiration status of the experiment "bogus-disabled"
      static const bool bogus_disabled = true;

      /// Expiration status of the experiment "bogus-enabled"
      static const bool bogus_enabled = true;
    }''');
  }

  void generateSection_KnownFeatures() {
    out.write('''

/// A map containing information about all known experimental flags.
const _knownFeatures = <String, ExperimentalFeature>{
''');
    for (var key in keysSorted) {
      var id = keyToIdentifier(key);
      out.write('''
  EnableString.$id: ExperimentalFeatures.$id,
    ''');
    }
    // TODO(danrubel): Remove bogus entries
    out.write('''

  // ignore: deprecated_member_use_from_same_package
  EnableString.bogus_disabled: ExperimentalFeatures.bogus_disabled,
  // ignore: deprecated_member_use_from_same_package
  EnableString.bogus_enabled: ExperimentalFeatures.bogus_enabled,
};
''');
  }
}
