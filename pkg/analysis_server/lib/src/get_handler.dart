// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library get.handler;

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/domain_completion.dart';
import 'package:analysis_server/src/socket_server.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/source.dart';

import 'analysis_server.dart';

/**
 * Instances of the class [GetHandler] handle GET requests.
 */
class GetHandler {
  /**
   * The path used to request the status of the analysis server as a whole.
   */
  static const String STATUS_PATH = '/status';

  /**
   * The path used to request code completion information.
   */
  static const String COMPLETION_PATH = '/completion';

  /**
   * The path used to request the list of source files in a certain cache
   * state.
   */
  static const String CACHE_STATE_PATH = '/cache_state';

  /**
   * Query parameter used to represent the cache state to search for, when
   * accessing [CACHE_STATE_PATH].
   */
  static const String STATE_QUERY_PARAM = 'state';

  /**
   * Query parameter used to represent the context to search for, when
   * accessing [CACHE_STATE_PATH].
   */
  static const String CONTEXT_QUERY_PARAM = 'context';

  /**
   * Query parameter used to represent the descriptor to search for, when
   * accessing [CACHE_STATE_PATH].
   */
  static const String DESCRIPTOR_QUERY_PARAM = 'descriptor';

  /**
   * The socket server whose status is to be reported on.
   */
  SocketServer _server;

  /**
   * Buffer containing strings printed by the analysis server.
   */
  List<String> _printBuffer;

  /**
   * Initialize a newly created handler for GET requests.
   */
  GetHandler(this._server, this._printBuffer);

  /**
   * Handle a GET request received by the HTTP server.
   */
  void handleGetRequest(HttpRequest request) {
    String path = request.uri.path;
    if (path == STATUS_PATH) {
      _returnServerStatus(request);
    } else if (path == CACHE_STATE_PATH) {
      _returnCacheState(request);
    } else if (path == COMPLETION_PATH) {
      _returnCompletionInfo(request);
    } else {
      _returnUnknownRequest(request);
    }
  }

  /**
   * Create a link to [path] with query parameters [params], with inner HTML
   * [innerHtml].
   */
  String _makeLink(String path, Map<String, String> params, String innerHtml) {
    Uri uri = new Uri(path: path, queryParameters: params);
    return '<a href="${HTML_ESCAPE.convert(uri.toString())}">$innerHtml</a>';
  }

  /**
   * Return a response indicating the set of source files in a certain cache
   * state.
   */
  void _returnCacheState(HttpRequest request) {
    // Figure out what CacheState is being searched for.
    String stateQueryParam = request.uri.queryParameters[STATE_QUERY_PARAM];
    if (stateQueryParam == null) {
      return _returnFailure(
          request,
          'Query parameter $STATE_QUERY_PARAM required');
    }
    CacheState stateFilter = null;
    for (CacheState value in CacheState.values) {
      if (value.toString() == stateQueryParam) {
        stateFilter = value;
      }
    }
    if (stateFilter == null) {
      return _returnFailure(
          request,
          'Query parameter $STATE_QUERY_PARAM is invalid');
    }

    // Figure out which context is being searched for.
    String contextFilter = request.uri.queryParameters[CONTEXT_QUERY_PARAM];
    if (contextFilter == null) {
      return _returnFailure(
          request,
          'Query parameter $CONTEXT_QUERY_PARAM required');
    }

    // Figure out which descriptor is being searched for.
    String descriptorFilter =
        request.uri.queryParameters[DESCRIPTOR_QUERY_PARAM];
    if (descriptorFilter == null) {
      return _returnFailure(
          request,
          'Query parameter $DESCRIPTOR_QUERY_PARAM required');
    }

    AnalysisServer analysisServer = _server.analysisServer;
    if (analysisServer == null) {
      return _returnFailure(request, 'Analysis server not running');
    }
    HttpResponse response = request.response;
    response.statusCode = HttpStatus.OK;
    response.headers.add(HttpHeaders.CONTENT_TYPE, "text/html");
    response.write('<html>');
    response.write('<head>');
    response.write('<title>Dart Analysis Server - Search result</title>');
    response.write('</head>');
    response.write('<body>');
    response.write('<h1>');
    response.write('Files with state ${HTML_ESCAPE.convert(stateQueryParam)}');
    response.write(' for descriptor ${HTML_ESCAPE.convert(descriptorFilter)}');
    response.write(' in context ${HTML_ESCAPE.convert(contextFilter)}');
    response.write('</h1>');
    response.write('<ul>');
    int count = 0;
    analysisServer.folderMap.forEach(
        (Folder folder, AnalysisContextImpl context) {
      if (folder.path != contextFilter) {
        return;
      }
      context.visitCacheItems(
          (Source source, SourceEntry dartEntry, DataDescriptor rowDesc, CacheState state)
              {
        if (state != stateFilter || rowDesc.toString() != descriptorFilter) {
          return;
        }
        response.write('<li>${HTML_ESCAPE.convert(source.fullName)}</li>');
        count++;
      });
    });
    response.write('</ul>');
    response.write('<p>$count files found</p>');
    response.write('</body>');
    response.write('</html>');
    response.close();
  }

