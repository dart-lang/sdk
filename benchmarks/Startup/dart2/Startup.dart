// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.9

import 'dart:convert';
import 'dart:io';

import 'package:compiler/src/dart2js.dart' as dart2js;

Future<void> main(List<String> args) async {
  if (args.contains('--child')) {
    return;
  }

  // Include dart2js and prevent tree-shaking to make this program have a
  // non-trival snapshot size.
  if (args.contains('--train')) {
    args.remove('--train');
    return dart2js.main(args);
  }

  var tempDir;
  var events;
  try {
    tempDir = await Directory.systemTemp.createTemp();
    final timelinePath =
        tempDir.uri.resolve('Startup-timeline.json').toFilePath();
    final p = await Process.run(Platform.executable, [
      ...Platform.executableArguments,
      '--timeline_recorder=file:$timelinePath',
      '--timeline_streams=VM,Isolate,Embedder',
      Platform.script.toFilePath(),
      '--child'
    ]);
    if (p.exitCode != 0) {
      print(p.stdout);
      print(p.stderr);
      throw 'Child process failed: ${p.exitCode}';
    }

    events = jsonDecode(await File(timelinePath).readAsString());
  } finally {
    await tempDir.delete(recursive: true);
  }

  var mainIsolateId;
  for (final event in events) {
    if (event['name'] == 'InitializeIsolate' &&
        event['args']['isolateName'] == 'main') {
      mainIsolateId = event['args']['isolateId'];
    }
  }
  if (mainIsolateId == null) {
    throw 'Could not determine main isolate';
  }

  void report(String name, String isolateId) {
    var filtered = events.where((event) => event['name'] == name);
    if (isolateId != null) {
      filtered =
          filtered.where((event) => event['args']['isolateId'] == isolateId);
    }
    var micros;
    final durations = filtered.where((event) => event['ph'] == 'X');
    final begins = filtered.where((event) => event['ph'] == 'B');
    final ends = filtered.where((event) => event['ph'] == 'E');
    if (durations.length == 1 && begins.length == 0 && ends.length == 0) {
      micros = durations.single['dur'];
    } else if (durations.length == 0 &&
        begins.length == 1 &&
        ends.length == 1) {
      micros = ends.single['ts'] - begins.single['ts'];
    } else {
      print(durations.toList());
      print(begins.toList());
      print(ends.toList());
      throw '$name is missing or ambiguous';
    }
    print('Startup.$name(RunTime): $micros us.');
  }

  report('CreateIsolateGroupAndSetupHelper', null);
  report('InitializeIsolate', mainIsolateId);
  report('ReadProgramSnapshot', mainIsolateId);
}
