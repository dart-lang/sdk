// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/edit/fix/dartfix_listener.dart';
import 'package:analysis_server/src/edit/fix/dartfix_registrar.dart';
import 'package:analysis_server/src/edit/fix/fix_code_task.dart';
import 'package:analysis_server/src/edit/nnbd_migration/highlight_css.dart';
import 'package:analysis_server/src/edit/nnbd_migration/highlight_js.dart';
import 'package:analysis_server/src/edit/nnbd_migration/index_renderer.dart';
import 'package:analysis_server/src/edit/nnbd_migration/info_builder.dart';
import 'package:analysis_server/src/edit/nnbd_migration/instrumentation_listener.dart';
import 'package:analysis_server/src/edit/nnbd_migration/instrumentation_renderer.dart';
import 'package:analysis_server/src/edit/nnbd_migration/migration_info.dart';
import 'package:analysis_server/src/edit/nnbd_migration/path_mapper.dart';
import 'package:analysis_server/src/edit/preview/http_preview_server.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/overlay_file_system.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/task/options.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:nnbd_migration/nnbd_migration.dart';
import 'package:path/path.dart' as path;
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

  /// The root of the included paths.
  ///
  /// The included paths may contain absolute and relative paths, non-canonical
  /// paths, and directory and file paths. The "root" is the deepest directory
  /// which all included paths share.
  ///
  /// If instrumentation files are written to [outputDir], they will be written
  /// as if in a directory structure rooted at [includedRoot].
  final String includedRoot;

  /// The absolute path of the directory to which preview pages are to be
  /// written, or `null` if no preview pages should be written to disk.
  final String outputDir;

  /// The port on which preview pages should be served, or `null` if no preview
  /// server should be started.
  final int port;

  InstrumentationListener instrumentationListener;

  NullabilityMigration migration;

  /// If this flag has a value of `false`, then something happened to prevent
  /// at least one package from being marked as non-nullable.
  /// If this occurs, then don't update any code.
  bool _packageIsNNBD = true;

  NonNullableFix(this.listener, this.outputDir, this.port,
      {List<String> included = const []})
      : this.includedRoot =
            _getIncludedRoot(included, listener.server.resourceProvider) {
    instrumentationListener =
        outputDir == null && port == null ? null : InstrumentationListener();
    migration = new NullabilityMigration(
        new NullabilityMigrationAdapter(listener),
        permissive: _usePermissiveMode,
        instrumentation: instrumentationListener);
  }

  @override
  int get numPhases => 2;

  /// Return a list of the Urls corresponding to the included roots.
  List<String> get previewUrls => [
        Uri(scheme: 'http', host: 'localhost', port: port, path: includedRoot)
            .toString()
      ];

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
    if (port != null) {
      OverlayResourceProvider provider = listener.server.resourceProvider;
      InfoBuilder infoBuilder = InfoBuilder(
          provider, includedRoot, instrumentationListener.data, listener);
      Set<UnitInfo> unitInfos = await infoBuilder.explainMigration();
      var pathContext = provider.pathContext;
      MigrationInfo migrationInfo = MigrationInfo(
          unitInfos, infoBuilder.unitMap, pathContext, includedRoot);
      PathMapper pathMapper = PathMapper(provider, outputDir, includedRoot);

      print(Uri(
          scheme: 'http', host: 'localhost', port: port, path: includedRoot));

      // TODO(brianwilkerson) Capture the server so that it can be closed
      //  cleanly.
      HttpPreviewServer(migrationInfo, pathMapper).serveHttp(port);
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
    // Remove any previously generated output.
    folder.getChildren().forEach((resource) => resource.delete());
    // Gather the data needed in order to produce the output.
    InfoBuilder infoBuilder = InfoBuilder(
        provider, includedRoot, instrumentationListener.data, listener);
    Set<UnitInfo> unitInfos = await infoBuilder.explainMigration();
    var pathContext = provider.pathContext;
    MigrationInfo migrationInfo = MigrationInfo(
        unitInfos, infoBuilder.unitMap, pathContext, includedRoot);
    PathMapper pathMapper = PathMapper(provider, folder.path, includedRoot);

    /// Produce output for the compilation unit represented by the [unitInfo].
    void render(UnitInfo unitInfo) {
      File output = provider.getFile(pathMapper.map(unitInfo.path));
      output.parent.create();
      String rendered =
          InstrumentationRenderer(unitInfo, migrationInfo, pathMapper).render();
      output.writeAsStringSync(rendered);
    }

    //
    // Generate the index file.
    //
    String indexPath = pathContext.join(folder.path, 'index.html');
    File output = provider.getFile(indexPath);
    output.parent.create();
    String rendered = IndexRenderer(migrationInfo, writeToDisk: true).render();
    output.writeAsStringSync(rendered);
    //
    // Generate the files in the package being migrated.
    //
    for (UnitInfo unitInfo in unitInfos) {
      render(unitInfo);
    }
    //
    // Generate other dart files.
    //
    for (UnitInfo unitInfo in infoBuilder.unitMap.values) {
      if (!unitInfos.contains(unitInfo)) {
        if (unitInfo.content == null) {
          try {
            unitInfo.content =
                provider.getFile(unitInfo.path).readAsStringSync();
          } catch (_) {
            // If we can't read the content of the file, then skip it.
            continue;
          }
        }
        render(unitInfo);
      }
    }
    // Generate resource files.
    File highlightJsOutput =
        provider.getFile(pathContext.join(folder.path, 'highlight.pack.js'));
    highlightJsOutput.writeAsStringSync(decodeHighlightJs());
    File highlightCssOutput =
        provider.getFile(pathContext.join(folder.path, 'androidstudio.css'));
    highlightCssOutput.writeAsStringSync(decodeHighlightCss());
  }

  static void task(DartFixRegistrar registrar, DartFixListener listener,
      EditDartfixParams params) {
    registrar.registerCodeTask(new NonNullableFix(
        listener, params.outputDir, params.port,
        included: params.included));
  }

  /// Get the "root" of all [included] paths. See [includedRoot] for its
  /// definition.
  static String _getIncludedRoot(
      List<String> included, OverlayResourceProvider provider) {
    path.Context context = provider.pathContext;
    // This step looks like it may be expensive (`getResource`, splitting up
    // all of the paths, comparing parts, joining one path back together). In
    // practice, this should be cheap because typically only one path is given
    // to dartfix.
    List<String> rootParts = included
        .map((p) => context.absolute(context.canonicalize(p)))
        .map((p) => provider.getResource(p) is File ? context.dirname(p) : p)
        .map((p) => context.split(p))
        .reduce((value, parts) {
      List<String> shorterPath = value.length < parts.length ? value : parts;
      int length = shorterPath.length;
      for (int i = 0; i < length; i++) {
        if (value[i] != parts[i]) {
          // [value] and [parts] are the same, only up to part [i].
          return value.sublist(0, i);
        }
      }
      // [value] and [parts] are the same up to the full length of the shorter
      // of the two, so just return that.
      return shorterPath;
    });
    return context.joinAll(rootParts);
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
    for (Location location in fix.locations) {
      listener.addSuggestion(fix.description.appliedMessage, location);
    }
  }

  @override
  void reportException(
      Source source, AstNode node, Object exception, StackTrace stackTrace) {
    listener.addDetail('''
$exception

$stackTrace''');
  }
}
