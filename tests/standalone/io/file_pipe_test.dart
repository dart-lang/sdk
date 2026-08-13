// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing the dart:io `Pipe` class

import 'dart:io';

import "package:expect/async_helper.dart";
import "package:expect/expect.dart";

testReadFromClosedPipe() async {
  final pipe = await Pipe.create();
  pipe.write.close();
  Expect.isTrue(await pipe.read.isEmpty);
}

testCreateSync() async {
  final pipe = Pipe.createSync();
  pipe.write.close();
  Expect.isTrue(await pipe.read.isEmpty);
}

testMultipleWritesAndReads() async {
  final pipe = await Pipe.create();
  int count = 0;
  pipe.write.add([count]);
  await pipe.read.listen((event) {
    Expect.listEquals([count], event);
    ++count;
    if (count < 10) {
      pipe.write.add([count]);
    } else {
      pipe.write.close();
    }
  }, onDone: () => Expect.equals(10, count));
}

main() async {
  asyncStart();
  try {
    await testReadFromClosedPipe();
    await testCreateSync();
    await testMultipleWritesAndReads();
  } finally {
    asyncEnd();
  }
}
