// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test the command line options of dart2js.

import 'dart:async';

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

import 'package:compiler/compiler_api.dart' as api;
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/dart2js.dart' as entry;
import 'package:compiler/src/options.dart' show CompilerOptions, Dart2JSStage;

main() {
  entry.enableWriteString = false;
  asyncTest(() async {
    // Full compile from Dart source
    await test(['foo.dart'], out: 'out.js');
    await test(['foo.dart', '-ofoo.js'], out: 'foo.js');
    await test(['foo.dart', '--out=foo.js'], out: 'foo.js');
    await test(['foo.dart', '--out=/some/path/'], out: '/some/path/out.js');
    await test(['foo.dart', '--out=prefix-'], out: 'prefix-');
    await test(['foo.dart', '--out=/some/path/prefix-'],
        out: '/some/path/prefix-');

    // Full compile from dill
    await test(['foo.dill'], allFromDill: true, out: 'out.js');
    await test(['foo.dill', '-ofoo.js'], allFromDill: true, out: 'foo.js');
    await test(['foo.dill', '--out=foo.js'], allFromDill: true, out: 'foo.js');
    await test(['foo.dill', '--out=/some/path/'],
        allFromDill: true, out: '/some/path/out.js');
    await test(['foo.dill', '--out=prefix-'],
        allFromDill: true, out: 'prefix-');
    await test(['foo.dill', '--out=/some/path/prefix-'],
        allFromDill: true, out: '/some/path/prefix-');

    // Run CFE only
    await test(['${Flags.stage}=cfe', 'foo.dart'], out: 'out.dill');
    await test(['${Flags.stage}=cfe', '--out=out1.dill', 'foo.dart'],
        out: 'out1.dill');
    await test([Flags.cfeOnly, 'foo.dart'], out: 'out.dill');
    await test([Flags.cfeOnly, 'foo.dart', '--out=out1.dill'],
        out: 'out1.dill');
    await test([Flags.cfeOnly, 'foo.dart', '-oout1.dill'], out: 'out1.dill');
    await test([Flags.cfeOnly, 'foo.dart', '--out=prefix-'], out: 'prefix-');
    await test([Flags.cfeOnly, 'foo.dart', '--out=/some/path/prefix-'],
        out: '/some/path/prefix-');
    await test(
        [
          Flags.cfeOnly,
          'foo.dart',
          '${Flags.readModularAnalysis}=modular1.data,modular2.data',
          '${Flags.writeModularAnalysis}=modularcfe.data',
        ],
        cfeModularAnalysis: true,
        readModularAnalysis: ['modular1.data', 'modular2.data'],
        writeModularAnalysis: 'modularcfe.data',
        out: 'out.dill');
    await test(['foo.dart', '${Flags.stage}=cfe', '--out=/some/path/'],
        out: '/some/path/out.dill');
    await test(['foo.dart', '${Flags.stage}=cfe', '--out=prefix-'],
        out: 'prefix-out.dill');
    await test([
      'foo.dart',
      '${Flags.stage}=cfe',
      '--out=/some/path/prefix-',
    ], out: '/some/path/prefix-out.dill');

    // Run CFE only from dill
    await test(['${Flags.stage}=cfe', 'foo.dill'],
        cfeFromDill: true, out: 'out.dill');
    await test(['${Flags.stage}=cfe', '--out=out1.dill', 'foo.dill'],
        cfeFromDill: true, out: 'out1.dill');
    await test([Flags.cfeOnly, 'foo.dill'], cfeFromDill: true, out: 'out.dill');
    await test([Flags.cfeOnly, 'foo.dill', '--out=out1.dill'],
        out: 'out1.dill');
    await test([Flags.cfeOnly, 'foo.dill', '-oout1.dill'],
        cfeFromDill: true, out: 'out1.dill');
    await test([Flags.cfeOnly, 'foo.dill', '--out=prefix-'],
        cfeFromDill: true, out: 'prefix-');
    await test([Flags.cfeOnly, 'foo.dill', '--out=/some/path/prefix-'],
        cfeFromDill: true, out: '/some/path/prefix-');
    await test(
        [
          Flags.cfeOnly,
          'foo.dill',
          '${Flags.readModularAnalysis}=modular1.data,modular2.data',
          '${Flags.writeModularAnalysis}=modularcfe.data',
        ],
        cfeFromDill: true,
        cfeModularAnalysis: true,
        readModularAnalysis: ['modular1.data', 'modular2.data'],
        writeModularAnalysis: 'modularcfe.data',
        out: 'out.dill');
    await test(['foo.dill', '${Flags.stage}=cfe', '--out=/some/path/'],
        cfeFromDill: true, out: '/some/path/out.dill');
    await test(['foo.dill', '${Flags.stage}=cfe', '--out=prefix-'],
        cfeFromDill: true, out: 'prefix-out.dill');
    await test([
      'foo.dill',
      '${Flags.stage}=cfe',
      '--out=/some/path/prefix-',
    ], cfeFromDill: true, out: '/some/path/prefix-out.dill');

    // Run modular analysis only
    await test(['${Flags.stage}=modular-analysis', 'foo.dart'],
        writeModularAnalysis: 'modular.data', out: 'out.dill');
    await test(
        ['${Flags.stage}=modular-analysis', '--out=out1.dill', 'foo.dart'],
        writeModularAnalysis: 'modular.data', out: 'out1.dill');
    await test([
      '${Flags.stage}=modular-analysis',
      '${Flags.writeModularAnalysis}=modular1.data',
      'foo.dart'
    ], writeModularAnalysis: 'modular1.data', out: 'out.dill');
    await test(['${Flags.writeModularAnalysis}=modular1.data', 'foo.dart'],
        out: 'out.dill', writeModularAnalysis: 'modular1.data');
    await test([
      '${Flags.writeModularAnalysis}=modular1.data',
      'foo.dart',
      '--out=out1.dill'
    ], out: 'out1.dill', writeModularAnalysis: 'modular1.data');
    await test([
      '${Flags.writeModularAnalysis}=modular1.data',
      'foo.dart',
      '-oout1.dill'
    ], out: 'out1.dill', writeModularAnalysis: 'modular1.data');
    await test(
        ['foo.dart', '${Flags.stage}=modular-analysis', '--out=/some/path/'],
        writeModularAnalysis: '/some/path/modular.data',
        out: '/some/path/out.dill');
    await test(['foo.dart', '${Flags.stage}=modular-analysis', '--out=prefix-'],
        writeModularAnalysis: 'prefix-modular.data', out: 'prefix-out.dill');
    await test([
      'foo.dart',
      '${Flags.stage}=modular-analysis',
      '--out=/some/path/prefix-'
    ],
        writeModularAnalysis: '/some/path/prefix-modular.data',
        out: '/some/path/prefix-out.dill');

    // Run deferred load ids only
    await test([
      '${Flags.stage}=deferred-load-ids',
      'foo.dill',
      '${Flags.deferredLoadIdMapUri}=load_ids.data'
    ], writeDeferredLoadIds: 'load_ids.data');
    await test([
      '${Flags.stage}=deferred-load-ids',
      'foo.dill',
    ], writeDeferredLoadIds: 'deferred_load_ids.data');
    await test(['foo.dill', '${Flags.deferredLoadIdMapUri}=load_ids.data'],
        writeDeferredLoadIds: 'load_ids.data');

    // Run closed world only
    await test(['${Flags.stage}=closed-world', 'foo.dill'],
        writeClosedWorld: 'world.data', out: 'out.dill');
    await test(['${Flags.stage}=closed-world', '${Flags.inputDill}=foo.dill'],
        writeClosedWorld: 'world.data', out: 'out.dill');
    await test(['${Flags.stage}=closed-world', '--out=out1.dill', 'foo.dill'],
        writeClosedWorld: 'world.data', out: 'out1.dill');
    await test([
      '${Flags.stage}=closed-world',
      '${Flags.writeClosedWorld}=world1.data',
      'foo.dill'
    ], writeClosedWorld: 'world1.data', out: 'out.dill');
    await test([
      '${Flags.writeClosedWorld}=world1.data',
      'foo.dill',
      '--out=out1.dill'
    ], out: 'out1.dill', writeClosedWorld: 'world1.data');
    await test(
        ['${Flags.writeClosedWorld}=world1.data', 'foo.dill', '-oout1.dill'],
        out: 'out1.dill', writeClosedWorld: 'world1.data');
    await test(
        ['${Flags.writeClosedWorld}=world1.data', 'foo.dill', '--out=prefix-'],
        out: 'prefix-', writeClosedWorld: 'world1.data');
    await test([
      '${Flags.writeClosedWorld}=world1.data',
      'foo.dill',
      '--out=/some/path/prefix-'
    ], out: '/some/path/prefix-', writeClosedWorld: 'world1.data');
    await test(
        [
          '${Flags.readModularAnalysis}=modular1.data,modular2.data',
          '${Flags.writeClosedWorld}=world1.data',
          'foo.dill'
        ],
        out: 'out.dill',
        readModularAnalysis: ['modular1.data', 'modular2.data'],
        writeClosedWorld: 'world1.data');
    await test(['foo.dill', '${Flags.stage}=closed-world', '--out=/some/path/'],
        writeClosedWorld: '/some/path/world.data', out: '/some/path/out.dill');
    await test(['foo.dill', '${Flags.stage}=closed-world', '--out=prefix-'],
        writeClosedWorld: 'prefix-world.data', out: 'prefix-out.dill');
    await test(
        ['foo.dill', '${Flags.stage}=closed-world', '--out=/some/path/prefix-'],
        writeClosedWorld: '/some/path/prefix-world.data',
        out: '/some/path/prefix-out.dill');

    // Run global inference only
    await test(['${Flags.stage}=global-inference', 'foo.dill'],
        readClosedWorld: 'world.data', writeData: 'global.data');
    await test(
        ['${Flags.stage}=global-inference', '${Flags.inputDill}=foo.dill'],
        readClosedWorld: 'world.data', writeData: 'global.data');
    await test([
      '${Flags.stage}=global-inference',
      '${Flags.readClosedWorld}=world1.data',
      'foo.dill'
    ], readClosedWorld: 'world1.data', writeData: 'global.data');
    await test([
      '${Flags.stage}=global-inference',
      '${Flags.writeData}=global1.data',
      'foo.dill'
    ], readClosedWorld: 'world.data', writeData: 'global1.data');
    await test([
      '${Flags.readClosedWorld}=world1.data',
      '${Flags.writeData}=global1.data',
      'foo.dill'
    ], readClosedWorld: 'world1.data', writeData: 'global1.data');
    await test([
      '${Flags.readClosedWorld}=world1.data',
      '${Flags.writeData}=global1.data',
      'foo.dill',
      '--out=prefix-'
    ], readClosedWorld: 'world1.data', writeData: 'global1.data');
    await test([
      '${Flags.readClosedWorld}=world1.data',
      '${Flags.writeData}=global1.data',
      'foo.dill',
      '--out=/some/path/prefix-'
    ], readClosedWorld: 'world1.data', writeData: 'global1.data');
    await test([
      '${Flags.readModularAnalysis}=modular1.data,modular2.data',
      '${Flags.readClosedWorld}=world1.data',
      '${Flags.writeData}=global1.data',
      'foo.dill'
    ], readModularAnalysis: [
      'modular1.data',
      'modular2.data'
    ], readClosedWorld: 'world1.data', writeData: 'global1.data');
    await test(
        ['foo.dill', '${Flags.stage}=global-inference', '--out=/some/path/'],
        readClosedWorld: '/some/path/world.data',
        writeData: '/some/path/global.data');
    await test(['foo.dill', '${Flags.stage}=global-inference', '--out=prefix-'],
        readClosedWorld: 'prefix-world.data', writeData: 'prefix-global.data');
    await test([
      'foo.dill',
      '${Flags.stage}=global-inference',
      '--out=/some/path/prefix-'
    ],
        readClosedWorld: '/some/path/prefix-world.data',
        writeData: '/some/path/prefix-global.data');
    await test([
      'foo.dill',
      '${Flags.stage}=global-inference',
      '--out=/some/path/foo.data'
    ],
        readClosedWorld: '/some/path/foo.dataworld.data',
        writeData: '/some/path/foo.dataglobal.data');
    await test(
        ['foo.dill', '${Flags.stage}=global-inference', '--out=foo.data'],
        readClosedWorld: 'foo.dataworld.data',
        writeData: 'foo.dataglobal.data');

    // Run codegen only
    await test([
      '${Flags.stage}=codegen',
      '${Flags.codegenShard}=10',
      '${Flags.codegenShards}=11',
      'foo.dill'
    ],
        readClosedWorld: 'world.data',
        readData: 'global.data',
        writeCodegen: 'codegen',
        codegenShard: 10,
        codegenShards: 11);
    await test([
      '${Flags.stage}=codegen',
      '${Flags.codegenShard}=10',
      '${Flags.codegenShards}=11',
      '${Flags.inputDill}=foo.dill'
    ],
        readClosedWorld: 'world.data',
        readData: 'global.data',
        writeCodegen: 'codegen',
        codegenShard: 10,
        codegenShards: 11);
    await test([
      '${Flags.stage}=codegen',
      '${Flags.readClosedWorld}=world1.data',
      '${Flags.readData}=global1.data',
      '${Flags.codegenShard}=10',
      '${Flags.codegenShards}=11',
      'foo.dill'
    ],
        readClosedWorld: 'world1.data',
        readData: 'global1.data',
        writeCodegen: 'codegen',
        codegenShard: 10,
        codegenShards: 11);
    await test([
      '${Flags.stage}=codegen',
      '${Flags.writeCodegen}=codegen1',
      '${Flags.codegenShard}=10',
      '${Flags.codegenShards}=11',
      'foo.dill'
    ],
        readClosedWorld: 'world.data',
        readData: 'global.data',
        writeCodegen: 'codegen1',
        codegenShard: 10,
        codegenShards: 11);
    await test([
      '${Flags.writeCodegen}=codegen1',
      '${Flags.codegenShard}=10',
      '${Flags.codegenShards}=11',
      'foo.dill'
    ],
        readClosedWorld: 'world.data',
        readData: 'global.data',
        writeCodegen: 'codegen1',
        codegenShard: 10,
        codegenShards: 11);
    await test([
      '${Flags.readClosedWorld}=world1.data',
      '${Flags.readData}=global1.data',
      '${Flags.writeCodegen}=codegen1',
      '${Flags.codegenShard}=10',
      '${Flags.codegenShards}=11',
      'foo.dill'
    ],
        readClosedWorld: 'world1.data',
        readData: 'global1.data',
        writeCodegen: 'codegen1',
        codegenShard: 10,
        codegenShards: 11);
    await test([
      '${Flags.readClosedWorld}=world1.data',
      '${Flags.readData}=global1.data',
      '${Flags.writeCodegen}=codegen1',
      '${Flags.codegenShard}=10',
      '${Flags.codegenShards}=11',
      'foo.dill',
      '--out=prefix-'
    ],
        readClosedWorld: 'world1.data',
        readData: 'global1.data',
        writeCodegen: 'codegen1',
        codegenShard: 10,
        codegenShards: 11);
    await test([
      '${Flags.readClosedWorld}=world1.data',
      '${Flags.readData}=global1.data',
      '${Flags.writeCodegen}=codegen1',
      '${Flags.codegenShard}=10',
      '${Flags.codegenShards}=11',
      'foo.dill',
      '--out=/some/path/prefix-'
    ],
        readClosedWorld: 'world1.data',
        readData: 'global1.data',
        writeCodegen: 'codegen1',
        codegenShard: 10,
        codegenShards: 11);
    await test([
      '${Flags.readModularAnalysis}=modular1.data,modular2.data',
      '${Flags.readClosedWorld}=world1.data',
      '${Flags.readData}=global1.data',
      '${Flags.writeCodegen}=codegen1',
      '${Flags.codegenShard}=10',
      '${Flags.codegenShards}=11',
      'foo.dill'
    ],
        readModularAnalysis: [
          'modular1.data',
          'modular2.data'
        ],
        readClosedWorld: 'world1.data',
        readData: 'global1.data',
        writeCodegen: 'codegen1',
        codegenShard: 10,
        codegenShards: 11);
    await test([
      'foo.dill',
      '${Flags.stage}=codegen',
      '--out=/some/path/',
      '${Flags.codegenShard}=10',
      '${Flags.codegenShards}=11',
    ],
        readClosedWorld: '/some/path/world.data',
        readData: '/some/path/global.data',
        writeCodegen: '/some/path/codegen',
        codegenShard: 10,
        codegenShards: 11);
    await test([
      'foo.dill',
      '${Flags.stage}=codegen',
      '--out=prefix-',
      '${Flags.codegenShard}=10',
      '${Flags.codegenShards}=11',
    ],
        readClosedWorld: 'prefix-world.data',
        readData: 'prefix-global.data',
        writeCodegen: 'prefix-codegen',
        codegenShard: 10,
        codegenShards: 11);
    await test([
      'foo.dill',
      '${Flags.stage}=codegen',
      '--out=/some/path/prefix-',
      '${Flags.codegenShard}=10',
      '${Flags.codegenShards}=11',
    ],
        readClosedWorld: '/some/path/prefix-world.data',
        readData: '/some/path/prefix-global.data',
        writeCodegen: '/some/path/prefix-codegen',
        codegenShard: 10,
        codegenShards: 11);
    await test([
      'foo.dill',
      '${Flags.stage}=codegen',
      '--out=/some/path/foo.data',
      '${Flags.codegenShard}=10',
      '${Flags.codegenShards}=11',
    ],
        readClosedWorld: '/some/path/foo.dataworld.data',
        readData: '/some/path/foo.dataglobal.data',
        writeCodegen: '/some/path/foo.datacodegen',
        codegenShard: 10,
        codegenShards: 11);
    await test([
      'foo.dill',
      '${Flags.stage}=codegen',
      '--out=foo.data',
      '${Flags.codegenShard}=10',
      '${Flags.codegenShards}=11',
    ],
        readClosedWorld: 'foo.dataworld.data',
        readData: 'foo.dataglobal.data',
        writeCodegen: 'foo.datacodegen',
        codegenShard: 10,
        codegenShards: 11);

    // Run emitter only
    await test(
        ['${Flags.stage}=emit-js', '${Flags.codegenShards}=11', 'foo.dill'],
        readClosedWorld: 'world.data',
        readData: 'global.data',
        readCodegen: 'codegen',
        codegenShards: 11,
        out: 'out.js');
    await test([
      '${Flags.stage}=emit-js',
      '${Flags.codegenShards}=11',
      '${Flags.inputDill}=foo.dill'
    ],
        readClosedWorld: 'world.data',
        readData: 'global.data',
        readCodegen: 'codegen',
        codegenShards: 11,
        out: 'out.js');
    await test([
      '${Flags.stage}=emit-js',
      '${Flags.readClosedWorld}=world1.data',
      '${Flags.readData}=global1.data',
      '${Flags.readCodegen}=codegen1',
      '${Flags.codegenShards}=11',
      'foo.dill'
    ],
        readClosedWorld: 'world1.data',
        readData: 'global1.data',
        readCodegen: 'codegen1',
        codegenShards: 11,
        out: 'out.js');
    await test([
      '${Flags.stage}=emit-js',
      '--out=out.js',
      '${Flags.codegenShards}=11',
      'foo.dill'
    ],
        readClosedWorld: 'world.data',
        readData: 'global.data',
        readCodegen: 'codegen',
        codegenShards: 11,
        out: 'out.js');
    await test([
      '${Flags.readClosedWorld}=world1.data',
      '${Flags.readData}=global1.data',
      '${Flags.readCodegen}=codegen1',
      '${Flags.codegenShards}=11',
      'foo.dill'
    ],
        readClosedWorld: 'world1.data',
        readData: 'global1.data',
        readCodegen: 'codegen1',
        codegenShards: 11,
        out: 'out.js');
    await test([
      '${Flags.readClosedWorld}=world1.data',
      '${Flags.readData}=global1.data',
      '${Flags.readCodegen}=codegen1',
      '${Flags.codegenShards}=11',
      '--out=out1.js',
      'foo.dill'
    ],
        readClosedWorld: 'world1.data',
        readData: 'global1.data',
        readCodegen: 'codegen1',
        codegenShards: 11,
        out: 'out1.js');
    await test([
      '${Flags.readClosedWorld}=world1.data',
      '${Flags.readData}=global1.data',
      '${Flags.readCodegen}=codegen1',
      '${Flags.codegenShards}=11',
      '-oout1.js',
      'foo.dill'
    ],
        readClosedWorld: 'world1.data',
        readData: 'global1.data',
        readCodegen: 'codegen1',
        codegenShards: 11,
        out: 'out1.js');
    await test([
      '${Flags.readModularAnalysis}=modular1.data,modular2.data',
      '${Flags.readClosedWorld}=world1.data',
      '${Flags.readData}=global1.data',
      '${Flags.readCodegen}=codegen1',
      '${Flags.codegenShards}=11',
      'foo.dill'
    ],
        readModularAnalysis: [
          'modular1.data',
          'modular2.data'
        ],
        readClosedWorld: 'world1.data',
        readData: 'global1.data',
        readCodegen: 'codegen1',
        codegenShards: 11,
        out: 'out.js');
    await test([
      'foo.dill',
      '${Flags.stage}=emit-js',
      '--out=/some/path/',
      '${Flags.codegenShards}=11'
    ],
        readClosedWorld: '/some/path/world.data',
        readData: '/some/path/global.data',
        readCodegen: '/some/path/codegen',
        codegenShards: 11,
        out: '/some/path/out.js');
    await test([
      'foo.dill',
      '${Flags.stage}=emit-js',
      '--out=prefix-',
      '${Flags.codegenShards}=11'
    ],
        readClosedWorld: 'prefix-world.data',
        readData: 'prefix-global.data',
        readCodegen: 'prefix-codegen',
        codegenShards: 11,
        out: 'prefix-out.js');
    await test([
      'foo.dill',
      '${Flags.stage}=emit-js',
      '--out=/some/path/prefix-',
      '${Flags.codegenShards}=11'
    ],
        readClosedWorld: '/some/path/prefix-world.data',
        readData: '/some/path/prefix-global.data',
        readCodegen: '/some/path/prefix-codegen',
        codegenShards: 11,
        out: '/some/path/prefix-out.js');

    // Run codegen and emitter only
    await test(['${Flags.stage}=codegen-emit-js', 'foo.dill'],
        readClosedWorld: 'world.data', readData: 'global.data', out: 'out.js');
    await test(
        ['${Flags.stage}=codegen-emit-js', '${Flags.inputDill}=foo.dill'],
        readClosedWorld: 'world.data', readData: 'global.data', out: 'out.js');
    await test([
      '${Flags.stage}=codegen-emit-js',
      '${Flags.readClosedWorld}=world1.data',
      '${Flags.readData}=global1.data',
      'foo.dill'
    ], readClosedWorld: 'world1.data', readData: 'global1.data', out: 'out.js');
    await test(['${Flags.stage}=codegen-emit-js', '--out=out.js', 'foo.dill'],
        readClosedWorld: 'world.data', readData: 'global.data', out: 'out.js');
    await test([
      '${Flags.readClosedWorld}=world1.data',
      '${Flags.readData}=global1.data',
      'foo.dill'
    ], readClosedWorld: 'world1.data', readData: 'global1.data', out: 'out.js');
    await test([
      '${Flags.readClosedWorld}=world1.data',
      '${Flags.readData}=global1.data',
      '--out=out1.js',
      'foo.dill'
    ],
        readClosedWorld: 'world1.data',
        readData: 'global1.data',
        out: 'out1.js');
    await test([
      '${Flags.readClosedWorld}=world1.data',
      '${Flags.readData}=global1.data',
      '-oout1.js',
      'foo.dill'
    ],
        readClosedWorld: 'world1.data',
        readData: 'global1.data',
        out: 'out1.js');
    await test([
      '${Flags.readModularAnalysis}=modular1.data,modular2.data',
      '${Flags.readClosedWorld}=world1.data',
      '${Flags.readData}=global1.data',
      'foo.dill'
    ], readModularAnalysis: [
      'modular1.data',
      'modular2.data'
    ], readClosedWorld: 'world1.data', readData: 'global1.data', out: 'out.js');
    await test(
        ['foo.dill', '${Flags.stage}=codegen-emit-js', '--out=/some/path/'],
        readClosedWorld: '/some/path/world.data',
        readData: '/some/path/global.data',
        out: '/some/path/out.js');
    await test(['foo.dill', '${Flags.stage}=codegen-emit-js', '--out=prefix-'],
        readClosedWorld: 'prefix-world.data',
        readData: 'prefix-global.data',
        out: 'prefix-out.js');
    await test([
      'foo.dill',
      '${Flags.stage}=codegen-emit-js',
      '--out=/some/path/prefix-'
    ],
        readClosedWorld: '/some/path/prefix-world.data',
        readData: '/some/path/prefix-global.data',
        out: '/some/path/prefix-out.js');

    // Invalid states with stage flag
    // CFE stage
    await test([
      '${Flags.stage}=cfe',
      '${Flags.readClosedWorld}=world1.data',
      'foo.dart'
    ], readClosedWorld: 'world.data', out: 'out.js', exitCode: 1);
    await test(
        ['${Flags.stage}=cfe', '${Flags.readData}=global1.data', 'foo.dart'],
        readData: 'global1.data', out: 'out.js', exitCode: 1);
    await test(
        ['${Flags.stage}=cfe', '${Flags.readCodegen}=codegen', 'foo.dart'],
        readCodegen: 'codegen', out: 'out.js', exitCode: 1);
    await test(['${Flags.stage}=cfe', '${Flags.codegenShard}=1', 'foo.dart'],
        codegenShard: 1, exitCode: 1);
    await test(['${Flags.stage}=cfe', '${Flags.codegenShards}=2', 'foo.dart'],
        codegenShards: 2, exitCode: 1);
    await test([
      '${Flags.stage}=cfe',
      '${Flags.writeClosedWorld}=world1.data',
      'foo.dart'
    ], writeClosedWorld: 'world.data', out: 'out.js', exitCode: 1);
    await test(
        ['${Flags.stage}=cfe', '${Flags.writeData}=global1.data', 'foo.dart'],
        writeData: 'global1.data', out: 'out.js', exitCode: 1);
    await test(
        ['${Flags.stage}=cfe', '${Flags.writeCodegen}=codegen', 'foo.dart'],
        writeCodegen: 'codegen', out: 'out.js', exitCode: 1);

    // Closed world stage
    await test(['${Flags.stage}=closed-world', 'foo.dart'],
        out: 'out.js', exitCode: 1);
    await test([
      '${Flags.stage}=closed-world',
      '${Flags.readClosedWorld}=world1.data',
      'foo.dill'
    ], readClosedWorld: 'world.data', out: 'out.js', exitCode: 1);
    await test([
      '${Flags.stage}=closed-world',
      '${Flags.readData}=global1.data',
      'foo.dill'
    ], readData: 'global1.data', out: 'out.js', exitCode: 1);
    await test([
      '${Flags.stage}=closed-world',
      '${Flags.readCodegen}=codegen',
      'foo.dill'
    ], readCodegen: 'codegen', out: 'out.js', exitCode: 1);
    await test(['${Flags.stage}=cfe', '${Flags.codegenShard}=1', 'foo.dill'],
        codegenShard: 1, exitCode: 1);
    await test(
        ['${Flags.stage}=closed-world', '${Flags.codegenShards}=2', 'foo.dill'],
        codegenShards: 2, exitCode: 1);
    await test([
      '${Flags.stage}=closed-world',
      '${Flags.writeData}=global1.data',
      'foo.dill'
    ], writeData: 'global1.data', out: 'out.js', exitCode: 1);
    await test([
      '${Flags.stage}=closed-world',
      '${Flags.writeCodegen}=codegen',
      'foo.dill'
    ], writeCodegen: 'codegen', out: 'out.js', exitCode: 1);

    // Global inference stage
    await test(['${Flags.stage}=global-inference', 'foo.dart'],
        out: 'out.js', exitCode: 1);
    await test([
      '${Flags.stage}=global-inference',
      '${Flags.readData}=global1.data',
      'foo.dill'
    ], readData: 'global1.data', out: 'out.js', exitCode: 1);
    await test([
      '${Flags.stage}=global-inference',
      '${Flags.readCodegen}=codegen',
      'foo.dill'
    ], readCodegen: 'codegen', out: 'out.js', exitCode: 1);
    await test(['${Flags.stage}=cfe', '${Flags.codegenShard}=1', 'foo.dill'],
        codegenShard: 1, exitCode: 1);
    await test([
      '${Flags.stage}=global-inference',
      '${Flags.codegenShards}=2',
      'foo.dill'
    ], codegenShards: 2, exitCode: 1);
    await test([
      '${Flags.stage}=global-inference',
      '${Flags.writeClosedWorld}=world1.data',
      'foo.dill'
    ], writeClosedWorld: 'world1.data', out: 'out.js', exitCode: 1);
    await test([
      '${Flags.stage}=global-inference',
      '${Flags.writeCodegen}=codegen',
      'foo.dill'
    ], writeCodegen: 'codegen', out: 'out.js', exitCode: 1);

    // Codegen stage
    await test([
      '${Flags.stage}=codegen',
      '${Flags.codegenShard}=0',
      '${Flags.codegenShards}=1',
      'foo.dart'
    ], out: 'out.js', exitCode: 1);
    await test(
        ['${Flags.stage}=codegen', '${Flags.readCodegen}=codegen', 'foo.dill'],
        readCodegen: 'codegen', out: 'out.js', exitCode: 1);
    await test([
      '${Flags.stage}=codegen',
      '${Flags.writeClosedWorld}=world1.data',
      'foo.dill'
    ], writeClosedWorld: 'world1.data', out: 'out.js', exitCode: 1);
    await test([
      '${Flags.stage}=codegen',
      '${Flags.writeData}=global1.data',
      'foo.dill'
    ], writeData: 'global1.data', out: 'out.js', exitCode: 1);

    // JS Emitter stage
    await test(
        ['${Flags.stage}=emit-js', '${Flags.codegenShards}=1', 'foo.dart'],
        codegenShards: 1, exitCode: 1);
    await test(
        ['${Flags.stage}=emit-js', '${Flags.codegenShard}=1', 'foo.dill'],
        codegenShard: 1, exitCode: 1);
    await test([
      '${Flags.stage}=emit-js',
      '${Flags.writeClosedWorld}=world1.data',
      'foo.dill'
    ], writeClosedWorld: 'world1.data', out: 'out.js', exitCode: 1);
    await test([
      '${Flags.stage}=emit-js',
      '${Flags.writeData}=global1.data',
      'foo.dill'
    ], writeData: 'global1.data', out: 'out.js', exitCode: 1);
    await test(
        ['${Flags.stage}=emit-js', '${Flags.writeCodegen}=codegen', 'foo.dill'],
        writeData: 'codegen', out: 'out.js', exitCode: 1);

    // Codegen and JS Emitter stage
    await test(['${Flags.stage}=codegen-emit-js', 'foo.dart'],
        out: 'out1.js', exitCode: 1);
    await test([
      '${Flags.stage}=codegen-emit-js',
      '${Flags.readCodegen}=codegen',
      'foo.dill'
    ], readCodegen: 'codegen', out: 'out1.js', exitCode: 1);
    await test([
      '${Flags.stage}=codegen-emit-js',
      '${Flags.writeClosedWorld}=world1.data',
      'foo.dill'
    ], writeClosedWorld: 'world1.data', out: 'out.js', exitCode: 1);
    await test([
      '${Flags.stage}=codegen-emit-js',
      '${Flags.writeData}=global1.data',
      'foo.dill'
    ], writeData: 'global1.data', out: 'out.js', exitCode: 1);
    await test([
      '${Flags.stage}=codegen-emit-js',
      '${Flags.writeCodegen}=global1.data',
      'foo.dill'
    ], writeCodegen: 'codegen', out: 'out.js', exitCode: 1);

    // Invalid states with write/read flags
    await test([], exitCode: 1);
    await test([Flags.cfeOnly], exitCode: 1);
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
        writeData: 'global.data', exitCode: 1);
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
    ], out: 'out.dill', writeClosedWorld: 'out.dill.world', exitCode: 1);

    await test([Flags.readClosedWorld, 'foo.dill'],
        out: 'out.js', readClosedWorld: 'foo.dill.world', exitCode: 1);
    await test([Flags.readClosedWorld, 'foo.dill', '--out=foo.js'],
        out: 'foo.js', readClosedWorld: 'foo.dill.world', exitCode: 1);
    await test(['${Flags.readClosedWorld}=out.world', 'foo.dill'],
        out: 'out.js', readClosedWorld: 'out.world', exitCode: 1);
    await test(
        ['${Flags.readClosedWorld}=out.world', 'foo.dill', '--out=foo.js'],
        out: 'foo.js', readClosedWorld: 'out.world', exitCode: 1);

    await test([Flags.readData, 'foo.dill'], exitCode: 1);
    await test([Flags.readClosedWorld, Flags.readData, 'foo.dill'],
        out: 'out.js',
        readClosedWorld: 'foo.dill.world',
        readData: 'foo.dill.data',
        exitCode: 1);
    await test(
        [Flags.readClosedWorld, Flags.readData, 'foo.dill', '--out=foo.js'],
        out: 'foo.js',
        readClosedWorld: 'foo.dill.world',
        readData: 'foo.dill.data',
        exitCode: 1);

    await test([
      Flags.writeCodegen,
      'foo.dill',
      '${Flags.codegenShard}=0',
      '${Flags.codegenShards}=2'
    ], exitCode: 1);
    await test([
      Flags.readClosedWorld,
      Flags.readData,
      Flags.writeCodegen,
      'foo.dill',
      '${Flags.codegenShard}=0',
      '${Flags.codegenShards}=2'
    ],
        readClosedWorld: 'foo.dill.world',
        readData: 'foo.dill.data',
        writeCodegen: 'codegen.code',
        codegenShard: 0,
        codegenShards: 2,
        exitCode: 1);
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
  });
}

