// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Verifies that many isolate workers can use one RegExp.

import 'dart:isolate';

import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';

worker(List<dynamic> args) {
  final re = args[0] as RegExp;
  final i = args[1] as int;
  print('worker $i');
  final sendPort = args[2] as SendPort;
  final sw = Stopwatch()..start();
  while (sw.elapsedMilliseconds < 2000) {
    final match = re.firstMatch('h' * i * 1000 + ' a b c ');
    Expect.isNotNull(match);
    Expect.equals(2, match!.groupCount);
    Expect.equals('a b c ', match.group(0));
    Expect.equals('a b c ', match.group(1));
  }
  sendPort.send(true);
}

main() {
  asyncStart();

  int nWorkers = 5;
  final r = RegExp(r'(?<=\W|\b|^)(a.? b c.?) ?(\(.*\))?$');
  final rps = List<ReceivePort>.generate(nWorkers, (_) => ReceivePort());

  for (int i = 0; i < nWorkers; i++) {
    Isolate.spawn(worker, <dynamic>[r, i, rps[i].sendPort]);
  }

  Future.wait(List<Future<dynamic>>.generate(nWorkers, (i) => rps[i].first))
      .whenComplete(() {
    rps.forEach((rp) => rp.close());
    asyncEnd();
  });
}
