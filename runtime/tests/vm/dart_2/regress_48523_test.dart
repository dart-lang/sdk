// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:async';
import 'dart:convert';

import 'package:expect/expect.dart';

import 'isolates/reload_utils.dart';

main() async {
  if (!currentVmSupportsReload) return;

  await withTempDir((String tempDir) async {
    final dills = await generateDills(tempDir, dartTestFile());
    final reloader = await launchOn(dills[0]);

    await reloader.waitUntilStdoutContains('[testee] helper isolate is ready');

    final helperIsolateId = await reloader.getIsolateId('helper-isolate');

    // Set breakpoint.
    final debugEvents = StreamIterator(reloader.getDebugStream());
    await reloader.addBreakpoint(7, isolateId: helperIsolateId);

    // Reload 1
    final reloadResult1 = await reloader.reload(dills[1]);
    Expect.equals('ReloadReport', reloadResult1['type']);
    Expect.equals(true, reloadResult1['success']);

    // Now we should get a debug resolved event.
    if (!await debugEvents.moveNext()) throw 'failed';
    final event = debugEvents.current;
    print(JsonEncoder.withIndent('  ').convert(event));
    if (event['kind'] != 'BreakpointResolved') throw 'failed';
    print('Got breakpoint resolved event ($event)');

    // Continue testee, which will run (and therefore compile) old closure
    // without a script.
    await reloader.waitUntilStdoutContains('[testee] running old closure');
    await reloader.waitUntilStdoutContains('[testee] done');

    // Reload 1
    print('reloading');
    final reloadResult2 = await reloader.reload(dills[2]);
    Expect.equals('ReloadReport', reloadResult2['type']);
    Expect.equals(true, reloadResult2['success']);
    print('reload 2 done');

    await reloader.waitUntilStdoutContains('[testee] shutting down');

    final int exitCode = await reloader.close();
    Expect.equals(0, exitCode);
  });
}

String dartTestFile() => '''
import 'dart:async';
import 'dart:isolate';
dynamic getAnonymousClosure() {
  return () {                               // @include-in-reload-0
    print('[testee] running old closure');  // @include-in-reload-0
    if (int.parse('1') == 0) {              // @include-in-reload-0
      throw 'should not execute';           // @include-in-reload-0
    }                                       // @include-in-reload-0
  };                                        // @include-in-reload-0
  return null;                              // @include-in-reload-1
}

var escapedOldClosure;

Future main() async {
  escapedOldClosure = getAnonymousClosure();

  Isolate.spawn((_) {
    print('[testee] helper isolate is ready');
    ReceivePort();
  }, null, debugName: 'helper-isolate');

  // Debugger should now set breakpoint on
  // myOldClosure.

  // Wait until we got reloaded.
  while (await waitUntilReloadDone());

  // Now run the old closure (which has breakpoint in it).
  escapedOldClosure();

  print('[testee] done');

  // Wait until we got reloaded.
  while (await waitUntilReloadDone2());

  print('[testee] shutting down');
}

final timeout = const Duration(milliseconds: 200);

@pragma('vm:never-inline')
Future<bool> waitUntilReloadDone() async {
  await Future.delayed(timeout);   // @include-in-reload-0
  return true;                     // @include-in-reload-0
  return false;                    // @include-in-reload-1
  throw 'unexpected';              // @include-in-reload-2
}

@pragma('vm:never-inline')
Future<bool> waitUntilReloadDone2() async {
  throw 'unexpected';              // @include-in-reload-0
  await Future.delayed(timeout);   // @include-in-reload-1
  return true;                     // @include-in-reload-1
  return false;                    // @include-in-reload-2
}
''';
