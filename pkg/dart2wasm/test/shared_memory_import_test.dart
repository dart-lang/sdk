// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';
import 'package:expect/expect.dart';
import 'package:wasm_builder/wasm_builder.dart' as w;

import 'util.dart';

Future<void> main(List<String> args) async {
  if (!Platform.isLinux && !Platform.isMacOS) return;

  final options = (ArgParser()..addFlag('src', negatable: false)).parse(args);
  await withTempDir((String directory) async {
    final sharedPeer = '$directory/shared.wasm';
    final unsharedPeer = '$directory/unshared.wasm';
    writePeer(sharedPeer, shared: true);
    writePeer(unsharedPeer, shared: false);

    for (final level in [0, 1]) {
      final output = '$directory/import_O$level.wasm';
      await run([
        'bash',
        'pkg/dart2wasm/tool/compile_benchmark',
        if (options.flag('src')) '--src',
        '--enable-experimental-wasm-interop',
        '-O$level',
        'pkg/dart2wasm/test/shared_memory/import.dart',
        output,
      ]);
      await run([
        'bash',
        'pkg/dart2wasm/tool/run_benchmark',
        output,
        sharedPeer,
      ]);

      // Importing an unshared memory must fail at instantiation, even though
      // its minimum and maximum match the Dart declaration.
      final result = await Process.run('bash', [
        'pkg/dart2wasm/tool/run_benchmark',
        output,
        unsharedPeer,
      ]);
      final diagnostic = '${result.stdout}\n${result.stderr}';
      Expect.notEquals(0, result.exitCode, diagnostic);
      Expect.contains('LinkError', diagnostic);
      Expect.contains('shared', diagnostic);
    }
  });
}

// An independent Wasm module owns the memory and exposes direct Wasm functions
// for checking that both modules access the same bytes, including after growth.
void writePeer(String path, {required bool shared}) {
  final module = w.ModuleBuilder('memory_peer', null);
  final unsharedMemory = module.memories.define(false, 1, 2);
  module.exports.export('memory', unsharedMemory);
  final memory = module.memories.define(shared, 1, 2);
  module.exports.export('sharedMemory', memory);

  final read = module.functions.define(
    module.types.defineFunction([w.NumType.i32], [w.NumType.i32]),
    'read',
  );
  read.body
    ..local_get(read.locals[0])
    ..i32_load(memory, 0)
    ..end();
  module.exports.export('read', read.build());

  final write = module.functions.define(
    module.types.defineFunction([w.NumType.i32, w.NumType.i32], []),
    'write',
  );
  write.body
    ..local_get(write.locals[0])
    ..local_get(write.locals[1])
    ..i32_store(memory, 0)
    ..end();
  module.exports.export('write', write.build());

  final serializer = w.Serializer();
  module.build().serialize(serializer);
  File(path).writeAsBytesSync(serializer.data);
}
