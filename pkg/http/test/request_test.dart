// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library request_test;

import 'dart:io';

import '../../unittest/lib/unittest.dart';
import '../lib/http.dart' as http;
import '../lib/src/utils.dart';
import 'utils.dart';

void main() {
  test('.send', () {
    print("This test is known to be flaky, please ignore "
          "(debug prints below added by sgjesse@)");
    print(".send test starting server...");
    startServer();
    print(".send test server running");

    var request = new http.Request('POST', serverUrl);
    request.body = "hello";
    var future = request.send().chain((response) {
      print(".send test response received");
      expect(response.statusCode, equals(200));
      return consumeInputStream(response.stream);
    }).transform((bytes) => new String.fromCharCodes(bytes));
    future.onComplete((_) {
      print(".send test stopping server...");
      stopServer();
      print(".send test server stopped");
    });

    expect(future, completion(parse(equals({
      'method': 'POST',
      'path': '/',
      'headers': {
        'content-type': ['text/plain; charset=UTF-8'],
        'content-length': ['5']
      },
      'body': 'hello'
    }))));
    print(".send test started");
  });

  group('#contentLength', () {
    test('is computed from bodyBytes', () {
      var request = new http.Request('POST', dummyUrl);
      request.bodyBytes = [1, 2, 3, 4, 5];
      expect(request.contentLength, equals(5));
      request.bodyBytes = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
      expect(request.contentLength, equals(10));
    });

    test('is computed from body', () {
      var request = new http.Request('POST', dummyUrl);
      request.body = "hello";
      expect(request.contentLength, equals(5));
      request.body = "hello, world";
      expect(request.contentLength, equals(12));
    });

    test('is not directly mutable', () {
      var request = new http.Request('POST', dummyUrl);
      expect(() => request.contentLength = 50, throwsUnsupportedError);
    });
  });

  group('#encoding', () {
    test('defaults to utf-8', () {
      var request = new http.Request('POST', dummyUrl);
      expect(request.encoding.name, equals(Encoding.UTF_8.name));
    });

    test('can be set', () {
      var request = new http.Request('POST', dummyUrl);
      request.encoding = Encoding.ISO_8859_1;
      expect(request.encoding.name, equals(Encoding.ISO_8859_1.name));
    });

    test('is based on the content-type charset if it exists', () {
      var request = new http.Request('POST', dummyUrl);
      request.headers[HttpHeaders.CONTENT_TYPE] =
          'text/plain; charset=iso-8859-1';
      expect(request.encoding.name, equals(Encoding.ISO_8859_1.name));
    });

    test('remains the default if the content-type charset is set and unset',
        () {
      var request = new http.Request('POST', dummyUrl);
      request.encoding = Encoding.ISO_8859_1;
      request.headers[HttpHeaders.CONTENT_TYPE] =
          'text/plain; charset=utf-8';
      expect(request.encoding.name, equals(Encoding.UTF_8.name));

      request.headers.remove(HttpHeaders.CONTENT_TYPE);
      expect(request.encoding.name, equals(Encoding.ISO_8859_1.name));
    });

    test('throws an error if the content-type charset is unknown', () {
      var request = new http.Request('POST', dummyUrl);
      request.headers[HttpHeaders.CONTENT_TYPE] =
          'text/plain; charset=not-a-real-charset';
      expect(() => request.encoding, throwsFormatException);
    });
  });

  group('#bodyBytes', () {
    test('defaults to empty', () {
      var request = new http.Request('POST', dummyUrl);
      expect(request.bodyBytes, isEmpty);
    });

    test('can be set', () {
      var request = new http.Request('POST', dummyUrl);
      request.bodyBytes = [104, 101, 108, 108, 111];
      expect(request.bodyBytes, equals([104, 101, 108, 108, 111]));
    });

    test('changes when body changes', () {
      var request = new http.Request('POST', dummyUrl);
      request.body = "hello";
      expect(request.bodyBytes, equals([104, 101, 108, 108, 111]));
    });
  });

  group('#body', () {
    test('defaults to empty', () {
      var request = new http.Request('POST', dummyUrl);
      expect(request.body, isEmpty);
    });

    test('can be set', () {
      var request = new http.Request('POST', dummyUrl);
      request.body = "hello";
      expect(request.body, equals("hello"));
    });

    test('changes when bodyBytes changes', () {
      var request = new http.Request('POST', dummyUrl);
      request.bodyBytes = [104, 101, 108, 108, 111];
      expect(request.body, equals("hello"));
    });

    // TODO(nweiz): test that both the getter and the setter respect #encoding
    // when issue 6284 is fixed.
  });

  group('#bodyFields', () {
    test("can't be read without setting the content-type", () {
      var request = new http.Request('POST', dummyUrl);
      expect(() => request.bodyFields, throwsStateError);
    });

    test("can't be read with the wrong content-type", () {
      var request = new http.Request('POST', dummyUrl);
      request.headers[HttpHeaders.CONTENT_TYPE] = 'text/plain';
      expect(() => request.bodyFields, throwsStateError);
    });

    test("can't be set with the wrong content-type", () {
      var request = new http.Request('POST', dummyUrl);
      request.headers[HttpHeaders.CONTENT_TYPE] = 'text/plain';
      expect(() => request.bodyFields = {}, throwsStateError);
    });

    test('defaults to empty', () {
      var request = new http.Request('POST', dummyUrl);
      request.headers[HttpHeaders.CONTENT_TYPE] =
          'application/x-www-form-urlencoded';
      expect(request.bodyFields, isEmpty);
    });

    test('can be set with no content-type', () {
      var request = new http.Request('POST', dummyUrl);
      request.bodyFields = {'hello': 'world'};
      expect(request.bodyFields, equals({'hello': 'world'}));
    });

    test('changes when body changes', () {
      var request = new http.Request('POST', dummyUrl);
      request.headers[HttpHeaders.CONTENT_TYPE] =
          'application/x-www-form-urlencoded';
      request.body = 'key%201=value&key+2=other%2bvalue';
      expect(request.bodyFields,
          equals({'key 1': 'value', 'key 2': 'other+value'}));
    });

    // TODO(nweiz): test that both the getter and the setter respect #encoding
    // when issue 6284 is fixed.
  });

  group('content-type header', () {
    test('defaults to empty', () {
      var request = new http.Request('POST', dummyUrl);
      expect(request.headers[HttpHeaders.CONTENT_TYPE], isNull);
    });

    test('defaults to empty if only encoding is set', () {
      var request = new http.Request('POST', dummyUrl);
      request.encoding = Encoding.ISO_8859_1;
      expect(request.headers[HttpHeaders.CONTENT_TYPE], isNull);
    });

    test('is set to application/x-www-form-urlencoded with charset utf-8 if '
        'bodyFields is set', () {
      var request = new http.Request('POST', dummyUrl);
      request.bodyFields = {'hello': 'world'};
      expect(request.headers[HttpHeaders.CONTENT_TYPE],
          equals('application/x-www-form-urlencoded; charset=UTF-8'));
    });

    test('is set to application/x-www-form-urlencoded with the given charset '
        'if bodyFields and encoding are set', () {
      var request = new http.Request('POST', dummyUrl);
      request.encoding = Encoding.ISO_8859_1;
      request.bodyFields = {'hello': 'world'};
      expect(request.headers[HttpHeaders.CONTENT_TYPE],
          equals('application/x-www-form-urlencoded; charset=ISO-8859-1'));
    });

    test('is set to text/plain and the given encoding if body and encoding are '
        'both set', () {
      var request = new http.Request('POST', dummyUrl);
      request.encoding = Encoding.ISO_8859_1;
      request.body = 'hello, world';
      expect(request.headers[HttpHeaders.CONTENT_TYPE],
          equals('text/plain; charset=ISO-8859-1'));
    });

    test('is modified to include utf-8 if body is set', () {
      var request = new http.Request('POST', dummyUrl);
      request.headers[HttpHeaders.CONTENT_TYPE] = 'application/json';
      request.body = '{"hello": "world"}';
      expect(request.headers[HttpHeaders.CONTENT_TYPE],
          equals('application/json; charset=UTF-8'));
    });

    test('is modified to include the given encoding if encoding is set', () {
      var request = new http.Request('POST', dummyUrl);
      request.headers[HttpHeaders.CONTENT_TYPE] = 'application/json';
      request.encoding = Encoding.ISO_8859_1;
      expect(request.headers[HttpHeaders.CONTENT_TYPE],
          equals('application/json; charset=ISO-8859-1'));
    });

    test('has its charset overridden by an explicit encoding', () {
      var request = new http.Request('POST', dummyUrl);
      request.headers[HttpHeaders.CONTENT_TYPE] =
          'application/json; charset=utf-8';
      request.encoding = Encoding.ISO_8859_1;
      expect(request.headers[HttpHeaders.CONTENT_TYPE],
          equals('application/json; charset=ISO-8859-1'));
    });

    test("doen't have its charset overridden by setting bodyFields", () {
      var request = new http.Request('POST', dummyUrl);
      request.headers[HttpHeaders.CONTENT_TYPE] =
          'application/x-www-form-urlencoded; charset=iso-8859-1';
      request.bodyFields = {'hello': 'world'};
      expect(request.headers[HttpHeaders.CONTENT_TYPE],
          equals('application/x-www-form-urlencoded; charset=iso-8859-1'));
    });

    test("doen't have its charset overridden by setting body", () {
      var request = new http.Request('POST', dummyUrl);
      request.headers[HttpHeaders.CONTENT_TYPE] =
          'application/json; charset=iso-8859-1';
      request.body = '{"hello": "world"}';
      expect(request.headers[HttpHeaders.CONTENT_TYPE],
          equals('application/json; charset=iso-8859-1'));
    });
  });

  group('#finalize', () {
    test('returns a stream that emits the request body', () {
      var request = new http.Request('POST', dummyUrl);
      request.body = "Hello, world!";
      expect(
          consumeInputStream(request.finalize())
              .transform((bytes) => new String.fromCharCodes(bytes)),
          completion(equals("Hello, world!")));
    });

    test('freezes #persistentConnection', () {
      var request = new http.Request('POST', dummyUrl);
      request.finalize();

      expect(request.persistentConnection, isTrue);
      expect(() => request.persistentConnection = false, throwsStateError);
    });

    test('freezes #followRedirects', () {
      var request = new http.Request('POST', dummyUrl);
      request.finalize();

      expect(request.followRedirects, isTrue);
      expect(() => request.followRedirects = false, throwsStateError);
    });

    test('freezes #maxRedirects', () {
      var request = new http.Request('POST', dummyUrl);
      request.finalize();

      expect(request.maxRedirects, equals(5));
      expect(() => request.maxRedirects = 10, throwsStateError);
    });

    test('freezes #encoding', () {
      var request = new http.Request('POST', dummyUrl);
      request.finalize();

      expect(request.encoding.name, equals(Encoding.UTF_8.name));
      expect(() => request.encoding = Encoding.ASCII, throwsStateError);
    });

    test('freezes #bodyBytes', () {
      var request = new http.Request('POST', dummyUrl);
      request.bodyBytes = [1, 2, 3];
      request.finalize();

      expect(request.bodyBytes, equals([1, 2, 3]));
      expect(() => request.bodyBytes = [4, 5, 6], throwsStateError);
    });

    test('freezes #body', () {
      var request = new http.Request('POST', dummyUrl);
      request.body = "hello";
      request.finalize();

      expect(request.body, equals("hello"));
      expect(() => request.body = "goodbye", throwsStateError);
    });

    test('freezes #bodyFields', () {
      var request = new http.Request('POST', dummyUrl);
      request.bodyFields = {"hello": "world"};
      request.finalize();

      expect(request.bodyFields, equals({"hello": "world"}));
      expect(() => request.bodyFields = {}, throwsStateError);
    });

    test("can't be called twice", () {
      var request = new http.Request('POST', dummyUrl);
      request.finalize();
      expect(request.finalize, throwsStateError);
    });
  });
}