Future test(List<String> arguments,
    {int? exitCode,
    String? out,
    List<String>? readModularAnalysis,
    String? writeModularAnalysis,
    bool allFromDill = false,
    bool cfeFromDill = false,
    bool cfeModularAnalysis = false,
    String? readClosedWorld,
    String? writeClosedWorld,
    String? writeDeferredLoadIds,
    String? readData,
    String? writeData,
    String? readCodegen,
    String? writeCodegen,
    int? codegenShard,
    int? codegenShards}) async {
  print('--------------------------------------------------------------------');
  print('dart2js ${arguments.join(' ')}');
  print('--------------------------------------------------------------------');
  entry.CompileFunc oldCompileFunc = entry.compileFunc;
  entry.ExitFunc oldExitFunc = entry.exitFunc;

  late final CompilerOptions options;
  int? actualExitCode;
  entry.compileFunc = (_options, input, diagnostics, output) {
    options = _options;
    return Future<api.CompilationResult>.value(api.CompilationResult(null));
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
    Expect.equals(toUri(out), options.outputUri, "Unexpected output uri.");
    if (allFromDill) {
      Expect.equals(Dart2JSStage.allFromDill, options.stage);
    }
    if (cfeFromDill) {
      Expect.equals(Dart2JSStage.cfeFromDill, options.stage);
    }
    if (readModularAnalysis != null) {
      Expect.isNotNull(options.modularAnalysisInputs,
          "modularAnalysisInputs expected to be non-null.");
      Expect.listEquals(
          readModularAnalysis.map(toUri).toList(),
          options.modularAnalysisInputs!,
          "Unexpected modularAnalysisInputs uri");
    }
    if (writeModularAnalysis == null) {
      Expect.notEquals(options.stage, Dart2JSStage.modularAnalysis);
    } else {
      Expect.equals(
          options.stage,
          cfeModularAnalysis
              ? (cfeFromDill ? Dart2JSStage.cfeFromDill : Dart2JSStage.cfe)
              : Dart2JSStage.modularAnalysis);
      Expect.equals(
          toUri(writeModularAnalysis),
          options.dataOutputUriForStage(Dart2JSStage.modularAnalysis),
          "Unexpected writeModularAnalysis uri");
    }
    if (writeDeferredLoadIds == null) {
      Expect.notEquals(options.stage, Dart2JSStage.deferredLoadIds);
    } else {
      Expect.equals(options.stage, Dart2JSStage.deferredLoadIds);
      Expect.equals(
          toUri(writeDeferredLoadIds),
          options.dataOutputUriForStage(Dart2JSStage.deferredLoadIds),
          "Unexpected writeDeferredLoadIds uri");
    }
    if (readClosedWorld == null) {
      Expect.isFalse(options.stage.shouldReadClosedWorld);
    } else {
      Expect.isTrue(options.stage.shouldReadClosedWorld);
      Expect.equals(
          toUri(readClosedWorld),
          options.dataInputUriForStage(Dart2JSStage.closedWorld),
          "Unexpected readClosedWorld uri");
    }
    if (writeClosedWorld == null) {
      Expect.notEquals(options.stage, Dart2JSStage.closedWorld);
    } else {
      Expect.equals(options.stage, Dart2JSStage.closedWorld);
      Expect.equals(
          toUri(writeClosedWorld),
          options.dataOutputUriForStage(Dart2JSStage.closedWorld),
          "Unexpected writeClosedWorld uri");
    }
    if (readData == null) {
      Expect.isFalse(options.stage.shouldReadGlobalInference);
    } else {
      Expect.isTrue(options.stage.shouldReadGlobalInference);
      Expect.equals(
          toUri(readData),
          options.dataInputUriForStage(Dart2JSStage.globalInference),
          "Unexpected readData uri");
    }
    if (writeData == null) {
      Expect.notEquals(options.stage, Dart2JSStage.globalInference);
    } else {
      Expect.equals(options.stage, Dart2JSStage.globalInference);
      Expect.equals(
          toUri(writeData),
          options.dataOutputUriForStage(Dart2JSStage.globalInference),
          "Unexpected writeData uri");
    }
    if (readCodegen == null) {
      Expect.isFalse(options.stage.shouldReadCodegenShards);
    } else {
      Expect.isTrue(options.stage.shouldReadCodegenShards);
      Expect.equals(
          toUri(readCodegen),
          options.dataInputUriForStage(Dart2JSStage.codegenSharded),
          "Unexpected readCodegen uri");
    }
    if (writeCodegen == null) {
      Expect.notEquals(options.stage, Dart2JSStage.codegenSharded);
    } else {
      Expect.equals(options.stage, Dart2JSStage.codegenSharded);
      Expect.equals(
          toUri(writeCodegen),
          options.dataOutputUriForStage(Dart2JSStage.codegenSharded),
          "Unexpected writeCodegen uri");
    }
    Expect.equals(
        codegenShard, options.codegenShard, "Unexpected codegenShard uri");
    Expect.equals(
        codegenShards, options.codegenShards, "Unexpected codegenShards uri");
  }

  entry.compileFunc = oldCompileFunc;
  entry.exitFunc = oldExitFunc;
}

Uri? toUri(String? path) => path != null ? Uri.base.resolve(path) : null;
