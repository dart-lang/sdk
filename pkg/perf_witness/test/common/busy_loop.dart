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

import 'simple_hot_loop.dart' deferred as simple_hot_loop;

final parser = ArgParser()
  ..addOption('tag', abbr: 't', help: 'Tag for the process')
  ..addFlag(
    'start-in-background',
    help: 'Start PerfWitnessServer server in background',
  )
  ..addFlag('start-isolate', abbr: 'i', help: 'Start test isolate')
  ..addFlag('no-shutdown', help: 'Do not shutdown PerfWitnessServer')
  ..addOption('spawn-uri', help: 'Spawn another isolate using spawnUri')
  ..addFlag('use-deferred', help: 'Use deferred library');

bool shouldStop = false;

Future<int> busyLoop({required String name, bool useDeferred = false}) async {
  if (useDeferred) {
    await simple_hot_loop.loadLibrary();
  }

  print('[$name] BUSY LOOP READY');
  var sum = 0;
  while (!shouldStop) {
    await AsyncSpan.run('sleep', () async {
      print(
        '[$name] AsyncSpan.create is nop: ${identical(Zone.current, Zone.root)}',
      );
      final sw = Stopwatch()..start();
      while (sw.elapsedMilliseconds < 250) {
        final l = <int>[];
        for (var i = 0; i < 10000; i++) {
          l.add(i * i);
        }
        sum += l[50];
      }
      if (useDeferred) {
        simple_hot_loop.hotLoop(duration: Duration(milliseconds: 100));
      }

      if (sw.elapsedMilliseconds < 500) {
        await Future.delayed(
          Duration(milliseconds: 500 - sw.elapsedMilliseconds),
        );
      }
    });
  }
  print('done');
  return sum;
}

void main(List<String> args) async {
  print('PID: $pid');
  final parsedArgs = parser.parse(args);

  // On Windows there is no easy way to send Ctrl-C (SIGINT) to the process
  // so we use a keypress instead.
  final shouldStopFuture = waitForUserToQuit(
    waitForQKeyPress: Platform.isWindows,
  );

  shouldStopFuture.then((_) {
    shouldStop = true;
  });

  final spawnUri = parsedArgs['spawn-uri'] as String?;
  Isolate? childIsolate;
  if (spawnUri != null) {
    childIsolate = await Isolate.spawnUri(Uri.parse(spawnUri), [], null);
  }

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
  await busyLoop(name: 'main', useDeferred: parsedArgs.flag('use-deferred'));
  if (parsedArgs.flag('no-shutdown')) {
    throw 'Abrupt exit without shutdown';
  }
  if (childIsolate != null) {
    childIsolate.kill(priority: Isolate.immediate);
  }
  await PerfWitnessServer.shutdown();
  exit(0);
}
