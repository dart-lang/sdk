// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--old_gen_heap_size=64

library slow_consumer3_test;

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

Stream<List> dataGenerator(int bytesTotal, int chunkSize) {
  int chunks = bytesTotal ~/ chunkSize;
  return new Stream.fromIterable(new Iterable.generate(chunks, (_) {
    // This assumes one byte per entry. In practice it will be more.
    return new List<int>(chunkSize);
  }));
}

main() {
  asyncStart();
  // The data provider can deliver 800MBs of data as fast as it is
  // requested. The data is sent in 0.5MB chunks. The consumer has a buffer of
  // 3MB. That is, it can accept a few packages without pausing its input.
  //
  // Notice that we aren't really counting bytes, but words, since we use normal
  // lists where each entry takes up a full word. In 64-bit VMs this will be
  // 8 bytes per entry, so the 3*MB buffer is picked to stay below 32 actual
  // MiB.
  //
  // This test is limited to 32MB of heap-space (see VMOptions on top of the
  // file). If the consumer doesn't pause the data-provider it will run out of
  // heap-space.

  dataGenerator(100 * MB, 512 * KB)
      .pipe(new SlowConsumer(200 * MB, 3 * MB))
      .then((count) {
    Expect.equals(100 * MB, count);
    asyncEnd();
  });
}
