// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library scheduled_server.handler;

import 'dart:async';
import 'dart:io';

import '../../scheduled_server.dart';
import '../../scheduled_test.dart';
import '../utils.dart';

/// A handler for a single request to a [ScheduledServer].
class Handler {
  /// The server for which this handler will handle a request.
  final ScheduledServer server;

  /// The expected method of the request to be handled.
  final String method;

  /// The expected path of the request to be handled.
  final String path;

  /// The function to run to handle the request.
  ScheduledHandler get fn => _fn;
  ScheduledHandler _fn;

  /// The scheduled task immediately prior to this handler. If this task is
  /// running when this handler receives a request, it should wait until the
  /// task has completed.
  ///
  /// The last task in the queue will be the prior task because a Handler is
  /// created before its associated [schedule] call.
  final Task _taskBefore = currentSchedule.tasks.contents.last;

  /// The result of running this handler. If an error occurs while running the
  /// handler, that will be piped through this [Future].
  Future get result => _resultCompleter.future;
  final _resultCompleter = new Completer();

  /// Whether it's time for the handler to receive its request.
  var ready = false;

  Handler(this.server, this.method, this.path, ScheduledHandler fn) {
    _fn = (request) {
      return _waitForTask().then((_) {
        if (!ready) {
          throw "'${server.description}' received $method $path earlier than "
              "expected.";
        }

        // Use a nested call to [schedule] to help the user tell the difference
        // between a test failing while waiting for a handler and a test failing
        // while executing a handler.
        chainToCompleter(schedule(() {
          return new Future.sync(() {
            if (request.method != method || request.uri.path != path) {
              throw "'${server.description}' expected $method $path, "
                  "but got ${request.method} ${request.uri.path}.";
            }

            return fn(request);
          });
        }, "'${server.description}' handling ${request.method} ${request.uri}"),
            _resultCompleter);
      });
    };
  }

  /// If the current task is [_taskBefore], waits for it to finish before
  /// completing. Otherwise, completes immediately.
  Future _waitForTask() {
    return pumpEventQueue().then((_) {
      if (currentSchedule.currentTask != _taskBefore) return;
      // If we're one task before the handler was scheduled, wait for that
      // task to complete and pump the event queue so that [ready] will be
      // set.
      return _taskBefore.result.then((_) => pumpEventQueue());
    });
  }
}
