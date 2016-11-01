// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'log/log.dart';
import 'page/log_page.dart';
import 'page/stats_page.dart';
import 'page/task_page.dart';

/**
 * An exception that is thrown when a request is received that cannot be
 * handled.
 */
class UnknownRequest implements Exception {}

/**
 * A simple web server.
 */
class WebServer {
  /**
   * The path to the page containing a single page from the instrumentation log.
   */
  static final String logPath = '/log';

  /**
   * The path to the page containing statistics about the instrumentation log.
   */
  static final String statsPath = '/stats';

  /**
   * The path to the page containing statistics about the instrumentation log.
   */
  static final String taskPath = '/task';

  /**
   * The content type for HTML responses.
   */
  static final ContentType _htmlContent =
      new ContentType("text", "html", charset: "utf-8");

  /**
   * The instrumentation log being served up.
   */
  final InstrumentationLog log;

  /**
   * Future that is completed with the HTTP server once it is running.
   */
  Future<HttpServer> _server;

  /**
   * Initialize a newly created server.
   */
  WebServer(this.log);

  Map<String, String> getParameterMap(HttpRequest request) {
    Map<String, String> parameterMap = new HashMap<String, String>();
    String query = request.uri.query;
    if (query != null && query.isNotEmpty) {
      List<String> pairs = query.split('&');
      for (String pair in pairs) {
        List<String> parts = pair.split('=');
        String value = parts[1].trim();
        value = value.replaceAll('+', ' ');
        parameterMap[parts[0].trim()] = value;
      }
    }
    return parameterMap;
  }

  /**
   * Return a table mapping the names of properties to the values of those
   * properties that is extracted from the given HTTP [request].
   */
  Future<Map<String, String>> getValueMap(HttpRequest request) async {
    StringBuffer buffer = new StringBuffer();
    await request.forEach((List<int> element) {
      for (int code in element) {
        buffer.writeCharCode(code);
      }
    });
    Map<String, String> valueMap = new HashMap<String, String>();
    String parameters = buffer.toString();
    if (parameters.isNotEmpty) {
      List<String> pairs = parameters.split('&');
      for (String pair in pairs) {
        List<String> parts = pair.split('=');
        String value = parts[1].trim();
        value = value.replaceAll('+', ' ');
        valueMap[parts[0].trim()] = value;
      }
    }
    return valueMap;
  }

  /**
   * Begin serving HTTP requests over the given [port].
   */
  void serveHttp(int port) {
    _server = HttpServer.bind(InternetAddress.LOOPBACK_IP_V4, port);
    _server.then(_handleServer).catchError((_) {/* Ignore errors. */});
  }

  /**
   * Handle a GET [request] received by the HTTP server.
   */
  void _handleGetRequest(HttpRequest request) {
    StringBuffer buffer = new StringBuffer();
    try {
      String path = request.uri.path;
      if (path == logPath) {
        _writeLogPage(request, buffer);
      } else if (path == statsPath) {
        _writeStatsPage(request, buffer);
      } else if (path == taskPath) {
        _writeTaskPage(request, buffer);
      } else {
        _returnUnknownRequest(request);
        return;
      }
    } on UnknownRequest {
      _returnUnknownRequest(request);
      return;
    } catch (exception, stackTrace) {
      HttpResponse response = request.response;
      response.statusCode = HttpStatus.OK;
      response.headers.contentType = _htmlContent;
      StringBuffer buffer = new StringBuffer();
      buffer.write('<p><b>Exception while composing page:</b></p>');
      buffer.write('<p>$exception</p>');
      buffer.write('<p>');
      _writeStackTrace(buffer, stackTrace);
      buffer.write('</p>');
      response.write(buffer.toString());
      response.close();
      return;
    }

    HttpResponse response = request.response;
    response.statusCode = HttpStatus.OK;
    response.headers.contentType = _htmlContent;
    response.write(buffer.toString());
    response.close();
  }

  /**
   * Handle a POST [request] received by the HTTP server.
   */
  Future<Null> _handlePostRequest(HttpRequest request) async {
    _returnUnknownRequest(request);
  }

  /**
   * Attach a listener to a newly created HTTP server.
   */
  void _handleServer(HttpServer httpServer) {
    httpServer.listen((HttpRequest request) {
      String method = request.method;
      if (method == 'GET') {
        _handleGetRequest(request);
      } else if (method == 'POST') {
        _handlePostRequest(request);
      } else {
        _returnUnknownRequest(request);
      }
    });
  }

  /**
   * Return an error in response to an unrecognized request received by the HTTP
   * server.
   */
  void _returnUnknownRequest(HttpRequest request) {
    HttpResponse response = request.response;
    response.statusCode = HttpStatus.NOT_FOUND;
    response.headers.contentType =
        new ContentType("text", "html", charset: "utf-8");
    response.write(
        '<html><head></head><body><h3>Page not found: "${request.uri.path}".</h3></body></html>');
    response.close();
  }

  void _writeLogPage(HttpRequest request, StringBuffer buffer) {
    Map<String, String> parameterMap = getParameterMap(request);
    String groupId = parameterMap['group'];
    String startIndex = parameterMap['start'];
    LogPage page = new LogPage(log);
    page.selectedGroup = EntryGroup.withId(groupId ?? 'nonTask');
    if (startIndex != null) {
      page.pageStart = int.parse(startIndex);
    } else {
      page.pageStart = 0;
    }
    page.pageLength = 25;
    page.writePage(buffer);
  }

  /**
   * Write a representation of the given [stackTrace] to the given [sink].
   */
  void _writeStackTrace(StringSink sink, StackTrace stackTrace) {
    if (stackTrace != null) {
      String trace = stackTrace.toString().replaceAll('#', '<br>#');
      if (trace.startsWith('<br>#')) {
        trace = trace.substring(4);
      }
      sink.write('<p>');
      sink.write(trace);
      sink.write('</p>');
    }
  }

  void _writeStatsPage(HttpRequest request, StringBuffer buffer) {
    new StatsPage(log).writePage(buffer);
  }

  void _writeTaskPage(HttpRequest request, StringBuffer buffer) {
    Map<String, String> parameterMap = getParameterMap(request);
    String analysisStart = parameterMap['analysisStart'];
    String start = parameterMap['start'];
    TaskPage page = new TaskPage(log);
    if (analysisStart == null) {
      throw new UnknownRequest();
    }
    page.analysisStart = int.parse(analysisStart);
    if (start != null) {
      page.pageStart = int.parse(start);
    } else {
      page.pageStart = 0;
    }
    page.pageLength = 25;
    page.writePage(buffer);
  }
}
