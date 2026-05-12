// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Regression test for an out-of-bounds read in dart::kernel::Program::ReadFrom
// when loading a .dill whose `library_count` field has been set to a value
// large enough that the subsequent ReadSingleFieldFromIndexNoReset call
// computes a negative offset.
//
// `library_count` is the uint32 at byte offset `size - 8` in the trailing
// index. Setting it to e.g. 2^28 causes
//     offset_ = size - (library_count + 12) * 4
// to underflow into a large negative intptr_t. Before the fix, the
// release-build Reader::ReadUInt32At only asserted (no-op under NDEBUG) and
// then dereferenced raw_buffer_ + offset_, segfaulting at
// `Program::ReadFrom+0x20f`.

import 'dart:io';
import 'dart:typed_data';

import 'package:expect/expect.dart';
import 'package:path/path.dart' as p;

Future<void> main() async {
  final tmp = await Directory.systemTemp.createTemp('regress_kernel_libcount');
  try {
    final source = File(p.join(tmp.path, 'hello.dart'));
    await source.writeAsString("void main() { print('hello'); }\n");

    final dillPath = p.join(tmp.path, 'hello.dill');
    final compile = await Process.run(Platform.executable, [
      'compile',
      'kernel',
      source.path,
      '-o',
      dillPath,
    ]);
    if (compile.exitCode != 0) {
      throw 'dart compile kernel failed:\n${compile.stdout}\n${compile.stderr}';
    }

    // Patch the uint32 library_count at file offset size-8 to a value
    // that makes (library_count + 12) * 4 exceed the file size.
    final evilPath = p.join(tmp.path, 'evil.dill');
    final bytes = Uint8List.fromList(File(dillPath).readAsBytesSync());
    const newLibraryCount = 1 << 28;
    bytes[bytes.length - 8] = (newLibraryCount >> 24) & 0xFF;
    bytes[bytes.length - 7] = (newLibraryCount >> 16) & 0xFF;
    bytes[bytes.length - 6] = (newLibraryCount >> 8) & 0xFF;
    bytes[bytes.length - 5] = newLibraryCount & 0xFF;
    File(evilPath).writeAsBytesSync(bytes);

    final run = await Process.run(Platform.executable, [evilPath]);

    // The patched .dill must not run cleanly.
    Expect.notEquals(0, run.exitCode);

    // The VM must reject the file gracefully — no SEGV / crash dump.
    final combinedStderr = run.stderr.toString();
    Expect.isFalse(
      combinedStderr.contains('===== CRASH ====='),
      'Expected graceful rejection but VM crashed:\n$combinedStderr',
    );
    Expect.isFalse(
      combinedStderr.contains('Program::ReadFrom'),
      'Expected graceful rejection but stack trace shows Program::ReadFrom:\n'
      '$combinedStderr',
    );
  } finally {
    await tmp.delete(recursive: true);
  }
}
