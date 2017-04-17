// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--old_gen_heap_size=64

library slow_consumer2_test;

import 'package:async_helper/async_helper.dart';
import "package:expect/expect.dart";
import 'dart:async';

const int KB = 1024;
const int MB = KB * KB;
const int GB = KB * KB * KB;

class SlowConsumer extends StreamConsumer {
  int receivedCount = 0;
  final int bytesPerSecond;
  final int bufferSize;
  final List bufferedData = [];
  int usedBufferSize = 0;
  int finalCount;

  SlowConsumer(int this.bytesPerSecond, int this.bufferSize);

  Future consume(Stream stream) {
    return addStream(stream).then((_) => close());
  }

  Future addStream(Stream stream) {
    Completer result = new Completer();
    var subscription;
    subscription = stream.listen((List<int> data) {
      receivedCount += data.length;
      usedBufferSize += data.length;
      bufferedData.add(data);
      int currentBufferedDataLength = bufferedData.length;
      if (usedBufferSize > bufferSize) {
        subscription.pause();
        usedBufferSize = 0;
        int ms = data.length * 1000 ~/ bytesPerSecond;
        Duration duration = new Duration(milliseconds: ms);
        new Timer(duration, () {
          for (int i = 0; i < currentBufferedDataLength; i++) {
            bufferedData[i] = null;
          }
          subscription.resume();
        });
      }
    }, onDone: () {
      finalCount = receivedCount;
      result.complete(receivedCount);
    });
    return result.future;
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

  DataProvider(int this.bytesPerSecond, int this.targetCount, this.chunkSize) {
    controller = new StreamController(
        sync: true, onPause: onPauseStateChange, onResume: onPauseStateChange);
    Timer.run(send);
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
    controller.add(new List(listSize));
    int ms = listSize * 1000 ~/ bytesPerSecond;
    Duration duration = new Duration(milliseconds: ms);
    if (!controller.isPaused) new Timer(duration, send);
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
  // chunks. The consumer has a buffer of 5MB. That is, it can accept a few
  // packages without pausing its input.
  //
  // This test is limited to 32MB of heap-space (see VMOptions on top of the
  // file). If the consumer doesn't pause the data-provider it will run out of
  // heap-space.

  new DataProvider(800 * MB, 100 * MB, 1 * MB)
      .stream
      .pipe(new SlowConsumer(200 * MB, 5 * MB))
      .then((count) {
    Expect.equals(100 * MB, count);
    asyncEnd();
  });
}
