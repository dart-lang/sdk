// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';

final NumberFormat numberFormat = NumberFormat.decimalPattern();

String escape(String text) => text == null ? '' : htmlEscape.convert(text);

String printInteger(int value) => numberFormat.format(value);

String printMilliseconds(num value) => '${numberFormat.format(value)} ms';

String printPercentage(num value, [fractionDigits = 1]) =>
    '${(value * 100).toStringAsFixed(fractionDigits)}%';

/// An entity that knows how to serve itself over http.
abstract class Page {
  final StringBuffer buf = StringBuffer();

  final String id;
  final String title;
  final String description;

  Page(this.id, this.title, {this.description});

  String get path => '/$id';

  Future<void> asyncDiv(void Function() gen, {String classes}) async {
    if (classes != null) {
      buf.writeln('<div class="$classes">');
    } else {
      buf.writeln('<div>');
    }
    // TODO(brianwilkerson) Determine if await is necessary, if so, change the
    // return type of [gen] to `Future<void>`.
    await (gen() as dynamic);
    buf.writeln('</div>');
  }

  void blankslate(String str) {
    div(() => buf.writeln(str), classes: 'blankslate');
  }

  void div(void Function() gen, {String classes}) {
    if (classes != null) {
      buf.writeln('<div class="$classes">');
    } else {
      buf.writeln('<div>');
    }
    gen();
    buf.writeln('</div>');
  }

  Future<String> generate(Map<String, String> params) async {
    buf.clear();
    // TODO(brianwilkerson) Determine if await is necessary, if so, change the
    // return type of [generatePage] to `Future<void>`.
    await (generatePage(params) as dynamic);
    return buf.toString();
  }

  Future<void> generatePage(Map<String, String> params);

  void h1(String text, {String classes}) {
    if (classes != null) {
      buf.writeln('<h1 class="$classes">${escape(text)}</h1>');
    } else {
      buf.writeln('<h1>${escape(text)}</h1>');
    }
  }

  void h2(String text) {
    buf.writeln('<h2>${escape(text)}</h2>');
  }

  void h3(String text, {bool raw = false}) {
    buf.writeln('<h3>${raw ? text : escape(text)}</h3>');
  }

  void h4(String text, {bool raw = false}) {
    buf.writeln('<h4>${raw ? text : escape(text)}</h4>');
  }

  void inputList<T>(Iterable<T> items, void Function(T item) gen) {
    buf.writeln('<select size="8" style="width: 100%">');
    for (var item in items) {
      buf.write('<option>');
      gen(item);
      buf.write('</option>');
    }
    buf.writeln('</select>');
  }

  bool isCurrentPage(String pathToTest) => path == pathToTest;

  void p(String text, {String style, bool raw = false, String classes}) {
    var c = classes == null ? '' : ' class="$classes"';

    if (style != null) {
      buf.writeln('<p$c style="$style">${raw ? text : escape(text)}</p>');
    } else {
      buf.writeln('<p$c>${raw ? text : escape(text)}</p>');
    }
  }

  void pre(void Function() gen, {String classes}) {
    if (classes != null) {
      buf.write('<pre class="$classes">');
    } else {
      buf.write('<pre>');
    }
    gen();
    buf.writeln('</pre>');
  }

  void prettyJson(Map<String, dynamic> data) {
    const jsonEncoder = JsonEncoder.withIndent('  ');
    pre(() {
      buf.write(jsonEncoder.convert(data));
    });
  }

  void ul<T>(Iterable<T> items, void Function(T item) gen, {String classes}) {
    buf.writeln('<ul${classes == null ? '' : ' class=$classes'}>');
    for (var item in items) {
      buf.write('<li>');
      gen(item);
      buf.write('</li>');
    }
    buf.writeln('</ul>');
  }
}

/// Contains a collection of Pages.
abstract class Site {
  final String title;
  final List<Page> pages = [];

  Site(this.title);

  String get customCss => '';

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
