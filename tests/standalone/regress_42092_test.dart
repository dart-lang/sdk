// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:expect/expect.dart';

Future<void> main() async {
  final process = await Process.start(
    Platform.resolvedExecutable,
    [
      Platform.script.resolve('regress_42092_script.dart').toString(),
    ],
  );
  late StreamSubscription sub;
  int count = 0;
  sub = process.stdout.transform(Utf8Decoder()).listen((event) {
    print(event);
    if (event.contains('child: Got a SIGINT')) {
      ++count;
      if (count == 3) {
        sub.cancel();
      }
    }
    process.kill(ProcessSignal.sigint);
  });

  await process.exitCode;
}
