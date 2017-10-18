// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// OtherResources=process_detached_script.dart

// Process test program to test detached processes.

import 'dart:async';
import 'dart:io';

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

import "process_test_util.dart";

void test() {
  asyncStart();
  var script =
      Platform.script.resolve('process_detached_script.dart').toFilePath();
  var future = Process.start(Platform.executable, [script],
      mode: ProcessStartMode.DETACHED);
  future.then((process) {
    Expect.isNotNull(process.pid);
    Expect.isTrue(process.pid is int);
    Expect.isNull(process.exitCode);
    Expect.isNull(process.stderr);
    Expect.isNull(process.stdin);
    Expect.isNull(process.stdout);
    Expect.isTrue(process.kill());
  }).whenComplete(() {
    asyncEnd();
  });
}

void testWithStdio() {
  asyncStart();
  var script =
      Platform.script.resolve('process_detached_script.dart').toFilePath();
  var future = Process.start(Platform.executable, [script, 'echo'],
      mode: ProcessStartMode.DETACHED_WITH_STDIO);
  future.then((process) {
    Expect.isNotNull(process.pid);
    Expect.isTrue(process.pid is int);
    Expect.isNull(process.exitCode);
    var message = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
    process.stdin.add(message);
    process.stdin.flush().then((_) => process.stdin.close());
    var f1 = process.stdout.fold([], (p, e) => p..addAll(e));
    var f2 = process.stderr.fold([], (p, e) => p..addAll(e));
    Future.wait([f1, f2]).then((values) {
      Expect.listEquals(values[0], message);
      Expect.listEquals(values[1], message);
    }).whenComplete(() {
      Expect.isTrue(process.kill());
    });
  }).whenComplete(() {
    asyncEnd();
  });
}

void testFailure() {
  asyncStart();
  Directory.systemTemp.createTemp('dart_detached_process').then((temp) {
    var future =
        Process.start(temp.path, ['a', 'b'], mode: ProcessStartMode.DETACHED);
    future.then((process) {
      Expect.fail('Starting process from invalid executable succeeded');
    }, onError: (e) {
      Expect.isTrue(e is ProcessException);
    }).whenComplete(() {
      temp.deleteSync();
      asyncEnd();
    });
  });
}

main() {
  test();
  testWithStdio();
  testFailure();
}
