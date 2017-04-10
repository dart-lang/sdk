// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override

import 'test_helper.dart';
import 'dart:async';
import 'dart:developer';
import 'dart:isolate' as I;
import 'dart:io';
import 'service_test_common.dart';
import 'package:observatory/service.dart';
import 'package:path/path.dart' as path;
import 'package:unittest/unittest.dart';

// Chop off the file name.
String baseDirectory = path.dirname(Platform.script.path) + '/';

Uri baseUri = Platform.script.replace(path: baseDirectory);
Uri spawnUri = baseUri.resolveUri(Uri.parse('complex_reload/v1/main.dart'));
Uri v2Uri = baseUri.resolveUri(Uri.parse('complex_reload/v2/main.dart'));
Uri v3Uri = baseUri.resolveUri(Uri.parse('complex_reload/v3/main.dart'));
Uri v2PackagesUri = baseUri.resolveUri(Uri.parse('complex_reload/v2/packages'));

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
  Instance result = await lib.evaluate('test()');
  expect(result.isString, isTrue);
  return result.valueAsString;
}

var tests = [
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

    // Find the slave isolate.
    Isolate slaveIsolate =
        vm.isolates.firstWhere((Isolate i) => i != mainIsolate);
    expect(slaveIsolate, isNotNull);

    // Invoke test in v1.
    String v1 = await invokeTest(slaveIsolate);
    expect(v1, 'apple');

    // Reload to v2.
    var response = await slaveIsolate.reloadSources(
      rootLibUri: v2Uri.toString(),
      packagesUri: v2PackagesUri.toString(),
    );
    print(response);
    expect(response['success'], isTrue);

    // Invoke test in v2.
    String v2 = await invokeTest(slaveIsolate);
    expect(v2, 'fooLib');

    // Reload to v3.
    response = await slaveIsolate.reloadSources(
      rootLibUri: v3Uri.toString(),
    );
    expect(response['success'], isTrue);

    // Invoke test in v3.
    String v3 = await invokeTest(slaveIsolate);
    expect(v3, 'cabbage');
  }
];

main(args) => runIsolateTests(args, tests, testeeConcurrent: testMain);
