// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test verifies that 'await' implementation calls Zone callbacks from
// correct Zones.

import 'dart:async';

import 'package:expect/expect.dart';

List<String> log = [];

class TestZone {
  final String name;
  TestZone(this.name);

  static T run<T>(String name, T Function() callback) {
    final tz = TestZone(name);
    final zone = Zone.current.fork(
        specification: ZoneSpecification(
            runUnary: tz.runUnary,
            runBinary: tz.runBinary,
            registerUnaryCallback: tz.registerUnaryCallback,
            registerBinaryCallback: tz.registerBinaryCallback,
            scheduleMicrotask: tz.scheduleMicrotask));
    return zone.run(callback);
  }

  R runUnary<R, T>(
      Zone self, ZoneDelegate parent, Zone zone, R Function(T arg) f, T arg) {
    log.add('$name.runUnary');
    return parent.runUnary(zone, f, arg);
  }

  R runBinary<R, T1, T2>(Zone self, ZoneDelegate parent, Zone zone,
      R Function(T1 arg1, T2 arg2) f, T1 arg1, T2 arg2) {
    log.add('$name.runBinary');
    return parent.runBinary(zone, f, arg1, arg2);
  }

  ZoneUnaryCallback<R, T> registerUnaryCallback<R, T>(
      Zone self, ZoneDelegate parent, Zone zone, R Function(T arg) f) {
    log.add('$name.registerUnaryCallback');
    return parent.registerUnaryCallback(zone, (T arg) {
      log.add('$name.unaryCallback');
      return f(arg);
    });
  }

  ZoneBinaryCallback<R, T1, T2> registerBinaryCallback<R, T1, T2>(Zone self,
      ZoneDelegate parent, Zone zone, R Function(T1 arg1, T2 arg2) f) {
    log.add('$name.registerBinaryCallback');
    return parent.registerBinaryCallback(zone, (T1 arg1, T2 arg2) {
      log.add('$name.binaryCallback');
      return f(arg1, arg2);
    });
  }

  void scheduleMicrotask(Zone self, ZoneDelegate parent, Zone zone, void f()) {
    log.add('$name.scheduleMicrotask');
    parent.scheduleMicrotask(zone, f);
  }
}

Future<void> foo() async {
  log.add('--- step 3');
}

Future<void> baz() async {
  log.add('--- step 8');
}

Future<void> bar() async {
  log.add('--- step 6');

  Future f = TestZone.run('Z3', () {
    log.add('--- step 7');
    return baz();
  });

  log.add('--- step 9');
  await TestZone.run('Z4', () async {
    log.add('--- step 10');
    await f;
    log.add('--- step 13');
  });
  log.add('--- step 14');
}

main() async {
  log.add('--- start');
  await TestZone.run('Z1', () async {
    log.add('--- step 1');
    await null;
    log.add('--- step 2');
    await foo();

    log.add('--- step 4');
    await TestZone.run('Z2', () async {
      log.add('--- step 5');
      Future f = bar();

      log.add('--- step 11');
      await TestZone.run('Z4', () async {
        log.add('--- step 12');
        await f;
        log.add('--- step 15');
      });
      log.add('--- step 16');
    });
    log.add('--- step 17');
  });
  log.add('--- end');

  print('Actual log = [');
  for (int i = 0; i < log.length; ++i) {
    print("  /* $i */ '${log[i]}',");
  }
  print('];');

  List<String> expectedLog = [
    /* 0 */ '--- start',
    /* 1 */ '--- step 1',
    /* 2 */ 'Z1.registerUnaryCallback',
    /* 3 */ 'Z1.registerBinaryCallback',
    /* 4 */ 'Z1.scheduleMicrotask',
    /* 5 */ 'Z1.runUnary',
    /* 6 */ 'Z1.unaryCallback',
    /* 7 */ '--- step 2',
    /* 8 */ '--- step 3',
    /* 9 */ 'Z1.scheduleMicrotask',
    /* 10 */ 'Z1.runUnary',
    /* 11 */ 'Z1.unaryCallback',
    /* 12 */ '--- step 4',
    /* 13 */ '--- step 5',
    /* 14 */ '--- step 6',
    /* 15 */ '--- step 7',
    /* 16 */ '--- step 8',
    /* 17 */ '--- step 9',
    /* 18 */ '--- step 10',
    /* 19 */ 'Z4.registerUnaryCallback',
    /* 20 */ 'Z2.registerUnaryCallback',
    /* 21 */ 'Z1.registerUnaryCallback',
    /* 22 */ 'Z4.registerBinaryCallback',
    /* 23 */ 'Z2.registerBinaryCallback',
    /* 24 */ 'Z1.registerBinaryCallback',
    /* 25 */ 'Z3.scheduleMicrotask',
    /* 26 */ 'Z2.scheduleMicrotask',
    /* 27 */ 'Z1.scheduleMicrotask',
    /* 28 */ 'Z2.registerUnaryCallback',
    /* 29 */ 'Z1.registerUnaryCallback',
    /* 30 */ 'Z2.registerBinaryCallback',
    /* 31 */ 'Z1.registerBinaryCallback',
    /* 32 */ '--- step 11',
    /* 33 */ '--- step 12',
    /* 34 */ 'Z4.registerUnaryCallback',
    /* 35 */ 'Z2.registerUnaryCallback',
    /* 36 */ 'Z1.registerUnaryCallback',
    /* 37 */ 'Z4.registerBinaryCallback',
    /* 38 */ 'Z2.registerBinaryCallback',
    /* 39 */ 'Z1.registerBinaryCallback',
    /* 40 */ 'Z2.registerUnaryCallback',
    /* 41 */ 'Z1.registerUnaryCallback',
    /* 42 */ 'Z2.registerBinaryCallback',
    /* 43 */ 'Z1.registerBinaryCallback',
    /* 44 */ 'Z4.runUnary',
    /* 45 */ 'Z2.runUnary',
    /* 46 */ 'Z1.runUnary',
    /* 47 */ 'Z1.unaryCallback',
    /* 48 */ 'Z2.unaryCallback',
    /* 49 */ 'Z4.unaryCallback',
    /* 50 */ '--- step 13',
    /* 51 */ 'Z2.runUnary',
    /* 52 */ 'Z1.runUnary',
    /* 53 */ 'Z1.unaryCallback',
    /* 54 */ 'Z2.unaryCallback',
    /* 55 */ '--- step 14',
    /* 56 */ 'Z4.runUnary',
    /* 57 */ 'Z2.runUnary',
    /* 58 */ 'Z1.runUnary',
    /* 59 */ 'Z1.unaryCallback',
    /* 60 */ 'Z2.unaryCallback',
    /* 61 */ 'Z4.unaryCallback',
    /* 62 */ '--- step 15',
    /* 63 */ 'Z2.runUnary',
    /* 64 */ 'Z1.runUnary',
    /* 65 */ 'Z1.unaryCallback',
    /* 66 */ 'Z2.unaryCallback',
    /* 67 */ '--- step 16',
    /* 68 */ 'Z1.runUnary',
    /* 69 */ 'Z1.unaryCallback',
    /* 70 */ '--- step 17',
    /* 71 */ '--- end',
  ];
  Expect.listEquals(expectedLog, log);
}
