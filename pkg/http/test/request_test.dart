// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library request_test;

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:unittest/unittest.dart';

import 'utils.dart';

void main() {
  test('.send', () {
    expect(startServer().then((_) {

      var request = new http.Request('POST', serverUrl);
      request.body = "hello";
      request.headers['User-Agent'] = 'Dart';

      expect(request.send().then((response) {
        expect(response.statusCode, equals(200));
        return response.stream.bytesToString();
      }).whenComplete(stopServer), completion(parse(equals({
        'method': 'POST',
        'path': '/',
        'headers': {
          'content-type': ['text/plain; charset=utf-8'],
          'accept-encoding': ['gzip'],
          'user-agent': ['Dart'],
          'content-length': ['5']
        },
        'body': 'hello'
      }))));
    }), completes);
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
      expect(request.encoding.name, equals(UTF8.name));
    });

    test('can be set', () {
      var request = new http.Request('POST', dummyUrl);
      request.encoding = LATIN1;
      expect(request.encoding.name, equals(LATIN1.name));
    });

    test('is based on the content-type charset if it exists', () {
      var request = new http.Request('POST', dummyUrl);
      request.headers[HttpHeaders.CONTENT_TYPE] =
          'text/plain; charset=iso-8859-1';
      expect(request.encoding.name, equals(LATIN1.name));
    });

    test('remains the default if the content-type charset is set and unset',
        () {
      var request = new http.Request('POST', dummyUrl);
      request.encoding = LATIN1;
      request.headers[HttpHeaders.CONTENT_TYPE] =
          'text/plain; charset=utf-8';
      expect(request.encoding.name, equals(UTF8.name));

      request.headers.remove(HttpHeaders.CONTENT_TYPE);
      expect(request.encoding.name, equals(LATIN1.name));
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

    test('is encoded according to the given encoding', () {
      var request = new http.Request('POST', dummyUrl);
      request.encoding = LATIN1;
      request.body = "föøbãr";
      expect(request.bodyBytes, equals([102, 246, 248, 98, 227, 114]));
    });

    test('is decoded according to the given encoding', () {
      var request = new http.Request('POST', dummyUrl);
      request.encoding = LATIN1;
      request.bodyBytes = [102, 246, 248, 98, 227, 114];
      expect(request.body, equals("föøbãr"));
    });
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

    test('is encoded according to the given encoding', () {
      var request = new http.Request('POST', dummyUrl);
      request.headers[HttpHeaders.CONTENT_TYPE] =
          'application/x-www-form-urlencoded';
      request.encoding = LATIN1;
      request.bodyFields = {"föø": "bãr"};
      expect(request.body, equals('f%F6%F8=b%E3r'));
    });

    test('is decoded according to the given encoding', () {
      var request = new http.Request('POST', dummyUrl);
      request.headers[HttpHeaders.CONTENT_TYPE] =
          'application/x-www-form-urlencoded';
      request.encoding = LATIN1;
      request.body = 'f%F6%F8=b%E3r';
      expect(request.bodyFields, equals({"föø": "bãr"}));
    });
  });

  test('#followRedirects', () {
    print("This test is known to be flaky, please ignore "
          "(debug prints below added by sgjesse@)");
    print("#followRedirects test starting server...");
    expect(startServer().then((_) {
      print("#followRedirects test server running");

      var request = new http.Request('POST', serverUrl.resolve('/redirect'))
          ..followRedirects = false;
      var future = request.send().then((response) {
        print("#followRedirects test response received");
        expect(response.statusCode, equals(302));
      });
      expect(future.catchError((_) {}).then((_) {
        print("#followRedirects test stopping server...");
        stopServer();
        print("#followRedirects test server stopped");
      }), completes);

      expect(future, completes);
      print("#followRedirects test started");
    }), completes);
  });

  test('#maxRedirects', () {
    print("This test is known to be flaky, please ignore "
          "(debug prints below added by sgjesse@)");
    print("#maxRedirects test starting server...");
    expect(startServer().then((_) {
      print("#maxRedirects test server running");

      var request = new http.Request('POST', serverUrl.resolve('/loop?1'))
        ..maxRedirects = 2;
      var future = request.send().catchError((error) {
        print("#maxRedirects test exception received");
        expect(error, isRedirectLimitExceededException);
        expect(error.redirects.length, equals(2));
      });
      expect(future.catchError((_) {}).then((_) {
        print("#maxRedirects test stopping server...");
        stopServer();
        print("#maxRedirects test server stopped");
      }), completes);

      expect(future, completes);
      print("#maxRedirects test started");
    }), completes);
  });

  group('content-type header', () {
    test('defaults to empty', () {
      var request = new http.Request('POST', dummyUrl);
      expect(request.headers[HttpHeaders.CONTENT_TYPE], isNull);
    });

    test('defaults to empty if only encoding is set', () {
      var request = new http.Request('POST', dummyUrl);
      request.encoding = LATIN1;
      expect(request.headers[HttpHeaders.CONTENT_TYPE], isNull);
    });

    test('is set to application/x-www-form-urlencoded with charset utf-8 if '
        'bodyFields is set', () {
      var request = new http.Request('POST', dummyUrl);
      request.bodyFields = {'hello': 'world'};
      expect(request.headers[HttpHeaders.CONTENT_TYPE],
          equals('application/x-www-form-urlencoded; charset=utf-8'));
    });

    test('is set to application/x-www-form-urlencoded with the given charset '
        'if bodyFields and encoding are set', () {
      var request = new http.Request('POST', dummyUrl);
      request.encoding = LATIN1;
      request.bodyFields = {'hello': 'world'};
      expect(request.headers[HttpHeaders.CONTENT_TYPE],
          equals('application/x-www-form-urlencoded; charset=iso-8859-1'));
    });

    test('is set to text/plain and the given encoding if body and encoding are '
        'both set', () {
      var request = new http.Request('POST', dummyUrl);
      request.encoding = LATIN1;
      request.body = 'hello, world';
      expect(request.headers[HttpHeaders.CONTENT_TYPE],
          equals('text/plain; charset=iso-8859-1'));
    });

    test('is modified to include utf-8 if body is set', () {
      var request = new http.Request('POST', dummyUrl);
      request.headers[HttpHeaders.CONTENT_TYPE] = 'application/json';
      request.body = '{"hello": "world"}';
      expect(request.headers[HttpHeaders.CONTENT_TYPE],
          equals('application/json; charset=utf-8'));
    });

    test('is modified to include the given encoding if encoding is set', () {
      var request = new http.Request('POST', dummyUrl);
      request.headers[HttpHeaders.CONTENT_TYPE] = 'application/json';
      request.encoding = LATIN1;
      expect(request.headers[HttpHeaders.CONTENT_TYPE],
          equals('application/json; charset=iso-8859-1'));
    });

    test('has its charset overridden by an explicit encoding', () {
      var request = new http.Request('POST', dummyUrl);
      request.headers[HttpHeaders.CONTENT_TYPE] =
          'application/json; charset=utf-8';
      request.encoding = LATIN1;
      expect(request.headers[HttpHeaders.CONTENT_TYPE],
          equals('application/json; charset=iso-8859-1'));
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
      expect(request.finalize().bytesToString(),
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

      expect(request.encoding.name, equals(UTF8.name));
      expect(() => request.encoding = ASCII, throwsStateError);
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

  group('#toString()', () {
    test('includes the method and URL', () {
      var request = new http.Request('POST', dummyUrl);
      expect(request.toString(), 'POST $dummyUrl');
    });
  });
}

