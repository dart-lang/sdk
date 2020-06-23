// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// OtherResources=simple_reload/v1/main.dart simple_reload/v2/main.dart

import 'test_helper.dart';
import 'dart:async';
import 'dart:developer';
import 'dart:isolate' as I;
import 'dart:io';
import 'service_test_common.dart';
import 'package:observatory/service.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

// Chop off the file name.
String baseDirectory = path.dirname(Platform.script.path) + '/';

Uri baseUri = Platform.script.replace(path: baseDirectory);
Uri spawnUri = baseUri.resolveUri(Uri.parse('simple_reload/v1/main.dart'));
Uri v2Uri = baseUri.resolveUri(Uri.parse('simple_reload/v2/main.dart'));

testMain() async {
  print(baseUri);
  debugger(); // Stop here.
  // Spawn the child isolate.
  I.Isolate isolate = await I.Isolate.spawnUri(spawnUri, [], null);
  print(isolate);
  debugger();
}

Future<String> invokeTest(Isolate isolate) async {
  await isolate.reload();
  Library lib = isolate.rootLibrary;
  await lib.load();
  Instance result = await lib.evaluate('test()') as Instance;
  expect(result.isString, isTrue);
  return result.valueAsString as String;
}

var tests = <IsolateTest>[
  // Stopped at 'debugger' statement.
  hasStoppedAtBreakpoint,
  // Resume the isolate into the while loop.
  resumeIsolate,
  // Stop at 'debugger' statement.
  hasStoppedAtBreakpoint,
  (Isolate mainIsolate) async {
    // Grab the VM.
    VM vm = mainIsolate.vm;
    await vm.reloadIsolates();
    expect(vm.isolates.length, 2);

    // Find the spawned isolate.
    Isolate spawnedIsolate =
        vm.isolates.firstWhere((Isolate i) => i != mainIsolate);
    expect(spawnedIsolate, isNotNull);

    // Invoke test in v1.
    String v1 = await invokeTest(spawnedIsolate);
    expect(v1, 'apple');

    // Reload to v2.
    var response = await spawnedIsolate.reloadSources(
      rootLibUri: v2Uri.toString(),
    );
    // Observe that it succeed.
    expect(response['success'], isTrue);

    String v2 = await invokeTest(spawnedIsolate);
    expect(v2, 'orange');
  }
];

main(args) => runIsolateTests(args, tests, testeeConcurrent: testMain);