  /**
   * Return a response displaying code completion information.
   */
  void _returnCompletionInfo(HttpRequest request) {
    var refresh = request.requestedUri.queryParameters['refresh'];
    HttpResponse response = request.response;
    response.statusCode = HttpStatus.OK;
    response.headers.add(HttpHeaders.CONTENT_TYPE, "text/html");
    response.write('<html>');
    response.write('<head>');
    response.write('<title>Dart Analysis Server - Completion Stats</title>');
    response.write('<style>');
    response.write('td.right {text-align: right;}');
    response.write('</style>');
    if (refresh is String) {
      int seconds = int.parse(refresh, onError: (_) => 5);
      response.write('<meta http-equiv="refresh" content="$seconds">');
    }
    response.write('</head>');
    response.write('<body>');
    _writeCompletionInfo(response);
    response.write('<form>');
    response.write(
        '<input type="button" onClick="history.go(0)" value="Refresh">');
    response.write('</form>');
    response.write('<p>Append "?refresh=5" to refresh every 5 seconds</p>');
    response.write('</body>');
    response.write('</html>');
    response.close();
  }

  void _returnFailure(HttpRequest request, String message) {
    HttpResponse response = request.response;
    response.statusCode = HttpStatus.OK;
    response.headers.add(HttpHeaders.CONTENT_TYPE, "text/html");
    response.write('<html>');
    response.write('<head>');
    response.write('<title>Dart Analysis Server - Failure</title>');
    response.write('</head>');
    response.write('<body>');
    response.write(HTML_ESCAPE.convert(message));
    response.write('</body>');
    response.write('</html>');
    response.close();
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
    response.write('<style>');
    response.write('td.right {text-align: right;}');
    response.write('</style>');
    response.write('</head>');
    response.write('<body>');
    response.write('<h1>Analysis Server</h1>');
    AnalysisServer analysisServer = _server.analysisServer;
    if (analysisServer == null) {
      response.write('<p>Not running</p>');
    } else {
      if (analysisServer.statusAnalyzing) {
        response.write('<p>Running (analyzing)</p>');
      } else {
        response.write('<p>Running (not analyzing)</p>');
      }
      response.write('<h1>Analysis Contexts</h1>');
      response.write('<h2>Summary</h2>');
      response.write('<table>');
      List headerRowText = ['Context'];
      headerRowText.addAll(CacheState.values);
      _writeRow(response, headerRowText, header: true);
      Map<Folder, AnalysisContext> folderMap = analysisServer.folderMap;
      List<Folder> folders = folderMap.keys.toList();
      folders.sort(
          (Folder first, Folder second) => first.shortName.compareTo(second.shortName));
      folders.forEach((Folder folder) {
        AnalysisContextImpl context = folderMap[folder];
        String key = folder.shortName;
        AnalysisContextStatistics statistics = context.statistics;
        Map<CacheState, int> totals = <CacheState, int>{};
        for (CacheState state in CacheState.values) {
          totals[state] = 0;
        }
        statistics.cacheRows.forEach((AnalysisContextStatistics_CacheRow row) {
          for (CacheState state in CacheState.values) {
            totals[state] += row.getCount(state);
          }
        });
        List rowText = [
            '<a href="#context_${HTML_ESCAPE.convert(key)}">$key</a>'];
        for (CacheState state in CacheState.values) {
          rowText.add(totals[state]);
        }
        _writeRow(response, rowText, classes: [null, "right"]);
      });
      response.write('</table>');
      folders.forEach((Folder folder) {
        AnalysisContextImpl context = folderMap[folder];
        String key = folder.shortName;
        response.write(
            '<h2><a name="context_${HTML_ESCAPE.convert(key)}">Analysis Context: $key</a></h2>');
        AnalysisContextStatistics statistics = context.statistics;
        response.write('<table>');
        _writeRow(response, headerRowText, header: true);
        statistics.cacheRows.forEach((AnalysisContextStatistics_CacheRow row) {
          List rowText = [row.name];
          for (CacheState state in CacheState.values) {
            String text = row.getCount(state).toString();
            Map<String, String> params = <String, String>{
              STATE_QUERY_PARAM: state.toString(),
              CONTEXT_QUERY_PARAM: folder.path,
              DESCRIPTOR_QUERY_PARAM: row.name
            };
            rowText.add(_makeLink(CACHE_STATE_PATH, params, text));
          }
          _writeRow(response, rowText, classes: [null, "right"]);
        });
        response.write('</table>');
        List<CaughtException> exceptions = statistics.exceptions;
        if (!exceptions.isEmpty) {
          response.write('<h2>Exceptions</h2>');
          exceptions.forEach((CaughtException exception) {
            response.write('<p>${exception.exception}</p>');
          });
        }
      });
    }
    response.write('<h1>Most recent strings printed by analysis server</h2>');
    response.write('<pre>');
    response.write(HTML_ESCAPE.convert(_printBuffer.join('\n')));
    response.write('</pre>');
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
    response.headers.add(HttpHeaders.CONTENT_TYPE, "text/html");
    response.write('<html>');
    response.write('<head>');
    response.write('<title>Dart Analysis Server - Page Not Found</title>');
    response.write('</head>');
    response.write('<body>');
    response.write('<h1>Page Not Found</h1>');
    response.write('<p>Try one of these links instead:</p>');
    response.write('<ul>');
    response.write('<li><a href="$STATUS_PATH">Server Status</a></li>');
    response.write('<li><a href="$COMPLETION_PATH">Completion Stats</a></li>');
    response.write('<ul>');
    response.write('</body>');
    response.write('</html>');
    response.close();
  }

