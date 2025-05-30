// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
import 'dart:isolate';

import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';

@pragma('vm:isolate-unsendable')
class Locked {}

class ExtendsLocked extends Locked {}

class ImplementsLocked implements Locked {}

main() async {
  asyncStart();

  final rpExit = ReceivePort();
  final rpError = RawReceivePort((e) {
    Expect.fail('Spawned isolated failed with $e');
  });

  final rp = RawReceivePort((e) {
    Expect.fail('Received unexpected $e, no objects should have arrived');
  });
  await Isolate.spawn(
    (sendPort) {
      for (final pairFunctionName in [
        [Locked.new, "Locked"],
        [ExtendsLocked.new, "ExtendsLocked"],
        [ImplementsLocked.new, "ImplementsLocked"],
      ]) {
        Expect.throws(
          () {
            Isolate.exit(sendPort, (pairFunctionName[0] as Function)());
          },
          (e) {
            return e is ArgumentError &&
                e.toString().contains(
                  RegExp("unsendable object .+${pairFunctionName[1]}"),
                );
          },
        );
      }
    },
    rp.sendPort,
    onError: rpError.sendPort,
    onExit: rpExit.sendPort,
  );
  await rpExit.first;
  rpError.close();
  rp.close();
  asyncEnd();
}
