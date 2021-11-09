// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This is a regression test for the bug in
// https://github.com/flutter/flutter/issues/89584.
// Verifies a Field::RecordStore is not done before all fields populated.

import 'dart:isolate';
import 'dart:typed_data';

void main() async {
  final receivePort = ReceivePort();
  await Isolate.spawn<SendPort>(isolateEntry, receivePort.sendPort);
  final wrapper = (await receivePort.first) as Wrapper;
  final result = readWrapperUint8ListView(wrapper);
  print(result);
}

const uint8ListLength = 1000000;

void isolateEntry(SendPort sendPort) async {
  final uint8list = Uint8List(uint8ListLength);
  sendPort.send(Wrapper(
    uint8list.buffer.asUint8List(0, uint8list.length),
  ));
}

int readWrapperUint8ListView(Wrapper wrapper) {
  var result = 0;
  for (int i = 0; i < uint8ListLength; i++) {
    result += wrapper.uint8ListView[i];
  }
  return result;
}

class Wrapper {
  final Uint8List uint8ListView;
  Wrapper(this.uint8ListView);
}
