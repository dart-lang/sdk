// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:http_throttle/http_throttle.dart';
import 'package:unittest/unittest.dart';

void main() {
  test("makes requests until the limit is hit", () {
    var pendingResponses = [];
    var client = new ThrottleClient(10, new MockClient((request) {
      var completer = new Completer();
      pendingResponses.add(completer);
      return completer.future.then((response) {
        pendingResponses.remove(completer);
        return response;
      });
    }));

    // Make the first batch of requests. All of these should be sent
    // immediately.
    for (var i = 0; i < 10; i++) {
      client.get('/');
    }

    return pumpEventQueue().then((_) {
      // All ten of the requests should have responses pending.
      expect(pendingResponses, hasLength(10));

      // Make the second batch of requests. None of these should be sent
      // until the previous batch has finished.
      for (var i = 0; i < 5; i++) {
        client.get('/');
      }

      return pumpEventQueue();
    }).then((_) {
      // Only the original ten requests should have responses pending.
      expect(pendingResponses, hasLength(10));

      // Send the first ten responses, allowing the next batch of requests to
      // fire.
      for (var completer in pendingResponses) {
        completer.complete(new http.Response("done", 200));
      }

      return pumpEventQueue();
    }).then((_) {
      // Now the second batch of responses should be pending.
      expect(pendingResponses, hasLength(5));
    });
  });
}

/// Returns a [Future] that completes after pumping the event queue [times]
/// times. By default, this should pump the event queue enough times to allow
/// any code to run, as long as it's not waiting on some external event.
Future pumpEventQueue([int times = 20]) {
  if (times == 0) return new Future.value();
  // We use a delayed future to allow microtask events to finish. The
  // Future.value or Future() constructors use scheduleMicrotask themselves and
  // would therefore not wait for microtask callbacks that are scheduled after
  // invoking this method.
  return new Future.delayed(Duration.ZERO, () => pumpEventQueue(times - 1));
}
