// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//

// @dart = 2.9
import 'dart:isolate';

import 'package:expect/expect.dart';

f(List args) {
  final sendPort = args[0] as SendPort;
  final re = args[1] as RegExp;
  Expect.stringEquals("RegExp: pattern=abc flags=", re.toString());
  sendPort.send(true);
}

main() async {
  final rpError = RawReceivePort((e) {
    Expect.fail('Spawned isolated failed with $e');
  });
  {
    // Test sending of initialized RegExp
    final rp = ReceivePort();
    final re = RegExp('abc');
    print(re.hasMatch('kukabcdef'));
    await Isolate.spawn(f, <dynamic>[rp.sendPort, re],
        onError: rpError.sendPort);
    Expect.isTrue(await rp.first);
  }
  {
    // Test send of uninitialized RegExp(num_groups is null)
    final rp = ReceivePort();
    final re = RegExp('abc');
    await Isolate.spawn(f, <dynamic>[rp.sendPort, re],
        onError: rpError.sendPort);
    Expect.isTrue(await rp.first);
  }
  rpError.close();
}
