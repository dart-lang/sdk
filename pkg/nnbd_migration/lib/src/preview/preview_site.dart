// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:charcode/charcode.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:meta/meta.dart';
import 'package:nnbd_migration/src/edit_plan.dart';
import 'package:nnbd_migration/src/front_end/migration_info.dart';
import 'package:nnbd_migration/src/front_end/migration_state.dart';
import 'package:nnbd_migration/src/front_end/path_mapper.dart';
import 'package:nnbd_migration/src/front_end/web/navigation_tree.dart';
import 'package:nnbd_migration/src/preview/dart_file_page.dart';
import 'package:nnbd_migration/src/preview/dart_logo_page.dart';
import 'package:nnbd_migration/src/preview/exception_page.dart';
import 'package:nnbd_migration/src/preview/highlight_css_page.dart';
import 'package:nnbd_migration/src/preview/highlight_js_page.dart';
import 'package:nnbd_migration/src/preview/http_preview_server.dart';
import 'package:nnbd_migration/src/preview/index_file_page.dart';
import 'package:nnbd_migration/src/preview/material_icons_page.dart';
import 'package:nnbd_migration/src/preview/navigation_tree_page.dart';
import 'package:nnbd_migration/src/preview/not_found_page.dart';
import 'package:nnbd_migration/src/preview/pages.dart';
import 'package:nnbd_migration/src/preview/preview_page.dart';
import 'package:nnbd_migration/src/preview/region_page.dart';
import 'package:nnbd_migration/src/preview/roboto_mono_page.dart';
import 'package:nnbd_migration/src/preview/roboto_page.dart';
import 'package:nnbd_migration/src/preview/unauthorized_page.dart';

// The randomly generated auth token used to access the preview site.
String _makeAuthToken() {
  final kTokenByteSize = 8;
  var bytes = Uint8List(kTokenByteSize);
  var random = Random.secure();
  for (var i = 0; i < kTokenByteSize; i++) {
    bytes[i] = random.nextInt(256);
  }
  return base64Url.encode(bytes);
}

/// A plan for an incremental migration.
///
/// This plan uses [UnitMigrationStatus]es from [NavigationTreeNode]s to apply
/// different edits to different files:
///
/// * migrating files will be edited according to a [SourceFileEdit],
/// * newly opted out files will be prepended with a Dart Language Version
///   comment specifying "2.9",
/// * already opted out files will remain unchanged.
class IncrementalPlan {
  static final _nonWhitespaceChar = RegExp(r'\S');
  final MigrationInfo migrationInfo;
  final Map<String, UnitInfo> unitInfoMap;
  final PathMapper pathMapper;
  final List<SourceFileEdit> edits;
  final Logger logger;

  /// The set of units which are to be opted out in this migration.
  final Set<String> optOutUnitPaths;

  /// Creates a new [IncrementalPlan], extracting all of the paths which are
  /// "opting out" from [navigationTree].
  factory IncrementalPlan(
      MigrationInfo migrationInfo,
      Map<String, UnitInfo> unitInfoMap,
      PathMapper pathMapper,
      List<SourceFileEdit> edits,
      Iterable<NavigationTreeNode> navigationTree,
      Logger logger) {
    var optOutUnitPaths = <String>{};
    void addUnitsToOptOut(NavigationTreeNode entity) {
      if (entity is NavigationTreeDirectoryNode) {
        for (var child in entity.subtree) {
          addUnitsToOptOut(child);
        }
      } else {
        if (entity.migrationStatus == UnitMigrationStatus.optingOut) {
          optOutUnitPaths.add(entity.path);
        }
      }
    }

    for (var entity in navigationTree) {
      addUnitsToOptOut(entity);
    }

    return IncrementalPlan._(
        migrationInfo, unitInfoMap, pathMapper, edits, optOutUnitPaths, logger);
  }

  IncrementalPlan._(this.migrationInfo, this.unitInfoMap, this.pathMapper,
      this.edits, this.optOutUnitPaths, this.logger);

