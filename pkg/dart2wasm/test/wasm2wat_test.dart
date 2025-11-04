// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as path;
import 'package:wasm_builder/wasm_builder.dart';

import 'util.dart';

Future main() async {
  if (!Platform.isLinux && !Platform.isMacOS) return;

  await withTempDir((String tempDir) async {
    final dartFilename = 'third_party/flute/benchmarks/lib/complex.dart';

    final wasmFilename = path.join(tempDir, 'flute.wasm');
    final optWasmFilename = path.join(tempDir, 'flute.opt.wasm');
    final wasmFile = File(wasmFilename);
    final optWasmFile = File(wasmFilename);

    // Ensure we can print unoptimized dart2wasm modules
    await run([
      Platform.executable,
      'compile',
      'wasm',
      '-O0',
      dartFilename,
      '-o',
      wasmFilename,
    ]);
    wasmPrint(wasmFile.readAsBytesSync());

    // Ensure we can print wasm-opt optimized wasm modules
    await run([
      Platform.executable,
      'compile',
      'wasm',
      '-O3',
      dartFilename,
      '-o',
      optWasmFilename,
    ]);
    wasmPrint(optWasmFile.readAsBytesSync());

    // Temporary files will be deleted when returning to [withTempDir].
  });
}

void wasmPrint(Uint8List wasmBytes) {
  final deserializer = Deserializer(wasmBytes);
  final module = Module.deserialize(deserializer);
  print('len = ${module.printAsWat().length}');
}
