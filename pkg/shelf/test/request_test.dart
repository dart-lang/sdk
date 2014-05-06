// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library shelf.request_test;

import 'dart:async';

import 'package:shelf/shelf.dart';
import 'package:unittest/unittest.dart';

import 'test_util.dart';

Request _request([Map<String, String> headers, Stream<List<int>> body]) {
  return new Request("GET", LOCALHOST_URI, headers: headers, body: body);
}

void main() {
  group('constructor', () {
    test('protocolVersion defaults to "1.1"', () {
      var request = new Request('GET', LOCALHOST_URI);
      expect(request.protocolVersion, '1.1');
    });

    test('provide non-default protocolVersion', () {
      var request = new Request('GET', LOCALHOST_URI, protocolVersion: '1.0');
      expect(request.protocolVersion, '1.0');
    });

    test('requestedUri must be absolute', () {
      expect(() => new Request('GET', Uri.parse('/path')),
          throwsArgumentError);
    });

    test('if uri is null, scriptName must be null', () {
      expect(() => new Request('GET', Uri.parse('/path'),
          scriptName: '/script/name'), throwsArgumentError);
    });

    test('if scriptName is null, uri must be null', () {
      var relativeUri = new Uri(path: '/cool/beans.html');
      expect(() => new Request('GET', Uri.parse('/path'),
          url: relativeUri), throwsArgumentError);
    });

    test('uri must be relative', () {
      var relativeUri = Uri.parse('http://localhost/test');

      expect(() => new Request('GET', LOCALHOST_URI,
          url: relativeUri, scriptName: '/news'),
          throwsArgumentError);

      // NOTE: explicitly testing fragments due to Issue 18053
      relativeUri = Uri.parse('http://localhost/test#fragment');

      expect(() => new Request('GET', LOCALHOST_URI,
          url: relativeUri, scriptName: '/news'),
          throwsArgumentError);
    });

    test('uri and scriptName', () {
      var pathInfo = '/pages/page.html?utm_source=ABC123';
      var scriptName = '/assets/static';
      var fullUrl = 'http://localhost/other_path/other_resource.asp';
      var request = new Request('GET', Uri.parse(fullUrl),
          url: Uri.parse(pathInfo), scriptName: scriptName);

      expect(request.scriptName, scriptName);
      expect(request.url.path, '/pages/page.html');
      expect(request.url.query, 'utm_source=ABC123');
    });

    test('minimal uri', () {
      var pathInfo = '/';
      var scriptName = '/assets/static';
      var fullUrl = 'http://localhost$scriptName$pathInfo';
      var request = new Request('GET', Uri.parse(fullUrl),
          url: Uri.parse(pathInfo), scriptName: scriptName);

      expect(request.scriptName, scriptName);
      expect(request.url.path, '/');
      expect(request.url.query, '');
    });

    test('invalid url', () {
      var testUrl = 'page';
      var scriptName = '/assets/static';
      var fullUrl = 'http://localhost$scriptName$testUrl';

      expect(() => new Request('GET', Uri.parse(fullUrl),
          url: Uri.parse(testUrl), scriptName: scriptName),
          throwsArgumentError);
    });

    test('scriptName with no leading slash', () {
      var pathInfo = '/page';
      var scriptName = 'assets/static';
      var fullUrl = 'http://localhost/assets/static/pages';

      expect(() => new Request('GET',Uri.parse(fullUrl),
          url: Uri.parse(pathInfo), scriptName: scriptName),
          throwsArgumentError);

      pathInfo = '/assets/static/page';
      scriptName = '/';
      fullUrl = 'http://localhost/assets/static/pages';

      expect(() => new Request('GET',Uri.parse(fullUrl),
          url: Uri.parse(pathInfo), scriptName: scriptName),
          throwsArgumentError);
    });

    test('scriptName that is only a slash', () {
      var pathInfo = '/assets/static/page';
      var scriptName = '/';
      var fullUrl = 'http://localhost/assets/static/pages';

      expect(() => new Request('GET',Uri.parse(fullUrl),
          url: Uri.parse(pathInfo), scriptName: scriptName),
          throwsArgumentError);
    });
  });

  group("ifModifiedSince", () {
    test("is null without an If-Modified-Since header", () {
      var request = _request();
      expect(request.ifModifiedSince, isNull);
    });

    test("comes from the Last-Modified header", () {
      var request = _request({
        'if-modified-since': 'Sun, 06 Nov 1994 08:49:37 GMT'
      });
      expect(request.ifModifiedSince,
          equals(DateTime.parse("1994-11-06 08:49:37z")));
    });
  });

  group('change', () {
    test('with no arguments returns instance with equal values', () {
      var controller = new StreamController();

      var uri = Uri.parse('https://test.example.com/static/file.html');

      var request = new Request('GET', uri,
          protocolVersion: '2.0',
          headers: {'header1': 'header value 1'},
          url: Uri.parse('/file.html'),
          scriptName: '/static',
          body: controller.stream,
          context: {'context1': 'context value 1'});

      var copy = request.change();

      expect(copy.method, request.method);
      expect(copy.requestedUri, request.requestedUri);
      expect(copy.protocolVersion, request.protocolVersion);
      expect(copy.headers, same(request.headers));
      expect(copy.url, request.url);
      expect(copy.scriptName, request.scriptName);
      expect(copy.context, same(request.context));
      expect(copy.readAsString(), completion('hello, world'));

      controller.add(HELLO_BYTES);
      return new Future(() {
        controller
          ..add(WORLD_BYTES)
          ..close();
      });
    });
  });
}
