// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:io';

import 'log/log.dart';
import 'page/log_page.dart';
import 'page/stats_page.dart';

/// An exception that is thrown when a request is received that cannot be
/// handled.
class UnknownRequest implements Exception {}

/// A simple web server.
class WebServer {
  /// The path to the page containing a single page from the instrumentation
  /// log.
  static final String logPath = '/log';

  /// The path to the page containing statistics about the instrumentation log.
  static final String statsPath = '/stats';

  /// The content type for HTML responses.
  static final ContentType _htmlContent =
      ContentType('text', 'html', charset: 'utf-8');

  /// The instrumentation log being served up.
  final InstrumentationLog log;

  /// Future that is completed with the HTTP server once it is running.
  Future<HttpServer> _server;

  /// Initialize a newly created server.
  WebServer(this.log);

  Map<String, String> getParameterMap(HttpRequest request) {
    Map<String, String> parameterMap = HashMap<String, String>();
    var query = request.uri.query;
    if (query != null && query.isNotEmpty) {
      var pairs = query.split('&');
      for (var pair in pairs) {
        var parts = pair.split('=');
        var value = parts[1].trim();
        value = value.replaceAll('+', ' ');
        parameterMap[parts[0].trim()] = value;
      }
    }
    return parameterMap;
  }

  /// Return a table mapping the names of properties to the values of those
  /// properties that is extracted from the given HTTP [request].
  Future<Map<String, String>> getValueMap(HttpRequest request) async {
    var buffer = StringBuffer();
    await request.forEach((List<int> element) {
      for (var code in element) {
        buffer.writeCharCode(code);
      }
    });
    Map<String, String> valueMap = HashMap<String, String>();
    var parameters = buffer.toString();
    if (parameters.isNotEmpty) {
      var pairs = parameters.split('&');
      for (var pair in pairs) {
        var parts = pair.split('=');
        var value = parts[1].trim();
        value = value.replaceAll('+', ' ');
        valueMap[parts[0].trim()] = value;
      }
    }
    return valueMap;
  }

  /// Begin serving HTTP requests over the given [port].
  void serveHttp(int port) {
    _server = HttpServer.bind(InternetAddress.loopbackIPv4, port);
    _server.then(_handleServer).catchError((_) {
      /* Ignore errors. */
    });
  }

  /// Handle a GET [request] received by the HTTP server.
  void _handleGetRequest(HttpRequest request) {
    var buffer = StringBuffer();
    try {
      var path = request.uri.path;
      if (path == logPath) {
        _writeLogPage(request, buffer);
      } else if (path == statsPath) {
        _writeStatsPage(request, buffer);
      } else {
        _returnUnknownRequest(request);
        return;
      }
    } on UnknownRequest {
      _returnUnknownRequest(request);
      return;
    } catch (exception, stackTrace) {
      var response = request.response;
      response.statusCode = HttpStatus.ok;
      response.headers.contentType = _htmlContent;
      var buffer = StringBuffer();
      buffer.write('<p><b>Exception while composing page:</b></p>');
      buffer.write('<p>$exception</p>');
      buffer.write('<p>');
      _writeStackTrace(buffer, stackTrace);
      buffer.write('</p>');
      response.write(buffer.toString());
      response.close();
      return;
    }

    var response = request.response;
    response.statusCode = HttpStatus.ok;
    response.headers.contentType = _htmlContent;
    response.write(buffer.toString());
    response.close();
  }

  /// Handle a POST [request] received by the HTTP server.
  Future<void> _handlePostRequest(HttpRequest request) async {
    _returnUnknownRequest(request);
  }

  /// Attach a listener to a newly created HTTP server.
  void _handleServer(HttpServer httpServer) {
    httpServer.listen((HttpRequest request) {
      var method = request.method;
      if (method == 'GET') {
        _handleGetRequest(request);
      } else if (method == 'POST') {
        _handlePostRequest(request);
      } else {
        _returnUnknownRequest(request);
      }
    });
  }

  /// Return an error in response to an unrecognized request received by the
  /// HTTP server.
  void _returnUnknownRequest(HttpRequest request) {
    var response = request.response;
    response.statusCode = HttpStatus.notFound;
    response.headers.contentType =
        ContentType('text', 'html', charset: 'utf-8');
    response.write(
        '<html><head></head><body><h3>Page not found: "${request.uri.path}".</h3></body></html>');
    response.close();
  }

  void _writeLogPage(HttpRequest request, StringBuffer buffer) {
    var parameterMap = getParameterMap(request);
    var groupId = parameterMap['group'];
    var startIndex = parameterMap['start'];
    var page = LogPage(log);
    page.selectedGroup = EntryGroup.withId(groupId ?? 'nonTask');
    if (startIndex != null) {
      page.pageStart = int.parse(startIndex);
    } else {
      page.pageStart = 0;
    }
    page.pageLength = 25;
    page.writePage(buffer);
  }

  /// Write a representation of the given [stackTrace] to the given [sink].
  void _writeStackTrace(StringSink sink, StackTrace stackTrace) {
    if (stackTrace != null) {
      var trace = stackTrace.toString().replaceAll('#', '<br>#');
      if (trace.startsWith('<br>#')) {
        trace = trace.substring(4);
      }
      sink.write('<p>');
      sink.write(trace);
      sink.write('</p>');
    }
  }

  void _writeStatsPage(HttpRequest request, StringBuffer buffer) {
    StatsPage(log).writePage(buffer);
  }
}
