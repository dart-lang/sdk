// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies retaining path in error message for spawnUri'ed worker attempt
// to send regular class instance.

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:expect/expect.dart';

import 'send_unsupported_objects_test.dart';

@pragma('vm:entry-point') // prevent obfuscation
class ConstFoo {
  const ConstFoo(this.name);
  final String name;
}

Future<void> main(args, message) async {
  if (message == null) {
    final receivePort = ReceivePort();
    final isolate = await Isolate.spawnUri(
        Platform.script, <String>['worker'], <SendPort>[receivePort.sendPort],
        errorsAreFatal: true);
    final result = await receivePort.first;
    Expect.equals('done', result);
    return;
  }

  Expect.equals('worker', args[0]);
  final SendPort sendPort = message[0] as SendPort;
  Expect.throws(() {
    sendPort.send(<dynamic>[
      <dynamic>[
        <dynamic>[const ConstFoo("42")],
      ],
    ]);
  }, (e) {
    print(e);
    Expect.isTrue(checkForRetainingPath(e, <String>['ConstFoo']));

    final msg = e.toString();
    Expect.equals(3, msg.split('\n').where((s) => s.contains('_List')).length);
    return true;
  });
  sendPort.send('done');
}
