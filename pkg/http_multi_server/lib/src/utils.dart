// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library http_multi_server.utils;

import 'dart:async';
import 'dart:io';

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
      subscription = stream.listen(controller.add,
          onError: controller.addError,
          onDone: () {
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

/// A cache for [supportsIpV6].
bool _supportsIpV6;

/// Returns whether this computer supports binding to IPv6 addresses.
Future<bool> get supportsIpV6 {
  if (_supportsIpV6 != null) return new Future.value(_supportsIpV6);

  return ServerSocket.bind(InternetAddress.LOOPBACK_IP_V6, 0).then((socket) {
    _supportsIpV6 = true;
    socket.close();
    return true;
  }).catchError((error) {
    if (error is! SocketException) throw error;
    _supportsIpV6 = false;
    return false;
  });
}
