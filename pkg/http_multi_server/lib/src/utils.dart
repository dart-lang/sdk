// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library http_multi_server.utils;

import 'dart:async';
import 'dart:io';

// TODO(nweiz): Revert this to the version of [mergeStreams] found elsewhere in
// the repo once issue 19815 is fixed in dart:io.
/// Merges all streams in [streams] into a single stream that emits all of their
/// values.
///
/// The returned stream will be closed only when every stream in [streams] is
/// closed.
Stream mergeStreams(Iterable<Stream> streams) {
  var subscriptions = new Set();
  var controller;
  controller = new StreamController(onListen: () {
    for (var stream in streams) {
      var subscription;
      subscription = stream.listen(controller.add, onError: (error, trace) {
        if (subscriptions.length == 1) {
          // If the last subscription errored, pass it on.
          controller.addError(error, trace);
        } else {
          // If only one of the subscriptions has an error (usually IPv6 failing
          // late), then just remove that subscription and ignore the error.
          subscriptions.remove(subscription);
          subscription.cancel();
        }
      }, onDone: () {
        subscriptions.remove(subscription);
        if (subscriptions.isEmpty) controller.close();
      });
      subscriptions.add(subscription);
    }
  }, onCancel: () {
    for (var subscription in subscriptions) {
      subscription.cancel();
    }
  }, onPause: () {
    for (var subscription in subscriptions) {
      subscription.pause();
    }
  }, onResume: () {
    for (var subscription in subscriptions) {
      subscription.resume();
    }
  }, sync: true);

  return controller.stream;
}
