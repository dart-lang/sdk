// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library shelf_io_test;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as parser;
import 'package:scheduled_test/scheduled_test.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

import 'test_util.dart';

void main() {
  test('sync handler returns a value to the client', () {
    _scheduleServer(syncHandler);

    return _scheduleGet().then((response) {
      expect(response.statusCode, HttpStatus.OK);
      expect(response.body, 'Hello from /');
    });
  });

  test('async handler returns a value to the client', () {
    _scheduleServer(asyncHandler);

    return _scheduleGet().then((response) {
      expect(response.statusCode, HttpStatus.OK);
      expect(response.body, 'Hello from /');
    });
  });

  test('sync null response leads to a 500', () {
    _scheduleServer((request) => null);

    return _scheduleGet().then((response) {
      expect(response.statusCode, HttpStatus.INTERNAL_SERVER_ERROR);
      expect(response.body, 'Internal Server Error');
    });
  });

  test('async null response leads to a 500', () {
    _scheduleServer((request) => new Future.value(null));

    return _scheduleGet().then((response) {
      expect(response.statusCode, HttpStatus.INTERNAL_SERVER_ERROR);
      expect(response.body, 'Internal Server Error');
    });
  });

  test('thrown error leads to a 500', () {
    _scheduleServer((request) {
      throw new UnsupportedError('test');
    });

    return _scheduleGet().then((response) {
      expect(response.statusCode, HttpStatus.INTERNAL_SERVER_ERROR);
      expect(response.body, 'Internal Server Error');
    });
  });

  test('async error leads to a 500', () {
    _scheduleServer((request) {
      return new Future.error('test');
    });

    return _scheduleGet().then((response) {
      expect(response.statusCode, HttpStatus.INTERNAL_SERVER_ERROR);
      expect(response.body, 'Internal Server Error');
    });
  });

  test('Request is populated correctly', () {
    var path = '/foo/bar?qs=value';

    _scheduleServer((request) {
      expect(request.contentLength, 0);
      expect(request.method, 'GET');

      var expectedUrl = 'http://localhost:$_serverPort$path';
      expect(request.requestedUri, Uri.parse(expectedUrl));

      expect(request.url.path, '/foo/bar');
      expect(request.url.pathSegments, ['foo', 'bar']);
      expect(request.protocolVersion, '1.1');
      expect(request.url.query, 'qs=value');
      expect(request.scriptName, '');

      return syncHandler(request);
    });

    return schedule(() => http.get('http://localhost:$_serverPort$path'))
        .then((response) {
      expect(response.statusCode, HttpStatus.OK);
      expect(response.body, 'Hello from /foo/bar');
    });
  });

  test('custom response headers are received by the client', () {
    _scheduleServer((request) {
      return new Response.ok('Hello from /', headers: {
        'test-header': 'test-value',
        'test-list': 'a, b, c'
      });
    });

    return _scheduleGet().then((response) {
      expect(response.statusCode, HttpStatus.OK);
      expect(response.headers['test-header'], 'test-value');
      expect(response.body, 'Hello from /');
    });
  });

  test('custom status code is received by the client', () {
    _scheduleServer((request) {
      return new Response(299, body: 'Hello from /');
    });

    return _scheduleGet().then((response) {
      expect(response.statusCode, 299);
      expect(response.body, 'Hello from /');
    });
  });

  test('custom request headers are received by the handler', () {
    _scheduleServer((request) {
      expect(request.headers, containsPair('custom-header', 'client value'));

      // dart:io HttpServer splits multi-value headers into an array
      // validate that they are combined correctly
      expect(request.headers, containsPair('multi-header', 'foo,bar,baz'));
      return syncHandler(request);
    });

    var headers = {
      'custom-header': 'client value',
      'multi-header': 'foo,bar,baz'
    };

    return _scheduleGet(headers: headers).then((response) {
      expect(response.statusCode, HttpStatus.OK);
      expect(response.body, 'Hello from /');
    });
  });

  test('post with empty content', () {
    _scheduleServer((request) {
      expect(request.mimeType, isNull);
      expect(request.encoding, isNull);
      expect(request.method, 'POST');
      expect(request.contentLength, 0);

      return request.readAsString().then((body) {
        expect(body, '');
        return syncHandler(request);
      });
    });

    return _schedulePost().then((response) {
      expect(response.statusCode, HttpStatus.OK);
      expect(response.stream.bytesToString(), completion('Hello from /'));
    });
  });

  test('post with request content', () {
    _scheduleServer((request) {
      expect(request.mimeType, 'text/plain');
      expect(request.encoding, UTF8);
      expect(request.method, 'POST');
      expect(request.contentLength, 9);

      return request.readAsString().then((body) {
        expect(body, 'test body');
        return syncHandler(request);
      });
    });

    return _schedulePost(body: 'test body').then((response) {
      expect(response.statusCode, HttpStatus.OK);
      expect(response.stream.bytesToString(), completion('Hello from /'));
    });
  });

  test('supports request hijacking', () {
    _scheduleServer((request) {
      expect(request.method, 'POST');

      request.hijack(expectAsync((stream, sink) {
        expect(stream.first, completion(equals("Hello".codeUnits)));

        sink.add((
            "HTTP/1.1 404 Not Found\r\n"
            "Date: Mon, 23 May 2005 22:38:34 GMT\r\n"
            "Content-Length: 13\r\n"
            "\r\n"
            "Hello, world!").codeUnits);
        sink.close();
      }));
    });

    return _schedulePost(body: "Hello").then((response) {
      expect(response.statusCode, HttpStatus.NOT_FOUND);
      expect(response.headers["date"], "Mon, 23 May 2005 22:38:34 GMT");
      expect(response.stream.bytesToString(),
          completion(equals("Hello, world!")));
    });
  });

  test('reports an error if a HijackException is thrown without hijacking', () {
    _scheduleServer((request) => throw const HijackException());

    return _scheduleGet().then((response) {
      expect(response.statusCode, HttpStatus.INTERNAL_SERVER_ERROR);
    });
  });

  test('passes asynchronous exceptions to the parent error zone', () {
    return runZoned(() {
      return shelf_io.serve((request) {
        new Future(() => throw 'oh no');
        return syncHandler(request);
      }, 'localhost', 0).then((server) {
        return http.get('http://localhost:${server.port}').then((response) {
          expect(response.statusCode, HttpStatus.OK);
          expect(response.body, 'Hello from /');
          server.close();
        });
      });
    }, onError: expectAsync((error) {
      expect(error, equals('oh no'));
    }));
  });

  test("doesn't pass asynchronous exceptions to the root error zone", () {
    return Zone.ROOT.run(() {
      return shelf_io.serve((request) {
        new Future(() => throw 'oh no');
        return syncHandler(request);
      }, 'localhost', 0).then((server) {
        return http.get('http://localhost:${server.port}').then((response) {
          expect(response.statusCode, HttpStatus.OK);
          expect(response.body, 'Hello from /');
          server.close();
        });
      });
    });
  });

  test('a bad HTTP request results in a 500 response', () {
    var socket;

    _scheduleServer(syncHandler);

    schedule(() {
      return Socket.connect('localhost', _serverPort).then((value) {
        socket = value;

        currentSchedule.onComplete.schedule(() {
          return socket.close();
        }, 'close the socket');
      });
    });

    schedule(() {
      socket.write('GET / HTTP/1.1\r\n');
      socket.write('Host: ^^super bad !@#host\r\n');
      socket.write('\r\n');
      return socket.close();
    });

    schedule(() {
      return UTF8.decodeStream(socket).then((value) {
        expect(value, contains('500 Internal Server Error'));
      });
    });
  });

  group('date header', () {
    test('is sent by default', () {
      _scheduleServer(syncHandler);

      // Update beforeRequest to be one second earlier. HTTP dates only have
      // second-level granularity and the request will likely take less than a
      // second.
      var beforeRequest = new DateTime.now().subtract(new Duration(seconds: 1));

      return _scheduleGet().then((response) {
        expect(response.headers, contains('date'));
        var responseDate = parser.parseHttpDate(response.headers['date']);

        expect(responseDate.isAfter(beforeRequest), isTrue);
        expect(responseDate.isBefore(new DateTime.now()), isTrue);
      });
    });

    test('defers to header in response', () {
      var date = new DateTime.utc(1981, 6, 5);
      _scheduleServer((request) {
        return new Response.ok('test', headers: {
          HttpHeaders.DATE: parser.formatHttpDate(date)
        });
      });

      return _scheduleGet().then((response) {
        expect(response.headers, contains('date'));
        var responseDate = parser.parseHttpDate(response.headers['date']);
        expect(responseDate, date);
      });
    });
  });

  group('server header', () {
    test('defaults to "dart:io with Shelf"', () {
      _scheduleServer(syncHandler);

      return _scheduleGet().then((response) {
        expect(response.headers,
            containsPair(HttpHeaders.SERVER, 'dart:io with Shelf'));
      });
    });

    test('defers to header in response', () {
      _scheduleServer((request) {
        return new Response.ok('test',
            headers: {HttpHeaders.SERVER: 'myServer'});
      });

      return _scheduleGet().then((response) {
        expect(response.headers, containsPair(HttpHeaders.SERVER, 'myServer'));
      });
    });
  });
}

int _serverPort;

Future _scheduleServer(Handler handler) {
  return schedule(() => shelf_io.serve(handler, 'localhost', 0).then((server) {
    currentSchedule.onComplete.schedule(() {
      _serverPort = null;
      return server.close(force: true);
    });

    _serverPort = server.port;
  }));
}

Future<http.Response> _scheduleGet({Map<String, String> headers}) {
  if (headers == null) headers = {};

  return schedule(() =>
      http.get('http://localhost:$_serverPort/', headers: headers));
}

Future<http.StreamedResponse> _schedulePost({Map<String, String> headers,
    String body}) {

  return schedule(() {

    var request = new http.Request('POST',
        Uri.parse('http://localhost:$_serverPort/'));

    if (headers != null) request.headers.addAll(headers);
    if (body != null) request.body = body;

    return request.send();
  });
}
