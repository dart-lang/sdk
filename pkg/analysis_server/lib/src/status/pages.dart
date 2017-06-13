// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';

final NumberFormat numberFormat = new NumberFormat.decimalPattern();

String escape(String text) => text == null ? '' : HTML_ESCAPE.convert(text);

String printInteger(int value) => numberFormat.format(value);

String printMilliseconds(num value) => '${numberFormat.format(value)} ms';

String printPercentage(num value) => '${(value * 100).toStringAsFixed(1)}%';

/// An entity that knows how to serve itself over http.
abstract class Page {
  final StringBuffer buf = new StringBuffer();

  final String id;
  final String title;
  final String description;

  Page(this.id, this.title, {this.description});

  String get path => '/$id';

  Future<Null> asyncDiv(void gen(), {String classes}) async {
    if (classes != null) {
      buf.writeln('<div class="$classes">');
    } else {
      buf.writeln('<div>');
    }
    await gen();
    buf.writeln('</div>');
  }

  void blankslate(String str) {
    div(() => buf.writeln(str), classes: 'blankslate');
  }

  void div(void gen(), {String classes}) {
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
    await generatePage(params);
    return buf.toString();
  }

  void generatePage(Map<String, String> params);

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

  void h3(String text, {bool raw: false}) {
    buf.writeln('<h3>${raw ? text : escape(text)}</h3>');
  }

  void h4(String text, {bool raw: false}) {
    buf.writeln('<h4>${raw ? text : escape(text)}</h4>');
  }

  void inputList<T>(Iterable<T> items, void gen(T item)) {
    buf.writeln('<select size="8" style="width: 100%">');
    for (T item in items) {
      buf.write('<option>');
      gen(item);
      buf.write('</option>');
    }
    buf.writeln('</select>');
  }

  bool isCurrentPage(String pathToTest) => path == pathToTest;

  void p(String text, {String style, bool raw: false, String classes}) {
    String c = classes == null ? '' : ' class="$classes"';

    if (style != null) {
      buf.writeln('<p$c style="$style">${raw ? text : escape(text)}</p>');
    } else {
      buf.writeln('<p$c>${raw ? text : escape(text)}</p>');
    }
  }

  void pre(void gen(), {String classes}) {
    if (classes != null) {
      buf.write('<pre class="$classes">');
    } else {
      buf.write('<pre>');
    }
    gen();
    buf.writeln('</pre>');
  }

  void ul<T>(Iterable<T> items, void gen(T item), {String classes}) {
    buf.writeln('<ul${classes == null ? '' : ' class=$classes'}>');
    for (T item in items) {
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
  List<Page> pages = [];

  Site(this.title);

  String get customCss => '';

  Page createExceptionPage(String message, StackTrace trace);

  Page createUnknownPage(String unknownPath);

  Future<Null> handleGetRequest(HttpRequest request) async {
    try {
      String path = request.uri.path;

      if (path == '/') {
        respondRedirect(request, pages.first.path);
        return;
      }

      for (Page page in pages) {
        if (page.path == path) {
          HttpResponse response = request.response;
          response.headers.contentType = ContentType.HTML;
          response.write(await page.generate(request.uri.queryParameters));
          response.close();
          return;
        }
      }

      await respond(request, createUnknownPage(path), HttpStatus.NOT_FOUND);
    } catch (e, st) {
      try {
        await respond(request, createExceptionPage('$e', st),
            HttpStatus.INTERNAL_SERVER_ERROR);
      } catch (e, st) {
        HttpResponse response = request.response;
        response.statusCode = HttpStatus.INTERNAL_SERVER_ERROR;
        response.headers.contentType = ContentType.TEXT;
        response.write('$e\n\n$st');
        response.close();
      }
    }
  }

  Future<Null> respond(HttpRequest request, Page page,
      [int code = HttpStatus.OK]) async {
    HttpResponse response = request.response;
    response.statusCode = code;
    response.headers.contentType = ContentType.HTML;
    response.write(await page.generate(request.uri.queryParameters));
    response.close();
  }

  void respondRedirect(HttpRequest request, String pathFragment) {
    HttpResponse response = request.response;
    response.statusCode = HttpStatus.MOVED_TEMPORARILY;
    response.redirect(request.uri.resolve(pathFragment));
  }
}
