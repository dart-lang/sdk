// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override

import 'dart:async';
import 'dart:convert';
import 'package:observatory/models.dart' as M;
import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'service_test_common.dart';
import 'test_helper.dart';

var tests = [
  (VM vm) async {
    // Create a new fs.
    var fsName = 'scratch';
    var result = await vm.invokeRpcNoUpgrade('_createDevFS', {
      'fsName': fsName,
    });
    expect(result['type'], equals('FileSystem'));
    expect(result['name'], equals('scratch'));
    expect(result['uri'], new isInstanceOf<String>());
    var fsUri = result['uri'];

    // Spawn a script with a bad uri and make sure that the error is
    // delivered asynchronously.
    Completer completer = new Completer();
    var sub;
    sub = await vm.listenEventStream(VM.kIsolateStream, (ServiceEvent event) {
      if (event.kind == ServiceEvent.kIsolateSpawn) {
        expect(event.spawnToken, equals('someSpawnToken'));
        expect(event.spawnError,
            startsWith('IsolateSpawnException: Unable to spawn isolate: '));
        expect(event.isolate, isNull);
        completer.complete();
        sub.cancel();
      }
    });

    result = await vm.invokeRpcNoUpgrade('_spawnUri', {
      'token': 'someSpawnToken',
      'uri': '${fsUri}doesnotexist.dart',
    });
    expect(result['type'], equals('Success'));
    await completer.future;

    // Delete the fs.
    result = await vm.invokeRpcNoUpgrade('_deleteDevFS', {
      'fsName': fsName,
    });
    expect(result['type'], equals('Success'));
  },
  (VM vm) async {
    // Create a new fs.
    var fsName = 'scratch';
    var result = await vm.invokeRpcNoUpgrade('_createDevFS', {
      'fsName': fsName,
    });
    expect(result['type'], equals('FileSystem'));
    expect(result['name'], equals('scratch'));
    expect(result['uri'], new isInstanceOf<String>());
    var fsUri = result['uri'];

    var filePaths = [
      'devfs_file0.dart',
      'devfs_file1.dart',
      'devfs_file2.dart'
    ];
    var scripts = [
      '''
import 'dart:developer';
proofOfLife() => 'I live!';
main() {
  print('HELLO WORLD 1');
  debugger();
}
''',
      '''
import 'dart:developer';
var globalArgs;
proofOfLife() => 'I live, \${globalArgs}!';
main(args) {
  globalArgs = args;
  print('HELLO WORLD 2');
  debugger();
}
''',
      '''
import 'dart:developer';
var globalArgs;
var globalMsg;
proofOfLife() => 'I live, \${globalArgs}, \${globalMsg}!';
main(args, msg) {
  globalArgs = args;
  globalMsg = msg;
  print('HELLO WORLD 3');
  debugger();
}
''',
    ];

    // Write three scripts to the fs.
    for (int i = 0; i < 3; i++) {
      var fileContents = BASE64.encode(UTF8.encode(scripts[i]));
      result = await vm.invokeRpcNoUpgrade('_writeDevFSFile', {
        'fsName': fsName,
        'path': filePaths[i],
        'fileContents': fileContents
      });
      expect(result['type'], equals('Success'));
    }

    // Spawn the script with no arguments or message and make sure
    // that we are notified.
    Completer completer = new Completer();
    var sub;
    sub = await vm.listenEventStream(VM.kIsolateStream, (ServiceEvent event) {
      if (event.kind == ServiceEvent.kIsolateSpawn) {
        expect(event.spawnToken, equals('mySpawnToken0'));
        expect(event.isolate, isNotNull);
        expect(event.isolate.name, equals('devfs_file0.dart:main()'));
        completer.complete(event.isolate);
        sub.cancel();
      }
    });
    result = await vm.invokeRpcNoUpgrade('_spawnUri', {
      'token': 'mySpawnToken0',
      'uri': '${fsUri}${filePaths[0]}',
    });
    expect(result['type'], equals('Success'));
    var spawnedIsolate = await completer.future;

    // Wait for the spawned isolate to hit a breakpoint.
    await spawnedIsolate.load();
    await hasStoppedAtBreakpoint(spawnedIsolate);

    // Make sure that we are running code from the spawned isolate.
    result = await spawnedIsolate.rootLibrary.evaluate('proofOfLife()');
    expect(result.type, equals('Instance'));
    expect(result.kind, equals(M.InstanceKind.string));
    expect(result.valueAsString, equals('I live!'));

    // Spawn the script with arguments.
    completer = new Completer();
    sub = await vm.listenEventStream(VM.kIsolateStream, (ServiceEvent event) {
      if (event.kind == ServiceEvent.kIsolateSpawn) {
        expect(event.spawnToken, equals('mySpawnToken1'));
        expect(event.isolate, isNotNull);
        expect(event.isolate.name, equals('devfs_file1.dart:main()'));
        completer.complete(event.isolate);
        sub.cancel();
      }
    });
    result = await vm.invokeRpcNoUpgrade('_spawnUri', {
      'token': 'mySpawnToken1',
      'uri': '${fsUri}${filePaths[1]}',
      'args': ['one', 'two', 'three']
    });
    expect(result['type'], equals('Success'));
    spawnedIsolate = await completer.future;

    // Wait for the spawned isolate to hit a breakpoint.
    await spawnedIsolate.load();
    await hasStoppedAtBreakpoint(spawnedIsolate);

    // Make sure that we are running code from the spawned isolate.
    result = await spawnedIsolate.rootLibrary.evaluate('proofOfLife()');
    expect(result.type, equals('Instance'));
    expect(result.kind, equals(M.InstanceKind.string));
    expect(result.valueAsString, equals('I live, [one, two, three]!'));

    // Spawn the script with arguments and message
    completer = new Completer();
    sub = await vm.listenEventStream(VM.kIsolateStream, (ServiceEvent event) {
      if (event.kind == ServiceEvent.kIsolateSpawn) {
        expect(event.spawnToken, equals('mySpawnToken2'));
        expect(event.isolate, isNotNull);
        expect(event.isolate.name, equals('devfs_file2.dart:main()'));
        completer.complete(event.isolate);
        sub.cancel();
      }
    });
    result = await vm.invokeRpcNoUpgrade('_spawnUri', {
      'token': 'mySpawnToken2',
      'uri': '${fsUri}${filePaths[2]}',
      'args': ['A', 'B', 'C'],
      'message': 'test'
    });
    expect(result['type'], equals('Success'));
    spawnedIsolate = await completer.future;

    // Wait for the spawned isolate to hit a breakpoint.
    await spawnedIsolate.load();
    await hasStoppedAtBreakpoint(spawnedIsolate);

    // Make sure that we are running code from the spawned isolate.
    result = await spawnedIsolate.rootLibrary.evaluate('proofOfLife()');
    expect(result.type, equals('Instance'));
    expect(result.kind, equals(M.InstanceKind.string));
    expect(result.valueAsString, equals('I live, [A, B, C], test!'));

    // Delete the fs.
    result = await vm.invokeRpcNoUpgrade('_deleteDevFS', {
      'fsName': fsName,
    });
    expect(result['type'], equals('Success'));
  },
];

main(args) async => runVMTests(args, tests);
