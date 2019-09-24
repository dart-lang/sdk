// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/edit/fix/dartfix_listener.dart';
import 'package:analysis_server/src/edit/fix/dartfix_registrar.dart';
import 'package:analysis_server/src/edit/fix/fix_code_task.dart';
import 'package:analysis_server/src/edit/nnbd_migration/info_builder.dart';
import 'package:analysis_server/src/edit/nnbd_migration/instrumentation_listener.dart';
import 'package:analysis_server/src/edit/nnbd_migration/instrumentation_renderer.dart';
import 'package:analysis_server/src/edit/nnbd_migration/migration_info.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/overlay_file_system.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/task/options.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:nnbd_migration/nnbd_migration.dart';
import 'package:source_span/source_span.dart';
import 'package:yaml/yaml.dart';

/// [NonNullableFix] visits each named type in a resolved compilation unit
/// and determines whether the associated variable or parameter can be null
/// then adds or removes a '?' trailing the named type as appropriate.
class NonNullableFix extends FixCodeTask {
  /// TODO(paulberry): stop using permissive mode once the migration logic is
  /// mature enough.
  static const bool _usePermissiveMode = true;

  final DartFixListener listener;

  final String outputDir;

  InstrumentationListener instrumentationListener;

  NullabilityMigration migration;

  /// If this flag has a value of `false`, then something happened to prevent
  /// at least one package from being marked as non-nullable.
  /// If this occurs, then don't update any code.
  bool _packageIsNNBD = true;

  NonNullableFix(this.listener, this.outputDir) {
    instrumentationListener =
        outputDir == null ? null : InstrumentationListener();
    migration = new NullabilityMigration(
        new NullabilityMigrationAdapter(listener),
        permissive: _usePermissiveMode,
        instrumentation: instrumentationListener);
  }

  @override
  int get numPhases => 2;

  @override
  Future<void> finish() async {
    migration.finish();
    if (outputDir != null) {
      OverlayResourceProvider provider = listener.server.resourceProvider;
      Folder outputFolder = provider.getFolder(outputDir);
      if (!outputFolder.exists) {
        outputFolder.create();
      }
      await _generateOutput(provider, outputFolder);
    }
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
    String optionsContent;
    YamlNode optionsMap;
    if (optionsFile.exists) {
      try {
        optionsContent = optionsFile.readAsStringSync();
      } on FileSystemException catch (e) {
        processYamlException('read', optionsFile.path, e);
        return;
      }
      try {
        optionsMap = loadYaml(optionsContent);
      } on YamlException catch (e) {
        processYamlException('parse', optionsFile.path, e);
        return;
      }
    }

    SourceSpan parentSpan;
    String content;
    YamlNode analyzerOptions;
    if (optionsMap is YamlMap) {
      analyzerOptions = optionsMap.nodes[AnalyzerOptions.analyzer];
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
      YamlNode experiments =
          analyzerOptions.nodes[AnalyzerOptions.enableExperiment];
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
            return null;
          },
        );
      }
    }

    if (parentSpan != null) {
      final space = ' '.codeUnitAt(0);
      final cr = '\r'.codeUnitAt(0);
      final lf = '\n'.codeUnitAt(0);

      int line = parentSpan.end.line;
      int offset = parentSpan.end.offset;
      while (offset > 0) {
        int ch = optionsContent.codeUnitAt(offset - 1);
        if (ch == space || ch == cr) {
          --offset;
        } else if (ch == lf) {
          --offset;
          --line;
        } else {
          break;
        }
      }
      listener.addSourceFileEdit(
          'enable non-nullable analysis',
          new Location(
            optionsFile.path,
            offset,
            content.length,
            line,
            0,
          ),
          new SourceFileEdit(optionsFile.path, 0,
              edits: [new SourceEdit(offset, 0, content)]));
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

  void processYamlException(String action, String optionsFilePath, error) {
    listener.addRecommendation('''Failed to $action options file
  $optionsFilePath
  $error

  Manually update this file to enable non-nullable by adding:

    analyzer:
      enable-experiment:
        - non-nullable
''');
    _packageIsNNBD = false;
  }

  /// Generate output into the given [folder].
  void _generateOutput(OverlayResourceProvider provider, Folder folder) async {
    List<LibraryInfo> libraryInfos = await InfoBuilder(listener.server)
        .explainMigration(instrumentationListener.data, listener);
    listener.addDetail('libraryInfos has ${libraryInfos.length} libs');
    for (LibraryInfo info in libraryInfos) {
      var pathContext = provider.pathContext;
      var libraryPath =
          pathContext.setExtension(info.units.first.path, '.html');
      // TODO(srawlins): Choose a better scheme than the double underscores,
      // likely with actual directories, which need to be individually created.
      // TODO(srawlins): Choose a better root for the relative paths. These
      // could be complex, as dartfix can be executed with multiple directories
      // (relative, absolute) and/or files.
      var relativePath = pathContext
          .relative(libraryPath, from: provider.pathContext.current)
          .replaceAll('/', '__');
      File output = folder.getChildAssumingFile(relativePath);
      String rendered = InstrumentationRenderer(info).render();
      output.writeAsStringSync(rendered);
    }
  }

  static void task(DartFixRegistrar registrar, DartFixListener listener,
      EditDartfixParams params) {
    registrar.registerCodeTask(new NonNullableFix(listener, params.outputDir));
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
    listener.addSuggestion(fix.description.appliedMessage, fix.location);
  }

  @override
  void reportException(
      Source source, AstNode node, Object exception, StackTrace stackTrace) {
    listener.addDetail('''
$exception

$stackTrace''');
  }
}
