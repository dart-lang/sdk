// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';
import 'package:expect/expect.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/binary/ast_to_binary.dart';
import 'package:vm/kernel_front_end.dart';

main() async {
  final outDir =
      Directory.systemTemp.createTempSync("incremental_load_from_dill_test");

  final dillFile = outDir.uri.resolve("dart2js.dart.dill").toFilePath();
  final unlinkedDillFile =
      outDir.uri.resolve("dart2js.dart.unlinked.dill").toFilePath();
  final unlinkedDillTxtFile =
      outDir.uri.resolve("dart2js.dart.unlinked dill.txt").toFilePath();

  final executable = Platform.executable;
  late final String platformDill;
  if (executable.endsWith('ReleaseX64/dart')) {
    platformDill =
        Uri.parse(executable).resolve('vm_platform_strong.dill').toFilePath();
  } else if (executable.endsWith('dart-sdk/bin/dart')) {
    platformDill = Uri.parse(executable)
        .resolve('../lib/_internal/vm_platform_strong.dill')
        .toFilePath();
  } else {
    print(
        'Skipping test due to not being run .../ReleaseX64/dart or .../dart-sdk/bin/dart.');
    return;
  }

  try {
    final arguments = <String>[
      '--platform=$platformDill',
      '--output=$dillFile',
      'pkg/compiler/lib/src/dart2js.dart',
    ];

    // Compile dart2js.dart.
    final ArgParser argParser = createCompilerArgParser();
    final int exitCode =
        await runCompiler(argParser.parse(arguments), '<usage>');
    Expect.equals(0, exitCode);

    // Load the dart2js.dart.dill and write the unlinked version.
    final component = loadComponentFromBinary(dillFile);
    final sink = File(unlinkedDillFile).openWrite();
    final printer = BinaryPrinter(sink,
        libraryFilter: (lib) => !lib.importUri.isScheme('dart'));
    printer.writeComponentFile(component);
    await sink.close();

    // Ensure we can load the unlinked dill file and ensure it doesn't include
    // core libraries.
    final unlinkedComponent = loadComponentFromBinary(unlinkedDillFile);
    final coreLibraryCount = unlinkedComponent.libraries
        .where(
            (lib) => lib.importUri.isScheme('dart') && lib.members.isNotEmpty)
        .length;
    Expect.equals(0, coreLibraryCount);

    // Ensure we can print the unlinked kernel to text.
    writeComponentToText(unlinkedComponent, path: unlinkedDillTxtFile);
  } finally {
    outDir.deleteSync(recursive: true);
  }
}
