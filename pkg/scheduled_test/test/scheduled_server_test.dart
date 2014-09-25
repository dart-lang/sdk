// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library scheduled_server_test;

import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:scheduled_test/scheduled_server.dart';
import 'package:scheduled_test/scheduled_test.dart';
import 'package:scheduled_test/src/mock_clock.dart' as mock_clock;
import 'package:shelf/shelf.dart' as shelf;

import 'package:metatest/metatest.dart';
import 'utils.dart';

void main() => initTests(_test);

void _test(message) {
  initMetatest(message);

  setUpTimeout();

  expectTestPasses("a server with no handlers does nothing",
      () => new ScheduledServer());

  expectServerError("a server with no handlers that receives a request throws "
      "an error", () {
    var server = new ScheduledServer();
    expect(server.url.then((url) => http.read(url.resolve('/hello'))),
        completion(equals('Hello, test!')));
  }, "'scheduled server 0' received GET /hello when no more requests were "
      "expected.");

  expectTestPasses("a handler runs when it's hit", () {
    var server = new ScheduledServer();
    expect(server.url.then((url) => http.read(url.resolve('/hello'))),
        completion(equals('Hello, test!')));

    server.handle('GET', '/hello',
        (request) => new shelf.Response.ok('Hello, test!'));
  });

  expectTestPasses("a handler blocks the schedule on the returned future", () {
    var blockedOnFuture = false;
    var server = new ScheduledServer();
    expect(server.url.then((url) => http.read(url.resolve('/hello'))),
        completion(equals('Hello, test!')));

    server.handle('GET', '/hello', (request) {
      return pumpEventQueue().then((_) {
        blockedOnFuture = true;
        return new shelf.Response.ok('Hello, test!');
      });
    });

    schedule(() => expect(blockedOnFuture, isTrue));
  });

  expectServerError("a handler fails if it's hit too early", () {
    var server = new ScheduledServer();
    var response = server.url.then((url) => http.read(url.resolve('/hello')));
    expect(response, completion(equals('Hello, test!')));

    // Block the schedule until we're sure the request has hit the server.
    schedule(() => response);

    // Add an additional task here so that when the previous task hits the
    // server, it will be considered too early. Otherwise we'd hit the heuristic
    // of allowing the server to be hit in the immediately prior task.
    schedule(() => null);

    server.handle('GET', '/hello',
        (request) => new shelf.Response.ok('Hello, test!'));
  }, "'scheduled server 0' received GET /hello earlier than expected.");

  expectTestPasses("a handler waits for the immediately prior task to complete "
      "before checking if it's too early", () {
    var server = new ScheduledServer();
    expect(server.url.then((url) => http.read(url.resolve('/hello'))),
        completion(equals('Hello, test!')));

    // Sleeping here is unfortunate, but we want to be sure that the HTTP
    // request hits the server during this test without actually blocking the
    // task on the request completing.
    //
    // This is also a potential race condition, but hopefully a local HTTP
    // request won't take 500ms.
    schedule(() => new Future.delayed(new Duration(milliseconds: 500)));

    server.handle('GET', '/hello',
        (request) => new shelf.Response.ok('Hello, test!'));
  });

  expectServerError("a handler fails if the url is wrong", () {
    var server = new ScheduledServer();
    expect(server.url.then((url) => http.read(url.resolve('/hello'))),
        completion(equals('Hello, test!')));

    server.handle('GET', '/goodbye',
        (request) => new shelf.Response.ok('Goodbye, test!'));
  }, "'scheduled server 0' expected GET /goodbye, but got GET /hello.");

  expectServerError("a handler fails if the method is wrong", () {
    var server = new ScheduledServer();
    expect(server.url.then((url) => http.head(url.resolve('/hello'))),
        completes);

    server.handle('GET', '/hello',
        (request) => new shelf.Response.ok('Hello, test!'));
  }, "'scheduled server 0' expected GET /hello, but got HEAD /hello.");

  expectTestsPass("a handler times out waiting to be hit", () {
    var clock = mock_clock.mock()..run();
    var timeOfException;
    var errors;
    test('test 1', () {
      currentSchedule.timeout = new Duration(milliseconds: 2);
      currentSchedule.onException.schedule(() {
        timeOfException = clock.time;
        errors = currentSchedule.errors;
      });

      var server = new ScheduledServer();

      server.handle('GET', '/hello',
          (request) => new shelf.Response.ok('Hello, test!'));
    });

    test('test 2', () {
      expect(clock.time, equals(2));

      expect(errors.single, new isInstanceOf<ScheduleError>());
      expect(errors.single.error.toString(), equals(
          "The schedule timed out after 0:00:00.002000 of inactivity."));
    });
  }, passing: ['test 2']);

  expectTestPasses("multiple handlers in series respond to requests in series",
      () {
    var server = new ScheduledServer();
    expect(server.url.then((url) {
      return http.read(url.resolve('/hello/1')).then((response) {
        expect(response, equals('Hello, request 1!'));
        return http.read(url.resolve('/hello/2'));
      }).then((response) {
        expect(response, equals('Hello, request 2!'));
        return http.read(url.resolve('/hello/3'));
      }).then((response) => expect(response, equals('Hello, request 3!')));
    }), completes);

    server.handle('GET', '/hello/1',
        (request) => new shelf.Response.ok('Hello, request 1!'));

    server.handle('GET', '/hello/2',
        (request) => new shelf.Response.ok('Hello, request 2!'));

    server.handle('GET', '/hello/3',
        (request) => new shelf.Response.ok('Hello, request 3!'));
  });

  expectServerError("a server that receives a request after all its handlers "
      "have run throws an error", () {
    var server = new ScheduledServer();
    expect(server.url.then((url) {
      return http.read(url.resolve('/hello/1')).then((response) {
        expect(response, equals('Hello, request 1!'));
        return http.read(url.resolve('/hello/2'));
      }).then((response) {
        expect(response, equals('Hello, request 2!'));
        return http.read(url.resolve('/hello/3'));
      }).then((response) => expect(response, equals('Hello, request 3!')));
    }), completes);

    server.handle('GET', '/hello/1',
        (request) => new shelf.Response.ok('Hello, request 1!'));

    server.handle('GET', '/hello/2',
        (request) => new shelf.Response.ok('Hello, request 2!'));
  }, "'scheduled server 0' received GET /hello/3 when no more requests were "
      "expected.");

  expectServerError("an error in a handler doesn't cause a timeout", () {
    var server = new ScheduledServer();
    expect(server.url.then((url) => http.read(url.resolve('/hello'))),
        completion(equals('Hello, test!')));

    server.handle('GET', '/hello', (request) => fail('oh no'));
  }, 'oh no');
}

/// Creates a metatest that runs [testBody], captures its schedule errors, and
/// asserts that it throws an error with the given [errorMessage].
void expectServerError(String description, testBody(),
    String errorMessage) {
  expectTestFails(description, testBody, (errors) {
    // There can be between one and three errors here. The first is the
    // expected server error. The second is an HttpException that may occur if
    // the server is closed fast enough after the error. The third is due to
    // issue 9151: the HttpException is reported without a stack trace, and so
    // when it's wrapped twice it registers as a different exception each time
    // (because it's given an ad-hoc stack trace).
    expect(errors.length, inInclusiveRange(1, 3));
    expect(errors[0].error.toString(), equals(errorMessage));

    for (var i = 1; i < errors.length; i++) {
      expect(errors[i].error, new isInstanceOf<HttpException>());
    }
  });
}
