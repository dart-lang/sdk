// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:expect/expect.dart';
import 'package:path/path.dart' as path;

import '../util.dart';

final String mainDart = '${path.dirname(Platform.script.path)}/data/main.dart';
final String cfeDillName = 'main.cfe.dill';
final String tfaDillName = 'main.tfa.dill';
final String wasmOutName = 'main.wasm';
final String wasmOptOutName = 'main.opt.wasm';

Future<void> main() async {
  await testSuccessCases();
  await testFailureCases();
}

Future<void> testSuccessCases() async {
  await withTempDir((tmpDirPath) async {
    final cfeDill = File(path.join(tmpDirPath, cfeDillName));
    final tfaDill = File(path.join(tmpDirPath, tfaDillName));
    final wasmOut = File(path.join(tmpDirPath, wasmOutName));
    final wasmOptOut = File(path.join(tmpDirPath, wasmOptOutName));

    // Run CFE and expect output
    await run([
      dartAotExecutable,
      dart2wasmSnapshot,
      '--platform=$platformDill',
      '--phases=cfe',
      mainDart,
      cfeDill.path,
    ]);
    Expect.isTrue(await cfeDill.exists());
    Expect.isTrue((await cfeDill.stat()).size > 0);

    // Run TFA and expect output
    await run([
      dartAotExecutable,
      dart2wasmSnapshot,
      '--platform=$platformDill',
      '--phases=tfa',
      cfeDill.path,
      tfaDill.path,
    ]);
    Expect.isTrue(await tfaDill.exists());
    Expect.isTrue((await tfaDill.stat()).size > 0);

    // Run codegen and expect output
    await run([
      dartAotExecutable,
      dart2wasmSnapshot,
      '--platform=$platformDill',
      '--phases=codegen',
      tfaDill.path,
      wasmOut.path,
    ]);
    Expect.isTrue(await wasmOut.exists());
    Expect.isTrue((await wasmOut.stat()).size > 0);

    // Run opt and expect output
    await run([
      dartAotExecutable,
      dart2wasmSnapshot,
      '--platform=$platformDill',
      '--phases=opt',
      '--wasm-opt=$wasmOptExecutable',
      wasmOut.path,
      wasmOptOut.path,
    ]);
    Expect.isTrue(await wasmOptOut.exists());
    Expect.isTrue((await wasmOptOut.stat()).size > 0);
  });

  await withTempDir((tmpDirPath) async {
    final tfaDill = File(path.join(tmpDirPath, tfaDillName));
    final wasmOut = File(path.join(tmpDirPath, wasmOutName));

    // Run CFE & TFA and expect output
    await run([
      dartAotExecutable,
      dart2wasmSnapshot,
      '--platform=$platformDill',
      '--phases=cfe,tfa',
      mainDart,
      tfaDill.path,
    ]);
    Expect.isTrue(await tfaDill.exists());
    Expect.isTrue((await tfaDill.stat()).size > 0);

    // Run codegen and expect output
    await run([
      dartAotExecutable,
      dart2wasmSnapshot,
      '--platform=$platformDill',
      '--phases=codegen',
      tfaDill.path,
      wasmOut.path,
    ]);
    Expect.isTrue(await wasmOut.exists());
    Expect.isTrue((await wasmOut.stat()).size > 0);
  });

  await withTempDir((tmpDirPath) async {
    final cfeDill = File(path.join(tmpDirPath, cfeDillName));
    final wasmOut = File(path.join(tmpDirPath, wasmOutName));

    // Run CFE and expect output
    await run([
      dartAotExecutable,
      dart2wasmSnapshot,
      '--platform=$platformDill',
      '--phases=cfe',
      mainDart,
      cfeDill.path,
    ]);
    Expect.isTrue(await cfeDill.exists());
    Expect.isTrue((await cfeDill.stat()).size > 0);

    // Run TFA & codegen and expect output
    await run([
      dartAotExecutable,
      dart2wasmSnapshot,
      '--platform=$platformDill',
      '--phases=tfa,codegen',
      cfeDill.path,
      wasmOut.path,
    ]);
    Expect.isTrue(await wasmOut.exists());
    Expect.isTrue((await wasmOut.stat()).size > 0);
  });

  await withTempDir((tmpDirPath) async {
    final wasmOut = File(path.join(tmpDirPath, wasmOutName));

    // Run CFE & TFA & codegen and expect output
    await run([
      dartAotExecutable,
      dart2wasmSnapshot,
      '--platform=$platformDill',
      '--phases=cfe,tfa,codegen',
      mainDart,
      wasmOut.path,
    ]);
    Expect.isTrue(await wasmOut.exists());
    Expect.isTrue((await wasmOut.stat()).size > 0);
  });

  await withTempDir((tmpDirPath) async {
    final wasmOptOut = File(path.join(tmpDirPath, wasmOptOutName));

    // Run CFE & TFA & codegen & opt and expect output
    await run([
      dartAotExecutable,
      dart2wasmSnapshot,
      '--platform=$platformDill',
      '--phases=cfe,tfa,codegen,opt',
      '--wasm-opt=$wasmOptExecutable',
      mainDart,
      wasmOptOut.path,
    ]);
    Expect.isTrue(await wasmOptOut.exists());
    Expect.isTrue((await wasmOptOut.stat()).size > 0);
  });
}

