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

/// Returns a buffered stream that will emit the same values as the stream
/// returned by [future] once [future] completes.
///
/// If [future] completes to an error, the return value will emit that error and
/// then close.
Stream futureStream(Future<Stream> future) {
  var controller = new StreamController(sync: true);
  future.then((stream) {
    stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close);
  }).catchError((e, stackTrace) {
    controller.addError(e, stackTrace);
    controller.close();
  });
  return controller.stream;
}

/// Like [new Future], but avoids around issue 11911 by using [new Future.value]
/// under the covers.
Future newFuture(callback()) => new Future.value().then((_) => callback());

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
