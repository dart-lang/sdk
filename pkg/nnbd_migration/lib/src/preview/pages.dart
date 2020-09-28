// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

/// An entity that knows how to serve itself over http.
abstract class Page {
  final StringBuffer buf = StringBuffer();

  final String id;

  Page(this.id);

  String get path => '/$id';

  Future<String> generate(Map<String, String> params) async {
    buf.clear();
    // TODO(brianwilkerson) Determine if await is necessary, if so, change the
    // return type of [generatePage] to `Future<void>`.
    await (generatePage(params) as dynamic);
    return buf.toString();
  }

  Future<void> generatePage(Map<String, String> params);
}

/// Contains a collection of Pages.
abstract class Site {
  final String title;
  final List<Page> pages = [];

  Site(this.title);

  Page createExceptionPage(String message, StackTrace trace);

  Page createUnknownPage(String unknownPath);

  Future<void> handleGetRequest(HttpRequest request) async {
    try {
      var path = request.uri.path;

      if (path == '/') {
        respondRedirect(request, pages.first.path);
        return;
      }

      for (var page in pages) {
        if (page.path == path) {
          var response = request.response;
          response.headers.contentType = ContentType.html;
          response.write(await page.generate(request.uri.queryParameters));
          response.close();
          return;
        }
      }

      await respond(request, createUnknownPage(path), HttpStatus.notFound);
    } catch (e, st) {
      try {
        await respond(request, createExceptionPage('$e', st),
            HttpStatus.internalServerError);
      } catch (e, st) {
        var response = request.response;
        response.statusCode = HttpStatus.internalServerError;
        response.headers.contentType = ContentType.text;
        response.write('$e\n\n$st');
        response.close();
      }
    }
  }

  Future<void> respond(
    HttpRequest request,
    Page page, [
    int code = HttpStatus.ok,
  ]) async {
    var response = request.response;
    response.statusCode = code;
    response.headers.contentType = ContentType.html;
    response.write(await page.generate(request.uri.queryParameters));
    await response.close();
  }

  Future<void> respondJson(
    HttpRequest request,
    Map<String, Object> json, [
    int code = HttpStatus.ok,
  ]) async {
    var response = request.response;
    response.statusCode = code;
    response.headers.contentType = ContentType.json;
    response.write(jsonEncode(json));
    await response.close();
  }

  Future<void> respondOk(
    HttpRequest request, {
    int code = HttpStatus.ok,
  }) async {
    if (request.headers.contentType.subType == 'json') {
      return respondJson(request, {'success': true}, code);
    }

    var response = request.response;
    response.statusCode = code;
    await response.close();
  }

  Future<void> respondRedirect(HttpRequest request, String pathFragment) async {
    var response = request.response;
    response.statusCode = HttpStatus.movedTemporarily;
    await response.redirect(request.uri.resolve(pathFragment));
  }
}
