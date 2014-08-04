// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library watcher.utils;

import 'dart:async';
import 'dart:io';
import 'dart:collection';

/// Returns `true` if [error] is a [FileSystemException] for a missing
/// directory.
bool isDirectoryNotFoundException(error) {
  if (error is! FileSystemException) return false;

  // See dartbug.com/12461 and tests/standalone/io/directory_error_test.dart.
  var notFoundCode = Platform.operatingSystem == "windows" ? 3 : 2;
  return error.osError.errorCode == notFoundCode;
}

/// Returns the union of all elements in each set in [sets].
Set unionAll(Iterable<Set> sets) =>
    sets.fold(new Set(), (union, set) => union.union(set));

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

/// Like [new Future], but avoids around issue 11911 by using [new Future.value]
/// under the covers.
Future newFuture(callback()) => new Future.value().then((_) => callback());

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

/// A stream transformer that batches all events that are sent at the same time.
///
/// When multiple events are synchronously added to a stream controller, the
/// [StreamController] implementation uses [scheduleMicrotask] to schedule the
/// asynchronous firing of each event. In order to recreate the synchronous
/// batches, this collates all the events that are received in "nearby"
/// microtasks.
class BatchedStreamTransformer<T> implements StreamTransformer<T, List<T>> {
  Stream<List<T>> bind(Stream<T> input) {
    var batch = new Queue();
    return new StreamTransformer<T, List<T>>.fromHandlers(
        handleData: (event, sink) {
      batch.add(event);

      // [Timer.run] schedules an event that runs after any microtasks that have
      // been scheduled.
      Timer.run(() {
        if (batch.isEmpty) return;
        sink.add(batch.toList());
        batch.clear();
      });
    }, handleDone: (sink) {
      if (batch.isNotEmpty) {
        sink.add(batch.toList());
        batch.clear();
      }
      sink.close();
    }).bind(input);
  }
}
