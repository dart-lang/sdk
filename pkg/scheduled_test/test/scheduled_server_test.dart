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

import 'metatest.dart';
import 'utils.dart';

void main() {
  setUpTimeout();

  expectTestsPass("a server with no handlers does nothing", () {
    test('test', () => new ScheduledServer());
  });

  expectTestsPass("a server with no handlers that receives a request throws an "
      "error", () {
    var errors;
    test('test 1', () {
      currentSchedule.onException.schedule(() {
        errors = currentSchedule.errors;
      });

      var server = new ScheduledServer();
      expect(server.url.then((url) => http.read(url.resolve('/hello'))),
          completion(equals('Hello, test!')));
    });

    test('test 2', () {
      expect(errors, everyElement(new isInstanceOf<ScheduleError>()));
      // TODO(nweiz): There can be three errors due to issue 9151. The
      // HttpParserException is reported without a stack trace, and so when it's
      // wrapped twice it registers as a different exception each time (because
      // it's given an ad-hoc stack trace). Always expect two exceptions when
      // issue 9151 is fixed.
      expect(errors.length, inInclusiveRange(2, 3));
      expect(errors[0].error, equals("'scheduled server 0' received GET /hello "
          "when no more requests were expected."));
      expect(errors[1].error, new isInstanceOf<HttpParserException>());
      if (errors.length > 2) {
        expect(errors[2].error, new isInstanceOf<HttpParserException>());
      }
    });
  }, passing: ['test 2']);

  expectTestsPass("a handler runs when it's hit", () {
    test('test', () {
      var server = new ScheduledServer();
      expect(server.url.then((url) => http.read(url.resolve('/hello'))),
          completion(equals('Hello, test!')));

      server.handle('GET', '/hello', (request) {
        request.response.write('Hello, test!');
        request.response.close();
      });
    });
  });

  expectTestsPass("a handler blocks the schedule on the returned future", () {
    test('test', () {
      var blockedOnFuture = false;
      var server = new ScheduledServer();
      expect(server.url.then((url) => http.read(url.resolve('/hello'))),
          completion(equals('Hello, test!')));

      server.handle('GET', '/hello', (request) {
        request.response.write('Hello, test!');
        request.response.close();
        return pumpEventQueue().then((_) {
          blockedOnFuture = true;
        });
      });

      schedule(() => expect(blockedOnFuture, isTrue));
    });
  });

  expectTestsPass("a handler fails if it's hit too early", () {
    var errors;
    test('test 1', () {
      currentSchedule.onException.schedule(() {
        errors = currentSchedule.errors;
      });

      var server = new ScheduledServer();
      var response = server.url.then((url) => http.read(url.resolve('/hello')));
      expect(response, completion(equals('Hello, test!')));

      // Block the schedule until we're sure the request has hit the server.
      schedule(() => response);

      // Add a task's worth of space to avoid hitting the heuristic of waiting
      // for the immediately-preceding task.
      schedule(() => null);

      server.handle('GET', '/hello', (request) {
        request.response.write('Hello, test!');
        request.response.close();
      });
    });

    test('test 2', () {
      // TODO(nweiz): There can be three errors due to issue 9151. The
      // HttpParserException is reported without a stack trace, and so when it's
      // wrapped twice it registers as a different exception each time (because
      // it's given an ad-hoc stack trace). Always expect two exceptions when
      // issue 9151 is fixed.
      expect(errors.length, inInclusiveRange(2, 3));
      expect(errors[0].error, equals("'scheduled server 0' received GET /hello "
          "earlier than expected."));
      expect(errors[1].error, new isInstanceOf<HttpParserException>());
      if (errors.length > 2) {
        expect(errors[2].error, new isInstanceOf<HttpParserException>());
      }
      expect(errors, everyElement(new isInstanceOf<ScheduleError>()));
    });
  }, passing: ['test 2']);

  expectTestsPass("a handler waits for the immediately prior task to complete "
      "before checking if it's too early", () {
    test('test', () {
      var server = new ScheduledServer();
      expect(server.url.then((url) => http.read(url.resolve('/hello'))),
          completion(equals('Hello, test!')));

      // Sleeping here is unfortunate, but we want to be sure that the HTTP
      // request hits the server during this test without actually blocking the
      // task on the request completing.
      //
      // This is also a potential race condition, but hopefully a local HTTP
      // request won't take 1s.
      schedule(() => new Future.delayed(new Duration(seconds: 1)));

      server.handle('GET', '/hello', (request) {
        request.response.write('Hello, test!');
        request.response.close();
      });
    });
  });

  expectTestsPass("a handler fails if the url is wrong", () {
    var errors;
    test('test 1', () {
      currentSchedule.onException.schedule(() {
        errors = currentSchedule.errors;
      });

      var server = new ScheduledServer();
      expect(server.url.then((url) => http.read(url.resolve('/hello'))),
          completion(equals('Hello, test!')));

      server.handle('GET', '/goodbye', (request) {
        request.response.write('Goodbye, test!');
        request.response.close();
      });
    });

    test('test 2', () {
      // TODO(nweiz): There can be three errors due to issue 9151. The
      // HttpParserException is reported without a stack trace, and so when it's
      // wrapped twice it registers as a different exception each time (because
      // it's given an ad-hoc stack trace). Always expect two exceptions when
      // issue 9151 is fixed.
      expect(errors.length, inInclusiveRange(2, 3));
      expect(errors[0].error, equals("'scheduled server 0' expected GET "
          "/goodbye, but got GET /hello."));
      expect(errors[1].error, new isInstanceOf<HttpParserException>());
      if (errors.length > 2) {
        expect(errors[2].error, new isInstanceOf<HttpParserException>());
      }
    });
  }, passing: ['test 2']);

  expectTestsPass("a handler fails if the method is wrong", () {
    var errors;
    test('test 1', () {
      currentSchedule.onException.schedule(() {
        errors = currentSchedule.errors;
      });

      var server = new ScheduledServer();
      expect(server.url.then((url) => http.head(url.resolve('/hello'))),
          completes);

      server.handle('GET', '/hello', (request) {
        request.response.write('Hello, test!');
        request.response.close();
      });
    });

    test('test 2', () {
      // TODO(nweiz): There can be three errors due to issue 9151. The
      // HttpParserException is reported without a stack trace, and so when it's
      // wrapped twice it registers as a different exception each time (because
      // it's given an ad-hoc stack trace). Always expect two exceptions when
      // issue 9151 is fixed.
      expect(errors.length, inInclusiveRange(2, 3));
      expect(errors[0].error, equals("'scheduled server 0' expected GET "
          "/hello, but got HEAD /hello."));
      expect(errors[1].error, new isInstanceOf<HttpParserException>());
      if (errors.length > 2) {
        expect(errors[2].error, new isInstanceOf<HttpParserException>());
      }
    });
  }, passing: ['test 2']);

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

      server.handle('GET', '/hello', (request) {
        request.response.write('Hello, test!');
        request.response.close();
      });
    });

    test('test 2', () {
      expect(clock.time, equals(2));

      expect(errors, everyElement(new isInstanceOf<ScheduleError>()));
      expect(errors.map((e) => e.error), equals(["The schedule timed out after "
        "0:00:00.002000 of inactivity."]));
    });
  }, passing: ['test 2']);

  expectTestsPass("multiple handlers in series respond to requests in series",
      () {
    test('test', () {
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

      server.handle('GET', '/hello/1', (request) {
        request.response.write('Hello, request 1!');
        request.response.close();
      });

      server.handle('GET', '/hello/2', (request) {
        request.response.write('Hello, request 2!');
        request.response.close();
      });

      server.handle('GET', '/hello/3', (request) {
        request.response.write('Hello, request 3!');
        request.response.close();
      });
    });
  });

  expectTestsPass("a server that receives a request after all its handlers "
      "have run throws an error", () {
    var errors;
    test('test 1', () {
      currentSchedule.onException.schedule(() {
        errors = currentSchedule.errors;
      });

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

      server.handle('GET', '/hello/1', (request) {
        request.response.write('Hello, request 1!');
        request.response.close();
      });

      server.handle('GET', '/hello/2', (request) {
        request.response.write('Hello, request 2!');
        request.response.close();
      });
    });

    test('test 2', () {
      // TODO(nweiz): There can be three errors due to issue 9151. The
      // HttpParserException is reported without a stack trace, and so when it's
      // wrapped twice it registers as a different exception each time (because
      // it's given an ad-hoc stack trace). Always expect two exceptions when
      // issue 9151 is fixed.
      expect(errors.length, inInclusiveRange(2, 3));
      expect(errors[0].error, equals("'scheduled server 0' received GET "
          "/hello/3 when no more requests were expected."));
      expect(errors[1].error, new isInstanceOf<HttpParserException>());
      if (errors.length > 2) {
        expect(errors[2].error, new isInstanceOf<HttpParserException>());
      }
    });
  }, passing: ['test 2']);

  expectTestsPass("an error in a handler doesn't cause a timeout", () {
    var errors;
    test('test 1', () {
      currentSchedule.onException.schedule(() {
        errors = currentSchedule.errors;
      });

      var server = new ScheduledServer();
      expect(server.url.then((url) => http.read(url.resolve('/hello'))),
          completion(equals('Hello, test!')));

      server.handle('GET', '/hello', (request) {
        throw 'oh no';
      });
    });

    test('test 2', () {
      // TODO(nweiz): There can be three errors due to issue 9151. The
      // HttpParserException is reported without a stack trace, and so when it's
      // wrapped twice it registers as a different exception each time (because
      // it's given an ad-hoc stack trace). Always expect two exceptions when
      // issue 9151 is fixed.
      expect(errors.length, inInclusiveRange(2, 3));
      expect(errors[0].error, equals('oh no'));
      expect(errors[1].error, new isInstanceOf<HttpParserException>());
      if (errors.length > 2) {
        expect(errors[2].error, new isInstanceOf<HttpParserException>());
      }
    });
  }, passing: ['test 2']);
}
