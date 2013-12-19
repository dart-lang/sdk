// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Help for combining multiple streams into a single stream.
 */
library dart.pkg.async.stream_zip;

import "dart:async";

/**
 * A stream that combines the values of other streams.
 */
class StreamZip extends Stream<List> {
  final Iterable<Stream> _streams;
  StreamZip(Iterable<Stream> streams) : _streams = streams;

  StreamSubscription<List> listen(void onData(List data), {
                                  Function onError,
                                  void onDone(),
                                  bool cancelOnError}) {
    cancelOnError = identical(true, cancelOnError);
    List<StreamSubscription> subscriptions = <StreamSubscription>[];
    StreamController controller;
    List current;
    int dataCount = 0;

    /// Called for each data from a subscription in [subscriptions].
    void handleData(int index, data) {
      current[index] = data;
      dataCount++;
      if (dataCount == subscriptions.length) {
        List data = current;
        current = new List(subscriptions.length);
        dataCount = 0;
        for (int i = 0; i < subscriptions.length; i++) {
          if (i != index) subscriptions[i].resume();
        }
        controller.add(data);
      } else {
        subscriptions[index].pause();
      }
    }

    /// Called for each error from a subscription in [subscriptions].
    /// Except if [cancelOnError] is true, in which case the function below
    /// is used instead.
    void handleError(Object error, StackTrace stackTrace) {
      controller.addError(error, stackTrace);
    }

    /// Called when a subscription has an error and [cancelOnError] is true.
    ///
    /// Prematurely cancels all subscriptions since we know that we won't
    /// be needing any more values.
    void handleErrorCancel(Object error, StackTrace stackTrace) {
      for (int i = 0; i < subscriptions.length; i++) {
        subscriptions[i].cancel();
      }
      controller.addError(error, stackTrace);
    }

    void handleDone() {
      for (int i = 0; i < subscriptions.length; i++) {
        subscriptions[i].cancel();
      }
      controller.close();
    }

    try {
      for (Stream stream in _streams) {
        int index = subscriptions.length;
        subscriptions.add(stream.listen(
            (data) { handleData(index, data); },
            onError: cancelOnError ? handleError : handleErrorCancel,
            onDone: handleDone,
            cancelOnError: cancelOnError));
      }
    } catch (e) {
      for (int i = subscriptions.length - 1; i >= 0; i--) {
        subscriptions[i].cancel();
      }
      rethrow;
    }

    current = new List(subscriptions.length);

    controller = new StreamController<List>(
      onPause: () {
        for (int i = 0; i < subscriptions.length; i++) {
          // This may pause some subscriptions more than once.
          // These will not be resumed by onResume below, but must wait for the
          // next round.
          subscriptions[i].pause();
        }
      },
      onResume: () {
        for (int i = 0; i < subscriptions.length; i++) {
          subscriptions[i].resume();
        }
      },
      onCancel: () {
        for (int i = 0; i < subscriptions.length; i++) {
          // Canceling more than once is safe.
          subscriptions[i].cancel();
        }
      }
    );

    if (subscriptions.isEmpty) {
      controller.close();
    }
    return controller.stream.listen(onData,
                                    onError: onError,
                                    onDone: onDone,
                                    cancelOnError: cancelOnError);
  }
}
