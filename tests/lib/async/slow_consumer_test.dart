// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--old_gen_heap_size=32

library slow_consumer_test;

import 'dart:async';
import 'dart:isolate';

const int KB = 1024;
const int MB = KB * KB;
const int GB = KB * KB * KB;

class SlowConsumer extends StreamConsumer {
  var current = new Future.immediate(0);
  final int bytesPerSecond;

  SlowConsumer(int this.bytesPerSecond);

  Future consume(Stream stream) {
    Completer completer = new Completer();
    var subscription;
    subscription = stream.listen(
      (List<int> data) {
        current = current
          .then((count) {
            // Simulated amount of time it takes to handle the data.
            int ms = data.length * 1000 ~/ bytesPerSecond;
            subscription.pause();
            return new Future.delayed(ms, () {
              subscription.resume();
              // Make sure we use data here to keep tracking it.
              return count + data.length;
            });
          });
        },
      onDone: () { current.then((count) { completer.complete(count); }); });
    return completer.future;
  }
}

class DataProvider {
  final int chunkSize;
  final int bytesPerSecond;
  int sentCount = 0;
  int targetCount;
  StreamController controller;

  DataProvider(int this.bytesPerSecond, int this.targetCount, this.chunkSize) {
    controller = new StreamController(onPauseStateChange: onPauseStateChange);
    new Timer(0, (_) => send());
  }

  Stream get stream => controller.stream;

  send() {
    if (controller.isPaused) return;
    if (sentCount == targetCount) {
      controller.close();
      return;
    }
    int listSize = chunkSize;
    sentCount += listSize;
    if (sentCount > targetCount) {
      listSize -= sentCount - targetCount;
      sentCount = targetCount;
    }
    controller.add(new List.fixedLength(listSize));
    int ms = listSize * 1000 ~/ bytesPerSecond;
    if (!controller.isPaused) new Timer(ms, (_) => send());
  }

  onPauseStateChange() {
    // We don't care if we just unpaused or paused. In either case we just
    // call send which will test it for us.
    send();
  }
}

main() {
  var port = new ReceivePort();
  // The data provider can deliver 800MB/s of data. It sends 100MB of data to
  // the slower consumer who can only read 200MB/s. The data is sent in 1MB
  // chunks.
  //
  // This test is limited to 32MB of heap-space (see VMOptions on top of the
  // file). If the consumer doesn't pause the data-provider it will run out of
  // heap-space.

  new DataProvider(800 * MB, 100 * MB, 1 * MB).stream
    .pipe(new SlowConsumer(200 * MB))
    .then((count) {
      port.close();
      Expect.equals(100 * MB, count);
    });
}