  /// Applies this migration to disk.
  void apply() {
    logger.stdout('Applying migration suggestions to disk...');
    var migratedFiles = <String>[];
    for (final fileEdit in edits) {
      var unit = unitInfoMap[fileEdit.file];
      // Decide whether to opt out; default to `false` files not included in
      // [edits], like [pubspec.yaml].
      var unitIsOptOut = unit != null
          ? optOutUnitPaths.contains(migrationInfo.computeName(unit))
          : false;
      if (!unitIsOptOut) {
        final file = pathMapper.provider.getFile(fileEdit.file);
        var code = file.exists ? file.readAsStringSync() : '';
        code = SourceEdit.applySequence(code, fileEdit.edits);
        file.writeAsStringSync(code);
        migratedFiles.add(migrationInfo.relativePathFromRoot(fileEdit.file));
      }
    }

    // A file which is to be opted out may not be found in [edits], if all types
    // were to be made non-nullable, etc. Iterate over [optOutUnitPaths] instead
    // of [edits] to opt files out.
    var newlyOptedOutFiles = <String>[];
    var keptOptedOutFiles = <String>[];
    for (var optOutUnitPath in optOutUnitPaths) {
      var absolutePath = migrationInfo.absolutePathFromRoot(optOutUnitPath);
      var unit = unitInfoMap[absolutePath];
      if (unit.wasExplicitlyOptedOut) {
        // This unit was explicitly opted out of null safety with a Dart
        // Language version comment. Leave the unit be.
        keptOptedOutFiles.add(optOutUnitPath);
      } else {
        // This unit was not yet migrated at the start, was not explicitly
        // opted out at the start, and is being opted out now. Add a Dart
        // Language version comment.
        final file = pathMapper.provider.getFile(absolutePath);
        var code = file.exists ? file.readAsStringSync() : '';
        file.writeAsStringSync(optCodeOutOfNullSafety(code));
        newlyOptedOutFiles.add(optOutUnitPath);
      }
    }

    _logFileStatus(migratedFiles, (text) => 'Migrated $text');
    _logFileStatus(
        newlyOptedOutFiles,
        (text) =>
            'Opted $text out of null safety with a new Dart language version '
            'comment');
    _logFileStatus(
        keptOptedOutFiles, (text) => 'Kept $text opted out of null safety');
  }

  void _logFileStatus(
      List<String> files, String Function(String text) template) {
    if (files.isNotEmpty) {
      var count = files.length;
      if (count <= 20) {
        var s = count > 1 ? 's' : '';
        var text = '$count file$s';
        logger.stdout('${template(text)}:');
        for (var path in files) {
          logger.stdout('    $path');
        }
      } else {
        var text = '$count files';
        logger.stdout('${template(text)}.');
      }
    }
  }

  @visibleForTesting
  static String optCodeOutOfNullSafety(String code) {
    var newline = '\n';
    var length = code.length;

    if (length == 0) {
      return '// @dart=2.9';
    }

    var index = 0;

    String getLine() {
      var nextIndex = code.indexOf('\n', index);
      if (nextIndex < 0) {
        // Last line.
        var line = code.substring(index);
        index = length;
        return line;
      }
      var line = code.substring(index, nextIndex);
      index = nextIndex + 1;
      return line;
    }

    // Skip past blank lines.
    var line = getLine();
    if (code.codeUnitAt(index - 1) == $lf) {
      if (index - 2 >= 0 && code.codeUnitAt(index - 2) == $cr) {
        // Looks like Windows-style line endings ("\r\n"). Use "\r\n" for all
        // inserted line endings.
        newline = '\r\n';
      }
    }
    var lineStart = line.indexOf(_nonWhitespaceChar);
    while (lineStart < 0) {
      line = getLine();
      if (index == length) {
        // [code] consists _only_ of blank lines.
        return '// @dart=2.9$newline$newline$code';
      }
      lineStart = line.indexOf(_nonWhitespaceChar);
    }

    // [line] is the first non-blank line.
    if (line.length > lineStart + 1 &&
        line.codeUnitAt(lineStart) == $slash &&
        line.codeUnitAt(lineStart + 1) == $slash) {
      // Comment.
      if (index == length) {
        // [code] consists _only_ of one comment line.
        return '$code$newline$newline// @dart=2.9$newline';
      }
      line = getLine();
      lineStart = line.indexOf(_nonWhitespaceChar);
      while (lineStart >= 0 &&
          line.length > lineStart + 1 &&
          line.codeUnitAt(lineStart) == $slash &&
          line.codeUnitAt(lineStart + 1) == $slash) {
        // Another comment line.
        line = getLine();
        if (index == length) {
          // [code] consists _only_ of this block comment.
          return '$code$newline$newline// @dart=2.9$newline';
        }
        lineStart = line.indexOf(_nonWhitespaceChar);
      }
      // [index] points to the start of [line], which is the first
      // non-comment line following the first comment.
      return '${code.substring(0, index)}$newline// @dart=2.9$newline$newline'
          '${code.substring(index)}';
    } else {
      // [code] does not start with a block comment.
      return '// @dart=2.9$newline$newline$code';
    }
  }
}

