// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Tests that SIGPIPE won't terminate websocket client dart app.

import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";
import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as p;

import '../../../tests/ffi/dylib_utils.dart';

class Isolate extends Opaque {}

abstract class FfiBindings {
  static final ffiTestFunctions = dlopenPlatformSpecific("ffi_test_functions");

  static final RestoreSIGPIPEHandler =
      ffiTestFunctions.lookupFunction<Void Function(), void Function()>(
          "RestoreSIGPIPEHandler");
  static final SleepOnAnyOS = ffiTestFunctions.lookupFunction<
      Void Function(IntPtr), void Function(int)>("SleepOnAnyOS");
}

Future<void> main() async {
  asyncStart();

  final server = await Process.start(Platform.executable, <String>[
    p.join(p.dirname(Platform.script.toFilePath()),
        "socket_sigpipe_test_server.dart")
  ]);
  final serverPort = Completer<int>();
  server.stdout
      .transform(utf8.decoder)
      .transform(LineSplitter())
      .listen((line) {
    print('server stdout: $line');
    if (!serverPort.isCompleted) {
      serverPort.complete(int.parse(line));
    }
  });
  server.stderr
      .transform(utf8.decoder)
      .transform(LineSplitter())
      .listen((data) {
    print('server stderr: $data');
  });

  FfiBindings.RestoreSIGPIPEHandler();
  final ws =
      await WebSocket.connect('ws://localhost:${await serverPort.future}');
  ws.listen((var data) {
    print('Got $data');
    // Sleep to prevent closed socket events coming through and being handled.
    // This way websocket stays open and writing into it should trigger SIGPIPE.
    // Unless of course we requested SIGPIPE not to be generated on broken socket
    // pipe. This is what this test is testing - that the SIGPIPE is not generated
    // on broken socket pipe.
    ws.add('foo');
    FfiBindings.SleepOnAnyOS(10 /*seconds*/); // give server time to exit
    ws.add('baz');
    ws.close();
  }, onDone: () {
    asyncEnd();
  }, onError: (e, st) {
    Expect.fail('Client websocket failed $e $st');
  });
}
