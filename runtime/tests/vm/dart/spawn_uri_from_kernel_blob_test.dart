// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// OtherResources=spawn_uri_from_kernel_blob_script.dart

// Test for Isolate.createUriForKernelBlob and subsequent Isolate.spawnUri.

import 'dart:io' show Platform;
import 'dart:isolate' show Isolate, ReceivePort;

import "package:expect/expect.dart";
import 'package:front_end/src/api_unstable/vm.dart'
    show CompilerOptions, DiagnosticMessage, kernelForProgram, NnbdMode;
import 'package:kernel/kernel.dart';
import 'package:kernel/target/targets.dart';
import 'package:vm/target/vm.dart' show VmTarget;

import 'snapshot_test_helper.dart';

main() async {
  final sourceUri =
      Platform.script.resolve('spawn_uri_from_kernel_blob_script.dart');
  final options = new CompilerOptions()
    ..target = VmTarget(TargetFlags())
    ..additionalDills = <Uri>[Uri.file(platformDill)]
    ..environmentDefines = {}
    ..nnbdMode = hasSoundNullSafety ? NnbdMode.Strong : NnbdMode.Weak
    ..onDiagnostic = (DiagnosticMessage message) {
      Expect.fail(
          "Compilation error: ${message.plainTextFormatted.join('\n')}");
    };
  final Component component =
      (await kernelForProgram(sourceUri, options))!.component!;
  final kernelBlob = writeComponentToBytes(component);

  final kernelBlobUri =
      (Isolate.current as dynamic).createUriForKernelBlob(kernelBlob);

  print('URI: $kernelBlobUri');

  for (int i = 0; i < 2; ++i) {
    final receivePort = ReceivePort();
    receivePort.listen((message) {
      Expect.equals(message, 'Hello');
      print('ok');
      receivePort.close();
    });

    await Isolate.spawnUri(kernelBlobUri, ['Hello'], receivePort.sendPort);
  }

  (Isolate.current as dynamic).unregisterKernelBlobUri(kernelBlobUri);

  try {
    await Isolate.spawnUri(kernelBlobUri, ['Hello'], null);
    Expect.fail(
        "Isolate.spawnUri didn't complete with error after unregisterKernelBlobUri");
  } catch (e) {
    print('Got exception: $e');
  }
}
