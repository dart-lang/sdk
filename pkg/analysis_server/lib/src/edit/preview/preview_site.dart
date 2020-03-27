// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:analysis_server/src/edit/nnbd_migration/migration_info.dart';
import 'package:analysis_server/src/edit/nnbd_migration/migration_state.dart';
import 'package:analysis_server/src/edit/nnbd_migration/path_mapper.dart';
import 'package:analysis_server/src/edit/preview/dart_file_page.dart';
import 'package:analysis_server/src/edit/preview/exception_page.dart';
import 'package:analysis_server/src/edit/preview/highlight_css_page.dart';
import 'package:analysis_server/src/edit/preview/highlight_js_page.dart';
import 'package:analysis_server/src/edit/preview/http_preview_server.dart';
import 'package:analysis_server/src/edit/preview/index_file_page.dart';
import 'package:analysis_server/src/edit/preview/navigation_tree_page.dart';
import 'package:analysis_server/src/edit/preview/not_found_page.dart';
import 'package:analysis_server/src/edit/preview/preview_page.dart';
import 'package:analysis_server/src/edit/preview/region_page.dart';
import 'package:analysis_server/src/edit/preview/unauthorized_page.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/status/pages.dart';
import 'package:analyzer/file_system/file_system.dart';

// The randomly generated auth token used to access the preview site.
String _makeAuthToken() {
  final kTokenByteSize = 8;
  Uint8List bytes = Uint8List(kTokenByteSize);
  Random random = Random.secure();
  for (int i = 0; i < kTokenByteSize; i++) {
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
  final Future<MigrationState> Function([List<String>]) rerunFunction;

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

  Page createUnauthorizedPage(String unauthorizedPath) {
    return UnauthorizedPage(this, unauthorizedPath.substring(1));
  }

  @override
  Page createUnknownPage(String unknownPath) {
    return NotFoundPage(this, unknownPath.substring(1));
  }

  @override
  Future<void> handleGetRequest(HttpRequest request) async {
    Uri uri = request.uri;
    String path = uri.path;
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
          path == migrationInfo.includedRoot ||
          path == '${migrationInfo.includedRoot}/') {
        // Note: `return await` needed due to
        // https://github.com/dart-lang/sdk/issues/39204
        return await respond(request, IndexFilePage(this));
      }

      UnitInfo unitInfo = unitInfoMap[path];
      if (unitInfo != null) {
        if (uri.queryParameters.containsKey('inline')) {
          // TODO(devoncarew): Ensure that we don't serve content outside of our
          //  project.

          // Note: `return await` needed due to
          // https://github.com/dart-lang/sdk/issues/39204
          return await respond(request, DartFilePage(this, unitInfo));
        } else if (uri.queryParameters.containsKey('region')) {
          // TODO(devoncarew): Ensure that we don't serve content outside of our
          //  project.

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
    Uri uri = request.uri;
    String path = uri.path;
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
      throw StateError('Cannot reapply migration.');
    }

    final edits = migrationState.listener.sourceChange.edits;

    // Eagerly mark the migration applied. If this throws, we cannot go back.
    migrationState.markApplied();
    for (final fileEdit in edits) {
      final file = pathMapper.provider.getFile(fileEdit.file);
      String code = file.exists ? file.readAsStringSync() : '';
      code = SourceEdit.applySequence(code, fileEdit.edits);
      file.writeAsStringSync(code);
    }
  }

  /// Perform the edit indicated by the [uri].
  Future<void> performEdit(Uri uri) async {
    //
    // Update the code on disk.
    //
    Map<String, String> params = uri.queryParameters;
    String path = uri.path;
    int offset = int.parse(params['offset']);
    int end = int.parse(params['end']);
    String replacement = params['replacement'];
    File file = pathMapper.provider.getFile(path);
    String oldContent = file.readAsStringSync();
    String newContent = oldContent.replaceRange(offset, end, replacement);
    file.writeAsStringSync(newContent);
    await rerunMigration([path]);
  }

  Future<void> rerunMigration([List<String> changedPaths]) async {
    migrationState = await rerunFunction(changedPaths);
    reset();
  }

  void reset() {
    unitInfoMap.clear();
    Set<UnitInfo> unitInfos = migrationInfo.units;
    ResourceProvider provider = pathMapper.provider;
    for (UnitInfo unit in unitInfos) {
      unitInfoMap[unit.path] = unit;
    }
    for (UnitInfo unit in migrationInfo.unitMap.values) {
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
    HttpResponse response = request.response;
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
      await respond(
          request,
          createExceptionPageWithPath(path, '$exception', stackTrace),
          HttpStatus.internalServerError);
    } catch (exception, stackTrace) {
      HttpResponse response = request.response;
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
