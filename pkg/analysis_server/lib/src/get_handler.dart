// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library get.handler;

import 'dart:io';

import 'package:analysis_server/src/socket_server.dart';

/**
 * Instances of the class [GetHandler] handle GET requests.
 */
class GetHandler {
  /**
   * The path used to request the status of the analysis server as a whole.
   */
  static const String STATUS_PATH = '/status';

  /**
   * The socket server whose status is to be reported on.
   */
  SocketServer _server;

  /**
   * Initialize a newly created handler for GET requests.
   */
  GetHandler(SocketServer this._server);

  /**
   * Handle a GET request received by the HTTP server.
   */
  void handleGetRequest(HttpRequest request) {
    String path = request.uri.path;
    if (path == STATUS_PATH) {
      _returnServerStatus(request);
    } else {
      _returnUnknownRequest(request);
    }
  }

  /**
   * Return a response indicating the status of the analysis server.
   */
  void _returnServerStatus(HttpRequest request) {
    HttpResponse response = request.response;
    response.statusCode = HttpStatus.OK;
    response.headers.add(HttpHeaders.CONTENT_TYPE, "text/html");
    response.write('<html>');
    response.write('<head>');
    response.write('<title>Dart Analysis Server - Status</title>');
    response.write('</head>');
    response.write('<body>');
    response.write('<h1>Analysis Server</h1>');
    if (_server.analysisServer == null) {
      response.write('<p>Not running</p>');
    } else {
      response.write('<p>Running</p>');
      response.write('<h1>Analysis Contexts</h1>');
      response.write('<h2>Summary</h2>');
      response.write('<table>');
      _writeRow(
          response,
          ['Context', 'ERROR', 'FLUSHED', 'IN_PROCESS', 'INVALID', 'VALID'],
          true);
      // TODO(scheglov) replace with using folder based contexts
//      _server.analysisServer.contextMap.forEach((String key, AnalysisContext context) {
//        AnalysisContentStatistics statistics =
//            (context as AnalysisContextImpl).statistics;
//        int errorCount = 0;
//        int flushedCount = 0;
//        int inProcessCount = 0;
//        int invalidCount = 0;
//        int validCount = 0;
//        statistics.cacheRows.forEach((AnalysisContentStatistics_CacheRow row) {
//          errorCount += row.errorCount;
//          flushedCount += row.flushedCount;
//          inProcessCount += row.inProcessCount;
//          invalidCount += row.invalidCount;
//          validCount += row.validCount;
//        });
//        _writeRow(response, [
//            '<a href="#context_$key">$key</a>',
//            errorCount,
//            flushedCount,
//            inProcessCount,
//            invalidCount,
//            validCount]);
//      });
      response.write('</table>');
//      _server.analysisServer.contextMap.forEach((String key, AnalysisContext context) {
//        response.write('<h2><a name="context_$key">Analysis Context: $key</a></h2>');
//        AnalysisContentStatistics statistics = (context as AnalysisContextImpl).statistics;
//        response.write('<table>');
//        _writeRow(
//            response,
//            ['Item', 'ERROR', 'FLUSHED', 'IN_PROCESS', 'INVALID', 'VALID'],
//            true);
//        statistics.cacheRows.forEach((AnalysisContentStatistics_CacheRow row) {
//          _writeRow(
//              response,
//              [row.name,
//               row.errorCount,
//               row.flushedCount,
//               row.inProcessCount,
//               row.invalidCount,
//               row.validCount]);
//        });
//        response.write('</table>');
//        List<CaughtException> exceptions = statistics.exceptions;
//        if (!exceptions.isEmpty) {
//          response.write('<h2>Exceptions</h2>');
//          exceptions.forEach((CaughtException exception) {
//            response.write('<p>${exception.exception}</p>');
//          });
//        }
//      });
    }
    response.write('</body>');
    response.write('</html>');
    response.close();
  }

  /**
   * Return an error in response to an unrecognized request received by the HTTP
   * server.
   */
  void _returnUnknownRequest(HttpRequest request) {
    HttpResponse response = request.response;
    response.statusCode = HttpStatus.NOT_FOUND;
    response.headers.add(HttpHeaders.CONTENT_TYPE, "text/plain");
    response.write('Not found');
    response.close();
  }

  /**
   * Write a single row within a table to the given [response] object. The row
   * will have one cell for each of the [columns], and will be a header row if
   * [header] is `true`.
   */
  void _writeRow(HttpResponse response, List<Object> columns, [bool header = false]) {
    if (header) {
      response.write('<th>');
    } else {
      response.write('<tr>');
    }
    columns.forEach((Object value) {
      response.write('<td>');
      response.write(value);
      response.write('</td>');
    });
    if (header) {
      response.write('</th>');
    } else {
      response.write('</tr>');
    }
  }
}