// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Functions go in this file as opposed to lib/src/utils.dart if they need to
/// be accessible to the transformer-loading isolate.
library pub.asset.utils;

import 'dart:async';

/// A regular expression to match the exception prefix that some exceptions'
/// [Object.toString] values contain.
final _exceptionPrefix = new RegExp(r'^([A-Z][a-zA-Z]*)?(Exception|Error): ');

/// Get a string description of an exception.
///
/// Many exceptions include the exception class name at the beginning of their
/// [toString], so we remove that if it exists.
String getErrorMessage(error) =>
  error.toString().replaceFirst(_exceptionPrefix, '');

/// Returns a buffered stream that will emit the same values as the stream
/// returned by [future] once [future] completes.
///
/// If [future] completes to an error, the return value will emit that error and
/// then close.
///
/// If [broadcast] is true, a broadcast stream is returned. This assumes that
/// the stream returned by [future] will be a broadcast stream as well.
/// [broadcast] defaults to false.
Stream futureStream(Future<Stream> future, {bool broadcast: false}) {
  var subscription;
  var controller;

  future = future.catchError((e, stackTrace) {
    // Since [controller] is synchronous, it's likely that emitting an error
    // will cause it to be cancelled before we call close.
    if (controller != null) controller.addError(e, stackTrace);
    if (controller != null) controller.close();
    controller = null;
  });

  onListen() {
    future.then((stream) {
      if (controller == null) return;
      subscription = stream.listen(
          controller.add,
          onError: controller.addError,
          onDone: controller.close);
    });
  }

  onCancel() {
    if (subscription != null) subscription.cancel();
    subscription = null;
    controller = null;
  }

  if (broadcast) {
    controller = new StreamController.broadcast(
        sync: true, onListen: onListen, onCancel: onCancel);
  } else {
    controller = new StreamController(
        sync: true, onListen: onListen, onCancel: onCancel);
  }
  return controller.stream;
}

/// Returns a [Stream] that will emit the same values as the stream returned by
/// [callback].
///
/// [callback] will only be called when the returned [Stream] gets a subscriber.
Stream callbackStream(Stream callback()) {
  var subscription;
  var controller;
  controller = new StreamController(onListen: () {
    subscription = callback().listen(controller.add,
        onError: controller.addError,
        onDone: controller.close);
  },
      onCancel: () => subscription.cancel(),
      onPause: () => subscription.pause(),
      onResume: () => subscription.resume(),
      sync: true);
  return controller.stream;
}
