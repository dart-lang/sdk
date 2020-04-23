// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test ensures that certain core libraries are "empty" in product mode (thereby
// ensuring the right conditional pragma annotations were used).

import "dart:async";
import "dart:io";

import 'package:expect/expect.dart';
import 'package:kernel/binary/ast_from_binary.dart'
    show BinaryBuilderWithMetadata;
import 'package:kernel/kernel.dart';
import 'package:path/path.dart' as path;
import 'package:vm/metadata/bytecode.dart' show BytecodeMetadataRepository;

import 'use_flag_test_helper.dart';

Future main(List<String> args) async {
  final buildDir = path.dirname(Platform.resolvedExecutable);

  if (!buildDir.contains('Product')) {
    print('Skipping test due to running in non-PRODUCT configuration.');
    return;
  }

  if (Platform.isAndroid) {
    print('Skipping test due to missing "${path.basename(platformDill)}".');
    return;
  }

  await withTempDir('product-aot-kernel-test', (String tempDir) async {
    final helloFile = path.join(tempDir, 'hello.dart');
    final helloDillFile = path.join(tempDir, 'hello.dart.dill');

    // Compile script to Kernel IR.
    await File(helloFile).writeAsString('main() => print("Hello");');
    await run(genKernel, <String>[
      '--aot',
      '--platform=$platformDill',
      '-o',
      helloDillFile,
      helloFile,
    ]);

    // Ensure the AOT dill file will have effectively empty service related
    // libraries.

    final component = Component();
    final bytecodeMetadataRepository = BytecodeMetadataRepository();
    component.addMetadataRepository(bytecodeMetadataRepository);
    final List<int> bytes = File(helloDillFile).readAsBytesSync();
    new BinaryBuilderWithMetadata(bytes).readComponent(component);

    final bytecodeComponent =
        bytecodeMetadataRepository.mapping[component]?.component;
    if (bytecodeComponent != null) {
      final libVmService = bytecodeComponent.libraries.singleWhere(
          (lib) => lib.importUri.toString() == "'dart:_vmservice'");
      final libVmServiceToplevelClass = libVmService.classes.single;
      Expect.isTrue(libVmServiceToplevelClass.name.toString() == "''");
      Expect.isTrue(libVmServiceToplevelClass.members.functions.isEmpty);
      Expect.isTrue(libVmServiceToplevelClass.members.fields.isEmpty);

      final libVmServiceIo = bytecodeComponent.libraries.singleWhere(
          (lib) => lib.importUri.toString() == "'dart:vmservice_io'");
      final libVmServiceIoToplevelClass = libVmServiceIo.classes.single;
      Expect.isTrue(libVmServiceIoToplevelClass.name.toString() == "''");
      Expect.isTrue(libVmServiceIoToplevelClass.members.functions.isEmpty);

      // Those fields are currently accessed by by the embedder, even in product
      // mode.
      Expect.isTrue(libVmServiceIoToplevelClass.members.fields.length <= 11);
    } else {
      final libVmService = component.libraries
          .singleWhere((lib) => lib.importUri.toString() == 'dart:_vmservice');
      Expect.isTrue(libVmService.procedures.isEmpty);
      Expect.isTrue(libVmService.classes.isEmpty);
      Expect.isTrue(libVmService.fields.isEmpty);

      final libVmServiceIo = component.libraries.singleWhere(
          (lib) => lib.importUri.toString() == 'dart:vmservice_io');
      Expect.isTrue(libVmServiceIo.procedures.isEmpty);
      Expect.isTrue(libVmServiceIo.classes.isEmpty);

      // Those fields are currently accessed by by the embedder, even in product
      // mode.
      Expect.isTrue(libVmServiceIo.fields.length <= 11);
    }
  });
}