Future<void> testFailureCases() async {
  await withTempDir((tmpDirPath) async {
    final cfeDill = File(path.join(tmpDirPath, cfeDillName));
    final tfaDill = File(path.join(tmpDirPath, tfaDillName));
    final wasmOut = File(path.join(tmpDirPath, wasmOutName));
    final wasmOptOut = File(path.join(tmpDirPath, wasmOptOutName));

    // CFE checks
    await expectFailedRun([
      dartAotExecutable,
      dart2wasmSnapshot,
      '--platform=$platformDill',
      '--phases=cfe',
      tfaDill.path,
      cfeDill.path
    ], 'Input to cfe phase must be a .dart file');

    await expectFailedRun([
      dartAotExecutable,
      dart2wasmSnapshot,
      '--platform=$platformDill',
      '--phases=cfe',
      mainDart,
      wasmOut.path
    ], 'Output from cfe phase must be a .dill file');

    // TFA checks
    await expectFailedRun([
      dartAotExecutable,
      dart2wasmSnapshot,
      '--platform=$platformDill',
      '--phases=tfa',
      mainDart,
      tfaDill.path
    ], 'Input to tfa phase must be a .dill file');

    await expectFailedRun([
      dartAotExecutable,
      dart2wasmSnapshot,
      '--platform=$platformDill',
      '--phases=tfa',
      cfeDill.path,
      wasmOut.path
    ], 'Output from tfa phase must be a .dill file');

    // Codegen checks
    await expectFailedRun([
      dartAotExecutable,
      dart2wasmSnapshot,
      '--platform=$platformDill',
      '--phases=codegen',
      mainDart,
      wasmOut.path
    ], 'Input to codegen phase must be a .dill file');

    await expectFailedRun([
      dartAotExecutable,
      dart2wasmSnapshot,
      '--platform=$platformDill',
      '--phases=codegen',
      tfaDill.path,
      cfeDill.path
    ], 'Output from codegen phase must be a .wasm file');

    // Opt checks
    await expectFailedRun([
      dartAotExecutable,
      dart2wasmSnapshot,
      '--platform=$platformDill',
      '--phases=opt',
      mainDart,
      wasmOptOut.path
    ], 'Input to opt phase must be a .wasm file');

    await expectFailedRun([
      dartAotExecutable,
      dart2wasmSnapshot,
      '--platform=$platformDill',
      '--phases=opt',
      wasmOut.path,
      cfeDill.path
    ], 'Output from opt phase must be a .wasm file');

    // Other checks
    await expectFailedRun([
      dartAotExecutable,
      dart2wasmSnapshot,
      '--platform=$platformDill',
      '--phases=cfe,codegen',
      mainDart,
      wasmOut.path
    ], 'must contain consecutive phases');

    await expectFailedRun([
      dartAotExecutable,
      dart2wasmSnapshot,
      '--platform=$platformDill',
      '--phases=notReal',
      mainDart,
      cfeDill.path
    ], 'Invalid compiler phase name');

    await expectFailedRun([
      dartAotExecutable,
      dart2wasmSnapshot,
      '--platform=$platformDill',
      '--phases=opt',
      '-O0',
      wasmOut.path,
      wasmOptOut.path
    ], 'Cannot specify "opt" phase with optimization level 0');
  });
}

Future<void> expectFailedRun(
    List<String> command, String expectedSubstring) async {
  try {
    await run(command, throwOutputOnFailure: true);
    Expect.fail('Expected dart2wasm error.');
  } catch (e) {
    Expect.contains(expectedSubstring, '$e');
  }
}
