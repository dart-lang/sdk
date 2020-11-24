// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Test the command line options of dart2js.

import 'dart:async';

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

import 'package:compiler/compiler_new.dart' as api;
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/dart2js.dart' as entry;
import 'package:compiler/src/options.dart' show CompilerOptions;

main() {
  entry.enableWriteString = false;
  asyncTest(() async {
    await test([], exitCode: 1);
    await test(['foo.dart'], out: 'out.js');
    await test(['foo.dart', '-ofoo.js'], out: 'foo.js');
    await test(['foo.dart', '--out=foo.js'], out: 'foo.js');

    await test([Flags.cfeOnly], exitCode: 1);
    await test([Flags.cfeOnly, 'foo.dart'], out: 'out.dill');
    await test([Flags.cfeOnly, 'foo.dart', '--out=out.dill'], out: 'out.dill');
    await test([Flags.cfeOnly, 'foo.dart', Flags.readClosedWorld], exitCode: 1);
    await test(['foo.dart', Flags.readClosedWorld, Flags.cfeOnly], exitCode: 1);
    await test([Flags.cfeOnly, 'foo.dart', Flags.readData], exitCode: 1);
    await test(['foo.dart', Flags.readData, Flags.cfeOnly], exitCode: 1);
    await test([Flags.cfeOnly, 'foo.dart', Flags.readCodegen], exitCode: 1);
    await test(['foo.dart', Flags.readCodegen, Flags.cfeOnly], exitCode: 1);
    await test([Flags.cfeOnly, 'foo.dart', Flags.writeClosedWorld],
        exitCode: 1);
    await test(['foo.dart', Flags.writeClosedWorld, Flags.cfeOnly],
        exitCode: 1);
    await test([Flags.cfeOnly, 'foo.dart', Flags.writeData], exitCode: 1);
    await test(['foo.dart', Flags.writeData, Flags.cfeOnly], exitCode: 1);
    await test([Flags.cfeOnly, 'foo.dart', Flags.writeCodegen], exitCode: 1);
    await test(['foo.dart', Flags.writeCodegen, Flags.cfeOnly], exitCode: 1);

    await test([Flags.writeData, 'foo.dart'],
        out: 'out.dill', writeData: 'out.dill.data');
    await test(['${Flags.writeData}=foo.data', 'foo.dart', '--out=foo.dill'],
        out: 'foo.dill', writeData: 'foo.data');
    await test([Flags.readClosedWorld, Flags.writeClosedWorld, 'foo.dart'],
        exitCode: 1);
    await test([Flags.writeClosedWorld, Flags.readClosedWorld, 'foo.dart'],
        exitCode: 1);
    await test([Flags.readData, Flags.writeData, 'foo.dart'], exitCode: 1);
    await test([Flags.writeData, Flags.readData, 'foo.dart'], exitCode: 1);
    await test([Flags.readCodegen, Flags.writeClosedWorld, 'foo.dart'],
        exitCode: 1);
    await test([Flags.readCodegen, Flags.writeData, 'foo.dart'], exitCode: 1);
    await test([Flags.writeClosedWorld, Flags.readData, 'foo.dart'],
        exitCode: 1);
    await test([Flags.writeClosedWorld, Flags.readCodegen, 'foo.dart'],
        exitCode: 1);
    await test([Flags.writeData, Flags.readCodegen, 'foo.dart'], exitCode: 1);

    await test([
      Flags.writeClosedWorld,
      'foo.dart',
    ], out: 'out.dill', writeClosedWorld: 'out.dill.world');
    await test(
        ['${Flags.writeClosedWorld}=foo.world', 'foo.dart', '--out=foo.dill'],
        out: 'foo.dill', writeClosedWorld: 'foo.world');

    await test([Flags.readClosedWorld, 'foo.dill'],
        out: 'out.js', readClosedWorld: 'foo.dill.world');
    await test([Flags.readClosedWorld, 'foo.dill', '--out=foo.js'],
        out: 'foo.js', readClosedWorld: 'foo.dill.world');
    await test(['${Flags.readClosedWorld}=out.world', 'foo.world'],
        out: 'out.js', readClosedWorld: 'out.world');
    await test(
        ['${Flags.readClosedWorld}=out.world', 'foo.world', '--out=foo.js'],
        out: 'foo.js', readClosedWorld: 'out.world');
    await test(
      [Flags.readClosedWorld, Flags.writeData, 'foo.dill'],
      out: 'out.dill',
      readClosedWorld: 'foo.dill.world',
      writeData: 'out.dill.data',
    );
    await test([
      '${Flags.readClosedWorld}=foo.world',
      '${Flags.writeData}=foo.data',
      'foo.dart',
      '--out=foo.dill'
    ], out: 'foo.dill', readClosedWorld: 'foo.world', writeData: 'foo.data');

    await test([Flags.readData, 'foo.dill'],
        out: 'out.js', readData: 'foo.dill.data');
    await test([Flags.readData, 'foo.dill', '--out=foo.js'],
        out: 'foo.js', readData: 'foo.dill.data');
    await test(['${Flags.readData}=out.data', 'foo.dill'],
        out: 'out.js', readData: 'out.data');
    await test(['${Flags.readData}=out.data', 'foo.dill', '--out=foo.js'],
        out: 'foo.js', readData: 'out.data');

    await test([
      Flags.writeCodegen,
      'foo.dill',
      '${Flags.codegenShard}=0',
      '${Flags.codegenShards}=2'
    ], exitCode: 1);
    await test([
      Flags.readData,
      Flags.writeCodegen,
      'foo.dill',
      '${Flags.codegenShard}=0',
      '${Flags.codegenShards}=2'
    ],
        out: 'out',
        readData: 'foo.dill.data',
        writeCodegen: 'out.code',
        codegenShard: 0,
        codegenShards: 2);
    await test([
      Flags.writeCodegen,
      Flags.readData,
      'foo.dill',
      '${Flags.codegenShard}=1',
      '${Flags.codegenShards}=2'
    ],
        out: 'out',
        readData: 'foo.dill.data',
        writeCodegen: 'out.code',
        codegenShard: 1,
        codegenShards: 2);
    await test([
      '${Flags.readData}=foo.data',
      '${Flags.writeCodegen}=foo.code',
      'foo.dill',
      '${Flags.codegenShard}=0',
      '${Flags.codegenShards}=3'
    ],
        out: 'out',
        readData: 'foo.data',
        writeCodegen: 'foo.code',
        codegenShard: 0,
        codegenShards: 3);
    await test([
      '${Flags.readData}=foo.data',
      '${Flags.writeCodegen}',
      'foo.dill',
      '--out=foo.js',
      '${Flags.codegenShard}=0',
      '${Flags.codegenShards}=2'
    ],
        out: 'foo.js',
        readData: 'foo.data',
        writeCodegen: 'foo.js.code',
        codegenShard: 0,
        codegenShards: 2);
    await test([Flags.writeCodegen, 'foo.dill', Flags.readCodegen],
        exitCode: 1);
    await test([Flags.readCodegen, Flags.writeCodegen, 'foo.dill'],
        exitCode: 1);
    await test(
        [Flags.readData, Flags.writeCodegen, 'foo.dill', Flags.readCodegen],
        exitCode: 1);
    await test(
        [Flags.readCodegen, Flags.readData, Flags.writeCodegen, 'foo.dill'],
        exitCode: 1);
    await test([
      Flags.readData,
      Flags.writeCodegen,
      'foo.dill',
    ], exitCode: 1);
    await test([
      Flags.readData,
      Flags.writeCodegen,
      'foo.dill',
      '${Flags.codegenShard}=0'
    ], exitCode: 1);
    await test([
      Flags.readData,
      Flags.writeCodegen,
      'foo.dill',
      '${Flags.codegenShards}=2'
    ], exitCode: 1);
    await test([
      Flags.readData,
      Flags.writeCodegen,
      'foo.dill',
      '${Flags.codegenShards}=0'
    ], exitCode: 1);
    await test([
      Flags.readData,
      Flags.writeCodegen,
      'foo.dill',
      '${Flags.codegenShard}=-1',
      '${Flags.codegenShards}=2'
    ], exitCode: 1);
    await test([
      Flags.readData,
      Flags.writeCodegen,
      'foo.dill',
      '${Flags.codegenShard}=2',
      '${Flags.codegenShards}=2'
    ], exitCode: 1);

    await test([Flags.readCodegen, 'foo.dill', '${Flags.codegenShards}=2'],
        out: 'out.js',
        readData: 'foo.dill.data',
        readCodegen: 'foo.dill.code',
        codegenShards: 2);
    await test([
      '${Flags.readCodegen}=foo.code',
      'foo.dill',
      '${Flags.codegenShards}=3'
    ],
        out: 'out.js',
        readData: 'foo.dill.data',
        readCodegen: 'foo.code',
        codegenShards: 3);

    await test([
      Flags.readData,
      Flags.readCodegen,
      'foo.dill',
      '${Flags.codegenShards}=2'
    ],
        out: 'out.js',
        readData: 'foo.dill.data',
        readCodegen: 'foo.dill.code',
        codegenShards: 2);
    await test([
      '${Flags.readData}=foo.data',
      '${Flags.readCodegen}=foo.code',
      'foo.dill',
      '${Flags.codegenShards}=3',
      '-v'
    ],
        out: 'out.js',
        readData: 'foo.data',
        readCodegen: 'foo.code',
        codegenShards: 3);
  });
}

