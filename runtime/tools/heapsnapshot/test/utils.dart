// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io' hide BytesBuilder;
import 'dart:typed_data' show BytesBuilder;

import 'package:heapsnapshot/src/load.dart';
import 'package:vm_service/vm_service_io.dart';

class Testee {
  final String testFile;

  late final Process _process;
  final Completer<String> _serviceUri = Completer<String>();

  Testee(this.testFile);

  Future<String> start(List<String> args) async {
    var script = Platform.script.toFilePath();
    if (RegExp('dart_([0-9]+).dill').hasMatch(script)) {
      // We run via `dart test` and the `package:test` has wrapped the `main()`
      // function. We don't want to invoke the wrapper as subprocess, but rather
      // the actual file.
      script = testFile;
    }

    final processArgs = [
      ...Platform.executableArguments,
      '--disable-dart-dev',
      '--no-dds',
      '--disable-service-auth-codes',
      '--enable-vm-service:0',
      '--pause-isolates-on-exit',
      script,
      ...args,
    ];
    _process = await Process.start(Platform.executable, processArgs);
    final childReadyCompleter = Completer();
    _process.stdout
        .transform(Utf8Decoder())
        .transform(const LineSplitter())
        .listen((line) {
      print('child-stdout: $line');
      final urlStart = line.indexOf('http://');
      if (line.contains('http')) {
        _serviceUri.complete(line.substring(urlStart).trim());
        return;
      }
      if (line.contains('Child ready')) {
        childReadyCompleter.complete();
        return;
      }
    });
    _process.stderr
        .transform(Utf8Decoder())
        .transform(const LineSplitter())
        .listen((line) {
      print('child-stderr: $line');
    });
    final uri = await _serviceUri.future;
    await childReadyCompleter.future;
    return uri;
  }

  Future getHeapsnapshotAndWriteTo(String filename) async {
    final chunks = await loadFromUri(Uri.parse(await _serviceUri.future));
    final bytesBuilder = BytesBuilder();
    for (final bd in chunks) {
      bytesBuilder
          .add(bd.buffer.asUint8List(bd.offsetInBytes, bd.lengthInBytes));
    }
    final bytes = bytesBuilder.toBytes();

    File(filename).writeAsBytesSync(bytes);
  }

  Future close() async {
    final wsUri =
        Uri.parse(await _serviceUri.future).replace(scheme: 'ws', path: '/ws');
    final service = await vmServiceConnectUri(wsUri.toString());

    final vm = await service.getVM();
    final vmIsolates = vm.isolates!;
    if (vmIsolates.isEmpty) {
      throw 'Could not find first isolate (expected it to be running already)';
    }
    final isolateRef = vmIsolates.first;

    // The isolate is hanging on --pause-on-exit.
    await service.resume(isolateRef.id!);
    final exitCode = await _process.exitCode;
    print('child-exitcode: $exitCode');
    if (exitCode != 0) {
      throw 'Child process terminated unsuccessfully';
    }
  }
}
