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

  group("readAsString", () {
    test("supports a null body", () {
      var request = _request();
      expect(request.readAsString(), completion(equals("")));
    });

    test("supports a Stream<List<int>> body", () {
      var controller = new StreamController();
      var request = _request({}, controller.stream);
      expect(request.readAsString(), completion(equals("hello, world")));

      controller.add([104, 101, 108, 108, 111, 44]);
      return new Future(() {
        controller
          ..add([32, 119, 111, 114, 108, 100])
          ..close();
      });
    });
  });

  group("read", () {
    test("supports a null body", () {
      var request = _request();
      expect(request.read().toList(), completion(isEmpty));
    });

    test("supports a Stream<List<int>> body", () {
      var controller = new StreamController();
      var request = _request({}, controller.stream);
      expect(request.read().toList(), completion(equals([
        [104, 101, 108, 108, 111, 44],
        [32, 119, 111, 114, 108, 100]
      ])));

      controller.add([104, 101, 108, 108, 111, 44]);
      return new Future(() {
        controller
          ..add([32, 119, 111, 114, 108, 100])
          ..close();
      });
    });
  });
}