/// The site used to serve pages for the preview tool.
class PreviewSite extends Site
    implements AbstractGetHandler, AbstractPostHandler {
  /// The path of the CSS page used to style the semantic highlighting within a
  /// Dart file.
  static const highlightCssPath = '/highlight.css';

  /// The path of the JS page used to associate highlighting within a Dart file.
  static const highlightJsPath = '/highlight.pack.js';

  /// The path of the Dart logo displayed in the toolbar.
  static const dartLogoPath = '/dart_192.png';

  /// The path of the Material icons font.
  static const materialIconsPath = '/MaterialIconsRegular.ttf';

  /// The path of the Roboto font.
  static const robotoFontPath = '/RobotoRegular.ttf';

  /// The path of the Roboto Mono font.
  static const robotoMonoFontPath = '/RobotoMonoRegular.ttf';

  static const navigationTreePath = '/_preview/navigationTree.json';

  static const applyHintPath = '/apply-hint';

  static const applyMigrationPath = '/apply-migration';

  static const rerunMigrationPath = '/rerun-migration';

  /// The state of the migration being previewed.
  MigrationState migrationState;

  /// A table mapping the paths of files to the information about the
  /// compilation units at those paths.
  final Map<String, UnitInfo> unitInfoMap = {};

  // A function provided by DartFix to rerun the migration.
  final Future<MigrationState> Function() rerunFunction;

  /// Callback function that should be invoked after successfully applying
  /// migration.
  final void Function() applyHook;

  final Logger logger;

  final String serviceAuthToken = _makeAuthToken();

  /// Initialize a newly created site to serve a preview of the results of an
  /// NNBD migration.
  PreviewSite(
      this.migrationState, this.rerunFunction, this.applyHook, this.logger)
      : super('NNBD Migration Preview') {
    reset();
  }

  /// Return the information about the migration that will be used to serve up
  /// pages.
  MigrationInfo get migrationInfo => migrationState.migrationInfo;

  /// Return the path mapper used to map paths from the unit infos to the paths
  /// being served.
  PathMapper get pathMapper => migrationState.pathMapper;

  @override
  Page createExceptionPage(String message, StackTrace trace) {
    // Use createExceptionPageWithPath instead.
    throw UnimplementedError();
  }

  /// Return a page used to display an exception that occurred while attempting
  /// to render another page. The [path] is the path to the page that was being
  /// rendered when the exception was thrown. The [message] and [stackTrace] are
  /// those from the exception.
  Page createExceptionPageWithPath(
      String path, String message, StackTrace stackTrace) {
    return ExceptionPage(this, path, message, stackTrace);
  }

  /// Return a page used to display an exception that occurred while attempting
  /// to render another page. The [path] is the path to the page that was being
  /// rendered when the exception was thrown. The [message] and [stackTrace] are
  /// those from the exception.
  Page createJsonExceptionResponse(
      String path, String message, StackTrace stackTrace) {
    return ExceptionPage(this, path, message, stackTrace);
  }

  Page createUnauthorizedPage(String unauthorizedPath) {
    return UnauthorizedPage(this, unauthorizedPath.substring(1));
  }

  @override
  Page createUnknownPage(String unknownPath) {
    return NotFoundPage(this, unknownPath.substring(1));
  }

  @override
  Future<void> handleGetRequest(HttpRequest request) async {
    var uri = request.uri;
    var path = uri.path;
    var decodedPath = pathMapper.reverseMap(uri);
    try {
      if (path == highlightCssPath) {
        // Note: `return await` needed due to
        // https://github.com/dart-lang/sdk/issues/39204
        return await respond(request, HighlightCssPage(this));
      } else if (path == highlightJsPath) {
        // Note: `return await` needed due to
        // https://github.com/dart-lang/sdk/issues/39204
        return await respond(request, HighlightJSPage(this));
      } else if (path == navigationTreePath) {
        // Note: `return await` needed due to
        // https://github.com/dart-lang/sdk/issues/39204
        return await respond(request, NavigationTreePage(this));
      } else if (path == dartLogoPath) {
        // Note: `return await` needed due to
        // https://github.com/dart-lang/sdk/issues/39204
        return await respond(request, DartLogoPage(this));
      } else if (path == materialIconsPath) {
        // Note: `return await` needed due to
        // https://github.com/dart-lang/sdk/issues/39204
        return await respond(request, MaterialIconsPage(this));
      } else if (path == robotoFontPath) {
        // Note: `return await` needed due to
        // https://github.com/dart-lang/sdk/issues/39204
        return await respond(request, RobotoPage(this));
      } else if (path == robotoMonoFontPath) {
        // Note: `return await` needed due to
        // https://github.com/dart-lang/sdk/issues/39204
        return await respond(request, RobotoMonoPage(this));
      } else if (path == '/' ||
          decodedPath == migrationInfo.includedRoot ||
          decodedPath ==
              '${migrationInfo.includedRoot}${pathMapper.separator}') {
        // Note: `return await` needed due to
        // https://github.com/dart-lang/sdk/issues/39204
        return await respond(request, IndexFilePage(this));
      }

      var unitInfo = unitInfoMap[decodedPath];
      if (unitInfo != null) {
        if (uri.queryParameters.containsKey('inline')) {
          // Note: `return await` needed due to
          // https://github.com/dart-lang/sdk/issues/39204
          return await respond(request, DartFilePage(this, unitInfo));
        } else if (uri.queryParameters.containsKey('region')) {
          // Note: `return await` needed due to
          // https://github.com/dart-lang/sdk/issues/39204
          return await respond(request, RegionPage(this, unitInfo));
        } else {
          // Note: `return await` needed due to
          // https://github.com/dart-lang/sdk/issues/39204
          return await respond(request, IndexFilePage(this));
        }
      }
      // Note: `return await` needed due to
      // https://github.com/dart-lang/sdk/issues/39204
      return await respond(
          request, createUnknownPage(path), HttpStatus.notFound);
    } catch (exception, stackTrace) {
      _respondInternalError(request, path, exception, stackTrace);
    }
  }

  @override
  Future<void> handlePostRequest(HttpRequest request) async {
    var uri = request.uri;
    var path = uri.path;
    try {
      // All POST requests must be authorized.
      if (!_isAuthorized(request)) {
        return _respondUnauthorized(request);
      }
      if (path == applyMigrationPath) {
        var navigationTree =
            ((await requestBodyJson(request))['navigationTree'] as List)
                .map((encoded) => NavigationTreeNode.fromJson(encoded));
        performApply(navigationTree);

        respondOk(request);
        return;
      } else if (path == rerunMigrationPath) {
        await rerunMigration();

        if (migrationState.hasErrors) {
          return await respondJson(
              request,
              {
                'success': false,
                'errors': migrationState.analysisResult.toJson(),
              },
              HttpStatus.ok);
        } else {
          respondOk(request);
        }
        return;
      } else if (path == applyHintPath) {
        final hintAction = HintAction.fromJson(await requestBodyJson(request));
        await performHintAction(hintAction);
        respondOk(request);
        return;
      } else if (uri.queryParameters.containsKey('replacement')) {
        await performEdit(uri);

        respondOk(request);
        return;
      }
    } catch (exception, stackTrace) {
      _respondInternalError(request, path, exception, stackTrace);
    }
  }

  /// Perform the migration.
  void performApply(Iterable<NavigationTreeNode> navigationTree) {
    if (migrationState.hasBeenApplied) {
      throw StateError(
          'It looks like this migration has already been applied. Try'
          ' restarting the migration tool if this is not the case.');
    }

    final edits = migrationState.listener.sourceChange.edits;

    // Perform a full check that no files have changed before touching the disk.
    for (final fileEdit in edits) {
      final file = pathMapper.provider.getFile(fileEdit.file);
      if (!file.path.endsWith('.dart')) {
        continue;
      }
      var code = file.exists ? file.readAsStringSync() : '';
      if (!unitInfoMap[file.path].hadDiskContent(code)) {
        throw StateError('Cannot apply migration. Files on disk do not match'
            ' the expected pre-migration state. Press the "rerun from sources"'
            ' button and then try again. (Changed file path is ${file.path})');
      }
    }

    // Eagerly mark the migration applied. If this throws, we cannot go back.
    migrationState.markApplied();
    IncrementalPlan(migrationInfo, unitInfoMap, pathMapper, edits,
            navigationTree, logger)
        .apply();
    applyHook();
  }

  /// Perform the edit indicated by the [uri].
  Future<void> performEdit(Uri uri) async {
    //
    // Update the code on disk.
    //
    var params = uri.queryParameters;
    var path = pathMapper.reverseMap(uri);
    var offset = int.parse(params['offset']);
    var end = int.parse(params['end']);
    var replacement = params['replacement'];
    var file = pathMapper.provider.getFile(path);
    var diskContent = file.readAsStringSync();
    if (!unitInfoMap[path].hadDiskContent(diskContent)) {
      throw StateError('Cannot perform edit. This file has been changed since'
          ' last migration run. Press the "rerun from sources" button and then'
          ' try again. (Changed file path is ${file.path})');
    }
    final unitInfo = unitInfoMap[path];
    final diskMapper = unitInfo.diskChangesOffsetMapper;
    final diskOffsetStart = diskMapper.map(offset);
    final diskOffsetEnd = diskMapper.map(end);
    if (diskOffsetStart == null || diskOffsetEnd == null) {
      throw StateError('Cannot perform edit. Relevant code has been deleted by'
          ' a previous hint action. Rerun the migration and try again.');
    }
    unitInfo.handleSourceEdit(SourceEdit(offset, end - offset, replacement));
    migrationState.needsRerun = true;
    var newContent =
        diskContent.replaceRange(diskOffsetStart, diskOffsetEnd, replacement);
    file.writeAsStringSync(newContent);
    unitInfo.diskContent = newContent;
  }

  /// Perform the hint edit indicated by the [hintAction].
  Future<void> performHintAction(HintAction hintAction) async {
    final node = migrationState.nodeMapper.nodeForId(hintAction.nodeId);
    final edits = node.hintActions[hintAction.kind];
    if (edits == null) {
      throw StateError('This edit was not available to perform.');
    }
    //
    // Update the code on disk.
    //
    var path = node.codeReference.path;
    var file = pathMapper.provider.getFile(path);
    var diskContent = file.readAsStringSync();
    if (!unitInfoMap[path].hadDiskContent(diskContent)) {
      throw StateError('Cannot perform edit. This file has been changed since'
          ' last migration run. Press the "rerun from sources" button and then'
          ' try again. (Changed file path is ${file.path})');
    }
    final unitInfo = unitInfoMap[path];
    final diskMapper = unitInfo.diskChangesOffsetMapper;
    var newContent = diskContent;
    migrationState.needsRerun = true;
    for (final entry in edits.entries) {
      final offset = entry.key;
      final edits = entry.value;
      final diskOffset = diskMapper.map(offset);
      if (diskOffset == null) {
        throw StateError(
            'Cannot perform edit. Relevant code has been deleted by'
            ' a previous hint action. Rerun the migration and try again.');
      }
      final unmappedSourceEdit = edits.toSourceEdit(offset);
      final diskSourceEdit = edits.toSourceEdit(diskMapper.map(offset));
      unitInfo.handleSourceEdit(unmappedSourceEdit);
      newContent = diskSourceEdit.apply(newContent);
    }
    file.writeAsStringSync(newContent);
    unitInfo.diskContent = newContent;
  }

  Future<Map<String, Object>> requestBodyJson(HttpRequest request) async =>
      (await request
          .map((entry) => entry.map((i) => i.toInt()).toList())
          .transform<String>(Utf8Decoder())
          .transform(JsonDecoder())
          .single) as Map<String, Object>;

  Future<void> rerunMigration() async {
    migrationState = await rerunFunction();
    if (!migrationState.hasErrors) {
      reset();
    }
  }

  void reset() {
    unitInfoMap.clear();
    var unitInfos = migrationInfo.units;
    var provider = pathMapper.provider;
    for (var unit in unitInfos) {
      unitInfoMap[unit.path] = unit;
    }
    for (var unit in migrationInfo.unitMap.values) {
      if (!unitInfos.contains(unit)) {
        if (unit.content == null) {
          try {
            unit.content = provider.getFile(unit.path).readAsStringSync();
          } catch (_) {
            // If we can't read the content of the file, then skip it.
            continue;
          }
        }
        unitInfoMap[unit.path] = unit;
      }
    }
  }

  @override
  Future<void> respond(HttpRequest request, Page page,
      [int code = HttpStatus.ok]) async {
    if (page is PreviewPage && page.requiresAuth) {
      if (!_isAuthorized(request)) {
        return _respondUnauthorized(request);
      }
    }
    var response = request.response;
    response.statusCode = code;
    if (page is HighlightCssPage) {
      response.headers.contentType =
          ContentType('text', 'css', charset: 'utf-8');
    } else if (page is HighlightJSPage) {
      response.headers.contentType =
          ContentType('application', 'javascript', charset: 'utf-8');
    } else if (page is DartLogoPage) {
      response.headers.contentType = ContentType('image', 'png');
    } else if (page is MaterialIconsPage ||
        page is RobotoPage ||
        page is RobotoMonoPage) {
      response.headers.contentType = ContentType('font', 'ttf');
    } else {
      response.headers.contentType = ContentType.html;
    }
    response.write(await page.generate(request.uri.queryParameters));
    response.close();
  }

  /// Returns whether [request] is an authorized request.
  bool _isAuthorized(HttpRequest request) {
    var authToken = request.uri.queryParameters['authToken'];
    return authToken == serviceAuthToken;
  }

  Future<void> _respondInternalError(HttpRequest request, String path,
      dynamic exception, StackTrace stackTrace) async {
    try {
      if (request.headers.contentType.subType == 'json') {
        return await respondJson(
            request,
            {
              'success': false,
              'exception': exception.toString(),
              'stackTrace': stackTrace.toString(),
            },
            HttpStatus.internalServerError);
      }
      await respond(
          request,
          createExceptionPageWithPath(path, '$exception', stackTrace),
          HttpStatus.internalServerError);
    } catch (exception, stackTrace) {
      var response = request.response;
      response.statusCode = HttpStatus.internalServerError;
      response.headers.contentType = ContentType.text;
      response.write('$exception\n\n$stackTrace');
      response.close();
    }
  }

  /// Responds with a 401 Unauthorized response.
  Future<void> _respondUnauthorized(HttpRequest request) async {
    var page = createUnauthorizedPage(request.uri.path);
    var response = request.response;
    response
      ..statusCode = HttpStatus.unauthorized
      ..headers.contentType = ContentType.html
      ..write(await page.generate(request.uri.queryParameters))
      ..close();
  }
}
