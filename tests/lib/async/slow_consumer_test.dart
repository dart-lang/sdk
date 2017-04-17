// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--old_gen_heap_size=64

library slow_consumer_test;

import 'package:async_helper/async_helper.dart';
import "package:expect/expect.dart";
import 'dart:async';

const int KB = 1024;
const int MB = KB * KB;
const int GB = KB * KB * KB;

class SlowConsumer extends StreamConsumer {
  var current = new Future.value(0);
  final int bytesPerSecond;
  int finalCount;

  SlowConsumer(int this.bytesPerSecond);

  Future consume(Stream stream) {
    return addStream(stream).then((_) => close());
  }

  Future addStream(Stream stream) {
    bool done = false;
    Completer completer = new Completer();
    var subscription;
    subscription = stream.listen((List<int> data) {
      current = current.then((count) {
        // Simulated amount of time it takes to handle the data.
        int ms = data.length * 1000 ~/ bytesPerSecond;
        Duration duration = new Duration(milliseconds: ms);
        if (!done) subscription.pause();
        return new Future.delayed(duration, () {
          if (!done) subscription.resume();
          // Make sure we use data here to keep tracking it.
          return count + data.length;
        });
      });
    }, onDone: () {
      done = true;
      current.then((count) {
        finalCount = count;
        completer.complete(count);
      });
    });
    return completer.future;
  }

  Future close() {
    return new Future.value(finalCount);
  }
}

class DataProvider {
  final int chunkSize;
  final int bytesPerSecond;
  int sentCount = 0;
  int targetCount;
  StreamController controller;
  Timer pendingSend;

  DataProvider(int this.bytesPerSecond, int this.targetCount, this.chunkSize) {
    controller = new StreamController(
        sync: true, onPause: onPauseStateChange, onResume: onPauseStateChange);
    Timer.run(send);
  }

  Stream get stream => controller.stream;

  send() {
    if (pendingSend != null) {
      pendingSend.cancel();
      pendingSend = null;
    }
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
    controller.add(new List(listSize));
    int ms = listSize * 1000 ~/ bytesPerSecond;
    Duration duration = new Duration(milliseconds: ms);
    if (!controller.isPaused) {
      pendingSend = new Timer(duration, send);
    }
  }

  onPauseStateChange() {
    // We don't care if we just unpaused or paused. In either case we just
    // call send which will test it for us.
    send();
  }
}

main() {
  asyncStart();
  // The data provider can deliver 800MB/s of data. It sends 100MB of data to
  // the slower consumer who can only read 200MB/s. The data is sent in 1MB
  // chunks.
  //
  // This test is limited to 64MB of heap-space (see VMOptions on top of the
  // file). If the consumer doesn't pause the data-provider it will run out of
  // heap-space.

  new DataProvider(800 * MB, 100 * MB, 1 * MB)
      .stream
      .pipe(new SlowConsumer(200 * MB))
      .then((count) {
    Expect.equals(100 * MB, count);
    asyncEnd();
  });
}
