// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library scheduled_test.scheduled_server;

import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:uri';

import 'scheduled_test.dart';
import 'src/utils.dart';
import 'src/scheduled_server/handler.dart';
import 'src/scheduled_server/safe_http_server.dart';

typedef Future ScheduledHandler(HttpRequest request);

/// A class representing an [HttpServer] that's scheduled to run in the course
/// of the test. This class allows the server's request handling to be scheduled
/// synchronously.
///
/// The server expects requests to be received in the order [handle] is called,
/// and expects that no additional requests will be received.
class ScheduledServer {
  /// The description of the server.
  final String description;

  /// The wrapped server.
  final Future<HttpServer> _server;

  /// The queue of handlers to run for upcoming requests. Each [Future] will
  /// complete once the schedule reaches the point where that handler was
  /// scheduled.
  final _handlers = new Queue<Handler>();

  /// The number of servers created. Used for auto-generating descriptions;
  static var _count = 0;

  ScheduledServer._(this._server, this.description);

  /// Creates a new server listening on an automatically-allocated port on
  /// localhost. [description] is used to refer to the server in debugging
  /// messages.
  factory ScheduledServer([String description]) {
    var id = _count++;
    if (description == null) description = 'scheduled server $id';

    var scheduledServer;
    scheduledServer = new ScheduledServer._(schedule(() {
      return SafeHttpServer.bind("127.0.0.1", 0).then((server) {
        server.listen(scheduledServer._handleRequest,
            onError: (e) => currentSchedule.signalError(e));
        currentSchedule.onComplete.schedule(server.close);
        return server;
      });
    }, "starting '$description'"), description);
    return scheduledServer;
  }

  /// The port on which the server is listening.
  Future<int> get port => _server.then((s) => s.port);

  /// The base URL of the server, including its port.
  Future<Uri> get url => port.then((p) => Uri.parse("http://localhost:$p"));

  /// Schedules [handler] to handle a request to the server with [method] and
  /// [path]. The schedule will wait until an HTTP request is received. If that
  /// request doesn't have the expected [method] and [path], it will fail.
  /// Otherwise, it will run [fn]. If [fn] returns a [Future], the schedule will
  /// wait until that [Future] completes.
  ///
  /// The request must be received at the point in the schedule at which
  /// [handle] was called, or in the task immediately prior (to allow for
  /// non-deterministic asynchronicity). Otherwise, an error will be thrown.
  void handle(String method, String path, ScheduledHandler fn) {
    var handler = new Handler(this, method, path, fn);
    _handlers.add(handler);
    schedule(() {
      handler.ready = true;
      return handler.result.catchError((e) {
        // Close the server so that we don't leave a dangling request.
        _server.then((s) => s.close());
        throw e;
      });
    }, "'$description' waiting for $method $path");
  }

  /// The handler for incoming [HttpRequest]s to this server. This dispatches
  /// the request to the first handler in the queue. It's that handler's
  /// responsibility to check that the method/path are correct and that it's
  /// being run at the correct time.
  void _handleRequest(HttpRequest request) {
    wrapFuture(new Future.sync(() {
      if (_handlers.isEmpty) {
        throw "'$description' received ${request.method} ${request.uri.path} "
            "when no more requests were expected.";
      }
      return _handlers.removeFirst().fn(request);
    }).catchError((e) {
      // Close the server so that we don't leave a dangling request.
      _server.then((s) => s.close());
      throw e;
    }), 'receiving ${request.method} ${request.uri}');
  }
}