Future test(List<String> arguments,
    {int exitCode,
    String out,
    String readClosedWorld,
    String writeClosedWorld,
    String readData,
    String writeData,
    String readCodegen,
    String writeCodegen,
    int codegenShard,
    int codegenShards}) async {
  print('--------------------------------------------------------------------');
  print('dart2js ${arguments.join(' ')}');
  print('--------------------------------------------------------------------');
  entry.CompileFunc oldCompileFunc = entry.compileFunc;
  entry.ExitFunc oldExitFunc = entry.exitFunc;

  CompilerOptions options;
  int actualExitCode;
  entry.compileFunc = (_options, input, diagnostics, output) {
    options = _options;
    return new Future<api.CompilationResult>.value(
        new api.CompilationResult(null));
  };
  entry.exitFunc = (_exitCode) {
    actualExitCode = _exitCode;
    throw 'exited';
  };
  try {
    await entry.compilerMain(arguments);
  } catch (e, s) {
    Expect.equals('exited', e, "Unexpected exception: $e\n$s");
  }
  Expect.equals(exitCode, actualExitCode, "Unexpected exit code");
  if (actualExitCode == null) {
    Expect.isNotNull(options, "Missing options object");
    Expect.equals(toUri(out), options.outputUri, "Unexpected output uri.");
    Expect.equals(toUri(readClosedWorld), options.readClosedWorldUri,
        "Unexpected readClosedWorld uri");
    Expect.equals(toUri(writeClosedWorld), options.writeClosedWorldUri,
        "Unexpected writeClosedWorld uri");
    Expect.equals(
        toUri(readData), options.readDataUri, "Unexpected readData uri");
    Expect.equals(
        toUri(writeData), options.writeDataUri, "Unexpected writeData uri");
    Expect.equals(toUri(readCodegen), options.readCodegenUri,
        "Unexpected readCodegen uri");
    Expect.equals(toUri(writeCodegen), options.writeCodegenUri,
        "Unexpected writeCodegen uri");
    Expect.equals(
        codegenShard, options.codegenShard, "Unexpected codegenShard uri");
    Expect.equals(
        codegenShards, options.codegenShards, "Unexpected codegenShards uri");
  }

  entry.compileFunc = oldCompileFunc;
  entry.exitFunc = oldExitFunc;
}

Uri toUri(String path) => path != null ? Uri.base.resolve(path) : null;
