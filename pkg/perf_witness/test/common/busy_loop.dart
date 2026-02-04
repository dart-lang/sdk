// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:isolate';

import 'package:args/args.dart';
import 'package:perf_witness/server.dart';
import 'package:perf_witness/src/async_span.dart';
import 'package:perf_witness/src/common.dart';

final parser = ArgParser()
  ..addOption('tag', abbr: 't', help: 'Tag for the process')
  ..addFlag(
    'start-in-background',
    help: 'Start PerfWitnessServer server in background',
  )
  ..addFlag('start-isolate', abbr: 'i', help: 'Start test isolate');

bool shouldStop = false;

Future<void> busyLoop({required String name}) async {
  print('[$name] BUSY LOOP READY');
  while (!shouldStop) {
    await AsyncSpan.run('sleep', () async {
      print(
        '[$name] AsyncSpan.create is nop: ${identical(Zone.current, Zone.root)}',
      );
      await Future.delayed(const Duration(milliseconds: 500));
    });
  }
  print('done');
}

void main(List<String> args) async {
  print('PID: $pid');

  // On Windows there is no easy way to send Ctrl-C (SIGINT) to the process
  // so we use a keypress instead.
  final shouldStopFuture = waitForUserToQuit(
    waitForQKeyPress: Platform.isWindows,
  );

  shouldStopFuture.then((_) {
    shouldStop = true;
  });

  final parsedArgs = parser.parse(args);
  final tag = parsedArgs['tag'] as String?;
  await PerfWitnessServer.start(
    tag: tag,
    inBackground: parsedArgs['start-in-background'],
  );
  Timeline.instantSync('ImportantStartupEvent');
  if (parsedArgs.flag('start-isolate')) {
    Isolate.run(() async {
      await PerfWitnessServer.start(tag: tag);
      await busyLoop(name: 'child-isolate');
    }).onError((e, s) {
      print('Isolate error: $e');
      print(s);
      exit(1);
    });
  }
  await busyLoop(name: 'main');
  await PerfWitnessServer.shutdown();
  exit(0);
}