  /**
   * Append code completion information.
   */
  void _writeCompletionInfo(HttpResponse response) {
    response.write('<h1>Code Completion</h1>');
    AnalysisServer analysisServer = _server.analysisServer;
    if (analysisServer == null) {
      response.write('<p>Not running</p>');
      return;
    }
    CompletionDomainHandler handler = analysisServer.handlers.firstWhere(
        (h) => h is CompletionDomainHandler,
        orElse: () => null);
    if (handler == null) {
      response.write('<p>No code completion</p>');
      return;
    }
    CompletionPerformance performance = handler.performance;
    if (performance == null) {
      response.write('<p>No performance stats yet</p>');
      return;
    }
    response.write('<h2>Performance</h2>');
    response.write('<table>');
    _writeRow(response, ['Elapsed', '', 'Operation'], header: true);
    performance.operations.forEach((OperationPerformance op) {
      String elapsed = op.elapsed != null ? op.elapsed.toString() : '???';
      _writeRow(response, [elapsed, '&nbsp;&nbsp;', op.name]);
    });
    response.write('</table>');
  }

  /**
   * Write a single row within a table to the given [response] object. The row
   * will have one cell for each of the [columns], and will be a header row if
   * [header] is `true`.
   */
  void _writeRow(HttpResponse response, List<Object> columns, {bool header:
      false, List<String> classes}) {
    response.write('<tr>');
    int count = columns.length;
    int maxClassIndex = classes == null ? 0 : classes.length - 1;
    for (int i = 0; i < count; i++) {
      String classAttribute = '';
      if (classes != null) {
        String className = classes[min(i, maxClassIndex)];
        if (className != null) {
          classAttribute = ' class="$className"';
        }
      }
      if (header) {
        response.write('<th$classAttribute>');
      } else {
        response.write('<td$classAttribute>');
      }
      response.write(columns[i]);
      if (header) {
        response.write('</th>');
      } else {
        response.write('</td>');
      }
    }

    response.write('</tr>');
  }
}
