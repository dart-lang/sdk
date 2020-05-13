// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:analysis_server/src/status/pages.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:nnbd_migration/src/front_end/migration_info.dart';
import 'package:nnbd_migration/src/front_end/migration_state.dart';
import 'package:nnbd_migration/src/front_end/path_mapper.dart';
import 'package:nnbd_migration/src/preview/dart_file_page.dart';
import 'package:nnbd_migration/src/preview/exception_page.dart';
import 'package:nnbd_migration/src/preview/highlight_css_page.dart';
import 'package:nnbd_migration/src/preview/highlight_js_page.dart';
import 'package:nnbd_migration/src/preview/http_preview_server.dart';
import 'package:nnbd_migration/src/preview/index_file_page.dart';
import 'package:nnbd_migration/src/preview/navigation_tree_page.dart';
import 'package:nnbd_migration/src/preview/not_found_page.dart';
import 'package:nnbd_migration/src/preview/preview_page.dart';
import 'package:nnbd_migration/src/preview/region_page.dart';
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

/// The site used to serve pages for the preview tool.
class PreviewSite extends Site
    implements AbstractGetHandler, AbstractPostHandler {
  /// The path of the CSS page used to style the semantic highlighting within a
  /// Dart file.
  static const highlightCssPath = '/highlight.css';

  /// The path of the JS page used to associate highlighting within a Dart file.
  static const highlightJsPath = '/highlight.pack.js';

  static const navigationTreePath = '/_preview/navigationTree.json';

  static const applyMigrationPath = '/apply-migration';

  static const rerunMigrationPath = '/rerun-migration';

  /// The state of the migration being previewed.
  MigrationState migrationState;

  /// A table mapping the paths of files to the information about the
  /// compilation units at those paths.
  final Map<String, UnitInfo> unitInfoMap = {};

  // A function provided by DartFix to rerun the migration.
  final Future<MigrationState> Function() rerunFunction;

  final String serviceAuthToken = _makeAuthToken();

  /// Initialize a newly created site to serve a preview of the results of an
  /// NNBD migration.
  PreviewSite(this.migrationState, this.rerunFunction)
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
        performApply();

        respondOk(request);
        return;
      } else if (path == rerunMigrationPath) {
        await rerunMigration();

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
  void performApply() {
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
    for (final fileEdit in edits) {
      final file = pathMapper.provider.getFile(fileEdit.file);
      var code = file.exists ? file.readAsStringSync() : '';
      code = SourceEdit.applySequence(code, fileEdit.edits);
      file.writeAsStringSync(code);
    }
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
    final insertionOnly = offset == end;
    if (insertionOnly) {
      unitInfo.handleInsertion(offset, replacement);
      migrationState.needsRerun = true;
    }
    var newContent = diskContent.replaceRange(
        diskMapper.map(offset), diskMapper.map(end), replacement);
    file.writeAsStringSync(newContent);
    unitInfo.diskContent = newContent;
    if (!insertionOnly) {
      await rerunMigration();
    }
  }

  Future<void> rerunMigration() async {
    migrationState = await rerunFunction();
    reset();
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
