// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:analysis_server/src/edit/nnbd_migration/migration_info.dart';
import 'package:analysis_server/src/edit/preview/dart_file_page.dart';
import 'package:analysis_server/src/edit/preview/exception_page.dart';
import 'package:analysis_server/src/edit/preview/highlight_css_page.dart';
import 'package:analysis_server/src/edit/preview/highlight_js_page.dart';
import 'package:analysis_server/src/edit/preview/not_found_page.dart';
import 'package:analysis_server/src/server/http_server.dart';
import 'package:analysis_server/src/status/pages.dart';

/// The site used to serve pages for the preview tool.
class PreviewSite extends Site implements AbstractGetHandler {
  /// The path of the CSS page used to style the semantic highlighting within a
  /// Dart file.
  static const highlightCssPagePath = '/css/androidstudio.css';

  /// The path of the JS page used to associate highlighting within a Dart file.
  static const highlightJSPagePath = '/js/highlight.pack.js';

  /// A table mapping the paths of files to the information about the
  /// compilation units at those paths.
  final Map<String, UnitInfo> unitInfoMap;

  /// Initialize a newly created site to serve a preview of the results of an
  /// NNBD migration.
  PreviewSite(this.unitInfoMap) : super('NNBD Migration Preview');

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

  @override
  Page createUnknownPage(String unknownPath) {
    return NotFoundPage(this, unknownPath.substring(1));
  }

  @override
  Future<void> handleGetRequest(HttpRequest request) async {
    String path = request.uri.path;
    try {
      if (path == highlightCssPagePath) {
        return respond(request, HighlightCssPage(this));
      } else if (path == highlightJSPagePath) {
        return respond(request, HighlightJSPage(this));
      }
      UnitInfo unitInfo = unitInfoMap[path];
      if (unitInfo != null) {
        return respond(request, DartFilePage(this, unitInfo));
      }
      return respond(request, createUnknownPage(path), HttpStatus.notFound);
    } catch (exception, stackTrace) {
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
  }
}
