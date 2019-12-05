// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test ensures that certain core libraries are "empty" in product mode (thereby
// ensuring the right conditional pragma annotations were used).

import "dart:async";
import "dart:io";

import 'package:path/path.dart' as path;
import 'package:kernel/kernel.dart';
import 'package:expect/expect.dart';

import 'use_bare_instructions_flag_test.dart' show run, withTempDir;

const platformFilename = 'vm_platform_strong.dill';

Future main(List<String> args) async {
  final buildDir = path.dirname(Platform.resolvedExecutable);

  if (!buildDir.contains('Product')) {
    print('Skipping test due to running in non-PRODUCT configuration.');
    return;
  }

  if (Platform.isAndroid) {
    print('Skipping test due missing "$platformFilename".');
    return;
  }

  final platformDill = path.join(buildDir, platformFilename);
  await withTempDir((String tempDir) async {
    final helloFile = path.join(tempDir, 'hello.dart');
    final helloDillFile = path.join(tempDir, 'hello.dart.dill');

    // Compile script to Kernel IR.
    await File(helloFile).writeAsString('main() => print("Hello");');
    final genKernel = Platform.isWindows ?
      "pkg\\vm\\tool\\gen_kernel.bat" : 'pkg/vm/tool/gen_kernel';
    await run(genKernel, <String>[
      '--aot',
      '--platform=$platformDill',
      '-o',
      helloDillFile,
      helloFile,
    ]);

    // Ensure the AOT dill file will have effectively empty service related
    // libraries.
    final Component component = loadComponentFromBinary(helloDillFile);

    final libVmService = component.libraries
        .singleWhere((lib) => lib.importUri.toString() == 'dart:_vmservice');
    Expect.isTrue(libVmService.procedures.isEmpty);
    Expect.isTrue(libVmService.classes.isEmpty);
    Expect.isTrue(libVmService.fields.isEmpty);

    final libVmServiceIo = component.libraries
        .singleWhere((lib) => lib.importUri.toString() == 'dart:vmservice_io');
    Expect.isTrue(libVmServiceIo.procedures.isEmpty);
    Expect.isTrue(libVmServiceIo.classes.isEmpty);

    // Those fields are currently accessed by by the embedder, even in product
    // mode.
    Expect.isTrue(libVmServiceIo.fields.length <= 11);
  });
}
