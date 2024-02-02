// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:isolate';
import 'dart:io';

import 'package:expect/expect.dart';
import 'package:path/path.dart' as path;

import '../use_flag_test_helper.dart';

void main() async {
  var result = 1;
  final d = Directory.systemTemp.createTempSync('aot_tmp');
  try {
    // This test is checking if we get an error when a spawnURI is
    // done using an AOT snapshot in a JIT VM and hence is skipped
    // for AOT runs.
    if (isAOTRuntime) return;

    if (Platform.isAndroid || Platform.isIOS) {
      return; // SDK tree not available on the test device.
    }
    if (Platform.version.contains('ia32')) {
      return; // AOT is not available for ia32
    }

    // These are the tools we need to be available to run on a given platform:
    if (!File(platformDill).existsSync()) {
      throw "Cannot run test as $platformDill does not exist";
    }

    // Generate an AOT snapshot.
    final spawnTest =
        path.join(sdkDir, 'runtime/tests/vm/dart/isolates/func.dart');
    Expect.isTrue(File(spawnTest).existsSync(), "Can't locate $spawnTest");
    final kernelOutput = File.fromUri(d.uri.resolve('func.dill')).path;
    final aotOutput = File.fromUri(d.uri.resolve('func.aot')).path;

    // Compile source to kernel.
    var result = Process.runSync(genKernel, <String>[
      '--aot',
      '--platform=$platformDill',
      '-o',
      kernelOutput,
      spawnTest,
    ]);
    Expect.equals(result.exitCode, 0);
    result = Process.runSync(genSnapshot, <String>[
      '--snapshot_kind=app-aot-elf',
      '--elf=$aotOutput',
      kernelOutput,
    ]);
    Expect.equals(result.exitCode, 0);

    // Now try spawning an isolate using that AOT file that was just generated.
    final isolate = await Isolate.spawnUri(Uri.parse(aotOutput), [], null);
  } catch (e) {
    Expect.contains("func.aot", e.toString());
    result = 0;
  } finally {
    d.deleteSync(recursive: true);
  }
  Expect.equals(result, 0);
}
