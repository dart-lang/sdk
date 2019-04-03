// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/edit/fix/dartfix_listener.dart';
import 'package:analysis_server/src/edit/fix/dartfix_registrar.dart';
import 'package:analysis_server/src/edit/fix/fix_code_task.dart';
import 'package:analysis_server/src/nullability/provisional_api.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/task/options.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:yaml/yaml.dart';
import 'package:source_span/source_span.dart';

/// [NonNullableFix] visits each named type in a resolved compilation unit
/// and determines whether the associated variable or parameter can be null
/// then adds or removes a '?' trailing the named type as appropriate.
class NonNullableFix extends FixCodeTask {
  /// TODO(paulberry): stop using permissive mode once the migration logic is
  /// mature enough.
  static const bool _usePermissiveMode = true;

  final DartFixListener listener;

  final NullabilityMigration migration;

  /// If this flag has a value of `false`, then something happened to prevent
  /// at least one package from being marked as non-nullable.
  /// If this occurs, then don't update any code.
  bool _packageIsNNBD = true;

  NonNullableFix(this.listener)
      : migration = new NullabilityMigration(
            new NullabilityMigrationAdapter(listener),
            permissive: _usePermissiveMode);

  @override
  int get numPhases => 2;

  @override
  Future<void> finish() async {
    migration.finish();
  }

  /// If the package contains an analysis_options.yaml file, then update the
  /// file to enabled NNBD. If that file does not exist, but the package
  /// contains a pubspec.yaml, then create the analysis_options.yaml file.
  @override
  Future<void> processPackage(Folder pkgFolder) async {
    if (!_packageIsNNBD) {
      return;
    }

    // TODO(danrubel): Update pubspec.yaml to enable NNBD

    File optionsFile = pkgFolder.getChildAssumingFile('analysis_options.yaml');
    YamlNode optionsMap;
    if (optionsFile.exists) {
      try {
        optionsMap = loadYaml(optionsFile.readAsStringSync());
      } on FileSystemException catch (e) {
        listener.addRecommendation(
            'Failed to read options file: ${optionsFile.path}\n'
            '  $e\n'
            '  Manually update this file to enable non-nullable by default');
        _packageIsNNBD = false;
        return;
      } on YamlException catch (e) {
        listener.addRecommendation(
            'Failed to parse options file: ${optionsFile.path}\n'
            '  $e\n'
            '  Manually update this file to enable non-nullable by default');
        _packageIsNNBD = false;
        return;
      }
    }

    SourceSpan parentSpan;
    String content;
    YamlNode analyzerOptions;
    if (optionsMap is YamlMap) {
      analyzerOptions = optionsMap[AnalyzerOptions.analyzer];
    }
    if (analyzerOptions == null) {
      var start = new SourceLocation(0, line: 0, column: 0);
      parentSpan = new SourceSpan(start, start, '');
      content = '''
analyzer:
  enable-experiment:
    - non-nullable
''';
    } else if (analyzerOptions is YamlMap) {
      YamlNode experiments = analyzerOptions[AnalyzerOptions.enableExperiment];
      if (experiments == null) {
        parentSpan = analyzerOptions.span;
        content = '''
  enable-experiment:
    - non-nullable''';
      } else if (experiments is YamlList) {
        experiments.nodes.firstWhere(
          (node) => node.span.text == EnableString.non_nullable,
          orElse: () {
            parentSpan = experiments.span;
            content = '''
    - non-nullable''';
          },
        );
      }
    }

    if (parentSpan != null) {
      listener.addSourceFileEdit(
          'enable non-nullable analysis',
          new Location(
            optionsFile.path,
            parentSpan.end.offset,
            content.length,
            parentSpan.end.line,
            parentSpan.end.column,
          ),
          new SourceFileEdit(optionsFile.path, 0,
              edits: [new SourceEdit(parentSpan.end.offset, 0, content)]));
    }
  }

  @override
  Future<void> processUnit(int phase, ResolvedUnitResult result) async {
    if (!_packageIsNNBD) {
      return;
    }
    switch (phase) {
      case 0:
        migration.prepareInput(result);
        break;
      case 1:
        migration.processInput(result);
        break;
      default:
        throw new ArgumentError('Unsupported phase $phase');
    }
  }

  static void task(DartFixRegistrar registrar, DartFixListener listener) {
    registrar.registerCodeTask(new NonNullableFix(listener));
  }
}

class NullabilityMigrationAdapter implements NullabilityMigrationListener {
  final DartFixListener listener;

  NullabilityMigrationAdapter(this.listener);

  @override
  void addEdit(SingleNullabilityFix fix, SourceEdit edit) {
    listener.addEditWithoutSuggestion(fix.source, edit);
  }

  @override
  void addFix(SingleNullabilityFix fix) {
    // TODO(danrubel): Update the description based upon the [fix.kind]
    listener.addSuggestion(fix.kind.appliedMessage, fix.location);
  }
}
