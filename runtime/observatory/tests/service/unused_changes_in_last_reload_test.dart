// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
Uri v1Uri = baseUri.resolveUri(Uri.parse('unused_changes_in_last_reload/v1/main.dart'));
Uri v2Uri = baseUri.resolveUri(Uri.parse('unused_changes_in_last_reload/v2/main.dart'));

testMain() async {
  print(baseUri);
  debugger(); // Stop here.
  // Spawn the child isolate.
  I.Isolate isolate = await I.Isolate.spawnUri(v1Uri, [], null);
  print(isolate);
  debugger();
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

    // Find the child isolate.
    Isolate childIsolate =
        vm.isolates.firstWhere((Isolate i) => i != mainIsolate);
    expect(childIsolate, isNotNull);

    // Fetch unused.
    await childIsolate.invokeRpc("_getUnusedChangesInLastReload", {}).then((v) {
      print(v);
      throw "MissingError";
    }, onError: (e) {
      print(e);
    });

    // Reload to v2.
    var response = await childIsolate.reloadSources(
      rootLibUri: v2Uri.toString(),
    );
    print(response);
    expect(response['success'], isTrue);

    // Fetch unused.
    response = await childIsolate.invokeRpc("_getUnusedChangesInLastReload", {});
    print(response);
    var unused = response['unused'].map((ea) => ea.toString());
    expect(unused, unorderedEquals([
      'Class(C)',
      'Class(NewClass)',
      'Field(main.dart.uninitializedField)',
      'Field(main.dart.fieldLiteralInitializer)',
      'Field(main.dart.initializedField)',
      'Field(main.dart.neverReferencedField)',
      'ServiceFunction(function)',
      'ServiceFunction(main2)',
    ]));

    // Invoke next main.
    Library lib = childIsolate.rootLibrary;
    await lib.load();
    Instance result = await lib.evaluate('main2()');
    expect(result.valueAsString, equals('null'));

    // Fetch unused.
    response = await childIsolate.invokeRpc("_getUnusedChangesInLastReload", {});
    print(response);
    unused = response['unused'].map((ea) => ea.toString());
    expect(unused, unorderedEquals([
      'Field(main.dart.fieldLiteralInitializer)',
      'Field(main.dart.initializedField)',
      'Field(main.dart.neverReferencedField)',
    ]));

    // Reload to v2 again.
    response = await childIsolate.reloadSources(
      rootLibUri: v2Uri.toString(),
    );
    print(response);
    expect(response['success'], isTrue);

    // Fetch unused.
    response = await childIsolate.invokeRpc("_getUnusedChangesInLastReload", {});
    print(response);
    unused = response['unused'].map((ea) => ea.toString());
    expect(unused, unorderedEquals([]));
  }
];

main(args) => runIsolateTests(args, tests, testeeConcurrent: testMain);
