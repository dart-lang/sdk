// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This exercises 'vm:shared' pragma.

import 'dart:async';
import 'dart:concurrent';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';

void doWork(int i, SendPort results) {
  int result = 0;
  // Calculate fibonacci number i.
  if (i < 3) {
    result = 1;
  } else {
    int pp = 1;
    int p = 1;
    int j = 3;
    while (j <= i) {
      result = pp + p;
      pp = p;
      p = result;
      j++;
    }
  }
  results.send(<int>[i, result]);
}

class SharedState {
  @pragma('vm:shared')
  static final totalProcessed = Uint16List(1);
}

int totalWorkItems = 10000;
int numberOfWorkers = 8;

@pragma('vm:shared')
final workItems = Uint16List.fromList(
  List<int>.generate(totalWorkItems, (i) => i + 1),
);
@pragma('vm:shared')
final lastProcessed = Uint16List(1);
@pragma('vm:shared')
final mutex = Mutex();

late var rpResults;
late var results = <int, int>{};

@pragma('vm:never-inline')
void init() {
  SharedState.totalProcessed[0] = 0;
}

final class Struct1Byte extends Struct {
  @Array(1)
  external Array<Uint8> a0;
}

@pragma('vm:shared')
final s1byte = Struct.create<Struct1Byte>();

final class StructWithArrays extends Struct {
  @Array.multi([16])
  external Array<Int8> a;
}

@pragma('vm:shared')
final switharrays = Struct.create<StructWithArrays>();

final class MyUnion extends Union {
  @Int32()
  external int a;

  @Float()
  external double b;
}

@pragma('vm:shared')
final myUnion = Union.create<MyUnion>();

@pragma('vm:shared')
final myArray = switharrays.a;

void main(List<String> args) async {
  asyncStart();

  if (args.length > 0) {
    totalWorkItems = int.parse(args[0]);
    if (args.length > 1) {
      numberOfWorkers = int.parse(args[1]);
    }
  }
  print('workItems: $totalWorkItems workers: $numberOfWorkers');

  init();

  rpResults = RawReceivePort((message) {
    Expect.isFalse(results.containsKey(message[0]));
    results[message[0]] = message[1];
  });
  var sendPort = rpResults.sendPort;

  var list = List.generate(
    numberOfWorkers,
    (index) => Isolate.run(() async {
      int countProcessed = 0;
      while (true) {
        var mine = mutex.runLocked(() => lastProcessed[0]++);
        if (mine >= workItems.length) {
          break;
        }
        doWork(workItems[mine], sendPort);
        countProcessed++;
        mutex.runLocked(() => SharedState.totalProcessed[0]++);
        await Future.delayed(Duration(seconds: 0));
      }
      print('worker $index processed $countProcessed items');
    }, debugName: 'worker $index'),
  );
  await Future.wait(list);
  rpResults.close();
  Expect.equals(results.keys.length, totalWorkItems);
  Expect.equals(SharedState.totalProcessed[0], totalWorkItems);
  print('all ${SharedState.totalProcessed[0]} done');
  asyncEnd();
}
