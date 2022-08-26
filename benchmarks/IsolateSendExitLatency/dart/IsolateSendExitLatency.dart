// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This test ensures that there are no long pauses when sending large objects
// via exit/send.

import 'dart:async';
import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:isolate';

import 'latency.dart';

main() async {
  final statsFuture =
      measureEventLoopLatency(const Duration(milliseconds: 1), 4000, work: () {
    // Every 1 ms we allocate some objects which may trigger GC some time.
    for (int i = 0; i < 32; i++) {
      List.filled(32 * 1024 ~/ 8, null);
    }
  });

  final result = await compute(() {
    final l = <dynamic>[];
    for (int i = 0; i < 10 * 1000 * 1000; ++i) {
      l.add(Object());
    }
    return l;
  });
  if (result.length != 10 * 1000 * 1000) throw 'failed';

  final stats = await statsFuture;
  stats.report('IsolateSendExitLatency');
}

Future<T> compute<T>(T Function() fun) {
  final rp = ReceivePort();
  final sp = rp.sendPort;
  Isolate.spawn((_) {
    final value = fun();
    Isolate.exit(sp, value);
  }, null);
  return rp.first.then((t) => t as T);
}
