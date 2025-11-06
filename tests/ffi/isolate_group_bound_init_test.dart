// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Tests IsolateGroup.runSync - what works, what doesn't.
//
// VMOptions=--experimental-shared-data
// VMOptions=--experimental-shared-data --use-slow-path
// VMOptions=--experimental-shared-data --use-slow-path --stacktrace-every=100
// VMOptions=--experimental-shared-data --dwarf_stack_traces --no-retain_function_objects --no-retain_code_objects
// VMOptions=--experimental-shared-data --test_il_serialization
// VMOptions=--experimental-shared-data --profiler --profile_vm=true
// VMOptions=--experimental-shared-data --profiler --profile_vm=false

import 'dart:async';
import 'dart:concurrent';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:dart_internal/isolate_group.dart' show IsolateGroup;
import "package:expect/async_helper.dart";
import "package:expect/expect.dart";
import 'package:ffi/ffi.dart';

@pragma('vm:shared')
late final Mutex mutex;

@pragma('vm:shared')
late final String shared_late_final_string = () {
  return "${int.parse('123') + 42}";
}();

@pragma('vm:shared')
late final String shared_late_final_throw = () {
  throw "${int.parse('123') + 42}";
}();

@pragma('vm:shared')
late final String foo = () {
  return "${int.parse('123') + 42}";
}();

testInitStrings() async {
  const int nWorkers = 100;
  mutex = Mutex();
  final rp = ReceivePort();
  final rpExitAndErrors = ReceivePort()
    ..listen((e) {
      print('e: $e');
    });
  final completer = Completer();
  int counter = 0;
  rp.listen((data) {
    counter++;
    print('got $data, counter: $counter');
    Expect.equals("165", data);
    if (counter == nWorkers) {
      completer.complete(data);
    }
  });
  for (int i = 0; i < nWorkers; i++) {
    Isolate.spawn(
      (sendPort) {
        @pragma('vm:shared')
        final sp = sendPort;
        IsolateGroup.runSync(() {
          sp.send(shared_late_final_string);
        });
      },
      rp.sendPort,
      onExit: rpExitAndErrors.sendPort,
      onError: rpExitAndErrors.sendPort,
    );
    print("spawned isolate #$i");
  }
  Expect.equals("165", await completer.future);
  rpExitAndErrors.close();
  rp.close();
}

testInitThrows() async {
  const int nWorkers = 100;
  final rp = ReceivePort();
  int exitCounter = 0;
  final completer = Completer();
  ReceivePort rpExits = ReceivePort()
    ..listen((e) {
      exitCounter++;
      print('exitCounter: $exitCounter, exit: $e');
      if (exitCounter == nWorkers) {
        completer.complete(true);
      }
    });
  int errorCounter = 0;
  ReceivePort rpErrors = ReceivePort()
    ..listen((e) {
      errorCounter++;
      Expect.equals("165", e[0]);
      print('errorCounter: $errorCounter, error: $e');
    });
  for (int i = 0; i < nWorkers; i++) {
    Isolate.spawn(
      (sendPort) {
        @pragma('vm:shared')
        final sp = sendPort;
        IsolateGroup.runSync(() {
          try {
            sp.send(shared_late_final_throw);
          } catch (e) {
            Expect.equals("165", e);
            rethrow;
          }
        });
      },
      rp.sendPort,
      onExit: rpExits.sendPort,
      onError: rpErrors.sendPort,
    );
    print("spawned isolate #$i");
  }
  await completer.future;
  Expect.equals(nWorkers, errorCounter);
  rpErrors.close();
  rpExits.close();
  rp.close();
}

@pragma('vm:shared')
late final String foo_bar = () {
  return "${int.parse('123') + 42} $foo";
}();

testNestedInitCall() {
  Expect.equals("165 165", foo_bar);
}

main() async {
  asyncStart();
  await testInitStrings();
  await testInitThrows();
  testNestedInitCall();
  asyncEnd();
}
