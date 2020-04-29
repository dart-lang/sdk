// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/edit/fix/dartfix_listener.dart';
import 'package:analysis_server/src/edit/fix/dartfix_registrar.dart';
import 'package:analysis_server/src/edit/fix/fix_code_task.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:charcode/charcode.dart';
import 'package:nnbd_migration/api_for_analysis_server/dartfix_listener_interface.dart';
import 'package:nnbd_migration/api_for_analysis_server/http_preview_server.dart';
import 'package:nnbd_migration/api_for_analysis_server/instrumentation_listener.dart';
import 'package:nnbd_migration/api_for_analysis_server/migration_state.dart';
import 'package:nnbd_migration/api_for_analysis_server/nnbd_migration.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:source_span/source_span.dart';
import 'package:yaml/yaml.dart';

/// [NonNullableFix] visits each named type in a resolved compilation unit
/// and determines whether the associated variable or parameter can be null
/// then adds or removes a '?' trailing the named type as appropriate.
class NonNullableFix extends FixCodeTask {
  /// TODO(paulberry): stop using permissive mode once the migration logic is
  /// mature enough.
  static const bool _usePermissiveMode = true;

  // TODO(srawlins): Refactor to use
  //  `Feature.non_nullable.firstSupportedVersion` when this becomes non-null.
  static const String _intendedMinimumSdkVersion = '2.9.0';

  static const String _intendedSdkVersionConstraint =
      '>=$_intendedMinimumSdkVersion <2.10.0';

  final int preferredPort;

  final DartFixListenerInterface listener;

  /// The root of the included paths.
  ///
  /// The included paths may contain absolute and relative paths, non-canonical
  /// paths, and directory and file paths. The "root" is the deepest directory
  /// which all included paths share.
  final String includedRoot;

  /// Indicates whether the web preview of migration results should be launched.
  final bool enablePreview;

  /// The HTTP server that serves the preview tool.
  HttpPreviewServer _server;

  /// The port on which preview pages should be served, or `null` if no preview
  /// server should be started.
  int port;

  String authToken;

  InstrumentationListener instrumentationListener;

  NullabilityMigrationAdapter adapter;

  NullabilityMigration migration;

  /// If this flag has a value of `false`, then something happened to prevent
  /// at least one package from being marked as non-nullable.
  /// If this occurs, then don't update any code.
  bool _packageIsNNBD = true;

  Future<void> Function([List<String>]) rerunFunction;

  NonNullableFix(this.listener,
      {List<String> included = const [],
      this.preferredPort,
      this.enablePreview = true})
      : includedRoot =
            _getIncludedRoot(included, listener.server.resourceProvider) {
    reset();
  }

  @override
  int get numPhases => 3;

  /// Return a list of the URLs corresponding to the included roots.
  List<String> get previewUrls => [
        // TODO(jcollins-g): Change protocol to only return a single string.
        Uri(
            scheme: 'http',
            host: 'localhost',
            port: port,
            path: includedRoot,
            queryParameters: {'authToken': authToken}).toString()
      ];

  @override
  Future<void> finish() async {
    final state = MigrationState(
        migration, includedRoot, listener, instrumentationListener);
    await state.refresh();

    if (enablePreview && _server == null) {
      _server = HttpPreviewServer(state, rerun, preferredPort);
      _server.serveHttp();
      port = await _server.boundPort;
      authToken = await _server.authToken;
    }
  }

