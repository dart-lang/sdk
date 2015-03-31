// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import '../descriptor.dart' as d;
import '../test_pub.dart';

const _catchableSignals = const [
  ProcessSignal.SIGHUP,
  ProcessSignal.SIGINT,
  ProcessSignal.SIGTERM,
  ProcessSignal.SIGUSR1,
  ProcessSignal.SIGUSR2,
  ProcessSignal.SIGWINCH,
];

const SCRIPT = """
import 'dart:io';

main() {
  ProcessSignal.SIGHUP.watch().listen(print);
  ProcessSignal.SIGINT.watch().listen(print);
  ProcessSignal.SIGTERM.watch().listen(print);
  ProcessSignal.SIGUSR1.watch().listen(print);
  ProcessSignal.SIGUSR2.watch().listen(print);
  ProcessSignal.SIGWINCH.watch().listen(print);

  print("ready");
}
""";

main() {
  initConfig();
  integration('forwards signals to the inner script', () {
    d.dir(appPath, [
      d.appPubspec(),
      d.dir("bin", [
        d.file("script.dart", SCRIPT)
      ])
    ]).create();

    var pub = pubRun(args: ["script"]);

    pub.stdout.expect("ready");
    for (var signal in _catchableSignals) {
      pub.signal(signal);
      pub.stdout.expect(signal.toString());
    }

    pub.kill();
  });
}