  /// Update the pubspec.yaml file to specify a minimum Dart SDK version which
  /// enables the Null Safety feature.
  @override
  Future<void> processPackage(Folder pkgFolder) async {
    if (!_packageIsNNBD) {
      return;
    }

    var pubspecFile = pkgFolder.getChildAssumingFile('pubspec.yaml');
    String pubspecContent;
    YamlNode pubspecMap;
    if (!pubspecFile.exists) {
      // TODO(srawlins): Handle other package types, such as Bazel.
      return;
    }

    try {
      pubspecContent = pubspecFile.readAsStringSync();
    } on FileSystemException catch (e) {
      processYamlException('read', pubspecFile.path, e);
      return;
    }
    try {
      pubspecMap = loadYaml(pubspecContent);
    } on YamlException catch (e) {
      processYamlException('parse', pubspecFile.path, e);
      return;
    }

    /// Inserts [content] into [pubspecFile], immediately after [parentSpan].
    void insertAfterParent(SourceSpan parentSpan, String content) {
      var line = parentSpan.end.line;
      var offset = parentSpan.end.offset;
      // Walk [offset] and [line] back to the first non-whitespace character
      // before [offset].
      while (offset > 0) {
        var ch = pubspecContent.codeUnitAt(offset - 1);
        if (ch == $space || ch == $cr) {
          --offset;
        } else if (ch == $lf) {
          --offset;
          --line;
        } else {
          break;
        }
      }
      var edit = SourceEdit(offset, 0, content);
      listener.addSourceFileEdit(
          'enable Null Safety language feature',
          Location(pubspecFile.path, offset, content.length, line, 0),
          SourceFileEdit(pubspecFile.path, 0, edits: [edit]));
    }

    void replaceSpan(SourceSpan span, String content) {
      var line = span.start.line;
      var offset = span.start.offset;
      var edit = SourceEdit(offset, span.length, content);
      listener.addSourceFileEdit(
          'enable Null Safety language feature',
          Location(pubspecFile.path, offset, content.length, line, 0),
          SourceFileEdit(pubspecFile.path, 0, edits: [edit]));
    }

    YamlNode environmentOptions;
    if (pubspecMap is YamlMap) {
      environmentOptions = pubspecMap.nodes['environment'];
    }
    if (environmentOptions == null) {
      var start = SourceLocation(0, line: 0, column: 0);
      var content = '''
environment:
  sdk: '$_intendedSdkVersionConstraint'

''';
      insertAfterParent(SourceSpan(start, start, ''), content);
    } else if (environmentOptions is YamlMap) {
      var sdk = environmentOptions.nodes['sdk'];
      if (sdk == null) {
        var content = """

  sdk: '$_intendedSdkVersionConstraint'""";
        insertAfterParent(environmentOptions.span, content);
      } else if (sdk is YamlScalar) {
        var currentConstraint = VersionConstraint.parse(sdk.value);
        var minimumVersion = Version.parse(_intendedMinimumSdkVersion);
        if (currentConstraint is VersionRange &&
            currentConstraint.min >= minimumVersion) {
          // The current SDK version constraint already enables Null Safety.
          return;
        } else {
          // TODO(srawlins): This overwrites the current maximum version. In
          // the uncommon situation that the maximum is not '<3.0.0', it should
          // not.
          replaceSpan(sdk.span, "'$_intendedSdkVersionConstraint'");
        }
      }
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
      case 2:
        migration.finalizeInput(result);
        break;
      default:
        throw ArgumentError('Unsupported phase $phase');
    }
  }

  void processYamlException(String action, String optionsFilePath, error) {
    listener.addRecommendation('''Failed to $action options file
  $optionsFilePath
  $error

  Manually update this file to enable the Null Safety language feature by
  adding:

    environment:
      sdk: '$_intendedSdkVersionConstraint';
''');
    _packageIsNNBD = false;
  }

  Future<MigrationState> rerun([List<String> changedPaths]) async {
    reset();
    await rerunFunction(changedPaths);
    final state = MigrationState(
        migration, includedRoot, listener, instrumentationListener);
    await state.refresh();
    return state;
  }

  void reset() {
    instrumentationListener = InstrumentationListener();
    adapter = NullabilityMigrationAdapter(listener);
    migration = NullabilityMigration(adapter,
        permissive: _usePermissiveMode,
        instrumentation: instrumentationListener);
  }

  void shutdownServer() {
    _server?.close();
  }

  static void task(DartFixRegistrar registrar, DartFixListener listener,
      EditDartfixParams params) {
    registrar.registerCodeTask(NonNullableFix(listener,
        included: params.included, preferredPort: params.port));
  }

  /// Get the "root" of all [included] paths. See [includedRoot] for its
  /// definition.
  static String _getIncludedRoot(
      List<String> included, ResourceProvider provider) {
    var context = provider.pathContext;
    // This step looks like it may be expensive (`getResource`, splitting up
    // all of the paths, comparing parts, joining one path back together). In
    // practice, this should be cheap because typically only one path is given
    // to dartfix.
    var rootParts = included
        .map((p) => context.normalize(context.absolute(p)))
        .map((p) => provider.getResource(p) is File ? context.dirname(p) : p)
        .map((p) => context.split(p))
        .reduce((value, parts) {
      var shorterPath = value.length < parts.length ? value : parts;
      var length = shorterPath.length;
      for (var i = 0; i < length; i++) {
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
  final DartFixListenerInterface listener;

  NullabilityMigrationAdapter(this.listener);

  @override
  void addEdit(Source source, SourceEdit edit) {
    listener.addEditWithoutSuggestion(source, edit);
  }

  @override
  void addSuggestion(String descriptions, Location location) {
    listener.addSuggestion(descriptions, location);
  }

  @override
  void reportException(
      Source source, AstNode node, Object exception, StackTrace stackTrace) {
    listener.addDetail('''
$exception

$stackTrace''');
  }
}
